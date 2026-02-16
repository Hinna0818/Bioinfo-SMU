# Pesudo-Bulk差异分析有一定复杂性，建议熟悉原理后再来使用该脚本
library(Seurat)
library(Matrix)
library(DESeq2)
library(edgeR)
library(limma)
load("Data/pbmc.Rda")

# 主函数参数说明:
# seu: Seurat对象；包含表达矩阵和meta.data。
# assay: assay名称，默认为 "RNA"
# layer: assay层名，默认为 "counts"（差异分析需要未经归一化的原始数据）。
# sample_col: meta.data中表示样本ID的列名，pseudo-bulk会按sample_col+group_col联合聚合，默认为 "orig.ident"。
# group_col: meta.data中表示组别/条件的列名，用于差异分析建模。
# celltype_col: meta.data中表示细胞类型的列名；若为NULL表示不分细胞类型直接进行整体差异分析，非NULL表示按该列逐类型分析。（详见示例）
# contrast: 长度为2的向量，用于指定比较方向，其取值需要来自group_col；例如 c("Tumor","Normal")，表示Tumor/Normal。
# covariates: 需要校正的协变量列名向量；例如 c("batch","sex")，不校正则设NULL。
# methods: 差异分析算法，可选 DESeq2、edgeR（基于负二项分布）、limma（基于线性模型），可传一个或多个。
# min_cells_per_sample: 每个分层内样本最少细胞数阈值，低于阈值样本会被丢弃，默认为 20。
# min_samples_per_group: 每组最少样本数，不足时直接报错。
# min_count: 基因在单个样本中的最小计数阈值，默认为 10。
# min_total_count: 基因在所有样本中的总计数阈值，默认为 20。
# min_prop_samples: 满足 min_count 的样本比例阈值；例如0.2表示至少20%样本达标。
# p_adj_method: 多重检验校正方法，默认为 "BH"。
# verbose: 是否打印进度信息。
run_pseudobulk_de <- function(
    seu,                          
    assay = "RNA",               
    layer = "counts",             
    sample_col = "orig.ident",                   
    group_col,                    
    celltype_col = NULL,          
    contrast,                     
    covariates = NULL,            
    methods = c("DESeq2", "edgeR", "limma"), 
    min_cells_per_sample = 20,    
    min_samples_per_group = 2,    
    min_count = 10,               
    min_total_count = 20,         
    min_prop_samples = 0.2,       
    p_adj_method = "BH",          
    verbose = TRUE                
) {
  
  method_map <- c("deseq2" = "DESeq2", "edger" = "edgeR", "limma" = "limma")
  methods_lower <- tolower(methods)
  if (any(!methods_lower %in% names(method_map))) {
    stop("`methods` 仅支持 DESeq2/edgeR/limma。", call. = FALSE)
  }
  methods <- unique(unname(method_map[methods_lower]))
  
  meta <- seu[[]]
  required_cols <- c(sample_col, group_col, covariates)
  if (!is.null(celltype_col)) required_cols <- c(required_cols, celltype_col)
  missing_cols <- setdiff(required_cols, colnames(meta))
  if (length(missing_cols) > 0) {
    stop(sprintf("meta.data 缺少列: %s", paste(missing_cols, collapse = ", ")), call. = FALSE)
  }
  
  # 提取 counts（优先 layer，失败则报错）
  counts <- NULL
  if ("LayerData" %in% getNamespaceExports("SeuratObject")) {
    counts <- SeuratObject::LayerData(object = seu, assay = assay, layer = layer)
  } else {
    counts <- SeuratObject::GetAssayData(object = seu, assay = assay, slot = layer)
  }
  
  common_cells <- intersect(colnames(counts), rownames(meta))
  counts <- counts[, common_cells, drop = FALSE]
  meta <- meta[common_cells, , drop = FALSE]
  
  # 根据 celltype_col 决定是全局分析还是按细胞类型分析
  if (is.null(celltype_col)) {
    strata <- list("__all__" = rownames(meta))
  } else {
    strata <- split(rownames(meta), as.character(meta[[celltype_col]]))
  }
  
  if (verbose) message("[PseudoBulk] start")
  
  all_results <- list()
  comparison_label <- paste0(as.character(contrast[1]), "_vs_", as.character(contrast[2]))
  
  for (stratum_name in names(strata)) {
    if (verbose) message(sprintf("[PseudoBulk] stratum=%s", stratum_name))
    
    # 1) 细胞 -> 伪样本聚合（sample_col + group_col）
    cells_in_stratum <- strata[[stratum_name]]
    meta_sub <- meta[cells_in_stratum, , drop = FALSE]
    counts_sub <- counts[, cells_in_stratum, drop = FALSE]
    
    pseudo_sample_id <- paste(
      as.character(meta_sub[[sample_col]]),
      as.character(meta_sub[[group_col]]),
      sep = "__"
    )
    sample_factor <- factor(pseudo_sample_id)
    agg_design <- Matrix::sparse.model.matrix(~ 0 + sample_factor)
    colnames(agg_design) <- levels(sample_factor)
    pb_counts <- counts_sub %*% agg_design
    colnames(pb_counts) <- levels(sample_factor)
    
    sample_meta <- meta_sub[
      match(colnames(pb_counts), pseudo_sample_id),
      c(sample_col, group_col, covariates),
      drop = FALSE
    ]
    rownames(sample_meta) <- colnames(pb_counts)
    
    # 2) 伪样本与基因过滤
    sample_cell_n <- table(pseudo_sample_id)
    keep_samples <- names(sample_cell_n)[sample_cell_n >= min_cells_per_sample]
    pb_counts <- pb_counts[, intersect(colnames(pb_counts), keep_samples), drop = FALSE]
    sample_meta <- sample_meta[colnames(pb_counts), , drop = FALSE]
    
    sample_meta <- sample_meta[sample_meta[[group_col]] %in% contrast, , drop = FALSE]
    pb_counts <- pb_counts[, rownames(sample_meta), drop = FALSE]
    
    group_n <- table(as.character(sample_meta[[group_col]]))
    missing_groups <- setdiff(as.character(contrast), names(group_n))
    
    if (length(missing_groups) > 0 || any(group_n[as.character(contrast)] < min_samples_per_group)) {
      if (!is.null(celltype_col)) {
        msg <- sprintf(
          "跳过细胞类型 `%s`：组内样本不足或缺少组别（group计数: %s）。",
          stratum_name,
          paste(sprintf("%s=%d", names(group_n), as.integer(group_n)), collapse = ", ")
        )
        message(msg)
        next
      }
      
      if (length(missing_groups) > 0) {
        stop(sprintf("分层 `%s` 缺少 contrast 指定组。", stratum_name), call. = FALSE)
      }
      if (any(group_n[as.character(contrast)] < min_samples_per_group)) {
        stop(sprintf("分层 `%s` 组内样本数不足。", stratum_name), call. = FALSE)
      }
    }
    
    min_n_samples <- max(1L, ceiling(min_prop_samples * ncol(pb_counts)))
    keep_genes <- Matrix::rowSums(pb_counts >= min_count) >= min_n_samples &
      Matrix::rowSums(pb_counts) >= min_total_count
    pb_counts <- pb_counts[keep_genes, , drop = FALSE]
    
    if (nrow(pb_counts) == 0) {
      stop(sprintf("分层 `%s` 过滤后无基因可用于建模。", stratum_name), call. = FALSE)
    }
    
    # 3) 建模与结果整理
    for (method_name in methods) {
      pb_for_method <- pb_counts
      sample_meta_method <- sample_meta
      sample_meta_method$..group <- factor(as.character(sample_meta_method[[group_col]]), levels = contrast)
      method_res <- NULL
      
      if (identical(method_name, "DESeq2")) {
        design_formula <- stats::as.formula(
          paste("~", paste(c(covariates, "..group"), collapse = " + "))
        )
        dds <- DESeq2::DESeqDataSetFromMatrix(
          countData = as.matrix(round(pb_for_method)),
          colData = sample_meta_method,
          design = design_formula
        )
        dds <- DESeq2::DESeq(dds, quiet = TRUE)
        res <- DESeq2::results(
          dds,
          contrast = c("..group", as.character(contrast[1]), as.character(contrast[2]))
        )
        res_df <- as.data.frame(res)
        method_res <- data.frame(
          gene = rownames(res_df),
          logFC = res_df$log2FoldChange,
          pvalue = res_df$pvalue,
          padj = res_df$padj,
          avgExpr = log2(res_df$baseMean + 1),
          stringsAsFactors = FALSE
        )
      } else if (identical(method_name, "edgeR")) {
        design_formula <- stats::as.formula(
          paste("~", paste(c("0 + ..group", covariates), collapse = " + "))
        )
        design <- stats::model.matrix(design_formula, data = sample_meta_method)
        case_col <- paste0("..group", make.names(contrast[1]))
        ctrl_col <- paste0("..group", make.names(contrast[2]))
        contrast_matrix <- limma::makeContrasts(
          contrasts = paste0("`", case_col, "` - `", ctrl_col, "`"),
          levels = design
        )
        
        y <- edgeR::DGEList(counts = as.matrix(pb_for_method))
        y <- edgeR::calcNormFactors(y, method = "TMM")
        y <- edgeR::estimateDisp(y, design = design, robust = TRUE)
        fit <- edgeR::glmQLFit(y, design = design, robust = TRUE)
        qlf <- edgeR::glmQLFTest(fit, contrast = contrast_matrix[, 1])
        tab <- edgeR::topTags(qlf, n = Inf, sort.by = "none")$table
        method_res <- data.frame(
          gene = rownames(tab),
          logFC = tab$logFC,
          pvalue = tab$PValue,
          padj = tab$FDR,
          avgExpr = tab$logCPM,
          stringsAsFactors = FALSE
        )
      } else if (identical(method_name, "limma")) {
        design_formula <- stats::as.formula(
          paste("~", paste(c("0 + ..group", covariates), collapse = " + "))
        )
        design <- stats::model.matrix(design_formula, data = sample_meta_method)
        case_col <- paste0("..group", make.names(contrast[1]))
        ctrl_col <- paste0("..group", make.names(contrast[2]))
        contrast_matrix <- limma::makeContrasts(
          contrasts = paste0("`", case_col, "` - `", ctrl_col, "`"),
          levels = design
        )
        
        y <- edgeR::DGEList(counts = as.matrix(pb_for_method))
        y <- edgeR::calcNormFactors(y, method = "TMM")
        v <- limma::voom(y, design = design, plot = FALSE)
        fit <- limma::lmFit(v, design)
        fit <- limma::contrasts.fit(fit, contrasts = contrast_matrix)
        fit <- limma::eBayes(fit, robust = TRUE)
        tab <- limma::topTable(fit, number = Inf, sort.by = "none")
        method_res <- data.frame(
          gene = rownames(tab),
          logFC = tab$logFC,
          pvalue = tab$P.Value,
          padj = tab$adj.P.Val,
          avgExpr = tab$AveExpr,
          stringsAsFactors = FALSE
        )
      }
      
      if (nrow(pb_for_method) == 0 || is.null(method_res) || nrow(method_res) == 0) {
        stop(sprintf("分层 `%s` 在方法 `%s` 下无可用结果。", stratum_name, method_name), call. = FALSE)
      }
      
      if (!identical(p_adj_method, "BH")) {
        method_res$padj <- stats::p.adjust(method_res$pvalue, method = p_adj_method)
      }
      
      method_res$method <- method_name
      method_res$celltype <- stratum_name
      method_res$comparison <- comparison_label
      method_res$n_samples <- nrow(sample_meta_method)
      method_res <- method_res[, c(
        "gene", "logFC", "pvalue", "padj", "avgExpr",
        "method", "celltype", "comparison", "n_samples"
      )]
      
      all_results[[paste(stratum_name, method_name, sep = "::")]] <- method_res
    }
  }
  
  if (length(all_results) == 0) {
    combined_results <- data.frame(
      gene = character(0),
      logFC = numeric(0),
      pvalue = numeric(0),
      padj = numeric(0),
      avgExpr = numeric(0),
      method = character(0),
      celltype = character(0),
      comparison = character(0),
      n_samples = integer(0),
      stringsAsFactors = FALSE
    )
    if (!is.null(celltype_col)) {
      message("所有细胞类型均因组内样本不足或缺少组别而被跳过。")
    }
  } else {
    combined_results <- do.call(rbind, all_results)
    rownames(combined_results) <- NULL
  }
  
  if (verbose) message("[PseudoBulk] done")
  
  combined_results
}


# 示例1：对S期细胞和非S期细胞之间进行pseudobulk差异分析，不考虑细胞类型的影响
# 先定义分组变量，即S期细胞与非S期细胞
pbmc$is_S_Phase <- ifelse(pbmc$Phase == "S", "S", "G") # 如果Phase=="S"则返回 "S"，否则返回 "G"

# 函数会将相同sample_col且相同group_col的细胞聚合成一个伪样本，然后对不同group_col的伪样本之间进行差异分析
# 例如这里是来自同一个orig.ident且处在S期/非S期的细胞聚合伪一个伪样本
# 差异分析将比较S期细胞聚合成的伪样本 vs 非S期细胞聚合成的伪样本之间的差异
deg_results <- run_pseudobulk_de(
  seu = pbmc,
  sample_col = "orig.ident",                   
  group_col = "is_S_Phase",
  contrast = c("S", "G"), # 指定差异分析的方向，c("S", "G")意味着分析结果的logFC反映的是S相比于G变化了多少
  celltype_col = NULL, # 不考虑细胞类型的影响
  covariates = "orig.ident", # 由于S期细胞和非S期细胞可能来自同一orig.ident的样本，存在组内相关性，需要设置协变量
  methods = "DESeq2" # 伪样本量较小时推荐使用DESeq2
)


# 示例2：相同情况，考虑细胞类型的影响
# celltype_col不为NULL时，差异分析会在相同细胞类型之间进行，即分别在相同的细胞类型中构建伪样本，并比较S期细胞与非S期细胞的差异
# 若某类细胞无法构建足够的伪样本，则会跳过该细胞
# 这样可排除因为细胞类型不同而导致的差异基因
deg_results <- run_pseudobulk_de(
  seu = pbmc,
  sample_col = "orig.ident",                   
  group_col = "is_S_Phase",
  contrast = c("S", "G"), 
  celltype_col = "celltype", # 不考虑细胞类型的影响
  covariates = "orig.ident", 
  methods = "DESeq2" 
)

# 筛选
deg_results <- deg_results[rowSums(is.na(deg_results)) == 0, ] # 去除包含空值NA的行
deg_results <- deg_results[deg_results$padj < 0.05, ]

save(deg_results, file="Data/pesudoBulkDE.Rda")




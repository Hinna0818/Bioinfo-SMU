library(Seurat)
library(ggplot2)
library(dplyr)
library(CytoTRACE2)
library(scop)
load("Data/subgroups.Rda")

sce <- subgroups

# 将 RNA count 数据转换为矩阵
exp <- as.matrix(GetAssayData(sce, assay = "RNA", layer = "counts"))
# 过滤掉在少于 5 个细胞中表达的基因
exp <- exp[apply(exp > 0, 1, sum) >= 5, ]

# 使用 CytoTRACE 进行分析
results <- cytotrace2(exp, 
                      species = "human",
                      ncores = 6 # 设置CPU核心数
                      )
save(results, file="Data/CytoTRACE2_results.Rda")

# 提取细胞类型注释信息，并将其转换为字符向量
phenotype <- sce$celltype
phenotype <- as.character(phenotype)
# 将细胞类型注释的名字设置为元数据中的行名
names(phenotype) <- rownames(sce@meta.data)
phenotype <- as.data.frame(phenotype)

# 绘图
plots <- plotData(cytotrace2_result = results,
                  annotation = phenotype,
                  expression_data = exp,
                  is_seurat = FALSE)

sce$CytoTRACE2_Score <- results$CytoTRACE2_Score
sce$CytoTRACE2_Relative <- results$CytoTRACE2_Relative

# UMAP图
FeatureDimPlot(
  srt = sce,
  features = c("CytoTRACE2_Relative"),
  reduction ="UMAP",
  pt.size = 1,
  theme_use ="theme_blank",
  theme_args = list(
    legend.key.size = grid::unit(0.7, 'cm'), # 调整colorbar的宽度
    plot.title = element_blank()
  )
)

# 箱线图
df <- data.frame(phenotype = sce$celltype,
                 score = sce$CytoTRACE2_Score)

cols <- c("#3F2B7A", "#2C7FB8", "#63B58A", "#e3e9bc", "#f8df5a", "#ffd17e" ,"#db817b", "#aa1642")
ggplot(df, aes(x = phenotype, y = score, color = phenotype, fill = phenotype)) +
  geom_boxplot(
    width = 0.55, alpha = 0.25, outlier.shape = NA,
    linewidth = 1.0
  ) +
  geom_jitter(
    width = 0.12, height = 0, size = 1.5, alpha = 0.8
  ) +
  scale_color_manual(values = cols, guide = "none") +
  scale_fill_manual(values = cols, guide = "none") +
  # scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2), expand = expansion(mult = c(0, 0.02))) +
  labs(
    x = "Cell phenotypes",
    y = "Predicted ordering by CytoTRACE"
  ) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(size = 16),
    axis.text  = element_text(size = 12, color = "black"),
    axis.line  = element_line(linewidth = 1.2, color = "black")
  )

subgroups <- sce
save(subgroups, file="./Data/subgroups.Rda")


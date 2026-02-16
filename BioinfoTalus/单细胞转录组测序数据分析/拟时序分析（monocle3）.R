library(Seurat)
library(tidyverse)
library(monocle3)
library(stringr)
library(tibble)
library(ggplot2)
library(viridis)
library(patchwork)
library(grid)

# 不能对明显没有生物学关联的细胞进行拟时序分析
# 例如上皮细胞肯定不可能发育成免疫细胞，虽然算法也能跑，但结果无意义
# 一般会在亚群数据上进行拟时序分析，这里选取处理好的亚群数据进行分析（处理过程见“亚群分析.R”）
load("Data/subgroups.Rda")

# 赋值给临时变量，以便于后续无需修改变量名
pbmc <- subgroups
# 细胞类型降维图
DimPlot(pbmc, group.by = "celltype", label = T)


# 获取表达矩阵
data <- GetAssayData(pbmc, assay = 'RNA', layer  = 'counts')
# 细胞注释信息
cell_metadata <- pbmc@meta.data
# 基因名
gene_annotation <- data.frame(gene_short_name = rownames(data), row.names = rownames(data))
# 创建一个新的 cell_data_set 对象
cds <- new_cell_data_set(data, cell_metadata = cell_metadata, gene_metadata = gene_annotation)
# 预处理cds
cds <- preprocess_cds(cds, method = "PCA")
# 降维
cds <- reduce_dimension(cds, reduction_method = "UMAP",preprocess_method = 'PCA')
# 画图
plot_cells(cds, reduction_method="UMAP", color_cells_by="seurat_clusters", show_trajectory_graph = FALSE) + ggtitle('cds.umap')


# 将seurat对象的UMAP导入
int.embed <- Embeddings(pbmc, reduction = "umap")
# 排序
int.embed <- int.embed[rownames(cds@int_colData$reducedDims$UMAP),]
# 导入
cds@int_colData$reducedDims$UMAP <- int.embed
# 画图
plot_cells(cds, reduction_method="UMAP", color_cells_by="seurat_clusters", show_trajectory_graph = FALSE) + ggtitle('seurat.umap')


# 聚类分区，不同分区的细胞会进行单独的轨迹分析
cds <- cluster_cells(cds, resolution = 1e-3)
# 画图
plot_cells(cds, color_cells_by = "partition", show_trajectory_graph = FALSE) + ggtitle("partition")

# 构建细胞轨迹
cds <- learn_graph(cds, 
                   learn_graph_control = list(euclidean_distance_ratio = 0.8), # 如果希望分化路径更复杂可以调小euclidean_distance_ratio
                   use_partition = TRUE # 如果希望分化路径为一个整体可设置为FALSE
                  )
# 画图
plot_cells(cds, color_cells_by = "partition",label_groups_by_cluster = FALSE, label_leaves = FALSE, label_branch_points = FALSE)


# 发育轨迹（拟时序）排列细胞
cds <- order_cells(cds) # 如果不能交互选定发育起点，请尝试如下解决方案

# 两种解决方案
# 方案一：直接用某个cluster作为发育起点
# root_cells <- colnames(cds)[colData(cds)$seurat_clusters == "4"] # 将4换成你想指定的cluster
# cds <- order_cells(cds, root_cells = root_cells)

# 方案二：手动指定发育节点
# g <- principal_graph(cds)[["UMAP"]]
# node_names <- igraph::V(g)$name
# 
# aux <- principal_graph_aux(cds)[["UMAP"]]
# node_pos <- as.data.frame(t(aux$dp_mst))  # 行=节点，列=UMAP1/UMAP2
# colnames(node_pos) <- c("x","y")
# node_pos$name <- rownames(node_pos)
# 
# node_pos <- node_pos[node_pos$name %in% node_names, ]
# 
# p <- plot_cells(cds, show_trajectory_graph = TRUE, cell_size = 0.15)
# p + geom_text(data = node_pos, aes(x = x, y = y, label = name),
#               size = 2.5, color = "red")
# # 根据图中标注的节点名称指定发育起始点
# cds <- order_cells(cds, root_pr_nodes = "Y_14") # 把Y_14换成你想要的端点

# 画图
plot_cells(cds, color_cells_by = "pseudotime", label_cell_groups = FALSE, 
           label_leaves = FALSE,  label_branch_points = FALSE)
save(cds, file = "Data/cell developmental trajectories.Rda")

expr_mat <- counts(cds)
# 至少在 10% 细胞中表达（可根据需要调整阈值）
keep_genes <- rowMeans(expr_mat > 0) > 0.10  
sum(keep_genes)       # 看看还剩多少基因
cds <- cds[keep_genes, ]

# 寻找拟时轨迹差异基因
Track_genes <- graph_test(cds, neighbor_graph="knn", cores=16, verbose = TRUE)
# 导出
write.csv(Track_genes, "Data/Track_genes.csv", row.names = F)


# 拟时基因热图
genes <- row.names(subset(Track_genes, morans_I > 0.5))
# 选取合适的clusters
num_clusters = 3
# 画图
pt.matrix <- exprs(cds)[match(genes,rownames(rowData(cds))),order(pseudotime(cds))]
pt.matrix <- t(apply(pt.matrix,1,function(x){smooth.spline(x,df=3)$y}))
pt.matrix <- t(apply(pt.matrix,1,function(x){(x-mean(x))/sd(x)}))
rownames(pt.matrix) <- genes
mycol = rev(RColorBrewer::brewer.pal(11, "Spectral"))
ComplexHeatmap::Heatmap(
  pt.matrix, name = "z-score", show_row_names = T, show_column_names = F,
  col = circlize::colorRamp2(seq(from=-2,to=2,length=11), mycol),
  row_names_gp = gpar(fontsize = 6), row_title_rot= 0, km = num_clusters, 
  cluster_rows = TRUE, cluster_row_slices = FALSE, cluster_columns = FALSE,use_raster=F
)
dev.off()


# 基因展示,选取morans_I排名前10的基因，可自定义
genes = rownames(top_n(Track_genes, n=10, morans_I))[3]
# 画图（画一个）
monocle3::plot_genes_in_pseudotime(cds[genes,], color_cells_by="celltype", min_expr=0.5) #min_expr 设置了基因表达的最低阈值，只有表达量 ≥ 0.5 的细胞才会在图中显示
plot_cells(cds, genes=genes, show_trajectory_graph=FALSE,
           label_cell_groups=FALSE,  label_leaves=FALSE)

# 寻找共表达基因模块
genelist <- row.names(subset(Track_genes, morans_I > 0.1))
gene_module <- find_gene_modules(cds[genelist,], resolution=1e-2, cores = 6)
table(gene_module$module)
# write.csv(gene_module, "Data/PseudotimeGenes_Module.csv", row.names = F)

# 热图
cell_group <- tibble(cell=row.names(colData(cds)), cell_group=colData(cds)$celltype)
agg_mat <- aggregate_gene_expression(cds, gene_module, cell_group)
row.names(agg_mat) <- str_c("Module ", row.names(agg_mat))
pheatmap::pheatmap(agg_mat, scale="column", clustering_method="ward.D2")

# 散点图（基因模块得分）
ME.list <- lapply(1:length(unique(gene_module$module)), function(i){subset(gene_module,module==i)$id})
# 过滤ME.list，只保留存在的基因
ME.list <- lapply(ME.list, function(module_genes) {
  module_genes[module_genes %in% rownames(pbmc)]
})
names(ME.list) <- paste0("module", 1:length(unique(gene_module$module)))


# pbmc <- AddModuleScore(pbmc, features = ME.list, name = "module")
# 计算模块分数（替代AddModuleScore）
expr_data <- as.matrix(GetAssayData(pbmc, slot = "data"))

# 计算每个模块的z-score
module_scores <- map_dfc(ME.list, function(genes) {
  module_expr <- expr_data[genes, , drop = FALSE]
  colMeans(module_expr)  # 计算平均表达
}) %>%
  as.data.frame() %>%
  mutate_all(scale)  # 标准化为z-score

# 添加到Seurat对象
colnames(module_scores) <- paste0("module", seq_along(ME.list))
pbmc <- AddMetaData(pbmc, metadata = module_scores)


p <- FeaturePlot(pbmc, features = paste0("module", 1), ncol = 2) # paste0("module", 1)表示只画第一个模块
p <- p + plot_layout()&scale_color_viridis_c(option = "C")
p


# 将临时变量赋值回原始变量
Tcell_subgroup <- pbmc
save(Tcell_subgroup, "Data/subgroups.Rda")


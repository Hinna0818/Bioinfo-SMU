library(Seurat)
library(data.table)
library(stringr)
library(tibble)
library(ggplot2)
library(patchwork)
library(monocle)
library(tidyverse)

# 不能对明显没有生物学关联的细胞进行拟时序分析
# 例如上皮细胞肯定不可能发育成免疫细胞，虽然算法也能跑，但结果无意义
# 一般会在亚群数据上进行拟时序分析，这里选取处理好的亚群数据进行分析（处理过程见“亚群分析.R”）
load("Data/subgroups.Rda")

# 赋值给临时变量，以便于后续无需修改变量名
pbmc <- subgroups

# 创建CellDataSet对象
# CellDataSet对象是Monocle用于存储单细胞转录组数据的核心数据结构
#获取表达矩阵
data <- GetAssayData(pbmc, assay = "RNA", layer = "counts")
#获取细胞注释信息，表型信息
pd <- new('AnnotatedDataFrame', data = pbmc@meta.data)
#获取基因名
fData <- data.frame(gene_short_name = row.names(data), row.names = row.names(data))
fd <- new('AnnotatedDataFrame', data = fData)

# 构建CellDataSet对象
monocle_cds <- newCellDataSet(as(as.matrix(data),"sparseMatrix"),
                              phenoData = pd,
                              featureData = fd,
                              lowerDetectionLimit = 0.5,
                              expressionFamily = negbinomial.size())

# 数据预处理，估计size factor和离散度，类似归一化，标准化
# 运行时间较长，可修改核心数
monocle_cds <- estimateSizeFactors(monocle_cds)
monocle_cds <- estimateDispersions(monocle_cds, cores=12)


# 细胞过滤
# 检测在至少0.1表达量以上的基因，这些基因会被保留用于后续分析
monocle_cds <- detectGenes(monocle_cds, min_expr = 0.1)
# 输出一些基因特征信息
print(head(fData(monocle_cds)))

# 筛选出关键的高变异基因用于后续分析
{
  mycds=monocle_cds # 复制数据集
  disp_table <- dispersionTable(mycds) # 获取每个基因的离散度
  # 筛选出平均表达量大于0.1且离散度高于模型拟合值的基因
  disp.genes <- subset(disp_table, mean_expression >= 0.1 & dispersion_empirical >= 1 * dispersion_fit)$gene_id
  mycds <- setOrderingFilter(mycds, disp.genes)
}
# disp.genes在2000左右较好
# 黑点表示的就是筛选出来用于后续分析的差异基因
plot_ordering_genes(mycds)

# 基于关键基因进行降维分析，使用DDRTree算法，降低维度到2个主成分
# 减去“无趣的”变异源的影响，以减少它们对集群的影响
mycds <- reduceDimension(mycds, max_components = 2,
                         reduction_method  = 'DDRTree', residualModelFormulaStr = "~orig.ident")

# 对细胞进行拟时序排序，以时间轨迹排序细胞
# 如果报错：`nei()` was deprecated in igraph 2.1.0 ...
# 需要igraph版本小于2.1.0，建议安装igraph2.0.3，若安装时编译失败则安装2.0.1
# 不要安装更低的版本，否则其他流程可能会出问题
mycds <- orderCells(mycds)

# 算法无法确定细胞分化的起点，需人工设定（根据绘图结果选择根节点）
mycds <- orderCells(mycds,root_state = 3) # Naïve_T_cells为分化起点

# 画图
# cell_trajectory
# color_by参数可选State，Pseudotime，celltype，orig.ident
plot_cell_trajectory(mycds, color_by = "State")
plot_cell_trajectory(mycds, color_by = "Pseudotime")
plot_cell_trajectory(mycds, color_by = "celltype")
plot_cell_trajectory(mycds, color_by = "orig.ident")
# 树形图
plot_complex_cell_trajectory(mycds, x = 1, y = 2, color_by = "celltype")
# 细胞密度图
ggplot(pData(mycds),aes(Pseudotime,colour = celltype,fill = celltype)) +geom_density(bw = 0.5, size = 1, alpha = 0.5)+theme_classic()
# 指定基因的表达变化
plot_genes_in_pseudotime(mycds["CCR7"], color_by="State")
plot_genes_in_pseudotime(mycds["CCR7"], color_by="Pseudotime")
plot_genes_in_pseudotime(mycds["CCR7"], color_by="celltype")

plot_genes_jitter(mycds["CCR7"],grouping="State",color_by="State")
plot_genes_violin(mycds["CCR7"],grouping="State",color_by="State")
plot_genes_in_pseudotime(mycds["CCR7"],color_by="State")

pData(mycds)$CNN1 = log2(exprs(mycds)["CCR7",] +1)
plot_cell_trajectory(mycds,color_by = "CCR7") + 
  scale_color_continuous(type = "viridis")

# 将结果保存至seurat对象
pdata <- Biobase::pData(mycds)
pbmc <- AddMetaData(pbmc, metadata = pdata[,c("Pseudotime","State")])

# 通过monocle2算法寻找拟时差异基因
Time_diff <- differentialGeneTest(mycds, cores = 10,
                                  fullModelFormulaStr = "~sm.ns(Pseudotime)")
write.csv(Time_diff, "./Data/Time_diff_all.csv", row.names = F)
# 画图，按qval排序，选取前100个
Time_genes <- Time_diff[order(Time_diff$qval), "gene_short_name"][1:100]
# num_clusters按行聚类，聚为多少类
p <- plot_pseudotime_heatmap(mycds[Time_genes,], num_clusters=6, 
                             show_rownames=T, return_heatmap=T)
p
# 保存
hp.genes <- p$tree_row$labels[p$tree_row$order]
Time_diff_sig <- Time_diff[hp.genes, c("gene_short_name", "pval", "qval")]
write.csv(Time_diff_sig, "./Data/Time_diff_sig.csv", row.names = F)

subgroups <- pbmc
save(subgroups, file="./Data/subgroups.Rda")





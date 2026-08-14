library(Seurat)
library(png)
library(tidyverse)
library(ggpubr)
library(patchwork)
library(viridis)
library(RColorBrewer)

# 反卷积即空转数据的注释，旨在推断出每个空间位置上不同细胞类型的组成比例
# 需要配对或近似的单细胞RNA-seq数据作为先验
# 由于空转和单转的示例数据均为结直肠癌样本数据，可用单转数据作为参照进行反卷积
load("Data/stRNA.Rda") # 读入空转数据
load("Data/pbmc.Rda") # 读入单转数据

# 确定主成分个数
# 确定与每个 PC 的百分比   
pct <- stRNA [["pca"]]@stdev / sum(stRNA [["pca"]]@stdev) * 100
# 计算每个 PC 的累计百分比
cumu <- cumsum(pct)
cumu

pcs = 1:38

# 寻找marker基因（差异基因）
markers_features <- FindAllMarkers(
  stRNA, 
  assay = "SCT",
  only.pos = TRUE,          # 只保留高表达基因
  min.pct = 0.25,           # 在至少25%区域细胞中表达
  logfc.threshold = 0.25     # 最小表达差异
)
# 提取每个类的前5个Marker
markers_features <- markers_features %>%
  group_by(cluster) %>%
  top_n(n = 5, wt = avg_log2FC)

# 单转数据细胞注释时所用的marker基因
marker <- list("Mast_cells" = c("TPSAB1", "GATA2", "MS4A2"),
               "Smooth_muscle_cells" = c("TAGLN", "ACTA2", "MYH11"),
               "Myeloid_cells" = c("LYZ", "CD14", "CD68", "CSF1R"),
               "Endothelia_cells" = c("PECAM1", "CLDN5", "VWF"),
               "Epithelial_cells"=c("KRT8", "CLDN4","TSPAN8"),
               "Fibroblasts"=c("COL1A1", "DCN", "LUM"),
               "B_cells"=c("HLA-DRA", "MS4A1"),
               "Plasma_cells"=c("MZB1", "JCHAIN"),
               "T_cells"=c("CD3D", "CD2", "TRBC2"),
               "NE" = c("FCGR3B", "CSF3R", "CXCR2", "G0S2")
)
marker_sc <- unique(as.vector(unlist(marker)))
# 合并去重
markers_concat <- unique(c(unlist(markers_features["gene"]), marker_sc))

# 寻找跨数据集锚点，建立单细胞数据和空转数据之间的基因表达对应关系，将单细胞分辨率映射到空间位置
anchors <- FindTransferAnchors(reference=pbmc,
                               query=stRNA,
                               reference.assay="SCT",
                               query.assay="SCT",
                               normalization.method="SCT",
                               features=markers_concat,
                               verbose=T)

predictions.assay <- TransferData(
  anchorset = anchors,
  refdata = pbmc$celltype,                      # 要转移的参考数据注释
  prediction.assay = T,                         # 以Assay形式存储预测结果
  weight.reduction = stRNA[["pca"]],            # 使用pca降维后的数据空间进行计算
  dims = pcs,                                  # 根据做pca时的方差解释率确定
  k.weight = min(round(ncol(stRNA) * 0.05), 50) # 加权计算的邻居数，一般不超过50
)
# 将预测结果写入Seurat_obj
stRNA[["predictions"]]<-predictions.assay
DefaultAssay(stRNA) <- "SCT"

# 将反卷积结果写入meta.data
deconv_mat <- as.matrix(stRNA[["predictions"]]@data)
deconv_df  <- as.data.frame(t(deconv_mat))
deconv_df  <- deconv_df[rownames(stRNA@meta.data), , drop = FALSE]
stRNA@meta.data <- cbind(stRNA@meta.data, deconv_df)

# 绘制细胞空间分布图
SpatialFeaturePlot(stRNA, 
                   features = 'T-cells', #要展示的细胞
                   pt.size = 5,
                   alpha = 0.6
              
)

save(stRNA, file="Data/stRNA.Rda")



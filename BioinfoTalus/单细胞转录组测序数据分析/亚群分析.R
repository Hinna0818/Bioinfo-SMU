library(Seurat)
library(patchwork)
library(ggplot2)
library(clustree)
library(cowplot)
library(tidyverse)
library(SCpubr)
library(GSEABase)
library(harmony)
library(plyr)
load("Data/pbmc.Rda")

####亚群提取####
# 先大体看一下数据情况
DimPlot(pbmc, reduction = "umap", label = T)

# 查看具体分群
table(pbmc@meta.data[["celltype"]])

# 提取自己感兴趣的亚群
{
  subgroups <- subset(pbmc, celltype=="T_cells") #也可以提取某个簇，seurat_clusters==c("0","9"）
}

# 去掉之前的降维结果数据
subgroups[["umap.harmony"]] <- NULL
subgroups[["tsne.harmony"]] <- NULL
subgroups[["harmony"]] <- NULL
subgroups[["umap"]] <- NULL
subgroups[["tsne"]] <- NULL
subgroups[["pca"]] <- NULL

# 后续流程与一般分析相同
# 标准化
subgroups = subgroups %>%
  NormalizeData() %>%
  FindVariableFeatures() %>%
  ScaleData()
subgroups <- SCTransform(subgroups)

#PCA
subgroups <- RunPCA(subgroups, verbose = F)

#选取合适的PC
#主成分累积贡献大于90%,选择拐点
ElbowPlot(subgroups, ndims = 50)
# dev.off()
#确定与每个 PC 的百分比   
pct <- subgroups [["pca"]]@stdev / sum( subgroups [["pca"]]@stdev) * 100
#计算每个 PC 的累计百分比
cumu <- cumsum(pct)
cumu

#设置PC
pcs = 1:44

seq = seq(0.1,2,by=0.1)
subgroups <- FindNeighbors(subgroups, reduction = "pca",  dims = pcs) 
for (res in seq){
  subgroups = FindClusters(subgroups, resolution = res, algorithm = 4)
}

#画图
p1 = clustree(subgroups, prefix = "SCT_snn_res.")+coord_flip()
p = p1+plot_layout(widths = c(3,1))
p

# 降维聚类，reduction参数设置取决于先前去除批次效应的算法
subgroups <- FindNeighbors(subgroups,  dims = pcs) %>% FindClusters(resolution = 0.6, algorithm = 4) # 根据聚类图选择合适的分别率
subgroups <- RunUMAP(subgroups, dims = pcs, reduction.name = "umap")
subgroups <- RunTSNE(subgroups, dims = pcs, reduction.name = "tsne")


#画图
DimPlot(subgroups, reduction = "umap", label = T)
dev.off()

save(subgroups, file="Data/subgroups.Rda")


####亚群注释####
# 寻找marker
DefaultAssay(subgroups) = "RNA"
subgroups.markers.RNA <- FindAllMarkers(subgroups, only.pos = TRUE, logfc.threshold = 1)
write.csv(subgroups.markers.RNA, file="Data/subgroups_markers.RNA.csv")

# 创建marker集合
# 亚群注释比大群复杂，因为亚群之间一般都比较相似，难以区分，而且相关文献较少
# 如果亚群难以区分可以注释的模糊一些
# 例如这里对T细胞没有细分CD8 T和CD4 T而是统一注释成效应T细胞（Effector_T_cells）
marker <- list("Naïve_T_cells"=c("CCR7", "LEF1", "TCF7"),
               "Effector_T_cells"=c("GZMB", "NKG7", "GNLY"),
               "Regulatory_T_cells"=c("FOXP3", "IL2RA")
)

do_DotPlot(sample = subgroups, features = marker, dot.scale = 10,legend.length = 50,
           legend.framewidth = 2, font.size =10)

#另一种颜色气泡图
DotPlot(subgroups, features = unique(as.vector(unlist(marker))), scale = FALSE, cols = "RdYlBu")+RotatedAxis()

# 如果不好注释，可调整聚类分辨率重新聚类（仅需要运行下面的代码即可）
# 例如某个簇同时表达两种细胞类型的marker，则可以尝试提高聚类分辨率，看能否将其聚为不同的两类再进行注释
DefaultAssay(subgroups) = "SCT"
subgroups <- FindClusters(subgroups, resolution = 0.8, algorithm = 4)
# 除了看marker的显著程度，还可以观察两个簇在umap降维散点图中的位置
# 如果两个簇相距较近则细胞类型可能比较相似，相距较远则细胞类型可能相差较大
DimPlot(subgroups, reduction = "umap.harmony", label = T)

subgroups$celltype <- recode(subgroups@meta.data$seurat_clusters,
                             "1" = "Regulatory_T_cells",
                             "2" = "Effector_T_cells",
                             "3" = "Effector_T_cells",
                             "4" = "Naïve_T_cells",
                             "5" = "Effector_T_cells"
)

#分组
Idents(subgroups) = "seurat_clusters"
Idents(subgroups) = "celltype"
#画图
DimPlot(subgroups, reduction = "umap", label = T, label.size = 3.5)+theme_classic()+theme(panel.border = element_rect(fill=NA,color="black", size=0.5, linetype="solid"),
                                                                                          legend.position = "right")
DimPlot(subgroups, reduction = "tsne", label = T, label.size = 3.5)+theme_classic()+theme(panel.border = element_rect(fill=NA,color="black", size=0.5, linetype="solid"),legend.position = "right")

save(subgroups, file="Data/subgroups.Rda")





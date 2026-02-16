library(Seurat)
library(data.table)
library(stringr)
library(tibble)
library(ggplot2)
library(patchwork)
library(dplyr)
library(tidyverse)
library(jsonlite)
library(CellChat)
load("Data/stRNA.Rda")

# 获取空间坐标信息
spatial.loc = GetTissueCoordinates(stRNA, scale = NULL, 
                                   cols = c("imagerow", "imagecol")) 
# 重命名列以符合CellChat要求
colnames(spatial.loc) <- c("y", "x")  # CellChat要求x, y坐标

json <- fromJSON(txt = "Data/10x Visium/GSM8594561/spatial/scalefactors_json.json")
# 没有json文件时运行这段代码
# json <- stRNA@images[["image"]]@scale.factor

# 缩放因子列表，供细胞通讯分析使用
scale.factor <- list(spot.diameter = 65, # 采样光斑大小（10x数据为65）
                     spot = json$spot_diameter_fullres,
                     fiducial = json$fiducial_diameter_fullres,
                     hires = json$tissue_hires_scalef
)

# 根据聚类结果定义分组信息
stRNA@meta.data$cluters <- paste0("C", Idents(stRNA))
# 提取归一化表达矩阵（使用SCT assay）
data.input <- GetAssayData(stRNA, assay = "SCT", slot = "data")

# 创建CellChat对象
cellchat <- createCellChat(object = data.input,
                           meta = stRNA@meta.data,
                           group.by = "cluters", #通过 group.by 定义分组
                           datatype = "spatial",
                           scale.factors = scale.factor
)
# 添加空间坐标到CellChat对象
cellchat <- setSpatialCoordinates(cellchat, spatial.loc = spatial.loc)

# 后续流程与单转一致
# 设置配体受体交互数据库 
CellChatDB <- CellChatDB.human #如果是小鼠的话使用内置“CellChatDB.mouse”数据

# 自分泌/旁分泌信号相互作用
# 细胞外基质（ECM）受体相互作用
# 细胞-细胞接触相互作用
showDatabaseCategory(CellChatDB)

# 添加参考数据库
# 可以选择数据库子集用于分析
# CellChatDB <- subsetDB(CellChatDB, search = "Secreted Signaling"),选择自分泌/旁分泌信号相互作用进行分析
cellchat@DB <- CellChatDB

# 多线程
future::plan("multisession", workers = 6)

# 提取细胞通讯信号基因
cellchat <- subsetData(cellchat)
# 识别过表达的配体、受体基因
cellchat <- identifyOverExpressedGenes(cellchat)
# 识别过表达的配体-受体对
cellchat <- identifyOverExpressedInteractions(cellchat)
# 数据校正（可选）
# 根据高度可信的实验验证的PPI网络中定义的基因表达值来平滑基因的表达值
cellchat <- projectData(cellchat, PPI.human)
# 计算通信概率并推断cellchat网络,如果用非校正数据，raw.use = T
cellchat <- computeCommunProb(cellchat, raw.use = F)
cellchat <- filterCommunication(cellchat, min.cells = 10)

# 在信号通路级别推断细胞-细胞通信
cellchat <- computeCommunProbPathway(cellchat)

# 提取 保存结果
df.net <- subsetCommunication(cellchat)
write.csv(df.net,"./Data/df.net.csv")

# 信号通路级别
df.netP <- subsetCommunication(cellchat, slot.name = "netP")
write.csv(df.netP, "./Data/Pathway.csv", row.names = F)

# 计算整合的细胞通信网络
cellchat <- aggregateNet(cellchat)

# 保存结果
save(cellchat, file = "./Data/cellchat.Rda")


# 画图
# 总
groupSize <- as.numeric(table(cellchat@idents))
par(xpd = TRUE)
netVisual_circle(cellchat@net$count, vertex.weight = groupSize, weight.scale = T, # Number of interactions
                 label.edge= F)
netVisual_circle(cellchat@net$weight, vertex.weight = groupSize, weight.scale = T, 
                 label.edge= F) # Interaction weights/strength
dev.off()

# 总热图
p3 <- netVisual_heatmap(cellchat)
p3
p4 <- netVisual_heatmap(cellchat, measure = "weight", color.heatmap = "Reds")
p4

# 分开展示
mat <- cellchat@net$weight
{
  mat_t <- matrix(0, nrow = nrow(mat), ncol = ncol(mat), dimnames = dimnames(mat))
  mat_t[1, ] <- mat[1, ] # 第一个细胞
  par(xpd = TRUE)
  netVisual_circle(mat_t, vertex.weight = groupSize, weight.scale = T, 
                   edge.weight.max = max(mat))
}
dev.off()


# 信号通路展示
mypathways <- cellchat@netP$pathways[1,] # 展示第一个信号通路

{
  par(xpd = TRUE)
  netVisual_aggregate(cellchat,signaling = mypathways, layout = "circle")
}
dev.off()

# 和弦图
{
  netVisual_aggregate(cellchat, signaling = mypathways, layout = "chord")
}
dev.off()
# 层级图
{
  netVisual_aggregate(cellchat, signaling = mypathways, layout = "hierarchy")
}
# 空间位置图
{
  netVisual_aggregate(cellchat, signaling = mypathways, layout = "spatial")
}
dev.off()

# 热图
{
  par(xpd = TRUE)
  p <- netVisual_heatmap(cellchat, signaling = mypathways, color.heatmap = "Reds")
  plot(p)
}
dev.off()

# 信号通路内的配体-受体相互作用展示
for(pathways.show in mypathways){
  # 配体-受体贡献度展示
  netAnalysis_contribution(cellchat, signaling = pathways.show)
  pairLR <- extractEnrichedLR(cellchat, signaling = pathways.show, geneLR.return = FALSE)$interaction_name
  for(LR.show in pairLR){
    # 网络图展示细胞间的配体-受体互作
    netVisual_individual(cellchat, signaling = pathways.show, pairLR.use = LR.show, layout = "circle")
  }
  for(LR.show in pairLR){
    # 和弦图展示细胞间的配体-受体互作
    netVisual_individual(cellchat, signaling = pathways.show, pairLR.use = LR.show, layout = "chord")
  }
}
dev.off()

# 显示所有的细胞间配体-受体互作
netVisual_bubble(cellchat, sources.use = 1:length(levels(cellchat@idents)), 
                 targets.use = 1:length(levels(cellchat@idents)), remove.isolate = FALSE)


# 指定细胞间的配体-受体互作
netVisual_bubble(cellchat, sources.use = 1:3, targets.use = 4:5, remove.isolate = FALSE) #sources.use指定配体，targets.use指定受体


# 指定细胞和信号通路的配体-受体互作
netVisual_bubble(cellchat, sources.use = 1:3, targets.use = 4:5, signaling = c("CCL","TNF"), remove.isolate = FALSE) #signaling指定信号通路

# 指定细胞和信号通路的特定配体-受体互作
pairLR.use <- c("CCL3_CCR1","CCL4_CCR5","CCL5_CCR3","TNF_TNFRSF1A","TNF_TNFRSF1B") #指定配体受体对，配体_受体
pairLR.use <- data.frame(interaction_name = pairLR.use)
netVisual_bubble(cellchat, sources.use = 1:3, targets.use = 4:5, pairLR.use =  pairLR.use, remove.isolate = FALSE)

# 配体、受体基因表达小提琴图
plotGeneExpression(cellchat, signaling = "CCL")
plotGeneExpression(cellchat, signaling = "CCL", enriched.only = FALSE)

# 细胞通信网络系统分析
# 计算每个细胞组的多个网络中心测量
# 随时识别细胞间通信网络中占主导地位的发送者、接收者、调解者和影响者。
net_Centrality <- netAnalysis_computeCentrality(cellchat, slot.name = "netP")
for(pathways.show in mypathways){
  netAnalysis_signalingRole_network(net_Centrality, signaling=pathways.show,
                                    width=8,height=2.5,font.size=10)
}
dev.off()




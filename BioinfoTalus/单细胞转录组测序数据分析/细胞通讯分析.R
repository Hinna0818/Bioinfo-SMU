library(Seurat)
library(data.table)
library(stringr)
library(tibble)
library(ggplot2)
library(patchwork)
library(dplyr)
library(tidyverse)
library(CellChat)
load("Data/pbmc.Rda")


# 如果需要纳入亚群一同进行细胞通讯分析，则先运行如下代码
# # 将亚群注释结果映射回主文件
# # 确定subgroups文件来自主文件
# load("Data/subgroups.Rda")
# all(colnames(subgroups) %in% colnames(pbmc))
# # 提取亚群注释
# anno <- subgroups@meta.data[, "celltype", drop = FALSE]
# # 找到主文件中亚群所属的细胞类型
# cells <- rownames(
#   pbmc@meta.data[pbmc@meta.data$celltype == "T_cells", ] # 这里改成亚群在主文件中所属的细胞类型
# )
# # 取交集防止不一致T
# common_cells <- intersect(cells, rownames(anno))
# # 映射
# pbmc@meta.data$celltype <- as.character(pbmc@meta.data$celltype)
# sub_labels <- as.character(anno[common_cells, "celltype"])
# pbmc@meta.data[common_cells, "celltype"] <- sub_labels
# pbmc@meta.data$celltype <- factor(pbmc@meta.data$celltype)


# 创建CellChat对象
cellchat = createCellChat(object = pbmc,
                          group.by = "celltype") # 通过 group.by 定义分组

# 设置配体受体交互数据库 
CellChatDB <- CellChatDB.human # 如果是小鼠的话使用内置“CellChatDB.mouse”数据


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
save(cellchat, file = "Data/cellchat_addsub.Rda")

# 数据校正（可选）
# 根据高度可信的实验验证的PPI网络中定义的基因表达值来平滑基因的表达值
#  cellchat <- projectData(cellchat, PPI.human)
# 计算通信概率并推断cellchat网络,如果用非校正数据，raw.use = T
load("Data/cellchat_addsub.Rda")
options(future.globals.maxSize = 4 * 1024^3)
cellchat <- computeCommunProb(cellchat, raw.use = T)
cellchat <- filterCommunication(cellchat, min.cells = 10)

# 在信号通路级别推断细胞-细胞通信
cellchat <- computeCommunProbPathway(cellchat)

# 提取 保存结果
df.net <- subsetCommunication(cellchat)
write.csv(df.net,"Data/df.net_addsub.csv")

# 信号通路级别
df.netP <- subsetCommunication(cellchat, slot.name = "netP")
write.csv(df.netP, "Data/Pathway_addsub.csv", row.names = F)

# 计算整合的细胞通信网络
cellchat <- aggregateNet(cellchat)

# 保存结果
save(cellchat, file = "Data/cellchat_addsub.Rda")


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
mypathways <- cellchat@netP$pathways[5] # 展示第一个信号通路

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
dev.off()

# 热图
{
  par(xpd = TRUE)
  p <- netVisual_heatmap(cellchat, signaling = mypathways, color.heatmap = "Reds")
  plot(p)
}
dev.off()

#信号通路内的配体-受体相互作用展示
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






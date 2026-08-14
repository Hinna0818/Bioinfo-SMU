# 实验二：加权基因共表达网络分析（WGCNA）

## 实验简介

WGCNA (Weighted Gene Co-expression Network Analysis) 是一种系统生物学方法，用于描述不同样本间基因关联模式，识别高度协同变化的基因模块。

---

## 实验目的

- 理解基因共表达网络的概念
- 掌握 WGCNA 的分析流程
- 学会识别基因模块
- 了解模块与表型的关联分析

---

## 理论背景

### WGCNA 原理

WGCNA 通过计算基因间的相关性，构建加权网络，并识别功能相关的基因模块。

### 关键步骤

1. **计算相似性矩阵**：计算基因间的相关系数
2. **构建邻接矩阵**：使用软阈值将相关系数转换为连接强度
3. **拓扑重叠矩阵（TOM）**：衡量基因间的连接相似性
4. **层次聚类**：识别基因模块
5. **模块-表型关联**：分析模块与表型的相关性

---

## 实验步骤

### 1. 数据准备和预处理

```r
# 加载 WGCNA 包
library(WGCNA)
library(ggplot2)

# 允许多线程
enableWGCNAThreads()

# 读取表达数据
# 行为基因，列为样本
expr_data <- read.csv("expression_data.csv", row.names = 1)
expr_data <- t(expr_data)  # 转置：行为样本，列为基因

# 检查缺失值
gsg <- goodSamplesGenes(expr_data, verbose = 3)

# 过滤低表达基因
expr_data_filtered <- expr_data[, gsg$goodGenes]
```

### 2. 选择软阈值

```r
# 计算不同软阈值下的网络拓扑
powers <- c(c(1:10), seq(from = 12, to = 20, by = 2))
sft <- pickSoftThreshold(expr_data_filtered,
                         powerVector = powers,
                         verbose = 5)

# 可视化
par(mfrow = c(1, 2))
plot(sft$fitIndices[,1],
     -sign(sft$fitIndices[,3]) * sft$fitIndices[,2],
     xlab = "Soft Threshold (power)",
     ylab = "Scale Free Topology Model Fit, signed R^2",
     type = "n",
     main = "Scale independence")
text(sft$fitIndices[,1],
     -sign(sft$fitIndices[,3]) * sft$fitIndices[,2],
     labels = powers,
     col = "red")
abline(h = 0.90, col = "red")
```

### 3. 构建网络和识别模块

```r
# 一步法构建网络并识别模块
net <- blockwiseModules(expr_data_filtered,
                        power = 6,  # 选择的软阈值
                        TOMType = "unsigned",
                        minModuleSize = 30,
                        reassignThreshold = 0,
                        mergeCutHeight = 0.25,
                        numericLabels = TRUE,
                        pamRespectsDendro = FALSE,
                        saveTOMs = TRUE,
                        saveTOMFileBase = "TOM",
                        verbose = 3)

# 查看模块信息
table(net$colors)

# 转换为颜色标签
moduleColors <- labels2colors(net$colors)
```

### 4. 可视化基因树和模块

```r
# 绘制基因树和模块
plotDendroAndColors(net$dendrograms[[1]],
                    moduleColors[net$blockGenes[[1]]],
                    "Module colors",
                    dendroLabels = FALSE,
                    hang = 0.03,
                    addGuide = TRUE,
                    guideHang = 0.05)
```

### 5. 模块与表型关联

```r
# 读取表型数据
traits <- read.csv("traits.csv", row.names = 1)

# 计算模块特征基因（ME）
MEs <- moduleEigengenes(expr_data_filtered, moduleColors)$eigengenes
MEs <- orderMEs(MEs)

# 计算模块与表型的相关性
moduleTraitCor <- cor(MEs, traits, use = "p")
moduleTraitPvalue <- corPvalueStudent(moduleTraitCor, nrow(expr_data_filtered))

# 可视化
textMatrix <- paste(signif(moduleTraitCor, 2), "\n(",
                   signif(moduleTraitPvalue, 1), ")", sep = "")
dim(textMatrix) <- dim(moduleTraitCor)

par(mar = c(6, 8.5, 3, 3))
labeledHeatmap(Matrix = moduleTraitCor,
               xLabels = names(traits),
               yLabels = names(MEs),
               ySymbols = names(MEs),
               colorLabels = FALSE,
               colors = blueWhiteRed(50),
               textMatrix = textMatrix,
               setStdMargins = FALSE,
               cex.text = 0.5,
               zlim = c(-1,1),
               main = "Module-trait relationships")
```

### 6. 导出网络用于 Cytoscape

```r
# 选择感兴趣的模块
module <- "blue"
genes <- colnames(expr_data_filtered)[moduleColors == module]

# 计算 TOM
TOM <- TOMsimilarityFromExpr(expr_data_filtered[, genes],
                             power = 6)

# 导出边信息
cyt <- exportNetworkToCytoscape(TOM,
                                edgeFile = paste("CytoscapeInput-edges-", module, ".txt", sep=""),
                                nodeFile = paste("CytoscapeInput-nodes-", module, ".txt", sep=""),
                                weighted = TRUE,
                                threshold = 0.02)
```

---

## 结果分析

### 模块功能富集

```r
# 对感兴趣的模块进行GO富集分析
library(clusterProfiler)
library(org.Hs.eg.db)

# 提取模块基因
module_genes <- colnames(expr_data_filtered)[moduleColors == "blue"]

# GO富集分析
ego <- enrichGO(gene = module_genes,
                OrgDb = org.Hs.eg.db,
                keyType = "SYMBOL",
                ont = "BP",
                pAdjustMethod = "BH",
                pvalueCutoff = 0.05,
                qvalueCutoff = 0.05)

# 可视化
barplot(ego, showCategory = 10)
dotplot(ego, showCategory = 10)
```

---

## 生物学解释

### 模块的意义

- 同一模块内的基因可能：
  - 参与相同的生物学过程
  - 受相同的转录调控
  - 在相同的细胞器中发挥作用

### Hub 基因

- 模块内连接度最高的基因
- 可能是该生物学过程的关键调控因子
- 潜在的生物标志物或治疗靶点

---

## 作业要求

1. **基础分析**
   - 完成 WGCNA 分析流程
   - 识别基因模块
   - 分析模块与表型的关联

2. **进阶分析**
   - 对关键模块进行功能富集分析
   - 识别 Hub 基因
   - 验证 Hub 基因的表达模式

3. **报告撰写**
   - 详细记录分析步骤
   - 展示关键结果图表
   - 对模块功能进行生物学解读

---

## 文件位置

```
Grade4/computational_biology/experiments/Exp2/
├── WGCNA.Rmd         # R Markdown 报告
└── data/             # 数据文件
```

---

## 参考资料

1. Langfelder, P., & Horvath, S. (2008). WGCNA: an R package for weighted correlation network analysis. *BMC Bioinformatics*, 9(1), 559.

2. [WGCNA 官方教程](https://horvath.genetics.ucla.edu/html/CoexpressionNetwork/Rpackages/WGCNA/)

3. Zhang, B., & Horvath, S. (2005). A general framework for weighted gene co-expression network analysis. *Statistical Applications in Genetics and Molecular Biology*, 4(1).

---

## 提示

::: {.callout-tip title="软阈值选择"}
选择使 Scale-free topology fit R² 达到 0.8-0.9 的最小阈值。

:::
::: {.callout-tip title="模块大小"}
根据数据集大小调整 `minModuleSize` 参数，一般设为 30-50。

:::
::: {.callout-warning title="内存使用"}
WGCNA 分析可能需要大量内存，建议在分析前清理 R 环境。

:::
---

[← 上一个实验：PPI](exp1.md) | [返回课程主页](index.md) | [下一个实验：MCL & RWR →](exp3.md)

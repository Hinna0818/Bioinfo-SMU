# 实验一：蛋白质相互作用网络分析（PPI）

## 实验简介

蛋白质相互作用网络（Protein-Protein Interaction Network, PPI）是研究细胞功能的重要工具。本实验通过构建和分析PPI网络，学习网络生物学的基本方法。

---

## 实验目的

- 理解蛋白质相互作用网络的概念
- 掌握使用 R 语言构建 PPI 网络
- 学会分析网络的拓扑性质
- 了解网络中心性指标的生物学意义

---

## 理论背景

### 什么是 PPI 网络？

蛋白质相互作用网络是将蛋白质作为节点，蛋白质之间的相互作用作为边的网络图。

### 网络拓扑性质

1. **度（Degree）**：节点连接的边数
2. **聚类系数（Clustering Coefficient）**：节点邻居之间相互连接的程度
3. **最短路径（Shortest Path）**：两个节点之间的最短距离
4. **中心性（Centrality）**：节点在网络中的重要性

### 中心性指标

- **度中心性（Degree Centrality）**：连接数最多的节点
- **介数中心性（Betweenness Centrality）**：经过该节点的最短路径数
- **紧密中心性（Closeness Centrality）**：到其他节点的平均距离
- **特征向量中心性（Eigenvector Centrality）**：考虑邻居重要性的中心性

---

## 实验步骤

### 1. 数据准备

```r
# 加载必需的包
library(igraph)
library(ggplot2)
library(dplyr)

# 读取 PPI 数据
# 数据通常包含两列：蛋白质A 和 蛋白质B
ppi_data <- read.csv("ppi_data.csv")
```

### 2. 构建网络

```r
# 创建图对象
g <- graph_from_data_frame(ppi_data, directed = FALSE)

# 查看网络基本信息
vcount(g)  # 节点数
ecount(g)  # 边数
```

### 3. 计算拓扑性质

```r
# 度分布
degree_dist <- degree(g)

# 聚类系数
clustering_coef <- transitivity(g, type = "local")

# 平均路径长度
avg_path_length <- mean_distance(g)
```

### 4. 计算中心性

```r
# 度中心性
degree_cent <- degree(g)

# 介数中心性
between_cent <- betweenness(g)

# 紧密中心性
close_cent <- closeness(g)

# 特征向量中心性
eigen_cent <- eigen_centrality(g)$vector
```

### 5. 网络可视化

```r
# 基础可视化
plot(g,
     vertex.size = 5,
     vertex.label = NA,
     edge.arrow.size = 0.3)

# 根据度中心性着色
V(g)$color <- colorRampPalette(c("lightblue", "darkred"))(max(degree_cent))[degree_cent]

plot(g,
     vertex.size = log(degree_cent) * 3,
     vertex.label = NA,
     vertex.color = V(g)$color,
     main = "PPI Network (colored by degree)")
```

---

## 结果分析

### 度分布

PPI 网络通常表现出无标度（Scale-free）特性，即少数"枢纽"蛋白与很多其他蛋白相互作用。

```r
# 绘制度分布图
ggplot(data.frame(degree = degree_dist), aes(x = degree)) +
  geom_histogram(bins = 30, fill = "steelblue") +
  scale_y_log10() +
  labs(title = "Degree Distribution",
       x = "Degree",
       y = "Count (log10)") +
  theme_minimal()
```

### Hub 蛋白识别

```r
# 识别度最高的前10个蛋白
top_hubs <- head(sort(degree_cent, decreasing = TRUE), 10)
print(top_hubs)
```

---

## 生物学解释

### Hub 蛋白的重要性

- Hub 蛋白通常是细胞功能的关键调控因子
- Hub 蛋白的突变更可能导致疾病
- Hub 蛋白是潜在的药物靶点

### 网络模块

- 高度连接的蛋白质群可能参与相同的生物学过程
- 可以通过社区检测算法识别功能模块

---

## 作业要求

1. **基础分析**
   - 构建 PPI 网络
   - 计算网络拓扑性质
   - 识别 Hub 蛋白

2. **进阶分析**
   - 进行社区检测
   - 分析不同模块的功能
   - 与已知通路比较

3. **报告撰写**
   - 使用 R Markdown 撰写报告
   - 包含代码、图表和解释
   - 对结果进行生物学解读

---

## 文件位置

```
Grade4/computational_biology/experiments/Exp1/
├── Exp1.PPI.Rmd      # R Markdown 报告
└── data/             # 数据文件（如果有）
```

---

## 参考资料

1. Barabási, A. L., & Oltvai, Z. N. (2004). Network biology: understanding the cell's functional organization. *Nature Reviews Genetics*, 5(2), 101-113.

2. Albert, R. (2005). Scale-free networks in cell biology. *Journal of Cell Science*, 118(21), 4947-4957.

3. [igraph 官方文档](https://igraph.org/r/doc/)

4. [STRING 数据库](https://string-db.org/)

---

## 提示

::: {.callout-tip title="数据来源"}
可以从 STRING 数据库下载特定物种或疾病相关的 PPI 数据。

:::
::: {.callout-tip title="可视化建议"}
对于大型网络，可以只展示部分节点或使用交互式可视化工具（如 visNetwork）。

:::
::: {.callout-warning title="计算时间"}
对于大型网络，计算介数中心性等指标可能需要较长时间。

:::
---

[返回课程主页](index.md) | [下一个实验：WGCNA →](exp2.md)

# 实验三：网络聚类与随机游走

## 实验简介

本实验学习两种重要的网络分析算法：MCL（Markov Cluster Algorithm）和 RWR（Random Walk with Restart），并应用于疾病基因预测。

---

## 实验目的

- 理解 MCL 聚类算法原理
- 掌握 RWR 算法的实现
- 学会进行 KEGG 通路富集分析
- 应用网络算法解决实际生物学问题

---

## 理论背景

### MCL 聚类算法

MCL (Markov Cluster Algorithm) 通过模拟流在网络中的传播来识别密集连接的区域（簇）。

**基本步骤**：
1. **Expansion**：矩阵乘法（随机游走）
2. **Inflation**：逐元素幂运算（促进流聚集）
3. **迭代**：重复上述步骤直至收敛

### Random Walk with Restart (RWR)

RWR 是一种在网络上进行随机游走的算法，从起始节点出发，每步以一定概率返回起始点。

**应用**：
- 候选疾病基因预测
- 药物靶点发现
- 功能相似性度量

---

## 实验步骤

### Part 1: MCL 聚类分析

#### 1. 数据准备

```r
library(igraph)
library(MCL)

# 读取 PPI 网络
ppi_data <- read.table("ppi_network.txt", header = TRUE)
g <- graph_from_data_frame(ppi_data, directed = FALSE)

# 获取邻接矩阵
adj_matrix <- as_adjacency_matrix(g, sparse = FALSE)
```

#### 2. 执行 MCL 聚类

```r
# MCL 聚类
# inflation 参数控制簇的粒度，通常取 2-5
mcl_result <- mcl(adj_matrix,
                  addLoops = TRUE,
                  inflation = 2,
                  allow1 = FALSE)

# 查看聚类结果
table(mcl_result$Cluster)

# 添加簇信息到图对象
V(g)$cluster <- mcl_result$Cluster
```

#### 3. 可视化聚类结果

```r
# 为不同簇分配颜色
cluster_colors <- rainbow(max(V(g)$cluster))
V(g)$color <- cluster_colors[V(g)$cluster]

# 绘制网络
plot(g,
     vertex.size = 5,
     vertex.label = NA,
     vertex.color = V(g)$color,
     main = "MCL Clustering Result")

# 添加图例
legend("topright",
       legend = paste("Cluster", 1:max(V(g)$cluster)),
       col = cluster_colors,
       pch = 19,
       cex = 0.8)
```

#### 4. 分析簇的功能

```r
library(clusterProfiler)
library(org.Hs.eg.db)

# 选择一个簇进行功能富集分析
cluster_id <- 1
cluster_genes <- V(g)$name[V(g)$cluster == cluster_id]

# KEGG 富集分析
kegg_enrich <- enrichKEGG(gene = cluster_genes,
                          organism = "hsa",
                          pvalueCutoff = 0.05,
                          qvalueCutoff = 0.05)

# 可视化
barplot(kegg_enrich, showCategory = 10)
dotplot(kegg_enrich, showCategory = 10)
```

---

### Part 2: Random Walk with Restart

#### 1. RWR 算法实现

```r
# RWR 函数
random_walk_with_restart <- function(adj_matrix, seed_nodes, restart_prob = 0.7, max_iter = 100, tol = 1e-6) {
  n <- nrow(adj_matrix)
  
  # 标准化邻接矩阵（列归一化）
  col_sums <- colSums(adj_matrix)
  col_sums[col_sums == 0] <- 1  # 避免除以0
  trans_matrix <- t(t(adj_matrix) / col_sums)
  
  # 初始化概率向量
  p0 <- rep(0, n)
  p0[seed_nodes] <- 1 / length(seed_nodes)
  
  # 迭代
  p <- p0
  for (i in 1:max_iter) {
    p_new <- (1 - restart_prob) * trans_matrix %*% p + restart_prob * p0
    
    # 检查收敛
    if (sum(abs(p_new - p)) < tol) {
      break
    }
    p <- p_new
  }
  
  return(as.vector(p))
}
```

#### 2. 应用：克罗恩病基因预测

```r
# 读取已知疾病基因
disease_genes <- read.table("Crohn's_disease.txt", header = FALSE)$V1

# 找到种子基因在网络中的索引
seed_indices <- which(V(g)$name %in% disease_genes)

# 执行 RWR
rwr_scores <- random_walk_with_restart(adj_matrix,
                                       seed_nodes = seed_indices,
                                       restart_prob = 0.7)

# 添加分数到图对象
V(g)$rwr_score <- rwr_scores

# 按分数排序，找到候选基因
gene_scores <- data.frame(
  gene = V(g)$name,
  score = rwr_scores,
  is_seed = V(g)$name %in% disease_genes
)
gene_scores <- gene_scores[order(gene_scores$score, decreasing = TRUE), ]

# 查看前20个候选基因
head(gene_scores[!gene_scores$is_seed, ], 20)
```

#### 3. 结果可视化

```r
# 根据 RWR 分数着色
score_colors <- colorRampPalette(c("lightblue", "red"))(100)
V(g)$color <- score_colors[cut(rwr_scores, breaks = 100)]

# 种子基因用不同颜色标记
V(g)$color[seed_indices] <- "green"

plot(g,
     vertex.size = 5,
     vertex.label = NA,
     vertex.color = V(g)$color,
     main = "RWR Scores (green = seed genes)")

# 分数分布
ggplot(gene_scores, aes(x = score, fill = is_seed)) +
  geom_histogram(bins = 50, alpha = 0.7) +
  scale_fill_manual(values = c("FALSE" = "steelblue", "TRUE" = "red"),
                    labels = c("Other genes", "Seed genes")) +
  labs(title = "RWR Score Distribution",
       x = "RWR Score",
       y = "Count",
       fill = "") +
  theme_minimal()
```

#### 4. 验证候选基因

```r
# 提取高分候选基因
top_candidates <- head(gene_scores[!gene_scores$is_seed, ], 50)$gene

# KEGG 富集分析
kegg_candidates <- enrichKEGG(gene = top_candidates,
                              organism = "hsa",
                              pvalueCutoff = 0.05)

# 查看富集的通路
head(kegg_candidates@result)

# 可视化
barplot(kegg_candidates, showCategory = 15)
```

---

## 结果分析

### MCL 聚类

- 识别功能相关的蛋白质群
- 不同簇可能对应不同的生物学过程
- 通过富集分析验证簇的功能一致性

### RWR 候选基因预测

- 高分候选基因可能与疾病相关
- 可以通过文献验证或实验确认
- 考虑网络拓扑结构的疾病基因预测方法

---

## 生物学解释

### 克罗恩病

克罗恩病是一种慢性炎症性肠病。通过网络分析可以：

- 发现新的疾病相关基因
- 理解疾病的分子机制
- 寻找潜在的治疗靶点

### 网络邻近性

- 功能相关的基因倾向于在网络中聚集
- RWR 利用这一原理进行基因功能预测
- 网络拓扑比单个基因更能反映生物学功能

---

## 作业要求

1. **MCL 聚类**
   - 尝试不同的 inflation 参数
   - 分析参数对聚类结果的影响
   - 对主要簇进行功能富集分析

2. **RWR 分析**
   - 实现 RWR 算法
   - 预测疾病候选基因
   - 验证候选基因的合理性

3. **综合分析**
   - 比较 MCL 和 RWR 的结果
   - 讨论两种方法的优缺点
   - 提出改进建议

---

## 文件位置

```
Grade4/computational_biology/experiments/Exp3/
├── MCL.R                          # MCL 聚类脚本
├── RWR.R                          # RWR 分析脚本
├── Exp3.Rmd                       # R Markdown 报告
├── Exp3.html                      # 生成的 HTML 报告
├── Crohn's_disease.txt            # 克罗恩病基因列表
└── c2.cp.kegg_legacy.v2025.1.Hs.entrez.gmt  # KEGG 基因集
```

---

## 参考资料

1. Van Dongen, S. (2000). *Graph clustering by flow simulation*. PhD thesis, University of Utrecht.

2. Köhler, S., et al. (2008). Walking the interactome for prioritization of candidate disease genes. *The American Journal of Human Genetics*, 82(4), 949-958.

3. Li, Y., & Patra, J. C. (2010). Genome-wide inferring gene–phenotype relationship by walking on the heterogeneous network. *Bioinformatics*, 26(9), 1219-1224.

---

## 提示

::: {.callout-tip title="参数选择"}
- MCL 的 inflation 参数：较小值产生大簇，较大值产生小簇
- RWR 的 restart 概率：通常取 0.5-0.8

:::
::: {.callout-tip title="计算效率"}
- 对于大型网络，MCL 可能需要较长时间
- RWR 可以使用稀疏矩阵加速计算

:::
::: {.callout-warning title="数据格式"}
确保基因 ID 与网络中的节点 ID 一致（如 Entrez ID 或 Symbol）。

:::
---

[← 上一个实验：WGCNA](exp2.md) | [返回课程主页](index.md) | [下一个实验：qPCR →](exp4.md)

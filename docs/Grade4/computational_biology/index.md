# 计算系统生物学

**课程代码**：待补充  
**学分**：待补充  
**学期**：大四上学期

---

## 📖 课程简介

计算系统生物学是生物信息学专业的核心课程，主要学习使用计算方法分析生物数据。本课程涵盖了网络生物学、基因表达分析、聚类算法等多个重要主题。

### 课程目标

- 🎯 掌握生物网络分析的基本方法
- 🎯 学会使用 R 语言进行数据分析
- 🎯 理解常用网络算法的原理
- 🎯 培养独立分析生物数据的能力

---

## 🧪 实验列表

### [实验一：蛋白质相互作用网络分析（PPI）](exp1.md)

**主要内容**：

- 蛋白质相互作用网络的构建
- 网络拓扑性质分析
- 中心性指标计算
- 网络可视化

**技术栈**：R, igraph

**代码位置**：`Grade4/computational_biology/experiments/Exp1/`

---

### [实验二：加权基因共表达网络分析（WGCNA）](exp2.md)

**主要内容**：

- 基因表达数据预处理
- 共表达网络构建
- 模块识别和特征基因提取
- 模块与表型关联分析

**技术栈**：R, WGCNA

**代码位置**：`Grade4/computational_biology/experiments/Exp2/`

---

### [实验三：网络聚类与随机游走](exp3.md)

**主要内容**：

- MCL (Markov Cluster Algorithm) 聚类分析
- RWR (Random Walk with Restart) 算法
- KEGG 通路富集分析
- 应用案例：克罗恩病相关基因分析

**技术栈**：R, clusterProfiler

**代码位置**：`Grade4/computational_biology/experiments/Exp3/`

---

### [实验四：qPCR 数据分析](exp4.md)

**主要内容**：

- qPCR 原理和数据格式
- Ct 值处理和标准化
- 相对表达量计算（ΔΔCt 方法）
- 统计检验和可视化

**技术栈**：R, ggplot2

**代码位置**：`Grade4/computational_biology/experiments/Exp4/`

---

## � 考试资料

### 💡 [考试重点与经验分享](exam-materials.md)

准备考试？这里有学长学姐整理的考试资料：

- ✅ 课程核心知识点总结
- ✅ 考试题型分析与经验
- ✅ 复习建议和重点标注
- ✅ PDF 资料下载

[📥 查看考试资料 →](exam-materials.md){ .md-button .md-button--primary }

---

## �📚 学习资源

### 推荐阅读

1. **网络生物学**
   - Barabási, A. L., & Oltvai, Z. N. (2004). Network biology: understanding the cell's functional organization. *Nature Reviews Genetics*, 5(2), 101-113.

2. **WGCNA**
   - Langfelder, P., & Horvath, S. (2008). WGCNA: an R package for weighted correlation network analysis. *BMC Bioinformatics*, 9(1), 559.

3. **网络聚类**
   - Van Dongen, S. (2000). Graph clustering by flow simulation. *PhD thesis*, University of Utrecht.

### 在线教程

- [WGCNA 官方教程](https://horvath.genetics.ucla.edu/html/CoexpressionNetwork/Rpackages/WGCNA/)
- [igraph 文档](https://igraph.org/r/doc/)
- [STRING 数据库](https://string-db.org/)

---

## 💻 环境配置

### R 环境

推荐使用 R >= 4.0.0

### 必需的 R 包

```r
# 基础包
install.packages(c("tidyverse", "ggplot2", "dplyr"))

# 生物信息学包
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c(
    "WGCNA",
    "igraph",
    "clusterProfiler",
    "org.Hs.eg.db"
))
```

### RStudio

推荐使用 RStudio 作为开发环境，可以更方便地编写和运行 R Markdown 文件。

---

## 📊 数据来源

### 常用数据库

| 数据库 | 用途 | 网址 |
|--------|------|------|
| STRING | 蛋白质相互作用 | https://string-db.org/ |
| GEO | 基因表达数据 | https://www.ncbi.nlm.nih.gov/geo/ |
| KEGG | 代谢通路 | https://www.kegg.jp/ |
| UniProt | 蛋白质信息 | https://www.uniprot.org/ |

---

## 📝 实验报告要求

### 报告结构

1. **实验目的**：简要说明实验要解决的问题
2. **实验原理**：介绍相关算法和方法
3. **实验步骤**：详细记录分析流程
4. **结果分析**：展示结果并进行解读
5. **讨论**：总结实验收获和思考

### 代码规范

- ✅ 代码清晰易读，有适当的注释
- ✅ 使用有意义的变量名
- ✅ 结果可重现
- ✅ 图表美观，标注清晰

!!! tip "报告撰写建议"
    - 使用 R Markdown 编写报告
    - 代码和文字结合，便于理解
    - 注意图表的标题和坐标轴标签
    - 对结果进行充分的生物学解释

---

## 🎯 考核方式

- 📝 平时作业：20%
- 🧪 实验报告：40%
- 📄 期末考试：40%

### 期末考试形式

通常包括：

- 理论知识（算法原理、概念解释）
- 代码阅读和填空
- 简单的数据分析题

---

## ❓ 常见问题

### Q: R 包安装失败怎么办？

A: 尝试以下方法：
```r
# 1. 更换 CRAN 镜像
options(repos = c(CRAN = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/"))

# 2. 使用 Bioconductor 镜像
options(BioC_mirror = "https://mirrors.tuna.tsinghua.edu.cn/bioconductor")

# 3. 更新 R 和 RStudio 到最新版本
```

### Q: 代码运行出错怎么办？

A: 
1. 检查数据文件路径是否正确
2. 确认所有必需的包都已安装
3. 查看错误信息，搜索解决方案
4. 在 Discussions 中提问

### Q: 如何获取实验数据？

A: 实验数据通常包含在代码文件夹中，或从指定的数据库下载。

---

## 📮 联系方式

- 💬 [Discussions](https://github.com/Hinna0818/Bioinfo-SMU/discussions)
- 🐛 [Issues](https://github.com/Hinna0818/Bioinfo-SMU/issues)
- 📧 Email: hinna01@163.com

---

<div align="center">

**祝学习顺利！如有问题欢迎交流！** 💪

[返回上级](../index.md) | [查看实验详情](#实验列表)

</div>

# 学习路线建议

本页面为生物信息学专业同学提供系统的学习路线建议，帮助大家循序渐进地掌握相关知识和技能。

---

## 新生入门

### 第一阶段：编程基础

#### R 语言
- **基础语法**：变量、数据类型、控制结构
- **数据结构**：向量、矩阵、数据框、列表
- **数据处理**：`dplyr`、`tidyr` 包的使用
- **数据可视化**：`ggplot2` 绘图

::: {.callout-tip title="推荐资源"}
- [R for Data Science](https://r4ds.had.co.nz/)
- [ggplot2 官方文档](https://ggplot2.tidyverse.org/)

:::
#### Python 语言
- **基础语法**：变量、数据类型、控制结构
- **数据结构**：列表、字典、集合、元组
- **常用库**：NumPy、Pandas、Matplotlib
- **科学计算**：SciPy、Scikit-learn

::: {.callout-tip title="推荐资源"}
- [Python for Biologists](https://pythonforbiologists.com/)
- [Biopython Tutorial](https://biopython.org/wiki/Documentation)

:::
### 第二阶段：生物学基础

- **分子生物学**：DNA、RNA、蛋白质的结构与功能
- **测序技术**：Sanger测序、NGS、三代测序
- **实验设计**：对照实验、统计学基础
- **常用技术**：PCR、qPCR、Western Blot等

### 第三阶段：统计学基础

- **描述性统计**：均值、方差、分布
- **概率论**：概率分布、贝叶斯定理
- **假设检验**：t检验、卡方检验、方差分析
- **回归分析**：线性回归、逻辑回归

---

## 进阶学习

### 基因组学

#### 基因组数据分析
- **序列比对**：BLAST、Bowtie2、BWA
- **变异检测**：SNP calling、INDEL检测
- **基因组注释**：基因预测、功能注释
- **进化分析**：系统发育树、选择压力分析

#### 转录组学
- **RNA-seq 分析**：
    - 数据预处理（质控、比对）
    - 差异表达分析（DESeq2、edgeR）
    - 功能富集分析（GO、KEGG）
- **单细胞测序**：
    - 数据降维（PCA、t-SNE、UMAP）
    - 细胞聚类与注释
    - 轨迹推断

### 蛋白质组学与代谢组学

- **蛋白质组**：质谱数据分析、蛋白质鉴定
- **代谢组**：代谢物鉴定、代谢通路分析
- **多组学整合**：关联分析、网络构建

### 生物网络分析

::: {.callout-note title="本课程重点"}
这是我们大四计算生物学课程的核心内容！

:::
- **PPI 网络**：蛋白质相互作用网络构建与分析
- **基因调控网络**：转录因子-靶基因关系
- **代谢网络**：代谢通路的网络表示
- **WGCNA**：加权基因共表达网络分析
- **网络算法**：
    - 社区检测（MCL、Louvain）
    - 随机游走（RWR）
    - 中心性分析

---

## 高级应用

### 机器学习与深度学习

#### 传统机器学习
- **监督学习**：
    - 分类：SVM、随机森林、XGBoost
    - 回归：线性回归、岭回归、Lasso
- **无监督学习**：
    - 聚类：K-means、层次聚类、DBSCAN
    - 降维：PCA、t-SNE、UMAP
- **模型评估**：交叉验证、ROC曲线、混淆矩阵

#### 深度学习
- **神经网络基础**：感知机、反向传播
- **常用架构**：
    - CNN（卷积神经网络）
    - RNN/LSTM（循环神经网络）
    - Transformer
- **生物信息应用**：
    - 蛋白质结构预测（AlphaFold）
    - 基因组序列分析
    - 药物-靶点预测

### 结构生物信息学

- **蛋白质结构**：
    - 结构预测（同源建模、从头预测）
    - 结构比对与分析
    - 分子对接
- **分子动力学模拟**：GROMACS、AMBER
- **药物设计**：虚拟筛选、QSAR建模

---

## 科研应用

### 第一步：选题

1. **确定研究方向**
    - 疾病机制研究
    - 药物靶点发现
    - 生物标志物筛选
    - 进化生物学

2. **文献调研**
    - PubMed 检索
    - 阅读综述文章
    - 追踪最新进展

### 第二步：数据获取

#### 公共数据库

| 数据库 | 用途 | 网址 |
|--------|------|------|
| GEO | 基因表达数据 | https://www.ncbi.nlm.nih.gov/geo/ |
| TCGA | 癌症基因组数据 | https://portal.gdc.cancer.gov/ |
| GTEx | 正常组织表达数据 | https://gtexportal.org/ |
| STRING | 蛋白质相互作用 | https://string-db.org/ |
| UniProt | 蛋白质序列与功能 | https://www.uniprot.org/ |
| KEGG | 代谢通路 | https://www.kegg.jp/ |

### 第三步：数据分析

1. **数据预处理**
    - 质量控制
    - 标准化
    - 批次效应校正

2. **统计分析**
    - 差异分析
    - 相关性分析
    - 生存分析

3. **功能分析**
    - 富集分析
    - 通路分析
    - 网络分析

### 第四步：结果验证

- **计算验证**：使用其他数据集验证
- **实验验证**：qPCR、Western Blot等
- **文献支持**：查找相关研究支持

### 第五步：论文撰写

1. **论文结构**
    - Introduction（引言）
    - Methods（方法）
    - Results（结果）
    - Discussion（讨论）

2. **数据可视化**
    - 使用 ggplot2 制作出版级图表
    - 注意配色和布局
    - 添加必要的统计信息

3. **投稿准备**
    - 选择合适的期刊
    - 准备补充材料
    - 代码和数据分享

---

## 推荐资源

### 在线课程

- [Coursera - Bioinformatics Specialization](https://www.coursera.org/specializations/bioinformatics)
- [edX - Data Analysis for Life Sciences](https://www.edx.org/course/data-analysis-for-life-sciences)
- [生信技能树](https://www.biotrainee.com/)

### 书籍推荐

- 《生物信息学》- 李霞、雷健波
- 《Bioinformatics Data Skills》- Vince Buffalo
- 《An Introduction to Statistical Learning》- James et al.

### 工具与平台

- **Galaxy**：图形化分析平台
- **Bioconductor**：R 语言生物信息学包集合
- **Biopython**：Python 生物信息学工具库

---

## 学习建议

::: {.callout-tip title="循序渐进"}
不要急于求成，扎实掌握每个阶段的知识再进入下一阶段。

:::
::: {.callout-tip title="理论与实践结合"}
学习理论知识的同时，多动手实践，完成实际项目。

:::
::: {.callout-tip title="积极交流"}
多与同学、老师交流，参加学术会议和研讨会。

:::
::: {.callout-tip title="持续学习"}
生物信息学发展迅速，保持学习的热情，关注最新技术和方法。

:::
---

## 阶段性目标

### 大一～大二
- 掌握 R 和 Python 编程
- 学习统计学基础
- 了解分子生物学知识

### 大三
- 学习基因组学、转录组学分析
- 掌握常用生物信息学工具
- 完成课程项目

### 大四
- 深入学习特定方向（网络分析、机器学习等）
- 参与科研项目
- 准备毕业论文

### 研究生
- 独立完成科研项目
- 发表学术论文
- 参加国际会议

---

有问题欢迎在 [Discussions](https://github.com/Hinna0818/Bioinfo-SMU/discussions) 中讨论！

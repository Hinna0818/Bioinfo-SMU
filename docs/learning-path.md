# 生物信息学学习路线

本页面提供从零基础到进阶的生物信息学学习路径建议，帮助同学们系统规划学习进度。

---

## 阶段一：基础入门

### 编程基础

**Python 编程**

- 基础语法：变量、数据类型、控制流、函数
- 数据结构：列表、字典、集合、元组
- 文件操作与异常处理
- 常用库：NumPy、Pandas、Matplotlib
- 推荐资源：
  - [Python 官方教程](https://docs.python.org/zh-cn/3/tutorial/)
  - [廖雪峰 Python 教程](https://www.liaoxuefeng.com/wiki/1016959663602400)
  - 《Python 编程：从入门到实践》

**R 语言编程**

- 基础语法与数据结构
- 数据处理：dplyr、tidyr
- 数据可视化：ggplot2
- 统计分析基础
- 推荐资源：
  - [R for Data Science](https://r4ds.had.co.nz/)
  - 本站 [R 语言教程](Rbase/index.md)
  - 《R 语言实战》

### 生物学基础

- 分子生物学中心法则
- 基因组结构与功能
- 转录与翻译机制
- 表观遗传学基础
- 推荐资源：
  - 《分子生物学》（第五版，Robert F. Weaver）
  - [Khan Academy - Biology](https://www.khanacademy.org/science/biology)

### 统计学基础

- 描述性统计
- 概率分布（正态分布、泊松分布等）
- 假设检验与 p 值
- 多重检验校正（FDR, Bonferroni）
- 线性回归与相关分析
- 推荐资源：
  - 《统计学习方法》（李航）
  - [StatQuest 视频教程](https://www.youtube.com/c/joshstarmer)

---

## 阶段二：生信核心技能

### 测序技术基础

**二代测序（NGS）**

- Illumina 测序原理
- FASTQ 文件格式
- 质量控制（FastQC）
- 序列比对（BWA、STAR、HISAT2）

**三代测序**

- PacBio 与 Oxford Nanopore 技术
- 长读长数据分析
- 基因组组装

**测序应用**

- DNA-seq：全基因组测序、外显子组测序
- RNA-seq：转录组测序
- ChIP-seq：染色质免疫沉淀测序
- ATAC-seq：染色质可及性测序

### 基因组学分析

- 参考基因组与注释文件
- 变异检测（SNP、InDel、CNV、SV）
- 变异注释与功能预测
- 群体遗传学分析
- 推荐工具：
  - 比对：BWA、Bowtie2
  - 变异检测：GATK、SAMtools、FreeBayes
  - 注释：ANNOVAR、SnpEff

### 转录组学分析

**Bulk RNA-seq 分析流程**

- 数据预处理与质控
- 基因表达定量（featureCounts、Salmon、Kallisto）
- 差异表达分析（DESeq2、edgeR、limma）
- 功能富集分析（GO、KEGG、GSEA）

**单细胞 RNA-seq 分析**

- 数据预处理与质控
- 降维与聚类（PCA、t-SNE、UMAP）
- 细胞类型注释
- 拟时序分析
- 细胞通讯分析
- 推荐工具：Seurat、Scanpy、Monocle3

**空间转录组分析**

- 空间数据可视化
- 空间变异基因识别
- 空间域划分
- 配体-受体互作分析
- 推荐工具：Seurat、SpatialExperiment、Giotto

### 表观基因组学分析

- ChIP-seq 分析：peak calling、差异 peak 分析
- ATAC-seq 分析：开放染色质识别、motif 分析
- DNA 甲基化分析：BS-seq、WGBS
- 推荐工具：
  - MACS2、Homer、deepTools
  - 甲基化分析：Bismark、MethylKit

---

## 阶段三：进阶分析

### 机器学习与深度学习

**机器学习基础**

- 监督学习：分类与回归
- 无监督学习：聚类与降维
- 特征工程与模型评估
- 常用算法：决策树、随机森林、SVM、XGBoost

**深度学习基础**

- 神经网络基础
- 卷积神经网络（CNN）
- 循环神经网络（RNN、LSTM）
- Transformer 架构
- 推荐资源：
  - 《深度学习》（Ian Goodfellow）
  - [吴恩达深度学习课程](https://www.coursera.org/specializations/deep-learning)
  - PyTorch 与 TensorFlow 教程

### 网络生物学

- 蛋白质相互作用网络（PPI）
- 基因调控网络（GRN）
- 加权基因共表达网络分析（WGCNA）
- 网络拓扑分析与中心性指标
- 社区检测算法（Louvain、MCL）
- 随机游走算法（Random Walk with Restart）
- 推荐资源：
  - 本站[计算生物学课程](Grade4/computational_biology/index.md)
  - Cytoscape 网络可视化工具
  - igraph、NetworkX 等网络分析包

### 多组学整合分析

- 多组学数据整合策略
- 关联分析与因果推断
- 多组学网络构建
- 推荐工具：
  - MOFA+、mixOmics
  - Multi-Omics Factor Analysis

---

## 阶段四：前沿技术

### AI4Science（AI for Science）

**Foundation Models for Biology**

- DNA 序列模型：DNABERT、Nucleotide Transformer、HyenaDNA
- RNA 序列模型：RNA-FM、RNABert
- 蛋白质序列模型：ESM-2、ProtGPT2、ProtT5
- 蛋白质结构预测：AlphaFold2、AlphaFold3、ESMFold、RoseTTAFold
- 多模态模型：整合序列、结构、功能信息
- 推荐资源：
  - 本站 [AI4S 专题](AI4S/index.md)
  - [AlphaFold Protein Structure Database](https://alphafold.ebi.ac.uk/)

**AI 驱动的药物设计（AIDD）**

- 虚拟筛选与分子对接
- 分子生成模型
- 药物-靶点相互作用预测
- ADMET 性质预测
- 推荐工具：
  - AutoDock Vina、Glide
  - DeepChem、Chemprop
  - 分子生成：MolGAN、GraphVAE

**虚拟细胞（Virtual Cell）**

- 细胞行为的计算建模
- 多尺度生物模拟
- 数字孪生技术在生物学中的应用
- 参考文献：
  - [Cell 2026: Virtual Cell Modeling](https://www.cell.com/cell/fulltext/S0092-8674(26)01015-9)（2026-09-29）

### 结构生物学

- 蛋白质结构预测（AlphaFold2/3）
- 蛋白质-配体复合物预测
- 分子动力学模拟（GROMACS、AMBER）
- 冷冻电镜数据分析
- 推荐资源：
  - [AlphaFold Colab](https://colab.research.google.com/github/deepmind/alphafold/blob/main/notebooks/AlphaFold.ipynb)
  - RCSB PDB 数据库

### 单细胞多组学

- scRNA-seq + scATAC-seq 联合分析
- CITE-seq：蛋白质与转录组联合测量
- 空间多组学技术（Visium、MERFISH、seqFISH）
- 细胞命运决策与分化轨迹
- 推荐工具：
  - ArchR、Signac、Seurat v5

### 长读长测序

- PacBio HiFi 测序
- Oxford Nanopore 测序
- 全长转录本测序
- 结构变异检测
- 单倍型组装
- 推荐工具：
  - minimap2、Flye、Canu
  - IsoSeq 全长转录本分析

---

## 阶段五：科研实践

### 选择研究方向

- 疾病基因组学（癌症、遗传病）
- 免疫组学（T 细胞受体、B 细胞受体）
- 微生物组学（宏基因组、宏转录组）
- 药物基因组学与精准医疗
- 进化基因组学
- 合成生物学与代谢工程

### 数据资源利用

**公共数据库**

- GEO：基因表达综合数据库
- TCGA：癌症基因组图谱
- GTEx：基因型-组织表达
- UK Biobank：大规模流行病学数据
- CellxGene：单细胞数据
- 参考：本站[流行病学数据库](Epidemiology/UK_Biobank.md)

**生物信息学工具与平台**

- UCSC Genome Browser
- Ensembl
- UniProt
- STRING：蛋白质相互作用数据库
- KEGG、Reactome：通路数据库

### 科研技能

**文献阅读与写作**

- 如何高效阅读文献
- 科研论文写作规范
- 图表制作与数据可视化
- 推荐工具：
  - Zotero、Mendeley 文献管理
  - Inkscape、Adobe Illustrator 科研绘图

**可重复性研究**

- 版本控制（Git）
- 环境管理（Conda、Docker）
- 工作流管理（Snakemake、Nextflow）
- Jupyter Notebook / R Markdown
- 推荐资源：
  - [Git 教程](https://git-scm.com/book/zh/v2)
  - [Docker 入门](https://docs.docker.com/get-started/)

**高性能计算**

- Linux 基础与 Shell 脚本
- 任务调度系统（SLURM、PBS）
- 并行计算与 GPU 加速
- 云计算平台使用（AWS、Google Cloud）

---

## 学习建议

### 时间规划

**大一至大二**

- 打好编程基础（Python、R）
- 学习生物学和统计学基础知识
- 完成课程作业，熟悉基本工具

**大二至大三**

- 深入学习转录组学、基因组学分析
- 参与课题组或实验室项目
- 开始阅读文献，了解研究前沿

**大三至大四**

- 选择感兴趣的研究方向
- 进行独立科研项目（毕业论文）
- 学习前沿技术（AI4S、单细胞等）
- 准备升学或就业

### 学习方法

**理论与实践结合**

- 不要只看教程，要动手实践
- 从简单数据集开始，逐步挑战复杂项目
- 复现已发表的分析流程

**利用在线资源**

- Coursera、edX、B站 等学习平台
- GitHub 上的开源项目和教程
- 生信技能树、生信菜鸟团 等中文社区

**参与学术交流**

- 加入生信相关的学术社群
- 参加学术会议和讲座
- 与同学、导师讨论问题

**建立知识体系**

- 做好笔记和代码管理
- 整理常用脚本和分析模板
- 定期回顾和总结所学内容

---

## 推荐书籍

**生物信息学入门**

- 《生物信息学》（樊龙江）
- 《Bioinformatics Data Skills》（Vince Buffalo）

**编程与统计**

- 《Python 编程：从入门到实践》
- 《R 语言实战》
- 《统计学习方法》（李航）

**高级主题**

- 《深度学习》（Ian Goodfellow）
- 《Biological Sequence Analysis》（Durbin et al.）
- 《Single Cell RNA-seq》（Orchestrating Single-Cell Analysis with Bioconductor）

---

## 相关链接

- [常用工具](tools.md)
- [参考资料](resources.md)
- [R 语言教程](Rbase/index.md)
- [生信流程](BioinfoTalus/index.md)
- [AI4S 专题](AI4S/index.md)
- [计算生物学课程](Grade4/computational_biology/index.md)

---

如果你对学习路线有任何疑问或建议，欢迎在 [GitHub Discussions](https://github.com/Hinna0818/Bioinfo-SMU/discussions) 中交流讨论！

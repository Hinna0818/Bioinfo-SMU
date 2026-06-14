# 生信流程 (BioinfoTalus)

**项目简介**：面向生物信息学转录组数据分析的 R 脚本集合，覆盖 Bulk 转录组、单细胞转录组与空间转录组三大领域。

::: {.callout-tip title="贡献者致谢"}
本模块由 [@BioConvolutionyt](https://github.com/BioConvolutionyt) 贡献（生物信息学23级lyt），感谢分享！

:::
---

## 项目特点

- **既可作为一套完整 pipeline，也可独立使用**
- **可泛化 + 注释较完整**：核心步骤与关键参数已尽量写成可迁移的形式
- **提供示例数据与部分运行结果**

---

## 模块概览

### Bulk 转录组测序数据分析

| 分析类型 | 主要内容 |
|:-------:|:-------:|
| 数据处理 | TCGA/GEO 数据处理、表达矩阵整理 |
| 差异分析 | DESeq2 差异分析 |
| 富集分析 | GO、KEGG 富集分析、GSEA |
| 免疫分析 | 免疫浸润 (CIBERSORT)、免疫/肿瘤/基质评分 (ESTIMATE) |
| 生存分析 | 生存分析、单因素/多因素 COX 回归、LASSO、Nomogram |
| 其他 | WGCNA、药物敏感性分析、免疫检查点分析 |

---

### 单细胞转录组测序数据分析

| 分析类型 | 主要内容 |
|:-------:|:-------:|
| 基础流程 | Seurat 主流程（读入/QC/聚类/去批次） |
| 细胞注释 | 自动注释、手动注释 |
| 质控 | 双细胞检测、细胞周期评估 |
| 高级分析 | CNV 推断、拟时序分析、发育潜能、细胞通讯 |

---

### 空间转录组测序数据分析

| 分析类型 | 主要内容 |
|:-------:|:-------:|
| 基础流程 | Visium 读入与聚类 |
| 反卷积 | 空间反卷积（基于单细胞先验） |
| 空间分析 | 空间差异基因、空间细胞通讯 |

---

## 示例数据说明

| 数据类型 | 来源 | 描述 |
|:-------:|:----:|:----:|
| Bulk 转录组 | TCGA-HNSC | 头颈部鳞状细胞癌 |
| 单细胞转录组 | GSM9113377-9 | 结直肠癌样本 |
| 空间转录组 | GSM8594561 | 结直肠癌样本 |

---

## 快速开始

### 1. 获取代码

```bash
git clone https://github.com/Hinna0818/Bioinfo-SMU.git
cd Bioinfo-SMU/BioinfoTalus
```

### 2. 下载数据

从 [GitHub Releases](https://github.com/BioConvolutionyt/BioinfoTalus/releases) 下载示例数据：

1. 下载所有 `data_split*.zip` 文件
2. 解压并放置到 `Data/` 目录下

### 3. 运行分析

建议使用 RStudio 打开 `BioinfoTalus.Rproj`，按需运行各模块脚本。

---

## 推荐运行顺序

::: {.panel-tabset}

### Bulk 转录组

1. `TCGA表达数据处理.R` → 生成表达矩阵
2. `差异分析.R` → DESeq2 差异分析
3. `GO & KEGG富集分析.R` / `GSEA.R`
4. `免疫、肿瘤、基质评分计算.R`
5. `生存分析.R` → `单因素COX回归.R` → `多因素COX回归.R`
6. 其他按需选用

### 单细胞转录组

1. 数据读入与 QC
2. 聚类与去批次
3. 细胞注释
4. 高级分析（拟时序、细胞通讯等）

### 空间转录组

1. Visium 数据读入
2. 聚类分析
3. 空间反卷积
4. 空间差异基因分析

:::

---

## 目录结构

```
BioinfoTalus/
├── Bulk 转录组测序数据分析/
│   ├── TCGA表达数据处理.R
│   ├── 差异分析.R
│   ├── GO & KEGG富集分析.R
│   ├── GSEA.R
│   ├── 生存分析.R
│   └── ...
├── 单细胞转录组测序数据分析/
│   ├── Seurat主流程.R
│   ├── 细胞注释.R
│   └── ...
├── 空间转录组测序数据分析/
│   ├── Visium读入与聚类.R
│   └── ...
└── Data/  (从 Releases 下载)
```

---

## 相关链接

- [GitHub 仓库目录](https://github.com/Hinna0818/Bioinfo-SMU/tree/main/BioinfoTalus)
- [数据下载 (Releases)](https://github.com/BioConvolutionyt/BioinfoTalus/releases)
- [贡献者主页 @BioConvolutionyt](https://github.com/BioConvolutionyt)

---

## 致谢

感谢 [@BioConvolutionyt](https://github.com/BioConvolutionyt) 贡献本模块代码！

如果你觉得这些代码对你有帮助，欢迎给仓库一个 Star！

---

[返回首页](../index.md)

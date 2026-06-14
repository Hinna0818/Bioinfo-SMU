# 贡献指南

感谢你有意向为 Bioinfo-SMU 项目贡献！本指南将帮助你了解如何参与项目。

---

## 贡献方式

我们欢迎以下类型的贡献：

### 学习资料

- 课程笔记和总结
- 实验代码和报告
- 考试重点和复习资料
- 学习心得和经验分享

### 代码贡献

- 实验代码优化
- Bug 修复
- 新功能实现
- 代码注释完善

### 文档改进

- 文档内容补充
- 错别字修正
- 格式优化
- 翻译工作

---

## 快速开始

### 1. Fork 仓库

点击仓库页面右上角的 "Fork" 按钮，将项目复制到你的 GitHub 账号下。

### 2. 克隆到本地

```bash
git clone https://github.com/你的用户名/Bioinfo-SMU.git
cd Bioinfo-SMU
```

### 3. 创建新分支

```bash
git checkout -b feature/your-contribution-name
```

::: {.callout-tip title="分支命名建议"}
- `feature/xxx` - 新功能
- `fix/xxx` - Bug修复
- `docs/xxx` - 文档更新
- `refactor/xxx` - 代码重构

:::
### 4. 进行修改

在本地编辑文件，添加你的贡献内容。

### 5. 提交更改

```bash
git add .
git commit -m "描述你的更改"
```

::: {.callout-tip title="Commit Message 建议"}
使用清晰的提交信息，例如：

- `Add: 添加计算生物学实验5代码`
- `Fix: 修复WGCNA分析脚本的错误`
- `Docs: 完善学习路线文档`
- `Update: 更新README中的联系方式`

:::
### 6. 推送到 GitHub

```bash
git push origin feature/your-contribution-name
```

### 7. 创建 Pull Request

1. 访问你 Fork 的仓库页面
2. 点击 "Pull Request" 按钮
3. 填写 PR 标题和描述
4. 提交 PR 等待审核

---

## 内容规范

### 代码规范

#### R 代码
```r
# 使用清晰的变量名
gene_expression_data <- read.csv("data.csv")

# 添加必要的注释
# 进行差异表达分析
results <- DESeq2::DESeq(dds)

# 使用一致的代码风格
plot_data <- data.frame(
  gene = rownames(results),
  log2fc = results$log2FoldChange,
  pvalue = results$pvalue
)
```

#### Python 代码
```python
# 遵循 PEP 8 规范
import pandas as pd
import numpy as np

# 使用类型注解
def calculate_expression(data: pd.DataFrame) -> pd.DataFrame:
    """
    计算基因表达值
    
    Args:
        data: 原始表达数据
    
    Returns:
        标准化后的表达数据
    """
    return data / data.sum()
```

### 文档规范

#### Markdown 格式

```markdown
# 一级标题

## 二级标题

### 三级标题

- 列表项1
- 列表项2

1. 有序列表1
2. 有序列表2

**粗体** *斜体*

[链接文字](URL)

![图片描述](图片URL)
```

#### 使用 Admonitions

```markdown
::: {.callout-note title="提示"}
这是一个提示信息

:::
::: {.callout-warning title="警告"}
这是一个警告信息

:::
::: {.callout-tip title="建议"}
这是一个建议

:::
::: {.callout-note title="信息"}
这是一个信息框
:::
```

效果：

::: {.callout-note title="提示"}
这是一个提示信息

:::
::: {.callout-warning title="警告"}
这是一个警告信息

:::
::: {.callout-tip title="建议"}
这是一个建议

:::
### 文件组织

```
Bioinfo-SMU/
├── docs/                      # 文档目录
│   ├── index.md              # 首页
│   ├── Grade4/               # 大四课程
│   │   ├── computational_biology/
│   │   │   ├── index.md
│   │   │   ├── exp1.md
│   │   │   └── ...
│   │   └── ...
│   └── ...
├── Grade4/                   # 实际代码和数据
│   ├── computational_biology/
│   │   └── experiments/
│   │       ├── Exp1/
│   │       │   ├── Exp1.PPI.Rmd
│   │       │   └── ...
│   │       └── ...
│   └── ...
└── mkdocs.yml               # MkDocs 配置文件
```

---

## 提交检查清单

在提交 Pull Request 之前，请确保：

- [] 代码可以正常运行
- [] 添加了必要的注释
- [] 文档格式正确
- [] 没有拼写错误
- [] 遵循项目的代码风格
- [] Commit message 清晰明确
- [] 已经测试过你的更改

---

## 代码审查

提交 PR 后，维护者会进行代码审查。可能会：

- 直接合并 - 如果一切正常
- 提出建议 - 需要进行一些修改
- 拒绝 - 不符合项目要求

请及时回应审查意见，根据反馈进行修改。

---

## 联系方式

如果你有任何问题或建议：

- **邮箱**：hinna01@163.com
- **Discussions**：[参与讨论](https://github.com/Hinna0818/Bioinfo-SMU/discussions)
- **Issues**：[提交问题](https://github.com/Hinna0818/Bioinfo-SMU/issues)

---

## 注意事项

::: {.callout-warning title="学术诚信"}
- 不要上传未经授权的考试题目或答案
- 尊重他人的知识产权
- 标注资料来源

:::
::: {.callout-warning title="隐私保护"}
- 不要上传包含个人敏感信息的文件
- 不要上传他人的个人作业（未经同意）

:::
::: {.callout-note title="文件大小"}
- 单个文件不超过 10MB
- 大文件请使用 Git LFS 或外部链接

:::
---

## 贡献者

感谢所有为本项目做出贡献的同学！

<a href="https://github.com/Hinna0818/Bioinfo-SMU/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Hinna0818/Bioinfo-SMU" />
</a>

---

## 许可证

通过向本项目贡献，你同意你的贡献将在 [MIT License](https://github.com/Hinna0818/Bioinfo-SMU/blob/main/LICENSE) 下发布。

---

<div align="center">

**感谢你的贡献！让我们一起让这个项目变得更好！** 

</div>

# DNA Foundation Models

DNA 序列编码了生命的遗传信息，包含基因编码区、调控元件、非编码区等复杂结构。DNA Foundation Models 通过在大规模基因组数据上进行预训练，学习 DNA 序列中的语法规则、功能模式和进化约束，能够预测基因功能、调控元件、变异效应等多种下游任务。

---

## 核心概念

### DNA 序列的复杂性

**多层次信息编码**:

1. **编码区（Coding Regions）**
   - 基因外显子：编码蛋白质
   - 密码子偏好性
   - 剪接位点信号

2. **调控元件（Regulatory Elements）**
   - 启动子（Promoter）
   - 增强子（Enhancer）
   - 沉默子（Silencer）
   - 绝缘子（Insulator）

3. **非编码区（Non-coding Regions）**
   - 内含子
   - 基因间区
   - 非编码 RNA 基因

4. **表观遗传信号**
   - CpG 岛
   - 转录因子结合位点（TFBS）
   - 染色质可及性区域

**序列特征**:
- 长程依赖关系（可达数十万碱基）
- 位置依赖性（上下文敏感）
- 物种特异性与保守性共存

---

### 为什么需要 Foundation Models？

**传统方法的局限**:
- **基于规则的方法**: 难以捕捉复杂模式
- **k-mer 特征**: 维度爆炸，缺乏泛化能力
- **单任务模型**: 每个任务需要独立训练，数据效率低

**Foundation Models 的优势**:
- **迁移学习**: 预训练捕捉通用序列特征，适应多种下游任务
- **长程依赖**: Transformer 等架构捕捉远距离相互作用
- **无监督学习**: 利用海量未标注基因组数据
- **零样本学习**: 预测训练时未见过的序列功能

---

## 经典模型

### 1. DNABERT（2021）

**架构**: 基于 BERT（Bidirectional Encoder Representations from Transformers）

**训练数据**: 人类基因组参考序列（GRCh38）

**输入表示**: k-mer tokenization（k=3, 4, 5, 6）
- 例如：`ATCGAT` → `ATC`, `TCG`, `CGA`, `GAT`

**预训练任务**:
- Masked Language Modeling（MLM）：随机遮盖 15% 的 k-mer，预测被遮盖的 token

**模型规模**:
- 12 层 Transformer
- 隐藏维度 768
- 12 个注意力头
- 约 110M 参数

**下游任务**:
- 启动子预测
- 转录因子结合位点预测
- 剪接位点预测
- 变异效应预测

**性能**:
- 在多个基因组预测任务上超越传统 CNN 和 RNN 模型
- 微调后在少样本场景下表现优异

**代码示例**:
```python
from transformers import AutoTokenizer, AutoModel
import torch

# 加载预训练 DNABERT
tokenizer = AutoTokenizer.from_pretrained("zhihan1996/DNA_bert_6")
model = AutoModel.from_pretrained("zhihan1996/DNA_bert_6")

# DNA 序列
sequence = "ATCGATCGATCG"

# k-mer 转换（k=6）
def seq_to_kmer(seq, k=6):
    return " ".join([seq[i:i+k] for i in range(len(seq) - k + 1)])

kmer_seq = seq_to_kmer(sequence, k=6)
print(f"k-mer 序列: {kmer_seq}")

# Tokenize
inputs = tokenizer(kmer_seq, return_tensors="pt")

# 获取嵌入
with torch.no_grad():
    outputs = model(**inputs)
    embeddings = outputs.last_hidden_state

print(f"嵌入形状: {embeddings.shape}")
```

**论文**: Ji, Y. et al. (2021). DNABERT: pre-trained Bidirectional Encoder Representations from Transformers model for DNA-language in genome. *Bioinformatics*, 37(15), 2112-2120.

---

### 2. Nucleotide Transformer（2023）

**架构**: Transformer encoder

**训练数据**: 
- 多物种基因组（3,202 个物种）
- 包含原核生物、真核生物、病毒
- 总共约 300B tokens

**输入表示**: 单核苷酸 tokenization（A, T, C, G）

**预训练任务**:
- Masked Language Modeling

**模型规模**:
- 多个版本：500M, 1B, 2.5B 参数
- 最大上下文窗口：6kb

**特点**:
- 跨物种预训练，学习进化保守特征
- 支持零样本跨物种迁移
- 性能随模型规模增长而提升

**下游任务**:
- 基因预测
- 调控元件预测
- 变异效应预测
- 表观遗传修饰预测

**代码示例**:
```python
from transformers import AutoTokenizer, AutoModelForMaskedLM

# 加载模型
model_name = "InstaDeepAI/nucleotide-transformer-500m-human-ref"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForMaskedLM.from_pretrained(model_name)

# DNA 序列
sequence = "ATCGATCGATCGATCG"

# Tokenize（单核苷酸）
inputs = tokenizer(sequence, return_tensors="pt")

# 前向传播
outputs = model(**inputs)
logits = outputs.logits

print(f"Logits 形状: {logits.shape}")
```

**论文**: Dalla-Torre, H. et al. (2023). The Nucleotide Transformer: Building and Evaluating Robust Foundation Models for Human Genomics. *bioRxiv*.

---

### 3. HyenaDNA（2023）

**架构**: Hyena operator（长程卷积的高效实现）

**训练数据**: 人类参考基因组

**关键创新**: 
- 替代 Transformer 的自注意力机制
- 线性复杂度，支持超长上下文
- 最长上下文：1M bp（百万碱基对）

**模型规模**:
- 多个版本：1M, 32k, 160k, 450k, 1M 上下文长度
- 参数量从数百万到数千万

**优势**:
- 训练和推理速度快
- 内存效率高
- 适合全基因组级别的序列建模

**应用**:
- 染色体级别的调控预测
- 长程增强子-启动子互作
- 结构变异效应预测

**代码示例**:
```python
# HyenaDNA 使用示例（需要安装 hyena-dna 包）
from hyenadna import HyenaDNAModel

# 加载预训练模型
model = HyenaDNAModel.from_pretrained("hyenadna-large-1m")

# 超长 DNA 序列（可达 1M bp）
long_sequence = "A" * 100000 + "TATA" * 1000 + "C" * 100000

# 嵌入
embeddings = model.encode(long_sequence)

print(f"嵌入形状: {embeddings.shape}")
```

**论文**: Nguyen, E. et al. (2023). HyenaDNA: Long-Range Genomic Sequence Modeling at Single Nucleotide Resolution. *NeurIPS 2023*.

---

### 4. Enformer（2021）

**架构**: Transformer + 卷积

**任务**: 预测染色质状态和基因表达

**训练数据**: 
- ENCODE、Roadmap Epigenomics 数据
- ChIP-seq, ATAC-seq, DNase-seq, RNA-seq

**输入**: 200kb DNA 序列

**输出**: 
- 5,313 个表观遗传和转录特征
- 在 128 个 bin 上的预测（每个 bin 128bp）

**关键特点**:
- 远程依赖建模（200kb 上下文）
- 预测增强子-启动子互作
- 变异效应量化

**应用**:
- GWAS 变异功能注释
- 疾病相关变异优先级排序
- 调控机制解析

**代码示例**:
```python
import tensorflow as tf
import tensorflow_hub as hub

# 加载 Enformer
model = hub.load("https://tfhub.dev/deepmind/enformer/1").model

# 输入：200kb 序列 one-hot 编码
# 形状: (batch, 196608, 4)
sequence = tf.random.uniform((1, 196608, 4))

# 预测
predictions = model.predict_on_batch(sequence)

# 输出形状: (batch, 896, 5313)
# 896 bins × 5313 tracks
print(f"预测形状: {predictions['human'].shape}")
```

**论文**: Avsec, Ž. et al. (2021). Effective gene expression prediction from sequence by integrating long-range interactions. *Nature Methods*, 18, 1196–1203.

---

### 5. GENA-LM（2023）

**架构**: BERT-based

**训练数据**: 
- T2T（Telomere-to-Telomere）完整人类基因组
- 包含着丝粒、端粒等传统方法难以组装的区域

**特点**:
- 首个基于完整人类基因组的模型
- 覆盖之前参考基因组缺失的区域

**论文**: Fishman, D. et al. (2023). GENA-LM: A Family of Open-Source Foundational DNA Language Models for Long Sequences. *bioRxiv*.

---

## 应用场景

### 1. 变异效应预测

**任务**: 预测单核苷酸变异（SNV）、插入/删除（Indel）对基因功能或表达的影响

**方法**:
1. 输入参考序列和变异序列
2. 获取两者的模型预测
3. 计算预测差异作为变异效应评分

**应用**:
- 致病性变异识别
- GWAS 功能注释
- 个性化医疗

**代码示例**:
```python
def predict_variant_effect(model, tokenizer, ref_seq, alt_seq):
    """
    预测变异效应
    
    Args:
        model: 预训练 DNA 模型
        tokenizer: tokenizer
        ref_seq: 参考序列
        alt_seq: 变异序列
    
    Returns:
        effect_score: 变异效应评分
    """
    # Tokenize
    ref_inputs = tokenizer(ref_seq, return_tensors="pt")
    alt_inputs = tokenizer(alt_seq, return_tensors="pt")
    
    # 预测
    with torch.no_grad():
        ref_outputs = model(**ref_inputs)
        alt_outputs = model(**alt_inputs)
    
    # 计算差异（示例：使用 logits 的 L2 距离）
    ref_logits = ref_outputs.logits
    alt_logits = alt_outputs.logits
    effect_score = torch.norm(ref_logits - alt_logits).item()
    
    return effect_score

# 示例
ref_seq = "ATCGATCG"
alt_seq = "ATCTATCG"  # C->T 变异
score = predict_variant_effect(model, tokenizer, ref_seq, alt_seq)
print(f"变异效应评分: {score}")
```

---

### 2. 启动子识别

**任务**: 识别 DNA 序列中的启动子区域

**方法**:
1. 在启动子/非启动子数据上微调
2. 对新序列进行分类

**数据集**:
- EPDnew: 真核启动子数据库
- FANTOM5: CAGE 数据

**代码示例**:
```python
from transformers import AutoModelForSequenceClassification, Trainer, TrainingArguments
import torch

# 加载预训练模型并添加分类头
model = AutoModelForSequenceClassification.from_pretrained(
    "zhihan1996/DNA_bert_6",
    num_labels=2  # 二分类：启动子/非启动子
)

# 准备数据（示例）
train_sequences = ["ATCG...", "GCTA..."]  # 启动子序列
train_labels = [1, 0]  # 1=启动子, 0=非启动子

# 微调（省略数据处理细节）
training_args = TrainingArguments(
    output_dir="./promoter_model",
    num_train_epochs=3,
    per_device_train_batch_size=16,
    learning_rate=5e-5
)

trainer = Trainer(
    model=model,
    args=training_args,
    # train_dataset=train_dataset,
    # eval_dataset=eval_dataset,
)

# trainer.train()
```

---

### 3. 转录因子结合位点预测

**任务**: 预测转录因子（TF）在基因组上的结合位点

**方法**:
- 输入：DNA 序列 + TF 信息
- 输出：结合概率

**应用**:
- 调控网络构建
- 增强子-启动子互作预测

---

### 4. 剪接位点预测

**任务**: 预测 mRNA 前体的剪接供体/受体位点

**经典位点信号**:
- 供体位点（Donor）: GT（保守）
- 受体位点（Acceptor）: AG（保守）

**挑战**: 
- 隐性剪接位点
- 可变剪接

**代码示例**:
```python
# 使用 DNABERT 预测剪接位点
def predict_splice_site(sequence, model, tokenizer):
    """
    预测序列中的剪接位点
    """
    inputs = tokenizer(sequence, return_tensors="pt")
    outputs = model(**inputs)
    
    # 获取每个位置的预测
    logits = outputs.logits
    predictions = torch.argmax(logits, dim=-1)
    
    return predictions
```

---

### 5. 表观遗传修饰预测

**任务**: 预测 DNA 甲基化、组蛋白修饰等表观遗传标记

**输入**: DNA 序列

**输出**: 修饰概率

**应用**:
- 癌症表观遗传标志识别
- 发育调控研究

---

## 模型比较

| 模型 | 架构 | 上下文长度 | 参数量 | 训练数据 | 特点 |
|------|------|-----------|--------|---------|------|
| **DNABERT** | BERT | 512 bp | 110M | 人类基因组 | k-mer tokenization，经典 |
| **Nucleotide Transformer** | Transformer | 6 kb | 500M-2.5B | 3,202 物种 | 跨物种，大规模 |
| **HyenaDNA** | Hyena operator | 1M bp | 数千万 | 人类基因组 | 超长上下文，高效 |
| **Enformer** | Transformer + CNN | 200 kb | 未公开 | ENCODE 数据 | 预测表观遗传特征 |
| **GENA-LM** | BERT | 数 kb | 未公开 | T2T 基因组 | 完整基因组覆盖 |

---

## 评估指标

### 序列预测任务

- **准确率（Accuracy）**: 分类任务
- **AUROC / AUPRC**: 二分类性能
- **F1 Score**: 平衡精确率与召回率

### 生成任务

- **困惑度（Perplexity）**: 语言模型质量
- **序列似然**: 生成序列的合理性

### 变异效应预测

- **Spearman 相关系数**: 预测评分与实验数据相关性
- **分类准确率**: 致病/良性变异分类

---

## 实践工具

### Hugging Face Transformers

```python
from transformers import AutoTokenizer, AutoModel

# 加载任意 DNA 模型
tokenizer = AutoTokenizer.from_pretrained("model_name")
model = AutoModel.from_pretrained("model_name")
```

### DNABERT 工具包

GitHub: [DNABERT](https://github.com/jerryji1993/DNABERT)

包含预训练模型、微调脚本、评估工具。

### Enformer 工具

TensorFlow Hub: [Enformer](https://tfhub.dev/deepmind/enformer/1)

### HyenaDNA

GitHub: [HyenaDNA](https://github.com/HazyResearch/hyena-dna)

---

## 挑战与未来方向

### 当前挑战

1. **上下文长度限制**
   - 人类基因组 3Gb，现有模型最长 1M bp
   - 染色体级调控互作难以建模

2. **物种泛化**
   - 多数模型专注人类基因组
   - 跨物种迁移效果有限

3. **可解释性**
   - 模型决策机制不透明
   - 难以提取生物学洞见

4. **数据偏差**
   - 训练数据多来自欧洲人群
   - 对其他人群的泛化能力弱

---

### 未来方向

1. **更长上下文**
   - 全染色体级模型
   - 高效长程注意力机制

2. **多模态整合**
   - DNA 序列 + 表观遗传数据
   - 序列 + 3D 染色质结构

3. **跨物种统一模型**
   - 学习进化保守特征
   - 提升少样本物种的预测

4. **因果推断**
   - 从相关性到因果关系
   - 理解调控机制

5. **个性化基因组建模**
   - 整合个体变异信息
   - 精准医疗应用

---

## 学习资源

### 论文

- Ji, Y. et al. (2021). DNABERT. *Bioinformatics*.
- Avsec, Ž. et al. (2021). Enformer. *Nature Methods*.
- Nguyen, E. et al. (2023). HyenaDNA. *NeurIPS 2023*.

### 教程

- [DNABERT Tutorial](https://github.com/jerryji1993/DNABERT)
- [Hugging Face Genomics Models](https://huggingface.co/models?pipeline_tag=feature-extraction&search=dna)

### 课程

- Deep Learning in Genomics (Stanford)
- Computational Genomics (MIT OpenCourseWare)

---

## 相关链接

- [AI4S 专题主页](index.md)
- [RNA Foundation Models](foundation-models-rna.md)
- [蛋白质 Foundation Models](foundation-models-protein.md)
- [AI4Drug](ai4drug-overview.md)
- [虚拟细胞](virtual-cell.md)

---

更新时间：2026-09-29

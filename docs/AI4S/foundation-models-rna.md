# RNA Foundation Models

RNA 在基因表达调控中扮演核心角色，从转录、剪接、翻译到降解的每个环节都受到精密调控。RNA Foundation Models 通过学习大规模 RNA 序列数据，捕捉序列-结构-功能关系，能够预测 RNA 稳定性、剪接模式、二级结构、蛋白质相互作用等关键特性。

---

## RNA 的独特性

### RNA vs DNA

**功能多样性**:
- **DNA**: 主要负责信息存储
- **RNA**: 
  - mRNA: 蛋白质编码
  - tRNA: 翻译适配器
  - rRNA: 核糖体组成
  - ncRNA: 调控功能（miRNA, lncRNA, circRNA）

**结构复杂性**:
- **DNA**: 双链螺旋，结构相对稳定
- **RNA**: 单链，形成复杂二级/三级结构（发夹、假结、茎环）

**化学差异**:
- RNA 含核糖（ribose），DNA 含脱氧核糖
- RNA 使用尿嘧啶（U）代替胸腺嘧啶（T）
- RNA 更易降解

---

### 为什么需要 RNA Foundation Models？

**挑战**:
1. **序列-结构耦合**: RNA 功能依赖于二级/三级结构
2. **剪接复杂性**: 一个基因可产生多个 mRNA 异构体
3. **表达调控**: mRNA 稳定性、定位、翻译效率
4. **RNA 修饰**: m6A, pseudouridine 等化学修饰影响功能

**Foundation Models 的优势**:
- 整合序列和结构信息
- 学习跨物种保守模式
- 迁移到低资源 RNA 类型
- 预测修饰位点和功能效应

---

## 经典模型

### 1. RNA-FM（2022）

**全称**: RNA Foundation Model

**架构**: BERT-like Transformer

**训练数据**:
- RNAcentral 数据库
- 23.7M RNA 序列
- 涵盖多种 RNA 类型（mRNA, rRNA, tRNA, ncRNA）

**预训练任务**:
- Masked Language Modeling（MLM）

**输入表示**: 单核苷酸 token（A, U, G, C）

**模型规模**:
- 约 100M 参数
- 12 层 Transformer

**下游任务**:
- RNA 二级结构预测
- ncRNA 分类
- RNA-蛋白质相互作用预测
- RNA 修饰位点预测

**性能**:
- 在多个 RNA 任务上超越从头训练的模型
- 零样本迁移到新 RNA 类型

**代码示例**:
```python
import torch
import fm

# 加载 RNA-FM
model, alphabet = fm.pretrained.rna_fm_t12()
batch_converter = alphabet.get_batch_converter()
model.eval()

# RNA 序列
data = [
    ("RNA1", "GGGAAACCC"),
    ("RNA2", "UCGAUCGAUCGAU"),
]

# 准备批次
batch_labels, batch_strs, batch_tokens = batch_converter(data)

# 提取特征
with torch.no_grad():
    results = model(batch_tokens, repr_layers=[12])
    token_embeddings = results["representations"][12]

print(f"嵌入形状: {token_embeddings.shape}")
# 输出: (batch_size, seq_len, hidden_dim)
```

**论文**: Chen, J. et al. (2022). Interpretable RNA Foundation Model from Unannotated Data for Highly Accurate RNA Structure and Function Predictions. *arXiv:2204.00300*.

---

### 2. RNABert（2023）

**架构**: BERT

**训练数据**:
- RNAcentral + Rfam
- 约 30M RNA 序列

**特点**:
- 专注于 ncRNA（非编码 RNA）
- 学习 RNA 家族特征
- 支持 RNA 功能预测

**输入表示**: k-mer（类似 DNABERT）

**下游任务**:
- RNA 家族分类
- ncRNA 功能注释
- RNA 相互作用预测

---

### 3. SpliceBERT（2023）

**专门化**: 专注于 mRNA 剪接

**架构**: BERT

**训练数据**:
- 人类外显子-内含子边界序列
- GENCODE 注释

**预训练任务**:
- MLM
- 剪接位点分类（供体/受体/非剪接位点）

**下游任务**:
- 剪接位点预测
- 可变剪接事件检测
- 剪接因子结合预测

**性能**:
- 在剪接位点预测上达到 SOTA
- 预测罕见/隐性剪接位点

**代码示例**:
```python
from transformers import AutoTokenizer, AutoModel

# 加载 SpliceBERT
tokenizer = AutoTokenizer.from_pretrained("biomed-ai/splicebert-510nt")
model = AutoModel.from_pretrained("biomed-ai/splicebert-510nt")

# mRNA 序列（外显子-内含子边界）
sequence = "AGGUAAGU...CAGGU"  # 供体位点附近序列

# Tokenize
inputs = tokenizer(sequence, return_tensors="pt")

# 提取嵌入
with torch.no_grad():
    outputs = model(**inputs)
    embeddings = outputs.last_hidden_state

print(f"嵌入: {embeddings.shape}")
```

**论文**: Chen, K. et al. (2023). SpliceBERT: A pre-trained model for splice site prediction. *bioRxiv*.

---

### 4. RNA-MSM（Multi-Species Model）（2023）

**特点**: 跨物种 RNA 预训练

**训练数据**:
- 多物种 RNA 序列（细菌、古菌、真核生物）
- 学习进化保守特征

**应用**:
- 跨物种功能预测
- 比较转录组学

---

### 5. UTR-LM（2023）

**专门化**: 5' 和 3' UTR（非翻译区）

**训练数据**: 
- 人类 5'UTR 和 3'UTR 序列
- eCLIP 数据（RBP 结合）

**下游任务**:
- mRNA 稳定性预测
- 翻译效率预测
- RBP（RNA 结合蛋白）结合位点预测
- miRNA 靶标预测

**应用**:
- mRNA 疫苗设计（优化 UTR 提高稳定性）
- 基因治疗载体优化

---

## 应用场景

### 1. RNA 二级结构预测

**任务**: 预测 RNA 的二级结构（碱基配对模式）

**传统方法**:
- **ViennaRNA**: 基于热力学自由能最小化
- **RNAfold**: 动态规划算法

**深度学习方法**:
- **SPOT-RNA**: CNN + LSTM
- **E2Efold**: 端到端学习
- **RNA-FM + 结构预测头**: 预训练 + 微调

**评估指标**:
- F1 score（碱基配对预测）
- Matthews Correlation Coefficient（MCC）

**代码示例**:
```python
# 使用 RNA-FM 预测二级结构
import fm
import torch

# 加载模型
model, alphabet = fm.pretrained.rna_fm_t12()
model.eval()

# RNA 序列
sequence = "GGGAAACCCUUUGGGUUUCCC"

# 编码
batch_converter = alphabet.get_batch_converter()
data = [("RNA", sequence)]
_, _, batch_tokens = batch_converter(data)

# 预测接触图
with torch.no_grad():
    results = model(batch_tokens, need_head_weights=True)
    attention = results["attentions"]  # 注意力权重可用于接触预测

# 解析二级结构（简化示例）
# 实际需要后处理将注意力转换为配对概率
```

---

### 2. mRNA 稳定性预测

**任务**: 预测 mRNA 的半衰期

**重要性**:
- mRNA 疫苗设计（提高稳定性）
- 基因表达调控理解
- 治疗性 mRNA 优化

**特征**:
- 5' UTR 序列
- 3' UTR 序列（ARE 元件）
- Poly(A) 尾长度
- 密码子优化

**数据集**:
- Saluki dataset（人类 mRNA 半衰期）
- 高通量测序实验数据

**代码示例**:
```python
from transformers import AutoModelForSequenceClassification

# 假设已微调的 mRNA 稳定性预测模型
model = AutoModelForSequenceClassification.from_pretrained(
    "rna-stability-model",
    num_labels=1  # 回归：预测半衰期
)

# mRNA 序列（5'UTR + CDS + 3'UTR）
mrna_sequence = "AGCUAGCU...AAAAAA"

# Tokenize
inputs = tokenizer(mrna_sequence, return_tensors="pt")

# 预测半衰期
with torch.no_grad():
    outputs = model(**inputs)
    predicted_half_life = outputs.logits.item()

print(f"预测半衰期: {predicted_half_life} 小时")
```

---

### 3. 剪接预测

**任务**: 预测可变剪接事件

**剪接类型**:
- **外显子跳跃（Exon Skipping, SE）**
- **可变 5' 剪接位点（A5SS）**
- **可变 3' 剪接位点（A3SS）**
- **内含子保留（Intron Retention, IR）**
- **互斥外显子（Mutually Exclusive Exons, MXE）**

**工具**:
- **SpliceAI**: 深度学习剪接预测（CNN）
- **SpliceBERT**: 基于 Transformer
- **MMSplice**: 模块化剪接模型

**应用**:
- 疾病相关剪接变异识别
- 剪接调控机制研究

**代码示例**:
```python
# 使用 SpliceAI 预测剪接效应
from spliceai import predict_splice

sequence = "AGGTAAGT...TGCAG"  # 包含剪接位点的序列
position = 100  # 变异位置

# 预测
scores = predict_splice(sequence, position)
print(f"供体位点增益: {scores['donor_gain']}")
print(f"受体位点损失: {scores['acceptor_loss']}")
```

---

### 4. RNA 修饰预测

**常见 RNA 修饰**:
- **m6A（N6-甲基腺苷）**: 最常见的 mRNA 修饰
- **pseudouridine（Ψ）**: 假尿苷
- **m5C（5-甲基胞嘧啶）**
- **m1A（N1-甲基腺苷）**

**功能**:
- 影响 mRNA 稳定性
- 调控翻译效率
- 影响 RNA 结构

**预测方法**:
- 基于序列 motif（DRACH 为 m6A motif）
- 深度学习模型（CNN, RNN, Transformer）

**数据集**:
- MeRIP-seq / m6A-seq 数据
- 高通量修饰检测数据

**代码示例**:
```python
# 预测 m6A 修饰位点
def predict_m6a(sequence, model, tokenizer):
    """
    预测序列中的 m6A 修饰位点
    """
    inputs = tokenizer(sequence, return_tensors="pt")
    
    with torch.no_grad():
        outputs = model(**inputs)
        probs = torch.sigmoid(outputs.logits)
    
    # 找到高概率位点
    m6a_sites = (probs > 0.5).nonzero(as_tuple=True)[1]
    
    return m6a_sites.tolist()

# 示例
rna_seq = "AGACUGGACUUAAA"
sites = predict_m6a(rna_seq, model, tokenizer)
print(f"预测 m6A 位点: {sites}")
```

---

### 5. RNA-蛋白质相互作用预测

**任务**: 预测 RNA 结合蛋白（RBP）的结合位点

**重要性**:
- 理解转录后调控
- 识别 RBP 靶标
- 设计 RNA 干扰工具

**方法**:
- **CLIP-seq 数据**: 交联免疫沉淀测序
- **深度学习**: 学习 RBP 结合 motif

**数据集**:
- ENCODE eCLIP 数据
- 数百个 RBP 的结合谱

**代码示例**:
```python
# RBP 结合预测
class RBPBindingPredictor(nn.Module):
    def __init__(self, rna_model):
        super().__init__()
        self.rna_encoder = rna_model
        self.classifier = nn.Linear(rna_model.config.hidden_size, 1)
    
    def forward(self, input_ids):
        embeddings = self.rna_encoder(input_ids).last_hidden_state
        pooled = embeddings.mean(dim=1)  # 平均池化
        logits = self.classifier(pooled)
        return logits

# 预测
model = RBPBindingPredictor(rna_fm_model)
sequence = "AGCUAGCU"
prediction = model(tokenizer(sequence, return_tensors="pt")["input_ids"])
print(f"RBP 结合概率: {torch.sigmoid(prediction).item()}")
```

---

### 6. 单细胞 RNA 分析

**任务**: 从单细胞 RNA-seq 数据中识别细胞类型、状态、轨迹

**传统工具**:
- Scanpy, Seurat（基于统计方法）

**Foundation Model 增强**:
- **scGPT**: 单细胞基因表达 Transformer
- **Geneformer**: 单细胞基因表达基础模型
- **scBERT**: 单细胞 BERT

**应用**:
- 细胞类型注释
- 细胞轨迹推断
- 基因扰动预测
- 细胞-细胞通讯

---

## 技术细节

### 输入表示

**单核苷酸 tokenization**:
```python
sequence = "AUCGAUCG"
tokens = ["A", "U", "C", "G", "A", "U", "C", "G"]
```

**k-mer tokenization**:
```python
sequence = "AUCGAUCG"
k = 3
kmers = ["AUC", "UCG", "CGA", "GAU", "AUC", "UCG"]
```

**结构感知编码**:
- 同时编码序列和二级结构
- 使用括号记号表示配对：`(((...)))`

---

### 预训练策略

**Masked Language Modeling（MLM）**:
```
原始序列:  A U C G A U C G
遮盖序列:  A [MASK] C G [MASK] U C G
预测目标:  U, A
```

**结构预测任务**:
- 预测碱基配对
- 预测接触图

**对比学习**:
- 学习相似 RNA 的表示相近
- 区分不同功能的 RNA

---

## 数据资源

### RNA 序列数据库

- **RNAcentral**: 非编码 RNA 综合数据库
- **Rfam**: RNA 家族数据库
- **GENCODE**: 人类和小鼠基因注释
- **miRBase**: miRNA 数据库

### 实验数据

- **ENCODE**: 表观基因组和转录组数据
- **GTEx**: 人类组织基因表达
- **GEO**: 基因表达数据库

### 结构数据

- **PDB**: RNA 三维结构
- **RNA Strand**: RNA 二级结构数据库
- **bpRNA**: 大规模 RNA 二级结构数据集

---

## 评估指标

### 分类任务

- **准确率（Accuracy）**
- **AUROC / AUPRC**
- **F1 Score**

### 结构预测

- **F1 Score**: 碱基配对预测
- **PPV / Sensitivity**: 阳性预测值 / 灵敏度
- **MCC**: Matthews 相关系数

### 回归任务

- **Pearson / Spearman 相关系数**
- **RMSE / MAE**

---

## 模型比较

| 模型 | 架构 | 训练数据 | 参数量 | 专门化 | 特点 |
|------|------|---------|--------|--------|------|
| **RNA-FM** | BERT | RNAcentral (23.7M) | 100M | 通用 | 多 RNA 类型 |
| **RNABert** | BERT | RNAcentral + Rfam | 未公开 | ncRNA | 家族分类 |
| **SpliceBERT** | BERT | 人类剪接位点 | 未公开 | 剪接 | 高精度剪接预测 |
| **UTR-LM** | BERT | 人类 UTR | 未公开 | UTR | 稳定性/翻译 |
| **RNA-MSM** | Transformer | 多物种 | 未公开 | 跨物种 | 进化保守性 |

---

## 实践工具

### RNA-FM

GitHub: [RNA-FM](https://github.com/ml4bio/RNA-FM)

```bash
# 安装
pip install rna-fm

# 提取特征
python scripts/extract_features.py \
    --model rna_fm_t12 \
    --fasta input.fasta \
    --output embeddings.pt
```

---

### ViennaRNA（传统方法对比）

```python
import RNA

# 序列
sequence = "GGGAAACCC"

# 预测最小自由能结构
structure, mfe = RNA.fold(sequence)
print(f"结构: {structure}")
print(f"MFE: {mfe} kcal/mol")

# 配对概率
fc = RNA.fold_compound(sequence)
fc.pf()
bp_prob = fc.bpp()
```

---

## 挑战与未来方向

### 当前挑战

1. **结构复杂性**
   - 三级结构预测困难
   - 假结（pseudoknot）难以建模

2. **数据稀缺**
   - 实验标注数据少
   - 某些 RNA 类型研究不足

3. **长序列建模**
   - lncRNA 可达数万碱基
   - 上下文窗口限制

4. **动态性**
   - RNA 结构动态变化
   - 细胞环境影响

---

### 未来方向

1. **序列-结构联合建模**
   - 同时预测序列和结构
   - 学习结构-功能关系

2. **多模态 RNA 模型**
   - 整合序列、结构、表达、修饰数据
   - 全面理解 RNA 功能

3. **可解释 RNA 模型**
   - 识别功能 motif
   - 理解调控机制

4. **RNA 设计**
   - 从功能到序列的逆向设计
   - mRNA 疫苗、治疗性 RNA 优化

5. **动态建模**
   - 捕捉 RNA 结构动态
   - 模拟折叠路径

---

## 学习资源

### 论文

- Chen, J. et al. (2022). RNA-FM. *arXiv:2204.00300*.
- Jaganathan, K. et al. (2019). SpliceAI. *Cell*.
- Chen, K. et al. (2023). SpliceBERT. *bioRxiv*.

### 在线资源

- [RNA-FM GitHub](https://github.com/ml4bio/RNA-FM)
- [ViennaRNA Package](https://www.tbi.univie.ac.at/RNA/)
- [RNAcentral](https://rnacentral.org/)

### 课程

- RNA Biology (MIT OpenCourseWare)
- Computational RNA Biology (Coursera)

---

## 相关链接

- [AI4S 专题主页](index.md)
- [DNA Foundation Models](foundation-models-dna.md)
- [蛋白质 Foundation Models](foundation-models-protein.md)
- [AI4Drug](ai4drug-overview.md)
- [虚拟细胞](virtual-cell.md)

---

更新时间：2026-09-29

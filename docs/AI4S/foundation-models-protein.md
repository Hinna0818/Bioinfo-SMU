# 蛋白质 Foundation Models

蛋白质是生命功能的执行者，其序列、结构和功能之间存在复杂的关系。蛋白质 Foundation Models 通过在海量蛋白质序列和结构数据上预训练，学习蛋白质的语法、结构模式和功能原理，实现从结构预测到功能注释、从突变效应评估到蛋白质设计的全方位应用。

---

## 蛋白质的复杂性

### 序列-结构-功能关系

**蛋白质的层次结构**:

1. **一级结构（Primary Structure）**
   - 氨基酸序列
   - 20 种标准氨基酸
   - 序列长度：数十到数千个残基

2. **二级结构（Secondary Structure）**
   - α-螺旋（Alpha Helix）
   - β-折叠（Beta Sheet）
   - 无规卷曲（Coil/Loop）

3. **三级结构（Tertiary Structure）**
   - 完整的三维折叠
   - 由疏水作用、氢键、二硫键等稳定
   - 决定蛋白质功能

4. **四级结构（Quaternary Structure）**
   - 多个亚基组装
   - 蛋白质复合物

---

### Anfinsen 定理

**核心原理**: 蛋白质的三维结构由其氨基酸序列唯一决定。

这一定理为从序列预测结构提供了理论基础，也是 AlphaFold 等模型的科学依据。

---

### 为什么需要 Foundation Models？

**挑战**:
1. **蛋白质空间巨大**: 100 个氨基酸的蛋白质有 20^100 种可能序列
2. **结构预测困难**: 实验方法（X-ray、Cryo-EM、NMR）耗时耗力
3. **功能注释稀疏**: 已知功能的蛋白质仅占很小比例
4. **进化信息**: 同源蛋白质的变异模式包含功能约束

**Foundation Models 的优势**:
- 学习进化保守性和变异耐受性
- 从序列直接预测结构（快速、低成本）
- 零样本功能预测和迁移学习
- 指导蛋白质工程和药物设计

---

## 序列模型

### 1. ESM（Evolutionary Scale Modeling）系列

#### ESM-1b（2021）

**架构**: Transformer encoder

**训练数据**: 
- UniRef50（2.5 千万蛋白质序列）

**预训练任务**: Masked Language Modeling（MLM）

**模型规模**: 650M 参数

---

#### ESM-2（2022）

**突破**: 将模型规模扩展到 150B 参数

**训练数据**: 
- UniRef（2.5 亿蛋白质序列）

**模型版本**:
- ESM2-8M (8M 参数)
- ESM2-35M
- ESM2-150M
- ESM2-650M
- ESM2-3B
- ESM2-15B

**关键发现**: 
- **650M 参数版本性能最优**（更大模型反而性能下降）
- 学习到的表示与蛋白质结构高度相关
- 零样本迁移能力强

**下游任务**:
- 蛋白质结构预测（ESMFold）
- 蛋白质功能预测
- 突变效应预测
- 蛋白质-蛋白质相互作用预测

**代码示例**:
```python
import torch
import esm

# 加载 ESM-2 模型
model, alphabet = esm.pretrained.esm2_t33_650M_UR50D()
batch_converter = alphabet.get_batch_converter()
model.eval()

# 蛋白质序列
data = [
    ("protein1", "MKTAYIAKQRQISFVKSHFSRQ"),
    ("protein2", "MQIFVKTLTGKTITLEVEPSDTIENVKAKIQDKEGIPPDQQRLIFAGKQLEDGR"),
]

# 准备批次
batch_labels, batch_strs, batch_tokens = batch_converter(data)

# 提取特征
with torch.no_grad():
    results = model(batch_tokens, repr_layers=[33], return_contacts=True)

# Token 嵌入（每个残基）
token_embeddings = results["representations"][33]

# 序列嵌入（整个蛋白质）
sequence_embeddings = token_embeddings.mean(dim=1)

# 接触图预测
contacts = results["contacts"]

print(f"Token 嵌入形状: {token_embeddings.shape}")
print(f"序列嵌入形状: {sequence_embeddings.shape}")
print(f"接触图形状: {contacts.shape}")
```

**论文**: Lin, Z. et al. (2023). Evolutionary-scale prediction of atomic-level protein structure with a language model. *Science*, 379(6637), 1123-1130.

---

### 2. ProtGPT2（2022）

**架构**: GPT-2（生成式）

**训练数据**: 
- UniRef50（5000 万蛋白质序列）

**预训练任务**: 
- 自回归语言建模（Next Token Prediction）

**特点**:
- **生成模型**: 可以从头生成新的蛋白质序列
- 学习蛋白质序列的概率分布

**应用**:
- De novo 蛋白质设计
- 序列完成与优化
- 蛋白质变体生成

**代码示例**:
```python
from transformers import pipeline

# 加载 ProtGPT2
generator = pipeline('text-generation', model="nferruz/ProtGPT2")

# 从提示序列生成蛋白质
seed_sequence = "MKTAYIA"
generated = generator(seed_sequence, max_length=100, do_sample=True)

print(f"生成的蛋白质序列: {generated[0]['generated_text']}")
```

**论文**: Ferruz, N. et al. (2022). ProtGPT2 is a deep unsupervised language model for protein design. *Nature Communications*, 13, 4348.

---

### 3. ProteinBERT（2022）

**架构**: BERT

**特点**: 整合序列和 GO（Gene Ontology）注释

**训练数据**:
- UniRef90 + SwissProt GO 注释

**预训练任务**:
- MLM
- GO 注释预测

**优势**: 明确学习功能信息

---

### 4. Ankh（2023）

**架构**: 大规模 Transformer（最大 1.5B 参数）

**训练数据**: 
- UniRef100 + Pfam + 元基因组数据
- 数亿蛋白质序列

**特点**:
- 多语言蛋白质模型（跨物种）
- 规模化提升性能

---

### 5. ProGen（2020, 2023）

**架构**: Transformer decoder

**训练数据**: 
- UniRef90 + 条件标签（蛋白质家族、物种）

**特点**:
- 条件生成：根据蛋白质家族生成序列
- ProGen2: 扩展到 6.4B 参数

**应用**:
- 蛋白质家族特异性设计
- 酶工程

---

## 结构模型

### 1. AlphaFold2（2021）

**突破性意义**: 解决了蛋白质结构预测这一 50 年难题

**架构**:
- Evoformer: 处理多序列比对（MSA）和配对表示
- Structure Module: 生成三维坐标

**输入**:
- 目标序列
- MSA（多序列比对，来自同源搜索）
- 模板结构（可选）

**训练数据**: 
- PDB（约 17 万结构）

**关键技术**:
1. **MSA 表示**: 编码进化信息
2. **配对表示**: 残基-残基关系
3. **Evoformer 模块**: 联合更新 MSA 和配对表示
4. **结构模块**: 迭代细化三维结构
5. **等变性**: 保持旋转和平移不变性

**性能**:
- CASP14: 中位 GDT 92.4（接近实验精度）
- 预测时间: 数分钟到数小时

**代码示例**:
```python
# 使用 AlphaFold2 通过 ColabFold
from colabfold import plot_protein
from colabfold.batch import get_queries, run

# 序列
sequence = "MKTAYIAKQRQISFVKSHFSRQ"

# 运行预测（简化示例）
# results = run(sequence)

# 可视化
# plot_protein(results)
```

**影响**:
- AlphaFold Protein Structure Database: 2 亿+ 预测结构
- 加速结构生物学研究
- 推动药物设计、蛋白质工程

**论文**: Jumper, J. et al. (2021). Highly accurate protein structure prediction with AlphaFold. *Nature*, 596, 583–589.

---

### 2. AlphaFold3（2024）

**扩展**: 预测蛋白质-配体、蛋白质-核酸复合物

**输入**:
- 蛋白质序列
- 配体 SMILES
- DNA/RNA 序列

**输出**: 复合物三维结构

**应用**:
- 药物-靶点复合物预测
- 蛋白质-DNA 复合物（转录因子）
- 蛋白质-RNA 复合物（RBP）

**性能**: 
- 蛋白质-配体对接精度超越传统分子对接
- 革新结构药物设计

**论文**: Abramson, J. et al. (2024). Accurate structure prediction of biomolecular interactions with AlphaFold 3. *Nature*, 630, 493–500.

---

### 3. ESMFold（2022）

**架构**: 基于 ESM-2 语言模型 + 结构预测头

**关键特点**:
- **无需 MSA**: 从单序列预测
- **速度快**: 比 AlphaFold2 快 60 倍
- **端到端**: 从序列直接到结构

**训练数据**: 
- PDB + AlphaFold Database

**性能**:
- 高分辨率结构：接近 AlphaFold2
- 低同源性蛋白质：略逊于 AlphaFold2
- 适合大规模筛选

**代码示例**:
```python
import torch
import esm

# 加载 ESMFold
model = esm.pretrained.esmfold_v1()
model = model.eval().cuda()

# 序列
sequence = "MKTAYIAKQRQISFVKSHFSRQ"

# 预测结构
with torch.no_grad():
    output = model.infer_pdb(sequence)

# 保存 PDB
with open("predicted_structure.pdb", "w") as f:
    f.write(output)

print("结构已保存到 predicted_structure.pdb")
```

**论文**: Lin, Z. et al. (2023). Evolutionary-scale prediction of atomic-level protein structure with a language model. *Science*, 379(6637), 1123-1130.

---

### 4. OmegaFold（2022）

**架构**: Transformer

**特点**: 
- 端到端训练
- 无需 MSA（单序列预测）
- 使用蛋白质语言模型初始化

**性能**: 与 AlphaFold2 相当，速度更快

---

### 5. RoseTTAFold（2021）

**来源**: 华盛顿大学 David Baker 实验室

**架构**: 三轨网络（1D、2D、3D）

**特点**:
- 联合处理序列、距离、坐标
- 开源实现

**论文**: Baek, M. et al. (2021). Accurate prediction of protein structures and interactions using a three-track neural network. *Science*, 373(6557), 871-876.

---

## 应用场景

### 1. 突变效应预测

**任务**: 预测氨基酸突变对蛋白质功能/稳定性的影响

**方法**:
- **Zero-shot**: 直接使用预训练模型
  - 比较野生型和突变型的对数似然
  - ESM-1v: 专门针对突变效应优化

**评估数据集**:
- **ClinVar**: 临床变异数据库
- **DMS（Deep Mutational Scanning）**: 高通量突变实验

**应用**:
- 疾病相关突变识别
- 蛋白质工程
- 抗体亲和力优化

**代码示例**:
```python
import torch
import esm

# 加载 ESM-1v（变异效应模型）
model, alphabet = esm.pretrained.esm1v_t33_650M_UR90S_1()
batch_converter = alphabet.get_batch_converter()
model.eval()

# 野生型序列
wt_sequence = "MKTAYIAKQRQISFVKSHFSRQ"

# 突变序列（K3A 突变）
mut_sequence = "MKTAYIAKQAQISFVKSHFSRQ"

# 准备批次
data = [
    ("WT", wt_sequence),
    ("MUT", mut_sequence),
]
batch_labels, batch_strs, batch_tokens = batch_converter(data)

# 计算对数似然
with torch.no_grad():
    results = model(batch_tokens, repr_layers=[33])
    logits = results["logits"]
    
    # 计算序列对数似然
    log_probs = torch.log_softmax(logits, dim=-1)
    wt_ll = log_probs[0, 1:len(wt_sequence)+1, :].gather(-1, batch_tokens[0, 1:len(wt_sequence)+1].unsqueeze(-1)).sum()
    mut_ll = log_probs[1, 1:len(mut_sequence)+1, :].gather(-1, batch_tokens[1, 1:len(mut_sequence)+1].unsqueeze(-1)).sum()
    
    # 突变效应评分（越负越有害）
    effect_score = mut_ll - wt_ll

print(f"突变效应评分: {effect_score.item():.3f}")
```

---

### 2. 蛋白质功能预测

**任务**: 从序列预测蛋白质功能（GO term、EC number、细胞定位）

**方法**:
1. 使用预训练模型提取特征
2. 在标注数据上训练分类器
3. 预测功能标签

**数据集**:
- **SwissProt**: 人工审核的蛋白质数据库（含 GO 注释）
- **CAFA（Critical Assessment of Function Annotation）**: 功能预测竞赛

**代码示例**:
```python
from transformers import AutoModel, AutoTokenizer
import torch.nn as nn

# 加载预训练模型
tokenizer = AutoTokenizer.from_pretrained("Rostlab/prot_bert")
model = AutoModel.from_pretrained("Rostlab/prot_bert")

# 功能预测分类器
class FunctionPredictor(nn.Module):
    def __init__(self, protein_model, num_labels):
        super().__init__()
        self.protein_encoder = protein_model
        self.classifier = nn.Linear(protein_model.config.hidden_size, num_labels)
    
    def forward(self, input_ids):
        embeddings = self.protein_encoder(input_ids).last_hidden_state
        pooled = embeddings[:, 0, :]  # [CLS] token
        logits = self.classifier(pooled)
        return logits

# 实例化
predictor = FunctionPredictor(model, num_labels=1000)  # 1000 个 GO terms

# 预测（示例）
sequence = "M K T A Y I A K Q R Q I S F V K S H F S R Q"
inputs = tokenizer(sequence, return_tensors="pt")
predictions = predictor(inputs["input_ids"])
```

---

### 3. 蛋白质-蛋白质相互作用预测

**任务**: 预测两个蛋白质是否相互作用

**方法**:
- 将两个蛋白质序列编码
- 计算相似性或使用分类器

**应用**:
- 构建蛋白质互作网络（PPI Network）
- 药物靶点识别
- 信号通路研究

---

### 4. 蛋白质设计

**任务**: 从头设计新的蛋白质序列

**方法**:

**生成式模型**:
- ProtGPT2, ProGen: 自回归生成
- 条件生成：指定蛋白质家族、功能

**结构引导设计**:
- AlphaFold + 优化
- RFdiffusion（结构扩散模型）

**应用**:
- 酶工程（提高催化活性）
- 抗体设计（提高亲和力和特异性）
- 新型蛋白质药物

**代码示例**:
```python
from transformers import pipeline

# 使用 ProtGPT2 生成蛋白质
generator = pipeline('text-generation', model="nferruz/ProtGPT2")

# 生成属于特定家族的蛋白质
prompt = "MKTAYIA"  # 种子序列
generated_sequences = generator(
    prompt, 
    max_length=200, 
    num_return_sequences=5,
    do_sample=True,
    temperature=0.8
)

for i, seq in enumerate(generated_sequences):
    print(f"序列 {i+1}: {seq['generated_text']}")
```

---

### 5. 抗体设计与优化

**任务**: 优化抗体的亲和力、特异性、稳定性

**方法**:
- ESM-2 编码抗体序列
- 预测抗原结合区（CDR）突变效应
- 结构预测验证

**工具**:
- **ABodyBuilder**: 抗体结构预测
- **ESM-IF**: 逆向折叠（从结构生成序列）

---

## 数据资源

### 序列数据库

- **UniProt**: 综合蛋白质数据库（2 亿+ 序列）
- **UniRef50/90/100**: 聚类减少冗余
- **Pfam**: 蛋白质家族数据库
- **SwissProt**: 人工审核的高质量蛋白质数据

### 结构数据库

- **PDB（Protein Data Bank）**: 实验解析结构（20 万+）
- **AlphaFold Database**: AI 预测结构（2 亿+）
- **CATH/SCOP**: 结构分类数据库

### 功能注释

- **Gene Ontology (GO)**: 基因/蛋白质功能本体
- **InterPro**: 蛋白质家族和域注释
- **KEGG**: 代谢通路数据库

---

## 模型比较

### 序列模型

| 模型 | 架构 | 参数量 | 训练数据 | 类型 | 特点 |
|------|------|--------|---------|------|------|
| **ESM-1b** | Transformer | 650M | UniRef50 (25M) | 掩码预测 | 经典，性能优秀 |
| **ESM-2** | Transformer | 8M-15B | UniRef (250M) | 掩码预测 | 多规模，650M 最优 |
| **ProtGPT2** | GPT-2 | 738M | UniRef50 (50M) | 生成式 | 可生成新序列 |
| **ProGen2** | Transformer | 6.4B | UniRef90 + 条件 | 生成式 | 条件生成 |
| **Ankh** | Transformer | 1.5B | UniRef100 + 元基因组 | 掩码预测 | 大规模 |

### 结构模型

| 模型 | MSA 需求 | 速度 | 精度 | 特点 |
|------|---------|------|------|------|
| **AlphaFold2** | 是 | 慢（小时） | 极高 | SOTA，需 MSA |
| **AlphaFold3** | 是 | 慢 | 极高 | 复合物预测 |
| **ESMFold** | 否 | 快（秒-分钟） | 高 | 单序列，快速 |
| **OmegaFold** | 否 | 快 | 高 | 端到端 |
| **RoseTTAFold** | 是 | 中 | 高 | 开源 |

---

## 评估指标

### 结构预测

- **GDT（Global Distance Test）**: 结构相似度
- **TM-score**: 模板建模评分（>0.5 为相同折叠）
- **RMSD（Root Mean Square Deviation）**: 原子位置偏差
- **lDDT（Local Distance Difference Test）**: 局部结构精度

### 功能预测

- **AUROC / AUPRC**: 功能分类性能
- **F-max**: 最大 F1 score（CAFA 评估）

### 突变效应

- **Spearman 相关系数**: 与实验数据相关性
- **AUC**: 分类致病/良性变异

---

## 实践工具

### ESM

GitHub: [ESM](https://github.com/facebookresearch/esm)

```bash
# 安装
pip install fair-esm

# 提取嵌入
python scripts/extract.py esm2_t33_650M_UR50D protein.fasta output --repr_layers 33 --include mean
```

### AlphaFold

- **AlphaFold Colab**: 在线预测（免费 GPU）
- **ColabFold**: 加速版本，集成 MMseqs2 快速 MSA
- **LocalColabFold**: 本地部署

### ESMFold

```python
import esm

# 加载模型
model = esm.pretrained.esmfold_v1()
model = model.eval().cuda()

# 预测结构
with torch.no_grad():
    output = model.infer_pdb("MKTAYIAKQRQISFVKSHFSRQ")

# 保存 PDB
with open("structure.pdb", "w") as f:
    f.write(output)
```

---

## 前沿技术

### 1. 逆向折叠（Inverse Folding）

**任务**: 从三维结构设计氨基酸序列

**传统流程**: 序列 → 结构
**逆向折叠**: 结构 → 序列

**应用**:
- 固定结构骨架，设计新序列
- 蛋白质稳定性优化
- 功能保持的序列多样化

**模型**:

**ESM-IF（Inverse Folding）**:
- 基于 ESM 架构
- 输入：蛋白质骨架坐标
- 输出：氨基酸序列

**ProteinMPNN**:
- 消息传递神经网络
- 考虑几何约束
- 高精度序列设计

**代码示例**:
```python
# ESM-IF 逆向折叠示例
import esm.inverse_folding

# 加载模型
model, alphabet = esm.pretrained.esm_if1_gvp4_t16_142M_UR50()
model.eval()

# 输入：蛋白质结构（坐标）
coords, seq = esm.inverse_folding.util.load_coords("protein.pdb", "A")

# 设计序列
ll, seq = esm.inverse_folding.util.score_sequence(
    model, alphabet, coords, seq
)

print(f"设计的序列: {seq}")
print(f"对数似然: {ll}")
```

---

### 2. 结构扩散模型

**RFdiffusion（2023）**:

**原理**: 
- 使用扩散模型生成蛋白质骨架
- 从噪声逐步去噪得到蛋白质结构

**应用**:
- De novo 蛋白质设计
- 结合位点设计（针对特定配体/抗原）
- 蛋白质支架设计

**流程**:
1. RFdiffusion 生成骨架
2. ProteinMPNN 设计序列
3. AlphaFold2 验证结构

**成果**:
- 设计出实验验证的新型蛋白质
- 发表于 *Nature* (2023)

---

### 3. 多模态蛋白质模型

**整合多种信息**:
- 序列 + 结构
- 序列 + 功能注释
- 序列 + 文本描述

**ProtST（Protein Structure-Text）**:
- 蛋白质结构与文本描述对齐
- 类似 CLIP 的对比学习
- 支持文本查询蛋白质

**应用**:
- "找到所有激酶结构"
- "检索与免疫相关的蛋白质"

---

### 4. 小样本蛋白质学习

**挑战**: 许多蛋白质家族标注数据稀少

**方法**:
- **元学习（Meta-Learning）**: 学习快速适应新任务
- **Few-shot Learning**: 从少量样本学习
- **迁移学习**: 从大家族迁移到小家族

---

### 5. 蛋白质动力学建模

**限制**: AlphaFold 预测静态结构

**挑战**: 
- 蛋白质结构动态变化
- 构象转换影响功能

**方向**:
- 预测蛋白质构象集合
- 模拟蛋白质折叠路径
- 整合分子动力学（MD）模拟

**AlphaFold-Multimer**: 预测蛋白质复合物的多个构象

---

## 成功案例

### 1. AlphaFold 预测人类蛋白质组

**成果**:
- 预测 2 亿+ 蛋白质结构
- 覆盖人类全部约 2 万个蛋白质
- 开放下载，加速全球研究

**影响**:
- 结构生物学家可直接获取预测结构
- 加速药物靶点研究
- 推动罕见病研究（孤儿蛋白结构）

---

### 2. De novo 蛋白质设计

**案例**: David Baker 实验室（华盛顿大学）

**成果**:
- 设计出自然界不存在的蛋白质
- 实验验证结构与设计一致
- 具有预定功能（如结合特定分子）

**应用**:
- 新型酶设计
- 纳米材料
- 生物传感器

---

### 3. 抗体药物设计

**案例**: 多家生物技术公司使用 ESM/AlphaFold

**流程**:
1. ESM-2 预测抗体 CDR 区突变效应
2. AlphaFold2 预测抗体-抗原复合物结构
3. 筛选高亲和力候选抗体
4. 实验验证

**优势**:
- 减少实验轮次
- 提高成功率
- 加速研发周期

---

### 4. COVID-19 蛋白质研究

**应用**:
- AlphaFold2 预测 SARS-CoV-2 蛋白质结构
- 辅助药物设计（主蛋白酶抑制剂）
- 抗体中和机制研究

---

## 挑战与未来方向

### 当前挑战

1. **内在无序蛋白（IDPs）**
   - 没有固定三维结构
   - AlphaFold 难以建模

2. **蛋白质动态性**
   - 静态结构预测为主
   - 构象变化、蛋白质折叠路径

3. **复合物预测**
   - AlphaFold-Multimer 性能有限
   - 瞬时相互作用难预测

4. **实验验证瓶颈**
   - AI 设计的蛋白质需实验验证
   - 高通量实验成本仍高

5. **可解释性**
   - 模型决策机制不透明
   - 难以提取生物学规律

---

### 未来方向

1. **统一序列-结构-功能模型**
   - 端到端学习
   - 多任务联合训练

2. **蛋白质生成模型**
   - 从功能需求生成序列
   - 可控生成（指定折叠、功能）

3. **闭环蛋白质设计**
   - AI 设计 → 高通量实验 → 反馈 → 迭代优化
   - 自动化实验室（Robot Scientist）

4. **跨模态学习**
   - 整合序列、结构、基因表达、文献
   - 知识图谱与蛋白质模型融合

5. **个性化蛋白质组学**
   - 整合个体变异
   - 预测疾病相关蛋白质变化

6. **进化建模**
   - 预测蛋白质进化轨迹
   - 理解适应性变异

---

## 学习资源

### 论文

**经典论文**:
- Jumper, J. et al. (2021). AlphaFold. *Nature*.
- Lin, Z. et al. (2023). ESM-2 & ESMFold. *Science*.
- Ferruz, N. et al. (2022). ProtGPT2. *Nature Communications*.
- Watson, J. et al. (2023). De novo design by deep learning. *Nature*.

**综述**:
- Pearce, R. & Zhang, Y. (2021). Deep learning techniques have significantly impacted protein structure prediction. *Nature Methods*.
- AlQuraishi, M. (2019). AlphaFold at CASP13. *Bioinformatics*.

---

### 在线课程

- **Deep Learning in Life Sciences (MIT)**: 深度学习在生命科学中的应用
- **Protein Structure Prediction (Coursera)**: 蛋白质结构预测
- **Machine Learning for Proteins (Stanford)**: 蛋白质机器学习

---

### 教程与工具

**AlphaFold**:
- [AlphaFold Colab](https://colab.research.google.com/github/deepmind/alphafold/blob/main/notebooks/AlphaFold.ipynb)
- [ColabFold](https://github.com/sokrypton/ColabFold)

**ESM**:
- [ESM GitHub](https://github.com/facebookresearch/esm)
- [ESM Tutorial](https://github.com/facebookresearch/esm/tree/main/examples)

**RoseTTAFold**:
- [RoseTTAFold GitHub](https://github.com/RosettaCommons/RoseTTAFold)

**可视化**:
- **PyMOL**: 蛋白质结构可视化
- **ChimeraX**: UCSF 开发的分子可视化工具
- **Mol***: 在线结构浏览器

---

### 书籍

- 《Protein Structure Prediction》（Mohammed AlQuraishi 等）
- 《Deep Learning for Protein Science》
- 《Bioinformatics and Functional Genomics》（Jonathan Pevsner）

---

### 社区与竞赛

**CASP（Critical Assessment of Structure Prediction）**:
- 两年一次的蛋白质结构预测竞赛
- 评估最新方法性能

**CAFA（Critical Assessment of Function Annotation）**:
- 蛋白质功能预测竞赛

---

## 实用建议

### 如何选择模型？

**场景 1: 快速结构预测**
- 推荐：**ESMFold**
- 原因：无需 MSA，秒级预测

**场景 2: 高精度结构预测**
- 推荐：**AlphaFold2**（通过 ColabFold）
- 原因：精度最高，MSA 搜索优化

**场景 3: 蛋白质复合物**
- 推荐：**AlphaFold-Multimer** 或 **AlphaFold3**
- 原因：专门优化复合物预测

**场景 4: 突变效应预测**
- 推荐：**ESM-1v**
- 原因：专门训练，零样本预测

**场景 5: 蛋白质设计**
- 推荐：**ProtGPT2** 或 **ProGen2**
- 原因：生成式模型

**场景 6: 功能预测**
- 推荐：**ESM-2** + 微调
- 原因：通用表示，迁移能力强

---

### 计算资源需求

| 模型 | GPU 需求 | 时间（100 aa 蛋白质） |
|------|---------|---------------------|
| **ESM-2 (650M)** | 单 GPU (16GB) | < 1 秒 |
| **ESMFold** | 单 GPU (16GB) | 数秒 |
| **AlphaFold2** | 单 GPU (16GB) | 数分钟到数小时 |
| **AlphaFold-Multimer** | 单 GPU (40GB) | 数小时 |

**建议**:
- 本地有 GPU：安装 ESMFold 或 ColabFold
- 无 GPU：使用 Google Colab（免费 T4 GPU）
- 大规模预测：使用云计算（AWS, GCP）

---

## 总结

蛋白质 Foundation Models 正在重塑结构生物学和蛋白质工程：

**已实现**:
- 快速、高精度的结构预测（AlphaFold, ESMFold）
- 零样本突变效应预测（ESM-1v）
- 蛋白质序列表示学习（ESM-2）
- 新蛋白质从头设计（ProtGPT2, RFdiffusion）

**进行中**:
- 蛋白质复合物预测优化
- 动态结构建模
- 闭环 AI 设计与实验验证

**未来展望**:
- 通用蛋白质智能：理解并设计任意蛋白质
- 个性化蛋白质组学：精准医疗应用
- 全自动蛋白质工程：AI + 机器人实验室

蛋白质 Foundation Models 的成功证明了 AI 在基础科学中的巨大潜力，也为其他生物分子（DNA, RNA）的建模提供了范式。

---

## 引用

在学术论文中引用这些模型：

**AlphaFold2**:
```
Jumper, J., Evans, R., Pritzel, A. et al. Highly accurate protein structure 
prediction with AlphaFold. Nature 596, 583–589 (2021).
```

**ESM-2**:
```
Lin, Z., Akin, H., Rao, R. et al. Evolutionary-scale prediction of atomic-level 
protein structure with a language model. Science 379, 1123-1130 (2023).
```

**ProtGPT2**:
```
Ferruz, N., Schmidt, S. & Höcker, B. ProtGPT2 is a deep unsupervised language 
model for protein design. Nat Commun 13, 4348 (2022).
```

---

## 相关链接

- [AI4S 专题主页](index.md)
- [DNA Foundation Models](foundation-models-dna.md)
- [RNA Foundation Models](foundation-models-rna.md)
- [AI4Drug](ai4drug-overview.md)
- [虚拟细胞](virtual-cell.md)
- [学习路线](../learning-path.md)

---

## 致谢

感谢以下团队的开源贡献：
- DeepMind（AlphaFold）
- Meta AI（ESM）
- David Baker Lab（RoseTTAFold, RFdiffusion）
- 所有开源社区贡献者

---

更新时间：2026-09-29

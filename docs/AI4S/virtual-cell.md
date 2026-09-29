# 虚拟细胞（Virtual Cell）

虚拟细胞是通过计算模型重建细胞完整行为的前沿研究方向，旨在构建细胞的"数字孪生"（Digital Twin），整合从分子到细胞器再到整个细胞的多尺度生物学数据，实现对细胞行为的预测、模拟和操控。虚拟细胞代表了系统生物学、合成生物学和计算生物学的深度融合，是 AI4Science 的重要应用领域。

---

## 什么是虚拟细胞？

### 定义

虚拟细胞是一个基于计算的、可预测的细胞模型，能够模拟细胞在不同条件下的行为，包括：

- **代谢网络**：物质与能量的流动
- **基因调控网络**：基因表达的动态变化
- **信号通路**：细胞对外界刺激的响应
- **细胞分裂**：细胞周期与增殖
- **细胞分化**：干细胞命运决定
- **细胞-细胞互作**：多细胞系统的协同行为

---

### 目标

**预测能力**:
- 给定初始条件，预测细胞状态演化
- 预测基因敲除/过表达的表型
- 预测药物对细胞的影响

**可操控性**:
- 虚拟实验：在计算机中测试假设
- 优化设计：合成生物学中的最优基因回路
- 个性化医疗：基于患者细胞的治疗方案

---

## 核心技术

### 1. 基于约束的建模

**代表方法：通量平衡分析（Flux Balance Analysis, FBA）**

**原理**:
- 假设细胞处于稳态（代谢物浓度不变）
- 最大化生物量或其他目标函数
- 约束：反应化学计量、通量上下界

**数学表示**:
```
最大化: v_biomass
约束:
  S · v = 0  （稳态约束）
  lb ≤ v ≤ ub  （通量边界）
```

其中：
- `S`: 化学计量矩阵
- `v`: 反应通量向量
- `lb, ub`: 通量下界与上界

**代码示例（使用 COBRApy）**:
```python
import cobra
from cobra.io import load_model

# 加载大肠杆菌基因组规模代谢模型
model = load_model("iJO1366")  # E. coli 模型

# 查看模型基本信息
print(f"反应数: {len(model.reactions)}")
print(f"代谢物数: {len(model.metabolites)}")
print(f"基因数: {len(model.genes)}")

# 模拟生长
solution = model.optimize()
print(f"最大生长速率: {solution.objective_value:.3f} 1/h")

# 基因敲除实验
with model:
    # 敲除 pgi 基因（葡萄糖-6-磷酸异构酶）
    model.genes.pgi.knock_out()
    ko_solution = model.optimize()
    print(f"敲除后生长速率: {ko_solution.objective_value:.3f} 1/h")

# 通量变异性分析（FVA）
from cobra.flux_analysis import flux_variability_analysis
fva_result = flux_variability_analysis(model, model.reactions[:10])
print(fva_result)
```

**应用**:
- 预测基因敲除效应
- 代谢工程：优化产物合成
- 致死基因识别：药物靶点发现

---

### 2. 常微分方程（ODE）建模

**适用场景**: 信号通路、基因调控网络的动态模拟

**原理**: 描述分子浓度随时间的变化

**示例：简单基因调控**:
```
dX/dt = k_on - k_off * X
```

其中：
- `X`: 蛋白质浓度
- `k_on`: 合成速率
- `k_off`: 降解速率

**代码示例（使用 SciPy）**:
```python
import numpy as np
from scipy.integrate import odeint
import matplotlib.pyplot as plt

# 基因调控 ODE：负反馈回路
def gene_regulation(y, t, k_on, k_off, k_inh, n):
    X = y[0]
    # Hill 函数抑制
    dX_dt = k_on / (1 + (X / k_inh) ** n) - k_off * X
    return [dX_dt]

# 参数
k_on = 1.0
k_off = 0.1
k_inh = 5.0
n = 2

# 初始条件
X0 = [0.1]

# 时间点
t = np.linspace(0, 100, 1000)

# 求解 ODE
sol = odeint(gene_regulation, X0, t, args=(k_on, k_off, k_inh, n))

# 可视化
plt.figure(figsize=(10, 6))
plt.plot(t, sol[:, 0], label='Protein X')
plt.xlabel('Time')
plt.ylabel('Concentration')
plt.title('Gene Regulation with Negative Feedback')
plt.legend()
plt.grid(True)
plt.show()
```

**应用**:
- 振荡器设计（合成生物学）
- 信号通路动力学
- 细胞周期模型

---

### 3. 随机模拟

**适用场景**: 低拷贝数分子、基因表达噪声

**Gillespie 算法（Stochastic Simulation Algorithm, SSA）**:
- 精确模拟化学反应的随机过程
- 适用于小体系

**代码示例**:
```python
import numpy as np
import matplotlib.pyplot as plt

def gillespie(reactions, X0, tmax):
    """
    Gillespie 算法
    
    reactions: list of (propensity_func, change_vector)
    X0: 初始状态
    tmax: 最大时间
    """
    X = np.array(X0, dtype=float)
    t = 0
    t_list = [t]
    X_list = [X.copy()]
    
    while t < tmax:
        # 计算所有反应的倾向性
        a_list = [prop(X) for prop, _ in reactions]
        a0 = sum(a_list)
        
        if a0 == 0:
            break
        
        # 采样时间增量
        tau = np.random.exponential(1 / a0)
        t += tau
        
        # 选择反应
        r = np.random.uniform(0, a0)
        cumsum = 0
        for i, a in enumerate(a_list):
            cumsum += a
            if r < cumsum:
                X += reactions[i][1]
                break
        
        t_list.append(t)
        X_list.append(X.copy())
    
    return np.array(t_list), np.array(X_list)

# 示例：mRNA 和蛋白质合成与降解
# 状态: [mRNA, Protein]
# 反应:
#   1. DNA -> DNA + mRNA  (rate = k1)
#   2. mRNA -> 0           (rate = k2 * mRNA)
#   3. mRNA -> mRNA + Protein (rate = k3 * mRNA)
#   4. Protein -> 0        (rate = k4 * Protein)

k1, k2, k3, k4 = 10, 0.1, 10, 0.01

reactions = [
    (lambda X: k1, np.array([1, 0])),           # mRNA 合成
    (lambda X: k2 * X[0], np.array([-1, 0])),   # mRNA 降解
    (lambda X: k3 * X[0], np.array([0, 1])),    # 蛋白质合成
    (lambda X: k4 * X[1], np.array([0, -1])),   # 蛋白质降解
]

X0 = [0, 0]
tmax = 100

# 运行多次模拟
n_sim = 10
plt.figure(figsize=(12, 5))

for _ in range(n_sim):
    t_list, X_list = gillespie(reactions, X0, tmax)
    plt.subplot(1, 2, 1)
    plt.plot(t_list, X_list[:, 0], alpha=0.5)
    plt.subplot(1, 2, 2)
    plt.plot(t_list, X_list[:, 1], alpha=0.5)

plt.subplot(1, 2, 1)
plt.xlabel('Time')
plt.ylabel('mRNA count')
plt.title('mRNA dynamics')
plt.grid(True)

plt.subplot(1, 2, 2)
plt.xlabel('Time')
plt.ylabel('Protein count')
plt.title('Protein dynamics')
plt.grid(True)

plt.tight_layout()
plt.show()
```

**应用**:
- 基因表达噪声
- 小分子数动力学
- 细胞命运决策

---

### 4. 多尺度建模

**挑战**: 细胞行为跨越多个时间尺度和空间尺度

**尺度**:
- **原子级**（纳秒、纳米）：分子动力学
- **分子级**（秒、纳米-微米）：生化反应
- **细胞器级**（分钟、微米）：线粒体、核糖体
- **细胞级**（小时、微米-毫米）：细胞分裂、迁移
- **组织级**（天、毫米）：器官发育

**多尺度整合方法**:
- 分层建模：不同尺度使用不同模型
- 耦合模拟：跨尺度信息传递

**工具**:
- **E-Cell**: 多尺度细胞模拟
- **Virtual Cell (VCell)**: 空间细胞建模

---

### 5. 机器学习驱动的虚拟细胞

**从数据学习细胞动力学**

**单细胞 RNA-seq → 细胞状态转换**:
- 学习细胞状态的潜在空间
- 预测扰动效应

**代表工具**:

**CellOracle**:
- 从单细胞数据推断基因调控网络
- 模拟基因扰动引起的细胞命运变化

**代码示例（CellOracle）**:
```python
import celloracle as co
import scanpy as sc

# 加载单细胞数据
adata = sc.read_h5ad("scRNA_data.h5ad")

# 构建基因调控网络（GRN）
oracle = co.Oracle()
oracle.import_anndata_as_raw_count(adata)
oracle.perform_PCA()
oracle.knn_imputation()

# 推断 GRN
oracle.fit_GRN()

# 模拟基因敲除
oracle.simulate_shift(gene="Gata1", n_propagation=3)

# 可视化细胞命运变化
oracle.visualize_development()
```

---

**Geneformer**:
- Transformer 模型学习基因表达
- 预测基因扰动和细胞状态

---

**scGPT**:
- 生成式预训练 Transformer
- 单细胞数据的通用表示

---

## 代表性虚拟细胞模型

### 1. 全细胞模型：Mycoplasma genitalium

**背景**: 
- 最简单的自由生活生物
- 基因组仅 525 个基因

**模型**:
- Karr et al. (2012) 在 *Cell* 发表
- 整合 28 个子模块
- 模拟细胞周期全过程

**成果**:
- 预测基因敲除表型
- 预测细胞分裂时间

**论文**: Karr, J. R. et al. (2012). A whole-cell computational model predicts phenotype from genotype. *Cell*, 150(2), 389-401.

---

### 2. 大肠杆菌代谢模型

**iJO1366 模型**:
- 1366 个基因
- 2583 个反应
- 1805 个代谢物

**应用**:
- 预测营养缺陷
- 代谢工程设计
- 合成生物学

---

### 3. 人类代谢模型

**Recon3D**:
- 全面的人类代谢重建
- 整合组织特异性数据

**应用**:
- 癌症代谢研究
- 遗传代谢病
- 药物-代谢互作

---

## 前沿进展（2026 年）

### Cell 2026 综述：虚拟细胞的未来

**参考文献**: [Cell 2026: Virtual Cell Modeling](https://www.cell.com/cell/fulltext/S0092-8674(26)01015-9)

**关键进展**:

**1. AI 与物理模型的混合建模**
- 深度学习学习数据驱动的规律
- 物理模型提供机制约束
- 神经常微分方程（Neural ODE）

---

**2. 单细胞多模态虚拟细胞**
- 整合 scRNA-seq、scATAC-seq、蛋白质组、代谢组
- 构建细胞状态的高维表示
- 预测细胞对扰动的响应

---

**3. 空间虚拟细胞**
- 空间转录组技术（Visium、MERFISH）
- 模拟空间微环境对细胞的影响
- 细胞-细胞互作与组织结构

---

**4. 个性化虚拟细胞**
- 基于患者组学数据构建个性化模型
- 预测个体化药物响应
- 精准医疗应用

---

**5. 自动化模型构建**
- 从文献自动提取生物学知识
- 知识图谱 + 机器学习
- 加速模型迭代

---

### 技术突破

**计算能力提升**:
- GPU 加速模拟
- 云计算平台
- 量子计算潜力

**数据爆炸**:
- 单细胞技术成熟
- 空间组学数据增长
- 多模态数据整合

**AI 赋能**:
- Foundation Models 学习生物规律
- 生成模型模拟细胞行为
- 强化学习优化细胞设计

---

## 应用场景

### 1. 代谢工程

**目标**: 优化微生物生产有价值化合物

**流程**:
1. 构建代谢网络模型
2. FBA 预测基因改造策略
3. 实验验证
4. 迭代优化

**案例**:
- 大肠杆菌生产生物燃料
- 酵母合成青蒿素（抗疟药）

**代码示例**:
```python
import cobra

model = cobra.io.load_model("iJO1366")

# 添加异源代谢途径（示例：生产琥珀酸）
with model:
    # 最大化琥珀酸生产
    model.objective = "EX_succ_e"
    solution = model.optimize()
    print(f"琥珀酸产量: {solution.objective_value:.3f} mmol/gDW/h")
    
    # 识别提升产量的基因过表达靶点
    from cobra.flux_analysis import single_gene_deletion
    deletion_results = single_gene_deletion(model)
    # 找到敲除后产量下降最大的基因（过表达候选）
```

---

### 2. 药物靶点识别

**虚拟敲除实验**:
- 在虚拟细胞中逐个敲除基因
- 预测致死基因
- 优先级排序药物靶点

**示例**:
```python
import cobra

model = cobra.io.load_model("iJO1366")

# 单基因敲除分析
from cobra.flux_analysis import single_gene_deletion

deletion_results = single_gene_deletion(model)

# 识别致死基因（敲除后生长速率接近 0）
essential_genes = deletion_results[deletion_results["growth"] < 0.01]
print(f"致死基因数: {len(essential_genes)}")
print(essential_genes.head())
```

---

### 3. 细胞命运预测

**从单细胞数据推断细胞分化轨迹**

**工具**: CellOracle, RNA Velocity, Waddington-OT

**应用**:
- 干细胞分化控制
- 癌症细胞可塑性
- 发育生物学

---

### 4. 合成生物学

**设计基因回路**:
- 振荡器
- 开关
- 逻辑门

**最小基因组设计**:
- JCVI-syn3.0: 仅 473 个基因的合成细菌
- 虚拟细胞指导基因选择

---

### 5. 疾病建模

**癌症虚拟细胞**:
- 整合患者基因组、转录组数据
- 预测癌细胞对治疗的响应
- 个性化治疗方案

**神经退行性疾病**:
- 模拟神经元代谢失调
- 预测保护性干预

---

## 工具与平台

### COBRApy

代谢网络约束建模

```bash
pip install cobra
```

**文档**: [COBRApy](https://cobrapy.readthedocs.io/)

---

### VCell（Virtual Cell）

多尺度细胞建模平台

**特点**:
- 图形化界面
- ODE、PDE、随机模拟
- 空间细胞建模

**网站**: [VCell](https://vcell.org/)

---

### CellOracle

基因调控网络与细胞命运预测

```bash
pip install celloracle
```

**GitHub**: [CellOracle](https://github.com/morris-lab/CellOracle)

---

### PhysiCell

多细胞系统 Agent-based 建模

**特点**:
- 模拟细胞群体
- 细胞-微环境互作
- 3D 可视化

**网站**: [PhysiCell](http://physicell.org/)

---

### E-Cell

多尺度细胞模拟

**GitHub**: [E-Cell](https://github.com/ecell/ecell4)

---

## 挑战与未来

### 当前挑战

**1. 模型复杂性**
- 生物系统极其复杂
- 参数众多，难以全部实验测定
- 不确定性量化困难

**2. 数据整合**
- 多模态数据格式不统一
- 数据质量参差不齐
- 缺失数据插补

**3. 计算成本**
- 全细胞模拟计算密集
- 高通量虚拟筛选需大量资源

**4. 验证困难**
- 虚拟预测需实验验证
- 细胞行为复杂，难以完全验证

**5. 泛化能力**
- 模型往往针对特定细胞类型
- 跨物种、跨细胞类型泛化困难

---

### 未来方向

**1. AI + 物理混合建模**
- 深度学习捕捉复杂模式
- 物理模型提供可解释性
- 神经 ODE、物理信息神经网络（PINN）

**2. 数字孪生细胞**
- 实时追踪真实细胞
- 虚拟细胞同步更新
- 预测细胞未来状态

**3. 全人类虚拟细胞**
- 整合 Human Cell Atlas 数据
- 覆盖所有细胞类型
- 个性化医疗基础设施

**4. 闭环设计-实验-学习**
- 虚拟设计 → 自动化实验 → 模型更新
- 加速科学发现

**5. 多细胞虚拟生物**
- 从单细胞到组织、器官
- 虚拟器官（Virtual Organ）
- 虚拟人体（Virtual Human）

---

## 学习资源

### 在线课程

- **Systems Biology (MIT OpenCourseWare)**: 系统生物学基础
- **Computational Systems Biology (Coursera)**: 计算系统生物学

---

### 书籍

- 《Systems Biology: A Textbook》（Edda Klipp 等）
- 《Computational Modeling of Signaling Networks》（Springer）

---

### 教程

- [COBRApy Tutorial](https://cobrapy.readthedocs.io/en/latest/getting_started.html)
- [CellOracle Tutorials](https://morris-lab.github.io/CellOracle.documentation/)

---

### 论文

- Karr, J. R. et al. (2012). A whole-cell computational model. *Cell*.
- Macklin, D. N. et al. (2020). Simultaneous cross-evaluation. *eLife*.
- Cell 2026 虚拟细胞综述（2026-09-29）

---

## 总结

虚拟细胞代表了生物学研究的未来方向，通过整合多尺度数据、物理模型和机器学习，构建细胞的可预测、可操控的数字孪生。虚拟细胞将加速药物发现、推动合成生物学、实现个性化医疗，并最终帮助我们全面理解生命的本质。

随着 AI 技术、测序技术和计算能力的飞速发展，虚拟细胞正在从科幻走向现实，成为生命科学研究不可或缺的工具。

---

## 相关链接

- [AI4S 专题主页](index.md)
- [DNA Foundation Models](foundation-models-dna.md)
- [RNA Foundation Models](foundation-models-rna.md)
- [蛋白质 Foundation Models](foundation-models-protein.md)
- [AI4Drug](ai4drug-overview.md)

---

更新时间：2026-09-29

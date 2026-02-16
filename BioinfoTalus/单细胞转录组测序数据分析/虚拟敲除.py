"""
# 需要先在R中获取表达矩阵
library(Seurat)
library(arrow)
load("Data/pbmc.Rda")

# 提取表达矩阵
expr <- GetAssayData(object = pbmc, assay = "RNA", layer = "counts")
expr <- as.data.frame(expr)
expr <- rownames_to_column(expr, var = "gene")

# 保存为 Parquet
write_parquet(expr, "Data/expr.parquet")
"""

import pandas as pd
from scTenifold import scTenifoldKnk

df = pd.read_parquet("Data/expr.parquet")
df = df.set_index(df.columns[0])
df.index.name = None

print("Begin the formal analysis")
sc = scTenifoldKnk(data=df,
                   ko_method="default",
                   ko_genes=["CRYZ"],  # 待敲除的基因，可以是一个也可以是多个
                   qc_kws={"min_lib_size": 10, "min_percent": 0.001, "min_exp_avg": 0.01},
                   )
result = sc.build()
result.to_csv("Data/vKnockout_result.csv")


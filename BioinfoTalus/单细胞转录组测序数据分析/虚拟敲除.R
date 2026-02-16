# 由于使用 R 语言执行虚拟敲除将会极为耗时
# 该脚本的核心流程基于 reticulate 调用 Python 实现（https://github.com/qwerty239qwe/scTenifoldpy）
# 脚本会自动创建/复用 Python环境，无需手动配置
# 若需要纯 Python 版本，见虚拟敲除.py
library(reticulate)
library(Seurat)
library(tibble)


# 配置区（仅需修改本区域；其余代码通常无需改动）
# 再次注明：本脚本会自动管理 Python 环境，无需手动安装/切换
CFG <- list(
  # 输入/输出
  rda_path = "Data/pbmc.Rda", # seurat对象
  seurat_obj_name = "pbmc", # seurat对象名称
  output_csv = "Data/vKnockout_result.csv",
  
  # Seurat 数据来源
  assay = "RNA",
  counts_layer = "counts",   # Seurat v5
  counts_slot = "counts",    # Seurat v4 回退参数
  
  # 虚拟敲除参数
  strict_lambda = 0,
  ko_method = "default", # 敲除方法，可选"default" / "propagation"
  ko_genes = c("CRYZ"), # 待敲除的基因，可以是单个也可以是多个
  # sc_QC 质控参数（均为可选）：
  # - min_lib_size: 细胞总计数（library size/counts）下限；低于该值的细胞会被移除
  # - remove_outlier_cells: 是否按 IQR 规则移除离群细胞（TRUE/FALSE）
  # - min_percent: 基因最小检出比例阈值；仅保留在超过该比例细胞中表达的基因
  # - max_mito_ratio: 线粒体基因表达比例上限；超过该比例的细胞会被移除
  # - min_exp_avg: 基因平均表达下限（当细胞数 > 500 时使用该阈值）
  # - min_exp_sum: 基因表达总和下限（当细胞数 <= 500 时使用该阈值）
  #
  # 注意：
  # 1) 不提供 qc_kws 时，scTenifoldKnk 内部会补默认值：min_exp_avg=0.05, min_exp_sum=25
  # 2) 此处显式传入的参数会覆盖上述默认值
  # 3) 质控可能过滤掉要敲除的基因，这将导致后续流程报错
  qc_kws = list(
    min_lib_size = 10,          # 过滤低测序深度细胞
    remove_outlier_cells = TRUE, # 是否移除离群细胞
    min_percent = 0.001,        # 基因最小检出比例
    max_mito_ratio = 0.1,       # 线粒体比例上限
    min_exp_avg = 0.01,        # 基因平均表达阈值
    min_exp_sum = 25            # 基因表达总和阈值
  ),
  
  # 可选步骤参数（不用时保持空列表）
  # 注意：Windows 环境下建议 n_cpus=1（禁用 Ray 并行），可避免 WinError 6 句柄错误
  # Linux 环境下则可正常并行
  nc_kws = list(n_cpus = 1),
  td_kws = list(),
  ma_kws = list(),
  dr_kws = list(),
  ko_kws = list(),
  
  # Python 环境参数
  env_name = "scTenifold_py39",
  python_version = "3.9", # scTenifoldpy 包需要较低python版本
  recreate_env = FALSE,
  python_packages = c(
    "scTenifoldpy==0.1.3",
    "pandas==1.2.5",
    "numpy==1.20.3",
    "scipy==1.6.3",
    "setuptools==56.2.0",
    "typer==0.4.0",
    "PyYAML==5.4.1",
    "ray==1.8.0",
    "scikit-learn==0.24.2",
    "tensorly==0.6.0",
    "requests==2.26.0",
    "seaborn==0.11.1",
    "matplotlib==3.4.3",
    "networkx==2.6.3",
    "scanpy==1.7.2",
    "protobuf==3.20.*"
  )
)

# 保持运行更稳定，并减少 TF/protobuf 的噪声日志
Sys.setenv(
  TENSORLY_BACKEND = "numpy",
  PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION = "python",
  TF_CPP_MIN_LOG_LEVEL = "2"
)

ensure_python_env <- function(cfg) {
  # 兼容不同 reticulate 版本：不依赖 miniconda_exists()
  conda_bin <- tryCatch(
    reticulate::conda_binary("auto"),
    error = function(e) ""
  )
  if (is.null(conda_bin) || !nzchar(conda_bin) || !file.exists(conda_bin)) {
    message("未检测到可用 conda，正在安装 Miniconda...")
    reticulate::install_miniconda()
    conda_bin <- reticulate::conda_binary("auto")
  }
  
  envs <- reticulate::conda_list(conda = conda_bin)
  env_exists <- cfg$env_name %in% envs$name
  should_install <- FALSE
  
  if (cfg$recreate_env && env_exists) {
    message("Removing existing env: ", cfg$env_name)
    reticulate::conda_remove(envname = cfg$env_name, conda = conda_bin)
    env_exists <- FALSE
  }
  
  if (!env_exists) {
    message("Creating env: ", cfg$env_name, " (python ", cfg$python_version, ")")
    reticulate::conda_create(
      envname = cfg$env_name,
      python_version = cfg$python_version,
      conda = conda_bin
    )
    should_install <- TRUE
  } else {
    message("Using existing env: ", cfg$env_name)
  }
  
  reticulate::use_condaenv(cfg$env_name, required = TRUE)
  
  # 即使环境已存在，也检查关键模块是否齐全；若缺失则自动补装依赖
  required_modules <- c(
    "scTenifold", "pandas", "numpy", "scipy", "sklearn", "tensorly",
    "requests", "seaborn", "matplotlib", "networkx", "scanpy", "yaml", "ray"
  )
  missing_modules <- required_modules[
    !vapply(required_modules, reticulate::py_module_available, logical(1))
  ]
  if (length(missing_modules) > 0) {
    message("检测到缺失 Python 模块：", paste(missing_modules, collapse = ", "))
    should_install <- TRUE
  }
  
  if (should_install) {
    message("正在安装/补齐固定版本 Python 依赖（通过 conda 环境内 pip）...")
    reticulate::conda_install(
      envname = cfg$env_name,
      packages = cfg$python_packages,
      pip = TRUE,
      conda = conda_bin
    )
  }
}

get_counts_matrix <- function(obj, assay, layer, slot) {
  counts <- tryCatch(
    GetAssayData(object = obj, assay = assay, layer = layer),
    error = function(e) {
      message("GetAssayData(layer=...) 失败，回退到 slot=... 模式。")
      GetAssayData(object = obj, assay = assay, slot = slot)
    }
  )
  counts
}

run_pipeline <- function(cfg) {
  ensure_python_env(cfg)
  
  if (!file.exists(cfg$rda_path)) {
    stop("RData file not found: ", cfg$rda_path)
  }
  
  message("Loading RData: ", cfg$rda_path)
  load(cfg$rda_path)
  
  if (!exists(cfg$seurat_obj_name, inherits = FALSE)) {
    stop("Object not found after load(): ", cfg$seurat_obj_name)
  }
  seu <- get(cfg$seurat_obj_name, inherits = FALSE)
  
  message("Extracting counts from Seurat...")
  counts <- get_counts_matrix(
    obj = seu,
    assay = cfg$assay,
    layer = cfg$counts_layer,
    slot = cfg$counts_slot
  )
  
  # scTenifold 需要 genes x cells 矩阵；大对象转稠密矩阵会占用较多内存
  expr <- as.data.frame(as.matrix(counts), check.names = FALSE)
  expr <- tibble::rownames_to_column(expr, var = "gene")
  
  py <- reticulate::import_main(convert = TRUE)
  py$expr_r <- expr
  py$strict_lambda <- cfg$strict_lambda
  py$ko_method <- cfg$ko_method
  py$ko_genes <- cfg$ko_genes
  py$qc_kws <- cfg$qc_kws
  py$nc_kws <- cfg$nc_kws
  py$td_kws <- cfg$td_kws
  py$ma_kws <- cfg$ma_kws
  py$dr_kws <- cfg$dr_kws
  py$ko_kws <- cfg$ko_kws
  py$output_csv <- cfg$output_csv
  
  message("Running virtual KO with scTenifold...")
  reticulate::py_run_string("
import pandas as pd
from scTenifold import scTenifoldKnk

df = expr_r.copy()
df = df.set_index('gene')
df.index.name = None

def _normalize_gene_list(x):
    # 防止单个基因字符串被 list() 拆成字符
    if isinstance(x, str):
        return [x]
    try:
        x = x.tolist()
    except Exception:
        pass
    if isinstance(x, (list, tuple, set)):
        return [str(i) for i in x]
    return [str(x)]

kwargs = dict(
    data=df,
    strict_lambda=float(strict_lambda),
    ko_method=str(ko_method),
    ko_genes=_normalize_gene_list(ko_genes),
    qc_kws=dict(qc_kws)
)

if len(nc_kws) > 0:
    kwargs['nc_kws'] = dict(nc_kws)
if len(td_kws) > 0:
    kwargs['td_kws'] = dict(td_kws)
if len(ma_kws) > 0:
    kwargs['ma_kws'] = dict(ma_kws)
if len(dr_kws) > 0:
    kwargs['dr_kws'] = dict(dr_kws)
if len(ko_kws) > 0:
    kwargs['ko_kws'] = dict(ko_kws)

print('Begin the formal analysis')
sc = scTenifoldKnk(**kwargs)
result = sc.build()
result.to_csv(output_csv, index=False)
print('Saved result to', output_csv)
")

message("Done. Output: ", cfg$output_csv)
}

# 初次运行由于需要配置环境，可能较慢
run_pipeline(CFG)



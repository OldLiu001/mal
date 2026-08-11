#!/bin/dash
# ============================================================
# env.sh —— 环境（官方 env.qx）
# env_new / env_set / env_get
# ============================================================
env_new() {  # $1=外层env ref -> r=E<id>
  local id
  new_id
  id=$r
  eval "_EB_E$id=' ' ; _EO_E$id=\$1"
  r="E$id"
}

env_set() {  # $1=env $2=名 $3=值ref
  _es_k="$2"
  _es_v="$3"
  # 只有真的绑过 DEBUG-EVAL 才让 EVAL 每轮去查环境链，避免常态下的性能损耗
  if [ "$_es_k" = 'DEBUG-EVAL' ]; then _MAL_DBG_SEEN=1; fi
  eval "_EB_$1=\" =\$_es_k \$_es_v\$_EB_$1\""
}

env_get() {  # $1=env $2=名 -> r=值ref（空串=未找到）
  local e="$1" name=" =$2 " kv rest
  while [ -n "$e" ]; do
    eval "kv=\$_EB_$e"
    # "$name" 必须加引号：符号名可以是 * ? [，不引会被当模式
    rest=${kv#*"$name"}
    if [ "$rest" != "$kv" ]; then r=${rest%% *}; return; fi
    eval "e=\$_EO_$e"
  done
  r=""
}

# ================= 错误 =================


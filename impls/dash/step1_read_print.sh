#!/bin/dash
# ============================================================
# step1_read_print —— 官方 step1
# reader + printer（引入 types/reader/printer 模块）
# 官方模块化架构：本文件 = step 主文件（主逻辑 + 启动），
# source 共享模块（types/reader/printer/env/core）。
# ============================================================
set -f
STEPNUM=1
. "$(dirname "$0")/types.sh"
. "$(dirname "$0")/reader.sh"
. "$(dirname "$0")/printer.sh"

EVAL() {  # $1=ast ref $2=env -> r（恒等）
  r="$1"
}

init_repl_env() {
  local e
  env_new ""
  REPL_ENV="$r"
  e="$REPL_ENV"
  mal_closure_native fn_add; env_set "$e" '+' "$r"
  mal_closure_native fn_sub; env_set "$e" '-' "$r"
  mal_closure_native fn_mul; env_set "$e" '*' "$r"
  mal_closure_native fn_div; env_set "$e" '/' "$r"
}


mal_repl() {
  local line
  # 文件参数（官方 step6 要求）：有参数时加载第一个文件并退出；
  # *ARGV* = 其余参数。加载的文件本身可启动自己的 REPL 循环
  # （自托管时 mal 写的解释器文件最后会进入 repl-loop 从 stdin 读）。
  if [ $# -ge 1 ] && [ "$STEPNUM" -ge 6 ]; then
    local argrefs="" a file="$1"
    shift
    for a in "$@"; do
      mal_str "$a"
      argrefs="$argrefs $r"
    done
    if [ -n "$argrefs" ]; then
      mal_list $argrefs
    else
      mal_list
    fi
    env_set "$REPL_ENV" '*ARGV*' "$r"
    MAL_ERR=0; MAL_ERR_MSG=""; MAL_BLANK=0
    rep_silent "(load-file \"$file\")"
    gc_maybe
    exit 0
  fi
  while true; do
    printf 'user> '
    IFS= read -r line || break
    if [ "$STEPNUM" = 0 ]; then
      printf '%s\n' "$line"
      continue
    fi
    MAL_ERR=0
    MAL_ERR_MSG=""
    MAL_BLANK=0
    READ "$line"
    if [ "$MAL_ERR" = 1 ]; then
      printf '%s\n' "$MAL_ERR_MSG"
      continue
    fi
    if [ "$MAL_BLANK" = 1 ]; then continue; fi
    EVAL "$r" "$REPL_ENV"
    if [ "$MAL_ERR" = 1 ]; then
      if [ -n "$MAL_ERR_VAL" ]; then
        pr_str "$MAL_ERR_VAL" 1
        printf 'Error: %s\n' "$r_str"
        MAL_ERR_VAL=""
      else
        printf '%s\n' "$MAL_ERR_MSG"
      fi
      continue
    fi
    PRINT "$r"
    printf '%s\n' "$r_str"
    gc_maybe
  done
}


# ---- 启动（官方 step1 无环境，EVAL 恒等，直接 REPL）----
mal_repl "$@"

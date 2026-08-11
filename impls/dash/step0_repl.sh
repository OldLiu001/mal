#!/bin/dash
# zsh 兼容：默认不分词（SH_WORD_SPLIT 未开），与 POSIX sh/dash/bash 的
# 字段分割行为对齐。实现依赖未加引号 $var 分词（ref 串遍历）。
if [ -n "$ZSH_VERSION" ]; then setopt SH_WORD_SPLIT; fi
# ============================================================
# step0_repl —— 官方 step0
# REPL 回显（READ/EVAL/PRINT/rep 桩）
# 官方模块化架构：本文件 = step 主文件（主逻辑 + 启动），
# source 共享模块（types/reader/printer/env/core）。
# ============================================================
set -f
STEPNUM=0

EVAL() {  # $1=ast ref $2=env -> r（恒等）
  r="$1"
}

while true; do
  printf 'user> '
  IFS= read -r line || break
  printf '%s\n' "$line"
done

# ---- 启动 ----
while true; do
  printf 'user> '
  IFS= read -r line || break
  printf '%s\n' "$line"
done

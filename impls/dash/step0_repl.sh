#!/bin/dash
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

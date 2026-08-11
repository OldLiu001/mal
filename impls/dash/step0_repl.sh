#!/bin/dash
# ============================================================
# mal in dash —— step0_repl（官方 step0）
#
# REPL 回显（READ/EVAL/PRINT 恒等）
#
# 本文件是独立完整的实现（从单文件实现按官方增量拆分，允许代码
# 重复）。功能裁剪规则与官方 process/step0.txt 对应；存储/GC/
# 内联为基础设施，各 step 一致。
# ============================================================
set -f
STEPNUM=0
# core.sh - dash 原生实现的 mal 核心（覆盖 step0~step4）
# 由 stepN_*.sh 设置 STEPNUM 后 source。
#
# 设计要点（沉淀历史踩坑）：
#  1. dash 无数组/关联数组/[[ ]]/${v:o:l}/${v//}/local 数组，全部用「引用字符串 + 动态变量」建模。
#  2. 存取任意内容零 fork：eval "_V_$ref=\$_tmp"。赋值语境不做分词与 pathname 展开，
#     所以内容含空格/换行/引号/反斜杠都安全，比 base64 快一个数量级。
#  3. set -f 全局关闭 pathname 展开：ref 可能是 S* / S? / S[，不关会被当通配符。
#  4. echo 会解释反斜杠 -> 一律 printf '%s\n'。
#  5. 谓词结果走全局 $r，不能用 shell &&/|| 判真假。
#  6. 递归函数的每个临时变量都必须 local，否则内外层互相串味。
#  7. 命令替换 $( ) 会剥尾部换行且开子 shell（副作用丢失）-> 一律不用，靠 $r 回传。
#  8. case 模式里的 * ? [ 必须加引号（'let*' 'fn*'），否则是通配符。
#  9. 单元素剥离：${s#* } 在无空格时原样返回，必须显式判 "$head" = "$s"。

set -f

# ---------------- 全局状态 ----------------
MAL_ERR=0
MAL_ERR_MSG=""
MAL_ERR_VAL=""        # throw 时保存被抛的值 ref；非 throw 错误为空
_TK_N=0
_TOK_POS=1
_MAL_NEXT=0
_MAL_NCLOS=0
_MAL_DBG_SEEN=0
REPL_ENV=""
TAB='	'
NL='
'

# ================= 存储（零 fork，任意内容安全） =================
EVAL() {  # $1=ast ref $2=env -> r（恒等）
  r="$1"
}

# ---- 启动：REPL 回显循环 ----
while true; do
  printf 'user> '
  IFS= read -r line || break
  printf '%s\n' "$line"
done

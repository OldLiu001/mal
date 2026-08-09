# AppleScript MAL — build rules
#
# 每个 step 提供两种产物形式:
#   依赖版   dependent : stepN.scpt                   (运行期 load types/reader/printer.scpt)
#   单文件   standalone: stepN.standalone.applescript  (零依赖单脚本源, 可直接 osascript)
#                         stepN.standalone.scpt        (零依赖编译产物)
#
# 直接运行源码(不走 make):
#   osascript stepN.applescript            -> 优先用 .scpt 模块, 缺失时自动编译 .applescript 再加载
#   osascript stepN.standalone.applescript -> 完全自包含, 零依赖
#
# 构建:
#   make                -> 构建所有 step 依赖版 .scpt
#   make standalone     -> 构建所有 step 单文件版(.standalone.applescript + .standalone.scpt)
#   make standalone-src -> 仅构建单文件源 .standalone.applescript
#
# 合并工具 merge.applescript 为纯 AppleScript 实现, 不依赖 Python / 外部脚本语言。

SCRIPT = osascript
CC     = osacompile

STEPS = step0_repl step1_read_print step2_eval step3_env step4_if_fn_do \
        step5_tco step6_file step7_quote step8_macros step9_try stepA_mal

# ---- 依赖版 (运行期加载 types/reader/printer.scpt) ----
$(STEPS:=.scpt): %.scpt: %.applescript types.scpt reader.scpt printer.scpt
	$(CC) -l AppleScript -o $@ $<

types.scpt reader.scpt printer.scpt: %.scpt: %.applescript
	$(CC) -l AppleScript -o $@ $<

# ---- 单文件无依赖版: 合并源 (.standalone.applescript) ----
# 由 AppleScript 原生 merge.applescript 合并(扁平化内联三个模块), 不依赖 Python
STANDALONE_SRC = $(STEPS:=.standalone.applescript)

$(STANDALONE_SRC): %.standalone.applescript: $(basename %).applescript types.applescript reader.applescript printer.applescript merge.applescript
	$(SCRIPT) merge.applescript $*

# ---- 单文件无依赖版: 编译产物 (.standalone.scpt) ----
%.standalone.scpt: %.standalone.applescript
	$(CC) -l AppleScript -o $@ $<

.PHONY: all standalone standalone-src clean
all: $(STEPS:=.scpt)

standalone-src: $(STANDALONE_SRC)

standalone: $(STEPS:=.standalone.scpt)

clean:
	rm -f $(STEPS:=.scpt) $(STEPS:=.standalone.scpt) $(STANDALONE_SRC) \
	      types.scpt reader.scpt printer.scpt

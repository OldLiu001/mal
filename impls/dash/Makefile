# mal in dash —— 官方架构风格 Makefile
# 官方模块化结构：types/reader/printer/env/core 模块 + step*.sh 主文件
# （官方 types.qx/reader.qx/printer.qx/env.qx/core.qx + stepN_xxx.qx）。
STEPS = step0_repl.sh step1_read_print.sh step2_eval.sh step3_env.sh \
	step4_if_fn_do.sh step5_tco.sh step6_file.sh step7_quote.sh \
	step8_macros.sh step9_try.sh stepA_mal.sh

# shell 解释器跑 shell 里的解释器，runtest 默认 20s/用例不够用。
# step5 的 (sum2 10000 0) 一条就要几十秒。
TEST_OPTS = --test-timeout 600

all:
	true

dist: mal

# 单文件分发版（官方 dist 语义）：由 stepA（最终实现）合成
mal: stepA_mal.sh
	cat $< > $@
	chmod +x $@

clean:
	rm -f mal

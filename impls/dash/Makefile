# mal in dash —— 官方架构风格 Makefile
# 每个 step 一个独立可执行文件（impls/dash/step*.sh），由 tools/split_steps.py 生成。
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

# 重新生成（模块化：5 个模块 + 11 个 step 主文件）
split:
	python3 tools/modularize.py

clean:
	rm -f mal

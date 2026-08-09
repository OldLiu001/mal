SOURCES_BASE = core.sh
SOURCES_LISP = step0_repl.sh step1_read_print.sh step2_eval.sh \
               step3_env.sh step4_if_fn_do.sh step5_tco.sh
SOURCES = $(SOURCES_BASE) $(SOURCES_LISP)

# shell 解释器跑 shell 里的解释器，runtest 默认 20s/用例不够用。
# step5 的 (sum2 10000 0) 一条就要几十秒。
TEST_OPTS = --test-timeout 600

all:
	true

dist: mal

mal: $(SOURCES) run
	echo '#!/bin/dash' > $@
	chmod +x $@

clean:
	rm -f mal

SOURCES_BASE = core.sh
SOURCES_LISP = step0_repl.sh step1_read_print.sh step2_eval.sh \
               step3_env.sh step4_if_fn_do.sh
SOURCES = $(SOURCES_BASE) $(SOURCES_LISP)

all:
	true

dist: mal

mal: $(SOURCES) run
	echo '#!/bin/dash' > $@
	chmod +x $@

clean:
	rm -f mal

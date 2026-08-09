%.scpt: %.applescript
	osacompile -l AppleScript -o $@ $<

step1_read_print.scpt: step1_read_print.applescript

step0_repl.scpt: step0_repl.applescript

.PHONY: clean
clean:
	rm -f *.scpt

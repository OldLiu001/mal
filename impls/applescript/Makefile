%.scpt: %.applescript
	osacompile -l AppleScript -o $@ $<

# step 文件依赖模块
step1_read_print.scpt: step1_read_print.applescript reader.scpt printer.scpt types.scpt

step2_eval.scpt: step2_eval.applescript reader.scpt printer.scpt types.scpt

reader.scpt: reader.applescript types.scpt

printer.scpt: printer.applescript

types.scpt: types.applescript

step0_repl.scpt: step0_repl.applescript

.PHONY: clean
clean:
	rm -f *.scpt

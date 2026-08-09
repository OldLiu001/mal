%.scpt: %.applescript
	osacompile -l AppleScript -o $@ $<

# step 文件依赖模块
step1_read_print.scpt: step1_read_print.applescript reader.scpt printer.scpt types.scpt

step2_eval.scpt: step2_eval.applescript reader.scpt printer.scpt types.scpt

step3_env.scpt: step3_env.applescript reader.scpt printer.scpt types.scpt

step4_if_fn_do.scpt: step4_if_fn_do.applescript reader.scpt printer.scpt types.scpt

step5_tco.scpt: step5_tco.applescript reader.scpt printer.scpt types.scpt

step6_file.scpt: step6_file.applescript reader.scpt printer.scpt types.scpt

step7_quote.scpt: step7_quote.applescript reader.scpt printer.scpt types.scpt

step8_macros.scpt: step8_macros.applescript reader.scpt printer.scpt types.scpt

step9_try.scpt: step9_try.applescript reader.scpt printer.scpt types.scpt

reader.scpt: reader.applescript types.scpt

printer.scpt: printer.applescript

types.scpt: types.applescript

step0_repl.scpt: step0_repl.applescript

.PHONY: clean
clean:
	rm -f *.scpt

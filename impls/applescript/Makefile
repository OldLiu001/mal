step1_read_print.scpt: reader.scpt

reader.scpt: types.scpt

%.scpt: %.applescript
	osacompile -l AppleScript -o $@ $<

.PHONY: clean
clean:
	rm *.scpt

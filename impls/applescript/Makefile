step1_read_print.scpt: reader.scpt

%.scpt: %.applescript
	osacompile -l AppleScript -o $@ $<

.PHONY: clean
clean:
	rm *.scpt

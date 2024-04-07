@echo off
setlocal disabledelayedexpansion
for /f "delims==" %%a in ('set') do set "%%a="

:main
	set input=
	set /p "input=user> "
	if defined input (
		rem first replace double quotation mark.
		set "input=%input:"=#$Double_Quotation$#%"
		rem Batch can't deal with "!" when delayed expansion is enabled, so replace it to a special string.
		call set "input=%%input:!=#$Exclamation$#%%"
		setlocal ENABLEDELAYEDEXPANSION
		%improve speed start% (
			rem Batch has some problem in "^" processing, so replace it.
			set "input=!input:^=#$Caret$#!"
			rem replace %.
			set input_formated=
			:replacement_loop
			if defined input (
				if "!input:~,1!" == "%%" (
					set "input_formated=!input_formated!#$Percent$#"
				) else (
					set "input_formated=!input_formated!!input:~,1!"
				)
				set "input=!input:~1!"
				goto replacement_loop
			)
			call :rep "!input_formated!"
			endlocal
		) %improve speed end%
	)
goto :main


%improve speed start% (
	:READ
		setlocal
			rem re means return, which bring return value.
			set "re=%~1"
		for /f "tokens=* eol=" %%a in ("!re!") do (
			endlocal
			set "re=%%~a"
		)
	goto :eof

	:EVAL
		setlocal
			set "re=%~1"
		for /f "tokens=* eol=" %%a in ("!re!") do (
			endlocal
			set "re=%%~a"
		)
	goto :eof

	:PRINT
		setlocal
			set "output=%~1"
			rem replace all speical symbol back.
			set output_buffer=
			:output_loop
			if "!output:~,15!" == "#$Exclamation$#" (
				set "output_buffer=!output_buffer!^!"
				set "output=!output:~15!"
				goto output_loop
			) else if "!output:~,9!" == "#$Caret$#" (
				set "output_buffer=!output_buffer!^^"
				set "output=!output:~9!"
				goto output_loop
			) else if "!output:~,20!" == "#$Double_Quotation$#" (
				set "output_buffer=!output_buffer!^""
				set "output=!output:~20!"
				goto output_loop
			) else if "!output:~,1!" == "=" (
				set "output_buffer=!output_buffer!="
				set "output=!output:~1!"
				goto output_loop
			) else if "!output:~,1!" == " " (
				set "output_buffer=!output_buffer! "
				set "output=!output:~1!"
				goto output_loop
			) else if "!output:~,11!" == "#$Percent$#" (
				set "output_buffer=!output_buffer!%%"
				set "output=!output:~11!"
				goto output_loop
			) else if defined output (
				set "output_buffer=!output_buffer!!output:~,1!"
				set "output=!output:~1!"
				goto output_loop
			)
			echo.!output_buffer!
			set "re=%~1"
		for /f "tokens=* eol=" %%a in ("!re!") do (
			endlocal
			set "re=%%~a"
		)
	goto :eof

	:rep
		setlocal
			call :READ "%~1"
			call :EVAL "!re!"
			call :PRINT "!re!"
		endlocal
	goto :eof
) %improve speed end%
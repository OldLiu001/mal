@REM v: 0.6

@REM Read escaped string from stdin and output unescaped string.

@REM Special Symbol Mapping:
@REM 	! --- \eE
@REM 	^ --- \eC
@REM 	" --- \eD
@REM 	% --- \eP

@echo off & setlocal ENABLEDELAYEDEXPANSION

for /f "delims=#" %%. in (
	'prompt #$E#^&echo on^&for %%a in ^(1^) do rem'
) do (
	@REM echo a.
	set "EscK=%%."
)

for /f "delims=" %%i in ('more') do (
	set "Output=%%~i"
	rem replace all speical symbol back.
	set OutputBuffer=
	:LOCALTAG_Print_OutputLoop
	if "!Output:~,2!" == "!EscK!E" (
		set "OutputBuffer=!OutputBuffer!^!"
		set "Output=!Output:~2!"
		goto LOCALTAG_Print_OutputLoop
	) else if "!Output:~,2!" == "!EscK!C" (
		set "OutputBuffer=!OutputBuffer!^^"
		set "Output=!Output:~2!"
		goto LOCALTAG_Print_OutputLoop
	) else if "!Output:~,2!" == "!EscK!D" (
		set "OutputBuffer=!OutputBuffer!^""
		set "Output=!Output:~2!"
		goto LOCALTAG_Print_OutputLoop
	) else if "!Output:~,1!" == "=" (
		set "OutputBuffer=!OutputBuffer!="
		set "Output=!Output:~1!"
		goto LOCALTAG_Print_OutputLoop
	) else if "!Output:~,1!" == " " (
		set "OutputBuffer=!OutputBuffer! "
		set "Output=!Output:~1!"
		goto LOCALTAG_Print_OutputLoop
	) else if "!Output:~,2!" == "!EscK!P" (
		set "OutputBuffer=!OutputBuffer!%%"
		set "Output=!Output:~2!"
		goto LOCALTAG_Print_OutputLoop
	) else if defined Output (
		set "OutputBuffer=!OutputBuffer!!Output:~,1!"
		set "Output=!Output:~1!"
		goto LOCALTAG_Print_OutputLoop
	)
	echo.!OutputBuffer!
)
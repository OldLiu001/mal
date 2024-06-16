@REM Read escaped string from stdin and output unescaped string.

@REM Special Symbol Mapping:
@REM 	! --- #$E$#
@REM 	^ --- #$C$#
@REM 	" --- #$D$#
@REM 	% --- #$P$#

@echo off & setlocal ENABLEDELAYEDEXPANSION

for /f "delims=" %%i in ('more') do (
	set "Output=%%~i"
	rem replace all speical symbol back.
	set OutputBuffer=
	:LOCALTAG_Print_OutputLoop
	if "!Output:~,5!" == "#$E$#" (
		set "OutputBuffer=!OutputBuffer!^!"
		set "Output=!Output:~5!"
		goto LOCALTAG_Print_OutputLoop
	) else if "!Output:~,5!" == "#$C$#" (
		set "OutputBuffer=!OutputBuffer!^^"
		set "Output=!Output:~5!"
		goto LOCALTAG_Print_OutputLoop
	) else if "!Output:~,5!" == "#$D$#" (
		set "OutputBuffer=!OutputBuffer!^""
		set "Output=!Output:~5!"
		goto LOCALTAG_Print_OutputLoop
	) else if "!Output:~,1!" == "=" (
		set "OutputBuffer=!OutputBuffer!="
		set "Output=!Output:~1!"
		goto LOCALTAG_Print_OutputLoop
	) else if "!Output:~,1!" == " " (
		set "OutputBuffer=!OutputBuffer! "
		set "Output=!Output:~1!"
		goto LOCALTAG_Print_OutputLoop
	) else if "!Output:~,5!" == "#$P$#" (
		set "OutputBuffer=!OutputBuffer!%%"
		set "Output=!Output:~5!"
		goto LOCALTAG_Print_OutputLoop
	) else if defined Output (
		set "OutputBuffer=!OutputBuffer!!Output:~,1!"
		set "Output=!Output:~1!"
		goto LOCALTAG_Print_OutputLoop
	)
	echo.!OutputBuffer!
)
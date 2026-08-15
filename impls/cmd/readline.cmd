@REM Will read a line from stdin and return escaped string.

@REM Special Symbol Mapping:
@REM 	! --- $E
@REM 	^ --- $C
@REM 	" --- $D
@REM 	% --- $P
@REM 	$ --- $$

@echo off
setlocal disabledelayedexpansion

set Input=
set /p "Input="
if not defined Input goto :eof

rem First, replace $ to $$.
set "Input=%Input:$=$$%"
rem Replace double quotation mark.
set "Input=%Input:"=$D%"
rem Replace ! to $E (call for two-step expansion to handle delayed-expansion char).
call set "Input=%%Input:!=$E%%"

rem Switch to delayed expansion for ^ and % handling.
rem Delayed expansion (!var!) is safe inside ( ) blocks because
rem values are expanded at runtime, not parse time.
setlocal ENABLEDELAYEDEXPANSION

rem Replace ^ to $C.
set "Input=!Input:^=$C!"

rem Replace % char by char (set command can't safely replace literal %).
set FormatedInput=
:ReplacementLoop
if defined Input (
	if "!Input:~,1!" == "%%" (
		set "FormatedInput=!FormatedInput!$P"
	) else (
		set "FormatedInput=!FormatedInput!!Input:~,1!"
	)
	set "Input=!Input:~1!"
	goto ReplacementLoop
)
echo.!FormatedInput!
endlocal

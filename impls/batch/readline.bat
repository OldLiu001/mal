@REM v: 0.6

@REM Will read a line from stdin and return escaped string.

@REM Special Symbol Mapping:
@REM 	! --- $E
@REM 	^ --- $C
@REM 	" --- $D
@REM 	% --- $P
@REM 	$ --- $$

@echo off
setlocal disabledelayedexpansion
for /f "delims=#" %%. in (
	'prompt #$E#^&echo on^&for %%a in ^(1^) do rem'
) do (
	@REM echo a.
	set "EscK=%%."
)
@REM pause

set Input=
set /p "Input="
for /f "delims=" %%. in ("%EscK%") do (
	if defined Input (
		rem Replace double quotation mark to avoid error.
		call set "Input=%%Input:"=%%.D%%"
		rem Batch can't deal with "!" when delayed expansion is enabled, so replace it to a special string.
		call set "Input=%%Input:!=%%.E%%"
		setlocal ENABLEDELAYEDEXPANSION
		%Speed Improve Start% (
			rem Batch has some problem in "^" processing, so replace it.
			set "Input=!Input:^=%%.C!"
			rem Replace %.
			set FormatedInput=
			:LOCALTAG_Main_ReplacementLoop
			if defined Input (
				if "!Input:~,1!" == "%%" (
					set "FormatedInput=!FormatedInput!%EscK%P"
				) else (
					set "FormatedInput=!FormatedInput!!Input:~,1!"
				)
				set "Input=!Input:~1!"
				goto LOCALTAG_Main_ReplacementLoop
			)
			@REM echo.!FormatedInput!
			:LOCALTAG_Main_ReplacementLoop2
			if defined FormatedInput (
				if "!FormatedInput:~,1!" == "%EscK%" (
					set "FormatedInput2=!FormatedInput2!$"
				) else if "!FormatedInput:~,1!" == "$" (
					set "FormatedInput2=!FormatedInput2!$$"
				) else (
					set "FormatedInput2=!FormatedInput2!!FormatedInput:~,1!"
				)
				set "FormatedInput=!FormatedInput:~1!"
				goto LOCALTAG_Main_ReplacementLoop2
			)
			echo.!FormatedInput2!
			endlocal
		) %Speed Improve End%
	)
)

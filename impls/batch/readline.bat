@REM Will read a line from stdin and return escaped string.

@REM Special Symbol Mapping:
@REM 	! --- #$E$#
@REM 	^ --- #$C$#
@REM 	" --- #$D$#
@REM 	% --- #$P$#

@echo off
setlocal disabledelayedexpansion

set Input=
set /p "Input="
if defined Input (
	rem first replace double quotation mark.
	set "Input=%Input:"=#$D$#%"
	rem Batch can't deal with "!" when delayed expansion is enabled, so replace it to a special string.
	call set "Input=%%Input:!=#$E$#%%"
	setlocal ENABLEDELAYEDEXPANSION
	%Speed Improve Start% (
		rem Batch has some problem in "^" processing, so replace it.
		set "Input=!Input:^=#$C$#!"
		rem replace %.
		set FormatedInput=
		:LOCALTAG_Main_ReplacementLoop
		if defined Input (
			if "!Input:~,1!" == "%%" (
				set "FormatedInput=!FormatedInput!#$P$#"
			) else (
				set "FormatedInput=!FormatedInput!!Input:~,1!"
			)
			set "Input=!Input:~1!"
			goto LOCALTAG_Main_ReplacementLoop
		)
		echo.!FormatedInput!
		endlocal
	) %Speed Improve End%
)
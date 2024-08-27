@REM Will read to eof and return escaped string.
@REM #$D$# is added to the beginning and end of each line.

@REM Special Symbol Mapping:
@REM 	! --- #$E$#
@REM 	^ --- #$C$#
@REM 	" --- #$D$#
@REM 	% --- #$P$#

@echo off
setlocal disabledelayedexpansion

for /f "tokens=* eol=" %%a in ('more') do (
	echo "%%a"|readline.bat
)
exit /b 0
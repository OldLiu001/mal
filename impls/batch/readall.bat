@echo off & setlocal disabledelayedexpansion

set "_RAW="
if /i "%~1" == "RAW" set "_RAW=1"

for /f "tokens=*" %%a in ('more') do (
	set "_LINE=%%a"
	call :FEED
)
exit /b 0

:FEED
	setlocal enabledelayedexpansion
	set "v=!_LINE!"
	set "v=!v:^=^^!"
	set "v=!v:&=^&!"
	set "v=!v:|=^|!"
	set "v=!v:<=^<!"
	set "v=!v:>=^>!"
	if defined _RAW (
		echo(!v!| call readline
	) else if not defined MAL_BATCH_IMPL_SINGLE_FILE (
		echo(!v!| call readline
	) else (
		echo(!v!| call "%~0" CALL_READLINE
	)
	endlocal
exit /b 0

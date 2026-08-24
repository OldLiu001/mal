@echo off & setlocal disabledelayedexpansion

set "_RAW="
if /i "%~1" == "RAW" set "_RAW=1"

for /f "tokens=* eol=" %%a in ('more') do (
	if defined _RAW (
		echo.%%a|call readline
	) else if not defined MAL_BATCH_IMPL_SINGLE_FILE (
		echo "%%a"|call readline
	) else (
		echo "%%a"|call "%~0" CALL_READLINE
	)
)
exit /b 0

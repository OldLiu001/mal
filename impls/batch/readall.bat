@echo off & setlocal disabledelayedexpansion

for /f "tokens=* eol=" %%a in ('more') do (
	if not defined MAL_BATCH_IMPL_SINGLE_FILE (
		echo "%%a"|call readline
	) else (
		echo "%%a"|call "%~0" CALL_READLINE
	)
)
exit /b 0
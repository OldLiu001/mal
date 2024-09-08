@echo off & setlocal disabledelayedexpansion

for /f "tokens=* eol=" %%a in ('more') do (
	echo "%%a"|readline.bat
)
exit /b 0
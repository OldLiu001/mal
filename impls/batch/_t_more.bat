@echo off
setlocal disabledelayedexpansion
for /f "tokens=* eol=" %%a in ('findstr .') do (
  echo got=[%%a]
)
exit /b 0
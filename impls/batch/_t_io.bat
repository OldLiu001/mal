@echo off
setlocal ENABLEDELAYEDEXPANSION
for /f "tokens=* eol=" %%a in ('call READLINE') do set "L1=%%~a"
for /f "tokens=* eol=" %%a in ('call READLINE') do set "L2=%%~a"
for /f "tokens=* eol=" %%a in ('call READLINE') do set "L3=%%~a"
echo L1=[%L1%] L2=[%L2%] L3=[%L3%]
exit /b 0
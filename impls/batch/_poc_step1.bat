@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
echo "(+ 1 2)" | step1_read_print.bat
exit /b 0
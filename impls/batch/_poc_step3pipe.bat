@echo off
set _G.FAST=1
set DBG2=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
(
echo (+ 1 2^)
) | step3_env.bat
exit /b 0
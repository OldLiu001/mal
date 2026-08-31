@echo off
setlocal enabledelayedexpansion
set "{s=call :NSUTIL_Set"
set "}=& (if defined _G.ERR (exit /b 0))"
set "->=& call :UTIL_GetRet"
echo V1 test
for %%a in (1) do (
	%{s% "E" "F" "<" %}%
)
echo V1-AFTER
echo V2 test
for %%a in (1) do (
	%{s% "E" "F" ">" %}%
)
echo V2-AFTER

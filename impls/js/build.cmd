@echo off
rem build.cmd - Bundle mal js files into a single file for cscript/jsc
rem Usage: build.cmd stepN_xxx
rem   Creates dist\stepN_xxx.js with all dependencies inlined

setlocal enabledelayedexpansion
set "IMPL_DIR=%~dp0"
set "STEP=%~1"
if "%STEP%"=="" set "STEP=stepA_mal"
set "OUTDIR=%IMPL_DIR%dist"
set "OUTFILE=%OUTDIR%\%STEP%.js"

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

rem File order: runtime, io, types, reader, printer, env, core, interop, node_readline, step
set "FILES=runtime.js io.js types.js reader.js printer.js env.js core.js interop.js node_readline.js %STEP%.js"

rem Clear output file
type nul > "%OUTFILE%"

rem Concatenate files, stripping require/module lines
for %%f in (%FILES%) do (
    if exist "%IMPL_DIR%%%f" (
        rem Add separator comment
        echo // ===== %%f ===== >> "%OUTFILE%"
        rem Copy lines, skipping require() and module.exports lines
        for /f "usebackq delims=" %%l in ("%IMPL_DIR%%%f") do (
            set "line=%%l"
            rem Skip lines containing require( or module.exports
            echo !line! | findstr /c:"require(" >nul
            if errorlevel 1 (
                echo !line! | findstr /c:"module.exports" >nul
                if errorlevel 1 (
                    echo !line! >> "%OUTFILE%"
                )
            )
        )
    )
)

echo Built: %OUTFILE%

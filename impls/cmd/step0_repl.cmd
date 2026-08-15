@rem Project Name: MAL
@rem Module Name: Main (step0_repl)
@rem
@rem Step 0: Basic REPL
@rem   READ  = identity (pass input through)
@rem   EVAL  = identity (pass value through)
@rem   PRINT = unescape and write to stdout
@rem
@rem CMD features used:
@rem   %*               - dynamic command execution (no args -> REPL)
@rem   for /f + more    - stdin capture in readline.cmd / writeall.cmd
@rem   set /p "=.."<nul - no-newline prompt output
@rem   pipeline |      - data transformation between stages

@echo off
setlocal ENABLEDELAYEDEXPANSION

rem --- %* dynamic execution ---
rem With args: execute as command, then exit.
rem   e.g.  call step0_repl.cmd call :Print "hello"
rem No args: fall through to REPL main loop.
if "%~1" equ "" goto :Main
%*
exit /b


:Main
	set "Input="
	set /p "=user> "<nul
	for /f "delims=" %%a in ('call readline.cmd') do set "Input=%%~a"
	call :REP "!Input!"
goto :Main


:Read str -> ReturnValue
	rem Step 0: READ is identity.
	set "ReturnValue=%~1"
goto :eof

:Eval str -> ReturnValue
	rem Step 0: EVAL is identity.
	set "ReturnValue=%~1"
goto :eof

:Print str
	rem Pipeline: echo escaped string -> writeall.cmd unescapes -> stdout
	echo."%~1"| call writeall.cmd
goto :eof

:REP str
	call :Read "%~1"
	call :Eval "!ReturnValue!"
	call :Print "!ReturnValue!"
goto :eof

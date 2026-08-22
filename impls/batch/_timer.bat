@echo off
rem usage: _timer.bat <target.bat> <infile>  -> stdout to _t_stderr_%pid% etc
call "%~dp0%~1" < "%~dp0%~2" > "%~dp0_t_run_out.txt" 2> "%~dp0_t_run_err.txt"
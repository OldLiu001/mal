@REM v: 1.4
@echo off & setlocal ENABLEDELAYEDEXPANSION

for /f "delims=" %%i in ('more') do (
	set "_Out=%%~i"
	set _OutBuf=
	:WRITEALL_Loop
	if "!_Out:~,2!" == "$$" (
		set "_OutBuf=!_OutBuf!$"
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if "!_Out:~,2!" == "$E" (
		set "_OutBuf=!_OutBuf!^!"
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if "!_Out:~,2!" == "$C" (
		set "_OutBuf=!_OutBuf!^^"
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if "!_Out:~,2!" == "$D" (
		set "_OutBuf=!_OutBuf!^""
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if "!_Out:~,1!" == "=" (
		set "_OutBuf=!_OutBuf!="
		set "_Out=!_Out:~1!"
		goto WRITEALL_Loop
	) else if "!_Out:~,1!" == " " (
		set "_OutBuf=!_OutBuf! "
		set "_Out=!_Out:~1!"
		goto WRITEALL_Loop
	) else if "!_Out:~,2!" == "$P" (
		set "_OutBuf=!_OutBuf!%%"
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if "!_Out:~,2!" == "$A" (
		set "_OutBuf=!_OutBuf!:"
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if defined _Out (
		set "_OutBuf=!_OutBuf!!_Out:~,1!"
		set "_Out=!_Out:~1!"
		goto WRITEALL_Loop
	)
	echo.!_OutBuf!
)
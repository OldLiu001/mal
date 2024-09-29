@rem Project Name: MAL
@rem Module Name: Main

@rem Origin name mapping:
@rem 	READ -> Read
@rem 	EVAL -> Eval
@rem 	PRINT -> Print
@rem 	rep -> REP

@echo off
setlocal ENABLEDELAYEDEXPANSION
set /a GLOBAL_STACKCNT = -1
goto Main


:Main
	set Input=
	set /p "=user> "<nul
	for /f "delims=" %%a in ('call readline.bat') do set "Input=%%~a"
	call :REP "!Input!"
goto :Main


%Speed Improve Start% (
	:Read
		call :GetVars Main Read "MalCode"
		rem return it directly.
		set "ReturnValue=!MalCode!"
		call :SaveVars Main Read "ReturnValue"
	goto :eof

	:Eval
		call :GetVars Main Read "MalCode"
		rem return it directly.
		set "ReturnValue=!MalCode!"
		call :SaveVars Main Read "ReturnValue"
	goto :eof

	:Print
		call :GetVars Main Read "MalCode"
		
		echo."!MalCode!"| call writeall.bat
	goto :eof

	:REP MalCode
		set "MalCode=%~1"
		
		call :SaveVars Main REP "MalCode"
		call :READ
		call :GetVars Main REP "ReturnValue"
		
		set "MalCode=!ReturnValue!"
		call :SaveVars Main REP "MalCode"
		call :EVAL
		call :GetVars Main REP "ReturnValue"

		set "MalCode=!ReturnValue!"
		call :SaveVars Main REP "MalCode"
		call :PRINT
	goto :eof
) %Speed Improve End%



@REM Batchfile Stackframe support BY OldLiu.
%Speed Improve Start% (
	:StackPushVar strVarName
		rem requirement: enable delayed expansion.
		set /a GLOBAL_STACKCNT += 1
		set "GLOBAL_STACK[!GLOBAL_STACKCNT!]=!%~1!"
	goto :eof

	:StackPushVal str
		rem requirement: enable delayed expansion.
		set /a GLOBAL_STACKCNT += 1
		set "GLOBAL_STACK[!GLOBAL_STACKCNT!]=%~1"
	goto :eof

	:StackPopVar strVarName
		rem requirement: enable delayed expansion.
		if %GLOBAL_STACKCNT% lss 0 (
			echo [Module: StackLib] [Fn: StackPopVar] [Fatal Error] Stack is empty. >&2
			exit /b 1
		)
		for %%i in (!GLOBAL_STACKCNT!) do (
			set "%~1=!GLOBAL_STACK[%%i]!"
			set "GLOBAL_STACK[%%i]="
		)
		set /a GLOBAL_STACKCNT -= 1
	goto :eof

	:GetVars ModuleName FnName VarList
		rem requirement: enable delayed expansion.
		rem requirement: VarList is a string, and each VarName is separated by " ".
		rem requirement: VarName is different from each other.
		set "ModuleName=%~1"
		set "FnName=%~2"
		set "VarList=%~3"
		
		rem Pop Vars.
		rem Pop Var count.
		call :StackPopVar VarCount
		for /l %%i in (1 1 !VarCount!) do (
			call :StackPopVar VarName

			rem check if VarName in VarList.
			for %%j in (!VarName!) do (
				@REM echo varlist "!VarList!" "%%j"
				@REM echo varlist "!VarList:%%j=!"
				if "!VarList!" == "!VarList:%%j=!" (
					echo [Mod: !ModuleName!] [Fn: !FnName!] [Fatal Error] VarName: %%j is not in VarList. >&2
					exit /b 1
				)

				rem Remove VarName from VarList.
				set VarList=!VarList:%%j=!
			)
			call :StackPopVar !VarName!
		)
		rem check if VarList is empty.
		for %%_ in (!VarList!) do (
			echo [Mod: !ModuleName!] [Fn: !FnName!] [Fatal Error] Need more Vars: !VarList! >&2
			exit /b 1
		)
	goto :eof

	:SaveVars ModuleName FnName VarList
		rem requirement: enable delayed expansion.
		rem requirement: VarList is a string, and each VarName is separated by " ".
		rem requirement: VarName is different from each other.
		set "ModuleName=%~1"
		set "FnName=%~2"
		set "VarList=%~3"
		
		rem Cout Var number.
		set "VarCount=0"
		for %%i in (!VarList!) do (
			if not defined %%i (
				echo [Mod: !ModuleName!] [Fn: !FnName!] [Fatal Error] VarName: %%i is not defined. >&2
				exit /b 1
			)
			call :StackPushVar %%i
			call :StackPushVal %%i
			set /a VarCount += 1
		)
		rem Push Var count.
		call :StackPushVal !VarCount!
	goto :eof
) %Speed Improve End%
@rem Project Name: MAL
@rem Module Name: Main

@rem Global function list:
@rem 	Main
@rem 	Read
@rem 	Eval
@rem 	Print
@rem 	REP

@rem Origin name mapping:
@rem 	READ -> Read
@rem 	EVAL -> Eval
@rem 	PRINT -> Print
@rem 	rep -> REP

@echo off
setlocal disabledelayedexpansion
rem cancel all pre-defined variables.
for /f "delims==" %%a in ('set') do set "%%a="
set /a GLOBAL_STACKCNT = -1
goto Main

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
		echo [Module: Main] [Fn: StackPopVar] [Fatal Error] Stack is empty. >&2
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
	if defined VarList (
		echo [Mod: Main] [Fn: Read] [Fatal Error] Need more Vars: !VarList! >&2
		exit /b 1
	)
goto :eof

:PrepareVars ModuleName FnName VarList
	rem requirement: enable delayed expansion.
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

:Main
	set Input=
	set /p "Input=user> "
	if defined Input (
		rem first replace double quotation mark.
		set "Input=%Input:"=#$Double_Quotation$#%"
		rem Batch can't deal with "!" when delayed expansion is enabled, so replace it to a special string.
		call set "Input=%%Input:!=#$Exclamation$#%%"
		setlocal ENABLEDELAYEDEXPANSION
		%Speed Improve Start% (
			rem Batch has some problem in "^" processing, so replace it.
			set "Input=!Input:^=#$Caret$#!"
			rem replace %.
			set FormatedInput=
			:LOCALTAG_Main_ReplacementLoop
			if defined Input (
				if "!Input:~,1!" == "%%" (
					set "FormatedInput=!FormatedInput!#$Percent$#"
				) else (
					set "FormatedInput=!FormatedInput!!Input:~,1!"
				)
				set "Input=!Input:~1!"
				goto LOCALTAG_Main_ReplacementLoop
			)
			call :REP "!FormatedInput!"
			endlocal
		) %Speed Improve End%
	)
goto :Main


%Speed Improve Start% (
	:Read
		call :GetVars Main Read strMalCode,
		rem return it directly.
		set "ReturnValue=!strMalCode!"
		call :PrepareVars Main Read ReturnValue,
	goto :eof

	:Eval
		setlocal
			set "MAL_Main_GLOBALVAR_ReturnValue=%~1"
		for /f "tokens=* eol=" %%a in ("!MAL_Main_GLOBALVAR_ReturnValue!") do (
			endlocal
			set "MAL_Main_GLOBALVAR_ReturnValue=%%~a"
		)
	goto :eof

	:Print
		setlocal
			set "MAL_Main_LOCALVAR_Print_Output=%~1"
			rem replace all speical symbol back.
			set MAL_Main_LOCALVAR_Print_OutputBuffer=
			:MAL_Main_LOCALTAG_Print_OutputLoop
			if "!MAL_Main_LOCALVAR_Print_Output:~,15!" == "#$Exclamation$#" (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!^!"
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~15!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if "!MAL_Main_LOCALVAR_Print_Output:~,9!" == "#$Caret$#" (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!^^"
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~9!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if "!MAL_Main_LOCALVAR_Print_Output:~,20!" == "#$Double_Quotation$#" (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!^""
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~20!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if "!MAL_Main_LOCALVAR_Print_Output:~,1!" == "=" (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!="
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~1!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if "!MAL_Main_LOCALVAR_Print_Output:~,1!" == " " (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer! "
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~1!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if "!MAL_Main_LOCALVAR_Print_Output:~,11!" == "#$Percent$#" (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!%%"
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~11!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if defined MAL_Main_LOCALVAR_Print_Output (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!!MAL_Main_LOCALVAR_Print_Output:~,1!"
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~1!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			)
			echo.!MAL_Main_LOCALVAR_Print_OutputBuffer!
			set "MAL_Main_GLOBALVAR_ReturnValue=%~1"
		for /f "tokens=* eol=" %%a in ("!MAL_Main_GLOBALVAR_ReturnValue!") do (
			endlocal
			set "MAL_Main_GLOBALVAR_ReturnValue=%%~a"
		)
	goto :eof

	:REP strMalCode
		set "strMalCode=%~1"
		
		rem Save the original value of strMalCode.
		call :PrepareVars Main REP "strMalCode"
		set GLOBAL_STACK
		echo.
		call :GetVars Main REP "strMalCode"
		set GLOBAL_STACK
		echo.
		echo.
		pause & exit

		rem Prepare arguments for Read.
		call :PrepareVars Main REP strMalCode,
		set GLOBAL_STACK
		echo.
		call :GetVars Main REP strMalCode,
		set GLOBAL_STACK
		echo.
		call :GetVars Main REP strMalCode,
		set GLOBAL_STACK
		echo.
		pause & exit

		call :READ
		rem Get return value.
		call :GetVars Main REP ReturnValue,
		rem Restore the original value of strMalCode.
		call :GetVars Main REP strMalCode,

		pause
		exit

		set ReturnValue
		call :EVAL "!ReturnValue[1]!"
		call :PRINT "!MAL_Main_GLOBALVAR_ReturnValue!"
	goto :eof
) %Speed Improve End%
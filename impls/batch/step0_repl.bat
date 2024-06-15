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
			echo [Mod: Main] [Fn: Read] [Fatal Error] Need more Vars: !VarList! >&2
			exit /b 1
		)
	goto :eof

	:PrepareVars ModuleName FnName VarList
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
		call :GetVars Main Read "strMalCode"
		rem return it directly.
		set "ReturnValue=!strMalCode!"
		call :PrepareVars Main Read "ReturnValue"
	goto :eof

	:Eval
		call :GetVars Main Read "strMalCode"
		rem return it directly.
		set "ReturnValue=!strMalCode!"
		call :PrepareVars Main Read "ReturnValue"
	goto :eof

	:Print
		call :GetVars Main Read "strMalCode"
		
		set "Output=!strMalCode!"
		rem replace all speical symbol back.
		set OutputBuffer=
		:LOCALTAG_Print_OutputLoop
		if "!Output:~,15!" == "#$Exclamation$#" (
			set "OutputBuffer=!OutputBuffer!^!"
			set "Output=!Output:~15!"
			goto LOCALTAG_Print_OutputLoop
		) else if "!Output:~,9!" == "#$Caret$#" (
			set "OutputBuffer=!OutputBuffer!^^"
			set "Output=!Output:~9!"
			goto LOCALTAG_Print_OutputLoop
		) else if "!Output:~,20!" == "#$Double_Quotation$#" (
			set "OutputBuffer=!OutputBuffer!^""
			set "Output=!Output:~20!"
			goto LOCALTAG_Print_OutputLoop
		) else if "!Output:~,1!" == "=" (
			set "OutputBuffer=!OutputBuffer!="
			set "Output=!Output:~1!"
			goto LOCALTAG_Print_OutputLoop
		) else if "!Output:~,1!" == " " (
			set "OutputBuffer=!OutputBuffer! "
			set "Output=!Output:~1!"
			goto LOCALTAG_Print_OutputLoop
		) else if "!Output:~,11!" == "#$Percent$#" (
			set "OutputBuffer=!OutputBuffer!%%"
			set "Output=!Output:~11!"
			goto LOCALTAG_Print_OutputLoop
		) else if defined Output (
			set "OutputBuffer=!OutputBuffer!!Output:~,1!"
			set "Output=!Output:~1!"
			goto LOCALTAG_Print_OutputLoop
		)
		echo.!OutputBuffer!
		
		rem return output buffer.
		set "ReturnValue=!OutputBuffer!"
		call :PrepareVars Main Read "ReturnValue"
	goto :eof

	:REP strMalCode
		set "strMalCode=%~1"
		
		rem Prepare arguments for Read.
		call :PrepareVars Main REP "strMalCode"
		rem Call function Read.
		call :READ
		rem Get return value.
		call :GetVars Main REP "ReturnValue"
		
		set "strMalCode=!ReturnValue!"
		call :PrepareVars Main REP "strMalCode"
		call :EVAL
		call :GetVars Main REP "ReturnValue"

		set "strMalCode=!ReturnValue!"
		call :PrepareVars Main REP "strMalCode"
		call :PRINT
		call :GetVars Main REP "ReturnValue"
	goto :eof
) %Speed Improve End%
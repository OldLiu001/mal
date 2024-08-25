@rem Module Name: Stackframe

@rem Export Functions:
@rem 	:PushVar str_VarName
@rem 	:PushVal str
@rem 	:PopVar str_VarName

@rem Requirement: enable delayed expansion.

@rem Used Namespaces:
@rem 	G_StackPtr
@rem 	G_Stackframe[!G_StackPtr!]
@rem 	G_CallPath


@echo off

::Start
	rem If G_StackPtr is not defined, then set it to 0.
	set /a G_StackPtr = G_StackPtr

	set "_CallPathBackup=!G_CallPath!"
	set "G_CallPath=!G_CallPath! Stackframe(Module)"

	set "_Arguments=%*"
	if "!_Arguments:~,1!" Equ ":" (
		Set "_Arguments=!_Arguments:~1!"
	)
	call :!_Arguments!
	set _Arguments=

	set "G_CallPath=!_CallPathBackup!"
goto :eof

@REM Batchfile Stackframe support BY OldLiu.
% Module - Stackframe - Start % (
	:PushVar _VarName
		set /a G_StackPtr += 1
		set "G_Stackframe[!G_StackPtr!]=!%~1!"
	goto :eof

	:PushVal _Value
		set /a G_StackPtr += 1
		set "G_Stackframe[!G_StackPtr!]=%~1"
	goto :eof

	:PopVar _VarName
		if %G_StackPtr% leq 0 (
			echo [!G_CallPath!] Stack is empty.
			exit 1
		)
		for %%i in (!G_StackPtr!) do (
			set "%~1=!G_Stackframe[%%i]!"
			set "G_Stackframe[%%i]="
		)
		set /a G_StackPtr -= 1
	goto :eof

	:GetVars _VarName1 _VarName2 ...
		rem _VarName is different from each other.
		set "_VarList=%*"
		
		rem Pop Vars.
		rem Pop Var count.
		call :PopVar _VarCount
		for /l %%i in (1 1 !_VarCount!) do (
			call :PopVar _VarName

			rem check if _VarName in _VarList.
			for %%j in (!_VarName!) do (
				if "!_VarList!" == "!_VarList:%%j=!" (
					echo [!G_CallPath!] _VarName: %%j is not in _VarList.
					exit 1
				)

				rem Remove _VarName from _VarList.
				set _VarList=!_VarList:%%j=!
			)
			call :PopVar !_VarName!
		)
		rem check if _VarList is empty.
		for %%_ in (!_VarList!) do (
			echo [!G_CallPath!] Need more Vars: !_VarList!
			exit 1
		)
	goto :eof

	:SaveVars _VarName1 _VarName2 ...
		rem _VarName is different from each other.
		set "_VarList=%*"
		
		rem Cout Var number.
		set "_VarCount=0"
		for %%i in (!_VarList!) do (
			if not defined %%i (
				echo [!G_CallPath!] VarName: %%i is not defined.
				exit 1
			)
			call :PushVar %%i
			call :PushVal %%i
			set /a _VarCount += 1
		)
		rem Push Var count.
		call :PushVal !_VarCount!
	goto :eof
) % Module - Stackframe - End %
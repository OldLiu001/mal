@rem Module Name: Stackframe

@rem Export Functions:
@rem 	:SaveVars _VarName1 _VarName2 ...
@rem 	:GetVars  _VarName1 _VarName2 ...


@echo off

::Start
	rem If G_SP is not defined, then set it to 0.
	set /a G_SP = G_SP

	set "_Args=%*"
	if "!_Args:~,1!" Equ ":" (
		Set "_Args=!_Args:~1!"
	)
	call :!_Args!
	set _Args=
goto :eof

:PushVar _VarName
	set /a G_SP += 1
	set "G_SF[!G_SP!]=!%~1!"
goto :eof

:PushVal _Value
	set /a G_SP += 1
	set "G_SF[!G_SP!]=%~1"
goto :eof

:PopVar _VarName
	if %G_SP% leq 0 (
		>&2 echo Stack is empty.
		pause & exit 1
	)
	for %%i in (!G_SP!) do (
		set "%~1=!G_SF[%%i]!"
		set "G_SF[%%i]="
	)
	set /a G_SP -= 1
goto :eof

:GetVars _VarName1 _VarName2 ...
	rem _VarName is different from each other.
	set "_VarList=%*"
	
	rem Pop Vars.
	call :PopVar _VarCount
	for /l %%i in (1 1 !_VarCount!) do (
		call :PopVar _VarName

		rem check if _VarName in _VarList.
		for %%j in (!_VarName!) do (
			if "!_VarList!" == "!_VarList:%%j=!" (
				>&2 echo _VarName: %%j is not in _VarList.
				pause & exit 1
			)

			rem Remove _VarName from _VarList.
			set _VarList=!_VarList:%%j=!
		)
		call :PopVar !_VarName!
	)
	rem check if _VarList is empty.
	for %%_ in (!_VarList!) do (
		>&2 echo Need more Vars: !_VarList!
		pause & exit 1
	)
goto :eof

:SaveVars _VarName1 _VarName2 ...
	rem _VarName is different from each other.
	set "_VarList=%*"
	
	rem Count Var number.
	set "_VarCount=0"
	for %%i in (!_VarList!) do (
		if not defined %%i (
			>&2 echo VarName: %%i is not defined.
			pause & exit 1
		)
		call :PushVar %%i
		call :PushVal %%i
		set /a _VarCount += 1
	)
	rem Push Var count.
	call :PushVal !_VarCount!
goto :eof
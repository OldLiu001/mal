@REM v1.4
@echo off
call %* || !_C_Fatal! "Call '%~nx0' failed."
exit /b 0


:PrintMalType _ObjMal -> _StrMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		if not defined !%%.ObjMal!.Type (
			!_C_Fatal! "!%%.ObjMal!.Type not defined!"
		)
		!_C_Copy! !%%.ObjMal!.Type %%.Type
		if not "!%%.Type:~,3!" == "Mal" (
			!_C_Fatal! "!%%.ObjMal! is not a MalType!"
		)
		
		!_C_Invoke! Str.bat :New & !_C_GetRet! %%.StrMal
		
		
		if "!%%.Type!" == "MalNum" (
			!_C_Invoke! Str.bat :AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalSym" (
			!_C_Invoke! Str.bat :AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalNil" (
			!_C_Invoke! Str.bat :AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalBool" (
			!_C_Invoke! Str.bat :AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalKwd" (
			!_C_Invoke! Str.bat :AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalStr" (
			!_C_Invoke! Str.bat :AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalLst" (
			!_C_Invoke! Str.bat :AppendVal %%.StrMal "("
			!_C_Copy! !%%.ObjMal!.Count %%.Count
			for /l %%i in (1 1 !%%.Count!) do (
				!_C_Invoke! :PrintMalType !%%.ObjMal!.Item[%%i] & !_C_GetRet! %%.RetStrMal
				!_C_Invoke! Str.bat :AppendStr %%.StrMal %%.RetStrMal
				!_C_Invoke! NS.bat :Free %%.RetStrMal
				
				if  "%%i" neq "!%%.Count!" (
					!_C_Invoke! Str.bat :AppendVal %%.StrMal " "
				)
			)
			!_C_Invoke! Str.bat :AppendVal %%.StrMal ")"
		) else if "!%%.Type!" == "MalVec" (
			!_C_Invoke! Str.bat :AppendVal %%.StrMal "["
			!_C_Copy! !%%.ObjMal!.Count %%.Count
			for /l %%i in (1 1 !%%.Count!) do (
				!_C_Invoke! :PrintMalType !%%.ObjMal!.Item[%%i] & !_C_GetRet! %%.RetStrMal
				!_C_Invoke! Str.bat :AppendStr %%.StrMal %%.RetStrMal
				!_C_Invoke! NS.bat :Free %%.RetStrMal
				
				if  "%%i" neq "!%%.Count!" (
					!_C_Invoke! Str.bat :AppendVal %%.StrMal " "
				)
			)
			!_C_Invoke! Str.bat :AppendVal %%.StrMal "]"
		) else if "!%%.Type!" == "MalMap" (
			!_C_Invoke! NS.bat :Free %%.StrMal
			!_C_Invoke! :PrintMalMap %%.ObjMal & !_C_GetRet! %%.StrMal
		) else (
			!_C_Fatal! "MalType '!%%.Type!' not support yet."
		)
		!_C_Invoke! NS.bat :Free %%.ObjMal

		!_C_Return! %%.StrMal
	)
exit /b 0

:PrintMalMap _MalMap -> _Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.MalMap=!%~1!"

		!_C_Invoke! Str.bat :New & !_C_GetRet! %%.Str
		!_C_Invoke! Str.bat :AppendVal %%.Str "{"

		!_C_Copy! !%%.MalMap!.RawKeyCount %%.KeyCount
		!_C_Copy! !%%.MalMap!.RawKeys %%.Keys

		for /l %%i in (1 1 !%%.KeyCount!) do (
			!_C_Copy! !%%.Keys!.Key[%%i] %%.RawKey
			
			!_C_Copy! !%%.MalMap!.Item[!%%.RawKey!].Count %%.SameKeyCount
			
			for /l %%j in (1 1 !%%.SameKeyCount!) do (
				!_C_Invoke! :PrintMalType !%%.MalMap!.Item[!%%.RawKey!].Item[%%j].Key & !_C_GetRet! %%.StrKey
				!_C_Invoke! :PrintMalType !%%.MalMap!.Item[!%%.RawKey!].Item[%%j].Value & !_C_GetRet! %%.StrVal

				!_C_Invoke! Str.bat :AppendStr %%.Str %%.StrKey
				!_C_Invoke! Str.bat :AppendVal %%.Str " "
				!_C_Invoke! Str.bat :AppendStr %%.Str %%.StrVal
				if %%j neq !%%.SameKeyCount! !_C_Invoke! Str.bat :AppendVal %%.Str " "
			)
			if %%i neq !%%.KeyCount! !_C_Invoke! Str.bat :AppendVal %%.Str " "
		)

		!_C_Invoke! Str.bat :AppendVal %%.Str "}"
		!_C_Return! %%.Str
	)
exit /b 0


(
	@REM Version 1.4

	:Init
		set "_G_LEVEL=0"
		set "_G_TRACE=>%~nx0"
		set "_G_RET="
		set "_G_ERR="

		set "_C_Invoke=call :Invoke"
		set "_C_Copy=call :CopyVar"
		set "_C_GetRet=call :GetRet"
		set "_C_Return=call :Return"
		set "_C_Fatal=call :Fatal"
		set "_C_Throw=call :Throw"
	exit /b 0

	:Invoke * -> *
		set /a _G_LEVEL = _G_LEVEL
		if not defined _G_TRACE (
			set "_G_TRACE=>"
		)

		set "_G_TRACE_{!_G_LEVEL!}=!_G_TRACE!"
		
		set "_G_TMP=%~1"
		if /i "!_G_TMP:~,1!" Equ ":" (
			set "_G_TRACE=!_G_TRACE!>%~1"
		) else (
			set "_G_TRACE=!_G_TRACE!>%~1>%~2"
		)
		set "_G_TMP="
		
		set "_G_RET="
		set /a _G_LEVEL += 1

		call %*
		
		for /f "delims==" %%a in (
			'set _L{!_G_LEVEL!}_ 2^>nul'
		) do set "%%a="

		set /a _G_LEVEL -= 1
		
		!_C_Copy! _G_TRACE_{!_G_LEVEL!} _G_TRACE
		set "_G_TRACE_{!_G_LEVEL!}="
	exit /b 0

	:GetRet _Var -> _
		if not defined _G_ERR (
			!_C_Copy! _G_RET %~1
		)
		set _G_RET=
	exit /b 0

	:Return _Var -> _
		set _G_RET=
		if "%~1" neq "" if "%~1" neq "_" if defined %~1 (
			!_C_Copy! %~1 _G_RET
		)
	exit /b 0

	:Fatal _Msg
		>&2 echo [!_G_TRACE!] Fatal: %~1
		pause & exit 1
	exit /b 0

	:Throw _Type _Data _Msg
		set _G_ERR=_
		set "_G_ERR.Type=%~1"
		if "%~2" neq "_" set "_G_ERR.Data=!%~2!"
		set "_G_ERR.Msg=[!_G_TRACE!] !_G_ERR.Type!: %~3"
	exit /b 0

	:CopyVar _VarFrom _VarTo -> _
		if not defined %~1 (
			!_C_Fatal! "'%~1' undefined."
		)
		set "%~2=!%~1!"
	exit /b 0
)
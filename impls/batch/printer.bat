@REM v1.4
@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
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
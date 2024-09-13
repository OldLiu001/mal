@echo off
set MAL_BATCH_IMPL_SINGLE_FILE=1
if "%~1" equ "CALL_READALL" goto :READALL
if "%~1" equ "CALL_READLINE" goto :READLINE
if "%~1" equ "CALL_WRITEALL" goto :WRITEALL

:MAIN

@REM v1.4

@echo off
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ("%*") do (
		call %%b || !_C_Fatal! "Call '%~nx0' failed."
	)
	exit /b 0
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined MAL_BATCH_IMPL_SINGLE_FILE (
	call UTILITIES :UTILITIES_Init %~n0
) else (
	call :UTILITIES_Init %~n0
)
!_C_Invoke! MAIN Main
exit /b 0

:MAIN_Main
	for %%. in (_L{!_G_LEVEL!}_) do (
		for /l %%_ in () do (
			set "%%.Prompt=user> " & !_C_Invoke! IO WriteVar %%.Prompt
			!_C_Invoke! IO ReadEscapedLine
			if defined _G_RET (
				!_C_GetRet! %%.Input
			) else (
				goto :Main
			)
			!_C_Invoke! MAIN REP %%.Input
		)
	)
exit /b 0

:MAIN_Read _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Return! %%.Mal
	)
exit /b 0

:MAIN_Eval _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Return! %%.Mal
	)
exit /b 0

:MAIN_Print _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Invoke! IO WriteEscapedLineVar %%.Mal
		!_C_Return! _
	)
exit /b 0

:MAIN_REP _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Invoke! MAIN Read %%.Mal & !_C_GetRet! %%.Mal
		!_C_Invoke! MAIN Eval %%.Mal & !_C_GetRet! %%.Mal
		!_C_Invoke! MAIN Print %%.Mal
		!_C_Return! _
	)
exit /b 0
exit /b 0

:io
@REM v:1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0

:IO_ReadEscapedLine _ -> _Line
	for %%. in (_L{!_G_LEVEL!}_) do (
		if not defined MAL_BATCH_IMPL_SINGLE_FILE (
			for /f "delims=" %%a in (
				'call READLINE'
			) do (
				set "%%.Line=%%~a"
			)
		) else (
			for /f "delims=" %%a in (
				'call "%~s0" CALL_READLINE'
			) do (
				set "%%.Line=%%~a"
			)
		)
		!_C_Return! %%.Line
	)
exit /b 0

:IO_WriteEscapedLineVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Var=%~1"
		if "!%%.Var!" == "" (
			!_C_Fatal! "Arg _Var is empty."
		)
		if not defined !%%.Var! (
			!_C_Fatal! "'!%%.Var!' undefined."
		)
		!_C_Copy! !%%.Var! %%.Var
		if not defined MAL_BATCH_IMPL_SINGLE_FILE (
			echo."!%%.Var!"| call WRITEALL
		) else (
			echo."!%%.Var!"| call "%~s0" CALL_WRITEALL
		)
		!_C_Return! _
	)
exit /b 0

:IO_WriteVal _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Val=%~1"
		<nul set /p "=!%%.Val!"
		!_C_Return! _
	)
exit /b 0

:IO_WriteVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Var=%~1"
		if "!%%.Var!" == "" (
			!_C_Fatal! "Arg _Var is empty."
		)
		if not defined !%%.Var! (
			!_C_Fatal! "'!%%.Var!' undefined."
		)
		!_C_Copy! !%%.Var! %%.Var
		<nul set /p "=!%%.Var!"
		!_C_Return! _
	)
exit /b 0

:IO_WriteStr _Str -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Str=!%~1!"
		for /f "delims=" %%b in ("!%%.Str!.LineCount") do (
			for /l %%i in (1 1 !%%b!) do (
				!_C_Copy! !%%.Str!.Line[%%i] %%.Line
				!_C_Invoke! IO WriteEscapedLineVar %%.Line
			)
		)

		!_C_Return! _
	)
exit /b 0

:IO_WriteErrLineVal _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		2>&1 echo.%~1
		!_C_Return! _
	)
exit /b 0

:IO_WriteErrLineVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		2>&1 echo.!%~1!
		!_C_Return! _
	)
exit /b 0
exit /b 0

:mal_step0_packed
@echo off
set MAL_BATCH_IMPL_SINGLE_FILE=1
if "%~1" equ "CALL_READALL" goto :READALL
if "%~1" equ "CALL_READLINE" goto :READLINE
if "%~1" equ "CALL_WRITEALL" goto :WRITEALL

:MAIN

@REM v1.4

@echo off
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ("%*") do (
		call %%b || !_C_Fatal! "Call '%~nx0' failed."
	)
	exit /b 0
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined MAL_BATCH_IMPL_SINGLE_FILE (
	call UTILITIES :UTILITIES_Init %~n0
) else (
	call :UTILITIES_Init %~n0
)
!_C_Invoke! MAIN Main
exit /b 0

:MAIN_Main
	for %%. in (_L{!_G_LEVEL!}_) do (
		for /l %%_ in () do (
			set "%%.Prompt=user> " & !_C_Invoke! IO WriteVar %%.Prompt
			!_C_Invoke! IO ReadEscapedLine
			if defined _G_RET (
				!_C_GetRet! %%.Input
			) else (
				goto :Main
			)
			!_C_Invoke! MAIN REP %%.Input
		)
	)
exit /b 0

:MAIN_Read _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Return! %%.Mal
	)
exit /b 0

:MAIN_Eval _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Return! %%.Mal
	)
exit /b 0

:MAIN_Print _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Invoke! IO WriteEscapedLineVar %%.Mal
		!_C_Return! _
	)
exit /b 0

:MAIN_REP _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Invoke! MAIN Read %%.Mal & !_C_GetRet! %%.Mal
		!_C_Invoke! MAIN Eval %%.Mal & !_C_GetRet! %%.Mal
		!_C_Invoke! MAIN Print %%.Mal
		!_C_Return! _
	)
exit /b 0
exit /b 0

:io
@REM v:1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0

:IO_ReadEscapedLine _ -> _Line
	for %%. in (_L{!_G_LEVEL!}_) do (
		if not defined MAL_BATCH_IMPL_SINGLE_FILE (
			for /f "delims=" %%a in (
				'call READLINE'
			) do (
				set "%%.Line=%%~a"
			)
		) else (
			for /f "delims=" %%a in (
				'call "%~s0" CALL_READLINE'
			) do (
				set "%%.Line=%%~a"
			)
		)
		!_C_Return! %%.Line
	)
exit /b 0

:IO_WriteEscapedLineVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Var=%~1"
		if "!%%.Var!" == "" (
			!_C_Fatal! "Arg _Var is empty."
		)
		if not defined !%%.Var! (
			!_C_Fatal! "'!%%.Var!' undefined."
		)
		!_C_Copy! !%%.Var! %%.Var
		if not defined MAL_BATCH_IMPL_SINGLE_FILE (
			echo."!%%.Var!"| call WRITEALL
		) else (
			echo."!%%.Var!"| call "%~s0" CALL_WRITEALL
		)
		!_C_Return! _
	)
exit /b 0

:IO_WriteVal _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Val=%~1"
		<nul set /p "=!%%.Val!"
		!_C_Return! _
	)
exit /b 0

:IO_WriteVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Var=%~1"
		if "!%%.Var!" == "" (
			!_C_Fatal! "Arg _Var is empty."
		)
		if not defined !%%.Var! (
			!_C_Fatal! "'!%%.Var!' undefined."
		)
		!_C_Copy! !%%.Var! %%.Var
		<nul set /p "=!%%.Var!"
		!_C_Return! _
	)
exit /b 0

:IO_WriteStr _Str -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Str=!%~1!"
		for /f "delims=" %%b in ("!%%.Str!.LineCount") do (
			for /l %%i in (1 1 !%%b!) do (
				!_C_Copy! !%%.Str!.Line[%%i] %%.Line
				!_C_Invoke! IO WriteEscapedLineVar %%.Line
			)
		)

		!_C_Return! _
	)
exit /b 0

:IO_WriteErrLineVal _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		2>&1 echo.%~1
		!_C_Return! _
	)
exit /b 0

:IO_WriteErrLineVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		2>&1 echo.!%~1!
		!_C_Return! _
	)
exit /b 0
exit /b 0

:mal_step0_packed
@echo off
set MAL_BATCH_IMPL_SINGLE_FILE=1
if "%~1" equ "CALL_READALL" goto :READALL
i
exit /b 0

:ns
@REM v1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0

:New _Type -> _Namespace
	for %%. in (_L{!_G_LEVEL!}_) do (
		set /a _G_NSP = _G_NSP
		set /a _G_NSP += 1
		set "_G_NS[!_G_NSP!]=_"
		set "_G_NS[!_G_NSP!].=_"
		set "_G_NS[!_G_NSP!].Type=%~1"

		set "%%.RetV=_G_NS[!_G_NSP!]"
		!_C_Return! %%.RetV
	)
exit /b 0

:Free _Namespace -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		if "!%~1!" == "" (
			!_C_Fatal! "Arg _Namespace is empty."
		)
		if not defined !%~1! (
			!_C_Fatal! "'!%~1!' undefined."
		)
		if not defined !%~1!. (
			!_C_Fatal! "'!%~1!' is not a namespace."
		)

		for /f "delims==" %%i in (
			'set !%~1!'
		) do (
			set "%%i="
		)

		!_C_Return! _
	)
exit /b 0
exit /b 0

:pack
@echo off
setlocal ENABLEDELAYEDEXPANSION
if "%~1" == "" (
	echo Single file packer for MAL-BATCH
	echo.
	echo Usage: %~n0 ^<entry^> ^<output^> 
	echo 	^<entry^> - Entry point of the program, like "stepX_XXX.bat"
	echo 	^<output^> - Output file, e.g. "mal_packed.bat"
	pause
	exit /b 1
)

pushd "%~dp0"
set "entry=%~1"
set "output=%~2"

if exist "%output%" (
	echo Output file already exist.
	exit /b 1
)
if not exist "%entry%" (
	echo Entry not exist.
	exit /b 1
)

(
	echo @echo off
	echo set MAL_BATCH_IMPL_SINGLE_FILE=1
	echo if "%%~1" equ "CALL_READALL" goto :READALL
	echo if "%%~1" equ "CALL_READLINE" goto :READLINE
	echo if "%%~1" equ "CALL_WRITEALL" goto :WRITEALL
	echo.
	echo :MAIN
	echo.
) >"%output%"
type %entry% >>"%output%"

for %%i in (*.bat) do (
	if "%%i" neq "%entry%" (
		(
			echo.
			echo exit /b 0
			echo.
			echo :%%~ni
		) >>"%output%"
		type "%%i"  >>"%output%"
	)
)

exit /b 0

:printer
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
exit /b 0

:readall
@echo off & setlocal disabledelayedexpansion

for /f "tokens=* eol=" %%a in ('more') do (
	if not defined MAL_BATCH_IMPL_SINGLE_FILE (
		echo "%%a"|call readline
	) else (
		echo "%%a"|call "%~0" CALL_READLINE
	)
)
exit /b 0
exit /b 0

:reader
@REM v:1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0



:ReadString _StrMalCode -> _ObjAST
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.StrMalCode=!%~1!"
		
		!_C_Invoke! NS.bat :New Reader & !_C_GetRet! %%.ObjReader
		

		set "!%%.ObjReader!.TokenCount=0"
		set "!%%.ObjReader!.TokenPtr=1"

		!_C_Copy! !%%.StrMalCode!.LineCount %%.LineCount
		for /l %%i in (1 1 !%%.LineCount!) do (
			!_C_Invoke! :Tokenize !%%.StrMalCode!.Line[%%i] %%.ObjReader
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free %%.ObjReader
				exit /b 0
			)
		)

		rem Check if there is any token.
		!_C_Copy! !%%.ObjReader!.TokenCount %%.TotalTokenNum
		if "!%%.TotalTokenNum!" == "0" (
			!_C_Fatal! TODO
		)
		
		rem Translate the tokens to AST.
		!_C_Invoke! :ReadForm %%.ObjReader & !_C_GetRet! %%.ObjAST
		if defined _G_ERR (
			!_C_Invoke! NS.bat :Free %%.ObjReader
			exit /b 0
		)
		

		!_C_Invoke! NS.bat :Free %%.ObjReader

		!_C_Return! %%.ObjAST
	)
exit /b 0

:ReadForm  _ObjReader -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjReader=!%~1!"

		!_C_Copy! !%%.ObjReader!.TokenPtr %%.TokenPtr
		!_C_Copy! !%%.ObjReader!.TokenCount %%.TotalTokenNum

		if !%%.TokenPtr! Gtr !%%.TotalTokenNum! (
			!_C_Throw! Exception _ "unexpected EOF, need more token."
			exit /b 0
		)

		!_C_Copy! !%%.ObjReader!.Token[!%%.TokenPtr!] %%.CurToken
		
		if "!%%.CurToken!" == "(" (
			!_C_Invoke! :ReadList %%.ObjReader & !_C_GetRet! %%.ObjAST
			if defined _G_ERR exit /b 0
		) else if "!%%.CurToken!" == "[" (
			!_C_Invoke! :ReadList %%.ObjReader & !_C_GetRet! %%.ObjAST
			if defined _G_ERR exit /b 0
		) else if "!%%.CurToken!" == "{" (
			!_C_Invoke! :ReadMap %%.ObjReader & !_C_GetRet! %%.ObjAST
			if defined _G_ERR exit /b 0
		) else if "!%%.CurToken!" == "'" (
			!_C_Invoke! TYPES.bat :NewMalAtom MalSym quote & !_C_GetRet! %%.ObjMalSymQuote
			set /a !%%.ObjReader!.TokenPtr += 1

			!_C_Invoke! :ReadForm %%.ObjReader & !_C_GetRet! %%.ObjMal
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free %%.ObjMalSymQuote
				exit /b 0
			)
			!_C_Invoke! TYPES.bat :NewMalList %%.ObjMalSymQuote %%.ObjMal & !_C_GetRet! %%.ObjAST
		) else if "!%%.CurToken!" == "`" (
			!_C_Invoke! TYPES.bat :NewMalAtom MalSym quasiquote & !_C_GetRet! %%.ObjMalSymQuote
			set /a !%%.ObjReader!.TokenPtr += 1

			!_C_Invoke! :ReadForm %%.ObjReader & !_C_GetRet! %%.ObjMal
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free %%.ObjMalSymQuote
				exit /b 0
			)
			!_C_Invoke! TYPES.bat :NewMalList %%.ObjMalSymQuote %%.ObjMal & !_C_GetRet! %%.ObjAST
		) else if "!%%.CurToken!" == "@" (
			!_C_Invoke! TYPES.bat :NewMalAtom MalSym deref
			!_C_Copy! _G_RET %%.ObjMalSymQuote
			set /a !%%.ObjReader!.TokenPtr += 1

			!_C_Invoke! :ReadForm %%.ObjReader & !_C_GetRet! %%.ObjMal
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free %%.ObjMalSymQuote
				exit /b 0
			)
			!_C_Invoke! TYPES.bat :NewMalList %%.ObjMalSymQuote %%.ObjMal & !_C_GetRet! %%.ObjAST
		) else if "!%%.CurToken!" == "~" (
			!_C_Invoke! TYPES.bat :NewMalAtom MalSym unquote & !_C_GetRet! %%.ObjMalSymQuote
			set /a !%%.ObjReader!.TokenPtr += 1

			!_C_Invoke! :ReadForm %%.ObjReader & !_C_GetRet! %%.ObjMal
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free %%.ObjMalSymQuote
				exit /b 0
			)
			!_C_Invoke! TYPES.bat :NewMalList %%.ObjMalSymQuote %%.ObjMal & !_C_GetRet! %%.ObjAST
		) else if "!%%.CurToken!" == "~@" (
			!_C_Invoke! TYPES.bat :NewMalAtom MalSym splice-unquote & !_C_GetRet! %%.ObjMalSymQuote
			set /a !%%.ObjReader!.TokenPtr += 1

			!_C_Invoke! :ReadForm %%.ObjReader & !_C_GetRet! %%.ObjMal
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free %%.ObjMalSymQuote
				exit /b 0
			)
			!_C_Invoke! TYPES.bat :NewMalList %%.ObjMalSymQuote %%.ObjMal & !_C_GetRet! %%.ObjAST
		) else if "!%%.CurToken!" == "$C" (
			!_C_Invoke! :ReadMeta %%.ObjReader & !_C_GetRet! %%.ObjAST
			if defined _G_ERR exit /b 0
		) else if "!%%.CurToken!" == ")" (
			echo TODO:Exception
			pause & exit 1
		) else if "!%%.CurToken!" == "]" (
			echo TODO:Exception
			pause & exit 1
		) else if "!%%.CurToken!" == "}" (
			echo TODO:Exception
			pause & exit 1
		) else if "!%%.CurToken:~,1!" == ";" (
			!_C_Throw! Empty _ _
		) else (
			!_C_Invoke! :ReadAtom %%.ObjReader & !_C_GetRet! %%.ObjAST
		)

		!_C_Return! %%.ObjAST
	)
exit /b 0

:ReadAtom _ObjReader -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjReader=!%~1!"

		!_C_Copy! !%%.ObjReader!.TokenPtr %%.TokenPtr
		!_C_Copy! !%%.ObjReader!.TokenCount %%.TotalTokenNum

		if !%%.TokenPtr! Gtr !%%.TotalTokenNum! (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)

		!_C_Copy! !%%.ObjReader!.Token[!%%.TokenPtr!] %%.CurToken
		set /a %%.TokenPtr += 1
		!_C_Copy! %%.TokenPtr !%%.ObjReader!.TokenPtr
		
		!_C_Invoke! NS.bat :New & !_C_GetRet! %%.ObjMalCode
		!_C_Copy! %%.CurToken !%%.ObjMalCode!.Value
		
		rem check token's MalType.
		set /a %%.TestNum = %%.CurToken
		if "!%%.TestNum!" == "!%%.CurToken!" (
			set "!%%.ObjMalCode!.Type=MalNum"
		) else if "!%%.CurToken!" == "nil" (
			set "!%%.ObjMalCode!.Type=MalNil"
		) else if "!%%.CurToken!" == "true" (
			set "!%%.ObjMalCode!.Type=MalBool"
		) else if "!%%.CurToken!" == "false" (
			set "!%%.ObjMalCode!.Type=MalBool"
		) else if "!%%.CurToken:~,2!" == "$D" (
			set "!%%.ObjMalCode!.Type=MalStr"
		) else if "!%%.CurToken:~,2!" == "$A" (
			set "!%%.ObjMalCode!.Type=MalKwd"
		) else (
			set "!%%.ObjMalCode!.Type=MalSym"
		)
		rem TODO: CheckMore.

		!_C_Return! %%.ObjMalCode
	)
exit /b 0

:ReadList _ObjReader -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjReader=!%~1!"

		!_C_Copy! !%%.ObjReader!.TokenPtr %%.TokenPtr
		!_C_Copy! !%%.ObjReader!.TokenCount %%.TotalTokenNum

		if !%%.TokenPtr! Gtr !%%.TotalTokenNum! (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)

		!_C_Copy! !%%.ObjReader!.Token[!%%.TokenPtr!] %%.CurToken

		if "!%%.CurToken!" Equ "(" (
			!_C_Invoke! NS.bat :New MalLst & !_C_GetRet! %%.ObjMalCode
		) else if "!%%.CurToken!" Equ "[" (
			!_C_Invoke! NS.bat :New MalVec & !_C_GetRet! %%.ObjMalCode
		) else (
			>&2 echo [!_G_TRACE!] unexpected token '!%%.CurToken!'.
			pause & exit 1
		)

		set /a %%.TokenPtr += 1
		!_C_Copy! %%.TokenPtr !%%.ObjReader!.TokenPtr

		if !%%.TokenPtr! Gtr !%%.TotalTokenNum! (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)
		

		set "%%.Count=0"
	)
	:ReadList_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! !%%.ObjReader!.TokenPtr %%.TokenPtr
		
		if !%%.TokenPtr! Gtr !%%.TotalTokenNum! (
			set _G_ERR=_
			set _G_ERR.Type=Exception
			set "_G_ERR.Msg=[!_G_TRACE!] Exception: unbalanced parenthesis."
			!_C_Invoke! NS.bat :Free %%.ObjMalCode
			exit /b 0
		)

		!_C_Copy! !%%.ObjReader!.Token[!%%.TokenPtr!] %%.CurToken

		if "!%%.CurToken!" == ")" (
			!_C_Copy! !%%.ObjMalCode!.Type %%.Type
			if "!%%.Type!" Neq "MalLst" (
				!_C_Invoke! NS.bat :Free %%.ObjMalCode
				set _G_ERR=_
				set _G_ERR.Type=Exception
				set "_G_ERR.Msg=[!_G_TRACE!] Exception: unbalanced parenthesis."
				exit /b 0
			)
			set /a %%.TokenPtr += 1
			!_C_Copy! %%.TokenPtr !%%.ObjReader!.TokenPtr
			goto :ReadList_Pass
		)
		if "!%%.CurToken!" == "]" (
			!_C_Copy! !%%.ObjMalCode!.Type %%.Type
			if "!%%.Type!" Neq "MalVec" (
				!_C_Invoke! NS.bat :Free %%.ObjMalCode
				set _G_ERR=_
				set _G_ERR.Type=Exception
				set "_G_ERR.Msg=[!_G_TRACE!] Exception: unbalanced parenthesis."
				exit /b 0
			)
			!_C_Copy! !%%.ObjMalCode!.Type %%.Type
			set /a %%.TokenPtr += 1
			!_C_Copy! %%.TokenPtr !%%.ObjReader!.TokenPtr
			goto :ReadList_Pass
		)
		set /a %%.Count += 1

		!_C_Invoke! :ReadForm %%.ObjReader & !_C_GetRet! !%%.ObjMalCode!.Item[!%%.Count!]

		goto :ReadList_Loop
	)
	:ReadList_Pass
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! %%.Count !%%.ObjMalCode!.Count

		!_C_Return! %%.ObjMalCode
	)
exit /b 0

:ReadMap _ObjReader -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjReader=!%~1!"

		!_C_Copy! !%%.ObjReader!.TokenPtr %%.TokenPtr
		!_C_Copy! !%%.ObjReader!.TokenCount %%.TokenCount
		
		if !%%.TokenPtr! Gtr !%%.TokenCount! (
			!_C_Invoke! :Throw Exception _ "unbalanced parenthesis."
			exit /b 0
		)

		set /a %%.TokenPtr += 1
		!_C_Copy! %%.TokenPtr !%%.ObjReader!.TokenPtr

		!_C_Invoke! NS.bat :New MalMap & !_C_GetRet! %%.MalMap

		set "%%.MapKeyCount=0"
		set /a %%.RawKeyCount=0
		!_C_Invoke! NS.bat :New RawKeyArr & !_C_GetRet! %%.RawKeys
	)
	:ReadMap_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
		
		if !%%.TokenPtr! Gtr !%%.TokenCount! (
			!_C_Invoke! :Throw Exception _ "unbalanced parenthesis."
			!_C_Invoke! NS.bat :Free %%.MalMap
			exit /b 0
		)
		!_C_Copy! !%%.ObjReader!.TokenPtr %%.TokenPtr
		!_C_Copy! !%%.ObjReader!.Token[!%%.TokenPtr!] %%.Token
		if "!%%.Token!" == "}" (
			set /a %%.TokenPtr += 1
			!_C_Copy! %%.TokenPtr !%%.ObjReader!.TokenPtr
			goto :ReadMap_Pass
		)

		@REM Read the key.
		!_C_Invoke! :ReadForm %%.ObjReader & !_C_GetRet! %%.MalKey


		@REM Check if the key is MalStr or MalKwd.
		!_C_Copy! !%%.MalKey!.Type %%.Type
		if "!%%.Type!" Neq "MalStr" if "!%%.Type!" Neq "MalKwd" (
			!_C_Invoke! :Throw Exception _ "Map key must be 'MalStr' or 'MalKwd'."
			!_C_Invoke! NS.bat :Free %%.MalKey
			!_C_Invoke! NS.bat :Free %%.MalMap
			exit /b 0
		)
		
		!_C_Copy! !%%.MalKey!.Value %%.RawKey


		!_C_Copy! !%%.ObjReader!.TokenPtr %%.TokenPtr

		if !%%.TokenPtr! Gtr !%%.TokenCount! (
			!_C_Invoke! :Throw Exception _ "Unmatched map key-value pair."
			!_C_Invoke! NS.bat :Free %%.MalMap
			exit /b 0
		)

		!_C_Invoke! :ReadForm %%.ObjReader & !_C_GetRet! %%.MalVal
		if defined !%%.MalMap!.Item[!%%.RawKey!] (
			!_C_Copy! !%%.MalMap!.Item[!%%.RawKey!].Count %%.SameKeyCount
			set %%.Exist=False
			for /l %%i in (1 1 !%%.SameKeyCount!) do (
				!_C_Copy! !%%.MalMap!.Item[!%%.RawKey!].Item[%%i].Key %%.ExistKey
				!_C_Copy! !%%.ExistKey!.Value %%.ExistRawKey
				if "!%%.ExistRawKey!" == "!%%.RawKey!" (
					set %%.Exist=True
					!_C_Fatal! TODO
				)
			)
			
			if "!%%.Exist!" == "False" (
				set /a !%%.MalMap!.Item[!%%.RawKey!].Count += 1
				
				!_C_Copy! "!%%.MalMap!.Item[!%%.RawKey!].Count" %%.SameKeyCount
				!_C_Copy! %%.MalKey !%%.MalMap!.Item[!%%.RawKey!].Item[!%%.SameKeyCount!].Key
				!_C_Copy! %%.MalVal !%%.MalMap!.Item[!%%.RawKey!].Item[!%%.SameKeyCount!].Value
			) else (
				!_C_Fatal! TODO
			)
		) else (
			set "!%%.MalMap!.Item[!%%.RawKey!]=_"
			set "!%%.MalMap!.Item[!%%.RawKey!].Count=1"

			!_C_Copy! "!%%.MalMap!.Item[!%%.RawKey!].Count" %%.SameKeyCount
			!_C_Copy! %%.MalKey !%%.MalMap!.Item[!%%.RawKey!].Item[!%%.SameKeyCount!].Key
			!_C_Copy! %%.MalVal !%%.MalMap!.Item[!%%.RawKey!].Item[!%%.SameKeyCount!].Value

			set /a %%.RawKeyCount += 1
			set "!%%.RawKeys!.Key[!%%.RawKeyCount!]=!%%.RawKey!"
		)

		set /a %%.MapKeyCount += 1
		goto :ReadMap_Loop
	)
	:ReadMap_Pass
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! %%.MapKeyCount !%%.MalMap!.Count
		!_C_Copy! %%.RawKeyCount !%%.MalMap!.RawKeyCount
		!_C_Copy! %%.RawKeys !%%.MalMap!.RawKeys
		!_C_Return! %%.MalMap
	)
exit /b 0

:ReadMeta _Reader -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Reader=!%~1!"

		set /a !%%.Reader!.TokenPtr += 1
		
		if !%%.TokenPtr! Gtr !%%.TokenCount! (
			!_C_Invoke! :Throw Exception _ "Unexpected EOF, need more token."
			exit /b 0
		)

		!_C_Invoke! TYPES.bat :NewMalAtom MalSym "with-meta" & !_C_GetRet! %%.MalSym
		!_C_Invoke! :ReadForm %%.Reader & !_C_GetRet! %%.MalMeta
		!_C_Invoke! :ReadForm %%.Reader & !_C_GetRet! %%.MalType
		!_C_Invoke! TYPES.bat :NewMalList %%.MalSym %%.MalType %%.MalMeta & !_C_GetRet! %%.MalRes
		!_C_Return! %%.MalRes
	)
exit /b 0





:Tokenize _Line _ObjReader -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Line=!%~1!"
		set "%%.ObjReader=!%~2!"

		!_C_Copy! %%.Line %%.CurLine
		!_C_Copy! !%%.ObjReader!.TokenCount %%.CurTokenNum

		rem Tokenize the _CurLine.
		set %%.ParsingStr=False
		set %%.NormalToken=
	)
	:Tokenizing_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
		if "!%%.CurLine!" == "" (
			if "!%%.ParsingStr!" == "True" (
				set _G_ERR=_
				set _G_ERR.Type=Exception
				set "_G_ERR.Msg=[!_G_TRACE!] Exception: unexpected EOF, string is incomplete."
				exit /b 0
			)
			goto :Tokenizing_Pass
		)
		if "!%%.ParsingStr!" == "False" (
			if "!%%.CurLine:~,1!" == " " (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurLine=!%%.CurLine:~1!"
				goto Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "	" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurLine=!%%.CurLine:~1!"
				goto Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "," (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurLine=!%%.CurLine:~1!"
				goto Tokenizing_Loop
			)
			if "!%%.CurLine:~,2!" == "~@" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=~@"
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~2!"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "[" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=["
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "]" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=]"
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "(" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=("
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == ")" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=)"
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "{" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken={"
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "}" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=}"
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "'" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken='"
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "`" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=`"
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "~" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=~"
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "@" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=@"
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto :Tokenizing_Loop
			)
			rem ^ --- \eC
			if "!%%.CurLine:~,2!" == "$C" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=$C"
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~2!"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,2!" == "$D" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				rem string.
				set "%%.CurLine=!%%.CurLine:~2!"
				set "%%.ParsingStr=True"
				set "%%.StrToken="
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == ";" (
				if defined %%.NormalToken (
					rem save normal token first.
					!_C_Copy! %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				rem comment.
				!_C_Copy! %%.CurLine %%.CurToken
				set /a %%.CurTokenNum += 1
				!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
				set "%%.CurLine="
				goto :Tokenizing_Loop
			)

			set "%%.NormalToken=!%%.NormalToken!!%%.CurLine:~,1!"
			set "%%.CurLine=!%%.CurLine:~1!"
			goto :Tokenizing_Loop
		) else (
			rem parsing string now.
			if "!%%.CurLine:~,2!" == "\\" (
				rem \\
				set "%%.CurLine=!%%.CurLine:~2!"
				set "%%.StrToken=!%%.StrToken!\\"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,3!" == "\$D" (
				rem \"
				set "%%.CurLine=!%%.CurLine:~3!"
				set "%%.StrToken=!%%.StrToken!\$D"
				goto :Tokenizing_Loop
			)
			if "!%%.CurLine:~,2!" == "$D" (
				rem end of string.
				set "%%.CurLine=!%%.CurLine:~2!"
				set "%%.ParsingStr=False"
				set /a %%.CurTokenNum += 1
				set "%%.StrToken=$D!%%.StrToken!$D"
				!_C_Copy! %%.StrToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
				goto :Tokenizing_Loop
			)
			set "%%.StrToken=!%%.StrToken!!%%.CurLine:~,1!"
			set "%%.CurLine=!%%.CurLine:~1!"
			goto :Tokenizing_Loop
		)
	)
	:Tokenizing_Pass
	for %%. in (_L{!_G_LEVEL!}_) do (
		if defined %%.NormalToken (
			rem save normal token first.
			!_C_Copy! %%.NormalToken %%.CurToken
			set /a %%.CurTokenNum += 1
			!_C_Copy! %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
			set %%.NormalToken=
		)
		!_C_Copy! %%.CurTokenNum !%%.ObjReader!.TokenCount

		!_C_Return! _
	)
exit /b 0
exit /b 0

:readline
@REM v: 1.4

@echo off
setlocal disabledelayedexpansion
for /f "delims=#" %%. in (
	'prompt #$E# ^& echo on ^& for %%_ in ^( . ^) do rem'
) do (
	set "_Esc=%%."
)

set _In= & set /p "_In="
for /f "delims=" %%. in ("%_Esc%") do (
	if defined _In (
		call set "_In=%%_In:"=%%.D%%"
		call set "_In=%%_In:!=%%.E%%"
		setlocal ENABLEDELAYEDEXPANSION
		(
			set "_In=!_In:^=%%.C!"
			set "_In2="
			:_Replace
			if defined _In (
				if "!_In:~,1!" == "%%" (
					set "_In2=!_In2!%_Esc%P"
				) else (
					set "_In2=!_In2!!_In:~,1!"
				)
				set "_In=!_In:~1!"
				goto _Replace
			)
			:_Replace2
			if defined _In2 (
				if "!_In2:~,1!" == "%_Esc%" (
					set "_In3=!_In3!$"
				) else if "!_In2:~,1!" == "$" (
					set "_In3=!_In3!$$"
				) else if "!_In2:~,1!" == ":" (
					set "_In3=!_In3!$A"
				) else (
					set "_In3=!_In3!!_In2:~,1!"
				)
				set "_In2=!_In2:~1!"
				goto _Replace2
			)
			echo.!_In3!
		)
		endlocal
	)
)

exit /b 0

:step1_read_print
@REM v:1.4

@echo off & pushd "%~dp0" & setlocal ENABLEDELAYEDEXPANSION
call :Init
!_C_Invoke! :Main
exit /b 0

:Main
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Prompt=user> " & !_C_Invoke! IO.bat :WriteVar %%.Prompt
		!_C_Invoke! IO.bat :ReadEscapedLine
		if defined _G_RET (
			!_C_GetRet! %%.Input
		) else (
			goto :Main
		)
		
		!_C_Invoke! Str.bat :FromVar %%.Input & !_C_GetRet! %%.Str

		!_C_Invoke! :REP %%.Str
		if defined _G_ERR (
			if "!_G_ERR.Type!" == "Exception" (
				!_C_Invoke! IO.bat :WriteErrLineVar _G_ERR.Msg
			) else if "!_G_ERR.Type!" == "Empty" (
				rem do nothing.
			) else (
				!_C_Fatal! "Error type '!_G_ERR.Type!' not support."
			)

			for /f "delims==" %%a in (
				'set _G_ERR 2^>nul'
			) do set "%%a="
		)
		
		!_C_Invoke! NS.bat :Free %%.Str
	)
goto :Main

:Read _StrMal -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.StrMal=!%~1!"
		
		!_C_Invoke! Reader.bat :ReadString %%.StrMal & !_C_GetRet! %%.ObjMal
		if defined _G_ERR exit /b 0

		!_C_Return! %%.ObjMal
	)
exit /b 0

:Eval _ObjMal -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		!_C_Return! %%.ObjMal
	)
exit /b 0

:Print _ObjMal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		
		!_C_Invoke! Printer.bat :PrintMalType %%.ObjMal & !_C_GetRet! %%.StrMal
		
		!_C_Invoke! IO.bat :WriteStr %%.StrMal

		!_C_Invoke! NS.bat :Free %%.StrMal

		!_C_Return! _
	)
exit /b 0

:REP _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		
		!_C_Invoke! :Read %%.Mal & !_C_GetRet! %%.Mal
		if defined _G_ERR exit /b 0
		!_C_Invoke! :Eval %%.Mal & !_C_GetRet! %%.Mal
		!_C_Invoke! :Print %%.Mal
		!_C_Return! _
	)
exit /b 0
exit /b 0

:str
@REM v:1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0

:New -> _Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Invoke! NS.bat :New String & !_C_GetRet! %%.Str
		set "!%%.Str!.LineCount=0"
		!_C_Return! %%.Str
	)
exit /b 0

:FromVar _Var -> _Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Invoke! NS.bat :New String & !_C_GetRet! %%.Str
		set "!%%.Str!.LineCount=1"
		set "!%%.Str!.Line[1]=!%~1!"
		!_C_Return! %%.Str
	)
exit /b 0

:FromVal _Val -> _Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Invoke! NS.bat :New String & !_C_GetRet! %%.Str
		set "!%%.Str!.LineCount=1"
		set "!%%.Str!.Line[1]=%~1"
		!_C_Return! %%.Str
	)
exit /b 0

:AppendStr _Str _NewStr -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! !%~1!.LineCount %%.LineCount
		!_C_Copy! !%~2!.LineCount %%.LineCount2
		if !%%.LineCount! geq 1 (
			if !%%.LineCount2! geq 1 (
				!_C_Copy! !%~1!.Line[!%%.LineCount!] %%.Line
				!_C_Copy! !%~2!.Line[1] %%.Line2
				set "!%~1!.Line[!%%.LineCount!]=!%%.Line!!%%.Line2!"
			)
		)
		for /l %%i in (2 1 !%%.LineCount2!) do (
			set /a %%.LineCount += 1
			!_C_Copy! !%~2!.Line[%%i] !%~1!.Line[!%%.LineCount!]
		)
		!_C_Copy! %%.LineCount !%~1!.LineCount
		!_C_Return! _
	)
exit /b 0

:AppendVal _Str _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! !%~1!.LineCount %%.LineCount
		if "!%%.LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set %%.LineCount=1
		)
		if defined !%~1!.Line[!%%.LineCount!] (
			!_C_Copy! !%~1!.Line[!%%.LineCount!] %%.LastLine
			set "%%.LastLine=!%%.LastLine!%~2"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		) else (
			set "%%.LastLine=%~2"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		)
		!_C_Return! _
	)
exit /b 0

:AppendVar _Str _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! !%~1!.LineCount %%.LineCount
		if "!%%.LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set %%.LineCount=1
		)
		if defined !%~1!.Line[!%%.LineCount!] (
			!_C_Copy! !%~1!.Line[!%%.LineCount!] %%.LastLine
			set "%%.LastLine=!%%.LastLine!!%~2!"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		) else (
			set "%%.LastLine=!%~2!"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		)
		!_C_Return! _
	)
exit /b 0
exit /b 0

:types
@REM v:1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0


:NewMalAtom _ValType _ValValue -> _ObjMalAtom
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ValType=%~1"
		set "%%.ValValue=%~2"
		!_C_Invoke! NS.bat :New !%%.ValType! & !_C_GetRet! %%.ObjMal
		!_C_Copy! %%.ValValue !%%.ObjMal!.Value
		!_C_Return! %%.ObjMal
	)
exit /b 0

:NewMalList _Var1 _Var2 ... -> _ObjMalList
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Invoke! NS.bat :New MalLst & !_C_GetRet! %%.ObjMal
		set "%%.Count=0"
	)
	:NewMalList_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
		if "%~1" neq "" (
			set /a %%.Count += 1
			!_C_Copy! %~1 !%%.ObjMal!.Item[!%%.Count!]
			shift
			goto :NewMalList_Loop
		)
		!_C_Copy! %%.Count !%%.ObjMal!.Count
		!_C_Return! %%.ObjMal
	)
exit /b 0
exit /b 0

:utilities

	@REM Version 1.5

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0


:UTILITIES_Init _MainModName
	set "_G_LEVEL=0"
	set "_G_TRACE=>%~1"
	set "_G_RET="
	set "_G_ERR="
	set "_G_MAIN=%~1"

	if defined MAL_BATCH_IMPL_SINGLE_FILE (
		set "_C_Invoke=call :UTILITIES_Invoke"
		set "_C_Copy=call :UTILITIES_CopyVar"
		set "_C_GetRet=call :UTILITIES_GetRet"
		set "_C_Return=call :UTILITIES_Return"
		set "_C_Fatal=call :UTILITIES_Fatal"
		set "_C_Throw=call :UTILITIES_Throw"
	) else (
		set "_C_Invoke=call UTILITIES :UTILITIES_Invoke"
		set "_C_Copy=call UTILITIES :UTILITIES_CopyVar"
		set "_C_GetRet=call UTILITIES :UTILITIES_GetRet"
		set "_C_Return=call UTILITIES :UTILITIES_Return"
		set "_C_Fatal=call UTILITIES :UTILITIES_Fatal"
		set "_C_Throw=call UTILITIES :UTILITIES_Throw"
	)
exit /b 0

:UTILITIES_Invoke _Mod _Fn * -> *
	set /a _G_LEVEL = _G_LEVEL
	if not defined _G_TRACE (
		set "_G_TRACE=>"
	)

	set "_G_TRACE_{!_G_LEVEL!}=!_G_TRACE!"
	set "_G_TRACE=!_G_TRACE!>(%~1)%~2"
	set "_G_RET="
	set /a _G_LEVEL += 1

	for /f "tokens=1,2,*" %%a in ("%*") do (
		if defined MAL_BATCH_IMPL_SINGLE_FILE (
			if "%%a" == "MAIN" (
				call :MAIN_%%b %%c
			) else (
				call :%%a_%%b %%c
			)
		) else (
			if "%%a" == "MAIN" (
				call !_G_MAIN! CALL_SELF :MAIN_%%b %%c
			) else (
				call %%a :%%a_%%b %%c
			)
		)
	)
	
	for /f "delims==" %%a in (
		'set _L{!_G_LEVEL!}_ 2^>nul'
	) do set "%%a="

	set /a _G_LEVEL -= 1
	
	!_C_Copy! _G_TRACE_{!_G_LEVEL!} _G_TRACE
	set "_G_TRACE_{!_G_LEVEL!}="
exit /b 0

:UTILITIES_GetRet _Var -> _
	if not defined _G_ERR (
		!_C_Copy! _G_RET %~1
	)
	set _G_RET=
exit /b 0

:UTILITIES_Return _Var -> _
	set _G_RET=
	if "%~1" neq "" if "%~1" neq "_" if defined %~1 (
		!_C_Copy! %~1 _G_RET
	)
exit /b 0

:UTILITIES_Fatal _Msg
	>&2 echo [!_G_TRACE!] Fatal: %~1
	pause & exit 1
exit /b 0

:UTILITIES_Throw _Type _Data _Msg
	set _G_ERR=_
	set "_G_ERR.Type=%~1"
	if "%~2" neq "_" set "_G_ERR.Data=!%~2!"
	set "_G_ERR.Msg=[!_G_TRACE!] !_G_ERR.Type!: %~3"
exit /b 0

:UTILITIES_CopyVar _VarFrom _VarTo -> _
	if not defined %~1 (
		!_C_Fatal! "'%~1' undefined."
	)
	set "%~2=!%~1!"
exit /b 0
exit /b 0

:writeall
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
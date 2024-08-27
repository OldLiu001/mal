@REM @echo off
@REM ::Start
@REM 	set "_Args=%*"
@REM 	if "!_Args:~,1!" Equ ":" (
@REM 		Set "_Args=!_Args:~1!"
@REM 	)
@REM 	call :!_Args!
@REM 	set _Args=
@REM exit /b 0



@REM :ReadString _StrMalCode
@REM 	set "_StrMalCode=!%~1!"
	
@REM 	!C_Invoke! NS.bat :New Reader
@REM 	set "_ObjReader=!_G_RET!"

@REM 	set "!_ObjReader!.TokenCount=0"
@REM 	set "!_ObjReader!.TokenPtr=1"

@REM 	call :CopyVar !_StrMalCode!.LineCount _LineCount
@REM 	for /l %%i in (1 1 !_LineCount!) do (
@REM 		!C_Invoke! :Tokenize !_StrMalCode!.Lines[%%i] _ObjReader
@REM 	)

@REM 	rem Check if there is any token.
@REM 	call :CopyVar !_ObjReader!.TokenCount _TotalTokenNum
@REM 	if "!_TotalTokenNum!" == "0" (
@REM 		rem TODO
@REM 		echo ERROR: No token found.
@REM 		pause
@REM 		exit
@REM 	)
	
@REM 	rem Translate the tokens to AST.
@REM 	!C_Invoke! :ReadForm _ObjReader
@REM 	set "_ObjAST=!_G_RET!"
	

@REM 	@REM TODO: check if there has more token.
@REM 	@REM TokenPtr <= _TotalTokenNum

@REM 	set "_G_RET=!_ObjAST!"
@REM 	call :ClearLocalVars
@REM exit /b 0

@REM :ReadForm _ObjReader
@REM 	set "_ObjReader=!%~1!"

@REM 	call :CopyVar !_ObjReader!.TokenPtr _TokenPtr
@REM 	call :CopyVar !_ObjReader!.TokenCount _TotalTokenNum

@REM 	if !_TokenPtr! Gtr !_TotalTokenNum! (
@REM 		rem TODO
@REM 		echo ERROR: No token found.
@REM 		pause
@REM 		exit
@REM 	)

@REM 	call :CopyVar !_ObjReader!.Tokens[!_TokenPtr!] _CurToken
	
@REM 	if "!_CurToken!" == "(" (
@REM 		!C_Invoke! :ReadList _ObjReader
@REM 		set "_ObjAST=!_G_RET!"
@REM 	) else (
@REM 		!C_Invoke! :ReadAtom _ObjReader
@REM 		set "_ObjAST=!_G_RET!"
@REM 	)

@REM 	set "_G_RET=!_ObjAST!"
@REM 	call :ClearLocalVars
@REM exit /b 0

@REM :ReadAtom
@REM 	set "_ObjReader=!%~1!"

@REM 	call :CopyVar !_ObjReader!.TokenPtr _TokenPtr
@REM 	call :CopyVar !_ObjReader!.TokenCount _TotalTokenNum

@REM 	if !_TokenPtr! Gtr !_TotalTokenNum! (
@REM 		rem TODO
@REM 		echo ERROR: No token found.
@REM 		pause
@REM 		exit
@REM 	)

@REM 	call :CopyVar !_ObjReader!.Tokens[!_TokenPtr!] _CurToken
@REM 	set /a _TokenPtr += 1
@REM 	call :CopyVar _TokenPtr !_ObjReader!.TokenPtr
	
@REM 	!C_Invoke! NS.bat :New
@REM 	call :CopyVar _G_RET _ObjMalCode
@REM 	set "!_ObjMalCode!.Value=!_CurToken!"

@REM 	rem check token's MalType.
@REM 	set /a _TestNum = _CurToken
@REM 	if "!_TestNum!" == "!_CurToken!" (
@REM 		set "!_ObjMalCode!.Type=MalNum"
@REM 	) else (
@REM 		set "!_ObjMalCode!.Type=MalSym"
@REM 	)
@REM 	rem TODO: CheckMore.

@REM 	set "_G_RET=!_ObjMalCode!"
@REM 	call :ClearLocalVars
@REM exit /b 0

@REM :ReadList
@REM 	set "_ObjReader=!%~1!"

@REM 	call :CopyVar !_ObjReader!.TokenPtr _TokenPtr
@REM 	call :CopyVar !_ObjReader!.TokenCount _TotalTokenNum

@REM 	if !_TokenPtr! Gtr !_TotalTokenNum! (
@REM 		rem TODO
@REM 		echo ERROR: No token found.
@REM 		pause
@REM 		exit
@REM 	)

@REM 	call :CopyVar !_ObjReader!.Tokens[!_TokenPtr!] _CurToken

@REM 	if "!_CurToken!" Neq "(" (
@REM 		rem TODO
@REM 		echo ERROR: Not a list.
@REM 		pause
@REM 		exit
@REM 	)

@REM 	set /a _TokenPtr += 1
@REM 	call :CopyVar _TokenPtr !_ObjReader!.TokenPtr

@REM 	if !_TokenPtr! Gtr !_TotalTokenNum! (
@REM 		rem TODO
@REM 		echo ERROR: No token found.
@REM 		pause
@REM 		exit
@REM 	)
	
@REM 	!C_Invoke! NS.bat :New MalLst
@REM 	call :CopyVar _G_RET _ObjMalCode
	
@REM 	set "_Count=0"
@REM 	:ReadList_Loop
@REM 		call :CopyVar !_ObjReader!.TokenPtr _TokenPtr
@REM 		call :CopyVar !_ObjReader!.Tokens[!_TokenPtr!] _CurToken

@REM 		if "!_CurToken!" == ")" (
@REM 			set /a _TokenPtr += 1
@REM 			call :CopyVar _TokenPtr !_ObjReader!.TokenPtr
@REM 			goto :ReadList_Pass
@REM 		)
@REM 		set /a _Count += 1

@REM 		!C_Invoke! :ReadForm _ObjReader
@REM 		call :CopyVar _G_RET !_ObjMalCode!.Item[!_Count!]

@REM 		goto :ReadList_Loop
@REM 	:ReadList_Pass
@REM 	call :CopyVar _Count !_ObjMalCode!.Count


@REM 	set "_G_RET=!_ObjMalCode!"
@REM 	call :ClearLocalVars
@REM exit /b 0



@REM :Tokenize _Line _ObjReader
@REM 	set "_Line=!%~1!"
@REM 	set "_ObjReader=!%~2!"

@REM 	call :CopyVar _Line _CurLine
@REM 	call :CopyVar !_ObjReader!.TokenCount _CurTokenNum

@REM 	rem Tokenize the _CurLine.
@REM 	set _ParsingStr=False
@REM 	set _NormalToken=
@REM 	:Tokenizing_Loop
@REM 	if "!_CurLine!" == "" (
@REM 		if "!_ParsingStr!" == "True" (
@REM 			rem TODO
@REM 			echo ERROR: STRING not full.
@REM 			pause
@REM 			exit
@REM 		)
@REM 		goto :Tokenizing_Pass
@REM 	)
@REM 	if "!_ParsingStr!" == "False" (
@REM 		if "!_CurLine:~,1!" == " " (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == "	" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == "," (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,2!" == "~@" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken=~@"
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~2!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == "[" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken=["
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == "]" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken=]"
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == "(" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken=("
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == ")" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken=)"
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == "{" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken={"
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == "}" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken=}"
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == "'" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken='"
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == "`" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken=`"
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == "~" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken=~"
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == "@" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken=@"
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~1!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		rem ^ --- $C
@REM 		if "!_CurLine:~,2!" == "$C" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			set "_CurToken=$C"
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

@REM 			set "_CurLine=!_CurLine:~2!"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		rem " --- $D
@REM 		if "!_CurLine:~,2!" == "$D" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			rem string.
@REM 			set "_CurLine=!_CurLine:~2!"
@REM 			set "_ParsingStr=True"
@REM 			set "_StrToken="
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,1!" == ";" (
@REM 			if defined _NormalToken (
@REM 				rem save normal token first.
@REM 				call :CopyVar _NormalToken _CurToken
@REM 				set /a _CurTokenNum += 1
@REM 				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 				set _NormalToken=
@REM 			)
@REM 			rem comment.
@REM 			call :CopyVar _CurLine _CurToken
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 			set "_CurLine="
@REM 			goto :Tokenizing_Loop
@REM 		)

@REM 		set "_NormalToken=!_NormalToken!!_CurLine:~,1!"
@REM 		set "_CurLine=!_CurLine:~1!"
@REM 		goto :Tokenizing_Loop
@REM 	) else (
@REM 		rem parsing string now.
@REM 		if "!_CurLine:~,2!" == "\\" (
@REM 			rem \\
@REM 			set "_CurLine=!_CurLine:~2!"
@REM 			set "_StrToken=!_StrToken!\"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,3!" == "\$D" (
@REM 			rem \"
@REM 			set "_CurLine=!_CurLine:~3!"
@REM 			set "_StrToken=!_StrToken!$D"
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		if "!_CurLine:~,2!" == "$D" (
@REM 			rem end of string.
@REM 			set "_CurLine=!_CurLine:~2!"
@REM 			set "_ParsingStr=False"
@REM 			set /a _CurTokenNum += 1
@REM 			call :CopyVar _StrToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 			goto :Tokenizing_Loop
@REM 		)
@REM 		set "_StrToken=!_StrToken!!_CurLine:~,1!"
@REM 		set "_CurLine=!_CurLine:~1!"
@REM 		goto :Tokenizing_Loop
@REM 	)
@REM 	:Tokenizing_Pass
@REM 	if defined _NormalToken (
@REM 		rem save normal token.
@REM 		call :CopyVar _NormalToken _CurToken
@REM 		set /a _CurTokenNum += 1
@REM 		call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
@REM 		set _NormalToken=
@REM 	)
@REM 	call :CopyVar _CurTokenNum !_ObjReader!.TokenCount

@REM 	set "_G_RET="
@REM 	call :ClearLocalVars
@REM exit /b 0


@REM (
@REM 	:Invoke
@REM 		if not defined G_TRACE (
@REM 			set "G_TRACE=MAIN"
@REM 		)
@REM 		call SF.Bat :PushVar G_TRACE
@REM 		set "G_TMP=%~1"
@REM 		if /i "!G_TMP:~,1!" Equ ":" (
@REM 			set "G_TRACE=!G_TRACE!>%~1"
@REM 		) else (
@REM 			set "G_TRACE=!G_TRACE!>%~1>%~2"
@REM 		)
@REM 		set "G_TMP="
@REM 		call SF.Bat :SaveLocalVars
@REM 		call %*
@REM 		call SF.Bat :RestoreLocalVars
@REM 		call SF.Bat :PopVar G_TRACE
@REM 	exit /b 0

@REM 	:ClearLocalVars
@REM 		for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
@REM 	exit /b 0

@REM 	:CopyVar _VarFrom _VarTo
@REM 		if not defined %~1 (
@REM 			2>&1 echo [!G_TRACE!] %~1 is not defined.
@REM 		)
@REM 		set "%~2=!%~1!"
@REM 	exit /b 0
@REM )

@echo off
2>nul call %* || (
	2>&1 echo [!_G_TRACE!] Call '%~nx0' failed.
	pause & exit 1
)
exit /b 0



:ReadString _StrMalCode
	set "_StrMalCode=!%~1!"
	
	!C_Invoke! NS.bat :New Reader
	set "_ObjReader=!_G_RET!"

	set "!_ObjReader!.TokenCount=0"
	set "!_ObjReader!.TokenPtr=1"

	call :CopyVar !_StrMalCode!.LineCount _LineCount
	for /l %%i in (1 1 !_LineCount!) do (
		!C_Invoke! :Tokenize !_StrMalCode!.Lines[%%i] _ObjReader
	)

	rem Check if there is any token.
	call :CopyVar !_ObjReader!.TokenCount _TotalTokenNum
	if "!_TotalTokenNum!" == "0" (
		rem TODO
		echo ERROR: No token found.
		pause
		exit
	)
	
	rem Translate the tokens to AST.
	!C_Invoke! :ReadForm _ObjReader
	set "_ObjAST=!_G_RET!"
	

	@REM TODO: check if there has more token.
	@REM TokenPtr <= _TotalTokenNum

	set "_G_RET=!_ObjAST!"
	call :ClearLocalVars
exit /b 0

:ReadForm _ObjReader
	set "_ObjReader=!%~1!"

	call :CopyVar !_ObjReader!.TokenPtr _TokenPtr
	call :CopyVar !_ObjReader!.TokenCount _TotalTokenNum

	if !_TokenPtr! Gtr !_TotalTokenNum! (
		rem TODO
		echo ERROR: No token found.
		pause
		exit
	)

	call :CopyVar !_ObjReader!.Tokens[!_TokenPtr!] _CurToken
	
	if "!_CurToken!" == "(" (
		!C_Invoke! :ReadList _ObjReader
		set "_ObjAST=!_G_RET!"
	) else (
		!C_Invoke! :ReadAtom _ObjReader
		set "_ObjAST=!_G_RET!"
	)

	set "_G_RET=!_ObjAST!"
	call :ClearLocalVars
exit /b 0

:ReadAtom
	set "_ObjReader=!%~1!"

	call :CopyVar !_ObjReader!.TokenPtr _TokenPtr
	call :CopyVar !_ObjReader!.TokenCount _TotalTokenNum

	if !_TokenPtr! Gtr !_TotalTokenNum! (
		rem TODO
		echo ERROR: No token found.
		pause
		exit
	)

	call :CopyVar !_ObjReader!.Tokens[!_TokenPtr!] _CurToken
	set /a _TokenPtr += 1
	call :CopyVar _TokenPtr !_ObjReader!.TokenPtr
	
	!C_Invoke! NS.bat :New
	call :CopyVar _G_RET _ObjMalCode
	set "!_ObjMalCode!.Value=!_CurToken!"

	rem check token's MalType.
	set /a _TestNum = _CurToken
	if "!_TestNum!" == "!_CurToken!" (
		set "!_ObjMalCode!.Type=MalNum"
	) else (
		set "!_ObjMalCode!.Type=MalSym"
	)
	rem TODO: CheckMore.

	set "_G_RET=!_ObjMalCode!"
	call :ClearLocalVars
exit /b 0

:ReadList
	set "_ObjReader=!%~1!"

	call :CopyVar !_ObjReader!.TokenPtr _TokenPtr
	call :CopyVar !_ObjReader!.TokenCount _TotalTokenNum

	if !_TokenPtr! Gtr !_TotalTokenNum! (
		rem TODO
		echo ERROR: No token found.
		pause
		exit
	)

	call :CopyVar !_ObjReader!.Tokens[!_TokenPtr!] _CurToken

	if "!_CurToken!" Neq "(" (
		rem TODO
		echo ERROR: Not a list.
		pause
		exit
	)

	set /a _TokenPtr += 1
	call :CopyVar _TokenPtr !_ObjReader!.TokenPtr

	if !_TokenPtr! Gtr !_TotalTokenNum! (
		rem TODO
		echo ERROR: No token found.
		pause
		exit
	)
	
	!C_Invoke! NS.bat :New MalLst
	call :CopyVar _G_RET _ObjMalCode
	
	set "_Count=0"
	:ReadList_Loop
		call :CopyVar !_ObjReader!.TokenPtr _TokenPtr
		call :CopyVar !_ObjReader!.Tokens[!_TokenPtr!] _CurToken

		if "!_CurToken!" == ")" (
			set /a _TokenPtr += 1
			call :CopyVar _TokenPtr !_ObjReader!.TokenPtr
			goto :ReadList_Pass
		)
		set /a _Count += 1

		!C_Invoke! :ReadForm _ObjReader
		call :CopyVar _G_RET !_ObjMalCode!.Item[!_Count!]

		goto :ReadList_Loop
	:ReadList_Pass
	call :CopyVar _Count !_ObjMalCode!.Count


	set "_G_RET=!_ObjMalCode!"
	call :ClearLocalVars
exit /b 0



:Tokenize _Line _ObjReader
	set "_Line=!%~1!"
	set "_ObjReader=!%~2!"

	call :CopyVar _Line _CurLine
	call :CopyVar !_ObjReader!.TokenCount _CurTokenNum

	rem Tokenize the _CurLine.
	set _ParsingStr=False
	set _NormalToken=
	:Tokenizing_Loop
	if "!_CurLine!" == "" (
		if "!_ParsingStr!" == "True" (
			rem TODO
			echo ERROR: STRING not full.
			pause
			exit
		)
		goto :Tokenizing_Pass
	)
	if "!_ParsingStr!" == "False" (
		if "!_CurLine:~,1!" == " " (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurLine=!_CurLine:~1!"
			goto Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == "	" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurLine=!_CurLine:~1!"
			goto Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == "," (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurLine=!_CurLine:~1!"
			goto Tokenizing_Loop
		)
		if "!_CurLine:~,2!" == "~@" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken=~@"
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~2!"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == "[" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken=["
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == "]" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken=]"
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == "(" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken=("
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == ")" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken=)"
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == "{" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken={"
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == "}" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken=}"
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == "'" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken='"
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == "`" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken=`"
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == "~" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken=~"
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == "@" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken=@"
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		)
		rem ^ --- $C
		if "!_CurLine:~,2!" == "$C" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			set "_CurToken=$C"
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

			set "_CurLine=!_CurLine:~2!"
			goto :Tokenizing_Loop
		)
		rem " --- $D
		if "!_CurLine:~,2!" == "$D" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			rem string.
			set "_CurLine=!_CurLine:~2!"
			set "_ParsingStr=True"
			set "_StrToken="
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,1!" == ";" (
			if defined _NormalToken (
				rem save normal token first.
				call :CopyVar _NormalToken _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set _NormalToken=
			)
			rem comment.
			call :CopyVar _CurLine _CurToken
			set /a _CurTokenNum += 1
			call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
			set "_CurLine="
			goto :Tokenizing_Loop
		)

		set "_NormalToken=!_NormalToken!!_CurLine:~,1!"
		set "_CurLine=!_CurLine:~1!"
		goto :Tokenizing_Loop
	) else (
		rem parsing string now.
		if "!_CurLine:~,2!" == "\\" (
			rem \\
			set "_CurLine=!_CurLine:~2!"
			set "_StrToken=!_StrToken!\"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,3!" == "\$D" (
			rem \"
			set "_CurLine=!_CurLine:~3!"
			set "_StrToken=!_StrToken!$D"
			goto :Tokenizing_Loop
		)
		if "!_CurLine:~,2!" == "$D" (
			rem end of string.
			set "_CurLine=!_CurLine:~2!"
			set "_ParsingStr=False"
			set /a _CurTokenNum += 1
			call :CopyVar _StrToken !_ObjReader!.Tokens[!_CurTokenNum!]
			goto :Tokenizing_Loop
		)
		set "_StrToken=!_StrToken!!_CurLine:~,1!"
		set "_CurLine=!_CurLine:~1!"
		goto :Tokenizing_Loop
	)
	:Tokenizing_Pass
	if defined _NormalToken (
		rem save normal token.
		call :CopyVar _NormalToken _CurToken
		set /a _CurTokenNum += 1
		call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
		set _NormalToken=
	)
	call :CopyVar _CurTokenNum !_ObjReader!.TokenCount

	set "_G_RET="
	call :ClearLocalVars
exit /b 0


(
	:Invoke
		if not defined G_TRACE (
			set "G_TRACE=MAIN"
		)
		call SF.Bat :PushVar G_TRACE
		set "G_TMP=%~1"
		if /i "!G_TMP:~,1!" Equ ":" (
			set "G_TRACE=!G_TRACE!>%~1"
		) else (
			set "G_TRACE=!G_TRACE!>%~1>%~2"
		)
		set "G_TMP="
		call SF.Bat :SaveLocalVars
		call %*
		call SF.Bat :RestoreLocalVars
		call SF.Bat :PopVar G_TRACE
	exit /b 0

	:ClearLocalVars
		for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
	exit /b 0

	:CopyVar _VarFrom _VarTo
		if not defined %~1 (
			2>&1 echo [!G_TRACE!] %~1 is not defined.
		)
		set "%~2=!%~1!"
	exit /b 0
)

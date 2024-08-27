@echo off
::Start
	set "_Args=%*"
	if "!_Args:~,1!" Equ ":" (
		Set "_Args=!_Args:~1!"
	)
	call :!_Args!
	set _Args=
goto :eof



:ReadString _StrMalCode
	set "_StrMalCode=!%~1!"
	
	!C_Invoke! NS.bat :New Reader
	set "_ObjReader=!G_RET!"

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
	set "_ObjAST=!G_RET!"
	

	@REM TODO: check if there has more token.
	@REM TokenPtr <= _TotalTokenNum

	set "G_RET=!_ObjAST!"
	call :ClearLocalVars
goto :eof

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
		set "_ObjAST=!G_RET!"
	) else (
		!C_Invoke! :ReadAtom _ObjReader
		set "_ObjAST=!G_RET!"
	)

	set "G_RET=!_ObjAST!"
	call :ClearLocalVars
goto :eof

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
	call :CopyVar G_RET _ObjMalCode
	set "!_ObjMalCode!.Value=!_CurToken!"

	rem check token's MalType.
	set /a _TestNum = _CurToken
	if "!_TestNum!" == "!_CurToken!" (
		set "!_ObjMalCode!.Type=MalNum"
	) else (
		set "!_ObjMalCode!.Type=MalSym"
	)
	rem TODO: CheckMore.

	set "G_RET=!_ObjMalCode!"
	call :ClearLocalVars
goto :eof

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
	call :CopyVar G_RET _ObjMalCode
	
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
		call :CopyVar G_RET !_ObjMalCode!.Item[!_Count!]

		goto :ReadList_Loop
	:ReadList_Pass
	call :CopyVar _Count !_ObjMalCode!.Count


	set "G_RET=!_ObjMalCode!"
	call :ClearLocalVars
goto :eof



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

	set "G_RET="
	call :ClearLocalVars
goto :eof


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
	goto :eof

	:ClearLocalVars
		for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
	goto :eof

	:CopyVar _VarFrom _VarTo
		if not defined %~1 (
			2>&1 echo [!G_TRACE!] %~1 is not defined.
		)
		set "%~2=!%~1!"
	goto :eof
)

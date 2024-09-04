@REM v:0.6

@echo off
2>nul call %* || (
	2>&1 echo [!_G_TRACE!] Call '%~nx0' failed.
	pause & exit 1
)
exit /b 0



:ReadString _StrMalCode -> _ObjAST
	for %%. in (!_G_LEVEL!) do (
		set "_L{%%.}_StrMalCode=!%~1!"
		
		!_C_Invoke! NS.bat :New Reader
		set "_L{%%.}_ObjReader=!_G_RET!"

		set "!_L{%%.}_ObjReader!.TokenCount=0"
		set "!_L{%%.}_ObjReader!.TokenPtr=1"

		!_C_Copy! !_L{%%.}_StrMalCode!.LineCount _L{%%.}_LineCount
		for /l %%i in (1 1 !_L{%%.}_LineCount!) do (
			!_C_Invoke! :Tokenize !_L{%%.}_StrMalCode!.Line[%%i] _L{%%.}_ObjReader
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free _L{%%.}_ObjReader
				exit /b 0
			)
		)

		rem Check if there is any token.
		!_C_Copy! !_L{%%.}_ObjReader!.TokenCount _L{%%.}_TotalTokenNum
		if "!_L{%%.}_TotalTokenNum!" == "0" (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)
		
		rem Translate the tokens to AST.
		!_C_Invoke! :ReadForm _L{%%.}_ObjReader
		if defined _G_ERR (
			!_C_Invoke! NS.bat :Free _L{%%.}_ObjReader
			exit /b 0
		)
		set "_L{%%.}_ObjAST=!_G_RET!"
		

		!_C_Invoke! NS.bat :Free _L{%%.}_ObjReader

		set "_G_RET=!_L{%%.}_ObjAST!"
	)
exit /b 0

:ReadForm  _ObjReader -> _ObjMal
	for %%. in (!_G_LEVEL!) do (
		set "_L{%%.}_ObjReader=!%~1!"

		!_C_Copy! !_L{%%.}_ObjReader!.TokenPtr _L{%%.}_TokenPtr
		!_C_Copy! !_L{%%.}_ObjReader!.TokenCount _L{%%.}_TotalTokenNum

		if !_L{%%.}_TokenPtr! Gtr !_L{%%.}_TotalTokenNum! (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)

		!_C_Copy! !_L{%%.}_ObjReader!.Token[!_L{%%.}_TokenPtr!] _L{%%.}_CurToken
		
		if "!_L{%%.}_CurToken!" == "(" (
			!_C_Invoke! :ReadList _L{%%.}_ObjReader
			if defined _G_ERR exit /b 0
			set "_L{%%.}_ObjAST=!_G_RET!"
		) else if "!_L{%%.}_CurToken!" == "[" (
			!_C_Invoke! :ReadList _L{%%.}_ObjReader
			if defined _G_ERR exit /b 0
			set "_L{%%.}_ObjAST=!_G_RET!"
		) else (
			!_C_Invoke! :ReadAtom _L{%%.}_ObjReader
			set "_L{%%.}_ObjAST=!_G_RET!"
		)

		set "_G_RET=!_L{%%.}_ObjAST!"
	)
exit /b 0

:ReadAtom _ObjReader -> _ObjMal
	for %%. in (!_G_LEVEL!) do (
		set "_L{%%.}_ObjReader=!%~1!"

		!_C_Copy! !_L{%%.}_ObjReader!.TokenPtr _L{%%.}_TokenPtr
		!_C_Copy! !_L{%%.}_ObjReader!.TokenCount _L{%%.}_TotalTokenNum

		if !_L{%%.}_TokenPtr! Gtr !_L{%%.}_TotalTokenNum! (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)

		!_C_Copy! !_L{%%.}_ObjReader!.Token[!_L{%%.}_TokenPtr!] _L{%%.}_CurToken
		set /a _L{%%.}_TokenPtr += 1
		!_C_Copy! _L{%%.}_TokenPtr !_L{%%.}_ObjReader!.TokenPtr
		
		!_C_Invoke! NS.bat :New
		!_C_Copy! _G_RET _L{%%.}_ObjMalCode
		!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjMalCode!.Value
		
		rem check token's MalType.
		set /a _L{%%.}_TestNum = _L{%%.}_CurToken
		if "!_L{%%.}_TestNum!" == "!_L{%%.}_CurToken!" (
			set "!_L{%%.}_ObjMalCode!.Type=MalNum"
		) else if "!_L{%%.}_CurToken!" == "nil" (
			set "!_L{%%.}_ObjMalCode!.Type=MalNil"
		) else if "!_L{%%.}_CurToken!" == "true" (
			set "!_L{%%.}_ObjMalCode!.Type=MalBool"
		) else if "!_L{%%.}_CurToken!" == "false" (
			set "!_L{%%.}_ObjMalCode!.Type=MalBool"
		) else if "!_L{%%.}_CurToken:~,2!" == "!_G_ESCKEY!D" (
			set "!_L{%%.}_ObjMalCode!.Type=MalStr"
		) else (
			set "!_L{%%.}_ObjMalCode!.Type=MalSym"
		)
		rem TODO: CheckMore.

		set "_G_RET=!_L{%%.}_ObjMalCode!"
	)
exit /b 0

:ReadList _ObjReader -> _ObjMal
	for %%. in (!_G_LEVEL!) do (
		set "_L{%%.}_ObjReader=!%~1!"

		!_C_Copy! !_L{%%.}_ObjReader!.TokenPtr _L{%%.}_TokenPtr
		!_C_Copy! !_L{%%.}_ObjReader!.TokenCount _L{%%.}_TotalTokenNum

		if !_L{%%.}_TokenPtr! Gtr !_L{%%.}_TotalTokenNum! (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)

		!_C_Copy! !_L{%%.}_ObjReader!.Token[!_L{%%.}_TokenPtr!] _L{%%.}_CurToken

		if "!_L{%%.}_CurToken!" Equ "(" (
			rem
		) else if "!_L{%%.}_CurToken!" Equ "[" (
			!_C_Invoke! NS.bat :New MalVec
			!_C_Copy! _G_RET _L{%%.}_ObjMalCode
		) else (
			>&2 echo [!_G_TRACE!] unexpected token '!_L{%%.}_CurToken!'.
			pause & exit 1
		)

		set /a _L{%%.}_TokenPtr += 1
		!_C_Copy! _L{%%.}_TokenPtr !_L{%%.}_ObjReader!.TokenPtr

		if !_L{%%.}_TokenPtr! Gtr !_L{%%.}_TotalTokenNum! (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)
		
		!_C_Invoke! NS.bat :New MalLst
		!_C_Copy! _G_RET _L{%%.}_ObjMalCode

		set "_L{%%.}_Count=0"
	)
	:ReadList_Loop
	for %%. in (!_G_LEVEL!) do (
		!_C_Copy! !_L{%%.}_ObjReader!.TokenPtr _L{%%.}_TokenPtr
		
		if !_L{%%.}_TokenPtr! Gtr !_L{%%.}_TotalTokenNum! (
			set _G_ERR=_
			set _G_ERR.Type=Exception
			set "_G_ERR.Msg=[!_G_TRACE!] Exception: unbalanced parenthesis."
			!_C_Invoke! NS.bat :Free _L{%%.}_ObjMalCode
			exit /b 0
		)

		!_C_Copy! !_L{%%.}_ObjReader!.Token[!_L{%%.}_TokenPtr!] _L{%%.}_CurToken

		if "!_L{%%.}_CurToken!" == ")" (
			set /a _L{%%.}_TokenPtr += 1
			!_C_Copy! _L{%%.}_TokenPtr !_L{%%.}_ObjReader!.TokenPtr
			goto :ReadList_Pass
		)
		set /a _L{%%.}_Count += 1

		!_C_Invoke! :ReadForm _L{%%.}_ObjReader
		!_C_Copy! _G_RET !_L{%%.}_ObjMalCode!.Item[!_L{%%.}_Count!]

		goto :ReadList_Loop
	)
	:ReadList_Pass
	for %%. in (!_G_LEVEL!) do (
		!_C_Copy! _L{%%.}_Count !_L{%%.}_ObjMalCode!.Count


		set "_G_RET=!_L{%%.}_ObjMalCode!"
	)
exit /b 0



:Tokenize _Line _ObjReader -> _
	for %%. in (!_G_LEVEL!) do (
		set "_L{%%.}_Line=!%~1!"
		set "_L{%%.}_ObjReader=!%~2!"

		!_C_Copy! _L{%%.}_Line _L{%%.}_CurLine
		!_C_Copy! !_L{%%.}_ObjReader!.TokenCount _L{%%.}_CurTokenNum

		rem Tokenize the _CurLine.
		set _L{%%.}_ParsingStr=False
		set _L{%%.}_NormalToken=
	)
	:Tokenizing_Loop
	for %%. in (!_G_LEVEL!) do (
		if "!_L{%%.}_CurLine!" == "" (
			if "!_L{%%.}_ParsingStr!" == "True" (
				set _G_ERR=_
				set _G_ERR.Type=Exception
				set "_G_ERR.Msg=[!_G_TRACE!] Exception: unexpected EOF, string is incomplete."
				exit /b 0
			)
			goto :Tokenizing_Pass
		)
		if "!_L{%%.}_ParsingStr!" == "False" (
			if "!_L{%%.}_CurLine:~,1!" == " " (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == "	" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == "," (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,2!" == "~@" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken=~@"
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~2!"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == "[" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken=["
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == "]" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken=]"
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == "(" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken=("
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == ")" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken=)"
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == "{" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken={"
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == "}" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken=}"
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == "'" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken='"
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == "`" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken=`"
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == "~" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken=~"
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == "@" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken=@"
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			rem ^ --- \eC
			if "!_L{%%.}_CurLine:~,2!" == "!_G_ESCKEY!C" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken=!_G_ESCKEY!C"
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~2!"
				goto :Tokenizing_Loop
			)
			rem " --- \eD
			if "!_L{%%.}_CurLine:~,2!" == "!_G_ESCKEY!D" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				rem string.
				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~2!"
				set "_L{%%.}_ParsingStr=True"
				set "_L{%%.}_StrToken="
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,1!" == ";" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				rem comment.
				!_C_Copy! _L{%%.}_CurLine _L{%%.}_CurToken
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
				set "_L{%%.}_CurLine="
				goto :Tokenizing_Loop
			)

			set "_L{%%.}_NormalToken=!_L{%%.}_NormalToken!!_L{%%.}_CurLine:~,1!"
			set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
			goto :Tokenizing_Loop
		) else (
			rem parsing string now.
			if "!_L{%%.}_CurLine:~,2!" == "\\" (
				rem \\
				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~2!"
				set "_L{%%.}_StrToken=!_L{%%.}_StrToken!\\"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,3!" == "\!_G_ESCKEY!D" (
				rem \"
				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~3!"
				set "_L{%%.}_StrToken=!_L{%%.}_StrToken!\!_G_ESCKEY!D"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,2!" == "!_G_ESCKEY!D" (
				rem end of string.
				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~2!"
				set "_L{%%.}_ParsingStr=False"
				set /a _L{%%.}_CurTokenNum += 1
				set "_L{%%.}_StrToken=!_G_ESCKEY!D!_L{%%.}_StrToken!!_G_ESCKEY!D"
				!_C_Copy! _L{%%.}_StrToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
				goto :Tokenizing_Loop
			)
			set "_L{%%.}_StrToken=!_L{%%.}_StrToken!!_L{%%.}_CurLine:~,1!"
			set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~1!"
			goto :Tokenizing_Loop
		)
	)
	:Tokenizing_Pass
	for %%. in (!_G_LEVEL!) do (
		if defined _L{%%.}_NormalToken (
			rem save normal token first.
			!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
			set /a _L{%%.}_CurTokenNum += 1
			!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
			set _L{%%.}_NormalToken=
		)
		!_C_Copy! _L{%%.}_CurTokenNum !_L{%%.}_ObjReader!.TokenCount

		set "_G_RET="
	)
exit /b 0

(
	@REM Version 0.9
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

	:CopyVar _VarFrom _VarTo -> _
		if not defined %~1 (
			2>&1 echo [!_G_TRACE!] '%~1' undefined.
			pause & exit 1
		)
		set "%~2=!%~1!"
	exit /b 0
)
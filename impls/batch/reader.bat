@REM v:1.4

@echo off
call %* || !_C_Fatal! "Call '%~nx0' failed."
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
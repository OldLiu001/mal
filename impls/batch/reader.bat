@REM v:0.6

@echo off
call %* || !_C_Fatal! "Call '%~nx0' failed."
exit /b 0



:ReadString _StrMalCode -> _ObjAST
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._StrMalCode=!%~1!"
		
		!_C_Invoke! NS.bat :New Reader & !_C_GetRet! %%._ObjReader
		

		set "!%%._ObjReader!.TokenCount=0"
		set "!%%._ObjReader!.TokenPtr=1"

		!_C_Copy! !%%._StrMalCode!.LineCount %%._LineCount
		for /l %%i in (1 1 !%%._LineCount!) do (
			!_C_Invoke! :Tokenize !%%._StrMalCode!.Line[%%i] %%._ObjReader
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free %%._ObjReader
				exit /b 0
			)
		)

		rem Check if there is any token.
		!_C_Copy! !%%._ObjReader!.TokenCount %%._TotalTokenNum
		if "!%%._TotalTokenNum!" == "0" (
			!_C_Fatal! TODO
		)
		
		rem Translate the tokens to AST.
		!_C_Invoke! :ReadForm %%._ObjReader & !_C_GetRet! %%._ObjAST
		if defined _G_ERR (
			!_C_Invoke! NS.bat :Free %%._ObjReader
			exit /b 0
		)
		

		!_C_Invoke! NS.bat :Free %%._ObjReader

		!_C_Return! %%._ObjAST
	)
exit /b 0

:ReadForm  _ObjReader -> _ObjMal
	for %%. in (!_G_LEVEL!) do (
		set "_L{%%.}_ObjReader=!%~1!"

		!_C_Copy! !_L{%%.}_ObjReader!.TokenPtr _L{%%.}_TokenPtr
		!_C_Copy! !_L{%%.}_ObjReader!.TokenCount _L{%%.}_TotalTokenNum

		if !_L{%%.}_TokenPtr! Gtr !_L{%%.}_TotalTokenNum! (
			set _G_ERR=_
			set _G_ERR.Type=Exception
			set "_G_ERR.Msg=[!_G_TRACE!] Exception: unexpected EOF, need more token."
			exit /b 0
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
		) else if "!_L{%%.}_CurToken!" == "{" (
			!_C_Invoke! :ReadMap _L{%%.}_ObjReader
			if defined _G_ERR exit /b 0
			set "_L{%%.}_ObjAST=!_G_RET!"
		) else if "!_L{%%.}_CurToken!" == "'" (
			!_C_Invoke! TYPES.bat :NewMalAtom MalSym quote
			!_C_Copy! _G_RET _L{%%.}_ObjMalSymQuote
			set /a !_L{%%.}_ObjReader!.TokenPtr += 1

			!_C_Invoke! :ReadForm _L{%%.}_ObjReader
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free _L{%%.}_ObjMalSymQuote
				exit /b 0
			)
			!_C_Copy! _G_RET _L{%%.}_ObjMal
			!_C_Invoke! TYPES.bat :NewMalList _L{%%.}_ObjMalSymQuote _L{%%.}_ObjMal
			!_C_Copy! _G_RET _L{%%.}_ObjAST
		) else if "!_L{%%.}_CurToken!" == "`" (
			!_C_Invoke! TYPES.bat :NewMalAtom MalSym quasiquote
			!_C_Copy! _G_RET _L{%%.}_ObjMalSymQuote
			set /a !_L{%%.}_ObjReader!.TokenPtr += 1

			!_C_Invoke! :ReadForm _L{%%.}_ObjReader
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free _L{%%.}_ObjMalSymQuote
				exit /b 0
			)
			!_C_Copy! _G_RET _L{%%.}_ObjMal
			!_C_Invoke! TYPES.bat :NewMalList _L{%%.}_ObjMalSymQuote _L{%%.}_ObjMal
			!_C_Copy! _G_RET _L{%%.}_ObjAST
		) else if "!_L{%%.}_CurToken!" == "@" (
			!_C_Invoke! TYPES.bat :NewMalAtom MalSym deref
			!_C_Copy! _G_RET _L{%%.}_ObjMalSymQuote
			set /a !_L{%%.}_ObjReader!.TokenPtr += 1

			!_C_Invoke! :ReadForm _L{%%.}_ObjReader
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free _L{%%.}_ObjMalSymQuote
				exit /b 0
			)
			!_C_Copy! _G_RET _L{%%.}_ObjMal
			!_C_Invoke! TYPES.bat :NewMalList _L{%%.}_ObjMalSymQuote _L{%%.}_ObjMal
			!_C_Copy! _G_RET _L{%%.}_ObjAST
		) else if "!_L{%%.}_CurToken!" == "~" (
			!_C_Invoke! TYPES.bat :NewMalAtom MalSym unquote
			!_C_Copy! _G_RET _L{%%.}_ObjMalSymQuote
			set /a !_L{%%.}_ObjReader!.TokenPtr += 1

			!_C_Invoke! :ReadForm _L{%%.}_ObjReader
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free _L{%%.}_ObjMalSymQuote
				exit /b 0
			)
			!_C_Copy! _G_RET _L{%%.}_ObjMal
			!_C_Invoke! TYPES.bat :NewMalList _L{%%.}_ObjMalSymQuote _L{%%.}_ObjMal
			!_C_Copy! _G_RET _L{%%.}_ObjAST
		) else if "!_L{%%.}_CurToken!" == "~@" (
			!_C_Invoke! TYPES.bat :NewMalAtom MalSym splice-unquote
			!_C_Copy! _G_RET _L{%%.}_ObjMalSymQuote
			set /a !_L{%%.}_ObjReader!.TokenPtr += 1

			!_C_Invoke! :ReadForm _L{%%.}_ObjReader
			if defined _G_ERR (
				!_C_Invoke! NS.bat :Free _L{%%.}_ObjMalSymQuote
				exit /b 0
			)
			!_C_Copy! _G_RET _L{%%.}_ObjMal
			!_C_Invoke! TYPES.bat :NewMalList _L{%%.}_ObjMalSymQuote _L{%%.}_ObjMal
			!_C_Copy! _G_RET _L{%%.}_ObjAST
		) else if "!_L{%%.}_CurToken!" == ")" (
			echo TODO:Exception
			pause & exit 1
		) else if "!_L{%%.}_CurToken!" == "]" (
			echo TODO:Exception
			pause & exit 1
		) else if "!_L{%%.}_CurToken!" == "}" (
			echo TODO:Exception
			pause & exit 1
		) else if "!_L{%%.}_CurToken:~,1!" == ";" (
			echo TODO:Return
			pause & exit 1
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
		) else if "!_L{%%.}_CurToken:~,2!" == "$D" (
			set "!_L{%%.}_ObjMalCode!.Type=MalStr"
		) else if "!_L{%%.}_CurToken:~,2!" == "$A" (
			set "!_L{%%.}_ObjMalCode!.Type=MalKwd"
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
			!_C_Invoke! NS.bat :New MalLst
			!_C_Copy! _G_RET _L{%%.}_ObjMalCode
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
			!_C_Copy! !_L{%%.}_ObjMalCode!.Type _L{%%.}_Type
			if "!_L{%%.}_Type!" Neq "MalLst" (
				!_C_Invoke! NS.bat :Free _L{%%.}_ObjMalCode
				set _G_ERR=_
				set _G_ERR.Type=Exception
				set "_G_ERR.Msg=[!_G_TRACE!] Exception: unbalanced parenthesis."
				exit /b 0
			)
			set /a _L{%%.}_TokenPtr += 1
			!_C_Copy! _L{%%.}_TokenPtr !_L{%%.}_ObjReader!.TokenPtr
			goto :ReadList_Pass
		)
		if "!_L{%%.}_CurToken!" == "]" (
			!_C_Copy! !_L{%%.}_ObjMalCode!.Type _L{%%.}_Type
			if "!_L{%%.}_Type!" Neq "MalVec" (
				!_C_Invoke! NS.bat :Free _L{%%.}_ObjMalCode
				set _G_ERR=_
				set _G_ERR.Type=Exception
				set "_G_ERR.Msg=[!_G_TRACE!] Exception: unbalanced parenthesis."
				exit /b 0
			)
			!_C_Copy! !_L{%%.}_ObjMalCode!.Type _L{%%.}_Type
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
		!_C_Copy! %%.MalMap _G_RET
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
			if "!_L{%%.}_CurLine:~,2!" == "$C" (
				if defined _L{%%.}_NormalToken (
					rem save normal token first.
					!_C_Copy! _L{%%.}_NormalToken _L{%%.}_CurToken
					set /a _L{%%.}_CurTokenNum += 1
					!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]
					set _L{%%.}_NormalToken=
				)
				set "_L{%%.}_CurToken=$C"
				set /a _L{%%.}_CurTokenNum += 1
				!_C_Copy! _L{%%.}_CurToken !_L{%%.}_ObjReader!.Token[!_L{%%.}_CurTokenNum!]

				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~2!"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,2!" == "$D" (
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
			if "!_L{%%.}_CurLine:~,3!" == "\$D" (
				rem \"
				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~3!"
				set "_L{%%.}_StrToken=!_L{%%.}_StrToken!\$D"
				goto :Tokenizing_Loop
			)
			if "!_L{%%.}_CurLine:~,2!" == "$D" (
				rem end of string.
				set "_L{%%.}_CurLine=!_L{%%.}_CurLine:~2!"
				set "_L{%%.}_ParsingStr=False"
				set /a _L{%%.}_CurTokenNum += 1
				set "_L{%%.}_StrToken=$D!_L{%%.}_StrToken!$D"
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
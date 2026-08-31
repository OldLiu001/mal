@echo off
if "%~1" neq "" (
	call %* || %?|% "Call '%~nx0' failed."
)
%-|%

:READER_ReadString &StrMal -> ObjAST
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.StrMalCode=!%~1!"
		
		%|% NS New Reader %->% %%.ObjReader
		

		set "!%%.ObjReader!.TokenCount=0"
		set "!%%.ObjReader!.TokenPtr=1"

		%&% !%%.StrMalCode!.LineCount %%.LineCount
		for /l %%i in (1 1 !%%.LineCount!) do (
			%|% READER Tokenize !%%.StrMalCode!.Line[%%i] %%.ObjReader
			%?% (
				%|% NS Free %%.ObjReader
				%-|%
			)
		)

		rem Check if there is any token.
		%&% !%%.ObjReader!.TokenCount %%.TotalTokenNum
		if "!%%.TotalTokenNum!" == "0" (
			%|% NS Free %%.ObjReader
			%??% "" Empty
			%-|%
		)
		
		rem Translate the tokens to AST.
		%|% READER ReadForm %%.ObjReader %->% %%.ObjAST
		%?% (
			%|% NS Free %%.ObjReader
			%-|%
		)
		

		%|% NS Free %%.ObjReader

		%<-% %%.ObjAST
	)
%-|%

:READER_ReadForm &ObjReader -> ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjReader=!%~1!"

		%&% !%%.ObjReader!.TokenPtr %%.TokenPtr
		%&% !%%.ObjReader!.TokenCount %%.TotalTokenNum

		if !%%.TokenPtr! Gtr !%%.TotalTokenNum! (
			%??% "unexpected EOF, need more token."
			%-|%
		)

		%&% !%%.ObjReader!.Token[!%%.TokenPtr!] %%.CurToken
		
		if "!%%.CurToken!" == "(" (
			%|% READER ReadList %%.ObjReader %->% %%.ObjAST
			%?% %-|%
		) else if "!%%.CurToken!" == "[" (
			%|% READER ReadList %%.ObjReader %->% %%.ObjAST
			%?% %-|%
		) else if "!%%.CurToken!" == "{" (
			%|% READER ReadMap %%.ObjReader %->% %%.ObjAST
			%?% %-|%
		) else if "!%%.CurToken!" == "'" (
			%|% TYPES NewMal MalSym quote %->% %%.ObjMalSymQuote
			set /a !%%.ObjReader!.TokenPtr += 1

			%|% READER ReadForm %%.ObjReader %->% %%.ObjMal
			%?% (
				%|% NS Free %%.ObjMalSymQuote
				%-|%
			)
			%|% TYPES NewMalList %%.ObjMalSymQuote %%.ObjMal %->% %%.ObjAST
		) else if "!%%.CurToken!" == "`" (
			%|% TYPES NewMal MalSym quasiquote %->% %%.ObjMalSymQuote
			set /a !%%.ObjReader!.TokenPtr += 1

			%|% READER ReadForm %%.ObjReader %->% %%.ObjMal
			%?% (
				%|% NS Free %%.ObjMalSymQuote
				%-|%
			)
			%|% TYPES NewMalList %%.ObjMalSymQuote %%.ObjMal %->% %%.ObjAST
		) else if "!%%.CurToken!" == "@" (
			%|% TYPES NewMal MalSym deref
			%&% _G_RET %%.ObjMalSymQuote
			set /a !%%.ObjReader!.TokenPtr += 1

			%|% READER ReadForm %%.ObjReader %->% %%.ObjMal
			%?% (
				%|% NS Free %%.ObjMalSymQuote
				%-|%
			)
			%|% TYPES NewMalList %%.ObjMalSymQuote %%.ObjMal %->% %%.ObjAST
		) else if "!%%.CurToken!" == "~" (
			%|% TYPES NewMal MalSym unquote %->% %%.ObjMalSymQuote
			set /a !%%.ObjReader!.TokenPtr += 1

			%|% READER ReadForm %%.ObjReader %->% %%.ObjMal
			%?% (
				%|% NS Free %%.ObjMalSymQuote
				%-|%
			)
			%|% TYPES NewMalList %%.ObjMalSymQuote %%.ObjMal %->% %%.ObjAST
		) else if "!%%.CurToken!" == "~@" (
			%|% TYPES NewMal MalSym splice-unquote %->% %%.ObjMalSymQuote
			set /a !%%.ObjReader!.TokenPtr += 1

			%|% READER ReadForm %%.ObjReader %->% %%.ObjMal
			%?% (
				%|% NS Free %%.ObjMalSymQuote
				%-|%
			)
			%|% TYPES NewMalList %%.ObjMalSymQuote %%.ObjMal %->% %%.ObjAST
		) else if "!%%.CurToken!" == "$C" (
			%|% READER ReadMeta %%.ObjReader %->% %%.ObjAST
			%?% %-|%
		) else if "!%%.CurToken!" == ")" (
			%??% "unexpected token ')'."
			%-|%
		) else if "!%%.CurToken!" == "]" (
			%??% "unexpected token ']'."
			%-|%
		) else if "!%%.CurToken!" == "}" (
			%??% "unexpected token '}'."
			%-|%
		) else if "!%%.CurToken:~,1!" == ";" (
			%??% "" Empty
		) else (
			%|% READER ReadAtom %%.ObjReader %->% %%.ObjAST
		)

		%<-% %%.ObjAST
	)
%-|%

:READER_ReadAtom &ObjReader -> ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjReader=!%~1!"

		%&% !%%.ObjReader!.TokenPtr %%.TokenPtr
		%&% !%%.ObjReader!.TokenCount %%.TotalTokenNum

		if !%%.TokenPtr! Gtr !%%.TotalTokenNum! (
			%??% "unexpected EOF, need more token."
			%-|%
		)

		%&% !%%.ObjReader!.Token[!%%.TokenPtr!] %%.CurToken
		set /a %%.TokenPtr += 1
		%&% %%.TokenPtr !%%.ObjReader!.TokenPtr
		
		%|% NS New %->% %%.ObjMalCode
		%&% %%.CurToken !%%.ObjMalCode!.Value
		
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

		%<-% %%.ObjMalCode
	)
%-|%

:READER_ReadList &ObjReader -> ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjReader=!%~1!"

		%&% !%%.ObjReader!.TokenPtr %%.TokenPtr
		%&% !%%.ObjReader!.TokenCount %%.TotalTokenNum

		if !%%.TokenPtr! Gtr !%%.TotalTokenNum! (
			%??% "unbalanced parenthesis."
			%-|%
		)

		%&% !%%.ObjReader!.Token[!%%.TokenPtr!] %%.CurToken

		if "!%%.CurToken!" Equ "(" (
			%|% NS New MalLst %->% %%.ObjMalCode
		) else if "!%%.CurToken!" Equ "[" (
			%|% NS New MalVec %->% %%.ObjMalCode
		) else (
			%?|% "unexpected token '!%%.CurToken!'."
		)

		set /a %%.TokenPtr += 1
		%&% %%.TokenPtr !%%.ObjReader!.TokenPtr

		if !%%.TokenPtr! Gtr !%%.TotalTokenNum! (
			%|% NS Free %%.ObjMalCode
			%??% "unbalanced parenthesis."
			%-|%
		)
		
		set "%%.Count=0"
	)
	:READER_ReadList_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
		%&% !%%.ObjReader!.TokenPtr %%.TokenPtr
		
		if !%%.TokenPtr! Gtr !%%.TotalTokenNum! (
			%|% NS Free %%.ObjMalCode
			%??% "unbalanced parenthesis."
			%-|%
		)

		%&% !%%.ObjReader!.Token[!%%.TokenPtr!] %%.CurToken

		if "!%%.CurToken!" == ")" (
			%&% !%%.ObjMalCode!.Type %%.Type
			if "!%%.Type!" Neq "MalLst" (
				%|% NS Free %%.ObjMalCode
				%??% "unbalanced parenthesis."
				%-|%
			)
			set /a %%.TokenPtr += 1
			%&% %%.TokenPtr !%%.ObjReader!.TokenPtr
			goto READER_ReadList_Pass
		)
		if "!%%.CurToken!" == "]" (
			%&% !%%.ObjMalCode!.Type %%.Type
			if "!%%.Type!" Neq "MalVec" (
				%|% NS Free %%.ObjMalCode
				%??% "unbalanced parenthesis."
				%-|%
			)
			set /a %%.TokenPtr += 1
			%&% %%.TokenPtr !%%.ObjReader!.TokenPtr
			goto READER_ReadList_Pass
		)
		set /a %%.Count += 1

		%|% READER ReadForm %%.ObjReader
		%|->% %%.MalRet
		%?% (
			%|% NS Free %%.ObjMalCode
			%-|%
		)
		%|% NS Link %%.ObjMalCode Item[!%%.Count!] %%.MalRet
		%|% NS Free %%.MalRet

		goto READER_ReadList_Loop
	)
	:READER_ReadList_Pass
	for %%. in (_L{!_G_LEVEL!}_) do (
		%&% %%.Count !%%.ObjMalCode!.Count

		%<-% %%.ObjMalCode
	)
%-|%

:READER_ReadMap &ObjReader -> ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjReader=!%~1!"

		%&% !%%.ObjReader!.TokenPtr %%.TokenPtr
		%&% !%%.ObjReader!.TokenCount %%.TokenCount
		
		if !%%.TokenPtr! Gtr !%%.TokenCount! (
			%??% "unbalanced parenthesis."
			%-|%
		)

		set /a %%.TokenPtr += 1
		%&% %%.TokenPtr !%%.ObjReader!.TokenPtr

		%|% NS New MalMap %->% %%.MalMap

		set "%%.MapKeyCount=0"
		set /a %%.RawKeyCount=0
		%|% NS New RawKeyArr %->% %%.RawKeys
	)
	:READER_ReadMap_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
		
		%&% !%%.ObjReader!.TokenPtr %%.TokenPtr
		if !%%.TokenPtr! Gtr !%%.TokenCount! (
			%|% NS Free %%.RawKeys
			%|% NS Free %%.MalMap
			%??% "unbalanced parenthesis."
			%-|%
		)
		%&% !%%.ObjReader!.Token[!%%.TokenPtr!] %%.Token
		if "!%%.Token!" == "}" (
			set /a %%.TokenPtr += 1
			%&% %%.TokenPtr !%%.ObjReader!.TokenPtr
			goto READER_ReadMap_Pass
		)

		@REM Read the key.
		%|% READER ReadForm %%.ObjReader %->% %%.MalKey
		%?% (
			%|% NS Free %%.MalMap
			%|% NS Free %%.RawKeys
			%-|%
		)


		@REM Check if the key is MalStr or MalKwd.
		%&% !%%.MalKey!.Type %%.Type
		if "!%%.Type!" Neq "MalStr" if "!%%.Type!" Neq "MalKwd" (
			%|% NS Free %%.RawKeys
			%|% NS Free %%.MalKey
			%|% NS Free %%.MalMap
			%??% "Map key must be 'MalStr' or 'MalKwd'."
			%-|%
		)
		
		%&% !%%.MalKey!.Value %%.RawKey


		%&% !%%.ObjReader!.TokenPtr %%.TokenPtr

		if !%%.TokenPtr! Gtr !%%.TokenCount! (
			%??% "Unmatched map key-value pair."
			%|% NS Free %%.RawKeys
			%|% NS Free %%.MalKey
			%|% NS Free %%.MalMap
			%-|%
		)

		%|% READER ReadForm %%.ObjReader %->% %%.MalVal
		%?% (
			%|% NS Free %%.RawKeys
			%|% NS Free %%.MalKey
			%|% NS Free %%.MalVal
			%|% NS Free %%.MalMap
			%-|%
		)
		if defined !%%.MalMap!.Item[!%%.RawKey!] (
			%&% !%%.MalMap!.Item[!%%.RawKey!].Count %%.SameKeyCount
			set "%%.Exist=False"
			for /l %%i in (1 1 !%%.SameKeyCount!) do (
				%&% !%%.MalMap!.Item[!%%.RawKey!].Item[%%i].Key %%.ExistKey
				%&% !%%.ExistKey!.Value %%.ExistRawKey
				if "!%%.ExistRawKey!" == "!%%.RawKey!" (
					%|% NS Free %%.RawKeys
					%|% NS Free %%.MalKey
					%|% NS Free %%.MalVal
					%|% NS Free %%.MalMap
					%??% "Key '!%%.RawKey!' already exist."
					%-|%
				)
			)
			
			if "!%%.Exist!" == "False" (
				set /a !%%.MalMap!.Item[!%%.RawKey!].Count += 1
				
				%&% "!%%.MalMap!.Item[!%%.RawKey!].Count" %%.SameKeyCount
				%|% NS Link %%.MalMap Item[!%%.RawKey!].Item[!%%.SameKeyCount!].Key %%.MalKey
				%|% NS Link %%.MalMap Item[!%%.RawKey!].Item[!%%.SameKeyCount!].Value %%.MalVal
				%|% NS Free %%.MalKey
				%|% NS Free %%.MalVal
			)
		) else (
			set "!%%.MalMap!.Item[!%%.RawKey!]=_"
			set "!%%.MalMap!.Item[!%%.RawKey!].Count=1"

			%&% "!%%.MalMap!.Item[!%%.RawKey!].Count" %%.SameKeyCount
			%|% NS Link %%.MalMap Item[!%%.RawKey!].Item[!%%.SameKeyCount!].Key %%.MalKey
			%|% NS Link %%.MalMap Item[!%%.RawKey!].Item[!%%.SameKeyCount!].Value %%.MalVal
			%|% NS Free %%.MalKey
			%|% NS Free %%.MalVal

			set /a %%.RawKeyCount += 1
			set "!%%.RawKeys!.Key[!%%.RawKeyCount!]=!%%.RawKey!"
		)

		set /a %%.MapKeyCount += 1
		goto READER_ReadMap_Loop
	)
	:READER_ReadMap_Pass
	for %%. in (_L{!_G_LEVEL!}_) do (
		%&% %%.MapKeyCount !%%.MalMap!.Count
		%&% %%.RawKeyCount !%%.MalMap!.RawKeyCount
		%|% NS Link %%.MalMap RawKeys %%.RawKeys
		%|% NS Free %%.RawKeys
		%<-% %%.MalMap
	)
%-|%

:READER_ReadMeta &Reader -> ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Reader=!%~1!"

		set /a !%%.Reader!.TokenPtr += 1
		
		%&% !%%.Reader!.TokenPtr %%.TokenPtr
		%&% !%%.Reader!.TokenCount %%.TokenCount
		if !%%.TokenPtr! Gtr !%%.TokenCount! (
			%??% "Unexpected EOF, need more token."
			%-|%
		)

		%|% TYPES NewMal MalSym "with-meta" %->% %%.MalSym
		%|% READER ReadForm %%.Reader %->% %%.MalMeta
		%?% (
			%|% NS Free %%.MalSym
			%-|%
		)
		%|% TYPES CheckType %%.MalMeta MalMap %->% %%.IsCorrect
		if "!%%.IsCorrect!" == "False" (
			%|% NS Free %%.MalSym
			%|% NS Free %%.MalMeta
			%??% "Meta must be a map."
			%-|%
		)
		%|% READER ReadForm %%.Reader %->% %%.MalType
		%?% (
			%|% NS Free %%.MalSym
			%|% NS Free %%.MalMeta
			%-|%
		)
		
		%|% TYPES NewMalList %%.MalSym %%.MalType %%.MalMeta %->% %%.MalRes
		%<-% %%.MalRes
	)
%-|%


:READER_Tokenize _Line &ObjReader
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Line=!%~1!"
		set "%%.ObjReader=!%~2!"

		%&% %%.Line %%.CurLine
		%&% !%%.ObjReader!.TokenCount %%.CurTokenNum

		rem Tokenize the _CurLine.
		set %%.ParsingStr=False
		set %%.NormalToken=
	)
	:READER_Tokenizing_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
		if "!%%.CurLine!" == "" (
			if "!%%.ParsingStr!" == "True" (
				set _G_ERR=_
				set _G_ERR.Type=Exception
				set "_G_ERR.Msg=[!_G_TRACE!] Exception: unexpected EOF, string is incomplete."
				%-|%
			)
			goto READER_Tokenizing_Pass
		)
		if "!%%.ParsingStr!" == "False" (
			if "!%%.CurLine:~,1!" == " " (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "	" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "," (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,2!" == "~@" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=~@"
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~2!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "[" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=["
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "]" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=]"
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "(" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=("
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == ")" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=)"
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "{" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken={"
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "}" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=}"
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "'" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken='"
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "`" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=`"
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "~" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=~"
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == "@" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=@"
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~1!"
				goto READER_Tokenizing_Loop
			)
			rem ^ --- \eC
			if "!%%.CurLine:~,2!" == "$C" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				set "%%.CurToken=$C"
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]

				set "%%.CurLine=!%%.CurLine:~2!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,2!" == "$D" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				rem string.
				set "%%.CurLine=!%%.CurLine:~2!"
				set "%%.ParsingStr=True"
				set "%%.StrToken="
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,1!" == ";" (
				if defined %%.NormalToken (
					rem save normal token first.
					%&% %%.NormalToken %%.CurToken
					set /a %%.CurTokenNum += 1
					%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
					set %%.NormalToken=
				)
				rem comment.
				%&% %%.CurLine %%.CurToken
				set /a %%.CurTokenNum += 1
				%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
				set "%%.CurLine="
				goto READER_Tokenizing_Loop
			)

			set "%%.NormalToken=!%%.NormalToken!!%%.CurLine:~,1!"
			set "%%.CurLine=!%%.CurLine:~1!"
			goto READER_Tokenizing_Loop
		) else (
			rem parsing string now.
			if "!%%.CurLine:~,2!" == "\\" (
				rem \\
				set "%%.CurLine=!%%.CurLine:~2!"
				set "%%.StrToken=!%%.StrToken!\\"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,3!" == "\$D" (
				rem \"
				set "%%.CurLine=!%%.CurLine:~3!"
				set "%%.StrToken=!%%.StrToken!\$D"
				goto READER_Tokenizing_Loop
			)
			if "!%%.CurLine:~,2!" == "$D" (
				rem end of string.
				set "%%.CurLine=!%%.CurLine:~2!"
				set "%%.ParsingStr=False"
				set /a %%.CurTokenNum += 1
				set "%%.StrToken=$D!%%.StrToken!$D"
				%&% %%.StrToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
				goto READER_Tokenizing_Loop
			)
			set "%%.StrToken=!%%.StrToken!!%%.CurLine:~,1!"
			set "%%.CurLine=!%%.CurLine:~1!"
			goto READER_Tokenizing_Loop
		)
	)
	:READER_Tokenizing_Pass
	for %%. in (_L{!_G_LEVEL!}_) do (
		if defined %%.NormalToken (
			rem save normal token first.
			%&% %%.NormalToken %%.CurToken
			set /a %%.CurTokenNum += 1
			%&% %%.CurToken !%%.ObjReader!.Token[!%%.CurTokenNum!]
			set %%.NormalToken=
		)
		%&% %%.CurTokenNum !%%.ObjReader!.TokenCount

		%<-% _
	)
%-|%
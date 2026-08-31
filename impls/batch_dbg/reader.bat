@echo off
if "%~1" neq "" (
	call %* || (
		if defined _G.TRACE (
			2>con >&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" failed.
		) else (
			2>con >&2 echo [%~n0] Fatal: Call "%~nx0" failed.
		)
		2>con >&2 pause
		exit 1
	)
) else (
	if defined _G.TRACE (
		2>con >&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" with nothing.
	) else (
		2>con >&2 echo [%~n0] Fatal: Call "%~nx0" with nothing.
	)
	2>con >&2 pause
	exit 1
)
exit /b 0

:READER_ReadString _Str -> AST
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Str=%~1"

		%{n% %%.Reader %}
		%{s% %%.Reader Type Reader %}
		set "%%.TokenCount=0"
		set "%%.TokenPtr=1"
		%{s% %%.Reader TokenCount 0 %}
		%{s% %%.Reader TokenPtr 1 %}

		call READER :READER_Tokenize "!%%.Str!" "!%%.Reader!"
		%?% (
			%-|%
		)

		%{g% %%.Reader TokenCount %%.TotalTokenNum %}
		if "!%%.TotalTokenNum!" == "0" (
			%??% "" Empty
			%-|%
		)

		echo SKIP_ReadForm
		%?% (
			%-|%
		)

		%<-% %%.AST
	)
%-|%

:READER_ReadForm *Reader -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}
		%{g% "%~1" TokenCount %%.TotalTokenNum %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unexpected EOF, need more token."
			%-|%
		)

		%{g% "%~1" Token[!%%.TokenPtr!] %%.CurToken %}

		if "!%%.CurToken!" == "(" (
			%{% READER ReadList "%~1" %}% %->% %%.AST 
			%?% (
				%-|%
			)
		) else if "!%%.CurToken!" == "[" (
			%{% READER ReadList "%~1" %}% %->% %%.AST 
			%?% (
				%-|%
			)
		) else if "!%%.CurToken!" == "{" (
			%{% READER ReadMap "%~1" %}% %->% %%.AST 
			%?% (
				%-|%
			)
		) else if "!%%.CurToken!" == "'" (
			%{% TYPES NewMal MalSym quote %}% %->% %%.SymQuote 
			%{g% "%~1" TokenPtr %%.TP %}
			set /a %%.TP += 1
			%{s% "%~1" TokenPtr !%%.TP! %}

			%{% READER ReadForm "%~1" %}% %->% %%.Mal 
			%?% (
				%-|%
			)
			%{% TYPES NewMalList %%.SymQuote %%.Mal %}% %->% %%.AST 
		) else if "!%%.CurToken!" == "`" (
			%{% TYPES NewMal MalSym quasiquote %}% %->% %%.SymQuote 
			%{g% "%~1" TokenPtr %%.TP %}
			set /a %%.TP += 1
			%{s% "%~1" TokenPtr !%%.TP! %}

			%{% READER ReadForm "%~1" %}% %->% %%.Mal 
			%?% (
				%-|%
			)
			%{% TYPES NewMalList %%.SymQuote %%.Mal %}% %->% %%.AST 
		) else if "!%%.CurToken!" == "@" (
			%{% TYPES NewMal MalSym deref %}% %->% %%.SymQuote 
			%{g% "%~1" TokenPtr %%.TP %}
			set /a %%.TP += 1
			%{s% "%~1" TokenPtr !%%.TP! %}

			%{% READER ReadForm "%~1" %}% %->% %%.Mal 
			%?% (
				%-|%
			)
			%{% TYPES NewMalList %%.SymQuote %%.Mal %}% %->% %%.AST 
		) else if "!%%.CurToken!" == "~" (
			%{% TYPES NewMal MalSym unquote %}% %->% %%.SymQuote 
			%{g% "%~1" TokenPtr %%.TP %}
			set /a %%.TP += 1
			%{s% "%~1" TokenPtr !%%.TP! %}

			%{% READER ReadForm "%~1" %}% %->% %%.Mal 
			%?% (
				%-|%
			)
			%{% TYPES NewMalList %%.SymQuote %%.Mal %}% %->% %%.AST 
		) else if "!%%.CurToken!" == "~@" (
			%{% TYPES NewMal MalSym splice-unquote %}% %->% %%.SymQuote 
			%{g% "%~1" TokenPtr %%.TP %}
			set /a %%.TP += 1
			%{s% "%~1" TokenPtr !%%.TP! %}

			%{% READER ReadForm "%~1" %}% %->% %%.Mal 
			%?% (
				%-|%
			)
			%{% TYPES NewMalList %%.SymQuote %%.Mal %}% %->% %%.AST 
		) else if "!%%.CurToken!" == "$C" (
			%{% READER ReadMeta "%~1" %}% %->% %%.AST 
			%?% (
				%-|%
			)
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
			%{% READER ReadAtom "%~1" %}% %->% %%.AST 
			%?% (
				%-|%
			)
		)

		%<-% %%.AST
	)
%-|%

:READER_ReadAtom *Reader -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}
		%{g% "%~1" TokenCount %%.TotalTokenNum %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unexpected EOF, need more token."
			%-|%
		)

		%{g% "%~1" Token[!%%.TokenPtr!] %%.CurToken %}
		set /a %%.TokenPtr += 1
		%{s% "%~1" TokenPtr !%%.TokenPtr! %}

		set /a %%.TestNum = %%.CurToken
		if "!%%.TestNum!" == "!%%.CurToken!" (
			%{% TYPES NewMal MalNum "!%%.CurToken!" %}% %->% %%.Mal 
		) else if "!%%.CurToken!" == "nil" (
			%{% TYPES NewMal MalNil nil %}% %->% %%.Mal 
		) else if "!%%.CurToken!" == "true" (
			%{% TYPES NewMal MalBool true %}% %->% %%.Mal 
		) else if "!%%.CurToken!" == "false" (
			%{% TYPES NewMal MalBool false %}% %->% %%.Mal 
		) else if "!%%.CurToken:~,2!" == "$D" (
			%{% TYPES NewMal MalStr "!%%.CurToken!" %}% %->% %%.Mal 
		) else if "!%%.CurToken:~,2!" == "$A" (
			%{% TYPES NewMal MalKwd "!%%.CurToken!" %}% %->% %%.Mal 
		) else (
			%{% TYPES NewMal MalSym "!%%.CurToken!" %}% %->% %%.Mal 
		)

		%<-% %%.Mal
	)
%-|%

:READER_ReadList *Reader -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}
		%{g% "%~1" TokenCount %%.TotalTokenNum %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unbalanced parenthesis."
			%-|%
		)

		%{g% "%~1" Token[!%%.TokenPtr!] %%.CurToken %}

		if "!%%.CurToken!" == "(" (
			%{% TYPES NewMalList %}% %->% %%.MalCode 
			%{s% %%.MalCode Type MalLst %}
		) else if "!%%.CurToken!" == "[" (
			%{% TYPES NewMalList %}% %->% %%.MalCode 
			%{s% %%.MalCode Type MalVec %}
		) else (
			%?|% "unexpected token '!%%.CurToken!'."
		)

		set /a %%.TokenPtr += 1
		%{s% "%~1" TokenPtr !%%.TokenPtr! %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unbalanced parenthesis."
			%-|%
		)

		set "%%.Count=0"
	)
	:READER_ReadList_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unbalanced parenthesis."
			%-|%
		)

		%{g% "%~1" Token[!%%.TokenPtr!] %%.CurToken %}

		if "!%%.CurToken!" == ")" (
			%{g% %%.MalCode Type %%.Type %}
			if "!%%.Type!" neq "MalLst" (
				%??% "unbalanced parenthesis."
				%-|%
			)
			set /a %%.TokenPtr += 1
			%{s% "%~1" TokenPtr !%%.TokenPtr! %}
			goto READER_ReadList_Pass
		)
		if "!%%.CurToken!" == "]" (
			%{g% %%.MalCode Type %%.Type %}
			if "!%%.Type!" neq "MalVec" (
				%??% "unbalanced parenthesis."
				%-|%
			)
			set /a %%.TokenPtr += 1
			%{s% "%~1" TokenPtr !%%.TokenPtr! %}
			goto READER_ReadList_Pass
		)
		set /a %%.Count += 1

		%{% READER ReadForm "%~1" %}% %->% %%.MalRet 
		%?% (
			%-|%
		)
		%{s% %%.MalCode Item[!%%.Count!] !%%.MalRet! %}

		goto READER_ReadList_Loop
	)
	:READER_ReadList_Pass
	for %%. in (_L[!_G.LEVEL!].) do (
		%{s% %%.MalCode Count !%%.Count! %}

		%<-% %%.MalCode
	)
%-|%

:READER_ReadMap *Reader -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}
		%{g% "%~1" TokenCount %%.TotalTokenNum %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unbalanced parenthesis."
			%-|%
		)

		set /a %%.TokenPtr += 1
		%{s% "%~1" TokenPtr !%%.TokenPtr! %}

		%{% TYPES NewMalMap %}% %->% %%.MalMap 
		%{g% %%.MalMap RawKeys %%.RawKeys %}

		set "%%.MapKeyCount=0"
		set "%%.RawKeyCount=0"
	)
	:READER_ReadMap_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}
		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unbalanced parenthesis."
			%-|%
		)
		%{g% "%~1" Token[!%%.TokenPtr!] %%.Token %}
		if "!%%.Token!" == "}" (
			set /a %%.TokenPtr += 1
			%{s% "%~1" TokenPtr !%%.TokenPtr! %}
			goto READER_ReadMap_Pass
		)

		%{% READER ReadForm "%~1" %}% %->% %%.MalKey 
		%?% (
			%-|%
		)

		%{g% "!%%.MalKey!" Type %%.Type %}
		if "!%%.Type!" neq "MalStr" if "!%%.Type!" neq "MalKwd" (
			%??% "Map key must be 'MalStr' or 'MalKwd'."
			%-|%
		)

		%{g% "!%%.MalKey!" Value %%.RawKey %}

		%{g% "%~1" TokenPtr %%.TokenPtr %}
		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "Unmatched map key-value pair."
			%-|%
		)

		%{% READER ReadForm "%~1" %}% %->% %%.MalVal 
		%?% (
			%-|%
		)

		%{g% %%.MalMap Item[!%%.RawKey!].Count %%.ExistCnt %}
		if "!%%.ExistCnt!" == "" (
			set /a %%.MapKeyCount += 1
			%{s% %%.MalMap Item[!%%.RawKey!].Count 1 %}
			%{s% %%.MalMap Item[!%%.RawKey!].Item[1].Key !%%.MalKey! %}
			%{s% %%.MalMap Item[!%%.RawKey!].Item[1].Value !%%.MalVal! %}

			set /a %%.RawKeyCount += 1
			%{s% "!%%.RawKeys!" Key[!%%.RawKeyCount!] "!%%.RawKey!" %}
		) else (
			set /a %%.ExistCnt += 1
			%{s% %%.MalMap Item[!%%.RawKey!].Count !%%.ExistCnt! %}
			%{s% %%.MalMap Item[!%%.RawKey!].Item[!%%.ExistCnt!].Key !%%.MalKey! %}
			%{s% %%.MalMap Item[!%%.RawKey!].Item[!%%.ExistCnt!].Value !%%.MalVal! %}
		)

		goto READER_ReadMap_Loop
	)
	:READER_ReadMap_Pass
	for %%. in (_L[!_G.LEVEL!].) do (
		%{s% %%.MalMap Count !%%.MapKeyCount! %}
		%{s% %%.MalMap RawKeyCount !%%.RawKeyCount! %}
		%{s% %%.MalMap RawKeys !%%.RawKeys! %}
		%<-% %%.MalMap
	)
%-|%

:READER_ReadMeta *Reader -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TP %}
		set /a %%.TP += 1
		%{s% "%~1" TokenPtr !%%.TP! %}

		%{g% "%~1" TokenPtr %%.TokenPtr %}
		%{g% "%~1" TokenCount %%.TokenCount %}
		if !%%.TokenPtr! gtr !%%.TokenCount! (
			%??% "Unexpected EOF, need more token."
			%-|%
		)

		%{% TYPES NewMal MalSym with-meta %}% %->% %%.MalSym 
		%{% READER ReadForm "%~1" %}% %->% %%.MalMeta 
		%?% (
			%-|%
		)
		%{% TYPES CheckType "!%%.MalMeta!" MalMap %}% %->% %%.IsCorrect 
		if "!%%.IsCorrect!" == "0" (
			%??% "Meta must be a map."
			%-|%
		)
		%{% READER ReadForm "%~1" %}% %->% %%.MalType 
		%?% (
			%-|%
		)

		%{% TYPES NewMalList %%.MalSym %%.MalType %%.MalMeta %}% %->% %%.MalRes 
		%<-% %%.MalRes
	)
%-|%

:READER_Tokenize _Str *Reader
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Line=%~1"
		set "%%.Reader=%~2"

		%{g% "!%%.Reader!" TokenCount %%.CurTokenNum %}
		set "%%.ParsingStr=False"
		set "%%.NormalToken="
	)
	:READER_Tokenizing_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		if "!%%.Line!" == "" (
			if "!%%.ParsingStr!" == "True" (
				%??% "unexpected EOF, string is incomplete."
				%-|%
			)
			goto READER_Tokenizing_Pass
		)
		if "!%%.ParsingStr!" == "False" (
			if "!%%.Line:~,1!" == " -DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "	-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == ",-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,2!" == "~@-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "~@" %}
				set "%%.Line=!%%.Line:~2!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "(-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "(" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == ")-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] ")" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "[-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "[" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "]-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "]" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "{-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "{" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "}-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "}" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "'" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "'" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "`" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "`" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "~" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "~" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "@" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "@" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,2!" == "$C-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "$C" %}
				set "%%.Line=!%%.Line:~2!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,2!" == "$D-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set "%%.Line=!%%.Line:~2!"
				set "%%.ParsingStr=True"
				set "%%.StrToken="
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == ";-DISABLED" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] ";!%%.Line!" %}
				set "%%.Line="
				goto READER_Tokenizing_Loop
			)

			set "%%.NormalToken=!%%.NormalToken!!%%.Line:~,1!"
			set "%%.Line=!%%.Line:~1!"
			goto READER_Tokenizing_Loop
		) else (
			if "!%%.Line:~,4!" == "\\\\$D" (
				set "%%.Line=!%%.Line:~4!"
				set "%%.StrToken=!%%.StrToken!\\$D"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,2!" == "\\" (
				set "%%.Line=!%%.Line:~2!"
				set "%%.StrToken=!%%.StrToken!\\"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,3!" == "\$D" (
				set "%%.Line=!%%.Line:~3!"
				set "%%.StrToken=!%%.StrToken!\$D"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,2!" == "$D-DISABLED" (
				set "%%.Line=!%%.Line:~2!"
				set "%%.ParsingStr=False"
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "$D!%%.StrToken!$D" %}
				goto READER_Tokenizing_Loop
			)
			set "%%.StrToken=!%%.StrToken!!%%.Line:~,1!"
			set "%%.Line=!%%.Line:~1!"
			goto READER_Tokenizing_Loop
		)
	)
	:READER_Tokenizing_Pass
	for %%. in (_L[!_G.LEVEL!].) do (
		if defined %%.NormalToken (
			set /a %%.CurTokenNum += 1
			%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
			set "%%.NormalToken="
		)
		%{s% "!%%.Reader!" TokenCount !%%.CurTokenNum! %}
		%<-% _
	)
%-|%

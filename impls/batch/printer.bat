@echo off
if "%~1" neq "" (
	call %* || (
		if defined _G.TRACE (
			>&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" failed.
		) else (
			>&2 echo [%~n0] Fatal: Call "%~nx0" failed.
		)
		2>con >&2 pause
		exit 1
	)
) else (
	if defined _G.TRACE (
		>&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" with nothing.
	) else (
		>&2 echo [%~n0] Fatal: Call "%~nx0" with nothing.
	)
	2>con >&2 pause
	exit 1
)
exit /b 0

:PRINTER_PrintMalType &Mal -> Str
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" Type %%.Type %}%
		if "!%%.Type!" == "MalNum" (
			%{g% "%~1" Value %%.Val %}
			%{% STR FromVar %%.Val %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalSym" (
			%{g% "%~1" Value %%.Val %}
			%{% STR FromVar %%.Val %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalNil" (
			%{% STR FromVal "nil" %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalBool" (
			%{g% "%~1" Value %%.Val %}
			%{% STR FromVar %%.Val %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalKwd" (
			%{g% "%~1" Value %%.Val %}
			%{% STR FromVar %%.Val %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalStr" (
			%{g% "%~1" Value %%.Val %}
			%{% STR FromVar %%.Val %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalLst" (
			%{% STR New %}% %->% %%.StrMal
			%{% STR AppendVal %%.StrMal "(" %}
			%{g% "%~1" Count %%.Count %}
			for /l %%i in (1 1 !%%.Count!) do (
				%{g% "%~1" Item[%%i] %%.ItemMal %}
				%{% PRINTER PrintMalType "!%%.ItemMal!" %}% %->% %%.RetStrMal
				%{% STR AppendStr %%.StrMal %%.RetStrMal %}
				if "%%i" neq "!%%.Count!" (
					%{% STR AppendVal %%.StrMal " " %}
				)
			)
			%{% STR AppendVal %%.StrMal ")" %}
		) else if "!%%.Type!" == "MalVec" (
			%{% STR New %}% %->% %%.StrMal
			%{% STR AppendVal %%.StrMal "[" %}
			%{g% "%~1" Count %%.Count %}
			for /l %%i in (1 1 !%%.Count!) do (
				%{g% "%~1" Item[%%i] %%.ItemMal %}
				%{% PRINTER PrintMalType "!%%.ItemMal!" %}% %->% %%.RetStrMal
				%{% STR AppendStr %%.StrMal %%.RetStrMal %}
				if "%%i" neq "!%%.Count!" (
					%{% STR AppendVal %%.StrMal " " %}
				)
			)
			%{% STR AppendVal %%.StrMal "]" %}
		) else if "!%%.Type!" == "MalMap" (
			%{% PRINTER PrintMalMap "%~1" %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalFn" (
			%{% STR FromVal "#<function>" %}% %->% %%.StrMal
		) else (
			%?|% "MalType '!%%.Type!' not support yet."
		)
		%<-% %%.StrMal
	)
%-|%

:PRINTER_PrintMalMap &MalMap -> Str
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% STR New %}% %->% %%.Str
		%{% STR AppendVal %%.Str "{" %}
		%{g% "%~1" RawKeyCount %%.KeyCount %}
		%{g% "%~1" RawKeys %%.Keys %}
																								for /l %%i in (1 1 !%%.KeyCount!) do (
						%{g% "!%%.Keys!" Key[%%i] %%.RawKey %}
			%{g% "%~1" Item[!%%.RawKey!].Count %%.SameKeyCount %}
			for /l %%j in (1 1 !%%.SameKeyCount!) do (
				%{g% "%~1" Item[!%%.RawKey!].Item[%%j].Key %%.KeyMal %}
				%{g% "%~1" Item[!%%.RawKey!].Item[%%j].Value %%.ValMal %}
				%{% PRINTER PrintMalType "!%%.KeyMal!" %}% %->% %%.StrKey
				%{% PRINTER PrintMalType "!%%.ValMal!" %}% %->% %%.StrVal
				%{% STR AppendStr %%.Str %%.StrKey %}
				%{% STR AppendVal %%.Str " " %}
				%{% STR AppendStr %%.Str %%.StrVal %}
				if "%%j" neq "!%%.SameKeyCount!" (
					%{% STR AppendVal %%.Str " " %}
				)
			)
			if "%%i" neq "!%%.KeyCount!" (
				%{% STR AppendVal %%.Str " " %}
			)
		)
		%{% STR AppendVal %%.Str "}" %}
		%<-% %%.Str
	)
%-|%

:PRINTER_PrStrMal &Mal -> Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% PRINTER PrintMalType "%~1" %}% %->% %%.StrMal
		%{% STR GetStr %%.StrMal %}% %->% %%.Result
		%<-% %%.Result
	)
%-|%

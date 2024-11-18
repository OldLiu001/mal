@echo off
if "%~1" neq "" (
	call %* || %?|% "Call '%~nx0' failed."
)
%-|%


:PRINTER_PrintMalType &ObjMal -> StrMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		if not defined !%%.ObjMal!.Type (
			%?|% "'!%%.ObjMal!.Type' not defined!"
		)
		%&% !%%.ObjMal!.Type %%.Type
		if not "!%%.Type:~,3!" == "Mal" (
			%?|% "'!%%.ObjMal!' is not a MalType!"
		)
		
		%|% Str New %->% %%.StrMal
		
		if "!%%.Type!" == "MalNum" (
			%|% Str AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalSym" (
			%|% Str AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalNil" (
			%|% Str AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalBool" (
			%|% Str AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalKwd" (
			%|% Str AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalStr" (
			%|% Str AppendVar %%.StrMal !%%.ObjMal!.Value
		) else if "!%%.Type!" == "MalLst" (
			%|% Str AppendVal %%.StrMal "("
			%&% !%%.ObjMal!.Count %%.Count
			for /l %%i in (1 1 !%%.Count!) do (
				%|% PRINTER PrintMalType !%%.ObjMal!.Item[%%i] %->% %%.RetStrMal
				%|% Str AppendStr %%.StrMal %%.RetStrMal
				%|% NS Free %%.RetStrMal
				
				if  "%%i" neq "!%%.Count!" (
					%|% Str AppendVal %%.StrMal " "
				)
			)
			%|% Str AppendVal %%.StrMal ")"
		) else if "!%%.Type!" == "MalVec" (
			%|% Str AppendVal %%.StrMal "["
			%&% !%%.ObjMal!.Count %%.Count
			for /l %%i in (1 1 !%%.Count!) do (
				%|% PRINTER PrintMalType !%%.ObjMal!.Item[%%i] %->% %%.RetStrMal
				%|% Str AppendStr %%.StrMal %%.RetStrMal
				%|% NS Free %%.RetStrMal
				
				if  "%%i" neq "!%%.Count!" (
					%|% Str AppendVal %%.StrMal " "
				)
			)
			%|% Str AppendVal %%.StrMal "]"
		) else if "!%%.Type!" == "MalMap" (
			%|% NS Free %%.StrMal
			%|% PRINTER PrintMalMap %%.ObjMal %->% %%.StrMal
		) else if "!%%.Type!" == "MalFn" (
			%|% NS Free %%.StrMal
			set "%%.Fn=#<function>"
			%|% Str FromVar %%.Fn %->% %%.StrMal
		) else (
			%?|% "MalType '!%%.Type!' not support yet."
		)

		%<-% %%.StrMal
	)
%-|%

:PRINTER_PrintMalMap &MalMap -> Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.MalMap=!%~1!"

		%|% Str New %->% %%.Str
		%|% Str AppendVal %%.Str "{"

		%&% !%%.MalMap!.RawKeyCount %%.KeyCount
		%&% !%%.MalMap!.RawKeys %%.Keys

		for /l %%i in (1 1 !%%.KeyCount!) do (
			%&% !%%.Keys!.Key[%%i] %%.RawKey
			
			%&% !%%.MalMap!.Item[!%%.RawKey!].Count %%.SameKeyCount
			
			for /l %%j in (1 1 !%%.SameKeyCount!) do (
				%|% PRINTER PrintMalType !%%.MalMap!.Item[!%%.RawKey!].Item[%%j].Key %->% %%.StrKey
				%|% PRINTER PrintMalType !%%.MalMap!.Item[!%%.RawKey!].Item[%%j].Value %->% %%.StrVal

				%|% Str AppendStr %%.Str %%.StrKey
				%|% NS Free %%.StrKey
				%|% Str AppendVal %%.Str " "
				%|% Str AppendStr %%.Str %%.StrVal
				%|% NS Free %%.StrVal
				if %%j neq !%%.SameKeyCount! %|% Str AppendVal %%.Str " "
			)
			if %%i neq !%%.KeyCount! %|% Str AppendVal %%.Str " "
		)

		%|% Str AppendVal %%.Str "}"
		%<-% %%.Str
	)
%-|%
@echo off
if "%~1" neq "" (
	call %* || %?|% "Call '%~nx0' failed."
)
%-|%

:NS_New _Type -> NS
	for %%. in (_L{!_G_LEVEL!}_) do (
		if "%~1" == "" (
			%?|% "Attempt to create a namespace with an empty type."
		)

		set /a _G_NSP += 1
		set "_G_NS[!_G_NSP!]=%~1"
		set "_G_NS[!_G_NSP!].=_"
		set "_G_NS[!_G_NSP!].RefCnt=0"
		set "_G_NS[!_G_NSP!].LnkCnt=0"

		set /a %%.UpperLevel = _G_LEVEL - 1
		set _L{!%%.UpperLevel!}.AutoFreeList{_G_NS[!_G_NSP!]}=_G_NS[!_G_NSP!]

		set "%%.Ret=_G_NS[!_G_NSP!]"
		%<-% %%.Ret
	)
%-|%

:NS_Link &NS _Field &SubNS
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.NS=!%~1!"
		set "%%.Field=%~2"
		set "%%.SubNS=!%~3!"

		if not defined !%%.NS!. (
			%?|% "Attempt to link to a freed namespace."
		)
		if not defined !%%.SubNS!. (
			%?|% "Attempt to link a freed namespace."
		)
		if "!%%.Field!" == "" (
			%?|% "Attempt to link to a namespace with an empty field."
		)

		%&% %%.SubNS !%%.NS!.Data.!%%.Field!

		set /a !%%.SubNS!.RefCnt += 1
		
		%&% !%%.NS!.LnkCnt %%.LnkCnt
		set /a %%.LnkCnt += 1
		%&% %%.LnkCnt !%%.NS!.LnkCnt

		%&% %%.SubNS !%%.NS!.Lnk[!%%.LnkCnt!]

		%<-% _
	)
%-|%

:NS_Copy &NS -> NS
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.NS=!%~1!"

		if not defined !%%.NS!. (
			%?|% "Attempt to copy a freed namespace."
		)
		set /a !%%.NS!.RefCnt += 1
		%<-% %%.NS
	)
%-|%

:NS_Free NS
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.NS=!%~1!"

		if not defined !%%.NS!. (
			%?|% "Attempt to free a freed namespace."
		)

		%&% !%%.NS!.RefCnt %%.RefCnt
		if !%%.RefCnt! gtr 0 (
			set /a %%.RefCnt -= 1
			%&% %%.RefCnt !%%.NS!.RefCnt
		) else (
			if !%%.RefCnt! lss 0 (
				%?|% "Double free detected."
			)

			%&% !%%.NSMeta!.LnkCnt %%.LnkCnt
			for /l %%i in (1 1 !%%.LnkCnt!) do (
				%&% !%%.NSMeta!.Lnk[%%i] %%.SubNS
				%|% NS Free %%.SubNS
			)

			for /f "delims==" %%i in (
				'set !%%.NS!'
			) do (
				set "%%i="
			)
		)

		%<-% _
	)
%-|%
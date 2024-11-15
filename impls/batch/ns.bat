@echo off
if "%~1" neq "" (
	call %* || %?|% "Call '%~nx0' failed."
)
%-|%

:NS_New [Type] -> NS
	for %%. in (_L{!_G_LEVEL!}_) do (
		set /a _G_NSP += 1
		set "_G_NS[!_G_NSP!]=_G_NSMETA[!_G_NSP!]"
		set "_G_NSMETA[!_G_NSP!].RefCnt=0"
		set "_G_NSMETA[!_G_NSP!].LnkCnt=0"
		set "_G_NS[!_G_NSP!].Type=%~1"

		set "%%.Ret=_G_NS[!_G_NSP!]"
		%<-% %%.Ret
	)
%-|%

:NS_Link NS Field SubNS -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.NS=!%~1!"
		set "%%.Field=%~2"
		set "%%.SubNS=!%~3!"
		%&% !%%.NS! %%.NSMeta
		%&% !%%.SubNS! %%.SubNSMeta

		%&% %%.SubNS !%%.NS!.!%%.Field!

		set /a !%%.SubNSMeta!.RefCnt += 1
		
		%&% !%%.NSMeta!.LnkCnt %%.LnkCnt
		set /a %%.LnkCnt += 1
		%&% %%.LnkCnt !%%.NSMeta!.LnkCnt

		%&% %%.SubNS !%%.NSMeta!.Lnk[!%%.LnkCnt!]

		%<-% _
	)
%-|%

:NS_Free NS -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.NS=!%~1!"
		%&% !%%.NS! %%.NSMeta

		%&% !%%.NSMeta!.RefCnt %%.RefCnt
		if !%%.RefCnt! gtr 0 (
			set /a %%.RefCnt -= 1
			%&% %%.RefCnt !%%.NSMeta!.RefCnt
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
				'set !%%.NS! ^& set !%%.NSMeta!'
			) do (
				set "%%i="
			)
		)

		%<-% _
	)
%-|%
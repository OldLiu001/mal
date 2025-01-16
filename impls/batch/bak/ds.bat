@echo off
if "%~1" neq "" (
	call %* || %?|% "Call '%~nx0' failed."
)
%-|%

:DS_New [_Type] -> DS
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Type=%~1"
		%|% NS New !%%.Type!Meta %->% %%.NS
		%|% NS New !%%.Type!Data %->% %%.NSData
		%|% NS Link !%%.NS! Data !%%.NSData!


	)
%-|%
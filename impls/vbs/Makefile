all:
	brew install --cask --no-quarantine wine@staging
	brew install winetricks
	WINEARCH=win32 winetricks -q wsh57
	WINEARCH=win32 winetricks -q dotnet35
	WINEARCH=win32 wine cmd /c echo hello,world
	WINEARCH=win32 wine cscript

clean:

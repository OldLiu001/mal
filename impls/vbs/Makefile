all:
	brew install wine winetricks
	wine winecfg
	winetricks -q wsh57
	winetricks -q dotnet35
	wine cmd /c echo hello,world
	wine cscript

clean:

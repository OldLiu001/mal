all:
	brew install --cask --no-quarantine wine@staging
	wine winecfg
	winetricks -q wsh57
	winetricks -q dotnet35
	wine cmd /c echo hello,world
	wine cscript

clean:

all:
	softwareupdate --install-rosetta --agree-to-license
	brew install --cask --no-quarantine wine@staging
	brew install --cask --no-quarantine winetricks
	wine winecfg
	winetricks -q wsh57
	winetricks -q dotnet35
	wine cmd /c echo hello,world
	wine cscript

clean:

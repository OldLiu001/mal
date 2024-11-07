all:
	brew install --cask --no-quarantine wine@staging
	brew install winetricks
	winetricks -q wsh57
	echo winetricks -q dotnet35
	wine cmd /c echo hello,world
	wine cscript

clean:

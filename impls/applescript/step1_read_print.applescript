use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

-- step1_read_print: 加载 types / reader / printer 模块
property typesLib : missing value
property readerLib : missing value
property printerLib : missing value



-- 动态加载模块: 优先已编译的 .scpt, 缺失时临时编译 .applescript 再加载
-- 这样 `osascript stepXxx.applescript` 可不经 make 直接运行
on loadMod(modName, scriptDir)
	set scptPath to scriptDir & "/" & modName & ".scpt"
	set srcPath to scriptDir & "/" & modName & ".applescript"
	if my fileExists(scptPath) then
		return load script (scptPath as POSIX file)
	else if my fileExists(srcPath) then
		set tmpPath to (do shell script "mktemp -t mal") & ".scpt"
		do shell script "osacompile -l AppleScript -o " & quoted form of tmpPath & " " & quoted form of srcPath
		return load script (tmpPath as POSIX file)
	else
		error "module not found: " & modName
	end if
end loadMod

on fileExists(p)
	try
		do shell script "test -f " & quoted form of p
		return true
	on error
		return false
	end try
end fileExists

on run()
	set scriptDir to do shell script "dirname " & quoted form of (POSIX path of (path to me))
	set typesLib to my loadMod("types", scriptDir)
	set readerLib to my loadMod("reader", scriptDir)
	set printerLib to my loadMod("printer", scriptDir)
	readerLib's setTypesLib(typesLib)

	repeat
		set inputText to readLine("user> ")
		if inputText is "" then exit repeat

		try
			set ast to readerLib's readString(inputText)
			set output to printerLib's Printer's pr_str(ast, true)
			log output
		on error errMsg number errNum
			log "Error: " & errMsg
		end try
	end repeat
end run

on readLine(prompt)
	local standardInput, standardOutput, inputText

	tell NSFileHandle of current application
		copy its fileHandleWithStandardInput to standardInput
		copy its fileHandleWithStandardOutput to standardOutput
	end tell

	standardOutput's writeData:(convertTextToNSData(prompt))
	set inputText to convertNSDataToText(standardInput's availableData())

	if length of inputText > 0 and character (length of inputText) of inputText is linefeed then
		set inputText to text 1 thru -2 of inputText
	end if

	return inputText
end readLine

to convertTextToNSString(inputText)
	return current application's NSString's stringWithString:inputText
end convertTextToNSString

to convertNSStringToText(inputNSString)
	return inputNSString as text
end convertNSStringToText

to convertNSStringToNSData(inputNSString)
	return inputNSString's dataUsingEncoding:(current application's NSUTF8StringEncoding)
end convertNSStringToNSData

to convertNSDataToNSString(inputNSData)
	tell current application
		return its NSString's alloc's initWithData:inputNSData encoding:its NSUTF8StringEncoding
	end
end convertNSDataToNSString

to convertTextToNSData(inputText)
	return convertNSStringToNSData(convertTextToNSString(inputText))
end convertTextToNSData

to convertNSDataToText(inputNSData)
	return convertNSStringToText(convertNSDataToNSString(inputNSData))
end convertNSDataToText

use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

-- step2_eval: 加载 types / reader / printer 模块
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
		set tmpPath to (current application's NSTemporaryDirectory() as text) & "mal_" & (current application's NSUUID's UUID()'s UUIDString()) & ".scpt"
		do shell script "osacompile -l AppleScript -o " & quoted form of tmpPath & " " & quoted form of srcPath
		return load script (tmpPath as POSIX file)
	else
		error "module not found: " & modName
	end if
end loadMod

on fileExists(p)
	set fm to current application's NSFileManager's defaultManager()
	return (fm's fileExistsAtPath:p) as boolean
end fileExists

on run()
	set scriptDir to (current application's NSString's stringWithString:(POSIX path of (path to me)))'s stringByDeletingLastPathComponent() as text
	set typesLib to my loadMod("types", scriptDir)
	set readerLib to my loadMod("reader", scriptDir)
	set printerLib to my loadMod("printer", scriptDir)
	readerLib's setTypesLib(typesLib)

	-- 初始化全局环境: + - * /
	set replEnv to makeReplEnv()
	repeat
		set inputText to readLine("user> ")
		if inputText is "" then exit repeat

		try
			set ast to readerLib's readString(inputText)
			set evalResult to evalMAL(ast, replEnv)
			set output to printerLib's Printer's pr_str(evalResult, true)
			log output
		on error errMsg number errNum
			log "Error: " & errMsg
		end try
	end repeat
end run

-- 创建全局 REPL 环境,绑定四个算术函数
on makeReplEnv()
	copy my Env to replEnv
	replEnv's setEnv("+", my makeMALFunction("+"))
	replEnv's setEnv("-", my makeMALFunction("-"))
	replEnv's setEnv("*", my makeMALFunction("*"))
	replEnv's setEnv("/", my makeMALFunction("/"))
	return replEnv
end makeReplEnv

-- 环境:符号名 -> MAL 对象 的映射
script Env
	prop keys : {}
	prop vals : {}
	on setEnv(k, v)
		set end of keys to k
		set end of vals to v
	end setEnv
	on getEnv(k)
		repeat with i from 1 to count of keys
			if item i of keys = k then
				return item i of vals
			end if
		end repeat
		error "'" & k & "' not found"
	end getEnv
end script

-- 通用算术函数工厂(step2: 仅二元算术)
on makeMALFunction(fnName)
	script MALFunction
		prop typeName : "function"
		prop funcName : fnName
		on apply(args)
			set firstVal to (item 1 of args)'s valueData
			set secondVal to (item 2 of args)'s valueData
			if funcName = "+" then
				set out to my typesLib's Types's makeMALNumber(firstVal + secondVal)
			else if funcName = "-" then
				set out to my typesLib's Types's makeMALNumber(firstVal - secondVal)
			else if funcName = "*" then
				set out to my typesLib's Types's makeMALNumber(firstVal * secondVal)
			else if funcName = "/" then
				set out to my typesLib's Types's makeMALNumber(firstVal div secondVal)
			end if
			return out
		end apply
	end script
	return MALFunction
end makeMALFunction

on evalMAL(ast, env)
	-- 符号: 查环境
	if ast's typeName = "symbol" then
		return env's getEnv(ast's valueData)
	-- 列表: 空列表返回自身,否则求值首元素为函数并应用到参数
	else if ast's typeName = "list" then
		set lstData to ast's valueData
		if (count of lstData) = 0 then
			return ast
		end if
		set fnObj to evalMAL(item 1 of lstData, env)
		set argList to {}
		repeat with i from 2 to count of lstData
			set end of argList to evalMAL(item i of lstData, env)
		end repeat
		return fnObj's apply(argList)
	-- 向量: 对每个元素求值
	else if ast's typeName = "vector" then
		set lstData to ast's valueData
		set newList to {}
		repeat with itemData in lstData
			set end of newList to evalMAL(itemData, env)
		end repeat
		return my typesLib's Types's makeMALVector(newList)
	-- 哈希表: 键不变,对值求值
	else if ast's typeName = "map" then
		set lstData to ast's valueData
		set newList to {}
		repeat with i from 1 to count of lstData
			if i mod 2 = 1 then
				set end of newList to item i of lstData
			else
				set end of newList to evalMAL(item i of lstData, env)
			end if
		end repeat
		return my typesLib's Types's makeMALMap(newList)
	-- 其他(数字/字符串/布尔/nil/函数): 原样返回
	else
		return ast
	end if
end evalMAL

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

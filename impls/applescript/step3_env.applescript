use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

-- step3_env: 加载 types / reader / printer 模块
property typesLib : missing value
property readerLib : missing value
property printerLib : missing value

on run()
	set scriptDir to do shell script "dirname " & quoted form of (POSIX path of (path to me))
	set typesLib to load script ((scriptDir & "/types.scpt") as POSIX file)
	set readerLib to load script ((scriptDir & "/reader.scpt") as POSIX file)
	set printerLib to load script ((scriptDir & "/printer.scpt") as POSIX file)
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

-- 环境: 符号名 -> MAL 对象,支持 outer 链
script Env
	prop keys : {}
	prop vals : {}
	prop outer : missing value
	on setOuter(o)
		set outer to o
	end setOuter
	on setEnv(k, v)
		considering case
			repeat with i from 1 to count of keys
				if item i of keys = k then
					set item i of vals to v
					return v
				end if
			end repeat
		end considering
		set end of keys to k
		set end of vals to v
		return v
	end setEnv
	on getEnv(k)
		considering case
			repeat with i from 1 to count of keys
				if item i of keys = k then
					return item i of vals
				end if
			end repeat
		end considering
		if outer is not missing value then
			return outer's getEnv(k)
		end if
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
	-- DEBUG-EVAL: 当 env 中有 DEBUG-EVAL 且值不是 nil/false 时打印
	try
		set debugVal to env's getEnv("DEBUG-EVAL")
		if debugVal's typeName is not "nil" and debugVal's typeName is not "false" then
			log "EVAL: " & printerLib's Printer's pr_str(ast, true)
		end if
	on error
		-- DEBUG-EVAL 未定义,忽略
	end try

	-- 符号: 查环境
	if ast's typeName = "symbol" then
		return env's getEnv(ast's valueData)
	-- 列表: 特殊形式或普通求值
	else if ast's typeName = "list" then
		set lstData to ast's valueData
		if (count of lstData) = 0 then
			return ast
		end if

		set firstForm to item 1 of lstData
		-- def!: (def! symbol value) -> 在当前环境绑定并返回 value
		if firstForm's typeName = "symbol" and (firstForm's valueData) = "def!" then
			set symName to (item 2 of lstData)'s valueData
			set valueObj to evalMAL(item 3 of lstData, env)
			return env's setEnv(symName, valueObj)
		-- let*: (let* (k1 v1 k2 v2 ...) body) 或 (let* [k1 v1 ...] body)
		else if firstForm's typeName = "symbol" and (firstForm's valueData) = "let*" then
			set bindingsObj to item 2 of lstData
			set bodyObj to item 3 of lstData
			copy my Env to newEnv
			newEnv's setOuter(env)
			set bindingList to bindingsObj's valueData
			repeat with i from 1 to (count of bindingList) by 2
				set keyName to (item i of bindingList)'s valueData
				set valObj to evalMAL(item (i + 1) of bindingList, newEnv)
				newEnv's setEnv(keyName, valObj)
			end repeat
			return evalMAL(bodyObj, newEnv)
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

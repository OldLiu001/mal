use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

script Reader
	prop tokenList : missing value
	prop currentPosition : 1

	on hasMoreTokens()
		return currentPosition ≤ (count of tokenList)
	end hasMoreTokens

	on peekToken()
		return (item currentPosition of tokenList)
	end peekToken

	on nextToken()
		set returnValue to (item currentPosition of tokenList)
		set currentPosition to (currentPosition + 1)
		return returnValue
	end nextToken

	on reset()
		set currentPosition to 1
	end reset
end script

on readString(inputString)
	copy Reader to tokenQueue
	set tokenQueue's tokenList to tokenizeInput(inputString)

	if tokenQueue's hasMoreTokens() then
		return readForm(tokenQueue)
	else
		return makeMALNil()
	end if
end readString

on readForm(tokenQueue)
	if not (tokenQueue's hasMoreTokens()) then
		return makeMALNil()
	end if

	set currentToken to tokenQueue's peekToken()

	if currentToken = "(" then
		tokenQueue's nextToken()
		return readList(tokenQueue, ")")
	else if currentToken = "[" then
		tokenQueue's nextToken()
		return readVector(tokenQueue, "]")
	else if currentToken = "{" then
		tokenQueue's nextToken()
		return readMap(tokenQueue, "}")
	else if currentToken = "'" then
		tokenQueue's nextToken()
		return makeMALList({makeMALSymbol("quote"), readForm(tokenQueue)})
	else if currentToken = "`" then
		tokenQueue's nextToken()
		return makeMALList({makeMALSymbol("quasiquote"), readForm(tokenQueue)})
	else if currentToken = "~" then
		tokenQueue's nextToken()
		return makeMALList({makeMALSymbol("unquote"), readForm(tokenQueue)})
	else if currentToken = "~@" then
		tokenQueue's nextToken()
		return makeMALList({makeMALSymbol("splice-unquote"), readForm(tokenQueue)})
	else if currentToken = "^" then
		tokenQueue's nextToken()
		set metaValue to readForm(tokenQueue)
		set valueValue to readForm(tokenQueue)
		return makeMALList({makeMALSymbol("with-meta"), valueValue, metaValue})
	else if currentToken = "@" then
		tokenQueue's nextToken()
		return makeMALList({makeMALSymbol("deref"), readForm(tokenQueue)})
	else
		return readAtom(tokenQueue)
	end if
end readForm

on readList(tokenQueue, endChar)
	set lst to {}
	repeat while tokenQueue's hasMoreTokens() and (tokenQueue's peekToken()) ≠ endChar
		set end of lst to readForm(tokenQueue)
	end repeat

	if tokenQueue's hasMoreTokens() and (tokenQueue's peekToken()) = endChar then
		tokenQueue's nextToken()
	else
		error "expected '" & endChar & "', got EOF"
	end if

	return makeMALList(lst)
end readList

on readVector(tokenQueue, endChar)
	set lst to {}
	repeat while tokenQueue's hasMoreTokens() and (tokenQueue's peekToken()) ≠ endChar
		set end of lst to readForm(tokenQueue)
	end repeat

	if tokenQueue's hasMoreTokens() and (tokenQueue's peekToken()) = endChar then
		tokenQueue's nextToken()
	else
		error "expected '" & endChar & "', got EOF"
	end if

	return makeMALVector(lst)
end readVector

on readMap(tokenQueue, endChar)
	set lst to {}
	repeat while tokenQueue's hasMoreTokens() and (tokenQueue's peekToken()) ≠ endChar
		set end of lst to readForm(tokenQueue)
		if tokenQueue's hasMoreTokens() then
			set end of lst to readForm(tokenQueue)
		else
			error "expected map value, got EOF"
		end if
	end repeat

	if tokenQueue's hasMoreTokens() and (tokenQueue's peekToken()) = endChar then
		tokenQueue's nextToken()
	else
		error "expected '" & endChar & "', got EOF"
	end if

	return makeMALMap(lst)
end readMap

on readAtom(tokenQueue)
	set token to tokenQueue's nextToken()

	-- Check if it's a string
	if character 1 of token = "\"" then
		if isClosedString(token) then
			return makeMALString(token)
		else
			error "expected '\"', got EOF"
		end if
	end if

	-- Check if it's a number
	try
		set num to token as number
		if (num as text) = token then
			return makeMALNumber(num)
		end if
	on error
		-- Not a number
	end try

	-- Check for keywords
	if (count of token) > 1 and character 1 of token = ":" then
		return makeMALKeyword(token)
	end if

	-- Check for boolean values
	if token = "true" then
		return makeMALTrue()
	else if token = "false" then
		return makeMALFalse()
	else if token = "nil" then
		return makeMALNil()
	end if

	-- It's a symbol
	return makeMALSymbol(token)
end readAtom

on tokenizeInput(inputString)
	-- Pattern to match tokens
	set patternString to "[\\s,]*(~@|[\\[\\]{}()'`~^@]|\"(?:\\\\.|[^\\\\\"])*\"?|;.*|[^\\s\\[\\]{}('\"`,;)]*)"
	set convertedNSString to convertTextToNSString(inputString)

	tell current application's NSRegularExpression's regularExpressionWithPattern:patternString options:0 |error|:missing value
		set matchRanges to its matchesInString:convertedNSString options:0 range:{location:0, |length|:(length of inputString)}
	end

	set extractedSubstrings to {}
	repeat with rangeResult in matchRanges
		if rangeResult's numberOfRanges() > 0 then
			set submatchString to convertedNSString's substringWithRange:(rangeResult's rangeAtIndex:1)

			tell current application's NSCharacterSet
				set trimmedString to submatchString's stringByTrimmingCharactersInSet:its whitespaceAndNewlineCharacterSet
			end

			copy convertNSStringToText(trimmedString) to trimmedText

			if trimmedText is not "" and character 1 of trimmedText is not ";" then
				copy trimmedText to end of extractedSubstrings
			end if
		end if
	end

	return extractedSubstrings
end tokenizeInput

on run()
	-- 初始化全局环境: + - * /
	set replEnv to makeReplEnv()
	repeat
		set inputText to readLine("user> ")
		if inputText is "" then exit repeat
		
		try
			set ast to readString(inputText)
			set evalResult to evalMAL(ast, replEnv)
			set output to pr_str(evalResult)
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
				set out to my makeMALNumber(firstVal + secondVal)
			else if funcName = "-" then
				set out to my makeMALNumber(firstVal - secondVal)
			else if funcName = "*" then
				set out to my makeMALNumber(firstVal * secondVal)
			else if funcName = "/" then
				set out to my makeMALNumber(firstVal div secondVal)
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
		return makeMALVector(newList)
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
		return makeMALMap(newList)
	-- 其他(数字/字符串/布尔/nil/函数): 原样返回
	else
		return ast
	end if
end evalMAL

on pr_str(malObject)
	if malObject is missing value then
		return ""
	end if
	
	set typeName to malObject's typeName
	
	if typeName = "symbol" then
		return malObject's valueData
	else if typeName = "keyword" then
		return malObject's valueData
	else if typeName = "nil" then
		return "nil"
	else if typeName = "true" then
		return "true"
	else if typeName = "false" then
		return "false"
	else if typeName = "number" then
		return malObject's valueData as text
	else if typeName = "string" then
		return malObject's valueData
	else if typeName = "list" then
		return "(" & pr_str_list(malObject's valueData) & ")"
	else if typeName = "vector" then
		return "[" & pr_str_list(malObject's valueData) & "]"
	else if typeName = "map" then
		return "{" & pr_str_list(malObject's valueData) & "}"
	else
		return "<unknown-type:" & typeName & ">"
	end if
end pr_str

on pr_str_list(lst)
	set out to ""
	repeat with itemData in lst
		if out is not "" then
			set out to out & " "
		end if
		set out to out & pr_str(itemData)
	end repeat
	return out
end pr_str_list

on isClosedString(token)
	set tokenLength to length of token
	if tokenLength < 2 then return false
	if character 1 of token ≠ "\"" then return false
	if character tokenLength of token ≠ "\"" then return false
	set i to tokenLength - 1
	set backslashCount to 0
	repeat while i ≥ 1 and character i of token = "\\"
		set backslashCount to backslashCount + 1
		set i to i - 1
	end repeat
	return (backslashCount mod 2 = 0)
end isClosedString

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

on makeMALAtom(inputValue)
	script MALAtom
		prop typeName : "atom"
		prop valueData : inputValue
	end script
	return MALAtom
end makeMALAtom

on makeMALNumber(inputValue)
	script MALNumber
		prop typeName : "number"
		prop valueData : inputValue
	end script
	return MALNumber
end makeMALNumber

on makeMALSymbol(inputValue)
	script MALSymbol
		prop typeName : "symbol"
		prop valueData : inputValue
	end script
	return MALSymbol
end makeMALSymbol

on makeMALKeyword(inputValue)
	script MALKeyword
		prop typeName : "keyword"
		prop valueData : inputValue
	end script
	return MALKeyword
end makeMALKeyword

on makeMALList(inputValue)
	script MALList
		prop typeName : "list"
		prop valueData : inputValue
	end script
	return MALList
end makeMALList

on makeMALVector(inputValue)
	script MALVector
		prop typeName : "vector"
		prop valueData : inputValue
	end script
	return MALVector
end makeMALVector

on makeMALMap(inputValue)
	script MALMap
		prop typeName : "map"
		prop valueData : inputValue
	end script
	return MALMap
end makeMALMap

on makeMALString(inputValue)
	script MALString
		prop typeName : "string"
		prop valueData : inputValue
	end script
	return MALString
end makeMALString

on makeMALNil()
	script MALNil
		prop typeName : "nil"
		prop valueData : "nil"
	end script
	return MALNil
end makeMALNil

on makeMALTrue()
	script MALTrue
		prop typeName : "true"
		prop valueData : "true"
	end script
	return MALTrue
end makeMALTrue

on makeMALFalse()
	script MALFalse
		prop typeName : "false"
		prop valueData : "false"
	end script
	return MALFalse
end makeMALFalse

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
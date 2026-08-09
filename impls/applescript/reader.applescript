use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

-- reader 模块: 依赖 types 模块(通过 setTypesLib 注入)
property typesLib : missing value

on setTypesLib(lib)
	set typesLib to lib
end setTypesLib

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
	copy my Reader to tokenQueue
	set tokenQueue's tokenList to tokenizeInput(inputString)

	if tokenQueue's hasMoreTokens() then
		return readForm(tokenQueue)
	else
		return my typesLib's Types's makeMALNil()
	end if
end readString

on readForm(tokenQueue)
	if not (tokenQueue's hasMoreTokens()) then
		return my typesLib's Types's makeMALNil()
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
		return my typesLib's Types's makeMALList({my typesLib's Types's makeMALSymbol("quote"), readForm(tokenQueue)})
	else if currentToken = "`" then
		tokenQueue's nextToken()
		return my typesLib's Types's makeMALList({my typesLib's Types's makeMALSymbol("quasiquote"), readForm(tokenQueue)})
	else if currentToken = "~" then
		tokenQueue's nextToken()
		return my typesLib's Types's makeMALList({my typesLib's Types's makeMALSymbol("unquote"), readForm(tokenQueue)})
	else if currentToken = "~@" then
		tokenQueue's nextToken()
		return my typesLib's Types's makeMALList({my typesLib's Types's makeMALSymbol("splice-unquote"), readForm(tokenQueue)})
	else if currentToken = "^" then
		tokenQueue's nextToken()
		set metaValue to readForm(tokenQueue)
		set valueValue to readForm(tokenQueue)
		return my typesLib's Types's makeMALList({my typesLib's Types's makeMALSymbol("with-meta"), valueValue, metaValue})
	else if currentToken = "@" then
		tokenQueue's nextToken()
		return my typesLib's Types's makeMALList({my typesLib's Types's makeMALSymbol("deref"), readForm(tokenQueue)})
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

	return my typesLib's Types's makeMALList(lst)
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

	return my typesLib's Types's makeMALVector(lst)
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

	return my typesLib's Types's makeMALMap(lst)
end readMap

on readAtom(tokenQueue)
	set token to tokenQueue's nextToken()

	-- Check if it's a string
	if character 1 of token = "\"" then
		if isClosedString(token) then
			return my typesLib's Types's makeMALString(unescapeString(token))
		else
			error "expected '\"', got EOF"
		end if
	end if

	-- Check if it's a number
	try
		set num to token as number
		if (num as text) = token then
			return my typesLib's Types's makeMALNumber(num)
		end if
	on error
		-- Not a number
	end try

	-- Check for keywords
	if (count of token) > 1 and character 1 of token = ":" then
		return my typesLib's Types's makeMALKeyword(token)
	end if

	-- Check for boolean values
	if token = "true" then
		return my typesLib's Types's makeMALTrue()
	else if token = "false" then
		return my typesLib's Types's makeMALFalse()
	else if token = "nil" then
		return my typesLib's Types's makeMALNil()
	end if

	-- It's a symbol
	return my typesLib's Types's makeMALSymbol(token)
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

-- 去掉首尾引号并解析转义序列,返回字符串内容
on unescapeString(token)
	set tokenLength to length of token
	if tokenLength < 2 then return ""
	set out to ""
	set i to 2
	repeat while i ≤ (tokenLength - 1)
		set ch to character i of token
		if ch = "\\" and i < (tokenLength - 1) then
			set nextCh to character (i + 1) of token
			if nextCh = "n" then
				set out to out & linefeed
			else if nextCh = "t" then
				set out to out & tab
			else if nextCh = "r" then
				set out to out & return
			else
				set out to out & nextCh
			end if
			set i to i + 2
		else
			set out to out & ch
			set i to i + 1
		end if
	end repeat
	return out
end unescapeString

-- Helper functions for string conversion
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

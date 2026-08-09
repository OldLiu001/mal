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
		return my makeMALNil()
	end if
end readString

on readForm(tokenQueue)
	if not (tokenQueue's hasMoreTokens()) then
		return my makeMALNil()
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
		return my makeMALList({my makeMALSymbol("quote"), readForm(tokenQueue)})
	else if currentToken = "`" then
		tokenQueue's nextToken()
		return my makeMALList({my makeMALSymbol("quasiquote"), readForm(tokenQueue)})
	else if currentToken = "~" then
		tokenQueue's nextToken()
		return my makeMALList({my makeMALSymbol("unquote"), readForm(tokenQueue)})
	else if currentToken = "~@" then
		tokenQueue's nextToken()
		return my makeMALList({my makeMALSymbol("splice-unquote"), readForm(tokenQueue)})
	else if currentToken = "^" then
		tokenQueue's nextToken()
		set metaValue to readForm(tokenQueue)
		set valueValue to readForm(tokenQueue)
		return my makeMALList({my makeMALSymbol("with-meta"), valueValue, metaValue})
	else if currentToken = "@" then
		tokenQueue's nextToken()
		return my makeMALList({my makeMALSymbol("deref"), readForm(tokenQueue)})
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

	return my makeMALList(lst)
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

	return my makeMALVector(lst)
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

	return my makeMALMap(lst)
end readMap

on readAtom(tokenQueue)
	set token to tokenQueue's nextToken()

	-- Check if it's a string
	if character 1 of token = "\"" then
		if isClosedString(token) then
			return my makeMALString(token)
		else
			error "expected '\"', got EOF"
		end if
	end if

	-- Check if it's a number
	try
		set num to token as number
		if (num as text) = token then
			return my makeMALNumber(num)
		end if
	on error
		-- Not a number
	end try

	-- Check for keywords
	if (count of token) > 1 and character 1 of token = ":" then
		return my makeMALKeyword(token)
	end if

	-- Check for boolean values
	if token = "true" then
		return my makeMALTrue()
	else if token = "false" then
		return my makeMALFalse()
	else if token = "nil" then
		return my makeMALNil()
	end if

	-- It's a symbol
	return my makeMALSymbol(token)
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

-- Helper functions for type creation
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
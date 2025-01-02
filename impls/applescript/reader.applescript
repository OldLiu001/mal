use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

on run
	global typeLibrary
	set typeLibrary to importLibrary("types")
	
	
	
	--assertTrue(False)
	log tokenizeInput("  (+ 1 2)  +_+_ =;2333 3+2")
	--log tokenizeInput2("  (+ 1 2)  +_+_ =;2333 3+2")
	log readString("  (+ 1 2)  +_+_ =;2333 3+2")
end

script Reader
	prop tokenList : missing value
	prop currentPosition : 1
	
	on hasMoreTokens()
		return currentPosition ≤ (count of tokenList)
	end
	
	on peekToken()
		return (item currentPosition of tokenList)
	end
	
	on nextToken()
	end
end

on readString(inputString)
	copy Reader to tokenQueue
	set tokenQueue's tokenList to tokenizeInput(inputString)
	
	return readForm(tokenQueue)
end

on readForm(tokenQueue)
	set currentToken to tokenQueue's peekToken()
	
	if currentToken = "(" or currentToken = "[" then
		return readListOrVector(tokenQueue)
	else if currentToken = "{" then
		return readMap(tokenQueue)
	else
		return readAtom(tokenQueue)
	end
end

on readAtom(tokenQueue)
	return 1
end

on readListOrVector(tokenQueue)
	return 2
end

on tokenizeInput(inputString)
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
			end
		end
	end
	
	return extractedSubstrings
end

to convertTextToNSString(inputText)
	return current application's NSString's stringWithString:inputText
end

to convertNSStringToText(inputNSString)
	return inputNSString as text
end

to assertTrue(inputBoolean)
	if not inputBoolean then
		error "Assertion failed"
	end
end

to importLibrary(fileName)
	local selfPath, parentPath, libPath
	set AppleScript's text item delimiters to ":"
	set selfPath to path to me as text
	set parentPath to item 1 thru -2 of every text item of selfPath as text
	set libPath to parentPath & ":" & fileName & ".scpt"
	return load script libPath as alias
end

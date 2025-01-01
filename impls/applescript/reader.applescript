use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

on run
	assertTrue(False)
	log tokenizeInput("  (+ 1 2)  +_+_ =;2333 3+2")
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
	return 1
end

on tokenizeInput(inputString)
	set patternString to "[\\s,]*(~@|[\\[\\]{}()'`~^@]|\"(?:\\\\.|[^\\\\\"])*\"?|;.*|[^\\s\\[\\]{}('\"`,;)]*)"
	set convertedNSString to convertTextToNSString(inputString)
	tell current application's NSRegularExpression's regularExpressionWithPattern:patternString options:0 |error|:missing value
		tell its matchesInString:convertedNSString options:0 range:{location:0, |length|:(length of inputString)}
			set matchRanges to its valueForKey:"range"
		end
	end
	set extractedSubstrings to {}
	repeat with substringRange in matchRanges
		copy convertNSStringToText(convertedNSString's substringWithRange:substringRange) to end of extractedSubstrings
	end repeat
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

use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

on run
	log tokenize("  (+ 1 2)  +_+_ =;2333 3+2")
end

script Reader
	prop tokens : missing value
	prop position : 0
	
	on peek()
	end
	
	on next()
	end
end

on readStr(inputString)
	
end

on findPattern(thePattern, theString)
	set theText to current application's NSString's stringWithString:theString
	set theRegEx to current application's NSRegularExpression's regularExpressionWithPattern:thePattern ¬
		options:0 |error|:(missing value)
	set theResult to (theRegEx's matchesInString:theText ¬
		options:0 ¬
		range:{location:0, |length|:theText's |length|})'s valueForKey:("range")
	
	set outputArray to {}
	repeat with thisRange in theResult
		copy (theText's substringWithRange:thisRange) as text to end of outputArray
	end repeat
	return outputArray
end findPattern:inString:

on tokenize(inputString)
	set regexPattern to "[\\s,]*(~@|[\\[\\]{}()'`~^@]|\"(?:\\\\.|[^\\\\\"])*\"?|;.*|[^\\s\\[\\]{}('\"`,;)]*)"
	log findPattern(regexPattern, inputString)
	return 123
	tell current application
		set regex to its NSRegularExpression's regularExpressionWithPattern:regexPattern options:its NSRegularExpressionCaseInsensitive |error|:missing value
	end
	--set regex to current application's NSRegularExpression's regularExpressionWithPattern:regexPattern options:(current application's NSRegularExpressionCaseInsensitive) |error|:(missing value)

	-- 执行匹配
	set matches to regex's matchesInString:inputString options:0 range:{0, length of inputString}

	-- 提取匹配结果
	log matches's |count|()
	log item 1 of matches
	set matchedEmails to {}
	repeat with match in matches
	--set range to match's range
	--set matchedString to (inputString's substringWithRange:range) as text
	--set end of matchedEmails to matchedString
	log class of match
	log match(123)
	end repeat

	-- 输出匹配结果
	display dialog "Matched emails: " & (matchedEmails as string)
end

on readForm()
	log 233
end


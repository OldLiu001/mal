use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

on readInput(inputMAL)
	return inputMAL
end

on evalInput(inputMAL)
	return inputMAL
end

on printInput(inputMAL)
	return inputMAL
end

on readEvalPrint(inputMAL)
	return printInput(evalInput(readInput(inputMAL)))
end

on run
	local standardInput, standardOutput
	tell NSFileHandle of current application
		copy its fileHandleWithStandardInput to standardInput
		copy its fileHandleWithStandardOutput to standardOutput
	end
	
	local inputText
	repeat
		standardOutput's writeData:covertTextToNSData("user> ")
		set inputText to convertNSDataToText(standardInput's availableData())
		if inputText = "" then exit
		standardOutput's writeData:covertTextToNSData(readEvalPrint(inputText))
	end
end

to convertTextToNSString(inputText)
	return current application's NSString's stringWithString:inputText
end

to convertNSStringToText(inputNSString)
	return inputNSString as text
end

to convertNSStringToNSData(inputNSString)
	return inputNSString's dataUsingEncoding:(current application's NSUTF8StringEncoding)
end

to convertNSDataToNSString(inputNSData)
	tell current application
		return its NSString's alloc's initWithData:inputNSData encoding:its NSUTF8StringEncoding
	end
end

to covertTextToNSData(inputText)
	return convertNSStringToNSData(convertTextToNSString(inputText))
end

to convertNSDataToText(inputNSData)
	return convertNSStringToText(convertNSDataToNSString(inputNSData))
end

use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

on read(mal)
	return mal
end

on eval(mal)
	return mal
end

on prt(mal)
	return mal
end

on rep(mal)
	return prt(eval(read(mal)))
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
		standardOutput's writeData:covertTextToNSData(rep(inputText))
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

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
	local reader
	set reader to importLibrary("reader")
	
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

to importLibrary(fileName)
	local selfPath, parentPath, libPath
	set AppleScript's text item delimiters to ":"
	set selfPath to path to me as text
	set parentPath to item 1 thru -2 of every text item of selfPath as text
	set libPath to parentPath & ":" & fileName & ".scpt"
	return load script libPath as alias
end

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

local stdIn, stdOut
copy fileHandleWithStandardInput of NSFileHandle of current application to stdIn
copy fileHandleWithStandardOutput of NSFileHandle of current application to stdOut
repeat
	stdOut's writeData:(current application's NSString's stringWithString:"user> ")'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
	set str to (current application's NSString's alloc's initWithData:(stdIn's availableData()) encoding:(current application's NSUTF8StringEncoding)) as text
	if str = "" then exit repeat
	stdOut's writeData:(current application's NSString's stringWithString:rep(str))'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
end

use AppleScript version "2.4"
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

to str_to_nsstr(str)
	return current application's NSString's stringWithString:str
end

to nsstr_to_nsdata(nsstr)
	return nsstr's dataUsingEncoding:(current application's NSUTF8StringEncoding)
end

to str_to_nsdata(str)
	return nsstr_to_nsdata(str_to_nsstr(str))
end

to nsdata_to_str(nsdata)
	tell current application
		return (its NSString's alloc's initWithData:nsdata encoding:(its NSUTF8StringEncoding)) as text
	end
end

on import from fileName
	set filePath to POSIX path of (path to me) as text & "/../" & fileName
	set fileObj to POSIX file filePath
	log fileObj
	log class of fileObj
	log 1
	set a to run script "on testhello()
	display dialog 233
	end
	return testhello"
	log a()
	log 2
end

on run
	(load script alias "Macintosh HD:Users:oldliu:Desktop:mal:impls:applescript:a.scpt")'s hello()
	
	local stdIn, stdOut
	tell NSFileHandle of current application
		copy its fileHandleWithStandardInput to stdIn
		copy its fileHandleWithStandardOutput to stdOut
	end
	
	repeat
		stdOut's writeData:str_to_nsdata("user> ")
		set str to nsdata_to_str(stdIn's availableData())
		if str = "" then exit
		stdOut's writeData:str_to_nsdata(rep(str))
	end
end

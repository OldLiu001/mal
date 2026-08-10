use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

-- core 模块: MAL 核心函数库, 通过 inject 注入外部依赖
property typesLib : missing value
property readerLib : missing value
property printerLib : missing value
property replEnvGlobal : missing value

on inject(types, reader, printer, replEnv)
	set typesLib to types
	set readerLib to reader
	set printerLib to printer
	set replEnvGlobal to replEnv
end inject

on coreArith(fnName, args)
	set firstVal to (item 1 of args)'s valueData
	set secondVal to (item 2 of args)'s valueData
	if fnName = "+" then
		set out to my typesLib's Types's makeMALNumber(firstVal + secondVal)
	else if fnName = "-" then
		set out to my typesLib's Types's makeMALNumber(firstVal - secondVal)
	else if fnName = "*" then
		set out to my typesLib's Types's makeMALNumber(firstVal * secondVal)
	else if fnName = "/" then
		set out to my typesLib's Types's makeMALNumber(firstVal div secondVal)
	end if
	return out
end coreArith


on coreCompare(fnName, args)
	set firstVal to (item 1 of args)'s valueData
	set secondVal to (item 2 of args)'s valueData
	if fnName = "<" then
		if firstVal < secondVal then
			return my typesLib's Types's makeMALTrue()
		else
			return my typesLib's Types's makeMALFalse()
		end if
	else if fnName = "<=" then
		if firstVal ≤ secondVal then
			return my typesLib's Types's makeMALTrue()
		else
			return my typesLib's Types's makeMALFalse()
		end if
	else if fnName = ">" then
		if firstVal > secondVal then
			return my typesLib's Types's makeMALTrue()
		else
			return my typesLib's Types's makeMALFalse()
		end if
	else if fnName = ">=" then
		if firstVal ≥ secondVal then
			return my typesLib's Types's makeMALTrue()
		else
			return my typesLib's Types's makeMALFalse()
		end if
	end if
	return my typesLib's Types's makeMALFalse()
end coreCompare

-- pr-str: 每个参数用 readably 打印,空格连接


on corePrStr(args)
	set out to ""
	set isFirst to true
	repeat with argObj in args
		if not isFirst then
			set out to out & " "
		end if
		set out to out & printerLib's Printer's pr_str(argObj, true)
		set isFirst to false
	end repeat
	return out
end corePrStr

-- str: 每个参数非 readably 打印,直接连接


on coreStr(args)
	set out to ""
	repeat with argObj in args
		set out to out & printerLib's Printer's pr_str(argObj, false)
	end repeat
	return out
end coreStr

-- println: 每个参数非 readably 打印,空格连接


on corePrintlnStr(args)
	set out to ""
	set isFirst to true
	repeat with argObj in args
		if not isFirst then
			set out to out & " "
		end if
		set out to out & printerLib's Printer's pr_str(argObj, false)
		set isFirst to false
	end repeat
	return out
end corePrintlnStr

-- 深度相等(用于 = )


on malEqual(a, b)
	if a is missing value or b is missing value then
		return (a is missing value and b is missing value)
	end if
	set ta to a's typeName
	set tb to b's typeName
	if ta = "number" and tb = "number" then
		return (a's valueData = b's valueData)
	end if
	if ta = "string" and tb = "string" then
		considering case
			return (a's valueData = b's valueData)
		end considering
	end if
	if ta = "symbol" and tb = "symbol" then
		considering case
			return (a's valueData = b's valueData)
		end considering
	end if
	if ta = "keyword" and tb = "keyword" then
		considering case
			return (a's valueData = b's valueData)
		end considering
	end if
	if (ta = "nil" and tb = "nil") or (ta = "true" and tb = "true") or (ta = "false" and tb = "false") then
		return true
	end if
	-- list 与 vector 互比: 元素逐项比较
	if (ta = "list" or ta = "vector") and (tb = "list" or tb = "vector") then
		set la to a's valueData
		set lb to b's valueData
		if (count of la) ≠ (count of lb) then return false
		repeat with i from 1 to count of la
			if not my malEqual(item i of la, item i of lb) then
				return false
			end if
		end repeat
		return true
	end if
	-- map 比较: 键值对逐项
	if ta = "map" and tb = "map" then
		set la to a's valueData
		set lb to b's valueData
		if (count of la) ≠ (count of lb) then return false
		-- 无序比较: la 的每个键值对都必须在 lb 中找到
		repeat with i from 1 to (count of la) by 2
			set foundPair to false
			repeat with j from 1 to (count of lb) by 2
				if my malEqual(item i of la, item j of lb) and my malEqual(item (i + 1) of la, item (j + 1) of lb) then
					set foundPair to true
					exit repeat
				end if
			end repeat
			if not foundPair then return false
		end repeat
		return true
	end if
	return false
end malEqual

-- 特殊形式判断: 符号且区分大小写等于 name


on boolResult(flag)
	if flag then
		return my typesLib's Types's makeMALTrue()
	else
		return my typesLib's Types's makeMALFalse()
	end if
end boolResult

-- map 键值更新(键相等则替换,否则追加)


on mapSet(mapData, keyObj, valObj)
	set outData to {}
	set replaced to false
	repeat with i from 1 to (count of mapData) by 2
		if my malEqual(item i of mapData, keyObj) then
			set end of outData to keyObj
			set end of outData to valObj
			set replaced to true
		else
			set end of outData to item i of mapData
			set end of outData to item (i + 1) of mapData
		end if
	end repeat
	if not replaced then
		set end of outData to keyObj
		set end of outData to valObj
	end if
	return outData
end mapSet

-- map 键删除


on mapRemove(mapData, keyObj)
	set outData to {}
	repeat with i from 1 to (count of mapData) by 2
		if not my malEqual(item i of mapData, keyObj) then
			set end of outData to item i of mapData
			set end of outData to item (i + 1) of mapData
		end if
	end repeat
	return outData
end mapRemove

-- apply: (apply f a b (list c d)) -> 调用 f(a b c d)


on coreConj(args)
	set coll to item 1 of args
	set collT to coll's typeName
	if collT = "nil" then
		set out to {}
		repeat with i from 2 to (count of args)
			set end of out to item i of args
		end repeat
		return my typesLib's Types's makeMALList(reverse of out)
	else if collT = "list" then
		set out to coll's valueData
		repeat with i from 2 to (count of args)
			set out to {item i of args} & out
		end repeat
		return my typesLib's Types's makeMALList(out)
	else if collT = "vector" then
		set out to coll's valueData
		repeat with i from 2 to (count of args)
			set end of out to item i of args
		end repeat
		return my typesLib's Types's makeMALVector(out)
	else
		error "conj: not a collection"
	end if
end coreConj

-- seq: (seq coll) nil/"" -> nil; string -> 字符列表; list/vector -> 列表; map -> [k v] 列表


on coreSeq(sObj)
	set seqT to sObj's typeName
	if seqT = "nil" then
		return my typesLib's Types's makeMALNil()
	else if seqT = "string" then
		if (count of sObj's valueData) = 0 then
			return my typesLib's Types's makeMALNil()
		end if
		set charList to {}
		repeat with ch in sObj's valueData
			set end of charList to my typesLib's Types's makeMALString(ch as text)
		end repeat
		return my typesLib's Types's makeMALList(charList)
	else if seqT = "list" then
		if (count of sObj's valueData) = 0 then
			return my typesLib's Types's makeMALNil()
		end if
		return my typesLib's Types's makeMALList(sObj's valueData)
	else if seqT = "vector" then
		if (count of sObj's valueData) = 0 then
			return my typesLib's Types's makeMALNil()
		end if
		return my typesLib's Types's makeMALList(sObj's valueData)
	else if seqT = "map" then
		set pairList to {}
		set md to sObj's valueData
		repeat with i from 1 to (count of md) by 2
			set pair to my typesLib's Types's makeMALVector({item i of md, item (i + 1) of md})
			set end of pairList to pair
		end repeat
		return my typesLib's Types's makeMALList(pairList)
	else
		return my typesLib's Types's makeMALNil()
	end if
end coreSeq

-- readline: 带提示从 stdin 读取一行(供 core 函数 readline 使用)


on coreReadLine(prompt)
	local standardInput, standardOutput, inputText
	tell NSFileHandle of current application
		copy its fileHandleWithStandardInput to standardInput
		copy its fileHandleWithStandardOutput to standardOutput
	end tell
	standardOutput's writeData:(convertTextToNSData(prompt))
	set inputText to convertNSDataToText(standardInput's availableData())
	if length of inputText > 0 and character (length of inputText) of inputText is linefeed then
		set inputText to text 1 thru -2 of inputText
	end if
	return inputText
end coreReadLine

-- with-meta: 拷贝对象并附上元数据(类型/值不变)


on isSymList(obj, symName)
	if obj's typeName ≠ "list" then return false
	set objData to obj's valueData
	if (count of objData) < 1 then return false
	set firstObj to item 1 of objData
	if (firstObj's typeName) ≠ "symbol" then return false
	if (firstObj's valueData) = symName then
		return true
	else
		return false
	end if
end isSymList

-- quasiquote: 展开为用 cons/concat/vec/quote 构建的表达式


on quasiquote(ast)
	if ast's typeName = "map" or ast's typeName = "symbol" then
		return my typesLib's Types's makeMALList({my typesLib's Types's makeMALSymbol("quote"), ast})
	else if ast's typeName = "vector" then
		return my typesLib's Types's makeMALList({my typesLib's Types's makeMALSymbol("vec"), qqFoldr(ast's valueData)})
	else if ast's typeName = "list" then
		if isSymList(ast, "unquote") then
			return item 2 of (ast's valueData)
		end if
		return qqFoldr(ast's valueData)
	else
		return ast
	end if
end quasiquote

-- qqFoldr: 从右向左折叠


on qqFoldr(forms)
	set acc to my typesLib's Types's makeMALList({})
	set formCount to count of forms
	repeat with i from formCount to 1 by -1
		set elt to item i of forms
		if isSymList(elt, "splice-unquote") then
			set acc to my typesLib's Types's makeMALList({my typesLib's Types's makeMALSymbol("concat"), item 2 of (elt's valueData), acc})
		else
			set acc to my typesLib's Types's makeMALList({my typesLib's Types's makeMALSymbol("cons"), quasiquote(elt), acc})
		end if
	end repeat
	return acc
end qqFoldr


on readLine(prompt)
	local standardInput, standardOutput, inputText

	tell NSFileHandle of current application
		copy its fileHandleWithStandardInput to standardInput
		copy its fileHandleWithStandardOutput to standardOutput
	end tell

	standardOutput's writeData:(convertTextToNSData(prompt))
	set inputText to convertNSDataToText(standardInput's availableData())

	if length of inputText > 0 and character (length of inputText) of inputText is linefeed then
		set inputText to text 1 thru -2 of inputText
	end if

	return inputText
end readLine


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

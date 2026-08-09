use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

-- step9_try: 加载 types / reader / printer 模块
property typesLib : missing value
property readerLib : missing value
property printerLib : missing value
property replEnvGlobal : missing value
property malErrorStack : {}

-- 安全弹出错误栈最后一个元素(单元素时清空,避免 items 1 thru -2 报错)
on popMalErrorStack()
	if (count of my malErrorStack) > 0 then
		if (count of my malErrorStack) = 1 then
			set my malErrorStack to {}
		else
			set my malErrorStack to items 1 thru -2 of my malErrorStack
		end if
	end if
end popMalErrorStack

on run(argv)
	set scriptDir to do shell script "dirname " & quoted form of (POSIX path of (path to me))
	set typesLib to load script ((scriptDir & "/types.scpt") as POSIX file)
	set readerLib to load script ((scriptDir & "/reader.scpt") as POSIX file)
	set printerLib to load script ((scriptDir & "/printer.scpt") as POSIX file)
	readerLib's setTypesLib(typesLib)

	-- 初始化全局环境: core 函数 + 语言定义函数
	set replEnv to makeReplEnv()
	set replEnvGlobal to replEnv
	-- (def! not (fn* (a) (if a false true)))
	rep("(def! not (fn* (a) (if a false true)))", replEnv)
	-- (def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) "\nnil)")))))
	rep("(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\nnil)\")))))", replEnv)
	-- (defmacro! cond ...)
	rep("(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))", replEnv)
	-- *host-language*: stepA 测试要求该变量被定义(不抛错即可)
	replEnv's setEnv("*host-language*", my typesLib's Types's makeMALString("applescript"))

	-- 处理命令行参数: 若有,则作为 *ARGV* 并加载第一个文件
	set argvList to {}
	repeat with argItem in argv
		set end of argvList to my typesLib's Types's makeMALString(argItem as text)
	end repeat
	replEnv's setEnv("*ARGV*", my typesLib's Types's makeMALList(argvList))

	if (count of argvList) > 0 then
		rep("(load-file \"" & ((item 1 of argvList)'s valueData) & "\")", replEnv)
		return
	end if

	repeat
		set inputText to readLine("user> ")
		if inputText is "" then exit repeat

		try
			set ast to readerLib's readString(inputText)
			set evalResult to evalMAL(ast, replEnv)
			set output to printerLib's Printer's pr_str(evalResult, true)
			log output
		on error errMsg number errNum
			if errNum = 5001 then
				-- 弹出 MAL 异常对象并清理
				my popMalErrorStack()
			end if
			log "Error: " & errMsg
		end try
	end repeat
end run

-- 创建全局 REPL 环境,绑定 core 函数
on makeReplEnv()
	copy my Env to replEnv
	set coreNames to {"+", "-", "*", "/", "=", "<", "<=", ">", ">=", "list", "list?", "empty?", "count", "pr-str", "str", "prn", "println", "read-string", "slurp", "eval", "atom", "atom?", "deref", "reset!", "swap!", "cons", "concat", "vec", "nth", "first", "rest", "macro?", "throw", "nil?", "true?", "false?", "symbol?", "keyword?", "vector?", "map?", "sequential?", "symbol", "keyword", "vector", "hash-map", "assoc", "dissoc", "get", "contains?", "keys", "vals", "apply", "map", "conj", "fn?", "number?", "string?", "readline", "seq", "time-ms", "meta", "with-meta"}
	repeat with coreName in coreNames
		replEnv's setEnv(coreName as text, my makeMALFunction(coreName as text))
	end repeat
	return replEnv
end makeReplEnv

-- 用 MAL 语言本身定义 not
on rep(inputString, replEnv)
	set ast to readerLib's readString(inputString)
	set evalResult to evalMAL(ast, replEnv)
	return printerLib's Printer's pr_str(evalResult, true)
end rep

-- 环境: 符号名 -> MAL 对象,支持 outer 链
script Env
	prop keys : {}
	prop vals : {}
	prop outer : missing value
	on setOuter(o)
		set outer to o
	end setOuter
	on setEnv(k, v)
		considering case
			repeat with i from 1 to count of keys
				if item i of keys = k then
					set item i of vals to v
					return v
				end if
			end repeat
		end considering
		set end of keys to k
		set end of vals to v
		return v
	end setEnv
	on getEnv(k)
		considering case
			repeat with i from 1 to count of keys
				if item i of keys = k then
					return item i of vals
				end if
			end repeat
		end considering
		if outer is not missing value then
			return outer's getEnv(k)
		end if
		error "'" & k & "' not found"
	end getEnv
	-- 无异常查询: 找到返回 true,否则 false(不抛错)
	on hasEnv(k)
		considering case
			repeat with i from 1 to count of keys
				if item i of keys = k then
					return true
				end if
			end repeat
		end considering
		if outer is not missing value then
			return outer's hasEnv(k)
		end if
		return false
	end hasEnv
	-- 绑定参数列表: binds 是符号名列表, exprs 是实参 MAL 对象
	-- 支持 & rest: 绑定后的剩余参数打包成 list
	on setBinds(binds, exprs)
		set i to 1
		set bindCount to count of binds
		set exprCount to count of exprs
		repeat while i ≤ bindCount
			set bindName to item i of binds
			if bindName = "&" then
				set restName to item (i + 1) of binds
				set restList to {}
				repeat with j from i to exprCount
					set end of restList to item j of exprs
				end repeat
				my setEnv(restName, my typesLib's Types's makeMALList(restList))
				set i to bindCount + 1
			else
				if i ≤ exprCount then
					my setEnv(bindName, item i of exprs)
				end if
				set i to i + 1
			end if
		end repeat
		return exprs
	end setBinds
end script

-- core 函数工厂(step4): 按 fnName 分发到对应实现
on makeMALFunction(fnName)
		script MALFunction
			prop typeName : "function"
			prop isUser : false
			prop isMacro : false
			prop funcName : fnName
			prop metaData : missing value
			on apply(args)
				return my dispatchCore(funcName, args)
			end apply
		end script
	return MALFunction
end makeMALFunction

-- 用户自定义函数: (fn* (parm...) body)
on makeMALUserFunction(parmObj, bodyObj, fnEnv)
	script MALUserFunction
		prop typeName : "function"
		prop isUser : true
		prop isMacro : false
		prop parmList : parmObj's valueData
		prop bodyValue : bodyObj
		prop closureEnv : fnEnv
		prop metaData : missing value
	end script
	return MALUserFunction
end makeMALUserFunction

-- 将用户函数标记为宏(返回拷贝,不修改原函数)
on setMacroFlag(fnObj)
	if fnObj's isUser is true then
		script MALUserFunction
			prop typeName : "function"
			prop isUser : true
			prop isMacro : true
			prop parmList : fnObj's parmList
			prop bodyValue : fnObj's bodyValue
			prop closureEnv : fnObj's closureEnv
			prop metaData : fnObj's metaData
		end script
		return MALUserFunction
	else
		script MALFunction
			prop typeName : "function"
			prop isUser : false
			prop isMacro : true
			prop funcName : fnObj's funcName
			prop metaData : fnObj's metaData
			on apply(args)
				return my dispatchCore(funcName, args)
			end apply
		end script
		return MALFunction
	end if
end setMacroFlag

-- core 函数分发
on dispatchCore(fnName, args)
	if fnName = "+" or fnName = "-" or fnName = "*" or fnName = "/" then
		return my coreArith(fnName, args)
	else if fnName = "=" then
		if my malEqual(item 1 of args, item 2 of args) then
			return my typesLib's Types's makeMALTrue()
		else
			return my typesLib's Types's makeMALFalse()
		end if
	else if fnName = "<" or fnName = "<=" or fnName = ">" or fnName = ">=" then
		return my coreCompare(fnName, args)
	else if fnName = "list" then
		return my typesLib's Types's makeMALList(args)
	else if fnName = "list?" then
		if (item 1 of args)'s typeName = "list" then
			return my typesLib's Types's makeMALTrue()
		else
			return my typesLib's Types's makeMALFalse()
		end if
	else if fnName = "empty?" then
		set target to item 1 of args
		if target's typeName = "list" or target's typeName = "vector" then
			if (count of target's valueData) = 0 then
				return my typesLib's Types's makeMALTrue()
			else
				return my typesLib's Types's makeMALFalse()
			end if
		else
			return my typesLib's Types's makeMALFalse()
		end if
	else if fnName = "count" then
		set target to item 1 of args
		if target's typeName = "nil" then
			return my typesLib's Types's makeMALNumber(0)
		else if target's typeName = "list" or target's typeName = "vector" then
			return my typesLib's Types's makeMALNumber(count of target's valueData)
		else
			return my typesLib's Types's makeMALNumber(0)
		end if
	else if fnName = "pr-str" then
		return my typesLib's Types's makeMALString(my corePrStr(args))
	else if fnName = "str" then
		return my typesLib's Types's makeMALString(my coreStr(args))
	else if fnName = "prn" then
		log my corePrStr(args)
		return my typesLib's Types's makeMALNil()
	else if fnName = "println" then
		log my corePrintlnStr(args)
		return my typesLib's Types's makeMALNil()
	else if fnName = "read-string" then
		return readerLib's readString((item 1 of args)'s valueData)
	else if fnName = "slurp" then
		set filePath to (item 1 of args)'s valueData
		set fileNSString to current application's NSString's stringWithContentsOfFile:filePath encoding:(current application's NSUTF8StringEncoding) |error|:missing value
		if fileNSString is missing value then
			error "slurp: cannot open '" & filePath & "'"
		end if
		return my typesLib's Types's makeMALString(fileNSString as text)
	else if fnName = "eval" then
		return evalMAL(item 1 of args, my replEnvGlobal)
	else if fnName = "cons" then
		set consItem to item 1 of args
		set consList to (item 2 of args)'s valueData
		return my typesLib's Types's makeMALList({consItem} & consList)
	else if fnName = "concat" then
		set concatOut to {}
		repeat with lstObj in args
			set concatOut to concatOut & (lstObj's valueData)
		end repeat
		return my typesLib's Types's makeMALList(concatOut)
	else if fnName = "vec" then
		set vecSrc to item 1 of args
		if vecSrc's typeName = "vector" then
			return vecSrc
		else
			return my typesLib's Types's makeMALVector(vecSrc's valueData)
		end if
	else if fnName = "nth" then
		set nthList to (item 1 of args)'s valueData
		set nthIndex to (item 2 of args)'s valueData
		if nthIndex < (count of nthList) then
			return item (nthIndex + 1) of nthList
		else
			error "nth: index out of range"
		end if
	else if fnName = "first" then
		set firstTarget to item 1 of args
		if firstTarget's typeName = "nil" then
			return my typesLib's Types's makeMALNil()
		end if
		set firstList to firstTarget's valueData
		if (count of firstList) > 0 then
			return item 1 of firstList
		else
			return my typesLib's Types's makeMALNil()
		end if
	else if fnName = "rest" then
		set restTarget to item 1 of args
		if restTarget's typeName = "nil" then
			return my typesLib's Types's makeMALList({})
		end if
		set restList to restTarget's valueData
		if (count of restList) > 1 then
			set restOut to {}
			repeat with i from 2 to (count of restList)
				set end of restOut to item i of restList
			end repeat
			return my typesLib's Types's makeMALList(restOut)
		else
			return my typesLib's Types's makeMALList({})
		end if
	else if fnName = "macro?" then
		set macroTarget to item 1 of args
		if macroTarget's typeName = "function" and macroTarget's isUser is true and macroTarget's isMacro is true then
			return my typesLib's Types's makeMALTrue()
		else
			return my typesLib's Types's makeMALFalse()
		end if
	else if fnName = "atom" then
		return my typesLib's Types's makeMALAtom(item 1 of args)
	else if fnName = "atom?" then
		if (item 1 of args)'s typeName = "atom" then
			return my typesLib's Types's makeMALTrue()
		else
			return my typesLib's Types's makeMALFalse()
		end if
	else if fnName = "deref" then
		return (item 1 of args)'s valueData
	else if fnName = "reset!" then
		set (item 1 of args)'s valueData to item 2 of args
		return item 2 of args
	else if fnName = "swap!" then
		set atm to item 1 of args
		set swapFn to item 2 of args
		-- 构造参数: (旧值) + 剩余参数
		set swapArgs to {atm's valueData}
		repeat with i from 3 to (count of args)
			set end of swapArgs to item i of args
		end repeat
		-- 调用 swapFn(用户函数或内建)
		if swapFn's isUser is true then
			copy my Env to swapEnv
			swapEnv's setOuter(swapFn's closureEnv)
			set parmNames to {}
			repeat with parmObj in swapFn's parmList
				set end of parmNames to parmObj's valueData
			end repeat
			swapEnv's setBinds(parmNames, swapArgs)
			set newVal to evalMAL(swapFn's bodyValue, swapEnv)
		else
			set newVal to swapFn's apply(swapArgs)
		end if
		set atm's valueData to newVal
		return newVal
	else if fnName = "throw" then
		set throwVal to item 1 of args
		set end of my malErrorStack to throwVal
		if throwVal's typeName = "string" then
			error (throwVal's valueData) number 5001
		else
			error (printerLib's Printer's pr_str(throwVal, true)) number 5001
		end if
	else if fnName = "nil?" then
		return my boolResult((item 1 of args)'s typeName = "nil")
	else if fnName = "true?" then
		return my boolResult((item 1 of args)'s typeName = "true")
	else if fnName = "false?" then
		return my boolResult((item 1 of args)'s typeName = "false")
	else if fnName = "symbol?" then
		return my boolResult((item 1 of args)'s typeName = "symbol")
	else if fnName = "keyword?" then
		return my boolResult((item 1 of args)'s typeName = "keyword")
	else if fnName = "vector?" then
		return my boolResult((item 1 of args)'s typeName = "vector")
	else if fnName = "map?" then
		return my boolResult((item 1 of args)'s typeName = "map")
	else if fnName = "sequential?" then
		set seqType to (item 1 of args)'s typeName
		return my boolResult(seqType = "list" or seqType = "vector")
	else if fnName = "symbol" then
		set symText to (item 1 of args)'s valueData
		if character 1 of symText = "\"" then
			set symText to text 2 thru -2 of symText
		end if
		return my typesLib's Types's makeMALSymbol(symText)
	else if fnName = "keyword" then
		set kwText to (item 1 of args)'s valueData
		if character 1 of kwText = "\"" then
			set kwText to text 2 thru -2 of kwText
		end if
		if character 1 of kwText ≠ ":" then
			set kwText to ":" & kwText
		end if
		return my typesLib's Types's makeMALKeyword(kwText)
	else if fnName = "vector" then
		return my typesLib's Types's makeMALVector(args)
	else if fnName = "hash-map" then
		return my typesLib's Types's makeMALMap(args)
	else if fnName = "assoc" then
		set mapData to (item 1 of args)'s valueData
		set newMap to mapData
		repeat with i from 2 to (count of args) by 2
			set newMap to my mapSet(newMap, item i of args, item (i + 1) of args)
		end repeat
		return my typesLib's Types's makeMALMap(newMap)
	else if fnName = "dissoc" then
		set mapData to (item 1 of args)'s valueData
		set newMap to mapData
		repeat with i from 2 to (count of args)
			set newMap to my mapRemove(newMap, item i of args)
		end repeat
		return my typesLib's Types's makeMALMap(newMap)
	else if fnName = "get" then
		set getTarget to item 1 of args
		if getTarget's typeName = "nil" then
			return my typesLib's Types's makeMALNil()
		end if
		set mapData to getTarget's valueData
		set keyObj to item 2 of args
		repeat with i from 1 to (count of mapData) by 2
			if my malEqual(item i of mapData, keyObj) then
				return item (i + 1) of mapData
			end if
		end repeat
		return my typesLib's Types's makeMALNil()
	else if fnName = "contains?" then
		set mapData to (item 1 of args)'s valueData
		set keyObj to item 2 of args
		repeat with i from 1 to (count of mapData) by 2
			if my malEqual(item i of mapData, keyObj) then
				return my typesLib's Types's makeMALTrue()
			end if
		end repeat
		return my typesLib's Types's makeMALFalse()
	else if fnName = "keys" then
		set mapData to (item 1 of args)'s valueData
		set keyList to {}
		repeat with i from 1 to (count of mapData) by 2
			set end of keyList to item i of mapData
		end repeat
		return my typesLib's Types's makeMALList(keyList)
	else if fnName = "vals" then
		set mapData to (item 1 of args)'s valueData
		set valList to {}
		repeat with i from 2 to (count of mapData) by 2
			set end of valList to item i of mapData
		end repeat
		return my typesLib's Types's makeMALList(valList)
	else if fnName = "apply" then
		return my coreApply(args)
	else if fnName = "map" then
		return my coreMapFn(args)
	else if fnName = "conj" then
		return my coreConj(args)
	else if fnName = "fn?" then
		set fnObj to item 1 of args
		if fnObj's typeName = "function" and fnObj's isMacro is false then
			return my typesLib's Types's makeMALTrue()
		else
			return my typesLib's Types's makeMALFalse()
		end if
	else if fnName = "number?" then
		return my boolResult((item 1 of args)'s typeName = "number")
	else if fnName = "string?" then
		return my boolResult((item 1 of args)'s typeName = "string")
	else if fnName = "readline" then
		set rlprompt to (item 1 of args)'s valueData
		return my typesLib's Types's makeMALString(my coreReadLine(rlprompt))
	else if fnName = "seq" then
		return my coreSeq(item 1 of args)
	else if fnName = "time-ms" then
		set nowDate to current application's NSDate's |date|()
		set secs to (nowDate's timeIntervalSince1970) as real
		set msVal to secs * 1000
		return my typesLib's Types's makeMALNumber(msVal)
	else if fnName = "meta" then
		set mObj to item 1 of args
		set mt to mObj's metaData
		if mt is missing value then
			return my typesLib's Types's makeMALNil()
		else
			return mt
		end if
	else if fnName = "with-meta" then
		return my withMetaHelper(item 1 of args, item 2 of args)
	end if
	error "'" & fnName & "' not found"
end dispatchCore

-- 布尔结果辅助
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
on coreApply(args)
	set applyFn to item 1 of args
	-- 收集前几个参数 + 最后一个 list/vector 展开
	set applyArgs to {}
	set argCount to count of args
	repeat with i from 2 to (argCount - 1)
		set end of applyArgs to item i of args
	end repeat
	set lastArg to item argCount of args
	set lastList to lastArg's valueData
	repeat with lastItem in lastList
		set end of applyArgs to lastItem
	end repeat
	return my callFunction(applyFn, applyArgs)
end coreApply

-- map: (map f coll) -> 对每个元素调用 f
on coreMapFn(args)
	set mapFn to item 1 of args
	set collList to (item 2 of args)'s valueData
	set outList to {}
	repeat with elemObj in collList
		set end of outList to my callFunction(mapFn, {elemObj})
	end repeat
	return my typesLib's Types's makeMALList(outList)
end coreMapFn

-- conj: (conj coll & xs) 列表前插,矢量后追, nil 视为空列表
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
on withMetaHelper(obj, m)
	set t to obj's typeName
	if t = "function" then
		if obj's isUser is true then
			script MALUserFunction
				prop typeName : "function"
				prop isUser : true
				prop isMacro : obj's isMacro
				prop parmList : obj's parmList
				prop bodyValue : obj's bodyValue
				prop closureEnv : obj's closureEnv
				prop metaData : m
			end script
			return MALUserFunction
		else
			script MALFunction
				prop typeName : "function"
				prop isUser : false
				prop funcName : obj's funcName
				prop metaData : m
				on apply(args)
					return my dispatchCore(funcName, args)
				end apply
			end script
			return MALFunction
		end if
	else if t = "list" then
		set newObj to my typesLib's Types's makeMALList(obj's valueData)
	else if t = "vector" then
		set newObj to my typesLib's Types's makeMALVector(obj's valueData)
	else if t = "map" then
		set newObj to my typesLib's Types's makeMALMap(obj's valueData)
	else if t = "string" then
		set newObj to my typesLib's Types's makeMALString(obj's valueData)
	else if t = "symbol" then
		set newObj to my typesLib's Types's makeMALSymbol(obj's valueData)
	else if t = "keyword" then
		set newObj to my typesLib's Types's makeMALKeyword(obj's valueData)
	else if t = "number" then
		set newObj to my typesLib's Types's makeMALNumber(obj's valueData)
	else
		return obj
	end if
	set newObj's metaData to m
	return newObj
end withMetaHelper

-- 调用任意函数(用户/宏/内建),参数已求值
on callFunction(fnObj, callArgs)
	if fnObj's isUser is true then
		copy my Env to callEnv
		callEnv's setOuter(fnObj's closureEnv)
		set parmNames to {}
		repeat with parmObj in fnObj's parmList
			set end of parmNames to parmObj's valueData
		end repeat
		callEnv's setBinds(parmNames, callArgs)
		return evalMAL(fnObj's bodyValue, callEnv)
	else
		return fnObj's apply(callArgs)
	end if
end callFunction

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
on isSpecialForm(firstForm, name)
	if firstForm's typeName ≠ "symbol" then return false
	considering case
		return (firstForm's valueData) = name
	end considering
end isSpecialForm

on evalMAL(ast, env)
	-- TCO 主循环: 尾位置(特殊形式 body、用户函数 body)不递归,
	-- 而是更新 ast/env 后 continue 循环
	repeat
		-- DEBUG-EVAL: 当 env 中有 DEBUG-EVAL 且值不是 nil/false 时打印
		if env's hasEnv("DEBUG-EVAL") then
			set debugVal to env's getEnv("DEBUG-EVAL")
			if debugVal's typeName is not "nil" and debugVal's typeName is not "false" then
				log "EVAL: " & printerLib's Printer's pr_str(ast, true)
			end if
		end if

		-- 符号: 查环境
		if ast's typeName = "symbol" then
			return env's getEnv(ast's valueData)
		-- 列表: 特殊形式或普通求值
		else if ast's typeName = "list" then
			set lstData to ast's valueData
			if (count of lstData) = 0 then
				return ast
			end if

			set firstForm to item 1 of lstData
			-- 快速判断: 仅当首元素是符号时才进入特殊形式分支(大小写敏感)
			set isSpecial to false
			if firstForm's typeName = "symbol" then
				considering case
					set firstSym to firstForm's valueData
					if firstSym = "def!" then
						set isSpecial to true
						set symName to (item 2 of lstData)'s valueData
						set valueObj to evalMAL(item 3 of lstData, env)
						return env's setEnv(symName, valueObj)
					else if firstSym = "let*" then
						set isSpecial to true
						set bindingsObj to item 2 of lstData
						set bodyObj to item 3 of lstData
						copy my Env to newEnv
						newEnv's setOuter(env)
						set bindingList to bindingsObj's valueData
						repeat with i from 1 to (count of bindingList) by 2
							set keyName to (item i of bindingList)'s valueData
							set valObj to evalMAL(item (i + 1) of bindingList, newEnv)
							newEnv's setEnv(keyName, valObj)
						end repeat
						set ast to bodyObj
						set env to newEnv
						-- continue 循环
					else if firstSym = "do" then
						set isSpecial to true
						set lastIndex to count of lstData
						repeat with i from 2 to (lastIndex - 1)
							evalMAL(item i of lstData, env)
						end repeat
						set ast to item lastIndex of lstData
						-- continue 循环
					else if firstSym = "if" then
						set isSpecial to true
						set condVal to evalMAL(item 2 of lstData, env)
						if condVal's typeName = "nil" or condVal's typeName = "false" then
							if (count of lstData) > 3 then
								set ast to item 4 of lstData
								-- continue 循环
							else
								return my typesLib's Types's makeMALNil()
							end if
						else
							set ast to item 3 of lstData
							-- continue 循环
						end if
					else if firstSym = "fn*" then
						set isSpecial to true
						return makeMALUserFunction(item 2 of lstData, item 3 of lstData, env)
					else if firstSym = "defmacro!" then
						set isSpecial to true
						set symName to (item 2 of lstData)'s valueData
						set valueObj to evalMAL(item 3 of lstData, env)
						return env's setEnv(symName, my setMacroFlag(valueObj))
					else if firstSym = "quote" then
						set isSpecial to true
						return item 2 of lstData
					else if firstSym = "quasiquote" then
						set isSpecial to true
						set ast to quasiquote(item 2 of lstData)
						-- continue 循环
					else if firstSym = "try*" then
						set isSpecial to true
						-- (try* form) 或 (try* form (catch* sym handler))
						if (count of lstData) = 2 then
							set ast to item 2 of lstData
							-- continue 循环
						else
							try
								set tryResult to evalMAL(item 2 of lstData, env)
								return tryResult
							on error errMsg number errNum
								set catchClause to item 3 of lstData
								set catchData to catchClause's valueData
								set catchSym to (item 2 of catchData)'s valueData
								set handlerAst to item 3 of catchData
								copy my Env to catchEnv
								catchEnv's setOuter(env)
								if errNum = 5001 then
									-- 从错误栈取回 MAL 对象
									set catchVal to item -1 of my malErrorStack
									my popMalErrorStack()
								else
									set catchVal to my typesLib's Types's makeMALString(errMsg)
								end if
								catchEnv's setEnv(catchSym, catchVal)
								set ast to handlerAst
								set env to catchEnv
								-- continue 循环
							end try
						end if
					end if
				end considering
			end if

			-- 普通调用: 求值首元素为函数,参数求值后调用
			if not isSpecial then
				-- 宏展开: 求值首元素为函数; 若是宏则不 eval 参数,直接展开
				set fnObj to evalMAL(item 1 of lstData, env)
				if fnObj's isUser is true and fnObj's isMacro is true then
					-- 宏: 绑定未求值参数,调用宏体得到展开式,继续循环
					copy my Env to macroEnv
					macroEnv's setOuter(fnObj's closureEnv)
					set macroParmNames to {}
					repeat with parmObj in fnObj's parmList
						set end of macroParmNames to parmObj's valueData
					end repeat
					-- 未求值的参数列表(宏不 eval 参数)
					set rawArgs to {}
					repeat with i from 2 to count of lstData
						set end of rawArgs to item i of lstData
					end repeat
					macroEnv's setBinds(macroParmNames, rawArgs)
					set ast to evalMAL(fnObj's bodyValue, macroEnv)
					-- continue 循环
				else
					set argList to {}
					repeat with i from 2 to count of lstData
						set end of argList to evalMAL(item i of lstData, env)
					end repeat
					-- 用户函数: 新建 Env(closureEnv) 绑定参数, tail 求值 body
					if fnObj's isUser is true then
						copy my Env to callEnv
						callEnv's setOuter(fnObj's closureEnv)
						-- parmList 元素是 MAL Symbol 对象,取 valueData
						set parmNames to {}
						repeat with parmObj in fnObj's parmList
							set end of parmNames to parmObj's valueData
						end repeat
						callEnv's setBinds(parmNames, argList)
						set ast to fnObj's bodyValue
						set env to callEnv
						-- continue 循环
					else
						return fnObj's apply(argList)
					end if
				end if
			end if
		-- 向量: 对每个元素求值
		else if ast's typeName = "vector" then
			set lstData to ast's valueData
			set newList to {}
			repeat with itemData in lstData
				set end of newList to evalMAL(itemData, env)
			end repeat
			return my typesLib's Types's makeMALVector(newList)
		-- 哈希表: 键不变,对值求值
		else if ast's typeName = "map" then
			set lstData to ast's valueData
			set newList to {}
			repeat with i from 1 to count of lstData
				if i mod 2 = 1 then
					set end of newList to item i of lstData
				else
					set end of newList to evalMAL(item i of lstData, env)
				end if
			end repeat
			return my typesLib's Types's makeMALMap(newList)
		-- 其他(数字/字符串/布尔/nil/函数): 原样返回
		else
			return ast
		end if
	end repeat
end evalMAL

-- 判断是否是指定符号的列表(大小写敏感)
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

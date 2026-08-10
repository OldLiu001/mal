use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

-- step3_env: 加载 types / reader / printer 模块
property typesLib : missing value
property readerLib : missing value
property printerLib : missing value
property coreLib : missing value

-- 动态加载模块: 优先已编译的 .scpt, 缺失时临时编译 .applescript 再加载
-- 这样 `osascript stepXxx.applescript` 可不经 make 直接运行
on loadMod(modName, scriptDir)
	set scptPath to scriptDir & "/" & modName & ".scpt"
	set srcPath to scriptDir & "/" & modName & ".applescript"
	if my fileExists(scptPath) then
		return load script (scptPath as POSIX file)
	else if my fileExists(srcPath) then
		set tmpPath to (current application's NSTemporaryDirectory() as text) & "mal_" & (current application's NSUUID's UUID()'s UUIDString()) & ".scpt"
		do shell script "osacompile -l AppleScript -o " & quoted form of tmpPath & " " & quoted form of srcPath
		return load script (tmpPath as POSIX file)
	else
		error "module not found: " & modName
	end if
end loadMod

on fileExists(p)
	set fm to current application's NSFileManager's defaultManager()
	return (fm's fileExistsAtPath:p) as boolean
end fileExists

on run()
	set scriptDir to (current application's NSString's stringWithString:(POSIX path of (path to me)))'s stringByDeletingLastPathComponent() as text
	set typesLib to my loadMod("types", scriptDir)
	set readerLib to my loadMod("reader", scriptDir)
	set printerLib to my loadMod("printer", scriptDir)
	readerLib's setTypesLib(typesLib)
	set coreLib to my loadMod("core", scriptDir)

	-- 初始化全局环境: core 函数 + 语言定义的 not
	set replEnv to makeReplEnv()
	coreLib's inject(typesLib, readerLib, printerLib, replEnv)
	-- (def! not (fn* (a) (if a false true)))
	rep("(def! not (fn* (a) (if a false true)))", replEnv)
	repeat
		set inputText to coreLib's readLine("user> ")
		if inputText is "" then exit repeat

		try
			set ast to readerLib's readString(inputText)
			set evalResult to evalMAL(ast, replEnv)
			set output to printerLib's Printer's pr_str(evalResult, true)
			log output
		on error errMsg number errNum
			log "Error: " & errMsg
		end try
	end repeat
end run

-- 创建全局 REPL 环境,绑定 core 函数
on makeReplEnv()
	copy my Env to replEnv
	set coreNames to {"+", "-", "*", "/", "=", "<", "<=", ">", ">=", "list", "list?", "empty?", "count", "pr-str", "str", "prn", "println"}
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
		prop funcName : fnName
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
		prop parmList : parmObj's valueData
		prop bodyValue : bodyObj
		prop closureEnv : fnEnv
	end script
	return MALUserFunction
end makeMALUserFunction

-- core 函数分发
on dispatchCore(fnName, args)
	if fnName = "+" or fnName = "-" or fnName = "*" or fnName = "/" then
		return coreLib's coreArith(fnName, args)
	else if fnName = "=" then
		if coreLib's malEqual(item 1 of args, item 2 of args) then
			return my typesLib's Types's makeMALTrue()
		else
			return my typesLib's Types's makeMALFalse()
		end if
	else if fnName = "<" or fnName = "<=" or fnName = ">" or fnName = ">=" then
		return coreLib's coreCompare(fnName, args)
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
		return my typesLib's Types's makeMALString(coreLib's corePrStr(args))
	else if fnName = "str" then
		return my typesLib's Types's makeMALString(coreLib's coreStr(args))
	else if fnName = "prn" then
		log coreLib's corePrStr(args)
		return my typesLib's Types's makeMALNil()
	else if fnName = "println" then
		log coreLib's corePrintlnStr(args)
		return my typesLib's Types's makeMALNil()
	end if
	error "'" & fnName & "' not found"
end dispatchCore

-- pr-str: 每个参数用 readably 打印,空格连接

-- str: 每个参数非 readably 打印,直接连接

-- println: 每个参数非 readably 打印,空格连接

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
			if not coreLib's malEqual(item i of la, item i of lb) then
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
		repeat with i from 1 to count of la
			if not coreLib's malEqual(item i of la, item i of lb) then
				return false
			end if
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
	-- DEBUG-EVAL: 当 env 中有 DEBUG-EVAL 且值不是 nil/false 时打印
	try
		set debugVal to env's getEnv("DEBUG-EVAL")
		if debugVal's typeName is not "nil" and debugVal's typeName is not "false" then
			log "EVAL: " & printerLib's Printer's pr_str(ast, true)
		end if
	on error
		-- DEBUG-EVAL 未定义,忽略
	end try

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
		-- def!: (def! symbol value) -> 在当前环境绑定并返回 value
		if isSpecialForm(firstForm, "def!") then
			set symName to (item 2 of lstData)'s valueData
			set valueObj to evalMAL(item 3 of lstData, env)
			return env's setEnv(symName, valueObj)
		-- let*: (let* (k1 v1 k2 v2 ...) body) 或 (let* [k1 v1 ...] body)
		else if isSpecialForm(firstForm, "let*") then
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
			return evalMAL(bodyObj, newEnv)
		-- do: (do form1 form2 ... last) -> 依次求值,返回最后一个
		else if isSpecialForm(firstForm, "do") then
			set lastVal to my typesLib's Types's makeMALNil()
			repeat with i from 2 to count of lstData
				set lastVal to evalMAL(item i of lstData, env)
			end repeat
			return lastVal
		-- if: (if cond then) 或 (if cond then else)
		else if isSpecialForm(firstForm, "if") then
			set condVal to evalMAL(item 2 of lstData, env)
			if condVal's typeName = "nil" or condVal's typeName = "false" then
				if (count of lstData) > 3 then
					return evalMAL(item 4 of lstData, env)
				else
					return my typesLib's Types's makeMALNil()
				end if
			else
				return evalMAL(item 3 of lstData, env)
			end if
		-- fn*: (fn* (parm...) body) 或 (fn* [parm...] body) -> 创建用户函数
		else if isSpecialForm(firstForm, "fn*") then
			return makeMALUserFunction(item 2 of lstData, item 3 of lstData, env)
		end if

		-- 普通调用: 求值首元素为函数,参数求值后调用
		set fnObj to evalMAL(item 1 of lstData, env)
		set argList to {}
		repeat with i from 2 to count of lstData
			set end of argList to evalMAL(item i of lstData, env)
		end repeat
		-- 用户函数: 新建 Env(closureEnv) 绑定参数,求值 body
		if fnObj's isUser is true then
			copy my Env to callEnv
			callEnv's setOuter(fnObj's closureEnv)
			-- parmList 元素是 MAL Symbol 对象,取 valueData
			set parmNames to {}
			repeat with parmObj in fnObj's parmList
				set end of parmNames to parmObj's valueData
			end repeat
			callEnv's setBinds(parmNames, argList)
			return evalMAL(fnObj's bodyValue, callEnv)
		end if
		return fnObj's apply(argList)
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
end evalMAL


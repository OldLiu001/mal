script Types
	-- Base class for all MAL types
	on makeMALAtom(inputValue)
		script MALAtom
			prop typeName : "atom"
			prop valueData : inputValue
		end script
		return MALAtom
	end makeMALAtom

	on makeMALNumber(inputValue)
		script MALNumber
			prop typeName : "number"
			prop valueData : inputValue
		end script
		return MALNumber
	end makeMALNumber

	on makeMALSymbol(inputValue)
		script MALSymbol
			prop typeName : "symbol"
			prop valueData : inputValue
		end script
		return MALSymbol
	end makeMALSymbol

	on makeMALKeyword(inputValue)
		script MALKeyword
			prop typeName : "keyword"
			prop valueData : inputValue
		end script
		return MALKeyword
	end makeMALKeyword

	on makeMALList(inputValue)
		script MALList
			prop typeName : "list"
			prop valueData : inputValue
		end script
		return MALList
	end makeMALList

	on makeMALVector(inputValue)
		script MALVector
			prop typeName : "vector"
			prop valueData : inputValue
		end script
		return MALVector
	end makeMALVector

	on makeMALMap(inputValue)
		script MALMap
			prop typeName : "map"
			prop valueData : inputValue
		end script
		return MALMap
	end makeMALMap

	on makeMALString(inputValue)
		script MALString
			prop typeName : "string"
			prop valueData : inputValue
		end script
		return MALString
	end makeMALString

	on makeMALNil()
		script MALNil
			prop typeName : "nil"
			prop valueData : "nil"
		end script
		return MALNil
	end makeMALNil

	on makeMALTrue()
		script MALTrue
			prop typeName : "true"
			prop valueData : "true"
		end script
		return MALTrue
	end makeMALTrue

	on makeMALFalse()
		script MALFalse
			prop typeName : "false"
			prop valueData : "false"
		end script
		return MALFalse
	end makeMALFalse

	on isNumber(malObject)
		try
			return (malObject's typeName) = "number"
		on error
			return false
		end try
	end isNumber

	on isSymbol(malObject)
		try
			return (malObject's typeName) = "symbol"
		on error
			return false
		end try
	end isSymbol

	on isList(malObject)
		try
			return (malObject's typeName) = "list"
		on error
			return false
		end try
	end isList

	on isVector(malObject)
		try
			return (malObject's typeName) = "vector"
		on error
			return false
		end try
	end isVector

	on isMap(malObject)
		try
			return (malObject's typeName) = "map"
		on error
			return false
		end try
	end isMap

	on isString(malObject)
		try
			return (malObject's typeName) = "string"
		on error
			return false
		end try
	end isString

	on isNil(malObject)
		try
			return (malObject's typeName) = "nil"
		on error
			return false
		end try
	end isNil

	on isTrue(malObject)
		try
			return (malObject's typeName) = "true"
		on error
			return false
		end try
	end isTrue

	on isFalse(malObject)
		try
			return (malObject's typeName) = "false"
		on error
			return false
		end try
	end isFalse

	on isBoolean(malObject)
		return isTrue(malObject) or isFalse(malObject)
	end isBoolean

	on isEmptyList(malObject)
		return isList(malObject) and (count of malObject's valueData) = 0
	end isEmptyList

	on countList(malObject)
		if isList(malObject) then
			return count of malObject's valueData
		else
			return 0
		end if
	end countList

	on getList(malObject)
		if isList(malObject) then
			return malObject's valueData
		else
			return {}
		end if
	end getList

end script
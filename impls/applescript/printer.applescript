use AppleScript version "2.8"
use scripting additions
use framework "Foundation"

script Printer
	on pr_str(malObject, print_readably)
		if malObject is missing value then
			return ""
		end if
		
		set typeName to malObject's typeName
		
		if typeName = "number" then
			return malObject's valueData as text
		else if typeName = "symbol" then
			return malObject's valueData
		else if typeName = "keyword" then
			return malObject's valueData
		else if typeName = "string" then
			if print_readably then
				return "\"" & escapeString(malObject's valueData) & "\""
			else
				return malObject's valueData
			end if
		else if typeName = "list" then
			return printList(malObject's valueData, "(", ")", print_readably)
		else if typeName = "vector" then
			return printList(malObject's valueData, "[", "]", print_readably)
		else if typeName = "map" then
			return printMap(malObject's valueData, print_readably)
		else if typeName = "nil" then
			return "nil"
		else if typeName = "true" then
			return "true"
		else if typeName = "false" then
			return "false"
		else if typeName = "atom" then
			return "(atom " & pr_str(malObject's valueData, print_readably) & ")"
		else
			return "<unknown-type:" & typeName & ">"
		end if
	end pr_str

	on printList(lst, startChar, endChar, print_readably)
		set out to startChar
		repeat with itemData in lst
			if out ≠ startChar then
				set out to out & " "
			end if
			set out to out & pr_str(itemData, print_readably)
		end repeat
		return out & endChar
	end printList

	on printMap(lst, print_readably)
		set out to "{"
		set countItems to count of lst
		repeat with i from 1 to countItems by 2
			if i > 1 then
				set out to out & " "
			end if
			set out to out & pr_str(item i of lst, print_readably)
			if i < countItems then
				set out to out & " "
				set out to out & pr_str(item (i + 1) of lst, print_readably)
			end if
		end repeat
		return out & "}"
	end printMap

	on escapeString(str)
		set out to ""
		repeat with ch in str
			set chText to ch as text
			if chText = "\"" then
				set out to out & "\\\""
			else if chText = "\\" then
				set out to out & "\\\\"
			else if chText = linefeed then
				set out to out & "\\n"
			else if chText = return then
				set out to out & "\\r"
			else if chText = tab then
				set out to out & "\\t"
			else
				set out to out & chText
			end if
		end repeat
		return out
	end escapeString
end script
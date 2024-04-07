Set "List=call "%~dp0LinearList_LSS_SLL.bat""
Set "Queue=call "%~dp0Queue_LSS.bat""
Set "Stack=call "%~dp0Stack_LSS.bat""

::Start
	Set "_TMP_Arguments_=%*"
	If "!_TMP_Arguments_:~,1!" Equ ":" (
		Set "_TMP_Arguments_=!_TMP_Arguments_:~1!"
	)
	Call :!_TMP_Arguments_!
	Set _TMP_Arguments_=
Goto :Eof

:read_str str
	call :tokenize "%~1"
	call :read_form "!re!"
goto :eof

:tokenize str
	!Queue! :Init tokens
	set "str=%~1"
	:tokenizing
		if "!str:~,1!" == " " (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "str=!str:~1!"
			goto tokenizing
		) else if "!str:~,1!" == "	" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "str=!str:~1!"
			goto tokenizing
		) else if "!str:~,1!" == "," (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "str=!str:~1!"
			goto tokenizing
		) else if "!str:~,2!" == "~@" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set tmp=~@
			set "str=!str:~2!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,1!" == "[" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp=["
			set "str=!str:~1!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,1!" == "]" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp=]"
			set "str=!str:~1!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,1!" == "(" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp=("
			set "str=!str:~1!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,1!" == ")" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp=)"
			set "str=!str:~1!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,1!" == "{" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp={"
			set "str=!str:~1!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,1!" == "}" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp=}"
			set "str=!str:~1!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,1!" == "'" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp='"
			set "str=!str:~1!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,1!" == "`" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp=`"
			set "str=!str:~1!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,1!" == "~" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp=~"
			set "str=!str:~1!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,1!" == "@" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp=@"
			set "str=!str:~1!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,9!" == "#$Caret$#" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp=#$Caret$#"
			set "str=!str:~9!"
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,20!" == "#$Double_Quotation$#" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			set "tmp=#$Double_Quotation$#"
			set "str=!str:~20!"
			:string_read
				if not "!str:~,20!" == "#$Double_Quotation$#" (
					set "tmp=!tmp!!str:~,1!"
					set "str=!str:~1!"
					goto string_read
				) else (
					set "tmp=!tmp!!str:~,20!"
					set "str=!str:~20!"
					if "!tmp:~-21,1!" == "\" (
						goto string_read
					)
				)
			!Queue! :Enqueue tokens tmp
		) else if "!str:~,1!" == ";" (
			if defined normal (
				!Queue! :Enqueue tokens normal
				set normal=
			)
			!Queue! :Enqueue tokens str
			set "str="
		) else if defined str (
			set "normal=!normal!!str:~,1!"
			set "str=!str:~1!"
			goto tokenizing
		)
		if defined normal (
			!Queue! :Enqueue tokens normal
			set normal=
		)
	set "re=!tokens!"
goto :eof

:read_form tokens_queue
	!List! :Init GrammarTree
	!Stack! :Init VariableBackup
	set "tokens_queue=%~1"
	:read_form_loop
		!Queue! :IsEmpty tokens_queue
		if not "!ErrorLevel!" == "0" (
			!Queue! :Peep tokens_queue token
			if "!token!" == "(" (
				call :read_list "!tokens_queue!"
			) else (
				call :read_atom "!tokens_queue!"
			)
			goto read_form_loop
		)
goto :eof

:read_list tokens_queue
	set "tokens_queue=%~1"
	!Queue! :Dequeue tokens_queue token
	:read_list_loop
		!Queue! :IsEmpty tokens_queue
		if not "!ErrorLevel!" == "0" (
			!Queue! :Peep tokens_queue token
			if "!token!" == ")" (
				!Queue! :Dequeue tokens_queue token
			) else (
				call :read_form "!tokens_queue!"
				goto read_list_loop
			)
		)
goto :eof

:read_atom tokens_queue
	set "tokens_queue=%~1"
	!Queue! :Dequeue tokens_queue token

goto :eof

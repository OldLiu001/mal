@echo off
@rem Project name: MAL
@rem Module name: Reader

@rem Global function list:
@rem 	ReadString
@rem 	Tokenize
@rem 	ReadForm
@rem 	ReadList
@rem 	ReadAtom
@rem 	CheckType

@rem Origin name mapping:
@rem 	read_str -> ReadString
@rem 	tokenize -> Tokenize
@rem 	read_form -> ReadForm
@rem 	read_list -> ReadList
@rem 	read_atom -> ReadAtom

set Collections_Lib_Embbeded=False

@rem Wrap of lib_collections.
:MAL_Reader_IMPORTFUNCTION_List Args
	echo %1
	if "%Collections_Lib_Embbeded%" == "False" (
		call "%~dp0Lib_Collections\LinearList_LSS_SLL.bat" %*
	) else (
		goto %* 2>nul
	)
goto :eof
set "List=call :MAL_Reader_IMPORTFUNCTION_List"

:MAL_Reader_IMPORTFUNCTION_Queue Args
	echo %1
	echo %*
	if "%Collections_Lib_Embbeded%" == "False" (
		call "%~dp0Lib_Collections\Queue_LSS.bat" %*
	) else (
		goto %* 2>nul
	)
goto :eof
set "Queue=call :MAL_Reader_IMPORTFUNCTION_Queue"

:MAL_Reader_IMPORTFUNCTION_Stack Args
	echo %1
	@REM if Collections_Lib_Embbeded=False, call the function in another file. else, call the function in this file.
	if not "%Collections_Lib_Embbeded%" == "True" (
		call "%~dp0Lib_Collections\Stack_LSS_SLL.bat" %*
	) else (
		goto %* 2>nul
	)
goto :eof
set "Stack=call :MAL_Reader_IMPORTFUNCTION_Stack"

@echo off
setlocal enabledelayedexpansion
call :MAL_Reader_GLOBALFUNCTION_TokenizeUnitTest
pause
exit

::Start
	set "_TMP_Arguments_=%*"
	if "!_TMP_Arguments_:~,1!" Equ ":" (
		set "_TMP_Arguments_=!_TMP_Arguments_:~1!"
	)
	call :MAL_Reader_EXPORTFUNCTION_!_TMP_Arguments_!
	set _TMP_Arguments_=
goto :eof

:MAL_Reader_GLOBALFUNCTION_ReadString MAL_Reader_LOCALVAR_ReadString_Str
	set "MAL_Reader_LOCALVAR_ReadString_Str=%~1"
	call :MAL_Reader_GLOBALFUNCTION_Tokenize "!MAL_Reader_LOCALVAR_ReadString_Str!"
	call :MAL_Reader_GLOBALFUNCTION_ReadForm "!MAL_Main_GLOBALVAR_ReturnValue!"
goto :eof

:MAL_Reader_GLOBALFUNCTION_Tokenize MAL_Reader_LOCALVAR_Tokenize_Str
	!Queue! :Init MAL_Reader_LOCALVAR_Tokenize_Tokens
	set "MAL_Reader_LOCALVAR_Tokenize_Str=%~1"
	:MAL_Reader_LOCALTAG_Tokenizing
		if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == " " (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			goto MAL_Reader_LOCALTAG_Tokenizing
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "	" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			goto MAL_Reader_LOCALTAG_Tokenizing
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "," (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			goto MAL_Reader_LOCALTAG_Tokenizing
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,2!" == "~@" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set MAL_Reader_LOCALVAR_Tokenize_Tmp=~@
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~2!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "[" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=["
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "]" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=]"
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "(" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=("
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == ")" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=)"
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "{" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp={"
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "}" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=}"
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "'" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp='"
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "`" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=`"
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "~" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=~"
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "@" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=@"
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,9!" == "#$Caret$#" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=#$Caret$#"
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~9!"
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,20!" == "#$Double_Quotation$#" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=#$Double_Quotation$#"
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~20!"
			:MAL_Reader_LOCALTAG_Tokenize_StringRead
				if not "!MAL_Reader_LOCALVAR_Tokenize_Str:~,20!" == "#$Double_Quotation$#" (
					set "MAL_Reader_LOCALVAR_Tokenize_Tmp=!MAL_Reader_LOCALVAR_Tokenize_Tmp!!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!"
					set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
					goto MAL_Reader_LOCALTAG_Tokenize_StringRead
				) else (
					set "MAL_Reader_LOCALVAR_Tokenize_Tmp=!MAL_Reader_LOCALVAR_Tokenize_Tmp!!MAL_Reader_LOCALVAR_Tokenize_Str:~,20!"
					set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~20!"
					if "!MAL_Reader_LOCALVAR_Tokenize_Tmp:~-21,1!" == "\" (
						goto MAL_Reader_LOCALTAG_Tokenize_StringRead
					)
				)
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == ";" (
			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
				set MAL_Reader_LOCALVAR_Tokenize_Normal=
			)
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Str
			set "MAL_Reader_LOCALVAR_Tokenize_Str="
		) else if defined MAL_Reader_LOCALVAR_Tokenize_Str (
			set "MAL_Reader_LOCALVAR_Tokenize_Normal=!MAL_Reader_LOCALVAR_Tokenize_Normal!!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!"
			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
			goto MAL_Reader_LOCALTAG_Tokenizing
		)
		if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
			set MAL_Reader_LOCALVAR_Tokenize_Normal=
		)
	set "MAL_Main_GLOBALVAR_ReturnValue=!MAL_Reader_LOCALVAR_Tokenize_Tokens!"
goto :eof

rem Built-in Tokenize function unit test.
:MAL_Reader_GLOBALFUNCTION_TokenizeUnitTest
	call :MAL_Reader_GLOBALFUNCTION_Tokenize "  (  )  [  ]  {  }  '  `  ~  @  ,  ;  "

	rem Check the result.
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "(" (
		echo Tokenize unit test failed.
		goto :eof
	)
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == ")" (
		echo Tokenize unit test failed.
		goto :eof
	)
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "[" (
		echo Tokenize unit test failed.
		goto :eof
	)
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "]" (
		echo Tokenize unit test failed.
		goto :eof
	)
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "{" (
		echo Tokenize unit test failed.
		goto :eof
	)
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "}" (
		echo Tokenize unit test failed.
		goto :eof
	)
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "'" (
		echo Tokenize unit test failed.
		goto :eof
	)
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "`" (
		echo Tokenize unit test failed.
		goto :eof
	)
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "~" (
		echo Tokenize unit test failed.
		goto :eof
	)
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "@" (
		echo Tokenize unit test failed.
		goto :eof
	)
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "," (
		echo Tokenize unit test failed.
		goto :eof
	)
	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == ";" (
		echo Tokenize unit test failed.
		goto :eof
	)
	echo Tokenize unit test passed.
goto :eof


:MAL_Reader_GLOBALFUNCTION_ReadForm MAL_Reader_LOCALVAR_ReadForm_TokensQueue
	!List! :Init MAL_Reader_LOCALVAR_ReadForm_GrammarTree
	!Stack! :Init MAL_Reader_LOCALVAR_ReadForm_VariableBackup
	set "MAL_Reader_LOCALVAR_ReadForm_TokensQueue=%~1"
	:MAL_Reader_LOCALTAG_ReadForm_Loop
		!Queue! :IsEmpty MAL_Reader_LOCALVAR_ReadForm_TokensQueue
		if not "!ErrorLevel!" == "0" (
			!Queue! :Peep MAL_Reader_LOCALVAR_ReadForm_TokensQueue MAL_Reader_LOCALVAR_ReadForm_TempToken
			if "!MAL_Reader_LOCALVAR_ReadForm_TempToken!" == "(" (
				call :MAL_Reader_GLOBALFUNCTION_ReadList "!MAL_Reader_LOCALVAR_ReadForm_TokensQueue"
			) else (
				call :MAL_Reader_GLOBALFUNCTION_ReadAtom "!MAL_Reader_LOCALVAR_ReadForm_TokensQueue"
			)
			goto MAL_Reader_LOCALTAG_ReadForm_Loop
		)
goto :eof


:MAL_Reader_GLOBALFUNCTION_ReadList MAL_Reader_LOCALVAR_ReadList_TokensQueue
	set "MAL_Reader_LOCALVAR_ReadList_TokensQueue=%~1"
	!Queue! :Dequeue MAL_Reader_LOCALVAR_ReadList_TokensQueue token
	:MAL_Reader_LOCALTAG_ReadList_Loop
		!Queue! :IsEmpty MAL_Reader_LOCALVAR_ReadList_TokensQueue
		if not "!ErrorLevel!" == "0" (
			!Queue! :Peep MAL_Reader_LOCALVAR_ReadList_TokensQueue token
			if "!token!" == ")" (
				!Queue! :Dequeue MAL_Reader_LOCALVAR_ReadList_TokensQueue token
			) else (
				call :MAL_Reader_GLOBALFUNCTION_ReadForm "!MAL_Reader_LOCALVAR_ReadList_TokensQueue!"
				goto MAL_Reader_LOCALTAG_ReadList_Loop
			)
		)
goto :eof


:MAL_Reader_GLOBALFUNCTION_ReadList MAL_Reader_LOCALVAR_ReadList_TokensQueue
	set "MAL_Reader_LOCALVAR_ReadList_TokensQueue=%~1"
	!Queue! :Dequeue MAL_Reader_LOCALVAR_ReadList_TokensQueue MAL_Reader_LOCALVAR_ReadList_TempToken
	:MAL_Reader_LOCALTAG_ReadList_Loop
		!Queue! :IsEmpty MAL_Reader_LOCALVAR_ReadList_TokensQueue
		if not "!ErrorLevel!" == "0" (
			!Queue! :Peep MAL_Reader_LOCALVAR_ReadList_TokensQueue MAL_Reader_LOCALVAR_ReadList_TempToken
			if "!MAL_Reader_LOCALVAR_ReadList_TempToken!" == ")" (
				!Queue! :Dequeue MAL_Reader_LOCALVAR_ReadList_TokensQueue MAL_Reader_LOCALVAR_ReadList_TempToken
			) else (
				call :MAL_Reader_GLOBALFUNCTION_ReadForm "!MAL_Reader_LOCALVAR_ReadList_TokensQueue!"
				goto MAL_Reader_LOCALTAG_ReadList_Loop
			)
		)
goto :eof


:MAL_Reader_GLOBALFUNCTION_ReadAtom MAL_Reader_LOCALVAR_ReadAtom_TokensQueue
	set "MAL_Reader_LOCALVAR_ReadAtom_TokensQueue=%~1"
	!Queue! :Dequeue MAL_Reader_LOCALVAR_ReadAtom_TokensQueue token
	!List! :Enqueue MAL_Reader_LOCALVAR_ReadForm_GrammarTree token

:check_type token
	set "token=%~1"
	
	rem check if it is a number
	:
	



rem _____________________________________________________________

rem rewrite above code without using outside libraries

@REM Project name: MAL
@REM Module name: Reader

@REM Global function list:
@REM 	ReadString
@REM 	Tokenize
@REM 	ReadForm
@REM 	ReadList
@REM 	ReadAtom
@REM 	CheckType

@REM Origin name mapping:
@REM 	read_str -> ReadString
@REM 	tokenize -> Tokenize
@REM 	read_form -> ReadForm
@REM 	read_list -> ReadList
@REM 	read_atom -> ReadAtom

@REM Special Symbol Mapping:
@REM 	! --- #$Exclamation$#
@REM 	^ --- #$Caret$#
@REM 	" --- #$Double_Quotation$#
@REM 	% --- #$Percent$#


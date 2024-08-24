@REM @echo off
@REM @rem Project name: MAL
@REM @rem Module name: Reader

@REM @rem Global function list:
@REM @rem 	ReadString
@REM @rem 	Tokenize
@REM @rem 	ReadForm
@REM @rem 	ReadList
@REM @rem 	ReadAtom
@REM @rem 	CheckType

@REM @rem Origin name mapping:
@REM @rem 	read_str -> ReadString
@REM @rem 	tokenize -> Tokenize
@REM @rem 	read_form -> ReadForm
@REM @rem 	read_list -> ReadList
@REM @rem 	read_atom -> ReadAtom

@REM set Collections_Lib_Embbeded=False

@REM @rem Wrap of lib_collections.
@REM :MAL_Reader_IMPORTFUNCTION_List Args
@REM 	echo %1
@REM 	if "%Collections_Lib_Embbeded%" == "False" (
@REM 		call "%~dp0Lib_Collections\LinearList_LSS_SLL.bat" %*
@REM 	) else (
@REM 		goto %* 2>nul
@REM 	)
@REM goto :eof
@REM set "List=call :MAL_Reader_IMPORTFUNCTION_List"

@REM :MAL_Reader_IMPORTFUNCTION_Queue Args
@REM 	echo %1
@REM 	echo %*
@REM 	if "%Collections_Lib_Embbeded%" == "False" (
@REM 		call "%~dp0Lib_Collections\Queue_LSS.bat" %*
@REM 	) else (
@REM 		goto %* 2>nul
@REM 	)
@REM goto :eof
@REM set "Queue=call :MAL_Reader_IMPORTFUNCTION_Queue"

@REM :MAL_Reader_IMPORTFUNCTION_Stack Args
@REM 	echo %1
@REM 	@REM if Collections_Lib_Embbeded=False, call the function in another file. else, call the function in this file.
@REM 	if not "%Collections_Lib_Embbeded%" == "True" (
@REM 		call "%~dp0Lib_Collections\Stack_LSS_SLL.bat" %*
@REM 	) else (
@REM 		goto %* 2>nul
@REM 	)
@REM goto :eof
@REM set "Stack=call :MAL_Reader_IMPORTFUNCTION_Stack"

@REM @echo off
@REM setlocal enabledelayedexpansion
@REM call :MAL_Reader_GLOBALFUNCTION_TokenizeUnitTest
@REM pause
@REM exit

@REM ::Start
@REM 	set "_TMP_Arguments_=%*"
@REM 	if "!_TMP_Arguments_:~,1!" Equ ":" (
@REM 		set "_TMP_Arguments_=!_TMP_Arguments_:~1!"
@REM 	)
@REM 	call :MAL_Reader_EXPORTFUNCTION_!_TMP_Arguments_!
@REM 	set _TMP_Arguments_=
@REM goto :eof

@REM :MAL_Reader_GLOBALFUNCTION_ReadString MAL_Reader_LOCALVAR_ReadString_Str
@REM 	set "MAL_Reader_LOCALVAR_ReadString_Str=%~1"
@REM 	call :MAL_Reader_GLOBALFUNCTION_Tokenize "!MAL_Reader_LOCALVAR_ReadString_Str!"
@REM 	call :MAL_Reader_GLOBALFUNCTION_ReadForm "!MAL_Main_GLOBALVAR_ReturnValue!"
@REM goto :eof

@REM :MAL_Reader_GLOBALFUNCTION_Tokenize MAL_Reader_LOCALVAR_Tokenize_Str
@REM 	!Queue! :Init MAL_Reader_LOCALVAR_Tokenize_Tokens
@REM 	set "MAL_Reader_LOCALVAR_Tokenize_Str=%~1"
@REM 	:MAL_Reader_LOCALTAG_Tokenizing
@REM 		if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == " " (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			goto MAL_Reader_LOCALTAG_Tokenizing
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "	" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			goto MAL_Reader_LOCALTAG_Tokenizing
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "," (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			goto MAL_Reader_LOCALTAG_Tokenizing
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,2!" == "~@" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set MAL_Reader_LOCALVAR_Tokenize_Tmp=~@
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~2!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "[" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=["
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "]" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=]"
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "(" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=("
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == ")" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=)"
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "{" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp={"
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "}" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=}"
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "'" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp='"
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "`" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=`"
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "~" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=~"
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == "@" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=@"
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,9!" == "#$Caret$#" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=#$Caret$#"
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~9!"
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,20!" == "#$Double_Quotation$#" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Tmp=#$Double_Quotation$#"
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~20!"
@REM 			:MAL_Reader_LOCALTAG_Tokenize_StringRead
@REM 				if not "!MAL_Reader_LOCALVAR_Tokenize_Str:~,20!" == "#$Double_Quotation$#" (
@REM 					set "MAL_Reader_LOCALVAR_Tokenize_Tmp=!MAL_Reader_LOCALVAR_Tokenize_Tmp!!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!"
@REM 					set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 					goto MAL_Reader_LOCALTAG_Tokenize_StringRead
@REM 				) else (
@REM 					set "MAL_Reader_LOCALVAR_Tokenize_Tmp=!MAL_Reader_LOCALVAR_Tokenize_Tmp!!MAL_Reader_LOCALVAR_Tokenize_Str:~,20!"
@REM 					set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~20!"
@REM 					if "!MAL_Reader_LOCALVAR_Tokenize_Tmp:~-21,1!" == "\" (
@REM 						goto MAL_Reader_LOCALTAG_Tokenize_StringRead
@REM 					)
@REM 				)
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Tmp
@REM 		) else if "!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!" == ";" (
@REM 			if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 				!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 				set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 			)
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Str
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str="
@REM 		) else if defined MAL_Reader_LOCALVAR_Tokenize_Str (
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Normal=!MAL_Reader_LOCALVAR_Tokenize_Normal!!MAL_Reader_LOCALVAR_Tokenize_Str:~,1!"
@REM 			set "MAL_Reader_LOCALVAR_Tokenize_Str=!MAL_Reader_LOCALVAR_Tokenize_Str:~1!"
@REM 			goto MAL_Reader_LOCALTAG_Tokenizing
@REM 		)
@REM 		if defined MAL_Reader_LOCALVAR_Tokenize_Normal (
@REM 			!Queue! :Enqueue MAL_Reader_LOCALVAR_Tokenize_Tokens MAL_Reader_LOCALVAR_Tokenize_Normal
@REM 			set MAL_Reader_LOCALVAR_Tokenize_Normal=
@REM 		)
@REM 	set "MAL_Main_GLOBALVAR_ReturnValue=!MAL_Reader_LOCALVAR_Tokenize_Tokens!"
@REM goto :eof

@REM rem Built-in Tokenize function unit test.
@REM :MAL_Reader_GLOBALFUNCTION_TokenizeUnitTest
@REM 	call :MAL_Reader_GLOBALFUNCTION_Tokenize "  (  )  [  ]  {  }  '  `  ~  @  ,  ;  "

@REM 	rem Check the result.
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "(" (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == ")" (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "[" (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "]" (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "{" (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "}" (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "'" (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "`" (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "~" (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "@" (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == "," (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	!Queue! :Dequeue MAL_Main_GLOBALVAR_ReturnValue MAL_Reader_LOCALVAR_TokenizeUnitTest_Token
@REM 	if not "!MAL_Reader_LOCALVAR_TokenizeUnitTest_Token!" == ";" (
@REM 		echo Tokenize unit test failed.
@REM 		goto :eof
@REM 	)
@REM 	echo Tokenize unit test passed.
@REM goto :eof


@REM :MAL_Reader_GLOBALFUNCTION_ReadForm MAL_Reader_LOCALVAR_ReadForm_TokensQueue
@REM 	!List! :Init MAL_Reader_LOCALVAR_ReadForm_GrammarTree
@REM 	!Stack! :Init MAL_Reader_LOCALVAR_ReadForm_VariableBackup
@REM 	set "MAL_Reader_LOCALVAR_ReadForm_TokensQueue=%~1"
@REM 	:MAL_Reader_LOCALTAG_ReadForm_Loop
@REM 		!Queue! :IsEmpty MAL_Reader_LOCALVAR_ReadForm_TokensQueue
@REM 		if not "!ErrorLevel!" == "0" (
@REM 			!Queue! :Peep MAL_Reader_LOCALVAR_ReadForm_TokensQueue MAL_Reader_LOCALVAR_ReadForm_TempToken
@REM 			if "!MAL_Reader_LOCALVAR_ReadForm_TempToken!" == "(" (
@REM 				call :MAL_Reader_GLOBALFUNCTION_ReadList "!MAL_Reader_LOCALVAR_ReadForm_TokensQueue"
@REM 			) else (
@REM 				call :MAL_Reader_GLOBALFUNCTION_ReadAtom "!MAL_Reader_LOCALVAR_ReadForm_TokensQueue"
@REM 			)
@REM 			goto MAL_Reader_LOCALTAG_ReadForm_Loop
@REM 		)
@REM goto :eof


@REM :MAL_Reader_GLOBALFUNCTION_ReadList MAL_Reader_LOCALVAR_ReadList_TokensQueue
@REM 	set "MAL_Reader_LOCALVAR_ReadList_TokensQueue=%~1"
@REM 	!Queue! :Dequeue MAL_Reader_LOCALVAR_ReadList_TokensQueue token
@REM 	:MAL_Reader_LOCALTAG_ReadList_Loop
@REM 		!Queue! :IsEmpty MAL_Reader_LOCALVAR_ReadList_TokensQueue
@REM 		if not "!ErrorLevel!" == "0" (
@REM 			!Queue! :Peep MAL_Reader_LOCALVAR_ReadList_TokensQueue token
@REM 			if "!token!" == ")" (
@REM 				!Queue! :Dequeue MAL_Reader_LOCALVAR_ReadList_TokensQueue token
@REM 			) else (
@REM 				call :MAL_Reader_GLOBALFUNCTION_ReadForm "!MAL_Reader_LOCALVAR_ReadList_TokensQueue!"
@REM 				goto MAL_Reader_LOCALTAG_ReadList_Loop
@REM 			)
@REM 		)
@REM goto :eof


@REM :MAL_Reader_GLOBALFUNCTION_ReadList MAL_Reader_LOCALVAR_ReadList_TokensQueue
@REM 	set "MAL_Reader_LOCALVAR_ReadList_TokensQueue=%~1"
@REM 	!Queue! :Dequeue MAL_Reader_LOCALVAR_ReadList_TokensQueue MAL_Reader_LOCALVAR_ReadList_TempToken
@REM 	:MAL_Reader_LOCALTAG_ReadList_Loop
@REM 		!Queue! :IsEmpty MAL_Reader_LOCALVAR_ReadList_TokensQueue
@REM 		if not "!ErrorLevel!" == "0" (
@REM 			!Queue! :Peep MAL_Reader_LOCALVAR_ReadList_TokensQueue MAL_Reader_LOCALVAR_ReadList_TempToken
@REM 			if "!MAL_Reader_LOCALVAR_ReadList_TempToken!" == ")" (
@REM 				!Queue! :Dequeue MAL_Reader_LOCALVAR_ReadList_TokensQueue MAL_Reader_LOCALVAR_ReadList_TempToken
@REM 			) else (
@REM 				call :MAL_Reader_GLOBALFUNCTION_ReadForm "!MAL_Reader_LOCALVAR_ReadList_TokensQueue!"
@REM 				goto MAL_Reader_LOCALTAG_ReadList_Loop
@REM 			)
@REM 		)
@REM goto :eof


@REM :MAL_Reader_GLOBALFUNCTION_ReadAtom MAL_Reader_LOCALVAR_ReadAtom_TokensQueue
@REM 	set "MAL_Reader_LOCALVAR_ReadAtom_TokensQueue=%~1"
@REM 	!Queue! :Dequeue MAL_Reader_LOCALVAR_ReadAtom_TokensQueue token
@REM 	!List! :Enqueue MAL_Reader_LOCALVAR_ReadForm_GrammarTree token

@REM :check_type token
@REM 	set "token=%~1"
	
@REM 	rem check if it is a number
@REM 	:
	



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
@REM 	! --- #$E$#
@REM 	^ --- #$C$#
@REM 	" --- #$D$#
@REM 	% --- #$P$#

(
	:Tokenize
)
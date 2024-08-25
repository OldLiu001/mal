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


@echo off
@REM Module Name: Reader

@rem Export Functions:
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
@REM 	! --- $E
@REM 	^ --- $C
@REM 	" --- $D
@REM 	% --- $P
@REM 	$ --- $$

::Start
	set "_Arguments=%*"
	if "!_Arguments:~,1!" Equ ":" (
		Set "_Arguments=!_Arguments:~1!"
	)
	call :!_Arguments!
	set _Arguments=
goto :eof

(
	:CopyVar _VarNameFrom _VarNameTo
		if not defined %~1 (
			echo [!G_CallPath!] %~1 is not defined.
			pause & exit 1
		)
		set "%~2=!%~1!"
	goto :eof
	
	:ReadString
		call Function.bat :GetArgs _StrMalCode
		call Function.bat :SaveCurrentCallInfo ReadString

		rem Get the tokens.
		call Namespace.bat :New
		call Function.bat :GetRetVar _ObjReader
		set "!_ObjReader!.TotalTokens=0"
		set /a _LineNumber = !_StrMalCode!.LineNumber
		for /l %%i in (1 1 !_LineNumber!) do (
			call :CopyVar !_StrMalCode!.Lines[%%i] _Line
			call Function.bat :PrepareCall _Line _ObjReader
			call :Tokenize
			call Function.bat :DropRetVar
		)

		rem Check if there is any token.
		call :CopyVar !_ObjReader!.TotalTokens _TotalTokenNum
		if "!_TotalTokenNum!" == "0" (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)

		rem Translate the tokens to AST.
		set "!_ObjReader!.CurTokenPtr=1"
		call Function.bat :PrepareCall _ObjReader
		call :ReadForm
		
		call Function.bat :RestoreCallInfo
		call Function.bat :RetVar _StrMalCode
	goto :eof

	:ReadForm
		call Function.bat :GetArgs _ObjReader
		call Function.bat :SaveCurrentCallInfo ReadForm

		call :CopyVar !_ObjReader!.CurTokenPtr _CurTokenPtr
		call :CopyVar !_ObjReader!.TotalTokens _TotalTokenNum

		if !_CurTokenPtr! Gtr !_TotalTokenNum! (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)

		call :CopyVar !_ObjReader!.Tokens[!_CurTokenPtr!] _CurToken
		
		if "!_CurToken!" == "(" (
			call Function.bat :PrepareCall _ObjReader
			call :ReadList
			call Function.bat :GetRetVar _ObjMalCode
		) else (
			rem Atom.
			call Function.bat :PrepareCall _ObjReader
			call :ReadAtom
			call Function.bat :GetRetVar _ObjMalCode
		)

		call Function.bat :RestoreCallInfo
		call Function.bat :RetVar _ObjMalCode
	goto :eof

	:ReadAtom
		call Function.bat :GetArgs _ObjReader
		call Function.bat :SaveCurrentCallInfo ReadAtom

		call :CopyVar !_ObjReader!.CurTokenPtr _CurTokenPtr
		call :CopyVar !_ObjReader!.TotalTokens _TotalTokenNum

		if !_CurTokenPtr! Gtr !_TotalTokenNum! (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)

		call :CopyVar !_ObjReader!.Tokens[!_CurTokenPtr!] _CurToken
		
		call Namespace.bat :New
		call Function.bat :GetRetVar _ObjMalCode
		set "!_ObjMalCode!.Type=MalType"
		set "!_ObjMalCode!.Value=!_CurToken!"

		rem check token's MalType.
		set /a _TestNum = _CurToken
		if "!_TestNum!" == "!_CurToken!" (
			set "!_ObjMalCode!.MalType=Number"
		) else (
			set "!_ObjMalCode!.Type=Symbol"
		)
		rem TODO: CheckMore.

		call Function.bat :RestoreCallInfo
		call Function.bat :RetVar _ObjMalCode
	goto :eof

	:ReadList
		call Function.bat :GetArgs _ObjReader
		call Function.bat :SaveCurrentCallInfo ReadList

		call :CopyVar !_ObjReader!.CurTokenPtr _CurTokenPtr
		call :CopyVar !_ObjReader!.TotalTokens _TotalTokenNum

		if !_CurTokenPtr! Gtr !_TotalTokenNum! (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)

		call :CopyVar !_ObjReader!.Tokens[!_CurTokenPtr!] _CurToken

		if "!_CurToken!" Neq "(" (
			rem TODO
			echo ERROR: Not a list.
			pause
			exit
		)

		set /a _CurTokenPtr += 1

		if !_CurTokenPtr! Gtr !_TotalTokenNum! (
			rem TODO
			echo ERROR: No token found.
			pause
			exit
		)

		call :CopyVar !_ObjReader!.Tokens[!_CurTokenPtr!] _CurToken
		:ReadList_Loop
			if "!_CurToken!" == ")" (
				set /a _CurTokenPtr += 1
				goto :ReadList_Pass
			)



	goto :eof



	:Tokenize
		call Function.bat :GetArgs _Line _ObjReader
		call Function.bat :SaveCurrentCallInfo Tokenize

		call :CopyVar _Line _CurLine
		call :CopyVar !_ObjReader!.TotalTokens _CurTokenNum

		rem Tokenize the _CurLine.
		set _ParsingStr=False
		set _NormalToken=
		:Tokenizing_Loop
		if "!_CurLine!" == "" (
			if "!_ParsingStr!" == "True" (
				rem TODO
				echo ERROR: STRING not full.
				pause
				exit
			)
			goto :Tokenizing_Pass
		)
		if "!_ParsingStr!" == "False" (
			if "!_CurLine:~,1!" == " " (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurLine=!_CurLine:~1!"
				goto Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == "	" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurLine=!_CurLine:~1!"
				goto Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == "," (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurLine=!_CurLine:~1!"
				goto Tokenizing_Loop
			)
			if "!_CurLine:~,2!" == "~@" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken=~@"
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~2!"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == "[" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken=["
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == "]" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken=]"
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == "(" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken=("
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == ")" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken=)"
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == "{" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken={"
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == "}" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken=}"
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == "'" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken='"
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == "`" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken=`"
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == "~" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken=~"
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == "@" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken=@"
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~1!"
				goto :Tokenizing_Loop
			)
			rem ^ --- $C
			if "!_CurLine:~,2!" == "$C" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				set "_CurToken=$C"
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]

				set "_CurLine=!_CurLine:~2!"
				goto :Tokenizing_Loop
			)
			rem " --- $D
			if "!_CurLine:~,2!" == "$D" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				rem string.
				set "_CurLine=!_CurLine:~2!"
				set "_ParsingStr=True"
				set "_StrToken="
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,1!" == ";" (
				if defined _NormalToken (
					rem save normal token first.
					call :CopyVar _NormalToken _CurToken
					set /a _CurTokenNum += 1
					call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
					set _NormalToken=
				)
				rem comment.
				call :CopyVar _CurLine _CurToken
				set /a _CurTokenNum += 1
				call :CopyVar _CurToken !_ObjReader!.Tokens[!_CurTokenNum!]
				set "_CurLine="
				goto :Tokenizing_Loop
			)

			set "_NormalToken=!_NormalToken!!_CurLine:~,1!"
			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		) else (
			rem parsing string now.
			if "!_CurLine:~,2!" == "\\" (
				rem \\
				set "_CurLine=!_CurLine:~2!"
				set "_StrToken=!_StrToken!\"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,3!" == "\$D" (
				rem \"
				set "_CurLine=!_CurLine:~3!"
				set "_StrToken=!_StrToken!$D"
				goto :Tokenizing_Loop
			)
			if "!_CurLine:~,2!" == "$D" (
				rem end of string.
				set "_CurLine=!_CurLine:~2!"
				set "_ParsingStr=False"
				set /a _CurTokenNum += 1
				call :CopyVar _StrToken !_ObjReader!.Tokens[!_CurTokenNum!]
				goto :Tokenizing_Loop
			)
			set "_StrToken=!_StrToken!!_CurLine:~,1!"
			set "_CurLine=!_CurLine:~1!"
			goto :Tokenizing_Loop
		)
		:Tokenizing_Pass
		call :CopyVar _CurTokenNum !_ObjReader!.TotalTokens

		set !_ObjReader!

		call Function.bat :RestoreCallInfo
		call Function.bat :RetNone
	goto :eof
)
::Code by OldLiu
::¿œ¡ı±‡–¥

::Start
	Set "_TMP_Arguments_=%*"
	If "!_TMP_Arguments_:~,1!" Equ ":" (
		Set "_TMP_Arguments_=!_TMP_Arguments_:~1!"
	)
	Call :Queue_LSS_!_TMP_Arguments_!
	Set _TMP_Arguments_=
Goto :Eof

::Queue_LSS(require LinearList_LSS_SLL) Begin
	:Queue_LSS_Init QueueName
		Call :LinearList_LSS_SLL_Init "%~1"
		Call :LinearList_LSS_SLL_EditNodeElem "%~1" "%~1"
	Goto :Eof
	
	:Queue_LSS_Clear QueueName
		Call :LinearList_LSS_SLL_Clear "%~1"
		Set /A _Queue_LSS_Clear_TMP_HeadNodePtr=%~1
		Call :LinearList_LSS_SLL_EditNodeElem "%~1" "_Queue_LSS_Clear_TMP_HeadNodePtr"
		Set _Queue_LSS_Clear_TMP_HeadNodePtr=
	Goto :Eof
	
	:Queue_LSS_Delete QueueName
		Call :LinearList_LSS_SLL_Delete "%~1"
	Goto :Eof
	
	:Queue_LSS_IsEmpty QueueName
		Call :LinearList_LSS_SLL_IsEmpty "%~1"
	Goto :Eof
	
	:Queue_LSS_Enqueue QueueName VarToInsert
		Call :LinearList_LSS_SLL_GetNodeElem "%~1" _Queue_LSS_Enqueue_TMP_QueueRearPtr
		Call :LinearList_LSS_SLL_InsertNextNode _Queue_LSS_Enqueue_TMP_QueueRearPtr "%~2"
		Call :LinearList_LSS_SLL_EditNodeElem "%~1" ErrorLevel
	Goto :Eof
	
	:Queue_LSS_Dequeue QueueName [VarToReturn]
		Call :LinearList_LSS_SLL_DeleteNextNode "%~1" "%~2"
		If !ErrorLevel! Neq 0 Goto :Eof
		Call :Queue_LSS_IsEmpty "%~1"
		If !ErrorLevel! Equ 0 Call :Queue_LSS_Clear "%~1"
		Set /A ErrorLevel=0
	Goto :Eof
	
	:Queue_LSS_Peep QueueName VarToReturn
		Call :LinearList_LSS_SLL_GetNextNodePtr "%~1"
		Call :LinearList_LSS_SLL_GetNodeElem ErrorLevel "%~2"
	Goto :Eof
::Queue_LSS End

::LinearList_LSS_SLL Begin
	:LinearList_LSS_SLL_GetRandom
		Set /A ErrorLevel=%random%%%10000+%random%*10000
		If !ErrorLevel! Equ 0 Goto GetRandom
		If Defined Memory[!ErrorLevel!].Data Goto GetRandom
	Goto :Eof

	:LinearList_LSS_SLL_Init ListName
		Call :LinearList_LSS_SLL_GetRandom
		Set /A %~1=ErrorLevel
		Set Memory[!ErrorLevel!].Data=ListHead
		Set /A Memory[!ErrorLevel!].Next=0
		Set /A ErrorLevel=0
	Goto :Eof

	:LinearList_LSS_SLL_Clear ListName
		Call :LinearList_LSS_SLL_DeleteNextNode "%~1"
		If !ErrorLevel! Equ 0 Goto :LinearList_LSS_SLL_Clear
		Set /A ErrorLevel=0
	Goto :Eof

	:LinearList_LSS_SLL_Delete ListName
		Call :LinearList_LSS_SLL_Clear "%~1"
		Set Memory[!%~1!].Data=
		Set Memory[!%~1!].Next=
		Set /A ErrorLevel=0
	Goto :Eof

	:LinearList_LSS_SLL_GetLength ListName
		Set /A _LinearList_LSS_SLL_GetLength_TMP_ListLength_=0
		Set /A _LinearList_LSS_SLL_GetLength_TMP_Next_Node_Ptr_=%~1
		:LinearList_LSS_SLL_GetLength_Loop
			Call :LinearList_LSS_SLL_GetNextNodePtr _LinearList_LSS_SLL_GetLength_TMP_Next_Node_Ptr_
			Set /A _LinearList_LSS_SLL_GetLength_TMP_Next_Node_Ptr_=ErrorLevel
			If !_LinearList_LSS_SLL_GetLength_TMP_Next_Node_Ptr_! Neq 0 (
				Set /A _LinearList_LSS_SLL_GetLength_TMP_ListLength_+=1
				Goto LinearList_LSS_SLL_GetLength_Loop
			)
		Set /A ErrorLevel=_LinearList_LSS_SLL_GetLength_TMP_ListLength_
		Set _LinearList_LSS_SLL_GetLength_TMP_ListLength_=
		Set _LinearList_LSS_SLL_GetLength_TMP_Next_Node_Ptr_=
	Goto :Eof

	:LinearList_LSS_SLL_IsEmpty ListName
	:LinearList_LSS_SLL_GetNextNodePtr NodePtr
		Set /A _LinearList_LSS_SLL_GetNextNodePtr_TMP_NodePtr_=%~1
		Set /A ErrorLevel=Memory[!_LinearList_LSS_SLL_GetNextNodePtr_TMP_NodePtr_!].Next
		Set _LinearList_LSS_SLL_GetNextNodePtr_TMP_NodePtr_=
	Goto :Eof

	:LinearList_LSS_SLL_InsertNextNode NodePtr VarToInsert
		Set /A _LinearList_LSS_SLL_InsertNextNode_TMP_NodePtr_=%~1
		Set /A _LinearList_LSS_SLL_InsertNextNode_TMP_NextNodePtr_=Memory[!_LinearList_LSS_SLL_InsertNextNode_TMP_NodePtr_!].Next
		Call :LinearList_LSS_SLL_GetRandom
		Set /A Memory[!_LinearList_LSS_SLL_InsertNextNode_TMP_NodePtr_!].Next=ErrorLevel
		Set /A Memory[!ErrorLevel!].Next=_LinearList_LSS_SLL_InsertNextNode_TMP_NextNodePtr_
		Set "Memory[!ErrorLevel!].Data=!%~2!"
		Set _LinearList_LSS_SLL_InsertNextNode_TMP_NextNodePtr_=
		Set _LinearList_LSS_SLL_InsertNextNode_TMP_NodePtr_=
	Goto :Eof

	:LinearList_LSS_SLL_DeleteNextNode NodePtr [VarToSaveNextNodeElemValue]
		Set /A _LinearList_LSS_SLL_DeleteNextNode_TMP_NodePtr_=%~1
		Set /A _LinearList_LSS_SLL_DeleteNextNode_TMP_Next_Node_Ptr_=Memory[!_LinearList_LSS_SLL_DeleteNextNode_TMP_NodePtr_!].Next
		If !_LinearList_LSS_SLL_DeleteNextNode_TMP_Next_Node_Ptr_! Equ 0 (
			Set _LinearList_LSS_SLL_DeleteNextNode_TMP_Next_Node_Ptr_=
			Set _LinearList_LSS_SLL_DeleteNextNode_TMP_NodePtr_=
			Set /A ErrorLevel=1
			Goto :Eof
		)
		Set /A Memory[!_LinearList_LSS_SLL_DeleteNextNode_TMP_NodePtr_!].Next=Memory[!_LinearList_LSS_SLL_DeleteNextNode_TMP_Next_Node_Ptr_!].Next
		If "%~2" Neq "" Call Set "%~2=%%Memory[!_LinearList_LSS_SLL_DeleteNextNode_TMP_Next_Node_Ptr_!].Data%%"
		Set Memory[!_LinearList_LSS_SLL_DeleteNextNode_TMP_Next_Node_Ptr_!].Next=
		Set Memory[!_LinearList_LSS_SLL_DeleteNextNode_TMP_Next_Node_Ptr_!].Data=
		Set _LinearList_LSS_SLL_DeleteNextNode_TMP_Next_Node_Ptr_=
		Set _LinearList_LSS_SLL_DeleteNextNode_TMP_NodePtr_=
		Set /A ErrorLevel=0
	Goto :Eof

	:LinearList_LSS_SLL_GetNodeElem NodePtr VarToSaveElemValue
		Set /A LinearList_LSS_SLL_GetNodeElem_TMP_NodePtr_=%~1
		Call Set "%~2=%%Memory[!LinearList_LSS_SLL_GetNodeElem_TMP_NodePtr_!].Data%%"
		Set LinearList_LSS_SLL_GetNodeElem_TMP_NodePtr_=
		Set /A ErrorLevel=0
	Goto :Eof

	:LinearList_LSS_SLL_EditNodeElem NodePtr VarToReplaceElemValue
		Set /A LinearList_LSS_SLL_EditNodeElem_TMP_NodePtr_=%~1
		Set "Memory[!LinearList_LSS_SLL_EditNodeElem_TMP_NodePtr_!].Data=!%~2!"
		Set LinearList_LSS_SLL_EditNodeElem_TMP_NodePtr_=
		Set /A ErrorLevel=0
	Goto :Eof
::LinearList_LSS_SLL End
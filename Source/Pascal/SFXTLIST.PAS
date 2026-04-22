(****************************************************************************
*  UNIT          : SFXTLIST                                                 *
*  AUTHOR        :                                                          *
*  DATE          :                                                          *
*  PURPOSE       :                                                          *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXTList;
INTERFACE
USES F6StdUtl,F6StdCtv,F6DTConv,FXFTrn,SFXGraph,FXFIngr,F6StdWn1,FXDetail,SFXBtn,
     SFXMsg,SFXWin,SfxKbd,SFXFGen,FXChoice,SFXUtils,FXModCtv,FXFWork;

TYPE PTRNList = ^TTRNList;
     TTRNList = PACKED RECORD
      WorkNo     : LONGINT;              {Work Order No}
      Revision   : BYTE;
      Ingredient : TIngredientRef;       {Ingreident}
      WeightDone : DOUBLE;               {Combined Weight Of all Ingredients}
      WeightReq  : DOUBLE;
      ContsDone  : LONGINT;              {Number Of Containers}
      ContsReq   : LONGINT;
      NEXT       : PTRNList;
     END;

     TBuildFilter = PACKED RECORD        {Filter List Used By BuildTransaction___}
      WorkNo      : LONGINT;          {Matching Filters <> 0/space_string}
      Revision    : BYTE;
      Ingredient  : TIngredientRef;   { is no match}
      ContNo      : INTEGER;
      MixNo       : WORD;
      MID         : WORD;
      RunNo       : LONGINT;
      NumElements : INTEGER;        {Number Of elements in linked list}
     END;



PROCEDURE ShowTodaysWeighings;
FUNCTION  BuildTransactionListForDay(TheDay : LONGINT;VAR Filter : TBuildFilter) : PTRNList;     {returns Pointer to header}
FUNCTION  BuildTransactionListForMix(VAR Filter : TBuildFilter) : PTRNList;
PROCEDURE ClearTransactionList(VAR Header : PTRNList);
FUNCTION  BuildOrderTransactionListForMix(VAR Filter : TBuildFilter) : PTRNList;

IMPLEMENTATION
USES SFXCOLR;
FUNCTION BuildTransactionListForMix(VAR Filter : TBuildFilter) : PTRNList;
VAR ListHead   : PTRNList;
    TRNRec     : TTranRecord;
    ReadTRNErr : INTEGER;

  PROCEDURE GetFirstTransaction;
  BEGIN
   FillChar(TRNRec,SizeOf(TRNRec),#0);
   TRNRec.TRN_OrderNo := Filter.WorkNo;
   TRNRec.TRN_Revision:= Filter.Revision-1;
   TRNRec.TRN_MixNo   := Filter.MixNo;
   ReadTRNErr := TransFile^.ReadRecord('GE',FALSE,FALSE,TRNRec,2);
  END;

  PROCEDURE GetNextTransaction;
  BEGIN
   ReadTRNErr := TransFile^.ReadRecord('GN',FALSE,FALSE,TRNRec,2);
  END;

  FUNCTION TransactionWithinFilter : BOOLEAN;
  BEGIN
   TransactionWithinFilter := FALSE;
   WITH Filter,TRNRec DO
    BEGIN
     IF (WorkNo <> 0) AND (WorkNo <> TRN_OrderNo)        THEN EXIT;
     IF (Revision<>0) AND ((Revision-1) <> TRN_Revision) THEN EXIT;
     IF (ContNo <> 0) AND (ContNo <> TRN_ContainerNo)    THEN EXIT;
     IF (MixNo  <> 0) AND (MixNo  <> TRN_MixNo)          THEN EXIT;
     IF (MID    <> 0) AND (MID    <> TRN_MID)            THEN EXIT;
     IF (RunNo  <> 0) AND (RunNo  <> TRN_SerialNo)       THEN EXIT;
     IF  (NOT NowtButSpace(Ingredient))
     AND (Ingredient <> TRN_Ingredient)                  THEN EXIT;
    END;
   TransactionWithinFilter := TRUE;
  END;

  PROCEDURE AddRecordToList;
  VAR Loop,Last,AddItem : PTRNList;

   PROCEDURE PrimeRecordWithTRN(ListRec : PTRNList;NewRec : BOOLEAN);
   BEGIN
    WITH ListRec^ DO
     BEGIN
      IF NewRec THEN
       BEGIN
        INC(Filter.NumElements);
        WorkNo     := TRNRec.TRN_OrderNo;
        Revision   := TRNRec.TRN_Revision;
        Ingredient := TRNRec.TRN_Ingredient;
        WeightDone := TRNRec.TRN_ContainerWt;
        ContsDone  := 1;
        Next       := NIL;
       END
      ELSE
       BEGIN
        WeightDone := WeightDone + TRNRec.TRN_ContainerWt;
        INC(ContsDone);
       END;
     END;
   END;

  BEGIN
   Loop := ListHead;
   Last := NIL;
   IF Loop = NIL THEN
    BEGIN
     New(ListHead);
     FillChar(ListHead^,sizeof(ListHead^),0);
     PrimeRecordWithTRN(ListHead,TRUE);
     EXIT;
    END;
   WHILE (Loop<>NIL) DO
    BEGIN
     IF Loop^.Ingredient = TRNRec.TRN_Ingredient THEN
      BEGIN
       PrimeRecordWithTRN(Loop,FALSE);
       EXIT;
      END;
     IF Loop^.Ingredient > TRNREc.TRN_Ingredient THEN
      BEGIN
       New(AddItem);
       FillChar(AddItem^,Sizeof(AddItem^),0);
       PrimeRecordWithTRN(AddItem,TRUE);
       IF Last = NIL THEN
        BEGIN
         AddItem^.Next := ListHead;
         ListHead      := AddItem;
        END
       ELSE
        BEGIN
         AddItem^.Next := Loop;
         Last^.Next    := AddItem;
        END;
       EXIT;
      END;
     Last := Loop;
     Loop := loop^.Next;
    END;
   New(Loop);
   FillChar(Loop^,Sizeof(Loop^),0);
   PrimeRecordWithTRN(Loop,TRUE);
   Last^.Next := Loop;
  END;

BEGIN
 ListHead := NIL;
 Filter.NumElements := 0;

 GetFirstTransaction;
 WHILE (ReadTRNErr = 0)
 AND   (TRNRec.TRN_MixNo = Filter.MixNo) DO
  BEGIN
   IF TransactionWithinFilter THEN AddRecordToList;
   GetNextTransaction;
  END;
 BuildTransactionListForMix := ListHead;
END;



FUNCTION BuildTransactionListForDay(TheDay : LONGINT;VAR Filter : TBuildFilter) : PTRNList;
VAR ListHead   : PTRNList;
    TRNRec     : TTranRecord;
    ReadTRNErr : INTEGER;

  PROCEDURE GetFirstTransaction;
  BEGIN
   FillChar(TRNRec,SizeOf(TRNRec),#0);
   TRNRec.TRN_Date := TheDay;
   TRNRec.TRN_OrderNo := Filter.WorkNo;
   TRNRec.TRN_Revision:= Filter.Revision;
   ReadTRNErr := TransFile^.ReadRecord('GE',FALSE,FALSE,TRNRec,0);
  END;

  PROCEDURE GetNextTransaction;
  BEGIN
   ReadTRNErr := TransFile^.ReadRecord('GN',FALSE,FALSE,TRNRec,0);
  END;

  PROCEDURE ResetVars;
  BEGIN
   Filter.NumElements := 0;
   ListHead := NIL;
  END;

  FUNCTION TransactionWithinFilter : BOOLEAN;
  BEGIN
   TransactionWithinFilter := FALSE;
   WITH Filter,TRNRec DO
    BEGIN
     IF (WorkNo <> 0) AND (WorkNo <> TRN_OrderNo) THEN EXIT;
     IF (Revision<>0) AND ((Revision-1) <> TRN_Revision) THEN EXIT;
     IF (ContNo <> 0) AND (ContNo <> TRN_ContainerNo) THEN EXIT;
     IF (MixNo  <> 0) AND (MixNo  <> TRN_MixNo) THEN EXIT;
     IF (MID    <> 0) AND (MID    <> TRN_MID) THEN EXIT;
     IF (RunNo  <> 0) AND (RunNo  <> TRN_SerialNo) THEN EXIT;
     IF (NOT NowtButSpace(Ingredient)) AND (Ingredient <> TRN_Ingredient) THEN EXIT;
    END;
   TransactionWithinFilter := TRUE;
  END;

  PROCEDURE AddRecordToList;
  VAR Loop,Last,AddItem : PTRNList;

   PROCEDURE PrimeRecordWithTRN(ListRec : PTRNList;NewRec : BOOLEAN);
   BEGIN
    WITH ListRec^ DO
     BEGIN
      IF NewRec THEN
       BEGIN
        INC(Filter.NumElements);
        WorkNo     := TRNRec.TRN_OrderNo;
        Revision   := TRNRec.TRN_Revision;
        Ingredient := TRNRec.TRN_Ingredient;
        WeightDone := TRNRec.TRN_ContainerWt;
        ContsDone  := 1;
        Next       := NIL;
       END
      ELSE
       BEGIN
        WeightDone := WeightDone + TRNRec.TRN_ContainerWt;
        INC(ContsDone);
       END;
     END;
   END;

  BEGIN
   Loop := ListHead;
   Last := NIL;
   IF Loop = NIL THEN
    BEGIN
     New(ListHead);
     FillChar(ListHead^,Sizeof(ListHead^),0);
     PrimeRecordWithTRN(ListHead,TRUE);
     EXIT;
    END;
   WHILE (Loop<>NIL) DO
    BEGIN
     IF Loop^.Ingredient = TRNRec.TRN_Ingredient THEN
      BEGIN
       PrimeRecordWithTRN(Loop,FALSE);
       EXIT;
      END;
     IF Loop^.Ingredient > TRNREc.TRN_Ingredient THEN
      BEGIN
       New(AddItem);
       Fillchar(AddItem^,Sizeof(AddItem^),0);
       PrimeRecordWithTRN(AddItem,TRUE);
       IF Last = NIL THEN
        BEGIN
         AddItem^.Next := ListHead;
         ListHead      := AddItem;
        END
       ELSE
        BEGIN
         AddItem^.Next := Loop;
         Last^.Next    := AddItem;
        END;
       EXIT;
      END;
     Last := Loop;
     Loop := loop^.Next;
    END;
   New(Loop);
   FillChar(Loop^,Sizeof(Loop^),0);
   PrimeRecordWithTRN(Loop,TRUE);
   Last^.Next := Loop;
  END;

BEGIN
 ListHead := NIL;
 ResetVars;
 GetFirstTransaction;
 WHILE (ReadTRNErr = 0)
 AND   (TRNRec.TRN_Date = TheDay) DO
  BEGIN
   IF  TransactionWithinFilter THEN
     AddRecordToList;
   GetNextTransaction;
  END;
 BuildTransactionListForDay := ListHead;
END;

PROCEDURE ClearTransactionList(VAR Header : PTRNList);
VAR Loop,Last : PTRNList;
BEGIN
 Loop := Header;
 WHILE (Loop <> NIL) DO
  BEGIN
   Last := Loop;
   Loop := Loop^.Next;
   Dispose(Last);
  END;
 Header := NIL;
END;

PROCEDURE ShowTodaysWeighings;
VAR
    ListHead  : PTRNList;
    Filter    : TbuildFilter;
    MaxCont    : LONGINT;
    MaxWt      : DOUBLE;
    ListEntries: LONGINT;
    NumEntries : LONGINT;
    TranDate   : LONGINT;
    ExitGraph  : BOOLEAN;
    SaveMsgState:TMsgWinState;

 PROCEDURE PrimeFilter;
 BEGIN
  FillChar(Filter,SizeOf(Filter),#0);
  WITH Filter DO
   BEGIN
    MID := GetCurrentMachineID;
   END;
 END;

 FUNCTION ShowContinueWindow : BOOLEAN;
 VAR C    : PChoiceBtn;
     Par  : PChoiceScreen;

 BEGIN
  New(Par,Init(MaxX-ChildWidth*2-32,MaxY-ChildHeight-16,MaxX-16,Maxy-16,C_WindowStaticText SHR 4,WT_Button OR WT_Visable));
  New(C,Init(MaxX-ChildWidth-16,MaxY-ChildHeight-16,Par,1,'Continue',FALSE));
  New(C,Init(MaxX-ChildWidth*2-32,MaxY-ChildHeight-16,Par,2,'EXIT',FALSE));
  REPEAT
   Wait_For_User_Input;
  UNTIL Par^.OptionSelected <> 0;
  IF Par^.OptionSelected = 2 THEN ExitGraph := TRUE;
  ShowContinueWindow := Par^.OptionSelected <> 1;
  Dispose(Par,Done);
 END;


 PROCEDURE GetListStatistics;
 VAR Loop : PTRNList;
 BEGIN
  MaxWt := 0.0;
  MaxCont := 0;
  ListEntries := 0;
  Loop := ListHead;
  WHILE (Loop<>NIL) DO
   BEGIN
    INC(ListEntries);
    IF Loop^.WeightDone > MaxWt THEN MaxWt := Loop^.WeightDone;
    IF Loop^.ContsDone  > MaxCont THEN MaxCont := Loop^.ContsDone;
    Loop := Loop^.Next;
   END;
 END;

 PROCEDURE DrawAxis(ListHeight : INTEGER);
 BEGIN
  ClrGraphWin;
  WriteStrAt(0,0,'Transaction On Day '+Days_To_Date(TranDate));
  DrawLine(SizeOf(TIngredientRef)*8,56,SizeOf(TIngredientRef)*8,56+ListHeight*24);
  DrawLine(SizeOf(TIngredientRef)*8,56+ListHeight*24,630,56+ListHeight*24);
 END;

 PROCEDURE DisplayContainerResults;
 CONST MaxBarSize = 630 - SizeOF(TIngredientRef)*8;

 VAR Loop,Last  : PTRNList;
     Counter    : DOUBLE;
     I,J        : INTEGER;
     Xpos,NewX  : INTEGER;
     ListHeight : INTEGER;


   PROCEDURE DisplayListItem(Item : PTRNList);
   VAR J : INTEGER;
       Xend : INTEGER;
   BEGIN
    WriteStrAt(1,I*3+4,Item^.Ingredient);
    XEnd :=SizeOf(TIngredientRef)*8+Round(Loop^.ContsDone*Counter);
    FOR J :=(I*3+4)*8-4 TO (I*3+5)*8+4 DO
     DrawLineHoriz(SizeOf(TIngredientRef)*8,XEnd,J,1);
   END;

 PROCEDURE SetScreen;
 VAR I : INTEGER;
 BEGIN
  ListHeight := Min(NumEntries,13);
  DrawAxis(ListHeight);
  WriteStrAt(1,3,'Containers Weighed Per Ingredient');
  Counter := MaxBarSize / MaxCont;
  XPos:= 0;NewX := 0;
  FOR I := 0 TO MaxCont DO
   BEGIN
    NewX := SizeOf(TIngredientRef)*8+Round(I*Counter);
    IF NewX>Xpos+32 THEN
     BEGIN
      WriteStrAtPixel(NewX-24,64+ListHeight*24,IntToStr(I,3));
      XPos := NewX
     END;
   END;
 END;

 BEGIN
  NumEntries := ListEntries;

  SetScreen;
  Loop := ListHead;
  I:=0;
  WHILE (Loop<>NIL) DO
   BEGIN
    INC(I);
    DEC(NumEntries);
    DisplayListItem(Loop);
    Loop := Loop^.Next;
    IF (I = 13) AND (NumEntries>0) THEN
     BEGIN
      IF ShowContinueWindow THEN EXIT;
      I := 0;
      SetScreen;
     END;
   END;
  ShowContinueWindow;
 END;

 PROCEDURE DisplayWeighingResults;
 CONST MaxBarSize = 630 - SizeOF(TIngredientRef)*8;

 VAR Loop,Last  : PTRNList;
     Counter    : DOUBLE;
     I,J        : INTEGER;
     Xpos,NewX  : INTEGER;
     ListHeight : INTEGER;


   PROCEDURE DisplayListItem(Item : PTRNList);
   VAR J : INTEGER;
       Xend : INTEGER;
   BEGIN
    WriteStrAt(1,I*3+4,Item^.Ingredient);
    XEnd :=SizeOf(TIngredientRef)*8+Round(Loop^.WeightDone*Counter);
    FOR J :=(I*3+4)*8-4 TO (I*3+5)*8+4 DO
     DrawLineHoriz(SizeOf(TIngredientRef)*8,XEnd,J,1);
   END;

 PROCEDURE SetScreen;
 VAR I : INTEGER;
 BEGIN
  ListHeight := Min(NumEntries,13);
  DrawAxis(ListHeight);
  WriteStrAt(1,3,'Total Weight Of Ingredients Weighed');
  Counter := (MaxBarSize-8) / (Round(MaxWt)+1);
  XPos:= 0;NewX := 0;
  FOR I := 0 TO (Round(MaxWt)+1) DO
   BEGIN
    NewX := SizeOf(TIngredientRef)*8+Round(I*Counter);
    IF NewX>Xpos+40 THEN
     BEGIN
      WriteStrAtPixel(NewX,64+ListHeight*24,IntToStr(I,1));
      XPos := NewX
     END;
   END;
 END;

 BEGIN
  NumEntries := ListEntries;
  SetScreen;
  Loop := ListHead;
  I:=0;
  WHILE (Loop<>NIL) DO
   BEGIN
    INC(I);
    Dec(NumEntries);
    DisplayListItem(Loop);
    Loop := Loop^.Next;
    IF (I = 13) AND (NumEntries >0) THEN
     BEGIN
      IF ShowContinueWindow THEN EXIT;
      I := 0;
      SetScreen;
     END;
   END;
  ShowContinueWindow;
 END;


BEGIN
 SetCurrentFont(DefaultFont);
 MessageWin.DisableMsgs(@SaveMsgState);
 ExitGraph := FALSE;
 TranDate := Date_To_Days(Date);
 PrimeFilter;
 ListHead := BuildTransactionListForDay(TranDate,Filter);
 IF ListHead = NIL THEN ExitGraph := TRUE;
 GetListStatistics;
 REPEAT
  ClrGraphWin;
  IF (NOT ExitGraph) AND (ListHead <> NIL) THEN DisplayContainerResults;
  IF (NOT ExitGraph) AND (ListHead <> NIL) THEN DisplayWeighingResults;
 UNTIL ExitGraph;
 ClearTransactionList(ListHead);
 MessageWin.RestoreMsgState(@SaveMsgState);
 ClrGraphWin;
END;

FUNCTION  BuildOrderTransactionListForMix(VAR Filter : TBuildFilter) : PTRNList;
VAR ListHead   : PTRNList;
    WorkHRec   : TWOHeaderRecord;
    WorkLRec   : TWOLineRecord;
    HReadErr   : INTEGER;
    LReadErr   : INTEGER;

  PROCEDURE AddToTranList;
  VAR Loop,Last,AddItem : PTRNList;

   PROCEDURE AddReqsToListRecord(ListRec : PTRNList;NewRec : BOOLEAN);
   VAR
     ContWts : DOUBLE;
   BEGIN
    WITH ListRec^ DO
     BEGIN
      IF NewRec THEN
       BEGIN
        INC(Filter.NumElements);
        WorkNo     := Filter.WorkNo;
        Revision   := Filter.Revision;
        Ingredient := WorkLRec.WOL_Ingredient;
        WeightDone := 0.0;
        ContsDone  := 0;
        Next       := NIL;
       END;
      EstimateIngredReqsForMixNo(Filter.MixNo, @WorkHRec, @WorkLRec,
                                 WeightReq, ContsReq, ContWts);
     END;
   END;

  BEGIN
   Loop := ListHead;
   Last := NIL;
   IF Loop = NIL THEN
    BEGIN
     New(ListHead);
     FillChar(ListHead^,Sizeof(ListHead^),0);
     AddReqsToListRecord(ListHead,TRUE);
     EXIT;
    END;
   WHILE (Loop<>NIL) DO
    BEGIN
     IF Loop^.Ingredient = WorkLRec.WOL_Ingredient THEN
      BEGIN
       AddReqsToListRecord(Loop,FALSE);
       EXIT;
      END;
     IF Loop^.Ingredient > WorkLRec.WOL_Ingredient THEN
      BEGIN
       New(AddItem);
       FillChar(AddItem^,Sizeof(AddItem^),0);
       AddReqsToListRecord(AddItem,TRUE);
       IF Last = NIL THEN
        BEGIN
         AddItem^.Next := ListHead;
         ListHead      := AddItem;
        END
       ELSE
        BEGIN
         AddItem^.Next := Loop;
         Last^.Next    := AddItem;
        END;
       EXIT;
      END;
     Last := Loop;
     Loop := loop^.Next;
    END;
   New(Loop);
   FillChar(Loop^,sizeof(Loop^),0);
   AddReqsToListRecord(Loop,TRUE);
   Last^.Next := Loop;
  END;



BEGIN
 ListHead := BuildTransactionListForMix(Filter);
 WorkHRec.WOH_OrderNo  := Filter.WorkNo;
 WorkHRec.WOH_Revision := Filter.Revision-1;
 HReadErr := WorkHeaderFile^.ReadRecord('EQ',FALSE,FALSE,WorkHRec,1);
 IF (HReadErr = 0) THEN
  BEGIN
   FillChar(WorkLRec,Sizeof(WorkLRec),0);
   WorkLRec.WOL_OrderNo  := WorkHRec.WOH_OrderNo;
   WorkLRec.WOL_Revision := WorkHRec.WOH_Revision;
   LReadErr := WorkLineFile^.ReadRecord('GE',FALSE,FALSE,WorkLRec,0);
   WHILE (LReadErr = 0) AND
         (WorkLREc.WOL_OrderNo = WorkHRec.WOH_OrderNo) AND
         (WorkLRec.WOL_Revision = WorkHRec.WOH_Revision) DO
    BEGIN
     AddToTranList;
     LReadErr := WorkLineFile^.ReadRecord('GN',FALSE,FALSE,WorkLRec,0);
    END;
  END;
 BuildOrderTransactionListForMix := ListHead;
END;

END.

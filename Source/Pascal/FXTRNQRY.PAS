(****************************************************************************
*  UNIT          : FXTRNQRY                                                 *
*  AUTHOR        : N.S Code Converted to OBJECT By S.W.                     *
*  DATE          : 12/05/2001                                               *
*  PURPOSE       : FORMIX Transaction Query Gizmo                           *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXTRNQRY;
INTERFACE
USES F6StdCtv,FXModCtv,FXMenu,F6DtConv,F6StdUtl,F6StdUt1,F6StdWin,F6StdWn1,F6RepSee,
     FXFTrn,F6StdRep,FXCfg,FXFIngr,FXBrw_IN,FXHelp{,FXFWork,FXFMacro};



TYPE TTransFilter = PACKED RECORD
      KeyNum     : WORD;                   { Index to use                   }
      MaxResults : LONGINT;                { Max Records To Return          }
      Ingredient : TIngredientRef;
      LineNo     : LONGINT;
      StartDay   : LONGINT;
      EndDay     : LONGINT;
      MinWorkNo  : LONGINT;
      MaxWorkNo  : LONGINT;
      MinMID     : WORD;
      MaxMID     : WORD;
      MinRunNo   : LONGINT;
      MaxRunNo   : LONGINT;
      MixNo      : WORD;
      IncludeAborted,
      IncludeActive : BOOLEAN;
      Detailed   : BOOLEAN;
      sMID,sMinorWo   : STRING[2];
      sSerial,sWorkNo : STRING[6];
      sBatchNo        : TBatchRef;
      SLotNo          : TLotRef;
      Date,Work,Batch : BOOLEAN;
      AllowDateRange  : BOOLEAN;
     END;


TYPE PTRNList = ^TTRNList;
     TTRNList = PACKED RECORD
      Date       : LONGINT;
      Time       : Time_Type;
      OrderNo    : LONGINT;              {Work Order No}
      Revision   : BYTE;
      RecipeNo   : TRecipeRef;
      Ingredient : TIngredientRef;       {Ingredient}
      LineNo     : LONGINT;
      Weight     : DOUBLE;               {Combined Weight Of all Ingredients}
      BatchNo    : TBatchRef;
      LotNo      : TLotRef;
      RunNo      : LONGINT;
      MID        : WORD;
      NumCont    : LONGINT;
      Status     : WORD;
      MixNo      : INTEGER;
      ContNo     : INTEGER;
      NEXT       : PTRNList;
     END;


TYPE TTranListSortType = (ST_Unsorted,ST_ByIngredient);

TYPE PTranList = ^TTranList;
     TTranList = OBJECT
       ListHead : PTRNList;
       ListSize : LONGINT;
       SortType : TTranListSortType;

       ListPtr  : PTRNList;

       CONSTRUCTOR Init(SortBy : TTranListSortType);
       DESTRUCTOR  Done;
       PROCEDURE   AddRecord(TRNRec : TTranRecord);   VIRTUAL;
       PROCEDURE   DisposeList;                       VIRTUAL;

       FUNCTION    GetLast : PTRNList;                VIRTUAL;
       FUNCTION    GetPrev : PTRNList;                VIRTUAL;
       FUNCTION    GetNext : PTRNList;                VIRTUAL;
       FUNCTION    SetFirst: PTRNList;                VIRTUAL;
       FUNCTION    GetSize : LONGINT;                 VIRTUAL;


     END;

TYPE PTRNQuery = ^TTrnQuery;
     TTRNQuery = OBJECT
       TRNRec        : TTranRecord;
       TRNFileOpen   : BOOLEAN;
       ReadTRNErr    : INTEGER;

       Filter        : TTransFilter;
       TranList      : PTranList;
       QueryFinished : Boolean;

       CONSTRUCTOR Init(DestTranList : PtranList);
       DESTRUCTOR  Done;                              VIRTUAL;

       PROCEDURE   GetFirstTransaction;               VIRTUAL;
       PROCEDURE   GetNextTransaction;                VIRTUAL;
       FUNCTION    QueryComplete : BOOLEAN;           VIRTUAL;
       PROCEDURE   SetFilter (AFilter : TTransFilter);VIRTUAL;

       FUNCTION    TransactionWithinFilter : BOOLEAN; VIRTUAL;
       FUNCTION    TRNWithinLimits         : BOOLEAN; VIRTUAL;
       PROCEDURE   ProcessSelectedRecord;             VIRTUAL;
       PROCEDURE   Run;                               VIRTUAL;

     END;


PROCEDURE InitFilter(VAR AFilter : TTransFilter);
PROCEDURE ExpandFilter(VAR AFilter : TTransFilter);

IMPLEMENTATION


CONSTRUCTOR TTranList.Init(SortBy : TTranListSortType);
BEGIN
 ListHead := NIL;
 ListPtr  := NIL;
 ListSize := 0;
 SortType := SortBy;
END;

DESTRUCTOR TTranList.Done;
BEGIN
 DisposeList;
END;


FUNCTION TTranList.SetFirst : PTRNList;
BEGIN
 ListPtr  := ListHead;
 SetFirst := ListPtr;
END;

FUNCTION TTRanList.GetNext : PTRNList;
BEGIN
 IF ListPtr <> NIL THEN ListPtr := ListPtr^.Next;
 GetNext := ListPtr;
END;


FUNCTION TTranList.GetPrev : PTRNList;
VAR TempPtr : PTRNList;
BEGIN
 TempPtr := ListHead;
 WHILE (TempPtr <> NIL) DO
  BEGIN
   IF TempPtr^.Next = ListPtr THEN Break;
   TempPtr := TempPtr^.Next;
  END;
 ListPtr := TempPtr;
 GetPrev := ListPtr;
END;

FUNCTION TTranList.GetLast : PTRNList;
BEGIN
 ListPtr := ListHead;
 IF ListPtr <> NIL THEN
  BEGIN
   WHILE (ListPtr^.Next <> NIL) DO ListPtr := ListPtr^.Next;
  END;
 GetLast := ListPtr;
END;

FUNCTION TTranList.GetSize : LONGINT;
BEGIN
  GetSize := ListSize;
END;


PROCEDURE TTranList.AddRecord(TRNRec : TTranRecord);
VAR Loop,Last : PTRNList;
    NewItem   : PTRNList;

   PROCEDURE PrimeListItemWithTRN(pNext : PTRNList);
   BEGIN
    New(NewItem);
    WITH NewItem^ DO
     BEGIN
      Date       := TRNRec.TRN_Date;
      Time       := TRNRec.TRN_Time;
      OrderNo    := TRNRec.TRN_OrderNo;
      Revision   := TRNRec.TRN_Revision;
      Ingredient := TRNRec.TRN_Ingredient;
      LineNo     := TRNRec.TRN_OrderLineNo;
      Weight     := TRNRec.TRN_ContainerWt;
      BatchNo    := TRNRec.TRN_BatchNo;
      LotNo      := TRNRec.TRN_LotNo;
      RecipeNo   := TRNRec.TRN_RecipeNo;
      RunNo      := TRNRec.TRN_SerialNo;
      MID        := TRNRec.TRN_Mid;
      NumCont    := 1;
      Status     := TRNRec.TRN_Status;
      MixNo      := TRNRec.TRN_MixNo;
      ContNo     := TRNRec.TRN_ContainerNo;
      Next       := pNext;
     END;
    INC(ListSize);
   END;

BEGIN
  Loop := ListHead;
  Last := NIL;

  CASE SortType OF

   ST_Unsorted : BEGIN

    PrimeListItemWithTRN(NIL);
    IF Loop = NIL THEN
     BEGIN
      ListHead := NewItem;
     END
    ELSE
     BEGIN
      WHILE (Loop^.Next <> NIL) DO Loop := Loop^.Next;
      Loop^.Next := NewItem;
     END;

   END; { END (CASE SortType OF ST_Unsorted) }

   ST_ByIngredient : BEGIN

    Loop := ListHead;
    Last := NIL;
    IF Loop = NIL THEN
     BEGIN
      PrimeListItemWithTRN(NIL);
      ListHead := NewItem;
     END
    ELSE
     BEGIN
      WHILE (Loop<>NIL) DO
       BEGIN
        IF Loop^.Ingredient > TRNRec.TRN_Ingredient THEN
         BEGIN
          PrimeListItemWithTRN(Loop);
          IF Last = NIL THEN ListHead := NewItem
          ELSE Last^.Next := NewItem;
          EXIT;
         END;
        Last := Loop;
        Loop := loop^.Next;
       END;
      PrimeListItemWithTRN(NIL);
      Last^.Next := NewItem;
     END;
    END; {END (CASE SortType OF ST_ByIngredient) }

   END; { END (CASE SortType) }
END;


PROCEDURE TTranList.DisposeList;
VAR Loop,Last : PTRNList;
BEGIN
 Loop := ListHead;
 WHILE (Loop <> NIL) DO
  BEGIN
   Last := Loop;
   Loop := Loop^.Next;
   Dispose(Last);
   DEC(ListSize);
  END;
 ListHead := NIL;
END;


(************************** TTRNQuery METHODS ******************************)

CONSTRUCTOR TTRNQuery.Init;
BEGIN
 TranList      := DestTranList;
 TRNFileOpen   := TransFile^.OpenFile = 0;
 InitFilter(Filter);
 QueryFinished := TRUE;
END;

DESTRUCTOR TTRNQuery.Done;
BEGIN
 IF TRNFileOpen THEN TransFile^.CloseFile;
END;

PROCEDURE TTRNQuery.SetFilter(AFilter : TTransFilter);
BEGIN
 Filter := AFilter;
 QueryFinished := TRUE;
END;


PROCEDURE TTRNQuery.GetFirstTransaction;
BEGIN
 { QueryFinished (TRUE) = Use Filter to start a new query                   }
 { "           " (FALSE)= Use Last Record Read to continue a query          }

 IF QueryFinished THEN
  BEGIN
   FillChar(TRNRec,SizeOf(TRNRec),#0);
   CASE Filter.KeyNum OF
   0:BEGIN
      TRNRec.TRN_Date     := Filter.StartDay;
      TRNRec.TRN_OrderNo  := Filter.MinWorkNo;
      TRNRec.TRN_Revision := 0;
    END;
   1:BEGIN
      TRNRec.TRN_MID      := Filter.MINMID;
      TRNRec.TRN_SerialNo := Filter.MinRunNo;
    END;
   2:BEGIN
      TRNRec.TRN_OrderNo  := Filter.MinWorkNo;
      VAL(Filter.sMinorWO,TRNRec.TRN_Revision,ReadTRNErr);
     END;
   END;
  END;

  ReadTRNErr := TransFile^.ReadRecord('GE',FALSE,FALSE,TRNRec,Filter.KeyNum);
END;


PROCEDURE TTRNQuery.GetNextTransaction;
BEGIN
  ReadTRNErr := TransFile^.ReadRecord('GN',FALSE,FALSE,TRNRec,Filter.KeyNum);
  CASE Filter.KeyNum OF
  0:BEGIN END;

  1:BEGIN
     IF ReadTRNErr = 0 THEN
      BEGIN
       IF Filter.MaxRunNo = 0 THEN Filter.MaxRunNo := MaxLongInt;

       IF TRNRec.TRN_SerialNo < Filter.MinRunNo THEN
        BEGIN
         TRNRec.TRN_SerialNo := Filter.MinRunNo;
         ReadTRNErr := TransFile^.ReadRecord('GE',FALSE,FALSE,TRNRec,Filter.KeyNum);
        END
       ELSE IF TRNRec.TRN_SerialNo > Filter.MaxRunNo THEN
        BEGIN
         INC(TRNRec.TRN_MID);
         TRNRec.TRN_SerialNo := Filter.MinRunNo;
         ReadTRNErr := TransFile^.ReadRecord('GE',FALSE,FALSE,TRNRec,Filter.KeyNum);
        END;
      END;
    END;

  2:BEGIN END;

  END;

END;
FUNCTION TTRNQuery.QueryComplete : BOOLEAN;
BEGIN
 QueryComplete := QueryFinished;
END;


FUNCTION TTRNQuery.TransactionWithinFilter : BOOLEAN;
BEGIN
  TransactionWithinFilter := FALSE;
  WITH Filter,TRNRec DO
   BEGIN
    IF (NOT IncludeAborted) AND (TRN_Status = TRNStatusAborted) THEN EXIT;
    IF (NOT IncludeActive)  AND (TRN_Status = TRNStatusActive) THEN EXIT;
    IF (NOT NowtButSpace(sWorkNo)) AND (NOT Str_Equal(sWorkNo,IntToZeroStr(TRN_OrderNo,6),Length(sWorkNo))) THEN EXIT;
    IF (NOT NowtButSpace(sMinorWo)) AND (NOT Str_Equal(sMinorWo,IntToZeroStr(TRN_Revision,2),Length(sMinorWo))) THEN EXIT;
    IF (NOT NowtButSpace(sMID))    AND (NOT Str_Equal(sMID,IntToZeroStr(TRN_MID,2),Length(sMID))) THEN EXIT;
    IF (NOT NowtButSpace(sSerial)) AND (NOT Str_Equal(sSerial,IntToZeroStr(TRN_SerialNo,6),Length(sSerial))) THEN EXIT;
    IF (AllowDateRange) AND ((StartDay  > TRN_Date) OR (EndDay < TRN_Date)) THEN EXIT;
    IF (LineNo <> 0) AND (LineNo <> TRN_OrderLineNo) THEN EXIT;
    IF (NOT NowtButSpace(Ingredient)) AND (NOT Str_Equal(Ingredient,TRN_Ingredient,Length(Ingredient))) THEN EXIT;
    IF (NOT NowtButSpace(sBatchNO)) AND (NOT Str_Equal(sBatchNo,TRN_BatchNo,Length(sBatchNo))) THEN EXIT;
    IF (NOT NowtButSpace(sLotNo)) AND (NOT Str_Equal(sLotNo,TRN_LotNo,Length(sLotNo))) THEN EXIT;
    IF (MixNo <> 0) AND (MixNo <> TRN_MixNo) THEN EXIT;
   END;
  TransactionWithinFilter := TRUE;
END;

FUNCTION TTRNQuery.TRNWithinLimits : BOOLEAN;
BEGIN
 CASE Filter.KeyNum OF
   0 : TRNWithinLimits := Filter.EndDay    >= TRNRec.TRN_Date;
   1 : TRNWithinLimits := Filter.MaxMid    >= TRNRec.TRN_MID;
   2 : TRNWithinLimits := Filter.MaxWorkNo >= TRNRec.TRN_OrderNo;
 END;
END;


PROCEDURE TTRNQuery.ProcessSelectedRecord;
BEGIN
 TranList^.AddRecord(TRNRec);
END;

PROCEDURE TTRNQuery.Run;
BEGIN
 IF TRNFileOpen THEN
  BEGIN
   { If a contiuation of a query then clear previous results                }
   IF NOT QueryFinished THEN TranList^.DisposeList;

   GetFirstTransaction;
   IF (ReadTRNErr = 0) AND TRNWithinLimits THEN
    BEGIN
     REPEAT
      IF TransactionWithinFilter THEN ProcessSelectedRecord;
      GetNextTransaction;
     UNTIL(ReadTRNErr <> 0) OR (NOT TRNWithinLimits) OR
          (TranList^.GetSize >= Filter.MaxResults);

     { Is Query Complete }
     IF (ReadTrnErr = 0) AND (TranList^.GetSize >= Filter.MaxResults) THEN
       QueryFinished := FALSE
     ELSE
       QueryFinished := TRUE;

    END
   ELSE
    BEGIN
     IF ReadTRNErr = 9 THEN
      BEGIN
       Filter.StartDay := -1;
       Filter.MINMid   := 255;
       QueryFinished   := TRUE;
      END

     ELSE
      IF ReadTrnErr = 0 THEN
       BEGIN
        IF Filter.KeyNum = 0 THEN
         Filter.StartDay := TRNRec.TRN_Date-1
        ELSE
         Filter.MinMid := TRNRec.TRN_MID-1;
        QueryFinished := TRUE;
       END;
    END;
  END;
END;

PROCEDURE InitFilter(VAR AFilter : TTransFilter);
BEGIN
 FillChar(AFilter,SizeOf(AFilter),#0);
 AFilter.KeyNum         := 0;
 AFilter.MaxResults     := MaxLongInt;
 AFilter.sMid           := SPACE_STRING;
 AFilter.sSerial        := SPACE_STRING;
 AFilter.sWorkNo        := SPACE_STRING;
 AFilter.sMinorWo       := SPACE_STRING;
 AFilter.sBatchNo       := SPACE_STRING;
 AFilter.sLotNo         := SPACE_STRING;
 AFilter.StartDay       := Date_To_Days(Date);
 AFilter.EndDay         := Date_To_Days(Date);
 AFilter.Ingredient     := SPACE_STRING;
 AFilter.IncludeActive  := TRUE;
 AFilter.IncludeAborted := TRUE;
 AFilter.AllowDateRange := FALSE;
END;

PROCEDURE ExpandFilter(VAR AFilter : TTransFilter);
VAR sMin,sMax : STRING[6];
    Errint    : INTEGER;
BEGIN
 WITH AFilter DO
  BEGIN
   IF NOT AllowDateRange THEN
    BEGIN
     StartDay := 0;
     EndDay   :=Date_To_Days('31/12/2099');
    END;

   IF NowtButSpace(sMid) THEN sMid :='??';
   {Machine ID Filter}
   GetMaskNumExtents(sMID,sMin,sMax);
   VAL(sMin,MinMID,Errint);
   VAL(sMax,MaxMID,ErrInt);
   IF NowtButSpace(sSerial) THEN sSerial :='??????';
   {Serial No Filter}
   GetMaskNumExtents(sSerial,sMin,sMax);
   VAL(sMin,MinRunNo,Errint);
   VAL(sMax,MaxRunNo,Errint);
   IF NowtButSpace(sWorkNo) THEN sWorkNo :='??????';
   {Work Order Number Filter}
   GetMaskNumExtents(sWorkNo,sMin,sMax);
   VAL(sMin,MinWorkNo,ErrInt);
   VAL(sMax,MaxWorkNo,ErrInt);
  END;
END;

END.

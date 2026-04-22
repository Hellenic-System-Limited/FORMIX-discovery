(****************************************************************************
*  UNIT          : FXPUSAGE                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 12/05/96                                                 *
*  PURPOSE       : FORMIX Transaction file reporter                         *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXPUSAGE;
INTERFACE
USES F6StdCtv,FXModCtv,FXMenu,F6DtConv,F6StdUtl,F6StdUt1,F6StdWin,F6StdWn1,F6RepSee,
     FXTrnQry,FXFTrn,F6StdRep,FXCfg,FXFIngr,FXBrw_IN,FXHelp,FXFWork,FXFMacro;


PROCEDURE Print_Ingredient_Usage;
PROCEDURE Print_Transactions;
(*
FUNCTION  BuildTransactionList(VAR Filter:TTransFilter;Key : INTEGER):PTRNList;

PROCEDURE ClearTransactionList(VAR Header : PTRNList);
*)
TYPE
     UsageListType = (batchlisttype,orderlisttype,grandtotallisttype,dailylisttype,detaillisttype);


TYPE CompareFunc = FUNCTION(pA,pB : PTRNList) :INTEGER;


TYPE PIngredientUsageReport = ^TIngredientUsageReport;
     TIngredientUsageReport  = OBJECT(TReportObject)

      TrnQueryView : PTranList;
      TrnQuery     : PTrnQuery;
      Filter       : TTransFilter;
      CurrentDate  : LONGINT;
      QueryRec     : PTRNList;


      GrandTotalList : PTRNList;         {Sorted By Ingredient}
      DailyTotalList : PTRNList;         {Sorted By Ingredient}
      WorkTotalList  : PTRNList;         {Sorted By Order No/By Ingredient}
      BatchList      : PTRNList;         {Sorted By Batch No/By Ingredient}

      PROCEDURE   ReportSetup; Virtual;
      PROCEDURE   PrintColumnHeadings; Virtual;
      PROCEDURE   PrintReportBody; Virtual;
      PROCEDURE   OutputReport; Virtual;
      PROCEDURE   PrintSubHeadIngs(ListType : UsageListType);
      FUNCTION    GetIngredientName(VAR Ingredient : TIngredientRef) : STRING;
      PROCEDURE   AddToGrandTotal(pItem : PTRNList);
      PROCEDURE   AddToDailyTotal(PItem : PTRNList);
      PROCEDURE   AddToWorkTotalList(pItem : PTRNList);
      PROCEDURE   AddToBatchList(pItem : PTRNList);
      PROCEDURE   AddToListTotal(VAR pTotalList,pItem : PTRNList;Func : CompareFunc);
      PROCEDURE   ClearTranTotalList(VAR Header : PTRNList);
      PROCEDURE   ShowTotalsForList(pHeader : PTRNList;ListType : UsageListType);
      PROCEDURE   WriteTotals(TotWt : DOUBLE;TotCont : LONGINT;ListType : UsageListType);
      FUNCTION    GetSelectionCriteria : BOOLEAN; VIRTUAL;
      PROCEDURE   RunMacroReport(CopyFilter : TFilter);VIRTUAL;
     END;


TYPE PTransactionReport = ^TTransactionReport;
     TTransactionReport = OBJECT(TReportObject)

      ListHeader   : PTRNList;
      Filter       : TTransFilter;
      TrnQueryView : PTranList;
      TrnQuery     : PTrnQuery;


      TrnFound    : LONGINT;
      TotalWt     : DOUBLE;

      PROCEDURE   ReportSetup; Virtual;
      PROCEDURE   PrintColumnHeadings; Virtual;
      PROCEDURE   PrintReportBody; Virtual;
      PROCEDURE   OutputReport; Virtual;
      FUNCTION    GetSelectionCriteria : BOOLEAN; VIRTUAL;
      PROCEDURE   RunMacroReport(CopyFilter : TFilter);VIRTUAL;
     END;

IMPLEMENTATION
CONST EditX = 25;


VAR
   Editpos        : INTEGER;
   lDate          : LONGINT;
   WrkStr         : STRING[10];
   EditLen        : INTEGER;


PROCEDURE DrawCriteriaWindow(VAR CritWin : WindowRecord;ForUsage : BOOLEAN);
CONST HeaderTxt1 = 'Ingredient Assignment Report';
CONST HeaderTxt2 = 'Transaction Report';

 PROCEDURE WriteStaticText;
 BEGIN
  IF ForUsage THEN
   Header(HeaderTxt1,1)
  ELSE
   Header(HeaderTxt2,1);
  Footer('ESC-Exit  F2-Report  F3-Save Macro',1);
      WriteAt(2,3 ,'   Use Date Range      [ ]');
      WriteAt(2,4 ,'   Min Date            [  /  /    ]');
      WriteAt(2,5 ,'   Max Date            [  /  /    ]');
  HighWriteAt(2,6 ,'   Ingredient Matching [        ]');
      WriteAt(2,7 ,'   Machine ID          [  ]');
      WriteAt(2,8 ,'   Serial Number       [      ]');
      WriteAt(2,9 ,'   Work Order Number   [      ]');
      WriteAt(2,10,'   Batch Number        [      ]');
      WriteAt(2,11,'   Lot Number          [              ]');
      WriteAt(2,12,'   Include Active      [ ]');
      WriteAt(2,13,'   Include Aborted     [ ]');
  IF ForUsage THEN
   BEGIN
      WriteAt(2,14,'   Detail Report       [ ]');
      WriteAt(2,16,'   Total By Date       [ ]');
      WriteAt(2,17,'   Total By Order No   [ ]');
      WriteAt(2,18,'   Total By Batch No   [ ]');
    Footer(' Group Total Report Options',5);
   END;
 END;

BEGIN
 BackColourScheme;
 IF ForUsage THEN
  SetWindow(10,2,56,22,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,CritWin)
 ELSE
  SetWindow(10,5,56,21,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,CritWin);
 WriteStaticText;
 ForeColourScheme;
END;

PROCEDURE WriteInfo(VAR Filter : TTransFilter;Usage : BOOLEAN);
BEGIN
 WriteTickBox(EditX,3,Filter.AllowDateRange);

 IF Filter.AllowDateRange THEN WriteField(EditX, 4,Days_To_Date(Filter.StartDay),TRUE);
 IF Filter.AllowDateRange THEN WriteField(EditX, 5,Days_To_Date(Filter.EndDay),TRUE);
 WriteField(EditX, 6,Filter.Ingredient,TRUE);
 WriteField(EditX, 7,Filter.sMID,TRUE);
 WriteField(EditX, 8,Filter.sSerial,TRUE);
 WriteField(EditX, 9,Filter.sWorkNo,TRUE);
 WriteField(EditX,10,Filter.sBatchNo,TRUE);
 WriteField(EditX,11,Filter.sLotNo,TRUE);
 WriteTickBox(EditX,12,Filter.IncludeActive);
 WriteTickBox(EditX,13,Filter.IncludeAborted);
 IF Usage THEN
  BEGIN
   WriteTickBox(EditX,14,Filter.Detailed);
   WriteTickBox(EditX,16,Filter.Date);
   WriteTickBox(EditX,17,Filter.Work);
   WriteTickBox(EditX,18,Filter.Batch);
  END;
END;

PROCEDURE OutputValue(VAR Filter : TTransFilter);
BEGIN
 CASE EditPos OF
  2 : Filter.StartDay   := lDate;
  3 : Filter.EndDay     := lDate;
  4 : Filter.Ingredient := WrkStr;
  5 : Filter.sMID       := WrkStr;
  6 : Filter.sSerial    := WrkStr;
  7 : Filter.sWorkNo    := WrkStr;
  8 : Filter.sBatchNo   := WrkStr;
  9 : Filter.sLotNo     := WrkStr;
 END;
END;

PROCEDURE InputValue(VAR Filter : TTRansFilter);
BEGIN
 CASE EditPos OF
  1     : GetBoolean(Filter.AllowDateRange,EditX,3,TickBox);
  2,3   : IF Filter.AllowDateRange THEN GetDate(lDate,EDitX,2+EditPos);
  4     : GetLine(WrkStr,EditLen,EditX,2+EditPos);
  5,6,7 : GetWildNumLine(WrkStr,EditLen,EditX,2+EditPos);
  8,9   : GetLine(WrkStr,EditLen,EditX,2+EditPos);
  10    : GetBoolean(Filter.IncludeActive,EditX,2+EditPos,TickBox);
  11    : GetBoolean(Filter.IncludeAborted,EditX,2+EditPos,TickBox);
  12    : GetBoolean(Filter.Detailed,EditX,2+EditPos,TickBox);
  13    : GetBoolean(Filter.Date,EDitX,3+EditPos,TickBox);
  14    : GetBoolean(Filter.Work,EDitX,3+EditPos,TickBox);
  15    : GetBoolean(Filter.Batch,EDitX,3+EditPos,TickBox);
 END;
END;

PROCEDURE PrimeValue(VAR Filter : TTransFilter);
BEGIN
 CASE EditPos OF
  2 : lDate := Filter.StartDay;
  3 : lDate := Filter.EndDay;
  4 : BEGIN
       EditLen := 8;
       WrkStr  := Filter.Ingredient;
      END;
  5 : BEGIN
       EditLen := 2;
       WrkStr  := Filter.sMID;
      END;
  6 : BEGIN
       EditLen := 6;
       WrkStr  := Filter.sSerial;
      END;
  7 : BEGIN
       EditLen := 6;
       WrkStr  := Filter.sWorkNo;
      END;
  8 : BEGIN
       EditLen := 6;
       WrkStr := Filter.sBatchNo;
      END;
  9 : BEGIN
       EditLen := 14;
       WrkStr := Filter.sLotNo;
      END;
 END;
END;


FUNCTION TIngredientUsageReport.GetSelectionCriteria : BOOLEAN;
VAR CritWin        : WindowRecord;

 PROCEDURE CheckCh1;
 VAR TransferBuff : TIngredient_Record;
     FilterBuff   : TFilter;
     FilterSave   : TTransFilter;
     TodayInDays  : LONGINT;
 BEGIN
  CASE Ch1 OF
   NEXT : IF EditPos<15 THEN Inc(EditPos) ELSE EditPos :=1;
   PREV : IF EditPos>1  THEN Dec(EditPos) ELSE EditPos :=15;
   FN_F1: IF EditPos = 4 THEN
    BEGIN
     TransferBuff.ING_Ingredient := Filter.Ingredient;
     IngredientLookup(@TransferBuff);
     IF NOT NowtButSpace(TransferBuff.ING_Ingredient) THEN
      Filter.Ingredient  := TransferBuff.ING_Ingredient;
    END;
   FN_F3 : BEGIN
            ToDayInDays := Date_To_Days(Date);
            FXTRNQRY.ExpandFilter(Filter);
            Dec(Filter.StartDay,TodayInDays);
            Dec(Filter.EndDay,TodayInDays);
            FillChar(FilterBuff,SizeOf(TFilter),#0);
            Move(FilterSave,FilterBuff,SizeOf(FilterSave));
            Inc(Filter.StartDay,TodayInDays);
            Inc(Filter.EndDay,TodayInDays);
            RepMacroFile^.AddNewRepMacroRecord(AssignmentReportTitle,@FilterBuff);
           END;
  END;
 END;

BEGIN
 FXTRNQRY.InitFilter(Filter);
 DrawCriteriaWindow(CritWin,TRUE);
 EditPos := 1;
 REPEAT
  WriteInfo(Filter,TRUE);
  PrimeValue(Filter);
  InputValue(Filter);
  OutPutValue(Filter);
  CheckCH1;
 UNTIL (Ch1 = ESC) OR (Ch1=FN_F2);
 FXTRNQRY.ExpandFilter(Filter);
 LoseWindow(CritWin);
 GetSelectionCriteria := Ch1 <> ESC;
END;


FUNCTION TTransactionReport.GetSelectionCriteria : BOOLEAN;
VAR CritWin : WindowRecord;

 PROCEDURE CheckCh1;
 VAR TransferBuff : TIngredient_Record;
     FilterBuff   : TFilter;
     FilterSave   : TTransFilter;
 BEGIN
  CASE Ch1 OF
   NEXT : IF EditPos<11 THEN Inc(EditPos) ELSE EditPos :=1;
   PREV : IF EditPos>1  THEN Dec(EditPos) ELSE EditPos :=11;
   FN_F1: IF EditPos = 4 THEN
    BEGIN
     TransferBuff.ING_Ingredient := Filter.Ingredient;
     IngredientLookup(@TransferBuff);
     IF NOT NowtButSpace(TransferBuff.ING_Ingredient) THEN
      Filter.Ingredient  := TransferBuff.ING_Ingredient;
    END;
   FN_F3 : BEGIN
            FilterSave := Filter;
            ExpandFilter(FilterSave);
            FillChar(FilterBuff,SizeOf(TFilter),#0);
            Move(FilterSave,FilterBuff,SizeOf(FilterSave));
            RepMacroFile^.AddNewRepMacroRecord(TranReportTitle,@FilterBuff);
           END;
  END;
 END;

BEGIN
 DrawCriteriaWindow(CritWin,FALSE);
 FXTRNQRY.InitFilter(Filter);
 EditPos := 1;
 REPEAT
  WriteInfo(Filter,FALSE);
  PrimeValue(Filter);
  InputValue(Filter);
  OutPutValue(Filter);
  CheckCH1;
 UNTIL (Ch1 = ESC) OR (Ch1=FN_F2);
 FXTRNQRY.ExpandFilter(Filter);
 LoseWindow(CritWin);
 GetSelectionCriteria := Ch1 <> ESC;
END;


PROCEDURE TIngredientUsageReport.ClearTranTotalList(VAR Header : PTRNList);
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

PROCEDURE TIngredientUsageReport.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
 ReportTitle    := 'Ingredient Assignment';
END;

PROCEDURE TIngredientUsageReport.PrintColumnHeadings;
BEGIN
 PrintLn;
 PrintLnAt(CursorX,'Showing Ingredients Weighed On '+Days_To_Date(CurrentDate));
 PrintLnAt(CursorX,'Ingredient    Weight Recipe No Order No  Mix Cont No Batch No Lot No');
 PrintLnAt(CursorX,'---------- --------- --------- --------- --- ------- -------- --------------');
END;

PROCEDURE TIngredientUsageReport.PrintSubHeadings(ListType : UsageListType);
BEGIN
 PrintLn;
 CASE ListType OF
  dailylisttype      : PrintLnAt(CursorX,'Totals For '+Days_To_Date(CurrentDate));
  batchlisttype      : PrintLnAt(CursorX,'Totals Grouped By Batch');
  orderlisttype      : PrintLnAt(CursorX,'Totals Grouped By Order Number');
  grandtotallisttype : PrintLnAt(CursorX,'Grand Totals For All Selected Items');
 END;

 CASE ListType OF
  batchlisttype : BEGIN
   PrintLnAt(CursorX,'Batch No  Ingredient  Description                   Total Wt.  Containers');
   PrintLnAt(CursorX,'--------  ----------  ----------------------------  ---------  ----------');
  END;

  orderlisttype : BEGIN
   PrintLnAt(CursorX,'Order No  Ingredient  Description                   Total Wt.  Containers');
   PrintLnAt(CursorX,'--------- ----------  ----------------------------  ---------  ----------');
  END;

  dailylisttype,
  grandtotallisttype : BEGIN
   PrintLnAt(CursorX,'Ingredient  Description                   Total Wt.  Containers');
   PrintLnAt(CursorX,'----------  ----------------------------  ---------  ----------');
  END;
 END; {CASE }
END;


PROCEDURE TIngredientUsageReport.WriteTotals(TotWt : DOUBLE;TotCont : LONGINT;ListType : UsageListType);
BEGIN
 IF (TotWt > 0.0) OR (TotCont > 0) THEN
  BEGIN
   CASE ListType OF
    batchlisttype,
    orderlisttype : BEGIN
     PrintLnAt(CursorX,'                                                    ---------  ----------');
     PrintLnAt(CursorX,'                                      Totals        '+
                       DoubleToStr(TotWt,9,3)+'      '+IntToStr(TotCont,6));
    END;

    detaillisttype: BEGIN
     PrintLnAt(CursorX,'           ---------');
     PrintLnAt(CursorX,' Total     '+DoubleToStr(TotWt,9,3)+'   Containers '+IntToStr(TotCont,6));
    END;

    dailylisttype,
    grandtotallisttype : BEGIN
     PrintLnAt(CursorX,'                                          ---------  ----------');
     PrintLnAt(CursorX,'                             Totals       '+
                       DoubleToStr(TotWt,9,3)+'      '+IntToStr(TotCont,6));
    END;

   END;
  END;
END;

FUNCTION TIngredientUsageReport.GetIngredientName(VAR Ingredient : TIngredientRef) : STRING;
VAR RecBuff : TIngredient_Record;
BEGIN
 IF IngredientFile^.GetIngredient(Ingredient,RecBuff,FALSE) = 0 THEN
  GetIngredientName := Recbuff.ING_Description
 ELSE
  GetIngredientName := COPY('Ingredient Not Found'+SPACE_STRING,1,30);
END;

FUNCTION CompareIngredients(pA,pB : PTRNList) : INTEGER;
BEGIN
 IF pA^.Ingredient = pB^.Ingredient THEN CompareIngredients := 0
 ELSE
  IF pA^.Ingredient < pB^.Ingredient THEN CompareIngredients := 1
 ELSE CompareIngredients :=-1;
END;

FUNCTION CompareOrderAndIngredient(pA,pB : PTRNList) : INTEGER;
BEGIN
 IF (pA^.OrderNo =pB^.OrderNO) AND (pB^.Revision = pA^.Revision) THEN
  BEGIN
   IF pA^.Ingredient = pB^.Ingredient THEN CompareOrderAndIngredient := 0
   ELSE
    IF pA^.Ingredient < pB^.Ingredient THEN CompareOrderAndIngredient := 1
   ELSE CompareOrderAndIngredient :=-1;
  END
 ELSE IF (pA^.OrderNo = pB^.OrderNo) THEN
  BEGIN
   IF (pA^.Revision < pB^.Revision) THEN CompareOrderAndIngredient := 1
   ELSE CompareOrderAndIngredient := -1;
  END
 ELSE
  IF pA^.OrderNo < pB^.OrderNo THEN CompareOrderAndIngredient := 1
 ELSE CompareOrderAndIngredient := -1;
END;

FUNCTION CompareBatchAndIngredient(pA,pB : PTRNList) : INTEGER;
BEGIN
 IF pA^.BatchNo =pB^.BatchNO THEN
  BEGIN
   IF pA^.Ingredient = pB^.Ingredient THEN CompareBatchAndIngredient := 0
   ELSE
    IF pA^.Ingredient < pB^.Ingredient THEN CompareBatchAndIngredient := 1
   ELSE CompareBatchAndIngredient := -1;
  END
 ELSE IF pA^.BatchNo < pB^.BatchNo THEN CompareBatchAndIngredient := 1
 ELSE CompareBatchAndIngredient := -1;
END;

{Sorted By Ingredient Only}
PROCEDURE TIngredientUsageReport.AddToListTotal(VAR pTotalList,pItem : PTRNList;Func : CompareFunc);
VAR Loop,Last : PTRNList;

  PROCEDURE AddTotals(VAR pListItem,pItemToAdd : PTRNList);
  BEGIN
   pListItem^.Weight  :=pListItem^.Weight+pItemToAdd^.Weight;
   INC(PListItem^.NumCont);
  END;

  PROCEDURE AddToFront(VAR pFront,pItem : PTRNList);
  VAR NewItem : PTRNList;
  BEGIN
   New(NewItem);
   NewItem^ := pItem^;    {Copy Items Accross}
   NewItem^.Next := pFront;    {add To Link List}
   pFront   := NewItem;   {Set As First Item}
  END;

  PROCEDURE AddBetween(VAR pAfterThis,pBeforeThis,pItem : PTRNList);
  VAR NewItem : PTRNList;
  BEGIN
   New(NewItem);
   NewItem^ := pItem^;    {Copy Items Accross}
   pAfterThis ^.Next := NewItem;  {Add Link From Previous Item}
   NewItem^.Next := pBeforeThis;  {add Link To Next Item}
  END;

  PROCEDURE AddAfter(VAR pAfterThis,pItem : PTRNList);
  VAR NewItem : PTRNList;
  BEGIN
   New(NewItem);
   NewItem^ := pItem^;
   NewItem^.Next := NIL;
   pAfterThis^.Next := NewItem;
  END;


BEGIN
 IF pTotalList = NIL THEN
  BEGIN
   AddToFront(pTotalList,pItem);
   EXIT;
  END;
 Loop := pTotalList;
 Last := NIL;
 WHILE (Loop <> NIL) DO
  BEGIN
   CASE Func(Loop,pItem) OF
    0 :BEGIN
     AddTotals(Loop,pItem);
     EXIT;
    END;
    -1 : BEGIN
     IF Last = NIL THEN
      BEGIN
       AddToFront(pTotalList,pItem);
      END
     ELSE
      BEGIN
       AddBetween(Last,Loop,pItem);
      END;
     EXIT;
    END;
   END;
   Last := Loop;
   Loop := Loop^.Next;
  END;
 AddAfter(Last,pItem);
END;

{Sorted By Order No/By Ingredient}
PROCEDURE TIngredientUsageReport.AddToWorkTotalList(pItem : PTRNList);
BEGIN
 AddToListTotal(WorkTotalList,pItem,CompareOrderAndIngredient);
END;

PROCEDURE TIngredientUsageReport.AddToGrandTotal(pItem : PTRNList);
BEGIN
 AddToListTotal(GrandTotalList,pItem,CompareIngredients);
END;

PROCEDURE TIngredientUsageReport.AddToDailyTotal(PItem : PTRNList);
BEGIN
 AddToListTotal(DailyTotalList,PItem,CompareIngredients);
END;

PROCEDURE TIngredientUsageReport.AddToBatchList(pItem : PTRNList);
BEGIN
 AddToListTotal(BatchList,pItem,CompareBatchAndIngredient);
END;


PROCEDURE TIngredientUsageReport.ShowTotalsForList(pHeader : PTRNList;ListType : UsageListType);
VAR Loop    : PTRNList;
    TotWt   : DOUBLE;
    TotCont : LONGINT;
BEGIN
 IF pHeader = NIL THEN Exit;
 {Sum totals For that day}
 TotWt   := 0.0;
 TotCont := 0;

 CheckPageBreak(5,TRUE);
 PrintSubHeadings(ListType);
 Loop := pHeader;
 WHILE (Loop<>NIL) DO
  BEGIN
   TotWt := TotWt+Loop^.Weight;
   INC(TotCont,Loop^.NumCont);
   IF CheckPageBreak(5,TRUE) THEN PrintSubHeadings(ListType);

   CASE ListType OF
    batchlisttype : PrintAt(CursorX,'  '+Loop^.BatchNo+'  ');
    orderlisttype : PrintAt(CursorX,OrderNoToStr(Loop^.OrderNo,Loop^.Revision)+' ');
    dailylisttype : BEGIN END;
   END;

   PrintLnAt(CursorX,'  '+Loop^.Ingredient+'  '+GetIngredientName(Loop^.Ingredient)+
                   DoubleToStr(Loop^.Weight,9,3)+'      '+IntToZeroStr(Loop^.NumCont,6));
   Loop := Loop^.Next;
  END;
 WriteTotals(TotWt,TotCont,ListType);

END;


PROCEDURE TIngredientUsageReport.PrintReportBody;
BEGIN
 IF Filter.Detailed THEN
  BEGIN
   IF CheckPageBreak(3,TRUE) THEN PrintColumnHeadings;
   WITH QueryRec^ DO
    BEGIN
     PrintLnAt(CursorX,Ingredient+'   '+
                       DoubleToStr(Weight,9,3)+' '+
                       '  '+RecipeNo+
                       OrderNoToStr(OrderNo,Revision)+
                       ' '+IntToZeroStr(MixNo,3)+'  '+
                       '   '+IntToZeroStr(Contno,3)+
                       '   ' +BatchNo+
                       ' '  +LotNo);
    END; { WITH }
  END;
END;


PROCEDURE TIngredientUsageReport.OutputReport;
VAR TransFound : BOOLEAN;
    TotWt      : DOUBLE;
    TotCont    : LONGINT;

BEGIN
 GrandTotalList := NIL;
 DailyTotalList := NIL;
 WorkTotalList  := NIL;
 BatchList      := NIL;
 TransFound     := FALSE;

 Filter.KeyNum     := 0;                           { Use Index 1            }
 Filter.MaxResults := 100;

 TrnQueryView := New(PTranList,Init(ST_ByIngredient)); { Results In Keyed Order }
 TrnQuery     := New(PTrnQuery,Init(TrnQueryView));

 IF NOT  Filter.AllowDateRange THEN
  BEGIN
   Filter.StartDay := 0;
   Filter.EndDay:=Date_To_Days('31/12/2099');
  END;

 TrnQuery^.SetFilter(Filter);

 TotWt   := 0.0;
 TotCont := 0;
 CurrentDate := -1;

 REPEAT
  TrnQuery^.Run;
  {IF Filter.MinMid=255 THEN BREAK;}
  DispSpin;
  IF TrnQueryView^.GetSize > 0 THEN
   BEGIN
    TransFound := TRUE;
    QueryRec := TrnQueryView^.SetFirst;
    WHILE (QueryRec <> NIL) DO
     BEGIN
      IF QueryRec^.Date <> CurrentDate THEN
       BEGIN
        { Print Daily Total For Detailed Transactional}
        IF Filter.Detailed THEN WriteTotals(TotWt,TotCont,detaillisttype);
        IF Filter.Date THEN
         BEGIN
          { Date Summary Selected - Print Daily Summary By Ingredient      }
          ShowTotalsForList(DailyTotalList,dailylisttype);
          ClearTranTotalList(DailyTotalList);{ Clear Daily Totals List   }
         END;
        CurrentDate := QueryRec^.Date;         { Set Next Subbreak Trigger }
        IF Filter.Detailed THEN
         BEGIN
          CheckPageBreak(5,TRUE);
          PrintColumnHeadings;
         END;
       END;

      PrintReportBody;

      TotWt := TotWt + QueryRec^.Weight;
      INC(TotCont);

      AddToGrandTotal(QueryRec);
      IF Filter.Date  THEN AddToDailyTotal(QueryRec);
      IF Filter.Work  THEN AddToWorkTotalList(QueryRec);
      IF Filter.Batch THEN AddToBatchList(QueryRec);
      QueryRec := TrnQueryView^.GetNext;
     END;
    TrnQueryView^.DisposeList;
   END;
 UNTIL (TrnQuery^.QueryComplete) OR (StopProcess);

 Dispose(TRNQuery,Done);
 Dispose(TRNQueryView,Done);

 IF Filter.Detailed THEN WriteTotals(TotWt,TotCont,detaillisttype);
 IF Filter.Date THEN
  BEGIN
   { Date Summary Selected - Print Daily Summary By Ingredient      }
   ShowTotalsForList(DailyTotalList,dailylisttype);
   ClearTranTotalList(DailyTotalList);{ Clear Daily Totals List   }
  END;

 IngredientFile^.OpenFile;

 IF WorkTotalList  <> NIL THEN ShowTotalsForList(WorkTotalList,orderlisttype);
 IF BatchList      <> NIL THEN ShowTotalsForList(BatchList,batchlisttype);
 IF GrandTotalList <> NIL THEN ShowTotalsForList(GrandTotalList,grandtotallisttype);

 IngredientFile^.CloseFile;

 IF Filter.Work  THEN ClearTranTotalList(WorkTotalList);
 IF Filter.Batch THEN ClearTranTotalList(BatchList);
 ClearTranTotalList(GrandTotalList);
 IF TransFound THEN EndReport;
END;


PROCEDURE TIngredientUsageReport.RunMacroReport(CopyFilter : TFilter);
BEGIN
 Move(CopyFilter,Filter,SizeOf(Filter));
 Inc(Filter.StartDay,Date_To_Days(Date));
 INC(Filter.EndDay,Date_To_Days(Date));
 GenerateReport;
END;



{********************* TTransactionReport Methods ************************}


PROCEDURE   TTransactionReport.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
 ReportTitle    := 'Transaction Report';
END;

PROCEDURE   TTransactionReport.PrintColumnHeadings;
BEGIN
 PrintLn;
 PrintLnAt(CursorX,'MI-Serial Ingredient  Weight   RecipeNo Ord. No    Batch Lot No         Type');
 PrintLnAt(CursorX,'--------- ---------- --------- -------- --------- ------ -------------- ------');
END;

PROCEDURE   TTransactionReport.PrintReportBody;
VAR QueryRec : PTRNList;
    LastProd : TIngredientRef;
    TotWeight: DOUBLE;
    Numcont  : LONGINT;
BEGIN
 QueryRec := TrnQueryView^.SetFirst;
 WHILE (QueryRec <> NIL) DO
  BEGIN
   INC(TrnFound);
   TotalWt := TotalWt + QueryRec^.Weight;
   IF CheckPageBreak(1,TRUE) THEN PrintColumnHeadings;
   WITH QueryRec^ DO
    BEGIN
     PrintLnAt(CursorX,IntToZeroStr(MID,2)+'-'+IntToZeroStr(RunNo,6)+
                       '   '+Ingredient+
                       ' '  +DoubleToStr(Weight,9,3)+
                       ' '  +RecipeNo+
                       ' '+OrderNoToStr(OrderNo,Revision)+
                       ' '+BatchNo+
                       ' '  +LotNo+
                       ' '  +GetTRNStatusType(Status));
    END;
   QueryRec := TrnQueryView^.GetNext;
  END;
END;


PROCEDURE TTransactionReport.RunMacroReport(CopyFilter : TFilter);
BEGIN
 MOVE(Copyfilter,Filter,SizeOf(Filter));
 INC(Filter.StartDay,Date_To_Days(Date));
 Inc(Filter.EndDay,Date_To_Days(Date));
 GenerateReport;
END;

PROCEDURE   TTransactionReport.OutputReport;
VAR TransFound : BOOLEAN;
BEGIN

 TransFound := FALSE;
 TRNFound   := 0;
 TotalWt    := 0.0;
 Filter.KeyNum     := 1;                           { Use Index 1           }
 Filter.MaxResults := 10;

 TrnQueryView := New(PTranList,Init(ST_Unsorted)); { Results In Keyed Order }
 TrnQuery     := New(PTrnQuery,Init(TrnQueryView));

 TrnQuery^.SetFilter(Filter);

 REPEAT
  TrnQuery^.Run;
  DispSpin;
  IF TrnQueryView^.GetSize > 0 THEN
   BEGIN
    TransFound := TRUE;
    PrintReportBody;
    TrnQueryView^.DisposeList;
   END;
 UNTIL (TrnQuery^.QueryComplete) OR (StopProcess);

 Dispose(TrnQuery,Done);
 Dispose(TrnQueryView,Done);

 IF TransFound THEN
  BEGIN
   PrintLnAt(CursorX,'    Total Of '+IntToStr(TRNFound,1)+' Transactions     Total Wt '+DoubleToStr(TotalWt,9,3)+'kg');
   EndReport;
  END;
END;


PROCEDURE Print_Ingredient_Usage;
VAR TheReport : PIngredientUsageReport;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,Init);
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_Usage,TRUE,FALSE,FALSE);
END;

PROCEDURE Print_Transactions;
VAR TheReport : PTransactionReport;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,Init);
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_TransactionRep,TRUE,FALSE,FALSE);
END;


END.

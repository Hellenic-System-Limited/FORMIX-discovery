(****************************************************************************
*  UNIT          : FXPNET                                                   *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 17/05/96                                                 *
*  PURPOSE       : Net Ingredient Usage Report                              *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXPNET;
INTERFACE
USES F6StdCtv,FXModCtv,F6StdUtl,F6StdChr,F6StdUt1,F6StdWn1,F6StdWin,F6StdRep,FXFMacro,
     FXCfg,F6RepSee,FXMenu,FXHelp,FXFNet,FXFIngr,F6DtConv,FXBRW_IN,FXFCost;

TYPE  PNetListItem = ^TNetListItem;
      TNetListItem = PACKED RECORD
       Ingredient : TIngredientRef;
       BatchNo    : TBatchRef;
       TotalWt    : DOUBLE;
       Containers : LONGINT;
       Cost       : DOUBLE;
       Next       : PNetListItem;
      END;


TYPE TIngredientUsageFilter = PACKED RECORD
      IngredientMatch : TIngredientRef;
      BatchMatch  : TBatchRef;
      LotMatch    : TLotRef;
      DateRange   : BOOLEAN;
      FromDate,
      ToDate      : LONGINT;
      SortByBatch : BOOLEAN;
      AddCosting  : BOOLEAN;
     END;

TYPE PIngredientUsage = ^TIngredientUsage;
     TIngredientUsage  = OBJECT(TReportObject)

       ListHeader : PNetListItem;
       NetRec     : TNetRecord;
       Loop       : PNetListItem;
       TotWt,
       TotCost    : DOUBLE;
       TotCont    : LONGINT;
       Filter     : TIngredientUsageFilter;

      DESTRUCTOR Done;VIRTUAL;
      PROCEDURE BuildNetList;
      PROCEDURE DisposeOfList;
      PROCEDURE ReportSetup; Virtual;
      PROCEDURE PrintColumnHeadings; Virtual;
      PROCEDURE PrintReportBody; Virtual;
      PROCEDURE OutputReport; Virtual;
      FUNCTION  GetSelectionCriteria : BOOLEAN;VIRTUAL;
      PROCEDURE RunMacroReport(CopyFilter : TFilter);VIRTUAL;
     END;

PROCEDURE Print_NetIngredientUsage_Details;

IMPLEMENTATION

DESTRUCTOR TIngredientUsage.Done;
BEGIN
 INHERITED Done;
END;

PROCEDURE  TIngredientUsage.RunMacroReport(CopyFilter : TFilter);
BEGIN
 Move(CopyFilter,Filter,SizeOf(Filter));
 INC(Filter.FromDate,Date_To_Days(Date));
 INC(Filter.ToDate,Date_To_DayS(Date));
 GenerateReport;
END;


PROCEDURE TIngredientUsage.BuildNetList;

    PROCEDURE AddRecord;
    VAR Last,AddItem,Loop : PNetListItem;

     FUNCTION GetCostOfNetRec : DOUBLE;
     VAR CostRec : TCostRecord;
     BEGIN
      GetCostOfNetRec := 0.0;
      IF CostFile^.OpenErr = 0 THEN
       BEGIN
        CostRec.COST_Ingredient := NetRec.NETW_Ingredient;
        CostRec.COST_LotNumber  := NetRec.NETW_LotNo;
        IF CostFile^.ReadRecord('EQ',FALSE,FALSE,CostRec,0) = 0 THEN
         BEGIN
          WITH CostRec,NetRec DO
           BEGIN
            IF COST_WeightIn <> 0.0 THEN
             GetCostOfNetRec := (Round((COST_Cost*NETW_NetContainerWt)*1000 / COST_WeightIn))/1000
            ELSE
             GetCostOfNetRec := 0.0;
           END;
         END
        ELSE IF Config_Rec^.Conf_GlobalLot THEN
         BEGIN
          CostRec.COST_LotNumber := SPACE_STRING;
          IF CostFile^.ReadRecord('EQ',FALSE,FALSE,CostRec,0) = 0 THEN
           BEGIN
            WITH CostRec,NetRec DO
             BEGIN
              IF COST_WeightIn <> 0.0 THEN
               GetCostOfNetRec := (Round((COST_Cost*NETW_NetContainerWt)*1000 / COST_WeightIn))/1000
              ELSE
               GetCostOfNetRec := 0.0;
             END;
           END
         END;
       END;
     END;


     PROCEDURE AddToTotals(pItem : PNetListItem;NewRec : BOOLEAN);
     BEGIN
      IF NewRec THEN
       BEGIN
        WITH pItem^ DO
         BEGIN
          Ingredient := NetRec.NETW_Ingredient;
          BatchNo    := NetRec.NETW_BatchNo;
          TotalWt    := NetRec.NetW_NetContainerWt;
          Containers := NetRec.NETW_Containers;
          Cost       := 0;
          Next       := NIL;
         END;
       END
      ELSE
       BEGIN
        WITH pItem^ DO
         BEGIN
          INC(Containers,NetRec.NETW_Containers);
          TotalWt := TotalWt+NetRec.NETW_NetContainerWt;
         END;
       END;
      pItem^.Cost := pItem^.Cost+GetCostOfNetRec;
     END;

     PROCEDURE AddToFront;
     BEGIN
      NEw(AddItem);
      AddToTotals(AddItem,TRUE);
      AddItem^.Next := ListHeader;
      ListHeader := AddItem;
     END;

     PROCEDURE AddBetween;
     BEGIN
      New(AddItem);
      AddToTotals(AddItem,TRUE);
      AddItem^.Next := Last^.Next;
      Last^.Next := AddItem;
     END;

    BEGIN
     IF ListHeader = NIL THEN
      BEGIN
       New(ListHeader);
       AddToTotals(ListHeader,TRUE);
       EXIT;
      END;
     Last := NIL;Loop := ListHeader;
     WHILE (Loop <> NIL) DO
      BEGIN
       IF Filter.SortByBatch THEN
        BEGIN
         IF Loop^.BatchNo = NetRec.NETW_BatchNo THEN
          BEGIN
           IF Loop^.Ingredient = NetRec.NETW_Ingredient THEN
            BEGIN
             AddToTotals(Loop,FALSE);
             EXIT;
            END;
           IF Loop^.Ingredient > NetRec.NETW_Ingredient THEN
            BEGIN
             IF Last = NIL THEN
              AddToFront
             ELSE
              AddBetween;
             EXIT;
            END;
          END; {Loop^.BatchNo = NetRec.NET_BatchNo}
         IF Loop^.BatchNo > NetRec.NETW_BatchNo THEN
          BEGIN
           IF Last = NIL THEN
            AddToFront
           ELSE
            AddBetween;
           EXIT;
          END
        END
       ELSE
        BEGIN
         IF Loop^.Ingredient = NetRec.NETW_Ingredient THEN
          BEGIN
           AddToTotals(Loop,FALSE);
           EXIT;
          END;
         IF Loop^.Ingredient > NetRec.NETW_Ingredient THEN
          BEGIN
           IF Last = NIL THEN
            AddToFront
           ELSE
            AddBetween;
           EXIT;
          END;
        END;
       Last := Loop;
       Loop := Loop^.Next;
      END;
     New(AddItem);
     AddToTotals(AddItem,TRUE);
     Last^.Next := AddItem;
    END;

    FUNCTION InCriteria : BOOLEAN;
    BEGIN
     InCriteria := FALSE;
     WITH NetRec,Filter DO
      BEGIN
       IF (NOT NowtButSpace(IngredientMatch)) AND
        (NOT Str_Equal(IngredientMatch,NETW_Ingredient,Length(IngredientMatch))) THEN
        EXIT;
       IF (NOT NowtButSpace(BatchMatch)) AND (NOT Str_Equal(BatchMatch,NETW_BatchNo,Length(BatchMatch))) THEN EXIT;
       IF (NOT NowtButSpace(LotMatch)) AND (NOT Str_Equal(LotMatch,NETW_LotNo,Length(LotMatch))) THEN EXIT;
       IF (DateRange) AND ((FromDate>NETW_Date) OR (ToDate < NETW_Date)) THEN EXIT;
      END;
     InCriteria := TRUE;
    END;

BEGIN
 ListHeader := NIL;
 NetFile^.OpenFile;
 CostFile^.OpenFile;
 FillChar(NetRec,SizeOf(NetRec),#0);
 IF Filter.DateRange THEN NetRec.NETW_Date := Filter.FromDate;
 NetFile^.ReadRecord('GE',FALSE,FALSE,NetRec,0);
 WHILE (NetFile^.BtrvErr = 0)
 AND   (NetRec.NETW_Date <= Filter.ToDate) DO
  BEGIN
   DispSpin;
   IF InCriteria THEN AddRecord;
   NetFile^.ReadRecord('GN',FALSE,FALSE,NetRec,0);
  END;
 CostFile^.CloseFile;
 NetFile^.CloseFile;
END;

FUNCTION TIngredientUsage.GetSelectionCriteria : BOOLEAN;
CONST HeaderTxt = 'Ingredient Usage Report';
      EditX     = 25;

VAR CritWin : WindowRecord;
    EditPos : INTEGER;

 PROCEDURE WriteInfo;
 BEGIN
  WITH Filter DO
   BEGIN
    WriteTickBox(EditX,3,DateRange);
    IF DateRange THEN WriteField(EditX,4,Days_To_Date(FromDate),TRUE);
    IF DateRange THEN WriteField(EditX,5,Days_To_Date(ToDate),TRUE);
    WriteField(EditX,6,IngredientMatch,TRUE);
    WriteField(EditX,7,BatchMatch,TRUE);
    WriteField(EditX,8,LotMatch,TRUE);
    WriteTickBox(EditX,9,SortByBatch);
    WriteTickBox(EditX,10,AddCosting);
   END;
 END;

 PROCEDURE GetEditField;
 BEGIN
  WITH Filter DO
   BEGIN
    CASE EditPos OF
     1 : GetBoolean(DateRange,EditX,3,tickbox);
     2 : IF DateRange THEN GetDate(FromDate,EditX,4);
     3 : IF DateRange THEN GetDate(ToDate,EditX,5);
     4 : GetLine(IngredientMatch,8,EditX,6);
     5 : GetLine(BatchMatch,6,EditX,7);
     6 : GetLine(LotMatch,14,EditX,8);
     7 : GetBoolean(SortByBatch,EditX,9,tickbox);
     8 : GetBoolean(AddCosting,EditX,10,tickbox);
    END;
   END;
 END;

 PROCEDURE ProcessCh1;
 VAR TransferBuff : TIngredient_Record;
     FilterBuff   : TFilter;
     TodayInDays  : LONGINT;
 BEGIN
  CASE Ch1 OF
   PREV : IF EditPos > 1 THEN Dec(EditPos) ELSE EditPos := 7;
   NEXT : IF EditPos < 7 THEN Inc(EditPos) ELSE EditPos := 1;
   FN_F1: IF EditPos = 4 THEN
    BEGIN
     TransferBuff.ING_Ingredient := Filter.IngredientMatch;
     IngredientLookup(@TransferBuff);
     IF NOT NowtButSpace(TransferBuff.ING_Ingredient) THEN
      Filter.IngredientMatch := TransferBuff.ING_Ingredient;
    END;
   FN_F3 : BEGIN
            FillChar(FilterBuff,SizeOf(TFilter),#0);
            TodayInDays := Date_To_Days(Date);
            Dec(Filter.FromDate,TodayInDays);
            Dec(Filter.ToDate,TodayInDays);
            Move(Filter,FilterBuff,SizeOf(Filter));
            Inc(Filter.FromDate,TodayInDays);
            Inc(Filter.ToDate,TodayInDays);
            RepMacroFile^.AddNewRepMacroRecord(NetReportTitle,@FilterBuff);
           END;
  END;
 END;

BEGIN
 BackColourScheme;
 SetWindow(10,6,56,19,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,CritWin);
 Header(HeaderTxt,1);
 Footer('F2 -Report ESC -Exit  F3 -Save Macro',1);
     WriteAt(2,3,'   Use Date Range      [ ]');
     WriteAt(2,4,'   From Date           [  /  /    ]');
     WriteAt(2,5,'   To Date             [  /  /    ]');
 HighWriteAt(2,6,'   Ingredient Matching [        ]');
     WriteAt(2,7,'   Batch No. Matching  [      ]');
     WriteAt(2,8,'   Lot No. Matching    [              ]');
     WriteAt(2,9,'   Group By Batch      [ ]');
     WriteAt(2,10,'   Add Costing         [ ]');
 ForeColourScheme;
 EditPos := 1;

 FillChar(Filter,SizeOf(Filter),#0);
 WITH Filter DO
  BEGIN
   FromDate   := Date_To_Days(Date);
   ToDate     := Date_To_Days(Date);
   BatchMatch := SPACE_STRING;
   LotMatch   := Space_String;
   IngredientMatch := SPACE_STRING;
  END;
 REPEAT
  WriteInfo;
  GetEditField;
  ProcessCh1;
 UNTIL (ch1 = ESC) OR (ch1 = FN_F2);
 LoseWindow(CritWin);
 GetSelectionCriteria := Ch1 <> ESC;
END;

PROCEDURE TIngredientUsage.DisposeOfList;
VAR DelRec : PNetListItem;
BEGIN
 Loop := ListHeader;
 WHILE (Loop <> NIL) DO
  BEGIN
   DelRec := Loop;
   Loop := Loop^.Next;
   Dispose(DelRec);
  END;
END;

PROCEDURE TIngredientUsage.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
 ReportTitle    := 'Ingredient Usage Report';
END;

PROCEDURE TIngredientUsage.PrintColumnHeadings;
VAR LineOut,
    UnderLine : STRING[100];
BEGIN
 LineOut   :=' Ingredient  Description                      Total Wt   Cnt ';
 UnderLine :=' ----------  ------------------------------  ---------  -----';

 IF Filter.SortByBatch THEN
  BEGIN
   LineOut   := ' Batch No'+LineOut;
   UnderLine := ' --------'+UnderLine;
  END;
 IF Filter.AddCosting THEN
  BEGIN
   IF Filter.SortByBatch THEN
    BEGIN
     LineOut   := COPY(LineOut,1,22)+CCondensed+COPY(LineOut,23,30)+CNormal+COPY(LineOut,53,Length(LineOut));
     UnderLine := COPY(UnderLine,1,22)+CCondensed+COPY(UnderLine,23,30)+CNormal+COPY(UnderLine,53,Length(UnderLine));
    END;
   LineOut   := LineOut   + '    Cost  ';
   UnderLine := UnderLine + ' ---------';
  END;
 PrintLnAt(CursorX,LineOut);
 PrintLnAt(CursorX,UnderLine);
END;

PROCEDURE TIngredientUsage.PrintReportBody;
BEGIN
 IF CheckPageBreak(3,TRUE) THEN PrintColumnHeadings;
 WITH Loop^ DO
  BEGIN
   IF Filter.SortByBatch THEN PrintAt(CursorX,'   '+BatchNo);
   PrintAt(CursorX,'   '+Ingredient+'  ');
   IF Filter.AddCosting AND Filter.SortByBatch THEN
    PrintAt(CursorX,CCondensed+GetIngredientDesc(Ingredient)+CNormal)
   ELSE
    PrintAt(CursorX,GetIngredientDesc(Ingredient));
   PrintAt(CursorX,'  '+DoubleToStr(TotalWt,9,3)+
                     '  '+IntToStr(Containers,5));
   IF Filter.AddCosting THEN
    PrintAt(CursorX,' '+DoubleToStr(Cost,9,3));
   PrintLn;
   TotCost := TotCost + Cost;
   TotWt   := TotWt   + TotalWt;
   TotCont := TotCont + Containers;
  END;
END;

PROCEDURE TIngredientUsage.OutputReport;
VAR TotalStr,
    BreakStr : STRING[60];
BEGIN
 {Needs To Go Through the net pack file building a linked list}
 BuildNetList;
 IF ListHeader = NIL THEN EXIT;
 TotWt   := 0.0;
 TotCost := 0.0;
 TotCont := 0;
 Loop := ListHeader;
 WHILE (Loop <> NIL) AND (NOT StopProcess) DO
  BEGIN
   PrintReportBody;
   Loop := Loop^.Next;
  END;

 TotalStr := 'Totals '+DoubleToStr(TotWt,9,3)+'  '+IntToStr(TotCont,5);
 BreakStr := '---------  -----';
 IF Filter.AddCosting THEN
  BEGIN
   TotalStr := TotalStr + ' '+DoubleToStr(TotCost,9,3);
   BreakStr := BreakStr + ' ---------';
  END;

 IF Filter.SortByBatch THEN
  BEGIN
   IF Filter.AddCosting THEN
    BEGIN
     PrintLnAt(CursorX+41,BreakStr);
     PrintLnAt(CursorX+34,TotalStr);
    END
   ELSE
    BEGIN
     PrintLnAt(CursorX+54,BreakStr);
     PrintLnAt(CursorX+47,TotalStr);
    END;
  END
 ELSE
  BEGIN
   PrintLnAt(CursorX+45,BreakStr);
   PrintLnAt(CursorX+38,TotalStr);
  END;
 DisposeOfList;
 EndReport;
END;

PROCEDURE Print_NetIngredientUsage_Details;
VAR TheReport : PIngredientUsage;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,Init);
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_NetPack,TRUE,FALSE,FALSE);
END;


END.

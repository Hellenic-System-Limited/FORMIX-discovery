(****************************************************************************
*  UNIT          : FXPSch                                                   *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 17/05/96                                                 *
*  PURPOSE       : Schedule Report                                          *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXPOrd;
INTERFACE
USES Crt,F6StdCtv,FXModCtv,F6DtConv,F6StdUtl,F6StdChr,F6StdUt1,F6StdWn1,F6StdWin,FXFRcp,
     F6StdRep,FXFIngr,F6Screen,FXFTrn,FXCalCst,F6Lists,
     FXCfg,F6RepSee,FXMenu,FXFWork,FXBRW_RP,FXHelp,FXTRNQRY,FXFCost,FXWO_TGL,
     FXFMix;

TYPE TOrderCostReportTotals = PACKED RECORD
       TOT_WtRequired : DOUBLE;
       TOT_WtDone     : DOUBLE;
       TOT_WtVariance : DOUBLE;
       TOT_VarCost    : DOUBLE;
       TOT_Cost       : DOUBLE;
     END;


     POrderSummaryRec = ^TOrderSummaryRec;
     TOrderSummaryRec = PACKED RECORD
       IL_Ingredient : TIngredientRef;
       IL_WtRequired : DOUBLE;
       IL_WtDone     : DOUBLE;
       IL_WtVariance : DOUBLE;
       IL_VarCost    : DOUBLE;
       IL_Cost       : DOUBLE;
     END;


     PIngredientList = ^TIngredientList;
     TIngredientList = OBJECT
       List      : PListOfExternallySortedPtrs;
       Data      : TOrderSummaryRec;

       DataFound : BOOLEAN;

       CONSTRUCTOR Init;
       DESTRUCTOR  Done;                            Virtual;
       PROCEDURE   GetFirstIngredient;              Virtual;
       PROCEDURE   GetNextIngredient;               Virtual;
       FUNCTION    Found : BOOLEAN;                 Virtual;
     END;


     TOrderCostReportStyle = (OCR_normal,OCR_Summary);

     POrderCostReport = ^TOrderCostReport;
     TOrderCostReport  = OBJECT(TReportObject)
      ITotals      : PIngredientList;
      WHRec        : TWOHeaderRecord;
      WLRec        : TWOLineRecord;
      WHErr,WLErr  : INTEGER;

      TrnQueryView : PTranList;
      TrnQuery     : PTrnQuery;

      Filter       : TTransFilter;

      TOT          : TOrderCostReportTotals;
      RepStyle     : TOrderCostReportStyle;

      CONSTRUCTOR Init(Style : TOrderCostReportStyle);
      DESTRUCTOR  Done; Virtual;

      PROCEDURE ReportSetup; Virtual;
      PROCEDURE PrintColumnHeadings; Virtual;
      PROCEDURE PrintReportBody; Virtual;
      PROCEDURE PrintSummary;
      PROCEDURE PrintReportTotals; Virtual;
      PROCEDURE PrintIngredients;
      PROCEDURE OutputReport; Virtual;
      FUNCTION  FindPrice(VAR Ing : TIngredientRef;
                          ForLineNo : LONGINT) : DOUBLE;
     END;



PROCEDURE Print_Order_Pricing_Report(Style : TOrderCostReportStyle);
PROCEDURE ViewMixes(OrderNo : LONGINT;Revision : BYTE);



IMPLEMENTATION


FUNCTION Compare(var a; var b; kind : Pointer) : INTEGER;
VAR pa,pb : POrderSummaryRec;
BEGIN
 pa := @(TOrderSummaryRec(a));
 pb := @(TOrderSummaryRec(b));

      IF (pa^.IL_Ingredient > pb^.IL_Ingredient) THEN Compare := 1
 ELSE IF (pa^.IL_Ingredient = pb^.IL_Ingredient) THEN Compare := 0
 ELSE Compare := -1;
END;

CONSTRUCTOR TIngredientList.Init;
BEGIN
 New(List,Init(SizeOf(Data),Compare,NIL));
 DataFound := FALSE;
END;

DESTRUCTOR  TIngredientList.Done;
BEGIN
 Dispose(List,Done);
END;


FUNCTION  TIngredientList.Found : BOOLEAN;
BEGIN
  Found := DataFound;
END;


PROCEDURE TIngredientList.GetFirstIngredient;
VAR DataPtr : POrderSummaryRec;
BEGIN
 DataFound := FALSE;
 DataPtr := POrderSummaryRec(List^.FirstData);
 IF DataPtr <> NIL THEN
  BEGIN
   DataFound := TRUE;
   Data := DataPtr^;
  END;
END;

PROCEDURE TIngredientList.GetNextIngredient;
VAR DataPtr : POrderSummaryRec;
BEGIN
 DataFound := FALSE;
 DataPtr := POrderSummaryRec( List^.NextData);
 IF DataPtr <> NIL THEN
  BEGIN
   DataFound := TRUE;
   Data := DataPtr^;
  END;
END;




CONSTRUCTOR TOrderCostReport.Init(Style : TOrderCostReportStyle);
BEGIN
 INHERITED Init;
 New(ITotals,Init);
 FillChar(TOT,SizeOF(TOrderCostReportTotals),0);
 RepStyle := Style;
END;

DESTRUCTOR TOrderCostReport.Done;
BEGIN
 Dispose(ITotals,Done);
 INHERITED Done;
END;

PROCEDURE TOrderCostReport.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                       +CopyRightInfo;
 IF RepStyle = OCR_Normal THEN ReportTitle    := 'Order Costing Report'
 ELSE ReportTitle := 'Order Summary Report';
END;


PROCEDURE TOrderCostReport.PrintColumnHeadings;
BEGIN

 PrintNCharsAt(1,' ',11);
 PrinterControl(CCondensed);
   PrintNCharsAt(12,' ',24);
   PrintAt(37,'  Mix');
   PrintAt(45,'Cont.');
 PrinterControl(CNormal);

 PrintNCharsAt(53,' ',8);
 PrintNCharsAt(62,' ',8);

 PrinterControl(CCondensed);
   PrintAt(71,' ------ Variance ------ ');
   {
   PrintNCharsAt(79,' ',7);
   PrintNCharsAt(87,' ',7);
   PrintNCharsAt(96,' ',7);
   }
 PrinterControl(CNormal);

 PrintNCharsAt(95,' ',9);

 PrintLn;


 PrintAt(1,'Ingredient ');

 PrinterControl(CCondensed);

 PrintAt(12 ,'Description');
 PrintAt(37 ,RJustify('Ratio  '));
 PrintAt(45 ,'Size   ');

 PrinterControl(CNormal);

 PrintAt(53 ,RJustify('Required'));
 PrintAt(62 ,RJustify('Done    '));

 PrinterControl(CCondensed);
 PrintAt(71 ,RJustify('Weight '));
 PrintAT(79 ,RJustify('Percent'));
 PrintAt(87 ,RJustify('Cost   '));
 PrinterControl(CNormal);

 PrintAt(95,RJustify('Cost     '));

 PrintLn;

 PrintNCharsAt(1,'-',10);
 PrintAt(CursorX,' ');

 PrinterControl(CCondensed);


 PrintNCharsAt(12,'-',24);
 PrintNCharsAt(37,'-',7);
 PrintNCharsAt(45,'-',7);

 PrinterControl(CNormal);

 PrintNCharsAt(53 ,'-',8);
 PrintNCharsAt(62 ,'-',8);

 PrinterControl(CCondensed);
 PrintNCharsAt(71,'-',7);
 PrintNCharsAt(79,'-',7);
 PrintNCharsAt(87,'-',7);
 PrinterControl(CNormal);

 PrintNCharsAt(95,'-',9);
 PrintLn;
END;


FUNCTION TOrderCostReport.FindPrice(VAR Ing : TIngredientRef;
                                    ForLineNo : LONGINT) : DOUBLE;
VAR
    TempPrice : DOUBLE;
    TempWt    : DOUBLE;
    Price     : DOUBLE;
BEGIN
 FindPrice := CalcWeightDoneAndPrices(Ing,ForLineNo,
                                      TempWt,Price,TempPrice,TrnQueryView);
END;

PROCEDURE TOrderCostReport.PrintReportBody;
    { Derived Fields }
VAR KeyIngredient   : CHAR;
    WtRequired      : DOUBLE;
    WtVariance      : DOUBLE;
    Var_Percent     : DOUBLE;
    Var_Cost        : DOUBLE;
    Cost            : DOUBLE;
    CostPerKg       : DOUBLE;
    UpdatePtr : POrderSummaryRec;

BEGIN
 WITH WLRec,TOT DO
  BEGIN
   Cost :=FindPrice(WOL_Ingredient,WOL_LineNo);
   IF WOL_KeyIngredient THEN KeyIngredient :='*'
   ELSE KeyIngredient :=' ';

   WtRequired := CalcLineGrossWtReqdFromRecipeNet(WHRec.WOH_FinishWtReqd,
                                                  WOL_Ratio,WOL_Yield);
   WtVariance  := WOL_TotalWtDone - WtRequired;

   Var_Percent := 0;
   IF WtRequired > 0.0 THEN
     Var_Percent := (WtVariance*100) / WtRequired;

   CostPerKg := 0.0;
   IF WOL_TotalWtDone > 0 THEN
     CostPerKg   := (Cost / WOL_TotalWtDone);

   Var_Cost := WtVariance * CostPerKg;

   CASE Repstyle OF
    OCR_Summary : BEGIN
     { Add To Ingredient Total List }
     FillChar(ITotals^.Data,SizeOF(ITotals^.Data),#0);
     ITotals^.Data.IL_Ingredient := WOL_Ingredient;
     IF NOT ITotals^.List^.FindDataMatch(ITotals^.Data) THEN
       ITotals^.List^.AddDataToList(ITotals^.Data);
     UpdatePtr := POrderSummaryRec(ITotals^.List^.CurrentData);
     WITH UpdatePtr^ DO
      BEGIN
       IL_WtRequired := IL_WtRequired + WtRequired;
       IL_WtDone     := IL_WtDone     + WOL_TotalWtDone;
       IL_WtVariance := IL_WtVariance + WtVariance;
       IL_VarCost    := IL_VarCost    + Var_Cost;
       IL_Cost       := IL_Cost       + Cost;
       ITotals^.Data := UpdatePtr^;
      END;
    END;

    OCR_normal : BEGIN
     IF CheckPageBreak(3,TRUE) THEN PrintColumnHeadings;
     PrintAt(CursorX  ,WOL_Ingredient+KeyIngredient);
     PrintAt(CursorX  ,'  ');

     PrinterControl(CCondensed);
     PrintAT(CursorX,COPY(GetIngredientDesc(WOL_Ingredient),1,24));
     PrintAt(CursorX+1,DoubleToStr(WOL_Ratio,7,3));
     PrintAt(CursorX+1,DoubleToStr(WOL_ContainerSize,7,3));
     PrinterControl(CNormal);
     PrintAt(CursorX+1,DoubleToStr(WtRequired,8,3));
     PrintAt(CursorX+1,DoubleToStr(WOL_TotalWtDone,8,3));
     PrinterControl(CCondensed);
     PrintAt(CursorX+1,DoubleToStr(WtVariance,7,3));
     PrintAt(CursorX+1,DoubleToStr(Var_Percent,7,3));
     PrintAt(CursorX+1,DoubleToStr(Var_Cost,7,3));
     PrinterControl(CNormal);
     PrintAt(CursorX+2,DoubleToStr(Cost,8,3));

     PrintLn;
     TOT_WtRequired := TOT_WtRequired + WtRequired;
     TOT_WtDone     := TOT_WtDone     + WOL_TotalWtDone;
     TOT_WtVariance := TOT_WtVariance + WtVariance;
     TOT_VarCost    := TOT_VarCost    + Var_Cost;
     TOT_Cost       := TOT_Cost       + Cost;
    END;
   END; { END (CASE) }
  END;
END;



PROCEDURE TOrderCostReport.PrintSummary;
Var
    Var_Percent    : DOUBLE;
BEGIN
 {IF ITotals^.GetItemCount <=0 THEN EXIT;}
                                  (****)

 IF CheckPageBreak(6,TRUE) THEN PrintColumnHeadings;

 WITH ITotals^,TOT DO
  BEGIN
   GetFirstIngredient; { loads Data }
   WHILE (Found) DO
    BEGIN
     Var_Percent := 0;
     IF Data.IL_WtRequired > 0 THEN
      BEGIN
       Var_Percent :=  ((Data.IL_WtDone-Data.IL_WtRequired) * 100) / Data.IL_WtRequired;
      END;


     PrintAt(CursorX  ,Data.IL_Ingredient);
     PrintAt(CursorX  ,'  ');

     PrinterControl(CCondensed);
     PrintAT(CursorX,COPY(GetIngredientDesc(Data.IL_Ingredient),1,24));
     PrintAt(CursorX+1,'       ');   { RATIO }
     PrintAt(CursorX+1,'        ');   { Container Size}
     PrinterControl(CNormal);
     PrintAt(CursorX+1,DoubleToStr(Data.IL_WtRequired,8,3));
     PrintAt(CursorX+1,DoubleToStr(Data.IL_WtDone,8,3));
     PrinterControl(CCondensed);
     PrintAt(CursorX+1,DoubleToStr(Data.IL_WtVariance,7,3));
     PrintAt(CursorX+1,DoubleToStr(Var_Percent,7,3));
     PrintAt(CursorX+1,DoubleToStr(Data.IL_VarCost,7,3));
     PrinterControl(CNormal);
     PrintAt(CursorX+2,DoubleToStr(Data.IL_Cost,8,3));

     PrintLn;

     TOT_WtRequired := TOT_WtRequired + Data.IL_WtRequired;
     TOT_WtDone     := TOT_WtDone     + Data.IL_WtDone;
     TOT_WtVariance := TOT_WtVariance + Data.IL_WtVariance;
     TOT_VarCost    := TOT_VarCost    + Data.IL_VarCost;
     TOT_Cost       := TOT_Cost       + Data.IL_Cost;
     GetNextIngredient;
    END;
  END;
END;


PROCEDURE TOrderCostReport.PrintIngredients;
VAR I : LONGINT;
BEGIN
 WITH WHRec DO
  BEGIN
   IF RepStyle = OCR_normal THEN
    BEGIN
     CheckPageBreak(6,TRUE);
     PrintLn;
     PrintAt(CursorX  ,'Order No : '+OrderNoToStr(WOH_OrderNo,WOH_Revision));
     PrintAt(CursorX+3,'Recipe No : '+WOH_RecipeNo+'  ');
     PrintLnAt(CursorX,'Schedule Date : '+Days_To_Date(WOH_SchDate));
     PrintLn;
     PrintColumnHeadings;
    END;
   I:=1;
   REPEAT
    WLErr := WorkLineFile^.Get_WO_Line_Record(WOH_OrderNo,WOH_Revision,I,WLRec);
    IF WLErr = 0 THEN
     BEGIN
      PrintReportBody;
     END;
    INC(I);
   UNTIL (WLErr <> 0);
  END;
END;


PROCEDURE TOrderCostReport.PrintReportTotals;
VAR Var_Percent : DOUBLE;
BEGIN
 WITH TOT DO
  BEGIN
   Var_Percent := 0;
   IF TOT_WtRequired > 0 THEN
     Var_Percent := ((TOT_WtDone - TOT_WtRequired) *100) / TOT_WtRequired;

   PrintNCharsAt(1,' ',11);
   PrinterControl(CCondensed);
    PrintNCharsAt(12,' ',24);
    PrintNCharsAt(37,' ',7);
    PrintNCharsAt(45,' ',7);
   PrinterControl(CNormal);

   PrintNCharsAt(53 ,'=',8);
   PrintNCharsAt(62 ,'=',8);

   PrinterControl(CCondensed);
    PrintNCharsAt(71,'=',7);
    PrintNCharsAt(79,'=',7);
    PrintNCharsAt(87,'=',7);
   PrinterControl(CNormal);

   PrintNCharsAt(95,'=',9);
   PrintLn;

   IF (RepStyle = OCR_Summary) THEN
     PrintAt(CursorX,'Grand Total')
   ELSE
     PrintAt(CursorX,'Order Total');
   PrinterControl(CCondensed);
    PrintNCharsAT(CursorX,' ',24);
    PrintNCharsAt(CursorX+1,' ',7);
    PrintNCharsAt(CursorX+1,' ',7);
   PrinterControl(CNormal);
   PrintAt(CursorX+1,DoubleToStr(TOT_WtRequired,8,3));
   PrintAt(CursorX+1,DoubleToStr(TOT_WtDone,8,3));

   PrinterControl(CCondensed);
    PrintAt(CursorX+1,DoubleToStr(TOT_WtVariance,7,3));
    PrintAt(CursorX+1,DoubleToStr(Var_Percent,7,3));
    PrintAt(CursorX+1,DoubleToStr(TOT_VarCost,7,3));
   PrinterControl(CNormal);
   PrintAt(CursorX+2,DoubleToStr(TOT_Cost,8,3));

   PrintLn;
   PrintLn;
   FillChar(TOT, SizeOf(TOT), 0);
  END;
END;


PROCEDURE TOrderCostReport.OutputReport;
VAR
    RecordFound : BOOLEAN;

    Loop        : PWOToggleItem;
BEGIN
 RecordFound := FALSE;
 FillCHar(WHRec,SizeOf(WHRec),#0);
 CostFile^.OpenFile;
 IF (WorkHeaderFile^.OpenFile = 0) AND (WorkLineFile^.OpenFile = 0) THEN
  BEGIN
   { Create Transaction Query Object Instances }
   TrnQueryView := New(PTranList,Init(ST_ByIngredient)); { Results In Keyed Order }
   TrnQuery     := New(PTrnQuery,Init(TrnQueryView));

   Loop  := WOToggleListHeader;
   WHErr := 0;
   WHILE (WHErr = 0) AND (Loop<>NIL) AND (NOT StopProcess) DO
    BEGIN
     DispSpin;
     WHREc.WOH_OrderNo  := Loop^.OrderNo;
     WHRec.WOH_Revision := Loop^.Revision;
     WHErr := WorkHeaderFile^.ReadRecord('EQ',FALSE,FALSE,WHRec,1);
     IF WHErr = 0 THEN
      BEGIN
       RecordFound      := TRUE;

       { Setup Transaction Query Criteria }
       FXTRNQRY.InitFilter(Filter);
       Filter.KeyNum := 2;                       {Use Key- Order/revision/mix}
       Filter.MinWorkNo := WHRec.WOH_OrderNo;    {Set Order Number           }
       Filter.MaxWorkNo := WHRec.WOH_OrderNo;    {Ser Order Number Limit     }
       Filter.sMinorWO  := IntToZeroStr(WHRec.WOH_Revision,2); { Set Revision}
       Filter.IncludeActive := TRUE;             {Weighed Ingredients        }
       Filter.IncludeAborted := FALSE;           {Exclude Aborted            }

       TrnQuery^.SetFilter(Filter);              {Prime Query With Filter    }
       TrnQuery^.Run;                            {Execute Query              }


       PrintIngredients;                         {Print Ingredients          }

       TrnQueryView^.DisposeList;                {Clear Query Results        }

       IF RepStyle = OCR_Normal THEN PrintReportTotals;
      END;

     Loop := Loop^.Next;
    END;

   Dispose(TrnQuery,Done);
   Dispose(TrnQueryView,Done);


   IF RepStyle = OCR_Summary THEN
    BEGIN
     PrintSummary;
     PrintReportTotals;
    END;
  END;


 IF RecordFound THEN EndReport;
 IF CostFile^.OpenErr       = 0 THEN CostFile^.CloseFile;
 IF WorkHeaderFile^.OpenErr = 0 THEN WorkHeaderFile^.CloseFile;
 IF WorkLineFile^.OpenErr   = 0 THEN WorkLineFile^.CloseFile;
END;

PROCEDURE Print_Order_Pricing_Report(Style : TOrderCostReportStyle);
VAR TheReport : POrderCostReport;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,Init(Style));
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_OrderReport,TRUE,FALSE,FALSE);
END;



PROCEDURE ViewMixes(OrderNo : LONGINT;Revision : BYTE);

TYPE
     PLineRecord = ^TLineRecord;
     TLineRecord = PACKED RECORD
      WOLRec  : TWOLineRecord;
      Next    : PLineRecord;
     END;

VAR  MixWin,DispWin : WindowRecord;
     Filter      : TTransFilter;
     WHRec       : TWOHeaderRecord;
     WLRec       : TWOLineRecord;
     WHErr,WLErr : INTEGER;
     ListHeader  : PTRNList;
     LinesList   : PLineRecord;
     LastLine,
     NewLine     : PLineRecord;
     Pos         : INTEGER;
     MixNo       : INTEGER;
     ListSize    : INTEGER;
     TrnQueryView : PTranList;
     TrnQuery     : PTrnQuery;
     MixWtReqd   : DOUBLE;
     MixTotalsLine : STRING[35];



  PROCEDURE GetOrderLines;
  VAR I : LONGINT;
  BEGIN
   I := 1;  LinesList := NIL;  LastLine := NIL;  ListSize := 0;
   REPEAT
    WITH WHRec DO
    WLErr := WorkLineFile^.Get_WO_Line_Record(WOH_OrderNo,WOH_Revision,I,WLRec);
    IF WLErr = 0 THEN
     BEGIN
      New(NewLine);
      MOVE(WLRec,NewLine^.WOLRec,SizeOf(TWOLineRecord));
      NewLine^.Next := NIL;
      IF LastLine = NIL THEN
       LinesList := NewLine
      ELSE
       LastLine^.Next := NewLine;
      LastLine := NewLine;
      INC(ListSize);
     END;
    INC(I);
   UNTIL (WLErr <> 0)
  END;

  PROCEDURE ClearOrderList;
  BEGIN
   LastLine := LinesList;
   WHILE (LastLine <> NIL) DO
    BEGIN
     NewLine := LastLine^.Next;
     Dispose(LastLine);
     LastLine := NewLine;
    END;
  END;


  PROCEDURE DisplayWindow;
  BEGIN
   BAckColourScheme;
   SetWindow(02,04,78,21,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,DispWin);
   Header('Mix Details',1);
   Footer(NEXT_KEY+PREV_KEY+'- Scrolls Ingredient List  PGUP/PGDN - Decrease/Increase Mix No',1);
   WriteAt(2,3,'Order Number : '+OrderNoToStr(OrderNo,Revision));
   WriteAt(2,5,'Ingredient  Key  Description             Wt Done     Wt Req       Cost');
   WriteAt(30,3,'Mix No : ');
   ForeColourScheme;
  END;

  PROCEDURE CalcMixDisplayTotals;
  BEGIN
   MixWtReqd     := GetMixWtReqdAsLastCalc(MixNo,@WHRec);
   MixTotalsLine := IntToStr(MixNo,4)+' of '+
                    LJustify(IntToStr(WHRec.WOH_NumMixes,4))+'  '+
                    DoubleToStr(GetMixWtDone(MixNo,@WHRec),8,3)+'/'+
                    DoubleToStr(MixWtReqd,5,3)+
                    'kg'+Space_String;
  END;

  PROCEDURE DisplayMixDetails(Pos,NumToDisplay,StartPos : INTEGER;
                              TheMixNo : LONGINT);
  VAR I           : INTEGER;
      LineWtDone  : DOUBLE;
      LinePrice   : DOUBLE;
      TempPrice   : DOUBLE;
      Temp_Ingred_TotWt        : DOUBLE;
      Temp_Ingred_Weighings    : LONGINT;
      Temp_Ingred_WtIncrements : DOUBLE;
      Temp_Ingred_WghsPerCont  : LONGINT;
      DummyDoneRec : TMixLineRecord;

  BEGIN
   FillChar(DummyDoneRec, SizeOf(DummyDoneRec), 0);
   WriteAt(39,3,MixTotalsLine);
   I := Pos;
   LastLine := LinesList;
   WHILE (I>0) AND (LastLine <> NIL) DO
    BEGIN
     LastLine := LastLine^.Next;
     Dec(I);
    END;
   I := NumToDisplay;
   WHILE (I>0) DO
    BEGIN
     GotoXY(2,StartPos);
     IF LastLine<> NIL THEN
      BEGIN
       WITH LastLine^.WOLRec,WHRec DO
        BEGIN
         CalcIngredReqsForMixWt(MixWtReqd,
                                @WHRec,
                                @LastLine^.WOLRec,
                                DummyDoneRec,
                                Temp_Ingred_TotWt,        {VAR}
                                Temp_Ingred_Weighings,    {VAR}
                                Temp_Ingred_WtIncrements, {VAR}
                                Temp_Ingred_WghsPerCont); {VAR}


         CalcWeightDoneAndPrices(WOL_Ingredient,WOL_LineNo,
                                 LineWtDone,LinePrice,TempPrice,TrnQueryView);
         Write('  '+WOL_Ingredient+
               '   '+BoolToYNStr(WOL_KeyIngredient,3)+
               ' '+COPY(GetIngredientDesc(WOL_Ingredient),1,20)+
               '  '+DoubleToStr(LineWtDone,9,3)+
               '  ',DoubleToStr(Temp_Ingred_TotWt,9,3),
               '  '+DoubleToStr(LinePrice,9,3));

        END;
        LastLine := LastLine^.Next;
      END
     ELSE
      Write(COPY(SPACE_STRING,1,40));
     Dec(I);
     Inc(StartPos);
    END;
  END;

  PROCEDURE BuildTransactionListForMix(NewMixNo : INTEGER);
  BEGIN
   FXTRNQRY.InitFilter(Filter);
   Filter.KeyNum         := 2;
   Filter.MinWorkNo      := WHRec.WOH_OrderNo;
   Filter.MaxWorkNo      := WHRec.WOH_OrderNo;
   Filter.sMinorWO       := IntToZeroStr(WHRec.WOH_Revision,2);
   Filter.IncludeActive  := TRUE;
   Filter.IncludeAborted := FALSE;
   MixNo                 := NewMixNo;
   Filter.MixNo          := MixNo;

   TrnQuery^.SetFilter(Filter);          { Prime Query With Trans. Filter   }
   TrnQueryView^.DisposeList;            { Clear Any Previous Query Results }
   TrnQuery^.Run;                        { Execute Transaction Query        }

   CalcMixDisplayTotals;
   DisplayMixDetails(Pos,10,6,MixNo);
   Flush_Keyboard_Buffer;
  END;


BEGIN
 ListHeader := NIL;
 CursorOff;
 FillChar(WHRec,SizeOf(WHRec),#0);
 CostFile^.OpenFile;  TransFile^.OpenFile;
 IF (WorkHeaderFile^.OpenFile = 0) AND (WorkLineFile^.OpenFile = 0) THEN
  BEGIN
   WHREc.WOH_OrderNo  := OrderNo;
   WHRec.WOH_Revision := Revision;
   WHErr := WorkHeaderFile^.ReadRecord('EQ',FALSE,FALSE,WHRec,1);
   IF (WHErr = 0) THEN
    BEGIN
     { Create Transaction Query Object Instances }
     TrnQueryView := New(PTranList,Init(ST_ByIngredient)); { Results In Keyed Order }
     TrnQuery     := New(PTrnQuery,Init(TrnQueryView));

     GetOrderLines;
     Pos := 0;
     DisplayWindow;
     BuildTransactionListForMix(1);
     REPEAT

      Ch := GetKey;
      CASE Ch OF
       Next : IF (Pos<ListSize-10) THEN
               BEGIN
                INC(Pos);
                ScrollUp(2+2,6+4,70+2,15+4);
                DisplayMixDetails(Pos+9,1,6+9,MixNo);
               END;
       PREV : IF (Pos > 0) THEN
               BEGIN
                Dec(Pos);
                ScrollDown(2+2,6+4,70+2,15+4,NormBack*16+LowFore);
                DisplayMixDetails(Pos,1,6,MixNo);
               END;
       PGUP : IF MixNo > 1 THEN
               BEGIN
                BuildTransactionListForMix(MixNo-1);
               END;
       PGDN : IF MixNo < WHRec.WOH_NumMixes THEN
               BEGIN
                BuildTransactionListForMix(MixNo+1);
               END;
      END;
     UNTIL Ch=ESC;

     LoseWindow(DispWin);

     Dispose(TrnQuery,Done);
     Dispose(TrnQueryView,Done);
     ClearOrderList;
    END
  END;
 IF TransFile^.OpenErr= 0 THEN TransFile^.CloseFile;
 IF CostFile^.OpenErr       = 0 THEN CostFile^.CloseFile;
 IF WorkHeaderFile^.OpenErr = 0 THEN WorkHeaderFile^.CloseFile;
 IF WorkLineFile^.OpenErr   = 0 THEN WorkLineFile^.CloseFile;
 CursorOn;
END;

END.

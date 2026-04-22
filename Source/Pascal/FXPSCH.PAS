(****************************************************************************
*  UNIT          : FXPSch                                                   *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 17/05/96                                                 *
*  PURPOSE       : SChedule Report                                          *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXPSCH;
INTERFACE
USES F6StdCtv,FXModCtv,F6DtConv,F6StdUtl,F6StdChr,F6StdUt1,F6StdWn1,F6StdWin,FXFRcp,F6StdRep,
     FXFMix,FXTRNQRY,FXCfg,F6RepSee,FXMenu,FXFWork,FXBRW_RP,FXHelp,FXFMacro,
     FXFIngr,FXCalCst,FXFCost,FXFTrn;

TYPE
     TOrderFilter = PACKED RECORD
      AllowDateRange : BOOLEAN;
      StartDay   : LONGINT;
      EndDay     : LONGINT;
      MinWorkNo  : LONGINT;
      MaxWorkNo  : LONGINT;
      SWorkNo    : STRING[6];
      DetailedRep: BOOLEAN;
      ScheduleRep: BOOLEAN;
      SRecipe    : TRecipeRef;
     END;


     PScheduleReport = ^TScheduleReport;
     TScheduleReport  = OBJECT(TReportObject)

      WHRec       : TWOHeaderRecord;
      WLRec       : TWOLineRecord;
      WHErr,WLErr : INTEGER;
      Filter      : TOrderFilter;
      LastDate    : LONGINT;

      CONSTRUCTOR Init(SchRep : BOOLEAN);
      PROCEDURE   ReportSetup; Virtual;
      PROCEDURE   PrintColumnHeadings; Virtual;
      PROCEDURE   PrintSubColumnHeadings;
      PROCEDURE   PrintReportBody; Virtual;
      PROCEDURE   OutputReport; Virtual;
      FUNCTION    GetSelectionCriteria : BOOLEAN; VIRTUAL;
      PROCEDURE   RunMacroReport(CopyFilter : TFilter);VIRTUAL;
     END;



PROCEDURE Print_Schedule_Report;
PROCEDURE Print_Order_Report;

IMPLEMENTATION

CONST DONEX = 45;

FUNCTION TScheduleReport.GetSelectionCriteria : BOOLEAN;
CONST HeaderTxt = 'Order Detail Report';
      EditX     = 25;

VAR CritWin        : WindowRecord;
    Editpos        : INTEGER;
    lDate          : LONGINT;
    WrkStr         : STRING[10];
    EditLen        : INTEGER;
    MaxEdit        : INTEGER;
    FilterSave     : TOrderFilter;


 PROCEDURE InputToSelectionFilter;
 VAR sMin,sMax : STRING[6];
     Errint    : INTEGER;
 BEGIN
  WITH Filter DO
   BEGIN
    IF Not NowtButSpace(sWorkNo) THEN
     BEGIN
      {Work Order Number Filter}
      GetMaskNumExtents(sWorkNo,sMin,sMax);
      VAL(sMin,MinWorkNo,ErrInt);
      VAL(sMax,MaxWorkNo,ErrInt);
     END;
   END;
 END;

 PROCEDURE CheckCh1;
 VAR FilterBuff : TFilter;
     TodayInDays: LONGINT;
 BEGIN
  CASE Ch1 OF
   NEXT : IF EditPos<MaxEdit THEN Inc(EditPos) ELSE EditPos :=1;
   PREV : IF EditPos>1 THEN Dec(EditPos) ELSE EditPos :=MaxEdit;
   FN_F3 : BEGIN
            TodayInDays := Date_To_Days(Date);
            InputToSelectionFilter;
            Dec(Filter.StartDay,TodayInDays);
            Dec(Filter.EndDay,TodayInDays);
            FillChar(FilterBuff,SizeOf(TFilter),#0);
            Move(Filter,FilterBuff,SizeOf(Filter));
            Inc(Filter.StartDay,TodayInDays);
            Inc(Filter.EndDay,TodayInDays);
            IF Filter.ScheduleRep THEN
             RepMacroFile^.AddNewRepMacroRecord(ScheduleReportTitle,@FilterBuff)
            ELSE
             RepMacroFile^.AddNewRepMacroRecord(OrderReportTitle,@FilterBuff);

           END;
  END;
 END;

 PROCEDURE WriteStaticText;
 BEGIN
  BackColourScheme;
  SetWindow(10,5,50,16,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,CritWin);
  Header(HeaderTxt,1);
  Footer('ESC -Exit  F2 -Report  F3 -Save Macro',1);

  WriteAt(2,3,'   Use Date Range      [ ]');
  WriteAt(2,4,'   From Date           [  /  /    ]');
  WriteAt(2,5,'   To Date             [  /  /    ]');
  IF NOT Filter.ScheduleRep THEN
   BEGIN
    WriteAt(2,6,'   Work Order Number   [      ]');
    WriteAt(2,7,'   Recipe              [      ]');
    WriteAt(2,8,'   Show Mix Details    [ ]');
   END;
  ForeColourScheme;
 END;

 PROCEDURE PrimeValue;
 BEGIN
  CASE EditPos OF
   2 : lDate := Filter.StartDay;
   3 : lDate := Filter.EndDay;
  END;
 END;

 PROCEDURE OutputValue;
 BEGIN
  CASE EditPos OF
   2 : Filter.StartDay := lDate;
   3 : Filter.EndDay   := lDate;
  END;
 END;

 PROCEDURE InputValue;
 BEGIN
  CASE EditPos OF
   1     : GetBoolean(Filter.AllowDateRange,EditX,3,TickBox);
   2,3   : IF Filter.AllowDateRange THEN GetDate(lDate,EditX,2+EditPos);
   4     : GetLine(Filter.sWorkNo,6,EditX,2+EditPos);
   5     : GetLine(Filter.sRecipe,8,EditX,2+EditPos);
   6     : GetBoolean(Filter.DetailedRep,EditX,2+EditPos,TickBox);
  END;
 END;

 PROCEDURE WriteInfo;
 BEGIN
  WriteTickBox(EditX,3,Filter.AllowDateRange);

  IF Filter.AllowDateRange THEN WriteField(EditX,4,Days_To_Date(Filter.StartDay),TRUE);
  IF Filter.AllowDateRange THEN WriteField(EditX,5,Days_To_Date(Filter.EndDay),TRUE);

  IF NOT Filter.ScheduleRep THEN
   BEGIN
    WriteField(EditX,6,Filter.sWorkNo,TRUE);
    WriteField(EditX,7,Filter.sRecipe,TRUE);
    WriteTickBox(EditX,8,Filter.DetailedRep);
   END;
 END;


BEGIN
 IF Filter.ScheduleRep THEN MaxEdit := 3 ELSE MaxEdit := 6;
 WriteStaticText;
 Filter.sWorkNo := SPACE_STRING;
 Filter.sRecipe := Space_String;
 Filter.DetailedRep := FALSE;
 Filter.StartDay := Date_To_Days(Date);
 Filter.EndDay   := Date_To_Days(Date);
 Filter.AllowDateRange := FALSE;
 EditPos := 1;
 REPEAT
  WriteInfo;
  PrimeValue;
  InputValue;
  OutPutValue;
  CheckCH1;
 UNTIL (Ch1 = ESC) OR (Ch1=FN_F2);
 InputToSelectionFilter;
 LoseWindow(CritWin);
 GetSelectionCriteria := Ch1<>ESC;
END;

PROCEDURE TScheduleReport.RunMacroReport(CopyFilter : TFilter);
BEGIN
 Move(CopyFilter,Filter,SizeOf(Filter));
 Inc(Filter.StartDay,Date_To_Days(Date));
 Inc(Filter.EndDay,Date_To_DayS(Date));
 GenerateReport;
END;

CONSTRUCTOR TScheduleReport.Init(SchRep : BOOLEAN);
BEGIN
 FillChar(Filter,SizeOf(Filter),#0);
 Filter.ScheduleRep := SchRep;
 INHERITED Init;
END;

PROCEDURE TScheduleReport.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
 IF Filter.ScheduleRep THEN
  ReportTitle    := 'Order Schedule Report'
 ELSE
  ReportTitle    := 'Order Detail Report';
END;


PROCEDURE TScheduleReport.PrintColumnHeadings;
BEGIN
 IF Filter.ScheduleRep THEN
  BEGIN
   PrintLnAt(CursorX,'                                                            Mixes');
   PrintLnAt(CursorX,' Sch. Date Order No  Recipe No Status Target Wt   Wt Done   Req  Done Seq Fixed');
   PrintLnAt(CursorX,'---------- --------- --------- ------ ---------  --------- ----  ---- ---------');
  END
 ELSE IF Filter.DetailedRep THEN
  BEGIN
   PrintLn;
   WITH WHRec DO
    BEGIN
     PrinterControl(CHighWrite);
     PrintAt(1,   'Order No : '+OrderNoToStr(WOH_OrderNo,WOH_Revision));
     PrintLnAt(24,'Recipe No : '+WOH_RecipeNo+'  Schedule Date : '+
                                                  Days_To_Date(WOH_SchDate));
     PrinterControl(CNormal);
    END;
  END
 ELSE
  BEGIN
   PrintLnAt(CursorX,'Ord. No    Sch. Date Recipe No Stat Mix Type  Target Wt  Wt Done  Batch Wt  Fix');
   PrintLnAt(CursorX,'--------- ---------- --------- ---- --------- --------- --------- --------- ---');
  END;
END;

PROCEDURE TScheduleReport.PrintSubColumnHeadings;
BEGIN
 PrintAt(  2,'Ingredient'+CCondensed+'                    '+CNormal+'Key Ratio%');
 PrintLnAt(DONEX,'Weight Req. Weight Done Act.Ratio% Variance%');
 PrintAt(  2,'----------'+CCondensed+'------------------- '+CNormal+'--- ------');
 PrintLnAt(DONEX,'----------- ----------- ---------- ---------');
END;

PROCEDURE TScheduleReport.PrintReportBody;

 PROCEDURE OrderDetailedReport;
 VAR
     MixNo : LONGINT;
     I : LONGINT;
     TFilter                  : TTransFilter;
     TrnQueryView             : PTranList;
     TrnQuery                 : PTrnQuery;
     MixStatRec               : TMixStatusRecord;
     LineWtDone               : DOUBLE;
     LinePrice                : DOUBLE;
     TempPrice                : DOUBLE;
     ActRatio                 : DOUBLE;
     DummyDoneRec             : TMixLineRecord;
     Temp_Ingred_TotWt        : DOUBLE;
     Temp_Ingred_Weighings    : LONGINT;
     Temp_Ingred_WtIncrements : DOUBLE;
     Temp_Ingred_WghsPerCont  : LONGINT;


  PROCEDURE BuildTransactionListForMix(MixNo : INTEGER);
  BEGIN
   FXTRNQRY.InitFilter(TFilter);
   TFilter.KeyNum         := 2;
   TFilter.MinWorkNo      := WHRec.WOH_OrderNo;
   TFilter.MaxWorkNo      := WHRec.WOH_OrderNo;
   TFilter.sMinorWO       := IntToZeroStr(WHRec.WOH_Revision,2);
   TFilter.IncludeActive  := TRUE;
   TFilter.IncludeAborted := FALSE;
   TFilter.MixNo          := MixNo;

   TrnQuery^.SetFilter(TFilter);          { Prime Query With Trans. Filter   }
   TrnQueryView^.DisposeList;            { Clear Any Previous Query Results }
   TrnQuery^.Run;                        { Execute Transaction Query        }
  END;


 BEGIN
  CheckPageBreak(9,TRUE);
  PrintColumnHeadings;
  WITH WHRec DO
   BEGIN
    CostFile^.OpenFile;
    TransFile^.OpenFile;
    MixStatusFile^.OpenFile;
    IngredientFile^.OpenFile;
    { Create Transaction Query Object Instances }
    TrnQueryView := New(PTranList,Init(ST_ByIngredient)); { Results In Keyed Order }
    TrnQuery     := New(PTrnQuery,Init(TrnQueryView));
    FOR MixNo := 1 TO WOH_NumMixes DO
     BEGIN
      MixStatusFile^.GetMixStatRec(WOH_OrderNo, WOH_Revision, MixNo,
                                   MixStatRec, FALSE);
      BuildTransactionListForMix(MixNo);

      IF CheckPageBreak(6,TRUE) THEN PrintColumnHeadings;
      PrintLn;
      PrinterControl(CHighWrite);
      PrintAt(1,'Mix No   :'+IntToStr(MixNo,3));
      PrinterControl(CNormal);
      PrintAt(CursorX,'   Mix Wt. Reqd: '+
                 DoubleToStr(MixStatRec.MIX_WtRequired,7,3));
      PrintLnAt(DONEX, 'Mix Wt. Done: '+
                    DoubleToStr(MixStatRec.MIX_WtDone,7,3));
      PrintAt(1,'Complete : '+ BoolToYNStr(MixStatRec.MIX_Complete,3));
      PrintLn;
      PrintSubColumnHeadings;
      I:=1;
      REPEAT
        WLErr := WorkLineFile^.Get_WO_Line_Record(WOH_OrderNo,WOH_Revision,I,WLRec);
        IF WLErr = 0 THEN
         BEGIN
          WITH WLRec DO
           BEGIN
            CalcWeightDoneAndPrices(WOL_Ingredient,WOL_LineNo,
                                    LineWtDone,LinePrice,TempPrice,TrnQueryView);

            CalcIngredReqsForMixWt(MixStatRec.MIX_WtRequired,
                                   @WHRec,
                                   @WLRec,
                                   DummyDoneRec,
                                   Temp_Ingred_TotWt,        {VAR}
                                   Temp_Ingred_Weighings,    {VAR}
                                   Temp_Ingred_WtIncrements, {VAR}
                                   Temp_Ingred_WghsPerCont); {VAR}


            IF CheckPageBreak(1,TRUE) THEN PrintSubColumnHeadings;

            ActRatio := DivDouble(LineWtDone*100, MixStatRec.MIX_WtDone);

            PrintAt(2,     WOL_Ingredient+'  '+
                           CCondensed+
                           Copy(GetIngredientDesc(WOL_Ingredient),1,19)+' '+CNormal+
                           BoolToYNStr(WOL_KeyIngredient,3)+
                           DoubleToStr(WOL_Ratio,7,3));

            PrintAt(DONEX, DoubleToStr(Temp_Ingred_TotWt,11,3));
            PrintAt(CursorX+1, DoubleToStr(LineWtDone,11,3));
            IF MixStatRec.MIX_Complete THEN
              PrintAt(CursorX, DoubleToStr(ActRatio,11,3)+
                               DoubleToStr(DivDouble((ActRatio-WOL_Ratio)*100,
                                                     WOL_Ratio),10,2));
            PrintLn;
           END;
         END;
        INC(I);
      UNTIL (WLErr <> 0);
     END;
    Dispose(TrnQuery,Done);
    Dispose(TrnQueryView,Done);
    IF IngredientFile^.OpenErr= 0 THEN IngredientFile^.CloseFile;
    IF MixStatusFile^.OpenErr= 0 THEN MixStatusFile^.CloseFile;
    IF TransFile^.OpenErr= 0 THEN TransFile^.CloseFile;
    IF CostFile^.OpenErr= 0  THEN CostFile^.CloseFile;
   END;
 END;

 PROCEDURE OrderNonDetailedReport;
 BEGIN
  IF  CheckPageBreak(1,TRUE) THEN PrintColumnHeadings;
  WITH WHRec DO
  PrintLnAt(CursorX,OrderNoToStr(WOH_OrderNo,WOH_Revision)+
                      ' '+Days_To_Date(WOH_SchDate)+
                      '  '+WOH_RecipeNo+
                      ' '+GetStatusType(WOH_Status)+
                      ' '+GetMixType(WOH_MixType)+
                      ' '+DoubleToStr(WOH_TotIngredWtReqd,9,3)+
                      ' '+DoubleToStr(WOH_WtDoneGross,9,3)+
                      ' '+DoubleToStr(WOH_MaxMixGrossWt,9,3)+
                      ' '+BoolToYNStr(WOH_SeqFixed,3));
 END;

BEGIN
 WITH WHRec DO
  BEGIN
   IF Filter.ScheduleRep THEN
    BEGIN
     IF  CheckPageBreak(1,TRUE) THEN PrintColumnHeadings;
     IF LastDate <> WOH_SchDate THEN
      BEGIN
       PrintAt(CursorX,Days_To_Date(WOH_SchDate));
       LastDate := WOH_SchDate;
      END
     ELSE PrintAt(CursorX,'          ');
     PrintLnAt(CursorX,' '+OrderNoToStr(WOH_OrderNo,WOH_Revision)+
                       '  '+WOH_RecipeNo+
                       '  '+GetStatusType(WOH_Status)+
                       '  '+DoubleToStr(WOH_TotIngredWtReqd,9,3)+
                       '  '+DoubleToStr(WOH_WtDoneGross,9,3)+
                       '  '+InttoStr(WOH_NumMixes,3)+
                       '  '+IntToStr(WOH_MixDone,3)+
                       '        '+BoolToYNStr(WOH_SeqFixed,3))
    END
   ELSE
    IF Filter.DetailedRep THEN OrderDetailedReport
    ELSE OrderNonDetailedReport;
  END;
END;

PROCEDURE TScheduleReport.OutputReport;
VAR ReadKey     : WORD;
    RecordFound : BOOLEAN;

 FUNCTION InFilter : BOOLEAN;
 BEGIN
  INFilter := FALSE;
  WITH Filter,WHRec DO
   BEGIN
    IF (NOT NowtButSpace(sWorkNo)) AND (NOT Str_Equal(sWorkNo,IntToZeroStr(WOH_OrderNo,6),Length(sWorkNo))) THEN EXIT;
    IF (AllowDateRange) AND ((WOH_SchDate <StartDay) OR (WOH_SchDate>EndDay)) THEN EXIT;
    IF NOT NowtButSpace(sRecipe) AND NOT Str_Equal(sRecipe, WOH_RecipeNo, 8) THEN EXIT;
   END;
  InFilter := TRUE;
 END;

BEGIN
 IF Filter.ScheduleRep THEN ReadKey := 0 ELSE ReadKey :=1;
 RecordFound := FALSE;
 LastDate := 0;
 IF NOT Filter.ScheduleRep THEN
  BEGIN
   WHRec.WOH_OrderNo := Filter.MinWorkNo;
  END;
 IF (WorkHeaderFile^.OpenFile = 0) AND (WorkLineFile^.OpenFile = 0) THEN
  BEGIN
   WHErr := WorkHeaderFile^.ReadRecord('GF',FALSE,FALSE,WHRec,ReadKey);
   WHILE (WHErr = 0) AND (NOT StopProcess) DO
    BEGIN
     DispSpin;
     IF InFilter THEN
      BEGIN
       PrintReportBody;
       RecordFound := TRUE;
      END;
     WHErr := WorkHeaderFile^.ReadRecord('GN',FALSE,FALSE,WHRec,ReadKey);
    END
  END;
 IF WorkHeaderFile^.OpenErr = 0 THEN WorkHeaderFile^.CloseFile;
 IF WorkLineFile^.OpenErr = 0 THEN WorkLineFile^.CloseFile;
 IF RecordFound THEN EndReport;
END;

PROCEDURE Print_Schedule_Report;
VAR TheReport : PScheduleReport;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,Init(TRUE));
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_ScheduleReport,TRUE,FALSE,FALSE);
END;

PROCEDURE Print_Order_Report;
VAR TheReport : PScheduleReport;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,Init(FALSE));
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_OrderReport,TRUE,FALSE,FALSE);
END;


END.

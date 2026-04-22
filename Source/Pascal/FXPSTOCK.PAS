(****************************************************************************
*  UNIT          : FXPSTOCK                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 17/05/96                                                 *
*  PURPOSE       : Schedule Report                                          *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXPStock;
INTERFACE
USES F6StdCtv,F6DtConv,F6StdUtl,F6StdChr,F6StdUt1,F6StdWn1,F6StdWin,F6StdRep,
     F6RepSee,FXModCtv,FXCfg,FXMenu,FXFStock,FXBRW_PR,FXFMacro,FXHelp,FXFRcp,
     FXFWork;


TYPE
     TOrderFilter = PACKED RECORD
      sProdCode      : TRecipeRef;
     END;


     PMixReq = ^TMixReq;
     TMixReq = PACKED RECORD
      Recipe       : TRecipeRef;
      MR_TotReqd   : LONGINT;
      MR_TotWtReqd : DOUBLE;
      MR_TotDone   : LONGINT;
      MR_TotIngredWtRem : DOUBLE;
      Next         : PMixReq;
     END;


     PStockReport = ^TStockReport;
     TStockReport = OBJECT(TReportObject)

      StockRec  : TStockRecord;
      Filter    : TOrderFilter;
      StockErr  : INTEGER;
      RecipeRec : TRecipeHeaderRecord;
      MixHeader : PMixReq;

      CONSTRUCTOR Init;
      (*PROCEDURE   ReportSetup; Virtual;*)
      PROCEDURE   PrintColumnHeadings; Virtual;
      PROCEDURE   PrintReportBody; Virtual;
      PROCEDURE   OutputReport; Virtual;
      FUNCTION    GetSelectionCriteria : BOOLEAN; VIRTUAL;
      PROCEDURE   RunMacroReport(CopyFilter : TFilter);VIRTUAL;
      PROCEDURE   BuildMixOrderList;
      PROCEDURE   DisposeMixReqList;
      FUNCTION    GetMixReq(RecipeCode : TRecipeRef) : PMixReq;
     END;



PROCEDURE Print_Stock_Report;

IMPLEMENTATION

FUNCTION TStockReport.GetSelectionCriteria : BOOLEAN;
CONST
      EditX     = 23;

VAR CritWin        : WindowRecord;
    Editpos        : INTEGER;
    lDate          : LONGINT;
    WrkStr         : STRING[10];
    EditLen        : INTEGER;
    MaxEdit        : INTEGER;
    FilterSave     : TOrderFilter;



 PROCEDURE CheckCh1;
 VAR FilterBuff : TFilter;
     TodayInDays: LONGINT;
 BEGIN
  CASE Ch1 OF
   NEXT : IF (EditPos < MaxEdit) THEN Inc(EditPos) ELSE EditPos := 1;
   PREV : IF (EditPos > 1      ) THEN Dec(EditPos) ELSE EditPos := MaxEdit;
   FN_F3 : BEGIN
            FillChar(FilterBuff,SizeOf(TFilter),#0);
            Move(Filter,FilterBuff,SizeOf(Filter));
            RepMacroFile^.AddNewRepMacroRecord(StockReportTitle,@FilterBuff);
           END;
  END;
 END;

 PROCEDURE WriteStaticText;
 BEGIN
  BackColourScheme;
  SetWindow(10,5,50,12,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,CritWin);
  Header(ReportTitle,1);
  Footer('ESC -Exit  F2 -Report  F3 -Save Macro',1);

  WriteAt(2,3,'   Stock Matching    [        ]');
  ForeColourScheme;
 END;

 PROCEDURE InputValue;
 BEGIN
  CASE EditPos OF
   1     : GetLine(Filter.sProdCode,8,EditX,2+EditPos);
  END;
 END;

 PROCEDURE WriteInfo;
 BEGIN
  WriteField(EditX,3,Filter.sProdCode,TRUE);
 END;


BEGIN
 WriteStaticText;
 Filter.sProdCode      := SPACE_STRING;
 EditPos := 1;
 MaxEdit := 1;
 REPEAT
  WriteInfo;
  InputValue;
  CheckCH1;
 UNTIL (Ch1 = ESC) OR (Ch1=FN_F2);
 LoseWindow(CritWin);
 GetSelectionCriteria := Ch1<>ESC;
END;

PROCEDURE TStockReport.RunMacroReport(CopyFilter : TFilter);
BEGIN
 Move(CopyFilter,Filter,SizeOf(Filter));
 GenerateReport;
END;

CONSTRUCTOR TStockReport.Init;
BEGIN
 FillChar(Filter,SizeOf(Filter),#0);
 MixHeader := NIL;
 INHERITED Init;
END;

(*
PROCEDURE TStockReport.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
 ReportTitle    := 'Stock Report';
END;
*)

PROCEDURE TStockReport.BuildMixOrderList;
VAR WorkRec : TWOHeaderRecord;
    WorkErr : INTEGER;

  PROCEDURE AddTolist;
  VAR NewRec : PMixReq;
  BEGIN
   WITH WorkRec DO
    BEGIN
     NewRec := GetMixReq(WOH_RecipeNo);
     IF (NewRec = NIL) THEN
      BEGIN
       New(NewRec);
       FillChar(NewRec^,Sizeof(NewRec^),0);
       NewRec^.Recipe := WOH_RecipeNo;
       {Order In List Is Not Important}
       NewRec^.Next := MixHeader;
       MixHeader    := NewRec;
      END;

     Inc(NewRec^.MR_TotReqd,WOH_NumMixes);
     NewRec^.MR_TotWtReqd := NewRec^.MR_TotWtReqd + WOH_FinishWtReqd;
     Inc(NewRec^.MR_TotDone,WOH_MixDone);
     IF WOH_MixDone < WOH_NumMixes THEN
       NewRec^.MR_TotIngredWtRem := NewRec^.MR_TotIngredWtRem +
                                     (WOH_TotIngredWtReqd - WOH_WtDoneGross);
    END;
  END;

BEGIN
 MixHeader := NIL;
 IF (WorkHeaderFile^.OpenFile = 0) THEN
  BEGIN
   WorkErr := WorkHeaderFile^.ReadRecord('GF',FALSE,FALSE,WorkRec,0);
   WHILE (WorkErr = 0) DO
    BEGIN
     DispSpin;
     IF (WorkRec.WOH_Status = StatusWIP) THEN
      BEGIN
       AddToList;
      END;
     WorkErr := WorkHeaderFile^.ReadRecord('GN',FALSE,FALSE,WorkRec,0);
    END;
   WorkHeaderFile^.CloseFile;
  END;
END;

PROCEDURE TStockReport.DisposeMixReqList;
VAR LoopRec,DelRec : PMixReq;
BEGIN
 LoopRec := MixHeader;
 WHILE (LoopRec <> NIL) DO
  BEGIN
   DelRec  := LoopRec;
   LoopRec := LoopRec^.Next;
   Dispose(DelRec);
  END;
 MixHeader := NIL;
END;

FUNCTION TStockReport.GetMixReq(RecipeCode : TRecipeRef) : PMixReq;
VAR LoopRec : PMixReq;
BEGIN
 LoopRec := MixHeader;
 WHILE (LoopRec <> NIL) AND (LoopRec^.Recipe <> RecipeCode) DO LoopRec := LoopRec^.Next;
 GetMixReq := LoopRec;
END;

PROCEDURE TStockReport.PrintColumnHeadings;
BEGIN
 PrintLnAt(CursorX,'                                                 MIXES    WEIGHT STILL  TOTAL ');
 PrintLnAt(CursorX,'COMPOUND STOCK  MIX   INITIAL CURRENT  STOCK     ON WIP   OF WIP  TO    WEIGHT');
 PrintLnAt(CursorX,' CODE     REQ. WEIGHT  STOCK   STOCK  SHORTAGE   ORDERS   ORDERS  MIX   TO MIX');
 PrintLnAt(CursorX,'-------- ----- ------ ------- ------- -------- -------- -------- -----  ------');
END;

PROCEDURE TStockReport.PrintReportBody;
VAR
    StockFound   : BOOLEAN;
    MixReq       : PMixReq;
BEGIN
 IF CheckPageBreak(1,TRUE) THEN PrintColumnHeadings;
 FillChar(StockRec,Sizeof(StockRec),0);
 StockRec.STOCK_Product := RecipeRec.RH_RecipeNo;
 StockFound := StockFile^.ReadRecord('EQ',FALSE,FALSE,StockRec,0)= 0;
 IF (NOT StockFound) THEN FillChar(StockRec,Sizeof(StockRec),0);
 WITH StockRec,RecipeRec DO
  BEGIN
   PrintAt(CursorX,    RH_RecipeNo+                    {Code}
                   ' '+IntToStr(RH_BasicStock,5)+      {Basic Stock Level}
                   ' '+DoubleToStr(RH_DefaultMixWt,6,2));{Mix Weight}
   PrintAt(CursorX,' '+'       ');                 {Inital Stock}
   PrintAt(CursorX,' '+IntToStr(STOCK_InStock,7)); {Current Stock}
   PrintAt(CursorX,' '+IntToStr(RH_BasicStock-STOCK_InStock,8));
   MixReq := GetMixReq(RH_RecipeNo);
   IF (MixReq <> NIL) THEN
    BEGIN
     PrintAt(CursorX,' '+IntToStr(MixReq^.MR_TotReqd,8)+
                     ' '+DoubleToStr(MixReq^.MR_TotWtReqd,8,2)+
                     ' '+IntToStr(MixReq^.MR_TotReqd-MixReq^.MR_TotDone,5)+
                     ' '+DoubleToStr(MixReq^.MR_TotIngredWtRem,7,2));
    END
   ELSE
    BEGIN
     PrintAt(CursorX,' '+IntToStr(0,8)+
                     ' '+DoubleToStr(0,8,2)+
                     ' '+IntToStr(0,5)+
                     ' '+DoubleToStr(0,7,2));
    END;
   PrintLnAt(CursorX,'');
  END;
END;

PROCEDURE TStockReport.OutputReport;
VAR
    RecordFound : BOOLEAN;

 FUNCTION InFilter : BOOLEAN;
 BEGIN
  INFilter := FALSE;
  WITH Filter,RecipeRec DO
   BEGIN
    IF (NOT NowtButSpace(sProdCode)) AND (NOT Str_Equal(sProdCode,RH_RecipeNo,Length(sProdCode))) THEN EXIT;
   END;
  InFilter := TRUE;
 END;

BEGIN
 RecordFound := FALSE;
 BuildMixOrderList;
 FillChar(StockRec,Sizeof(StockRec),0);
 IF (StockFile^.OpenFile = 0) AND (RecipeHeaderFile^.OpenFile = 0) THEN
  BEGIN
   StockErr := RecipeHeaderFile^.ReadRecord('GF',FALSE,FALSE,RecipeRec,0);
   WHILE (StockErr = 0) AND (NOT StopProcess) DO
    BEGIN
     DispSpin;
     IF InFilter THEN
      BEGIN
       PrintReportBody;
       RecordFound := TRUE;
      END;
     StockErr := RecipeHeaderFile^.ReadRecord('GN',FALSE,FALSE,RecipeRec,0);
    END
  END;
 IF StockFile^.OpenErr = 0 THEN StockFile^.CloseFile;
 IF (RecipeHeaderFile^.OpenErr = 0) THEN RecipeHeaderFile^.CloseFile;
 IF RecordFound THEN EndReport;
 DisposeMixReqList;
END;

PROCEDURE Print_Stock_Report;
VAR TheReport : PStockReport;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,InitWithTitle('Stock Report'));
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_ScheduleReport,TRUE,FALSE,FALSE);
END;

END.
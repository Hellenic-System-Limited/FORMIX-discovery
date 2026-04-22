(****************************************************************************
*  UNIT          : FXPUSER                                                  *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 12/05/96                                                 *
*  PURPOSE       : FORMIX User Weighing Transaction file reporter           *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXPUSER;
INTERFACE
USES F6StdCtv,FXModCtv,FXMenu,F6DtConv,F6StdUtl,F6StdUt1,F6StdWin,F6StdWn1,F6RepSee,
     FXFTrn,F6StdRep,FXCfg,FXFIngr,FXBrw_IN,FXHelp,FXFWork,FXFMacro,FileObj,F6Btrv;

PROCEDURE Print_User_Weighings;

TYPE TUserFilter = PACKED RECORD
      Ingredient : TIngredientRef;
      StartDay   : LONGINT;
      EndDay     : LONGINT;
      sUserID    : TUserRef;
      sBatchNo   : TBatchRef;
      SLotNo     : TLotRef;
      Batch,Lot  : BOOLEAN;
      AllowDateRange  : BOOLEAN;
     END;


TYPE PUserWeighingReport = ^TUserWeighingReport;
     TUserWeighingReport = OBJECT(TReportObject)

      Filter      : TUserFilter;
      ACTrnFound,
      ABTrnFound  : LONGINT;
      ACTotalWt,
      ABTotalWt   : DOUBLE;
      LastUser    : TUserRef;


      PROCEDURE   ReportSetup; Virtual;
      PROCEDURE   PrintColumnHeadings; Virtual;
      PROCEDURE   PrintReportBody; Virtual;
      PROCEDURE   OutputReport; Virtual;
      FUNCTION    GetSelectionCriteria : BOOLEAN; VIRTUAL;
      PROCEDURE   RunMacroReport(CopyFilter : TFilter);VIRTUAL;
      PROCEDURE   BuildTransactionList;
     END;

IMPLEMENTATION
CONST EditX = 25;

CONST User_FileName = 'USERFILE.TMP';

TYPE
     TUserWRecord = PACKED RECORD
      UserID     : TUSerRef;
      Ingredient : TIngredientRef;{Ingredient}
      ACWeight   : DOUBLE;        {Combined Weight Of all Active Ingredients}
      ACNumCont  : LONGINT;       {Number Of Active Containers}
      ABWeight   : DOUBLE;        {Combined Weight Of all Aborted Ingredients}
      ABNumCont  : LONGINT;       {Number Of Aborted Containers}
      BatchNo    : TBatchRef;
      LotNo      : TLotRef;
     END;

 TUserFile = OBJECT(TBtrvFileObject)
  PROCEDURE InitRecord(VAR RecBuff); VIRTUAL;
  FUNCTION GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
 END;

VAR UserFile : TUserFile;
    UserRec  : TUserWRecord;


PROCEDURE TUserFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOf(TUserWRecord),#0);
 WITH TUserWRecord(RecBuff) DO
  BEGIN
   UserID     := SPACE_STRING;
   Ingredient := SPACE_STRING;
   BatchNo    := SPACE_STRING;
   LotNo      := SPACE_STRING;
  END;
END;

FUNCTION TUserFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TUserWRecord);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.0 UserID}
   INC(SegC,Set_Key(Key_Buf[0],01,09,K_EXTTYPE OR K_SEGMENTED,EKT_LSTRING,0));
   { 0.1 Ingredient}
   INC(SegC,Set_Key(Key_Buf[1],10,09,K_EXTTYPE,EKT_LSTRING,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;


FUNCTION TUserWeighingReport.GetSelectionCriteria : BOOLEAN;
VAR CritWin : WindowRecord;
   Editpos  : INTEGER;
   lDate    : LONGINT;
   WrkStr   : STRING[10];
   EditLen  : INTEGER;


PROCEDURE SetFilter;
BEGIN
 FillChar(Filter,SizeOf(Filter),#0);
 WITH Filter DO
  BEGIN
   Ingredient := SPACE_STRING;
   sUserID    := SPACE_STRING;
   StartDay   := Date_To_Days(Date);
   EndDay     := Date_To_Days(Date);
   sBatchNo   := SPACE_STRING;
   SLotNo     := SPACE_STRING;
  END;
END;

PROCEDURE DrawCriteriaWindow;
CONST HeaderTxt = 'User Weighing Report';


 PROCEDURE WriteStaticText;
 BEGIN
  Header(HeaderTxt,1);
  Footer('ESC-Exit  F2-Report  F3-Save Macro',1);
      WriteAt(2,3 ,'   Use Date Range      [ ]');
      WriteAt(2,4 ,'   Min Date            [  /  /    ]');
      WriteAt(2,5 ,'   Max Date            [  /  /    ]');
      WriteAt(2,6 ,'   Users Matching      [        ]');
  HighWriteAt(2,7 ,'   Ingredient Matching [        ]');
      WriteAt(2,8 ,'   Batch Number        [      ]');
      WriteAt(2,9 ,'   Lot Number          [              ]');
 END;

BEGIN
 BackColourScheme;
 SetWindow(10,7,56,19,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,CritWin);
 WriteStaticText;
 ForeColourScheme;
END;

PROCEDURE WriteInfo;
BEGIN
 WriteTickBox(EditX,3,Filter.AllowDateRange);
 IF Filter.AllowDateRange THEN WriteField(EditX, 4,Days_To_Date(Filter.StartDay),TRUE);
 IF Filter.AllowDateRange THEN WriteField(EditX, 5,Days_To_Date(Filter.EndDay),TRUE);
 WriteField(EditX, 6,Filter.sUserId,TRUE);
 WriteField(EditX, 7,Filter.Ingredient,TRUE);
 WriteField(EditX, 8,Filter.sBatchNo,TRUE);
 WriteField(EditX, 9,Filter.sLotNo,TRUE);
END;

PROCEDURE OutputValue;
BEGIN
 CASE EditPos OF
  2 : Filter.StartDay   := lDate;
  3 : Filter.EndDay     := lDate;
  4 : Filter.sUserID    := WrkStr;
  5 : Filter.Ingredient := WrkStr;
  6 : Filter.sBatchNo   := WrkStr;
  7 : Filter.sLotNo     := WrkStr;
 END;
END;

PROCEDURE InputValue;
BEGIN
 CASE EditPos OF
  1     : GetBoolean(Filter.AllowDateRange,EditX,3,TickBox);
  2,3   : IF Filter.AllowDateRange THEN GetDate(lDate,EDitX,2+EditPos);
  4,5   : GetLine(WrkStr,EditLen,EditX,2+EditPos);
  6,7   : GetLine(WrkStr,EditLen,EditX,2+EditPos);
 END;
END;

PROCEDURE PrimeValue;
BEGIN
 CASE EditPos OF
  2 : lDate := Filter.StartDay;
  3 : lDate := Filter.EndDay;
  4 : BEGIN
       EditLen := 8;
       WrkStr  := Filter.sUSerID;
      END;
  5 : BEGIN
       EditLen := 8;
       WrkStr  := Filter.Ingredient;
      END;
  6 : BEGIN
       EditLen := 6;
       WrkStr := Filter.sBatchNo;
      END;
  7 : BEGIN
       EditLen := 14;
       WrkStr := Filter.sLotNo;
      END;
 END;
END;


 PROCEDURE CheckCh1;
 VAR TransferBuff : TIngredient_Record;
     FilterBuff   : TFilter;
 BEGIN
  CASE Ch1 OF
   NEXT : IF EditPos<11 THEN Inc(EditPos) ELSE EditPos :=1;
   PREV : IF EditPos>1  THEN Dec(EditPos) ELSE EditPos :=11;
   FN_F1: IF EditPos = 5 THEN
    BEGIN
     TransferBuff.ING_Ingredient := Filter.Ingredient;
     IngredientLookup(@TransferBuff);
     IF NOT NowtButSpace(TransferBuff.ING_Ingredient) THEN
      Filter.Ingredient  := TransferBuff.ING_Ingredient;
    END;
   FN_F3 : BEGIN
            FillChar(FilterBuff,SizeOf(TFilter),#0);
            Move(Filter,FilterBuff,SizeOf(Filter));
            RepMacroFile^.AddNewRepMacroRecord(UserWeighingTitle,@FilterBuff);
           END;
  END;
 END;

BEGIN
 DrawCriteriaWindow;
 SetFilter;
 EditPos := 1;
 REPEAT
  WriteInfo;
  PrimeValue;
  InputValue;
  OutPutValue;
  CheckCH1;
 UNTIL (Ch1 = ESC) OR (Ch1=FN_F2);
 LoseWindow(CritWin);
 GetSelectionCriteria := Ch1 <> ESC;
END;

PROCEDURE TUserWeighingReport.BuildTransactionList;
VAR
    TRNRec     : TTranRecord;
    ReadTRNErr : INTEGER;
    Weight     : DOUBLE;
    ExitLoop   : BOOLEAN;

  PROCEDURE GetFirstTransaction;
  BEGIN
   FillChar(TRNRec,SizeOf(TRNRec),#0);
   ReadTRNErr := TransFile^.ReadRecord('GF',FALSE,FALSE,TRNRec,1);
  END;

  PROCEDURE GetNextTransaction;
  BEGIN
   ReadTRNErr := TransFile^.ReadRecord('GN',FALSE,FALSE,TRNRec,1);
  END;


  FUNCTION TransactionWithinFilter : BOOLEAN;
  BEGIN
   TransactionWithinFilter := FALSE;
   WITH Filter,TRNRec DO
    BEGIN
     IF (AllowDateRange) AND ((StartDay  > TRN_Date) OR (EndDay < TRN_Date)) THEN EXIT;
     IF (NOT NowtButSpace(sUserID)) AND (NOT Str_Equal(sUserID,TRN_UserID,Length(sUSerID))) THEN EXIT;
     IF (NOT NowtButSpace(Ingredient)) AND (NOT Str_Equal(Ingredient,TRN_Ingredient,Length(Ingredient))) THEN EXIT;
     IF (NOT NowtButSpace(sBatchNO)) AND (NOT Str_Equal(sBatchNo,TRN_BatchNo,Length(sBatchNo))) THEN EXIT;
     IF (NOT NowtButSpace(sLotNo)) AND (NOT Str_Equal(sLotNo,TRN_LotNo,Length(sLotNo))) THEN EXIT;
    END;
   TransactionWithinFilter := TRUE;
  END;

  PROCEDURE AddRecordToList;
  VAR USerItem   : TUserWRecord;

   PROCEDURE InitNewRecord;
   BEGIN
    UserFile.InitRecord(UserItem);
    WITH UserItem DO
     BEGIN
      UserID     := TRNRec.TRN_UserId;
      Ingredient := TRNRec.TRN_Ingredient;
      BatchNo    := TRNRec.TRN_BatchNo;
      LotNo      := TRNRec.TRN_LotNo;
     END
   END;

   PROCEDURE AddToTotals;
   BEGIN
    WITH UserItem DO
     BEGIN
      IF TRNRec.TRN_Status IN [TRNStatusActive] THEN
       BEGIN
        ACWeight   := ACWeight + TRNRec.TRN_ContainerWt;
        IF TRNRec.TRN_Status = TRNStatusActive THEN INC(ACNumCont);
       END
      ELSE
       BEGIN
        ABWeight := ABWeight + TRNRec.TRN_ContainerWt;
        IF TRNRec.TRN_Status = TRNStatusAborted THEN INC(ABNumCont);
       END;
     END;
   END;

  BEGIN
   UserItem.UserID     := TRNRec.TRN_UserID;
   UserItem.Ingredient := TRNRec.TRN_Ingredient;
   IF UserFile.ReadRecord('EQ',TRUE,FALSE,UserItem,0) = 0 THEN
    BEGIN
     AddToTotals;
     UserFile.UpdateRecord(UserItem);
    END
   ELSE
    BEGIN
     InitNewRecord;
     AddToTotals;
     UserFile.AddRecord(UserItem);
    END;
  END;

  FUNCTION TRNWithinLimits : BOOLEAN;
  BEGIN
   TRNWithinLimits := TRUE;
  END;

BEGIN
 IF TransFile^.OpenFile = 0 THEN
  BEGIN
   GetFirstTransaction;
   IF (ReadTRNErr = 0) AND TRNWithinLimits THEN
    BEGIN
     REPEAT
      DispSpin;
      IF TransactionWithinFilter THEN AddRecordToList;
      GetNextTransaction;
      EXitLoop := NOT TRNWithinLimits;
     UNTIL (ReadTRNErr <> 0) OR ExitLoop;
    END;
   TransFile^.CloseFile;
  END;
END;

PROCEDURE   TUserWeighingReport.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
 ReportTitle    := 'User Weighing Report';
END;

PROCEDURE   TUserWeighingReport.PrintColumnHeadings;
BEGIN
 PrintLn;
 PrintLnAt(CursorX,'                     ---- Active ----  --- Aborted ----');
 PrintLnAt(CursorX,'User ID   Ingredient  Weight    Conts   Weight    Conts');{   Batch   Lot No ');}
 PrintLnAt(CursorX,'--------  ---------- ---------  -----  ---------  -----');{  ------  --------------');}
END;

PROCEDURE   TUserWeighingReport.PrintReportBody;
VAR Loop     : TUserWRecord;
    LastProd : TIngredientRef;
    TotWeight: DOUBLE;
    Numcont  : LONGINT;
BEGIN
 IF CheckPageBreak(1,TRUE) THEN PrintColumnHeadings;
 UserFile.ReadRecord('GF',FALSE,FALSE,Loop,0);
 WHILE (UserFile.BtrvErr = 0) AND (NOT StopProcess) DO
  BEGIN
   WITH Loop DO
    BEGIN
     IF CheckPageBreak(3,TRUE) THEN PrintColumnHeadings;
     INC(ACTrnFound,ACNumCont);
     ACTotalWt := ACTotalWt + Loop.ACWeight;
     INC(ABTrnFound,ABNumCont);
     ABTotalWt := ABTotalWt + Loop.ABWeight;
     IF LastUser <> UserID THEN
      BEGIN
       PrintAt(CursorX,UserID);
       LastUser := UserID;
      END
     ELSE
      PrintAt(CursorX,'        ');
     PrintLnAt(CursorX,'    ' +Ingredient+
                       ' ' +DoubleToStr(ACWeight,9,3)+
                       '  '+IntToStr(ACNumCont,5)+
                       '  '+DoubleToStr(ABWeight,9,3)+
                       '  '+IntToStr(ABNumCont,5)+
 {                      '  '+BatchNo+
                       '  '+LotNo+}
                       ' ');
    END;
   UserFile.ReadRecord('GN',FALSE,FALSE,Loop,0);
  END;
END;

PROCEDURE TUserWeighingReport.RunMacroReport(CopyFilter : TFilter);
BEGIN
 MOVE(Copyfilter,Filter,SizeOf(Filter));
 INC(Filter.StartDay,Date_To_Days(Date));
 Inc(Filter.EndDay,Date_To_Days(Date));
 GenerateReport;
END;

PROCEDURE   TUserWeighingReport.OutputReport;
VAR
    DelFile    : FILE;
BEGIN
 LastUser := SPACE_STRING;
 UserFile.Init(Config_Rec^.Conf_FPath+User_FileName);
 UserFile.Create;
 UserFile.OpenFile;
 ACTRNFound := 0;
 ABTrnFound := 0;
 ACTotalWt  := 0.0;
 ABTotalWt  := 0.0;
 BuildTransactionList;
 PrintReportBody;
 IF ACTRNFound+ABTRNFound <> 0 THEN
  BEGIN
   PrintLnAt(CursorX,'                     ---------  -----  ---------  -----');
   PrintLnAt(CursorX,'              Total  '+
                              DoubleToStr(ACTotalWt,9,3)+'  '+IntToStr(ACTRNFound,5)+'  '+
                              DoubleToStr(ABTotalWt,9,3)+'  '+IntToStr(ABTRNFound,5));
   EndReport;
  END;
 UserFile.CloseFile;
 USerFIle.Done;
 Assign(DelFile,Config_Rec^.Conf_FPath+User_FileName);
 {$I-}
 Erase(DelFile);
 {$I+}
 IF IORESULT <> 0 THEN BEGIN END;
END;

PROCEDURE Print_User_Weighings;
VAR TheReport : PUserWeighingReport;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,Init);
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_TransactionRep,TRUE,FALSE,FALSE);
END;


END.

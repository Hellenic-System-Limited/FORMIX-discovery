(****************************************************************************
*  UNIT          : FXFMacro                                                 *
*  AUTHOR        : N. Spooner                                               *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : FORMIX REPORT MACRO FILE                                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFMacro;
INTERFACE
USES F6Btrv,F6StdCtv,FXModCtv,FileObj;

CONST RepMacro_FileName    = 'REPMACRO.FIL';
      MacroHeader_FileName = 'MACROGRP.FIL';
      MacroLine_FileName   = 'MACROLN.FIL';

CONST

      AssignmentReportTitle = 01;
      IngredientReportTitle = 02;
      NetReportTitle        = 03;
      OrderReportTitle      = 04;
      ProdReportTitle       = 05;
      RecipeReportTitle     = 06;
      ScheduleReportTitle   = 07;
      TranReportTitle       = 08;
      UserWeighingTitle     = 09;
      StockReportTitle      = 10;

      MaxReportNo           = StockReportTitle;

TYPE
    PMacroHeaderRecord = ^TMacroHeaderRecord;
    TMacroHeaderRecord = PACKED RECORD
     MAC_UniqueRef  : LONGINT;
     MAC_HeaderName : TMacroHeaderRef;
     MAC_UpdateCount: LONGINT;
     MAC_Reserved   : ARRAY[0..18] OF BYTE;
    END;

    PMacroLineRecord = ^TMacroLineRecord;
    TMacroLineRecord = PACKED RECORD
     MACL_HeaderRef : LONGINT;
     MACL_LineRef   : LONGINT;
     MACL_Reserved  : ARRAY[0..23] OF BYTE;
    END;

    PRepMacroRecord = ^TRepMacroRecord;
    TRepMacroRecord = PACKED RECORD
     REP_Report    : INTEGER;
     REP_UniqueRef : LONGINT;
     REP_ID        : TMacroIDRef;
     REP_RepFilter : TFilter;
     REP_PrintOnly : BOOLEAN;
     REP_Reserved  : ARRAY[0..63] OF CHAR;
    END;

  PRepMacroFile = ^TRepMacroFile;
  TRepMacroFile = OBJECT(TBtrvFileObject)
   PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
   FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
   PROCEDURE  AddNewRepMacroRecord(ReportNumber : INTEGER;Filter : PFilter);
   FUNCTION   GetUsingUniqueRef(UniqueRef : LONGINT;Lock,Multi : BOOLEAN;
                               VAR TheRecord : TRepMacroRecord) : INTEGER;
  END;

  PMacroHeaderFile = ^TMacroHeaderFile;
  TMacroHeaderFile = OBJECT(TBtrvFileObject)
   PROCEDURE InitRecord (VAR RecBuff); VIRTUAL;
   FUNCTION  GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;VIRTUAL;
  END;

  PMacroLineFile = ^TMacroLineFile;
  TMacroLineFile = OBJECT(TBtrvFileObject)
   PROCEDURE InitRecord(VAR RecBuff); VIRTUAL;
   FUNCTION  GetFileSpec(VAR FileSpec : FILE_SPEC): INTEGER;VIRTUAL;
   FUNCTION  GetFirstHeaderRef(HeaderRef : LONGINT;Lock,Multi : BOOLEAN;
                                 VAR TheRecord : TMacroLineRecord) : INTEGER;
  END;

FUNCTION GetReportTitle(ReportNo : INTEGER) : STRING;

VAR
  RepMacroFile    : PRepMacroFile;
  MacroHeaderFile : PMacroHeaderFile;
  MacroLineFile   : PMacroLineFile;

IMPLEMENTATION
{$IFNDEF TERMINAL}
USES F6StdWin,F6StdUtl,F6StdUt1,F6StdWn1;
{$ENDIF}

CONST ReportTitles : ARRAY[AssignmentReportTitle..StockReportTitle] OF STRING40=(
                        'INGREDIENT ASSIGNMENT         ',
                        'INGREDIENT REPORT             ',
                        'INGREDIENT USAGE              ',
                        'ORDER REPORT                  ',
                        'PRODUCT REPORT                ',
                        'RECIPE REPORT                 ',
                        'SCHEDULE REPORT               ',
                        'TRANSACTION LISTING           ',
                        'USER WEIGHINGS                ',
                        'STOCK REPORT                  '
                       );


FUNCTION GetReportTitle(ReportNo : INTEGER) : STRING;
BEGIN
 IF (ReportNo >= AssignmentReportTitle) AND (ReportNo <= MaxReportNo) THEN
  GetReportTitle := ReportTitles[ReportNo]
 ELSE
  GetReportTitle := COPY('Report Not Found'+SPACE_STRING,1,40);
END;

PROCEDURE TRepMacroFile.AddNewRepMacroRecord(ReportNumber : INTEGER;Filter : PFilter);
VAR RepMacroRec : TRepMacroRecord;
    RepMacroWin : WindowRecord;
BEGIN
 IF RepMacroFile^.OpenFile = 0 THEN
  BEGIN
   RepMacroFile^.InitRecord(RepMacroRec);
   RepMacroRec.REP_Report    := ReportNumber;
   RepMacroRec.REP_PrintOnly := TRUE;
   BackColourScheme;
   SetWindow(13,10,48,15,TRUE,SW_DEFAULT,SW_DEFAULT,RepMacroWin);
   Header('Enter Report Identification',1);
   ForeColourScheme;
   REPEAT
    REPEAT
     GetLine(RepMacroRec.REP_ID,30,2,3);
    UNTIL (Ch1 = ESC) OR (NOT NowtButSpace(RepMacroRec.REP_ID));
    Move(Filter^,RepMacroRec.REP_RepFilter,SizeOf(TFilter));
   UNTIL (ch1 = ESC) OR (Show_Btrv_Err(RepMacroFile^.AddRecord(RepMacroRec)) <> BDuplicate);
   LoseWindow(RepMacroWin);
   RepMacroFile^.CloseFile;
  END;
END;

FUNCTION TRepMacroFile.GetUsingUniqueRef(UniqueRef : LONGINT;Lock,Multi : BOOLEAN;
                                     VAR TheRecord : TRepMacroRecord) : INTEGER;
VAR ReadErr : INTEGER;
BEGIN

 TheRecord.REP_UniqueRef := UniqueRef;
 ReadErr := ReadRecord('EQ',Lock,Multi,TheRecord,1);
 IF (ReadErr <> 0) THEN
  BEGIN
   InitRecord(TheRecord);
   TheRecord.REP_Report := -1;
  END;
 GetUsingUniqueRef := ReadErr;
END;


PROCEDURE TRepMacroFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOf(TRepMacroRecord),#0);
 WITH TRepMacroRecord(RecBuff) DO
  BEGIN
   REP_ID     := SPACE_STRING;
  END;
END;

FUNCTION TRepMacroFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TRepMacroRecord);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 2;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.0 MAC_Report}
   INC(SegC,Set_Key(Key_Buf[0],01,02,K_EXTTYPE OR K_SEGMENTED,EKT_INTEGER,0));
   { 0.1 MAC ID}
   INC(SegC,Set_Key(Key_Buf[1],07,41,K_EXTTYPE,EKT_LSTRING,0));
   { 1.0 Unique Reference}
   INC(SegC,Set_Key(Key_Buf[2],03,04,K_EXTTYPE,EKT_AUTO_INC,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

PROCEDURE TMacroHeaderFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOf(TMacroHeaderRecord),#0);
 WITH TMacroHeaderRecord(RecBuff) DO
  BEGIN
   MAC_HeaderName := SPACE_STRING;
  END;
END;

FUNCTION TMacroHeaderFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TMacroHeaderRecord);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.0 Unique Ref}
   INC(SegC,Set_Key(Key_Buf[0],01,04,K_EXTTYPE,EKT_AUTO_INC,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

PROCEDURE TMacroLineFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOf(TMacroLineRecord),#0);
 WITH TMacroLineRecord(RecBuff) DO
  BEGIN
  END;
END;

FUNCTION TMacroLineFile.GetFirstHeaderRef(HeaderRef : LONGINT;
                                     Lock,Multi : BOOLEAN;
                                 VAR TheRecord : TMacroLineRecord) : INTEGER;
BEGIN
 InitRecord(TheRecord);
 TheRecord.MACL_HeaderRef := HeaderRef;
 GetFirstHeaderRef := ReadRecord('GE',Lock,Multi,TheRecord,0);
END;

FUNCTION TMacroLineFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TMacroLineRecord);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.0 Header Ref}
   INC(SegC,Set_Key(Key_Buf[0],01,04,K_EXTTYPE OR K_SEGMENTED,EKT_INTEGER,0));
   { 0.1 Line Ref}
   INC(SegC,Set_Key(Key_Buf[1],05,04,K_EXTTYPE,EKT_INTEGER,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

END.

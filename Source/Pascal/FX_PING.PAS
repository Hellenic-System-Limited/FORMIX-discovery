(****************************************************************************
*  UNIT          : FX_PING                                                   *
*  AUTHOR        : S. M. Wright                                             *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : FORMIX PRINT INGREDIENT FILE LISTING                     *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FX_PING;
INTERFACE

USES FXFINGR,F6StdWin,F6StdCtv,FXModCtv,F6StdUt1,F6STDUTL,F6STDREP,F6RepSee,
     FXBRW_IN,FXCFG,FxHelp,FXFMacro;

PROCEDURE Print_IngredientList;

TYPE
     TIngredientFilter = PACKED RECORD
      IMatch   : TIngredientRef;
     END;


TYPE PIngredientReport = ^TIngredientReport;
     TIngredientReport  = OBJECT(TReportObject)
      IRec     : TIngredient_Record;
      Filter   : TIngredientFilter;
      PROCEDURE   ReportSetup; Virtual;
      PROCEDURE   PrintColumnHeadings; Virtual;
      PROCEDURE   PrintReportBody; Virtual;
      PROCEDURE   OutputReport; Virtual;
      FUNCTION    GetSelectionCriteria : BOOLEAN; VIRTUAL;
      PROCEDURE   RunMacroReport(CopyFilter : TFilter);VIRTUAL;
     END;

IMPLEMENTATION

VAR TheReport : PIngredientReport;
    RepName   : STRING[12];

FUNCTION TIngredientReport.GetSelectionCriteria : BOOLEAN;
VAR CritWin : WindowRecord;

 PROCEDURE CheckCh1;
 VAR TransferBuff : TIngredient_Record;
     FilterBuff   : TFilter;
 BEGIN
  CASE Ch1 OF
   FN_F1:BEGIN
     TransferBuff.ING_Ingredient := Filter.IMatch;
     IngredientLookup(@TransferBuff);
     IF NOT NowtButSpace(TransferBuff.ING_Ingredient) THEN
      Filter.IMatch  := TransferBuff.ING_Ingredient;
    END;
   FN_F3 : BEGIN
           FillChar(FilterBuff,SizeOf(TFilter),#0);
           Move(Filter,FilterBuff,SizeOf(Filter));
           RepMacroFile^.AddNewRepMacroRecord(IngredientReportTitle,@FilterBuff);
          END;
  END;
 END;


BEGIN
 BackColourScheme;
 SetWindow(20,5,57,11,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,CritWin);
 Header('Ingredient Report',1);
 Footer('ESC-Exit  F2-Report  F3-Save Macro',1);
 HighWriteAt(2,3,' Ingredient Matching');
 ForeColourScheme;
 Filter.IMatch := SPACE_STRING;
 REPEAT
  GetLine(Filter.IMatch,8,24,3);
  CheckCh1;
 UNTIL (Ch1 = ESC) OR (ch1 = FN_F2);
 GetSelectionCriteria := Ch1 <> ESC;
 LoseWindow(CritWin);
END;

PROCEDURE TIngredientReport.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
 ReportTitle    := 'Ingredient Listing';
END;

PROCEDURE TIngredientReport.PrintColumnHeadings;
BEGIN
 PrintLnAt(CursorX,'Ingredient  Description                     Type     Lo Tol.    Hi Tol.  ');
 PrintLnAt(CursorX,'----------  ------------------------------  -------  ---------  ---------');
END;

PROCEDURE TIngredientReport.PrintReportBody;
BEGIN
 IF CheckPageBreak(1,TRUE) THEN PrintColumnHeadings;
 WITH IRec DO
  BEGIN
   PrintAt(CursorX,'  '+ING_Ingredient);
   PrintAt(CursorX+2,ING_Description);
   CASE ING_DefaultProcessType OF
    PTWeight : PrintAt(CursorX+2,'Weighed');
    PTStep   : PrintAt(CursorX+2,'Step   ');
    PTCount  : PrintAt(CursorX+2,'Counted');
   END;
   PrintAt(CursorX+2,DoubleToStr(ING_DefaultLowTol,9,3));
   PrintLnAt(CursorX+2,DoubleToStr(ING_DefaultHighTol,9,3));
  END;
END;


PROCEDURE TingredientReport.RunMacroReport(CopyFilter : TFilter);
BEGIN
 Move(CopyFilter,Filter,SizeOf(Filter));
 GenerateReport;
END;


PROCEDURE TIngredientReport.OutputReport;
VAR IngErr      : INTEGER;
    RecordFound : BOOLEAN;

  FUNCTION InFilter : BOOLEAN;
  BEGIN
   InFilter := TRUE;
   WITH Filter DO
   IF NOT NowtButSpace(IMatch) AND NOT (Str_Equal(IMatch,IRec.ING_Ingredient,Length(IMatch)))
    THEN InFilter := FALSE;
  END;

BEGIN
 RecordFound := FALSE;
 IF (IngredientFile^.OpenFile = 0) THEN
  BEGIN
   IngErr := IngredientFile^.ReadRecord('GF',FALSE,FALSE,IRec,0);
   WHILE (IngErr = 0) DO
    BEGIN
     DispSpin;
     IF InFilter THEN
      BEGIN
       PrintReportBody;
       RecordFound := TRUE;
      END;
     IngErr := IngredientFile^.ReadRecord('GN',FALSE,FALSE,IRec,0);
    END
  END;
 IF IngredientFile^.OpenErr = 0 THEN IngredientFile^.CloseFile;
 IF RecordFound THEN EndReport;
END;

PROCEDURE Print_IngredientList;
BEGIN
 NEW(TheReport,Init);
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,0100,TRUE,FALSE,FALSE);
END;

END.
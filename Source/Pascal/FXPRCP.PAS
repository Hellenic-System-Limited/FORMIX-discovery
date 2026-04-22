(****************************************************************************
*  UNIT          : FXPRCP                                                   *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 17/05/96                                                 *
*  PURPOSE       : Recipe File Report                                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXPRcp;
INTERFACE
USES F6StdCtv,FXModCtv,F6StdUtl,F6StdChr,F6StdUt1,F6StdWn1,F6StdWin,FXFRcp,F6StdRep,
     FXCfg,F6RepSee,FXMenu,FXFWork,FXBRW_RP,FXHelp,FXFMacro;

TYPE TRecipeFilter = PACKED RECORD
      DetailedRep   : BOOLEAN;
      MatchRecipeNo : TRecipeRef;
     END;


TYPE PRecipeReport = ^TRecipeReport;
     TRecipeReport  = OBJECT(TReportObject)

      RHRec       : TRecipeHeaderRecord;
      RLRec       : TRecipeLineRecord;
      RHErr,RLErr : INTEGER;
      Filter      : TRecipeFilter;

      PROCEDURE ReportSetup; Virtual;
      PROCEDURE PrintColumnHeadings; Virtual;
      PROCEDURE PrintSubColumnHeadings;
      PROCEDURE PrintReportBody; Virtual;
      PROCEDURE OutputReport; Virtual;
      FUNCTION  GetSelectionCriteria : BOOLEAN; VIRTUAL;
      PROCEDURE RunMacroReport(CopyFilter : TFilter);VIRTUAL;
     END;

PROCEDURE Print_Recipe_Details;

IMPLEMENTATION

FUNCTION TRecipeReport.GetSelectionCriteria : BOOLEAN;
CONST HeaderTxt = 'Recipe Report';
      EditX     = 25;

VAR CritWin : WindowRecord;
    EditPos : INTEGER;

 PROCEDURE WriteStaticText;
 BEGIN
  BackColourScheme;
  SetWindow(10,5,50,12,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,CritWin);
  Header(HeaderTxt,1);
  Footer('ESC -Exit  F2 -Report  F3 -Save Macro',1);

  HighWriteAt(2,3,'  Recipe No            [        ]');
  WriteAt(2,4,'  Detailed Report      [ ]');
  ForeColourScheme;
 END;

 PROCEDURE WriteInfo;
 BEGIN
  WriteField(EditX,3,Filter.MatchRecipeNo,TRUE);
  WriteTickBox(EditX,4,Filter.DetailedRep);
 END;

 PROCEDURE CheckCh1;
 VAR TempRcpNo    : TRecipeRef;
     FilterBuff   : TFilter;
 BEGIN
  CASE Ch1 OF
   NEXT : IF EditPos<2 THEN Inc(EditPos) ELSE EditPos :=1;
   PREV : IF EditPos>1 THEN Dec(EditPos) ELSE EditPos :=2;
   FN_F1: IF EditPos = 1 THEN
    BEGIN
     TempRcpNo := Filter.MatchRecipeNo;
     BrowseRecipe(TempRcpNo, TRUE{OkToSelectObsolete});
     IF NOT NowtButSpace(TempRcpNo) THEN Filter.MatchRecipeNo := TempRcpNo;
    END;
   FN_F3 :BEGIN
           FillChar(FilterBuff,SizeOf(TFilter),#0);
           Move(Filter,FilterBuff,SizeOf(Filter));
           RepMacroFile^.AddNewRepMacroRecord(RecipeReportTitle,@FilterBuff);
          END;
  END;
 END;

 PROCEDURE InputValue;
 BEGIN
  CASE EditPos OF
   1 : GetLine(Filter.MatchRecipeNo,8,EditX,3);
   2 : GetBoolean(Filter.DetailedRep,EditX,4,tickbox);
  END;
 END;

BEGIN
 WriteStaticText;
 Filter.MatchRecipeNo := SPACE_STRING;
 Filter.DetailedRep   := FALSE;
 EditPos       := 1;
 REPEAT
  WriteInfo;
  InputValue;
  CheckCH1;
 UNTIL (Ch1 = ESC) OR (Ch1=FN_F2);
 LoseWindow(CritWin);
 GetSelectionCriteria := Ch1 <> ESC;
END;


PROCEDURE TRecipeReport.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
 ReportTitle    := 'Recipe Report';
END;

PROCEDURE TRecipeReport.RunMacroReport(CopyFilter : TFilter);
BEGIN
 Move(CopyFilter,Filter,SizeOf(Filter));
 GenerateReport;
END;

PROCEDURE TRecipeReport.PrintColumnHeadings;
BEGIN
 IF NOT Filter.DetailedRep THEN
  BEGIN
   PrintLnAt(CursorX,' Recipe    '+
                     CCondensed+'Description                   '+CNormal+
                     ' Obs. Mix Type     Mix Wt  '+ Config_Rec^.CONF_SglUnitName+
                                                 ' Wt');
   PrintLnAt(CursorX,' --------  '+
                     CCondensed+'------------------------------'+CNormal+
                     ' ---- ---------  --------  --------');
  END;
END;

PROCEDURE TRecipeReport.PrintSubColumnHeadings;
BEGIN
 PrintLnAt(CursorX,'      Ingredient  Key Ingredient    Ratio    Container Size');
 PrintLnAt(CursorX,'      ----------  --------------  ---------  --------------');
END;

PROCEDURE TRecipeReport.PrintReportBody;

   FUNCTION ShowBoolean(bTRUE : BOOLEAN) : STRING;
   VAR S:STRING[3];
   BEGIN
    IF bTRUE THEN S := 'YES' ELSE S:=' NO';
    ShowBoolean := S;
   END;

  PROCEDURE PrintNonDetailedInfo;
  VAR ObsoleteFlag : STRING[4];
  BEGIN
   IF  CheckPageBreak(1,TRUE) THEN PrintColumnHeadings;
   WITH RHRec DO
    BEGIN
     IF RH_Obsolete THEN
       ObsoleteFlag := ' X  '
     ELSE
       ObsoleteFlag := '    ';
     PrintLnAt(CursorX,' '+RH_RecipeNo+
                       '  '+CCondensed+RH_Description+CNormal+
                       ' '+ObsoleteFlag+
                       ' '+GetMixType(RH_DefaultMixType)+
                       DoubleToStr(RH_DefaultMixWt,10,3)+
                       DoubleToStr(RH_StdCaseWt,10,3));
    END;
  END;

  PROCEDURE PrintDetailedInfo;
  VAR I : LONGINT;
  BEGIN
   IF  CheckPageBreak(6,TRUE) THEN PrintColumnHeadings;
   WITH RHRec DO
    BEGIN
     PrintLn;
     PrintAt(CursorX,CHighWrite+'  RecipeNo : '+RH_RecipeNo+'  Description : '+RH_Description+CNormal);
     IF RH_Obsolete THEN
       PrintAt(CursorX, ' (Obsolete)');
     PrintLn;
     PrintLn;
     I:=1;
     PrintSubColumnHeadings;
     REPEAT
      RLErr := RecipeLineFile^.GetRecipeLine(RH_UniqueRef,I,RLRec);
      IF RLErr = 0 THEN
       BEGIN
        IF CheckPageBreak(1,TRUE) THEN PrintColumnHeadings;
        WITH RLRec DO
         BEGIN
          PrintLnAt(CursorX,'        '+RL_Ingredient+
                            '       '+ShowBoolean(RL_DefaultKeyIngred)+
                            '        '+DoubleToStr(RL_DefaultRatio,9,3)+
                            '       '+DoubleToStr(RL_DefaultContSize,9,3));

         END;
        INC(I);
       END;
     UNTIL (RLErr <> 0);
    END;
  END;


BEGIN
 RHRec.RH_Description := RHRec.RH_Description+SPACE_STRING;
 IF Filter.DetailedRep THEN PrintDetailedInfo
 ELSE PrintNonDetailedInfo;
END;

PROCEDURE TRecipeReport.OutputReport;
BEGIN
 IF (RecipeHeaderFile^.OpenFile = 0) AND (RecipeLineFile^.OpenFile = 0) THEN
  BEGIN
   RHErr := RecipeHeaderFile^.ReadRecord('GF',FALSE,FALSE,RHRec,0);
   WHILE (RHErr = 0) AND (NOT StopProcess) DO
    BEGIN
     DispSpin;
     WITH Filter DO
      IF NowtButSpace(MatchRecipeNo) OR Str_Equal(MatchRecipeNo,RHRec.RH_RecipeNo,Length(MatchRecipeNo)) THEN
       PrintReportBody;
     RHErr := RecipeHeaderFile^.ReadRecord('GN',FALSE,FALSE,RHRec,0);
    END
  END;
 IF RecipeHeaderFile^.OpenErr = 0 THEN RecipeHeaderFile^.CloseFile;
 IF RecipeLineFile^.OpenErr = 0 THEN RecipeLineFile^.CloseFile;
 EndReport;
END;

PROCEDURE Print_Recipe_Details;
VAR TheReport : PRecipeReport;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,Init);
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_RecipeReport,TRUE,FALSE,FALSE);
END;


END.

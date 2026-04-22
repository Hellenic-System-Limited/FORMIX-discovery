(****************************************************************************
*  UNIT          : FXPProd                                                  *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 17/05/96                                                 *
*  PURPOSE       : Recipe File Report                                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXPProd;
INTERFACE
USES F6StdCtv,FXModCtv,F6StdUtl,F6StdChr,F6StdUt1,F6StdWn1,F6StdWin,FXFRcp,F6StdRep,
     FXCfg,F6RepSee,FXMenu,FXHelp,FXFProd,FXBrw_PR,FXFMacro;

TYPE TProdFilter = PACKED RECORD
      ProdMatch  : TProductRef;
      ShowDesc   : BOOLEAN;
     END;

TYPE PProductReport = ^TProductReport;
     TProductReport  = OBJECT(TReportObject)

      PLRec      : TProdLineRecord;
      ProdHRec   : TProdHeaderRecord;
      CookDesc   : STRING[40];
      Filter     : TProdFilter;

      CONSTRUCTOR Init;
      PROCEDURE   ReportSetup; Virtual;
      PROCEDURE   PrintColumnHeadings; Virtual;
      PROCEDURE   PrintSubColumnHeadings(Again : BOOLEAN);
      PROCEDURE   PrintReportBody; Virtual;
      PROCEDURE   OutputReport; Virtual;
      PROCEDURE   OpenFiles;
      PROCEDURE   CloseFiles;
      PROCEDURE   ShowDescriptions;
      FUNCTION    GetSelectionCriteria : BOOLEAN; VIRTUAL;
      FUNCTION    InCriteria  : BOOLEAN;
      PROCEDURE   RunMacroReport(CopyFilter : TFilter);VIRTUAL;
     END;

PROCEDURE Print_Product_Report;

IMPLEMENTATION

CONSTRUCTOR TProductReport.Init;
BEGIN
 INHERITED Init;
END;

FUNCTION TProductReport.GetSelectionCriteria : BOOLEAN;
CONST EditX = 26;
VAR CritWin    : WindowRecord;
    EditPos    : INTEGER;
    FilterBuff : TFilter;
BEGIN
 BackColourScheme;
 SetWindow(15,08,60,15,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,CritWin);
 Header('Product Report',1);
 Footer('F2 - Report  ESC - Exit  F3 - Save Macro',1);
 HighWriteAt(2,3,'   Products Matching    [          ]');
 WriteAt(2,4,'   Show Cooking Methods [ ]');
 ForeColourScheme;
 Filter.ProdMatch := SPACE_STRING;
 Filter.ShowDesc  := FALSE;
 EditPos   := 0;
 REPEAT
  WriteField(EditX,3,Filter.ProdMatch,TRUE);
  WriteTickBox(EditX,4,Filter.ShowDesc);
  CASE EditPos OF
   0 : GetLine(Filter.ProdMatch,10,EditX,3);
   1 : GetBoolean(Filter.ShowDesc,EditX,4,TickBox);
  END;
  CASE Ch1 OF
   NEXT,PREV : EditPos := 1-EditPos;
   FN_F1     : BrowseProduct(Filter.ProdMatch);
   FN_F3     : BEGIN
                FillChar(FilterBuff,SizeOf(TFilter),#0);
                Move(Filter,FilterBuff,SizeOf(Filter));
                RepMacroFile^.AddNewRepMacroRecord(ProdReportTitle,@FilterBuff);
               END;
  END;
 UNTIL (Ch1 = ESC) OR (Ch1 = FN_F2);
 LoseWindow(CritWin);
 GetSelectionCriteria := Ch1 <> ESC;
END;

FUNCTION TProductReport.InCriteria : BOOLEAN;
BEGIN
 WITH Filter DO
  InCriteria := (NowtButSpace(ProdMatch)) OR (Str_Equal(ProdMatch,ProdHRec.PH_ProductCode,Length(ProdMatch)));
END;

PROCEDURE TProductReport.RunMacroReport(CopyFilter : TFilter);
BEGIN
 Move(CopyFilter,Filter,SizeOf(Filter));
 GenerateReport;
END;

PROCEDURE TProductReport.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
 ReportTitle    := 'Product Report';
END;

PROCEDURE TProductReport.PrintColumnHeadings;
BEGIN
 PrintLnAt(CursorX,' Line Code    Line Type  Description                          Ratio');
 PrintLnAt(CursorX,' -----------  ---------  ------------------------------   ---------');
END;


PROCEDURE TProductReport.PrintReportBody;
VAR ReadLErr : INTEGEr;
BEGIN
 CheckPageBreak(4,TRUE);
 PrintLn;
 PrintLnAt(CursorX,' Product :'+ProdHRec.PH_ProductCode+'  Desc : '+ProdHRec.PH_Description);
 PrintColumnHeadings;
 FillChar(PLRec,SizeOf(TProdLineRecord),#0);
 PLRec.PL_ProductCode := ProdHRec.PH_ProductCode;
 ReadLErr := ProdLineFile^.ReadRecord('GE',FALSE,FALSE,PLRec,0);
 WHILE (ReadLErr =0) AND (PLRec.PL_ProductCode = ProdHRec.PH_ProductCode) DO
  BEGIN
   IF CheckPageBreak(1,TRUE) THEN PrintColumnHeadings;
   IF NowtButSpace(PLRec.PL_RecipeNo) THEN
    PrintLnAt(CursorX,'  '+PLRec.PL_SubProduct+
                      '  Product  '+
                      '  '+GetProductName(PLRec.PL_SubProduct)+
                      '   '+DoubleToStr(PLRec.PL_Ratio,9,3))

   ELSE
    PrintLnAt(CursorX,'  '+PLRec.PL_RecipeNo+
                    '    Recipe   '+
                      '  '+GetRecipeName(PLRec.PL_RecipeNo)+
                      '   '+DoubleToStr(PLRec.PL_Ratio,9,3));
   ReadLErr := ProdLineFile^.ReadRecord('GN',FALSE,FALSE,PLRec,0);
  END;
END;

PROCEDURE TProductReport.OpenFiles;
BEGIN
 RecipeHeaderFile^.OpenFile;
 ProdDescFile^.OpenFile;
 ProdLineFile^.OpenFile;
 ProdHeaderFile^.OpenFile;
END;

PROCEDURE TProductReport.CloseFiles;
BEGIN
 ProdHeaderFile^.CloseFile;
 ProdLineFile^.Closefile;
 ProdDescFile^.CloseFile;
 RecipeHeaderFile^.CloseFile;
END;

PROCEDURE TProductReport.PrintSubColumnHeadings(Again : BOOLEAN);
BEGIN
 PrintLn;
 PrintAt(CursorX,'Cooking Method :- '+CookDesc);
 IF Again THEN PrintAt(CursorX,' (Continued)');
 PrintLn;
END;

PROCEDURE TProductReport.ShowDescriptions;
VAR ProdDesc : TProdDescription;
    ReadErr  : INTEGER;
BEGIN
 FillChar(ProdDesc,SizeOf(ProdDesc),#0);
 ProdDesc.PD_ProductCode := ProdHRec.PH_ProductCode;
 ProdDesc.PD_Method      := 0;
 ProdDesc.PD_LineNo      := 0;
 ReadErr := ProdDescFile^.ReadRecord('GE',FALSE,FALSE,ProdDesc,0);
 WHILE (ReadErr = 0) AND (ProdDesc.PD_ProductCode = ProdHRec.PH_ProductCode) DO
  BEGIN
   IF CheckPageBreak(1,TRUE) THEN PrintSubColumnHeadings(TRUE);
   IF ProdDesc.PD_LineNo = 0 THEN
    BEGIN
     CookDesc := ProdDesc.PD_Description;
     CheckPageBreak(4,TRUE);
     PrintSubColumnHeadings(FALSE);
    END
   ELSE
    BEGIN
     CookDesc := SPACE_STRING;
     PrintLnAt(CursorX,'    '+ProdDesc.PD_Description);
    END;
   ReadErr := ProdDescFile^.ReadRecord('GN',FALSE,FALSE,ProdDesc,0);
  END;
END;


PROCEDURE TProductReport.OutputReport;
VAR ReadHErr : INTEGER;
    ProdPos  : LONGINT;
BEGIN
 OpenFiles;
 {Reads Each Header File For Recipe}
 FillChar(ProdHRec,SizeOf(TProdHeaderRecord),#0);
 ProdHRec.PH_ProductCode := SPACE_STRING;
 ReadHErr := ProdHeaderFile^.ReadRecord('GE',FALSE,FALSE,ProdHRec,0);
 WHILE (ReadHErr = 0) AND (NOT StopProcess) DO
  BEGIN
   DispSpin;
   IF InCriteria THEN
    BEGIN
     ProdPos := ProdHeaderFile^.Position;
     PrintReportBody;
     IF Filter.ShowDesc THEN ShowDescriptions;
     ProdHeaderFile^.GetRecordDirect(ProdPos,FALSE,FALSE,ProdHRec,0);
    END;
   ReadHErr := ProdHeaderFile^.ReadRecord('GN',FALSE,FALSE,ProdHRec,0);
  END;
 CloseFiles;
 EndReport;
END;

PROCEDURE Print_Product_Report;
VAR TheReport : PProductReport;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,Init);
 TheReport^.RunNEwReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_ProductReport,TRUE,FALSE,FALSE);
END;


END.
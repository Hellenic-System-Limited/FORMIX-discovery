(****************************************************************************
*  UNIT          : FXPCook                                                  *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 17/05/96                                                 *
*  PURPOSE       : Recipe File Report                                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXPCook;
INTERFACE
USES F6StdCtv,FXModCtv,F6StdUtl,F6StdChr,F6StdUt1,F6StdWn1,F6StdWin,FXFRcp,F6StdRep,
     FXCfg,F6RepSee,FXMenu,FXHelp,FXFProd,FXFWork,FXFIngr;

TYPE PCookingReport = ^TCookingReport;
     TCookingReport  = OBJECT(TReportObject)

      ProdOrdRec : TProdOrderRecord;
      WHRec      : TWOHeaderRecord;
      CookDesc   : STRING[40];

      CONSTRUCTOR Init(VAR ProdOrder : TProdOrderRecord);
      PROCEDURE ReportSetup; Virtual;
      PROCEDURE PrintColumnHeadings; Virtual;
      PROCEDURE PrintSubColumnHeadings(Again : BOOLEAN);
      PROCEDURE PrintReportBody; Virtual;
      PROCEDURE OutputReport; Virtual;
      PROCEDURE OpenFiles;
      PROCEDURE CloseFiles;
      PROCEDURE ShowDescriptions;
     END;

PROCEDURE Print_Cooking_Report(VAR ProdOrder : TProdOrderRecord);

IMPLEMENTATION


CONSTRUCTOR TCookingReport.Init(VAR ProdOrder : TProdOrderRecord);
BEGIN
 ProdOrdRec := ProdOrder;
 INHERITED Init;
END;

PROCEDURE TCookingReport.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
 ReportTitle    := 'Cooking Details';
END;

PROCEDURE TCookingReport.PrintColumnHeadings;
BEGIN
 PrintLnAt(CursorX,' Ingredient  Description                        Wt Req.    Wt Done');
 PrintLnAt(CursorX,' ----------  ------------------------------   ---------  ---------');
END;

PROCEDURE TCookingReport.PrintReportBody;
VAR ReadLErr : INTEGEr;
    WLRec    : TWOLineRecord;
BEGIN
 CheckPageBreak(5,TRUE);
 PrintLn;
 WITH WHRec DO
  PrintLnAt(CursorX,'Order : '+OrderNoToStr(WOH_OrderNo,WOH_Revision)+
           '   Recipe : '+WOH_RecipeNo+'   Desc : '+GetRecipeName(WOH_RecipeNo));
 PrintColumnHeadings;
 FillChar(WLRec,SizeOf(WLRec),#0);
 WLRec.WOL_OrderNo  := WHRec.WOH_OrderNo;
 WLRec.WOL_Revision := WHRec.WOH_Revision;
 WLRec.WOL_LineNo   := 0;
 ReadLErr := WorkLineFile^.ReadRecord('GE',FALSE,FALSE,WLRec,0);
 WHILE (ReadLErr =0) AND (WLRec.WOL_OrderNo = WHRec.WOH_OrderNo) AND
  (WLRec.WOL_Revision = WHRec.WOH_Revision) DO
  BEGIN
   IF CheckPageBreak(1,TRUE) THEN PrintColumnHeadings;
   PrintLnAt(CursorX,'   '+WLRec.WOL_Ingredient+
                     '  '+GetIngredientDesc(WLRec.WOL_Ingredient)+
                     '   '+DoubleToStr(CalcLineGrossWtReqdFromRecipeNet(
                                                     WHRec.WOH_FinishWtReqd,
                                                     WLRec.WOL_Ratio,
                                                     WLRec.WOL_Yield),9,3)+
                     '  '+DoubletoStr(WLRec.WOL_TotalWtDone,9,3));
   ReadLErr := WorkLineFile^.ReadRecord('GN',FALSE,FALSE,WLRec,0);
  END;
END;

PROCEDURE TCookingReport.OpenFiles;
BEGIN
 IngredientFile^.OpenFile;
 WorkHeaderFile^.OpenFile;
 WorkLineFile^.OpenFile;
 ProdDescFile^.OpenFile;
 ProdHeaderFile^.OpenFile;
END;

PROCEDURE TCookingReport.CloseFiles;
BEGIN
 ProdHeaderFile^.CloseFile;
 ProdDescFile^.CloseFile;
 WorkLineFile^.CloseFile;
 WorkHeaderFile^.CloseFile;
 IngredientFile^.CloseFile;
END;

PROCEDURE TCookingReport.PrintSubColumnHeadings(Again : BOOLEAN);
BEGIN
 PrintLn;
 PrintAt(CursorX,'Cooking Method :- '+CookDesc);
 IF Again THEN PrintAt(CursorX,' (Continued)');
 PrintLn;
END;

PROCEDURE TCookingReport.ShowDescriptions;
VAR ProdDesc : TProdDescription;
    ReadErr  : INTEGER;
BEGIN
 FillChar(ProdDesc,SizeOf(ProdDesc),#0);
 ProdDesc.PD_ProductCode := ProdOrdRec.PO_ProductCode;
 ProdDesc.PD_Method      := ProdOrdRec.PO_Method;
 ProdDesc.PD_LineNo      := 0;
 ReadErr := ProdDescFile^.ReadRecord('GE',FALSE,FALSE,ProdDesc,0);
 IF (ReadErr = 0) AND (ProdDesc.PD_Method = ProdOrdRec.PO_Method)
  AND (PRodDesc.PD_ProductCode = ProdOrdRec.PO_ProductCode) THEN
  BEGIN
   IF ProdDesc.PD_LineNo = 0 THEN
    CookDesc := ProdDesc.PD_Description
   ELSE
    BEGIN
     CookDesc := SPACE_STRING;
     PrintLnAt(CursorX,'    '+ProdDesc.PD_Description);
    END;
   CheckPageBreak(4,TRUE);
   PrintSubColumnHeadings(FALSE);

   ReadErr := ProdDescFile^.ReadRecord('GN',FALSE,FALSE,ProdDesc,0);
   WHILE (ReadErr = 0) AND (ProdDesc.PD_Method = ProdOrdRec.PO_Method)
    AND (ProdDesc.PD_ProductCode = ProdOrdRec.PO_ProductCode) DO
    BEGIN
     IF CheckPageBreak(1,TRUE) THEN PrintSubColumnHeadings(TRUE);
     PrintLnAt(CursorX,'    '+ProdDesc.PD_Description);
     ReadErr := ProdDescFile^.ReadRecord('GN',FALSE,FALSE,ProdDesc,0);
    END;
  END;
 ProdDescFile^.CloseFile;
END;

PROCEDURE TCookingReport.OutputReport;
VAR ReadHErr : INTEGER;
BEGIN
 OpenFiles;
 {Reads Each Header File For Recipe}
 FillChar(WHRec,SizeOf(TWOHeaderRecord),#0);
 WHRec.WOH_OrderNo := ProdOrdRec.PO_OrderNo;
 WHRec.WOH_Revision:= 0;
 ReadHErr := WorkHeaderFile^.ReadRecord('GE',FALSE,FALSE,WHRec,1);
 WHILE (ReadHErr = 0) AND (WHRec.WOH_OrderNo = ProdOrdRec.PO_OrderNo) AND
       (NOT StopProcess) DO
  BEGIN
   DispSpin;
   PrintReportBody;
   ReadHErr := WorkHeaderFile^.ReadRecord('GN',FALSE,FALSE,WHRec,1);
  END;
 ShowDescriptions;
 CloseFiles;
 EndReport;
END;

PROCEDURE Print_Cooking_Report(VAR ProdOrder : TProdOrderRecord);
VAR TheReport : PCookingReport;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,Init(ProdOrder));
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_CookingReport,TRUE,FALSE,FALSE);
END;


END.
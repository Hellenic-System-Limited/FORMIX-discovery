(****************************************************************************
*  UNIT          : FXPPCost                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 20/09/96                                                 *
*  PURPOSE       : Product Costing Report                                   *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXPPCost;
INTERFACE
USES F6StdCtv,FXModCtv,F6StdUtl,F6StdChr,F6StdUt1,F6StdWn1,F6StdWin,FXFRcp,F6StdRep,
     FXCfg,F6RepSee,FXMenu,FXHelp,FXFProd,FXFWork,FXFIngr,FXTRNQRY,FXFCost,
     FXCalCst;

TYPE PProdCostReport = ^TProdCostReport;
     TProdCostReport = OBJECT(TReportObject)
      ProdOrdRec   : TProdOrderRecord;
      WHRec        : TWOHeaderRecord;
      WLRec        : TWOLineRecord;
      TrnQueryView : PTranList;
      TrnQuery     : PTrnQuery;

      CONSTRUCTOR Init(VAR ProdOrder : TProdOrderRecord);
      PROCEDURE   ReportSetup; Virtual;
      PROCEDURE   PrintColumnHeadings; Virtual;
      PROCEDURE   PrintReportBody; Virtual;
      PROCEDURE   OutputReport; Virtual;
      PROCEDURE   OpenFiles;
      PROCEDURE   CloseFiles;
     END;

PROCEDURE Print_Product_Costing_Report(VAR ProdOrder : TProdOrderRecord);

IMPLEMENTATION


CONSTRUCTOR TProdCostReport.Init(VAR ProdOrder : TProdOrderRecord);
BEGIN
 ProdOrdRec := ProdOrder;
 INHERITED Init;
END;

PROCEDURE TProdCostReport.ReportSetup;
VAR CopyRightInfo :STRING;
BEGIN
 CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
 ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
 ReportTitle    := 'Product Costing';
END;

PROCEDURE TProdCostReport.PrintColumnHeadings;
BEGIN
 PrintLnAt(CursorX,CCondensed+'                                      Content Proc       Pk''d  Yield'+
                   '     Proc.             Est.     FINAL  '+CNormal);
 PrintLnAt(CursorX,CCondensed+'Ingredient  Description                  %    Loss%        Wt    %  '+
                   '      Wt    Wt Done    p/'+StrRangeCode(Config_Rec^.Conf_DefaultWtRange)+'     COST   '+CNormal);
 PrintLnAt(CursorX,CCondensed+'----------  ------------------------- ------- ----- --------- ------'+
                   ' --------- -------- -------- --------- '+CNormal);
END;

PROCEDURE TProdCostReport.PrintReportBody;
VAR ReadLErr     : INTEGER;
    NetWt        : DOUBLE;
    GrossWt      : DOUBLE;
    WtDiff       : DOUBLE;
    PriceLB      : DOUBLE;
    LinePrice    : DOUBLE;
    RcpHead      : TRecipeHeaderRecord;
    Filter       : TTransFilter;
    TempWt       : DOUBLE;


BEGIN
 CheckPageBreak(5,TRUE);

 FXTRNQRY.InitFilter(Filter);
 Filter.KeyNum         := 2;
 Filter.MinWorkNo      := WHRec.WOH_OrderNo;
 Filter.MaxWorkNo      := WHRec.WOH_OrderNo;
 Filter.sMinorWO       := IntToZeroStr(WHRec.WOH_Revision,2);
 Filter.IncludeActive  := TRUE;
 Filter.IncludeAborted := FALSE;

 TrnQuery^.SetFilter(Filter);               { Prime Query Record Filter    }
 TrnQuery^.Run;                             { Execute Query                }

 PrintLn;
 WITH WHRec DO
  PrintLnAt(CursorX,'Order :'+OrderNoToStr(WOH_OrderNo,WOH_Revision)+
            '  Recipe : '+WOH_RecipeNo+'   Desc : '+GetRecipeName(WOH_RecipeNo));
 PrintColumnHeadings;
 FillChar(WLRec,SizeOf(WLRec),#0);
 WLRec.WOL_OrderNo  := WHRec.WOH_OrderNo;
 WLRec.WOL_Revision := WHRec.WOH_Revision;
 WLRec.WOL_LineNo   := 0;
 ReadLErr := WorkLineFile^.ReadRecord('GE',FALSE,FALSE,WLRec,0);
 WHILE (ReadLErr =0) AND (WLRec.WOL_OrderNo = WHRec.WOH_OrderNo) AND
  (WLRec.WOL_Revision = WHRec.WOH_Revision) DO
  BEGIN
   NetWt   := CalcLineGrossWtReqdFromRecipeNet(WHRec.WOH_FinishWtReqd,
                                               WLRec.WOL_Ratio,
                                               100); { ie with no loss adjustment }
   GrossWt := CalcLineGrossWtReqdFromRecipeNet(WHRec.WOH_FinishWtReqd,
                                               WLRec.WOL_Ratio,
                                               WLRec.WOL_Yield);
   CalcWeightDoneAndPrices(WLRec.WOL_Ingredient, WLRec.WOL_LineNo,
                           TempWt,LinePrice,PriceLB,TrnQueryView);
   IF CheckPageBreak(1,TRUE) THEN PrintColumnHeadings;
   PrintLnAt(CursorX,CCondensed+
    {Ingredient}     '  '+WLRec.WOL_Ingredient+
    {Description}    '  '+COPY(GetIngredientDesc(WLRec.WOL_Ingredient),1,25)+
    {Ratio}          ' '+DoubleToStr(WLRec.WOL_Ratio,6,2)+
    {Proc Loss %}    '       '+
    {Net Weight}     ' '+DoubleToStr(NetWt,9,3)+
    {Yield %}        ' '+DoubleToStr(WLRec.WOL_Yield,6,2)+
    {Gross Wt}       ' '+DoubleToStr(Grosswt,9,3)+
    {Wt Done}        ' '+DoubleToStr(WLRec.WOL_TotalWtDone,8,3)+
    {Price Per lb}   ' '+DoubleToStr(PriceLB,8,3)+
    {Total Price}    ' '+DoubleToStr(LinePrice,9,3)+
                     CNormal);
   ReadLErr := WorkLineFile^.ReadRecord('GN',FALSE,FALSE,WLRec,0);
  END;
 IF RecipeHeaderFile^.ReadRecipeHeader(RcpHead,WHRec.WOH_RecipeNo) = 0 THEN
  BEGIN
   WITH WHRec,RcpHead DO
    BEGIN
     PrintAt(CursorX,CCondensed);
     WtDiff := (WOH_FinishWtReqd*(RH_ProcLossAfterMixing/100));
     IF (WtDiff <> 0.0) THEN WtDiff := -WtDiff;
     PrintLnAt(48,DoubleToStr(RH_ProcLossAfterMixing,5,2)+
                 ' '+DoubleToStr(WtDiff,9,3)+CNormal);
    END;
  END;
 TrnQueryView^.DisposeList;                 { Clear Previous Query Results }
END;

PROCEDURE TProdCostReport.OpenFiles;
BEGIN
 IngredientFile^.OpenFile;
 WorkHeaderFile^.OpenFile;
 WorkLineFile^.OpenFile;
 ProdHeaderFile^.OpenFile;
 RecipeHeaderFile^.OpenFile;
 CostFile^.OpenFile;
END;

PROCEDURE TProdCostReport.CloseFiles;
BEGIN
 CostFile^.CloseFile;
 RecipeHeaderFile^.CloseFile;
 ProdHeaderFile^.CloseFile;
 WorkLineFile^.CloseFile;
 WorkHeaderFile^.CloseFile;
 IngredientFile^.CloseFile;
END;


PROCEDURE TProdCostReport.OutputReport;
VAR ReadHErr : INTEGER;
BEGIN
 OpenFiles;

 { Create Object Instances For Transaction Query                           }
 TrnQueryView := New(PTranList,Init(ST_ByIngredient));{Results In Key Order }
 TrnQuery     := New(PTrnQuery,Init(TrnQueryView));


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

 Dispose(TrnQuery,Done);
 Dispose(TrnQueryView,Done);

 CloseFiles;
 EndReport;
END;

PROCEDURE Print_Product_Costing_Report(VAR ProdOrder : TProdOrderRecord);
VAR TheReport : PProdCostReport;
    RepName   : STRING[80];
BEGIN
 NEW(TheReport,Init(ProdOrder));
 TheReport^.RunNewReport;
 RepName := TheReport^.GetReportFileName;
 DISPOSE(TheReport,Done);
 Show_Report(RepName,cm_CookingReport,TRUE,FALSE,FALSE);
END;


END.

(****************************************************************************
*  UNIT          : SFX_Bars                                                 *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix bars window                                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFX_Bars;
INTERFACE
USES F6StdUtl,FXFIngr,SFXStd,SFXGraph,SFXBtn,SFXFont,SFXWin,SFXComms,
     SFXMsg,FXCfg,FXFWork,FXModCtv;

CONST
{Main percentage bar}
     Bar1_X1 = 500;
     Bar1_X2 = Bar1_X1+100;
     Bar1_X3 = Bar1_X1+60;
     Bar1_Y1 = 050;  {001}
     Bar1_Y2 = 299;  {301}
{Shadow Percentage Bar}
     Bar2_X1 = Bar1_X1-20;
     Bar2_X2 = Bar1_X2-20;
     Bar2_X3 = Bar1_X3-20;
     Bar2_Y1 = Bar1_Y1+07;
     Bar2_Y2 = Bar1_Y2+07;
     BARBACKCOL = $0F;
     LINETHICK  = 2;

(*     HiTolY  = Bar1_Y1+20; *)
(*     HiTolX  = Bar1_X1+20 DIV ((Bar1_y2-Bar1_Y1) DIV (Bar1_X3-Bar1_X1));*)
(*     LoTolY  = Bar1_Y1+100;*)
(*     LoTolX  = Bar1_X1+ 100 DIV ((Bar1_y2-Bar1_Y1) DIV (Bar1_X3-Bar1_X1));*)


TYPE TFillingBarAttributes = PACKED RECORD
       HiTolWt,                      {highest weight in tolerance}
       LoTolWT         : DOUBLE;     {lowest weight in tolerance}
       IgnoreLowTolerance : BOOLEAN;
       MaxBarWeight    : DOUBLE;     {Top of bar Weight}
       HiTolX,
       HiTolY,
       LoTolY,
       LoTolX,
       TargetY         : LONGINT;
       LowerBarRatio   : DOUBLE;     {weight scaling below low tolerance}
       MiddleBarRatio  : DOUBLE;     {weight scaling in tolerance}
       UpperBarRatio   : DOUBLE;     {weight scaling above tolerance}
       NoToleranceBars : BOOLEAN;
       ContainerWt     : DOUBLE;
       AmountReq       : DOUBLE;
    END;


TYPE
      PBarsWindow = ^TBarsWindow;
      TBarsWindow = OBJECT(TButtonWindow)
        OrderComplete   : INTEGER;
      PRIVATE
        TWt,WtD         : DOUBLE;
        MainBarAttr     : TFillingBarAttributes;
        LastTotalBarPos,
        LastNewWtBarPos : LONGINT;
        OutlinePending  : BOOLEAN;
        ProcessType     : TProcessTypes;
        TareWt          : DOUBLE;
        DrawBarsEnabled : BOOLEAN;
        BarsDrawn       : BOOLEAN;
        FixedWt         : DOUBLE;
      PUBLIC
       CONSTRUCTOR Init(X1,Y1,X2,Y2 : INTEGER);
       DESTRUCTOR  Done;VIRTUAL;
       PROCEDURE Draw; VIRTUAL;
       PROCEDURE DropLowTolerance;
       PROCEDURE RestoreLowTolerance;
       FUNCTION  LowTolHasBeenDisabled : BOOLEAN;
       FUNCTION  UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
       PROCEDURE ResetMainBarForIngred(TargetWt,
                                       LowestWt,
                                       HighestWt      : DOUBLE;
                                       AWOrderLine    : PWOLineRecord;
                                       RelatedIngRec  : PIngredient_Record);
       PROCEDURE ResetMainBarToDefault;
       PROCEDURE ResetTotBar(TotalWtReqd, TotalWtDone : DOUBLE);
       PROCEDURE ShowWeightIfValid(NetScaleWt : DOUBLE;
                                   ScaleError : INTEGER;
                                   DisplayMsg : BOOLEAN);
       PROCEDURE ReceiveMsg(Msg : INTEGER);VIRTUAL;
       PROCEDURE ClearMainBar;
       (*PROCEDURE ShowNewBarTotals;*)
       PROCEDURE EnableDraw(DrawState : BOOLEAN);
       FUNCTION  IsDrawingEnabled : BOOLEAN;
       FUNCTION  GetHiTolWeight : DOUBLE;
       FUNCTION  GetLoTolWeight : DOUBLE;
       FUNCTION  GetTargetWeight : DOUBLE;

      PRIVATE
       PROCEDURE DrawBarsAndText(WriteText,NoHightolerance: BOOLEAN);
       PROCEDURE DrawBarOutlines(NoHightolerance : BOOLEAN);
       PROCEDURE ResetMainBarAttr(HighTolWt,
                                  LowTolWt,
                                  ContainerWt,
                                  AmountRequired : DOUBLE);
       FUNCTION  ConvertWtToMainBarPixels(AWt : DOUBLE) : LONGINT;
       PROCEDURE FillMainBarFromTo(From_, TO_ : INTEGER;CLEAR : BOOLEAN);
       PROCEDURE FillTotalBarFromTo(From_, To_ : INTEGER; Col : BYTE);
       PROCEDURE ShowGraphicalTotals(NetScaleWt : DOUBLE;
                                     ShowScaleWt: BOOLEAN);
      END;
(*
      PDisplayRequiredWt = ^TDisplayRequiredWt;
      TDisplayRequiredWt = OBJECT(TSFWindow)
       CONSTRUCTOR Init;
       PROCEDURE ShowRequiredWtAndProcessType(MinWt,MaxWt : DOUBLE;ProcessType : TProcessTypes);
      END;
*)

CONST
    BarsWindow : PBarsWindow = NIL;


IMPLEMENTATION
USES F6StdWn1,SFXTrans,SFXScale,SFX_MAIN,SFXCURR,SFX_SCRL,SFXCOLR;
(*
VAR DisplayRequiredWt : PDisplayRequiredWt;

CONSTRUCTOR TDisplayRequiredWt.Init;
BEGIN
 INHERITED Init(8,32*8,17+30*8,34*8+3*8+7,WT_VISABLE,NIL,TRUE);
END;

PROCEDURE TDisplayRequiredWt.ShowRequiredWtAndProcessType(MinWt,MaxWt : DOUBLE;ProcessType : TProcessTypes);
VAR HoldFont : PFontType;
BEGIN
 HoldFont := SetCurrentFont(RecipeNormalFont);
 WriteStrAt(1,32,'Process         :- '+GetProcessTypeName(ProcessType));
 WriteStrAt(1,34,'Max Wt Required :- '+DoubleToStr(MaxWt,9,3)+'kg');
 WriteStrAt(1,36,'Min Wt Required :- '+DoubleToStr(MinWt,9,3)+'kg');
 SetCurrentFont(HoldFont);
END;
*)
{TBarsWindow Methods}
CONSTRUCTOR TBarsWindow.Init(X1,Y1,X2,Y2 : INTEGER);
BEGIN
{$IFDEF DEBUGBARS}
 Disp_Error_Msg('TBarsWindow.Init ENTRY');
{$ENDIF}
(* New(DisplayRequiredWt,Init);*)
 DrawBarsEnabled := TRUE;
 TWt := 0.0;
 WtD := 0.0;
 ResetMainBarAttr(0.0, 0.0, 0.0, 999.999);
 LastTotalBarPos := BAR2_Y2;
 LastNewWtBarPos := BAR1_Y2;
 OutlinePending  := TRUE;
 OrderComplete   := 0;
 FillCHar(MainBarAttr,SizeOF(MainBarAttr),#0);
 BarsDrawn       := FALSE;
{ COLOURS YET TO BE COMPLETED }

{$IFDEF DEBUGBARS}
 Disp_Error_Msg('TBarsWindow.Init call inherited');
{$ENDIF}
 INHERITED Init(X1,Y1,X2,Y2,BackGround,WT_VISABLE);
END;

DESTRUCTOR TBarsWindow.Done;
BEGIN
 INHERITED Done;
 BarsWindow := NIL;
END;

PROCEDURE TBarsWindow.DropLowTolerance;
BEGIN
 MainBarAttr.IgnoreLowTolerance := TRUE;
END;

PROCEDURE TBarsWindow.RestoreLowTolerance;
BEGIN
 MainBarAttr.IgnoreLowTolerance := FALSE;
END;

FUNCTION TBarsWindow.LowTolHasBeenDisabled : BOOLEAN;
BEGIN
 LowTolHasBeenDisabled := MainBarAttr.IgnoreLowTolerance;
END;



FUNCTION  TBarsWindow.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR GrossWt, NetWt : DOUBLE;
BEGIN
 IF NoIngredientSelected THEN
  BEGIN
   MessageWin.DisplayMsg('Select An Ingredient First',TRUE);
   UserActivateFunction := FALSE;
   EXIT;
  END;
 IF ProcessType = PTStep THEN { actual weight is 0 }
   CreateTransaction(0.0,{FALSE,}ProcessType,FALSE)

 ELSE IF (ProcessType = PTCount) THEN { assume user has weighed it off elsewhere }
  BEGIN
   CreateTransaction(FixedWt,{FALSE,}PTCount, FALSE)
  END

 ELSE
  BEGIN
   IF ScaleWindow^.WaitForScaleWt(GrossWt, NetWt) = No_Scale_Error THEN
    BEGIN
     IF WeightOkForTran(NetWt, ProcessType,
                        MainBarAttr.LoTolWt,
                        MainBarAttr.HiTolWt,
                        MainBarAttr.IgnoreLowTolerance) THEN
      BEGIN
       CreateTransaction(NetWt,{FALSE,}ProcessType,FALSE);
       ScrollerWindows^.WriteScrollerText(DisplayRecListPos);
      END;
    END;
  END;
 UserActivateFunction := OrderComplete<>0;
END;

PROCEDURE TBarsWindow.ReceiveMsg(Msg : INTEGER);
BEGIN
 OrderComplete := Msg;
END;

PROCEDURE TBarsWindow.DrawBarOutlines(NoHightolerance : BOOLEAN);
BEGIN
{Draw the main bar}
   DrawlineHoriz (Bar1_X1,Bar1_X2,Bar1_Y1,1);
   DrawLineHoriz (Bar1_X1,Bar1_X2,Bar1_Y1+1,1);
   DrawlineHoriz (Bar1_X3,Bar1_X2,Bar1_Y2,1);
   DrawLineHoriz (Bar1_X3,BAr1_X2,Bar1_Y2-1,1);
   DrawlineVert (Bar1_X2,Bar1_Y1,Bar1_Y2,1);
   DrawlineVert (Bar1_X2-1,Bar1_Y1,Bar1_Y2,1);

   DrawLine (Bar1_X1,Bar1_Y1,Bar1_X3,Bar1_Y2);
   DrawLine (Bar1_X1+1,Bar1_Y1,Bar1_X3+1,Bar1_Y2);

   WITH MainBarAttr DO
    BEGIN
(*
     {Draw Tolerance Bars}
     IF NOT NoHightolerance THEN
*)
      BEGIN
       DrawLineHoriz(HiTolX,Bar1_X2,HiTolY,1);
       DrawLineHoriz(HiTolX,Bar1_X2,HiTolY+1,1);
      END;
     DrawLineHoriz(LoTolX, Bar1_X2, LoTolY, 1);
     DrawLineHoriz(LoTolX, Bar1_X2, LoTolY+1, 1);

     { draw target }
     DrawLineHoriz((Bar1_X2 -40), Bar1_X2-15, TargetY, 1);
    END;


{Draw the shadow Bar}
   DrawlineHORIZ (Bar2_X1,Bar2_X1+22,Bar2_Y1,1);
   DrawlineHORIZ (Bar2_X1,Bar2_X1+22,Bar2_Y1+1,1);
   DrawlineHORIZ (Bar2_X3,Bar2_X2,Bar2_Y2,1);
   DrawlineHORIZ (Bar2_X3,Bar2_X2,Bar2_Y2-1,1);

   DrawlineVERT (Bar2_X2,Bar1_Y2,Bar2_Y2,1);
   DrawlineVERT (Bar2_X2-1,Bar1_Y2,Bar2_Y2,1);

   Drawline (Bar2_X1,Bar2_Y1,Bar2_X3,Bar2_Y2);
   DrawLine (Bar2_X1+1,Bar2_Y1,Bar2_X3+1,Bar2_Y2);

   OutlinePending := FALSE;
END;

PROCEDURE TBarsWindow.DrawBarsAndText(WriteText,NoHightolerance: BOOLEAN);
VAR OldFont,Newfont : PFontType;
    SaveCol : BYTE;
BEGIN
 FillMainBarFromTo(Bar1_Y2,Bar1_Y1,TRUE);
 FillTotalBarFromTo(Bar2_Y2,Bar2_Y1,BARBACKCOL);

 DrawBarOutlines(NoHighTolerance);

{Write Infomation text}
 IF WriteText THEN
  BEGIN
   NewFont  := CopyFont(Font8x16);
   SaveCol  := SetTextColour(BackColour SHL 4);
{   NewFont^.TextDirection := VERT;}
   NewFont^.FontStyle := NewFont^.FontStyle OR Vert;
   OldFont  := SetCurrentFont(NewFont);
   WriteStrAt(76,08,'Ingredient Wt.');
   DeleteFont(NewFont);
   NewFont  := CopyFont(Font8x8);
{   NewFont^.TextDirection := VERT;}
   NewFont^.FontStyle := NewFont^.FontStyle OR Vert;
   SetCurrentFont(NewFont);
   WriteStrAt(61,18,'Current Mix Wt.');
   SetTextColour(SaveCol);
   DeleteFont(NewFont);
   SetCurrentFont(OldFont);
  END;
END;

PROCEDURE TBarsWindow.Draw;
BEGIN
 DrawBarsAndText(TRUE,CompareWts(MainBarAttr.HiTolWt,MainBarAttr.LoTolWt)=0);
{$IFDEF DEBUGBARS}
 Disp_Error_Msg('Half way through TBarsWindow.Draw"');
{$ENDIF}
 ShowGraphicalTotals(0.0,FALSE);
END;

PROCEDURE TBarsWindow.ResetTotBar(TotalWtReqd,TotalWtDone : DOUBLE);
VAR OldFont : PFontType;
BEGIN
 TWt := TotalWtReqd;
 WtD := TotalWtDone;
 {LastNewWtBarPos := BAR1_Y2;}
 {ShowGraphicalTotals(0.0,TRUE);}
END;

(*
PROCEDURE TBarsWindow.ShowNewBarTotals;
BEGIN
 Redraw;  { draws / fill the lot }     ddddddddddddddd
 {LastTotalBarPos := BAR2_Y2;}
 ShowGraphicalTotals(0.0,FALSE);
 {LastNewWtBarPos := BAR1_Y2;}
END;
*)

PROCEDURE TBarsWindow.EnableDraw(DrawState : BOOLEAN);
BEGIN
 DrawBarsEnabled := DrawState;
END;

FUNCTION TBarsWindow.IsDrawingEnabled : BOOLEAN;
BEGIN
 IsDrawingEnabled := DrawBarsEnabled;
END;

PROCEDURE TBarsWindow.ClearMainBar;
BEGIN
 {LastNewWtBarPos := BAR1_Y2;}
 ShowGraphicalTotals(0.0,TRUE);
END;


PROCEDURE TBarsWindow.ShowWeightIfValid(NetScaleWt : DOUBLE;
                                        ScaleError : INTEGER;
                                        DisplayMsg : BOOLEAN);

VAR OutOfTolerance : BOOLEAN;
    HoldFont : PFontType;
    SaveCol  : BYTE;
BEGIN
 IF NoIngredientSelected OR (NOT IsDrawingEnabled) THEN EXIT;
                                                       {****}
 IF DisplayMsg THEN
  BEGIN
   IF ScaleError IN [0,Scale_In_Motion] THEN { valid scale wt }
    BEGIN
     CASE ProcessType OF
      PTWeight :    BEGIN
       WITH MainBarAttr DO
        BEGIN
(*
         IF ((LowerBarRatio+MiddleBarRatio+UpperBarRatio) = 0)
         AND (KeyIngredientLineNo <> 0) THEN
           MessageWin.DisplayMsgIfBlank('Key Ingredient Must Be Weighed First')
         ELSE
*)
         IF CompareWts(NetScaleWt,HiTolWt) > 0 THEN
           MessageWin.DisplayMsg('Weight To High For This Ingredient',FALSE)
         ELSE IF CompareWts(NetScaleWt,LoTolWt) < 0 THEN
           MessageWin.DisplayMsg('Add Ingredient',FALSE)
         ELSE
           MessageWin.DisplayMsg('Weight Is Within Tolerance. Accept ?',FALSE);
        END;
      END;
      PTCount : WITH MainBarAttr DO
      BEGIN
       (*IF CompareWts(NetScaleWt,HiTolWt) > 0 THEN
           MessageWin.DisplayMsg('Fixed Weight Item is Out of Tolerance',FALSE)
         ELSE IF CompareWts(NetScaleWt,LoTolWt) < 0 THEN
           MessageWin.DisplayMsg('Add Fixed Weight Item',FALSE)
         ELSE
           MessageWin.DisplayMsg('Fixed Weight Item Is Within Tolerance. Accept ?',FALSE);
       *)
       MessageWin.DisplayMsg(
                        'Hit Enter Key when weight has been prepared',FALSE);
      END;
      PTStep  : MessageWin.DisplayMsg(
                        'Hit Enter Key when Process STEP has been completed',FALSE);
      END;
    END
   ELSE
    BEGIN
     HandleScaleError(ScaleError);
    END;
  END;

 IF (ProcessType IN [PTWeight{,PTCount}]) THEN { show scale weight }
  BEGIN
   IF ScaleError IN [0,
                     Scale_In_Motion,
                     Weight_Negative,
                     Scale_Not_In_Range] THEN { weight figure is realistic }
    BEGIN
     ShowGraphicalTotals(NetScaleWt,TRUE);
     HoldFont := SetCurrentFont(ScaleFont);
     SaveCol := SetTextColour((BackColour SHL 4));
     WriteStrAt(35,32,DoubleToStr(MainBarAttr.AmountReq - NetScaleWt ,8,3)+'kg');
     SetTextColour(SaveCol);
     SetCurrentFont(HoldFont);
    END;
  END;
END;


PROCEDURE TBarsWindow.ResetMainBarToDefault;
VAR
  DummyIng     : TIngredient_Record;
  DummyOrdLine : TWOLineRecord;
BEGIN
 IngredientFile^.InitRecord(DummyIng);
 WorkLineFile^.InitRecord(DummyOrdLine);
 ResetMainBarForIngred(1.0, 1.0, 2.0,@DummyOrdLine,@DummyIng);
END;

PROCEDURE TBarsWindow.ResetMainBarForIngred(TargetWt,
                                            LowestWt,
                                            HighestWt      : DOUBLE;
                                            AWOrderLine    : PWOLineRecord;
                                            RelatedIngRec  : PIngredient_Record);
VAR HoldFont : PFontType;
    SaveCol  : BYTE;
(*    MinWt,MaxWt : DOUBLE;*)
BEGIN
 {LastTotalBarPos := BAR2_Y2;}
 ProcessType     := AWOrderLine^.WOL_ProcessType;
 FixedWt         := AWOrderLine^.WOL_FixedWt;

(*
 IF  (ProcessType = PTCount)
 AND (TargetWt < FixedWt) THEN { change it to a weighing operation }
   ProcessType := PTWeight;
*)

{$IFDEF MAUNDERS} { maunders want count ingredient to mean user just needs
                    to confirm required weight has been done elsewhere. }
 IF  (ProcessType = PTCount) THEN
   FixedWt := TargetWt;
{$ELSE}
 IF  (ProcessType = PTCount)
 AND (CompareWts(HighestWt,TargetWt) < 0) THEN { another fixed wt is too much }
   ProcessType := PTWeight;
{$ENDIF}
(*
 Tolerance needs to relate to weight remaining ddddddddddd

 CalcIngredientTolWts(RelatedIngRec,
                      AmountRequired,
                      MinWt,
                      MaxWt);
*)
 ResetMainBarAttr(HighestWt, LowestWt,
                  AWOrderLine^.WOL_ContainerSize,
                  TargetWt);
 {ClearMainBar;}
 {Paint;}

 HoldFont := SetCurrentFont(ScaleFont);
 SaveCol  := SetTextColour(BackColour SHL 4);
 WriteStrAt(35,32,'          ');
 SetTextColour(SaveCol);
 SetCurrentFont(HoldFont);
END;


PROCEDURE drawfillline(Relative : BOOLEAN; x1,y1,x2,y2,X3,ClipY1,ClipY2:INTEGER);
VAR dx,dy,incr1,incr2,d,x,y,xinc,yinc,xend,yend : INTEGER;
(*
   Mask1,Mask2 : BYTE;*)


(*
   FUNCTION GetMask(y : INTEGER) : BYTE;
   BEGIN
    IF (Y MOD 2) = 0 THEN
     GetMask := Mask1 ELSE GetMask := Mask2;
   END;
*)
   PROCEDURE FillLine;
   BEGIN
    IF (Y >= CLIPY1) AND (Y <= CLIPY2) THEN
      IF Relative THEN
       DrawLineHoriz(X,X+X3,Y,1)
      ELSE
       DrawLineHoriz(X,X3,Y,1);
   END;


BEGIN
(* IF dithering THEN
  BEGIN
   Mask1 := DitherArray[SFXGRAPH.DPattern,1];
   Mask2 := DitherArray[SFXGRAPH.DPattern,0];

 ELSE
  BEGIN
   Mask1 := $FF;
   Mask2 := $FF;

 END;
*)

 dx := abs(x2-x1);
 dy := abs(y2-y1);
 IF (dx>dy) THEN
  BEGIN
   IF (x1<x2) THEN
    BEGIN
     x:=x1; y:=y1; xend := x2;
     if (y1>y2) THEN yinc := -1 else yinc := 1;
    END
   ELSE
    BEGIN
     x := x2; y := y2; xend := x1;
     if (y1>y2) THEN yinc := 1 else yinc:= -1;
    END;
   incr1 := 2*dy;d:=incr1-dx;incr2:=d-dx;
   FillLine;
   WHILE (x<xend) DO
    BEGIN
     INC(X);
     IF(d<0) THEN
      INC(d,incr1)
     ELSE
      BEGIN
       INC(d,incr2);INC(y,yinc);
      END;
     FillLine;
    END;
  END {dx>dy}
 ELSE
  BEGIN
   IF (y1<y2) THEN
    BEGIN
     x:=x1; y:=y1; yend := y2;
     if (x1>x2) THEN xinc := -1 else xinc := 1;
    END
   ELSE
    BEGIN
     x := x2; y := y2; yend := y1;
     if (x1>x2) THEN xinc := 1 else xinc:= -1;
    END;
   incr1 := 2*dx;d:=incr1-dy;incr2:=d-dy;
   FillLine;
(*
   IF (Y >= CLIPY1) AND (Y <= CLIPY2) THEN
     DrawLineHoriz(X,X+X3,Y,1);
*)
  WHILE (y<yend) DO
   BEGIN
    INC(Y);
    if(d<0) THEN INC(d,incr1)
    ELSE
     BEGIN
      INC(d,incr2);INC(x,xinc);
     END;
    FillLine;
   END;
  END;
END;




PROCEDURE TBarsWindow.FillMainBarFromTo(From_, TO_ : INTEGER;CLEAR : BOOLEAN);
VAR I          : INTEGER;
    SaveColour : BYTE;
BEGIN
 IF From_ > Bar1_Y2 THEN From_ := Bar1_Y2;
 IF To_   < Bar1_Y1 THEN To_   := Bar1_Y1;

 SetLineStyle(L_FillBarLineStyle);
 SaveColour    := CurrentColour;

 IF From_ >= To_ THEN
   OutlinePending := TRUE;

 FOR I :=From_ DOWNTO TO_ DO
  BEGIN
   IF NOT CLEAR THEN
    BEGIN
     SetColour(C_FillBarOutTol);
     IF (I < MainBarAttr.LoTolY) AND (I > MainBarAttr.HiTolY) THEN
       SetColour(C_FillBarInTol);
     END
   ELSE SetColour(BARBACKCOL);
   DrawFillLine(FALSE,Bar1_X1+1,Bar1_Y1,
                Bar1_X3+1,Bar1_Y2-LINETHICK,Bar1_X2-1,I,I);
  END;

 CurrentColour := SaveColour;
 SetLineStyle(0);

 IF CLEAR THEN
   LastNewWtBarPos := From_ +1   { main bar has been lowered }
 ELSE
   LastNewWtBarPos := To_;

 IF LastNewWtBarPos > (Bar1_Y2) THEN
   LastNewWtBarPos := Bar1_Y2;
END;


PROCEDURE TBarsWindow.FillTotalBarFromTo(From_, To_ : INTEGER; Col : BYTE);
VAR SaveColour : BYTE;
    I          : INTEGER;
BEGIN
 IF From_ > Bar2_Y2 THEN From_ := Bar2_Y2;
 IF To_   < Bar2_Y1 THEN To_   := Bar2_Y1;

 SetLineStyle(L_MixBarLineStyle);
 SaveColour    := CurrentColour;
 SetColour(Col);

 IF From_ >= To_ THEN
   OutlinePending := TRUE;

 FOR I := From_ DOWNTO To_ DO
  BEGIN
   IF (I < Bar2_Y2-(Bar2_Y2-(Bar1_Y2+1))) THEN
     DrawFillLine(TRUE,Bar2_X1+1,Bar2_Y1,Bar2_X3+1,Bar2_Y2-LINETHICK,21,I,I)
   ELSE
     DrawFillLine(FALSE,Bar2_X1+1,Bar2_Y1,
                  Bar2_X3+1,Bar2_Y2-LINETHICK,BAR2_X2-1,I,I);
  END;
 CurrentColour := SaveColour;
 SetLineStyle(0);

 IF Col = BARBACKCOL THEN { background colour }
   LastTotalBarPos := From_ +1   { total bar has been lowered }
 ELSE
   LastTotalBarPos := To_;

 IF LastTotalBarPos > (Bar2_Y2) THEN
   LastTotalBarPos := Bar2_Y2;
END;


FUNCTION  TBarsWindow.ConvertWtToMainBarPixels(AWt : DOUBLE) : LONGINT;
VAR
    LowerPPos,
    MiddlePPos,
    UpperPPos   : LONGINT;
BEGIN
 WITH MainBarAttr DO
  BEGIN
   IF LowerBarRatio = 0 THEN
    LowerPPos := Bar1_Y2-LoTolY
   ELSE
    BEGIN
     LowerPPos  := Min(ROUND(AWt*LowerBarRatio),BAR1_Y2-LoTolY);
     IF LowerPPos <= 0 THEN LowerPPos := 0;
    END;

   IF CompareWts(AWt,HiTolWt) >= 0 THEN { fill tolerance bar }
     MiddlePPos := LoTolY-HiTolY
   ELSE IF CompareWts(AWt,LoTolWt) >= 0 THEN { fill part of tolerance bar }
     MiddlePPos := ROUND((AWt-LoTolWt)*MiddleBarRatio)
   ELSE
     MiddlePPos := 0;

   UpperPPos  := Min(Round((AWt-HiTolWt)*UpperBarRatio),HiTolY-Bar1_Y1);
   IF UpperPPos <= 0 THEN UpperPPos := 0;
  END;
 ConvertWtToMainBarPixels := LowerPPos+MiddlePPos+UpperPPos;
END;


PROCEDURE TBarsWindow.ShowGraphicalTotals(NetScaleWt : DOUBLE;
                                          ShowScaleWt: BOOLEAN);
VAR TotalPComp,
    BatchPComp  : LONGINT;
    I{,J,K}     : INTEGER;
    OldFont,
    Newfont     : PFontType;


(*
  PROCEDURE DrawBarUpTo(Position,Max : LONGINT);
  BEGIN
   IF (Position > 0) AND (LastNewWtBarPos < Max) THEN
    FillMainBarFromTo(LastNewWtBarPos,Position,ForeGround);
  END;
*)
BEGIN
 IF ShowScaleWt AND (ProcessType <> PTStep) THEN
  BEGIN
   BatchPComp := Bar1_Y2-ConvertWtToMainBarPixels(NetScaleWt);

   IF BatchPComp > LastNewWtBarPos THEN
    BEGIN    {deletes from batchpcomp lastnewwtbarpos}
     FillMainBarFromTo(BatchPComp,LastNewWtBarPos,TRUE);
    END
   ELSE IF LastNewWtBarPos > BatchPComp THEN
    BEGIN
     FillMainBarFromTo(LastNewWtBarPos,BatchPComp,FALSE);{ COLOUR }
    END;
 {  DrawBarOutlines(MainBarAttr.HiTolWt = MainBarAttr.LoTolWt);}
 {  LastNewWtBarPos := BatchPComp;}



  END;
(*
 ELSE IF (ShowScaleWt AND (ProcessType = PTStep)) THEN
  BEGIN
   NewFont  := CreateFont(1,2,Vert,FONT_8x16,FontNormal);
   OldFont  := SetCurrentFont(NewFont);
   WriteStrAt(71,4,'Step Ingredient');
   DeleteFont(SetCurrentFont(OldFont));
  END;
*)

{$IFDEF DEBUGBARS}
 Disp_Error_Msg('half way through ShowGraphicalTotals '+ DoubleToStr(TWt,1,2));
{$ENDIF}

 IF CompareWts(TWt,0.0) <> 0 THEN
   TotalPComp := Bar2_Y2-ROUND((WtD+NetScaleWt)*(Bar1_Y2-Bar1_Y1)  / TWt)
 ELSE
   TotalPComp := Bar2_Y2;

 IF TotalPComp<Bar2_Y1 THEN TotalPComp := Bar2_Y1;
(*
  IF (TotalPComp<>LastTotalBarPos) THEN
   BEGIN

   {Shade the second bar}
{   SetLineStyle(8);    }

   J:=BAR2_X3-(Bar2_Y2-LastTotalBarPos) DIV ((Bar1_y2-Bar1_Y1) DIV (Bar1_X3-Bar1_X1));

   IF LastTotalBarPos <(Bar2_Y2 -(Bar2_y2-Bar1_y2)) THEN
    K := J+22
   ELSE
    K:=BAR2_X2;
*)
 IF TotalPComp > LastTotalBarPos THEN { lower weight }
   FillTotalBarFromTo(TotalPComp,LastTotalBarPos,BARBACKCOL) { clear from top to bottom }
 ELSE IF LastTotalBarPos > TotalPComp THEN { moving down }
   FillTotalBarFromTo(LastTotalBarPos,TotalPComp,C_MixBar);

 {LastTotalBarPos := TotalPComp;}
(* END;*)
 IF OutlinePending THEN
   DrawBarOutlines(CompareWts(MainBarAttr.HiTolWt,MainBarAttr.LoTolWt)=0);
END;

PROCEDURE TBarsWindow.ResetMainBarAttr(HighTolWt,
                                       LowTolWt,
                                       ContainerWt,
                                       AmountRequired : DOUBLE);
VAR WeightRequired : DOUBLE;
(*VAR HoldFont       : PFontType;*)

BEGIN
{$IFDEF DEBUGBARS}
 Disp_Error_Msg('ResetMainBarAttr entry');
{$ENDIF}

{Compute the high and low tolerance levels}
 FillChar(MainBarAttr,SizeOf(MainBarAttr),#0);
 MainBarAttr.ContainerWt  := ContainerWt;
 MainBarAttr.AmountReq    := AmountRequired;
 IF MainBarAttr.AmountReq < 0.0 THEN
   MainBarAttr.AmountReq := 0.0;
 MainBarAttr.HiTolWt      := HighTolWt;
 MainBarAttr.LoTolWt      := LowTolWt;
 MainBarAttr.IgnoreLowTolerance := FALSE;

 WITH MainBarAttr DO { work out scaling. note:Y co-ords are from top of screen }
  BEGIN
   MaxBarWeight := HiTolWt * 1.2;
(*
   RoundWtToScaleRes(HiTolWt);
   RoundWtToScaleRes(LoTolWt);
   RoundWtToScaleRes(MaxBarWeight);
*)
   AdjustTolToScaleRes(LoTolWt, HiTolWt);
   MaxBarWeight := RoundWtToNearestGram(MaxBarWeight);

 { set low tol bar posn to reflect quantity required compared to the size of
   the container so that full containers are distinguishable from part
   containers.
   Restrict low tol bar pos to: Bar1_Y1+80 .. Bar1_Y1+130
   unless low tolerance is zero in which case its at the bottom of the cone}
   IF CompareWts(LoTolWt,0.0) <= 0 THEN
     LoTolY := Bar1_Y2
   ELSE
     LoTolY := Bar1_Y1 + 130 - (50*Round(DivDouble(AmountReq,ContainerWt)));
   LoTolX := Bar1_X1 + 1 +
               (((Bar1_X3-Bar1_X1) * (LoTolY-Bar1_Y1)) DIV (Bar1_y2-Bar1_Y1));

 { set high tolerance bar distance from low tolerance bar so that it reflects
   the tightness of the tolerance.
   Restrict distance to 15 .. 80 }
   HiTolY := (LoTolY -15) -Round(DivDouble(65*(HiTolWt-LoTolWt), HiTolWt));
{   MessageWin.DisplayMsg(IntToStr(LoTolY,1)+'  '+IntToStr(HiTolY,1),TRUE);}

   HiTolX := Bar1_X1 + 1 +
               (((Bar1_X3-Bar1_X1) * (HiTolY-Bar1_Y1)) DIV (Bar1_y2-Bar1_Y1));

   { old tolerance bars need clearing }
   LastNewWtBarPos := BAR1_Y1; { force clearing from top of cone }
   OutlinePending := TRUE;

   IF CompareWts(LoTolWt,0.0) <> 0 THEN
     LowerBarRatio  := (Bar1_Y2 - LoTolY) / LoTolWt
   ELSE
     LowerBarRatio := 0;

   IF CompareWts((HiTolWt - LoTolWt),0.0) <> 0 THEN
     MiddleBarRatio := ((LoTolY-HiTolY))  / (HiTolWt - LoTolWt)
   ELSE
     MiddleBarRatio := 0;

   IF CompareWts(MaxBarWeight-HiTolWt, 0.0) <> 0 THEN
     UpperBarRatio  := ((HiTolY-Bar1_Y1)) / (MaxBarWeight-HiTolWt)
   ELSE
     UpperBarRatio := 0;

   TargetY := Bar1_y2 - ConvertWtToMainBarPixels(AmountReq);
{$IFDEF DEBUGBARS}
   Disp_Error_Msg('ResetMainBarAttr exit');
{$ENDIF}
  END;
END;


FUNCTION TBarsWindow.GetHiTolWeight : DOUBLE;
BEGIN
 GetHiTolWeight := MainBarAttr.HiTolWt;
END;

FUNCTION TBarsWindow.GetLoTolWeight : DOUBLE;
BEGIN
 GetLoTolWeight := MainBarAttr.LoTolWt;
END;

FUNCTION TBarsWindow.GetTargetWeight : DOUBLE;
BEGIN
 GetTargetWeight := MainBarAttr.AmountReq;
END;

BEGIN
 BarsWindow := NIL;
END.
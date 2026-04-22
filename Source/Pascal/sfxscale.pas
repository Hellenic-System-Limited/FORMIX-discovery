(****************************************************************************
*  UNIT          : SFXScale                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : Objects Used To Interface With The Scale And Tare        *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$C FIXED PRELOAD PERMANENT}
{$I F6COMP}
UNIT SFXScale;
INTERFACE
USES FXCfg,Crt,F6StdCtv,F6StdUtl,FXModCTV,SFXBtn,SFXStd,SFXGraph,SFXFont,SFX_Pro,SFXCurr,
     SFXConst,SFXMsg,ComCheck,SFXWin,SFXComms,SFX_Bars,FXFWork,SFXOList,SFXDate,
     SFX_Msg;


CONST
 SCALE_WIN_LEFT          = 474;
 SCALE_WIN_WID           = 162;
 SCALE_WIN_TOP           = 004;
 SCALE_WIN_HEIGHT        = 38;
 No_Scale_Error          = 0;
 Scale_Not_Activated     = 1;
 Scale_Not_There         = 2;
 Weight_Not_Yet_Recieved = 3;
 Scale_In_Motion         = 4;
 Scale_Not_Visable       = 5;
 Weight_Negative         = 6;
 Scale_Not_In_Range      = 7;
 Weight_Not_Valid        = 8;

 FACE_SEMI_AUTO_TARE          = 1;
 FACE_SEMI_AUTO_TARE_INVERTED = 2;
 FACE_CANCEL_TARE             = 3;

TYPE
     PWtSimulator = ^ TWtSimulator;
     TWtSimulator = OBJECT
      SIM_Wt : LONGINT;
      CONSTRUCTOR Init;
      PROCEDURE IncWt(NoOfIncs : LONGINT);
      PROCEDURE DecWt(NoOfIncs : LONGINT);
      FUNCTION  GetGrossWt(VAR GrossWtVar : DOUBLE) : INTEGER;
     END;

CONST
     WtSimulator : PWtSimulator = NIL;

TYPE PTareButton = ^TTareButton;
     TTareButton = OBJECT(TPCXTriStateButton)
      WaitingForTare : BOOLEAN;
      CONSTRUCTOR Init(x1,y1,x2,y2,WinFlags : WORD;Pcx1,Pcx2,Pcx3 : PCXNameStr);
      DESTRUCTOR  Done;VIRTUAL;
      FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
      PROCEDURE   MakeTareActive;
      PROCEDURE   MakeNormalTareActive; { non flashing }
      PROCEDURE   MakeFlashingTareActive;
      PROCEDURE   MakeCancelActive;
      PROCEDURE   MakeInActive;
      PROCEDURE   Draw; VIRTUAL;
(*      PROCEDURE   ResetTareAdjustment;*)
     END;


{$IFNDEF NOPARTWEIGH}
     PPartialWtBtn = ^TPartialWtBtn;
     TPartialWtBtn = OBJECT(TPCXButton)
      PROCEDURE MakeActive;
      PROCEDURE MakeInactive;
      FUNCTION UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
     END;
{$ENDIF}


     PScaleWindow = ^TScaleWindow;
     TScaleWindow = OBJECT(TSFWINDOW)

      ScaleActivated : BOOLEAN;
      TareWeight     : DOUBLE;
      InitialContainerTare    : DOUBLE;

      TareButton     : PTareButton;
{$IFNDEF NOPARTWEIGH}
      PartialWtBtn   : PPartialWtBtn;
{$ENDIF}

      PROCEDURE ShowWindow; VIRTUAL;
      PROCEDURE HideWindow; VIRTUAL;


      CONSTRUCTOR Init;
      DESTRUCTOR  Done; VIRTUAL;
      FUNCTION  WaitForScaleWt(VAR GrossWeight : DOUBLE;
                               VAR NetWeight   : DOUBLE) : INTEGER;
                { note: Doesnt inform WeighProcessController of weight.
                  ie. the calling function will complete before the controller
                      will change automatically to any weight changes.
                }
      PROCEDURE SetScaleTareWt(GrossWt : DOUBLE); { NOTE: setting scale tare to 0.0
                                                     is not the same as
                                                     ClearScaleTareWt }
      PROCEDURE ClearScaleTareWt; { Invalidates any tare set in current
                                    weighing process }
      FUNCTION  SetTareAtCurrentWeight : INTEGER;
      (*PROCEDURE SetAutoTareWtOfContainer;*)
      PROCEDURE RefreshWt;
      FUNCTION  TareWtExists : BOOLEAN;

     PRIVATE
      PROCEDURE ShowWeightNetOfTare(GrossWt : DOUBLE);
(*    FUNCTION  GetScaleWeight(VAR TheWeight : DOUBLE) : INTEGER;*)
      FUNCTION  GetScaleGrossWeight(VAR GrossWt   : DOUBLE) : INTEGER;
     END;


CONST
{VAR}ScaleWindow   : PScaleWindow= NIL;


TYPE
     TWeighingStep = (ws_PlaceCont,
                      ws_TareCont,
                      ws_AddIngred,
                      ws_RemoveCont);

     PWeighProcessController = ^TWeighProcessController;
     TWeighProcessController = OBJECT
       WPC_IgnoreScale   : BOOLEAN;
       WPC_OrderNo   : LONGINT;
       WPC_Revision  : BYTE;
       WPC_MixNo     : LONGINT;
       WPC_LineNo    : LONGINT;
       WPC_ContNo    : LONGINT;
       WPC_TareOk    : BOOLEAN;
       WPC_CurrentOp : TWeighingStep; { USE SetCurrentOpTo() FOR ASSIGNMENTS }
       CONSTRUCTOR Init;
       DESTRUCTOR  Done; VIRTUAL;

       PROCEDURE   WeighingSelected(ContNoForLineInMix : LONGINT;
                                    NoOfContainersReqd : LONGINT);
                   { Needs to be called every time SelRecs are changed
                     between weighings }

       PROCEDURE   WeightUpdate(ScaleError : INTEGER;
                                GrossWt, NetWt : DOUBLE);
                   { Needs to be called as often as possible }

       PROCEDURE   ATareWtHasBeenSet;
                   { Needs to be called when scale window tare weight set/re-set }

       PROCEDURE   TareCancelled;
                   { Needs to be called when scale window tare zeroed }


       PROCEDURE   IngredWeightAccepted;
                   { Needs to be called when a weighing has been
                     successfully completed }
     PRIVATE
       FUNCTION    ValidOp(OpID : TWeighingStep) : BOOLEAN;
       PROCEDURE   SetCurrentOpTo(Operation : TWeighingStep);
       PROCEDURE   StepOverInvalidOps(StartingFromOp : TWeighingStep);
     END;

VAR
     WeighProcessController : TWeighProcessController;


TYPE
(*
     PGetTareWt = ^TGetTareWt;
     TGetTareWt = OBJECT(TBackGroundTask)
       PROCEDURE   Execute; VIRTUAL;
     END;


    PCancelTareWt = ^TCancelTareWt;
    TCancelTareWt = OBJECT(TBackGroundTask)
      PROCEDURE   Execute; VIRTUAL;
    END;
*)

(*
    PZeroScale = ^TZeroScale;
    TZeroScale = OBJECT(TBackGroundTask)
      PROCEDURE   Execute; VIRTUAL;
    END;


    PWaitForZeroWt = ^TWaitForZeroWt;
    TWaitForZeroWt = OBJECT(TBackGroundTask)
      PROCEDURE   Execute; VIRTUAL;
    END;

    PWaitForNonZeroWt = ^TWaitForNonZeroWt;
    TWaitForNonZeroWt = OBJECT(TBackGroundTask)
      PROCEDURE   Execute; VIRTUAL;
    END;
*)

    TScaleTaskState = PACKED RECORD
(*
      GetTareWtActive          : BOOLEAN;
      CancelTareWtActive       : BOOLEAN;
      ZeroScaleActive          : BOOLEAN;
      WaitForZeroWtActive      : BOOLEAN;
      WaitForNonZeroWtActive   : BOOLEAN;
*)
      FlashSemiAutoTareActive  : BOOLEAN;
      BarsWindowDrawActive     : BOOLEAN;
      ProcessControllerActive  : BOOLEAN;
    END;


(*
VAR
    GetTareWt          : PGetTareWt;
    CancelTareWt       : PCancelTareWt;
*)
(*
    ZeroScale          : PZeroScale;
    WaitForZeroWt      : PWaitForZeroWt;
    WaitForNonZeroWt   : PWaitForNonZeroWt;
*)


FUNCTION  HandleScaleError(ErrorNum : INTEGER) : INTEGER;
(*FUNCTION  WtIsAcceptableToContinueTare(Wt : DOUBLE;ScaleError : INTEGER):BOOLEAN;*)
PROCEDURE TaskInit;
FUNCTION  MainScaleInit : BOOLEAN;
PROCEDURE MainScaleDone;

PROCEDURE RestoreScaleTasks(ScaleTaskState : TScaleTaskState);
PROCEDURE StopScaleTasks(VAR ScaleTaskState : TScaleTaskState);


IMPLEMENTATION
USES SFX_Scrl,SFXCOLR;

TYPE
    PFlashSemiAutoTare = ^TFlashSemiAutoTare;
    TFlashSemiAutoTare = OBJECT(TBackGroundTask)
(*    stopped : boolean;*)
      CONSTRUCTOR Init;
      PROCEDURE   Execute; VIRTUAL;
(*    procedure   autostop;
      procedure   autostart;
*)
    END;
CONST
    FlashSemiAutoTare  : PFlashSemiAutoTare = NIL;

{
VAR ScaleFont          : PFontType;
}

FUNCTION MinContWtOnCurrScale : DOUBLE;
{ approx - LUCID doesnt transmit increment (LSD) }
BEGIN
 MinContWtOnCurrScale := GetKgScaleIncrement*5;
END;

(*
FUNCTION WtIsAcceptableToContinueTare(Wt : DOUBLE;ScaleError : INTEGER):BOOLEAN;
BEGIN
 WtIsAcceptableToContinueTare :=
        ((ScaleError = 0) AND (Wt < (GetKgScaleIncrement*5)) AND (Wt >= 0.0))
     OR (ScaleError IN [Scale_Not_Activated,Scale_Not_There]);
END;
*)

FUNCTION HandleScaleError(ErrorNum : INTEGER) : INTEGER;
VAR ErrStr   : STRING[80];
    ScaleStr : STRING[40];
BEGIN
 IF ErrorNum <> No_Scale_Error THEN
  BEGIN
   {$IFDEF DEBUG}
    ScaleStr := 'Scale : '+IntToStr(ReadingScale,1)+'. ';
   {$ELSE}
    ScaleStr := '';
   {$ENDIF}
   ErrStr   := '';
   CASE ErrorNum OF
    Scale_Not_Activated : ErrStr := 'Scale Currently Unreadable';
    Scale_Not_There     : ErrStr := 'Scale Not Responding Or No Scale Attached';
    Scale_In_Motion     : ErrStr := 'Scale In Motion';
    Weight_Negative     : ErrStr := 'Weight Is Below Zero';
    Scale_Not_In_Range  : ErrStr := 'Scale Is Not Within Range';
    Weight_Not_Valid    : ErrStr := 'Weight Is Not Valid';
   END; {CASE}
   ErrStr := ScaleStr+ErrStr;
   IF NOT NowtButSpace(ErrStr) THEN
    MessageWin.DisplayMsg(ErrStr,FALSE);
  END; {!=NO_SCALE_ERROR}
 HandleScaleError := ErrorNum;
END;

(*
FUNCTION IsTareWtNeeded : BOOLEAN;
BEGIN
  IsTareWtNeeded := (ScaleWindow^.TareWeight = 0.0);
END;
*)
(*
PROCEDURE ResetObjectForScaleTare;
BEGIN
 IF NOT ScaleWindow^.ScaleActivated THEN EXIT;
 IF TareNotSet THEN
  BEGIN
   IF (NOT (WaitForZeroWt^.Active OR WaitForNonZeroWt^.Active OR
       GetTareWt^.Active OR CancelTareWt^.Active)) THEN
    BEGIN
     GetTareWt^.EnableTask;
     ScaleWindow^.SetScaleTareWt(0);
    END;
  END;
END;
*)
{---------------------------------------------------------------}

CONSTRUCTOR TWtSimulator.Init;
BEGIN
 SIM_Wt := 0;
END;

PROCEDURE TWtSimulator.IncWt(NoOfIncs : LONGINT);
BEGIN
 IF (SIM_Wt + NoOfIncs) < 9999999 THEN
   Inc(SIM_Wt,NoOfIncs);
END;

PROCEDURE TWtSimulator.DecWt(NoOfIncs : LONGINT);
BEGIN
 IF (SIM_Wt - NoOfIncs) > -999 THEN
   Dec(SIM_Wt,NoOfIncs);
END;

FUNCTION TWtSimulator.GetGrossWt(VAR GrossWtVar : DOUBLE) : INTEGER;
BEGIN
 GrossWtVar := SIM_Wt*Config_Rec^.Conf_ScaleRes;
 IF SIM_Wt < 0 THEN
   GetGrossWt := Weight_Negative
 ELSE
   GetGrossWt := No_Scale_Error;
END;

{================Semi Auto Tare Button===================}
CONSTRUCTOR TTareButton.Init(x1,y1,x2,y2,WinFlags : WORD;Pcx1,Pcx2,Pcx3 : PCXNameStr);
BEGIN
(* TareNotSet     := IsTareWtNeeded;*)
 WaitingForTare := FALSE;
 INHERITED Init(x1,y1,x2,y2,WinFlags,Pcx1,Pcx2,Pcx3);
END;

DESTRUCTOR TTareButton.Done;
BEGIN
 INHERITED Done;
END;

FUNCTION TTareButton.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR GrossWt,NetWt : DOUBLE;
BEGIN
 UserActivateFunction := FALSE;
 MessageWin.ClearMsg;
 IF CurrFace = FACE_CANCEL_TARE THEN { user is cancelling semi-auto tare }
  BEGIN
   ScaleWindow^.ClearScaleTareWt;
{   MakeTareActive;}
{   BarsWindow^.ShowWeightIfValid(0,FALSE);}
   MessageWin.DisplayMsg('Tare Has Been Cancelled.',TRUE);
(*   Delay(1000);*)
(*
   TareNotSet := {NOT TareNotSet} TRUE;
   TareButton^.ResetTareAdjustment;
*)
  END
 ELSE  { user is semi-auto taring }
  BEGIN
   IF ScaleWindow^.WaitForScaleWt(GrossWt,NetWt) = 0 THEN
    BEGIN
     ScaleWindow^.SetScaleTareWt(GrossWt);
     { BarsWindow^.ClearMainBar;}
     { ChangeWindowFont(RecipeNormalFont);}
    END
   ELSE
     EXIT;
    {****}
  END;

 Paint;
{ BarsWindow^.EnableDraw(TRUE);}
{ BarsWindow^.ClearMainBar; xsd}
END;

PROCEDURE TTareButton.MakeTareActive;
BEGIN
 IF WaitingForTare THEN
   FlashSemiAutoTare^.EnableTask
 ELSE
   FlashSemiAutoTare^.DisableTask;
 CurrFace := FACE_SEMI_AUTO_TARE;
 ShowWindow;
 EnableButton;
END;

PROCEDURE TTareButton.MakeNormalTareActive;
BEGIN
 WaitingForTare := FALSE;
 MakeTareActive;
END;

PROCEDURE TTareButton.MakeFlashingTareActive;
BEGIN
 WaitingForTare := TRUE;
 MakeTareActive;
END;

PROCEDURE TTareButton.MakeCancelActive;
BEGIN
 WaitingForTare := FALSE;
 FlashSemiAutoTare^.DisableTask;
 CurrFace := FACE_CANCEL_TARE;
 ShowWindow; {if not visible - make it visible and paint it}
 EnableButton;
END;

PROCEDURE TTareButton.MakeInActive;
BEGIN
 WaitingForTare := FALSE;
 FlashSemiAutoTare^.DisableTask;
 HideWindow;
 DisableButton; {DisableBtn(TRUE);}
END;


(*
PROCEDURE TTareButton.ResetTareAdjustment;
BEGIN
 TareNotSet := IsTareWtNeeded;
 IF TareNotSet THEN
   MakeInActive
 ELSE
   Paint;
 ResetObjectForScaleTare;
END;
*)

PROCEDURE TTareButton.Draw;
BEGIN
(*
 IF (NOT WaitingForTare) THEN  { not waiting for user to press semi-auto tare}
  BEGIN
   IF (ScaleWindow^.TareWeight > 0.0) THEN { tare has been set }
     CurrFace := FACE_CANCEL_TARE;         { show 'cancel tare' }
*)
 INHERITED Draw;
(*
 IF TareNotSet THEN
  DisplayText(1,'Semi Auto '+CRLF+'   Tare   ')
 ELSE
  DisplayText(1,'Cancel    '+CRLF+'   Tare   ');
*)
END;



{$IFNDEF NOPARTWEIGH}
FUNCTION TPartialWtBtn.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR ScaleErr      : INTEGER;
    GrossWt,NetWt : DOUBLE;

BEGIN
 UserActivateFunction := FALSE;

 IF SelRecs.WorkHRecord.WOH_MixType = mt_EqualContainersPerMix THEN
   EXIT;
  {****}
 IF NoIngredientSelected THEN
   EXIT;
  {****}
 BarsWindow^.DropLowTolerance;
 UserActivateFunction := BarsWindow^.UserActivateFunction(0,0);
                                       { eventually calls PrimeNextIngredient }
 BarsWindow^.RestoreLowTolerance;
(*  this button used to just record the weight and ask for a second
    barcode scan
 ScaleErr := 0;
 NetWt := 0.0;

 ScaleErr := ScaleWindow^.WaitForScaleWt(GrossWt, NetWt);

 IF ScaleErr = No_Scale_Error THEN  { SAVE CURRENT WEIGHT}
  BEGIN
   IF (NetWt > 0.0) THEN
    BEGIN
     SelRecs.FirstSourceWt := NetWt;
     { ASK FOR SOURCE BARCODE SCAN }
     SelRecs.GetSecondSourceBarcode;
    END;
  END;
*)
END;


PROCEDURE TPartialWtBtn.MakeActive;
BEGIN
(* IF Config_Rec^.CONF_PromptForSource THEN*)
  BEGIN
   EnableButton;
   ShowWindow;
  END;
END;

PROCEDURE TPartialWtBtn.MakeInActive;
BEGIN
 HideWindow;
 DisableButton;
END;
{$ENDIF}

{===============SCALE ROUTINES ==========================}

CONSTRUCTOR TScaleWindow.Init;
BEGIN
 INHERITED Init(SCALE_WIN_LEFT,SCALE_WIN_TOP,
                SCALE_WIN_LEFT+SCALE_WIN_WID,
                SCALE_WIN_TOP+SCALE_WIN_HEIGHT,C_WindowStaticText SHR 4,WT_Border OR WT_Shadow,NIL,FALSE);

 New(TareButton,Init(But3Start,ButtonTop,But3Stop,ButtonBot,
                     (WT_Border OR WT_Shadow OR WT_Button
                      OR WT_NonDeletable), { to be persistent as the scale window}
                     'SAUTO1.PCX','SAUTO2.PCX','SAUTO3.PCX'));
{$IFNDEF NOPARTWEIGH}
 New(PartialWtBtn,Init(But4Start,ButtonTop,But4Stop,ButtonBot,
                       (WT_Border OR WT_Shadow OR WT_Button
                        OR WT_NonDeletable), { to be persistent as the scale window}
                       'PARTWT.PCX'));
{$ENDIF}

 ScaleActivated := FALSE;
 TareWeight     := 0.0;
 InitialContainerTare    := 0.0;

END;


DESTRUCTOR TScaleWindow.Done;
BEGIN
 IF Assigned(TareButton) THEN
  BEGIN
   Dispose(TareButton,Done);
   TareButton := NIL;
  END;

{$IFNDEF NOPARTWEIGH}
 IF Assigned(PartialWtBtn) THEN
  BEGIN
   Dispose(PartialWtBtn,Done);
   PartialWtBtn   := NIL;
  END;
{$ENDIF}
 INHERITED Done;
END;


PROCEDURE TScaleWindow.ShowWindow;
BEGIN
 INHERITED ShowWindow;
 IF TareButton^.IsWindowSelectable THEN
   TareButton^.ShowWindow;
{$IFNDEF NOPARTWEIGH}
 IF PartialWtBtn^.IsWindowSelectable THEN
   PartialWtBtn^.ShowWindow;
{$ENDIF}
END;

PROCEDURE TScaleWindow.HideWindow;
BEGIN
{$IFNDEF NOPARTWEIGH}
 PartialWtBtn^.HideWindow;
{$ENDIF}
 TareButton^.HideWindow;
 INHERITED HideWindow;
END;

FUNCTION TScaleWindow.WaitForScaleWt(VAR GrossWeight : DOUBLE;
                                     VAR NetWeight   : DOUBLE) : INTEGER;
VAR
  StartTick,
  CurrTick   : LONGINT;
  ScaleErr   : INTEGER;
BEGIN
 StartTick := GetTickCount;
 REPEAT
   ScaleErr := (HandleScaleError(ScaleWindow^.GetScaleGrossWeight(GrossWeight)));
   IF ScaleErr = 0 THEN
     BREAK;
    {*****}
   CurrTick := GetTickCount;
 UNTIL (CurrTick > StartTick+6) OR (CurrTick < StartTick);

 NetWeight := GrossWeight - ScaleWindow^.TareWeight;
 WaitForScaleWt := ScaleErr;
END;

FUNCTION  TScaleWindow.TareWtExists : BOOLEAN;
{ avoids comparing doubles for equality }
BEGIN
 TareWtExists := (TareWeight > 0.0001)
              OR (TareWeight < -0.0001);
END;

PROCEDURE TScaleWindow.SetScaleTareWt(GrossWt : DOUBLE);
{ NOTE: setting scale tare to 0.0 is not the same as ClearScaleTareWt }
BEGIN
 IF NOT TareWtExists THEN { no tare has been set for current container yet }
   InitialContainerTare := GrossWt;

 TareWeight := GrossWt;
 IF GrossWt > 0.0 THEN
   TareButton^.MakeCancelActive
 ELSE
   TareButton^.MakeNormalTareActive; { give second chance to tare container off }

 WeighProcessController.ATareWtHasBeenSet;
 RefreshWt;
END;

PROCEDURE TScaleWindow.ClearScaleTareWt;
{ Invalidates any tare set in current weighing process }
BEGIN
 InitialContainerTare := 0.0;
 TareWeight := 0.0;
 TareButton^.MakeInactive; {WeighProcessController will re-init it }
 WeighProcessController.TareCancelled;
 RefreshWt;
END;


FUNCTION TScaleWindow.SetTareAtCurrentWeight : INTEGER;
VAR GWt, NWt : DOUBLE;
    ScaleErr : INTEGER;
BEGIN
 ScaleErr := WaitForScaleWt(GWt,NWt);
 IF ScaleErr = 0 THEN
   SetScaleTareWt(GWt);
 SetTareAtCurrentWeight := ScaleErr;
END;

(*
PROCEDURE TScaleWindow.SetAutoTareWtOfContainer;
{VAR Wt : DOUBLE;
   ScaleError : BYTE;

   PROCEDURE LoopCalls;
   BEGIN
    ScaleError := GetScaleWeight(Wt);
    IF NOT ReturnToOrderOn THEN EXIT;
    IF Process_User_Input(FALSE) THEN
     BEGIN
      TranslatePress;
      IF RetToOrder^.IsPointInWindow(ScreenPosX,ScreenPosY) THEN
       BEGIN
        RetToOrder^.ButtonDown;
        WHILE Process_User_Input(FALSE) DO
         BEGIN
         END;
        RetToOrder^.ButtonUp;
        RetToOrder^.UserActivateFunction(0,0);
       END;
     END;
   END;}

BEGIN
 WaitForZeroWt^.EnableTask;
END;
*)

PROCEDURE TScaleWindow.ShowWeightNetOfTare(GrossWt : DOUBLE);
VAR SaveCol : BYTE;
    NetWt   : DOUBLE;
BEGIN
 IF ((WinType AND WT_Visable) = 0) THEN EXIT;
 NetWt := GrossWt - TareWeight;

 SaveCol := SetTextColour(C_WindowText);

{ Temp := ScalePortData.WM_St2 AND (S2_POSITIVE_WT OR S2_OVER_RANGE);
 WriteStrAt(1,3,DoubleToStr(Wt,6,2)+'  '+IntToStr(ScalePortData.WM_St2,1)
                +'  '+IntToStr(temp,1));}

 DEC(Bounds.Top,4);
 SetCurrentFont(DoubleHeightFont);

 CASE ScaleHardware[ReadingScale].SH_ScaleType OF
  TWeigh_Master : BEGIN
   IF ((ScalePortData.WM_St2 AND S2_OVER_RANGE) <> 0) OR
      ((ScalePortData.WM_St2 AND S2_POSITIVE_WT) = 0) THEN
    DisplayText(1,COPY(SPACE_STRING,1,7)+'kg')
   ELSE
    DisplayText(1,DoubleToStr(NetWt,7,ScaleParameters.NumDecimal)+'kg');
  END;
  TSystem80: BEGIN
   IF (ScalePortData.S80_Sign = Ord('-')) OR
    (ScalePortData.S80_Status IN [Ord('U'),Ord('N')]) THEN
    DisplayText(1,COPY(SPACE_STRING,1,7)+'kg')
   ELSE
    DisplayText(1,DoubleToStr(NetWt,7,ScaleParameters.NumDecimal)+'kg');
  END;
  TLucid : BEGIN
   IF (ScalePortData.LUC_Sign <> ORD(' ')) THEN
    BEGIN
    DisplayText(1,COPY(SPACE_STRING,1,7)+'kg')
    END
   ELSE
    BEGIN
     DisplayText(1,DoubleToStr(NetWt,7,(ScalePortData.LUC_NoDP-ORD('0')))+'kg');
    END;
  END;
  TNoScale : BEGIN
    DisplayText(1,DoubleToStr(NetWt,7,ScaleParameters.NumDecimal)+'kg');
  END;
 END;
 INC(Bounds.Top,4);
 SetTextColour(SaveCol);

{
 DrawWindow(SCALE_WIN_LEFT,SCALE_WIN_TOP,
            SCALE_WIN_LEFT+SCALE_WIN_WID,
            SCALE_WIN_TOP+SCALE_WIN_HEIGHT,TRUE);
}
END;

FUNCTION TScaleWindow.GetScaleGrossWeight(VAR GrossWt : DOUBLE) : INTEGER;
VAR WgtStr        : STRING[10];
    WgtLng        : LONGINT;
    Dummy         : INTEGER;
    ScaleWtErr    : INTEGER;
    ScaleResult   : INTEGER;
    TempWt        : DOUBLE;
BEGIN
 IF ScaleHardware[ReadingScale].SH_ScaleType = TNoScale THEN
   ScaleWtErr := WtSimulator^.GetGrossWt(GrossWt)
 ELSE
  BEGIN
   {$IFDEF SLOWSCALE}
   Delay(70);
   {$ENDIF}
   ScaleWtErr    := Weight_Not_Yet_Recieved;
   GrossWt       := 0.0;

   ScaleResult := GetPacketFromScale;
   IF (ScaleResult = PT_Parameters) THEN
    BEGIN
     CalibrateScale;
    END;
   IF (ScaleResult <> PT_Data) THEN
    BEGIN
     IF NOT ScaleActivated THEN GetScaleGrossWeight := Scale_Not_There
     ELSE GetScaleGrossWeight := Weight_Not_Yet_Recieved;
     EXIT; {exit if no packet waiting}
    END;

   IF NOT ScaleActivated THEN        {if scale has not previously been activated}
    BEGIN
     CalibrateScale;
     ScaleActivated := NOT TimeOutError;
    END;

   IF (NOT ScaleActivated) THEN
    BEGIN
     GetScaleGrossWeight := Scale_Not_Activated;
     EXIT;
    END;

   CASE ScaleHardware[ReadingScale].SH_ScaleType OF
     TWeigh_Master : BEGIN

       IF (ScalePortData.WM_St2 AND S2_POSITIVE_WT) = 0 THEN
        BEGIN
         ScaleWtErr := Weight_Negative;
        END
       ELSE IF (ScalePortData.WM_St2 AND S2_OVER_RANGE) <> 0 THEN
        BEGIN
         ScaleWtErr := Scale_Not_In_Range;
        END
       ELSE IF (ScalePortData.WM_St1 AND S1_SCALE_IN_MOTION) <> 0 THEN
        BEGIN
         ScaleWtErr := Scale_In_Motion;
        END;
       Move(ScalePortData.WM_Net,WgtStr[1],SizeOF(ScalePortData.WM_Net));
       WgtStr[0]:= Char(SizeOF(ScalePortData.WM_Net));
       Val(WgtStr,WgtLng,Dummy);
       IF (Dummy <> 0) THEN
        BEGIN
         { Leave GrossWt at 0.0 }
         ScaleWtErr := Weight_Not_Yet_Recieved; { stop caller using weight returned }
        END
       ELSE
        BEGIN
         GrossWt     := FPLong_To_Double(WgtLng,ScaleParameters.NumDecimal);
         ScaleWtErr  := 0; { clear default error code }
(*
         TheWeight := TempWt-TareWeight;
         TheWeight := Round(TheWeight *1000) / 1000;
         IF TheWeight < 0.0 THEN TheWeight := 0.0;
         IF ((WinType AND WT_Visable) = 0) THEN
          BEGIN
           ScaleWtErr := Scale_Not_Visable;
          END
         ELSE
          BEGIN
           ShowWeight(TheWeight);
          END;
*)
        END;
      END; {Case TWeigh_Master}

     TSystem80: BEGIN
       IF (ScalePortData.S80_Status <> Ord('S')) THEN
        BEGIN
         ScaleWtErr := Scale_Not_In_Range;
        END
       ELSE IF (ScalePortData.S80_Sign = Ord('-')) THEN
        BEGIN
         ScaleWtErr := Weight_Negative;
        END
       ELSE IF (ScalePortData.S80_Status = Ord('M')) THEN
        BEGIN
         ScaleWtErr := Scale_In_Motion;
        END;
       Move(ScalePortData.S80_Weight,WgtStr[1],Sizeof(ScalePortData.S80_weight));
       WgtStr[0] := Char(Sizeof(ScalePortData.S80_weight));
       Val(WgtStr,TempWt,Dummy);
       IF (Dummy <> 0) THEN
        BEGIN
         { Leave GrossWt at 0.0 }
         ScaleWtErr := Weight_Not_Yet_Recieved; { stop caller using weight returned }
        END
       ELSE
        BEGIN
         IF (ScalePortData.S80_Sign = Ord('-')) THEN
           GrossWt := -TempWt
         ELSE
           GrossWt := TempWt;
         ScaleWtErr := 0;  { clear default error code }
    (*
         IF (ScalePortData.S80_Sign = Ord('-')) THEN
          TheWeight := -TempWt
         ELSE
          TheWeight := TempWt - TareWeight;
         TheWeight := Round(TheWeight*1000)/1000;
         IF TheWeight < 0.0 THEN TheWeight := 0.0;
         IF ((WinType AND WT_Visable) = 0) AND (ScaleWtErr = 0)THEN
          BEGIN
           ScaleWtErr := Scale_Not_Visable;
          END
         ELSE
          BEGIN
           ShowWeight(TheWeight);
          END
    *)
        END;
      END; {Case System80}

     TLucid : BEGIN
       IF (ScalePortData.LUC_Sign IN [Ord('O'),ORD('U')]) THEN
        BEGIN
         ScaleWtErr := Scale_Not_In_Range;
        END
       ELSE IF (ScalePortData.LUC_Sign = Ord('-')) THEN
        BEGIN
         ScaleWtErr := Weight_Negative;
        END
       ELSE IF (ScalePortData.LUC_Status1 = Ord('M')) THEN
        BEGIN
         ScaleWtErr := Scale_In_Motion;
        END;

    {
        IF (ScalePortData.LUC_Status4 <> ORD('R')) THEN
        BEGIN
         IF (ScalePortData.LUC_Status4 <> ORD('Z')) THEN
          BEGIN
           IF (ScalePortData.LUC_Status4 = ORD('M')) THEN
            ScaleWtErr := Scale_In_Motion
           ELSE
            ScaleWtErr := Weight_Not_Valid;
          END
        END
       ELSE IF (ScalePortData.LUC_Status1 = Ord('M')) THEN
        BEGIN
         ScaleWtErr := Scale_In_Motion;
        END;
    }
       Move(ScalePortData.LUC_Weight,WgtStr[1],Sizeof(ScalePortData.LUC_weight));
       WgtStr[0] := #6;{char(Sizeof(ScalePortData.LUC_weight));}
       Val(WgtStr,WgtLng,Dummy);
       IF Dummy <> 0 THEN
        BEGIN
         { Leave GrossWt at 0.0 }
         ScaleWtErr := Weight_Not_Yet_Recieved; { stop caller using weight returned }
        END
       ELSE
        BEGIN
         TempWt := FPLong_To_Double(WgtLng,(ScalePortData.LUC_NoDP-ORD('0')));
         IF (ScalePortData.LUC_Sign = Ord('-')) THEN
           GrossWt := -TempWt
         ELSE
           GrossWt := TempWt;
         ScaleWtErr := 0; { clear default error code }

    (*
         IF (ScalePortData.LUC_Sign = Ord('-')) THEN
          TheWeight := -TempWt
         ELSE
          TheWeight := TempWt - TareWeight;
         TheWeight := Round(TheWeight*1000)/1000;
         IF TheWeight < 0.0 THEN TheWeight := 0.0;
         IF ((WinType AND WT_Visable) = 0) AND (ScaleWtErr = 0)THEN
          BEGIN
           ScaleWtErr := Scale_Not_Visable;
          END
         ELSE
          BEGIN
           ShowWeight(TheWeight);
          END
    *)
        END;
      END;
    END; {CASE}
  END;

 IF ScaleWtErr <> Weight_Not_Yet_Recieved THEN { round weight to 3 dp }
  BEGIN
   GrossWt := Round(GrossWt*1000)/1000;

   IF ((WinType AND WT_Visable) <> 0) THEN { display weight in window }
     ShowWeightNetOfTare(GrossWt)

   ELSE IF (ScaleWtErr = 0) THEN { if no other error, return not_visible }
     ScaleWtErr := Scale_Not_Visable;
  END;

 GetScaleGrossWeight := ScaleWtErr;
(*
 IF  (InitialContainerTare <> 0.0)
 AND WtIsAcceptableToContinueTare(TempWt,ScaleWtErr)
 AND (SelRecs.WorkHRecord.WOH_MixType IN MixSet_AutoCancelOfTares) THEN
   BEGIN
    MessageWin.ClearMsg;
    MessageWin.DisplayMsg('Tare Wt Auto Cancelled',FALSE);
   { BarsWindow^.ClearMainBar;}
    CRT.Delay(1000);
    TheWeight  := TheWeight + TareWeight;
    TareWeight := 0.0;
    InitialContainerTare:= 0.0;
    TareButton^.ResetTareAdjustment;
   END;
*)
END; {GetScaleGrossWeight}

PROCEDURE TScaleWindow.RefreshWt;
VAR GrossWt    : DOUBLE;
    ScaleError : INTEGER;
BEGIN
 IF IsWindowVisable
 OR (ScaleHardware[ReadingScale].SH_ScaleType = TNoScale) THEN
  BEGIN
   ScaleError := GetScaleGrossWeight(GrossWt);
   IF  (ScaleHardware[ReadingScale].SH_ScaleType = TNoScale)
   AND (GrossWtWin <> NIL) THEN
     GrossWtWin^.DrawGrossWt(DoubleToStr(GrossWt,7,ScaleParameters.NumDecimal));

   IF IsWindowVisable THEN
     WeighProcessController.WeightUpdate(ScaleError, GrossWt, (GrossWt-TareWeight));
(*
   IF  (ReadScale)        { eg not waiting for tare to be set }
   AND (NOT OnAStepProcess) THEN
    BEGIN
     BarsWindow^.ShowWeightIfValid(Wt,ScaleError,ReadScale);
    END
   ELSE
    BEGIN
     BarsWindow^.ShowWeightIfValid(0.0,ScaleError,ReadScale);
    END;
*)
  END;
END;

(*
{============================================================================}
{         Get Tare Wt Task                                                   }
{============================================================================}
PROCEDURE TGetTareWt.Execute;
BEGIN
 {Set new tare wt}
 IF  (TareNotSet)
 AND (NOT NoIngredientSelected) THEN
  BEGIN
   {ScaleWindow^.SetAutoTareWtOfContainer;}
   WaitForZeroWt^.EnableTask;
   DisableTask;
  END;
END;
{============================================================================}
{         Cancel Tare Weight                                                 }
{============================================================================}
PROCEDURE TCancelTareWt.Execute;
VAR ScaleError : INTEGER;
    Wt         : DOUBLE;
BEGIN
 MessageWin.DisplayMsg('Remove Container From Scale',TRUE);
 ScaleError := ScaleWindow^.WaitForScaleWt(Wt);
 IF ScaleError = 0 THEN
  BEGIN
   IF WtIsAcceptableToContinueTare(Wt,ScaleError) THEN
    BEGIN
     DisableTask;
     IF NOT (ScaleError IN [Scale_Not_Activated,Scale_Not_There]) THEN
      BEGIN
       GetTareWt^.EnableTask;
       TareButton^.ResetTareAdjustment;
      END;
    END;
  END;
END;
*)

{============================================================================}
{         Flashing Semi Auto Tare                                            }
{============================================================================}
CONSTRUCTOR TFlashSemiAutoTare.Init;
begin
(* stopped := false;*)
 inherited init(TRUE);
end;

(*
procedure TFlashSemiAutoTare.autostop;
begin
 stopped := true;
end;

procedure TFlashSemiAutoTare.autostart;
begin
 stopped := false;
end;
*)

PROCEDURE TFlashSemiAutoTare.Execute;
VAR Wt : DOUBLE;
    FaceNo,
    CurrFaceNo : INTEGER;
BEGIN
(* if (stopped) then exit;*)
(*
 ScaleWindow^.GetScaleWeight(Wt);                           {Needed To Display Current Wt}
*)

 CurrFaceNo := Scalewindow^.TareButton^.GetFace;
 IF CurrFaceNo IN [FACE_SEMI_AUTO_TARE, FACE_SEMI_AUTO_TARE_INVERTED] THEN
  BEGIN
   IF ((GetTickCount DIV 8) AND 1) = 0 THEN
     FaceNo := FACE_SEMI_AUTO_TARE
   ELSE
     FaceNo := FACE_SEMI_AUTO_TARE_INVERTED;

   IF FaceNo <> CurrFaceNo THEN
     ScaleWindow^.TareButton^.SetFace(FaceNo);
  END;
END;

(*
{============================================================================}
{         Zero Scale Task                                                    }
{============================================================================}
PROCEDURE TZeroScale.Execute;
VAR ScaleError : INTEGER;
    Wt : DOUBLE;
BEGIN
 IF (ScaleWindow^.ScaleActivated) THEN
  BEGIN
   ScaleWindow^.TareWeight  := 0.0;
   ScaleWindow^.InitialContainerTare := 0.0;
   ScaleError := ScaleWindow^.GetScaleWeight(Wt);
{ not sure this is right - I can accept weight on fixed wt prods before zero
   NoWeighingsAllowed := NOT WtIsAcceptableToContinueTare(Wt,ScaleError);
   IF NOT NoWeighingsAllowed THEN
    BEGIN
     DisableTask;
     IF (WaitForZeroWt^.Active) OR (WaitForNonZeroWt^.Active) THEN
       PrimeNextIngredient(NP_MultiSel);
     TareButton^.ResetTareAdjustment;
    END;
}
   NoWeighingsAllowed := TRUE;
   IF WtIsAcceptableToContinueTare(Wt,ScaleError) THEN
    BEGIN
     DisableTask;
     IF NOT ((WaitForZeroWt^.Active) OR (WaitForNonZeroWt^.Active)) THEN
       NoWeighingsAllowed := FALSE;
     TareButton^.ResetTareAdjustment;
    END;
  END;
END;
{============================================================================}
{         Wait For Zero WT Task                                              }
{============================================================================}
PROCEDURE TWaitForZeroWt.Execute;
VAR ScaleError : INTEGER;
    Wt : DOUBLE;
BEGIN
 IF (ZeroScale^.Active) THEN ZeroScale^.DisableTask;
 IF UserWantsToQuit
 OR (NOT TareNotSet) THEN { tare has been set - dont need to wait for zero }
  BEGIN
   WaitForZeroWt^.DisableTask;
   ZeroScale^.DisableTask;
   MessageWin.ClearMsg;
  END
 ELSE IF NOT DisregardWaitForScaleToZero THEN
  BEGIN
   ScaleError := ScaleWindow^.GetScaleWeight(Wt);
   IF WtIsAcceptableToContinueTare(Wt,ScaleError) THEN
    BEGIN
     WaitForZeroWt^.DisableTask;
     ZeroScale^.DisableTask;
     IF (SelRecs.TareIngredient) THEN
      BEGIN
       WaitForNonZeroWt^.EnableTask;
      END
     ELSE
      BEGIN
       NoWeighingsAllowed := FALSE;
       TareNotSet := {NOT TareNotSet} FALSE;
       GetTareWt^.DisableTask;
       FlashSemiAutoTare^.DisableTask;
     {  BarsWindow^.ClearMainBar;}
      END;
     MessageWin.ClearMsg;
    END
   ELSE IF (ScaleError = Weight_Negative) THEN
     MessageWin.DisplayMsg('Waiting For Scale To Be Zeroed.',TRUE)
   ELSE
     MessageWin.DisplayMsg('Waiting For Scale To Zero. Remove Any Weight From Scale',TRUE);
  END
 ELSE { tare not set but zero not reqd first }
  BEGIN
   WaitForZeroWt^.DisableTask;
   ZeroScale^.DisableTask;
   WaitForNonZeroWt^.EnableTask;
   MessageWin.ClearMsg;
  END;
END;
{============================================================================}
{         Wait For Non Zero WT                                               }
{============================================================================}
PROCEDURE TWaitForNonZeroWt.Execute;
VAR ScaleError : INTEGER;
    Wt : DOUBLE;
BEGIN
 IF WaitForZeroWt^.Active THEN
  BEGIN
   WaitForZeroWt^.DisableTask;
   MessageWin.ClearMsg;
  END;
 MessageWin.DisplayMsg('Place Container On Scale And Press Semi Auto Tare',TRUE);
 ScaleError := ScaleWindow^.WaitForScaleWt(Wt);
 IF Wt >0.0 THEN
  IF ((ScaleError = No_Scale_Error) OR (ScaleError = Scale_In_Motion)) AND
    (Wt>=0.0) THEN
   BEGIN
    WaitForNonZeroWt^.DisableTask;
    MessageWin.ClearMsg;
    MessageWin.DisplayMsg('Press Semi Auto Tare To Accept Tare',TRUE);
    TareButton^.WaitForTare;
    NoWeighingsAllowed := FALSE;
   END;
END;
*)

{------------------------------------------------------------------------}
CONSTRUCTOR TWeighProcessController.Init;
BEGIN
 WPC_IgnoreScale := FALSE;
 WPC_OrderNo := 0;
 WPC_Revision:= 0;
 WPC_MixNo   := 0;
 WPC_LineNo  := 0;
 WPC_ContNo  := 0;
 WPC_TareOk  := FALSE;
 WPC_CurrentOp := ws_RemoveCont;
 SetCurrentOpTo(ws_RemoveCont);
 { make sure bars window is enabled - bad code might have stopped it
   but not switched it back on }
 BarsWindow^.EnableDraw(TRUE);
END;

DESTRUCTOR TWeighProcessController.Done;
BEGIN
END;

FUNCTION TWeighProcessController.ValidOp(OpID : TWeighingStep) : BOOLEAN;
BEGIN
 ValidOp := TRUE;

 CASE OpID OF
     {
     ws_PlaceCont :
         Regardless of SelRecs.TareIngredient, PlaceCont op only gets
         completed by scale weight reading.
     }

     ws_TareCont :
      BEGIN
       IF WPC_TareOk THEN { container doesnt need taring }
         ValidOp := FALSE;
      END;

     {
     ws_AddIngred : add ingredient always required
     }

     {
     ws_RemoveCont:
         this state can only be reached outside this procedure
         if acked to do it - do it
     }
    END;
END;

PROCEDURE TWeighProcessController.SetCurrentOpTo(Operation : TWeighingStep);
BEGIN
 IF Operation <> WPC_CurrentOp THEN
  BEGIN
   { tidy last step up }
   CASE WPC_CurrentOp OF
    {ws_PlaceCont :}
    {ws_TareCont  :}
     ws_AddIngred : BEGIN
                     BarsWindow^.ClearMainBar;
                     MsgReader^.EnableTask;
                    END;
    {ws_RemoveCont:}
    END;
  END;

 WPC_CurrentOp := Operation;

 IF ValidOp(WPC_CurrentOp) THEN  { initialise/re-init process for new step }
  BEGIN
{$IFNDEF NOPARTWEIGH}
   ScaleWindow^.PartialWtBtn^.MakeInActive;
{$ENDIF}

   CASE WPC_CurrentOp OF
       ws_PlaceCont  : ScaleWindow^.TareButton^.MakeNormalTareActive;
       ws_TareCont   : ScaleWindow^.TareButton^.MakeFlashingTareActive; { flashes until hit then
                                                           changes to 'Cancel Tare'}
       ws_AddIngred  : BEGIN
                        MsgReader^.DisableTask;
                        MessageWin.ClearMsg; { remove any "... is complete" msgs }
{$IFNDEF NOPARTWEIGH}
                        IF SelRecs.SR_IngredientType = PTWeight THEN
                          ScaleWindow^.PartialWtBtn^.MakeActive;
                          { note: fixed weight items have their label wt
                            added to line wt done - not actual wt, therfore
                            cant allow under-tol counts }
{$ENDIF}
                       END;
       ws_RemoveCont : BEGIN
                        ScaleWindow^.ClearScaleTareWt;
                        { so user can see true weight on touch screen }
                        { and not 0.0 when net is actually negative   }

                        { If containers are being tared by this program
                          instead of at the indicator,
                          give user the chance to add next ingredient to same
                          container by hitting tare button. }
                        IF SelRecs.TareIngredient THEN
                          ScaleWindow^.TareButton^.MakeNormalTareActive;
                         { so user can jump past removal and replacement of cont}
                       END;
    END;
  END;
END;

PROCEDURE TWeighProcessController.StepOverInvalidOps(StartingFromOp : TWeighingStep);
VAR NextOpReqd : TWeighingStep;
BEGIN
 NextOpReqd := StartingFromOp;

 REPEAT
   IF ValidOp(NextOpReqd) THEN
     BREAK;
    {*****}

   { op isnt required - inc to next op }
   IF NextOpReqd = ws_RemoveCont THEN
     NextOpReqd := ws_PlaceCont
   ELSE
     NextOpReqd := Succ(NextOpReqd);

 UNTIL (NextOpReqd = StartingFromOp); { no valid ops - break out }

 SetCurrentOpTo(NextOpReqd);
END;


PROCEDURE TWeighProcessController.WeighingSelected(
                                            ContNoForLineInMix : LONGINT;
                                            NoOfContainersReqd  : LONGINT);
VAR WeighInDiffContainer : BOOLEAN;
BEGIN
 { Does this selection mean a container change ? }
 WeighInDiffContainer := FALSE;
 IF SelRecs.SR_IngredientType = PTWeight THEN
  BEGIN
   WITH SelRecs.WorkHRecord,SelRecs.WorkLRecord DO
    BEGIN
     IF (WOH_OrderNo    <> WPC_OrderNo)
     OR (WOH_Revision   <> WPC_Revision)
     OR (WOH_CurrentMix <> WPC_MixNo) THEN
       WeighInDiffContainer := TRUE;

     IF (WOH_MixType IN MixSet_AutoTareAfterWeighing) THEN
      BEGIN { container has been tared off - only works if no.of conts = 1 }
       IF NoOfContainersReqd > 1 THEN { they will have to be segregated }
         WeighInDiffContainer := TRUE;
      END
     ELSE { last container hasnt been autotared }
      BEGIN
       IF WOH_MixType IN MixSet_ProportionallyMixedConts THEN{ Only weighings with same     }
        BEGIN                                      { contr number go in same contr}
         IF  (ContNoForLineInMix <> WPC_ContNo) THEN
           WeighInDiffContainer := TRUE;
        END
       ELSE   { NOT AutoTared and NOT Proportionally mixed containers }
        BEGIN { Assume ingredients should be segregated }
         IF (WOL_LineNo <> WPC_LineNo)
         OR (ContNoForLineInMix <> WPC_ContNo) THEN
           WeighInDiffContainer := TRUE;
        END;
      END;
    END;
  END;

 StepOverInvalidOps(WPC_CurrentOp); { current op may no longer be required }

 { Update state of process }
 CASE WPC_CurrentOp OF
   ws_PlaceCont : BEGIN END; { container still reqd }

   ws_TareCont,
   ws_AddIngred : BEGIN { a container is probably on the scale }
                   IF WeighInDiffContainer THEN { need to remove current cont }
                     SetCurrentOpTo(ws_RemoveCont);
                   {ELSE carry on taring or waiting for ingredient }
                  END;

   ws_RemoveCont: BEGIN { a container is probably on the scale and hasn't
                          been autotared therefore we should still wait for
                          container to be removed and the tare auto-cancelled
                        }
                  END;
  END;

 { Update weighing identity vars }
 WITH SelRecs.WorkHRecord,SelRecs.WorkLRecord DO
  BEGIN
   WPC_OrderNo  := WOH_OrderNo;
   WPC_Revision := WOH_Revision;
   WPC_MixNo    := WOH_CurrentMix;
   WPC_LineNo   := WOL_LineNo;
   WPC_ContNo   := ContNoForLineInMix;
   IF  (WeighInDiffContainer) THEN { any tare done is now invalid }
     WPC_TareOk := FALSE;  { WILL ALWAYS HAPPEN ON FIRST WEIGHING }
                           { SELECTED FOR A MIX }
  END;
END;

PROCEDURE TWeighProcessController.WeightUpdate(ScaleError : INTEGER;
                                               GrossWt, NetWt : DOUBLE);
{ Weigh process responses to scale weight readings }
BEGIN
 IF WPC_IgnoreScale THEN EXIT;
                    {****}

 IF GetNonDisabledButton <> NIL THEN { modal button active }
   EXIT;
  {****}
 IF NoIngredientSelected THEN { usefull place to redisplay 'Select ..' msg }
  BEGIN
   IF OrderComplete(SelRecs.WorkHRecord) THEN
     MessageWin.DisplayMsg('Order Is Complete',FALSE)

   ELSE IF (SelectableElementsInList > 0)
       AND (NOT SelRecs.WorkHRecord.WOH_SeqFixed) THEN
     MessageWin.DisplayMsg('Select An Ingredient From The List Below',FALSE);
   EXIT; { WPC_CurrentOp stays where it is when no ingredient selected }
  {****}
  END;

 IF WPC_CurrentOp = ws_PlaceCont THEN { has this been done now? }
  BEGIN
   IF SelRecs.TareIngredient THEN { container needs to be tared by this program }
    BEGIN
     IF  (ScaleError IN [0,Scale_In_Motion])
     AND (GrossWt >= MinContWtOnCurrScale) THEN { container is on scale }
      BEGIN
       StepOverInvalidOps(Succ(WPC_CurrentOp));
      END
     ELSE
       MessageWin.DisplayMsg('Place Container On Scale And Press Semi Auto Tare',FALSE);
    END
   ELSE { container probably tared on scale indicator }
    BEGIN
(*   wt from indicator might already include the tare of
     the container and so will go negative between weighings.

     IF  (ScaleError IN [0,Scale_In_Motion])  { eg not negative }
     AND (NetWt < MinContWtOnCurrScale)
     AND (NetWt > (-MinContWtOnCurrScale)) THEN { acceptable start weight for adding ingred }
      BEGIN
       WPC_TareOK    := TRUE;
       StepOverInvalidOps(Succ(WPC_CurrentOp));
      END
     ELSE
       MessageWin.DisplayMsg('Scale needs to be at zero',FALSE);
    END;
*)
     IF ((ScaleError IN [0,Scale_In_Motion]) AND (NetWt < MinContWtOnCurrScale))
     OR (ScaleError = Weight_Negative) THEN { acceptable start weight for adding ingred }
      BEGIN
       WPC_TareOK    := TRUE;
       StepOverInvalidOps(Succ(WPC_CurrentOp));
      END
     ELSE
       MessageWin.DisplayMsg('Scale needs to be near zero',FALSE);
    END;
  END;

 IF WPC_CurrentOp = ws_TareCont THEN
   MessageWin.DisplayMsg('Press Semi Auto Tare To Accept Tare',FALSE);

 IF WPC_CurrentOp = ws_AddIngred THEN
  BEGIN
   IF  (NOT Config_Rec^.CONF_NoAutoCancelOfTares)
   AND (SelRecs.WorkHRecord.WOH_MixType IN MixSet_AutoCancelOfTares)
   AND (ScaleWindow^.TareWtExists)
   AND (ScaleError IN [0,Scale_In_Motion,Weight_Negative])
   AND ((GrossWt < MinContWtOnCurrScale) OR (NetWt < (-MinContWtOnCurrScale))) THEN
    BEGIN
     ScaleWindow^.ClearScaleTareWt; { will call TareCancelled in this object }
     EXIT;
    {****}
    END;

   IF SelRecs.SR_IngredientType = PTStep THEN
     BarsWindow^.ShowWeightIfValid(0.0,ScaleError,TRUE)
   ELSE
     BarsWindow^.ShowWeightIfValid(NetWt,ScaleError,TRUE);
  END;

 IF WPC_CurrentOp = ws_RemoveCont THEN
  BEGIN
   IF  (ScaleError IN [0,Scale_In_Motion,Weight_Negative])
   AND (GrossWt < MinContWtOnCurrScale) THEN
    BEGIN
     WPC_TareOK    := FALSE;
     StepOverInvalidOps(ws_PlaceCont);
    END
   ELSE
    BEGIN
     IF ScaleWindow^.TareButton^.IsWindowSelectable THEN
       MessageWin.DisplayMsg('Remove Container from Scale  or  Semi-Auto Tare',
                             FALSE)
     ELSE
       MessageWin.DisplayMsg('Remove Container from Scale',
                             FALSE);
    END;
  END;
END;

PROCEDURE TWeighProcessController.ATareWtHasBeenSet;
BEGIN
 IF NoIngredientSelected THEN { usefull place to redisplay 'Select ..' msg }
   EXIT; { WPC_CurrentOp stays where it is when no ingredient selected }
  {****}

 CASE WPC_CurrentOp OF
   ws_RemoveCont,{ included so manual tare wt entry skips cont removal detection }
   ws_PlaceCont, { included so manual tare wt entry skips place cont detection }
   ws_TareCont,
   ws_AddIngred : BEGIN
                   SetCurrentOpTo(ws_AddIngred);
                   WPC_TareOk    := TRUE;
                  END;
   {else do nothing}
  END;
END;

PROCEDURE TWeighProcessController.TareCancelled;
BEGIN
 IF NoIngredientSelected THEN { usefull place to redisplay 'Select ..' msg }
   EXIT; { WPC_CurrentOp stays where it is when no ingredient selected }
  {****}

 CASE WPC_CurrentOp OF
   ws_PlaceCont,
   ws_TareCont  : BEGIN END; { container still reqd }

   ws_AddIngred : BEGIN { user is going to have to tare/re-tare container }
                   WPC_TareOk := FALSE;
                   SetCurrentOpTo(ws_PlaceCont);
                  END;

   ws_RemoveCont: BEGIN END; { ignore tare removal }
  END;
END;

PROCEDURE TWeighProcessController.IngredWeightAccepted;
VAR
   ScaleBeenAutoTared : BOOLEAN;
BEGIN
 ScaleBeenAutoTared := FALSE;
 WITH SelRecs.WorkHRecord DO
  BEGIN
   IF WOH_MixType IN MixSet_AutoTareAfterWeighing THEN
    BEGIN
     { need to tare it at current weight (tran weight could be manual entry).}
     ScaleBeenAutoTared := ScaleWindow^.SetTareAtCurrentWeight = 0;
     { note: SetTareAtWeight (if successful) will call ATareWtHasBeenSet }
     {       method and therefore set op to AddIngred                    }
    END;

   IF NOT ScaleBeenAutoTared THEN
    BEGIN
     SetCurrentOpTo(ws_RemoveCont); { removal detection looks at gross wt }
    END;
  END;
END;

{-------------------------------------------------------------------------}





PROCEDURE SwitchOffScaleTasks; { ??????????? }
BEGIN
(*
 GetTareWt^.DisableTask;
 CancelTareWt^.DisableTask;
*)
 IF Assigned(FlashSemiAutoTare) THEN FlashSemiAutoTare^.DisableTask;
(*
 ZeroScale^.DisableTask;
 WaitForZeroWt^.DisableTask;
 WaitForNonZeroWt^.DisableTask;
*)
 IF Assigned(BarsWindow) THEN BarsWindow^.EnableDraw(FALSE);
 WeighProcessController.WPC_IgnoreScale := TRUE;
END;

PROCEDURE StopScaleTasks(VAR ScaleTaskState : TScaleTaskState);
BEGIN
 FillChar(ScaleTaskState, SizeOf(ScaleTaskState), 0);
 WITH ScaleTaskState DO
  BEGIN
(*
   GetTareWtActive          := FALSE; {GetTareWt^.Active;}
   CancelTareWtActive       := FALSE; {CancelTareWt^.Active;}
   ZeroScaleActive          := FALSE; {ZeroScale^.Active;}
   WaitForZeroWtActive      := FALSE; {WaitForZeroWt^.Active;}
   WaitForNonZeroWtActive   := FALSE; {WaitForNonZeroWt^.Active;}
*)
   IF FlashSemiAutoTare <> NIL THEN
     FlashSemiAutoTareActive  := FlashSemiAutoTare^.Active;

   IF BarsWindow <> NIL THEN
     BarsWindowDrawActive     := BarsWindow^.IsDrawingEnabled;

   ProcessControllerActive  := NOT WeighProcessController.WPC_IgnoreScale;
  END;

 SwitchOffScaleTasks;
END;

PROCEDURE RestoreScaleTasks(ScaleTaskState : TScaleTaskState);
BEGIN
 WITH ScaleTaskState DO
  BEGIN
(*
   GetTareWt^.SetActive(GetTareWtActive);
   CancelTareWt^.SetActive(CancelTareWtActive);
*)
   IF FlashSemiAutoTare <> NIL THEN
     FlashSemiAutoTare^.SetActive(FlashSemiAutoTareActive);
(*
   ZeroScale^.SetActive(ZeroScaleActive);
   WaitForZeroWt^.SetActive(WaitForZeroWtActive);
   WaitForNonZeroWt^.SetActive(WaitForNonZeroWtActive);
*)
   IF BarsWindow <> NIL THEN
     BarsWindow^.EnableDraw(BarsWindowDrawActive);

   WeighProcessController.WPC_IgnoreScale := NOT ProcessControllerActive;
  END;
END;

PROCEDURE TaskInit;
BEGIN
(*
 New(GetTareWt,Init);
 New(CancelTareWt,Init);
*)
 New(FlashSemiAutoTare,Init);
(*
 New(ZeroScale,Init);
 New(WaitForZeroWt,Init);
 New(WaitForNonZeroWt,Init);
*)
 SwitchOffScaleTasks;
END;

FUNCTION MainScaleInit : BOOLEAN;
VAR I : INTEGER;
BEGIN
 MainScaleInit := TRUE;
 New(ScaleWindow,Init);
{
 ScaleFont    := CreateFont(3,3,HORIZ,FONT_8X16,FontNormal);
}
{ ScaleWindow^.HideWindow;}
 ScaleWindow^.ChangeWindowFont(DoubleSizeFont);
 {
 ScaleWindow^.ChangeWindowFont(ScaleFont);
 }
 MainScaleInit := ScaleCommsInit; {In SFXComms}
 FOR I := Low(ScaleHardware) TO High(ScaleHardware) DO
  BEGIN
   IF ScaleHardware[I].SH_ScaleType = TNoScale THEN
    BEGIN
     WtSimulator := New(PWtSimulator,Init);
     ScaleWindow^.ScaleActivated := TRUE;
     BREAK;
    END
  END;

 IF ScaleWindow^.ScaleActivated THEN
   ScaleWindow^.ScaleActivated := NOT ScaleWindowTimeOutError;

 IF NOT ScaleWindow^.ScaleActivated THEN WriteStrAt(0,14,'Scale Is Not Responding');
{$IFDEF DEBUG}
 WriteStr('No Scale Comms');
{$ENDIF}
END;

PROCEDURE MainScaleDone;
BEGIN
 ScaleCommsDone;
 IF ScaleWindow <> NIL THEN Dispose(ScaleWindow,Done);
{ IF ScaleFont   <> NIL THEN DeleteFont(ScaleFont);}
 ScaleWindow := NIL;
{ ScaleFont := NIL;}
 IF WtSimulator <> NIL THEN Dispose(WtSimulator);
 WtSimulator := NIL;
END;




END.

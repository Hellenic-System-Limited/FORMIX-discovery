(****************************************************************************
*  UNIT          : FXFRCP                                                   *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Routines To Display Recipe Information      *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT DispRec;

{
 This Unit Will Display Orders and Recipe Details In The Scrolling Window
 Provided
}
INTERFACE
USES CRT,FXModCTV,F6StdCtv,F6StdWn1,FXFWork,FX_Msg,SFXGraph,SFXFGen,SFXMixes,SFXEvent,SFXMENU,
     SFXConst,SFXWin,SFXStdBt,SFX_Scrl,SFXStd,SFXBtn,SFX_Main,SFXScale,SFXMsg,
     SFXTrans,SFXUtils,SFXOList,SFXComms,SFXEdit,FXStdUt1,SFX_Bars,FXChoice,
     SFXTime,SFXDate,SFXlog,F6StdUtl,SfxCurr,SFXBMAP,FXFUsers,FXCfg;


CONST HeaderIsShowing = FALSE;
      LineIsShowing   = TRUE;



PROCEDURE MainProc;


IMPLEMENTATION
USES SFXCOLR;
(*
TYPE PCompleteWin = ^TCompleteWin;
     TCompleteWin = OBJECT(TParentWindow)
      OKBtn : PChoiceBtn;
      Cont  : INTEGER;

      CONSTRUCTOR Init;
      FUNCTION UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
      PROCEDURE Draw;Virtual;
      PROCEDURE ReceiveMsg(Msg : INTEGER);VIRTUAL;
      DESTRUCTOR Done;VIRTUAL;
     END;
*)
TYPE PRetToOrder = ^TRetToOrder;
     TRetToOrder = OBJECT(TPCXButton)
      FUNCTION UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
      {PROCEDURE Draw;Virtual;}
     END;


VAR    QuitBox            : PPCXSwitchWindow;
       RetToOrder         : PRetToOrder;
       BreakLineSelect : BOOLEAN;
(*
       CompleteWinShowing : BOOLEAN;
*)
{RETURN TO ORDER DISPLAY METHODS}
FUNCTION TRetToOrder.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 BreakLineSelect := TRUE;
 UserActivateFunction := TRUE;
END;



(*
PROCEDURE TRetToOrder.Draw;
BEGIN
 DisplayText(1,'Return To'+CRLF+'Orders List');
END;
*)

(*
{ORDER IS COMPLETE METHODS}
PROCEDURE TCompleteWin.ReceiveMsg(Msg : INTEGER);
BEGIN
 Cont := Msg;
END;

FUNCTION TCompleteWin.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 ActivateIfInAChildWindow(X,Y);
 UserActivateFunction := Cont=1;
END;

CONSTRUCTOR TCompleteWin.Init;
BEGIN
 CompleteWinShowing := TRUE;
 INHERITED Init(200,200,200+30*8,220+56+LargeChildHeight,C_WindowStaticText SHR 4,StdWin);
 Cont :=0;
 DisableAllButtonsExceptMe;
 WITH Bounds DO
  New(OKBtn,Init((Left+Right) DIV 2-(LargeChildWidth DIV 2),Bottom-10-LargeChildHeight,@Self,1,CRLF+'    OK',TRUE));
 RetToOrder^.WinType := RetToOrder^.WinType AND (NOT WT_AlwaysActive);
END;

DESTRUCTOR TCompleteWin.Done;
BEGIN
 CompleteWinShowing := FALSE;
 INHERITED Done;
END;

PROCEDURE TCompleteWin.Draw;
BEGIN
 ScaleWindow^.HideWindow;
 WriteHeader('Order Complete');
END;

*)

PROCEDURE Lose_Visable_Windows;
BEGIN
{ DateWindow.HideWindow;}                 {Hide Constant windows}
{ TimeWindow.HideWindow;}
 MessageWin.DisableMsgs(NIL);
 ScaleWindow^.HideWindow;
 Lose_Windows_In_Visable_List;
 ClrGraphWin; { get rid of "weight remaining figure drawn outside of a win }
 ShowVersionNo;
END;


PROCEDURE DisplayOpSelectWindows;
BEGIN
 MessageWin.DisableMsgs(NIL);
 {DateWindow.ShowWindow;}
 New(UserWindow,Init(NIL));
 SetUpScrollerWindows(HeaderIsShowing);

 New(QuitBox,     Init(OpBrowser_LX, OpButtonTop,
                       OpBrowser_LX+ButtonSz, OpButtonBot,
                       StdBtn,'EXIT.PCX',@UserWantsToQuit));
 WITH QuitBox^.Bounds DO
   New(MainMenu,  Init(Right+ButtonSc, OpButtonTop,
                       Right+ButtonSc+ButtonSz, OpButtonBot,
                       StdBtn,'SETUPM.PCX'));
 WITH MainMenu^.Bounds DO
   New(DateBack,  Init(Right+ButtonSc, OpButtonTop,
                       Right+ButtonSc+ButtonSz, OpButtonBot,
                       FALSE,'DATEMIN.PCX'));
 WITH DateBack^.Bounds DO
   New(DateForward,Init(Right+ButtonSc, OpButtonTop,
                       Right+ButtonSc+ButtonSz, OpButtonBot,
                       TRUE,'DATEPLU.PCX'));
END;

(*
PROCEDURE DisplayCompleteWindow;
VAR CompleteWindow : PCompleteWin;
BEGIN
 NEW(CompleteWindow,Init);
 SendMessage(PCID,ResetTWOBRW);
END;
*)

PROCEDURE Display_Line_Select_Window;
VAR TempAddWtErr : INTEGER;
BEGIN
{ NoIngredientSelected := TRUE;}
{ LineNoSelected       := 1;}
 BreakLineSelect := FALSE;
 MessageWin.EnableAtMidScreen(NIL);
{ TimeWindow.ShowWindow;}

(* header now loaded when order selected - see scroller UserActivateFunction
 SelRecs.LoadHeaderRecord(SelRecs.WorkHRecord.WOH_OrderNo,
                          SelRecs.WorkHRecord.WOH_Revision);

*)
 New(UserWindow,Init(NIL));
 SetUpScrollerWindows(LineIsShowing);
 SetMainScreen;
 ScaleWindow^.ShowWindow;
(*
 New(ListBoxLeft, Init(But1Start,ButtonTop,But1Stop,ButtonBot,FALSE,TRUE));
*)
 IF ReturnToOrderOn THEN
  New(RetToOrder,  Init(But2Start,ButtonTop,But2Stop,ButtonBot,
                        StdBtn {OR WT_AlwaysActive},'EXIT.PCX'));
(* IF NOT ScaleWindow^.ScaleActivated THEN *)

(*
 New(TareButton,Init(But3Start,ButtonTop,But3Stop,
                   ButtonBot,WT_Border OR WT_Shadow OR  WT_Button,
                   'SAUTO1.PCX','SAUTO2.PCX','SAUTO3.PCX'));
*)
(* ELSE
  New(SemiAutoTare,Init(But3Start,ButtonTop,But3Stop,ButtonBot,StdBtn,
                   'SAUTO1.PCX','SAUTO2.PCX','SAUTO3.PCX'));
 SemiAutoTare^.DisableButton; {DisableBtn(TRUE);}
*)
(*
 New(ListBoxRight,Init(ButR1Start,ButtonTop,ButR1Stop,ButtonBot,TRUE,TRUE));
*)

(* New(AbortMix,    Init(But4Start,ButtonTop,But4Stop,ButtonBot,
                         WT_Border OR WT_Shadow OR  WT_Button,'ABORT.PCX'));*)

 IF AdvancedOptionsOn THEN
  New(AdvOptWin,   Init(But5Start,ButtonTop,But5Stop,ButtonBot,StdBtn,'OPTIONS.PCX'));
{ New(QuitBox,     Init(But2Start,ButtonTop,But2Stop,ButtonBot,@UserWantsToQuit));}
{ New(NextMix,     Init(But3Start,ButtonTop,But3Stop,ButtonBot,StdBtn));}
{ New(DisplayOrder,Init(But5Start,ButtonTop,But5Stop,ButtonBot,StdBtn));}
{ New(EditBatch,   Init(But2Start,ButtonTop,But2Stop,ButtonTop,StdBtn));
  New(EditLot,     Init(But3Start,ButtonTop,But3Stop,ButtonTop,StdBtn));}

(* mix is now advanced when order is selected - see scroller UserActivatedFunc
 IF SelRecs.WorkHRecord.WOH_Status <> StatusCOMP THEN
  BEGIN
   IF PrintAndAdvanceMixIfComplete(FALSE) THEN { calls PrimeNextIngredient }
    BEGIN
*)
(*
     IF OrderComplete(SelRecs.WorkHRecord) THEN
       DisplayCompleteWindow;
*)
(*  END;
  END
 ELSE PrimeNextIngredient(NP_NewOrd);
*)
END;

PROCEDURE OperationSelectLoop;
{ User selects an order, a date range, setup menu button or exit button }
VAR
  OrderListPosSave : LONGINT;
  MixLabelBarcode  : STRING[12];
  KeyCh : CHAR;

  PROCEDURE AcceptSrcWtOrStartWeighing;
  BEGIN
   IF  Config_Rec^.CONF_AcceptLabelWeight
   AND SelRecs.SR_UseSourceWt THEN
     CreateTransaction(SelRecs.SR_CurrSourceWtKg,
                       SelRecs.WorkLRecord.WOL_ProcessType,
                       TRUE) {ManualWtEntry}
   ELSE
     WeighProcessController.WeighingSelected(
                                        MainWindow^.GetCurrentContainerNo,
                                        MainWindow^.GetContsReqdForIngredient);
  END;
  {----------}

BEGIN
(* CompleteWinShowing   := FALSE;*)
 NoIngredientSelected := TRUE;
 OrderListInit;
 OrderListPosSave    := 0;
 DisplayRecListPos   := 0;
 REPEAT
(*  ResetAllTasks;*)
  SelRecs.SetUp;
  DisplayOpSelectWindows;
  Display_Recipes_For_Date(TRUE);
  TimedOrderRefresh^.EnableTask;

  MixLabelBarcode := '';
  Flush_Keyboard_Buffer;
  REPEAT
   MessageWin.DisableMsgs(NIL);
   IF KeyWasPressed THEN
    BEGIN
     KeyCh := GetKey;
     IF ((NOT FuncKey) AND (KeyCh = ENTER))
     OR (KeyCh = CHR(STX)) THEN { enter key or scanner prefix }
      BEGIN
       MixLabelBarcode := '';
       GetStr(12,20,MIXBAR_LEN,(KeyCh <> CHR(STX)),
              'Mix Label Barcode:',MixLabelBarcode);
{       DateWindow.ShowDate;}
       IF ScrollerWindows^.SelectOrderViaMixLabelBarcode(MixLabelBarcode) THEN
         BREAK;
        {*****}
      END;
    END;
{   DateWindow.ShowDate;}
  {User Either Presses a recipe key,the date change key,Scroller or esc???}

  UNTIL (Wait_For_User_Input=TRUE) { may set 'UserWantToQuit' }
     OR UserWantsToQuit;

  { only gets to here if user exits or selects an order }
  { --------------------------------------------------- }
{$IFDEF DEBUGWIN}
  Beep(warbeep);
{$ENDIF}

  IF  (NOT UserWantsToQuit)
  AND (SelRecs.WorkHRecord.WOH_SchDate <> RecipeDay) THEN { scanner selected order}
   BEGIN
    RecipeDay := SelRecs.WorkHRecord.WOH_SchDate;
    DisplayRecListPos := 0;
   END;

  { Save current order scroller offset }
  { Note: use of date buttons will have set DisplayRecListPos to 0. }
  OrderListPosSave := DisplayRecListPos;

  { If Scroller button has been pressed then
    scroller UserActivateFunction will:
    a)  SelRecs header will be loaded
    b)  Current mix number will be reset
    c)  SelRecs line record will be cleared or set to last known line worked on.
  }

  TimedOrderRefresh^.DisableTask;
  Lose_Visable_Windows;
  IF NOT UserWantsToQuit THEN {User Pressed a Order Key}
   BEGIN
{$IFNDEF NOCOMMS}
    SwitchToDefaultScale;
{$ENDIF}
    DisplayRecListPos := 0;
    DisposeListRec;
    Display_Line_Select_Window; { displays 'MainWindow' aswell }
    WeighProcessController.Init;

    BuildLineRecipeList(@SelRecs.WorkHRecord,FALSE);{ Changes scroller list }
                                                    { to ingredients        }
(*
    IF NOT CompleteWinShowing THEN
     BEGIN
{    GetLotAndBatchNoIfNeeded(ScrollerWindows^.LineNumberHighlighted);}
{    SemiAutoTare^.ResetTareAdjustment;}
     END
    ELSE SetOrderToComplete;
*)
    PrimeNextIngredient(NP_NewOrd,'');

    Flush_Keyboard_Buffer;
    REPEAT
     IF UserWantsToQuit
     OR BreakLineSelect THEN BREAK;

     IF MainWindow^.DrawPending THEN { bars etc dont reflect latest selection }
       MainWindow^.Draw;     { eg. PrimeNextIngredient may auto loaded a line }

     IF MainWindow^.SelChgPending THEN { weighing setup needed }
      BEGIN
       IF NOT NoIngredientSelected THEN
        BEGIN
         IF MainWindow^.PreWeighingSetup THEN
           AcceptSrcWtOrStartWeighing
         ELSE
           BreakLineSelect := TRUE;
        END;
       Flush_Keyboard_Buffer;
      END;

     IF UserWantsToQuit
     OR BreakLineSelect THEN BREAK;

     { Note: If Scroller button has been pressed then SelRecs line will be }
     {       loaded by UserActivateFunction called by Wait_For_User_Input  }
     {       at bottom of loop.                                            }
     {Needs to get weight maybe}
     IF KeyWasPressed THEN Ch := GetKey
     ELSE Ch := #0;
     IF CH = CR THEN { wont happen first time - getkey hasnt been called }
      BEGIN
       { try to accept the current weight }
       BarsWindow^.UserActivateFunction(0,0); { eventually call PrimeNextIngredient }
       IF BarsWindow^.OrderComplete <> 0 THEN BREAK;
      END;

     IF UserWantsToQuit
     OR BreakLineSelect THEN BREAK;

     IF MainWindow^.DrawPending THEN { current ingredient details changed }
       MainWindow^.Draw;             { eg due to ingredient wt accepted   }

     IF MainWindow^.SelChgPending THEN { weighing setup needed }
      BEGIN
       IF NOT NoIngredientSelected THEN
        BEGIN
         IF MainWindow^.PreWeighingSetup THEN
           AcceptSrcWtOrStartWeighing
         ELSE
           BreakLineSelect := TRUE;
        END;
       Flush_Keyboard_Buffer;
      END;

     IF UserWantsToQuit
     OR BreakLineSelect THEN BREAK;
(*     IF SFXSTD.NoIngredientSelected THEN
      BEGIN
{$IFDEF FOPSTRACELINK}
       ScaleWindow^.PartialWtBtn^.MakeInActive; { hides and disables }
{$ENDIF}
       TareButton^.MakeInActive; { hides and disables }
      END;
*)
(*
     ELSE { ingredient is selected }
      BEGIN
{$IFDEF FOPSTRACELINK}
       IF TareNotset THEN { tare is required but not been set }
         PartialWtBtn^.MakeInActive { hides it aswell }
       ELSE
         PartialWtBtn^.MakeActive;
{$ENDIF}
       IF SelRecs.TareIngredient THEN
         SemiAutoTare^.ShowWindow    { visible but not active }
       ELSE
         SemiAutoTare^.MakeInActive; { hide and disable }
      END;
*)
     Wait_For_User_Input { may set 'UserWantToQuit' }
    UNTIL UserWantsToQuit
       OR BreakLineSelect;
    {UserWantsToQuit := AutoLogOut;}
    {ResetAllTasks;}
{    ProcessObject^.InitTimedOrderRefresh;}
   END;
  Lose_Visable_Windows;
  NoIngredientSelected := TRUE;
  ScaleWindow^.ClearScaleTareWt;
  IF UserWantsToQuit THEN
   BEGIN
    IF NOT AutoLogOut THEN
      UserWantsToQuit := YesNoWin('              User Logout'+CRLF+
                                  '          Are You Sure ? (Y/N)');
   END;

  { Restore DisplayRecListPos to that before possibly changing to }
  { order line scroller. }
  DisplayRecListPos := OrderListPosSave;
 UNTIL (UserWantsToQuit);
 ClrGraphWin;
END;

PROCEDURE MainProc;
BEGIN
{ ProcessObject^.StartMsgReading; $$$}
 REPEAT
  OpenAllFiles;
  AutoLogOut := FALSE;
  UserWantsToQuit := FALSE;
  REPEAT
    ShowVersionNo;
    IF UserLogIn THEN
     BEGIN
      OperationSelectLoop;
      UserLoggedOut; { record log out }
     END
    ELSE IF (StringLIComp(CurrentUser.USR_ID,'EXIT',4) = 0) THEN
     BEGIN
      ShutDownSet := TRUE;
     END;
  UNTIL ShutDownSet;
  CloseAllFiles;
 UNTIL ShutDownSet OR ScaleConfRec.DebugLogOff;
END;

BEGIN
END.
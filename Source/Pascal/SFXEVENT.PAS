(****************************************************************************
*  UNIT          : SFXEvent                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : Standard Menu Handler                                    *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXEvent;
INTERFACE
USES F6StdCtv,F6StdUtl,SFXBtn,SFXKbd,FXChoice,SFXMsg,SFXComms,ComCheck,SFXMenu,
     SFX_Bars,SFXConst,SFXOList,SFXWin,FXUbiPtr,SFXTList,SFXTouch,SFXEdit,FxFWork,
     FX_MSG,SFXTrans,F6StdWn1,SFXMixes,SFXGraph,SFXScale,SFXDate,SFXStd,SFXSetup,
     SFXUtils,SFXCurr,FxModCtv,SFXTiket,SFXLog,FXCfg;


TYPE PMainMenu = ^TMainMenu;
     TMainMenu = OBJECT(TPCXButton)
      FUNCTION  UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
(*      PROCEDURE Draw; VIRTUAL;*)
     END;

    PSelectionWindow = ^TSelectionWindow;
    TSelectionWindow = OBJECT(TMenuWindow)
     PROCEDURE   SetupChildWindows;VIRTUAL;
    END;


VAR MainSelectionWindow : PSelectionWindow;
    MainMenu          : PMainMenu;


IMPLEMENTATION
USES SFXCOLR;


PROCEDURE ShowScaleOptions;
VAR C    : PChoiceBtn;
    Par  : PChoiceScreen;
    DataWinScale1,
    DataWinScale2 : PSFWindow;
    SaveCol       : BYTE;

   FUNCTION GetScaleName(ScaleType : TConnectedScale) : STRING;
   BEGIN
    Case ScaleType OF
     TNoScale      : GetScaleName := 'No Scale (Use Keys)';
     TInvalidScale : GetScaleName := 'Invalid Scale Name';
     TWeigh_Master : GetScaleName := 'Weigh Master';
     TSystem80     : GetScaleName := 'System80';
     TLucid        : GetScaleName := 'Lucid';
    ELSE GetScaleName := 'Unknown';
    END;
   END;


BEGIN
{$IFNDEF NOCOMMS}
 New(DataWinScale1,Init(8, 48,MAXX DIV 2-8,160,C_WindowStaticText SHR 4,StdWin,NIL,TRUE));
 New(DataWinScale2,Init(8,168,MAXX DIV 2-8,280,C_WindowStaticText SHR 4,StdWin,NIL,TRUE));
 SaveCol := SetTextColour(C_WindowStaticText);
 IF (ScaleHardware[1].SH_Available) THEN
  BEGIN
   WITH ScaleHardware[1],DataWinScale1^ DO
    BEGIN
     DisplayText( 1,'Active        : YES');
     DisplayText( 3,'Port Address  : '+IntToHexStr(SH_PortAddr,2));
     DisplayText( 5,'IRQ No        : '+IntToStr(SH_IRQNo,1));
     DisplayText( 7,'Scale Type    : '+GetScaleName(SH_ScaleType));
     DisplayText( 9,'Initialized   : '+BoolToYNStr(SH_Initialized,3));
     DisplayText(11,'Baud Rate     : '+IntToStr(SH_BaudRate,1));
    END;
  END
 ELSE DataWinScale1^.DisplayText( 1,'Active        : NO');

 IF (ScaleHardware[2].SH_Available) THEN
  BEGIN
   WITH ScaleHardware[2],DataWinScale2^ DO
    BEGIN
     DisplayText( 1,'Active        : YES');
     DisplayText( 3,'Port Address  : '+IntToHexStr(SH_PortAddr,2));
     DisplayText( 5,'IRQ No        : '+IntToStr(SH_IRQNo,1));
     DisplayText( 7,'Scale Type    : '+GetScaleName(SH_ScaleType));
     DisplayText( 9,'Initialized   : '+BoolToYNStr(SH_Initialized,3));
     DisplayText(11,'Baud Rate     : '+IntToStr(SH_BaudRate,1));
    END;
  END
 ELSE DataWinScale2^.DisplayText( 1,'Active        : NO');

 SetTextColour(SaveCol);

 New(Par,Init(MaxX-LargeChildWidth-32,MaxY-LargeChildHeight-16,MaxX-16,Maxy-16,C_BackGround,WT_Button OR WT_Visable));
 New(C,Init(MaxX-LargeChildWidth-32,MaxY-LargeChildHeight-16,Par,2,'EXIT',TRUE));
 REPEAT
  Wait_For_User_Input;
 UNTIL Par^.OptionSelected <> 0;
 Dispose(Par,Done);

 Dispose(DataWinScale2,Done);
 Dispose(DataWinScale1,Done);
{$ENDIF}
END;

{===========================================================================}
{===================== SELECTION WINDOW (Main Menu)  =======================}
PROCEDURE TSelectionWindow.SetupChildWindows;
BEGIN
 AddChildWindow(1,1, 1,'Exit '+CRLF+'Menu');
 AddChildWindow(1,2, 3,'Change'+CRLF+'Password');
 AddChildWindow(1,3, 4,'Set Up');
 AddChildWindow(1,4, 6,'Printer'+CRLF+'Options...');
 AddChildWindow(2,1, 5,'Edit Batch'+CRLF+'And Lot');
 AddChildWindow(2,2, 7,'Show '+CRLF+'Graphical'+CRLF+'Totals');
 AddChildWindow(2,3, 8,'Send'+CRLF+'Message');
 AddChildWindow(2,4,11,'Show Scale'+CRLF+'Options');
 IF Config_Rec^.CONF_Touchscreen THEN
   AddChildWindow(3,2,10,'Recalibrate'+CRLF+'Touch'+CRLF+'Screen');
 AddChildWindow(3,4, 9,'Shut Down');
END;

{=====================Main Menu Button==================}
FUNCTION TMainMenu.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR
   END_MainLoop : BOOLEAN;
   Option       : INTEGER;
   OldList      : PSFWindow;
(*   GetPassWin   : PGetPassWord;*)
   SaveMsgWinState : TMsgWinState;


PROCEDURE ShutDown;
(*VAR GetPassWin : PGetPassWord;*)
BEGIN
 ShutDownSet := FALSE;
 IF (YesNoWin('     Are You Sure You Wish'+CRLF+
              '  To Shutdown The Scale? (Y/N)')) THEN
  BEGIN
   MessageWin.ClearMsg;
(*
   New(GetPassWin,Init(100,100,100+30*8,132,C_WindowStaticText SHR 4,StdWin,NIL,FALSE));
   IF GetPassWin^.UserActivateFunction(0,0) THEN ShutDownSet := TRUE
*)
   IF GetSystemPasswordFromUser THEN
     ShutDownSet := TRUE
   ELSE MessageWin.DisplayMsg('Incorrect Password.',TRUE);
(*   Dispose(GetPassWin,Done);*)
   IF ShutDownSet THEN
    MessageWin.DisplayMsg('User Must Log Out To Complete Shutdown',TRUE);
  END;
END;

BEGIN
 UserActivateFunction := FALSE;
 TimedOrderRefresh^.DisableTask;

 END_MainLoop := FALSE;
 IF ScaleConfRec.MenuPasswordProtected THEN
 BEGIN
(*
  New(GetPassWin,Init(100,110,100+30*8,142,C_WindowStaticText SHR 4,StdWin,NIL,FALSE));
  IF NOT GetPassWin^.UserActivateFunction(0,0) THEN
*)
  IF NOT GetSystemPasswordFromUser THEN
   BEGIN
    MessageWin.DisplayMsg('Incorrect Password.',TRUE);
    End_MainLoop := TRUE;
   END;
(*  Dispose(GetPassWin,Done);*)
  IF End_MainLoop THEN EXIT;
 END;
 UserWindow^.HideWindow;
 MessageWin.EnableAtTopOfScreen(@SaveMsgWinState);
 ClrGraphWin;
 OldList := SetWindowList(NIL);
 New(MainSelectionWindow,Init);
 SetWindowList(MainSelectionWindow);

 REPEAT
  Option := MainSelectionWindow^.GetOptionSelected;
  CASE Option OF
   1 : END_MainLoop := TRUE;
   3 : BEGIN
(*
        New(GetPassWin,Init(100,110,100+30*8,142,C_WindowStaticText SHR 4,StdWin,NIL,FALSE));
        IF NOT GetPassWin^.UserActivateFunction(0,0) THEN
*)
        IF NOT GetSystemPasswordFromUser THEN
         MessageWin.DisplayMsg('Incorrect Password.',TRUE)
        ELSE
         SetNewPassWord;
       END;
   4 : RunSetUp;
   5 : EditGlobalBatchAndLotNo;
   6 : TicketSetUp;
   7 : ShowTodaysWeighings;
   8 : OutputMsg;
   9 : ShutDown;
   10: Get_TouchScreen_Settings(TRUE);
   11: ShowScaleOptions;
  END;
 UNTIL END_MainLoop;
 Dispose(MainSelectionWindow,Done);
 SetWindowList(OldList);
 MessageWin.RestoreMsgState(@SaveMsgWinState);
 ScreenRedraw;
 UserWindow^.Showwindow;
 Display_Recipes_For_Date(TRUE); {work group might have chenged}
 TimedOrderRefresh^.EnableTask;
END;

(*
PROCEDURE TMainMenu.Draw;
BEGIN
 DisplayText(1,'Menu...');
END;
*)
END.
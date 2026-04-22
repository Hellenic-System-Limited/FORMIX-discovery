(****************************************************************************
*  UNIT          : SFXWin                                                   *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Windows That Are Not Standard               *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXWin;
INTERFACE
USES SFXGraph,F6StdCtv,F6StdUtl,SFXBtn,SFXEdit,SFXStd,SFXUtils,SFXMsg,
     FXChoice,SFXKbd,FXStdUt1;

{Windows Graphical Poistioning}

CONST SelWinGap      = 48;
      SelWinSx       = 8;
      SelWinSY       = 60;

CONST idSave         = 1;
      idAbort        = 2;

TYPE
    PChoiceScreen = ^TChoiceScreen;
    TChoiceScreen = OBJECT(TParentWindow)
     OptionSelected : INTEGER;
     CONSTRUCTOR Init(X1,Y1,X2,Y2 : INTEGER; BackCol : BYTE; Flag : WORD);
     PROCEDURE   ReceiveMsg(Msg : INTEGER);VIRTUAL;
     DESTRUCTOR  Done;VIRTUAL;
     {Searches through the list of child windows to find the one with
     a retval of retval}
     FUNCTION    GetChildWindow(RetVal : INTEGER) : PChoiceBtn;
     FUNCTION    GetTypeName : STRING;VIRTUAL;
    END;

    PScreenWithKeyboard = ^TScreenWithKeyBoard;
    TScreenWithKeyboard = OBJECT(TChoiceScreen)
     CurrentEditing : BOOLEAN;

     CONSTRUCTOR Init;
     DESTRUCTOR  Done;VIRTUAL;
     PROCEDURE   MainLoop;
     FUNCTION    UserActivateFunction(X,y : INTEGER) :BOOLEAN ;VIRTUAL;
     PROCEDURE   ReceiveMsg(Msg : INTEGER);VIRTUAL;
     PROCEDURE   HideWindow;VIRTUAL;
     PROCEDURE   ShowWindow;VIRTUAL;
     FUNCTION    GetTypeName : STRING;VIRTUAL;
    END;

    PEditScreen = ^TEditScreen;
    TEditScreen = OBJECT(TScreenWithKeyboard)
     CONSTRUCTOR Init;
     DESTRUCTOR  Done;VIRTUAL;
     FUNCTION    GetTypeName : STRING;VIRTUAL;
    END;

    CallBackFunction = FUNCTION (CallBackValue : INTEGER) : BOOLEAN;

    PEditScreenWithCallBack = ^TEditScreenWithCallBack;
    TEditScreenWithCallBack = OBJECT(TEditScreen)
     PreCallBackFunc,PostCallBackFunc : CallBackFunction;

     CONSTRUCTOR Init(X1,Y1,X2,Y2 : INTEGER;PreCall,PostCall : CallBackFunction);
     DESTRUCTOR  Done;VIRTUAL;
     PROCEDURE   ReceiveMsg(Msg : INTEGER);VIRTUAL;
     FUNCTION    GetTypeNAme : STRING;VIRTUAL;
    END;


    PMenuWindow = ^TMenuWindow;
    TMenuWindow = OBJECT(TChoiceScreen)

     CONSTRUCTOR Init;
     PROCEDURE   SetUpChildWindows;VIRTUAL;
     DESTRUCTOR  Done;VIRTUAL;
     PROCEDURE   Draw;Virtual;
     FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
     FUNCTION    GetOptionSelected : INTEGER;
     PROCEDURE   AddChildWindow(ROW,COL : INTEGER;ButtonID : INTEGER; ButtonText : STRING);
     FUNCTION    GetTypeName : STRING;VIRTUAL;
    END;

    PDisplayWindow = ^TDisplayWindow;
    TDisplayWindow = OBJECT(TChoiceScreen)
     CONSTRUCTOR Init;
     FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
     FUNCTION    GetTypeName : STRING;VIRTUAL;
    END;

IMPLEMENTATION
USES SFXCOLR;
{=========================TDisplayWindow=====================}
CONSTRUCTOR TDisplayWindow.Init;
VAR pExitBtn : PChoiceBtn;
BEGIN
 INHERITED Init(20,20,620,460,C_WindowStaticText SHR 4,StdWin);
 WITH Bounds DO
  BEGIN
   New(pExitBtn,Init((Right+Left)DIV 2 - ChildWidth DIV 2,KbdYOffset-5-ChildHeight,@Self,1,'  Exit',TRUE));
  END;
 DisableAllButtonsExceptMe;
END;

FUNCTION TDisplayWindow.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 ActivateIfInAChildWindow(X,Y);
 UserActivateFunction := OptionSelected <> 0;
END;

FUNCTION TDisplayWindow.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TDISPLAYWINDOW';
END;
{==================CHOICE SCREEN METHODS ==================}
CONSTRUCTOR TChoiceScreen.Init(X1,Y1,X2,Y2 : INTEGER; BackCol : BYTE;Flag : WORD);
BEGIN
 INHERITED Init(X1,Y1,X2,Y2,BackCol,Flag);
 OptionSelected := 0;
END;

PROCEDURE TChoiceScreen.ReceiveMsg(Msg : INTEGER);
BEGIN
 OptionSelected := Msg;
{ LastKeyPress   := CR;} { MODIFIED}
END;

DESTRUCTOR TChoiceScreen.Done;
BEGIN
 INHERITED Done;
END;

FUNCTION TChoiceScreen.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TCHOICEWSCREEN';
END;

FUNCTION TChoiceScreen.GetChildWindow(RetVal : INTEGER) : PChoiceBtn;
VAR pChildRec : PChoiceBtn;
BEGIN
 GetChildWindow := NIL;
 pChildRec := PChoiceBtn(ChildWindows);
 WHILE (pChildRec <> NIL) DO
  BEGIN
   IF (TypeOf(pChildRec^) = TypeOf(TChoiceBtn)) THEN
    BEGIN
     IF pChildRec^.GetReturnValue = RetVal THEN
      BEGIN
       GetChildWindow := pChildRec;
       EXIT;
      END;
    END;
   pChildRec := PChoiceBtn(pChildRec^.Next);
  END;
END;

{======================= EDIT SCREENS =====================================}
{FULL SCREEN EXCEPT KEYBOARD. CHANGE THIS FOR KEYSIZE}
CONSTRUCTOR TScreenWithKeyboard.Init;
BEGIN
 MessageWin.ClearMsg;
 INHERITED Init(0,0,639,KbdYOffset-2{479} { 347-48},C_BackGround,WT_Button OR WT_Visable);
 ShowKbd;
 CurrentEditing := FALSE;
END;

DESTRUCTOR TScreenWithKeyboard.Done;
BEGIN
 LoseKbd;
(* ReturnLastMousePress := FALSE;*)
 INHERITED Done;
END;

FUNCTION TScreenWithKeyboard.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TSCREENWITHKBD';
END;

PROCEDURE TScreenWithKeyboard.MainLoop;
BEGIN
 OptionSelected := 0;
 REPEAT
  Wait_For_User_Input;
 UNTIL OptionSelected <>0;
END;

FUNCTION TScreenWithKeyBoard.UserActivateFunction(X,y : INTEGER) :BOOLEAN;
BEGIN
 IF (LastChildhit <> NIL) AND (TypeOf(LastChildHit^) = TypeOf(TEdit)) THEN
  CurrentEditing := TRUE;
 UserActivateFunction := INHERITED UserActivateFunction(X,Y);
 CurrentEditing := FALSE;
END;

PROCEDURE TScreenWithKeyboard.ReceiveMsg(Msg : INTEGER);
BEGIN
 IF (CurrentEditing) THEN
  BEGIN
   LastKeysPressed.AddCharacterCode(ORD(CR));
(* MouseButtons         := 1; { left mouse button down }*)
(* ReturnLastMousePress := TRUE;*)
  END;
 INHERITED ReceiveMsg(Msg);
END;

PROCEDURE TScreenWithKeyboard.HideWindow;
BEGIN
 LoseKbd;
 INHERITED HideWindow;
END;

PROCEDURE TScreenWithKeyboard.ShowWindow;
BEGIN
 INHERITED ShowWindow;
 ShowKbd;
END;

{======================= EDIT SCREEN =====================================}
CONSTRUCTOR TEditScreen.Init;
VAR C : PChoiceBtn;
BEGIN
 INHERITED Init;
 WITH Bounds DO
  BEGIN
   New(C,Init(Left+16,                 KbdYOffset-5-LargeChildHeight,@Self,idSave,SaveStr,TRUE));
   New(C,Init(Right-16-LargeChildWidth,KbdYOffset-5-LargeChildHeight,@Self,idAbort,AbortStr,TRUE));
  END;
END;

DESTRUCTOR TEditScreen.Done;
BEGIN
 INHERITED Done;
END;

FUNCTION TEditScreen.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TEDITSCREEN';
END;

{======================= EDIT SCREEN WITH CALLBACK SUPPORT ===============}
CONSTRUCTOR TEditScreenWithCallBack.Init(X1,Y1,X2,Y2 : INTEGER;PreCall,PostCall : CallBackFunction);
BEGIN
 PreCallBackFunc  := PreCall;
 PostCallBackFunc := PostCall;
 INHERITED Init;
END;

DESTRUCTOR TEditScreenWithCallBack.Done;
BEGIN
 INHERITED Done;
END;

PROCEDURE TEditScreenWithCallBack.ReceiveMsg(Msg : INTEGER);
BEGIN
 IF (Msg > 90) THEN
  BEGIN
   INHERITED ReceiveMsg(Msg);
   EXIT;
  END;
 IF (Msg < 0) THEN
  BEGIN
   IF (Assigned(PreCallBackFunc)) THEN PreCallBackFunc(Msg);
  END
 ELSE
  BEGIN
   IF (Assigned(PostCallBackFunc)) THEN
   IF (NOT PostCallBackFunc(Msg)) AND (LastChildHit <> NIL) THEN
    LastChildHit^.UserActivateFunction(0,0);
  END;
END;

FUNCTION TEditScreenWithCallBack.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TEDITSCREENWITHCALLBACK';
END;
{======================= MENU  WINDOW ==========================================}
CONSTRUCTOR TMenuWindow.Init;
BEGIN
 INHERITED Init(SelWinSx,SelWinSY,SelWinSX+4*ChildWidth+5*SelWinGap,SelWinSY+16+SelWinGap*4+ChildHeight*3,
                C_WindowStaticText SHR 4,StdWin);
 OptionSelected := 0;
 SetUpChildWindows;
END;

FUNCTION TMenuWindow.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TMENUWINDOW';
END;


PROCEDURE TMenuWindow.AddChildWindow(ROW,COL : INTEGER;ButtonID : INTEGER; ButtonText : STRING);
VAR C : PChoiceBtn;
BEGIN
 WITH Bounds DO
  BEGIN
   NEW(C,Init(Left+(SelWinGap*COL)+((ChildWidth) *(COL-1)),
              Top +(SelWinGap*ROW)+((ChildHeight)*(ROW-1)),
              @Self,ButtonID,ButtonText,TRUE));
  END;
END;

PROCEDURE TMenuWindow.SetUpChildWindows;
BEGIN
END;

DESTRUCTOR TMenuWindow.Done;
BEGIN
 INHERITED Done;
END;

PROCEDURE TMenuWindow.Draw;
BEGIN
 WriteHeader('Select Option');
END;

FUNCTION TMenuWindow.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 ActivateIfInAChildWindow(X,Y);
 UserActivateFunction := FALSE;
END;

FUNCTION TMenuWindow.GetoptionSelected : INTEGER;
BEGIN
 OptionSelected := 0;
 IF (WinType AND WT_Visable) = 0 THEN ShowWindow;
 REPEAT
  Wait_For_User_Input;
 UNTIL OptionSelected <> 0;
 GetOptionSelected := OptionSelected;
 TMenuWindow.HideWindow;
END;

END.
(****************************************************************************
*  UNIT          : SFXWin                                                   *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Windows That Are Not Standard               *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXMsg;
INTERFACE
USES SFXGraph,F6StdCtv,F6StdUtl,SFXBtn,SFXConst,SFX_Pro,SFXFont,F6StdWn1,CRT;

CONST MessageWinStartY = 218+4;
      MessageWinHeight = 36;
      MessageWinWidth  = 55*8+7;
      NonWeighMsgWinY  = 1;


TYPE  PMessageTask = ^TMessageTask;
      TMessageTask = OBJECT(TBackgroundTask)
       PROCEDURE Execute;Virtual;
      END;

     PMsgWinState = ^TMsgWinState;
     TMsgWinState = PACKED RECORD
       MWS_WinType     : WORD;
       MWS_DontDrawMsg : BOOLEAN;
       MWS_YPos        : INTEGER;
     END;

TYPE
     { TMessageWindow is used to show system/process status. }
     { (user messages now appear in Disp_Error_Msg windows)  }
     TMessageWindow = OBJECT(TSFWindow)
     PRIVATE
      MsgStartTick : LONGINT;
     PUBLIC
      Msg : STRING[55];
      {TRUE MEANS THAT NO OTHER MSG CAN BE DISPLAYED WHILE THIS ONE IS DISPLAYING}
      AllowNoMoreMsg : BOOLEAN;
      {TRUE MEANS THAT NO MESSAGES AT ALL CAN BE DISPLAYED}
      DontDrawMsg    : BOOLEAN;
      {MEANS MSG BEING DISPLAYED IS ONLY A MINOR MSG}
      MinorMsg       : BOOLEAN;
      CONSTRUCTOR Init;
      DESTRUCTOR Done;VIRTUAL;
      PROCEDURE Draw;VIRTUAL;
      PROCEDURE RemoveWindowIfTimeOut;
      PROCEDURE DisplayMsg(TMsg : STRING;AllowNoOtherMsg : BOOLEAN);
      PROCEDURE DisplayMsgIfBlank(TMsg : STRING);
      PROCEDURE SetWindow(x1,y1,x2,y2 : WORD);VIRTUAL;
      PROCEDURE SaveCurrentState(PtrToSaveStateRec : PMsgWinState);
      PROCEDURE ClearMsg;
      {-- procs for changing state / position of message (status) win --}
      PROCEDURE EnableAtMidScreen(PtrToOptSaveStateRec : PMsgWinState);
      PROCEDURE EnableAtTopOfScreen(PtrToOptSaveStateRec : PMsgWinState);
      PROCEDURE DisableMsgs(PtrToOptSaveStateRec : PMsgWinState);
      PROCEDURE RestoreMsgState(PtrToSavedStateRec : PMsgWinState);
      {-----------------------------------------------------------------}
     END;

VAR MessageWin          : TMessageWindow;
IMPLEMENTATION

USES SFXCOLR;


PROCEDURE TMessageTask.Execute;
BEGIN
 MessageWin.RemoveWindowIfTimeOut;
END;


{=============MESSAGE WINDOW METHODS==================}
CONSTRUCTOR TMessageWindow.Init;
VAR MessageTask : PMessageTask;
BEGIN
 Msg            := SPACE_STRING;
 AllowNoMoreMsg := FALSE;
 DontDrawMsg    := TRUE;
 MinorMsg       := FALSE;
 INHERITED Init(All_Win_Left,
                20,
                All_Win_Left+MessageWinWidth,
                20+MessageWinHeight,
                BackGround,
                {WT_Visable} WT_NonDeletable,NIL,FALSE);
 ChangeWindowFont(DoubleHeightFont);

 New(MessageTask,Init(FALSE));
END;

DESTRUCTOR TMessageWindow.Done;
BEGIN
 {DeleteFont(FontToUse);}
 INHERITED Done;
END;

PROCEDURE TMessageWindow.SetWindow(x1,y1,x2,y2 : WORD);
BEGIN
 INHERITED SetWindow(x1,y1,x2,y2);
 AllowNoMoreMsg := FALSE;
END;

PROCEDURE TMessageWindow.ClearMsg;
BEGIN
 AllowNoMoreMsg := FALSE;
 Msg := Space_String;
 HideWindow;
END;

PROCEDURE TMessageWindow.Draw;
VAR SaveCol : BYTE;
BEGIN
 IF DontDrawMsg THEN EXIT;
 MsgStartTick := GetTickCount;
 SaveCol := SetTextColour(C_MessageWin);
 DisplayText(0,Msg);
 SetTextColour(SaveCol);
END;

PROCEDURE TMessageWindow.SaveCurrentState(PtrToSaveStateRec : PMsgWinState);
BEGIN
 IF PtrToSaveStateRec <> NIL THEN
  BEGIN
   WITH PtrToSaveStateRec^ DO
    BEGIN
     MWS_WinType     := WinType;
     MWS_DontDrawMsg := DontDrawMsg;
     MWS_YPos        := Bounds.Top;
    END;
  END;
END;

PROCEDURE TMessageWindow.EnableAtMidScreen(PtrToOptSaveStateRec : PMsgWinState);
BEGIN
 DisableMsgs(PtrToOptSaveStateRec); { might need to hide window in current pos }
 SetWindow(All_Win_Left,MessageWinStartY,All_Win_Left+MessageWinWidth,MessageWinStartY+MessageWinHeight);
 DontDrawMsg := FALSE;
END;

PROCEDURE TMessageWindow.EnableAtTopOfScreen(PtrToOptSaveStateRec : PMsgWinState);
BEGIN
 DisableMsgs(PtrToOptSaveStateRec); { might need to hide window in current pos }
 SetWindow(All_Win_Left,NonWeighMsgWinY,All_Win_Left+MessageWinWidth,NonWeighMsgWinY+MessageWinHeight);
 DontDrawMsg := FALSE;
END;

PROCEDURE TMessageWindow.DisableMsgs(PtrToOptSaveStateRec : PMsgWinState);
BEGIN
 SaveCurrentState(PtrToOptSaveStateRec);
 HideWindow;
 DontDrawMsg := TRUE;
END;

PROCEDURE TMessageWindow.RestoreMsgState(PtrToSavedStateRec : PMsgWinState);
BEGIN
 DisableMsgs(NIL); { might need to hide window in current pos }
 DontDrawMsg := PtrToSavedStateRec^.MWS_DontDrawMsg;
 WinType     := PtrToSavedStateRec^.MWS_WinType;
 SetWindow(All_Win_Left,
           PtrToSavedStateRec^.MWS_YPos,
           All_Win_Left+MessageWinWidth,
           PtrToSavedStateRec^.MWS_YPos+MessageWinHeight);
 IF IsWindowVisable THEN ShowWindow;
END;

PROCEDURE TMessageWindow.DisplayMsg(TMsg : STRING;AllowNoOtherMsg : BOOLEAN);
BEGIN
 IF DontDrawMsg THEN
   Disp_Error_Msg(TMsg)
 ELSE
  BEGIN
   IF AllowNoMoreMsg THEN EXIT;
   {Store The Message}
   MinorMsg := FALSE;
   AllowNoMoreMsg := AllowNoOtherMsg;
   Msg := TMsg+SPACE_STRING;
   IF (WinType AND WT_Visable) = 0 THEN ShowWindow
   ELSE Draw;
  END;
END;

PROCEDURE TMessageWindow.DisplayMsgIfBlank(TMsg : STRING);
BEGIN
 IF DontDrawMsg THEN
   Disp_Error_Msg(TMsg)
 ELSE
  BEGIN
   IF  (NOT MinorMsg)
   AND (AllowNoMoreMsg OR (NOT NowtButSpace(Msg))) THEN EXIT;
   MinorMsg := TRUE;
   Msg := TMsg+SPACE_STRING;
   IF (WinType AND WT_Visable) = 0 THEN ShowWindow
   ELSE Draw;
  END;
END;

PROCEDURE TMessageWindow.RemoveWindowIfTimeOut;
VAR
   SecsSoFar : LONGINT;

   FUNCTION MinPossDiffInTicks(StartTick, CurrentTick : LONGINT) : LONGINT;
   BEGIN
    IF CurrentTick >= StartTick THEN
      MinPossDiffInTicks := CurrentTick - StartTick
    ELSE
      MinPossDiffInTicks := CurrentTick; { because i done know wrap around point }
   END;

BEGIN
 IF  (NOT DontDrawMsg)
 AND IsWindowVisable THEN { any Msg is currently being displayed to user }
  BEGIN;
   SecsSoFar := MinPossDiffInTicks(MsgStartTick, GetTickCount) DIV 18;

   IF SecsSoFar > NonRefreshedMsgMinTimeOut THEN
     AllowNoMoreMsg := FALSE; { ie. all messages are overwritable after 4 secs }

   IF SecsSoFar > MaxMsgTimeOut THEN
    BEGIN
     ClearMsg;
    END;
  END;
END;


END.

(****************************************************************************
*  UNIT          : SFX_MSG                                                  *
*  AUTHOR        : N.S.                                                     *
*  DATE          : 4/6/96                                                   *
*  PURPOSE       : PERFORMS MESSAGE READING                                 *
*  MODIFICATIONS : -                                                        *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
{$C FIXED PRELOAD PERMANENT}
UNIT SFX_Msg;
INTERFACE
USES SFX_Pro,FX_Msg,Sfxconst,F6StdUtl,SFXTime,SFXGraph,F6StdWn1;

TYPE PMsgRead = ^TMsgRead;
     TMsgRead = OBJECT(TBackGroundTask)
      MsgPacket : TMsgPacket;
      EventDone : BOOLEAN;

      CONSTRUCTOR Init;
      DESTRUCTOR  Done; VIRTUAL;
      PROCEDURE Execute;VIRTUAL;
     END;

PROCEDURE StartMsgInit;
VAR MsgReader : PMsgRead;

IMPLEMENTATION

CONSTRUCTOR TMsgRead.Init;
BEGIN
 INHERITED Init(TRUE);
 EventDone := FALSE;
END;

DESTRUCTOR  TMsgRead.Done;
BEGIN
 INHERITED Done;
END;

PROCEDURE TMsgRead.Execute;
BEGIN
 IF (SecOfDayInSet(ScaleConfRec.GetMessageSearchTime)) THEN
  BEGIN
   IF (NOT EventDone) THEN RecieveMsg(NIL);
   EventDone := TRUE;
  END
 ELSE
  BEGIN
   EventDone := FALSE;
  END;
END;

PROCEDURE StartMsgInit;
BEGIN
 New(MsgReader,Init);
 MsgInit;
END;

END.
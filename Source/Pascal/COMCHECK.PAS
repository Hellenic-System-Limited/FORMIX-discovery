{$O+,F+}
{$I F6COMP}
UNIT ComCheck;
INTERFACE
USES F6STDUTl,SFXMsg;


PROCEDURE CheckForTimeOut(FirstCheck : BOOLEAN;TimeOut : INTEGER;DispMsg : BOOLEAN);
VAR
    TimeOutError  : BOOLEAN;


IMPLEMENTATION

PROCEDURE CheckForTimeOut(FirstCheck : BOOLEAN;TimeOut : INTEGER;DispMsg : BOOLEAN);
CONST  LastH    : WORD = 0;
       LastM    : WORD = 0;
       LastS    : WORD = 0;
       TimeOutS : WORD = 0;
       ShowErr  : BOOLEAN = FALSE;

VAR H,M,S,S100 : WORD;
      I :INTEGER;
BEGIN
 IF FirstCheck THEN
  BEGIN
   LastH    := 0;
   LastM    := 0;
   LastS    := 0;
   TimeOutS := 0;
   ShowErr  := FALSE;
   TimeOutError := FALSE;
  END;
 GetRTCTime(H,M,S,S100);
 IF (LastH+LastM+LastS) = 0 THEN
  BEGIN
   LastH := H;
   LastM := M;
   LastS := S;
   IF TimeOut < 10 THEN TimeOutS := S
   ELSE TimeOutS := (S+5);
   IF TimeOutS > 59 THEN DEC(TimeOutS,60);
  END;
 IF ((TimeOutS) = S) AND NOT ShowErr THEN
  BEGIN
   ShowErr  := TRUE;
   TimeOutS := TimeOutS+TimeOut;
   IF TimeOut >= 10 THEN Dec(TimeOutS,5);
   IF TimeOutS > 59 THEN DEC(TimeOutS,60);
  END;
 IF ShowErr AND ((LastH <> H) OR (LastM <> M) OR (LastS <> S)) THEN
  BEGIN
   I := TimeOutS;
   IF (DispMsg) THEN
    BEGIN
     IF I-S < 0 THEN
      MessageWin.DisplayMsg('Time Out In '+IntToStr(TimeOutS+60-S,3)+' Secs ',FALSE)
     ELSE
      MessageWin.DisplayMsg('Time Out In '+IntToStr(TimeOutS-S,3)+' Secs ',FALSE);
    END;
  END;
 IF TimeOutS = S THEN
  BEGIN
   TimeOutError := TRUE;
  END;
END;

END.
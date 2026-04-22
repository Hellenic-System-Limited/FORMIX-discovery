{$C FIXED PRELOAD PERMANENT}
{$O+,F+}
UNIT SFXTime;
INTERFACE
USES F6StdCTV,SFXGraph,SFXBtn,F6StdUtl,SFX_Pro,F6DtConv;

CONST SecsPerDay = 24*60*60;

TYPE TTimedEvent = PACKED RECORD
      StartTimeInSecs : LONGINT;
      SecondInterval  : LONGINT;
     END;

(*
TYPE
     TTimeWindow = OBJECT(TSFWindow)
      CONSTRUCTOR Init(X,Y : INTEGER);
      PROCEDURE Draw;VIRTUAL;
     END;
*)

FUNCTION TimeStrToSeconds(TimeStr : STRING) : LONGINT;
FUNCTION GetDayTimeInSeconds : LONGINT;
FUNCTION GetSecondsAdvance(NumSecs : LONGINT) : LONGINT;
PROCEDURE ExpandTimedEventStr(EventStr : STRING;VAR TimedEvent : TTimedEvent);
FUNCTION SecOfDayInSet(VAR TimedEvent : TTimedEvent) : BOOLEAN;

(*
VAR TimeWindow : TTimeWindow;
*)

IMPLEMENTATION

USES SFXCOLR;

FUNCTION TimeStrToSeconds(TimeStr : STRING) : LONGINT;
VAR TheHour,
    TheMin,
    TheSecs  : LONGINT;
    ValError : INTEGER;
BEGIN
  TheHour := 0; TheMin := 0; TheSecs := 0;
  VAL(Copy(TimeStr,1,2), TheHour, ValError);
  VAL(Copy(TimeStr,4,2), TheMin,  ValError);
  VAL(Copy(TimeStr,7,2), TheSecs, ValError);
  TimeStrToSeconds := TheHour*60*60+TheMin*60+TheSecs;
END;

FUNCTION GetDayTimeInSeconds : LONGINT;
BEGIN
 GetDayTimeInSeconds := TimeStrToSeconds(Time);
END;

FUNCTION GetSecondsAdvance(NumSecs : LONGINT) : LONGINT;
VAR ActualSecs : LONGINT;
BEGIN
 ActualSecs := GetDayTimeInSeconds+NumSecs;
 IF (ActualSecs  > SecsPerDay) THEN Dec(ActualSecs,SecsPerDay);
 GetSecondsAdvance := ActualSecs;
END;

FUNCTION SecOfDayInSet(VAR TimedEvent : TTimedEvent) : BOOLEAN;
VAR  SecondOfDay : LONGINT;
BEGIN
  SecondOfDay   := GetDayTimeInSeconds;
  WITH TimedEvent DO
   SecOfDayInSet := (SecondOfDay >= StartTimeInSecs)
                    AND (((SecondOfDay - StartTimeInSecs) MOD SecondInterval) = 0);
END;


PROCEDURE ExpandTimedEventStr(EventStr : STRING;VAR TimedEvent : TTimedEvent);
VAR CommaPos : INTEGER;
    TimeStr  : STRING[10];
    NumStr   : STRING[10];
BEGIN
 WITH TimedEvent DO
  BEGIN
   StartTimeInSecs := 0;
   SecondInterval  := 20;
   IF (Length(EventStr) = 0) THEN EXIT;
   CommaPos := POS(',',EventStr);
   IF (CommaPos = 0) THEN
    BEGIN
     IF (Valid_Time(EventStr)) THEN
      StartTimeinSecs := TimeStrToSeconds(EventStr);
    END
   ELSE
    BEGIN
     TimeStr := COPY(EventStr,1,CommaPos-1);
     IF (Valid_Time(TimeStr)) THEN
      StartTimeinSecs := TimeStrToSeconds(TimeStr);
     NumStr := COPY(EventStr,CommaPos+1,Length(EventStr));
     SecondInterval := StringToLong(NumStr);
     IF (SecondInterval < 1) THEN SecondInterval := 20;
    END;
  END;
END;


(*
CONSTRUCTOR TTimeWindow.Init(X,Y : INTEGER);
VAR TimeTask : PTimeTask;
BEGIN
{ LastTimeInSecs := 0;}
 LastTimeStr := '';
 INHERITED Init(X*8-4,Y*8-1,X*8+10*8+4,Y*8+10,C_WindowStaticText SHR 4,{WT_Visable}0,NIL,FALSE);
 New(TimeTask,Init);
END;

PROCEDURE TTimeWindow.Draw;
VAR
{   TimeInSecs : LONGINT;
    TimeStr    : STRING[8];}
    TimeStr    : STRING[8];  { Displaying seconds stops keyboard wedge scanner}
                             { working reliably }
    HoldFont   : PFontType;
    SaveCol    : BYTE;
BEGIN
 IF (WinType AND WT_Visable) =0 THEN EXIT;
 timestr    := Time;
{ TimeInSecs := TimeStrToSeconds(TimeStr);
   if (timeinSecs <> lasttimeinsecs) THEN
}
 IF TimeStr <> LastTimeStr THEN { different second }
  BEGIN
   HoldFont   := SetCurrentFont(FontToUse);
   SaveCol := SetTextColour(C_WindowStaticText);
{$IFDEF DISPMEM}
   DisplayText(0,IntToStr(MemAvail,8));
{$ELSE}
   DisplayText(0,TimeStr);
   LastTimeStr := TimeStr;
{   lasttimeinsecs:=timeinsecs;}
{$ENDIF}
   SetTextColour(SaveCol);
   SetCurrentFont(HoldFont);
  END;

END;
*)

END.
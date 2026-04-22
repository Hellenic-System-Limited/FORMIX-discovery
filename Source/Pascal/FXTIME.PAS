(****************************************************************************
*  UNIT          : F6TIME                                                   *
*  AUTHOR        : C. J. Collins                                            *
*  DATE          : 28/02/94                                                 *
*  PURPOSE       : FOPS6 TIME DISPLAY                                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXTIME;
INTERFACE



CONST DAILY = 1440;
TYPE TimeState = (Active, OnHold, InGrp, InGrpOnHold);

     TimedEvent = PROCEDURE;

     TMinsOfDay = PACKED RECORD
                   Period   : INTEGER; { between events in minutes }
                   FirstMin : INTEGER;
                  END;

     EventPtr  = ^EventItem;
     EventItem = PACKED RECORD
       Event       : TimedEvent;
       TimeSet     : TMinsOfDay;
       Staggered   : BOOLEAN;
       LastRun     : WORD;
       EventStatus : TimeState;
       Next        : EventPtr;
     END;

FUNCTION Schedule_Timed_Event(TheEvent   : TimedEvent;
                               Hour      : BYTE;
                               Min       : BYTE;
                               Staggered : BOOLEAN;
                               Interval  : LONGINT) : EventPtr;

PROCEDURE Cancel_Timed_Event(TheEvent  : TimedEvent);
PROCEDURE DispTime;
PROCEDURE Hold_All_Timed_Events;
PROCEDURE Restore_All_Timed_Events;

VAR  Timed_Event_Active : BOOLEAN;
     FirstEvent         : EventPtr;
     TimeDisp           : BOOLEAN;
     ECntDown           : LONGINT;

IMPLEMENTATION

USES Dos,Crt,F6StdCtv,FXModCtv,F6StdWin,F6StdUtl,FXCFG,FX_Msg,
{$IFDEF WINDOWS} Video, {$ENDIF}
     FXFIni;

CONST EventStagger : ARRAY [0..5] OF INTEGER = (0,10,20,30,40,50);

VAR TimeWindow : WindowRecord;
    LastH,LastM,
    LastS      : WORD;
    DumpDone   : BOOLEAN;
    HoldEvent  : TimedEvent;
    Stagger    : BYTE;
    LastStagMin: WORD;
    NextMsgCheck : BOOLEAN;


FUNCTION MinOfDayInSet(AHr,AMin: WORD; Setting: TMinsOfDay) : BOOLEAN;
VAR  MinuteOfDay : WORD;
BEGIN
  MinuteOfDay := AHr*60+Amin;
  MinOfDayInSet := (MinuteOfDay >= Setting.FirstMin)
            AND (((MinuteOfDay - Setting.FirstMin) MOD Setting.Period) = 0);
END;


PROCEDURE WriteToScreen(CONST AString : STRING; X,Y : LONGINT);
{$IFNDEF WINDOWS}
VAR
   scrn_ptr : Scrn_Ptr_Type;  {Store screen address here}
   i        : WORD;
   Offset   : LONGINT;
{$ENDIF}

BEGIN
{$IFDEF WINDOWS}
  WriteDirectAt(X,Y,AString);
{$ELSE}
  scrn_ptr := Screen_Address;
  Offset := (80 * (Y-1) + X) * 2;
  FOR i := Offset TO (Offset + ((Length(AString)-1)*2)) DO
   BEGIN
    IF (i MOD 2) = 0 THEN
      scrn_ptr^[i] := ORD(AString[((i-Offset)DIV 2)+1]);
   END;
{$ENDIF}
END;


FUNCTION LastScreenRow : INTEGER;
{$IFDEF WINDOWS}
VAR
   VideoMode : TVideoMode;
{$ENDIF}
BEGIN
{$IFDEF WINDOWS}
  GetVideoMode(VideoMode);
  LastScreenRow := VideoMode.Row;
{$ELSE}
  IF (LastMode = CO80) OR (LastMode = BW80) THEN
    LastScreenRow := 25
  ELSE
    LastScreenRow := 50;
{$ENDIF}
END;


PROCEDURE DispTime;
VAR H,M,S,S100 : WORD;
    RB,RF,NB,HiF,LoF : BYTE;
    old_x1, old_y1,
    old_x2, old_y2,
    old_xc, old_yc : BYTE;
    HoldAttr       : BYTE;
    WrkH,WrkM,WrkS : STRING[2];
    HoldClock      : BOOLEAN;
    CurrEvent      : EventPtr;
    RunTime        : LONGINT;
{$IFDEF MEMTEST}
    MemStr1,MemStr2: STRING[10];
{$ENDIF}

(*
   PROCEDURE WriteTime(TStr : STRING);
   CONST
   {$IFDEF MEMTEST}
         TimeOffset = 3960;
         LargeTimeOffSet = 7456+480+28;
         TimeLen    = 17;
   {$ELSE}
         TimeOffset = 3982;
         LargeTimeOffSet = 7474+480+28;
         TimeLen    = 8;
   {$ENDIF}
   VAR scrn_ptr : Scrn_Ptr_Type;  {Store screen address here}
       i,K      : WORD;
  BEGIN
    TStr := TStr+SPACE_STRING;
    scrn_ptr := Screen_Address;
    K := 1;
    IF (LastMode = CO80) OR (LastMode = BW80) THEN
     BEGIN
      I := TimeOffset;
      WHILE (i <=TimeOffset + (TimeLen*2)) DO
       BEGIN
        Scrn_Ptr^[i] := ORD(TStr[K]);
        INC(I,2);
        INC(K);
       END;
     END
    ELSE
     BEGIN
      FOR i := LargeTimeOffset TO LargeTimeOffset + (TimeLen*2) DO
       BEGIN
        IF (i MOD 2) = 0 THEN
         scrn_ptr^[i] := ORD(TStr[((i-LargeTimeOffset)DIV 2)+1]);
       END;
     END;
   END;
*)
   PROCEDURE WriteTime(TStr: STRING);
   BEGIN
     WriteToScreen(TStr,80-(Length(TStr)+2), LastScreenRow);
   END;

BEGIN
 GetRTCTime(H,M,S,S100);
 {if still in same second as last time, exit}
 IF (LastS = S) AND (LastM = M) AND (LastH = H) THEN Exit;
 LastH := H; LastM := M; LastS := S;
 IF NOT Timed_Event_Active THEN
  BEGIN
   RunTime := H*60+M;
   CurrEvent := FirstEvent;
   WHILE CurrEvent <> NIL DO
    BEGIN
     IF MinOfDayInSet(H,M,CurrEvent^.TimeSet) AND
        (CurrEvent^.EventStatus = Active) THEN
      BEGIN
       IF (NOT CurrEvent^.Staggered) THEN { Non Staggered Event            }
        BEGIN
         IF (RunTime <> CurrEvent^.LastRun) THEN
          BEGIN
           HoldClock := TimeDisp;          { Hold Clock On/Off Setting      }
           TimeDisp  := FALSE;             { Turn Clock Update Off          }
           Timed_Event_Active := TRUE;     { Ye May Not Re Enter Flag       }
           CurrEvent^.Event;               { Run Timed Event                }
           Timed_Event_Active := FALSE;    { Finished Event                 }
           TimeDisp := HoldClock;          { Restore Clock Settings         }
           CurrEvent^.LastRun :=RunTime;   { Store Time Executed            }
          END;
        END
       ELSE                                { Staggered Event                }
        BEGIN
         IF (S > EventStagger[Stagger]) AND
            (RunTime <> CurrEvent^.LastRun) THEN
          BEGIN
           HoldClock := TimeDisp;          { Hold Clock On/Off Setting      }
           TimeDisp  := FALSE;             { Turn Clock Update Off          }
           Timed_Event_Active := TRUE;     { Ye May Not Re Enter Flag       }
           CurrEvent^.Event;               { Run Timed Event                }
           Timed_Event_Active := FALSE;    { Finished Event                 }
           TimeDisp := HoldClock;          { Restore Clock Settings         }
           CurrEvent^.LastRun :=RunTime;   { Store Time Executed            }
          END;
        END;
      END
     ELSE IF (CurrEvent^.TimeSet.Period = DAILY)
          AND (CurrEvent^.LastRun = CurrEvent^.TimeSet.FirstMin) THEN
       CurrEvent^.LastRun := $FFFF;        { to ensure daily ops get recalled}

     CurrEvent := CurrEvent^.Next;
    END;
  END;
 IF NOT TimeDisp THEN Exit;

 STR(LastH:2,WrkH); STR(LastM:2,WrkM); STR(LastS:2,WrkS);

{$IFDEF MEMTEST}
 STR(MemAvail:0,MemStr1);
 STR(MaxAvail:0,MemStr2);
 WriteTime('A='+MemStr1+' C='+MemStr2+SPACE_STRING);
{$ELSE}
 WriteTime(Add_Zeros(WrkH)+':'+Add_Zeros(WrkM)+':'+Add_Zeros(WrkS));
{$ENDIF}
 IF (S = 0) THEN              { ONLY CHECK MESSAGES ONCE PER MIN }
  BEGIN
   IF (NextMsgCheck) THEN
    BEGIN
     RecieveMsg(NIL);
     NextMsgCheck := (NOT NextMsgCheck);
    END;
  END
 ELSE NextMsgCheck := TRUE;
END;

FUNCTION Schedule_Timed_Event(TheEvent  : TimedEvent;
                               Hour      : BYTE;
                               Min       : BYTE;
                               Staggered : BOOLEAN;
                               Interval  : LONGINT) : EventPtr;

VAR CurrEvent  : EventPtr;
    NewEvent   : EventPtr;
    H,M,S,S100 : WORD;
BEGIN
  NewEvent            := NIL;
  Schedule_Timed_Event:= NewEvent;
  IF Interval = 0 THEN Exit;
  CurrEvent := FirstEvent;
  NEW(NewEvent);
  NewEvent^.Event               := TheEvent;
  NewEvent^.TimeSet.Period      := Interval;
  NewEvent^.TimeSet.FirstMin    := Hour*60+Min;
  NewEvent^.Staggered           := Staggered;
  GetRTCTime(H,M,S,S100);
  NewEvent^.LastRun             := H*60+M;       { Stop Immediate Execution }
  NewEvent^.EventStatus         := Active;
  NewEvent^.Next                := FirstEvent;   { Place On Event Stack     }
  FirstEvent :=NewEvent;
  Schedule_Timed_Event := NewEvent;              { Return Pointer To Event  }
END;

{****************************************************************************
 * Cancel a Timed Event if in Event Stack                                   *
 ****************************************************************************}

PROCEDURE Cancel_Timed_Event(TheEvent  : TimedEvent);
VAR CurrEvent : EventPtr;
    LastEvent : EventPtr;
BEGIN
 CurrEvent := FirstEvent;
 LastEvent := NIL;
 WHILE CurrEvent <> NIL DO
  BEGIN
   IF @CurrEvent^.Event = @TheEvent THEN
    BEGIN
     IF LastEvent = NIL THEN                     { Top Of Stack             }
      BEGIN
       FirstEvent :=CurrEvent^.Next;             { Remove From Stack        }
       Dispose(CurrEvent);                       { Dispose                  }
       Exit;                                     { Done                     }
      END
     ELSE
      BEGIN
       LastEvent^.Next := CurrEvent^.Next;       { TableCloth Trick         }
       Dispose(CurrEvent);                       { Dispose                  }
       Exit                                      { Done                     }
      END;
    END;
   LastEvent := CurrEvent;                       { Remember Previous Event  }
   CurrEvent := CurrEvent^.Next;                 { Next Event               }
  END;
END;

PROCEDURE Hold_All_Timed_Events;
VAR CurrEvent : EventPtr;
BEGIN
 CurrEvent := FirstEvent;
 WHILE CurrEvent <> NIL DO
  BEGIN
   CASE CurrEvent^.EventStatus OF
    Active : CurrEvent^.EventStatus := InGrp;
    OnHold : CurrEvent^.EventStatus := InGrpOnHold;
   END;
   CurrEvent := CurrEvent^.Next;
  END;
END;

PROCEDURE Restore_All_Timed_Events;
VAR CurrEvent : EventPtr;
BEGIN
 CurrEvent := FirstEvent;
 WHILE CurrEvent <> NIL DO
  BEGIN
   CASE CurrEvent^.EventStatus OF
    InGrp       : CurrEvent^.EventStatus := Active;
    InGrpOnHold : CurrEvent^.EventStatus := OnHold;
   END;
   CurrEvent := CurrEvent^.Next;
  END;
END;


BEGIN
  FirstEvent         := NIL;
  LastH              := 25;                      { Force Display }
  LastM              := 0;
  LastS              := 0;
  DumpDone           := FALSE;
  TimeDisp           := TRUE;
  Stagger            := Random(5);
  LastStagMin        := LastM;
  Timed_Event_Active := FALSE;
  NextMsgCheck       := TRUE;
END.

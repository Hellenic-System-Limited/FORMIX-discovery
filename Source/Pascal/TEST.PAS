USES Dos,Crt,F6StdUtl;


CONST Runs : INTEGER = 32000;

VAR S1,S2 : ARRAY[0..100] OF INTEGER;
    I : INTEGER;
    Start,Stop : LONGINT;
    StartTime,stopTime : DOUBLE;
    Hour, Minute, Second, Sec100: Word;

PROCEDURE GetStartTime;
BEGIN
 GetTime(Hour, Minute, Second, Sec100);
 StartTime := Hour*60*60+Minute*60+Second+Sec100/100;
END;

PROCEDURE GetStopTime;
BEGIN
 GetTime(Hour, Minute, Second, Sec100);
 StopTime := Hour*60*60+Minute*60+Second+Sec100/100;
 WriteLn('Time Ellapsed is ',(sTopTime-StartTime):9:2);
END;





BEGIN
{ IF ParamCount > 0 THEN VAL(ParamStr(1),Runs,I);
 IF Runs = 0 THEN Runs := 10000;}
 Randomize;
 FOR I := 0 TO 100 DO S1[I] := Random(200);
 Move(S1,S2,SizeOf(S2));
 S2[0] := S1[0]+10;
 GetStartTime;
 FOR I := 1 TO Runs DO MemComp(S1,S1,SizeOf(S1));
 GetStopTime;

 GetStartTime;
 FOR I := 1 TO Runs DO MemComp(S1,S2,SizeOf(S1));
 GetStopTime;
 WriteLn; WriteLn;

GetStartTime;
 FOR I := 1 TO Runs DO MemCompare(S1,S1,SizeOf(S1));
 GetStopTime;


 GetStartTime;
 FOR I := 1 TO Runs DO MemCompare(S1,S2,SizeOf(S1));
 GetStopTime;

END.



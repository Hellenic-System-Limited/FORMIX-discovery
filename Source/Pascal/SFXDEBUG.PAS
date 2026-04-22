{$O+,F+}
{$I F6COMP}
UNIT SFXDEBUG;
INTERFACE
USES F6StdUtl,F6StdCtv,DOS,CRT;



CONST DBUG_FNAME = 'DEBUG';
      DBUG_EXTN  = '.LOG';


Procedure WriteDebugStr(TheStr : STRING);


IMPLEMENTATION

VAR DBUG_FILE : FILE OF BYTE;
    Sequence  : LONGINT;

PROCEDURE WriteDebugStr(TheStr : STRING);
VAR ErrInt : INTEGER;
    OldFMode,LPA : INTEGER;
    MachineID    : STRING[12];
    SeqStr       : STRING[11];

BEGIN
 MachineID := GetEnv('fxini');
 IF MachineID ='' THEN MachineID := DBUG_FNAME;
 OldFMode := FileMode;
 FileMode := READ_WRITE OR DENY_ALL;
 Assign(DBUG_FILE,MachineID+DBUG_EXTN);
 ErrInt := -1;
 WHILE (ErrInt <> 0) DO
  BEGIN
   {$i-}
   Reset(DBUG_FILE);
   {$i+}
   ErrInt := IOResult;
   IF ErrInt = 5 THEN Continue;
   IF ErrInt = FILE_NOT_FOUND THEN
    BEGIN
     ReWrite(DBUG_FILE);
    END
   ELSE IF ErrInt = 0 THEN Seek(DBUG_FILE,FileSize(DBUG_FILE));
  END;
 SeqStr := IntToZeroStr(Sequence,10);
 SeqStr[11] :=':';
 FOR LPA := 1 TO 11 DO
   Write(DBUG_FILE,BYTE(SeqStr[LPA]));
 FOR LPA := 1 TO Length(TheStr) DO
  BEGIN
   Write(DBUG_FILE,BYTE(TheStr[LPA]));
  END;
 TheStr[1] :=#13;
 Write(DBUG_FILE,BYTE(TheStr[1]));
 TheStr[1] :=#10;
 Write(DBUG_FILE,BYTE(TheStr[1]));
 Close(DBUG_FILE);
 FileMode := OldFMode;
 INC(Sequence);
END;

(*
PROCEDURE WriteDebugStr(TheStr : STRING);
BEGIN
END;
*)
BEGIN
 Sequence := 0;
END.
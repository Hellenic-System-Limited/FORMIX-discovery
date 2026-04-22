(****************************************************************************
*  UNIT          : FXExit                                                   *
*  AUTHOR        : N. S. Mod From S.W CODE                                  *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : FORMIX System Exit                                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXExit;

INTERFACE

USES SFXGraph,F6StdUtl,FXModCtv,F6StdCtv,FXCfg,SfxScale,F6Btrv;

VAR BorlandExitProc : Pointer;

PROCEDURE Exit_System(ECode : INTEGER);

IMPLEMENTATION
USES SFXFGen;
TYPE TFarPointer = PACKED RECORD
                    Offset  : WORD;
                    Segment : WORD;
                  END;

PROCEDURE RTEHandler; FAR;
VAR RTEFile : TEXT;
    RTEStr  : STRING[3];

  FUNCTION StrHex(w : WORD) : STRING;
  VAR HexStr : STRING[4];

    FUNCTION HexIt(V : BYTE) : CHAR;
    BEGIN
     IF V <= 9 THEN HexIt := CHR(V+48)
     ELSE HexIt := CHR(V+55);
    END;

  BEGIN
   HexStr[1] := HexIt(Hi(w) DIV $10);
   HexStr[2] := HexIt(Hi(w) MOD $10);
   HexStr[3] := HexIt(Lo(w) DIV $10);
   HexStr[4] := HexIt(Lo(w) MOD $10);
   HexStr[0] := CHR(4);
   StrHex := HexStr;
  END;

BEGIN
 { Formix Run Time Error Handler - Writes Time, Date, Version, And RTE To File }
 ExitProc := BorlandExitProc;
 MainScaleDone;
 GraphDone;
 IF ExitCode > 0 THEN
  BEGIN
   Assign(RTEFile,'SRUNERR.ERR');
   {$I-}
   Append(RTEFile);
   {$I+}
   IF IOResult <> 0 THEN
    BEGIN
     { Try To ReWrite File }
     {$I-}
     Rewrite(RTEFile);
     {$I+}
     IF IOResult <> 0 THEN Exit;
    END;
   STR(ExitCode:3,RTEStr);
   Write(RTEFile,Date,' ',Time,' Scale Formix v',Version_Number);
   IF ExitCode <> $FF THEN
     WriteLn(RTEFile,' Error ',Add_Zeros(RTEStr),
                     ' ',StrHex(TFarPointer(ErrorAddr).Segment),
                     ':',StrHex(TFarPointer(ErrorAddr).Offset))
   ELSE WriteLn(RTEFile,' Control Break - User Termination ');
   Close(RTEFile);
  END;
 CloseAllFilesIfPossible;
END;

PROCEDURE Exit_System(ECode : INTEGER);
VAR j,i : BYTE;
BEGIN
 {************************************************************************
 * Any Code That Needs to be run before the program is exited            *
 *************************************************************************}
 Dispose_Config_Rec;
 CloseGraphMode;
{$IFDEF DPMI}
 IF ECode <> BMemError THEN FreeDPMIBtrvMem
 ELSE ECode := 0;
{$ENDIF}
 IF ECode <> -1 THEN Halt(ECode);
END;

BEGIN
 BorlandExitProc := ExitProc;
 ExitProc := @RTEHandler;
END.

Program Conv1067;
{$I F6COMP}
{$IFNDEF FPC} make 64 bit compatible prog {$ENDIF}

USES Crt,FILEOBJ,F6StdWin,F6StdUtl,f6bTRV,F6StdCtv,F6StdWn1,F6STDFIL,FXFTrnW;


CONST
     LIVE_FILE_NAME   = TransWarnings_FileName;
     BACKUP_FILE_NAME = 'FXTranWr.066';
     TEMP_FILE_NAME   = 'FXTranWr.NEW';

TYPE
     TOldRecord = TTransWarnRecord;

     POldFile = ^TOldFile;
     TOldFile = OBJECT(TBtrvFileObject)
       FUNCTION GetFileSpec(VAR FileBuf : FILE_SPEC): INTEGER; VIRTUAL;
     END;

VAR
  OldFile   : POldFile;
  NewFile   : PTransWarnFile;
  OldRecord : TOldRecord;
  NewRecord : TTransWarnRecord;


FUNCTION TOldFile.GetFileSpec(VAR FileBuf : FILE_SPEC): INTEGER; {VIRTUAL;}
BEGIN
 WITH FileBuf DO
  BEGIN
   Rec_Len   := SizeOf(TOldRecord);
  END;
 GetFileSpec := 0;
END;

FUNCTION Init : BOOLEAN;
BEGIN
 Init := FALSE;
 Win_Init;
{$IFDEF DPMI}
 SetupDPMIBtrvMem(4096);
{$ENDIF}

 OldFile := New(POldFile, Init(LIVE_FILE_NAME));
 WITH OldFile^ DO
  BEGIN
   IF ShowError(OpenFile,'Open') <> 0 THEN Exit;
   IF GetRecordLength <> SizeOf(TOldRecord) THEN { get record length will auto open file}
    BEGIN
     Disp_Error_Msg(LIVE_FILE_NAME+': Current record size is not '+
                    IntToStr(SizeOf(TOldRecord),1));
     EXIT;
    END;
  END;
 New(NewFile,  Init(TEMP_FILE_NAME));
 WITH NewFile^ DO IF ShowError(Create,'Create') <> 0 THEN Exit;
 WITH NewFile^ DO IF ShowError(OpenFile,'Open') <> 0 THEN Exit;
 Init := TRUE;
END;


PROCEDURE Run;
VAR ErrInt : SMALLINT;
    NumRecords : LONGINT;
    CurrentRec : LONGINT;
    CurrentX,CurrentY : SMALLINT;
    i : SMALLINT;
    TempFile : FILE;
    ReadErr  : SMALLINT;
    NewFileErr : SMALLINT;

BEGIN
 NumRecords := OldFile^.RecordCount;
 CurrentRec := 0;
 WriteLn('Converting '+LIVE_FILE_NAME);

 Write('Record Conversion Count :');
 CurrentX := WhereX;
 CurrentY := WhereY;
 FillChar(OldRecord,SizeOF(OldRecord),#0);
 ErrInt := OldFile^.ReadRecord('SF',FALSE,FALSE,OldRecord,0);
 WHILE (ErrInt = 0) DO
  BEGIN
   FillChar(NewRecord,SizeOF(NewRecord),#0);
   Move(OldRecord, NewRecord, SizeOf(OldRecord));
   WITH NewRecord DO
    BEGIN
     TRW_SrcConcessionNo := 0;
     FillChar(TRW_Free, SizeOf(TRW_Free), 0);{old files seem to have spaces for NULL}
    END;
   NewFileErr:= NewFile^.AddRecord(NewRecord);
   IF NewFileErr = 0 THEN
     Inc(CurrentRec)
   ELSE
    BEGIN
     WriteLn;
     WriteLn('Transaction '+IntToZeroStr(OldRecord.TRW_Mid,2)+
             '-'+IntToZeroStr(OldRecord.TRW_SerialNo,6)+
             ' error '+IntToStr(NewFileErr,1));
    END;
   GotoXY(CurrentX,CurrentY);
   Write(CurrentRec:1,'/',NumRecords:1);
   ErrInt := OldFile^.ReadRecord('SN',FALSE,FALSE,OldRecord,0);
  END;
 GotoXY(CurrentX,CurrentY);
 Write(CurrentRec:1,'/',NumRecords:1);
 OldFile^.CloseFile;
 NewFile^.CloseFile;
 IF NOT (BtrvErrType(ErrInt) IN [berr_None,berr_NAck]) THEN
  BEGIN
   WriteLn;
   WriteLn('Error '+IntToStr(ErrInt,1)+' reading existing file. Conversion aborted.')
  END
 ELSE
  BEGIN
   WriteLn;
   WriteLn;
   WriteLn('Attempting to rename '+LIVE_FILE_NAME+' to '+BACKUP_FILE_NAME);
   Assign(TempFile,LIVE_FILE_NAME);
   IF RenameOverwrite(TempFile,BACKUP_FILE_NAME) <> 0 THEN
    BEGIN
     WriteLn('Error Renaming');
     Exit;
    END;
   WriteLn('Attempting to rename '+TEMP_FILE_NAME+' to '+LIVE_FILE_NAME);
   Assign(TempFile,TEMP_FILE_NAME);
   IF RenameOverwrite(TempFile,LIVE_FILE_NAME) <> 0 THEN
    BEGIN
     WriteLn('Error Renaming');
     Exit;
    END;
  END;
END;

PROCEDURE Done;
BEGIN
 IF Assigned(OldFile) THEN
   Dispose(OldFile,Done);
 IF Assigned(NewFile) THEN
   Dispose(NewFile,Done);
{$IFDEF DPMI}
 FreeDPMIBtrvMem;
{$ENDIF}
 Win_Close;
// Dispose(Config_Rec);
END;


BEGIN
 IF Init THEN
  BEGIN
   Run;
  END;
 Done;
END.

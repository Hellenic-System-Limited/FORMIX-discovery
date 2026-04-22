PROGRAM CONV1014;

USES
 CRT,F6StdUtl,F6StdWin,F6StdWn1,FXFTrn;


VAR
 OldTransFile : PTransFile;
 NewTransFile : PTransFile;
 ConvErr      : INTEGER;
 TotRecs      : LONGINT;
 RecsDone     : LONGINT;
 TranRecErr   : INTEGER;
 TransRec     : TTranRecord;


CONST OldTransaction_FileName = 'FXTRANS.013';

PROCEDURE Init_System;
VAR ErrInt,i    : INTEGER;
    NewRange    : STRING[1];
    NewUnitName : STRING[5];
BEGIN
 Win_Init;
 {CheckSnow := FALSE;}
 {StopProcess := FALSE;}
{$IFDEF DPMI}
 IF SetUpDPMIBtrvMem(4096) <> 0 THEN
  BEGIN
   Show_Btrv_Err(BMemError);
   Exit_System(0);
  END;
{$ENDIF}

 ClrScr;
END;



BEGIN
 Init_System;
 OldTransFile := New(PTransFile,Init(OldTransaction_FileName));
 NewTransFile := New(PTransFile,Init(Transaction_FileName));

 { is btrieve running ? }
 ConvErr := Show_Btrv_Err(NewTransFile^.OpenFile);
 IF ConvErr = 0 THEN
   ConvErr := Show_Btrv_Err(NewTransFile^.CloseFile);

 { rename existing file }
 IF ConvErr = 0 THEN
  BEGIN
   IF RenameFile(Transaction_FileName, OldTransaction_FileName) THEN
     WriteLn(Transaction_FileName+' has been renamed to '+
             OldTransaction_FileName)
   ELSE
    BEGIN
     Disp_Error_Msg('Failed to rename '+ Transaction_FileName +
                    ' to '+ OldTransaction_FileName);
     ConvErr := 9999;
    END;
  END;

 { Open old file }
 IF ConvErr = 0 THEN
  BEGIN
   ConvErr := OldTransFile^.OpenFile;
   IF ConvErr <> 0 THEN
    BEGIN
     Disp_Error_Msg('Failed to open '+OldTransaction_FileName);
     Show_Btrv_Err(ConvErr);
    END;
  END;

 { Create and open new file }
 IF ConvErr = 0 THEN
   ConvErr := NewTransFile^.CheckIfThere('New Transaction');

 IF ConvErr = 0 THEN
  BEGIN
   ConvErr := NewTransFile^.OpenFile;
   IF ConvErr <> 0 THEN
    BEGIN
     Disp_Error_Msg('Failed to open '+Transaction_FileName);
     Show_Btrv_Err(ConvErr);
    END;
  END;

 { copy records from one to the other }
 IF ConvErr = 0 THEN
  BEGIN
   TotRecs  := OldTransFile^.RecordCount;
   RecsDone := 0;
   WriteLn;
   TranRecErr := OldTransFile^.ReadRecord('SF',FALSE,FALSE,TransRec,0);
   WHILE TranRecErr = 0 DO
    BEGIN
     FillChar(TransRec.Reserved, SizeOf(TransRec.Reserved), #0);

     IF Show_Btrv_Err(NewTransFile^.AddRecord(TransRec)) = 0 THEN
       Inc(RecsDone);

     Write(#13,RecsDone, ' of ', TotRecs, ' added');
     TranRecErr := OldTransFile^.ReadRecord('SN',FALSE,FALSE,TransRec,0);
    END;
   WriteLn(#13,RecsDone, ' of ', TotRecs);
  END;

 OldTransFile^.CloseFile;
 NewTransFile^.CloseFile;
 Dispose(OldTransFile,Done);
 Dispose(NewTransFile,Done);

END.
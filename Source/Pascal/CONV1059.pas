Program Conv1059;
{$I F6COMP}
{$IFNDEF FPC} make 64 bit compatible prog {$ENDIF}

USES Crt,FILEOBJ,F6StdWin,F6StdUtl,f6bTRV,F6StdCtv,F6StdWn1,F6STDFIL,FXFILot;


CONST
     PrevVerSuffix = '058';
     //PrevRecSize   = 163;

     LI_FileName = 'LOT.FIL';
TYPE

  POld_LotIngredientRecord = ^TOld_LotIngredientRecord;
  TOld_LotIngredientRecord = PACKED RECORD
   LI_Ingredient : STRING[8];       {0.0}
   LI_ScaleID    : WORD;            {0.1}
   LI_LotNumber  : STRING[8];
  END;

  POldLotIngredientFileObject = ^TOldLotIngredientFileObject;
  TOldLotIngredientFileObject = OBJECT(TBtrvFileObject)
    FUNCTION GetFileSpec(VAR FileBuf : FILE_SPEC): INTEGER; VIRTUAL;
  END;

VAR
  OldLotIngredientFile : POldLotIngredientFileObject;
  NewLotIngredientFile : PLotIngredientFile;


FUNCTION TOldLotIngredientFileObject.GetFileSpec(VAR FileBuf : FILE_SPEC): INTEGER;
VAR
    SegC     : BYTE;
BEGIN
 SegC := 0;
 WITH FileBuf DO
  BEGIN
   Rec_Len   := SizeOf(TOld_LotIngredientRecord);
   Page_Size := 1024;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.1 Ingrdient Code}
   INC(SegC,Set_Key(Key_Buf[0],01,08,K_EXTTYPE OR K_SEGMENTED,
       EKT_LSTRING,0));
   { 0.1 Machine ID }
   INC(SegC,Set_Key(Key_Buf[1],9,02,K_EXTTYPE ,EKT_INTEGER,0));
  END;
 GetFileSpec := FileBuf.Ndx_Cnt + SegC;
END;

FUNCTION InitConv : BOOLEAN;
BEGIN
  InitConv := FALSE;
  New(OldLotIngredientFile, Init(LI_FileName));
  WITH OldLotIngredientFile^ DO
   BEGIN
    IF ShowError(OpenFile,'Open') <> 0 THEN Exit;
    IF OldLotIngredientFile^.GetRecordLength <> SizeOf(TOld_LotIngredientRecord) THEN { get record length will auto open file}
     BEGIN
      Disp_Error_Msg(LI_FileName+': Current record size is not '+
                     IntToStr(SizeOf(TOld_LotIngredientRecord),1));
      EXIT;
     END;
   END;

  New(NewLotIngredientFile,  Init('LOT.NEW'));
  WITH NewLotIngredientFile^ DO IF ShowError(Create,'Create') <> 0 THEN Exit;
  WITH NewLotIngredientFile^ DO IF ShowError(OpenFile,'Open') <> 0 THEN Exit;
  InitConv := TRUE;
END;


FUNCTION ConvertLotIngredientFile : BOOLEAN;
VAR ErrInt : INTEGER;
    NumRecords : LONGINT;
    CurrentRec : LONGINT;
    CurrentX,CurrentY : INTEGER;
    OldRecord : TOld_LotIngredientRecord;
    NewRecord : TLotIngredientRecord;
BEGIN
 ConvertLotIngredientFile := FALSE;
 NumRecords := OldLotIngredientFile^.RecordCount;
 CurrentRec := 0;
 WriteLn;
 WriteLn('Converting '+LI_FileName);

 Write('Record Conversion Count :');
 CurrentX := WhereX;
 CurrentY := WhereY;

 ErrInt := OldLotIngredientFile^.ReadRecord('SF',FALSE,FALSE,OldRecord,0);
 WHILE (ErrInt = 0) DO
  BEGIN
   FillChar(NewRecord, SizeOf(NewRecord), 0);
   WITH NewRecord DO
    BEGIN
     LI_Ingredient := OldRecord.LI_Ingredient;
     LI_ScaleID    := OldRecord.LI_ScaleID;
     LI_LotNumber  := OldRecord.LI_LotNumber;

     IF NewLotIngredientFile^.ShowError(NewLotIngredientFile^.AddRecord(NewRecord),
                                'Adding '+ NewRecord.LI_Ingredient) = 0 THEN
      BEGIN
       Inc(CurrentRec);
       GotoXY(CurrentX,CurrentY);
       Write(CurrentRec:1,'/',NumRecords:1);
      END;
    END;
   ErrInt := OldLotIngredientFile^.ReadRecord('SN',FALSE,FALSE,OldRecord,0);
  END;
 GotoXY(CurrentX,CurrentY);
 Write(CurrentRec:1,'/',NumRecords:1);

 OldLotIngredientFile^.CloseFile;
 NewLotIngredientFile^.CloseFile;
 ConvertLotIngredientFile := CurrentRec >= NumRecords;
END;


PROCEDURE RenameFiles;
VAR
  TempFile         : FILE;
  IOErr : INTEGER;
BEGIN
  WriteLn;
  WriteLn('Attempting to rename '+LI_FileName+' to LOT.'+PrevVerSuffix);
  Assign(TempFile,LI_FileName);
  IOErr := RenameOverwrite(TempFile,'LOT.'+PrevVerSuffix);
  IF IOErr = 0 THEN
    WriteLn('Done')
  ELSE
   BEGIN
    WriteLn('Error ',IOErr,' Renaming');
    Exit;
   END;
  WriteLn('Attempting to rename LOT.NEW to '+LI_FileName);
  Assign(TempFile,'LOT.NEW');
  IOErr := RenameOverwrite(TempFile,LI_FileName);
  IF IOErr = 0 THEN
    WriteLn('Done')
  ELSE
   BEGIN
    WriteLn('Error ',IOErr,' Renaming');
    Exit;
   END;
END;





BEGIN
 Win_Init;
{$IFDEF DPMI}
 SetupDPMIBtrvMem(4096);
{$ENDIF}
 IF InitConv THEN
  BEGIN
   IF (NOT ConvertLotIngredientFile) THEN
     WriteLn('File Conversion failed - abandon upgrade')
   ELSE
    BEGIN
     {now do second file conversion}
     {if secondconversion then begin}

     RenameFiles;
    END;
  END;


 Dispose(OldLotIngredientFile,Done);
 Dispose(NewLotIngredientFile,Done);
{ OldPackFile^.CloseFile;}
{$IFDEF DPMI}
 FreeDPMIBtrvMem;
{$ENDIF}
 Win_Close;
END.


(****************************************************************************
*  UNIT          : FXFSerNo                                                  *
*  AUTHOR        :                                                          *
*  DATE          :                                                          *
*  PURPOSE       : Btrieve file for storing and changing Serial nos.
                   and system wide variable strings.
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFSerNo;

INTERFACE

USES Crt,Dos,FILEOBJ,F6Btrv,F6Stdutl,F6StdCTV{,FXDetail};




FUNCTION  GetNextOrderNo : LONGINT; {Returns zero if fails.}
          { DON'T CALL THIS DIRECTLY - USE NextAvaiableOrdNo(). }

PROCEDURE ReturnOrderNo(SerNo : LONGINT); {for recycling}




CONST
     SerialNoFileName = 'COMSERNO.FIL';

TYPE

     SerialB_ptr = ^SerialB_Record;
     SerialB_Record = PACKED RECORD
      Serial_KeyName     : STRING[35]; { Primary key                    }
      Serial_Number      : LONGINT;    { last serial no. used (USUALLY) }
      Serial_CurrString  : STRING[30]; { used to store global strings   }
      Free_Space         : ARRAY [1..50] OF BYTE;
     END;

TYPE
     PSerFile = ^TSerFile;
     TSerFile = OBJECT(TBtrvFileObject)
      FUNCTION  GetFileSpec (VAR FileBuf : FILE_SPEC) : INTEGER; VIRTUAL;
     END;

VAR
     SerialNoFile  : PSerFile;




IMPLEMENTATION



TYPE
     TSerialObject = OBJECT  { ABSTRACT }
      SP_SerFile    : PSerFile;
      SP_KeyName    : STRING[35];
      SP_MinNo      : LONGINT;
      SP_MaxNo      : LONGINT;
      SP_DefaultStr : STRING[30];
      SP_FileRecord : SerialB_Record; { work record}
      CONSTRUCTOR Init(SerFile     : PSerFile;
                       KeyName     : STRING;
                       MinNo,MaxNo : LONGINT;
                       DefaultStr  : STRING);
      PROCEDURE   SetFileRecordToDefault;    VIRTUAL;
      FUNCTION    ReadLockRecord : INTEGER;  VIRTUAL;
      PROCEDURE   SetFileRecFromOldFile;     VIRTUAL; { ABSTRACT }
     END;


     TPreIncrementSerialNo = OBJECT(TSerialObject) { NUMERICAL SERIAL NO. }
      CONSTRUCTOR Init(SerFile : PSerFile;
                       KeyName     : STRING;
                       MinNo,MaxNo : LONGINT);
      FUNCTION    TakeNextAvailableNo(VAR SerialNo : LONGINT) : INTEGER; VIRTUAL;
     END;


     TRecycledSerialNo = OBJECT(TPreIncrementSerialNo)
      FUNCTION    GetRecycleKeyNameForSerNo(ForSerialNo : LONGINT) : STRING; VIRTUAL;
      PROCEDURE   ReturnSerialNo(SerialNo : LONGINT);
      FUNCTION    ReadLockRecycledRecord : INTEGER;
      FUNCTION    TakeNextAvailableNo(VAR SerialNo : LONGINT) : INTEGER; VIRTUAL;
     END;




     {---- Decendants used by program --- }
     TOrderSerialNo = OBJECT(TRecycledSerialNo)
      CONSTRUCTOR Init;
      {PROCEDURE   SetFileRecFromOldFile;     VIRTUAL;}
     END;


{----------------------------- END OF TYPES ------------------------------}




{Set up file & keys to correct size}
FUNCTION TSerFile.GetFileSpec(VAR FileBuf : FILE_SPEC) : INTEGER;
VAR
     i        : BYTE;
     BSerial  : SerialB_Record;
BEGIN
 WITH FileBuf DO
  BEGIN
   Rec_len     := SizeOf(SerialB_Record);
   Page_size   := 4096;
   Ndx_cnt     := 1;
   Record_Cnt  := 0;
   File_Flags  := 0;
   FOR i := 0 TO 1 DO Reserved[i] := 0;
   Pre_Alloc   := 0;
   {Key is serial_description}
   Set_Key(KEY_BUF[0],BFieldPos(BSerial,BSerial.Serial_KeyName),
                                Sizeof(BSerial.Serial_KeyName),
                                K_EXTTYPE,EKT_LSTRING,0);
   GetFileSpec := NDX_CNT;
  END;
END;


{------------------------- TSerialObject methods -----------------------}
CONSTRUCTOR TSerialObject.Init(SerFile     : PSerFile;
                               KeyName     : STRING;
                               MinNo,MaxNo : LONGINT;
                               DefaultStr  : STRING);
BEGIN
 SP_SerFile    := SerFile;
 SP_KeyName    := KeyName + Space_String;
 SP_MinNo      := MinNo;
 SP_MaxNo      := MaxNo;
 SP_DefaultStr := DefaultStr;
 SetFileRecordToDefault;
END;

PROCEDURE TSerialObject.SetFileRecordToDefault;
BEGIN
 FillChar(SP_FileRecord, SizeOf(SP_FileRecord), 0);
 WITH SP_FileRecord DO
  BEGIN
   Serial_KeyName     := SP_KeyName;
   Serial_Number      := SP_MinNo -1;
   Serial_CurrString  := SP_DefaultStr;
  END;
END;

FUNCTION TSerialObject.ReadLockRecord : INTEGER;
VAR FileErr : INTEGER;
BEGIN
 REPEAT
  SetFileRecordToDefault;
  FileErr := SP_SerFile^.ReadRecord('EQ',TRUE,FALSE,SP_FileRecord,0);
  IF FileErr = BNoRecord THEN
   BEGIN
    SetFileRecFromOldFile;
    FileErr := SP_SerFile^.AddRecord(SP_FileRecord);
    IF NOT (FileErr IN [0,BDuplicate]) THEN
       BREAK; { critical error }
   END
  ELSE
    BREAK; { either read it OK, or theres a critical error }
 UNTIL FALSE;
 ReadLockRecord := FileErr;
END;


PROCEDURE TSerialObject.SetFileRecFromOldFile;
BEGIN
 { if this serial no. was originally in a DOS record file, this function
   needs to be overwritten to grab the record from the old file and convert
   it to the btrieve file record format.
 }
 SetFileRecordToDefault;
END;



{------------------ TPreIncrementSerialNo methods -------------------------}
CONSTRUCTOR TPreIncrementSerialNo.Init(SerFile : PSerFile;
                                       KeyName     : STRING;
                                       MinNo,MaxNo : LONGINT);
BEGIN
 INHERITED Init(SerFile,KeyName,MinNo,MaxNo,'');
END;


FUNCTION TPreIncrementSerialNo.TakeNextAvailableNo(VAR SerialNo : LONGINT)
                                                  : INTEGER;
{REQUIRES:
 PROMISES: Only sets SerialNo if return error code is 0.
}
VAR FileErr : INTEGER;
BEGIN
 FileErr := SP_SerFile^.OpenFile;
 IF FileErr = 0 THEN
  BEGIN
   FileErr := ReadLockRecord;
   IF FileErr = 0 THEN
    BEGIN
     Inc(SP_FileRecord.SERIAL_Number);
     IF (SP_FileRecord.SERIAL_Number > SP_MaxNo)
     OR (SP_FileRecord.SERIAL_Number < SP_MinNo) THEN
       SP_FileRecord.SERIAL_Number := SP_MinNo;
     FileErr := SP_SerFile^.UpdateRecord(SP_FileRecord);
    END;
   SP_SerFile^.CloseFile; { dont care about result of close }
  END;

 IF FileErr = 0 THEN { written to file OK }
   SerialNo := SP_FileRecord.SERIAL_Number; { as written back to file }
 TakeNextAvailableNo := FileErr;
END;


{------------------ TRecycledSerialNo methods -------------------------}
FUNCTION TRecycledSerialNo.GetRecycleKeyNameForSerNo(
                                              ForSerialNo : LONGINT) : STRING;
BEGIN
 GetRecycleKeyNameForSerNo := Copy(SP_KeyName,1,20)+
                              '.Recyc'+IntToStr(ForSerialNo,9);
END;


PROCEDURE TRecycledSerialNo.ReturnSerialNo(SerialNo : LONGINT);
BEGIN
 IF SP_SerFile^.OpenFile = 0 THEN
  BEGIN
   SetFileRecordToDefault;
   WITH SP_FileRecord DO
    BEGIN
     Serial_KeyName := GetRecycleKeyNameForSerNo(SerialNo);
     Serial_Number  := SerialNo;
    END;
   SP_SerFile^.AddRecord(SP_FileRecord);
   SP_SerFile^.CloseFile;
  END;
END;


FUNCTION TRecycledSerialNo.ReadLockRecycledRecord : INTEGER;
VAR
  FileErr : INTEGER;
  RecycleKeyName : STRING[35];
BEGIN
 SetFileRecordToDefault;
 WITH SP_FileRecord DO
  BEGIN
   RecycleKeyName := GetRecycleKeyNameForSerNo(0);

   Serial_KeyName := RecycleKeyName;
   FileErr := SP_SerFile^.ReadRecord('GE',TRUE,FALSE,SP_FileRecord,0);
   IF (FileErr = 0) THEN { a record is locked }
    BEGIN
     IF NOT Str_Equal(RecycleKeyName, Serial_KeyName, 26) THEN {unrelated record}
      BEGIN
       SP_SerFile^.Unlock_Single;
       SetFileRecordToDefault;
       FileErr := BEndOfFile;
      END;
    END;
  END;
 ReadLockRecycledRecord := FileErr;
END;

FUNCTION TRecycledSerialNo.TakeNextAvailableNo(VAR SerialNo : LONGINT)
                                                  : INTEGER;
{REQUIRES:
 PROMISES: Only sets SerialNo if return error code is 0.
}
VAR FileErr : INTEGER;
BEGIN
 FileErr := SP_SerFile^.OpenFile;
 IF FileErr = 0 THEN
  BEGIN
   FileErr := ReadLockRecycledRecord;
   IF FileErr = 0 THEN { take recycled number }
    BEGIN
     FileErr := SP_SerFile^.DeleteRecord;
     IF FileErr = 0 THEN { deleted ok - return recycled number }
       SerialNo := SP_FileRecord.SERIAL_Number;
    END;

   IF FileErr <> 0 THEN { inc normal serial no record }
    BEGIN
     FileErr := INHERITED TakeNextAvailableNo(SerialNo);
    END;

   SP_SerFile^.CloseFile; { dont care about result of close }
  END;

 TakeNextAvailableNo := FileErr;
END;



(******** E X A M P L E   F R O M   F O P S 6

{--------------------- MOVEMENT EXPORT SERIAL NO --------------------------}

CONSTRUCTOR TMovementExpSerialNo.Init;
BEGIN
 INHERITED Init(SerialNoFile,'Movement Export No.',1,99999999);
END;

PROCEDURE TMovementExpSerialNo.SetFileRecFromOldFile;
VAR NextNoFromOldFile : LONGINT;
BEGIN
 SetFileRecordToDefault;
 NextNoFromOldFile := F6Serial.ObsoleteGetMoveExportNo;
 IF NextNoFromOldFile > 0 THEN
   SP_FileRecord.SERIAL_Number := NextNoFromOldFile - 1;
END;

FUNCTION GetMoveExportNo : LONGINT;
VAR
  SerNo : LONGINT;
  SerialNoObject : TMovementExpSerialNo;
BEGIN
 SerNo := -1; { error return value }
 SerialNoObject.Init;
 SerialNoObject.TakeNextAvailableNo(SerNo);
 GetMoveExportNo := SerNo;
END;
*)


{----------------------- RECIPE ORDER NO. --------------------------}

CONSTRUCTOR TOrderSerialNo.Init;
BEGIN
 INHERITED Init(SerialNoFile,'Recipe Order No.',1,999999);
END;
(*  shouldnt need this anymore 7/8/2019
PROCEDURE TOrderSerialNo.SetFileRecFromOldFile;
{ Latest practice is to serialise the order numbers and have the batch nos
  reflect the last part of the order number combined with the mix no.
  Consequently we will start the order numbers at the next batch number
  available.
}
VAR NextNoFromOldFile : LONGINT;
BEGIN
 SetFileRecordToDefault;
 NextNoFromOldFile := FXDetail.GetAutoBatchNumber;
 IF NextNoFromOldFile > 0 THEN
   SP_FileRecord.SERIAL_Number := NextNoFromOldFile - 1;
END;
*)
FUNCTION GetNextOrderNo : LONGINT;
{PROMISES Returns zero if fails.
}
VAR
  SerNo : LONGINT;
  SerialNoObject : TOrderSerialNo;
BEGIN
 SerNo := 0; { error return value }
 SerialNoObject.Init;
 SerialNoObject.TakeNextAvailableNo(SerNo);
 GetNextOrderNo := SerNo;
END;

PROCEDURE ReturnOrderNo(SerNo : LONGINT);
VAR
  SerialNoObject : TOrderSerialNo;
BEGIN
 SerialNoObject.Init;
 SerialNoObject.ReturnSerialNo(SerNo);
END;
{-------------------------}

END.

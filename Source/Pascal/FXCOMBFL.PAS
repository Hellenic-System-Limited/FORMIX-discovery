(****************************************************************************
*  UNIT          : FXCOMBFL                                                 *
*  AUTHOR        : S. Wright (Seperated From Main Recipie Code By N.Spooner)*
*  DATE          : 23.09.98                                                *
*  PURPOSE       : FORMIX DUAL FILE (HEADER/LINE) OBJECT                    *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXCOMBFL;
INTERFACE
USES FILEOBJ,F6Btrv,F6StdCtv;

TYPE PDeleteList = ^TDeleteList;
     TDeleteList = PACKED RECORD
       RecPos    : LONGINT;
       Next      : PDeleteList;
     END;

     {A General Object For Combining Headers And Line Records}
     PCombineFile = ^TCombineFile;
     TCombineFile = OBJECT
       HeaderFile  : PBtrvFileObject;         { Component File Instances }
       LineFile    : PBtrvFileObject;
       BtrvErr     : INTEGER;
       OpenErr     : INTEGER;
       OpenCount   : INTEGER;
       CONSTRUCTOR Init;
       DESTRUCTOR  Done;
       PROCEDURE   ClearDeleteList(VAR Header : PDeleteList);
       PROCEDURE   DeleteLineRecords(VAR RecBuff;FirstRec : PDeleteList);
       FUNCTION    OpenFile : INTEGER; Virtual;
       FUNCTION    CloseFile : INTEGER; Virtual;
       FUNCTION    Read_Header_Record(    Operation   : OpCodeStr;
                                          Lock,
                                          Multi       : BOOLEAN;
                                      VAR RecBuff;
                                          Key         : BYTE) : INTEGER; Virtual;
    END;

    TLineRecord = OBJECT
      CONSTRUCTOR INIT;
      DESTRUCTOR Done;
      FUNCTION  LineRecordInRange : BOOLEAN; VIRTUAL;
      PROCEDURE PrimeLineRecordKey(VAR Header);VIRTUAL;
      FUNCTION  ReadLineRecord(FileStruct :PCombineFile;Op :STRING) : INTEGER;VIRTUAL;
      FUNCTION  GetLineNumber : INTEGER;VIRTUAL;
     END;


IMPLEMENTATION

PROCEDURE Abstract;
BEGIN
 RunError(211);
END;

{================================================================}
{===============LINE OBJECT METHODS==============================}
{================================================================}
CONSTRUCTOR TLineRecord.INIT;
BEGIN
END;

DESTRUCTOR TLineRecord.Done;
BEGIN
END;

FUNCTION TLineRecord.LineRecordInRange : BOOLEAN;
BEGIN
 Abstract;
END;

PROCEDURE TLineRecord.PrimeLineRecordKey(VAR Header);
BEGIN
 Abstract;
END;

FUNCTION TLineRecord.ReadLineRecord(FileStruct :PCombineFile;Op:STRING) : INTEGER;
BEGIN
 Abstract;
END;

FUNCTION TLineRecord.GetLineNumber : INTEGER;
BEGIN
 Abstract;
END;

{=========================================================================}
{=========================  TCombineFile Methods  ========================}
{=========================================================================}

CONSTRUCTOR TCombineFile.Init;
BEGIN
 OpenErr   := -1;
 BtrvErr   := 0;
 OpenCount := 0;
END;

DESTRUCTOR TCombineFile.Done;
BEGIN
 IF OpenErr <> -1 THEN CloseFile;
 Dispose(HeaderFile,Done);
 Dispose(LineFile,Done);
END;

PROCEDURE TCombineFile.ClearDeleteList(VAR Header : PDeleteList);
VAR TempPtr,DeletePtr : PDeleteList;
BEGIN
 TempPtr := Header;
 WHILE (TempPtr <> NIL) DO
  BEGIN
   DeletePtr := TempPtr;
   TempPtr := TempPtr^.Next;
   Dispose(DeletePtr);
  END;
 Header := NIL;
END;

PROCEDURE TCombineFile.DeleteLineRecords(VAR RecBuff;FirstRec : PDeleteList);
VAR DelPtr  : PDeleteList;
BEGIN
 DelPtr := FirstRec;
 WHILE (DelPtr <> NIL) DO
  BEGIN
     { Get Rec. Direct       }
   IF LineFile^.GetRecordDirect(DelPtr^.RecPos,TRUE,FALSE,RecBuff,0) = 0 THEN
    BEGIN
     LineFile^.DeleteRecord;
    END;
   DelPtr := DelPtr^.Next;
  END; { END (WHILE) }
END;


FUNCTION TCombineFile.OpenFile : INTEGER;
BEGIN
  INC(OpenCount);
  IF  (HeaderFile^.OpenFile = 0)
  AND (LineFile^.OpenFile = 0) THEN
   BEGIN
    OpenErr := 0;
   END
  ELSE
   BEGIN
    OpenErr := HeaderFile^.OpenErr;
    IF (OpenErr = 0) THEN OpenErr := LineFile^.OpenErr;
    CloseFile;
   END;
 OpenFile := OpenErr;
END;

FUNCTION TCombineFile.Read_Header_Record(Operation   : OpCodeStr;
                                   Lock,Multi  : BOOLEAN;
                                   VAR RecBuff;
                                   Key         : BYTE) : INTEGER;
BEGIN
 Read_Header_Record := HeaderFile^.ReadRecord(Operation,Lock,Multi,RecBuff,Key);
END;


FUNCTION TCombineFile.CloseFile : INTEGER;
BEGIN
 DEC(OpenCount);
 IF OpenCount = 0 THEN
  BEGIN
   IF HeaderFile^.OpenErr = 0 THEN HeaderFile^.CloseFile;
   IF LineFile^.OpenErr = 0 THEN LineFile^.CloseFile;
   OpenErr := -1;
  END;
END;


END.
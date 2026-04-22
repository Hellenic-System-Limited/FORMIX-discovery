(****************************************************************************
*  UNIT          : FXFCMAC                                                  *
*  AUTHOR        : S. Wright (Moved To Seperate Unit (Was By N. Spooner)    *
*  DATE          : 23/09/98                                                 *
*  PURPOSE       : FORMIX REPORT MACRO COMBINED FILE OBJECT                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFCMAC;

INTERFACE
USES FILEOBJ,F6Btrv,FXCOMBFL,F6StdCtv,FXCfg,F6StdUtl,FXModCtv,FXFMacro;

TYPE PMacroGroupRecord = ^TMacroGroupRecord;
     TMAcroGroupRecord = PACKED RECORD
       Line : TMacroLineRecord;
       Item : TRepMacroRecord;
     END;

     PMacroRecord = ^TMacroRecord;
     TMacroRecord = PACKED RECORD
      MAC_Header : TMacroHeaderRecord;
      MAC_Lines  : ARRAY [1..MAX_LINES_ON_RECORD] OF PMacroGroupRecord;
      MAC_LinePos: ARRAY [1..MAX_LINES_ON_RECORD] OF LONGINT;
      MAC_DeleteList : PDeleteList;
     END;

     PCombineMacroFile = ^TCombineMacroFile;
     TCombineMacroFile = OBJECT(TCombineFile)
       CONSTRUCTOR Init(HeaderName,DetailName  : STRING);
       DESTRUCTOR  Done;
       PROCEDURE   InitRecord      (The_Record : PMacroRecord); Virtual;
       PROCEDURE   ClearLines      (The_Record : PMacroRecord); Virtual;
       FUNCTION    ReadAllRecords(Operation  : OpCodeStr;
                                    Lock,Multi : BOOLEAN;
                                    The_Record : PMacroRecord;
                                    Key        : BYTE) : INTEGER; Virtual;
       FUNCTION    ReadLineRecords (The_Record : PMacroRecord) : INTEGER; Virtual;
       PROCEDURE   UpdateRecord    (The_Record : PMacroRecord); Virtual;
       FUNCTION    AddRecord       (The_Record : PMacroRecord) : INTEGER; Virtual;
       PROCEDURE   DeleteLineRec   (The_Record : PMacroRecord;LineRef : INTEGER);
     END;

     TMacroLine = OBJECT(TLineRecord)
      LineRecord : TMacroLineRecord;
      CONSTRUCTOR INIT;
      FUNCTION  LineRecordInRange : BOOLEAN; VIRTUAL;
      PROCEDURE PrimeLineRecordKey(VAR Header);VIRTUAL;
      FUNCTION  ReadLineRecord(FileStruct :PCombineFile;Op:STRING) : INTEGER;VIRTUAL;
     END;


VAR MacroFile      : PCombineMacroFile;

IMPLEMENTATION

{====================MACRO LINE METHODS========================}
CONSTRUCTOR TMacroLine.INIT;
BEGIN
 FillChar(LineRecord,SizeOf(LineRecord),#0);
END;

FUNCTION TMacroLine.LineRecordInRange : BOOLEAN;
BEGIN
 lineRecordInRange := TRUE;{LineRecord.ML_LineNo IN [1..MAX_LINES_ON_RECORD];}
END;

PROCEDURE TMacroLine.PrimeLineRecordKey(VAR Header);
BEGIN
 WITH LineRecord,TMacroHeaderRecord(Header) DO
  BEGIN
  END;
END;

FUNCTION TMacroLine.ReadLineRecord(FileStruct :PCombineFile;Op:STRING) : INTEGER;
BEGIN
 ReadLineRecord := FileStruct^.LineFile^.ReadRecord(Op,FALSE,FALSE,LineRecord,0);
END;


CONSTRUCTOR TCombineMacroFile.Init(HeaderName,DetailName  : STRING);
BEGIN
 HeaderFile := NEW(PMacroHeaderFile,Init(HeaderName));
 LineFile   := NEW(PMacroLineFile,Init(DetailName));
 RepMacroFile^.OpenFile;
 INHERITED Init;
END;

DESTRUCTOR TCombineMacroFile.Done;
BEGIN
 RepMacroFile^.CloseFile;
 INHERITED Done;
END;

PROCEDURE TCombineMacroFile.InitRecord(The_Record : PMacroRecord);
VAR LPA : INTEGER;
BEGIN
 HeaderFile^.InitRecord(The_Record^.MAC_Header);
 FOR LPA := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   The_Record^.MAC_LinePos[LPA] := 0;
   The_Record^.MAC_Lines[LPA]   := NIL;
  END;
 The_Record^.MAC_DeleteList := NIL;
END;

PROCEDURE TCombineMacroFile.ClearLines(The_Record : PMacroRecord);
VAR LPA        : LONGINT;
BEGIN
 FOR LPA :=1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF Assigned(The_Record^.MAC_Lines[LPA]) THEN
    BEGIN
     Dispose(The_Record^.MAC_Lines[LPA]);
    END;
   The_Record^.MAC_Lines[LPA] := NIL;
  END;
 { ClearDown List Of Records Marked For Deletion }
 ClearDeleteList(The_Record^.MAC_DeleteList);
END;


FUNCTION TCombineMacroFile.ReadAllRecords(Operation  : OpCodeStr;
                           Lock,Multi : BOOLEAN;
                           The_Record   : PMacroRecord;
                           Key        : BYTE) : INTEGER;
BEGIN
 ReadAllRecords := HeaderFile^.ReadRecord(Operation,Lock,Multi,The_Record^.MAC_Header,Key);
 IF (HeaderFile^.BtrvErr = 0) THEN
  BEGIN
   ReadLineRecords(The_Record);
  END;
END;

FUNCTION TCombineMacroFile.ReadLineRecords (The_Record : PMacroRecord) : INTEGER;
VAR MACL : TMacroLineRecord;
    MACR : TRepMacroRecord;
    LineNO : INTEGER;
BEGIN
 WITH The_Record^.MAC_Header DO
  BEGIN
   LineNo := 1;
   MACL.MACL_HeaderRef := MAC_UniqueRef;
   LineFile^.ReadRecord('GE',FALSE,FALSE,MACL,0);
   WHILE (LineFile^.BtrvErr = 0) AND (MACL.MACL_HeaderRef = MAC_UniqueRef) DO
    BEGIN
     NEW(The_Record^.MAC_Lines[LineNo]);
     The_Record^.MAC_Lines[LineNo]^.Line := MACL;
     RepMacroFile^.GetUsingUniqueRef(MACL.MACL_LineRef,FALSE,FALSE,The_Record^.MAC_Lines[LineNo]^.Item);
     The_Record^.MAC_LinePos[LineNo]  := LineFile^.Position;
     INC(LineNo);
     LineFile^.ReadRecord('GN',FALSE,FALSE,MACL,0);
    END;
  END;
END;

PROCEDURE TCombineMacroFile.UpdateRecord(The_Record : PMacroRecord);
VAR OrdLine : INTEGER;
    LineRec : TMacroLineRecord;
BEGIN
 DeleteLineRecords(LineRec,The_Record^.MAC_DeleteList);
 FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   WITH The_Record^ DO
    BEGIN
     IF  (Assigned(MAC_Lines[OrdLine])) THEN
      BEGIN
       IF MAC_LinePos[OrdLine] <> 0 THEN         { Existing Rec. Update  }
        BEGIN
         IF LineFile^.GetRecordDirect(MAC_LinePos[OrdLine],TRUE,FALSE,LineRec,0) = 0 THEN
          BEGIN
           LineFile^.UpdateRecord(MAC_Lines[OrdLine]^.Line);  { Update Rec.           }
          END;
        END
       ELSE
        BEGIN
         LineFile^.AddRecord(MAC_Lines[OrdLine]^.Line);  { Add New Record       }
        END;
      END; { END (Valid Record) }
    END; { END (WITH) }
  END; { END (FOR) }
  INC(The_Record^.MAC_Header.MAC_UpdateCount); { Increment Update Counter   }
  HeaderFile^.UpdateRecord(The_Record^.MAC_Header);
END;

FUNCTION TCombineMacroFile.AddRecord(The_Record : PMacroRecord) : INTEGER;
VAR OrdLine : INTEGER;
BEGIN
 { Add Header Record }
 BtrvERR := HeaderFile^.AddRecord(The_Record^.MAC_Header);
 IF BtrvErr = 0 THEN
  BEGIN
   { Re-Read & Lock Header }
   BtrvErr := HeaderFile^.ReadRecord('EQ',TRUE,FALSE,The_Record^.MAC_Header,0);
   IF BtrvErr = 0 THEN
    BEGIN
     FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
      BEGIN
       WITH The_Record^ DO
        BEGIN
         IF Assigned(MAC_Lines[OrdLine]) THEN
          BEGIN
           MAC_Lines[OrdLine]^.Line.MACL_HeaderRef := MAC_Header.MAC_UniqueRef;
           LineFile^.AddRecord(MAC_Lines[OrdLine]^.Line);  { Add New Record       }
          END; { END (Valid Record) }
        END;
      END;
     HeaderFile^.Unlock_Single;
    END;
  END;
 AddRecord := BtrvErr;
END;


PROCEDURE TCombineMacroFile.DeleteLineRec(The_Record : PMacroRecord;LineRef : INTEGER);
VAR LPA       : INTEGER;
    DelPtr    : PDeleteList;
BEGIN
 IF Assigned(The_Record^.MAC_Lines[LineRef]) THEN
  BEGIN
   IF The_Record^.MAC_LinePos[LineRef] <> 0 THEN
    BEGIN
     DelPtr := NIL;
     NEW(DelPtr);
     IF Assigned(DelPtr) THEN
      BEGIN
       DelPtr^.RecPos := The_Record^.MAC_LinePos[LineRef];
       DelPtr^.Next   := The_Record^.MAC_DeleteList;       { Insert Into List }
       The_Record^.MAC_DeleteList := DelPtr;
      END;
    END;
   Dispose(The_Record^.MAC_Lines[LineRef]);
   The_Record^.MAC_Lines[LineRef] := NIL;
   { Copy Remaining Line Pointers }
   FOR LPA := LineRef TO MAX_LINES_ON_RECORD-1 DO
    BEGIN
     The_Record^.MAC_Lines[LPA]   := The_Record^.MAC_Lines[LPA+1];
     The_Record^.MAC_LinePos[LPA] := The_Record^.MAC_LinePos[LPA+1];
    END;
   { Clear Last Line Pointer As it Has Moved }
   The_Record^.MAC_Lines[MAX_LINES_ON_RECORD]   := NIL;
   The_Record^.MAC_LinePos[MAX_LINES_ON_RECORD] := 0;
  END;
END;


BEGIN
 MacroFile     := NIL;
END.
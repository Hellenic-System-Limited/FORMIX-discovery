(****************************************************************************
*  UNIT          : FXFCPRD                                                  *
*  AUTHOR        : S. Wright (Seperated To This Unit, Was By N.Spooner      *
*  DATE          : 23/09/98                                                 *
*  PURPOSE       : FORMIX PRODUCT FILE (RECIPE GROUPS)                      *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFCPRD;
INTERFACE
USES FILEOBJ,F6Btrv,FXCOMBFL,F6StdCtv,FXCfg,F6StdUtl,FXFProd,FXModCtv;

TYPE PProdRecord = ^TProdRecord;
     TProdRecord = PACKED RECORD
       PR_Header     : TProdHeaderRecord;
       PR_Lines      : ARRAY [1..MAX_LINES_ON_RECORD] OF PProdLineRecord;
       PR_LinePos    : ARRAY [1..MAX_LINES_ON_RECORD] OF LONGINT;
       PR_DeleteList : PDeleteList;
     END;

     PCombineProdFile = ^TCombineProdFile;
     TCombineProdFile = OBJECT(TCombineFile)
       CONSTRUCTOR Init(HeaderName,DetailName  : STRING);
       PROCEDURE   InitRecord      (The_Record : PProdRecord); Virtual;
       PROCEDURE   ClearLines      (The_Record : PProdRecord); Virtual;
       FUNCTION    ReadAllRecords(Operation  : OpCodeStr;
                                    Lock,Multi : BOOLEAN;
                                    The_Record : PProdRecord;
                                    Key        : BYTE) : INTEGER; Virtual;
       FUNCTION    ReadLineRecords (The_Record : PProdRecord) : INTEGER; Virtual;
       PROCEDURE   UpdateRecord    (The_Record : PProdRecord); Virtual;
       FUNCTION    AddRecord       (The_Record : PProdRecord) : INTEGER; Virtual;
       PROCEDURE   DeleteLineRec   (The_Record : PProdRecord;LineRef : INTEGER);
       FUNCTION    LineOkToAddRecord (LineRec : PProdLineRecord) : BOOLEAN;
     END;

     TProdLine = OBJECT(TLineRecord)
      LineRecord : TProdLineRecord;
      CONSTRUCTOR INIT;
      FUNCTION  LineRecordInRange : BOOLEAN; VIRTUAL;
      PROCEDURE PrimeLineRecordKey(VAR Header);VIRTUAL;
      FUNCTION  ReadLineRecord(FileStruct :PCombineFile;Op:STRING) : INTEGER;VIRTUAL;
     END;

VAR ProdFile       : PCombineProdFile;

IMPLEMENTATION

{===============PRODUCT Line METHODS=======================}
CONSTRUCTOR TProdLine.INIT;
BEGIN
 FillChar(LineRecord,SizeOf(LineRecord),#0);
END;

FUNCTION TProdLine.LineRecordInRange : BOOLEAN;
BEGIN
 LineRecordInRange := LineRecord.PL_LineNo IN [1..MAX_LINES_ON_RECORD];
END;

PROCEDURE TProdLine.PrimeLineRecordKey(VAR Header);
BEGIN
 WITH LineRecord,TProdHeaderRecord(Header) DO
  BEGIN
  END;
END;

FUNCTION TProdLine.ReadLineRecord(FileStruct :PCombineFile;Op:STRING) : INTEGER;
BEGIN
 ReadLineRecord := FileStruct^.LineFile^.ReadRecord(Op,FALSE,FALSE,LineRecord,0);
END;

{============== TCombineProdFile METHODS   ==================}
CONSTRUCTOR TCombineProdFile.Init(HeaderName,DetailName : STRING);
BEGIN
 HeaderFile := NEW(PProdHeaderFile,Init(HeaderName));
 LineFile   := NEW(PProdLineFile,Init(DetailName));
 INHERITED Init;
END;

PROCEDURE TCombineProdFile.InitRecord(The_Record : PProdRecord);
VAR LPA : INTEGER;
BEGIN
 HeaderFile^.InitRecord(The_Record^.PR_Header);
 FOR LPA := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   The_Record^.PR_LinePos[LPA] := 0;
   The_Record^.PR_Lines[LPA]   := NIL;
  END;
 The_Record^.PR_DeleteList := NIL;
END;

FUNCTION TCombineProdFile.ReadAllRecords(Operation   : OpCodeStr;
                                            Lock,Multi  : BOOLEAN;
                                            The_Record  : PProdRecord;
                                            Key         : BYTE) : INTEGER;
BEGIN
 ReadAllRecords := HeaderFile^.ReadRecord(Operation,Lock,Multi,The_Record^.PR_Header,Key);
 IF (HeaderFile^.BtrvErr = 0) THEN
  BEGIN
   ReadLineRecords(The_Record);
  END;
END;

FUNCTION TCombineProdFile.ReadLineRecords(The_Record : PProdRecord) : INTEGER;
VAR ProdLine : TProdLineRecord;
BEGIN
 WITH The_Record^.PR_Header DO
  BEGIN
   FILLCHAR(ProdLine,SizeOF(ProdLine),#0);
   ProdLine.PL_ProductCode := PH_ProductCode;
   ProdLine.PL_LineNo      := 0;
   LineFile^.ReadRecord('GE',FALSE,FALSE,ProdLine,0);
   WHILE (LineFile^.BtrvErr = 0) AND (ProdLine.PL_ProductCode = PH_ProductCode) DO
    BEGIN
     IF ProdLine.PL_LineNo IN [1..MAX_LINES_ON_RECORD] THEN
      BEGIN
       NEW(The_Record^.PR_Lines[ProdLine.PL_LineNo]);
       The_Record^.PR_Lines[ProdLine.PL_LineNo]^   := ProdLine;
       The_Record^.PR_LinePos[ProdLine.PL_LineNo]  := LineFile^.Position;
      END;
     LineFile^.ReadRecord('GN',FALSE,FALSE,ProdLine,0);
    END;
  END;
END;

PROCEDURE TCombineProdFile.ClearLines(The_Record : PProdRecord);
VAR LPA        : LONGINT;
{    TempPtr,
    DeletePtr : PDeleteList;}
BEGIN
 FOR LPA :=1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF Assigned(The_Record^.PR_Lines[LPA]) THEN
    BEGIN
     Dispose(The_Record^.PR_Lines[LPA]);
    END;
   The_Record^.PR_Lines[LPA] := NIL;
  END;
 { ClearDown List Of Records Marked For Deletion }
 ClearDeleteList(The_Record^.PR_DeleteList);
END;

PROCEDURE TCombineProdFile.DeleteLineRec(The_Record : PProdRecord;LineRef : INTEGER);
VAR LPA       : INTEGER;
    DelPtr    : PDeleteList;
BEGIN
 IF Assigned(The_Record^.PR_Lines[LineRef]) THEN
  BEGIN
   IF The_Record^.PR_LinePos[LineRef] <> 0 THEN
    BEGIN
     DelPtr := NIL;
     NEW(DelPtr);
     IF Assigned(DelPtr) THEN
      BEGIN
       DelPtr^.RecPos := The_Record^.PR_LinePos[LineRef];
       DelPtr^.Next   := The_Record^.PR_DeleteList;       { Insert Into List }
       The_Record^.PR_DeleteList := DelPtr;
      END;
    END;
   Dispose(The_Record^.PR_Lines[LineRef]);
   The_Record^.PR_Lines[LineRef] := NIL;
   { Copy Remaining Line Pointers }
   FOR LPA := LineRef TO MAX_LINES_ON_RECORD-1 DO
    BEGIN
     The_Record^.PR_Lines[LPA]   := The_Record^.PR_Lines[LPA+1];
     The_Record^.PR_LinePos[LPA] := The_Record^.PR_LinePos[LPA+1];
     IF Assigned(The_Record^.PR_Lines[LPA]) THEN
      BEGIN
       The_Record^.PR_Lines[LPA]^.PL_LineNo := LPA;
      END;
    END;
   { Clear Last Line Pointer As it Has Moved }
   The_Record^.PR_Lines[MAX_LINES_ON_RECORD] := NIL;
   The_Record^.PR_LinePos[MAX_LINES_ON_RECORD] := 0;
  END;
END;


FUNCTION TCombineProdFile.LineOkToAddRecord(LineRec : PProdLineRecord) : BOOLEAN;
BEGIN
 LineOkToAddRecord := (Assigned(LineRec))
     AND ((NOT NowtButSpace(LineRec^.PL_RecipeNo)) OR
          (NOT NowtButSpace(LineRec^.PL_SubProduct)))
     AND (LineRec^.PL_LineNo > 0);
END;


PROCEDURE TCombineProdFile.UpdateRecord(The_Record : PProdRecord);
VAR OrdLine : INTEGER;
    LineRec : TProdLineRecord;
    DelPtr  : PDeleteList;
BEGIN
 DeleteLineRecords(LineRec,The_Record^.PR_DeleteList);
 FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   WITH The_Record^ DO
    BEGIN
     IF LineOkToAddRecord(PR_Lines[OrdLine]) THEN  { Valid Record?         }
      BEGIN
       IF PR_LinePos[OrdLine] <> 0 THEN             { Existing Rec. Update  }
        BEGIN
               { Get Rec. Direct       }
         IF LineFile^.GetRecordDirect(PR_LinePos[OrdLine],TRUE,FALSE,LineRec,0) = 0 THEN
          BEGIN
           LineFile^.UpdateRecord(PR_Lines[OrdLine]^);  { Update Rec.           }
          END;
        END
       ELSE
        BEGIN
         LineFile^.AddRecord(PR_Lines[OrdLine]^);  { Add New Record       }
        END;
      END; { END (Valid Record) }
    END; { END (WITH) }
  END; { END (FOR) }
 INC(The_Record^.PR_Header.PH_UpdateCount); { Increment Update Counter   }
 HeaderFile^.UpdateRecord(The_Record^.PR_Header);
END;

FUNCTION TCombineProdFile.AddRecord(The_Record : PProdRecord) : INTEGER;
VAR OrdLine : INTEGER;
BEGIN
 { Add Header Record }
 BtrvERR := HeaderFile^.AddRecord(The_Record^.PR_Header);

 IF BtrvErr = 0 THEN
  BEGIN
   { Re-Read & Lock Header }
   {Need To reread the record to store the unique reference in line records}
   BtrvErr := HeaderFile^.ReadRecord('EQ',TRUE,FALSE,The_Record^.PR_Header,0);
   IF BtrvErr = 0 THEN
    BEGIN
     FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
      BEGIN
       WITH The_Record^ DO
        BEGIN
         IF Assigned(PR_Lines[OrdLine]) THEN
          BEGIN
           PR_Lines[OrdLine]^.PL_ProductCode := The_Record^.PR_Header.PH_ProductCode;
           LineFile^.AddRecord(PR_Lines[OrdLine]^);  { Add New Record       }
          END; { END (Valid Record) }
        END;
      END;
     HeaderFile^.Unlock_Single;
    END;
  END;
 AddRecord := BtrvErr;
END;

BEGIN
 ProdFile      := NIL;
END.
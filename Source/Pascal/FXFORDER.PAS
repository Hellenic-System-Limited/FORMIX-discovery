(****************************************************************************
*  UNIT          : FXFORDER                                                 *
*  AUTHOR        : S. Wright                                                *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : FORMIX RECIPIE ORDER FILE                                *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFORDER;
INTERFACE
USES FILEOBJ,F6Btrv,FXCOMBFL,F6StdCtv,FXCfg,FXFWORK,F6StdUtl,
     FXModCtv,FXFRCP;

TYPE
    PCombineWOFile = ^TCombineWOFile;
    TCombineWOFile = OBJECT(TCombineFile)

      CONSTRUCTOR Init(HeaderName,DetailName : STRING);
      FUNCTION    ReadAllRecords(Operation   : OpCodeStr;
                                   Lock,Multi  : BOOLEAN;
                                   The_Record   : PWOrderObject;
                                   Key         : BYTE) : INTEGER; Virtual;
      FUNCTION    ReadLineRecords (The_Record   : PWOrderObject) : INTEGER; Virtual;
      FUNCTION    UpdateRecord    (The_Record : PWOrderObject) : INTEGER; Virtual;
      FUNCTION    AddRecord       (The_Record : PWOrderObject) : INTEGER; Virtual;
      PROCEDURE   DeleteLineRec   (The_Record : PWOrderObject;LineRef : INTEGER);
    END;

     TWOLine = OBJECT(TLineRecord)
      LineRecord : TWOLineRecord;
      CONSTRUCTOR INIT;
      FUNCTION  LineRecordInRange : BOOLEAN; VIRTUAL;
      PROCEDURE PrimeLineRecordKey(VAR Header);VIRTUAL;
      FUNCTION  ReadLineRecord(FileStruct :PCombineFile;Op:STRING) : INTEGER;VIRTUAL;
      FUNCTION  GetLineNumber : INTEGER;VIRTUAL;
     END;



VAR WorkOrderFile  : PCombineWOFile;

IMPLEMENTATION

{==============Work Order Line Method ===========================}
CONSTRUCTOR TWOLine.INIT;
BEGIN
 FillChar(LineRecord,SizeOf(LineRecord),#0);
END;

FUNCTION TWOLine.LineRecordInRange : BOOLEAN;
BEGIN
 lineRecordInRange := LineRecord.WOL_LineNo IN [1..MAX_LINES_ON_RECORD];
END;

PROCEDURE TWOLine.PrimeLineRecordKey(VAR Header);
BEGIN
 WITH LineRecord,TWOHeaderRecord(Header) DO
  BEGIN
   WOL_OrderNo := WOH_OrderNo;     { Prime Key                       }
   WOL_Revision:= WOH_Revision;
   WOL_LineNo  := 0;
  END;
END;

FUNCTION TWOLine.ReadLineRecord(FileStruct :PCombineFile;Op:STRING) : INTEGER;
BEGIN
 ReadLineRecord:= FileStruct^.LineFile^.ReadRecord(Op,FALSE,FALSE,LineRecord,0);
END;

FUNCTION TWOLine.GetLineNumber : INTEGER;
BEGIN
 GetLineNumber := LineRecord.WOL_LineNo;
END;

{============== TCombineWOFile METHODS   ==================}
CONSTRUCTOR TCombineWOFile.Init(HeaderName,DetailName : STRING);
BEGIN
 HeaderFile := NEW(PWOHeaderFile,Init(HeaderName));
 LineFile   := NEW(PWOLineFile,Init(DetailName));
 INHERITED Init;
END;

FUNCTION TCombineWOFile.ReadAllRecords(Operation   : OpCodeStr;
                                       Lock,Multi  : BOOLEAN;
                                       The_Record  : PWOrderObject;
                                       Key         : BYTE) : INTEGER;
BEGIN
 ReadAllRecords := HeaderFile^.ReadRecord(Operation,Lock,Multi,The_Record^.WO_Header,Key);
 IF (HeaderFile^.BtrvErr = 0) THEN
  BEGIN
   ReadLineRecords(The_Record);
  END;
END;

FUNCTION TCombineWOFile.ReadLineRecords(The_Record : PWOrderObject) : INTEGER;
VAR LineRecord : TWOLine{TWOLineRecord};
    LineNo     : INTEGER;
BEGIN
 LineRecord.Init;
 WITH The_Record^.WO_Header DO
  BEGIN
   LineRecord.PrimeLineRecordKey(The_Record^.WO_Header);
   LineRecord.ReadLineRecord(@Self,'GE');
   WHILE (LineFile^.BtrvErr = 0)
   AND   (LineRecord.LineRecord.WOL_OrderNo = WOH_OrderNo)
   AND   (LineRecord.LineRecord.WOL_Revision = WOH_Revision) DO
    BEGIN
     IF LineRecord.LineRecordInRange THEN
      BEGIN
       LineNo := LineRecord.GetLineNumber;
       NEW(The_Record^.WO_Lines[LineNo]);
       The_Record^.WO_Lines[LineNo]^   := LineRecord.LineRecord;
       The_Record^.WO_LinePos[LineNo]  := LineFile^.Position;
      END;
     LineRecord.ReadLineRecord(@Self,'GN');
    END;
  END;
 LineRecord.Done;
END;

PROCEDURE TCombineWOFile.DeleteLineRec(The_Record : PWOrderObject;LineRef : INTEGER);
VAR LPA       : INTEGER;
    DelPtr    : PDeleteList;
BEGIN
 IF Assigned(The_Record^.WO_Lines[LineRef]) THEN
  BEGIN
   IF The_Record^.WO_LinePos[LineRef] <> 0 THEN
    BEGIN
     DelPtr := NIL;
     NEW(DelPtr);
     IF Assigned(DelPtr) THEN
      BEGIN
       DelPtr^.RecPos := The_Record^.WO_LinePos[LineRef];
       DelPtr^.Next   := The_Record^.WO_DeleteList;     { Insert Into List }
       The_Record^.WO_DeleteList := DelPtr;
      END;
    END;
   Dispose(The_Record^.WO_Lines[LineRef]);
   The_Record^.WO_Lines[LineRef] := NIL;
   { Copy Remaining Line Pointers }
   FOR LPA := LineRef TO MAX_LINES_ON_RECORD-1 DO
    BEGIN
     The_Record^.WO_Lines[LPA]   := The_Record^.WO_Lines[LPA+1];
     The_Record^.WO_LinePos[LPA] := The_Record^.WO_LinePos[LPA+1];
     IF Assigned(The_Record^.WO_Lines[LPA]) THEN
      BEGIN
       The_Record^.WO_Lines[LPA]^.WOL_LineNo := LPA;
      END;
    END;
   { Clear Last Line Pointer As it Has Moved }
   The_Record^.WO_Lines[MAX_LINES_ON_RECORD] := NIL;
   The_Record^.WO_LinePos[MAX_LINES_ON_RECORD] := 0;
  END;
END;


FUNCTION TCombineWOFile.UpdateRecord(The_Record : PWOrderObject) : INTEGER;
VAR OrdLine : INTEGER;
    LineRec : TWOLineRecord;

BEGIN
 The_Record^.ResetCalculatedFields;

 DeleteLineRecords(LineRec, The_Record^.WO_DeleteList);

 FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   WITH The_Record^ DO
    BEGIN
     IF  (Assigned(WO_Lines[OrdLine]))
     AND (WO_Lines[OrdLine]^.WOL_OrderNo > 0)
     AND (WO_Lines[OrdLine]^.WOL_LineNo > 0) THEN  { Valid Record?         }
      BEGIN
       IF WO_LinePos[OrdLine] <> 0 THEN             { Existing Rec. Update  }
        BEGIN
            { Get Rec. Direct       }
         IF LineFile^.GetRecordDirect(WO_LinePos[OrdLine],TRUE,FALSE,LineRec,0) = 0 THEN
          BEGIN
           LineFile^.UpdateRecord(WO_Lines[OrdLine]^);  { Update Rec.           }
          END;
        END
       ELSE
        BEGIN
         LineFile^.AddRecord(WO_Lines[OrdLine]^);  { Add New Record       }
        END;
      END; { END (Valid Record) }
    END; { END (WITH) }
  END; { END (FOR) }
  INC(The_Record^.WO_Header.WOH_UpdateCount); { Increment Update Counter   }
  UpdateRecord := HeaderFile^.UpdateRecord(The_Record^.WO_Header);
END;

FUNCTION TCombineWOFile.AddRecord(The_Record : PWOrderObject) : INTEGER;
VAR OrdLine : INTEGER;
BEGIN
 The_Record^.ResetCalculatedFields;

 { Add Header Record }
 BtrvERR := HeaderFile^.AddRecord(The_Record^.WO_Header);
 IF BtrvErr = 0 THEN
  BEGIN
   { Re-Read & Lock Header }
   BtrvErr := HeaderFile^.ReadRecord('EQ',TRUE,FALSE,The_Record^.WO_Header,0);
   IF BtrvErr = 0 THEN
    BEGIN
     FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
      BEGIN
       WITH The_Record^ DO
        BEGIN
         IF Assigned(WO_Lines[OrdLine]) THEN
          BEGIN
           WO_Lines[OrdLine]^.WOL_OrderNo := WO_Header.WOH_OrderNo;
           WO_Lines[OrdLine]^.WOL_Revision:= WO_Header.WOH_Revision;
           LineFile^.AddRecord(WO_Lines[OrdLine]^);  { Add New Record       }
          END; { END (Valid Record) }
        END;
      END;
     HeaderFile^.Unlock_Single;
    END;
  END;
 AddRecord := BtrvErr;
END;

BEGIN
 WorkOrderFile := NIL;
END.
(****************************************************************************
*  UNIT          : FXFCRCP                                                  *
*  AUTHOR        : S. Wright (Seperated To This Unit)                       *
*  DATE          : 23/09/98                                                 *
*  PURPOSE       : FORMIX RECIPE FILE (COMBINED HEADER/LINE)                *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFCRCP;
INTERFACE
USES FILEOBJ,F6Btrv,FXCOMBFL,F6StdCtv,FXCfg,F6StdUtl,FxModCtv,FXFRCP,FXFIngr;

TYPE TRecipeLine = OBJECT(TLineRecord)
      LineRecord : TRecipeLineRecord;
      CONSTRUCTOR INIT;
      FUNCTION  LineRecordInRange : BOOLEAN; VIRTUAL;
      PROCEDURE PrimeLineRecordKey(VAR Header);VIRTUAL;
      FUNCTION  ReadLineRecord(FileStruct :PCombineFile;Op:STRING) : INTEGER;VIRTUAL;
     END;

     PRecipeRecord = ^TRecipeRecord;
     TRecipeRecord = PACKED RECORD
      RP_Header     : TRecipeHeaderRecord;
      RP_Lines      : ARRAY [1..MAX_LINES_ON_RECORD] OF PRecipeLineRecord;
      RP_LinePos    : ARRAY [1..MAX_LINES_ON_RECORD] OF LONGINT;
      RP_DeleteList : PDeleteList;
     END;

     PCombineRecipeFile = ^TCombineRecipeFile;
     TCombineRecipeFile = OBJECT(TCombineFile)
       { these appear to be methods that work on TRecipeRecord! }
       { ------------------------------------------------------ }
       { havent got time to change it like I did in FXFWORK. TB }
       CONSTRUCTOR Init(HeaderName,DetailName  : STRING);
       PROCEDURE   InitRecord         (The_Record : PRecipeRecord); Virtual;
       PROCEDURE   ClearLines         (The_Record : PRecipeRecord); Virtual;
       FUNCTION    ReadAllRecords     (Operation  : OpCodeStr;
                                      Lock,Multi : BOOLEAN;
                                      The_Record : PRecipeRecord;
                                      Key        : BYTE) : INTEGER; Virtual;
       FUNCTION    ReadLineRecords    (The_Record : PRecipeRecord) : INTEGER; Virtual;
       PROCEDURE   UpdateRecord       (The_Record : PRecipeRecord); Virtual;
       FUNCTION    AddRecord          (The_Record : PRecipeRecord) : INTEGER; Virtual;
       PROCEDURE   DeleteLineRec      (The_Record : PRecipeRecord;LineRef : INTEGER);
       PROCEDURE   ResetContainerSizes(The_Record : PRecipeRecord);
       PROCEDURE   CalculateRatiosFromPHR (The_Record : PRecipeRecord);
       FUNCTION    AllLinesAreUntoleranced(The_Record : PRecipeRecord) : BOOLEAN;
       PROCEDURE   ApplyIngredTols(The_Record : PRecipeRecord);

     END;


VAR RecipeFile     : PCombineRecipeFile;

IMPLEMENTATION

{==============Recipe Line Method ===========================}
CONSTRUCTOR TRecipeLine.INIT;
BEGIN
 FillChar(LineRecord,SizeOf(LineRecord),#0);
END;

FUNCTION TRecipeLine.LineRecordInRange : BOOLEAN;
BEGIN
 lineRecordInRange := LineRecord.RL_LineNo IN [1..MAX_LINES_ON_RECORD];
END;

PROCEDURE TRecipeLine.PrimeLineRecordKey(VAR Header);
BEGIN
 WITH LineRecord,TRecipeHeaderRecord(Header) DO
  BEGIN
  END;
END;

FUNCTION TRecipeLine.ReadLineRecord(FileStruct :PCombineFile;Op:STRING) : INTEGER;
BEGIN
 ReadLineRecord := FileStruct^.LineFile^.ReadRecord(Op,FALSE,FALSE,LineRecord,0);
END;

{============== TCombineRecipeFile METHODS   ==================}
CONSTRUCTOR TCombineRecipeFile.Init(HeaderName,DetailName : STRING);
BEGIN
 HeaderFile := NEW(PRecipeHeaderFile,Init(HeaderName));
 LineFile   := NEW(PRecipeLineFile,Init(DetailName));
 INHERITED Init;
END;


PROCEDURE TCombineRecipeFile.InitRecord(The_Record : PRecipeRecord);
VAR LPA : INTEGER;
BEGIN
 HeaderFile^.InitRecord(The_Record^.RP_Header);
 FOR LPA := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   The_Record^.RP_LinePos[LPA] := 0;
   The_Record^.RP_Lines[LPA]   := NIL;
  END;
 The_Record^.RP_DeleteList := NIL;
END;

FUNCTION TCombineRecipeFile.ReadAllRecords(Operation   : OpCodeStr;
                                            Lock,Multi  : BOOLEAN;
                                            The_Record  : PRecipeRecord;
                                            Key         : BYTE) : INTEGER;
BEGIN
  ReadAllRecords := HeaderFile^.ReadRecord(Operation,Lock,Multi,The_Record^.RP_Header,Key);
  IF (HeaderFile^.BtrvErr = 0) THEN
   BEGIN
    ReadLineRecords(The_Record);
   END;
 END;

FUNCTION TCombineRecipeFile.ReadLineRecords(The_Record : PRecipeRecord) : INTEGER;
VAR
  RPL : TRecipeLineRecord;
BEGIN
 WITH The_Record^.RP_Header DO
  BEGIN
   FILLCHAR(RPL,SizeOF(RPL),#0);
   RPL.RL_HUniqueRef := RH_UniqueRef; {Prime Key}
   RPL.RL_LineNo   := 0;
   LineFile^.ReadRecord('GE',FALSE,FALSE,RPL,0);
   WHILE (LineFile^.BtrvErr = 0) AND (RPL.RL_HUniqueRef = RH_UniqueRef) DO
    BEGIN
     IF RPL.RL_LineNo IN [1..MAX_LINES_ON_RECORD] THEN
      BEGIN
       NEW(The_Record^.RP_Lines[RPL.RL_LineNo]);
       The_Record^.RP_Lines[RPL.RL_LineNo]^   := RPL;
       The_Record^.RP_LinePos[RPL.RL_LineNo]  := LineFile^.Position;
      END;
     LineFile^.ReadRecord('GN',FALSE,FALSE,RPL,0);
    END;
  END;
 {CalculateRatiosFromPHR(The_Record); we dont know that all the lines were read!}
END;

PROCEDURE TCombineRecipeFile.ClearLines(The_Record : PRecipeRecord);
VAR LPA        : LONGINT;
{    TempPtr,
    DeletePtr : PDeleteList;}
BEGIN
 FOR LPA :=1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF Assigned(The_Record^.RP_Lines[LPA]) THEN
    BEGIN
     Dispose(The_Record^.RP_Lines[LPA]);
    END;
   The_Record^.RP_Lines[LPA] := NIL;
  END;
 { ClearDown List Of Records Marked For Deletion }
 ClearDeleteList(The_Record^.RP_DeleteList);
{ TempPtr := The_Record^.RP_DeleteList;
 WHILE (TempPtr <> NIL) DO
  BEGIN
   DeletePtr := TempPtr;
   TempPtr := TempPtr^.Next;
   Dispose(DeletePtr);
  END;}
END;

PROCEDURE TCombineRecipeFile.ResetContainerSizes(The_Record : PRecipeRecord);
VAR OrdLine : INTEGER;
    TotalNetWt : DOUBLE;
BEGIN
 IF NOT (The_Record^.RP_Header.RH_DefaultMixType IN MixSet_ProportionallyMixedConts) THEN EXIT;
 FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   WITH The_Record^,The_Record^.RP_Header DO
    BEGIN
     IF  (Assigned(RP_Lines[OrdLine])) THEN
      BEGIN
        RP_Lines[OrdLine]^.RL_DefaultContSize := RP_Lines[1]^.RL_DefaultContSize;
      END;
    END;
  END;
END;

PROCEDURE TCombineRecipeFile.CalculateRatiosFromPHR(The_Record : PRecipeRecord);
{PROMISES: 1. ifdef RECIPEBYPHR then sets the percentage on The_Record's
              Lines according to the PHR figures.
           2. if RECIPEBYPHR is NOT defined then sets the percentages and
              clears the PHR figures on the The_Record's Lines providing no
              percentages already exist (usefull for Recipe CSV import).
}
VAR OrdLine  : INTEGER;
    TotalPHR : DOUBLE;
    PCentsAlreadyExist : BOOLEAN;
BEGIN
 TotalPHR   := 0.0;
 PCentsAlreadyExist := FALSE;
 FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   WITH The_Record^ DO
    BEGIN
     IF  (Assigned(RP_Lines[OrdLine])) THEN
      BEGIN
       TotalPHR := TotalPHR + RP_Lines[OrdLine]^.RL_PHR;
       IF RP_Lines[OrdLine]^.RL_DefaultRatio <> 0.0 THEN
         PCentsAlreadyExist := TRUE;
      END;
    END;
  END;
 IF (TotalPHR <> 0.0)
{$IFnDEF RECIPEBYPHR}
 AND (NOT PCentsAlreadyExist)
{$ENDIF}
 THEN
  BEGIN
   FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
    BEGIN
     WITH The_Record^ DO
      BEGIN
       IF  (Assigned(RP_Lines[OrdLine])) THEN
        BEGIN
         RP_Lines[OrdLine]^.RL_DefaultRatio := (RP_Lines[OrdLine]^.RL_PHR*100/TotalPHR);
{$IFnDEF RECIPEBYPHR}
         RP_Lines[OrdLine]^.RL_PHR := 0.0;
{$ENDIF}
        END;
      END;
    END;
  END;
END;

PROCEDURE TCombineRecipeFile.DeleteLineRec(The_Record : PRecipeRecord;LineRef : INTEGER);
VAR LPA       : INTEGER;
    DelPtr    : PDeleteList;
BEGIN
 IF Assigned(The_Record^.RP_Lines[LineRef]) THEN
  BEGIN
   IF The_Record^.RP_LinePos[LineRef] <> 0 THEN
    BEGIN
     DelPtr := NIL;
     NEW(DelPtr);
     IF Assigned(DelPtr) THEN
      BEGIN
       DelPtr^.RecPos := The_Record^.RP_LinePos[LineRef];
       DelPtr^.Next   := The_Record^.RP_DeleteList;       { Insert Into List }
       The_Record^.RP_DeleteList := DelPtr;
      END;
    END;
   Dispose(The_Record^.RP_Lines[LineRef]);
   The_Record^.RP_Lines[LineRef] := NIL;
   { Copy Remaining Line Pointers }
   FOR LPA := LineRef TO MAX_LINES_ON_RECORD-1 DO
    BEGIN
     The_Record^.RP_Lines[LPA]   := The_Record^.RP_Lines[LPA+1];
     The_Record^.RP_LinePos[LPA] := The_Record^.RP_LinePos[LPA+1];
     IF Assigned(The_Record^.RP_Lines[LPA]) THEN
      BEGIN
       The_Record^.RP_Lines[LPA]^.RL_LineNo := LPA;
      END;
    END;
   { Clear Last Line Pointer As it Has Moved }
   The_Record^.RP_Lines[MAX_LINES_ON_RECORD] := NIL;
   The_Record^.RP_LinePos[MAX_LINES_ON_RECORD] := 0;
  END;
END;


PROCEDURE TCombineRecipeFile.UpdateRecord(The_Record : PRecipeRecord);
VAR OrdLine : INTEGER;
    LineRec : TRecipeLineRecord;
    DelPtr  : PDeleteList;
BEGIN
 CalculateRatiosFromPHR(The_Record);
 DeleteLineRecords(LineRec,The_Record^.RP_DeleteList);
(*
  DelPtr := The_Record^.RP_DeleteList;
  WHILE (DelPtr <> NIL) DO
   BEGIN
    Move(DelPtr^.RecPos,LineRec,4);      { Get Rec. Direct       }
    IF LineFile^.ReadRecord('GD',TRUE,FALSE,LineRec,0) = 0 THEN
     BEGIN
      LineFile^.DeleteRecord;
     END;
    DelPtr := DelPtr^.Next;
   END; { END (WHILE) }*)

 FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   WITH The_Record^ DO
    BEGIN
     IF  (Assigned(RP_Lines[OrdLine]))
     AND (NOT NowtButSpace(RP_Lines[OrdLine]^.RL_RecipeNo))
     AND (RP_Lines[OrdLine]^.RL_LineNo > 0) THEN  { Valid Record?         }
      BEGIN
       IF RP_LinePos[OrdLine] <> 0 THEN             { Existing Rec. Update  }
        BEGIN
             { Get Rec. Direct       }
         IF LineFile^.GetRecordDirect(RP_LinePos[OrdLine],TRUE,FALSE,LineRec,0) = 0 THEN
          BEGIN
           LineFile^.UpdateRecord(RP_Lines[OrdLine]^);      { Update Rec.           }
          END;
        END
       ELSE
        BEGIN
         LineFile^.AddRecord(RP_Lines[OrdLine]^);  { Add New Record       }
        END;
      END; { END (Valid Record) }
    END; { END (WITH) }
  END; { END (FOR) }
  INC(The_Record^.RP_Header.RH_UpdateCount); { Increment Update Counter   }
  HeaderFile^.UpdateRecord(The_Record^.RP_Header);
END;

FUNCTION TCombineRecipeFile.AddRecord(The_Record : PRecipeRecord) : INTEGER;
VAR OrdLine : INTEGER;
BEGIN
 CalculateRatiosFromPHR(The_Record);
 { Add Header Record }
 BtrvERR := HeaderFile^.AddRecord(The_Record^.RP_Header);

 IF BtrvErr = 0 THEN
  BEGIN
   { Re-Read & Lock Header }
   {Need To reread the record to store the unique reference in line records}
   BtrvErr := HeaderFile^.ReadRecord('EQ',TRUE,FALSE,The_Record^.RP_Header,1);
   IF BtrvErr = 0 THEN
    BEGIN
     FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
      BEGIN
       WITH The_Record^ DO
        BEGIN
         IF Assigned(RP_Lines[OrdLine]) THEN
          BEGIN
           RP_Lines[OrdLine]^.RL_HUniqueRef := The_Record^.RP_Header.RH_UniqueRef;
           LineFile^.AddRecord(RP_Lines[OrdLine]^);  { Add New Record       }
          END; { END (Valid Record) }
        END;
      END;
     HeaderFile^.Unlock_Single;
    END;
  END;
 AddRecord := BtrvErr;
END;

FUNCTION TCombineRecipeFile.AllLinesAreUntoleranced(The_Record : PRecipeRecord) : BOOLEAN;
{ if no lines then returns FALSE }
VAR
   LineNo : INTEGER;
   Lines  : INTEGER;
BEGIN
 Lines := 0;
 AllLinesAreUntoleranced := FALSE;
 FOR LineNo := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF (Assigned(The_Record^.RP_Lines[LineNo])) THEN
    BEGIN
     Inc(Lines);
     WITH The_Record^.RP_Lines[LineNo]^ DO
      BEGIN
       IF (RL_DefaultHighTol > 0.0001)
       OR (RL_DefaultLowTol  > 0.0001) THEN
         EXIT; { a tolerance exists }
        {****}
      END;
    END;
  END;
 AllLinesAreUntoleranced := Lines > 0;
END;

PROCEDURE TCombineRecipeFile.ApplyIngredTols(The_Record : PRecipeRecord);
VAR
  TempIngRec : TIngredient_Record;
  LineNo     : INTEGER;
BEGIN
 FOR LineNo := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF (Assigned(The_Record^.RP_Lines[LineNo])) THEN
    BEGIN
     WITH The_Record^.RP_Lines[LineNo]^ DO
      BEGIN
       IF IngredientFile^.GetIngredient(RL_Ingredient, TempIngRec, FALSE) = 0 THEN
        BEGIN
         RL_DefaultHighTol := TempIngRec.ING_DefaultHighTol;
         RL_DefaultLowTol  := TempIngRec.ING_DefaultLowTol;
        END;
      END;
    END;
  END;
END;



BEGIN
 RecipeFile    := NIL;
END.

(****************************************************************************
*  UNIT          : FXFRCP                                                   *
*  AUTHOR        : N.  Spooner & S. Wright                                  *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : FORMIX RECIPE FILE                                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFRCP;
INTERFACE

USES FILEOBJ,F6STDCTV,F6BTRV,FXMODCTV,FXFIngr,SFXSTD;

CONST  Recipe_Header_FileName = 'HRECIPE.FIL';
CONST  Recipe_Line_FileName   = 'LRECIPE.FIL';

       {This Header Needs A Mixing Loss}
TYPE   PRecipeHeaderRecord = ^TRecipeHeaderRecord;
       TRecipeHeaderRecord = PACKED RECORD
         RH_UniqueRef  : LONGINT;     {01-04}{OBSOLETE KEY?
                                    Needed when recipes could have duplicates}
         RH_RecipeNo   : TRecipeRef;  {05-13}
         RH_Description: STRING[30];  {14-44}
         RH_DefaultMixType : TMixType;{45-45}{ for orders }
         RH_DefaultMixWt   : DOUBLE;  {46-53}
         RH_SPAREDBL1  : DOUBLE;      {54-61}
         RH_SPAREDBL2  : DOUBLE;      {62-67}
         RH_UpdateCount: LONGINT;
         RH_StdCaseWt  : DOUBLE; { / default batch weight }
         RH_ProcLossAfterMixing : DOUBLE;{Used when raising orders via product defs }
                                         {Equivelent to 100-yield on ingredients.   }
         RH_BasicStock : LONGINT;   {preferred stock buffer }
         RH_IssueNo    : STRING[8]; {not used by rest of program}
         RH_BarCode    : STRING[14];{fixed barcode on label}
         RH_DefaultSeqFixed : BOOLEAN;
         RH_WorkGroup  : TWorkGrp; {Length byte is only written to by this program}
         RH_JobNo      : INTEGER;
         RH_Obsolete   : BOOLEAN;
         Reserved      : ARRAY[0..12] OF BYTE;
       END;

{SQL  Note : Cannot define FileRef as IDENTITY because Pervasive will
             automatically use it to create Index 0  (cant force it to
             index 1 as defined here.

{     Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

CREATE TABLE Recipe_Header IN DICTIONARY USING 'HRECIPE.FIL'
(
FileRef        INTEGER     NOT NULL,
Recipe_Code    VARCHAR(8)  NOT NULL,
Description    VARCHAR(30) NOT NULL,
Mix_Method     UTINYINT    NOT NULL,
Mix_Weight     DOUBLE      NOT NULL,
Reserved1      DOUBLE      NOT NULL,
Reserved2      DOUBLE      NOT NULL,
Updates        INTEGER     NOT NULL,
Batch_Weight   DOUBLE      NOT NULL,
PostMix_Loss   DOUBLE      NOT NULL,
Reorder_Level  INTEGER     NOT NULL,
Issue          VARCHAR(8)  NOT NULL,
BarCode        VARCHAR(14) NOT NULL,
Fixed_Sequence BIT         NOT NULL,
Reserved3      UTINYINT    NOT NULL,
Work_Group     CHAR(3)     NOT NULL,
Job_Number     SMALLINT    NOT NULL,
Obsolete       BIT         NOT NULL,
Reserved       CHAR(13)    NOT NULL
)#
CREATE UNIQUE INDEX ByCode IN DICTIONARY ON Recipe_Header(Recipe_Code)#
CREATE UNIQUE NOT MODIFIABLE INDEX ByFileRef IN DICTIONARY ON
 Recipe_Header(FileRef)#
}

       {This Line Needs A Mixing Loss From Ingredient}
       PRecipeLineRecord = ^TRecipeLineRecord;
       TRecipeLineRecord = PACKED RECORD
         RL_UniqueRef     : LONGINT;        {01-04}
         RL_RecipeNo      : TRecipeRef;     {05-13}
         RL_LineNo        : LONGINT;        {14-17}      {0.1}
         RL_HUniqueRef    : LONGINT;        {18-21} {Header Files Unique Ref} {0.0}
    {}   RL_Ingredient    : TIngredientRef;
         RL_DefaultKeyIngred : BOOLEAN;
         RL_DefaultRatio     : DOUBLE;
         RL_DefaultContSize  : DOUBLE; {primed from Ingredient record}
         RL_DefaultYield     : DOUBLE; {primed from Ingredient record}
         RL_PHR           : DOUBLE;
         RL_DefaultLowTol : DOUBLE; {primed from Ingredient record}
         RL_DefaultHighTol: DOUBLE; {primed from Ingredient record}
         Reserved         : ARRAY[0..31] OF BYTE;
       END;

{SQL  Note : Cannot define FileRef as IDENTITY because Pervasive will
             automatically use it to create Index 0  (cant force it to
             index 1 as defined here.

{     Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

CREATE TABLE Recipe_Line IN DICTIONARY USING 'LRECIPE.FIL'
(
FileRef        INTEGER     NOT NULL,
Recipe_Code    VARCHAR(8)  NOT NULL,
Line_No        INTEGER     NOT NULL,
HeaderFileRef  INTEGER     NOT NULL,
Ingredient     VARCHAR(8)  NOT NULL,
Key_Line       BIT         NOT NULL,
Final_Percent  DOUBLE      NOT NULL,
Container_Wt   DOUBLE      NOT NULL,
Mixing_Yield   DOUBLE      NOT NULL,
Reserved1      DOUBLE      NOT NULL,
Tol_NegPercent DOUBLE      NOT NULL,
Tol_PosPercent DOUBLE      NOT NULL,
Reserved       CHAR(32)    NOT NULL
)#
CREATE INDEX ByHeadRefLine IN DICTIONARY ON
 Recipe_Line(HeaderFileRef , Line_No)#
CREATE UNIQUE NOT MODIFIABLE INDEX ByFileRef IN DICTIONARY ON
 Recipe_Line(FileRef)#
}

    PRecipeHeaderFile = ^TRecipeHeaderFile;
    TRecipeHeaderFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
      FUNCTION   ReadRecipeHeader(VAR AHeadRec : TRecipeHeaderRecord;
                                  RecipeCode   : TRecipeRef) :INTEGER;
      FUNCTION   SetObsoleteOnRecipe(RecipeCode : TRecipeRef;
                                     ToObsolete : BOOLEAN) : INTEGER;
    END;

    PRecipeLineFile = ^TRecipeLineFile;
    TRecipeLineFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
      FUNCTION   DelLinesForRecipe(HUniqueRef : LONGINT) : INTEGER;
      FUNCTION   GetRecipeLine (HUniqueRef,LineNo : LONGINT;VAR RecBuf : TRecipeLineRecord) : INTEGER;
    END;

VAR RecipeHeaderFile : PRecipeHeaderFile;     { File Object Instance Pointer }
    RecipeLineFile   : PRecipeLineFIle;

PROCEDURE PrimeRecipeLineForIngredient(VAR ARecipeLine : TRecipeLineRecord;
                                       IngredientRef   : TIngredientRef);
(*FUNCTION CheckForCircularRecipeRef(VAR RecipeCode : TRecipeRef) : BOOLEAN;*)
FUNCTION GetRecipeName(VAR Recipe : STRING) : STRING;

IMPLEMENTATION

PROCEDURE  TRecipeHeaderFile.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TRecipeHeaderRecord),#0);
 WITH TRecipeHeaderRecord(RecBuff) DO
  BEGIN
   RH_RecipeNo   := SPACE_STRING;
   RH_Description:= SPACE_STRING;
{$IFDEF DAWSONS}
   RH_DefaultMixType    := mt_CampaignWeighing;
{$ELSE}
   RH_DefaultMixType    := mt_SingleContainerPerMix;
{$ENDIF}
   RH_DefaultMixWt := 0.0;
   RH_BarCode    := SPACE_STRING;
   RH_UpdateCount:= 0;
   RH_UniqueRef  := 0;
   RH_WorkGroup  := Space_String;
  END;
END;

FUNCTION   TRecipeHeaderFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TRecipeHeaderRecord);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 2;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.0 Recipe Name}
   INC(SegC,Set_Key(Key_Buf[0],05,09,K_EXTTYPE OR K_MODIFIABLE,EKT_LSTRING,0));
   {0.1 Min Target Weight}
{   INC(SegC,Set_Key(Key_Buf[1],54,08,K_EXTTYPE OR K_MODIFIABLE OR K_DUPLICATE,EKT_FLOAT,0));}
   { 1.0 Unique Reference}
   INC(SegC,Set_Key(Key_Buf[1],01,04,K_EXTTYPE,EKT_AUTO_INC,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;


FUNCTION TRecipeHeaderFile.ReadRecipeHeader(VAR AHeadRec : TRecipeHeaderRecord;
                                            RecipeCode   : TRecipeRef) :INTEGER;
{REQUIRES: file to be open}
BEGIN
 InitRecord(AHeadRec);
 AHeadRec.RH_RecipeNo := RecipeCode;
 ReadRecipeHeader := ReadRecord('EQ',FALSE,FALSE,AHeadRec,0);
END;

FUNCTION TRecipeHeaderFile.SetObsoleteOnRecipe(RecipeCode : TRecipeRef;
                                               ToObsolete : BOOLEAN) : INTEGER;
{REQUIRES: file to be open}
VAR
  HeadRec : TRecipeHeaderRecord;
  FErr : INTEGER;
BEGIN
 InitRecord(HeadRec);
 HeadRec.RH_RecipeNo := RecipeCode;
 FErr := ReadRecord('EQ',TRUE,FALSE,HeadRec,0);
 IF FErr = 0 THEN
  BEGIN
   HeadRec.RH_Obsolete := ToObsolete;
   FErr := UpdateRecord(HeadRec);
  END;
 SetObsoleteOnRecipe := FErr;
END;

{-------------------------------------------------------------}

PROCEDURE  TRecipeLineFile.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TRecipeLineRecord),#0);
 WITH TRecipeLineRecord(RecBuff) DO
  BEGIN
   RL_RecipeNo      := SPACE_STRING;
   RL_LineNo        := 0;
   RL_Ingredient    := SPACE_STRING;
   RL_DefaultKeyIngred := FALSE;
   RL_DefaultRatio     := 0.0;
   RL_DefaultContSize  := 0.0;
  END;
END;

PROCEDURE PrimeRecipeLineForIngredient(VAR ARecipeLine : TRecipeLineRecord;
                                       IngredientRef   : TIngredientRef);
VAR IngredientRec : TIngredient_Record;
BEGIN
 IngredientFile^.GetIngredient(IngredientRef,IngredientRec,FALSE);
 WITH ARecipeLine, IngredientRec DO
  BEGIN
   RL_Ingredient        := IngredientRef;
   RL_DefaultYield      := ING_DefaultYield;
   RL_DefaultLowTol     := ING_DefaultLowTol;
   RL_DefaultHighTol    := ING_DefaultHighTol;
   RL_DefaultContSize   := ING_DefaultContSize;
  END;
END;

FUNCTION   TRecipeLineFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TRecipeLineRecord);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 2;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.1 Header File Unique Reference}
   INC(SegC,Set_Key(Key_Buf[0],18,04,K_EXTTYPE OR K_DUPLICATE OR
   K_MODIFIABLE OR K_SEGMENTED,EKT_INTEGER,0));
   { 0.1 Line Number       }
   INC(SegC,Set_Key(Key_Buf[1],14,04,K_EXTTYPE OR K_DUPLICATE OR
   K_MODIFIABLE,EKT_INTEGER,0));
   { 1.0 Unique Reference}
   INC(SegC,Set_Key(Key_Buf[2],01,04,K_EXTTYPE,EKT_AUTO_INC,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

FUNCTION TRecipeLineFile.DelLinesForRecipe(HUniqueRef : LONGINT) : INTEGER;
VAR LineBuff : PRecipeLineRecord;
BEGIN
 BtrvErr := -1;
 LineBuff := NIL;
 NEW(LineBuff);
 IF Assigned(LineBuff) THEN
  BEGIN
   LineBuff^.RL_HUniqueRef := HUniqueRef;
   LineBuff^.RL_LineNo     := 0;
   BtrvErr := ReadRecord('GE',TRUE,FALSE,LineBuff^,0);
   WHILE (BtrvErr = 0) DO
    BEGIN
     IF (LineBuff^.RL_HUniqueRef <> HUniqueRef) THEN Break;
     DeleteRecord;
     BtrvErr := ReadRecord('GN',TRUE,FALSE,LineBuff^,0);
    END;
   Dispose(LineBuff);
  END;
 IF BtrvErr IN [4,9] THEN DelLinesForRecipe := 0
 ELSE DelLinesForRecipe := BtrvErr;
END;

FUNCTION  TRecipeLineFile.GetRecipeLine (HUniqueRef,LineNo : LONGINT;VAR RecBuf : TRecipeLineRecord) : INTEGER;
BEGIN
 RecBuf.RL_HUniqueRef := HUniqueRef;
 RecBuf.RL_LineNo     := LineNo;
 GetRecipeLine := ReadRecord('EQ',FALSE,FALSE,RecBuf,0);
END;

FUNCTION GetRecipeName(VAR Recipe : STRING) : STRING;
VAR RecipeRec : TRecipeHeaderRecord;
BEGIN
 GetRecipeName := COPY(SPACE_STRING,1,30);
 IF RecipeHeaderFile^.OpenFile = 0 THEN
  BEGIN
   RecipeRec.RH_RecipeNo    := Recipe;
   IF (RecipeHeaderFile^.ReadRecord('GE',FALSE,FALSE,RecipeRec,0) = 0) AND
    (RecipeRec.RH_RecipeNo = Recipe) THEN
    BEGIN
     GetRecipeName := RecipeRec.RH_Description;
    END
   ELSE
    GetRecipeName := COPY('Recipe Not Found'+SPACE_STRING,1,30);
   RecipeHeaderFile^.CloseFile;
  END
END;

(*
FUNCTION CheckForCircularRecipeRef(VAR RecipeCode : TRecipeRef) : BOOLEAN;
{As For Products}
{See FXFProd For Notes On How This Procedure Works}
TYPE PRecipeTree = ^TRecipeTree;
     TRecipeTree = RECORD
      Recipe     : TRecipeRef;
      UniqueRef  : LONGINT;
      ParentRcp  : PRecipeTree;        {IF NIL THEN Header Of List}
      ChildRcp   : PRecipeTree;        {First Child In List .IF NIL Then Leaf}
      Next       : PRecipeTree;        {Next Item In Linked List Of Children Of Parent}
     END;

VAR ListHeader : PRecipeTree;
    RecipeHead : TRecipeHeaderRecord;
    RecipeLine : TRecipeLineRecord;
    CurrentLeaf: PRecipeTree;
    CircularReferenceExists : BOOLEAN;

FUNCTION ReadRecipeHeaderRecord(VAR RecipeNo : TRecipeRef) : BOOLEAN;
BEGIN
 RecipeHead.RH_RecipeNo := RecipeNo;
 ReadRecipeHeaderRecord := RecipeHeaderFile^.ReadRecord('EQ',FALSE,FALSE,RecipeHead,0)=0;
END;

PROCEDURE DisposeOfBranch(VAR BranchHeader : PRecipeTree);
VAR BranchLoop,DelRec : PRecipeTree;
BEGIN
 BranchLoop := BranchHeader;
 WHILE (BranchLoop <> NIL) DO
  BEGIN
   IF (BranchLoop^.ChildRcp <> NIL) THEN
    BEGIN
     DisposeOfBranch(BranchLoop^.ChildRcp);
    END;
   DelRec     := BranchLoop;
   BranchLoop := BranchLoop^.Next;
   Dispose(DelRec);
  END;
 BranchHeader := NIL;
END;

PROCEDURE AddToTree(Header : PRecipeTree;VAR RecipeCode : TRecipeRef;HeaderRef :LONGINT);
VAR NewRec : PRecipeTree;

 PROCEDURE CreateNewBlankRecord(VAR NewRecord : PRecipeTree);
 BEGIN
  New(NewRecord);
  WITH NewRecord^ DO
   BEGIN
    Recipe    := RecipeCode;
    UniqueRef := HeaderRef;
    ParentRcp := Header;
    ChildRcp  := NIL;
    Next      := NIL;
   END;
 END;

BEGIN
 IF Header = NIL THEN
  BEGIN
   CreateNewBlankRecord(ListHeader);
  END
 ELSE
  BEGIN
   CreateNewBlankRecord(NewRec);
   NewRec^.Next      := Header^.ChildRcp;
   Header^.ChildRcp  := NewRec;
  END;
END;

PROCEDURE ReadAndAddRecipeLinesToTree(Header : PRecipeTree);
BEGIN
 FillChar(RecipeLine,SizeOf(TRecipeLineRecord),#0);
 RecipeLine.RL_HUniqueRef := Header^.UniqueRef;
 RecipeLineFile^.ReadRecord('GE',FALSE,FALSE,RecipeLine,0);
 WHILE (RecipeLineFile^.BtrvErr = 0) AND (RecipeLine.RL_HUniqueRef = Header^.UniqueRef) DO
  BEGIN
   RecipeHead.RH_RecipeNo := RecipeLine.RL_Ingredient;
   IF (RecipeHeaderFile^.ReadRecord('EQK',FALSE,FALSE,RecipeHead,0) = 0) THEN
    AddToTree(Header,RecipeLine.RL_Ingredient,0);
   RecipeLineFile^.ReadRecord('GN',FALSE,FALSE,RecipeLine,0);
  END;
END;

FUNCTION CheckForCircularRef(From : PRecipeTree) : BOOLEAN;
Var Parent : PRecipeTree;
BEGIN
 Parent := From^.ParentRcp;
 WHILE (Parent <> NIL) AND (NOT CircularReferenceExists) DO
  BEGIN
   IF Parent^.Recipe = From^.Recipe THEN
    CircularReferenceExists := TRUE;
   Parent := Parent^.ParentRcp;
  END;
 CheckForCircularRef := CircularReferenceExists;
END;

BEGIN
 FillChar(RecipeHead,SizeOf(TRecipeHeaderRecord),#0);
 FillChar(RecipeLine,SizeOf(TRecipeLineRecord),#0);
 ListHeader := NIL;
 CircularReferenceExists := FALSE;
 IF (RecipeHeaderFile^.OpenFile + RecipeLineFile^.OpenFile= 0) THEN
  BEGIN
   IF ReadRecipeHeaderRecord(RecipeCode) THEN
    BEGIN
     AddToTree(NIL,RecipeCode,RecipeHead.RH_UniqueRef);{Create Start Of Tree}
     CurrentLeaf := ListHeader;
     WHILE (CurrentLeaf <> NIL) DO
      BEGIN
       ReadAndAddRecipeLinesToTree(CurrentLeaf);
       IF CurrentLeaf^.ChildRcp <> NIL THEN
        BEGIN
         CurrentLeaf := CurrentLeaf^.ChildRcp;  {If There Is A Child Goto It}
         IF CheckForCircularRef(CurrentLeaf) THEN Break
        END
       ELSE   {No Children}
       IF CurrentLeaf^.Next <> NIL THEN
        BEGIN
         CurrentLeaf := CurrentLeaf^.Next;      {Goto Next Line aLong}
         IF CheckForCircularRef(CurrentLeaf) THEN Break;
        END
       ELSE {No Children Of Next. Go Back To Parent And Next In Parent List}
        BEGIN {No Need To Check For Circular Reference Here}
         IF CurrentLeaf^.ParentRcp <> NIL THEN
          CurrentLeaf := CurrentLeaf^.ParentRcp^.Next
         ELSE
          CurrentLeaf := NIL;
        END;
       IF CurrentLeaf <> NIL THEN
        BEGIN
         ReadRecipeHeaderRecord(CurrentLeaf^.Recipe);
         CurrentLeaf^.UniqueRef := RecipeHead.RH_UniqueRef;
        END;
      END;
    END;
  END;
 IF RecipeHeaderFile^.OpenErr = 0 THEN RecipeHeaderFile^.CloseFile;
 IF RecipeLineFile^.OpenErr   = 0 THEN RecipeLineFile^.CloseFile;
 DisposeOfBranch(ListHeader);
 CheckForCircularRecipeRef := CircularReferenceExists;
END;
*)

END.

(****************************************************************************
*  UNIT          : FXFINGR                                                  *
*  AUTHOR        : S. M. Wright                                             *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : FORMIX INGREDIENT FILE                                   *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFINGR;
INTERFACE

USES FILEOBJ,F6Btrv,F6StdCtv,FXCfg,FXModCtv;

CONST Ingredient_file_name = 'INGRED.FIL';

CONST TProcessTypeNames : ARRAY[PTWeight..High(TProcessTypes)] OF TListBoxString =
       ('Weighed',
        'Step   ',
        'Counted',
        'Auto   ');

      NumProcessTypeNames = Sizeof(TProcessTypeNames) DIV Sizeof(TProcessTypeNames[PTWeight]);

{ * - indicates an indexed field }
TYPE
       PIngredient_Record = ^TIngredient_Record;
       TIngredient_Record = PACKED RECORD
{*0} {}  ING_Ingredient    : TIngredientRef; {Ingredient Reference Code}
         ING_Description   : STRING[30];     {Ingredient Description}
     {}  ING_DefaultProcessType : TProcessTypes; { for ORDERS}
     {}  ING_DefaultLowTol      : DOUBLE;        { for RECIPES/ORDERS}
     {}  ING_DefaultHighTol     : DOUBLE;        { for RECIPES/ORDERS}
         ING_SG            : DOUBLE;         {Specific Gravity}
         ING_Hazard_Code   : CHAR;           {Hazard Code}
         ING_Free_Byte     : BYTE;           {FREE}
         ING_Cost          : DOUBLE;         {Base Cost Of Ingredient}
     {}  ING_DefaultInstructions  : ARRAY [1..2] OF STRING[30]; {DEFAULT value
                                                          for ORDERS}
     {}  ING_DefaultYield  : DOUBLE;         { for RECIPES/ORDERS}
         ING_ScaleNo       : LONGINT;        {Scale That Ingredient Will Be Weighed On}
         ING_DefaultStdWt  : DOUBLE;         { for ORDERS}
         ING_NoTare        : BOOLEAN;
         ING_DefaultContSize : DOUBLE;       { for RECIPES/ORDERS}
         ING_PrepArea      : STRING[8];
         ING_Free_Space    : ARRAY [1..62] OF CHAR;
       END;

{SQL  Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

CREATE TABLE Ingredients IN DICTIONARY USING 'INGRED.FIL'
(
Ingredient      VARCHAR(8)  NOT NULL,
Description     VARCHAR(30) NOT NULL,
Process_Type    UTINYINT    NOT NULL,
Tol_NegPercent  DOUBLE      NOT NULL,
Tol_PosPercent  DOUBLE      NOT NULL,
Specif_Gravity  DOUBLE      NOT NULL,
Hazard_Code     CHAR(1)     NOT NULL,
Reserved1       CHAR(1)     NOT NULL,
Cost            DOUBLE      NOT NULL,
Instruction1    VARCHAR(30) NOT NULL,
Instruction2    VARCHAR(30) NOT NULL,
Mixing_Yield    DOUBLE      NOT NULL,
Reserved2       CHAR(4)     NOT NULL,
Standard_Wt     DOUBLE      NOT NULL,
No_Tare         BIT         NOT NULL,
Container_Wt    DOUBLE      NOT NULL,
Prep_Area       VARCHAR(8)  NOT NULL,
Reserved        CHAR(62)    NOT NULL
)#
CREATE UNIQUE INDEX ByIngredient IN DICTIONARY ON
 Ingredients(Ingredient)#
}

       PIngredientFile = ^TIngredientFile;
       TIngredientFile = Object(TBtrvFileObject)
         PROCEDURE   InitRecord     (VAR RecBuff); VIRTUAL;
         FUNCTION    GetIngredient  (Ingredient  : TIngredientRef;
                                     VAR RecBuff : TIngredient_Record;
                                     Lock         : BOOLEAN) : INTEGER; VIRTUAL;
         FUNCTION    GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
       END;

VAR IngredientFile : PIngredientFile;     { File Object Instance Pointer }


(*
PROCEDURE CalcIngredientTolWts(IngredRec      : PIngredient_Record;
                              TargetWeight   : DOUBLE;{ in current container }
                              MixType        : TMixType;
                              LineWtRequired : DOUBLE;{ in current mix }
                              LineWtDone     : DOUBLE;{ in current mix }
                              VAR LowestWt   : DOUBLE;
                              VAR HighestWt  : DOUBLE);
*)
FUNCTION  GetIngredientProcessType(VAR Ingredient : TingredientRef) : TProcessTypes;
FUNCTION  GetIngredientDesc(VAR Ingredient: TingredientRef) : STRING;
FUNCTION  GetProcessTypeName(Process : TProcessTypes) : STRING;

IMPLEMENTATION

FUNCTION GetProcessTypeName(Process : TProcessTypes) : STRING;
BEGIN
 IF (ORD(Process) >= ORD(Low(TProcessTypes))) AND
    (ORD(Process) <= ORD(High(TProcessTypes))) THEN
  BEGIN
   GetProcessTypeName := TProcessTypeNames[Process];
  END
 ELSE GetProcessTypeName := COPY(SPACE_STRING,1,7);
END;

FUNCTION TIngredientFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TIngredient_Record);
   Page_Size := 4096;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   INC(SegC,Set_Key(Key_Buf[0],1,09,K_EXTTYPE OR K_MODIFIABLE,
	    EKT_LSTRING,0));                     { 0.0 Ingredient Ref       }
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;


PROCEDURE TIngredientFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TIngredient_Record),#0);
 WITH TIngredient_Record(RecBuff) DO
  BEGIN
   ING_Ingredient      := SPACE_STRING;
   ING_Description     := SPACE_STRING;
   ING_DefaultProcessType := PTWeight;
   ING_DefaultLowTol   := 0;
   ING_DefaultHighTol  := 99.999;
   ING_DefaultInstructions[1] := SPACE_STRING;
   ING_DefaultInstructions[2] := SPACE_STRING;
   ING_DefaultYield    := 100.0;
   ING_SG              := 0.0;
   ING_Hazard_Code     := ' ';
   ING_Cost            := 0.0;
   ING_NoTare          := TRUE;
   ING_DefaultStdWt    := 0.0;
  END;
END;

{ GetIngredient ----- Function To Retrieve Record By Primary Key          }
FUNCTION TIngredientFile.GetIngredient  (Ingredient  : TIngredientRef;
                                         VAR RecBuff : TIngredient_Record;
                                         Lock        : BOOLEAN) : INTEGER;
VAR Result : INTEGER;
BEGIN
 InitRecord(RecBuff);
 RecBuff.ING_Ingredient := Ingredient;

 Result := OpenFile;
 IF Result = 0 THEN
  BEGIN
   Result := ReadRecord('EQ',Lock,FALSE,RecBuff,0);
   CloseFile;
  END;
 GetIngredient := Result;
END;


(* tolerance is now defined on recipe order lines
PROCEDURE CalcIngredientTolWts(IngredRec      : PIngredient_Record;
                               TargetWeight   : DOUBLE;{ in current container }
                               MixType        : TMixType;
                               LineWtRequired : DOUBLE;{ in current mix }
                               LineWtDone     : DOUBLE;{ in current mix }
                               VAR LowestWt   : DOUBLE;
                               VAR HighestWt  : DOUBLE);
BEGIN
 WITH IngredRec^ DO
  BEGIN
   IF MixType = mt_EqualContainersPerMix THEN
    BEGIN
     HighestWt := TargetWeight * (1+ (ING_HighTol/100));
     LowestWt  := TargetWeight * (1- (Abs(ING_LowTol)/100));
     {NOTE Original Ingredient File Had Negative LowTol so abs
           used to counter this}
     IF LowestWt < 0.0 THEN
       LowestWt := 0.0;
    END
   ELSE { high tolerance reflects total mix requirement for ingredient }
    BEGIN
     HighestWt := LineWtRequired * (1+ (ING_HighTol/100));
     HighestWt := HighestWt - LineWtDone;
     IF HighestWt < 0.0 THEN HighestWt := 0.0;

     LowestWt  := LineWtRequired * (1- (Abs(ING_LowTol)/100));
     LowestWt  := LowestWt - LineWtDone;
     IF  (TargetWeight > 0.0)
     AND (TargetWeight < LowestWt) THEN { another container expected afterwards }
       LowestWt :=  TargetWeight * (1- (Abs(ING_LowTol)/100));

     IF LowestWt < 0.0 THEN LowestWt := 0.0;
    END;
  END;
END;
*)

FUNCTION GetIngredientProcessType(VAR Ingredient : TingredientRef) : TProcessTypes;
VAR IngRec : TIngredient_Record;
    Result : INTEGER;
BEGIN
 GetIngredientProcessType := PTWeight;
 Result := IngredientFile^.GetIngredient(Ingredient,IngRec,FALSE);
 { IF Ingredient Record Found }
 IF Result = 0 THEN
  BEGIN
   IF (ORD(IngRec.ING_DefaultProcessType) >= Ord(Low(TProcessTypes))) AND
      (ORD(IngRec.ING_DefaultProcessType) <= Ord(High(TProcessTypes))) THEN
    GetIngredientProcessType :=IngRec.ING_DefaultProcessType;
  END;
END;

FUNCTION GetIngredientDesc(VAR Ingredient : TingredientRef) : STRING;
VAR IngRec : TIngredient_Record;
BEGIN
 IF IngredientFile^.GetIngredient(Ingredient,IngRec,FALSE) = 0 THEN
  BEGIN
   GetIngredientDesc :=IngRec.ING_Description;
  END
 ELSE
   GetIngredientDesc := COPY('Ingredient Not Found'+SPACE_STRING,1,30);
END;


BEGIN
 IngredientFile := NIL;
END.

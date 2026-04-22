(****************************************************************************
*  UNIT          : FXFCost                                                  *
*  AUTHOR        : N. S                                                     *
*  DATE          : 28/06/95                                                 *
*  PURPOSE       : FORMIX COSTING FILE                                      *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFCost;
INTERFACE
USES FILEOBJ,F6STDCTV,F6Btrv,FXMODCTV,FXcfg,FXFTrn;
CONST  Cost_FileName   = 'FXCOST.FIL';



TYPE   PCostRecord = ^TCostRecord;
       TCostRecord = PACKED RECORD
         COST_Ingredient     : TIngredientRef; {0.0}         {01-09}
         COST_LotNumber      : TLotRef;        {0.1}         {10-18}
         COST_Cost           : DOUBLE;                       {19-24}
         COST_WeightIn       : DOUBLE;                       {25-30}
         COST_Weighed        : DOUBLE;                       {31-36}
         COST_Unused         : DOUBLE;                       {37-42}
         COST_Wasted         : DOUBLE;                       {43-48}
         Reserved            : ARRAY[1..12] OF BYTE;         {49-60}
       END;

{SQL  Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

CREATE TABLE LotCost IN DICTIONARY USING 'FXCOST.FIL'
(Ingredient   VARCHAR(8) NOT NULL,
LotNo         VARCHAR(8) NOT NULL,
Cost          DOUBLE NOT NULL,
WeightIn      DOUBLE NOT NULL,
WeightUsed    DOUBLE NOT NULL,
Free1         CHAR(8) NOT NULL,
WeightWasted  DOUBLE NOT NULL,
Reserved      CHAR(12) NOT NULL
)#
CREATE UNIQUE NOT MODIFIABLE INDEX ByIngredientLot IN DICTIONARY ON LotCost(Ingredient , LotNo )#
}
    PCostFile = ^TCostFile;
    TCostFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
      FUNCTION   ReadRecord     (Operation  : STRING;
        	                     Lock,Multi : BOOLEAN;
      			                 VAR The_Record;
			                     Key        : BYTE): INTEGER;VIRTUAL;

      FUNCTION   AddRecord       (VAR The_Record) : INTEGER;VIRTUAL;
      FUNCTION   UpdateRecord    (VAR The_Record) : INTEGER;VIRTUAL;
      FUNCTION   GetCostRecord(VAR Ingredient : TIngredientRef;
                               VAR LotNumber  : TLotRef;
                               VAR CostRec    : TCostRecord;
                               Lock,Multi     : BOOLEAN): INTEGER;
    END;


VAR CostFile : PCostFile;     { File Object Instance Pointer }

IMPLEMENTATION

USES FXUTL;


TYPE   PCostDiskRecord = ^TCostDiskRecord;
       TCostDiskRecord = PACKED RECORD
{        COST_DummylenByte   : BYTE;}
         COST_Ingredient     : ARRAY[1..08] OF CHAR; {0.0}
{        COST_DummyLenByte2  : BYTE;}
         COST_LotNumber      : ARRAY[1..14] OF CHAR; {0.1}
         COST_Cost           : DOUBLE;
         COST_WeightIn       : DOUBLE;
         COST_Weighed        : DOUBLE;
         COST_Unused         : DOUBLE;
         COST_Wasted         : DOUBLE;
         Reserved            : ARRAY[1..12] OF BYTE;
       END;

{Used when adding/updating a record for datatype conversion between }
{Pascal Record and Database Record                                  }
PROCEDURE ConvertToDiskRecord(Src : PCostRecord; VAR Dst : TCostDiskRecord);
VAR i: Integer;
BEGIN
  LStrToCharStr(Src^.COST_Ingredient,Dst.COST_Ingredient,SizeOF(Dst.COST_Ingredient));
  LStrToCharStr(Src^.COST_LotNumber,Dst.COST_LotNumber,SizeOF(Dst.COST_LotNumber));
  Dst.COST_Cost      := Src^.COST_Cost;
  Dst.COST_WeightIn  := Src^.COST_WeightIn;
  Dst.COST_Weighed   := Src^.COST_Weighed;
  Dst.COST_Unused    := Src^.COST_Unused;
  Dst.COST_Wasted    := Src^.COST_Wasted;
  for i := 1 to SizeOF(Dst.Reserved) do
    Dst.Reserved[i] := Src^.Reserved[i];
END;

{Used when adding/updating a record for datatype conversion between }
{Pascal Record and Database Record                                  }
PROCEDURE ConvertToProgRecord(Src: PCostDiskRecord; VAR Dst: TCostRecord);
VAR i: Integer;
BEGIN
  FillChar(Dst,SizeOF(TCostRecord),#0);
  CharStrToLStr(Src^.COST_Ingredient,SizeOF(Src^.COST_Ingredient),Dst.COST_Ingredient);
  CharStrToLStr(Src^.COST_LotNumber,SizeOF(Src^.COST_LotNumber),Dst.COST_LotNumber);
  Dst.COST_Cost      := Src^.COST_Cost;
  Dst.COST_WeightIn  := Src^.COST_WeightIn;
  Dst.COST_Weighed   := Src^.COST_Weighed;
  Dst.COST_Unused    := Src^.COST_Unused;
  Dst.COST_Wasted    := Src^.COST_Wasted;
  for i := 1 to SizeOF(Dst.Reserved) do
    Dst.Reserved[i] := Src^.Reserved[i];
END;


FUNCTION TCostFile.ReadRecord(Operation  : STRING;
        		               Lock,Multi : BOOLEAN;
      			               VAR The_Record;
			                   Key        : BYTE): INTEGER;
Var StoreRec: TCostDiskRecord;
    FErr: INTEGER;
BEGIN
  ConvertToDiskRecord(@The_Record,StoreRec);
  FErr := INHERITED ReadRecord(Operation,Lock,Multi,StoreRec,Key);
  if (FErr = 0) THEN ConvertToProgRecord(@StoreRec,TCostRecord(The_Record));
  ReadRecord := FErr;
END;



FUNCTION TCostFile.AddRecord(VAR The_Record) : INTEGER;
VAR StoreRec: TCostDiskRecord;
BEGIN
  ConvertToDiskRecord(@The_Record,StoreRec);
  AddRecord := INHERITED AddRecord(StoreRec);
END;


FUNCTION TCostFile.UpdateRecord(VAR The_Record) : INTEGER;
VAR StoreRec: TCostDiskRecord;
BEGIN
  ConvertToDiskRecord(@The_Record,StoreRec);
  UpdateRecord := INHERITED UpdateRecord(StoreRec);
END;


PROCEDURE TCostFile.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TCostRecord),#0);
 WITH TCostRecord(RecBuff) DO
  BEGIN
   COST_Ingredient := SPACE_STRING;
   COST_LotNumber  := SPACE_STRING;
   COST_Cost       := 0;
   COST_WeightIn   := 0;
   COST_Weighed    := 0;
   COST_Unused     := 0;
   COST_Wasted     := 0;
  END;
END;

FUNCTION TCostFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TCostDiskRecord);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   {0.0 Ingredient}
   INC(SegC,Set_Key(Key_Buf[0],01,08,K_EXTTYPE OR K_SEGMENTED,
   EKT_STRING,0));
   {0.1 Lot}
   INC(SegC,Set_Key(Key_Buf[1],09,14,K_EXTTYPE,
   EKT_STRING,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;


FUNCTION TCostFile.GetCostRecord(VAR Ingredient : TIngredientRef;
                               VAR LotNumber  : TLotRef;
                               VAR CostRec    : TCostRecord;
                               Lock,Multi     : BOOLEAN) : INTEGER;
BEGIN
 InitRecord(CostRec);
 CostRec.COST_Ingredient := Ingredient;
 CostRec.COST_LotNumber  := LotNumber;
 GetCostRecord := ReadREcord('EQ',Lock,Multi,CostRec,0);
END;



END.

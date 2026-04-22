(****************************************************************************
*  UNIT          : FXFNet                                                   *
*  AUTHOR        : N. S                                                     *
*  DATE          : 28/06/95                                                 *
*  PURPOSE       : FORMIX NET PACKING TOTALS                                *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFNet;
INTERFACE
USES FILEOBJ,F6STDCTV,F6Btrv,FXMODCTV,FXcfg,FXFTrn;
CONST  NetPack_FileName   = 'FXNET.FIL';



TYPE   PNetRecord = ^TNetRecord;
       TNetRecord = PACKED RECORD
         NETW_Ingredient     : TIngredientRef;         {0.1}  {01-09}
         NETW_Date           : LONGINT;                {0.0}  {10-13}
         NETW_NetContainerWt : DOUBLE;                        {14-21}
         NETW_BatchNo        : TBatchRef;                     {22-28}
         NETW_LotNo          : TLotRef;                       {29-37}
         NETW_Containers     : LONGINT;                       {38-41}
         Reserved            : ARRAY[1..09] OF BYTE;          {42-50}
       END;


{SQL  Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

CREATE TABLE Ingred_Usage IN DICTIONARY USING 'FXNET.FIL'
(
Ingredient    VARCHAR(8) NOT NULL,
Date_Used     INTEGER    NOT NULL,
Net_Wt        DOUBLE     NOT NULL,
Batch_No      VARCHAR(6) NOT NULL,
Lot_No        VARCHAR(8) NOT NULL,
Trans_Count   INTEGER    NOT NULL,
Reserved      CHAR(9)    NOT NULL
)#
CREATE UNIQUE NOT MODIFIABLE INDEX ByDateBatLotIngred IN DICTIONARY ON
 Ingred_Usage(Date_Used , Batch_No , Lot_No , Ingredient)#
}

    PNetFile = ^TNetFile;
    TNetFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
      FUNCTION   ReadRecord     (Operation  : STRING;
        	                     Lock,Multi : BOOLEAN;
      			                 VAR The_Record;
			                     Key        : BYTE): INTEGER;VIRTUAL;

      FUNCTION   AddRecord       (VAR The_Record) : INTEGER;VIRTUAL;
      FUNCTION   UpdateRecord    (VAR The_Record) : INTEGER;VIRTUAL;
    END;


VAR NetFile : PNetFile;     { File Object Instance Pointer }

IMPLEMENTATION

USES FXUTL;

TYPE   PNetDiskRecord = ^TNetDiskRecord;
       TNetDiskRecord = PACKED RECORD
         NETW_Ingredient     : ARRAY[1..08] OF CHAR;   {0.1}
         NETW_Date           : LONGINT;                {0.0}
         NETW_NetContainerWt : DOUBLE;
         NETW_BatchNo        : ARRAY[1..06] OF CHAR;
         NETW_LotNo          : ARRAY[1..14] OF CHAR;
         NETW_Containers     : LONGINT;
         Reserved            : ARRAY[1..09] OF BYTE;
       END;


{Used when adding/updating a record for datatype conversion between }
{Pascal Record and Database Record                                  }
PROCEDURE ConvertToDiskRecord(CONST Src : TNetRecord; VAR Dst : TNetDiskRecord);
VAR i: Integer;
BEGIN
  LStrToCharStr(Src.NETW_Ingredient, Dst.NETW_Ingredient, SizeOf(Dst.NETW_Ingredient));
  Dst.NETW_Date           := Src.NETW_Date;
  Dst.NETW_NetContainerWt := Src.NETW_NetContainerWt;
  LStrToCharStr(Src.NETW_BatchNo, Dst.NETW_BatchNo, SizeOF(Dst.NETW_BatchNo));
  LStrToCharStr(Src.NETW_LotNo,   Dst.NETW_LotNo, SizeOF(Dst.NETW_LotNo));
  Dst.NETW_Containers := Src.NETW_Containers;
  for i := 1 to SizeOF(Dst.Reserved) do
    Dst.Reserved[i] := Src.Reserved[i];
END;

{Used when adding/updating a record for datatype conversion between }
{Pascal Record and Database Record                                  }
PROCEDURE ConvertToProgRecord(CONST Src: TNetDiskRecord; VAR Dst: TNetRecord);
VAR i: Integer;
BEGIN
  FillChar(Dst,SizeOF(TNetRecord),#0);
  CharStrToLStr(Src.NETW_Ingredient,SizeOF(Src.NETW_Ingredient),Dst.NETW_Ingredient);
  Dst.NETW_Date           := Src.NETW_Date;
  Dst.NETW_NetContainerWt := Src.NETW_NetContainerWt;
  CharStrToLStr(Src.NETW_BatchNo,SizeOF(Src.NETW_BatchNo),Dst.NETW_BatchNo);
  CharStrToLStr(Src.NETW_LotNo,SizeOF(Src.NETW_LotNo),Dst.NETW_LotNo);
  Dst.NETW_Containers := Src.NETW_Containers;
  for i := 1 to SizeOF(Dst.Reserved) do
    Dst.Reserved[i] := Src.Reserved[i];
END;


FUNCTION TNetFile.ReadRecord(Operation  : STRING;
        		               Lock,Multi : BOOLEAN;
      			               VAR The_Record;
			                   Key        : BYTE): INTEGER;
Var StoreRec: TNetDiskRecord;
    FErr: INTEGER;
BEGIN
  ConvertToDiskRecord(TNetRecord(The_Record),StoreRec);
  FErr := INHERITED ReadRecord(Operation,Lock,Multi,StoreRec,Key);
  if (FErr = 0) THEN ConvertToProgRecord(StoreRec,TNetRecord(The_Record));
  ReadRecord := FErr;
END;



FUNCTION TNetFile.AddRecord(VAR The_Record) : INTEGER;
VAR StoreRec: TNetDiskRecord;
BEGIN
  ConvertToDiskRecord(TNetRecord(The_Record), StoreRec);
  AddRecord := INHERITED AddRecord(StoreRec);
END;


FUNCTION TNetFile.UpdateRecord(VAR The_Record) : INTEGER;
VAR StoreRec: TNetDiskRecord;
BEGIN
  ConvertToDiskRecord(TNetRecord(The_Record), StoreRec);
  UpdateRecord := INHERITED UpdateRecord(StoreRec);
END;

PROCEDURE  TNetFile.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TNetRecord),#0);
 WITH TNetRecord(RecBuff) DO
  BEGIN
   NETW_Ingredient     := SPACE_STRING;
   NETW_Date           := 0;
   NETW_NetContainerWt := 0.0;
   NETW_BatchNo        := SPACE_STRING;
   NETW_LotNo          := SPACE_STRING;
  END;
END;

FUNCTION   TNetFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TNetDiskRecord);
   Page_Size := 4096;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   {0.0 transaction date}
   INC(SegC,Set_Key(Key_Buf[0],09,04,K_EXTTYPE OR K_SEGMENTED,
   EKT_INTEGER,0));

   {0.1 Batch Numbrt}
   INC(SegC,Set_Key(Key_Buf[1],21,06,K_EXTTYPE OR K_SEGMENTED,
   EKT_STRING,0));

   {0.1 Lot Number}
   INC(SegC,Set_Key(Key_Buf[2],27,14,K_EXTTYPE OR K_SEGMENTED,
   EKT_STRING,0));

   {0.2 ingredient}
   INC(SegC,Set_Key(Key_Buf[3],01,08,K_EXTTYPE,
   EKT_STRING,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;


END.

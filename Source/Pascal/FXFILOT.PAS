(****************************************************************************
*  UNIT          : FXFILOT                                                  *
*  AUTHOR        : N. Spooner / S. Wright                                   *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : FORMIX INGREDIENT LOT FILE                               *
                   Retains last lot number entered against an ingredient
                   on a scale so that it can be recalled on when ingredient
                   is re-selected.
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFILot;
INTERFACE
USES F6Btrv,F6StdCtv,FXModCtv,FileObj,F6STDWN1;

CONST LI_FileName = 'LOT.FIL';

TYPE

  PLotIngredientRecord = ^TLotIngredientRecord;
  TLotIngredientRecord = PACKED RECORD
   LI_Ingredient : TIngredientRef;       {0.0}
   LI_ScaleID    : INTEGER;              {0.1}
   LI_LotNumber  : TLotRef;
  END;



  PLotIngredientFile = ^TLotIngredientFile;
  TLotIngredientFIle = OBJECT(TBtrvFileObject)
   PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
   FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
   FUNCTION   ReadRecord     (Operation  : STRING;
        		      Lock,Multi : BOOLEAN;
      			      VAR The_Record;
			      Key        : BYTE): INTEGER;VIRTUAL;

   FUNCTION   AddRecord       (VAR The_Record) : INTEGER;VIRTUAL;
   FUNCTION   UpdateRecord    (VAR The_Record) : INTEGER;VIRTUAL;


   FUNCTION   Get_LI_Record(Ingredient : TIngredientRef;
                            ScaleID    : BYTE;
                            VAR LIRec  : TLotIngredientRecord;
                            Lock       : BOOLEAN) : INTEGER;

   FUNCTION   Add_LI_Record(Ingredient : TIngredientRef;
                            LotNumber  : TLotRef;
                            ScaleID    : BYTE;
                            VAR LIRec  : TLotIngredientRecord) : INTEGER;

   FUNCTION   Update_LI_Record(    Ingredient : TIngredientRef;
                                   LotNumber  : TLotRef;
                                   ScaleID    : BYTE;
                               VAR LIRec      : TLotIngredientRecord) : INTEGER;
  END;

VAR
  LotIngredientFile : PLotIngredientFile;



IMPLEMENTATION
{$IFNDEF TERMINAL}
USES FXFGen,FXUTL;
{$ELSE}
USES FXUTL;
{$ENDIF}



TYPE
  PLIDiskRecord = ^TLIDiskRecord;
  TLIDiskRecord = PACKED RECORD
   LI_Ingredient : ARRAY [1..08] OF CHAR; {0.0}
   LI_ScaleID    : INTEGER;               {0.1}
   LI_LotNumber  : ARRAY [1..14] OF CHAR;
  END;


{Used when adding/updating a record for datatype conversion between }
{Pascal Record and Database Record                                  }
PROCEDURE ConvertToDiskRecord(Src : PLotIngredientRecord; VAR Dst : TLIDiskRecord);
BEGIN
  LStrToCharStr(Src^.LI_Ingredient,Dst.LI_Ingredient,SizeOF(Dst.LI_Ingredient));
  Dst.LI_ScaleID := Src^.LI_ScaleID;
  LStrToCharStr(Src^.LI_LotNumber,Dst.LI_LotNumber,SizeOF(Dst.LI_LotNumber));
END;

{Used when adding/updating a record for datatype conversion between }
{Pascal Record and Database Record                                  }
PROCEDURE ConvertToProgRecord(Src: PLIDiskRecord; VAR Dst: TLotIngredientRecord);
BEGIN
  FillChar(Dst,SizeOF(TLotIngredientRecord),#0);
  CharStrToLStr(Src^.LI_Ingredient,SizeOF(Src^.LI_Ingredient),Dst.LI_Ingredient);
  Dst.LI_ScaleID := Src^.LI_ScaleID;
  CharStrToLStr(Src^.LI_LotNumber,SizeOF(Src^.LI_LotNumber),Dst.LI_LotNumber);
END;



FUNCTION TLotIngredientFile.ReadRecord(Operation  : STRING;
        		               Lock,Multi : BOOLEAN;
      			               VAR The_Record;
			               Key        : BYTE): INTEGER;
Var StoreRec: TLIDiskRecord;
    FErr: INTEGER;
BEGIN
  ConvertToDiskRecord(@The_Record,StoreRec);
  FErr := INHERITED ReadRecord(Operation,Lock,Multi,StoreRec,Key);
  if (FErr = 0) THEN ConvertToProgRecord(@StoreRec,TLotIngredientRecord(The_Record));
  ReadRecord := FErr;
END;



FUNCTION TLotIngredientFile.AddRecord(VAR The_Record) : INTEGER;
VAR StoreRec: TLIDiskRecord;
BEGIN
  ConvertToDiskRecord(@The_Record,StoreRec);
  AddRecord := INHERITED AddRecord(StoreRec);
END;


FUNCTION TLotIngredientFile.UpdateRecord(VAR The_Record) : INTEGER;
VAR StoreRec: TLIDiskRecord;
BEGIN
  ConvertToDiskRecord(@The_Record,StoreRec);
  UpdateRecord := INHERITED UpdateRecord(StoreRec);
END;


PROCEDURE TLotIngredientFIle.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOf(TLotIngredientRecord),#0);
 WITH TLotIngredientRecord(RecBuff) DO
  BEGIN
   LI_Ingredient := SPACE_STRING;
   LI_LotNumber  := SPACE_STRING;
  END;
END;

FUNCTION TLotIngredientFIle.GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TLIDiskRecord);
   Page_Size := 1024;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.1 Ingrdient Code}
   INC(SegC,Set_Key(Key_Buf[0],01,08,K_EXTTYPE OR K_SEGMENTED,
       EKT_STRING,0));
   { 0.1 Machine ID }
   INC(SegC,Set_Key(Key_Buf[1],09,02,K_EXTTYPE ,EKT_INTEGER,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

FUNCTION TLotIngredientFile.Get_LI_Record(Ingredient : TIngredientRef;
                                          ScaleID    : BYTE;
                                          VAR LIRec  : TLotIngredientRecord;
                                          Lock       : BOOLEAN) : INTEGER;
VAR ReadResult : INTEGER;
BEGIN
 OpenFile;                                  { Open File if not Already Open}
 LIRec.LI_Ingredient := Ingredient;         { Prime Key Fields             }
 LIRec.LI_ScaleID    := ScaleID;
 ReadResult := ReadRecord('EQ',Lock,FALSE,LIRec,0); { Attempt Read         }
 CloseFile;                                 { Close File if Opened Here    }
 BtrvErr := ReadResult;                     { Set BtrvErr To Read Op. Error}
 GET_LI_Record := BtrvErr;                  { Return Read Op. Error        }
END;

FUNCTION TLotIngredientFile.Add_LI_Record(Ingredient : TIngredientRef;
                                          LotNumber  : TLotRef;
                                          ScaleID    : BYTE;
                                          VAR LIRec  : TLotIngredientRecord) : INTEGER;
VAR AddResult  : INTEGER;
BEGIN
 OpenFile;                                  { Open File if not Already Open}
 LIRec.LI_Ingredient := Ingredient;         { Fill Record Buffer           }
 LIRec.LI_ScaleID    := ScaleID;
 LIRec.LI_LotNumber  := LotNumber;
 AddResult := AddRecord(LIRec);             { Add Record                   }
 CloseFile;                                 { Close File if Opened Here    }
 BtrvErr := AddResult;                      { Set BtrvErr To Add Op. Error }
 Add_LI_Record := BtrvErr;                  { Return Add Op. Error         }
END;

FUNCTION TLotIngredientFile.Update_LI_Record(    Ingredient : TIngredientRef;
                                                 LotNumber  : TLotRef;
                                                 ScaleID    : BYTE;
                                             VAR LIRec      : TLotIngredientRecord) : INTEGER;
VAR UpdateResult  : INTEGER;
BEGIN
 OpenFile;                                       { Open File if not open }
 WITH LIRec DO
  BEGIN
   IF Get_LI_Record(Ingredient,ScaleID,LIRec,TRUE) = 0 THEN
    BEGIN
     LIRec.LI_LotNumber  := LotNumber;    { Change Lot Number            }
     UpdateRecord(LIRec);                 { Update Record                }
    END;
  END;
 UpdateResult := BtrvErr;                 { Save Result Code             }
 CloseFile;                               { Close File if Opened Here    }
 BtrvErr := UpdateResult;                 { Set BtrvErr To Op. Error     }
 Update_LI_Record := BtrvErr;             { Return Op. Error             }
END;

END.

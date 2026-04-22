(****************************************************************************
*  UNIT          : FXFTRN                                                   *
*  AUTHOR        : N. Spooner & S. Wright                                   *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : FORMIX TRANSACTION FILE                                  *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFTRN;
INTERFACE
USES FILEOBJ,F6STDCTV,F6Btrv,FXMODCTV,FXcfg,F6StdUtl;
CONST  Transaction_FileName   = 'FXTrans.FIL';
CONST  MAX_MID = 100;


CONST {Status Types}
       TRNStatusActive  = 1;
       TRNStatusAborted = 2;  {Note Abort Mix Option From Scale}
(*
       TRNPartialActive = 3;
       TRNPartialAborted= 4;
*)

{SQL  Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

SET TRUENULLCREATE=OFF#
DROP TABLE Transactions IN DICTIONARY#
CREATE TABLE Transactions IN DICTIONARY USING 'FXTRANS.FIL'
(
Reserved1        UTINYINT,
Ingredient       CHAR(8),
Order_No         INTEGER,
Reserved2        UTINYINT,
Recipe_No        CHAR(8),
MC_ID            USMALLINT,
Serial_No        INTEGER,
Reserved3        UTINYINT,
Trans_Time       CHAR(5),
Trans_Date       INTEGER,
Order_Line_No    INTEGER,
Reserved4        CHAR(1),
Weight_In_Mix    DOUBLE,
Reserved5        UTINYINT,
Batch_No         CHAR(6),
Reserved6        UTINYINT,
Lot_No           CHAR(14) NOT NULL,
Container_No     SMALLINT,
Mix_No           USMALLINT,
Status           USMALLINT,
Order_No_Suffix  UTINYINT,
TempChecked      UTINYINT,
User_ID          CHAR(8),
Calc_Post_Mix_Wt DOUBLE,
Weight_on_Scale  DOUBLE,
Source_code_id   INTEGER,
Temperature      DOUBLE
)#
CREATE NOT MODIFIABLE INDEX ByDateOrder IN DICTIONARY ON
 Transactions(Trans_Date , Order_No , Order_No_Suffix)#
CREATE UNIQUE NOT MODIFIABLE INDEX ById IN DICTIONARY ON
 Transactions(MC_Id , Serial_No)#
CREATE NOT MODIFIABLE INDEX ByOrderMixLine IN DICTIONARY ON
 Transactions(Order_No , Order_No_Suffix , Mix_No , Order_Line_No)#
SET TRUENULLCREATE=ON#
}

TYPE
       PTranRecord = ^TTranRecord;
       TTranRecord = PACKED RECORD
         TRN_Ingredient     : TIngredientRef;                {01-09}
         TRN_OrderNo        : LONGINT;                {0.1}  {10-13}
         TRN_RecipeNo       : TRecipeRef;                    {14-22}
         TRN_Mid            : WORD;                   {1.0}  {23-24}
         TRN_SerialNo       : LONGINT;                {1.1}  {25-28}
         TRN_Time           : Time_Type;                     {29-34}
         TRN_Date           : LONGINT;                {0.0}  {35-38}
         TRN_OrderLineNo    : LONGINT; {29-43 order line no tran was for }
         TRN_RESERVED2      : BYTE;
         TRN_ContainerWt    : DOUBLE;  {44-51 wt contribution to gross mix wt }
         TRN_BatchNo        : TBatchRef;                     {52-58}
         TRN_LotNo          : TLotRef;                       {59-67}
         TRN_ContainerNo    : INTEGER; {68-69 Container number within mix }
{                             Note: could be multiple fixed wt
                                    trans for ingred in a container.
}
                                       {      ingredient in TRN_MixNo  }
         TRN_MixNo          : WORD;    {70-71 tran for Mix no. in TRN_Orderno}
         TRN_Status         : WORD;                          {72-73}
         TRN_Revision       : BYTE;                          {74-74}
         TRN_TempChecked    : BYTE;
         TRN_UserID         : TUserRef;
         TRN_CalcNetWt      : DOUBLE;  { calculated net weight after mixing }
         TRN_ActualWeight   : DOUBLE;  { real weight of trans }
         TRN_SourceId       : LONGINT; {not used yet - will relate to new table}
         TRN_Temperature    : DOUBLE;
       END;

    PTransFile = ^TTransFile;
    TTransFile = Object(TBtrvFileObject)
      //DiskRec : TTranDiskRecord;
      FUNCTION    ReadRecord(Operation  : STRING;
                             Lock,Multi : BOOLEAN;
                             VAR The_Record;
                             Key        : BYTE): INTEGER;VIRTUAL;
      FUNCTION    AddRecord       (VAR The_Record) : INTEGER;VIRTUAL;
      FUNCTION    UpdateRecord    (VAR The_Record) : INTEGER;VIRTUAL;
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
      FUNCTION   GetTotsForMixLine(OrderNo        : LONGINT;
                                   Revision       : BYTE;
                                   MixNo          : WORD;
                                   OrderLineNo    : LONGINT;
                                   VAR TotCont    : LONGINT;
                                   VAR TotWt      : DOUBLE) : INTEGER;
      FUNCTION   GetTermsLastActiveTranForOrd(ThisMid  : WORD;
                                          OrderNo  : LONGINT;
                                          Revision : BYTE;
                                          VAR LastTran : TTranRecord) : BOOLEAN;

    PRIVATE
      PROCEDURE ProgRecToDiskRec(CONST The_Record; VAR ADiskRec);
      PROCEDURE DiskRecToProgRec(CONST ADiskRec; VAR The_Record);

    END;

FUNCTION GetTRNStatusType (Stat : WORD) : STRING;
PROCEDURE AbortTranRecord(TRNRec : PTranRecord);

VAR TransFile : PTransFile;     { File Object Instance Pointer }

IMPLEMENTATION

USES FXUTL;

TYPE
       PTranDiskRecord = ^TTranDiskRecord;
       TTranDiskRecord = PACKED RECORD
         TRND_ObsoleteLen1 : BYTE;
         TRND_Ingredient     : ARRAY[1..8] OF CHAR;
         TRND_OrderNo        : LONGINT;
         TRND_ObsoleteLen2 : BYTE;
         TRND_RecipeNo       : ARRAY[1..8] OF CHAR;
         TRND_Mid            : WORD;                   {1.0}
         TRND_SerialNo       : LONGINT;                {1.1}
         TRND_ObsoleteLen3 : BYTE;
         TRND_Time           : ARRAY[1..5] OF CHAR;
         TRND_Date           : LONGINT;                {0.0}
         TRND_OrderLineNo    : LONGINT; {order line no tran was for }
         TRND_RESERVED2      : BYTE;
         TRND_ContainerWt    : DOUBLE;  {wt contribution to gross mix wt }
         TRND_ObsoleteLen5 : BYTE;
         TRND_BatchNo        : ARRAY[1..6] OF CHAR;
         TRND_ObsoleteLen6 : BYTE;
         TRND_LotNo          : ARRAY[1..14] OF CHAR;
         TRND_ContainerNo    : INTEGER;
         TRND_MixNo          : WORD;    {tran for Mix no. in TRND_Orderno}
         TRND_Status         : WORD;
         TRND_Revision       : BYTE;
         TRND_TempChecked    : BYTE;
         TRND_UserID         : ARRAY[1..8] OF CHAR;
         TRND_CalcNetWt      : DOUBLE;  { calculated net weight after mixing }
         TRND_ActualWeight   : DOUBLE;  { real weight of trans }
         TRND_SourceId       : LONGINT; {not used yet - will relate to new table}
         TRND_Temperature    : DOUBLE;
       END;


FUNCTION GetTRNStatusType (Stat : WORD) : STRING;
VAR S : STRING[15];
BEGIN
 CASE Stat OF
  TRNStatusActive  : S:= 'Active'+SPACE_STRING;
  TRNStatusAborted : S:= 'Aborted'+SPACE_STRING;
(*
  TRNPartialActive : S:= 'Partial Active'+SPACE_STRING;
  TRNPartialAborted: S:= 'Partial Aborted'+SPACE_STRING;
*)
  ELSE S:= 'Invalid'+Space_String;
  END;
 GetTRNStatusType := S;
END;


PROCEDURE AbortTranRecord(TRNRec : PTranRecord);
BEGIN
(*
 IF (TRNRec^.TRN_Status = TRNStatusActive) THEN
  TRNRec^.TRN_Status := TRNStatusAborted
 ELSE IF (TRNRec^.TRN_Status = TRNPartialActive) THEN
  TRNRec^.TRN_Status := TRNPartialAborted
 ELSE
*)
  TRNRec^.TRN_Status := TRNStatusAborted;
END;


PROCEDURE TTransFile.ProgRecToDiskRec(CONST The_Record; VAR ADiskRec);
BEGIN
 FillChar(ADiskRec, SizeOf(ADiskRec), 0);
 WITH TTranDiskRecord(ADiskRec), TTranRecord(The_Record)  DO
  BEGIN
   LStrToCharStr      (TRN_Ingredient, TRND_Ingredient, SizeOf(TRND_Ingredient));
   TRND_OrderNo     := TRN_OrderNo;
   LStrToCharStr      (TRN_RecipeNo,   TRND_RecipeNo,   SizeOf(TRND_RecipeNo));
   TRND_Mid         := TRN_Mid;
   TRND_SerialNo    := TRN_SerialNo;
   LStrToCharStr      (TRN_Time,       TRND_Time, SizeOf(TRND_Time));
   TRND_Date        := TRN_Date;
   TRND_OrderLineNo := TRN_OrderLineNo;
   TRND_RESERVED2   := TRN_RESERVED2;
   TRND_ContainerWt := TRN_ContainerWt;
   LStrToCharStr      (TRN_BatchNo,    TRND_BatchNo, SizeOf(TRND_BatchNo));
   LStrToCharStr      (TRN_LotNo,      TRND_LotNo,   SizeOf(TRND_LotNo));
   TRND_ContainerNo := TRN_ContainerNo;
   TRND_MixNo       := TRN_MixNo;
   TRND_Status      := TRN_Status;
   TRND_Revision    := TRN_Revision;
   TRND_TempChecked := TRN_TempChecked;
   LStrToCharStr      (TRN_UserID,     TRND_UserId,  SizeOf(TRND_UserId));
   TRND_CalcNetWt   := TRN_CalcNetWt;
   TRND_ActualWeight:= TRN_ActualWeight;
   TRND_SourceId    := TRN_SourceId;
   TRND_Temperature := TRN_Temperature;
  END;
END;

PROCEDURE TTransFile.DiskRecToProgRec(CONST ADiskRec; VAR The_Record);
BEGIN
 WITH TTranDiskRecord(ADiskRec), TTranRecord(The_Record)  DO
  BEGIN
   CharStrToLStr     (TRND_Ingredient, SizeOf(TRND_Ingredient), TRN_Ingredient);
   TRN_OrderNo     := TRND_OrderNo;
   CharStrToLStr     (TRND_RecipeNo,   SizeOf(TRND_RecipeNo),   TRN_RecipeNo);
   TRN_Mid         := TRND_Mid;
   TRN_SerialNo    := TRND_SerialNo;
   CharStrToLStr     (TRND_Time,       SizeOf(TRND_Time),       TRN_Time);
   TRN_Date        := TRND_Date;
   TRN_OrderLineNo := TRND_OrderLineNo;
   TRN_RESERVED2   := TRND_RESERVED2;
   TRN_ContainerWt := TRND_ContainerWt;
   CharStrToLStr     (TRND_BatchNo,    SizeOf(TRND_BatchNo),    TRN_BatchNo);
   CharStrToLStr     (TRND_LotNo,      SizeOf(TRND_LotNo),      TRN_LotNo);
   TRN_ContainerNo := TRND_ContainerNo;
   TRN_MixNo       := TRND_MixNo;
   TRN_Status      := TRND_Status;
   TRN_Revision    := TRND_Revision;
   TRN_TempChecked := TRND_TempChecked;
   CharStrToLStr     (TRND_UserID,     SizeOf(TRND_UserId),     TRN_UserId);
   TRN_CalcNetWt   := TRND_CalcNetWt;
   TRN_ActualWeight:= TRND_ActualWeight;
   TRN_SourceId    := TRND_SourceId;
   TRN_Temperature := TRND_Temperature;
  END;
END;

FUNCTION TTransFile.ReadRecord(Operation  : STRING;
                               Lock,Multi : BOOLEAN;
                               VAR The_Record;
                               Key        : BYTE): INTEGER;{VIRTUAL;}
VAR DiskRec: TTranDiskRecord;
BEGIN
 ProgRecToDiskRec(The_Record, DiskRec);
 ReadRecord := INHERITED ReadRecord(Operation,Lock,Multi,DiskRec,Key);
 DiskRecToProgRec(DiskRec, The_Record);
END;

FUNCTION TTransFile.AddRecord(VAR The_Record) : INTEGER;{VIRTUAL;}
VAR DiskRec: TTranDiskRecord;
BEGIN
 ProgRecToDiskRec(The_Record, DiskRec);
 AddRecord := INHERITED AddRecord(DiskRec);
END;

FUNCTION TTransFile.UpdateRecord(VAR The_Record) : INTEGER;{VIRTUAL;}
VAR DiskRec: TTranDiskRecord;
BEGIN
 ProgRecToDiskRec(The_Record, DiskRec);
 UpdateRecord := UpdateRecord(DiskRec);
END;

PROCEDURE  TTransFile.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TTranRecord),#0);
 WITH TTranRecord(RecBuff) DO
  BEGIN
   TRN_Ingredient     := SPACE_STRING;
   TRN_OrderNo        := 0;
   TRN_OrderLineNo    := 0;
   TRN_RecipeNo       := SPACE_STRING;
   TRN_Mid            := 0;
   TRN_SerialNo       := 0;
   TRN_Time           := SPACE_STRING;     { ???}
   TRN_Date           := 0;                { ???}
   TRN_UserID         := SPACE_STRING;
   TRN_ActualWeight   := 0.0;
   TRN_BatchNo        := SPACE_STRING;
   TRN_LotNo          := SPACE_STRING;
   TRN_ContainerNo    := 0;
   TRN_MixNo          := 0;
   TRN_Revision       := 0;
   TRN_UserID         := SPACE_STRING;
   TRN_CalcNetWt      := 0.0;
   TRN_ContainerWt    := 0.0;
  END;
END;

FUNCTION   TTransFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
    DummyRec: TTranDiskRecord;
BEGIN
 SegC := 0;
 WITH FileSpec, DummyRec DO
  BEGIN
   Rec_Len   := SizeOf(DummyRec);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 3;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   {0.0 transaction date}
   INC(SegC,Set_Key(Key_Buf[0],BFieldPos(DummyRec, TRND_Date),
                    SizeOf(TRND_Date),K_EXTTYPE OR K_DUPLICATE OR K_SEGMENTED,
                    EKT_INTEGER,0));
   {0.1 work number}
   INC(SegC,Set_Key(Key_Buf[1],BFieldPos(DummyRec, TRND_OrderNo),
                    SizeOf(TRND_OrderNo),K_EXTTYPE OR K_DUPLICATE OR K_SEGMENTED,
                    EKT_INTEGER,0));
   {0.2 Revision}
   INC(SegC,Set_Key(Key_Buf[2],BFieldPos(DummyRec, TRND_Revision),
                    SizeOf(TRND_Revision),K_EXTTYPE OR K_DUPLICATE,
                    EKT_UNSIGNED_BIN,0));
   {1.0 Machine ID}
   INC(SegC,Set_Key(Key_Buf[3],BFieldPos(DummyRec, TRND_Mid),
                    SizeOf(TRND_mid),K_EXTTYPE OR K_SEGMENTED,
                    EKT_UNSIGNED_BIN,0));
   {1.1 Run Number}
   INC(SegC,Set_Key(Key_Buf[4],BFieldPos(DummyRec, TRND_SerialNo),
                    SizeOf(TRND_SerialNo),K_EXTTYPE,
                    EKT_INTEGER,0));
   {2.0 Work No}
   INC(SegC,Set_Key(Key_Buf[5],BFieldPos(DummyRec, TRND_OrderNo),
                    SizeOf(TRND_OrderNo),K_EXTTYPE OR K_DUPLICATE OR K_SEGMENTED,
                    EKT_INTEGER,0));
   {2.1 Revision}
   INC(SegC,Set_Key(Key_Buf[6],BFieldPos(DummyRec, TRND_Revision),
                    SizeOf(TRND_Revision),K_EXTTYPE OR K_DUPLICATE OR K_SEGMENTED,
                    EKT_UNSIGNED_BIN,0));
   {2.2 MixNo}
   INC(SegC,Set_Key(Key_Buf[7],BFieldPos(DummyRec, TRND_MixNo),
                    SizeOf(TRND_MixNo),K_EXTTYPE OR K_DUPLICATE OR K_SEGMENTED,
                    EKT_UNSIGNED_BIN,0));
   {2.3 Order line no.}
   INC(SegC,Set_Key(Key_Buf[8],BFieldPos(DummyRec, TRND_OrderLineNo),
                    SizeOf(TRND_OrderLineNo),
                    K_EXTTYPE OR K_DUPLICATE,
                    EKT_INTEGER,0))
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;


FUNCTION TTransFile.GetTotsForMixLine(OrderNo        : LONGINT;
                                      Revision       : BYTE;
                                      MixNo          : WORD;
                                      OrderLineNo    : LONGINT;
                                      VAR TotCont    : LONGINT;
                                      VAR TotWt      : DOUBLE) : INTEGER;
{ Returns critical btrv errors.
  Sets TotCont and TotQt to no of weighings and wt for for ingredient
  on mix: MixNo.
}
VAR
   TRNRec  : TTranRecord;
   ReadErr : INTEGER;

BEGIN
 TotCont := 0;
 TotWt   := 0.0;

 OpenFile;
 FillChar(TRNRec,SizeOf(TRNRec),#0);
 TRNRec.TRN_OrderNo     := OrderNo;
 TRNRec.TRN_Revision    := Revision;
 TRNRec.TRN_MixNo       := MixNo;
 TRNRec.TRN_OrderLineNo := OrderLineNo;
 ReadErr := TransFile^.ReadRecord('GE',FALSE,FALSE,TRNRec,2);
 WHILE (ReadErr = 0)
 AND   (TRNRec.TRN_OrderNo     = OrderNo)
 AND   (TRNRec.TRN_Revision    = Revision)
 AND   (TRNRec.TRN_MixNo       = MixNo)
 AND   (TRNRec.TRN_OrderLineNo = OrderLineNo) DO
  BEGIN
   IF  (TRNRec.TRN_Status <> TRNStatusAborted) THEN
    BEGIN
     Inc(TotCont);
     TotWt := TotWt + TRNRec.TRN_ContainerWt;
    END;
   ReadErr := TransFile^.ReadRecord('GN',FALSE,FALSE,TRNRec,2);
  END;

 IF BtrvErrType(ReadErr) = berr_Nack THEN
   ReadErr := 0;

 CloseFile;
 GetTotsForMixLine := ReadErr;
END;


FUNCTION TTransFile.GetTermsLastActiveTranForOrd(ThisMid  : WORD;
                                             OrderNo  : LONGINT;
                                             Revision : BYTE;
                                             VAR LastTran : TTranRecord) : BOOLEAN;
{REQUIRES Each terminal to be set up with different mids.
          Assumes serial nos will always increment during any one day.
 PROMISES Returns TRUE if it finds a tran.
          'LastTran' will return tran found else be nulled out.
}
VAR
   TRNRec   : TTranRecord;
   ReadErr  : INTEGER;
   FoundOne : BOOLEAN;

BEGIN
 FoundOne := FALSE;
 FillChar(LastTran, SizeOf(LastTran), 0);

 OpenFile;
 FillChar(TRNRec,SizeOf(TRNRec),#0);
 TRNRec.TRN_OrderNo     := OrderNo;
 TRNRec.TRN_Revision    := Revision;
{TRNRec.TRN_MixNo       :=}
{TRNRec.TRN_OrderLineNo :=}
 ReadErr := TransFile^.ReadRecord('GE',FALSE,FALSE,TRNRec,2);
 WHILE (ReadErr = 0)
 AND   (TRNRec.TRN_OrderNo     = OrderNo)
 AND   (TRNRec.TRN_Revision    = Revision) DO
  BEGIN
   IF  (TRNRec.TRN_mid = ThisMid)
   AND (TRNRec.TRN_Status = TRNStatusActive) THEN
    BEGIN
     IF (TRNRec.TRN_Date > LastTran.TRN_Date)      { obviously later }
     OR (    (TRNRec.TRN_Date = LastTran.TRN_Date) { or apparently later }
         AND (TRNRec.TRN_SerialNo > LastTran.TRN_SerialNo)) THEN
      BEGIN
       FoundOne := TRUE;
       LastTran := TRNRec;
      END;
    END;
   ReadErr := TransFile^.ReadRecord('GN',FALSE,FALSE,TRNRec,2);
  END;

 IF BtrvErrType(ReadErr) = berr_Nack THEN
   ReadErr := 0;

 CloseFile;
 GetTermsLastActiveTranForOrd := FoundOne;
END;

END.

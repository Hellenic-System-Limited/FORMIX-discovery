(****************************************************************************
*  UNIT          : FXFProd                                                  *
*  AUTHOR        : N. Spooner                                               *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : FORMIX PRODUCT FILE                                      *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFProd;
INTERFACE
USES F6StdWn1,F6Btrv,FileObj,F6StdCtv,FXModCtv,F6StdUtl;
CONST Product_Header_FileName = 'PRODHEAD.FIL';
      Product_Line_FileName   = 'PRODLINE.FIL';
      Product_Desc_FileName   = 'PRODDESC.FIL';
      Product_Order_FileName  = 'PRODORD.FIL';

TYPE
     PProdOrderRecord = ^TProdOrderRecord;
     TProdOrderRecord = PACKED RECORD
       PO_OrderNo     : LONGINT;   {Uses Same Order Number As Work Order}
       PO_Date        : LONGINT;
       PO_ProductCode : TProductRef;
       PO_NumOrders   : WORD;
       PO_Method      : WORD;
       PO_TotalWt     : DOUBLE;
       PO_Containers  : LONGINT;
       Reserved       : ARRAY[0..59] OF BYTE;
     END;

{SQL  Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

CREATE TABLE Prod_Schedule IN DICTIONARY USING 'PRODORD.FIL'
(
Order_No       INTEGER     NOT NULL,
Schedule_Date  INTEGER     NOT NULL,
Product_Code   VARCHAR(10) NOT NULL,
No_Of_Orders   USMALLINT   NOT NULL,
Product_Method SMALLINT    NOT NULL,
Weight_Reqd    DOUBLE      NOT NULL,
Cases_Reqd     INTEGER     NOT NULL,
Reserved       CHAR(60)    NOT NULL
)#
CREATE UNIQUE NOT MODIFIABLE INDEX ByDateOrder IN DICTIONARY ON
 Prod_Schedule(Schedule_Date , Order_No)#
CREATE UNIQUE NOT MODIFIABLE INDEX ByOrder IN DICTIONARY ON
 Prod_Schedule(Order_No)#
}

     PProdHeaderRecord = ^TProdHeaderRecord;
     TProdHeaderRecord = PACKED RECORD
       PH_ProductCode : TProductRef;                   {0.0}
       PH_Description : STRING[30];
       PH_UpdateCount : LONGINT;
       PH_NumMethods  : INTEGER;
       PH_CaseSize    : DOUBLE;
       Reserved       : ARRAY[0..55] OF BYTE;
     END;
{SQL  Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

CREATE TABLE Prod_Header IN DICTIONARY USING 'PRODHEAD.FIL'
(
Product_Code   VARCHAR(10) NOT NULL,
Description    VARCHAR(30) NOT NULL,
Updates        INTEGER     NOT NULL,
No_Of_Methods  SMALLINT    NOT NULL,
Case_Weight    DOUBLE      NOT NULL,
Reserved       CHAR(56)    NOT NULL
)#
CREATE UNIQUE NOT MODIFIABLE INDEX ByProd IN DICTIONARY ON
 Prod_Header(Product_Code)#
}

     PProdLineRecord = ^TProdLineRecord;
     TProdLineRecord = PACKED RECORD
       PL_ProductCode : TProductRef;                   {0.0}
       PL_LineNo      : INTEGER;
       PL_RecipeNo    : TRecipeRef;
       PL_Ratio       : DOUBLE;
       PL_SubProduct  : TProductRef;
       Reserved       : ARRAY[0..52] OF BYTE;
     END;

{SQL  Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

CREATE TABLE Prod_Line IN DICTIONARY USING 'PRODLINE.FIL'
(
Product_Code   VARCHAR(10) NOT NULL,
Line_No        SMALLINT    NOT NULL,
Recipe_Code    VARCHAR(8)  NOT NULL,
Percentage     DOUBLE      NOT NULL,
Sub_Product    VARCHAR(10) NOT NULL,
Reserved       CHAR(53)    NOT NULL
)#
CREATE UNIQUE INDEX ByProdLine IN DICTIONARY ON
 Prod_Line(Product_Code , Line_No)#
}

     PProdDescription = ^TProdDescription;
     TProdDescription = PACKED RECORD
       PD_ProductCode : TProductRef;                   {0.0}
       PD_LineNo      : INTEGER;  { line 0 record holds method name in description }
       PD_Method      : INTEGER;
       PD_Description : STRING[40];
       Reserved       : ARRAY[0..63] OF BYTE;
     END;
{SQL  Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

CREATE TABLE Prod_Instructions IN DICTIONARY USING 'PRODDESC.FIL'
(
Product_Code   VARCHAR(10) NOT NULL,
Method_Line_No SMALLINT    NOT NULL,
Product_Method SMALLINT    NOT NULL,
Description    VARCHAR(40) NOT NULL,
Reserved       CHAR(64)    NOT NULL
)#
CREATE UNIQUE NOT MODIFIABLE INDEX ByProdMethodLine IN DICTIONARY ON
 Prod_Instructions(Product_Code , Product_Method , Method_Line_No)#
}

  PProdOrderFile = ^TProdOrderFile;
  TProdOrderFile = OBJECT(TBtrvFileObject)
   PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
   FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
  END;


  PProdHeaderFile = ^TProdHeaderFile;
  TProdHeaderFIle = OBJECT(TBtrvFileObject)
   PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
   FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
  END;

  PProdLineFile = ^TProdLineFile;
  TProdLineFile = OBJECT(TBtrvFileObject)
   PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
   FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
   FUNCTION   DelLinesForProd(ProductCode : TProductRef) : INTEGER; VIRTUAL;
  END;

  PProdDescFile = ^TProdDescFile;
  TProdDescFile = OBJECT(TBtrvFileObject)
   PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
   FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
   FUNCTION   DeleteDescriptions(ProductCode : TProductRef) : INTEGER; VIRTUAL;
  END;

VAR ProdHeaderFile : PProdHeaderFile;
    ProdLineFile   : PProdLineFile;
    ProdDescFile   : PProdDescFile;
    ProdOrderFile  : PProdOrderFile;

FUNCTION GetInstructionName(Product : TProductRef;MethodNo : INTEGER):STRING;
FUNCTION GetProductName(VAR ProdCode : TProductRef) : STRING;
FUNCTION CheckForCircularProductRef(VAR ProdCode : TProductRef):BOOLEAN;

IMPLEMENTATION

{==================== PRODUCT ORDERING FILE ==========================}

FUNCTION GetProductName(VAR ProdCode : TProductRef) : STRING;
VAR ProdRec : TProdHeaderRecord;
BEGIN
 ProdRec.PH_ProductCode := ProdCode;
 IF ProdHeaderFile^.ReadRecord('EQ',FALSE,FALSE,ProdRec,0) = 0 THEN
  GetProductName := ProdRec.PH_DEscription
 ELSE
  GetProductName := COPY(SPACE_STRING,1,30);
END;


PROCEDURE TProdOrderFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOf(TProdOrderRecord),#0);
 WITH TProdOrderRecord(RecBuff) DO
  BEGIN
   PO_ProductCode := SPACE_STRING;
  END;
END;

FUNCTION TProdOrderFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TProdOrderRecord);
   Page_Size := 1024;
   File_Flags:= 0;
   Ndx_Cnt   := 2;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.0 Date Code}
   INC(SegC,Set_Key(Key_Buf[0],05,04,K_EXTTYPE OR K_SEGMENTED,EKT_INTEGER,0));
   { 0.1 Order No}
   INC(SegC,Set_Key(Key_Buf[1],01,04,K_EXTTYPE,EKT_INTEGER,0));
   { 1.0 Order No}
   INC(SegC,Set_Key(Key_Buf[2],01,04,K_EXTTYPE,EKT_INTEGER,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;



{======================== PRODUCT HEADER FILE ========================}
PROCEDURE TProdHeaderFIle.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOf(TProdHeaderRecord),#0);
 WITH TProdHeaderRecord(RecBuff) DO
  BEGIN
   PH_ProductCode := SPACE_STRING;
   PH_Description := SPACE_STRING;
   PH_UpdateCount := 0;
   PH_NumMethods  := 0;
  END;
END;

FUNCTION TProdHeaderFIle.GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TProdHeaderRecord);
   Page_Size := 1024;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.1 Product Code}
   INC(SegC,Set_Key(Key_Buf[0],01,11,K_EXTTYPE,EKT_LSTRING,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

PROCEDURE TProdLineFile.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOf(TProdLineRecord),#0);
 WITH TProdLineRecord(RecBuff) DO
  BEGIN
   PL_ProductCode := SPACE_STRING;
   PL_LineNo      := 0;
   PL_RecipeNo    := SPACE_STRING;
   PL_Ratio       := 0.0;
   PL_SubProduct  := SPACE_STRING;
  END;
END;

FUNCTION TProdLineFile.GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TProdLineRecord);
   Page_Size := 1024;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.1 Product Code}
   INC(SegC,Set_Key(Key_Buf[0],01,11,K_EXTTYPE OR K_MODIFIABLE OR K_SEGMENTED,EKT_LSTRING,0));
   { 0.2 Line No}
   INC(SegC,Set_Key(Key_Buf[1],12,02,K_EXTTYPE OR K_MODIFIABLE,EKT_INTEGER,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

FUNCTION TProdLineFile.DelLinesForProd(ProductCode : TProductRef) : INTEGER;
VAR LineBuff : PProdLineRecord;
BEGIN
 BtrvErr := -1;
 LineBuff := NIL;
 NEW(LineBuff);
 IF Assigned(LineBuff) THEN
  BEGIN
   LineBuff^.PL_ProductCode := ProductCode;
   LineBuff^.PL_LineNo  :=0;
   BtrvErr := 0;
   WHILE (BtrvErr = 0) DO
    BEGIN
     IF (ReadRecord('GE',TRUE,FALSE,LineBuff^,0) = 0) THEN
      BEGIN
       IF (LineBuff^.PL_ProductCode <> ProductCode) THEN Break;
       DeleteRecord;
      END;
    END;
   Dispose(LineBuff);
  END;
 IF ((BtrvErr =4) OR (BtrvErr =9)) THEN DelLinesForProd := 0
 ELSE DelLinesForProd := BtrvErr;
END;


PROCEDURE TProdDescFile.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOf(TProdDescription),#0);
 WITH TProdDescription(RecBuff) DO
  BEGIN
   PD_ProductCode := SPACE_STRING;
   PD_Method      := 0;
   PD_LineNo      := 0;
   PD_Description := SPACE_STRING;
  END;
END;

FUNCTION TProdDescFile.GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TProdDescription);
   Page_Size := 1024;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.1 Product Code}
   INC(SegC,Set_Key(Key_Buf[0],01,11,K_EXTTYPE OR K_SEGMENTED,EKT_LSTRING,0));
   { 0.2 Method No}
   INC(SegC,Set_Key(Key_Buf[1],14,02,K_EXTTYPE OR K_SEGMENTED,EKT_INTEGER,0));
   { 0.3 Line No}
   INC(SegC,Set_Key(Key_Buf[2],12,02,K_EXTTYPE,EKT_INTEGER,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

FUNCTION TProdDescFile.DeleteDescriptions(ProductCode : TProductRef) : INTEGER;
VAR LineBuff : PProdDescription;
BEGIN
 BtrvErr := -1;
 LineBuff := NIL;
 NEW(LineBuff);
 IF Assigned(LineBuff) THEN
  BEGIN
   LineBuff^.PD_ProductCode := ProductCode;
   LineBuff^.PD_Method    := 0;
   LineBuff^.PD_LineNo    := 0;
   BtrvErr := 0;
   WHILE (BtrvErr = 0) DO
    BEGIN
     IF (ReadRecord('GE',TRUE,FALSE,LineBuff^,0) = 0) THEN
      BEGIN
       IF (LineBuff^.PD_ProductCode <> ProductCode) THEN Break;
       DeleteRecord;
      END;
    END;
   Dispose(LineBuff);
  END;
 IF ((BtrvErr =4) OR (BtrvErr =9)) THEN DeleteDescriptions := 0
 ELSE DeleteDescriptions := BtrvErr;
END;


FUNCTION GetInstructionName(Product : TProductRef;MethodNo : INTEGER):STRING;
VAR DescRec : TProdDescription;
BEGIN
 DescRec.PD_ProductCode := Product;
 DescRec.PD_Method      := MethodNo;
 DescRec.PD_LineNo      := 0;
 IF ProdDescFile^.ReadRecord('EQ',FALSE,FALSE,DescRec,0) = 0 THEN
  GetInstructionName := DescRec.PD_Description
 ELSE
  GetInstructionName := COPY(SPACE_STRING,1,40);
END;


FUNCTION CheckForCircularProductRef(VAR ProdCode : TProductRef) : BOOLEAN;
{1  Read Through ProdLineFile For All Occurances Of ProdCodes Lines}
{2  If Line Points To A Product Then Create A branch For That Product}
{3  Check The Product In Each Branch To See if It Contains Products}
{4  If Product Found Goto 2 ELSE Goto 5}
{5  Scan Though Product Tree To Find Recurances of Product}
{NOTES Circular Reference Is Only To Parent Product}

{EXAMPLE Circular Reference/Non Circular Reference

                                       Prod 1
                                         |
             ------------------------------------------------------------
             |                                 |                        |
           Prod 2                            Prod 3                   Prod 4
             |                                 |                        |
     -------------------              ------------------              Prod 5
     |                 |              |                |
    Prod 1          Prod 3         Prod 2           Prod 4


    Prod 2 Branch 1 Is Prod 1 Which Has Circular Reference As Prod 1 Is
    Parent To All.
    Prod 2 Branch 2 Is Prod 3 And Prod 3 Branch 1 Is Prod 2 So Circular
    Reference.
    Prod 3 Branch 2 Is Prod 4 But Prod 4 Although It Would Be Incuded Twice
    Does Not cause circular reference.

}

TYPE PProdTree = ^TProdTree;
     TProdTree = PACKED RECORD
      Product    : TProductRef;
      ParentProd : PProdTree;        {IF NIL THEN Header Of List}
      ChildProd  : PProdTree;        {First Child In List .IF NIL Then Leaf}
      Next       : PProdTree;        {Next Item In Linked List Of Children Of Parent}
     END;

VAR ListHeader : PProdTree;
    HeaderRec  : TProdHeaderRecord;
    ProdLine   : TProdLineRecord;
    CurrentLeaf: PProdTree;
    CircularReferenceExists : BOOLEAN;

FUNCTION ReadProdHeaderRecord(VAR ProdNo : TProductRef) : BOOLEAN;
BEGIN
 HeaderRec.PH_ProductCode := ProdNo;
 ReadProdHeaderRecord := ProdHeaderFile^.ReadRecord('EQ',FALSE,FALSE,HeaderRec,0)=0;
END;

PROCEDURE DisposeOfBranch(VAR BranchHeader : PProdTree);
VAR BranchLoop,DelRec : PProdTree;
BEGIN
 BranchLoop := BranchHeader;
 WHILE (BranchLoop <> NIL) DO
  BEGIN
   IF (BranchLoop^.ChildProd <> NIL) THEN
    BEGIN
     DisposeOfBranch(BranchLoop^.ChildProd);
    END;
   DelRec := BranchLoop;
   BranchLoop := BranchLoop^.Next;
   Dispose(DelRec);
  END;
 BranchHeader := NIL;
END;

PROCEDURE AddToTree(Header : PProdTree;VAR ProductCode : TPRoductRef);
VAR NewRec : PProdTree;

 PROCEDURE CreateNewBlankRecord(VAR NewRecord : PProdTree);
 BEGIN
  New(NewRecord);
  WITH NewRecord^ DO
   BEGIN
    Product    := ProductCode;
    ParentProd := Header;
    ChildProd  := NIL;
    Next       := NIL;
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
   NewRec^.Next      := Header^.ChildProd;
   Header^.ChildProd := NewRec;
  END;
END;

PROCEDURE ReadAndAddProdLinesToTree(Header : PProdTree);

BEGIN
 FillChar(ProdLine,SizeOf(TProdLineRecord),#0);
 ProdLine.PL_ProductCode := Header^.Product;
 ProdLineFile^.ReadRecord('GE',FALSE,FALSE,ProdLine,0);
 WHILE (ProdLineFile^.BtrvErr = 0) AND (ProdLine.PL_ProductCode = Header^.Product) DO
  BEGIN
   IF NOT NowtButSpace(ProdLine.PL_SubProduct) THEN
    AddToTree(Header,ProdLine.PL_SubProduct);
   ProdLineFile^.ReadRecord('GN',FALSE,FALSE,ProdLine,0);
  END;
END;

FUNCTION CheckForCircularRef(From : PProdTree) : BOOLEAN;
Var Parent : PProdTree;
BEGIN
 Parent := From^.ParentProd;
 WHILE (Parent <> NIL) AND (NOT CircularReferenceExists) DO
  BEGIN
   IF Parent^.Product = From^.Product THEN
    CircularReferenceExists := TRUE;
   Parent := Parent^.ParentProd;
  END;
 CheckForCircularRef := CircularReferenceExists;
END;

BEGIN
 FillChar(HeaderRec,SizeOf(TProdHeaderRecord),#0);
 FillChar(ProdLine,SizeOf(TProdLineRecord),#0);
 ListHeader := NIL;
 CircularReferenceExists := FALSE;
 IF (ProdHeaderFile^.OpenFile + ProdLineFile^.OpenFile = 0) THEN
  BEGIN
   IF ReadProdHeaderRecord(ProdCode) THEN
    BEGIN
     AddToTree(NIL,ProdCode);            {Create Start Of Tree}
     CurrentLeaf := ListHeader;
     WHILE (CurrentLeaf <> NIL) DO
      BEGIN
       ReadAndAddProdLinesToTree(CurrentLeaf);
       IF CurrentLeaf^.ChildProd <> NIL THEN
        BEGIN
         CurrentLeaf := CurrentLeaf^.ChildProd;  {If There Is A Child Goto It}
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
         IF CurrentLeaf^.ParentProd <> NIL THEN
          CurrentLeaf := CurrentLeaf^.ParentProd^.Next
         ELSE
          CurrentLeaf := NIL;
        END;
       IF CurrentLeaf <> NIL THEN
        BEGIN
         ReadProdHeaderRecord(CurrentLeaf^.Product);
        END;
      END;
    END;
  END;
 IF ProdHeaderFile^.OpenErr = 0 THEN ProdHeaderFile^.CloseFile;
 IF ProdLineFile^.OpenErr   = 0 THEN ProdLineFile^.CloseFile;
 DisposeOfBranch(ListHeader);
 CheckForCircularProductRef := CircularReferenceExists;
END;

END.

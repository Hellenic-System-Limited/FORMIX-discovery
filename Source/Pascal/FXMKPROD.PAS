(****************************************************************************
*  UNIT          : FXMkProd                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 12/05/96                                                 *
*  PURPOSE       : FORMIX Product Production Routines                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXMkProd;
INTERFACE
USES F6StdCtv,FXModCtv,FXMenu,F6DtConv,F6StdUtl,F6StdUt1,F6StdWin,F6StdWn1,
     FXFTrn,F6StdRep,FXCfg,FXFIngr,FXBrw_IN,FXHelp,FXFWork,FXFProd,FXBRW_PR,
     F6RepSee,FXFOrder,FXBRW_PD,FXFRcp,F6StdFil,F6StdChr,FxBRW_RP,FXFSerNo;

PROCEDURE CreateProduct;

IMPLEMENTATION

USES CRT;
TYPE
     PProdDescItem = ^TProdDescItem;
     TProdDescItem = PACKED RECORD
      Description : String[40];
      LineNo      : INTEGER;
      Next        : PProdDescItem;
     END;


FUNCTION BuildCookingDescList(VAR Product : TProductRef;MethodNo : INTEGER) : PProdDescItem;
VAR Last,NewItem : PProdDescItem;
    ReadErr      : INTEGER;
    DescRec      : TProdDescription;
    ListHeader   : PProdDescItem;

   PROCEDURE CopyValues(VAR pDest : PProdDescItem);
    BEGIN
     WITH pDest^ DO
      BEGIN
       Description := DescRec.PD_Description;
       LineNo      := DescRec.PD_LineNo;
       Next        := NIL;
      END;
    END;

BEGIN
 ProdDescFile^.OpenFile;
 ListHeader := NIL;
 DescRec.PD_ProductCode := Product;
 DescRec.PD_Method      := MethodNo;
 DescRec.PD_LineNo      := 0;
 ReadErr := ProdDescFile^.ReadRecord('GE',FALSE,FALSE,DescRec,0);
 WHILE (ReadErr = 0) AND (DescRec.PD_ProductCode = Product) DO
  BEGIN
   IF ListHeader = NIL THEN
    BEGIN
     New(ListHeader);
     CopyValues(ListHeader);
     Last := ListHeader;
    END
   ELSE
    BEGIN
     New(NewItem);
     CopyValues(NewItem);
     Last^.Next := NewItem;
     Last := NewItem;
    END;
   ReadErr := ProdDescFile^.ReadRecord('GN',FALSE,FALSE,DescRec,0);
  END;
 BuildCookingDescList := ListHeader;
 ProdDescFile^.CloseFile;
END;

PROCEDURE DisposeList(ListHeader : PProdDescItem);
VAR Loop,DelRec : PProdDescItem;
BEGIN
 Loop := ListHeader;
 WHILE (Loop <> NIL) DO
  BEGIN
   DelRec := Loop;
   Loop := Loop^.Next;
   Dispose(DelRec);
  END;
END;

PROCEDURE CreateProduct;
VAR ListHeader     : PProdDescItem;
    ProductNo      : TProductRef;
    RecipeNo       : TRecipeRef;
    ProdDescBrowse : PProdDescBrowse;
    MethodNo       : INTEGER;
    TheOrderNumber : LONGINT;
    RevisionNo     : BYTE;
    ProductWt      : DOUBLE;
    ProgressWin    : WindowRecord;
    ProdOrder      : TProdOrderRecord;
    PHRec          : TProdHeaderRecord;
    ProductCases   : LONGINT;
    RecipeRec      : TRecipeHeaderRecord;
    RepName        : STRING[12];
    CircularError  : BOOLEAN;
    OUT_FILE       : TEXT;

 FUNCTION OpenFiles : BOOLEAN;
 VAR Err : INTEGER;
 BEGIN
  Err := 0;
  INC(Err,RecipeHeaderFile^.OpenFile);
  INC(Err,RecipeLineFile^.OpenFile);
  INC(Err,WorkHeaderFile^.OpenFile);
  INC(Err,WorkLineFile^.OpenFile);
  INC(Err,ProdDescFile^.OpenFile);
  INC(Err,ProdLineFile^.OpenFile);
  INC(Err,ProdOrderFile^.OpenFile);
  INC(Err,ProdHeaderFile^.OpenFile);
  New(WorkOrderFile,Init(Config_Rec^.Conf_FPath+WOHeader_File_Name,
                  Config_Rec^.Conf_FPath+WOLine_File_Name));
  Inc(Err,WorkOrderFile^.OpenFile);
  OpenFiles := Err = 0;
 END;

 PROCEDURE CloseFiles;
 BEGIN
  Dispose(WorkOrderFile,Done);
  WorkOrderFile := NIL;
  ProdHeaderFile^.CloseFile;
  ProdOrderFile^.CloseFile;
  ProdLineFile^.CloseFile;
  ProdDescFile^.CloseFile;
  WorkLineFile^.CloseFile;
  WorkHeaderFile^.CloseFile;
  RecipeLineFile^.CloseFile;
  RecipeHeaderFile^.CloseFile;
 END;


(*
 FUNCTION AlreadyAProdOrder(OrderNum : LONGINT):BOOLEAN;
 VAR ProdRec : TProdOrderRecord;
 BEGIN
  ProdRec.PO_OrderNo := OrderNum;
  AlreadyAProdOrder  := ProdOrderFile^.ReadRecord('EQ',FALSE,FALSE,ProdRec,1) =0;
 END;
*)
(*
 {Finds First Order Number Not Being Used}
 FUNCTION SearchForAnOrderNumber : LONGINT;
 VAR ReadErr   : INTEGER;
     NextAvail : LONGINT;
     WHRec     : TWOHeaderRecord;
 BEGIN
  ReadErr   := 0;
  WHRec.WOH_OrderNo  := 1;
  WHRec.WOH_Revision := 0;
  ReadErr := WorkHeaderFile^.ReadRecord('GE',FALSE,FALSE,WHRec,1);
  NextAvail := 1;
  WHILE (ReadErr=0) AND (WHRec.WOH_OrderNo <= 999999) DO
   BEGIN
    IF (WHRec.WOH_OrderNo > NextAvail+1) AND
     NOT AlreadyAProdOrder(NextAvail+1) THEN BREAK;
    NextAvail := WHRec.WOH_OrderNo;
    ReadErr   := WorkHeaderFile^.ReadRecord('GN',FALSE,FALSE,WHRec,1);
   END;
  IF WHRec.WOH_OrderNo > 999999 THEN
   SearchForAnOrderNumber := -1
  ELSE
   BEGIN
    IF ReadErr <> 0 THEN
     BEGIN
      WHILE (AlreadyAProdOrder(NextAvail+1)) DO INC(NextAvail);
     END;
    IF NextAvail >999999 THEN
     SearchForAnOrderNumber := -1
    ELSE
     SearchForAnOrderNumber := NextAvail+1;
   END;
 END;
*)
(*
 PROCEDURE GetOrderNumber;
 VAR WHRec : TWOHeaderRecord;
 BEGIN
  WHRec.WOH_OrderNo := 99999999;
  WorkHeaderFile^.ReadRecord('LE',FALSE,FALSE,WHRec,1);
  IF (WorkHeaderFile^.BtrvErr = BNoRecord) OR (WorkHeaderFile^.BtrvErr = BEndOfFile) THEN
   TheOrderNumber := 1
  ELSE
   TheOrderNumber := (WHREc.WOH_OrderNo MOD 1000000 +1);
  IF AlreadyAProdOrder(TheOrderNumber) OR (TheOrderNumber > 999999) THEN
   TheOrderNumber := SearchForAnOrderNumber;
 END;
*)

 PROCEDURE GetCookingMethod;

  FUNCTION ProductHasDescriptions : BOOLEAN;
  VAR DescRec : TProdDescription;
      ErrInt  : INTEGER;
  BEGIN
   FillChar(DescRec,Sizeof(DescRec),0);
   DescRec.PD_ProductCode := ProductNo;
   ProdDescFile^.OpenFile;
   ErrInt := ProdDescFile^.ReadRecord('GE',FALSE,FALSE,DescRec,0);
   ProdDescFile^.CloseFile;
   ProductHasDescriptions := (ErrInt = 0) AND
                             (DescRec.PD_ProductCode = ProductNo);
  END;

 BEGIN
  FillChar(PHRec,SizeOf(TProdHeaderRecord),#0);
  PHRec.PH_ProductCode := ProductNo;
  ProdHeaderFile^.ReadRecord('EQ',FALSE,FALSE,PHRec,0);
  IF (PHRec.PH_NumMethods > 0) AND (ProductHasDescriptions) THEN
   BEGIN
    New(ProdDescBrowse,Init(@PHRec,FALSE));
    ProdDescBrowse^.Run;
    MethodNo := ProdDescBrowse^.MethodNo;
    Dispose(ProdDescBrowse,Done);
   END
  ELSE MethodNo := 0;
 END;

 FUNCTION GetProdRecipeLine(    ProductCode : TProductRef;
                            VAR ReadMethod  : STRING;
                            VAR ProdLine    : TProdLineRecord) : BOOLEAN;
 VAR ReadErr : INTEGER;
 BEGIN
  ProdLine.PL_ProductCode := ProductCode;
  ReadErr                 := ProdLineFile^.ReadRecord(ReadMethod,FALSE,FALSE,ProdLine,0);
  ReadMethod              := 'GN';
  GetProdRecipeLine       := (ReadErr = 0) AND (ProdLine.PL_ProductCode = ProductCode);
 END;

 FUNCTION GetProductRequirement : BOOLEAN;
 VAR EditWin  : WIndowRecord;
     sNumCont : STRING[6];
     Dummy    : INTEGER;
     GetWeight: BOOLEAN;
     EditPos  : INTEGER;
 BEGIN
  BackColourScheme;
  SetWindow(21,6,57,13,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,EditWin);
  Header('Enter Product Details',1);
  Footer('F2 - Accept   ESC - Abort',1);
  WriteAt(2,3,' '+Config_Rec^.CONF_UnitName+' : ');
  ForeColourScheme;
  sNumCont := IntToZeroStr(0,6);
  EditPos := 0;
  REPEAT
   WriteField(13,3,sNumCont,TRUE);
   CASE EditPos OF
    0 : GetLine_Num(sNumCont,6,13,3,0);
   END;
   VAL(sNumCont,ProductCases,Dummy);
   GetWeight := (ch1 = FN_F2) AND (ProductCases <> 0);
  UNTIL (GetWeight) OR (ch1 = ESC);
  ProductWt := PHRec.PH_CaseSize * ProductCases;
  LoseWindow(EditWin);
  GetProductRequirement := GetWeight;
 END;

 PROCEDURE PrintMsg(Msg : STRING);
 BEGIN
  WriteLn(OUT_FILE,Msg);
  WriteLn(Msg);
 END;


 PROCEDURE ConvertRecipeToOrder(RecipeCode : TRecipeRef;
                                WtWhenReadyAsAnIngredient           : DOUBLE;
                                StdRecipeCasesInsteadOfWt : LONGINT);
 {REQUIRES StdRecipeCasesInsteadOfWt to be 0 if WtWhenReadyAsAnIngredient is to be
           used.
 }
 VAR I : INTEGER;
     OrderRec       : PWOrderObject;

       {Fields On the Order Record Not On A Recipe}
        PROCEDURE SetHeaderNonRecipeFields;
        VAR
           RecipeHeader   : TRecipeHeaderRecord;
        BEGIN
         WITH OrderRec^.WO_Header DO
          BEGIN
           WOH_OrderNo      := TheOrderNumber;
           WOH_Revision     := RevisionNo;
           WOH_SchDate      := ProdOrder.PO_Date;
           WOH_Status       := StatusWIP;
           IF StdRecipeCasesInsteadOfWt > 0 THEN
            BEGIN
             WOH_NumCases     := StdRecipeCasesInsteadOfWt;
             WOH_SelectByCase := TRUE; { finishwt gets reset on file update }
            END
           ELSE
            BEGIN
             RecipeHeaderFile^.ReadRecipeHeader(RecipeHeader, RecipeCode);
             WOH_FinishWtReqd := DivDouble(
                             WtWhenReadyAsAnIngredient*100,
                             (100-RecipeHeader.RH_ProcLossAfterMixing));
            END;
          END;
        END;

        PROCEDURE SetLineNonRecipeFields(I : INTEGER);
        BEGIN
         WITH OrderRec^.WO_Lines[I]^ DO
          BEGIN
           WOL_OrderNo    := OrderRec^.WO_Header.WOH_OrderNo;
           WOL_Revision   := OrderRec^.WO_Header.WOH_Revision;
          END;
        END;

 BEGIN
(* this doesnt happen - recipe lines always refer to ingredients
  IF (CheckForCircularRecipeRef(RecipeCode)) THEN
   BEGIN
    PrintMsg('Circular Reference For Recipe '+RecipeCode+' Recipe Not Added');
    CircularError := TRUE;
    EXIT;
   END;
*)
  NEW(OrderRec,Init);
  RecipeToOrder(OrderRec^.WO_Header,OrderRec^.WO_Lines,RecipeCode);
  SetHeaderNonRecipeFields;

(* this doesnt happen - order lines always refer to ingredients

  {Now Check To See If Any Ingredients On Recipe Are Recipes Themselves}
  {And If So Add That Recipe To The List}
  FOR I := 1 TO MAX_LINES_ON_RECORD DO
   BEGIN
    IF Assigned(OrderRec^.WO_Lines[I]) THEN
     BEGIN
      WITH OrderRec^.WO_Lines[I]^,RecipeRec,OrderRec^.WO_Header DO
       BEGIN
        RecipeRec.RH_RecipeNo    := WOL_Ingredient;
        IF (RecipeHeaderFile^.ReadRecord('GE',FALSE,FALSE,RecipeRec,0) = 0) THEN
         BEGIN
          IF (RH_RecipeNo = WOL_Ingredient) THEN
           ConvertRecipeToOrder(WOL_Ingredient,
                 (Round(WOL_Ratio*WOH_FinishWtReqd*10*(1+RH_MixLoss/100)))/1000,0);
         END;
       END;
     END;
   END;
*)
  PrintMsg('Generating Order Number '+OrderNoToStr(TheOrderNumber,RevisionNo)+'.');
  PrintMsg('Converting From Recipe '+RecipeCode+'.');
  FOR I := 1 TO MAX_LINES_ON_RECORD DO
   BEGIN
    IF Assigned(OrderRec^.WO_Lines[I]) THEN SetLineNonRecipeFields(I);
   END;
  INC(RevisionNo);
  INC(ProdOrder.PO_NumOrders);
  WorkOrderFile^.AddRecord(OrderRec);
  Dispose(OrderRec,Done);             {Dispose Order Composite Record}
 END;


 PROCEDURE ConvertProductsRecipesToOrder(ProductCode : TProductRef;ProductWeight : DOUBLE);
 VAR ReadMethod      : STRING[2];
     ProdLineFilePos : LONGINT;
     ProdLine        : TProdLineRecord;
 BEGIN
{Need To Set OrderRec^.WO_Header.WOH_TargetWt THEN CALL}
{RecipeToOrder(OrderRec^.WO_Header,OrderRec^.WO_Lines,ProdLine.PL_RecipeNo);}
{FOR EACH RECIPE ON THE PRODUCT. IF ProdLine Points To A Sub Product Then
Convert That Products Recipes}
  FillChar(ProdLine,SizeOf(TProdLineRecord),#0);
  ReadMethod := 'GE';
  WHILE (GetProdRecipeLine(ProductCode,ReadMethod,ProdLine)) DO
   BEGIN
    IF NowtButSpace(ProdLine.PL_RecipeNo) THEN
     BEGIN
      ProdLineFilePos := ProdLineFile^.Position;
      ConvertProductsRecipesToOrder(ProdLine.PL_SubProduct,(ROUND(ProdLine.PL_Ratio*ProductWeight*10))/1000);
      ProdLineFile^.GetRecordDirect(ProdLineFilePos,FALSE,FALSE,ProdLine,0);
     END
    ELSE
     BEGIN
      IF Config_Rec^.CONF_OneRecipeCasePerProdCase THEN
        ConvertRecipeToOrder(ProdLine.PL_RecipeNo,0.0,ProductCases)
      ELSE
        ConvertRecipeToOrder(
                    ProdLine.PL_RecipeNo,
                    RoundWtToNearestGram(
                          DivDouble(ProductWeight*ProdLine.PL_Ratio,100)),
                    0);
     END;
   END;
 END;

 {Needs To Create An Order For Each Of its Recipes}
 {Read Last Order Record To Get Order Number}
BEGIN
 IF NOT OpenFiles THEN
  BEGIN
   CloseFiles;
   EXIT;
  END;
 ProdOrderFile^.InitRecord(ProdOrder);
 ProductNo := SPACE_STRING;
 BrowseProduct(ProductNo);
 IF NowtButSpace(ProductNo) THEN
  BEGIN
   CloseFiles;
   EXIT;
  END;
 IF CheckForCircularProductRef(ProductNo) THEN
  BEGIN
   Disp_Error_Msg('A Circular Product Reference Exists For This Product');
   CloseFiles;
   EXIT;
  END;
 GetCookingMethod;
 IF MethodNo = -1 THEN
  BEGIN
   CloseFiles;
   EXIT;
  END;
 IF (NOT GetProductRequirement) THEN
  BEGIN
   CloseFiles;
   EXIT;
  END;
 RevisionNo := 0;

 IF (MethodNo <> -1) THEN
  BEGIN
   {Build Linked List Of Cooking Instructions}
   ListHeader := BuildCookingDescList(ProductNo,MethodNo);
   TheOrderNumber := WorkHeaderFile^.NextAvailableOrdNo;
   WITH ProdOrder DO
    BEGIN
     PO_ProductCode := ProductNo;
     PO_Date        := Date_To_Days(Date);
     PO_OrderNo     := TheOrderNumber;
     PO_Method      := MethodNo;
     PO_TotalWt     := ProductWt;
     PO_Containers  := ProductCases;
    END;


   IF TheOrderNumber > 0 THEN
    BEGIN
     CircularError := FALSE;
     RepName := CreateAFileName('RPT');
     Assign(OUT_FILE,PROP_RamFilePath+RepName);
{$I-}
     Append(OUT_FILE);
{$I+}
     BackColourScheme;
     SetWindow(10,05,66,20,TRUE,SW_DEFAULT,SW_DEFAULT,ProgressWin);
     Header('Generating Orders',1);
     Footer('',1);
     ForeColourScheme;
     WITH ProgressWin DO
      CRT.Window(cur_x1,cur_y1+1,cur_x2,cur_y2-1);

     ConvertProductsRecipesToOrder(ProductNo,ProductWt);

     ProdOrderFile^.AddRecord(ProdOrder);
     PrintMsg('');
     PrintMsg('Creation Complete.');
     PrintMsg('Orders Generated Have Prefix '+IntToZeroStr(TheOrderNumber,6)+'.');

     Write(OUT_FILE,CRLF,CEndPage);
     Close(OUT_FILE);
     IF CircularError THEN
      Show_Report(RepName,0,TRUE,FALSE,FALSE)
     ELSE
      BEGIN
       KillReportFile(RepName);
       WriteLn('Press Any Key To Continue.');
       GetKey;
      END;
     LoseWindow(ProgressWin);
    END;
   DisposeList(ListHeader);
  END;
 CloseFiles;
END;


END.

(****************************************************************************
*  UNIT          : FXFFOPS                                                  *
*  AUTHOR        : S. W                                                     *
*  DATE          : 06/12/01                                                 *
*  PURPOSE       : FORMIX FOPS6 FILE ACCESS                                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}

{$IFnDEF TERMINAL} not used {$ENDIF}

UNIT FXFFOPS;
INTERFACE
USES FxModCTV,FILEOBJ,F6STDCTV,F6StdUtl,F6DtConv,FXCFG,F6StdWn1,FXFUsers;


CONST  F6TRAN_FileName   = 'TRANS.FIL';
       F6GRPPLU_FileName = 'GRPPLU.FIL';


       { Function Return Codes }
       F6BCERR_INCORRECTLEN = 1;
       F6BCERR_OUTOFDATE    = 2;
       F6BCERR_WRONGPRODUCT = 3;
       F6BCERR_TRANNOTFOUND = 4;

TYPE TranStatus = (TRN_Active, { Outer case on site. }
                   TRN_Desp,   { Outer case off site. }
                   TRN_Intake, { Provisional outer case. }
                   TRN_Inner); { Inner - see notes }


     TRN_Record = PACKED RECORD
{*3.1,4.0,5.0} TRN_Status : TranStatus;          {   1 Transaction Status   }
{*0.0,5.1}     TRN_mi     : CHAR;                {   2 Machine ID 1,2,Ect   }
{*0.1}         TRN_rn     : LONGINT;             {   3 Serial no            }
{*3.2,5.2}     TRN_prod   : Prod_Type;           {   7 PLU number           }
{*1.0,3.0}     TRN_Site   : Site_Type;           {  16 Transaction Site     }
               TRN_Fo     : LONGINT;             {  25 Fact Order No        }
               TRN_pal    : LONGINT;             {  29 Pallet number        }
{*5.3}         TRN_wt     : Double;              {  33 Weight               }
{*1.2}         TRN_ti     : Time_Type;           {  41 Time                 }
{*1.1}         TRN_dt     : LONGINT;             {  47 Date                 }
               TRN_Pdt    : LONGINT;             {  51 Date                 }
               TRN_usr    : STRING[4];           {  55 User index           }
               TRN_OutBat : LONGINT;             {  60 Output Batch Number  }
               TRN_FODGrp : Prod_Type;           {  64 Factory  Group       }
               TRN_DODGrp : Prod_Type;           {  73 Despatch Group OR    }
                                                 {     Grade For Intake     }
               TRN_Gross  : Double;              {  82 Gross wt             }
{*5.5}         TRN_InpBat : LONGINT;             {  90 Input Batch Number   }
               TRN_DelCode: BYTE;                {  94 Bit 7 = Rework Flag
                                                       + Delete code char.  }
{*4.1,5.6}     TRN_Do     : LONGINT;             {  95 Desp Order No.       }
               TRN_awt    : Double;              {  99 Actual Trn Wgt       }
               TRN_Ran    : CHAR;                { 107 Weight Range         }
{*2.1}         TRN_DTime  : Time_Type;       { 108 Despatch/Delete Time/... }
              { IF Active: overwritten with $0 + Last modified (JulMin_Type)}
{*2.0,4.2}     TRN_DDate  : LONGINT;             { 114 Despatch/Delete Date }
               TRN_PO     : LONGINT;             { 118 Purchase Order Number}
               TRN_PODGrp : Prod_Type;           { 122 Purchase Group       }
{*3.3}         TRN_MinLife: LONGINT;             { 131 Min Durability Date  }
               TRN_MaxLife: LONGINT;             { 135 Max Durability Date  }
{*5.4}         TRN_BarDate: LONGINT;             { 139 Ext. Int. Bar Date   }
               TRN_Items  : LONGINT;             { 143 Count For Wgt.ing    }
               TRN_CostVal: DOUBLE;              { 147 Cost Value (Intake)  }
               TRN_Area   : BYTE;                { 155 Stock Area           }
               TRN_Rack   : CHAR;                { 156 Stock Rack           }
               TRN_Loc    : BYTE;                { 157 Stock Location       }
               TRN_NoSrcBarcode : BOOLEAN;       { 158 definitely no related}
               TRN_LoadNo : STRING[2];           { 159 Despatch Load No.    }
       { NOTE: Some people might have records only 162 bytes long }
               TRN_OutBatDate : LONGINT;         { 162 Output batch date }
              END;


     GRPPLU_Record = PACKED RECORD
{*0}{*2.0}GRP_No      : Prod_Type;
{*1}{*2.1}GRP_Product : Prod_Type;
     END;




    PF6TranFile = ^TF6TranFile;
    TF6TranFile = Object(TAdoptedBtrvFileObject)
      TRec : TRN_Record;
      FUNCTION StringToMID (MidStr : STRING) : CHAR;
      FUNCTION FindTran(Mid : CHAR;Rn : LONGINT) : INTEGER;
    END;

    PF6GrpPluFile = ^TF6GrpPluFile;
    TF6GrpPluFile = Object(TAdoptedBtrvFileObject)
      GPRec : GRPPLU_Record;
      FUNCTION FindGrpPlu(GrpCode,ProdCode : Prod_Type) : INTEGER;
    END;

    PF6ProdFile = ^TF6ProdFile;
    TF6ProdFile = Object(TAdoptedBtrvFileObject)
    END;

FUNCTION GetFops6PluNumberForIngredient(IngredientCode : TIngredientRef) : INTEGER;

FUNCTION VerifyFopsBarcode(VAR BarcodeStr  : STRING;
                           IngredientCode  : STRING;
                           VAR CurrStockWtInKg : DOUBLE;
                           VAR OrigStockWtInKg : DOUBLE;
                           VAR LifeDate    : LONGINT) : INTEGER;


IMPLEMENTATION
USES F6FProd;

FUNCTION TF6TranFile.StringToMID (MidStr : STRING) : CHAR;
VAR MidVal : BYTE;
BEGIN
 MidVal := BYTE(StringToLong(MidStr));

 IF MidVal < 10 THEN StringToMID := CHR(MidVal+48)
 ELSE StringToMid := CHR(MidVal+55);
END;

FUNCTION TF6TranFile.FindTran(Mid : CHAR;Rn : LONGINT) : INTEGER;
BEGIN
  TRec.TRN_Mi := Mid;
  TRec.TRN_Rn := Rn;
  IF OpenFile = 0 THEN
    ReadRecord('EQ',FALSE,FALSE,TRec,0);
  FindTran := BtrvErr;
  CloseFile;
END;

FUNCTION TF6GrpPluFile.FindGrpPlu(GrpCode,ProdCode : Prod_Type) : INTEGER;
BEGIN
  GPRec.GRP_No      := GrpCode;
  GPRec.GRP_Product := ProdCode;
  IF OpenFile = 0 THEN
    ReadRecord('EQ',FALSE,FALSE,GPRec,2);
  FindGrpPlu := BtrvErr;
  CloseFile;
END;

FUNCTION GetFops6PluNumberForIngredient(IngredientCode : TIngredientRef) : INTEGER;
VAR
  ProdRec : F6FProd.PLU_Record;
  F6ProdFile : PF6ProdFile;
BEGIN
 GetFops6PluNumberForingredient := 0;
 F6ProdFile := New(PF6ProdFile,Init(Config_Rec^.CONF_Fops6FilePath+F6FProd.Prod_file_name));
 WITH F6ProdFile^ DO
  BEGIN
   ProdRec.PLU_No := IngredientCode + Space_String;
   IF OpenFile = 0 THEN
    BEGIN
     ReadRecord('EQ',FALSE,FALSE,ProdRec,0);
     IF BtrvErr = 0 THEN
       GetFops6PluNumberForingredient := ProdRec.PLU_plu;
    END
   ELSE
     Disp_Error_Msg('Warning: Failed to open FOPS6 product file');
   CloseFile;
  END;
 Dispose(F6ProdFile, Done);
END;


(*
FUNCTION IgnoreFopsBarcodeError(ErrMsg : STRING) : BOOLEAN;
VAR
  Ignore : BOOLEAN;
BEGIN
 Ignore := TRUE;
 IF NOT NowtbutSpace(ErrMsg) THEN
  BEGIN
   Ignore := YesNoWin(Centered(ErrMsg,40)+CRLF+Centered('Continue?',40));
  END;
 IgnoreFopsBarcodeError := Ignore;
END;
*)



{******** See RecipeScanFlow.doc ***********}
{*******************************************}
FUNCTION VerifyFopsBarcode(VAR BarcodeStr  : STRING;
                           IngredientCode  : STRING;
                           VAR CurrStockWtInKg : DOUBLE;
                           VAR OrigStockWtInKg : DOUBLE;
                           VAR LifeDate    : LONGINT
                           ) : INTEGER;
{REQUIRES
 PROMISES 1. To handle errors and return error code.
}

TYPE TBarFields = PACKED RECORD
       BF_Mid : STRING[2];
       BF_Rn  : STRING[6];
       BF_Plu : STRING[4];
       BF_Wt  : STRING[6];
     END;


VAR F6TranFile   : PF6TranFile;     { File Object Instance Pointer }
    F6GrpPluFile : PF6GrpPluFile;
    BC           : TBarFields;
    BCLen        : WORD;
    Result       : INTEGER;
    TranFoundErr : INTEGER;


 PROCEDURE Parse20DigitBarcode;
  BEGIN
   BC.BF_Mid := COPY(BarcodeStr,1,2);
   BC.BF_Rn  := COPY(BarcodeStr,3,6);
   BC.BF_Plu := COPY(BarcodeStr,9,4);
   BC.BF_Wt  := COPY(BarcodeStr,13,3)+ '.'+ Copy(BarcodeStr,16,2);
  END;

BEGIN
 CurrStockWtInKg  := 0.0;
 OrigStockWtInKg  := 0.0;
 LifeDate         := 0;
 F6TranFile   := New(PF6TranFile  ,Init(Config_Rec^.CONF_Fops6FilePath+F6TRAN_FileName));
 F6GrpPluFile := NIL;

 Result := 0;
 BCLen := Length(CLIP(BarcodeStr));
 IF  (BCLen <> 20) THEN
  BEGIN
   IF (Length(Config_Rec^.CONF_IntakeMid) = 2) THEN { 6 digits are acceptable }
    BEGIN
     IF (BCLen <> 6) THEN
      BEGIN
       Result := F6BCERR_INCORRECTLEN;
{$IFDEF FOPSTRACELINK}
       Disp_Error_Msg('Source Barcode Must Be 20 or 6 digits or ''PO''+6 digit purchase no.');
{$ELSE}
       Disp_Error_Msg('Source Barcode Must Be 20 or 6 digits.');
{$ENDIF}
      END;
    END
   ELSE
    BEGIN
     Result := F6BCERR_INCORRECTLEN;
{$IFDEF FOPSTRACELINK}
     Disp_Error_Msg('Source Barcode Must Be 20  digits or ''PO''+6 digit purchase no.');
{$ELSE}
     Disp_Error_Msg('Source Barcode Must Be 20 digits.');
{$ENDIF}
    END;
  END;

 IF Result = 0 THEN
  BEGIN
   IF BCLen = 6 THEN { label serial num - convert to 20 digit }
    BEGIN
     {******* ALTER CALLERS BARCODE ********}
     BarcodeStr := Config_Rec^.CONF_IntakeMid+ Clip(BarcodeStr) +
                   '999900000000'; { a plu 9999 will have to be set up on fops }
    END;
   Parse20DigitBarcode;

   WITH F6TranFile^ DO
    BEGIN
     TranFoundErr := FindTran(StringToMid(BC.BF_Mid),StringToLong(BC.BF_Rn));
     IF TranFoundErr = 0 THEN { return current stock wt }
      BEGIN
       CurrStockWtInKg := TRec.TRN_awt;
       OrigStockWtInKg := StringToDouble(BC.BF_Wt);
       { Extract orig wt from barcode to save reading trn source file }
       IF OrigStockWtInKg < CurrStockWtInKg THEN { barcode TONNE problem? }
         OrigStockWtInKg := TRec.TRN_awt;

       IF TRec.TRN_ran = lbRange THEN { convert to kg }
        BEGIN
         CurrStockWtInKg := CurrStockWtInKg * KG_TO_LB; {const is really a divisor}
         OrigStockWtInKg := OrigStockWtInKg * KG_TO_LB; {const is really a divisor}
        END;
       LifeDate        := TRec.TRN_MaxLife;
      END
     ELSE
      BEGIN
       { TRAN NOT FOUND / FILE ERROR }
       IF F6TranFile^.BtrvErr = BNoRecord THEN
        BEGIN
         Disp_Error_Msg('FOPS6 Transaction '+
                        BC.BF_Mid+'-'+BC.BF_Rn+' Not found');
        END
       ELSE
        BEGIN
         Disp_Error_Msg('Error '+
                        IntToStr(F6TranFile^.BtrvErr,4)+
                        ' Accessing '+ Clip(F6TranFile^.FullFilePath));
        END;
       { suffolk want weight from barcode }
       OrigStockWtInKg := StringToDouble(BC.BF_Wt);
       CurrStockWtInKg := OrigStockWtInKg;
       Result := F6BCERR_TRANNOTFOUND;
      END;

     IF  (Result = 0) { trans has been found }
     AND Config_Rec^.CONF_IngredientsInFops6 THEN
      BEGIN
       { Check transaction product code either:
         matches ingredient code
         or is a member of a group whose code matches Ingredient code }
       IF NOT Str_Equal(TRec.TRN_prod, IngredientCode, SizeOf(TRec.TRN_prod)-1) THEN
        BEGIN
         F6GrpPluFile := New(PF6GrpPluFile,Init(Config_Rec^.CONF_Fops6FilePath+F6GRPPLU_FileName));
         IF F6GrpPluFile^.FindGrpPlu(IngredientCode,TRec.TRN_Prod) <> 0 THEN
          BEGIN
           { GROUP PLU NOT FOUND / FILE OPEN ERROR }
           IF F6GrpPluFile^.BtrvErr = BNoRecord THEN
            BEGIN
             Result := F6BCERR_WRONGPRODUCT;
(*           IF IgnoreFopsBarcodeError('Wrong Product: '+TRec.TRN_Prod) THEN
               Result := 0;
*)           Disp_Error_Msg('Incorrect Source Product: '+TRec.TRN_Prod);
            END
           ELSE
            BEGIN
             Disp_Error_Msg('Error '+
                            IntToStr(F6GrpPluFile^.BtrvErr,4)+
                            ' Accessing '+ Clip(F6GrpPluFile^.FullFilePath));
            END;
          END;
         Dispose(F6GrpPluFile,Done);
        END;
      END;
    END; { END (WITH) }
  END;
 Dispose(F6TranFile,Done);

{$IFNDEF FOPSTRACELINK}
 IF Result = F6BCERR_TRANNOTFOUND THEN { loop hole to allow suffolk to
                                         continue without a real barcode }
   Result := 0;
{$ENDIF}

 VerifyFopsBarcode := Result;
END;


END.

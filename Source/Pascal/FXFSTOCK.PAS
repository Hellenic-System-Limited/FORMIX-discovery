(****************************************************************************
*  UNIT          : FXFStock                                                 *
*  AUTHOR        : N. S                                                     *
*  DATE          : 09/06/97                                                 *
*  PURPOSE       : Supposed to be stock tots of mixes I think,
                   only trouble is figures only ever go up.
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFStock;
INTERFACE
USES FILEOBJ,F6STDCTV,F6Btrv,FxModCtv;
CONST  Stock_FileName   = 'FXSTOCK.FIL';



TYPE   PStockRecord = ^TStockRecord;
       TStockRecord = PACKED RECORD
         STOCK_Product    : TRecipeRef; {0.0}         {01-09}
         STOCK_InStock    : LONGINT;
         STOCK_Weight     : DOUBLE;
         STOCK_Initial    : LONGINT;
         STOCK_InitWt     : DOUBLE;
         Reserved         : ARRAY[1..40] OF BYTE;         {49-60}
       END;

{ No point putting this in DDFs so no SQL statement }

    PStockFile = ^TStockFile;
    TStockFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord(VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
    END;

PROCEDURE AddStockRecord(Recipe : TRecipeRef;Weight : DOUBLE);

VAR StockFile : PStockFile;     { File Object Instance Pointer }

IMPLEMENTATION

PROCEDURE TstockFile.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TStockRecord),#0);
 WITH TStockRecord(RecBuff) DO
  BEGIN
  END;
END;

FUNCTION TStockFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TStockRecord);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   {0.0 Ingredient}
   INC(SegC,Set_Key(Key_Buf[0],01,09,K_EXTTYPE,EKT_LSTRING,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

PROCEDURE AddStockRecord(Recipe : TRecipeRef;Weight : DOUBLE);
VAR StockRec : TStockRecord;
BEGIN
 StockFile^.InitRecord(StockRec);
 StockRec.STOCK_Product := Recipe;
 IF (StockFile^.ReadRecord('EQ',TRUE,FALSE,StockRec,0) = 0) THEN
  BEGIN
   Inc(StockRec.STOCK_InStock);
   StockRec.Stock_Weight := StockRec.Stock_Weight+Weight;
   StockFile^.UpdateRecord(StockRec);
  END
 ELSE IF (StockFile^.BtrvErr = BNoRecord) THEN
  BEGIN
   StockRec.STOCK_Product := Recipe;
   StockRec.STOCK_Weight  := Weight;
   StockRec.STOCK_InStock := 1;
   StockFile^.AddRecord(StockRec);
  END;
END;

END.

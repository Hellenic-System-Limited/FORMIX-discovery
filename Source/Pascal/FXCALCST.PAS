(****************************************************************************
*  UNIT          : FXCalCst                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 20/09/96                                                 *
*  PURPOSE       : Calculating Cost Function                                *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXCalCst;
INTERFACE
USES FXTRNQRY,FXModCtv,FXFCost,FXCfg,F6StdCtv;


FUNCTION CalcWeightDoneAndPrices(CONST ForIngredient : TIngredientRef;
                                 ForOrderLineNo   : LONGINT; { 0 = any }
                                 VAR LineWtDone   : DOUBLE;
                                 VAR LinePrice    : DOUBLE;
                                 VAR PriceUnit    : DOUBLE;
                                     TrnQueryView : PTranList) : DOUBLE;



IMPLEMENTATION

{MOD Cost File Must Be Open Before Function Is Called}
FUNCTION CalcWeightDoneAndPrices(CONST ForIngredient : TIngredientRef;
                                 ForOrderLineNo : LONGINT; { 0 = any }
                                 VAR LineWtDone : DOUBLE;
                                 VAR LinePrice  : DOUBLE;
                                 VAR PriceUnit  : DOUBLE;
                                     TrnQueryView : PTranList) : DOUBLE;
VAR QueryRec       : PTRNList;
    Cost           : TCostRecord;
    LastLotNumber  : TLotRef;
    ReadErr        : INTEGER;
{Needs To Calculate Cost Per Unit}
BEGIN
 LinePrice  := 0.0;
 LineWtDone := 0.0;
 PriceUnit  := 0.0;
 FillChar(LastLotNumber ,SizeOF(TIngredientRef),#255);
 ReadErr    := -1;

 QueryRec := TrnQueryView^.SetFirst;

 WHILE (QueryRec <> NIL) DO
  BEGIN
   IF  (QueryRec^.Ingredient = ForIngredient)
   AND ((ForOrderLineNo = 0) OR (QueryRec^.LineNo = ForOrderLineNo)) THEN
    BEGIN
     LineWtDone := LineWtDone + QueryRec^.Weight;
     IF (LastLotNumber  <> QueryRec^.LotNo) THEN
      BEGIN
       COST.COST_Ingredient := ForIngredient;
       COST.COST_LotNumber  := QueryRec^.LotNo;
       ReadErr := CostFile^.ReadRecord('EQ',FALSE,FALSE,Cost,0);
      END;

     IF (ReadErr = 0) THEN
      BEGIN
       LastLotNumber := QueryRec^.LotNo;

       IF (COST.COST_WeightIn <> 0.0) THEN
        LinePrice := LinePrice+(Round((COST.COST_Cost*QueryRec^.Weight)*1000 / COST.COST_WeightIn))/1000;

      END
     ELSE IF Config_Rec^.CONF_GlobalLot THEN
      BEGIN
       COST.COST_Ingredient := ForIngredient;
       COST.COST_LotNumber  := SPACE_STRING;
       LastLotNumber        := SPACE_STRING;
       IF CostFile^.ReadRecord('EQ',FALSE,FALSE,Cost,0) = 0 THEN
        BEGIN
         IF (COST.COST_WeightIn <> 0.0) THEN
          LinePrice := LinePrice+(Round((COST.COST_Cost*QueryRec^.Weight)*1000 / COST.COST_WeightIn))/1000;
        END
      END;
    END;
   QueryRec := TrnQueryView^.GetNext;
  END;
 IF (LineWtDone <> 0) THEN PriceUnit := LinePrice / LinewtDone;
 CalcWeightDoneAndPrices := LinePrice;
END;


END.
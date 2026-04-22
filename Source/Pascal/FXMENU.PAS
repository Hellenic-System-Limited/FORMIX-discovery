(****************************************************************************
*  UNIT          : FXMenu                                                   *
*  AUTHOR        : S. M. CWright                                            *
*  DATE          : 15/8/94                                                  *
*  PURPOSE       : FORMIX Event Constants                                   *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXMenu;

INTERFACE

{DONT IFDEF FIELDS IN THIS UNIT AS THEY ARE USED BY GREY MENU ITEM}

CONST { Menu Event Numbers }
      cm_IngredientEdit = 101;
      cm_RecipeEdit     = 102;
      cm_Lot_Ingredient = 103;
      cm_ProdEditor     = 104;
      cm_CostEdit       = 105;
      cm_UserEdit       = 106;
      cm_MacroEdit      = 107;

      cm_OrderSchedule  = 201;
      cm_TranBrowse     = 202;
      cm_CreateProduct  = 203;
      cm_ProdSchedule   = 204;

      cm_ScheduleReport = 301;
      cm_OrderReport    = 302;
      cm_IngredientList = 304;
      cm_RecipeReport   = 305;
      cm_TransactionRep = 306;
      cm_Usage          = 307;
      cm_ProductReport  = 308;
      cm_NetPack        = 309;
      cm_UserWeighing   = 310;
      cm_StockReport    = 311;
      cm_MacroReport    = 398;
      cm_SavedReport    = 399;


      cm_CookingReport  = 601;

      cm_OrderClearDown = 404;
      cm_IngredientClear= 405;

      cm_ViewErrorFile  = 501;
      cm_SendMessage    = 502;
      cm_IngredImport   = 503;
      cm_RecipeImport   = 504;

      cm_Help    = $7FFF;      {Maximum value of Integer}
      cm_ViewErr = $7777;      {Temporary}
IMPLEMENTATION
END.

(****************************************************************************
*  UNIT          : F6Event                                                  *
*  AUTHOR        : C. J. Collins AND S. M. Wright                           *
*  DATE          : 09/11/93                                                 *
*  PURPOSE       : FOPS6 MENU EVENT HANDLER                                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXEvent;

INTERFACE

USES CRT,F6STDCTV,F6STDUTL,F6STDUT1,F6DTCONV,FXPUsage,FXPWord,
     FXBRW_RP,FXBRW_LI,FXBRW_IN,FXBRW_TR,FXBRW_IC,FXBRW_MA,FXBRW_MC,FXBRW_PO,
     FXBRW_US,FXCSVIMP,

     F6LokOut,FXDelOrd,FXCfg,FXHelp,FXMenu,FXBRW_WO,FX_WOE,
     FX_PING,FX_Msg,FXPRcp,FXPSch,F6RepSee,F6GetRep,FXBRW_PR,FXMkProd,
     FXPProd,FXPNet,FXDelIng,FXPUSER,FXPStock,FXORDIMP;

PROCEDURE ExecEvent(EventID : INTEGER);

IMPLEMENTATION

PROCEDURE ExecEvent(EventID : INTEGER);
VAR RB,RF,NB,HiF,LoF : BYTE;
BEGIN
{$IFDEF MULTIPASSWORD}
 FindCalledFunction (EventID);
{$ENDIF}
{$IFDEF HELPON}
 SetHelpToFunction(EventID);
{$ENDIF}
 Save_Colours(NB,LoF,HiF,RB,RF);
 Set_Colours(Black,Cyan,Yellow,Blue,White);
 CursorOn; StopProcess := FALSE;
 CASE EventID OF
  cm_IngredientEdit : IngredientBrowse;
  cm_OrderSchedule  : WorksOrderBrowse;
  cm_Lot_Ingredient : Edit_Ingredient_Lot_Values;
  cm_ProdEditor     : ProductEdit;
  cm_UserEdit       : BrowseUserFile;
  cm_MacroEdit      : MacroHeaderBrowse;
  cm_CreateProduct  : CreateProduct;
  cm_ProdSchedule   : ProductOrderBrowse;
  cm_TranBrowse     : TransactionBrowse;
  cm_RecipeEdit     : RecipeEdit;
  cm_CostEdit       : Edit_Ingredient_Costings;
  cm_ScheduleReport : Print_Schedule_Report;
  cm_OrderReport    : Print_Order_Report;
  cm_IngredientList : Print_IngredientList;
  cm_TransactionRep : Print_Transactions;
  cm_ProductReport  : Print_Product_Report;
  cm_RecipeReport   : Print_Recipe_Details;
  cm_Usage          : Print_Ingredient_Usage;
  cm_NetPack        : Print_NetIngredientUsage_Details;
  cm_UserWeighing   : Print_User_Weighings;
  cm_StockReport    : Print_Stock_Report;
  cm_MacroReport    : Edit_RepMacro;
  cm_OrderClearDown : IF PassWord(FALSE) THEN Delete_Complete_Orders;
  cm_IngredientClear: IF PassWord(FALSE) THEN ClearDown_Ingredient_Usage;
  cm_ViewErrorFile  : ViewErrorFile(cm_ViewErrorFile);
  cm_SendMessage    : OutputMsg;
  cm_IngredImport   : ImportIngredients;
  cm_RecipeImport   : ImportRecipes;
{ cm_ChangePassword : ChangePassword;}
  cm_SavedReport    : Select_Report_File('*.RPT',Config_Rec^.Conf_RPath,
                                         SRF_Selectable OR SRF_AllowDelete,
                                         cm_SavedReport);
 END;
 CursorOff; StopProcess := FALSE;
 Set_Colours (NB,LoF,HiF,RB,RF);
 menucr := '';
{$IFDEF HELPON}
 SetHelpToFunction(HelpOff);
{$ENDIF}
{$IFDEF MULTIPASSWORD}
 EndFunctionSelect;
{$ENDIF}
END;

END.

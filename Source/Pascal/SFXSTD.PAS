(****************************************************************************
*  UNIT          : SFXStd                                                   *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       :                                                          *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXStd;
INTERFACE
USES FXModCtv,F6StdCtv;

CONST SaveStr  : STRING[13]='Save'+CRLF+'Changes';
      AbortStr : STRING[14]='Abort'+CRLF+'Changes';

TYPE PassWordStr = STRING[8];

VAR
    GlobalBatchNumber    : TBatchRef;
    GlobalLotNumber      : TLotRef;
    IngredientLotNumber  : TLotRef;
    CurrentWorkGroup     : TWorkGrp;
CONST
    NoIngredientSelected : BOOLEAN = TRUE;
    UserWantsToQuit      : BOOLEAN = FALSE;
    ShutDownSet          : BOOLEAN = FALSE;
(*    TareNotSet           : BOOLEAN;*)
(*    NoWeighingsAllowed   : BOOLEAN;*)
    UserTotalCosting     : BOOLEAN = FALSE;
    AutoAddCostRec       : BOOLEAN = FALSE;
    UserMustEnterPassWord: BOOLEAN = FALSE;
    UseSecretPassWord    : BOOLEAN = TRUE;
    KeyIngredientLineNo  : LONGINT = 0;
    RecipeDay            : LONGINT = 0;    {Day of selected recipes}
    DisplayRecListSize   : INTEGER = 0;    {Number of elements in linked list}
    DisplayRecListpos    : INTEGER = 0;    {Position of item in the left most position in list}
    AutoBatchNumbering   : BOOLEAN = FALSE;
    BatchNumbersReqd     : BOOLEAN = FALSE;
    RecallLotNumbers     : BOOLEAN = TRUE;


IMPLEMENTATION


BEGIN
 GlobalBatchNumber    := SPACE_STRING;
 GlobalLotNumber      := SPACE_STRING;
 IngredientLotNumber  := SPACE_STRING;
 CurrentWorkGroup     := '*'+SPACE_STRING;
END.




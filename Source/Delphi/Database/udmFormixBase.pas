unit udmFormixBase;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, BaseDM, HSLSecurity, DB, pvtables, btvtables, uStdUtl, RxMemDS,
  uFopsLib, uCustomHSLSecurity;

type
  TRegistrySettingNo = (
                    r_MachineID,
                    r_RunNumber,
//                    r_BatchNumber,
                    r_FXLastMixCompensation,
                    r_Scale,
                    r_Password,
                    r_CurrentWeighScale,
                    r_S1_ScaleType,
                    r_S2_ScaleType,
                    r_S1_ScaleModel,
                    r_S2_ScaleModel,
                    r_S1_ScaleSetup,
                    r_S2_ScaleSetup,
                    r_S1_IPScaleSetup,
                    r_S2_IPScaleSetup,
                    r_S1_ScaleIncrement,
                    r_S2_ScaleIncrement,
                    r_S1_FxWtRoundMod,
                    r_S2_FxWtRoundMod,
                    r_S1_ScaleMax,
                    r_S2_ScaleMax,
//                    r_EnquireForLotBatchNo,
//                    r_DisregardKeyIngredient,
//                    r_UseLotNumbers,
                    r_SFXProgramStaysOnTop,
                    r_SFXUserTimeoutSecs,
                    r_SFXModeIssue,
                    r_WorkGroupFilter,
                    r_AllowManualWeight,
                    r_PrinterSetup,
                    r_NoOfTranTickets,
                    r_NoOfMixTickets,
                    r_MixTicketsAnytime,
                    r_PrintTranTicket,
//                    r_CheckLabelTaken,
                    r_GlobalLotNumber,
                    r_GlobalBatchNumber,
                    r_FXLabFormat,
                    r_FXMixLabFormat,
                    r_FXLabFile,
                    r_PrepArea,
                    r_SFXShowMixesDoneForArea,
                    r_FXFullContainerHighTol,
                    r_SFXINGREDIENTCOSTING,
                    r_FXGlobalLot,
                    r_SFXAUTOADDCOST,
//                    r_LotNumber,
                    r_Stock,
                    r_SFXAddMixToFopsStock,
                    r_FXEqualMixes,
//                    r_SFXSendIssuesToFops6   = 'SFXSendIssuesToFops6';
                    r_SFXPromptForSource,
                    r_SFXPromptForTemperature,
                    r_SFXRecordSource,
                    r_SFXIntakeMid,
                    r_FXIngredientsInFops6,
                    r_SFXSourceOptional,
                    r_SFXCommBufferName,
                    r_FXRoundWeights,
                    r_EnquireForLotNo,
                    r_CopyFopsTranSourceAsLot,
                    r_EnquireForBatchNo,
                    r_AcceptLabelWeight,
                    r_SendFopsIssueTrans,
                    r_SFXAutoBatchFormat,
                    r_BatchPrefixForFops,
                    r_SFXAllowWtAboveSourceWt,
                    r_SFXUseOneScanOnly,
                    r_SFXAllowProductOverride,
                    r_SFXRemoteOverrides,
                    r_SFXAskForLifeDtConcessionNo,
                    r_SFXAllowSixDigitBarCode,
                    r_SFXAllowBarcodeLength,
                    r_SFXAllowKeyedBarcode,
                    r_SFXAllowPOBarcode,
                    r_SFXAllowTranNotFound,
                    r_SFXNoAutoCancelOfTares,
                    r_SFXQAAtMixStart,
                    r_SFXMixScanAtOrderSelect,
//                    r_SFXJulianBatchNumbers,
                    r_NavBarcodeLengths,
                    r_NavBarcodeFormat,
                    r_PromptForBatchOnOrderChange,
                    r_PromptForBatchOnMixChange,
                    r_OcmProgramFile,
                    r_OcmIniFile,
                    r_MaxPasswordAge
                   );

const
    { C H A N G I N G  T H I S  U N I T ?  then update the constant defining the version number. }
    {**********************************************************************}
    FormixDatabaseFolderV8 = #0;  {version number for source in formix\database folder (also used by fops8).
    {**********************************************************************}
(*
    {Registry Constants}
//    REG_System    = 'System';
    REG_MachineID = 'Machine ID';
    REG_RunNumber = 'Run Number';
//    REG_BatchNumber           = 'Batch Number';
    REG_FXLastMixCompensation = 'FXLastMixCompensation'; //Target weight of last mix is adjusted to suit ordered weight and taking into account weight of mixes currently completed.
    REG_Scale                 = 'Scale.';
    REG_Password              = 'Password';
    REG_CurrentWeighScale     = 'CurrentWeighScale';

    REG_ScaleType             = 'ScaleType';
    REG_ScaleModel            = 'ScaleModel';
    REG_ScaleSetup            = 'ScaleSetup';
    REG_IPScaleSetup          = 'IPScaleSetup';
    REG_ScaleIncrement         = 'ScaleIncrement'; //scale decimal places!
    REG_FxWtRoundMod           = 'FXWtRoundMod';//scale increment e.g. 0.005
//    REG_EnquireForLotBatchNo  = 'EnquireForLotBatchNo';
//    REG_DisregardKeyIngredient = 'DisregardKeyIngredient';
//    REG_UseLotNumbers          = 'UseLotNumbers';
    REG_SFXProgramStaysOnTop   = 'SFXProgramStaysOnTop';
    REG_SFXModeIssue           = 'SFXModeIssue';
    REG_WorkGroupFilter        = 'WorkGroupFilter';
    REG_AllowManualWeight      = 'AllowManualWeight';
    REG_PrinterSetup           = 'PrinterSetup';
    REG_NoOfTranTickets        = 'NoOfTranTickets'; // number of labels to print for ingredient weighing
    REG_NoOfMixTickets         = 'NoOfMixTickets'; // number of labels to print when prep area finishes a mix
    REG_MixTicketsAnytime      = 'MixTicketsAnytime';
    REG_PrintTranTicket        = 'PrintTranTicket'; // ingredient labels are required
//    REG_CheckLabelTaken        = 'CheckLabelTaken';
    REG_GlobalLotNumber        = 'GlobalLotNumber';
    REG_GlobalBatchNumber      = 'GlobalBatchNumber';
    REG_FXLabFormat            = 'FXLabFormat'; //ingredient label format
    REG_FXMixLabFormat         = 'FXMixLabFormat'; //mix label format
    REG_FXLabFile              = 'FXLabFile'; //label formats file to download to printer
    REG_ScaleMax               = 'ScaleMax'; //max scale weight
    REG_PrepArea               = 'PrepArea';
    REG_FXFullContainerHighTol = 'FXFullContainerHighTol'; //high tolerance on first weighings of multi container ingredient requirement
    REG_SFXINGREDIENTCOSTING   = 'SFXINGREDIENTCOSTING'; //add transaction weights to ingredient cost records
    REG_FXGlobalLot            = 'FXGlobalLot';
    REG_SFXAUTOADDCOST         = 'SFXAUTOADDCOST';// create ingredient cost record automatically if not found
//    REG_LotNumber              = 'LotNumber';
    REG_Stock                  = 'FXStock'; //add completed mix count and weight to stock file
    REG_SFXAddMixToFopsStock   = 'SFXAddMixToFopsStock';
    REG_FXEqualMixes           = 'FXEqualMixes'; //mix weights to be equal on multi-mix orders
//    REG_SFXSendIssuesToFops6   = 'SFXSendIssuesToFops6';
    REG_SFXPromptForSource     = 'SFXPromptForSource'; //ingredient weighings prompt a source barcode scan
    REG_SFXPromptForTemperature= 'SFXPromptForTemperature';//ingredient weighings prompt a temperature
    REG_SFXRecordSource        = 'SFXRecordSource'; //source barcodes are saved in SOURCE_CODES table.
    REG_SFXIntakeMid           = 'SFXIntakeMid'; //fops transaction machine number when 6 digit serial number is entered as the source barcode
    REG_FXIngredientsInFops6   = 'FXIngredientsInFops6';//validate product code of fops source barcode matches, or belongs to a group that matches, the ingredient code.
    REG_SFXSourceOptional      = 'SFXSourceOptional';// source barcode prompt can be skipped by the user
    REG_SFXCommBufferName      = 'SFXCommBufferName';//commfilename prefix of fops session processing issue commands
    REG_FXRoundWeights         = 'FXRoundWeights';//Adjust calculated tolerances to nearest scale increments
    REG_EnquireForLotNo        = 'EnquireForLotNo';
    REG_CopyFopsTranSourceAsLot= 'CopyFopsTranSourceAsLot';//lot no = fops tran src barcode or curr lot for ingredient.
    REG_EnquireForBatchNo      = 'EnquireFoBatchNo';
    REG_AcceptLabelWeight      = 'SFXAcceptLabelWeight';//accept weight of fops transaction scanned
    REG_SendFopsIssueTrans     = 'SFXSendFopsIssueTrans';//send stock issue and part-issue commands to fops
    REG_SFXAutoBatchFormat     = 'SFXAutoBatchFormat';// can be DDD000 (day number prefix) or DDDJJJ (day number and Recipe Job No).
    REG_BatchPrefixForFops     = 'BatchPrefixForFops';//two digit prefix to convert formix batch to fops batch.
    REG_SFXAllowWtAboveSourceWt = 'SFXAllowWtAboveSourceWt';//allow source FOPS transaction to have less weight than weighing.
    REG_SFXUseOneScanOnly      = 'SFXUseOneScanOnly';//source barcode scan also sets lot and batch numbers
    REG_SFXAllowProductOverride = 'SFXAllowProductOverride';//allow incorrect fops products to be used if authorized
    REG_SFXRemoteOverrides      = 'SFXRemoteOverrides';//incorrect product authorization is done remotely (web app).
    REG_SFXAllowSixDigitBarCode = 'SFXAllowSixDigitBarcode';//six digit source barcode is acceptable
    REG_SFXAllowBarcodeLength   = 'SFXAllowBarcodeLength';//eg =12 for truncated mix barcode
    REG_SFXAllowKeyedBarcode    = 'SFXAllowKeyedBarcode';// manual input using touchscreen keyboard.
    REG_SFXAllowPOBarcode       = 'SFXAllowPOBarcode';//'PO' followed by six digit number is accepted as a source barcode.
    REG_SFXAllowTranNotFound    = 'SFXAllowTranNotFound';//accept source barcodes that appeat to relate to a fops transaction, but the transaction can not be found.
    REG_SFXNoAutoCancelOfTares  = 'SFXNoAutoCancelOfTares';//stops cancel of tare when container is removed for 'No Tare' ingredient.
    REG_SFXQAAtMixStart         = 'SFXQAAtMixStart';//QA required for each mix before weighing ingredients in each prep area.
    REG_SFXMixScanAtOrderSelect = 'SFXMixScanAtOrderSelect';//
//    REG_SFXJulianBatchNumbers   = 'SFXJulianBatchNumbers';
    REG_NavBarcodeLengths       = 'NavBarcodeLengths';//comma separated lengths of valid NAV barcodes.
    REG_NavBarcodeFormat        = 'NavBarcodeFormat';//CSV like in fops carcasebarcodeformat
    REG_PromptForBatchOnOrderChange = 'PromptForBatchOnOrderChange';
    REG_PromptForBatchOnMixChange   = 'PromptForBatchOnMixChange';
*)

    {Reg Table}
    RG_TagName    = 'TagName';
    RG_FolderName = 'FolderName';
    RG_Value      = 'Value';

    OH_OrderNo              = 'Order_No';
    OH_OrderNoSuffix        = 'Order_No_Suffix';
    OH_Status               = 'Status';
    OH_ScheduleDate         = 'Schedule_Date';
    OH_RecipeCode           = 'Recipe_No';
    OH_TotalWeightDone      = 'Tot_Weight_Done';
    OH_TotalWeightRequired  = 'Tot_Weight_Reqd';
    OH_MixesRequired        = 'Mixes_Reqd';
    OH_CurrentMix           = 'Current_Mix';
    OH_MixesDone            = 'Mixes_Done';
    OH_MixType              = 'Mix_Method';
    OH_FinishWeightRequired = 'Finish_Wt_Reqd';
    OH_MaxMixWeight         = 'Max_Mix_Wt';
    OH_FixedSequence        = 'Fixed_Sequence';
    OH_WorkGroup            = 'Work_Group';
    OH_Updates              = 'Updates';

    OL_OrderNo         = 'Order_No';
    OL_OrderNoSuffix   = 'Order_No_Suffix';
    OL_KeyLine         = 'Key_Line';
    OL_LineNo          = 'Line_No';
    OL_Ingredient      = 'Ingredient';
    OL_ProcessType     = 'Process_Type';
    OL_ContainerWeight = 'Container_Wt';
    OL_FixedWeight     = 'Fixed_Weight';
    OL_FinalPercent    = 'Final_Percent';
    OL_MixingYield     = 'Mixing_Yield';
    OL_ToleranceNegPercent = 'Tol_NegPercent';
    OL_TolerancePosPercent = 'Tol_PosPercent';
    OL_TotalWeightDone     = 'Tot_Weight_Done';
    OL_TotalTransDone      = 'Tot_Trans_Done';
    OL_SpecialInstruction1 = 'Spec_Instruct1';
    OL_SpecialInstruction2 = 'Spec_Instruct2';

    Rej_Offerid            = 'Offer_id';
    Rej_Usercode           = 'User_code';
    Rej_RejectionDate      = 'Rejection_Date';
    Rej_RejectionTime      = 'Rejection_Time';
    Rej_OverrideRequested  = 'Override_requested';

    RejRea_ReasonNo        = 'Reason_no';
    RejRea_Description     = 'Description';

    RH_RecipeCode  = 'Recipe_Code';
    RH_Description = 'Description';
    RH_FileRef     = 'FileRef';
    RH_MixMethod   = 'Mix_Method';
    RH_JobNumber   = 'Job_Number';

    RL_LineNo     = 'Line_No';
    RL_Ingredient = 'Ingredient';

    RoRejOff_OfferId            = 'Offer_id';
    RoRejOff_OrderNo            = 'Order_no';
    RoRejOff_Ingredient         = 'Ingredient';
    RoRejOff_Barcode            = 'Barcode';
    RoRejOff_ReasonNo           = 'Reason_no';
    RoRejOff_LabelBarcode       = 'Label_barcode';
    RoRejOff_CurrentOverrideId  = 'Current_override_id';

    RoOve_OverrideId            = 'Override_id';
    RoOve_OfferId               = 'Offer_id';
    RoOve_Denied                = 'Denied';
    RoOve_Reason                = 'Reason';
    RoOve_ValidFromDate         = 'Valid_from_date';
    RoOve_ValidFromTime         = 'Valid_from_time';
    RoOve_ValidToDate           = 'Valid_to_date';
    RoOve_ValidToTime           = 'Valid_to_time';
    RoOve_Authorized_by         = 'Authorized_by';
    RoOve_Authorization_date    = 'Authorization_date';
    RoOve_Authorization_time    = 'Authorization_time';

    ING_Ingredient  = 'Ingredient';
    ING_Description = 'Description';
    ING_NegativeTolerance = 'Tol_NegPercent';
    ING_PositiveTolerance = 'Tol_PosPercent';
    ING_PrepArea          = 'Prep_Area';
    ING_NoTare            = 'No_Tare';

    MIX_OrderNo        = 'Order_No';
    MIX_OrderNoSuffix  = 'Order_No_Suffix';
    MIX_MixNo          = 'Mix_No';
    MIX_Complete       = 'Complete';
    MIX_WeightRequired = 'Weight_Reqd';
    MIX_WeightDone     = 'Weight_Done';
    MIX_QAComplete     = 'QA_Complete';
    MIX_MeatQADone      = 'Meat_QA_done';
    MIX_SeasoningQADone = 'Seasoning_QA_done';
    MIX_WaterQADone     = 'Water_QA_done';
    MIX_Reserved       = 'Reserved';

    SC_ID             = 'ID';
    SC_Code           = 'Code';
    SC_Type           = 'Type';

    TRN_Ingredient    = 'Ingredient';
    TRN_OrderNo       = 'Order_No';
    TRN_RecipeNo      = 'Recipe_No';
    TRN_MID           = 'MC_ID';
    TRN_SerialNo      = 'Serial_No';
    TRN_Time          = 'Trans_Time';
    TRN_Date          = 'Trans_Date';
    TRN_OrderLineNo   = 'Order_Line_No';
    TRN_Reserved2     = 'Reserved2';
    TRN_WeightInMix   = 'Weight_In_Mix';
    TRN_BatchNo       = 'Batch_No';
    TRN_LotNo         = 'Lot_No';
    TRN_ContainerNo   = 'Container_No';
    TRN_MixNo         = 'Mix_No';
    TRN_Status        = 'Status';
    TRN_OrderNoSuffix = 'Order_No_Suffix';
    TRN_TempChecked   = 'TempChecked';
    TRN_UserID        = 'User_ID';
    TRN_CalcPostMixWt = 'Calc_Post_Mix_Wt';
    TRN_WeightOnScale = 'Weight_on_Scale';
    TRN_SourceCodeId  = 'Source_code_id';
    TRN_Temperature   = 'Temperature';
    TRN_Reserved      = 'Reserved';

    TWN_MID           = 'MC_ID';
    TWN_SerialNo      = 'Serial_No';
    TWN_Warning       = 'Warning';
    TWN_SrcConcessionNo = 'SrcConcessionNo';
    TWN_Reserved      = 'Reserved';

    INGU_Ingredient  = 'Ingredient';
    INGU_DateUsed    = 'Date_Used';
    INGU_NetWt       = 'Net_Wt';
    INGU_BatchNo     = 'Batch_No';
    INGU_LotNo       = 'Lot_No';
    INGU_TransCount  = 'Trans_Count';

    COST_Ingredient   = 'Ingredient';
    COST_LotNo        = 'Lot_No';
    COST_Cost         = 'Cost';
    COST_WeightIn     = 'WeightIn';
    COST_WeightUsed   = 'WeightUsed';
    COST_Free1        = 'Free1';
    COST_WeightWasted = 'WeightWasted';
    COST_Reserved     = 'Reserved';

    UN_UserName    = 'UserName';
    UN_FullName    = 'FullName';
    UN_Password    = 'Pass';
    UN_AccessLevel = 'AccessLevel';

    STK_Product = 'Product';
    STK_InStock = 'InStock';
    STK_Weight  = 'Weight';
    STK_Initial = 'Initial';
    STK_InitWt  = 'InitWt';

    LOT_Ingredient = 'Ingredient';
    LOT_MachineID  = 'MachineID';
    LOT_LotNo      = 'Lot_No';

type
  TOverrideType = (override_zero,
                   override_INCORRECTPROD,
                   override_LIFEEXPIRED,
                   override_EMPTY);

  TMixType = (mt_SingleContainerPerMix,
              mt_SegregatedIngredients,
              mt_OptionallySegregated,
              mt_EqualContainersPerMix,
              mt_CampaignWeighing);

const
  MixSet_ProportionallyMixedConts : SET OF TMixType =
                       [mt_SingleContainerPerMix,
                        mt_EqualContainersPerMix];

  MixSet_AutoTareAfterWeighing : SET OF TMixType =
                       [mt_SingleContainerPerMix,
                        mt_OptionallySegregated];

  MixSet_AutoCancelOfTares : SET OF TMixType =
              { (DiffContEachWeighing and optionally segregated ) }
                       [mt_SegregatedIngredients,
                        mt_OptionallySegregated,
                        mt_EqualContainersPerMix,
                        mt_CampaignWeighing];

  {Transaction Status Types}
  TRNStatusActive  = 1;
  TRNStatusAborted = 2;  {Note Abort Mix Option From Scale}


type
  TProcessTypes = (PTWeight,PTStep,PTCount,PTAuto);
  TStatusType = (StatusHOLD,StatusWIP,StatusCOMP);

  TFindMixResult = (FM_MixFound,
                    FM_AllMixesComplete,
                    FM_PrevMixFound,
                    FM_IngredCompInAllMixes,
                    FM_MixesFinishedInArea,
                    FM_OrderNotFound);

  PMixLineRecord = ^TMixLineRecord; { Not written to disk - initialised }
  TMixLineRecord = record           { from transaction file.            }
     ML_OrderNo         : LONGINT;          {0.0}
     ML_Revision        : BYTE;
     ML_MixNo           : LONGINT;
     ML_LineNo          : LONGINT;          {0.1}
     ML_WghsDone        : LONGINT;
     ML_WtDone          : DOUBLE;
  end;

  TdmFormixBase = class(TBaseDM)
    pvtblOrderHeader: TPvTable;
    pvtblOrderLine: TPvTable;
    pvtblRecipeHeader: TPvTable;
    pvtblRecipeLines: TPvTable;
    pvtblIngredients: TPvTable;
    pvtblMixTotal: TPvTable;
    pvtblTransactions: TPvTable;
    pvtblIngredientUsage: TPvTable;
    pvtblCost: TPvTable;
    pvtblUserName: TPvTable;
    pvtblStock: TPvTable;
    pvtblLotIRef: TPvTable;
    pvtblRORejectedOffering: TPvTable;
    pvtblRejections: TPvTable;
    pvvtblRejectReasons: TPvTable;
    pvtblROOverrides: TPvTable;
    pvtblSourceCodes: TPvTable;
    pvtblTransactionsForMixCalcs: TPvTable;
    rxmIngredientsCache: TRxMemoryData;
    rxmIngredientsCacheIngredient: TStringField;
    rxmIngredientsCacheDescription: TStringField;
    rxmRecipeCache: TRxMemoryData;
    rxmRecipeCacheRecipe_Code: TStringField;
    rxmRecipeCacheDescription: TStringField;
    pvtblTransWarnings: TPvTable;
    rxmIngredientsCachePrep_Area: TStringField;
    rxmTermRegSettings: TRxMemoryData;
    rxmTermRegSettingsSettingNo: TIntegerField;
    rxmTermRegSettingsTag: TStringField;
    rxmTermRegSettingsSystemWide: TBooleanField;
    rxmTermRegSettingsTermScaleNo: TWordField;
    rxmTermRegSettingsDefaultValue: TStringField;
    rxmTermRegSettingsDescription: TStringField;
    rxmTermRegSettingsValue: TStringField;
    rxmIngredientsCacheNo_Tare: TBooleanField;
    procedure MixMethodGetText(Sender: TField; var Text: String; DisplayText: Boolean);
    procedure pvtblTransactionsAfterOpen(DataSet: TDataSet);
    procedure pvtblMixTotalAfterOpen(DataSet: TDataSet);
    procedure pvtblRecipeHeaderAfterOpen(DataSet: TDataSet);
    procedure pvtblOrderHeaderAfterOpen(DataSet: TDataSet);
  private
    { Private declarations }
    f_Cache_FXEqualMixes : boolean;
    f_Cache_FXLastMixCompensation : boolean;
    procedure AddTermRegSetting(ARegSettingNo   : TRegistrySettingNo;
                                const KeyName64 : string;
                                IsSystemWide    : boolean;
                                IsForTerminalScaleNo   : integer;
                                const ADefaultValue100 : string;
                                const DescOfUsage128   : string);
  public
    { Public declarations }
    function MakeConnection : Boolean; override;
    procedure RefreshRegistryCache; virtual;
    procedure LoadRxmTermRegSettings;
    procedure RefreshValueOnCurrRxmTermRegSettings;
    procedure AddDBValuesToRxmTermRegSettings;
    function  LocateRxmTermRegSettingsOnNumber(ForRegSettingNo : TRegistrySettingNo) : boolean;
    function GetPvtblRegFolderNameForRxmTermRegSetting : string;
    function RestorePositionOfWorkingTables(OrderNo : integer; OrderNoSuffix : integer;
                                            OrderLineNo : integer) : boolean;
//    function  AllTerminalsIniSectionName : string;

    {Override GetRegStringDef function so that a null entry in the DB table is treated as undefined.}
    function  GetRegStringDef(FolderName,TagName,Default: string): string; override;

    function  GetTermRegString(ForRegSettingNo : TRegistrySettingNo) : string;
    function  SetTermRegString(ForRegSettingNo : TRegistrySettingNo;
                               const ToString : string) : boolean;
    function  GetTermRegBoolean(ForRegSettingNo : TRegistrySettingNo): Boolean;
    function  SetTermRegBoolean(ForRegSettingNo : TRegistrySettingNo;
                                ToBool : boolean) : boolean;
    function  GetTermRegInteger(ForRegSettingNo : TRegistrySettingNo) : integer;
    function  SetTermRegInteger(ForRegSettingNo : TRegistrySettingNo;
                                ToInt : integer) : boolean;
    function  GetTermRegDouble(ForRegSettingNo : TRegistrySettingNo) : double;
    function  SetTermRegDouble(ForRegSettingNo : TRegistrySettingNo;
                               ToDouble : double) : boolean;
    procedure ResetDataSetDisplayLabels(DataSet: TDataSet);
    procedure HideDatasetReservedFields(ADataSet : TDataSet);
    function  FieldNameToTitle(FieldName: String) : String;
    procedure JulianToText(Sender: TField; var Text: String; DisplayText: Boolean);

    procedure CalcIngredReqsForMixWt(GrossMixWt  : DOUBLE;{tot ingred weight of one mix }
                                     CurrMixLineTots : TMixLineRecord;
                                     VAR Mix_Ingred_TotWt       : DOUBLE;
                                     VAR Mix_Ingred_Weighings   : LONGINT;
                                     VAR Mix_Ingred_WtIncrements: DOUBLE;
                                     VAR Mix_Ingred_WghsPerCont : LONGINT);
    function CalcLineGrossPortion: Double;
    function CalcMixGrossWtRemainingForOrdLine(const CurrMixLineTots: TMixLineRecord) : double;
    function CalcLineGrossWtReqdFromRecipeNet(ATotNetWt, { eg order finish wt }
                                              LineRatioPercent,
                                              LineYieldPercent : Double) : Double;
    function CalcCompensatedBatchMixWt(ForMixNo: Longint) : Double;
    function EstimateGrossWtReqdForMixNo(MixNo : Longint) : Double;
    function GetTotsForMixLine(OrderNo        : LONGINT;
                               Revision       : BYTE;
                               MixNo          : WORD;
                               OrderLineNo    : LONGINT;
                               var TotCont    : LONGINT;
                               var TotWt      : DOUBLE) : boolean;
    function ConstructMixLineRecForOrdLine(ForMixNo    : LONGINT;
                              var MixLRec : TMixLineRecord) : boolean;
    function  GetMixMethodDescription(FromMixMethod: Integer): String;
    function  GetTotalWtDoneOnMix(ForOrder, ForSuffix, ForMixNo: Integer): Double;
    function  GetCurrentFullOrderNo: String;
    function  GetRecipeName(ForRecipeCode: String): String;
    procedure ClearIngredientsCache;
    function  SynchIngredientsCacheWithCode(IngredientCode : string) : boolean;
    function  SynchRecipeCacheWithCode(RecipeCode : string) : boolean;
  end;

var
  TerminalName : string = '';

implementation
uses StrUtils,uIniUtils,DateUtils,uStdCTV,{ ufrmFormixMain, ufrmFormixProcessRecipe,ufrmGlobalLotBatchEdit,
     ufrmUserOverride} uTermDialogs, uDBFunctions;
{$R *.dfm}

function TdmFormixBase.MakeConnection : Boolean;
begin
  Result := inherited MakeConnection;
  if Result then //can now read files
  begin
    LoadRxmTermRegSettings; //This needs to be done before any calls to read registry table values.
    RefreshRegistryCache; //virtual method.
  end;
end;

procedure TdmFormixBase.RefreshRegistryCache; {virtual;}
begin
  f_Cache_FXEqualMixes          := GetTermRegBoolean(r_FXEqualMixes);
  f_Cache_FXLastMixCompensation := GetTermRegBoolean(r_FXLastMixCompensation);
end;

procedure TdmFormixBase.AddTermRegSetting(ARegSettingNo : TRegistrySettingNo;
                                          const KeyName64 : string;
                                          IsSystemWide    : boolean;
                                          IsForTerminalScaleNo   : integer;
                                          const ADefaultValue100 : string;
                                          const DescOfUsage128   : string);
begin
  rxmTermRegSettings.Append;
  rxmTermRegSettingsSettingNo.AsInteger   := Ord(ARegSettingNo);
  rxmTermRegSettingsTag.AsString          := KeyName64;
  rxmTermRegSettingsSystemWide.AsBoolean  := IsSystemWide;
  rxmTermRegSettingsTermScaleNo.AsInteger := IsForTerminalScaleNo;
  rxmTermRegSettingsDefaultValue.AsString := ADefaultValue100;
  rxmTermRegSettingsDescription.AsString  := DescOfUsage128;
  rxmTermRegSettings.Post;
end;

procedure TdmFormixBase.LoadRxmTermRegSettings;
{NOTE: Default strings values cannot be overriden by null ('') due to implementation
       of virtual GetRegStringDef() function.
}
begin
  rxmTermRegSettings.Active := true;
  rxmTermRegSettings.EmptyTable;

  AddTermRegSetting(r_MachineID              , 'Machine ID',  false, 0,
                          '00', 'Machine Number saved on Transactions');
  AddTermRegSetting(r_RunNumber              , 'Run Number', false, 0,
                          '000001', 'Serial number for next Transaction');
//    REG_BatchNumber           = 'Batch Number';
  AddTermRegSetting(r_FXLastMixCompensation  , 'FXLastMixCompensation', true, 0,
                          'true', 'Target weight of last mix is adjusted to suit ordered weight and mix weights already done.');
  AddTermRegSetting(r_Password               , 'Password', false, 0,
                          '', 'Setup Menu access data');
  AddTermRegSetting(r_CurrentWeighScale      , 'CurrentWeighScale', false, 0,
                          '1', 'ID of active Scale Indicator');
  AddTermRegSetting(r_S1_ScaleType             , 'ScaleType', false, 1,
                          '0', 'Scale Indicator 1 connection type: 0=Serial, 1=Network');
  AddTermRegSetting(r_S2_ScaleType             , 'ScaleType', false, 2,
                          '0', 'Scale Indicator 2 connection type: 0=Serial, 1=Network');
  AddTermRegSetting(r_S1_ScaleModel            , 'ScaleModel', false, 1,
                          '0', 'Scale Indicator 1 model: 0=CSW, 1=Rinstrun, 2=Mettler');
  AddTermRegSetting(r_S2_ScaleModel            , 'ScaleModel', false, 2,
                          '0', 'Scale Indicator 2 model: 0=CSW, 1=Rinstrun, 2=Mettler');
  AddTermRegSetting(r_S1_ScaleSetup            , 'ScaleSetup', false, 1,
                          '',  'Scale Indicator 1 config string.');
  AddTermRegSetting(r_S2_ScaleSetup            , 'ScaleSetup', false, 2,
                          '',  'Scale Indicator 2 config string.');
  AddTermRegSetting(r_S1_IPScaleSetup          , 'IPScaleSetup', false, 1,
                          '',  'Scale Indicator 1 network setup.');
  AddTermRegSetting(r_S2_IPScaleSetup          , 'IPScaleSetup', false, 2,
                          '',  'Scale Indicator 2 network setup.');
  AddTermRegSetting(r_S1_ScaleIncrement        , 'ScaleIncrement', false, 1,
                          '2', 'Scale Indicator 1 number of DECIMAL PLACES.');
  AddTermRegSetting(r_S2_ScaleIncrement        , 'ScaleIncrement', false, 2,
                          '2', 'Scale Indicator 2 number of DECIMAL PLACES.');
  AddTermRegSetting(r_S1_FxWtRoundMod          , 'FXWtRoundMod', false, 1,
                          '0.005', 'Scale Indicator 1 weight increments.');
  AddTermRegSetting(r_S2_FxWtRoundMod          , 'FXWtRoundMod', false, 2,
                          '0.005', 'Scale Indicator 2 weight increments.');
  AddTermRegSetting(r_S1_ScaleMax             , 'ScaleMax', false, 1,
                          '60.00', 'Scale Indicator 1 max weight.');
  AddTermRegSetting(r_S2_ScaleMax             , 'ScaleMax', false, 2,
                          '60.00', 'Scale Indicator 2 max weight.');
//    REG_EnquireForLotBatchNo  = 'EnquireForLotBatchNo';
//    REG_DisregardKeyIngredient = 'DisregardKeyIngredient';
//    REG_UseLotNumbers          = 'UseLotNumbers';
  AddTermRegSetting(r_SFXProgramStaysOnTop    , 'SFXProgramStaysOnTop', false, 0,
                          'false', 'Program''s main windows stay on top of other windows');
  AddTermRegSetting(r_SFXUserTimeoutSecs      , 'SFXUserTimeoutSecs', true{IsSystemWide}, 0,
                          '0', 'Seconds without screen touches before User password required. 0=infinite');
  AddTermRegSetting(r_SFXModeIssue            , 'SFXModeIssue', false, 0,
                          'false', '"Issue Stock Item" action available.');
  AddTermRegSetting(r_WorkGroupFilter         , 'WorkGroupFilter', false, 0,
                          '*', 'Work Group Filter applied to list of Work Orders.');
  AddTermRegSetting(r_AllowManualWeight       , 'AllowManualWeight', false, 0,
                          'true', 'Allow manual entry of weights.');
  AddTermRegSetting(r_PrinterSetup            , 'PrinterSetup', false, 0,
                          '', 'Setup string for Label Printer.');
  AddTermRegSetting(r_NoOfTranTickets         , 'NoOfTranTickets', false, 0,
                          '1', 'Number of labels to print (if required) for ingredient weighings.');
  AddTermRegSetting(r_NoOfMixTickets          , 'NoOfMixTickets', false, 0,
                          '0', 'Number of labels to print when prep area finishes a mix.');
  AddTermRegSetting(r_MixTicketsAnytime       , 'MixTicketsAnytime', false, 0,
                          'true', 'Allow Mix Labels to be printed before mix is finished.');
  AddTermRegSetting(r_PrintTranTicket         , 'PrintTranTicket', false, 0,
                          'false', 'Ingredient labels are required.');
//    REG_CheckLabelTaken        = 'CheckLabelTaken';
  AddTermRegSetting(r_GlobalLotNumber         , 'GlobalLotNumber', false, 0,
                          '', 'Default Lot Code for weighings.');
  AddTermRegSetting(r_GlobalBatchNumber       , 'GlobalBatchNumber', false, 0,
                          '', 'Default Batch Number for weighings.');
  AddTermRegSetting(r_FXLabFormat             , 'FXLabFormat', false, 0,
                          '', 'Ingredient weighing label format and default mix label format.');
  AddTermRegSetting(r_FXMixLabFormat          , 'FXMixLabFormat', false, 0,
                          '', 'Mix label format.');
  AddTermRegSetting(r_FXLabFile               , 'FXLabFile', false, 0,
                          '', 'Label formats file to download to printer.');
  AddTermRegSetting(r_PrepArea                , 'PrepArea', false, 0,
                          '*', 'Preparation Area filter to be applied to Ingredient Lists.');
  AddTermRegSetting(r_SFXShowMixesDoneForArea , 'SFXShowMixesDoneForArea', false, 0,
                          'true', 'Mixes Done = number of mixes finished in Prep Area.');
  AddTermRegSetting(r_FXFullContainerHighTol  , 'FXFullContainerHighTol', false, 0,
                          '0.0', 'High tolerance on 1st weighings of multi container ingredient requirement.');
  AddTermRegSetting(r_SFXINGREDIENTCOSTING    , 'SFXINGREDIENTCOSTING', false, 0,
                          'false', 'Add Tran weights to ingredient cost records.');
  AddTermRegSetting(r_FXGlobalLot             , 'FXGlobalLot', false, 0,
                          'false', 'Add Trans weights to one Lot Cost record if specific record not found for Ingredient.');
  AddTermRegSetting(r_SFXAUTOADDCOST          , 'SFXAUTOADDCOST', false, 0,
                          'false', 'Create ingredient cost record automatically if not found.');
//    REG_LotNumber              = 'LotNumber';
  AddTermRegSetting(r_Stock                   , 'FXStock', false, 0,
                          'false', 'Add completed mix count and weight to stock file.');
  AddTermRegSetting(r_SFXAddMixToFopsStock    , 'SFXAddMixToFopsStock', false, 0,
                          'false', 'Add completed mixes to FOPS Stock.');
  AddTermRegSetting(r_FXEqualMixes            , 'FXEqualMixes', true, 0,
                          'false', 'Mix weights to be equal on multi-mix orders.');
//    REG_SFXSendIssuesToFops6   = 'SFXSendIssuesToFops6';
  AddTermRegSetting(r_SFXPromptForSource      , 'SFXPromptForSource', false, 0,
                          'false', 'Ingredient weighings prompt a source barcode scan.');
  AddTermRegSetting(r_SFXPromptForTemperature , 'SFXPromptForTemperature', false, 0,
                          'false', 'Ingredient weighings prompt for a temperature.');
  AddTermRegSetting(r_SFXRecordSource         , 'SFXRecordSource', false, 0,
                          'true', 'Source barcodes are saved in SOURCE_CODES table.');
  AddTermRegSetting(r_SFXIntakeMid            , 'SFXIntakeMid', false, 0,
                          '', 'FOPS Trans machine number for 6 digit serial numbers entered as the source.');
  AddTermRegSetting(r_FXIngredientsInFops6    , 'FXIngredientsInFops6', false, 0,
                          'true', 'Check FOPS Product code of source item matches, or belongs to a group that matches, the ingredient code.');
  AddTermRegSetting(r_SFXSourceOptional       , 'SFXSourceOptional', false, 0,
                          'false', 'Source barcode prompt can be skipped by the user.');
  AddTermRegSetting(r_SFXCommBufferName       , 'SFXCommBufferName', false, 0,
                          'COMMS', 'Commfilename prefix of fops session processing issue commands.');
  AddTermRegSetting(r_FXRoundWeights          , 'FXRoundWeights', false, 0,
                          'false', 'Adjust calculated tolerances to nearest scale increments.');
  AddTermRegSetting(r_EnquireForLotNo         , 'EnquireForLotNo', false, 0,
                          'false', 'Prompt User for Lot Code for each weighing.');
  AddTermRegSetting(r_CopyFopsTranSourceAsLot , 'CopyFopsTranSourceAsLot', false, 0,
                          'false', 'Lot no = fops tran src barcode or curr lot for ingredient.');
  AddTermRegSetting(r_EnquireForBatchNo       , 'EnquireFoBatchNo', false, 0,
                          'false', 'Prompt User for Batch Number for each weighing.');
  AddTermRegSetting(r_AcceptLabelWeight       , 'SFXAcceptLabelWeight', false, 0,
                          'false', 'Accept weight of fops transaction scanned.');
  AddTermRegSetting(r_SendFopsIssueTrans      , 'SFXSendFopsIssueTrans', false, 0,
                          'false', 'Send stock issue and part-issue commands to FOPS.');
  AddTermRegSetting(r_SFXAutoBatchFormat      , 'SFXAutoBatchFormat', false, 0,
                          '', 'Can be DDD000 (day number prefix) or DDDJJJ (day number and Recipe Job No).');
  AddTermRegSetting(r_BatchPrefixForFops      , 'BatchPrefixForFops', false, 0,
                          '00', 'Two digit prefix to convert formix batch to fops batch.');
  AddTermRegSetting(r_SFXAllowWtAboveSourceWt  , 'SFXAllowWtAboveSourceWt', false, 0,
                          'false', 'Allow source FOPS transaction to have less weight than weighing.');
  AddTermRegSetting(r_SFXUseOneScanOnly       , 'SFXUseOneScanOnly', false, 0,
                          'false', 'Source barcode scan also sets lot and batch numbers.');
  AddTermRegSetting(r_SFXAllowProductOverride  , 'SFXAllowProductOverride', false, 0,
                          'false', 'Allow incorrect fops products to be used if authorized.');
  AddTermRegSetting(r_SFXRemoteOverrides       , 'SFXRemoteOverrides', false, 0,
                          'false', 'Incorrect product authorization is done remotely (web app).');
  AddTermRegSetting(r_SFXAskForLifeDtConcessionNo,'SFXAskForLifeDtConcessionNo',false, 0,
                          'false', 'Product Concession number needs to be entered to accept out of date Product.');
  AddTermRegSetting(r_SFXAllowSixDigitBarCode  , 'SFXAllowSixDigitBarcode', false, 0,
                          'false', 'Six digit source barcode is acceptable.');
  AddTermRegSetting(r_SFXAllowBarcodeLength    , 'SFXAllowBarcodeLength', false, 0,
                          '0', 'Acceptable source barcode length. e.g. =12 for truncated mix barcode.');
  AddTermRegSetting(r_SFXAllowKeyedBarcode     , 'SFXAllowKeyedBarcode', false, 0,
                          'true', 'Allow manual input of Source using touchscreen keyboard.');
  AddTermRegSetting(r_SFXAllowPOBarcode        , 'SFXAllowPOBarcode', false, 0,
                          'false', '''PO'' followed by six digit number is accepted as a source barcode.');
  AddTermRegSetting(r_SFXAllowTranNotFound     , 'SFXAllowTranNotFound', false, 0,
                          'false', 'Accept source barcodes that appear to relate to FOPS Trans but cannot be found.');
  AddTermRegSetting(r_SFXNoAutoCancelOfTares   , 'SFXNoAutoCancelOfTares', false, 0,
                          'false', 'Stops cancel of tare when container is removed for ''No Tare'' ingredient.');
  AddTermRegSetting(r_SFXQAAtMixStart          , 'SFXQAAtMixStart', false, 0,
                          'false', 'QA required for each mix before weighing ingredients in each prep area.');
  AddTermRegSetting(r_SFXMixScanAtOrderSelect  , 'SFXMixScanAtOrderSelect', false, 0,
                          'false', 'Mix Label barcode can be used for Order selection.');
//    REG_SFXJulianBatchNumbers   = 'SFXJulianBatchNumbers';
  AddTermRegSetting(r_NavBarcodeLengths        , 'NavBarcodeLengths', true, 0,
                          '', 'Comma separated lengths of valid NAV barcodes.');
  AddTermRegSetting(r_NavBarcodeFormat         , 'NavBarcodeFormat', true, 0,
                          '', 'like in FOPS carcasebarcodeformat');
  AddTermRegSetting(r_PromptForBatchOnOrderChange  , 'PromptForBatchOnOrderChange', false, 0,
                          'false', '');
  AddTermRegSetting(r_PromptForBatchOnMixChange    , 'PromptForBatchOnMixChange', false, 0,
                          'false', '');
  AddTermRegSetting(r_OcmProgramFile           , 'OcmProgramFile', false, 0,
                          '', 'File to be run for OCM operations.');
  AddTermRegSetting(r_OcmIniFile               , 'OcmIniFile', false, 0,
                          '', 'Fully pathed name of "System Ini file" to be used by OCM program.');
  AddTermRegSetting(r_MaxPasswordAge           , 'MaxPasswordAge', true, 0,
                          '', 'Maximum age of User Passwords, in days, that are valid for system (0 = unlimited).');
end;

procedure TdmformixBase.RefreshValueOnCurrRxmTermRegSettings;
begin
  rxmTermRegSettings.Edit;
  rxmTermRegSettingsValue.AsString := GetRegStringDef(GetPvtblRegFolderNameForRxmTermRegSetting,
                                                      rxmTermRegSettingsTag.AsString,
                                                      rxmTermRegSettingsDefaultValue.AsString);
  rxmTermRegSettings.Post;
end;

procedure TdmFormixBase.AddDBValuesToRxmTermRegSettings;
begin
  Registry.Active := true;
  rxmTermRegSettings.First;
  while not rxmTermRegSettings.Eof do
  begin
    RefreshValueOnCurrRxmTermRegSettings;
    rxmTermRegSettings.Next;
  end;
  Registry.Active := false;
end;

{ TdmFormix }
function RoundWtUpToUnits(Weight : DOUBLE;
                          UnitWt : DOUBLE) : LONGINT;
var UnitsExact: DOUBLE;
    PartUnitWt: DOUBLE;
    NoOfUnits : LONGINT;
begin
 UnitsExact := DivDouble(Weight,UnitWt);
 NoOfUnits := Trunc(UnitsExact);
 PartUnitWt := frac(UnitsExact) * UnitWt;
 { if remainder >= 0.001(smallest possible scale increment) then round up }
 if CompareWts(PartUnitWt, 0.0) > 0 then
   Inc(NoOfUnits);
 RoundWtUpToUnits := NoOfUnits;
end;
(*
function TdmFormixBase.AllTerminalsIniSectionName : string;
begin
  Result := REG_Scale;
end;
*)

function TdmFormixBase.GetPvtblRegFolderNameForRxmTermRegSetting : string;
{REQUIRES: rxmTermRegSettings to be located on setting in question.}
begin
  if rxmTermRegSettingsSystemWide.AsBoolean then
    Result := 'Scale.'
  else if rxmTermRegSettingsTermScaleNo.AsInteger < 2 then
    Result := 'Scale.'+TerminalName
  else {only Scale Indicator 2 has an extra number on the foldername}
    Result := 'Scale.'+TerminalName+'.'+IntToStr(rxmTermRegSettingsTermScaleNo.AsInteger);
end;

function TdmFormixBase.LocateRxmTermRegSettingsOnNumber(ForRegSettingNo : TRegistrySettingNo) : boolean;
begin
  rxmTermRegSettings.Active := true;
  Result := rxmTermRegSettings.Locate(rxmTermRegSettingsSettingNo.FieldName, Ord(ForRegSettingNo), []);
  if not Result then
    TermMessageDlg('Error reading Setting number '+IntToStr(Ord(ForRegSettingNo)),
                   mtError, [mbOK], 0);
end;

function TdmFormixBase.GetRegStringDef(FolderName,TagName,Default: string): string; {override;}
{PROMISES: To return Default if the record is not found in the table or the record value is null.
}
var
  Found : Boolean;
begin
  Result := GetRegString(FolderName, TagName, Found);
  if Result = '' then
    Result := Default;
end;

function TdmFormixBase.GetTermRegString(ForRegSettingNo : TRegistrySettingNo) : string;
{PROMISES: Reads string from pvtblRegistry, not from a cache.}
begin
  if LocateRxmTermRegSettingsOnNumber(ForRegSettingNo) then
    Result := GetRegStringDef(GetPvtblRegFolderNameForRxmTermRegSetting,
                              rxmTermRegSettingsTag.AsString,
                              rxmTermRegSettingsDefaultValue.AsString)
  else
    Result := '';
end;
function TdmFormixBase.SetTermRegString(ForRegSettingNo : TRegistrySettingNo;
                                        const ToString : string) : boolean;
begin
  Result := false;
  if LocateRxmTermRegSettingsOnNumber(ForRegSettingNo) then
  begin
    SetRegString(GetPvtblRegFolderNameForRxmTermRegSetting,
                 rxmTermRegSettingsTag.AsString,
                 ToString);
    Result := true;
  end;
end;

function TdmFormixBase.GetTermRegBoolean(ForRegSettingNo : TRegistrySettingNo): Boolean;
{PROMISES: yes,Yes,YES,1,true etc are accepted as boolean setting of true}
begin
  Result := false;
  if LocateRxmTermRegSettingsOnNumber(ForRegSettingNo) then
    Result := IniStrToBoolean(GetTermRegString(ForRegSettingNo),
                              IniStrToBoolean(rxmTermRegSettingsDefaultValue.AsString, false));
end;
function TdmFormixBase.SetTermRegBoolean(ForRegSettingNo : TRegistrySettingNo;
                                         ToBool : boolean) : boolean;
begin
  Result := false;
  if LocateRxmTermRegSettingsOnNumber(ForRegSettingNo) then
  begin
    SetRegBoolean(GetPvtblRegFolderNameForRxmTermRegSetting,
                  rxmTermRegSettingsTag.AsString,
                  ToBool);
    Result := true;
  end;
end;

function TdmFormixBase.GetTermRegInteger(ForRegSettingNo : TRegistrySettingNo): integer;
begin
  Result := 0;
  if LocateRxmTermRegSettingsOnNumber(ForRegSettingNo) then
    Result := StrToIntDef(GetTermRegString(ForRegSettingNo),
                          StrToIntDef(rxmTermRegSettingsDefaultValue.AsString, 0));
end;
function TdmFormixBase.SetTermRegInteger(ForRegSettingNo : TRegistrySettingNo;
                                         ToInt : integer) : boolean;
begin
  Result := false;
  if LocateRxmTermRegSettingsOnNumber(ForRegSettingNo) then
  begin
    SetRegInteger(GetPvtblRegFolderNameForRxmTermRegSetting,
                  rxmTermRegSettingsTag.AsString,
                  ToInt);
    Result := true;
  end;
end;

function TdmFormixBase.GetTermRegDouble(ForRegSettingNo : TRegistrySettingNo): double;
begin
  Result := 0.0;
  if LocateRxmTermRegSettingsOnNumber(ForRegSettingNo) then
    Result := StrToFloatDef(GetTermRegString(ForRegSettingNo),
                            StrToFloatDef(rxmTermRegSettingsDefaultValue.AsString, 0.0));
end;
function TdmFormixBase.SetTermRegDouble(ForRegSettingNo : TRegistrySettingNo;
                                        ToDouble : double) : boolean;
begin
  Result := false;
  if LocateRxmTermRegSettingsOnNumber(ForRegSettingNo) then
  begin
    SetRegReal(GetPvtblRegFolderNameForRxmTermRegSetting,
               rxmTermRegSettingsTag.AsString,
               ToDouble);
    Result := true;
  end;
end;


function TdmFormixBase.CalcCompensatedBatchMixWt(ForMixNo: Integer): DOUBLE;
{REQUIRES  OrdHRec to be initialised with identification and tot number
           of mixes.
 PROMISES  To return target mix wt that will compensate for weight deviations
           on previous mixes. Currently compensation is only done on last mix.
}
var RetTargetWt,
    AdjustedTargetWt : DOUBLE;
    NewDBTrans : boolean;
begin
 RetTargetWt := 0.0;
 if pvtblMixTotal.Locate(MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo,
                         VarArrayOf([pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                     pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                                     ForMixNo]),[]) then
  begin
   RetTargetWt := pvtblMixTotal.FindField(MIX_WeightRequired).AsFloat;
   if  f_Cache_FXLastMixCompensation
   and (pvtblOrderHeader[OH_MixType] <> mt_CampaignWeighing) {Cant have live wts  }
   and (ForMixNo = pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger) { only last mix adjusted - at the moment }
   and (CompareWts(pvtblMixTotal.FindField(MIX_WeightDone).AsFloat,0.0) <= 0) then { Target weight free to be adjusted}
    begin                               { for previous batch deviations    }
     AdjustedTargetWt := EstimateGrossWtReqdForMixNo(ForMixNo);
     { read other mix records to accumulate deviations }
     pvtblMixTotal.FindNearest([pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                                1]);
     while (not pvtblMixTotal.Eof)
     and   (pvtblMixTotal.FindField(MIX_OrderNo).AsInteger = pvtblOrderHeader.FindField(OH_OrderNo).AsInteger)
     and   (pvtblMixTotal.FindField(MIX_OrderNoSuffix).AsInteger = pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger) do
      begin
       if (pvtblMixTotal.FindField(MIX_MixNo).AsInteger <> ForMixNo) and
          (pvtblMixTotal.FindField(MIX_Complete).AsBoolean) then
         AdjustedTargetWt := AdjustedTargetWt +
                             EstimateGrossWtReqdForMixNo(pvtblMixTotal.FindField(MIX_MixNo).AsInteger)-
                             pvtblMixTotal.FindField(MIX_WeightDone).AsFloat;
       pvtblMixTotal.Next;
      end;
     if AdjustedTargetWt < 0.0 then
       AdjustedTargetWt := 0.0;
     AdjustedTargetWt := RoundWtToNearestGram(AdjustedTargetWt);
     { now update mix record with new target wt }
     if AdjustedTargetWt <> RetTargetWt then
      begin
       if pvtblMixTotal.Locate(MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo,
                               VarArrayOf([pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                           pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                                           ForMixNo]),[]) then
        begin
         if (CompareWts(pvtblMixTotal.FindField(MIX_WeightDone).AsFloat,0.0) <= 0) then { still hasnt been started }
          begin
           NewDBTrans := not pvtblMixTotal.Database.InTransaction;
           try
             if NewDBTrans then
               pvtblMixTotal.Database.StartTransaction;
             pvtblMixTotal.Edit;
             pvtblMixTotal.FindField(MIX_WeightRequired).AsFloat := AdjustedTargetWt;
             pvtblMixTotal.Post;
             if NewDBTrans then
               pvtblMixTotal.Database.Commit;
           except
             on E: exception do
             begin
               if NewDBTrans then
               begin
                 pvtblMixTotal.Database.Rollback;
                 TermMessageDlg(E.Message,mtWarning,[mbOk],0);
               end;
               pvtblMixTotal.Cancel;
             end;
           end;
           RetTargetWt := pvtblMixTotal.FindField(MIX_WeightRequired).AsFloat;
          end
         else { mix has been started now }
          begin
           RetTargetWt := pvtblMixTotal.FindField(MIX_WeightRequired).AsFloat;
         end;
        end;
      end;
    end;
  end;
 Result := RetTargetWt;
end;

function TdmFormixBase.CalcMixGrossWtRemainingForOrdLine(const CurrMixLineTots: TMixLineRecord) : double;
{REQUIRES: Tables to be positioned on related records:-
            OrderHeader
            OrderLine
            MixTotal
}
var
  OrdLineMixGrossWt    : double;
begin
  OrdLineMixGrossWt := pvtblMixTotal.FieldByName(MIX_WeightRequired).AsFloat * CalcLineGrossPortion;
  Result := OrdLineMixGrossWt - CurrMixLineTots.ML_WtDone;
end;

procedure TdmFormixBase.CalcIngredReqsForMixWt(GrossMixWt: DOUBLE;
  CurrMixLineTots: TMixLineRecord; var Mix_Ingred_TotWt: DOUBLE;
  var Mix_Ingred_Weighings: Integer; var Mix_Ingred_WtIncrements: DOUBLE;
  var Mix_Ingred_WghsPerCont: Integer);
{NOTES:
1. This procedure is designed to be used by the terminal to display
   the size and predicted quantity of remaining weighings.
   Do not use this function to calculate the remaining weight required
   by a mix for an order line.
2. If mix type is NOT Proportionally mixed containers then
   requirements = remaining requirement + whats been done
   (enables only last weighing to be within a tolerance).

REQUIRES: Tables to be positioned on related records:-
            OrderHeader
            OrderLine
}
VAR
  ContainersReq : LONGINT;
  IngredWtForContainer : DOUBLE;
  RemainingWt : DOUBLE;
BEGIN
 Mix_Ingred_TotWt       := 0.0;
 Mix_Ingred_Weighings   := 0; { caller might pass through 0 wt when order is complete}
 Mix_Ingred_WtIncrements:= 0.0;
 Mix_Ingred_WghsPerCont := 1;

 IF (GrossMixWt > 0.0) THEN
  BEGIN
   Mix_Ingred_Weighings   := 0;

//   WITH OrderHeader^, OrderLine^ DO
    BEGIN
     Mix_Ingred_TotWt := GrossMixWt * CalcLineGrossPortion;
     { calculate requirements as: remaining requirement + whats been done.}
     RemainingWt := Mix_Ingred_TotWt - CurrMixLineTots.ML_WtDone;

(*   RoundWtToScaleRes(RemainingWt); *)

     { Calculate no of weighings for mix and at what weight }
     { Weighings in any one mix are always the same.        }
     IF pvtblOrderLine[OL_ProcessType] = PTStep THEN { steps only have 1 "weighing" per mix }
      BEGIN
       Mix_Ingred_Weighings    := 1;
       Mix_Ingred_WtIncrements := 0.0;
      END
     ELSE IF TMixType(pvtblOrderHeader.FindField(OH_MixType).AsInteger) IN MixSet_ProportionallyMixedConts THEN
      BEGIN
       {Usually more, but smaller, weighings due to ingredients being split over
        more containers. There maybe less containers in total because they're all
        nearly full.
        Number of containers and hence weighings is controlled by the total mix
        weight and the shared container size.
       }
       { HOW MANY CONTAINERS? }
       ContainersReq := RoundWtUpToUnits(GrossMixWt,pvtblOrderLine[OL_ContainerWeight]);

       { HOW MUCH INGREDIENT WEIGHT PER CONTAINER? }
       IngredWtForContainer := DivDouble(Mix_Ingred_TotWt, ContainersReq);

       { HOW MANY WEIGHINGS? }
{$IFNDEF MAUNDERS} { maunders want count ingredient to mean user just needs
                     to confirm required weight has been done elsewhere.
                     So set wt increment as for normal weighing. }
       IF pvtblOrderLine[OL_ProcessType] = PTCount THEN { might need more than 1 weighing per container }
        BEGIN
         Mix_Ingred_WtIncrements := pvtblOrderLine[OL_FixedWeight];
         Mix_Ingred_WghsPerCont  := RoundWtUpToUnits(IngredWtForContainer,
                                                     pvtblOrderLine[OL_FixedWeight]);
         Mix_Ingred_Weighings := ContainersReq * Mix_Ingred_WghsPerCont;
        END
       ELSE { PTWeight }
{$ENDIF}
        BEGIN
         Mix_Ingred_WtIncrements := IngredWtForContainer;
         Mix_Ingred_Weighings    := ContainersReq;
        END;
      END
     ELSE
      BEGIN
       { Assume ingredients will go into their own containers as this is       }
       { easier to prepare.                                                    }
       { Mix type might give user the option to put them in the same container }
       { at their own risk (might overflow).                                   }
       { Number of containers and hence weighings is controlled by the         }
       { ingredient weight and the container size.                             }

{$IFNDEF MAUNDERS} { maunders want count ingredient to mean user just needs
                     to confirm required weight has been done elsewhere.
                     So set wt increment as for normal weighing. }
       IF pvtblOrderLine[OL_ProcessType] = PTCount THEN
        BEGIN
         { A lot of the code assumes all containers for an ingredient in a mix
           have the same weight - to reliably achieve this with fixed weight
           items and reduce fixed weight "give away" all fixed items
           will be assumed to be in their own container.
         ie. Mix_Ingred_WghsPerCont := 1
         }
         Mix_Ingred_WtIncrements := pvtblOrderLine[OL_FixedWeight];
         Mix_Ingred_Weighings    := RoundWtUpToUnits(Mix_Ingred_TotWt,
                                                     pvtblOrderLine[OL_FixedWeight]);
        END
       ELSE { PTWeight }
{$ENDIF}
        BEGIN
         { Use 'ContainersReq' to hold REMAINING containers required. }
         { -----------------------------------------------------------}
         { HOW MANY MORE CONTAINERS PURELY FOR THIS INGREDIENT? }
         ContainersReq := RoundWtUpToUnits(RemainingWt, pvtblOrderLine[OL_ContainerWeight]);


         { HOW MUCH INGREDIENT WEIGHT PER REMAINING CONTAINER? }
(*       no longer evenly spread - was a req for completion by container count
         IngredWtForContainer := DivDouble(RemainingWt, ContainersReq);
*)
         IF ContainersReq > 1 THEN
           IngredWtForContainer := pvtblOrderLine[OL_ContainerWeight]
         ELSE
           IngredWtForContainer := RemainingWt;
         Mix_Ingred_WtIncrements := IngredWtForContainer;

         { HOW MANY WEIGHINGS? }
         Mix_Ingred_Weighings    := ContainersReq + CurrMixLineTots.ML_WghsDone;
        END;
      END;
    END;
  END;

(* RoundWtToScaleRes(Mix_Ingred_TotWt);        *)
(* RoundWtToScaleRes(Mix_Ingred_WtIncrements); *)
end;

function TdmFormixBase.CalcLineGrossPortion: Double;
{REQUIRES: Tables to be positioned on related records:-
            OrderHeader
            OrderLine
}
begin
 Result := DivDouble(CalcLineGrossWtReqdFromRecipeNet(pvtblOrderHeader.FindField(OH_FinishWeightRequired).AsFloat,
                                                      pvtblOrderLine.FindField(OL_FinalPercent).AsFloat,
                                                      pvtblOrderLine.FindField(OL_MixingYield).AsFloat),
                     pvtblOrderHeader.FindField(OH_TotalWeightRequired).AsFloat);
end;


function TdmFormixBase.CalcLineGrossWtReqdFromRecipeNet(ATotNetWt,
  LineRatioPercent, LineYieldPercent: Double): Double;
var LineMixWt : DOUBLE;
begin
{  Ingredient wt  =  finish mix wt * (linePercent / 100)
                     ----------------------------
                     YieldPercent / 100
}
 if LineYieldPercent > 0.00001 then { we can divide }
   LineMixWt := ATotNetWt*(LineRatioPercent/LineYieldPercent) { 100's cancel out }
 else
   LineMixWt := ATotNetWt*(LineRatioPercent/100);
 Result := LineMixWt;
end;

function TdmFormixBase.EstimateGrossWtReqdForMixNo(MixNo: Integer): Double;
var MixWtGross : DOUBLE;
begin
 if f_Cache_FXEqualMixes then
  begin
   MixWtGross := DivDouble(pvtblOrderHeader.FindField(OH_TotalWeightRequired).AsFloat,
                           pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger);
  end
 else
  begin
   if MixNo < pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger then { full capacity mix }
    begin
     MixWtGross := pvtblOrderHeader.FindField(OH_MaxMixWeight).AsFloat;
    end
   else
    begin
     if MixNo = pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger then { last part mix }
      begin
       MixWtGross := pvtblOrderHeader.FindField(OH_TotalWeightRequired).AsFloat -
                           (pvtblOrderHeader.FindField(OH_MaxMixWeight).AsFloat *
                           (pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger-1));
      end
     else MixWtGross := 0.0;
    end;
  end;
 if MixWtGross < 0.0 then { scale res is greater last mix wt? }
   MixWtGross := 0.0;
 MixWtGross := RoundWtToNearestGram(MixWtGross);
 Result := MixWtGross;
end;

function TdmFormixBase.ConstructMixLineRecForOrdLine(ForMixNo: Integer; var MixLRec: TMixLineRecord): boolean;
{REQUIRES: 1. Tables to be positioned on related records:- OrderLine
           2. Transactions table's range to be free to be cancelled.
}
begin
 FillChar(MixLRec, SizeOf(MixLRec), 0);
 with MixLRec do
  BEGIN
   ML_OrderNo  := pvtblOrderLine.FindField(OL_OrderNo).AsInteger;
   ML_Revision := pvtblOrderLine.FindField(OL_OrderNoSuffix).AsInteger;
   ML_MixNo    := ForMixNo;
   ML_LineNo   := pvtblOrderLine.FindField(OL_LineNo).AsInteger;
   Result      := GetTotsForMixLine(ML_OrderNo,
                                    ML_Revision,
                                    ML_MixNo,
                                    ML_LineNo,
                                    ML_WghsDone, {VAR}
                                    ML_WtDone);  {VAR}
  END;
end;

function TdmFormixBase.GetTotsForMixLine(OrderNo: Integer; Revision: BYTE;
  MixNo: WORD; OrderLineNo: Integer; var TotCont: Integer;
  var TotWt: DOUBLE): boolean;
//edited by TB
{REQUIRES:
{PROMISES: 1. Returns false if database was not read ok.
           2. Sets TotCont and TotQt to no of weighings and wt for for OrderLineNo on mix: MixNo.
}
begin
 Result := false;
 TotCont := 0;
 TotWt   := 0.0;
 try
   if not pvtblTransactionsForMixCalcs.Active then
     pvtblTransactionsForMixCalcs.Open;
   pvtblTransactionsForMixCalcs.CancelRange;
   pvtblTransactionsForMixCalcs.IndexName := 'ByOrderMixLine';
   pvtblTransactionsForMixCalcs.SetRange([OrderNo,Revision,MixNo,OrderLineNo],
                              [OrderNo,Revision,MixNo,OrderLineNo]);
   try
     pvtblTransactionsForMixCalcs.First;
     while (not pvtblTransactionsForMixCalcs.Eof) do
     begin
       if (pvtblTransactionsForMixCalcs[TRN_Status] <> TRNStatusAborted) then
       begin
         Inc(TotCont);
         TotWt := TotWt + pvtblTransactionsForMixCalcs.FindField(TRN_WeightInMix).AsFloat;
       end;
       pvtblTransactionsForMixCalcs.Next;
     end;
     Result := true;
   finally
     try
       pvtblTransactionsForMixCalcs.Close; // stop CancelRange causing Record Not Found error.
     except
       on E:Exception do TermMessageDlg('Error on tidy up after reading mix transactions.'+#13#10+
                                        E.Message,mtError,[mbOk],0);
     end;
   end;
 except
   on E:Exception do
   begin
     TermMessageDlg('Error reading mix transactions'+#13#10+
                     E.Message,mtError,[mbOk],0);
   end;
 end;
end;


procedure TdmFormixBase.MixMethodGetText(Sender: TField;
  var Text: String; DisplayText: Boolean);
begin
 if Sender.IsNull then
   Text := ''
 else
   Text := GetMixMethodDescription(Sender.AsInteger);
end;


function TdmFormixBase.GetMixMethodDescription(FromMixMethod: Integer): String;
begin
 Result := '';
 case TMixType(FromMixMethod) of
  mt_SingleContainerPerMix : Result := 'Single';
  mt_SegregatedIngredients : Result := 'Segregate';
  mt_OptionallySegregated  : Result := 'Flexible';
  mt_EqualContainersPerMix : Result := 'Equal';
  mt_CampaignWeighing      : Result := 'Campaign';
  else Result := '';
 end;
end;

function TdmFormixBase.GetTotalWtDoneOnMix(ForOrder, ForSuffix,
  ForMixNo: Integer): Double;
begin
 Result := 0.0;
 if pvtblMixTotal.Locate(MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo,
                  VarArrayOf([ForOrder,ForSuffix,ForMixNo]),[]) then
   Result := pvtblMixTotal.FindField(MIX_WeightDone).AsFloat;
end;

function TdmFormixBase.GetCurrentFullOrderNo: String;
begin
 Result := IntToZeroStr(pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,6)+
           '/'+
           IntToZeroStr(pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,2);
end;


function TdmFormixBase.GetRecipeName(ForRecipeCode: String): String;
var RHOpened: Boolean;
begin
 Result := 'Recipe Not Found';
 try
  RHOpened := FALSE;
  if not pvtblRecipeHeader.Active then
   begin
    RHOpened := TRUE;
    pvtblRecipeHeader.IndexName := 'ByCode';
    pvtblRecipeHeader.Open;
   end;
  if pvtblRecipeHeader.Locate(RH_RecipeCode,ForRecipeCode,[]) then
    Result := pvtblRecipeHeader.FindField(RH_Description).AsString;
  if RHOpened then pvtblRecipeHeader.Close;
 except
   on E:Exception do
   begin
     TermMessageDlg('Error reading recipe name'+#13#10+
                     E.Message,mtError,[mbOk],0);
   end;
 end;
end;


procedure TdmFormixBase.JulianToText(Sender: TField; var Text: String; DisplayText: Boolean);
begin
 if Sender.IsNull then
  Text := ''
 else
 begin
  if Sender.AsInteger=0 then
   Text := ''
  else Text := DateToStr(JulianToDateValue(Sender.AsInteger));
 end;
end;

procedure TdmFormixBase.ResetDataSetDisplayLabels(DataSet: TDataSet);
var i: Integer;
begin
  for i := 0 to DataSet.Fields.Count-1 do
    DataSet.Fields[i].DisplayLabel := FieldNameToTitle(DataSet.Fields[i].FieldName);
end;

procedure TdmFormixBase.HideDatasetReservedFields(ADataSet : TDataSet);
var i: Integer;
begin
  for i := 0 to ADataSet.Fields.Count-1 do
  begin
    if Pos('RESERVED', UpperCase(ADataSet.Fields[i].FieldName)) = 1 then
      ADataSet.Fields[i].Visible := false;
  end;
end;

function TdmFormixBase.FieldNameToTitle(FieldName: String) : String;
var ReturnStr : string;
    i : integer;
begin
  ReturnStr := FieldName;
  for i := 1 to Length(ReturnStr) do
  begin
    if ReturnStr[i] = '_' then
      ReturnStr[i] := ' ';
  end;
  ReturnStr[1] := UpCase(ReturnStr[1]);
  FieldNameToTitle := ReturnStr;
end;
procedure TdmFormixBase.pvtblTransactionsAfterOpen(DataSet: TDataSet);
begin
  inherited;
  ResetDataSetDisplayLabels(DataSet);
  HideDatasetReservedFields(DataSet);
  with DataSet do
  begin
    FieldByName(TRN_Date).OnGetText := JulianToText;
    with FieldByName(TRN_Ingredient) do
      DisplayWidth := Round(DisplayWidth * 1.5);{allow for all capitals}
    with FieldByName(TRN_RecipeNo) do
      DisplayWidth := Round(DisplayWidth * 1.5);{allow for all capitals}
    with FieldByName(TRN_MixNo) do
      DisplayWidth := 3;
  end;
end;

procedure TdmFormixBase.pvtblMixTotalAfterOpen(DataSet: TDataSet);
var Field : TField;
begin
  inherited;
  ResetDataSetDisplayLabels(DataSet);
  HideDatasetReservedFields(DataSet);
  with DataSet do
  begin
    with FieldByName(MIX_MixNo) do
    begin
      DisplayWidth := 6;
    end;
    with FieldByName(MIX_OrderNo) do
    begin
      DisplayWidth := 8;
    end;
    with FieldByName(MIX_OrderNoSuffix) do
    begin
      DisplayLabel := 'Suffix';
      DisplayWidth := 6;
    end;
    with TFloatField(FieldByName(MIX_WeightRequired)) do
    begin
      DisplayLabel  := 'Wt. Reqd.';
      DisplayFormat := '0.000';
    end;
    with TFloatField(FieldByName(MIX_WeightDone)) do
    begin
      DisplayLabel  := 'Wt. Done';
      DisplayFormat := '0.000';
    end;
    Field := FindField(MIX_QAComplete);
    if field <> NIL then
      Field.DisplayLabel := 'QA done';
  end;
end;

procedure TdmFormixBase.pvtblRecipeHeaderAfterOpen(DataSet: TDataSet);
begin
  inherited;
  ResetDataSetDisplayLabels(DataSet);
  HideDatasetReservedFields(DataSet);
  with DataSet do
    FieldByName(RH_MixMethod).OnGetText := MixMethodGetText;
end;

procedure TdmFormixBase.pvtblOrderHeaderAfterOpen(DataSet: TDataSet);
begin
  inherited;
  ResetDataSetDisplayLabels(DataSet);
  HideDatasetReservedFields(DataSet);
  with DataSet do
    FieldByName(OH_ScheduleDate).OnGetText := JulianToText;
end;

procedure TdmFormixBase.ClearIngredientsCache;
begin
  rxmIngredientsCache.Active := true;
  rxmIngredientsCache.EmptyTable;
end;

function TdmFormixBase.SynchIngredientsCacheWithCode(IngredientCode : string) : boolean;
{PROMISES: returns false if rxmIngredientsCache is located on a made-up record.}
begin
  IngredientCode := CorrectCode(IngredientCode,8);
  if not rxmIngredientsCache.Active then
    rxmIngredientsCache.Open;
  if not rxmIngredientsCache.Locate(rxmIngredientsCacheIngredient.FieldName,IngredientCode,[]) then
  begin
    if not pvtblIngredients.Active then pvtblIngredients.Open;
    rxmIngredientsCache.Insert;
    if PvTableLocateUsingIndex(pvtblIngredients, ING_Ingredient, IngredientCode, []) then  // found record, now add to memory copy
      DatasetCopyValues(rxmIngredientsCache,pvtblIngredients)
    else
    begin
      rxmIngredientsCacheIngredient.AsString := IngredientCode;
      rxmIngredientsCacheDescription.AsString := 'Code not found';
    end;
    rxmIngredientsCache.Post;
  end;
  Result := rxmIngredientsCacheDescription.AsString <> 'Code not found';
end;

function TdmformixBase.SynchRecipeCacheWithCode(RecipeCode : string) : boolean;
{PROMISES: returns false if rxmRecipeCache is located on a made-up record.}
begin
  RecipeCode := CorrectCode(RecipeCode,8);
  if not rxmRecipeCache.Active then
    rxmRecipeCache.Open;
  if not rxmRecipeCache.Locate(rxmRecipeCacheRecipe_Code.FieldName,RecipeCode,[]) then
  begin
    if not pvtblRecipeHeader.Active then pvtblRecipeHeader.Open;
    rxmRecipeCache.Insert;
    if pvtblRecipeHeader.Locate(RH_RecipeCode, RecipeCode, []) then  // found record, now add to memory copy
      DatasetCopyValues(rxmRecipeCache,pvtblRecipeHeader)
    else
    begin
      rxmRecipeCacheRecipe_Code.AsString := RecipeCode;
      rxmRecipeCacheDescription.AsString := 'Code not found';
    end;
    rxmRecipeCache.Post;
  end;
  Result := rxmRecipeCacheDescription.AsString <> 'Code not found';
end;


function TdmFormixBase.RestorePositionOfWorkingTables(OrderNo : integer; OrderNoSuffix : integer;
                                                      OrderLineNo : integer) : boolean;
var IngredientCode : string;
begin
  Result := false;
  if (pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger <> OrderNo)
  or (pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger <> OrderNoSuffix) then
  begin
    if not pvtblOrderHeader.Locate(OH_OrderNo+';'+OH_OrderNoSuffix,
                                   VarArrayOf([OrderNo,OrderNoSuffix]), []) then
      EXIT;
  end;
  if (pvtblOrderLine.FieldByName(OL_OrderNo).AsInteger <> OrderNo)
  or (pvtblOrderLine.FieldByName(OL_OrderNoSuffix).AsInteger <> OrderNoSuffix)
  or (pvtblOrderLine.FieldByName(OL_LineNo).AsInteger <> OrderLineNo) then
  begin
    if not pvtblOrderLine.Locate(OL_OrderNo+';'+OL_OrderNoSuffix+';'+OL_LineNo,
                                 VarArrayOf([OrderNo,OrderNoSuffix,OrderLineNo]),[]) then
      EXIT;
  end;
  IngredientCode := CorrectCode(pvtblOrderLine.FieldByName(OL_Ingredient).AsString,8);
  if (pvtblIngredients.FieldByName(ING_Ingredient).AsString <> IngredientCode) then
  begin
    if not PvTableLocateUsingIndex(pvtblIngredients, ING_Ingredient, IngredientCode, []) then
      EXIT;
  end;
  Result := true;
end;

end.

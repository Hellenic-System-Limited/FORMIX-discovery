unit udmFormix;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, BaseDM, HSLSecurity, DB, pvtables, btvtables, uStdUtl, RxMemDS,
  uLabelDesignUtils, ufrmPrinterUtils, uTermDialogs, uFopsLib, ufrmFormixStdEntry, udmFops,
  udmFormixBase, uBaseTablesCTV,
  uCustomHSLSecurity,uFormixTerminalQAClient, FileInfo, uTFLog;

const
  FormixDBFolderVersion = FormixDatabaseFolderV8;

const
    {Std}
    SpaceString = '                                                             ';
    STX  = $02;
    ETX  = $03;
    EOT  = $04;

type
  TagType = record
     Name : string[15];
     ID   : INTEGER;
  end;

const
  qamode_MEAT      = 'MEAT';
  qamode_SEASONING = 'SEASONING';
  qamode_WATER     = 'WATER';

const
  {Label Consts}
  IngredientInfo : STRING[15] = '*INGREDIENTINFO';
  NumSingleTags  = 23;
  SingleTags : array [1..NumSingleTags] of TagType =
      ((Name:'*ORDERNO'       ;ID: 1),
       (Name:'*INGREDIENTREF' ;ID: 2),
       (Name:'*TICKET'        ;ID: 3),
       (Name:'*TOTWEIGHT'     ;ID: 4),
       (Name:'*USER'          ;ID: 5),
       (Name:'*BATCHNO'       ;ID: 6),
       (Name:'*LOTNO'         ;ID: 7),
       (Name:'*RECIPENO'      ;ID: 8),
       (Name:'*DATE'          ;ID: 9),
       (Name:'*TIME'          ;ID:10),
       (Name:'*MIXNO'         ;ID:11),
       (Name:'*CONTAINERNO'   ;ID:12),
       (Name:'*MIXCOMPLETE'   ;ID:13),
       (Name:'*MIXRANGE'      ;ID:14),
       (Name:'*CONTRANGE'     ;ID:15),
       (Name:'*TEXT1'         ;ID:16),
       (Name:'*TEXT2'         ;ID:17),
       (Name:'*RECIPENAME'    ;ID:18),
       (Name:'*INGREDIENTDESC';ID:19),
       (Name:'*MAXLIFE'       ;ID:20),
       (Name:'*PORDER'        ;ID:21),
       (Name:'*TRACEDESC'     ;ID:22),
       (Name:'*RECIPEPLU'     ;ID:23));

type
  TSetOfBarcodeLengths = set of byte;
  TdmFormix = class(TdmFormixBase)
    dsOrderHeader: TDataSource;
    rxmMixContents: TRxMemoryData;
    rxmMixContentsOrderNo: TIntegerField;
    rxmMixContentsRevision: TIntegerField;
    rxmMixContentsIngredient: TStringField;
    rxmMixContentsWeightDone: TFloatField;
    rxmMixContentsWeightReq: TFloatField;
    rxmMixContentsContsDone: TIntegerField;
    rxmMixContentsContsReq: TIntegerField;
    rxmMixContentsRecNo: TIntegerField;
    rxmMixContentsUseBy: TStringField;
    rxmMixContentsPurchOrder: TStringField;
    rxmMixContentsIngredientDesc: TStringField;
    rxmMixContentsUseByInternal: TStringField;
    memtabWarningsOverriden: TRxMemoryData;
    memtabWarningsOverridenOverrideType: TIntegerField;
    memtabWarningsOverridenOverrideUser: TStringField;
    rxmPossibleProducts: TRxMemoryData;
    rxmPossibleProductsCode: TStringField;
    rxmPossibleProductsDescription: TStringField;
    rxmPossibleGroups: TRxMemoryData;
    rxmPossibleGroupsCode: TStringField;
    memtabWarningsOverridenSrcConcessionNo: TIntegerField;
    procedure DataModuleCreate(Sender: TObject);
    procedure dsOrderHeaderDataChange(Sender: TObject; Field: TField);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
    fMixRpt : PTextFileLogger;
    fCurrentUser: String;
    fCurrentScale: Integer;
    fBatchPrefixForFopsStr : string;
    fAutoBatchFormat       : string;
    fFullContainerHighTol  : double;
    fCommBufferName        : string;
    fRecordSource          : boolean;
    fIngredientCosting     : boolean;
    fPrintTranTicket       : boolean;
    fSendFopsIssueTrans    : boolean;
    fNoOfTranTickets       : integer;
    fMachineId             : integer;
    fLabelFormat           : string;
    fLabelFileName         : string;
    fDirectPrinterProtocol : boolean;{Printer doesnt use HSL program to receive data}
    fAddMixToFopsStock     : boolean;
    fAddToFormixStock      : boolean;
    fRoundWeights          : boolean;
    fRemoteOverrides       : boolean;
    fAskForLifeDtConcessionNo : boolean;
    fSetOfLazenbyNavBarLengths : TSetOfBarcodeLengths;
    fNavBarcodeHasProdFirst: boolean;
    fNavBarcodeDtPos       : integer;
    fLastOrderNumber       : String;
    fLastMixNumber         : Integer;

    MixLabelBatchNoStr : string;
    MixLabelLotNoStr   : string;


    function GetRejectionDesc(ForReason: TOverrideType) : string;
    function GetGlobalBatchNumber: String;
    procedure SetGlobalBatchNumber(const WithString: String);
    procedure LogMixProgress(const MsgAboutAMix : string);

  public
    { Public declarations }
    CurrentOrderNo,
    CurrentSuffix,
    CurrentMixNo,
    CurrentLineNo,
    CurrentContNo: Integer;
    CurrentCompensatedBatchMixWt: Double;
    CurrentIngredientLot: String;
    CurrentBatch : string;
    UsePreCalcedCompensatedBatchMixWt: Boolean;
    SelectedLineIsAutoWeigh : boolean;
    fOneScanStr: String;
    SourceBarcode: String;
    SourceItemLabelBarcode : string;
    CurrSourceWtKg,
    OrigSourceWtKg :Double;
    SourceItemCheckedAt : TDateTime;
    SourceWtCheckBypassReason : string;
    CurrIngredientTemperatureStr : string;
    CurrIngredientTempEntered : boolean;
    UseSourceWt    : Boolean;
    SourceLifeJDay   : Integer;
    SourceLotCode : string;
    SourceItemFopsMcNo  : integer;
    SourceItemFopsSerNo : integer;
    SourceProdCode : string;
    CurrentUserIsIdle : boolean;
    QAClientSession : TTerminalQAClientSession;
    fPrepAreaFilter : string;
    fShowMixesDoneforArea  : boolean;
    fUserTimeoutMilliSecs  : integer;
    fProgramStaysOnTop     : boolean;
    fModeIssue             : boolean;

    fAllowBarcodeLength : integer;
    fQAAtMixStart : boolean;
    fNoAutoCancelOfTares : boolean;
    fUseOneScanOnly      : boolean;
    fAllowKeyedBarcode   : boolean;
    fEnquireForBatchNo   : boolean;
    fEnquireForLotNo     : boolean;
    fCopyFopsTranSourceAsLot:boolean;
    fAllowWtAboveSourceWt: boolean;
    fPromptForSource     : boolean;
    fSourceOptional      : boolean;
    fPromptForTemperature: boolean;
    fIngredientsInFops6  : boolean;
    fAllowProductOverride: boolean;
    fAcceptLabelWeight   : boolean;
    fAllowSixDigitBarcode: boolean;
    fAllowPOBarcode      : boolean;
    fAllowTranNotFound   : boolean;
    fPromptForBatchOnOrd : boolean;
    fPromptForBatchOnMix : boolean;
    fNoOfMixTickets      : integer;
    fIntakeMid           : string;

    function MakeConnection : Boolean; override;
    procedure RefreshRegistryCache; override;

    function IsThisLineCompleteForCurrMix(WghsDoneForCurrMix: Integer;
                                          WtDoneForCurrMix  : Double): Boolean;
    function CalcLineGrossWtReqdForCurrMix: Double;
    function CalcLineWeighingsReqdForCurrMix: Longint;
    procedure CalcWOLineTolWts(TargetWeight   : DOUBLE;{ in current container }
                               MixType        : TMixType;
                               LineWtRequired : DOUBLE;{ in current mix }
                               LineWtDone     : DOUBLE;{ in current mix }
                               var LowestWt   : DOUBLE;
                               var HighestWt  : DOUBLE);
    function  CreateTransaction(ActualWt    : DOUBLE;
                                ActualProcessType : TProcessTypes
                                {ManualWtEntry: BOOLEAN}): Boolean;

    function  GetWeighingsPerContainer: Integer;
    function  GetCurrentContainerNo: Integer;
    function  GetContainersForIngredient: Integer;
    function  GetCurrentMachineId: Integer;
    function  GetCurrentRunNumber: Integer;
    function  GetNextRunNumber: Integer;
    function  GetBatchStrForFormixTran : String; {batch number to be used by transaction}
    function  WeightOkForTran(ActNetWt  : Double;
                              IngType   : TProcessTypes;
                              LowTolWt,
                              HighTolWt : Double;
                              {by user (partial wt button)}
                              LowTolDisabled : Boolean): Boolean;
    procedure AddWeightToMixRecord(ToMixNo      : Word;
                                   WeightToAdd  : Double;
                                   IsLastWtForKeyIngredient: Boolean);
    function  QAHasBeenDoneForMixInPrepArea(MixNo : integer) : boolean;
    function  SetQAStatusOnMixRecordTo(Complete : boolean; MixNo : integer) : boolean;
    procedure RunQAChecksForMix;
    procedure AddTranToTotalsFile(ForDate: Integer;ForBatch,ForLot,ForIngredient: String;
                                  ForWeight: Double);
    procedure AddToCostFile;
    function  GetLotNumber: String;
//    procedure SetLotNumber(UseLotNumber: String);
    procedure GetAreaQAStatusOnMixes(var QADoneOnCurrentMix  : boolean;
                                 var NoOfMixesWithQADone : integer;
                                     ForOrder, ForSuffix,  MixNoOfCurrentMix: Integer);
    procedure GetCompleteInAreaStatForMixes(var CurrMixCompInArea : boolean;
                                            var NoOfMixesCompInArea : integer;
                                            MixNoOfCurrentMix: Integer);
    procedure PrintCurrentTransactionTicket;
    function  CalcMixStatus(var CompleteForPrepArea : boolean;
                            var Complete            : boolean): Boolean;
    function  IsMixComplete(ForOrder: Integer; ForSuffix: Integer;
                            ForMixNo: Integer): Boolean;
    function  GetMixLabelBarcode(FopsPluNumber : integer) : String;
    procedure PrintMixTicket(ForMixNo: Integer);
    procedure FillOutLabelData(UsePvtblTransactionsDetails : boolean;
                               MixNo : integer;
                               {FDL: Boolean;}
                               {ForLabelName: Array of Char;}
                               ForLabelFormat: String;
                               CurrentTicket, TotalTickets,
                               IngredientNumber, IngredientsPerTicket: Integer;
                               {var ForLabelFile: ListRecFile;}
                               const LabelVarDataItems : TArrayOfLabelVarDataItem;
                               var ReturnLabelData: TStrings);
    procedure PrintOutLabel({FDL: Boolean;} FromLabelData: TStrings);
    function  IsValidUser(ForUser, ForPassword: String): Boolean;
    procedure PrintAllMixTickets;
    function  FindNextWipLineForTerminal(StartLineNo: Integer): Integer;
    function  WeighInDiffContainer(NoOfContainersReqd: Integer): Boolean;
    procedure MarkMixCompleteIfNecess;
//    function  AllLinesCompleteForCurrentMix: Boolean;
    procedure AddStockRecord(ForIngredient: String; AddWeight: Double);
    function  SetCurrMixNoToAnUnfinishedMix: TFindMixResult;
    procedure PreCalcCompensatedBatchMixWt;
    procedure CancelPreCalcCompensatedBatchMixWt;
    function  GetContainerNumber: Integer;
//    procedure DelayCurrentMix;
    procedure ClearSourceItemDetails;
    procedure ClearWeighingDetails;
    procedure ClearSelectedLineDetails;
    function  GetExpandedSourceBarcode : string;
    function  SourceBarcodeRelatesToAFopsTran : boolean;
    function  BarcodeIsAMixBarcode(const Barcode : string) : boolean;
    function  GetOrderNoFromMixBarcode(const Barcode : string) : integer;
    function  GetOrdNoSuffixFromMixBarcode(const Barcode : string) : integer;
    function  GetMixNoFromMixBarcode(const Barcode : string) : integer;
    function  BarcodeIsACranswickNavBarcode(const Barcode : string) : boolean;
    function  SourceBarcodeIsACranswickNavBarcode : boolean;
    function  GetUsersAccessLevel(ForUser: String): Integer;
    function  GetCorrectMixNo: Integer;
    procedure SendCommandToFops(const TransStr : string);
    function  MakeAPdcuIssueCommandStr(const ForBarcode : string; BatchNo : integer) : string;
    function  GetFops6TranStr(Weight  : DOUBLE;
                              FullIssueOffStock : BOOLEAN) : string;
    function  GetScaleDisplayDecimalPlaces(ScaleNo: Integer) : integer;
    function  SetScaleDisplayDecimalPlaces(ScaleNo: Integer ;NoOfDecimalPlaces : integer) : boolean;
    function GetLastUsedScale: Integer;
    procedure SetLastUsedScale;
    function  GetScaleIncrement(ScaleNo: Integer) : double;
    function  SetScaleIncrement(ScaleNo: Integer; WtIncrement : double) : boolean;
//    function GetScaleINISection(ScaleNo: Integer): String;
    function GetScaleMaxWeight(ScaleNo: Integer): Double;
    procedure SetScaleMaxWeight(ScaleNo: Integer; MaxWeight: Double);
    function GetScaleIPConfig(ScaleNo: Integer): String;
    function GetScaleSerialConfig(ScaleNo: Integer): String;
    function GetScaleType(ScaleNo: Integer): Integer;
    procedure SetScaleIPConfig(ScaleNo: Integer; ConfigStr: String);
    procedure SetScaleSerialConfig(ScaleNo: Integer; ConfigStr: String);
    procedure SetScaleType(ScaleNo, ScaleType: Integer);
    procedure SetScaleModel(ScaleNo, ScaleModel: Integer);
    function GetScaleModel(ScaleNo: Integer): Integer;
    function RoundWtUpToNextScaleInc(Weight: DOUBLE) : DOUBLE;
    procedure AdjustTolToScaleRes(var LowWt, HighWt : DOUBLE);
    function  GetCurrentUser: String;
    procedure SetCurrentUser(const ToUserCode : string);
    procedure CheckUserIsLoggedIn;
    function IngredientIsInPrepArea(LocatedIngredientDataset : TDataSet): Boolean;
    function GetQAModeForPrepArea : string;
    function GetPvtblMixTotalFieldForPrepAreaQA : TField;
    function EditGlobalBatchAndLot : Boolean;
    function GetLotNoForIngredient(MachineID: Word; IngredientCode: String): String;
    procedure SetLotNumberForIngredient(MachineID: Word; IngredientCode, LotNo: String);
    function PromptForFopsUserThatHasRights(ToSecurityToken : TSecurityToken;
                                            WithRights : TRightsOptions) : string;
    function PromptForOverrideUserApproval(ForReason : TOverrideType;
                                           const ErrDetail : string) : boolean;
    function OverrideExistsForSourceItem(ForReason : TOverrideType;
                                         ForOrdNo  : integer;
                                         const ForIngredient : string;
                                         MinWtUsage : double;
                                         const ErrDetail     : string) : boolean;
    function CurrentFullOrderNumberAsString: String;
    function GetProdCodeFromCranswickNavBarcode(const NavBarcode : string) : string;
    function GetDateFromCranswickNavBarcode(const NavBarcode : string; var ADateTime : TDateTime) : boolean;
    function GetLotCodeFromCranswickNavBarcode(const NavBarcode : string) : string;
    property CurrentScale : Integer read fCurrentScale write fCurrentScale;
    property SendFopsIssueTrans : boolean read fSendFopsIssueTrans;
    property BatchPrefixForFops: String read fBatchPrefixForFopsStr;
    property AutoBatchFormat: string read fAutoBatchFormat;
    property SetOfLazenbyNavBarLengths: TSetOfBarcodeLengths read fSetOfLazenbyNavBarLengths;
    property NavBarcodeHasProdFirst : boolean read fNavBarcodeHasProdFirst;
    property NavBarcodeDtPos : integer read fNavBarcodeDtPos;
    property LastOrderNumber: String read fLastOrderNumber write fLastOrderNumber;
    property LastMixNumber: Integer read fLastMixNumber write fLastMixNumber;
  end;

function OrderNoToString(OrderNo, OrderNoSuffix : integer) : string;

var
  dmFormix: TdmFormix;
var
  ApplicationFileInfo: TWinFileInfo = nil;


implementation
uses StrUtils,uIniUtils,DateUtils,uStdCTV, uIni, uDBFunctions,
     ufrmFormixMain, ufrmFormixProcessRecipe,
     ufrmGlobalLotBatchEdit, ufrmUserOverride,ufrmQAProgress,ufrmDisplayPrinterData,
     ufrmFormixLogin, uSecurityConsts;
{$R *.dfm}

const
  HslLibWFolderVersion = HSLLIBWFolderV1238;

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

function CompTag(const SourceTag: String; const CompareTag : String) : Boolean;
begin
 Result := StringLIComp(SourceTag,CompareTag,Length(CompareTag)) = 0;
end;

{ Get Array Position of Tag that Matches Label List Item}
{ From SingleTags Array                                 }
function FindSingleTagNumber(SourceTag : string): Integer;
var TagID : BYTE;
begin
 FindSingleTagNumber := 0;
 for TagID := 1 to NumSingleTags do
  begin
   if CompTag(SourceTag,SingleTags[TagID].Name) then
    begin
     FindSingleTagNumber := SingleTags[TagID].ID;
     Break;
    end;
  end;
end;
(*
procedure SetLabelName(ForLabelFormat: String; var ForLabelName: Array of CHAR);
begin
 {Set name like this otherwise [0] ends up wrong}
 ForLabelName[0] := 'H';
 ForLabelName[1] := 'S';
 ForLabelName[2] := 'L';
 ForLabelName[3] := '_';
 ForLabelName[4] := 'F';
 ForLabelName[5] := 'o';
 ForLabelName[6] := 'r';
 ForLabelName[7] := 'm';
 ForLabelName[8] := 'a';
 ForLabelName[9] := 't' ;
 ForLabelName[10] := ' ';
 ForLabelName[11] := ForLabelFormat[1];
end;
*)
function TdmFormix.MakeConnection : Boolean;
begin
  Result := inherited MakeConnection; //calls LoadRxmTermRegSettings and RefreshRegistryCache.
  if Result then //can now read files
  begin
    // cache static registry settings.
    fUserTimeOutMilliSecs := 1000 * GetTermRegInteger(r_SFXUserTimeoutSecs);
    fProgramStaysOnTop := GetTermRegBoolean(r_SFXProgramStaysOnTop);
    fCommBufferName    := GetTermRegString(r_SFXCommBufferName);
    fModeIssue := GetTermRegBoolean(r_SFXModeIssue);
    //Make sure security tokens exist in datbase by doing a GetUserRights() call.
    if (FormixIni.FopsServerName <> '') then
    begin
      HslSecurity.GetUserRights(SECTOK_FX_OVERR_SRCPROD);
      HslSecurity.GetUserRights(SECTOK_FX_OVERR_LIFEDT);
      HslSecurity.GetUserRights(SECTOK_FX_OVERR_SRCEMPTY);
      HslSecurity.GetUserRights(SECTOK_FX_MAN_WT);
    end;
  end;
end;

procedure TdmFormix.LogMixProgress(const MsgAboutAMix : string);
begin
  if Assigned(fMixRpt) then
    fMixRpt^.WriteErrorTS(MsgAboutAMix);
end;

procedure TdmFormix.RefreshRegistryCache;
{PROMISES: Reads a collection of registry settings presumed to be used reguarly by weighings for an order.}
var
  Strings : TStringList;
  i, intLen : integer;
  NavBarcodeFormat : string;
  TagPos : integer;
begin
  inherited RefreshRegistryCache;
  Registry.Active := true;
  fPrepAreaFilter        := GetTermRegString(r_PrepArea);
  if fPrepAreaFilter = '*' then
    fShowMixesDoneforArea := false
  else
    fShowMixesDoneforArea := GetTermRegBoolean(r_SFXShowMixesDoneforArea);
  fBatchPrefixForFopsStr := IntToZeroStr(GetTermRegInteger(r_BatchPrefixForFops),2);
  fAutoBatchFormat       := GetTermRegString(r_SFXAutoBatchFormat);
  fFullContainerHighTol  := GetTermRegDouble(r_FXFullContainerHighTol);
  fRecordSource          := GetTermRegBoolean(r_SFXRecordSource);
  fIngredientCosting     := GetTermRegBoolean(r_SFXINGREDIENTCOSTING);
  fPrintTranTicket       := GetTermRegBoolean(r_PrintTranTicket);
  fSendFopsIssueTrans    := GetTermRegBoolean(r_SendFopsIssueTrans);
  fNoOfTranTickets       := GetTermRegInteger(r_NoOfTranTickets);
  fMachineId             := GetTermRegInteger(r_MachineID);
  fLabelFormat           := GetTermRegString(r_FXLabFormat);
  fLabelFileName         := GetTermRegString(r_FXLabFile);
  fDirectPrinterProtocol := UpperCase(ExtractFileExt(fLabelFileName)) <> '.FDL';
  fAddMixToFopsStock     := GetTermRegBoolean(r_SFXAddMixToFopsStock);
  fAddToFormixStock      := GetTermRegBoolean(r_Stock);
  fRoundWeights          := GetTermRegBoolean(r_FXRoundWeights);
  fRemoteOverrides       := GetTermRegBoolean(r_SFXRemoteOverrides);
  fAskForLifeDtConcessionNo:= GetTermRegBoolean(r_SFXAskForLifeDtConcessionNo);
  fAllowBarcodeLength  := GetTermRegInteger(r_SFXAllowBarcodeLength);
  fQAAtMixStart        := GetTermRegBoolean(r_SFXQAAtMixStart);
  fNoAutoCancelOfTares := GetTermRegBoolean(r_SFXNoAutoCancelOfTares);
  fUseOneScanOnly      := GetTermRegBoolean(r_SFXUseOneScanOnly);
  fAllowKeyedBarcode   := GetTermRegBoolean(r_SFXAllowKeyedBarcode);
  fEnquireForBatchNo   := GetTermRegBoolean(r_EnquireForBatchNo);
  fEnquireForLotNo     := GetTermRegBoolean(r_EnquireForLotNo);
  fCopyFopsTranSourceAsLot := GetTermRegBoolean(r_CopyFopsTranSourceAsLot);
  fAllowWtAboveSourceWt:= GetTermRegBoolean(r_SFXAllowWtAboveSourceWt);
  fPromptForSource     := GetTermRegBoolean(r_SFXPromptForSource);
  fPromptForTemperature:= GetTermRegBoolean(r_SFXPromptForTemperature);
  fSourceOptional      := GetTermRegBoolean(r_SFXSourceOptional);
  fIngredientsInFops6  := GetTermRegBoolean(r_FXIngredientsInFops6);
  fAllowProductOverride:= GetTermRegBoolean(r_SFXAllowProductOverride);
  fAcceptLabelWeight   := GetTermRegBoolean(r_AcceptLabelWeight);
  fAllowSixDigitBarcode:= GetTermRegBoolean(r_SFXAllowSixDigitBarCode);
  fAllowPOBarcode      := GetTermRegBoolean(r_SFXAllowPOBarcode);
  fAllowTranNotFound   := GetTermRegBoolean(r_SFXAllowTranNotFound);
  fNoOfMixTickets      := GetTermRegInteger(r_NoOfMixTickets);
  fIntakeMid           := GetTermRegString(r_SFXIntakeMid);
  fPromptForBatchOnOrd := GetTermRegBoolean(r_PromptForBatchOnOrderChange);
  fPromptForBatchOnMix := GetTermRegBoolean(r_PromptForBatchOnMixChange);

  fSetOfLazenbyNavBarLengths := [];
  Strings := TStringList.Create;
  try
    Strings.CommaText := GetTermRegString(r_NavBarcodeLengths);
    for i := 0 to Strings.Count-1 do
    begin
      if  TryStrToInt(Strings[i], intLen)
      and (intLen > 0)
      and (intLen < 99) then
        fSetOfLazenbyNavBarLengths := fSetOfLazenbyNavBarLengths + [intLen];
    end;
  finally
    FreeAndNil(Strings);
  end;
  NavBarcodeFormat := GetTermRegString(r_NavBarcodeFormat);
  fNavBarcodeHasProdFirst := Copy(NavBarcodeFormat, 1,2) = 'PR';
  fNavBarcodeDtPos := 0;
  TagPos := Pos('DT',NavBarcodeFormat);
  if TagPos = 5 then //it's the second field
  begin
    if  TryStrToInt(Copy(NavBarcodeFormat,3,2), fNavBarcodeDtPos)
    and (fNavBarcodeDtPos > 0) then //first field length is valid.
      Inc(fNavBarcodeDtPos);//one after product code.
  end;
  Registry.Active := false;
end;


function TdmFormix.CalcLineGrossWtReqdForCurrMix: Double;
VAR
   TotWeightInMix : DOUBLE;
   WeighingsInMix : LONGINT;
   WtsInMix       : DOUBLE;
   WghsPerContainer: LONGINT;
   DummyDoneRec   : TMixLineRecord;
begin
 FillChar(DummyDoneRec, SizeOf(DummyDoneRec), 0);
 if UsePreCalcedCompensatedBatchMixWt then
   CalcIngredReqsForMixWt(CurrentCompensatedBatchMixWt,
                          DummyDoneRec,
                          TotWeightInMix,
                          WeighingsInMix,
                          WtsInMix,
                          WghsPerContainer)
 else
   CalcIngredReqsForMixWt({OrderHeader^.WOH_TargetBatchWt,}
                          CalcCompensatedBatchMixWt(GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger}),
                          DummyDoneRec,
                          TotWeightInMix,
                          WeighingsInMix,
                          WtsInMix,
                          WghsPerContainer);
 Result := TotWeightInMix;
end;


function TdmFormix.CalcLineWeighingsReqdForCurrMix: Longint;
var TotWeightInMix : DOUBLE;
    WeighingsInMix : LONGINT;
    WtsInMix       : DOUBLE;
    WghsPerContainer: LONGINT;
    DoneRec        : TMixLineRecord;
begin
 ConstructMixLineRecForOrdLine(GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger}, DoneRec);
 if UsePreCalcedCompensatedBatchMixWt then
   CalcIngredReqsForMixWt(CurrentCompensatedBatchMixWt,
                          DoneRec,
                          TotWeightInMix,
                          WeighingsInMix,
                          WtsInMix,
                          WghsPerContainer)
 else
   CalcIngredReqsForMixWt(CalcCompensatedBatchMixWt(GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger}),
                          DoneRec,
                          TotWeightInMix,
                          WeighingsInMix,
                          WtsInMix,
                          WghsPerContainer);
 CalcLineWeighingsReqdForCurrMix := WeighingsInMix;
end;

procedure TdmFormix.CalcWOLineTolWts(TargetWeight: DOUBLE;
  MixType: TMixType; LineWtRequired, LineWtDone: DOUBLE; var LowestWt,
  HighestWt: DOUBLE);
var ContainerMaxWt : DOUBLE;
begin
 if MixType = mt_EqualContainersPerMix then
  begin
   HighestWt := TargetWeight * (1+ (pvtblOrderLine.FieldByName(OL_TolerancePosPercent).AsFloat/100));
   LowestWt  := TargetWeight * (1- (Abs(pvtblOrderLine.FieldByName(OL_ToleranceNegPercent).AsFloat)/100));
   {NOTE Original Ingredient File Had Negative LowTol so abs
         used to counter this}
   if LowestWt < 0.0 then LowestWt := 0.0;
  end
 else
  begin
   { On last container high and low tolerance needs to reflect
     total mix requirement for ingredient }
   HighestWt := LineWtRequired * (1+ (pvtblOrderLine.FieldByName(OL_TolerancePosPercent).AsFloat/100));
   HighestWt := HighestWt - LineWtDone;
   LowestWt  := LineWtRequired * (1- (Abs(pvtblOrderLine.FieldByName(OL_ToleranceNegPercent).AsFloat)/100));
   LowestWt  := LowestWt - LineWtDone;

   if  (TargetWeight > 0.0)
   and (TargetWeight < LowestWt) then { another container expected afterwards }
    begin
     if CompareWts(fFullContainerHighTol,0.0) > 0 then
       ContainerMaxWt := TargetWeight *
                          (1+ (fFullContainerHighTol/100))
     else
       ContainerMaxWt := TargetWeight * (1+ (pvtblOrderLine.FieldByName(OL_TolerancePosPercent).AsFloat/100));

     { Providing container max wt doesnt take wt over mix requirement }
     { use container tolerance (FullContainerHighTol might be large)  }
     if ContainerMaxWt < HighestWt then
       HighestWt := ContainerMaxWt;

     { apply low tol to container wt }
     { Partial weigh button can be used if this is to tight }
     LowestWt  := TargetWeight * (1- (Abs(pvtblOrderLine.FieldByName(OL_ToleranceNegPercent).AsFloat)/100));
    end;
   if HighestWt < 0.0 then HighestWt := 0.0;
   if LowestWt < 0.0 then LowestWt := 0.0;

  end;
end;

procedure TdmFormix.SendCommandToFops(const TransStr : string);
var SchDateTime : TDateTime;
begin
  if not Assigned(dmFops) then EXIT;
  SchDateTime := Now - 1{same time yesterday};
  with dmFops.pvtblCommBuff do
  begin
    Insert;
    FieldByName(ComBuf_DestinationId).AsString := fCommBufferName;
    FieldByName(ComBuf_ScheduleDate).AsString := FormatDateTime('YYYY-MM-DD',SchDateTime);
    FieldByName(ComBuf_ScheduleTime).AsString := FormatDateTime('HH:NN:SS',SchDateTime);
    FieldByName(ComBuf_ScheduleNo).AsInteger := 1;
    FieldByName(ComBuf_IVersion).AsInteger := 1;
    FieldByName(ComBuf_SourceId).AsString := 'FORMIX';
    FieldByName(ComBuf_F6Transaction).AsString := TransStr;
    Post;
  end;
end;

function TdmFormix.CreateTransaction(ActualWt: DOUBLE;
  ActualProcessType: TProcessTypes {;ManualWtEntry: BOOLEAN}): Boolean;
var MixLRec: TMixLineRecord;
//    WrkLotNo : String;
    IngredientCompInMix: Boolean;
    HoldMID, HoldSerial: Integer;
    HoldBatchStr : string;
//    LotNoOk: Boolean;
    SourceId : integer;
    ContainerNo : integer;
    LogDateTime : TDateTime;
begin
 Result := FALSE;
// LotNoOk:= FALSE;
//  WrkLotNo := TfrmFormixStdEntry.GetStdStringEntry('Enter Lot Number','Lot Number',8,LotNoOk,FALSE);
//  if not LotNoOk then Exit;
 pvtblTransactions.Database.StartTransaction;
 try
  SourceId := 0;
  if  (not NowtButSpace(SourceBarcode))
  and fRecordSource then
  begin
    with pvtblSourceCodes do
    begin
      if not Locate(SC_Code+';'+SC_Type, VarArrayOf([TrimRight(SourceBarcode),'']),[]) then
      begin
        Insert;
        FieldByName(SC_Code).AsString := TrimRight(SourceBarcode);
        FieldByName(SC_Type).AsString := '';
        Post;
      end;
      SourceId := FieldByName(SC_ID).AsInteger;
    end;
  end;
  ContainerNo := GetContainerNumber;//note: reads trans file
  LogDateTime := Now;
  with pvtblTransactions do
  begin
    Append;
    FieldByName(TRN_Ingredient).AsString := Copy(pvtblOrderLine.FieldByName(OL_Ingredient).AsString+SpaceString,1,8);
    FieldByName(TRN_OrderNo).AsInteger   := pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger;
    FieldByName(TRN_RecipeNo).AsString   := Copy(pvtblOrderHeader.FieldByName(OH_RecipeCode).AsString+SpaceString,1,8);
    FieldByName(TRN_MID).AsInteger       := GetCurrentMachineId;
    FieldByName(TRN_SerialNo).AsInteger  := GetNextRunNumber;
    FieldByName(TRN_Time).AsString       := FormatDateTime('HH:NN',LogDateTime);
    FieldByName(TRN_Date).AsInteger      := DateToJulianValue(DateOf(LogDateTime));
    FieldByName(TRN_OrderLineNo).AsInteger:= pvtblOrderLine.FieldByName(OL_LineNo).AsInteger;
    FieldByName(TRN_Reserved2).AsInteger := 0;
    FieldByName(TRN_WeightInMix).AsFloat := ActualWt;
                                  {$IFDEF LAZENBYS}      not required they use OneScan option
                                  IntToZeroStr((pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger MOD 10000), 4) +
                                  IntToZeroStr((CurrentMixNo MOD 100), 2),
                                  {$ELSE}
    FieldByName(TRN_BatchNo).AsString    := GetBatchStrForFormixTran;
                                  {$ENDIF}
    FieldByName(TRN_LotNo).AsString      := Copy(GetLotNumber+SpaceString,1,14);
    FieldByName(TRN_ContainerNo).AsInteger := ContainerNo;
    FieldByName(TRN_MixNo).AsInteger     := CurrentMixNo;//pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger,
    FieldByName(TRN_Status).AsInteger    := TRNStatusActive;
    FieldByName(TRN_OrderNoSuffix).AsInteger := pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger;
    FieldByName(TRN_UserId).AsString     := Copy(GetCurrentUser+SpaceString,1,8);
    FieldByName(TRN_CalcPostMixWt).AsFloat := (ActualWt*pvtblOrderLine.FieldByName(OL_MixingYield).AsFloat)/100;
    FieldByName(TRN_WeightOnScale).AsFloat := ActualWt;
    if FindField(TRN_SourceCodeId) <> nil then
      FieldByName(TRN_SourceCodeId).AsInteger := SourceId;
    if FindField(TRN_TempChecked) <> nil then //database at v1.063 or later
    begin
      if CurrIngredientTempEntered then
      begin
        FieldByName(TRN_TempChecked).AsInteger := 1;
        FieldByName(TRN_Temperature).AsFloat := StrToFloat(CurrIngredientTemperatureStr);
      end
      else
      begin
        FieldByName(TRN_TempChecked).AsInteger := 0;
        FieldByName(TRN_Temperature).AsFloat := 0.0;
      end;
    end
    else
      FieldByName(TRN_Reserved).AsString   := '';
    Post;
  end;

  HoldMID    := pvtblTransactions.FieldByName(TRN_MID).AsInteger;
  HoldSerial := pvtblTransactions.FieldByName(TRN_SerialNo).AsInteger;
  HoldBatchStr := pvtblTransactions.FieldByName(TRN_BatchNo).AsString;
  {Now update order header and line}
  pvtblOrderLine.Edit;
  pvtblOrderLine.FieldByName(OL_TotalWeightDone).AsFloat  := pvtblOrderLine.FieldByName(OL_TotalWeightDone).AsFloat+
                                                           ActualWt;
  pvtblOrderLine.FieldByName(OL_TotalTransDone).AsInteger := pvtblOrderLine.FieldByName(OL_TotalTransDone).AsInteger+
                                                           1;
  pvtblOrderLine.Post;

  {Now update mix totals}
  IngredientCompInMix := FALSE;
  ConstructMixLineRecForOrdLine(CurrentMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger},MixLRec);
  {Update Mix Status Record For The Current Mix}
  IngredientCompInMix := IsThisLineCompleteForCurrMix(MixLRec.ML_WghsDone,MixLRec.ML_WtDone);
//  ConstructMixLineRecForOrdLine(pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger,MixLRec);

  AddWeightToMixRecord(CurrentMixNo,{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger,}
                       ActualWt,
                       (IngredientCompInMix AND pvtblOrderLine.FieldByName(OL_KeyLine).AsBoolean));

  IngredientCompInMix := FALSE;
  ConstructMixLineRecForOrdLine(CurrentMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger},MixLRec);
  IngredientCompInMix := IsThisLineCompleteForCurrMix(MixLRec.ML_WghsDone,MixLRec.ML_WtDone);
  {Update order header after mixtotal to avoid deadlock with MarkMixAsCompleteIfNecess()}
  {Relocate the header in to stop error 88}
  if pvtblOrderHeader.Locate(OH_OrderNo+';'+OH_OrderNoSuffix,
                             varArrayOf([pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                         pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger]),[]) then
   begin
    pvtblOrderHeader.Edit;
    pvtblOrderHeader.FieldByName(OH_TotalWeightDone).AsFloat := pvtblOrderHeader.FieldByName(OH_TotalWeightDone).AsFloat+
                                                              ActualWt;
    pvtblOrderHeader.Post;
   end;

  if IngredientCompInMix then
    frmFormixProcessRecipe.SetProcessStepToCompleted;

  {Update other files}
  AddTranToTotalsFile(DateToJulianValue(DateOf(LogDateTime)),HoldBatchStr,
                      Copy(GetLotNumber+SpaceString,1,14),
                      Copy(pvtblOrderLine.FieldByName(OL_Ingredient).AsString+SpaceString,1,8),
                      ActualWt);
  if fIngredientCosting then
    AddToCostFile;
  pvtblTransactions.Database.Commit;
  if pvtblTransWarnings.Exists then
   begin
    if memtabWarningsOverriden.RecordCount > 0 then
     begin
      memtabWarningsOverriden.First;
      while not memtabWarningsOverriden.eof do
       begin
        try
         pvtblTransWarnings.Active := true;
         pvtblTransWarnings.Append;
         pvtblTransWarnings.FieldByName(TWN_MID).AsInteger := HoldMid;
         pvtblTransWarnings.FieldByName(TWN_SerialNo).AsInteger := HoldSerial;
         pvtblTransWarnings.FieldByName(TWN_Warning).AsString :=
                                GetRejectionDesc(TOverrideType(memtabWarningsOverridenOverrideType.AsInteger))+
                                ' Overriden by '+memtabWarningsOverridenOverrideUser.AsString;
         DatasetSetInteger(pvtblTransWarnings, TWN_SrcConcessionNo,
                           memtabWarningsOverridenSrcConcessionNo.AsInteger);
         pvtblTransWarnings.FieldByName(TWN_Reserved).SetData(@ZEROS_64BYTES);
         pvtblTransWarnings.Post;
        except
         on E:Exception do
           TermMessageDlg('Failed to record warning. '+E.Message, mtError,[mbOk],0);
        end;
        if  fAskForLifeDtConcessionNo and Assigned(dmFops)
        and (memtabWarningsOverridenSrcConcessionNo.AsInteger > 0) then
        begin
          try
            dmFops.AddToUsedWtOnProdConcession(memtabWarningsOverridenSrcConcessionNo.AsInteger,
                                               ActualWt);
          except
            on E:Exception do
              TermMessageDlg('Failed to add weight used to Concession record. '+E.Message, mtError,[mbOk],0);
          end;
        end;

        memtabWarningsOverriden.Next;
       end;
     end;
    if (SourceWtCheckBypassReason <> '') then
     begin
      try
       pvtblTransWarnings.Active := true;
       pvtblTransWarnings.Append;
       pvtblTransWarnings.FieldByName(TWN_MID).AsInteger := HoldMid;
       pvtblTransWarnings.FieldByName(TWN_SerialNo).AsInteger := HoldSerial;
       pvtblTransWarnings.FieldByName(TWN_Warning).AsString :=
                              'Weight in stock disregarded, '+ SourceWtCheckBypassReason+
                              ' (Wt in stock = '+DoubleToStr(CurrSourceWtKg,1,2)+
                              ' as at '+FormatDateTime('HH:mm dd/mm/yy',SourceItemCheckedAt)+')';
       DatasetSetInteger(pvtblTransWarnings, TWN_SrcConcessionNo, 0);
       pvtblTransWarnings.FieldByName(TWN_Reserved).SetData(@ZEROS_64BYTES);
       pvtblTransWarnings.Post;
      except
       on E:Exception do
         TermMessageDlg('Failed to record warning. '+E.Message, mtError,[mbOk],0);
      end;
     end;
   end;
  if  fPrintTranTicket
  and (not dmFormix.SelectedLineIsAutoWeigh) then
   begin
    pvtblTransactions.IndexName := 'ById';
    pvtblTransactions.Locate(TRN_MID+';'+TRN_SerialNo,VarArrayOf([HoldMid,HoldSerial]),[]);
    PrintCurrentTransactionTicket;
    {now set it back}
    pvtblTransactions.IndexName := 'ByOrderMixLine';
    ConstructMixLineRecForOrdLine(CurrentMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger},MixLRec);
   end;
  Result := TRUE;
  //OverrideUser := '';
 except
  on E:Exception do
   begin
    pvtblTransactions.Database.Rollback;
    Result := FALSE;
    if EPvDBEngineError(E).Errors[EPvDBEngineError(E).ErrorCount-1].NativeError = 5 then
      TermMessageDlg('Duplicate Transaction ID'+#13#10+
                     'Check Machine Id and Run Number',mtError,[mbOk],0)
    else TermMessageDlg(E.Message,mtError,[mbOk],0);
    //OverrideUser := '';
    pvtblSourceCodes.Cancel;
    pvtblTransactions.Cancel;
    pvtblOrderLine.Cancel;
    pvtblOrderHeader.Cancel;
    pvtblMixTotal.Cancel;
    if Assigned(dmFops) then
      dmFops.pvtblCommBuff.Cancel;
    pvtblIngredientUsage.Cancel;
    pvtblCost.Cancel;
   end;
 end;
 if  Result
 and (dmFops <> nil)
 and fSendFopsIssueTrans
 and (not SourceBarcodeIsACranswickNavBarcode) then  //Exclude NAV 14 Digit barcodes
 begin
   try
     SendCommandToFops(GetFops6TranStr(ActualWt,FALSE));
     CurrSourceWtKg := CurrSourceWtKg - ActualWt;
   except
     on E: exception do
       TermMessageDlg('Part-Issue Stock command not sent to FOPS'+#13#10+E.Message,mtError,[mbOk],0);
   end;
 end;
end;

function TdmFormix.GetContainersForIngredient: Integer;
var TotWeightInMix : DOUBLE;
    WeighingsInMix : LONGINT;
    WtsInMix       : DOUBLE;
    WghsPerContainer: LONGINT;
    DoneRec        : TMixLineRecord;
begin
 ConstructMixLineRecForOrdLine(GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger}, DoneRec);
 if UsePreCalcedCompensatedBatchMixWt then
   CalcIngredReqsForMixWt(CurrentCompensatedBatchMixWt,
                          DoneRec,
                          TotWeightInMix,
                          WeighingsInMix,
                          WtsInMix,
                          WghsPerContainer)
 else
   CalcIngredReqsForMixWt(CalcCompensatedBatchMixWt(GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger}),
                          DoneRec,
                          TotWeightInMix,
                          WeighingsInMix,
                          WtsInMix,
                          WghsPerContainer);
 if WghsPerContainer > 0 then
   Result := (WeighingsInMix DIV WghsPerContainer)
 else
   Result := 0;
end;

function TdmFormix.GetCurrentContainerNo: Integer;
{ note: for segregated ingredients the container number
        starts from one for each ingredient.
        ie. there's multiple containers with the same number.
}
var TotWeightInMix : DOUBLE;
    WeighingsInMix : LONGINT;
    WtsInMix       : DOUBLE;
    WghsPerContainer: LONGINT;
    DoneRec        : TMixLineRecord;
    ContsDone : LONGINT;
begin
 ContsDone := 0;
 ConstructMixLineRecForOrdLine(GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger}, DoneRec);
 if UsePreCalcedCompensatedBatchMixWt then
   CalcIngredReqsForMixWt(CurrentCompensatedBatchMixWt,
                          DoneRec,
                          TotWeightInMix,
                          WeighingsInMix,
                          WtsInMix,
                          WghsPerContainer)
 else
   CalcIngredReqsForMixWt(CalcCompensatedBatchMixWt(GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger}),
                          DoneRec,
                          TotWeightInMix,
                          WeighingsInMix,
                          WtsInMix,
                          WghsPerContainer);
 if WghsPerContainer > 0 then { no divide by 0 problems }
   ContsDone := (DoneRec.ML_WghsDone DIV WghsPerContainer);
 Result := ContsDone + 1;
end;

function TdmFormix.GetCurrentMachineId: Integer;
begin
 Result := 0;
 Result := fMachineId;
end;

function TdmFormix.GetCurrentRunNumber: Integer;
begin
 Result := 0;
 Result := GetTermRegInteger(r_RunNumber);
end;


function TdmFormix.GetWeighingsPerContainer: Integer;
var TotWeightInMix : DOUBLE;
    WeighingsInMix : LONGINT;
    WtsInMix       : DOUBLE;
    WghsPerContainer: LONGINT;
    DoneRec        : TMixLineRecord;
begin
 ConstructMixLineRecForOrdLine(GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger}, DoneRec);
 if UsePreCalcedCompensatedBatchMixWt then
   CalcIngredReqsForMixWt(CurrentCompensatedBatchMixWt,
                          DoneRec,
                          TotWeightInMix,
                          WeighingsInMix,
                          WtsInMix,
                          WghsPerContainer)
 else
   CalcIngredReqsForMixWt(CalcCompensatedBatchMixWt(GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger}),
                          DoneRec,
                          TotWeightInMix,
                          WeighingsInMix,
                          WtsInMix,
                          WghsPerContainer);
 Result := WghsPerContainer;
end;

function TdmFormix.IsThisLineCompleteForCurrMix(
  WghsDoneForCurrMix: Integer; WtDoneForCurrMix: Double): Boolean;
var LineWtRequired,
    LowestLineWt,
    HighestLineWt: Double;

begin
 Result := FALSE;
(*   IngredientFile^.GetIngredient(WorkLRec^.WOL_Ingredient,TempIngRec,FALSE);*)
     CalcLineGrossWtReqdForCurrMix;
     if pvtblOrderLine[OL_ProcessType] = PTStep then
      BEGIN
       Result := WghsDoneForCurrMix >= CalcLineWeighingsReqdForCurrMix;
      END
     ELSE
      BEGIN
       LineWtRequired := CalcLineGrossWtReqdForCurrMix;
       {CalcIngredientTolWts(@TempIngRec,}
       CalcWOLineTolWts(LineWtRequired, { need know tolerance on mix tot }
                        pvtblOrderHeader[OH_MixType],
                        LineWtRequired,
                        0.0,            { weight done }
                        LowestLineWt,
                        HighestLineWt);
       AdjustTolToScaleRes(LowestLineWt,HighestLineWt);
       Result := (CompareWts(WtDoneForCurrMix, LowestLineWt) >= 0);

(*     { is smallest weight remaining less than half a scale increment? }
       MinRemainingWt := LowestLineWt - WtDoneForCurrMix;
       RoundWtToScaleRes(MinRemainingWt);
       Complete := CompareWts(MinRemainingWt, 0.0) <= 0;

       no - this is no good - scales with different increments would
       see the line status differently and could set mix status to complete
       prematurely.

       Therefore tolerance band on weighing must make sure weight goes on
       or over min wt requirement ie. round wts up to nearest scale increment.
*)
      END;
end;

function TdmFormix.GetNextRunNumber: Integer;
var WrkInt: Integer;
begin
 Result := 0;
 WrkInt := 0;
 WrkInt := GetTermRegInteger(r_RunNumber);
 if WrkInt <> 999999 then SetTermRegInteger(r_RunNumber,WrkInt+1)
                     else SetTermRegInteger(r_RunNumber,1);
 Result := WrkInt;
end;

function TdmFormix.GetGlobalBatchNumber: String;
begin
  Result := GetTermRegString(r_GlobalBatchNumber);
end;

procedure TdmFormix.SetGlobalBatchNumber(const WithString: String);
begin
  SetTermRegString(r_GlobalBatchNumber,WithString);
end;

function TdmFormix.GetBatchStrForFormixTran: String;
var
  TempBatchNoStr : string;
  JobNo : integer;
begin
  if Trim(CurrentBatch) = '' then {hasnt been set by user}
    TempBatchNoStr := GetGlobalBatchNumber
  else
    TempBatchNoStr := CurrentBatch;
  if  (Trim(TempBatchNoStr) = '')
  and (Pos('JJJ', fAutoBatchFormat) > 0) then //load recipe job number into batchNoStr
  begin
    if (pvtblRecipeHeader.FindField(RH_JobNumber) <> nil) then
      JobNo := dmFormix.pvtblRecipeHeader.FieldByName(RH_JobNumber).AsInteger
    else
      JobNo := 0;
    TempBatchNoStr := IntToZeroStr(JobNo,3);
  end;
  if  (Pos('DDD',fAutoBatchFormat) = 1)
  and (Length(TempBatchNoStr) <= 3) then
    TempBatchNoStr := IntToZeroStr(DayOfTheYear(JulianToDateValue(
                          pvtblOrderHeader.FieldByName(OH_ScheduleDate).AsInteger)),
                                   3) + ZeroPad(TempBatchNoStr,3,true{preceeding});

  Result := SpacePad(TempBatchNoStr,6,false{preceeding});
end;

function TdmFormix.WeightOkForTran(ActNetWt  : Double;
                                   IngType   : TProcessTypes;
                                   LowTolWt,
                                   HighTolWt : Double;
                                   {by user (partial wt button)}
                                   LowTolDisabled : Boolean): Boolean;
begin
 Result := FALSE;
 if IngType = PTWeight then { can do partial weighings }
  begin
   if  (CompareWts(ActNetWt, HighTolWt) <= 0)
   and (   (LowTolDisabled and (CompareWts(ActNetWt,0.0) > 0))
        or (CompareWts(ActNetWt, LowTolWt) >= 0)) then
     Result := TRUE;
  end
 else if IngType = PTCount then {fixed wt contributes to wt done (no part wghs)}
  begin
   if  (CompareWts(ActNetWt, HighTolWt) <= 0)
   and (CompareWts(ActNetWt, LowTolWt) >= 0) then
     Result := TRUE;
  end
 else if IngType IN [PTStep, PTAuto] then
   Result := TRUE;
end;

procedure TdmFormix.AddWeightToMixRecord(ToMixNo: Word;
  WeightToAdd: Double; IsLastWtForKeyIngredient: Boolean);
{REQUIRES: Caller to have started a database transaction.
}
var WrkMixRequired: Double;
begin
 if pvtblMixTotal.Locate(MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo,
                  VarArrayOf([pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                              pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger,
                              ToMixNo]),[]) then
  begin
   pvtblMixTotal.Edit;
   pvtblMixTotal.FieldByName(MIX_WeightDone).AsFloat := pvtblMixTotal.FieldByName(MIX_WeightDone).AsFloat+
                                                        WeightToAdd;
   {If last weighing for key ingredient then adjust target mix weight.}
   if IsLastWtForKeyIngredient then
    begin
     WrkMixRequired := 0.0;
     WrkMixRequired := DivDouble(pvtblMixTotal.FieldByName(MIX_WeightDone).AsFloat,
                                 CalcLineGrossPortion);
     {round-down to nearest gram
      to make sure key ingredient recalculates as "complete"}
     WrkMixRequired := WrkMixRequired-0.00051;
     WrkMixRequired := RoundWtToNearestGram(WrkMixRequired);
     pvtblMixTotal.FieldByName(MIX_WeightRequired).AsFloat := WrkMixRequired;
    end;
   pvtblMixTotal.Post;
  end;
end;


function TdmFormix.GetPvtblMixTotalFieldForPrepAreaQA : TField;
begin
  with PvtblMixTotal do
  begin
    if GetQAModeForPrepArea = qamode_MEAT then
      Result := FieldByName(MIX_MeatQADone)
    else if GetQAModeForPrepArea = qamode_SEASONING then
      Result := FieldByName(MIX_SeasoningQADone)
    else if GetQAModeForPrepArea = qamode_WATER then
      Result := FieldByName(MIX_WaterQADone)
    else
      Result := FieldByName(MIX_QAComplete);
  end;
end;

function TdmFormix.QAHasBeenDoneForMixInPrepArea(MixNo : integer) : boolean;
var Field : TField;
begin
  Result := false;
  Field := GetPvtblMixTotalFieldForPrepAreaQA;
  if Field = nil then
  begin
    TermMessageDlg('Database needs upgrading to record completion of QA on mix.',mtError,[mbOK],0);
  end
  else
  begin
    if pvtblMixTotal.Locate(MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo,
                            VarArrayOf([pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                        pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger,
                                        MixNo]),[]) then
      Result := Field.AsBoolean;
  end;
end;

function TdmFormix.SetQAStatusOnMixRecordTo(Complete : boolean; MixNo : integer) : boolean;
var Field : TField;
begin
  Result := false;
  Field := GetPvtblMixTotalFieldForPrepAreaQA;
  if Field = nil then
  begin
    TermMessageDlg('Database needs upgrading to record completion of QA on mix.',mtError,[mbOK],0);
  end
  else
  begin
    if pvtblMixTotal.Locate(MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo,
                            VarArrayOf([pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                        pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger,
                                        MixNo]),[]) then
    begin
      pvtblMixTotal.Edit;
      Field.AsBoolean := Complete;
      pvtblMixTotal.Post;
      Result := true;
    end;
  end;
end;

procedure TdmFormix.RunQAChecksForMix;
begin
  if TfrmQAProgress.RunQAChecks then
    SetQAStatusOnMixRecordTo(true, CurrentMixNo);
end;

procedure TdmFormix.AddTranToTotalsFile(ForDate: Integer;ForBatch,ForLot,ForIngredient: String;
                                        ForWeight: Double);
{REQUIRES: Caller to have started a database transaction.
}
begin
 if not pvtblIngredientUsage.Locate(INGU_DateUsed+';'+INGU_BatchNo+';'+INGU_LotNo+';'+INGU_Ingredient,
                             VarArrayOf([ForDate,ForBatch,ForLot,ForIngredient]),[]) then
  begin
   pvtblIngredientUsage.Append;
   pvtblIngredientUsage.FieldByName(INGU_Ingredient).AsString  := ForIngredient;
   pvtblIngredientUsage.FieldByName(INGU_DateUsed).AsInteger   := ForDate;
   pvtblIngredientUsage.FieldByName(INGU_BatchNo).AsString     := ForBatch;
   pvtblIngredientUsage.FieldByName(INGU_LotNo).AsString       := ForLot;
   pvtblIngredientUsage.FieldByName(INGU_TransCount).AsInteger := 1;
   pvtblIngredientUsage.FieldByName(INGU_NetWt).AsFloat        := ForWeight;
   pvtblIngredientUsage.FieldByName('Reserved').AsString       := #0;
   pvtblIngredientUsage.Post;
  end
 else
  begin
   pvtblIngredientUsage.Edit;
   pvtblIngredientUsage.FieldByName(INGU_TransCount).AsInteger :=
                        pvtblIngredientUsage.FieldByName(INGU_TransCount).AsInteger+1;
   pvtblIngredientUsage.FieldByName(INGU_NetWt).AsFloat :=
                        pvtblIngredientUsage.FieldByName(INGU_NetWt).AsFloat +
                        ForWeight;
   pvtblIngredientUsage.Post;
  end;
(* if not pvtblIngredientUsage.Locate(INGU_DateUsed+';'+INGU_BatchNo+';'+INGU_LotNo+';'+INGU_Ingredient,
                             VarArrayOf([pvtblTransactions.FindField(TRN_Date).AsInteger,
                                         pvtblTransactions.FindField(TRN_BatchNo).AsString,
                                         pvtblTransactions.FindField(TRN_LotNo).AsString,
                                         pvtblTransactions.FindField(TRN_Ingredient).AsString]),[]) then
  begin
   pvtblIngredientUsage.Append;
   pvtblIngredientUsage.FindField(INGU_Ingredient).AsString :=
                        pvtblTransactions.FindFIeld(TRN_Ingredient).AsString;
   pvtblIngredientUsage.FindField(INGU_DateUsed).AsInteger :=
                        pvtblTransactions.FindFIeld(TRN_Date).AsInteger;
   pvtblIngredientUsage.FindField(INGU_BatchNo).AsString :=
                        pvtblTransactions.FindFIeld(TRN_BatchNo).AsString;
   pvtblIngredientUsage.FindField(INGU_LotNo).AsString :=
                        pvtblTransactions.FindFIeld(TRN_LotNo).AsString;
   pvtblIngredientUsage.FindField(INGU_TransCount).AsInteger := 1;
   pvtblIngredientUsage.FindField(INGU_NetWt).AsFloat :=
                        pvtblTransactions.FindField(TRN_WeightInMix).AsFloat;
   pvtblIngredientUsage.FindField('Reserved').AsString := #0;
   pvtblIngredientUsage.Post;
  end
 else
  begin
   pvtblIngredientUsage.Edit;
   pvtblIngredientUsage.FindField(INGU_TransCount).AsInteger :=
                        pvtblIngredientUsage.FindField(INGU_TransCount).AsInteger+1;
   pvtblIngredientUsage.FindField(INGU_NetWt).AsFloat :=
                        pvtblIngredientUsage.FindField(INGU_NetWt).AsFloat +
                        pvtblTransactions.FindField(TRN_WeightInMix).AsFloat;
   pvtblIngredientUsage.Post;
  end;*)
end;

procedure TdmFormix.AddToCostFile;
{REQUIRES: Caller to have started a database transaction.
}
var Added: Boolean;
begin
 // NOTE: there's only one instance of this dm.
 if not pvtblCost.Active then {not opened at the start of the program - then not used}
   EXIT;
 Added := FALSE;
 if pvtblCost.Locate(COST_Ingredient+';'+COST_LotNo,
              VarArrayOf([pvtblTransactions.FieldByName(TRN_Ingredient).AsString,
                          pvtblTransactions.FieldByName(TRN_LotNo).AsString]),[]) then
  begin
   pvtblCost.Edit;
   pvtblCost.FieldByName(COST_WeightUsed).AsFloat :=
             pvtblCost.FieldByName(COST_WeightUsed).AsFloat +
                       pvtblTransactions.FieldByName(TRN_WeightInMix).AsFloat;
   pvtblCost.Post;
   Added := TRUE;
  end
 else
  begin
   if GetTermRegBoolean(r_FXGlobalLot) then
    begin
     if pvtblCost.Locate(COST_Ingredient+';'+COST_LotNo,
                  VarArrayOf(['        ',
                              pvtblTransactions.FieldByName(TRN_LotNo).AsString]),[]) then
      begin
       pvtblCost.Edit;
       pvtblCost.FieldByName(COST_WeightUsed).AsFloat :=
                 pvtblCost.FieldByName(COST_WeightUsed).AsFloat +
                           pvtblTransactions.FieldByName(TRN_WeightInMix).AsFloat;
       pvtblCost.Post;
       Added := TRUE;
      end;
    end;
  end;
 if (not Added) and (GetTermRegBoolean(r_SFXAUTOADDCOST)) then
  begin
   pvtblCost.Append;
   pvtblCost.FieldByName(COST_Ingredient).AsString := pvtblTransactions.FieldByName(TRN_Ingredient).AsString;
   pvtblCost.FieldByName(COST_LotNo).AsString      := pvtblTransactions.FieldByName(TRN_LotNo).AsString;
   pvtblCost.FieldByName(COST_WeightUsed).AsFloat  := pvtblTransactions.FieldByName(TRN_WeightInMix).AsFloat;
   // cant have null fields
   pvtblCost.FieldByName(COST_Cost).AsFloat := 0.0;
   pvtblCost.FieldByName(COST_WeightIn).AsFloat := 0.0;
   pvtblCost.FieldByName(COST_Free1).AsString := '';
   pvtblCost.FieldByName(COST_WeightWasted).AsFloat := 0.0;
   pvtblCost.FieldByName(COST_Reserved).AsString := '';
   pvtblCost.Post;
  end;
end;

function TdmFormix.GetLotNumber: String;
begin
  Result := '';
  if not SelectedLineIsAutoWeigh then {Lot No can be edited}
  begin
    if Trim(CurrentIngredientLot) = '' then
      Result := GetTermRegString(r_GlobalLotNumber)
    else Result := CurrentIngredientLot;
  end;
end;
(*
procedure TdmFormix.SetLotNumber(UseLotNumber: String);
begin
 SetRegString(r_LotNumber,UseLotNumber);
end;
*)
procedure TdmFormix.GetAreaQAStatusOnMixes(var QADoneOnCurrentMix : boolean;
                                       var NoOfMixesWithQADone : integer;
                                           ForOrder, ForSuffix,  MixNoOfCurrentMix: Integer);
var QAField : TField;
begin
  QADoneOnCurrentMix := false;
  NoOfMixesWithQADone := 0;
  QAField := GetPvtblMixTotalFieldForPrepAreaQA;
  if QAField <> nil then
  begin
    pvtblMixTotal.IndexFieldNames := MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo;
    pvtblMixTotal.SetRange([ForOrder,ForSuffix],[ForOrder,ForSuffix]);
    try
      pvtblMixTotal.First;
      while not pvtblMixTotal.Eof do
      begin
        if QAField.AsBoolean then
        begin
          Inc(NoOfMixesWithQADone);
          if pvtblMixTotal.FieldByName(MIX_MixNo).AsInteger = MixNoOfCurrentMix then
            QADoneOnCurrentMix := true;
        end;
        pvtblMixTotal.Next;
      end;
    finally
      pvtblMixTotal.CancelRange;
    end;
  end;
end;

procedure TdmFormix.PrintCurrentTransactionTicket;
var
//    LabError: Integer;
    LabelList: TStrings;
//    LabFile : ListRecFile;
//    LabName : Array [0..12] of CHAR;
    CurrentTicket : integer;
    LabelVarDataItems : TArrayOfLabelVarDataItem;

begin
  if (fNoOfTranTickets > 0) then//print ticket or show printer commands.
  begin
    try
      LabelList := TStringList.Create;
      try
        if fLabelFileName <> '' then
              begin
          if fLabelFormat <> '' then
          begin
            //FDL := UpperCase(ExtractFileExt(fLabelFileName)) = '.FDL';
            {Load Label Format's data tags into an array of records}
            SetLength(LabelVarDataItems, 0);
            try
              GetLabelsVarDataItems(fLabelFileName, fLabelFormat, LabelVarDataItems);
              for CurrentTicket := 1 to fNoOfTranTickets do
              begin
                {convert label format's data tags into actual data and save into StringList}
                FillOutLabelData(TRUE, pvtblTransactions.FieldByName(TRN_MixNo).AsInteger,
                                 {FDL,LabName,}fLabelFormat,
                                 1{CurrentTicket},1{TotalTickets},
                                 0,0,{LabFile,}
                                 LabelVarDataItems, LabelList);
              end;
            finally
              LabelVarDataItems := nil;
            end;
            PrintOutLabel({FDL,}LabelList);
          end
          else TermMessageDlg('No Transaction Label Format set',mtError,[mbOk],0);
          end
        else TermMessageDlg('No Label File set'+#13#10+
                            'Transaction Label not printed',mtError,[mbOk],0);
      finally
        LabelList.Free;
      end;
    except
      on E:Exception do
      begin
        TermMessageDlg('Transaction Label printing failed'+#13#10+
                       E.Message,mtInformation,[mbOk],0);
      end;
    end;
  end;
end;

function TdmFormix.CalcMixStatus(var CompleteForPrepArea : boolean;
                                 var Complete            : boolean): Boolean;
//edited by TB 07/12/2011
{REQUIRES: 1. OrderHeader to be current in dmFormix
           2. CurrentMixNo to be set if mix number on OrderHeader is not to be used.
           3. Range to be set on OrderLines in dmFormix
 PROMISES: 1. Returns false and parameters as true on file read errors.
}
var
    MixLRec : TMixLineRecord;
begin
  Result := false;
  CompleteForPrepArea := true;
  Complete            := true;
  try
    PreCalcCompensatedBatchMixWt;// sets CurrentCompensatedBatchMixWt used by ingredient calcs
    // assume ingredients are done left to right - search for unfinished from right to left.
    pvtblOrderLine.Last;
    while not pvtblOrderLine.BOF do
    begin
      if not ConstructMixLineRecForOrdLine(CurrentMixNo,MixLRec) then
        exit;
       {****}
      if not IsThisLineCompleteForCurrMix(MixLRec.ML_WghsDone,MixLRec.ML_WtDone) then
      begin
        Complete := false;
        if SynchIngredientsCacheWithCode(pvtblOrderLine.FieldByName(OL_Ingredient).AsString) then
        begin
          if IngredientIsInPrepArea(rxmIngredientsCache) then
          begin
            CompleteForPrepArea := false;
            Result := true;
            exit; // double false - thats all we need to know
          end;
        end;
      end;
      pvtblOrderLine.Prior;
    end;
    Result := true;
  except
    on E:Exception do
    begin
      TermMessageDlg('Error calculating mix status'+#13#10+
                     E.Message,mtError,[mbOk],0);
    end;
  end;
  CancelPreCalcCompensatedBatchMixWt;
end;

function TdmFormix.IsMixComplete(ForOrder: Integer; ForSuffix: Integer;
                                 ForMixNo: Integer): Boolean;
begin
 Result := FALSE;
 if pvtblMixTotal.Locate(MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo,
                         VarArrayOf([ForOrder,ForSuffix,ForMixNo]),[]) then
   Result := pvtblMixTotal.FieldByName(MIX_Complete).AsBoolean;
end;


function TdmFormix.GetMixLabelBarcode(FopsPluNumber : integer) : String;
{REQUIRES: 1. PvtblOrderHeader and pvtblMixTotal to be located on relevant records.
           2. FopsPluNumber to be non-zero if SFXAddMixToFopsStock=TRUE.
 PROMISES: Returns '' if fAddMixToFopsStock and (FopsPluNumber <= 0).
}
var WeightStr : string;
begin
  if fAddMixToFopsStock then
  begin
    if  pvtblMixTotal.FieldByName(MIX_Complete).AsBoolean
    and (FopsPluNumber > 0) then
    begin
      WeightStr := FormatFloat('00000.0000',pvtblMixTotal.FieldByName(MIX_WeightDone).AsFloat);
      Result := 'M'+ {and 30 digits: OOOOOO SS MMMM PPPPP ddmmyy WWWWwww}
            IntToZeroStr(pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger, 6)+
            IntToZeroStr(pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger, 2)+
            IntToZeroStr(pvtblMixTotal.FieldByName(MIX_MixNo).AsInteger, 4)+
            IntToZeroStr(FopsPluNumber,5)+
            FormatDateTime('ddmmyy', JulianToDateValue(pvtblOrderHeader.FieldByName(OH_ScheduleDate).AsInteger))+
            Copy(WeightStr,2,4)+Copy(WeightStr,7,3);
    end
    else
      Result := '';
  end
  else
    Result := IntToZeroStr(pvtblMixTotal.FieldByName(MIX_OrderNo).AsInteger, 6)+
              IntToZeroStr(pvtblMixTotal.FieldByName(MIX_OrderNoSuffix).AsInteger, 2)+
              IntToZeroStr(pvtblMixTotal.FieldByName(MIX_MixNo).AsInteger, 4)+
              IntToZeroStr(fMachineID, 2);
end;

procedure TdmFormix.PrintMixTicket(ForMixNo: Integer);
{REQUIRES: 1. pvtblOrderHeader to be located.
 PROMISES: 2. will print current mix if ForMixNo is supplied as -1.
}
var
//    LabError: Integer;
    LabelFormat: String;
    LabelList: TStrings;
    TransactionKey : string;
//    LabName: Array [0..12] of Char;
//    LabFile : ListRecFile;
    IngredPerTicket,
    IngredCount: Integer;
//    LoadRec : TListRec;
//    WrkStr: String;
    Tickets,
    TotalTickets: Integer;

    {Filter variables for transaction listing}
    FilterOrder: Integer;
    FilterRevision: integer;
    {FDL: Boolean;}
    MachineID: Integer;
    SerialNo: Integer;
    IngredientDesc: String;
    UseBy: String;
    PurchOrder: String;
    LabelVarDataItems : TArrayOfLabelVarDataItem;
    Idx : integer;
begin
  if ForMixNo = -1 then
    ForMixNo := GetCorrectMixNo;
  if (ForMixNo < 1)
  or (    (not GetTermRegBoolean(r_MixTicketsAnytime))
      and (ForMixNo > pvtblOrderHeader.FieldByName(OH_MixesDone).AsInteger)) then
    EXIT;
   {****}

  if ((PrinterCommPort <> nil) and (PrinterCommPort.Connected))
  or (fNoOfMixTickets > 0){A mix ticket was definitely wanted or needs to be debugged} then
  begin
    rxmMixContents.Open;
    rxmMixContents.EmptyTable;
    MixLabelBatchNoStr := '';
    MixLabelLotNoStr   := '';
    LabelFormat := GetTermRegString(r_FXMixLabFormat);
    if LabelFormat = '' then
      LabelFormat := fLabelFormat;
    if LabelFormat = '' then
      LabelFormat := 'D';
    LabelList := TStringList.Create;
    try
      if fLabelFileName <> '' then
      begin
        if LabelFormat <> '' then
        begin
          {Load Label Format's data tags into an array of records}
          SetLength(LabelVarDataItems, 0);
          try
            GetLabelsVarDataItems(fLabelFileName, LabelFormat, LabelVarDataItems);

            {Fill out memory table}
            IngredCount := 0;
            TransactionKey := pvtblTransactions.IndexName;
            pvtblTransactions.IndexName := 'ByOrderMixLine';

            FilterOrder    := pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger;
            FilterRevision := pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger;
            pvtblTransactions.FindNearest([FilterOrder,FilterRevision,ForMixNo]);
            while (not pvtblTransactions.Eof) and
                  (pvtblTransactions.FieldByName(TRN_OrderNo).AsInteger = FilterOrder) and
                  (pvtblTransactions.FieldByName(TRN_OrderNoSuffix).AsInteger = FilterRevision) and
                  (pvtblTransactions.FieldByName(TRN_MixNo).AsInteger = ForMixNo) do
            begin
              if Trim(MixLabelBatchNoStr) = '' then
                MixLabelBatchNoStr := pvtblTransactions.FieldByName(TRN_BatchNo).AsString;
              if Trim(MixLabelLotNoStr) = '' then
                MixLabelLotNoStr := pvtblTransactions.FieldByName(TRN_LotNo).AsString;
              {Add to memory table}
              IngredientDesc :='';
              UseBy := '';
              PurchOrder := '';
              if pvtblTransactions.FieldByName(TRN_Status).AsInteger <> TRNStatusAborted then
              begin
                if pvtblIngredients.Locate(ING_Ingredient,
                           CorrectCode(pvtblTransactions.FieldByName(TRN_Ingredient).AsString,8),
                                           []) then
                begin
                  IngredientDesc := pvtblIngredients.FieldByName(ING_Description).AsString;
                  if Assigned(dmFops) and
                     (UpperCase(pvtblIngredients.FieldByName(ING_PrepArea).AsString) = 'DRYGOODS') and
                     TryStrToInt(COPY(pvtblTransactions.FieldByName(TRN_LotNo).AsString,1,2),MachineID) and
                     TryStrToInt(COPY(pvtblTransactions.FieldByName(TRN_LotNo).AsString,3,6),SerialNo) then
                  begin
                    UseBy := dmFops.GetTranMaxLifeDateStr(MachineID,SerialNo);
                    PurchOrder:= dmFops.GetTranPurchaseOrderStr(MachineID,SerialNo);
                  end;
                end;

                if rxmMixContents.Locate(rxmMixContentsIngredient.FieldName+';'+
                                              rxmMixContentsUseBy.FieldName+';'+
                                              rxmMixContentsPurchOrder.FieldName,
                                              VarArrayof([pvtblTransactions.FieldByName(TRN_Ingredient).AsString,
                                                          UseBy,PurchOrder]),[]) then
                begin
                  {It allready exists so just update the weight done and the conts done}
                  rxmMixContents.Edit;
                  rxmMixContents.FieldByName('WeightDone').AsFloat :=
                                      rxmMixContents.FieldByName('WeightDone').AsFloat +
                                      pvtblTransactions.FieldByName(TRN_WeightInMix).AsFloat;
                  rxmMixContents.FieldByName('ContsDone').AsInteger :=
                                      rxmMixContents.FieldByName('ContsDone').AsInteger +
                                      1;
                  rxmMixContents.Post;
                end
                else
                begin
                  {Its a new ingredient so add it}
                  Inc(IngredCount);
                  rxmMixContents.Append;
                  rxmMixContentsRecNo.Value          := IngredCount;
                  rxmMixContentsOrderNo.Value        := pvtblTransactions.FieldByName(TRN_OrderNo).AsInteger;
                  rxmMixContentsRevision.Value       := pvtblTransactions.FieldByName(TRN_OrderNo).AsInteger;
                  rxmMixContentsIngredient.Value     := pvtblTransactions.FieldByName(TRN_Ingredient).AsString;
                  rxmMixContentsWeightDone.Value     := pvtblTransactions.FieldByName(TRN_WeightInMix).AsFloat;
                  rxmMixContentsWeightReq.Value      := 0;
                  rxmMixContentsContsDone.Value      := 1;
                  rxmMixContentsContsReq.Value       := 0;
                  rxmMixContentsIngredientDesc.Value := IngredientDesc;
                  //Use By Date and Purchase order if dry goods (Hilton Ireland)
                  rxmMixContentsUseBy.Value          := UseBy;
                  rxmMixContentsUseByInternal.Value  := Copy(UseBy,7,2)+COPY(UseBy,4,2)+COPY(UseBy,1,2);
                  rxmMixContentsPurchOrder.Value     :=PurchOrder;
                  rxmMixContents.Post;
                end;
              end;
              pvtblTransactions.Next;
            end;
            rxmMixContents.SortOnFields(rxmMixContentsIngredient.FieldName+';'+
                                             rxmMixContentsUseByInternal.FieldName);

            pvtblTransactions.IndexName := TransactionKey;
            {Are there any transactions}
            if rxmMixContents.RecordCount > 0 then
            begin
              {Work out how many ingredients there are per ticket}
              IngredPerTicket := 0;
              for idx := 0 to Length(LabelVarDataItems)-1 do
              begin
                if CompTag(LabelVarDataItems[idx].LPD_Tag, IngredientInfo) then
                  Inc(IngredPerTicket);
              end;
              TotalTickets := 1;
              Tickets := 1;
              if IngredPerTicket = 0 then
              begin
                {convert label format's data tags into actual data and save into StringList}
                FillOutLabelData(FALSE,ForMixNo,{FDL,LabName,}LabelFormat,
                                 Tickets{CurrentTicket},TotalTickets,0,0,{LabFile,}
                                 LabelVarDataItems, LabelList);
                PrintOutLabel({FDL,} LabelList);
              end
              else
              begin
                IngredCount := 0;
                TotalTickets := (rxmMixContents.RecordCount DIV IngredPerTicket);
                if (rxmMixContents.RecordCount - (TotalTickets*IngredPerTicket)) <> 0 then
                  Inc(TotalTickets);

                for Tickets := 1 to TotalTickets do
                begin
                  {convert label format's data tags into actual data and save into StringList}
                  FillOutLabelData(FALSE,ForMixNo,{FDL,LabName,}LabelFormat,
                                   Tickets{CurrentTicket},TotalTickets,
                                   IngredCount,IngredPerTicket,{LabFile,}
                                   LabelVarDataItems, LabelList);
                end;
                PrintOutLabel({FDL,}LabelList);  // Print Out All Labels
  (*
               {Print ticket for each ingredient}
               rxmMixContents.First;
               while not rxmMixContents.Eof do
                begin
                 Inc(IngredCount);
                 FillOutLabelData(FALSE,ForMixNo,FDL,LabName,LabelFormat,Tickets,TotalTickets,
                                  IngredCount,IngredPerTicket,LabFile,LabelList);
                 if (IngredCount MOD IngredPerTicket) = 0 then PrintOutLabel(FDL, LabelList);
                 rxmMixContents.Next;
                end;
               {Print last ticket if still some unprinted ingreients}
               if (IngredCount MOD IngredPerTicket) <> 0 then
                begin
                 Inc(Tickets);
                 FillOutLabelData(FALSE,ForMixNo,FDL,LabName,LabelFormat,Tickets,TotalTickets,
                                  IngredCount,IngredPerTicket,LabFile,LabelList);
                 PrintOutLabel(FDL,LabelList);
                end;
  *)
              end;
            end
            else
              TermMessageDlg('No Transactions found for Mix '+IntToStr(ForMixNo),
                             mtInformation, [mbOk], 0);
          finally
            LabelVarDataItems := nil;
          end;
        end
        else TermMessageDlg('No Label Format set',mtError,[mbOk],0);
      end
      else TermMessageDlg('No Label File set'+#13#10+
                          'Transaction Label not printed',mtError,[mbOk],0);
    finally
      LabelList.Free;
      rxmMixContents.Close;
    end;
  end;
end;

procedure TdmFormix.FillOutLabelData(UsePvtblTransactionsDetails : boolean;
                                     MixNo: integer;
                                     //FDL: Boolean;
                                     //ForLabelName: array of Char;
                                     ForLabelFormat: String;
                                     CurrentTicket, TotalTickets,
                                     IngredientNumber, IngredientsPerTicket: Integer;
                                     //var ForLabelFile: ListRecFile;
                                     const LabelVarDataItems : TArrayOfLabelVarDataItem;
                                     var ReturnLabelData: TStrings);
{REQUIRES: 1. rxmMixContents to be loaded.
           2. pvtblOrderHeader to be located.
           3. pvtblOrderLine to be located if UsePvtblTransactionsDetails = true.
           4. UsePvtblTransactionsDetails to be TRUE to print an INGREDIENT TICKET
}
var FirstLine: Boolean;
//    LoadRec : TListRec;
    RecipePluNo : integer;
    IngredientLocated : boolean;
    ItemIdx : integer;

  function GetRecipePluNo : integer;
  begin
    if (RecipePluNo = -1) then //load up RecipePluNo.
    begin
      if Assigned(dmFops) then
        RecipePluNo := dmFops.GetFops6PluNumberForIngredient(pvtblOrderHeader.FieldByName(OH_RecipeCode).AsString)
      else
        RecipePluNo := 0;
    end;
    Result := RecipePluNo;
  end;

  function GetLabelTextForLabelVarDataItem(LabItem : TLabelVarDataItem) : string;
  var
        WrkStr: String;
        IngredLineNum,
        DummyInt: Integer;
        TotWt: Double;
        UseDesc: Boolean;
        LotNo: String;
        MachineID: Integer;
        SerialNo: Integer;
        TagId : integer;
        AdjustInt : integer;
        DelimChar : char;


      function GetIngredientRecord : Boolean;
      begin
        if  (not IngredientLocated)
        and UsePvtblTransactionsDetails then
          IngredientLocated := pvtblIngredients.Locate(ING_Ingredient,
                  CorrectCode(pvtblTransactions.FieldByName(TRN_Ingredient).AsString,8),
                                                       []);
        Result := IngredientLocated;
      end;

  begin
    Result := '';
    try
      TagId := FindSingleTagNumber(UpperCase(LabItem.LPD_Tag));
      case TagId of
      1 : Result := GetCurrentFullOrderNo;
      2 : if UsePvtblTransactionsDetails then
            Result := pvtblTransactions.FieldByName(TRN_Ingredient).AsString;
      3 : Result := IntToStr(CurrentTicket)+'/'+IntToStr(TotalTickets);
      4 : begin
            if UsePvtblTransactionsDetails then
              Result := FormatFloat('#0.000',pvtblTransactions.FieldByName(TRN_WeightInMix).AsFloat)+'kg'
            else
            begin
              TotWt := 0;
              rxmMixContents.First;
              while not rxmMixContents.Eof do
              begin
                TotWt := TotWt+ rxmMixContentsWeightDone.AsFloat;
                rxmMixContents.Next;
              end;
              Result := FormatFloat('#0.000',TotWt);
            end;
          end;
      5 : Result := GetCurrentUser;
      6 : if UsePvtblTransactionsDetails then
            Result := pvtblTransactions.FieldByName(TRN_BatchNo).AsString
          else
            Result := MixLabelBatchNoStr;
      7 : if UsePvtblTransactionsDetails then
            Result := pvtblTransactions.FieldByName(TRN_LotNo).AsString
          else
            Result := MixLabelLotNoStr;
      8 : Result := pvtblOrderHeader.FieldByName(OH_RecipeCode).AsString;
      9 : begin
            AdjustInt := 0;
            DelimChar := (LabItem.LPD_Tag+' ')[Length(SingleTags[TagId].Name)+1];
            if DelimChar in ['+','-'] then
              AdjustInt := StringToLong(Copy(TrimRight(LabItem.LPD_Tag),
                                             Length(SingleTags[TagId].Name)+1, 11));
            if UsePvtblTransactionsDetails then
              Result := FormatDateTime('dd/mm/yy',
                             JulianToDateValue(pvtblTransactions.FieldByName(TRN_Date).AsInteger+
                                               AdjustInt))
            else
              Result := FormatDateTime('dd/mm/yy', Date + AdjustInt);
          end;
      10: if UsePvtblTransactionsDetails then
            Result := pvtblTransactions.FieldByName(TRN_Time).AsString
          else
            Result := FormatDateTime('hh:nn',TimeOf(Now));
      11: Result := IntToZeroStr(MixNo,2);
      12: if UsePvtblTransactionsDetails then
            Result := IntToZeroStr(pvtblTransactions.FieldByName(TRN_ContainerNo).AsInteger,2);
      13: if pvtblMixTotal.FieldByName(MIX_Complete).AsBoolean then
            Result := 'YES'
          else
            Result := 'NO';
      14: Result := IntToStr(MixNo)+ ' of '+ IntToStr(pvtblOrderHeader.FieldByName(OH_MixesRequired).AsInteger);
      15: if UsePvtblTransactionsDetails then
            Result := IntToZeroStr(pvtblTransactions.FieldByName(TRN_ContainerNo).AsInteger,2)+
                      ' of '+
                      IntToZeroStr(frmFormixProcessRecipe.fCurrentContainers,2);
      16: if UsePvtblTransactionsDetails then
            Result := pvtblOrderLine.FieldByName(OL_SpecialInstruction1).AsString;
      17: if UsePvtblTransactionsDetails then
            Result := pvtblOrderLine.FieldByName(OL_SpecialInstruction2).AsString;
      18: Result := TrimRight(GetRecipeName(pvtblOrderHeader.FieldByName(OH_RecipeCode).AsString));
      19: begin   // Ingredient Description *INGREDIENT
            if UsePvtblTransactionsDetails
            and GetIngredientRecord then
              Result := TrimRight(pvtblIngredients.FieldByName(ING_Description).AsString);
          end;
      20,21,22: begin // Maximum Life, PO, TraceId (HFI Dry Goods Only);
          if  Assigned(dmFops)
          and GetIngredientRecord
          and (UpperCase(pvtblIngredients.FieldByName(ING_PrepArea).AsString) = 'DRYGOODS') then
            begin
              if UsePvtblTransactionsDetails then
                LotNo := pvtblTransactions.FieldByName(TRN_LotNo).AsString
              else
                LotNo := MixLabelLotNoStr;
              if TryStrToInt(COPY(LotNo,1,2),MachineID) then
              begin
                if TryStrToInt(COPY(LotNo,3,6),SerialNo) then
                begin
                  case TagId of
                    20 : Result := dmFops.GetTranMaxLifeDateStr(MachineID,SerialNo);
                    21 : Result := dmFops.GetTranPurchaseOrderStr(MachineID,SerialNo);
                    22 : Result := dmFops.GetTranProducerIdDesc(MachineID, SerialNo);
                  end;
                end
              end;
            end;
          end;
      23: Result := IntToZeroStr(GetRecipePluNo,5);
      else
       begin
        {check to see if its an IngredientInfo line}
        WrkStr := UpperCase(LabItem.LPD_Tag);
        if CompTag(WrkStr,IngredientInfo) then
         begin
          UseDesc := (WrkStr[Length(IngredientInfo)+1] = 'X');
          if UseDesc then
            Val(Copy(LabItem.LPD_Tag,Length(IngredientInfo)+2,2), IngredLineNum,DummyInt)
          else
            Val(Copy(LabItem.LPD_Tag,Length(IngredientInfo)+1,2), IngredLineNum,DummyInt);

          IngredLineNum := ((CurrentTicket-1)*IngredientsPerTicket)+IngredLineNum;
          if rxmMixContents.Locate('RecNo',IngredLineNum,[]) then
          begin
            WrkStr := FormatFloat('#0.000',rxmMixContents.FieldByName('WeightDone').AsFloat);
            WrkStr := COPY(SPACE_STRING,1,10-LENGTH(WrkStr))+WrkStr;

            if UseDesc then
            begin
              Result  := CorrectCode(rxmMixContentsIngredient.AsString,8)+' '+
                         COPY(rxmMixContentsIngredientDesc.Value,1,12)+' '+
                         IntToStrLen(rxmMixContentsContsDone.Value,2)+
                         WrkStr+' '+
                         rxmMixContentsUseBy.Value+' '+
                         rxmMixContentsPurchOrder.Value;
            end
            else
            begin
              Result  := CorrectCode(rxmMixContentsIngredient.AsString,8)+' '+
                         IntToStrLen(rxmMixContentsContsDone.Value,2)+
                         WrkStr;
            end;
          end
          else Result := '';

//        if ( (IngredientNumber) - (IngredientsPerTicket*(CurrentTicket-1)) = IngredLineNum) then
//         begin
//          Result  := rxmMixContents.FindField('Ingredient').AsString+' '+
//                     rxmMixContents.FindField('ContsDone').AsString+' '+
//                     FormatFloat('000000.000',rxmMixContents.FindField('WeightDone').AsFloat);
//         end;
         end;
       end;
      end;
    except
      on E:Exception do
        TermMessageDlg('Calculating data for label tag '''+LabItem.LPD_Tag+''''+CR+LF+
                       E.Message,mtError,[mbOk],0);
    end;
  end;

    procedure CheckAndAddLine(LabItem : TLabelVarDataItem);
    var
      WrkData: String;
    begin
     if LabItem.LPD_Type IN [TextItem, BarcodeWithReadable, BarcodeWithoutReadable] then
      begin
       if LabItem.LPD_Type = TextItem then
         WrkData := GetLabelTextForLabelVarDataItem(LabItem)
       else //barcode - assume its a Mix barcode
       begin
         if fAddMixToFopsStock then //new mix barcode reqs plu
           WrkData := GetMixLabelBarcode(GetRecipePluNo)
         else // old mix label barcode
           WrkData := GetMixLabelBarcode(0)
       end;
       if Length(WrkData) > 50 then WrkData := Copy(WrkData,1,50);

       if FirstLine and fDirectPrinterProtocol then
         ReturnLabelData.Add(CHR(STX)+Trim(WrkData))
       else
         ReturnLabelData.Add(Trim(WrkData));

       FirstLine := FALSE;

       {If its a human readable barcode then add the data a second time so printer
        gets it for the hr part}
       if LabItem.LPD_Type = BarcodeWithReadable then
        begin
         ReturnLabelData.Add(Trim(WrkData));
        end;
      end;
    end;

begin
  RecipePluNo := -1;
  IngredientLocated := false;
  if not pvtblMixTotal.Locate(MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo,
                              VarArrayOf([pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                          pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger,
                                          MixNo]),[]) then
  begin
    TermMessageDlg('Mix record not found for label print.',mtError,[mbOk],0);                                      ;
    exit;
  end;

  {Fill out the data for a label file and return it}
  if not fDirectPrinterProtocol then
  begin
    ReturnLabelData.Add('SF'+ForLabelFormat);
  end
  else
  begin
    ReturnLabelData.Add('Input On');
    ReturnLabelData.Add('Layout Run "LF'+ForLabelFormat+'"');
  end;
  FirstLine := TRUE;

  for ItemIdx := 0 to Length(LabelVarDataItems)-1 do
    CheckAndAddLine(LabelVarDataItems[ItemIdx]);

  if not fDirectPrinterProtocol then
  begin
    ReturnLabelData.Add('$END01');
  end
  else
  begin
    ReturnLabelData.Add(Chr(EOT));
    ReturnLabelData.Add('PF1');
    ReturnLabelData.Add('Input Off');
  end;
end;

procedure TdmFormix.PrintOutLabel({FDL: Boolean;} FromLabelData: TStrings);
var
  i: Integer;
  frmDisplayPrinterData: TfrmDisplayPrinterData;
begin
  if  (PrinterCommPort <> nil)
  and (PrinterCommPort.Connected) then
  begin
    if fDirectPrinterProtocol then
      DisplayOnPrinter('Printing','Label(s)',PrinterCommPort,FALSE);
    for i := 0 to FromLabelData.Count-1 do
      PrinterCommPort.WriteStr(FromLabelData.Strings[i]+#13);
    if fDirectPrinterProtocol then
      DisplayOnPrinter('Label(s)','Printed',PrinterCommPort,FALSE);
  end
  else
  begin
    frmDisplayPrinterData := TfrmDisplayPrinterData.Create(Self);
    try
      frmDisplayPrinterData.memo1.Lines.AddStrings(FromLabelData);
      frmDisplayPrinterData.ShowModal;
    finally
      frmDisplayPrinterData.Free;
    end;
  end;
end;

function TdmFormix.IsValidUser(ForUser, ForPassword: String): Boolean;
{REQUIRES: 1. ForPassword to be in the "case" it was typed in
              (FOPS8 saves mixed case password in UserTable).
           2. ForUser to be in the "case" it was typed in (future proofing).
 PROMISES: ForUser gets upper-cased before searching for User in FORMIX DB;
 NOTE:     FOPS8 saves mixed case User Codes in UserTable but the key on User Codes
           is case-insensitive!).
}
begin
  Result := FALSE;
  if  Assigned(dmFops) and FormixIni.UseFopsUsers then //FOPS8 User required
  begin
    if HslSecurity.CheckUserAndPassword(ForUser, ForPassword) then
      Result := true;
  end
  else //do old Formix user password checking.
  begin
    if (SameText(ForUser,'SUPERHSL')) and
       (SameText(ForPassword,'766463')) then
    begin
      Result := TRUE;
      Exit;
    end;
    {Formix database holds User codes and passwords uppercased; UserCode index is case sensitive.}
    ForUser := UpperCase(ForUser);
    ForPassword := UpperCase(ForPassword);
    if not pvtblUserName.Active then pvtblUserName.Open;
    if pvtblUserName.Locate(UN_UserName,Copy(ForUser+'        ',1,8),[]) then
    begin
      if Trim(pvtblUserName.FieldByName(UN_Password).AsString) <> '' then
      begin
        if SameText({F6DeCript}Trim(pvtblUserName.FieldByName(UN_Password).AsString),ForPassword) then
          Result := TRUE
        else TermMessageDlg('Invalid Password entered for User Name: '+ForUser,
                            mtError,[mbOk],0);
      end
      else Result := TRUE;
    end
    else
      TermMessageDlg('User Name: '+ForUser+' not found in Database',mtError,[mbOk],0);
  end;
end;

procedure TdmFormix.PrintAllMixTickets;
var MixNo: Integer;
begin
 {Need to print all mix tickets}
 for MixNo := 1 to pvtblOrderHeader.FieldByName(OH_MixesRequired).AsInteger do
   PrintMixTicket(MixNo);
end;


function TdmFormix.IngredientIsInPrepArea(LocatedIngredientDataset : TDataSet) : Boolean;
begin
  //Note: Lazenbys database has got a null prep area on some of there ingredients!
  Result := Str_Equal(COPY(fPrepAreaFilter+SPACE_STRING,1,8),
                      LocatedIngredientDataset.FieldByName(ING_PrepArea).AsString,
                      Length(LocatedIngredientDataset.FieldByName(ING_PrepArea).AsString));
end;

function TdmFormix.GetQAModeForPrepArea : string;
begin
  if Pos('MEAT', UpperCase(fPrepAreaFilter)) > 0 then
    Result := qamode_MEAT
  else if Pos('WATER', UpperCase(fPrepAreaFilter)) > 0 then
    Result := qamode_WATER
  else
    Result := qamode_SEASONING;
end;

function TdmFormix.FindNextWipLineForTerminal(
  StartLineNo: Integer): Integer;
var  Weighings    : LONGINT;
    Wt           : DOUBLE;
    PassNo       : INTEGER; { 1 = From Current line No; 2 = line 1..StartLineNo-1}
    IsAChildLine : BOOLEAN;
    UseLineNo    : Integer;
begin
 Result := 0;
 PassNo := 1;
 UseLineNo := StartLineNo;
 repeat
  pvtblOrderLine.FindNearest([pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                              pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger,
                              UseLineNo-1]);
  IsAChildLine := (not pvtblOrderLine.Eof) and
                  (pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger =
                   pvtblOrderLine.FieldByName(OL_OrderNo).AsInteger) and
                  (pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger =
                   pvtblOrderLine.FieldByName(OL_OrderNoSuffix).AsInteger);
  if IsAChildLine then {can it be worked on}
   begin
    SynchIngredientsCacheWithCode(pvtblOrderLine.FieldByName(OL_Ingredient).AsString);
    if IngredientIsInPrepArea(rxmIngredientsCache) then
     begin
      GetTotsForMixLine(pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                        pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger,
                        GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger},
                        pvtblOrderLine.FieldByName(OL_LineNo).AsInteger,
                        Weighings, Wt);
      if not IsThisLineCompleteForCurrMix(Weighings,Wt) then
       begin
        Result := pvtblOrderLine.FieldByName(OL_LineNo).AsInteger;
        Break;
       end;
     end;
   end;

  { NOT FOUND A LINE YET }
  if (PassNo > 1) and
     (IsAChildLine) and
     (pvtblOrderLine.FieldByName(OL_LineNo).AsInteger = (StartLineNo-1)) then
    Break; { come back to start point }

  if (not IsAChildLine) then
   begin
    if (PassNo = 1) and
       (StartLineNo > 1) then
     begin
      UseLineNo := 0;
      Inc(PassNo);
     end
    else Break;
   end;
 until FALSE;
end;

function TdmFormix.WeighInDiffContainer(NoOfContainersReqd: Integer): Boolean;
begin
 Result := FALSE;
  if pvtblOrderLine[OL_ProcessType] = PTWeight then
  begin
    if (pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger <> CurrentOrderNo) or
       (pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger <> CurrentSuffix) or
       (pvtblOrderHeader.FieldByName(OH_CurrentMix).AsInteger <> CurrentMixNo) then
      Result := TRUE;
    if not Result then
    begin
      if TMixType(pvtblOrderHeader.FieldByName(OH_MixType).AsInteger) in MixSet_AutoTareAfterWeighing then
      begin { container has been tared off - only works if no.of conts = 1 }
        if NoOfContainersReqd > 1 then { they will have to be segregated }
          Result := TRUE;
      end
      else
      begin
(*      if TMixType(pvtblOrderHeader.FindField(OH_MixType).AsInteger) in MixSet_ProportionallyMixedConts then
        begin
          if GetCurrentContainerNo <> CurrentContNo then
            Result := TRUE;
        end
        else
        begin
          if (pvtblOrderLine.FindField(OL_LineNo).AsInteger <> CurrentLineNo) or
             (GetCurrentContainerNo <> CurrentContNo) then
            Result := TRUE;
        end;*)
      end;
    end;
  end;
 {Reset Varaibles}
  CurrentOrderNo := pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger;
  CurrentSuffix  := pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger;
// CurrentMixNo   := pvtblOrderHeader.FieldByName(OH_CurrentMix).AsInteger;
  CurrentLineNo  := pvtblOrderLine.FieldByName(OL_LineNo).AsInteger;
  CurrentContNo  := GetCurrentContainerNo;
end;

procedure TdmFormix.DataModuleCreate(Sender: TObject);
var
  LogFolderPath : string;
begin
  inherited;
  LogFolderPath := '.\LogFiles';
  if not DirectoryExists(LogFolderPath) then
  begin
    if not CreateDir(LogFolderPath) then
      LogFolderPath := '.';
  end;
  New(fMixRpt, Init(LogFolderPath+'\',
                    'MixProgressLog.TXT','MixProgressLogB4.TXT',
                    'MIX PROGRESS LOG'+#13#10#13#10));

  CurrentOrderNo := 0;
  CurrentSuffix  := 0;
  CurrentMixNo   := 0;
  CurrentLineNo  := 0;
  CurrentContNo  := 0;
  SetCurrentUser('');
  CurrentUserIsIdle := false;
  LastOrderNumber :='';
  LastMixNumber   :=0;
  CurrentCompensatedBatchMixWt := 0;
  UsePreCalcedCompensatedBatchMixWt := FALSE;
  ClearWeighingDetails;
  ClearSelectedLineDetails;
end;

procedure TdmFormix.MarkMixCompleteIfNecess;
{REQUIRES: Mix status to have been confirmed as complete by CalcMixStatus().
 PROMISES: 1. Reads current mix and order header from file.
           2. If the mix is not currently marked as complete then will mark it complete
              and increment the mix done count on the related order header.
}
var NewDBTrans : boolean;
    AddToStockFops6TranStr : string;
    MixOk : boolean;
    FopsPluNo : integer;
    MixIdStrForLog : string;
begin
  try
    if not pvtblMixTotal.Active then pvtblMixTotal.Open;
    MixOk := pvtblMixTotal.Locate(MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo,
                             VarArrayOf([pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                         pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger,
                                         GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger}]),[]);
    if MixOk then
    begin
      {Relocate the header in to stop error 88}
      if  (not pvtblMixTotal.FieldByName(MIX_Complete).AsBoolean)
      and pvtblOrderHeader.Locate(OH_OrderNo+';'+OH_OrderNoSuffix,
                                varArrayOf([pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                            pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger]),[]) then
      begin
        FopsPluNo := 0;
        if fAddMixToFopsStock then
        begin
          if dmFops = nil then //wont happen - program should have terminated.
          begin
            TermMessageDlg('Cannot mark mix as Complete without'+#13#10+
                           'connecting to the FOPS database on start-up.', mtWarning, [mbOk], 0);
            MixOk := false;
          end
          else
          begin
            FopsPluNo := dmFops.GetFops6PluNumberForIngredient(pvtblOrderHeader.FieldByName(OH_RecipeCode).AsString);
            if FopsPluNo = 0 then
            begin
              TermMessageDlg('FOPS PLU number not found for recipe code.'+#13#10+
                             'Mix cannot be marked as complete.',mtError,[mbOk],0);
              MixOk := false;
            end;
          end;
        end;

        if MixOk then {MixTotal and OrderHeader are located; and FopsPluNo <> 0 if fAddMixToFopsStock}
        begin
          MixIdStrForLog := 'Order '+
                         OrderNoToString(pvtblMixTotal.FieldByName(MIX_OrderNo).AsInteger,
                                         pvtblMixTotal.FieldByName(MIX_OrderNoSuffix).AsInteger)+
                         ', Mix '+ pvtblMixTotal.FieldByName(MIX_MixNo).AsString;
          NewDBTrans := not pvtblOrderHeader.Database.InTransaction;
          if NewDBTrans then
          begin
            pvtblOrderHeader.Database.StartTransaction;
            LogMixProgress(MixIdStrForLog+' starting new Formix DB Transaction for Mix Completion.');
          end
          else
            LogMixProgress(MixIdStrForLog+' using caller''s DB Transaction for Mix Completion.');
          try
            {Update Mix}
            pvtblMixTotal.Edit;
            pvtblMixTotal.FieldByName(MIX_Complete).AsBoolean := TRUE;
            pvtblMixTotal.Post;

            {Update Order Header}
            pvtblOrderHeader.Edit;
            pvtblOrderHeader.FieldByName(OH_MixesDone).AsInteger := pvtblOrderHeader.FieldByName(OH_MixesDone).AsInteger+1;
            if pvtblOrderHeader.FieldByName(OH_MixesDone).AsInteger >=
                           pvtblOrderHeader.FieldByName(OH_MixesRequired).AsInteger then
              pvtblOrderHeader.FieldByName(OH_Status).AsInteger := 2;
            pvtblOrderHeader.Post;

            if not NewDBTrans then
              LogMixProgress(MixIdStrForLog + ' marked as Complete within DB Transaction.');

            if fAddToFormixStock then
              AddStockRecord(pvtblOrderHeader.FieldByName(OH_RecipeCode).AsString,
                             pvtblMixTotal.FieldByName(MIX_WeightDone).AsFloat);

            if fAddMixToFopsStock then {add record to FOPS database }
            begin
              {FOPS database is separate from the current "database transaction"
               but the writing to the comm buffer might raise an exception,
               possibly causing a rollback (see below) on the formix database.
              }
              AddToStockFops6TranStr := GetMixLabelBarcode(FopsPluNo);
              if AddToStockFops6TranStr <> '' then
              begin
                AddToStockFops6TranStr := '2,A,0,,,'+
                                          (dmFormix.BatchPrefixForFops +
                                              ZeroPad(Trim(dmFormix.GetBatchStrForFormixTran),6,true{preceeding}))+
                                          ',APRODN,,,'+AddToStockFops6TranStr+',';
                SendCommandToFops(AddToStockFops6TranStr);
                LogMixProgress('Command written to FOPS Comm Buffer: '+ AddToStockFops6TranStr);
              end
              else
                raise Exception.Create('Failed to construct FOPS "Add as Production" command.');
            end;
            if NewDBTrans then {commit formix database update}
            begin
              pvtblOrderHeader.Database.Commit;
              LogMixProgress(MixIdStrForLog + ' marked as Complete in the database.');
            end;
          except
            on E: exception do
            begin
              if NewDBTrans then
              begin
                pvtblOrderHeader.Database.Rollback;
                LogMixProgress(MixIdStrForLog+' completion error: '+e.Message);
                TermMessageDlg('Error completing mix'+#13#10+E.Message,mtWarning,[mbOk],0);
              end;
              pvtblOrderHeader.Cancel;
              pvtblMixTotal.Cancel;
            end;
          end;
        end;
      end;
    end;
  except
    on e: exception do
      TermMessageDlg('Error reading mix for completion'+#13#10+E.Message,mtWarning,[mbOk],0);

  end;
end;

(* not needed because CalcMixStatus() has already done this.
function TdmFormix.AllLinesCompleteForCurrentMix: Boolean;
var WrkCount: Integer;
    WrkWeight : Double;
begin
 Result := FALSE;
 pvtblOrderLine.FindNearest([pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                             pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                             MaxLongint]);
 if not pvtblOrderLine.Bof then pvtblOrderLine.Prior; !!!!! what about last record in range?
 while (not pvtblOrderLine.Bof) and
       (pvtblOrderHeader.FindField(OH_OrderNo).AsInteger =
        pvtblOrderLine.FindField(OL_OrderNo).AsInteger) and
       (pvtblOrderHeader.FindField(OH_OrderNo).AsInteger !!!!!!=
        pvtblOrderLine.FindField(OL_OrderNo).AsInteger) !!!!!!!!do
  begin
   WrkCount := 0;
   WrkWeight := 0;
   GetTotsForMixLine(pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                     pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                     GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger},
                     pvtblOrderLine.FindField(OL_LineNo).AsInteger,
                     WrkCount,WrkWeight);
   if not IsThisLineCompleteForCurrMix(WrkCount,WrkWeight) then Exit;
   pvtblOrderLine.Prior;
  end;
 Result := TRUE;
end;
*)
procedure TdmFormix.AddStockRecord(ForIngredient: String;
  AddWeight: Double);
{REQUIRES: Caller to have started a database transaction.
}
begin
 if not pvtblStock.Active then pvtblStock.Open;
 if pvtblStock.Locate(STK_Product,ForIngredient,[]) then
  begin
   pvtblStock.Edit;
   pvtblStock.FieldByName(STK_InStock).AsInteger := pvtblStock.FieldByName(STK_InStock).AsInteger+1;
   pvtblStock.FieldByName(STK_Weight).AsFloat    := pvtblStock.FieldByName(STK_Weight).AsFloat+AddWeight;
   pvtblStock.Post;
  end
 else
  begin
   pvtblStock.AppendRecord([ForIngredient,
                            1,
                            AddWeight,
                            #0,#0,#0]);
  end;
end;

procedure TdmFormix.GetCompleteInAreaStatForMixes(var CurrMixCompInArea : boolean;
                                                  var NoOfMixesCompInArea : integer;
                                                  MixNoOfCurrentMix: Integer);
{REQUIRES: 1. OrderHeader to be current in dmFormix.
}
var
  MixCompleted,
  MixCompletedInPrepArea : boolean;
  SaveCurrentMixNo : integer;
  SaveOrderLineNo : integer;
begin
  CurrMixCompInArea   := false;
  NoOfMixesCompInArea := 0;
  SaveCurrentMixNo := CurrentMixNo;
  SaveOrderLineNo := pvtblOrderLine.FieldByName(OL_LineNo).AsInteger;
  try
    {CalcMixStatus() requires pvtblOrderLines to be ranged for pvtblOrderHeader}
    pvtblOrderLine.IndexName := 'ByOrderLine';
    pvtblOrderLine.SetRange([pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                             pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger],
                            [pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                             pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger]);
    try
      pvtblMixTotal.IndexFieldNames := MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo;
      pvtblMixTotal.SetRange([pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                              pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger],
                             [pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                              pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger]);
      try
        pvtblMixTotal.First;
        while not pvtblMixTotal.Eof do
        begin
          MixCompletedInPrepArea := pvtblMixTotal.FieldByName(MIX_Complete).AsBoolean;
          if not MixCompletedInPrepArea then//maybe it is complete in prep area - calculate
          begin
            {CalcMixStatus() requires CurrentMixNo to be set to mix in question - get restored later}
            CurrentMixNo := pvtblMixTotal.FieldByName(MIX_MixNo).AsInteger;
            CalcMixStatus(MixCompletedInPrepArea, MixCompleted);
          end;
          if MixCompletedInPrepArea then
          begin
            Inc(NoOfMixesCompInArea);
            if pvtblMixTotal.FieldByName(MIX_MixNo).AsInteger = MixNoOfCurrentMix then
              CurrMixCompInArea := true;//set var function parameter
          end;
          pvtblMixTotal.Next;
        end;
      finally
        pvtblMixTotal.CancelRange;
      end;
    finally
      //pvtblOrderLine.CancelRange; dont - caller might have SetRange as well.
    end;
  finally
    CurrentMixNo := SaveCurrentMixNo;
    RestorePositionOfWorkingTables(pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                   pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                                   SaveOrderLineNo);
  end;
end;

function TdmFormix.SetCurrMixNoToAnUnfinishedMix: TFindMixResult;
var WrkMix: Integer;
    NewDBTrans : boolean;
    MixesStillNeedWork,
    AllMixesFinishedInAllAreas : boolean;

  procedure SearchForwardUpToMixNo(MaxMixNo: Integer; var MixesStillNeedWorkInSomeAreas : boolean);
  //edited by TB
  {REQUIRES: WrkMix to be set to first mix to be checked for outstanding weighings.
   PROMISES: WrkMix to be set to first mix with outstanding weighings, otherwise MaxMixNo+1.
  }
  var
    SaveCurrentMixNo : integer;
    MixFinishedInPrepArea, MixIsComplete : boolean;
  begin
    MixesStillNeedWorkInSomeAreas := false;
    SaveCurrentMixNo := CurrentMixNo;
    while (WrkMix <= MaxMixNo) do
    begin
      // check status on mix record first
      if not IsMixComplete(pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                           pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger,
                           WrkMix) then // check if this area can work on mix
      begin
        MixesStillNeedWorkInSomeAreas := true;
        CurrentMixNo := WrkMix;
        if  CalcMixStatus(MixFinishedInPrepArea, MixIsComplete)
        and (not MixFinishedInPrepArea) then
          break;
         {*****}
      end;
      Inc(WrkMix);
    end;
    CurrentMixNo := SaveCurrentMixNo;
  end;

begin
 {Find the next available mix}
 Result := FM_MixFound;
 AllMixesFinishedInAllAreas := true;
 {CalcMixStatus() requires pvtblOrderLine to be ranged.}
 pvtblOrderLine.IndexName := 'ByOrderLine';
 pvtblOrderLine.SetRange([pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                          pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger],
                         [pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                          pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger]);
 try
   WrkMix := GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger};
   SearchForwardUpToMixNo(pvtblOrderHeader.FieldByName(OH_MixesRequired).AsInteger,
                          MixesStillNeedWork);
   if MixesStillNeedWork then
     AllMixesFinishedInAllAreas := false;
   if WrkMix > pvtblOrderHeader.FieldByName(OH_MixesRequired).AsInteger then
   begin
     if GetCorrectMixNo > 1 then //see if previous mixes still need work
     begin
       WrkMix := 1;
       SearchForwardUpToMixNo(GetCorrectMixNo -1, MixesStillNeedWork);
       if MixesStillNeedWork then
         AllMixesFinishedInAllAreas := false;
       if WrkMix >= GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger} then
       begin
         if AllMixesFinishedInAllAreas then
           Result := FM_AllMixesComplete
         else
           Result := FM_MixesFinishedInArea;
       end
       else
         Result := FM_PrevMixFound;
     end
     else
     begin
       if AllMixesFinishedInAllAreas then
         Result := FM_AllMixesComplete
       else
         Result := FM_MixesFinishedInArea;
     end;
     {Relocate the header in to stop error 88}
     if pvtblOrderHeader.Locate(OH_OrderNo+';'+OH_OrderNoSuffix,
                               varArrayOf([pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                           pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger]),[]) then
     begin
       NewDBTrans := not pvtblOrderHeader.Database.InTransaction;
       try
         if NewDBTrans then
           pvtblOrderHeader.Database.StartTransaction;
         pvtblOrderHeader.Edit;
         if Result = FM_AllMixesComplete then // set order status to complete and mix number to highest
         begin
           pvtblOrderHeader.FieldByName(OH_CurrentMix).AsInteger :=
                       pvtblOrderHeader.FieldByName(OH_MixesRequired).AsInteger;
           pvtblOrderHeader.FieldByName(OH_Status).AsInteger := 2;
         end
         else if Result = FM_MixesFinishedInArea then //other areas still have work to do - reset mix no
           pvtblOrderHeader.FieldByName(OH_CurrentMix).AsInteger := 1
         else  // set mix number to one found for this area
           pvtblOrderHeader.FieldByName(OH_CurrentMix).AsInteger := WrkMix;
         // check we havent set mix number too high
         if pvtblOrderHeader.FieldByName(OH_CurrentMix).AsInteger >
                       pvtblOrderHeader.FieldByName(OH_MixesRequired).AsInteger then
           pvtblOrderHeader.FieldByName(OH_CurrentMix).AsInteger :=
                       pvtblOrderHeader.FieldByName(OH_MixesRequired).AsInteger;
         pvtblOrderHeader.Post;
         if NewDBTrans then
           pvtblOrderHeader.Database.Commit;
       except
         on E: exception do
         begin
           if NewDBTrans then
           begin
             pvtblOrderHeader.Database.RollBack;
             TermMessageDlg('Error updating current mix number on order.'+#13#10+E.Message,mtWarning,[mbOk],0);
           end;
           pvtblOrderHeader.Cancel;
         end;
       end;
     end;
   end
   else
   begin
     {Relocate the header in to stop error 88}
     if pvtblOrderHeader.Locate(OH_OrderNo+';'+OH_OrderNoSuffix,
                               varArrayOf([pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                           pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger]),[]) then
     begin
       NewDBTrans := not pvtblOrderHeader.Database.InTransaction;
       try
         if NewDBTrans then
           pvtblOrderHeader.Database.StartTransaction;
         pvtblOrderHeader.Edit;
         pvtblOrderHeader.FieldByName(OH_CurrentMix).AsInteger := WrkMix;
         pvtblOrderHeader.Post;
         if NewDBTrans then
           pvtblOrderHeader.Database.Commit;
       except
         on E: exception do
         begin
           if NewDBTrans then
           begin
             pvtblOrderHeader.Database.RollBack;
             TermMessageDlg('Error updating current mix number on order.'+#13#10+E.Message,mtWarning,[mbOk],0);
           end;
           pvtblOrderHeader.Cancel;
         end;
       end;
     end;
   end;
 finally
   //pvtblOrderLine.CancelRange; dont - caller might have set range as well.
 end;
end;

procedure TdmFormix.CancelPreCalcCompensatedBatchMixWt;
begin
  UsePreCalcedCompensatedBatchMixWt := FALSE;
  CurrentCompensatedBatchMixWt := 0;
end;

procedure TdmFormix.PreCalcCompensatedBatchMixWt;
begin
  UsePreCalcedCompensatedBatchMixWt := TRUE;
  CurrentCompensatedBatchMixWt := CalcCompensatedBatchMixWt(GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger});
end;

function TdmFormix.GetContainerNumber: Integer;
var ContsDone: Integer;
    MixLRec: TMixLineRecord;
begin
 Result := 0;
 ConstructMixLineRecForOrdLine(GetCorrectMixNo{pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger},MixLRec);
 ContsDone := 0;
 if frmFormixProcessRecipe.rmdIngredients.FieldByName('WeighsPerContainer').AsFloat > 0 then { no divide by 0 problems }
   Result := (MixLRec.ML_WghsDone DIV frmFormixProcessRecipe.rmdIngredients.FieldByName('WeighsPerContainer').AsInteger);
 Result := Result + 1;
end;
(*
procedure TdmFormix.DelayCurrentMix;
var MixFindErr: TFindMixResult;
begin
 {Need to delay the current mix and then go onto the next available mix,
  also needs to reset the current mix value on the order header}
 if (CompareWts(pvtblOrderHeader.FindField(OH_TotalWeightDone).AsFloat,0.0) <= 0) or
    (not (pvtblMixTotal.Locate(MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo,
                               VarArrayOf([pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                               pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                               1]),[]))) then
  begin
   TermMessageDlg('Unable to delay first mix without weighing to it',mtInformation,[mbOk],0);
   Exit;
  end;

 if GetTermRegInteger(r_NoOfMixTickets,0) > 0 then
  begin
   if TermMessageDlg('Do you wish to print a ticket'+#13+
                     'for the Mix being delayed?',mtConfirmation,[mbYes,mbNo],0) = mrYes then
     begin
      PrintMixTicket(-1);
     end;
  end;

 MixFindErr := SetCurrMixNoToAnUnfinishedMix;
 {Relocate the header in to stop error 88}
 if pvtblOrderHeader.Locate(OH_OrderNo+';'+OH_OrderNoSuffix,
                            varArrayOf([pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                        pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger]),[]) then
  begin
   pvtblOrderHeader.Edit;
   pvtblOrderHeader.FindField(OH_Updates).AsInteger :=
                    pvtblOrderHeader.FindField(OH_Updates).AsInteger + 1;
   pvtblOrderHeader.Post;
  end;

 frmFormixProcessRecipe.BuildProductList;

old code
VAR
    OrdHRec     : TWOHeaderRecord;
    HeadReadErr : INTEGER;
    MixFindErr  : TFindMixResult;
    TicketWanted : BOOLEAN;
    SaveMixNo   : LONGINT;
    CurrScaleTaskstate : TScaleTaskState;
BEGIN
 SaveMixNo := SelRecs.WorkHRecord.WOH_CurrentMix;
{Read all lines and set Containers done etc to zero}

 StopScaleTasks(CurrScaleTaskState);           { Save State Of Scale Tasks }
 TicketWanted := FALSE;
 IF FXDETAIL.GetNumberofMixTickets > 0 THEN
   TicketWanted := YesNoWin('  Do You Wish To Print A Ticket'+CRLF+
                            '   For The Mix Being Delayed');

 OpenOrderRelatedFiles;

 HeadReadErr := SelRecs.LockHeaderRecord;
 IF HeadReadErr = 0 THEN
  BEGIN
   OrdHRec := SelRecs.WorkHRecord;
   IF TicketWanted THEN
     Print_Partial_Mix_Ticket(FXDETAIL.GetNumberofMixTickets);
   MixFindErr := SetCurrMixNoToAnUnfinishedMix(OrdHRec);
   INC(OrdHRec.WOH_UpdateCount);
   WorkHeaderFile^.UpdateRecord(OrdHRec);
   SelRecs.WorkHRecord := OrdHRec;
   SelRecs.SetCurrentMixNoTo(OrdHRec.WOH_CurrentMix); { resets batch no. etc }
   DisplayMixSearchResult(MixFindErr);
  END;

 RestoreScaleTasks(CurrScaleTaskstate);         { Restore Scale Tasks }

 IF SelRecs.WorkHRecord.WOH_CurrentMix <> SaveMixNo THEN
  BEGIN
   PrimeNextIngredient(NP_MixNoChg,
                       'Mix '+ IntToStr(SaveMixNo,1)+ ' delayed.');
  END;

end;
*)
procedure TdmFormix.ClearSourceItemDetails;
begin
 SourceBarcode  := SPACESTRING;
 SourceItemLabelBarcode := SourceBarcode;
 CurrSourceWtKg := 0.0;
 SourceItemCheckedAt := 0;
 OrigSourceWtKg := 0.0;
 SourceWtCheckBypassReason := '';
 UseSourceWt    := FALSE;
 SourceLifeJDay   := 0;
 SourceLotCode := '';
 SourceProdCode := '';
 SourceItemFopsMcNo  := 0;
 SourceItemFopsSerNo := 0;
 memtabWarningsOverriden.Active := true;
 memtabWarningsOverriden.EmptyTable;
end;

procedure TdmFormix.ClearWeighingDetails;
begin
  ClearSourceItemDetails;
  CurrIngredientTempEntered := false;
  CurrIngredientTemperatureStr := '';
end;

procedure TdmFormix.ClearSelectedLineDetails;
begin
  SelectedLineIsAutoWeigh := false;
end;

function TdmFormix.GetExpandedSourceBarcode : string;
{PROMISES: If the source barcode entry identified a transaction in FOPS then it
           returns the label barcode of that transaction, otherwise it returns
           the barcode entered (trimmed).
}
begin
  if Trim(SourceItemLabelBarcode) = '' then {tran not found}
    Result := Trim(SourceBarcode)
  else
    Result := SourceItemLabelBarcode;
end;

function TdmFormix.SourceBarcodeRelatesToAFopsTran : boolean;
begin
  Result := (Length(Trim(SourceItemLabelBarcode)) >= 20)
        and (Trim(SourceProdCode) <> '');
end;

function TdmFormix.BarcodeIsAMixBarcode(const Barcode : string) : boolean;
begin
  Result := false;
  if (Length(Barcode) = 14) then
    Result := StrOnlyHasDigits(Barcode)
  else if (Length(Barcode) = 31) then
    Result := (Barcode[1] = 'M')
          and StrOnlyHasDigits(Copy(Barcode,2,30));
end;

function TdmFormix.GetOrderNoFromMixBarcode(const Barcode : string) : integer;
begin
  Result := 0;
  if BarcodeIsAMixBarcode(Barcode) then
    Result := StringToLong(Copy(Barcode,1,6));
end;

function TdmFormix.GetOrdNoSuffixFromMixBarcode(const Barcode : string) : integer;
begin
  Result := 0;
  if BarcodeIsAMixBarcode(Barcode) then
    Result := StringToLong(Copy(Barcode,7,2));
end;

function TdmFormix.GetMixNoFromMixBarcode(const Barcode : string) : integer;
begin
  Result := 0;
  if BarcodeIsAMixBarcode(Barcode) then
    Result := StringToLong(Copy(Barcode,9,4));
end;

function TdmFormix.BarcodeIsACranswickNavBarcode(const Barcode : string) : boolean;
var ProdCode : string;
begin
  Result := (Length(Barcode) IN fSetOfLazenbyNavBarLengths);
  if Result then
  begin
    ProdCode := GetProdCodeFromCranswickNavBarcode(Barcode);
    if (Trim(ProdCode) = '') then
      Result := false
    else if (Length(Barcode) = 20) and (ProdCode[1] in ['0'..'9']) then {might be a HSL 20 barcode}
      Result := false;
  end;
end;

function TdmFormix.GetProdCodeFromCranswickNavBarcode(const NavBarcode : string) : string;
begin
  if fNavBarcodeHasProdFirst then //Norfolk NAV
    Result := Copy(NavBarcode,1,8)
  else //Lazenbys NAV
  begin
    case Length(NavBarcode) of
      14 : Result := Copy(NavBarcode,7,8);
      18 : Result := Copy(NavBarcode,11,8);
      else Result := '';
    end;
  end;
end;

function TdmFormix.GetDateFromCranswickNavBarcode(const NavBarcode : string; var ADateTime : TDateTime) : boolean;
{PROMISES: 1. Only returns true if there is a YYMMDD at fNavBarcodeDtPos that is valid and
              is between 5 years ago and 20 years in the future.
           2. ADateTime is only set if this function returns true.   
}
var
  Year,Month,Day : integer;
  AbbrYear : integer;
  YearsLeft : integer;
begin
  Result := false;
  if  (fNavBarcodeDtPos > 0)
  and (Length(NavBarcode) >= (fNavBarcodeDtPos+6)) then//long enough for YYMMDD and a lot code
  begin
    if TryStrToInt(Copy(NavBarcode, fNavBarcodeDtPos, 2), AbbrYear) then//YY is numerical
    begin
      Month := 0;
      TryStrToInt(Copy(NavBarcode, fNavBarcodeDtPos+2, 2), Month);
      Day := 0;
      TryStrToInt(Copy(NavBarcode, fNavBarcodeDtPos+4, 2), Day);
      Year := 2000 + AbbrYear;//ok until year 2080?
      YearsLeft := Year - YearOf(Today);
      if  (YearsLeft >= -5)
      and (YearsLeft <= 20)
      and IsValidDate(Year, Month, Day) then
      begin
        ADateTime := EncodeDate(Year, Month, Day);
        Result := true;
      end;
    end;
  end;
end;

function TdmFormix.GetLotCodeFromCranswickNavBarcode(const NavBarcode : string) : string;
var
  LotCodePos : integer;
  TempDate : TDateTime;
begin
  if fNavBarcodeHasProdFirst then //Norfolk NAV
  begin
    if GetDateFromCranswickNavBarcode(NavBarcode, TempDate) then
      LotCodePos := fNavBarcodeDtPos+6
    else
      LotCodePos := 9;
    Result := Copy(NavBarcode,LotCodePos, 10)
  end
  else //Lazenbys NAV
  begin
    case Length(NavBarcode) of
      14 : Result := Copy(NavBarcode,1,6);
      18 : Result := Copy(NavBarcode,1,10);
      else Result := '';
    end;
  end;
end;

function TdmFormix.SourceBarcodeIsACranswickNavBarcode : boolean;
begin
  Result := BarcodeIsACranswickNavBarcode(SourceBarcode);
end;

function RejectReasonToOverrideSecurityToken(RejectionReason : TOverrideType) : TSecurityToken;
begin
  case RejectionReason of
    override_INCORRECTPROD : Result := SECTOK_FX_OVERR_SRCPROD;
    override_LIFEEXPIRED   : Result := SECTOK_FX_OVERR_LIFEDT;
    override_EMPTY         : Result := SECTOK_FX_OVERR_SRCEMPTY;
    else                     Result := SECTOK_FX_OVERR_SRCEMPTY;
  end;
end;

function TdmFormix.GetUsersAccessLevel(ForUser: String): Integer;
begin
 Result := 0;
 ForUser := UpperCase(ForUser); //Formix holds User codes and passwords upper cased. UserCode index is case sensitive.
 if pvtblUserName.Locate(UN_UserName,ForUser,[]) then
   Result := pvtblUserName.FieldByName(UN_AccessLevel).AsInteger;
end;

function TdmFormix.GetCorrectMixNo: Integer;
begin
 if CurrentMixNo = 0 then
   Result := pvtblOrderHeader.FieldByName(OH_CurrentMix).AsInteger
 else Result := CurrentMixNo;
end;

procedure TdmFormix.dsOrderHeaderDataChange(Sender: TObject;
  Field: TField);
begin
 {If the event fired is an update event then we need to rebuild the current product list}
  inherited;
//  frmFormixProcessRecipe.BuildProductList;
end;

function TdmFormix.MakeAPdcuIssueCommandStr(const ForBarcode : string; BatchNo : integer) : string;
begin
{
-- PDCU Stock Movement frame
----------------------------
-- CommsTranType,SubTranType,PrinterPort,OrderNo,PalNo,BatchNo,Action,User,Tare,Barcode,
-- DateBarcode,Location,OpDate_dd/mm/yyyy,OpTime_hh:mm,MoveWt,ActWt,LineNo,Reason,LeanGrPerkg,SourceBarcode,
-- MoveItems,IgnoreCutNo,Category,Grade,KillDate_ddmmyy,PackDate_ddmmyy,MatureDate_ddmmyy,MaxLifeDate_ddmmyy,FirstDesignation,NextDesignation,
-- ProdCodeOverr
}
  Result := '2,A,0,,,'+IntToStr(BatchNo)+',I,,,'+ForBarcode+',';
end;

function TdmFormix.GetFops6TranStr(Weight  : DOUBLE;
                         FullIssueOffStock : BOOLEAN) : string;
{REQUIRES: 1. Formix Transaction to have been added to the DB.
           2. pvtblTransactions to be located on Formix Transaction added.
           3. SourceItemLabelBarcode to reflect source of Formix Transaction added.
           4. SourceProdCode to reflect source of Formix Transaction added.
{NOTE: This constructs an OCM transaction string so that where SourceItemLabelBarcode
       is not found in the FOPS database, a new FOPS transaction is created for
       the issued weight with a MID and serial number matching this terminal's
       FORMIX transaction! i.e. only use SFXAllowTranNotFound=TRUE with
       SFXSendFopsIssueTrans=TRUE if FORMIX and FOPS terminal mids dont clash.
}
var
    WtStr     : string[5];
    PlunoStr  : string[4];
    PluNo     : Integer;
    FormixTrnBatNo : integer;
begin
 { use CSV format so we can send 8 digit batch number }
 Result := '';
 WtStr := IntToZeroStr(Double_To_FPLong(Weight,2),5);
 if FullIssueOffStock or (Trim(SourceItemLabelBarcode) = '') then
   Result := 'F,D,'
 else
   Result := 'F,I,'; { part issue }
 Result := Result + '3,';{ LZB3 = 2dp }

 PluNo := 0;
 if (Length(Trim(SourceItemLabelBarcode)) <> 20)
 or (not TryStrToInt(Copy(SourceItemLabelBarcode,9,4), PluNo)) then //not a properly populated 20 digit barcode
 begin
   if SourceProdCode <> '' then
     PluNo := dmFops.GetFops6PluNumberForIngredient(SourceProdCode)
   else
     PluNo := dmFops.GetFops6PluNumberForIngredient(pvtblTransactions.FieldByName(TRN_Ingredient).AsString);
  end;
 if PluNo = 0 then
   PluNo := 9999;
 PluNoStr := IntToZeroStr(PluNo,4);

 Result := Result + PluNoStr;
 Result := Result +','+ WtStr+','+                 { LabelWt       }
                    IntToStr(pvtblTransactions.FieldByName(TRN_MID).AsInteger)+','+      { Machine ID    }
                    IntToStr(pvtblTransactions.FieldByName(TRN_SerialNo).AsInteger)+','; { Serial No     }
 {Add batch number}
 if pvtblTransactions.FieldByName(TRN_BatchNo).IsNull then
   FormixTrnBatNo := 0
 else
   FormixTrnBatNo := StringToLong(pvtblTransactions.FieldByName(TRN_BatchNo).AsString);
 if FullIssueOffStock then
   Result := Result + '99999999,' {avoid normal batches}
 else if FormixTrnBatNo > 0 then
   Result := Result + BatchPrefixForFops+ IntToZeroStr(FormixTrnBatNo, 6)+','
 else
   Result := Result + '0,';{zero will get autobatched by fops}
 Result := Result + FormatDateTime('DDMMYY',Date)+','+       { Pack Date     }
                    Copy(GetCurrentUser,1,4)+','+            { User Code     }
                    WtStr+','+                               { Gross Wt      }
                    WtStr+','+                               { ActualWt      }
                    'K,'+                                    { Wt Range      }
                    ','+                                     { Pallet        }
                    FormatDateTime('DDMMYY',Date)+','+       { MinLife Date  }
                    FormatDateTime('DDMMYY',Date)+','+       { MaxLife Date  }
                    '1,'+                                    { Items         }
                    SourceItemLabelBarcode+
                    CHR(ETX);
end;
(*
////////////////////////////////////////////////////////////////////////////////
//Seperate section for each scale configuration
//if scale is 1 then original section name is used for compatibility
function TdmFormix.GetScaleINISection(ScaleNo: Integer) : String;
begin
  Result := REG_Scale+TerminalName;
  if ScaleNo > 1 then
    Result := Result + '.'+IntToStr(ScaleNo);
end;
*)

function TdmFormix.GetLastUsedScale : Integer;
begin
  Result := GetTermRegInteger(r_CurrentWeighScale);
end;

procedure TdmFormix.SetLastUsedScale;
begin
  SetTermRegInteger(r_CurrentWeighScale,CurrentScale);
end;

function TdmFormix.GetScaleType(ScaleNo: Integer) : Integer; //0=Serial 1=IP
begin
  case ScaleNo of
    1 : Result := GetTermRegInteger(r_S1_ScaleType);
    2 : Result := GetTermRegInteger(r_S2_ScaleType);
    else Result := 0;
  end;
end;

procedure TdmFormix.SetScaleType(ScaleNo: Integer; ScaleType: Integer); //0=Serial 1=IP
begin
  case ScaleNo of
    1 : SetTermRegInteger(r_S1_ScaleType, ScaleType);
    2 : SetTermRegInteger(r_S2_ScaleType, ScaleType);
  end;
end;

function TdmFormix.GetScaleModel(ScaleNo: Integer) : Integer; //0=CSW 1=Rinstrun 2=Mettler
begin
  case ScaleNo of
    1 : Result := GetTermRegInteger(r_S1_ScaleModel);
    2 : Result := GetTermRegInteger(r_S2_ScaleModel);
    else Result := 0;
  end;
end;

procedure TdmFormix.SetScaleModel(ScaleNo: Integer; ScaleModel: Integer); //0=CSW 1=Rinstrun 2=Mettler
begin
  case ScaleNo of
    1 : SetTermRegInteger(r_S1_ScaleModel, ScaleModel);
    2 : SetTermRegInteger(r_S2_ScaleModel, ScaleModel);
  end;
end;

function TdmFormix.GetScaleSerialConfig(ScaleNo: Integer) : String;
begin
  case ScaleNo of
    1 : Result := GetTermRegString(r_S1_ScaleSetup);
    2 : Result := GetTermRegString(r_S2_ScaleSetup);
    else Result := '';
  end;
end;

procedure TdmFormix.SetScaleSerialConfig(ScaleNo: Integer; ConfigStr: String);
begin
  case ScaleNo of
    1 : SetTermRegString(r_S1_ScaleSetup, ConfigStr);
    2 : SetTermRegString(r_S2_ScaleSetup, ConfigStr);
  end;
end;

function TdmFormix.GetScaleIPConfig(ScaleNo: Integer) : String;
begin
  case ScaleNo of
    1 : Result := GetTermRegString(r_S1_IPScaleSetup);
    2 : Result := GetTermRegString(r_S2_IPScaleSetup);
    else Result := '';
  end;
end;

procedure TdmFormix.SetScaleIPConfig(ScaleNo: Integer; ConfigStr: String);
begin
  case ScaleNo of
    1 : SetTermRegString(r_S1_IPScaleSetup, ConfigStr);
    2 : SetTermRegString(r_S2_IPScaleSetup, ConfigStr);
  end;
end;

function TdmFormix.GetScaleMaxWeight(ScaleNo : Integer) : Double;

begin
  case ScaleNo of
    1 : Result := GetTermRegDouble(r_S1_ScaleMax);
    2 : Result := GetTermRegdouble(r_S2_ScaleMax);
    else Result := 60.0;
  end;
end;

procedure TdmFormix.SetScaleMaxWeight(ScaleNo: Integer; MaxWeight : Double);
begin
  case ScaleNo of
    1 : SetTermRegDouble(r_S1_ScaleMax, MaxWeight);
    2 : SetTermRegDouble(r_S2_ScaleMax, MaxWeight);
  end;
end;

function TdmFormix.GetScaleDisplayDecimalPlaces(ScaleNo : Integer) : integer;
//Note: not neccessarily related to scale increment weight e.g. increment might be 0.1 but scale displays 2 DP.
begin
  case ScaleNo of
    1 : Result := GetTermRegInteger(r_S1_ScaleIncrement);
    2 : Result := GetTermRegInteger(r_S2_ScaleIncrement);
    else Result := 2;
  end;
end;

function TdmFormix.SetScaleDisplayDecimalPlaces(ScaleNo: Integer; NoOfDecimalPlaces : integer) : boolean;
//Note: decimal places is saved as ScaleIncrement in registry table.
begin
  case ScaleNo of
    1 : SetTermRegInteger(r_S1_ScaleIncrement, NoOfDecimalPlaces);
    2 : SetTermRegInteger(r_S2_ScaleIncrement, NoOfDecimalPlaces);
  end;
  Result := true; //dont know if it worked
end;

function TdmFormix.GetScaleIncrement(ScaleNo : Integer) : double;
begin
  case ScaleNo of
    1 : Result := GetTermRegDouble(r_S1_FxWtRoundMod);
    2 : Result := GetTermRegDouble(r_S2_FxWtRoundMod);
    else Result := 0.001;
  end;
end;

function TdmFormix.SetScaleIncrement(ScaleNo: Integer; WtIncrement : double) : boolean;
begin
  case ScaleNo of
    1 : SetTermRegDouble(r_S1_FXWtRoundMod, WtIncrement);
    2 : SetTermRegDouble(r_S2_FXWtRoundMod, WtIncrement);
  end;
  Result := true;
end;

function TdmFormix.RoundWtUpToNextScaleInc(Weight: DOUBLE) : DOUBLE;
var ScaleIncrement: Double;
begin
  if fRoundWeights then
  begin
    ScaleIncrement :=  GetScaleIncrement(CurrentScale);
    Result := RoundWtUpToUnits(Weight,ScaleIncrement) * ScaleIncrement;
  end
  else Result := Weight;
end;


procedure TdmFormix.AdjustTolToScaleRes(VAR LowWt, HighWt : DOUBLE);
{ low wt will be rounded-up so ingredient appears complete after weighing }
{ HighWt will be rounded to nearest scale increment unless that would cause
  it to be lower than low, in which case it will = lowWt.
}
var
 LowTolScaleIncs,
 HighTolScaleIncs : LONGINT;
 OverFlowed : BOOLEAN;
 ScaleIncrement: Double;

begin
 if not fRoundWeights then Exit;
 ScaleIncrement := GetScaleIncrement(CurrentScale);

 LowTolScaleIncs := RoundWtUpToUnits(LowWt,ScaleIncrement);
 LowWt := LowTolScaleIncs * ScaleIncrement;

 HighTolScaleIncs := RoundDblToLong(DivDouble(HighWt, ScaleIncrement),OverFlowed);
 if not OverFlowed then
  begin
   if HighTolScaleIncs < LowTolScaleIncs then
     HighTolScaleIncs := LowTolScaleIncs;
   HighWt := HighTolScaleIncs * ScaleIncrement;
  end;
end;

function TdmFormix.GetCurrentUser: String;
begin
 {if OverrideUser <> '' then Result := OverrideUser
                       else} Result := fCurrentUser;
end;

procedure TdmFormix.SetCurrentUser(const ToUserCode : string);
begin
  fCurrentUser := ToUserCode;
  CurrentUserIsIdle := false;
  if Assigned(dmFops) and FormixIni.UseFopsUsers then
    dmFops.HslSecurity.UserName := ToUserCode;
  if Assigned(frmFormixMain) then
    frmFormixMain.UpdateCurrentUserText;
end;

procedure TdmFormix.CheckUserIsLoggedIn;
begin
  if (Trim(fCurrentUser) = '')
  or CurrentUserIsIdle then
    TfrmFormixLogin.PromptUserToLogin;
end;

function TdmFormix.EditGlobalBatchAndLot : Boolean;
begin
  Result := FALSE;
 {Show the batch and lot edit screen}
  frmGlobalLotBatchEdit := TfrmGlobalLotBatchEdit.Create(Self);
  with frmGlobalLotBatchEdit do
  begin
    edGlobalBatch.Text := GetGlobalBatchNumber;
    edGlobalLot.Text   := GetTermRegString(r_GlobalLotNumber);
    ShowModal;
    if ModalResult = mrOk then
    begin
      SetGlobalBatchNumber(UpperCase(edGlobalBatch.Text));
      SetTermRegString(r_GlobalLotNumber,UpperCase(edGlobalLot.Text));
      TermMessageDlg('Global Lot && Batch saved',mtInformation,[mbOk],0);
      Result := TRUE;
    end
    else TermMessageDlg('Global Lot && Batch not saved',mtInformation,[mbOk],0);
    Free;
  end;
end;


procedure TdmFormix.SetLotNumberForIngredient(MachineID: Word; IngredientCode: String; LotNo: String);
begin
   try
     //Only save if not globally overridden (MachineID 0)
     if not pvtblLotIRef.Locate(LOT_Ingredient+';'+LOT_MachineID,VarArrayOF([IngredientCode,0]),[]) then
     begin
       if not pvtblLotIRef.Locate(LOT_Ingredient+';'+LOT_MachineID,VarArrayOF([IngredientCode,MachineID]),[]) then
       begin
         pvtblLotIRef.Append;

         pvtblLotIRef.FieldByName(LOT_Ingredient).AsString := IngredientCode;
         pvtblLotIRef.FieldByName(LOT_MachineID).AsInteger := MachineID;
       end
       else pvtblLotIRef.Edit;

       pvtblLotIRef.FieldByName(LOT_LotNo).AsString      := LotNo;
       pvtblLotIRef.Post;
     end;
   except
     on e: exception do
       TermMessageDlg(e.message,mtError,[mbOk],0);
   end;
end;


function TdmFormix.GetLotNoForIngredient(MachineID: Word; IngredientCode: String) : String;
begin
   Result := '';
   try
     if pvtblLotIRef.Locate(LOT_Ingredient+';'+LOT_MachineID,VarArrayOF([IngredientCode,MachineID]),[]) then
     begin
       Result := pvtblLotIRef.FieldByName(LOT_LotNo).AsString;
     end
     else if pvtblLotIRef.Locate(LOT_Ingredient+';'+LOT_MachineID,VarArrayOF([IngredientCode,0]),[]) then
     begin
       Result := pvtblLotIRef.FieldByName(LOT_LotNo).AsString;
     end;
   except
     on e: exception do
       TermMessageDlg(e.message,mtError,[mbOk],0);
   end;
end;

function TdmFormix.GetRejectionDesc(ForReason: TOverrideType) : string;
begin
  case ForReason of
    override_INCORRECTPROD : Result := 'Wrong source product for ingredient';
    override_LIFEEXPIRED   : Result := 'Source has gone past its life date';
    override_EMPTY         : Result := 'Source is empty';
    else                     Result := 'Wrong barcode';
  end;
end;

function TdmFormix.PromptForFopsUserThatHasRights(ToSecurityToken : TSecurityToken;
                                                  WithRights : TRightsOptions) : string;
{PROMISES: 1. Will only prompt user for a User Code if the currently logged in User
              or Override-User does not have rights.
           2. Returns the currently logged in User if it has the appropriate rights.
           3. Returns an Override User if the currently logged in User does not have
              rights and an Override-User (just logged in or saved in memory) does.
           4. Returns '' if currently logged in User does not have rights and an
              override-user fails to "temporarily log in".
           3. If an Override User code is returned, the override user code is cleared from
              HslSecurity memory (will have to temporarily log in again for next call).
}
var
  SaveUser : string;
begin
  Result := '';
  {UserHasRights may ask for a override user and then UserName property will keep returning that.}
  SaveUser := dmFops.HslSecurity.UserName;
  try
    if dmFops.HslSecurity.UserHasRights(ToSecurityToken, WithRights) then
      Result := dmFops.HslSecurity.UserName;
  finally
    dmFops.HslSecurity.UserName := SaveUser;//Only way to clear the Override User.
  end;
end;

function TdmFormix.PromptForOverrideUserApproval(ForReason : TOverrideType;
                                                 const ErrDetail : string) : boolean;
var
  UserThatApproves: String;
  ReasonMsg:string;
begin
  Result := FALSE;
  UserThatApproves := GetCurrentUser;
  ReasonMsg := GetRejectionDesc(ForReason);
  repeat
    if not (TermMessageDlg(ReasonMsg+#13#10+ErrDetail+#13#10+'Continue?',
                           mtConfirmation,[mbYes,mbNo],0) = mrYes) then
      BREAK;
    if Assigned(dmFops) and FormixIni.UseFopsUsers then //check FOPS8 User rights
    begin
      UserThatApproves := PromptForFopsUserThatHasRights(RejectReasonToOverrideSecurityToken(ForReason),
                                                         [roCreate]);
      Result := UserThatApproves <> '';
      BREAK;//only call PromptForFopsUserThatHasRights() once.
    end
    else //check FORMIX User record has high enough access level (AGAIN).
    begin
      if GetUsersAccessLevel(UserThatApproves) < 10 then
      begin
        TermMessageDlg('User with Access Level 10 required',mtInformation,[mbOk],0);
        if not GetOverrideUser(UserThatApproves) then
          BREAK;
      end;

      if (GetUsersAccessLevel(UserThatApproves) >= 10) then
        Result := TRUE;
    end;
  until Result;
  if Result then
  begin
    memtabWarningsOverriden.Append;
    memtabWarningsOverridenOverrideType.AsInteger := Integer(ForReason);
    memtabWarningsOverridenOverrideUser.AsString := UserThatApproves;
    memtabWarningsOverriden.Post;
  end;
end;

function TdmFormix.OverrideExistsForSourceItem(ForReason : TOverrideType;
                                               ForOrdNo  : integer;
                                               const ForIngredient : string;
                                               MinWtUsage : double;
                                               const ErrDetail     : string) : boolean;
{REQURIES: SourceBarcode, SourceItemLabelBarcode, SourceLifeJDay, SourceLotCode, SourceProdCode
           to reflect source item scanned.
}
var
  OfferAlreadyExists,
  OverrideDenied,
  ValidOverrideExists,
  RejectionAdded    : boolean;
  CurrDateTime,
  ValidFromDateTime,
  ValidToDateTime   : TDateTime;
  OfferId           : integer;
  Msg               : string;
  ConcessNumStr     : string;
  ConcessionNo      : integer;
  EnteredOk         : boolean;
begin
  Result := FALSE;
  if fRemoteOverrides then
  begin
    OverrideDenied      := FALSE;
    ValidOverrideExists := FALSE;
    RejectionAdded      := FALSE;
    CurrDateTime        := Now;
    try
      Msg := SourceBarcode+#13#10+
             GetRejectionDesc(ForReason);
      with pvtblRORejectedOffering do
      begin
        // fetch or make an offer id
        Active := true;
        OfferAlreadyExists := Locate(RoRejOff_OrderNo+';'+ RoRejOff_Ingredient+';'+
                                             RoRejOff_Barcode+';'+ RoRejOff_ReasonNo,
                                     VarArrayOf([ForOrdNo,ForIngredient,SourceBarcode,ForReason]),
                                     []);
      end;

      if OfferAlreadyExists then {is there a valid override in place?}
      begin
        {if not Valid Override then extend Msg with detail of invalid override}
        with pvtblROOverrides do
        begin
          Active := true;
          if not Locate(RoOve_OverrideId,
                        pvtblRORejectedOffering.FieldByName(RoRejOff_CurrentOverrideId).AsVariant,
                        []) then
            Msg := Msg+#13#10+
                   'Remote override is required.'
          else
          begin
            OverrideDenied := FieldByName(RoOve_Denied).AsBoolean;
            if OverrideDenied then
              Msg := Msg +#13#10+
                     'Overrides denied.'
            else
            begin
              ValidFromDateTime := FieldByName(RoOve_ValidFromDate).AsDateTime+
                                   FieldByName(RoOve_ValidFromTime).AsDateTime;
              ValidToDateTime := FieldByName(RoOve_ValidToDate).AsDateTime+
                                 FieldByName(RoOve_ValidToTime).AsDateTime;
              if ValidToDateTime < CurrDateTime then
                Msg := Msg+#13#10+
                       'Override for source expired at '+ FormatDateTime('HH:mm  dd/mm/yy',ValidToDateTime)
              else if ValidFromDateTime > CurrDateTime then
                Msg := Msg+#13#10+
                       'Override for source starts at '+FormatDateTime('HH:mm  dd/mm/yy',ValidFromDateTime)
              else
                ValidOverrideExists := TRUE;
            end;
          end;
        end; {with table}
      end
      else
        Msg := Msg+#13#10+'Remote override is required.';


      { Quote from Lazenbys requirement spec (author: TC):
        '1. Web application to show where user is trying to use an incorrect ingredient'
      }
      OfferID :=0;
      if not ValidOverrideExists then {record rejection}
      begin
        Database.StartTransaction;
        try
          if not OfferAlreadyExists then {add one}
          begin
            with pvtblRORejectedOffering do
            begin
              Insert;
              FieldByName(RoRejOff_OrderNo).AsInteger   := ForOrdNo;
              FieldByName(RoRejOff_Ingredient).AsString := ForIngredient;
              FieldByName(RoRejOff_Barcode).AsString    := SourceBarcode;
              FieldByName(RoRejOff_ReasonNo).AsInteger  := Ord(ForReason);
              FieldByName(RoRejOff_LabelBarcode).AsString := SourceItemLabelBarcode;
              Post;
              Refresh;//fetch autoinc and defaults
            end;
          end;
          OfferId := pvtblRORejectedOffering.FieldByName(RoRejOff_OfferId).AsInteger;
          with pvtblRejections do
          begin
            Active := true;
            Insert;
            FieldByName(Rej_OfferId).AsInteger := OfferId;
            FieldByName(Rej_UserCode).AsString := GetCurrentUser;
            FieldByName(Rej_RejectionDate).AsDateTime := DateOf(CurrDateTime);
            FieldByName(Rej_RejectionTime).AsDateTime := TimeOf(CurrDateTime);
            Post;
          end;
          Database.Commit;
          RejectionAdded := TRUE;
        except
          on E:Exception do
          begin
            Database.Rollback;
            TermMessageDlg(E.Message,mtError,[mbOk],0);
            pvtblRORejectedOffering.Cancel;
            pvtblRejections.Cancel;
          end;
        end;
      end;

      if RejectionAdded then
      begin
        if OverrideDenied then
          TermMessageDlg(Msg, mtError,[mbOk],0)
        else  {inform user and ask if a new override is required}
        begin
          if TermMessageDlg(Msg+#13#10+'REQUEST NEW OVERRIDE?   (Offer ID: '+ IntToStr(OfferId)+ ').',
                            mtInformation,[mbYes, mbNo],0) = mrYes then
          begin
            with pvtblRejections do
            begin
              try
                Database.StartTransaction;
                Edit;
                FieldByName(Rej_OverrideRequested).AsBoolean := true;
                Post;
                Database.Commit;
              except
                on E:Exception do
                begin
                  Database.Rollback;
                  TermMessageDlg(E.Message,mtError,[mbOk],0);
                  Cancel;
                end;
              end;
            end;
          end;
        end;
      end;
      {else error already handled above in except}
    except
      on E:Exception do
      begin
        TermMessageDlg(E.Message,mtError,[mbOk],0);
        if not ValidOverrideExists then
          ValidOverrideExists := PromptForOverrideUserApproval(ForReason, ErrDetail);
      end;
    end;
    Result := ValidOverrideExists;
  end
  else if  (ForReason = override_LIFEEXPIRED)
       and fAskForLifeDtConcessionNo then
  begin
    ConcessNumStr := TfrmFormixStdEntry.GetIntegerNumStr(
                                     'Enter Concession number for expired Life Date '+
                                       FormatDateTime('dd/mm/yyyy',JulianToDateValue(SourceLifeJDay)),
                                     'Concession No.', 9, EnteredOk, 0, false{AllowMinus});
    if EnteredOk then
    begin
      try
        if not Assigned(dmFops) then
          Msg := 'Cannot access FOPS database.'
        else if (not TryStrToInt(ConcessNumStr, ConcessionNo))
             or (ConcessionNo = 0) then
          Msg := 'A number is required.'
        else if not PvTableLocateUsingIndex(dmFops.pvtblProductConcession, ProCon_Id, ConcessionNo, []) then
          Msg := 'Concession not found'
        else
        begin
          Msg := dmFops.CurrProdConcessionInvalidMsg(SourceProdCode,
                                                     JulianToDateValue(SourceLifeJDay),
                                                     SourceLotCode,
                                                     ForIngredient, MinWtUsage);
          if Msg <> '' then
            Msg := 'Concession '+IntToStr(ConcessionNo)+ ' ' + Msg;
        end;
      except
        on e: exception do Msg := e.Message;
      end;
      if Msg = '' then //Concession is ok.
      begin
        Result := true;
        memtabWarningsOverriden.Append;
        memtabWarningsOverridenOverrideType.AsInteger    := Integer(ForReason);
        memtabWarningsOverridenOverrideUser.AsString     := GetCurrentUser;{override user wasnt needed}
        memtabWarningsOverridenSrcConcessionNo.AsInteger := ConcessionNo;
        memtabWarningsOverriden.Post;
      end
      else
        TermMessageDlg(Msg, mtError, [mbOk], 0);
    end;
  end
  else
    Result := PromptForOverrideUserApproval(ForReason, ErrDetail);
end;


procedure TdmFormix.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(fMixRpt) then
    Dispose(fMixRpt, Done);
  if Assigned(QAClientSession) then
    FreeAndNil(QAClientSession);
  inherited;
end;

function TdmFormix.CurrentFullOrderNumberAsString : String;
begin
  Result := OrderNoToString(pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                            pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger);
end;

function OrderNoToString(OrderNo, OrderNoSuffix : integer) : string;
begin
  Result := IntToZeroStr(OrderNo,6)+ '/'+
            IntToZeroStr(OrderNoSuffix,2);
end;

initialization
  ApplicationFileInfo := TWinFileInfo.Create(ParamStr(0));
  AppOnlyToHaveOneHslSecurity := true; //so that dmFormix and dmFops use the same Security.
  TerminalName := ParamStr(1);// do this before any GetReg...() calls.

finalization
  if Assigned(ApplicationFileInfo) then
    FreeAndNil(ApplicationFileInfo);

end.

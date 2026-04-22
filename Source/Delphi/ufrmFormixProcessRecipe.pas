unit ufrmFormixProcessRecipe;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, dbcgrids, ExtCtrls, StdCtrls, DBCtrls, TeEngine, Series,
  TeeProcs, Chart, Mask, udmFormix, CPort, Math, uStdUtl, HSLAZKeyboard,
  ComCtrls, JvExExtCtrls, JvComponent, JvCaptionPanel, RxMemDS, Grids,
  DBGrids, uTermDialogs, AnalogMeter, JvExStdCtrls, JvButton, JvCtrls,
  Buttons, ImgList, ufrmFormixStdEntry, JvExControls,
  JvTransparentButton, JvSegmentedLEDDisplay, JvExtComponent,uCSWScale;

const ProductPanelWidth = 200;

type
  TProcessStep = (psTareReqd,
                  psAddIngredient,
                  psRemoveContOrSemiAutoTare,
                  psWeightIsInToleranceAccept,
                  psPlaceContainerOnScaleAndSemiAutoTare,
                  psWeightToHighForIngredient,
                  psRemoveContainerFromScale,
                  psLastIngredientCompletedSelectNew,
                  psSelectIngredientFromTheListBelow);                  

  TfrmFormixProcessRecipe = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    plOrderDetails: TPanel;
    lbBatchNo: TLabel;
    lbUser: TLabel;
    lbTime: TLabel;
    tmClockAndLineRefresh: TTimer;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    dsMemOrderHeader: TDataSource;
    DBEdit1: TDBEdit;
    DBEdit2: TDBEdit;
    DBEdit3: TDBEdit;
    DBEdit4: TDBEdit;
    DBEdit5: TDBEdit;
    DBEdit6: TDBEdit;
    DBEdit7: TDBEdit;
    lbScaleWt: TLabel;
    plProducts: TPanel;
    plIngredientList: TPanel;
    plScaleLabel: TPanel;
    plMixDetails: TPanel;
    jvpOrderDetails: TJvCaptionPanel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    edContainerDesc: TEdit;
    edRequires: TEdit;
    edMixNumber: TEdit;
    edTolerance: TEdit;
    rmdIngredients: TRxMemoryData;
    rmdIngredientsProductCode: TStringField;
    rmdIngredientsMinTol: TFloatField;
    rmdIngredientsMaxTol: TFloatField;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    rmdIngredientsWtRemaining: TFloatField;
    rmdIngredientsWeighsPerContainer: TIntegerField;
    rmdIngredientsWeightIncrements: TFloatField;
    rmdIngredientsProductDesc: TStringField;
    edProductCode: TEdit;
    edProductDesc: TEdit;
    rmdIngredientsLineNo: TIntegerField;
    Label14: TLabel;
    edLotNo: TEdit;
    Label15: TLabel;
    edHazardCode: TEdit;
    lbMessage: TLabel;
    btExit: TButton;
    btOptions: TButton;
    rmdIngredientsNoTare: TBooleanField;
    plAnalog: TPanel;
    btPartWeigh: TButton;
    lbRemainingWeight: TLabel;
    tmTareFlasher: TTimer;
    btTare: TJvImgBtn;
    plTotalMix: TPanel;
    plTotalMixValue: TPanel;
    Label2: TLabel;
    rmdIngredientsIsComplete: TBooleanField;
    rmdIngredientsMixDesc: TStringField;
    rmdIngredientsCompleteLabel: TStringField;
    rmdIngredientsWtRemainingLabel: TStringField;
    ImageList1: TImageList;
    btbnLeft: TBitBtn;
    btbtnRight: TBitBtn;
    Button1: TButton;
    rmdIngredientsWtReqdByMix: TFloatField;
    dbcbxMixQADone: TDBCheckBox;
    DBEdit8: TDBEdit;
    Label1: TLabel;
    edSourceID: TEdit;
    Label16: TLabel;
    edTemperature: TEdit;
    lblTemperature: TLabel;
    procedure tmClockAndLineRefreshTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SelectIngredient(Sender: TObject);
    procedure plMixDetailsClick(Sender: TObject);
    procedure plOrderDetailsClick(Sender: TObject);
    function  CreateNewTransaction(NetWt : double) : Boolean;
    procedure btExitClick(Sender: TObject);
    //procedure SetlbMessage(ForMsgNumber: Integer);
    //function  IsValidStep(ForStep: Integer): Boolean;
    procedure SetTareWt(GrossWt: Double);
    procedure SetupCancelTareButton;
    procedure SetupTareButton;
    function  IngredientSelected: Boolean;
    procedure btTareClick(Sender: TObject);
    procedure btOptionsClick(Sender: TObject);
    procedure plAnalogClick(Sender: TObject);
    procedure btPartWeighClick(Sender: TObject);
    function  CalcWeightPercentage(ForWeight: Double): Double;
    procedure UpdateOrderMemTable;
    procedure tmTareFlasherTimer(Sender: TObject);
    procedure HidePartWeighDetails;
    function  GetCurrentMixTotalPercentage: Integer;
    procedure SetTotalMixValue(ForValue: Integer);
    procedure SwitchOnScalePortEvent;
    procedure SwitchOffScalePortEvent;
    procedure btbnLeftClick(Sender: TObject);
    procedure btbtnRightClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PossiblyIssueFopsTranRemainder(ActualWt: Double);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure DBEdit7Change(Sender: TObject);
    procedure dbcbxMixQADoneMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    fScaleSwitchOffCount : integer;
    fProcessStep : TProcessStep;
    procedure SetUserPromptForProcessStep;
    procedure SetProcessStepTo(Step : TProcessStep);
    function IsCurrentProcessStepAt(Step : TProcessStep): Boolean;
    procedure SetLabelsAndMeter;
    function IsWaitingForContainerRemoval: Boolean;
    procedure UpdateFromScale(ScaleWeightStr: String);
    function GetNetWeight : Extended;
    procedure ClearEditFieldsThatRelateToSelectIngred;
    procedure ClearSelectionFromIngredPanels;
    procedure DeselectCurrentIngredient(forceRebuild: Boolean);
    procedure SelectIngredPanelForOrderLineNo(OrdLineNo : integer);
    function  IsSourceContainerWtOk(ActualIngredWt : double) : boolean;
    function InitialiseCurrentScale(Connect: Boolean) : Boolean;
    function ConnectScale : Boolean;
    function GetCurrentScaleObject: TCSWScale;
    procedure ScaleConnectError;
    procedure IPScaleError(Scale: TObject);
//    procedure ClickMouse(X, Y: Integer);
    procedure AcceptWeight;
    procedure BuildProductList;
  public
    { Public declarations }
    AnalogMeter1: TAnalogMeter;
    fIngredientCount,
    fLeftmostIngredient: Integer;
    fCurrentIngredientCode: String;
    fCurrentOrderLineNo   : integer;
    fScale1: TCSWScale;
    fScale2: TCSWScale;

    fScaleBuffer: String;
    fScaleWeight: String;
    fScaleMax,
    fMinPercent,
    fMaxPercent,
    fWtRemaining,
    fTareWt,
    fInitialContainerWt: Double;
    fScaleDP: Integer;                               // Default No of DP from Scale
    fScaleType: Integer;
    fScaleModel: Integer;
    {Current Step}
    //CurrentStep: TWeighingStep;
    fTareSet: Boolean;
    fManualWeight : double;
    fManualWtActive : boolean;
    fKeyIngredientReq: Boolean;
    fKeyIngredientCode: String;
    fIngredientsForArea: Boolean;
    fWghsDoneInThisAreaForMix : integer;

//    fCurrentMixPercentage: Integer;
    fCurrentContainers: Integer;
    fFirstTime: Boolean;
    fFirstBuildProductListForOrd : boolean;
    fAnalogInc: Integer;
    fReLaunchProcessScreen: Boolean;
    fReBuildList: Boolean;
    fScaleDisplayFormat: String;
    fScaleIncrement : double;
    fMixChangedFromOptions: Boolean;

    class procedure ProcessRecipe(OrderDataSet: TDataSet; MixNoOverride : integer);
    procedure SetProcessStepToCompleted;
    function  TareWtExists: Boolean;
    procedure CreateAnalogMetre(MinVal, MaxVal :Double);
    procedure CancelCurrentTare(ChangeMessage: Boolean = TRUE);
    function  AnyIngredientAvailable: Boolean;
    function  IsCurrentIngredientComplete: Boolean;
    function  IsWeightInToleranceForScale(NetWt : double;
                                                             LowWtAdjustedForScale, HighWtAdjustedForScale : double) : boolean;
    function  IsCurrentWeightOk(CheckWeight: Double; IsAPartWeigh: Boolean): Boolean;
//    procedure RefreshOrderLines;
    procedure RefreshBatchNoDisplay;
    procedure RefreshDisplayOfPreWghIngredSetup;
  end;

var
  frmFormixProcessRecipe: TfrmFormixProcessRecipe;

implementation
uses uFopsLib,uIni,ufrmFormixMain, ufrmProcessRecipeOptions, udmFops,uComUtils,udmFormixBase,
     uDBFunctions, uFormixTerminalQAClient, ufrmQAProgress, uPreWeighingSetup;

{$R *.dfm}

const
  keyIngredientStr                       = 'Key Ingredient';
  col_IngredientSelected                 = clAqua;
  rsSemiAutoTare                         = 'Semi Auto Tare';
  rsCancelTare                           = 'Cancel Tare';

procedure TfrmFormixProcessRecipe.SetUserPromptForProcessStep;
begin
  case fProcessStep of
    psTareReqd                            : lbMessage.Caption := 'Press Semi Auto Tare To Accept Tare';
    psAddIngredient:     if fManualWtActive then lbMessage.Caption := 'Use Part Weigh button to accept'
                         else               lbMessage.Caption := 'Add Ingredient';
    psRemoveContOrSemiAutoTare            : lbMessage.Caption := 'Remove Container From Scale  or  Semi-Auto Tare';
    psWeightisInToleranceAccept           : lbMessage.Caption := 'Weight Is Within Tolerance. Accept?';
    psPlaceContainerOnScaleAndSemiAutoTare: lbMessage.Caption := 'Place Container On Scale And Press Semi Auto Tare';
    psWeightToHighForIngredient           : lbMessage.Caption := 'Weight Too High For This Ingredient';
    psRemoveContainerFromScale            : lbMessage.Caption := 'Remove Container From Scale';
    psLastIngredientCompletedSelectNew    : lbMessage.Caption := 'Last Ingredient Completed, Select New Ingredient';
    psSelectIngredientFromTheListBelow    : lbMessage.Caption := 'Select Ingredient From The List Below';
    else                                    lbMessage.Caption := '';
  end;
end;

procedure TfrmFormixProcessRecipe.SetProcessStepTo(Step : TProcessStep);
begin
    //always execute this, even if Step = fProcessStep (FManualWtActive may have changed).
    if (Step = psAddIngredient) then
    begin
      if fManualWtActive then
        btTare.Visible := false;
      btPartWeigh.Visible := TRUE;
      btPartWeigh.Enabled := TRUE;
      lbRemainingWeight.Visible := TRUE;
    end
    else
    begin
      btPartWeigh.Enabled := FALSE;
      if (Step = psRemoveContainerFromScale)
      or (Step = psTareReqd)
      or (Step = psPlaceContainerOnScaleAndSemiAutoTare)
      or (Step = psRemoveContOrSemiAutoTare) then
      begin
        btTare.Visible := true;
        tmTareFlasher.Enabled := TRUE;
      end
      else
      begin
        //btTare.Visible := false; not brave enough to try this.
        tmTareFlasher.Enabled := FALSE;
      end;
    end;
    fProcessStep := Step;
    SetUserPromptForProcessStep;
end;

function TfrmFormixProcessRecipe.IsCurrentProcessStepAt(Step : TProcessStep): Boolean;
begin
  Result := fProcessStep = Step;
end;

procedure TfrmFormixProcessRecipe.ClearEditFieldsThatRelateToSelectIngred;
begin
  edContainerDesc.Text := '';
  edRequires.Text := '';
  edTolerance.Text := '';
  edProductCode.Text := '';
  edProductDesc.Text := '';
  edHazardCode.Text := '';
end;

procedure TfrmFormixProcessRecipe.ClearSelectionFromIngredPanels;
var i : integer;
begin
  // remove selected-colour from all ingredient panels.
  for i := 0 to plIngredientList.ControlCount-1 do
  begin
    if plIngredientList.Controls[i] is TPanel then
      TPanel(plIngredientList.Controls[i]).Color := clWhite;
  end;
end;

procedure TfrmFormixProcessRecipe.DeselectCurrentIngredient(forceRebuild: Boolean);
begin
  fManualWtActive := false;
  fCurrentIngredientCode := '';
  fCurrentOrderLineNo := -1;
  if forceRebuild then fReBuildList := TRUE;
  ClearSelectionFromIngredPanels;
  SetProcessStepTo(psSelectIngredientFromTheListBelow);
  btTare.Visible := FALSE;
  btPartWeigh.Visible := FALSE;
  SetLabelsAndMeter;
  ClearEditFieldsThatRelateToSelectIngred;
  plMixDetails.Visible   := FALSE; //hide panel with ingredient related fields
  plOrderDetails.Visible := TRUE;
end;


procedure TfrmFormixProcessRecipe.SetProcessStepToCompleted;
begin
  SetProcessStepTo(psLastIngredientCompletedSelectNew);
end;

function GetIngredientButtonName(OrderLineNo : integer) : string;
begin
  Result := 'P'+IntToZeroStr(OrderLineNo, 6);
end;

function GetOrderLineNoForIngredientButton(ButtonPanel : TPanel) : integer;
begin
  Result := StringToLong(Copy(ButtonPanel.Name,2,6));
end;

procedure TfrmFormixProcessRecipe.SelectIngredPanelForOrderLineNo(OrdLineNo : integer);
var i : integer;
begin
  for i := plIngredientList.ControlCount-1 downto 0 do
  begin
    if GetIngredientButtonName(OrdLineNo) = plIngredientList.Controls[i].Name then
    begin
      if plIngredientList.Controls[i].Enabled then
      begin
        rmdIngredients.Locate('LineNo',fCurrentOrderLineNo,[]);
        SelectIngredient(plIngredientList.Controls[i]);
      end;
      Break;
    end;
  end;
end;

procedure TfrmFormixProcessRecipe.BuildProductList;
var WrkPanel: TPanel;
    //WrkLabel: TLabel;
    IngredientIsComplete: Boolean;
    i,
    FirstIncompleteLine,
    CurrentScroller: Integer;
    IngredientForArea: Boolean;
    FirstIncompleteLineIsAutoTran : boolean;


    procedure AddDetailsToMemTable(OrdLineIsForThisPrepArea : boolean);
    var
        MixLRec : TMixLineRecord;
        WrkMix_Ingred_TotWt,
        WrkMix_Ingred_WtIncrements,
        LowestWt,
        HighestWt: Double;
        WrkMix_Ingred_Weighings,
        WrkMix_Ingred_WghsPerCont : integer;
        MixDesc,
        WtRLabel: String;
        IngredientCode: String;
    begin
     IngredientIsComplete := FALSE;
     dmFormix.ConstructMixLineRecForOrdLine(dmFormix.GetCorrectMixNo{dmFormix.CurrentMixNo},MixLRec);
     if OrdLineIsForThisPrepArea then
       fWghsDoneInThisAreaForMix := fWghsDoneInThisAreaForMix + MixLRec.ML_WghsDone;

     if dmFormix.IsThisLineCompleteForCurrMix(MixLRec.ML_WghsDone,MixLRec.ML_WtDone) then
       IngredientIsComplete := TRUE;

     jvpOrderDetails.Caption := 'Order '+
                    OrderNoToString(dmFormix.pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                    dmFormix.pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger)+
                                '   '+
                                dmFormix.pvtblOrderHeader.FieldByName(OH_RecipeCode).AsString;
     edMixNumber.Text := IntToStr(dmFormix.pvtblOrderHeader.FieldByName(OH_MixesDone).AsInteger)+' of '+
                         IntToStr(dmFormix.pvtblOrderHeader.FieldByName(OH_MixesRequired).AsInteger);
(*
     fCurrentContainers := dmFormix.GetContainersForIngredient;
     edContainerDesc.Text := '('+
                             FormatFloat('#,0.000',dmFormix.pvtblOrderLine.FieldByName(OL_ContainerWeight).AsFloat)+
                             'kg) '+
                             IntToStr(dmFormix.GetCurrentContainerNo)+
                             ' of '+
                             IntToStr(fCurrentContainers);
*)
     dmFormix.CalcIngredReqsForMixWt(dmFormix.CurrentCompensatedBatchMixWt,
                                     MixLRec,WrkMix_Ingred_TotWt,WrkMix_Ingred_Weighings,
                                     WrkMix_Ingred_WtIncrements,WrkMix_Ingred_WghsPerCont);
     dmFormix.CalcWOLineTolWts(WrkMix_Ingred_WtIncrements,
                               dmFormix.pvtblOrderHeader[OH_MixType],
                               WrkMix_Ingred_TotWt,
                               MixLRec.ML_WtDone,
                               LowestWt,
                               HighestWt);
     dmFormix.AdjustTolToScaleRes(LowestWt,HighestWt);
(*
     { NOTE: wghs per container is usually 1 even for fixed wt ingredients
            (see CalcIngredReqsForMixWt)}
     if WrkMix_Ingred_WghsPerCont > 1 then
       { Ideally it should say Number x FixWt + Fraction for fixed weight
          ingredients - so advice not to use fractions of fixed weights
          in Even Distribution mixes. }
       edRequires.Text := IntToStr(WrkMix_Ingred_WghsPerCont)+' x '+
                          FormatFloat('#,0.000',WrkMix_Ingred_WtIncrements)+'kg'
     else
       edRequires.Text := FormatFloat('#,0.000',WrkMix_Ingred_WtIncrements)+'kg';
     edTolerance.Text := FormatFloat('#,0.000',LowestWt)+
                         ' - '+
                         FormatFloat('#,0.000',HighestWt);
     edLotNo.Text := dmFormix.GetRegStringDef(REG_Scale+TerminalName,REG_GlobalLotNumber,'');
*)
     MixDesc := 'Mix No: '+IntToStr(dmFormix.GetCorrectMixNo{dmFormix.CurrentMixNo});
     if dmFormix.pvtblOrderLine.FieldByName(OL_KeyLine).AsBoolean then
       MixDesc := MixDesc + ' '+ KeyIngredientStr;
     if IngredientIsComplete then
       WtRLabel := DoubleToStr(0.0, 7, 3)
     else
       WtRLabel := DoubleToStr(WrkMix_Ingred_WtIncrements, 7, 3);

     IngredientCode := dmFormix.pvtblOrderLine.FieldByName(OL_Ingredient).AsString;
     rmdIngredients.Append;
     rmdIngredientsProductCode.Value       := Trim(IngredientCode);
     rmdIngredientsProductDesc.Value       := Trim(dmFormix.rxmIngredientsCacheDescription.AsString);
     rmdIngredientsMinTol.Value            := LowestWt;
     rmdIngredientsMaxTol.Value            := HighestWt;

     rmdIngredientsWeighsPerContainer.Value:= WrkMix_Ingred_WghsPerCont;
     rmdIngredientsWeightIncrements.Value  := WrkMix_Ingred_WtIncrements;
     rmdIngredientsLineNo.Value            := dmFormix.pvtblOrderLine.FieldByName(OL_LineNo).AsInteger;
     rmdIngredientsNoTare.AsBoolean        := dmFormix.rxmIngredientsCacheNo_Tare.AsBoolean;
     rmdIngredientsIsComplete.Value        := IngredientIsComplete;
     rmdIngredientsMixDesc.Value           := MixDesc;
     rmdIngredientsWtRemainingLabel.Value  := WtRLabel;
     rmdIngredientsWtReqdByMix.Value       := WrkMix_Ingred_TotWt;
     if IngredientIsComplete then
     begin
       rmdIngredientsWtRemaining.Value      := 0;
       rmdIngredientsCompleteLabel.Value    := 'COMPLETE';
     end
     else
     begin
       rmdIngredientsWtRemaining.Value      := dmformix.CalcLineGrossWtReqdForCurrMix;
       rmdIngredientsCompleteLabel.Value    := '';
     end;
     rmdIngredients.Post;
    end;


  function CreateChildLabel(X,Y: Integer; Text: String) : TLabel;
  begin
    Result := TLabel.Create(nil);
    with Result do
    begin
      Parent   := WrkPanel;
      Left     := X;
      Top      := Y;
      Width    := Parent.Width-(X+2);
      AutoSize := FALSE;
      Caption  := Text;
      Enabled  := Parent.Enabled;
      OnClick  := SelectIngredient;
    end;
  end;

begin
  {Need to build a product list in plProductList}
  SwitchOffScalePortEvent;
  try
    {Locate the order header and lines}
    fIngredientCount   := 0;
    FirstIncompleteLine := 0;
    FirstIncompleteLineIsAutoTran := false;
    CurrentScroller := 0;
    fIngredientsForArea := false;
    fWghsDoneInThisAreaForMix := 0;
    if fFirstTime then fKeyIngredientReq := FALSE;
    fKeyIngredientCode := '';
    {Clear all old ingredients}
    while plIngredientList.ControlCount > 0 do
      plIngredientList.Controls[0].free;
    rmdIngredients.EmptyTable;
    fLeftMostIngredient := 1;
    {load up all ingredients for recipe}
    dmFormix.pvtblOrderHeader.IndexName := 'ByOrder';
    if dmFormix.pvtblOrderHeader.Locate(OH_OrderNo+';'+OH_OrderNoSuffix,
                VarArrayOf([dsMemOrderHeader.DataSet.FieldByName('WrkOrder').AsInteger,
                            dsMemOrderHeader.DataSet.FieldByName('WrkSuffix').AsInteger]),[]) then
    begin
      dmFormix.PreCalcCompensatedBatchMixWt;
      dmFormix.pvtblOrderLine.SetRange([dmFormix.pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                        dmFormix.pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger],
                                       [dmFormix.pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                        dmFormix.pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger]);
      try
        dmFormix.pvtblOrderLine.First;
        while not dmFormix.pvtblOrderLine.Eof do
        begin
          dmFormix.SynchIngredientsCacheWithCode(dmFormix.pvtblOrderLine.FieldByName(OL_Ingredient).AsString);
          IngredientForArea := dmFormix.IngredientIsInPrepArea(dmFormix.rxmIngredientsCache);

          if IngredientForArea then fIngredientsForArea := TRUE;

          AddDetailsToMemTable(IngredientForArea);
          {Create the ingredient panel}
          WrkPanel := TPanel.Create(nil);
          with WrkPanel do
          begin
            Parent  := plIngredientList;
            ParentBackground := FALSE;
            ParentColor := FALSE;
            Left    := fIngredientCount * ProductPanelWidth;
            Width   := ProductPanelWidth;
            Tag     := fIngredientCount;
            Height  := 200;
            Enabled := (not IngredientIsComplete) and (IngredientForArea);
            OnClick := SelectIngredient;
            Name    := GetIngredientButtonName(dmFormix.pvtblOrderLine.FieldByName(OL_LineNo).AsInteger);
            Color  := clWhite;
            Caption := '';
            {WrkPanel.Font.Name :='Arial Narrow';}
          end;
          {Create line no label}
          CreateChildLabel(2,2,IntToZeroStr(rmdIngredientsLineNo.AsInteger,3));
          {Create ingredient label}
          CreateChildLabel(100,2,rmdIngredientsProductCode.AsString);
          {Create description label}
          with CreateChildLabel(2,22,TrimRight(rmdIngredientsProductDesc.AsString)) do
            Font.Style := Font.Style +[fsBold];
          {Create Mix No label}
          with CreateChildLabel(2,42,rmdIngredientsMixDesc.AsString) do
          begin
            if Pos(keyIngredientStr, rmdIngredientsMixDesc.AsString) > 0 then
            begin
              Color := clRed;
              if not IngredientIsComplete then
              begin
                if fFirstTime then
                begin
                  fFirstTime := FALSE;
                  if not fKeyIngredientReq then fKeyIngredientReq := TRUE;
                end;
              end;
              fKeyIngredientCode := dmFormix.pvtblOrderLine.FieldByName(OL_Ingredient).AsString;
            end;
          end;
          if rmdIngredientsIsComplete.AsBoolean then {dont show wt remaining}
            CreateChildLabel(2,62, rmdIngredientsCompleteLabel.AsString)
          else
          begin
            CreateChildLabel(2,62, 'Next Weight:');
            CreateChildLabel(124,62, rmdIngredientsWtRemainingLabel.AsString);
          end;
          CreateChildLabel(2,82,   'Wt. Reqd. by Mix:');
          CreateChildLabel(124,82, DoubleToStr(rmdIngredientsWtReqdByMix.AsFloat,7,3));
          if  (FirstIncompleteLine = 0)
          and (not IngredientIsComplete) then
          begin
            FirstIncompleteLine := dmFormix.pvtblOrderLine.FieldByName(OL_LineNo).AsInteger;
            FirstIncompleteLineIsAutoTran :=
                     dmFormix.pvtblOrderLine.FieldByName(OL_ProcessType).AsInteger = Ord(PTAuto);
          end;
          if dmFormix.pvtblOrderLine.FieldByName(OL_LineNo).AsInteger = fCurrentOrderLineNo then
            CurrentScroller := dmFormix.pvtblOrderLine.FieldByName(OL_LineNo).AsInteger;

          Inc(fIngredientCount);
          dmFormix.pvtblOrderLine.Next;
        end;
        dmFormix.CancelPreCalcCompensatedBatchMixWt;
        if  (fIngredientCount > 0)
        and (FirstIncompleteLine = 0) then
          dmFormix.MarkMixCompleteIfNecess;
      finally
        //dmformix.pvtblOrderLine.CancelRange; dont - caller might have SetRange as well.
      end;
    end;

    dmFormix.pvtblOrderHeader.IndexName := 'ByDateOrder';

    {need to move product list along to first incomplete product,
     or jump straight to the current product if its a part weigh}
    if CurrentScroller > 0 then //fCurrentOrderLineNo must be greater than zero
    begin
      for i := 1 to CurrentScroller-1 do btbtnRight.Click; //scroll ingredients grid
      SelectIngredPanelForOrderLineNo(fCurrentOrderLineNo)
    end
    else //no ingredient pre-selected
    begin
      if FirstIncompleteLine > 0 then //scroll ingredients grid
      begin
        for i := 1 to (FirstIncompleteLine -1) do btbtnRight.Click;
        (* change of plan - even water needs a batch number for yield - user
           might as well select water.
        if FirstIncompleteLineIsAutoTran then
          SelectIngredPanelForOrderLineNo(FirstIncompleteLine);
        *)
      end;
    end;
    plOrderDetailsClick(nil); //make sure Mix Details window is displayed if ingred not selected.
  finally
    SwitchOnScalePortEvent;
  end;
  if  fFirstBuildProductListForOrd
  and (not fIngredientsForArea) then
  begin
    fFirstBuildProductListForOrd := false;
    TermMessageDlg('Order not applicable to your Preparation Area',mtInformation,[mbOk],0);
  end;
  //SMW
  {if AnyIngredientAvailable then btTare.Visible := TRUE
                            else btTare.Visible := FALSE; }
end;


procedure TfrmFormixProcessRecipe.tmClockAndLineRefreshTimer(Sender: TObject);
var WH,WM,WS,WMS: Word;
begin
  tmClockAndLineRefresh.Enabled := false;
  tmClockAndLineRefresh.Interval := 1000; //restore normal interval.
  try
    lbTime.Caption := FormatDateTime('hh:mm:ss',Now);
    DecodeTime(Now,WH,WM,WS,WMS);
(*
    if (WS mod 20 =0) then
      RefreshOrderLines; doesnt work
*)      
    if fReBuildList then
    begin
      fReBuildList := FALSE;
      BuildProductList;
    end;
  finally
    tmClockAndLineRefresh.Enabled := true;
  end;
end;


function TfrmFormixProcessRecipe.GetCurrentScaleObject : TCSWScale;
begin
  case dmFormix.CurrentScale of
    1: Result := fScale1;
    2: Result := fScale2;
    else Result :=fScale1;
  end;
end;


function TfrmFormixProcessRecipe.ConnectScale : Boolean;
begin
  fScale1.Disconnect;
  fScale2.Disconnect;
  Result := GetCurrentScaleObject.Connect;
end;

procedure TfrmFormixProcessRecipe.ScaleConnectError;
begin
  TermMessageDlg('Unable to Connect To Scale: '+
                 IntToStr(dmFormix.CurrentScale)+' '+
                 'Reason: '+GetCurrentScaleObject.ConnectError,mtError,[mbOk],0);
end;

procedure TfrmFormixProcessRecipe.IPScaleError(Scale : TObject);
begin
  ScaleConnectError;
end;

function TfrmFormixProcessRecipe.InitialiseCurrentScale(Connect: Boolean) : Boolean;
var I: integer;
    InitString: String;
begin
  Result := True;
  fScaleType := dmFormix.GetScaleType(dmFormix.CurrentScale);
  fScaleModel := dmFormix.GetScaleModel(dmFormix.CurrentScale);
  fScaleMax  := dmFormix.GetScaleMaxWeight(dmFormix.CurrentScale);
  fScaleDP   := dmFormix.GetScaleDisplayDecimalPlaces(dmFormix.CurrentScale);
  fScaleDisplayFormat := '#0.';
  for i := 1 to fScaleDP do fScaleDisplayFormat := fScaleDisplayFormat + '0';
  fScaleIncrement := dmFormix.GetScaleIncrement(dmFormix.CurrentScale);

  case fScaleType of
    0: InitString := dmFormix.GetScaleSerialConfig(dmFormix.CurrentScale);
    1: InitString := dmFormix.GetScaleIPConfig(dmFormix.CurrentScale);
    else InitString := dmFormix.GetScaleSerialConfig(dmFormix.CurrentScale);
  end;

  GetCurrentScaleObject.Initialise(fScaleModel,fScaleType=0{ Serial },InitString,fScaleDP,UpdateFromScale,IPScaleError);
  if (Connect) then Result := ConnectScale;
end;

procedure TfrmFormixProcessRecipe.FormCreate(Sender: TObject);
begin
  fScaleSwitchOffCount := 0;
  if (FormStyle = fsStayOnTop) and (not dmFormix.fProgramStaysOnTop) then
    FormStyle   := fsNormal;
  dmFormix.RefreshRegistryCache;
  dmFormix.CurrentScale := dmFormix.GetLastUsedScale;
  fScale1 := TCSWScale.Create(Self);
  fScale2 := TCSWScale.Create(Self);

  if (not InitialiseCurrentScale(True)) then ScaleConnectError;
  fReBuildList := true; //first timer event needs to build ingredient list.
//  SetTotalMixValue(fCurrentMixPercentage);

  fAnalogInc := 1;
  fFirstTime := TRUE;
  fFirstBuildProductListForOrd := true;
  DeselectCurrentIngredient(FALSE);

  fIngredientsForArea := FALSE;
  AnalogMeter1 := nil;
  fIngredientCount   := 0;

  FScaleBuffer := '';
  fMinPercent  := 0;
  fMaxPercent  := 0;
  fWtRemaining := 0;

 //DEBUG
  //fScale1 := TCSWScale.Create(Self);
  //fScale1.Initialise(false,'192.168.0.199:1001',fScaleDP,UpdateFromScale);
  //fScale1.Connect;
  //DEBUG

  fTareWt      := 0.0;
  fTareSet := FALSE;
  fScaleWeight := '';
  fManualWeight:= 0.0;
  fManualWtActive := FALSE;
  fInitialContainerWt := 0.0;
  SetProcessStepTo(psSelectIngredientFromTheListBelow);
  fCurrentContainers := 0;
  fMixChangedFromOptions := FALSE;
(*
  try
    ScaleStr := '';
    ScaleStr := dmFormix.GetRegStringDef(REG_Scale+TerminalName,REG_ScaleSetup,'');
    if ScaleStr <> '' then
    begin
      cpScale.Port        := GetComPortFromString(ScaleStr);
      cpScale.BaudRate    := GetBaudRate(GetBaudRateFromString(ScaleStr));
      cpScale.DataBits    := GetDataBits(GetDataBitsFromString(ScaleStr));
      cpScale.Parity.Bits := GetParity(GetParityFromString(ScaleStr));
      cpScale.StopBits    := GetStopBits(GetStopBitsFromString(ScaleStr));
      cpScale.FlowControl.FlowControl := GetFlowControl(GetFlowControlFromString(ScaleStr));
      i := 0;
      while (not cpScale.Connected) and (i < 5) do
      begin
        cpScale.Open;
        Inc(i);
        Sleep(250);
      end;
    end;
  except
    on E:Exception do
    begin
      TermMessageDlg('Unable to open Scale Port',mtError,[mbOk],0);
    end;
  end;
*)
  if not dmFormix.fPromptForTemperature then
  begin
    edTemperature.Visible := false;
    lblTemperature.Visible := false;
  end;
  SetLabelsAndMeter;
end;

procedure TfrmFormixProcessRecipe.FormDestroy(Sender: TObject);
begin
  try
    //if cpScale.Connected then cpScale.Close;
    FreeAndNIL(fScale1);
    FreeAndNIL(fScale2);
  except
    on E:Exception do
    begin
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Functions triggered from weight capture


function TfrmFormixProcessRecipe.GetNetWeight : Extended;
begin
  Result := 0;
  try
    if fManualWtActive then
      Result := fManualWeight
    else
      Result := StrToFloat(fScaleWeight)-fTareWt;
  except
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// SetLabelsAndMeter
// Updates display on new weight packet from scale
//    Weight
//    Weight Remaining
//    Analog Dial
//    Userprompt
procedure TfrmFormixProcessRecipe.SetLabelsAndMeter;
var DisplayWeight: Extended;
    RemainingWtForThisScaleTolerance: Extended;
    //CurrTare: Extended;
begin
  //if fTareSet then CurrTare := fTareWt else CurrTare := 0;
  if GetCurrentScaleObject.OverRange then
  begin
    lbScaleWt.Caption :='OVER RANGE';
    DisplayWeight := 0;
  end
  else if (GetCurrentScaleObject.UnderRange) then
  begin
    lbScaleWt.Caption :='UNDER RANGE';
    DisplayWeight := 0;
  end
  else
  begin
    DisplayWeight   := GetNetWeight;
    lbScaleWt.Caption := FormatFloat(fScaleDisplayFormat,DisplayWeight);
  end;
  if fManualWtActive then
    lbScaleWt.Caption := lbScaleWt.Caption + ' (man)';

  if (IngredientSelected) then
  begin
    if fWtRemaining > rmdIngredientsMaxTol.AsFloat then
      RemainingWtForThisScaleTolerance := rmdIngredientsMaxTol.AsFloat
    else if fWtRemaining < rmdIngredientsMinTol.AsFloat then
      RemainingWtForThisScaleTolerance := rmdIngredientsMinTol.AsFloat
    else
      RemainingWtForThisScaleTolerance := fWtRemaining;

    lbRemainingWeight.Caption := FormatFloat(fScaleDisplayFormat+'kg', RemainingWtForThisScaleTolerance - DisplayWeight);
  end
  else
    lbRemainingWeight.Caption := '';

  if (AnalogMeter1 <> nil) then
  begin
    if IngredientSelected then
      AnalogMeter1.Value := CalcWeightPercentage(DisplayWeight)
    else
      AnalogMeter1.Value := 0;
//    SetTotalMixValue(fCurrentMixPercentage+Trunc(AnalogMeter1.Value/fAnalogInc));

    if IngredientSelected then
    begin
      if fManualWtActive     // or are We Mid Weighing
      or (
         (not IsCurrentProcessStepAt(psTareReqd)) and
         (not IsCurrentProcessStepAt(psRemoveContOrSemiAutoTare)) and
         (not IsCurrentProcessStepAt(psPlaceContainerOnScaleAndSemiAutoTare)) and
         (not IsCurrentProcessStepAt(psRemoveContainerFromScale))) then
      begin
        if IsWeightInToleranceForScale(DisplayWeight, rmdIngredientsMinTol.AsFloat,
                                       rmdIngredientsMaxTol.AsFloat) then
          SetProcessStepTo(psWeightisInToleranceAccept)
        else if CompareWts(DisplayWeight, rmdIngredientsMinTol.AsFloat) < 1 then //must be low
          SetProcessStepTo(psAddIngredient)
        else
          SetProcessStepTo(psWeightToHighForIngredient)
      end;
    end;
  end;
end;


////////////////////////////////////////////////////////////////////////////////
// IsWaitingForContainerRemoval
// Tests User Prompt for condition of waiting for a container removal or tare
////////////////////////////////////////////////////////////////////////////////
function TfrmFormixProcessRecipe.IsWaitingForContainerRemoval : Boolean;
begin
  Result := TRUE;
  if IsCurrentProcessStepAt(psTareReqd) then Exit;
  if IsCurrentProcessStepAt(psRemoveContOrSemiAutoTare)      then Exit;
  if IsCurrentProcessStepAt(psRemoveContainerFromScale)      then Exit;
  Result := FALSE;
end;

////////////////////////////////////////////////////////////////////////////////
// UpdateFromScale
// Process Weight received from scale
////////////////////////////////////////////////////////////////////////////////
procedure TfrmFormixProcessRecipe.UpdateFromScale(ScaleWeightStr : String);
var  WeightAsFloat: Extended;
//     LastDisplayedWt: Extended;
begin
{  if not TryStrToFloat(lbScaleWt.Caption,LastDisplayedWt) then
    LastDisplayedWt := 0;
}
  WeightAsFloat := 0;
  if TryStrToFloat(ScaleWeightStr,WeightAsFloat) then
    fScaleWeight := FormatFloat(fScaleDisplayFormat,WeightAsFloat);

  if (WeightAsFloat <=0) then
  begin
    if not IngredientSelected then
    begin
      CancelCurrentTare(FALSE);
      SetProcessStepTo(psSelectIngredientFromTheListBelow)
    end
    else
    begin
      if rmdIngredientsNoTare.Value then //cancel tare and user is expected to semi-auto tare indicator.
      begin
        if not dmFormix.fNoAutoCancelOfTares then
          CancelCurrentTare(FALSE);
        //else "NoTare" ingredients can now have container filled whilst off the scale pan.
        SetProcessStepTo(psAddIngredient);
      end
      else
      begin
        CancelCurrentTare(FALSE);
        SetProcessStepTo(psPlaceContainerOnScaleAndSemiAutoTare);
      end;
    end;
  end;
//  else
//  begin
//    if IngredientSelected then
//    begin
//      if not IsWaitingForContainerRemoval then
//        SetLabelsAndMeter(fScaleWeight);
//    end
//  end;
  SetLabelsAndMeter;  // Update Analog and Remaining Wt etc.
(*
  if (WeightAsFloat <= 0) then
  begin
    //Container Removed From Scale;
    CancelCurrentTare(FALSE);
    if not IngredientSelected then SetProcessStepTo(psSelectIngredientFromTheListBelow)
                              else SetProcessStepTo(psPlaceContainerOnScaleAndSemiAutoTare);

    if (CompareValue(LastDisplayedWt,WeightAsFloat) <> 0) and
       (ScaleWeightStr <> '-.') then
      lbScaleWt.Caption := FormatFloat(fScaleDisplayFormat,WeightAsFloat);
    Exit;
  end
  else
  begin
    // Weight Has Changed
    if (lbScaleWt.Caption = '')
    or (CompareValue(LastDisplayedWt,StrtoFloat(fScaleWeight)) <> 0)
    {or (    (CompareValue(StrToFloat(lbScaleWt.Caption),0.0) = 0)
        and (CompareValue(StrToFloat(fScaleWeight),0.0) = 0))} then
    begin
      if IsWaitingForContainerRemoval then
      begin
        if StrToFloat(fScaleWeight) > 0 then
        begin
          lbScaleWt.Caption := fScaleWeight;
          exit;
        end
        else SetProcessStepTo(psPlaceContainerOnScaleAndSemiAutoTare);
      end
      else SetLabelsAndMeter(fScaleWeight)
    end;
  end;
*)
end;

procedure TfrmFormixProcessRecipe.RefreshBatchNoDisplay;
begin
  lbBatchNo.Caption      := 'Batch No: '+dmFormix.GetBatchStrForFormixTran;
end;

procedure TfrmFormixProcessRecipe.RefreshDisplayOfPreWghIngredSetup;
{Updates edit boxes showing SourceBarcode/SourceItem, LotNumber and Ingredient temperature}
begin
  edLotNo.Text := dmFormix.GetLotNumber;
  edSourceId.Text := dmFormix.GetExpandedSourceBarcode;
  edTemperature.Text := dmFormix.CurrIngredientTemperatureStr;
end;

////////////////////////////////////////////////////////////////////////////////
//Select Ingredient, Called when Ingredient selection panel selected
////////////////////////////////////////////////////////////////////////////////
procedure TfrmFormixProcessRecipe.SelectIngredient(Sender: TObject);
var
    IngredientPanel :TPanel;
    AutoWeight : boolean;
//    i : integer;

  function SetupForIngredient(OrderLineNo : integer) : Boolean;
  {REQUIRES: dmFormix.pvtblOrderLine to be located on line for weighing.
   PROMISES: To call DeselectCurrentIngredient() before returning false.}
  var MixLRec: TMixLineRecord;
      WrkMix_Ingred_TotWt,
      WrkMix_Ingred_WtIncrements,
      LowestWt,
      HighestWt: Double;
      WrkMix_Ingred_Weighings,
      WrkMix_Ingred_WghsPerCont: Integer;
      BatchOk,
      OneScanOk: Boolean;
      WrkStr: String;
//      SavePos: TBookMark;
      PreWghSetupOk : boolean;

  begin
    Result := FALSE;
    dmFormix.ClearSourceItemDetails;
    dmFormix.ClearSelectedLineDetails;
    //Get OrderLine Data Related to panel selected

//    SavePos := rmdIngredients.GetBookmark;
    rmdIngredients.Locate(rmdIngredientsLineNo.FieldName, OrderLineNo, []);

    if fKeyIngredientReq then
    begin
      if not SameText(TrimRight(fKeyIngredientCode),TrimRight(rmdIngredientsProductCode.Value)) then
      begin
//        rmdIngredients.GotoBookmark(SavePos);  // Restore Position
//        rmdIngredients.FreeBookmark(SavePos);
        TermMessageDlg(keyIngredientStr+ ' '+ fKeyIngredientCode+' must be completed first'
                       ,mtInformation,[mbOk],0);
        DeselectCurrentIngredient(TRUE);
        Exit;
      end;
    end;

//    rmdIngredients.FreeBookmark(SavePos);

    fCurrentIngredientCode := rmdIngredientsProductCode.Value;
    fCurrentOrderLineNo    := rmdIngredientsLineNo.AsInteger;

    {Need to check if the ingredient has been completed by another scale}
    with dmFormix do
    begin
      if not PvtableLocateUsingIndex(pvtblOrderLine, OL_OrderNo+';'+OL_OrderNoSuffix+';'+OL_LineNo,
                            VarArrayOf([pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                        pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger,
                                        rmdIngredientsLineNo.AsInteger]),[]) then
      begin
        TermMessageDlg('Order Line no longer exists.',mtInformation,[mbOk],0);
        DeselectCurrentIngredient(TRUE);
        EXIT;
       {****}
      end;
      FillChar(MixLRec,SizeOf(MixLRec),#0);
      ConstructMixLineRecForOrdLine(dmFormix.CurrentMixNo{dmFormix.pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger},MixLRec);
    end;
    dmFormix.SelectedLineIsAutoWeigh :=
            TProcessTypes(dmFormix.pvtblOrderLine.FieldByName(OL_ProcessType).AsInteger) = PTAuto;
    if dmFormix.IsThisLineCompleteForCurrMix(MixLRec.ML_WghsDone,MixLRec.ML_WtDone) then
    begin
      with MixLRec do
        TermMessageDlg('This ingredient has already been completed.'+#10+
                   'MIX NO.: '+IntToStr(ML_MixNo)+#10+
                   'ORDER  : '+OrderNoToString(ML_OrderNo, ML_Revision)+#10+
                   'LINE NO: '+IntToStr(ML_LineNo)+#10+
                   'WT.DONE: '+DoubleToStr(ML_WtDone,1,4),
                       mtInformation,[mbOk],0);
      DeselectCurrentIngredient(TRUE);
    end
    else
    begin
      {Need to recheck weight tolerances and update header screen}
      dmFormix.CalcIngredReqsForMixWt(
        dmFormix.CalcCompensatedBatchMixWt(dmFormix.CurrentMixNo{dmFormix.pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger}),
                                           MixLRec,WrkMix_Ingred_TotWt,WrkMix_Ingred_Weighings,
                                           WrkMix_Ingred_WtIncrements,WrkMix_Ingred_WghsPerCont);

      dmFormix.CalcWOLineTolWts(WrkMix_Ingred_WtIncrements,
                                dmFormix.pvtblOrderHeader[OH_MixType],
                                WrkMix_Ingred_TotWt,
                                MixLRec.ML_WtDone,
                                LowestWt,
                                HighestWt);

      dmFormix.AdjustTolToScaleRes(LowestWt,HighestWt);

      rmdIngredients.Edit;
      rmdIngredientsMinTol.AsFloat             := LowestWt;
      rmdIngredientsMaxTol.AsFloat             := HighestWt;
      rmdIngredientsWtRemaining.AsFloat        := dmformix.CalcLineGrossWtReqdForCurrMix;
      rmdIngredientsWeighsPerContainer.AsFloat := WrkMix_Ingred_WghsPerCont;
      rmdIngredientsWeightIncrements.AsFloat   := WrkMix_Ingred_WtIncrements;
      rmdIngredients.Post;

      fCurrentContainers := dmFormix.GetContainersForIngredient;
      {Just try clearing the current scale wt as it will be added by the next packet in}
      lbScaleWt.Caption := '';
      jvpOrderDetails.Caption := 'Order '+
                                 dsMemOrderHeader.DataSet.FieldByName('Order').AsString+
                                 '   '+
                                 dsMemOrderHeader.DataSet.FieldByName('Recipe').AsString+' '+
                                 dsMemOrderHeader.DataSet.FieldByName('Description').AsString;

      fWtRemaining := rmdIngredientsWeightIncrements.AsFloat;
      if rmdIngredientsWeighsPerContainer.AsInteger > 1 then
       { Ideally it should say Number x FixWt + Fraction for fixed weight
         ingredients - so advice not to use fractions of fixed weights
         in Even Distribution mixes. }
        edRequires.Text := IntToStr(rmdIngredientsWeighsPerContainer.AsInteger)+' x '+
                           FormatFloat('#,0.000',rmdIngredientsWeightIncrements.AsFloat)+'kg'
      else
        edRequires.Text := FormatFloat('#,0.000',rmdIngredientsWeightIncrements.AsFloat)+'kg';

      edTolerance.Text := FormatFloat('#,0.000',rmdIngredientsMinTol.AsFloat)+
                         ' - '+
                         FormatFloat('#,0.000',rmdIngredientsMaxTol.AsFloat);
      edProductCode.Text := rmdIngredientsProductCode.AsString;
      edProductDesc.Text := rmdIngredientsProductDesc.AsString;
      edMixNumber.Text := dsMemOrderHeader.DataSet.FieldByName('MixNoDesc').AsString+
                          ' of '+
                          dsMemOrderHeader.DataSet.FieldByName('MixesRequired').AsString;
      edContainerDesc.Text := '('+
                              FormatFloat('#,0.000',dmFormix.pvtblOrderLine.FieldByName(OL_ContainerWeight).AsFloat)+
                              'kg) '+
                              IntToStr(dmFormix.GetCurrentContainerNo)+
                              ' of '+
                              IntToStr(fCurrentContainers);

      CreateAnalogMetre(rmdIngredientsMinTol.AsFloat,rmdIngredientsMaxTol.AsFloat);

      plMixDetails.Visible   := TRUE;
      plOrderDetails.Visible := FALSE;
      //TODO: MachineID
      dmFormix.CurrentIngredientLot := dmFormix.GetLotNoForIngredient(dmFormix.GetCurrentMachineId,
                                                            Copy(fCurrentIngredientCode+SpaceString,1,8));
      RefreshDisplayOfPreWghIngredSetup;

      if  dmFormix.fUseOneScanOnly
      and (not dmFormix.SelectedLineIsAutoWeigh)
      then {scan source barcode once, possibly use it for batch and/or lot code;
            and cache for validation later on.}
      begin
        OneScanOk  := FALSE;
        dmFormix.fOneScanStr := '';
        dmFormix.fOneScanStr := TfrmFormixStdEntry.GetStdStringEntry(
                           'Scan Barcode for '+rmdIngredientsProductDesc.AsString,
                           'Barcode',20,OneScanOk,FALSE,'',TRUE{MustEnterVal},
                           (not dmFormix.fAllowKeyedBarcode){PasswordedKeyboard});
        if OneScanOk then
        begin
          if dmFormix.fEnquireForBatchNo then
          begin
            dmFormix.CurrentBatch := UpperCase(Copy(dmFormix.fOneScanStr,1,6));
            RefreshBatchNoDisplay;
          end;
        end
        else
        begin
          DeselectCurrentIngredient(FALSE);
          Result := FALSE;
          dmformix.fOneScanStr := '';
          Exit;
        end;
      end
      else {batch number is not automatically related to barcode scan.}
      begin
        {Need to get lot number and batch number}
        if dmFormix.fEnquireForBatchNo then
        begin
          BatchOk := FALSE;
          WrkStr  := '';
          WrkStr := TfrmFormixStdEntry.GetStdStringEntry('Enter Batch Number','Batch Number',6,BatchOk,FALSE,'',TRUE);
          if BatchOk then
          begin
            dmFormix.CurrentBatch := UpperCase(WrkStr);
            RefreshBatchNoDisplay;
          end
          else
          begin
            DeselectCurrentIngredient(FALSE);
            Result := FALSE;
            Exit;
          end;
        end
        else//check if batch number should change.
        begin
          BatchOK := True;
          if  (dmFormix.fPromptForBatchOnOrd)
          and (dmFormix.LastOrderNumber <> dmFormix.CurrentFullOrderNumberAsString) then
            BatchOK := False;
          if  (dmFormix.fPromptForBatchOnMix)
          and (   (dmFormix.LastOrderNumber <> dmFormix.CurrentFullOrderNumberAsString)
               or (dmFormix.LastMixNumber   <> dmFormix.CurrentMixNo)) then
            BatchOK := False;
          dmFormix.LastOrderNumber := dmFormix.CurrentFullOrderNumberAsString;
          dmFormix.LastMixNumber   := dmFormix.CurrentMixNo;
          if (not BatchOK) then
          begin
            WrkStr := TfrmFormixStdEntry.GetStdStringEntry('Change Batch Number from '+dmFormix.GetBatchStrForFormixTran,
                                                           'Batch Number',6,BatchOk,FALSE,'',TRUE);
            if BatchOk then
              dmFormix.CurrentBatch := UpperCase(WrkStr);
          end;
          RefreshBatchNoDisplay;
        end;
      end;

      PreWghSetupOk := PreWeighingSetup(dmFormix.pvtblOrderLine, rmdIngredientsMinTol.AsFloat,
                                        rmdIngredientsMaxTol.AsFloat);
      RefreshDisplayOfPreWghIngredSetup;
      if (not PreWghSetupOk)
      {and (dmFormix.GetRegBooleanDef(REG_Scale+TerminalName,REG_SFXUseOneScanOnly,FALSE))}
      then {make sure they can't continue with invalid source barcode etc.}
      begin
        Result := FALSE;
        DeselectCurrentIngredient(FALSE);
        dmFormix.fOneScanStr := '';
       (* btExit.Click; {Appears to be put in to force weighing process messages to start again.
                       Otherwise you can get an 'Add Ingredient' message when no ingredient is
                       selected.
                      }           *)
        Exit;
      end;
     {Check to see if it needs to go into a new container}
      if dmFormix.WeighInDiffContainer(fCurrentContainers) then
      begin
        {It Does}
        fTareWt := 0.0;
        SetupTareButton;
        //SetProcessStepTo(psTareReqd);
        fTareSet := FALSE;
        //btPartWeigh.Visible := FALSE;
        SetProcessStepTo(psRemoveContainerFromScale);
      end
      else
      begin
        {It Doesnt}
(*        SetTareWt(StrToFloat(lbScaleWt.Caption)+TareWt);
        lbScaleWt.Caption := '0.00';
        SetupCancelTareButton;
        SetProcessStepTo(psAddIngredient);
        btPartWeigh.Visible := TRUE;
        tmTareFlasher.Enabled := FALSE; *)
      end;
      Result := TRUE;
    end;
  end;

begin
  if  dmFormix.fQAAtMixStart
  and (not dmFormix.QAHasBeenDoneForMixInPrepArea(dmFormix.CurrentMixNo)) then
  begin
    dmFormix.RunQAChecksForMix;
    frmFormixMain.AddUpdateRecordToList(dmFormix.CurrentMixNo, true);
    if not dmFormix.QAHasBeenDoneForMixInPrepArea(dmFormix.CurrentMixNo) then
      EXIT;
  end;
  fManualWtActive := false;
  SwitchOffScalePortEvent;
  try
    ClearSelectionFromIngredPanels;
    if Sender is TPanel then IngredientPanel := TPanel(Sender)
    else IngredientPanel := TPanel(TControl(Sender).Parent);
    IngredientPanel.Color := col_IngredientSelected;
    if SetupForIngredient(GetOrderLineNoForIngredientButton(IngredientPanel)) then
    begin
      AutoWeight := dmFormix.UseSourceWt
                 or dmFormix.SelectedLineIsAutoWeigh;
      if AutoWeight then
      begin
        if dmFormix.UseSourceWt then
          fManualWeight := dmFormix.CurrSourceWtKg
        else
        begin
          fManualWeight := dmFormix.RoundWtUpToNextScaleInc(fWtRemaining);
        end;
        fManualWtActive := true;
        SetProcessStepTo(psAddIngredient);
      end
      else
        btTare.Visible := TRUE;
      SetLabelsAndMeter;
      if IsCurrentProcessStepAt(psWeightIsInToleranceAccept) and dmFormix.UseSourceWt then
      begin
  //    AcceptWeight; access violates after returning
        PostMessage(plAnalog.Handle, WM_LBUTTONDOWN, 0, $00010001);
        PostMessage(plAnalog.Handle, WM_LBUTTONUP, 0, $00010001);
      end;
    end;
  finally
    SwitchOnScalePortEvent;
  end;
end;



procedure TfrmFormixProcessRecipe.plMixDetailsClick(Sender: TObject);
begin
  if IngredientSelected then
  begin
    plMixDetails.Visible   := FALSE;
    plOrderDetails.Visible := TRUE;
  end;
end;

procedure TfrmFormixProcessRecipe.plOrderDetailsClick(Sender: TObject);
begin
  if IngredientSelected then //switch to Mix Details window
  begin
    plMixDetails.Visible   := TRUE;
    plOrderDetails.Visible := FALSE;
  end;
end;

function TfrmFormixProcessRecipe.CreateNewTransaction(NetWt : Double): Boolean;
{var FixedWt : Double;}
begin
  SwitchOffScalePortEvent;
  try
    Result := FALSE;
  {  FixedWt     := 0;}
    if not IngredientSelected then
    begin
      TermMessageDlg('Select an ingredient first',mtError,[mbOk],0);
      Exit;
    end;

    if lbScaleWt.Caption <> '' then
    begin
      if dmFormix.pvtblOrderLine[OL_ProcessType] = PTStep then
      begin
        Result := dmFormix.CreateTransaction(0.0,PTStep);
        if Result then fWtRemaining := fWtRemaining - 0.0;
      end
      else
      begin
        if (dmFormix.pvtblOrderLine[OL_ProcessType] = PTCount) then { assume user has weighed it off elsewhere }
        begin
          Result := dmFormix.CreateTransaction(dmFormix.pvtblOrderLine.FieldByName(OL_FixedWeight).AsFloat,PTCount);
          if Result then fWtRemaining := fWtRemaining - dmFormix.pvtblOrderLine.FieldByName(OL_FixedWeight).AsFloat;
        end
        else
        begin
          if dmFormix.WeightOkForTran(NetWt,
                                      dmFormix.pvtblOrderLine[OL_ProcessType],
                                      rmdIngredientsMinTol.AsFloat,
                                      rmdIngredientsMaxTol.AsFloat,
                                      TRUE{LowTolDisabled}) then
          begin
            Result := dmFormix.CreateTransaction(NetWt,
                                    dmFormix.pvtblOrderLine[OL_ProcessType]);
            if Result then fWtRemaining := fWtRemaining - NetWt;
          end;
        end;
      end;
    end
    else TermMessageDlg('No weight currently entered',mtError,[mbOk],0);
  finally
    SwitchOnScalePortEvent;
  end;
end;

procedure TfrmFormixProcessRecipe.btExitClick(Sender: TObject);
begin
  fReLaunchProcessScreen := FALSE;
  Close;
end;

procedure TfrmFormixProcessRecipe.SetTareWt(GrossWt: Double);
begin
  if not TareWtExists then
    fInitialContainerWt := GrossWt;
  fTareWt := GrossWt;

  if GrossWt > 0.0 then
  begin
    SetupCancelTareButton;
    fTareSet := TRUE;
  end
  else SetupTareButton;
  SetLabelsAndMeter;
end;

function TfrmFormixProcessRecipe.TareWtExists: Boolean;
begin
  Result := (fTareWt > 0.0001) or (fTareWt < -0.0001);
end;

procedure TfrmFormixProcessRecipe.SetupCancelTareButton;
begin
  btTare.Caption := rsCancelTare;
end;

procedure TfrmFormixProcessRecipe.SetupTareButton;
begin
  btTare.Caption := rsSemiAutoTare;
end;

function TfrmFormixProcessRecipe.IngredientSelected: Boolean;
//var i: Integer;
begin
  Result := fCurrentOrderLineNo > -1;
{  Result := FALSE;
  for i := 0 to plIngredientList.ControlCount-1 do
  begin
    if plIngredientList.Controls[i] is TPanel then
    begin
      if TPanel(plIngredientList.Controls[i]).Color = col_IngredientSelected then
      begin
        Result := TRUE;
        Break;
      end;
    end;
  end;
}
end;

procedure TfrmFormixProcessRecipe.btTareClick(Sender: TObject);
begin
  {Either set the tare or cancel it}
  if btTare.Caption = '' then btTare.Caption := rsSemiAutoTare;
  if btTare.Caption = rsSemiAutoTare then
  begin
    if  (lbScaleWt.Caption <> '')
    and (GetNetWeight > -0.0001) then
    begin
      SetTareWt(GetNetWeight);
      SetupCancelTareButton;
      SetProcessStepTo(psAddIngredient);
      tmTareFlasher.Enabled := FALSE;
    end;
  end
  else CancelCurrentTare;
end;

procedure TfrmFormixProcessRecipe.btOptionsClick(Sender: TObject);
var SaveCurrentScale: Integer;
begin
  {Show the options screen}
  SaveCurrentScale := dmFormix.CurrentScale;
  dmFormix.dsOrderHeader.OnDataChange := nil;
  try
    frmProcessRecipeOptions := TfrmProcessRecipeOptions.Create(Self);
    with frmProcessRecipeOptions do
    begin
      ShowModal;

      if dmFormix.CurrentScale <> SaveCurrentScale then
      begin
        if InitialiseCurrentScale(True) then
        begin
          dmFormix.SetLastUsedScale;
        end
        else
        begin
          ScaleConnectError;
          dmFormix.CurrentScale := SaveCurrentScale;
          InitialiseCurrentScale(True);
        end;
      end;
  {
      if ManualTareWeight <> 0 then
        lbScaleWt.Caption := FormatFloat('#0.00',ManualTareWeight);
  }
      if ManualWeight     <> 0 then
      begin
        fManualWeight := ManualWeight;
        fManualWtActive := true;
        SetProcessStepTo(psAddIngredient);
        SetLabelsAndMeter;
  {
        if fTareSet then
        begin
          lbScaleWt.Caption := FormatFloat('#0.00',ManualWeight-fTareWt);
          if btPartWeigh.Visible then
            lbRemainingWeight.Caption := FormatFloat('#0.000kg',fWtRemaining-ManualWeight+fTareWt)
          else lbRemainingWeight.Caption := '';
          if AnalogMeter1 <> nil then
          begin
            AnalogMeter1.Value := CalcWeightPercentage(ManualWeight-fTareWt);
            SetTotalMixValue(fCurrentMixPercentage+Trunc(AnalogMeter1.Value/fAnalogInc));
          end;
        end
        else
        begin
          lbScaleWt.Caption := FormatFloat('#0.00',ManualWeight);
          if btPartWeigh.Visible then
            lbRemainingWeight.Caption := FormatFloat('#0.000kg',fWtRemaining-ManualWeight)
          else lbRemainingWeight.Caption := '';

          if AnalogMeter1 <> nil then
          begin
            AnalogMeter1.Value := CalcWeightPercentage(ManualWeight);
            SetTotalMixValue(fCurrentMixPercentage+Trunc(AnalogMeter1.Value/fAnalogInc));
          end;
        end;

        // Mid Weighing?
        if (not IsCurrentProcessStepAt(psTareReqd)) and
           (not IsCurrentProcessStepAt(psRemoveContOrSemiAutoTare)) and
           (not IsCurrentProcessStepAt(psPlaceContainerOnScaleAndSemiAutoTare)) and
           (not IsCurrentProcessStepAt(psRemoveContainerFromScale)) then
        begin
          if (AnalogMeter1 <> nil) and
             (IngredientSelected) then
          begin
            if (AnalogMeter1.Value < AnalogMeter1.LowZone) then
              SetProcessStepTo(psAddIngredient);
            if (AnalogMeter1.Value >= AnalogMeter1.LowZone) and
               (AnalogMeter1.Value <= AnalogMeter1.HighZone) then
              SetProcessStepTo(psWeightisInToleranceAccept);
            if (AnalogMeter1.Value > AnalogMeter1.HighZone) then
              SetProcessStepTo(psWeightToHighForIngredient);
          end;
        end;
  }
      end;

      if fMixChangedFromOptions then
      begin
        fMixChangedFromOptions := false;
        {They have changed the mix so need to cancel any tare and
         show remove container message}
        //dmFormix.OverrideUser := '';
        DeselectCurrentIngredient(FALSE);
        if fTareSet then
          SetProcessStepTo(psRemoveContainerFromScale);
        CancelCurrentTare(FALSE);
        if GetNetWeight > 0.0 then
          SetProcessStepTo(psRemoveContainerFromScale);
  {     if not IngredientSelected then
         SetlbMessage(99);}
        frmFormixMain.AddUpdateRecordToList(dmFormix.CurrentMixNo, true);
        fFirstTime := TRUE;
        BuildProductList;
      end
      else
        frmFormixMain.AddUpdateRecordToList(dmFormix.CurrentMixNo, true);
      Free;
    end;
  finally
    dmFormix.dsOrderHeader.OnDataChange := dmFormix.dsOrderHeaderDataChange;
  end;
end;

procedure TfrmFormixProcessRecipe.CreateAnalogMetre(MinVal, MaxVal: Double);
//var i: Integer;
begin
  if AnalogMeter1 = nil then AnalogMeter1 := TAnalogMeter.Create(Self);
  with AnalogMeter1 do
  begin
    Parent := plAnalog;
    Align := alClient;
{This aint doing anything with the following line setting fAnalogInc to 1.
 Should it have be using scale DP or increment?
    if dmFormix.GetRegIntegerDef(REG_Scale+TerminalName,REG_ScaleIncrement,1) > 1 then
    begin
      for i := 2 to dmFormix.GetRegIntegerDef(REG_Scale+TerminalName,REG_ScaleIncrement,1) do
        fAnalogInc := fAnalogInc*10;
    end;
}
    fAnalogInc := 1;
    Min := 0;
    Max := 100*fAnalogInc;
    LowZone := 50;
    HighZone := 75;
    Caption := 'Touch to Accept';
    ShowTicksScale := FALSE;

    TickDigits := 10;
    ValueDigits := 10;
    TickPrecision := 10;
    ValuePrecision := 10;
    AngularRange := 270;

    ShowZones := TRUE;
    NeedleWidth := 2;
    Color := clBlack;
    OKzoneColor := clLime;
    Font.Color := clWhite;
    TickColor := clWhite;
    ShowValue := FALSE;
    OnClick := plAnalogClick;
    KnobSize := 35;
  end;
end;

function TfrmFormixProcessRecipe.IsSourceContainerWtOk(ActualIngredWt : double) : boolean;
const SourceIsEmptyMsg = 'The Source Container weight is'+#13#10+
                         'less than the weight you are recording.';
begin
  Result := false;
  if dmformix.SendFopsIssueTrans then
  begin
    if (dmFormix.SourceItemFopsSerNo <> 0) then
    begin
      if dmFormix.CurrSourceWtKg < ActualIngredWt then
      begin
        if not dmFormix.fAllowWtAboveSourceWt then
        begin
          TermMessageDlg(SourceIsEmptyMsg+#13#10+#13#10+
                         'Ingredient weight cannot be accepted.' ,mtError,[mbOk],0);
          Exit;
        end
        else if TermMessageDlg(SourceIsEmptyMsg+#13#10+#13#10+
                          'Do you still wish to continue?',mtConfirmation,[mbYes,mbNo],0) = mrNo then
          Exit
        else
          dmFormix.SourceWtCheckBypassReason := 'User '''+dmFormix.GetCurrentUser+''' chose to continue.';
      end;
    end
    else
      dmFormix.SourceWtCheckBypassReason := 'Failed to find Source item in FOPS.';
  end;
  Result := true;
end;

procedure TfrmFormixProcessRecipe.plAnalogClick(Sender: TObject);
begin
  AcceptWeight;
end;

procedure TfrmFormixProcessrecipe.AcceptWeight;
var NetWeight : extended;
    MixIsFinishedInPrepArea, MixIsComplete : boolean;
begin
  dmFormix.dsOrderHeader.OnDataChange := nil;
  try
    if (IsCurrentProcessStepAt(psWeightisInToleranceAccept)) then
    begin
      NetWeight := GetNetWeight;//doesnt get a new scale weight.
      if IsWeightInToleranceForScale(NetWeight, rmdIngredientsMinTol.AsFloat,
                                     rmdIngredientsMaxTol.AsFloat) then
      begin
        if IsCurrentIngredientComplete then Exit;
        if not IsCurrentWeightOk(NetWeight,FALSE) then Exit;
        if not IsSourceContainerWtOk(NetWeight) then Exit;
        if CreateNewTransaction(NetWeight) then
        begin
          PossiblyIssueFopsTranRemainder(NetWeight);
//          fCurrentMixPercentage := fCurrentMixPercentage+Trunc(AnalogMeter1.Value);

          DeselectCurrentIngredient(FALSE);

          UpdateOrderMemTable;
          //plMixDetailsClick(nil);
          if dmFormix.CalcMixStatus(MixIsFinishedInPrepArea, MixIsComplete) then
          begin
            if MixIsComplete then {Update the order header and mix totals}
              dmFormix.MarkMixCompleteIfNecess;
            if not MixIsFinishedInPrepArea then
            begin
              BuildProductList;
              HidePartWeighDetails;
              fFirstTime := FALSE;
              if fKeyIngredientReq then fKeyIngredientReq := FALSE;

              if dmFormix.WeighInDiffContainer(fCurrentContainers) then
              begin
                {It Does}
                fTareWt := 0.0;
                SetupTareButton;
                SetProcessStepTo(psTareReqd);
                fTareSet := FALSE;
                btPartWeigh.Visible := FALSE;
                SetProcessStepTo(psRemoveContainerFromScale);
              end
              else
              begin
                {It Doesnt}
                {Apply semi auto tare automatically}
                SetTareWt(NetWeight+fTareWt);
                SetupCancelTareButton;
                btPartWeigh.Visible := TRUE;
                lbRemainingWeight.Visible := TRUE;
                tmTareFlasher.Enabled := FALSE;
                lbScaleWt.Caption := '';
                SetProcessStepTo(psSelectIngredientFromTheListBelow);
              end;
            end
            else // mix is finished in this prep area
            begin
              if dmFormix.fNoOfMixTickets > 0 then
                dmFormix.PrintMixTicket(dmFormix.CurrentMixNo);
              {Try and find next mix}
              if not (dmFormix.SetCurrMixNoToAnUnfinishedMix in [FM_AllMixesComplete, FM_MixesFinishedInArea]) then
              begin
                dmFormix.CurrentMixNo := dmFormix.pvtblOrderHeader.FieldByName(OH_CurrentMix).AsInteger;
                DeselectCurrentIngredient(FALSE);
                CancelCurrentTare;
                UpdateOrderMemTable;
                fFirstTime := TRUE;
                BuildProductList;
//                fCurrentMixPercentage  := 0;
//                SetTotalMixValue(0);
                lbScaleWt.Caption := '';
                SetProcessStepTo(psRemoveContainerFromScale);
              end
              else
              begin
                CancelCurrentTare;
                TermMessageDlg('Order is finished in this area.',mtInformation,[mbOk],0);
                ModalResult := mrOk;
              end;
            end;
          end;
        end;
      end
      else if CompareWts(NetWeight, rmdIngredientsMaxTol.AsFloat) > 0 then
        TermMessageDlg('Current ingredient weight too high',mtError,[mbOk],0)
      else
        TermMessageDlg('Current ingredient weight too low',mtError,[mbOk],0);
    end;{process step = wt in tolerance}
  finally
    dmFormix.dsOrderHeader.OnDataChange := dmFormix.dsOrderHeaderDataChange;
  end;
end;

procedure TfrmFormixProcessRecipe.btPartWeighClick(Sender: TObject);
var NetWeight : extended;
begin
  {Need to do the part weigh option, this creates a transaction and decrement weight remaining}
  NetWeight := GetNetWeight;
  dmFormix.dsOrderHeader.OnDataChange := nil;
  try
    if  IngredientSelected
    and (NetWeight > 0.0) then
    begin
      if IsCurrentProcessStepAt(psAddIngredient) then
      begin
        if IsWeightInToleranceForScale(NetWeight, rmdIngredientsMinTol.AsFloat,
                                       rmdIngredientsMaxTol.AsFloat)
        or (CompareWts(NetWeight, rmdIngredientsMaxTol.AsFloat) > 0) then
          TermMessageDlg('Weight is too high for a Part Weigh.',mtError,[mbOk],0)
        else
        begin
            if IsCurrentIngredientComplete then Exit;
            if not IsCurrentWeightOk(NetWeight,TRUE) then Exit;
            if not IsSourceContainerWtOk(NetWeight) then exit;
            if CreateNewTransaction(NetWeight) then
            begin
              PossiblyIssueFopsTranRemainder(NetWeight);
              btTare.Caption := rsSemiAutoTare;
              UpdateOrderMemTable;
              fFirstTime := TRUE;
              BuildProductList;//will SelectIngredient (for same ingredient) which will ask for source barcode etc.
              if not fManualWtActive then //source barcode hasnt set manualwt, need to tare new gross weight off.
              begin
                SetProcessStepTo(psRemoveContOrSemiAutoTare);
                HidePartWeighDetails;
              end;
              if  (dmFormix.CurrSourceWtKg < 0)
              and (fCurrentOrderLineNo > 0){DeselectCurrentIngredient has not been called} then
              begin
                SwitchOffScalePortEvent;
                try
                  //pvtblOrderLine should be located by BuildProductList calling SelectIngredient.
                  PreWeighingSetup(dmFormix.pvtblOrderLine, rmdIngredientsMinTol.AsFloat,
                                   rmdIngredientsMaxTol.AsFloat);
                  RefreshDisplayOfPreWghIngredSetup;
                finally
                  SwitchOnScalePortEvent;
                end;
              end;
            end;
        end;
      end;
    end;
  finally
    dmFormix.dsOrderHeader.OnDataChange := dmFormix.dsOrderHeaderDataChange;
  end;
end;

function TfrmFormixProcessRecipe.CalcWeightPercentage(ForWeight: Double): Double;
var
   FractionOfUnderRange,
   FractionOfOkRange,
   FractionOfOverRange : double;
   DialPercent : double;
   Tolerance : double;
   MaxDialWt : double;
begin
  // adjust OK zone to indicate tightness of tolerance
  DialPercent := 25; //use DialPercent for calc ok range percentage
  Tolerance := rmdIngredientsMaxTol.AsFloat - rmdIngredientsMinTol.AsFloat;
  if  (Tolerance < (rmdIngredientsMinTol.AsFloat / 2)) //tolerance is smaller than LowWt even with magnifying effect on okRange
  and ((Tolerance / fScaleIncrement) < 5) then //tolerance is less than 5 full scale increments
    DialPercent := Round(Tolerance / fScaleIncrement) * 5; //Allow 5percent of dial for each scale increment in ok range
  if DialPercent < 5 then
    DialPercent := 5;
  AnalogMeter1.HighZone := AnalogMeter1.LowZone + DialPercent;

  if IsWeightInToleranceForScale(ForWeight, rmdIngredientsMinTol.AsFloat, rmdIngredientsMaxTol.AsFloat) then
  begin
    if CompareWts(rmdIngredientsMaxTol.AsFloat, rmdIngredientsMinTol.AsFloat) > 0 then //there is a tolerance
      FractionOfOkRange := (ForWeight - rmdIngredientsMinTol.AsFloat) /
                               (rmdIngredientsMaxTol.AsFloat - rmdIngredientsMinTol.AsFloat)
    else
      FractionOfOkRange := 0.5;

    DialPercent := AnalogMeter1.LowZone + (FractionOfOkRange * (AnalogMeter1.HighZone - AnalogMeter1.LowZone));
    if DialPercent > AnalogMeter1.HighZone then DialPercent := AnalogMeter1.HighZone; //make sure it doesnt look over
    if DialPercent < (AnalogMeter1.LowZone + 0.00001) then
      DialPercent := AnalogMeter1.LowZone + 0.00001; //make sure the colour changes to ok - green
  end
  else if CompareWts(ForWeight, rmdIngredientsMinTol.AsFloat) < 1 then //must be low
  begin
    if rmdIngredientsMinTol.AsFloat > 0.0001 then
      FractionOfUnderRange := (ForWeight / rmdIngredientsMinTol.AsFloat)
    else
      FractionOfUnderRange := 0;
    DialPercent := FractionOfUnderRange * AnalogMeter1.LowZone;
    if DialPercent > (AnalogMeter1.LowZone - 0.5) then
      DialPercent := AnalogMeter1.LowZone - 0.5; //make sure its looks under
  end
  else //must be high
  begin
    //try to make overrange dial sensitivity at least 1/20th the sensitivity of underrange
    // (underange has 50% of dial, overrange has 25 to 45% of dial).
    if (rmdIngredientsMaxTol.AsFloat * 10) < fScaleMax then
      MaxDialWt := (rmdIngredientsMaxTol.AsFloat * 10) //limit dial to 10 times max weight
    else
      MaxDialWt := FScaleMax;
    if  CompareWts(MaxDialWt, ForWeight) > 0 then
      FractionOfOverRange := (ForWeight - rmdIngredientsMaxTol.AsFloat) /
                                   (MaxDialWt - rmdIngredientsMaxTol.AsFloat)
    else
      FractionOfOverRange := 1.0;
    DialPercent := AnalogMeter1.HighZone + (FractionOfOverRange * (100 - AnalogMeter1.HighZone));
    if DialPercent < (AnalogMeter1.HighZone + 0.5) then
      DialPercent := AnalogMeter1.HighZone + 0.5; //make sure it looks high
  end;
  Result := DialPercent;
end;

procedure TfrmFormixProcessRecipe.UpdateOrderMemTable;
begin
  SwitchOffScalePortEvent;
  try
    dsMemOrderHeader.DataSet.Edit;
    try
      frmFormixMain.RefreshColsInRmdOrderListWithOrdAndMixProgress(dmFormix.CurrentMixNo);
      dsMemOrderHeader.DataSet.Post;
  //    SetTotalMixValue(Trunc(AnalogMeter1.Value+fTareWt));
    except
      on E: Exception do
      begin
        dsMemOrderHeader.DataSet.Cancel;
        TermMessageDlg(E.Message,mtError,[mbOk],0);
      end;
    end;
  finally
    SwitchOnScalePortEvent;
  end;  
end;

procedure TfrmFormixProcessRecipe.tmTareFlasherTimer(Sender: TObject);
begin
 { if btTare.Color = clBtnFace then btTare.Color := clRed
                              else btTare.Color := clBtnFace;}
  if btTare.Caption = '' then
    btTare.Caption := rsSemiAutoTare
  else
    btTare.Caption := '';
end;

procedure TfrmFormixProcessRecipe.HidePartWeighDetails;
begin
  btPartWeigh.Visible := FALSE;
  lbRemainingWeight.Visible := FALSE;
end;

function TfrmFormixProcessRecipe.GetCurrentMixTotalPercentage: Integer;
begin
  Result := 0;
  try
    Result := Trunc(100* (dmFormix.GetTotalWtDoneOnMix(dmFormix.pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                          dmFormix.pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger,
                          dmFormix.CurrentMixNo
                         {dmFormix.pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger})/
                          dmFormix.CalcCompensatedBatchMixWt(dmFormix.CurrentMixNo{dmFormix.pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger})));
  except
    on E:Exception do
    begin
      TermMessageDlg(E.Message,mtError,[mbOk],0);
    end;
  end;
end;

procedure TfrmFormixProcessRecipe.CancelCurrentTare(ChangeMessage: Boolean = TRUE);
begin
  if fTareSet then
  begin
    fTareWt := 0.0;
    SetupTareButton;
    fTareSet := FALSE;
  end;
  if ChangeMessage then
    SetProcessStepTo(psTareReqd);
  //tmTareFlasher.Enabled := FALSE;
  //btPartWeigh.Visible := FALSE;
  //lbRemainingWeight.Visible := FALSE;
end;

procedure TfrmFormixProcessRecipe.SetTotalMixValue(ForValue: Integer);
begin
  plTotalMix.ParentBackground := FALSE;
  if Assigned(dsMemOrderHeader.DataSet) then
    plTotalMixValue.Width := Trunc(DivDouble((plTotalMix.Width * dsMemOrderHeader.DataSet.FieldByName('CurrentMixWtDone').AsFloat),
                                     dsMemOrderHeader.DataSet.FieldByName('CurrentMixWtReqd').AsFloat))
  else
    plTotalMixValue.Width := 0;
end;

procedure TfrmFormixProcessRecipe.SwitchOffScalePortEvent;
begin
  if fScaleSwitchOffCount = 0 then
  begin
    GetCurrentScaleObject.OnWeightCallBack :=nil;
    tmClockAndLineRefresh.Enabled := false;
  end;
  Inc(fScaleSwitchOffCount);
end;

procedure TfrmFormixProcessRecipe.SwitchOnScalePortEvent;
begin
  if fScaleSwitchOffCount > 0 then
    Dec(fScaleSwitchOffCount);
  if fScaleSwitchOffCount = 0 then
  begin
    GetCurrentScaleObject.OnWeightCallBack := UpdateFromScale;
    tmClockAndLineRefresh.Enabled := true;
  end;
end;

procedure TfrmFormixProcessRecipe.btbnLeftClick(Sender: TObject);
var i: Integer;
begin
  if (fLeftmostIngredient > 1) then
  begin
    for i := fIngredientCount-1 downto 0 do
    begin
      plIngredientList.Controls[i].Tag := plIngredientList.Controls[i].Tag + 1;
      plIngredientList.Controls[i].Left :=plIngredientList.Controls[i].Tag*ProductPanelWidth;
    end;
    Dec(fLeftmostIngredient);
  end
end;

procedure TfrmFormixProcessRecipe.btbtnRightClick(Sender: TObject);
var i: Integer;
begin
  if (fLeftmostIngredient < fIngredientCount) then
  begin
    for i := 0 to fIngredientCount-1 do
    begin
      plIngredientList.Controls[i].Tag := plIngredientList.Controls[i].Tag -1;
      plIngredientList.Controls[i].Left :=plIngredientList.Controls[i].Tag*ProductPanelWidth;
    end;
    Inc(fLeftmostIngredient);
  end;
end;

function TfrmFormixProcessRecipe.AnyIngredientAvailable: Boolean;
var i: Integer;
begin
  Result := FALSE;
  for i := 0 to plIngredientList.ControlCount-1 do
  begin
    if plIngredientList.Controls[i] is TPanel then
    begin
      if TPanel(plIngredientList.Controls[i]).Enabled then
      begin
        Result := TRUE;
        Break;
      end;
    end;
  end;
end;

function TfrmFormixProcessRecipe.IsCurrentIngredientComplete: Boolean;
var MixLRec: TMixLineRecord;
begin
  Result := FALSE;
  FillChar(MixLRec,SizeOf(MixLRec),#0);
  dmFormix.ConstructMixLineRecForOrdLine(dmFormix.CurrentMixNo{dmFormix.pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger},MixLRec);
  if dmFormix.IsThisLineCompleteForCurrMix(MixLRec.ML_WghsDone,MixLRec.ML_WtDone) then
  begin
    with MixLRec do
      TermMessageDlg('This Ingredient has been completed by another terminal.'+#10+
                   'MIX NO.: '+IntToStr(ML_MixNo)+#10+
                   'ORDER  : '+OrderNoToString(ML_OrderNo,ML_Revision)+#10+
                   'LINE NO: '+IntToStr(ML_LineNo)+#10+
                   'WT.DONE: '+DoubleToStr(ML_WtDone,1,4),
                     mtInformation,[mbOk],0);
    DeselectCurrentIngredient(TRUE);
    Result := TRUE;
  end;
end;

function TfrmFormixProcessRecipe.IsWeightInToleranceForScale(NetWt : double;
                                                             LowWtAdjustedForScale, HighWtAdjustedForScale : double) : boolean;
begin
  Result := (CompareWts(NetWt, LowWtAdjustedForScale) > -1)
        and (CompareWts(NetWt, HighWtAdjustedForScale) < 1);
end;

function TfrmFormixProcessRecipe.IsCurrentWeightOk(
  CheckWeight: Double; IsAPartWeigh: Boolean): Boolean;
var MixLRec : TMixLineRecord;
    WrkMix_Ingred_TotWt,
    WrkMix_Ingred_WtIncrements,
    LowestWt,
    HighestWt: Double;
    WrkMix_Ingred_Weighings,
    WrkMix_Ingred_WghsPerCont: Integer;
begin
  Result := FALSE;
  dmFormix.ConstructMixLineRecForOrdLine(dmFormix.CurrentMixNo,MixLRec);

  dmFormix.CalcIngredReqsForMixWt(dmFormix.CalcCompensatedBatchMixWt(dmFormix.CurrentMixNo),
                                  MixLRec,WrkMix_Ingred_TotWt,WrkMix_Ingred_Weighings,
                                  WrkMix_Ingred_WtIncrements,WrkMix_Ingred_WghsPerCont);
  dmFormix.CalcWOLineTolWts(WrkMix_Ingred_WtIncrements,
                            dmFormix.pvtblOrderHeader[OH_MixType],
                            WrkMix_Ingred_TotWt,
                            MixLRec.ML_WtDone,
                            LowestWt,
                            HighestWt);
  dmFormix.AdjustTolToScaleRes(LowestWt,HighestWt);
  if IsAPartWeigh then
  begin
   if CompareWts(CheckWeight, LowestWt) < 1 then
     Result := TRUE;
  end
  else
    Result := IsWeightInToleranceForScale(CheckWeight, LowestWt, HighestWt);

  if not Result then
  begin
    TermMessageDlg('Incorrect weight: '+DoubleToStr(CheckWeight,1,5), mtError,[mbOk],0);
    DeselectCurrentIngredient(TRUE);
  end;
end;

procedure TfrmFormixProcessRecipe.Button1Click(Sender: TObject);
begin
  SwitchOffScalePortEvent;
  try
    PreWeighingSetup(dmFormix.pvtblOrderLine, rmdIngredientsMinTol.AsFloat,
                     rmdIngredientsMaxTol.AsFloat);
    RefreshDisplayOfPreWghIngredSetup;
  finally
    SwitchOnScalePortEvent;
  end;
end;

procedure TfrmFormixProcessRecipe.FormClose(Sender: TObject;
var Action: TCloseAction);
begin
  dmFormix.CurrentMixNo := 0;
end;

(* Doesnt work because dmFormix.CurrentCompensatedBatchMixWt is being used with
   calling PreCalcCompensatedBatchMixWt.
   CurrentCompensatedBatchMixWt() should do recal automatically, or better still:
   when the CurrentMix gets changed so should CurrentCompensatedBatchMixWt.
procedure TfrmFormixProcessRecipe.RefreshOrderLines;
var
    MixLRec : TMixLineRecord;
    WrkMix_Ingred_TotWt,
    WrkMix_Ingred_WtIncrements,
    LowestWt,
    HighestWt: Double;
    WrkMix_Ingred_Weighings,
    WrkMix_Ingred_WghsPerCont,
    HoldOrderLine: Integer;
begin
  {Check the order lines havent changed}
  if fCurrentIngredientCode <> '' then Exit;
  HoldOrderLine := dmFormix.pvtblOrderLine.FieldByName(OL_LineNo).AsInteger;
  dmFormix.pvtblOrderLine.First;
  while not dmFormix.pvtblOrderLine.Eof do
  begin
    dmFormix.ConstructMixLineRecForOrdLine(dmFormix.GetCorrectMixNo{dmFormix.CurrentMixNo},MixLRec);
    rmdIngredients.Locate('ProductCode',dmFormix.pvtblOrderLine.FieldByName(OL_Ingredient).AsString,[]);
    dmFormix.CalcIngredReqsForMixWt(dmFormix.CurrentCompensatedBatchMixWt,
                                    MixLRec,WrkMix_Ingred_TotWt,WrkMix_Ingred_Weighings,
                                    WrkMix_Ingred_WtIncrements,WrkMix_Ingred_WghsPerCont);
    dmFormix.CalcWOLineTolWts(WrkMix_Ingred_WtIncrements,
                              dmFormix.pvtblOrderHeader[OH_MixType],
                              WrkMix_Ingred_TotWt,
                              MixLRec.ML_WtDone,
                              LowestWt,
                              HighestWt);
    dmFormix.AdjustTolToScaleRes(LowestWt,HighestWt);
    if (rmdIngredientsWtRemaining.AsFloat > 0) and
       (InRange(WrkMix_Ingred_WtIncrements,
                rmdIngredientsMinTol.AsFloat,
                rmdIngredientsMaxTol.AsFloat)) then
    begin
      fReBuildList := TRUE;
      Exit;
    end;
    dmFormix.pvtblOrderLine.Next;
  end;

  if HoldOrderLine <> -1 then
  begin
    dmFormix.pvtblOrderLine.First;
    while not dmFormix.pvtblOrderLine.Eof do
    begin
      if dmFormix.pvtblOrderLine.FieldByName(OL_LineNo).AsInteger = HoldOrderLine then
        Break
      else dmFormix.pvtblOrderLine.Next;
    end;
  end;
end;
*)
procedure TfrmFormixProcessRecipe.PossiblyIssueFopsTranRemainder(ActualWt: Double);
begin
  if  dmformix.SendFopsIssueTrans
  and Assigned(dmFops) then
  begin
    if  dmFormix.SourceBarcodeRelatesToAFopsTran
    and (not dmFormix.UseSourceWt) then
    begin
      {ask user if source container is empty if
       a) They used the partial weigh button
       b) Source container was less than 10% of its original weight (note:
          original weight is based on data in barcode)
       c) Weighing accounts for more than a third of the remaining weight
          that was left in stock (2 people could be working from same source).
      }
      if (dmFormix.CurrSourceWtKg < (dmFormix.OrigSourceWtKg/10)) or
         ((ActualWt * 3) > dmFormix.CurrSourceWtKg) then
      begin
        if TermMessageDlg('Is Source Container for'+#13#10+
                          fCurrentIngredientCode+' now empty?',
                          mtConfirmation,[mbYes,mbNo],0) = mrYes then
        begin
          dmFormix.SendCommandToFops(dmFormix.GetFops6TranStr(0.0,TRUE));
          {do we need to clear sourcebarcode ?}
          dmformix.ClearSourceItemDetails;
        end;
      end;
    end;
  end;
end;

procedure TfrmFormixProcessRecipe.FormKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
    WeightStr: String;

begin
  if lbScaleWt.Caption = '' then
  begin
    lbScaleWt.Caption := '0.00';
  end
  else
  begin
    case Key of
      VK_F4 : begin
                if Shift = [ssShift] then
                  WeightStr := FormatFloat(fScaleDisplayFormat,GetNetWeight-1+fTareWt)
                else
                  WeightStr := FormatFloat(fScaleDisplayFormat,
                                           GetNetWeight - fScaleIncrement + fTareWt);

              end;
      VK_F5 : begin
                if Shift = [ssShift] then
                  WeightStr := FormatFloat(fScaleDisplayFormat,GetNetWeight+1+fTareWt)
                else
                  WeightStr := FormatFloat(fScaleDisplayFormat,
                                           GetNetWeight+ fScaleIncrement + fTareWt);
              end;
{    VK_LEFT : lbScaleWt.Caption := FormatFloat('#0.00',StrToFloat(lbScaleWt.Caption)-
                                   dmFormix.GetRegRealDef(REG_Scale+TerminalName,REG_FxWtRoundMod,0.005));
    VK_RIGHT : lbScaleWt.Caption := FormatFloat('#0.00',StrToFloat(lbScaleWt.Caption)+
                                    dmFormix.GetRegRealDef(REG_Scale+TerminalName,REG_FxWtRoundMod,0.005));}

    end;

    if (Key in [VK_F4,VK_F5]) then
    begin
      UpdateFromScale(WeightStr);
    end;
  end;
end;


class procedure TfrmFormixProcessRecipe.ProcessRecipe(OrderDataSet: TDataSet;
                                                      MixNoOverride : integer);
{REQUIRES: 1. dmFormix.pvtblOrderHeader to be positioned on the relevant works order.
           2. MixNoOverride to be zero if the mix number selection is to be automatic.
}
begin
  frmFormixProcessRecipe := TfrmFormixProcessRecipe.Create(NIL);
  try
    try
     if  (not Assigned(dmFormix.QAClientSession))
     and (FormixIni.QAServiceURL <> '') then
       dmFormix.QAClientSession := TTerminalQAClientSession.Create(FormixIni.QAServiceURL);

     with frmFormixProcessRecipe do
     begin
      dmFormix.ClearIngredientsCache;
      dmFormix.pvtblMixTotal.CancelRange;
      if dmFormix.pvtblRecipeHeader.Locate(RH_RecipeCode, dmFormix.pvtblOrderHeader.FieldByName(OH_RecipeCode).AsString,[]) then
      begin
        dmFormix.pvtblRecipeLines.SetRange([dmFormix.pvtblRecipeHeader.FieldByName(RH_FileRef).AsInteger],
                                           [dmFormix.pvtblRecipeHeader.FieldByName(RH_FileRef).AsInteger]);

        dsMemOrderHeader.DataSet  := OrderDataSet;

        lbTime.Caption            := FormatDateTime('HH:NN:SS',Now);
        lbUser.Caption            := 'User: '+dmFormix.GetCurrentUser;
        RefreshBatchNoDisplay;
        if MixNoOverride < 1 then
          dmFormix.CurrentMixNo := dmFormix.pvtblOrderHeader.FieldByName(OH_CurrentMix).AsInteger
        else
          dmFormix.CurrentMixNo := MixNoOverride;
        //BuildProductList; let timer do this.
        UpdateOrderMemTable;//with CurrentMixNo
        dmFormix.CurrentBatch := '';
        dmFormix.CurrentIngredientLot := '';

        dmFormix.ClearWeighingDetails;
        dmFormix.dsOrderHeader.OnDataChange := dmFormix.dsOrderHeaderDataChange;
        try
          ShowModal
        finally
          dmFormix.dsOrderHeader.OnDataChange := nil;
        end;
      end
      else TermMessageDlg('Recipe not found',mtInformation,[mbOk],0);
     end;
    except
      on E: Exception do
        TermMessageDlg(E.Message,mtError,[mbOk],0);
    end;
  finally
    if Assigned(frmFormixProcessRecipe) then FreeAndNIL(frmFormixProcessRecipe);
    dmFormix.pvtblOrderLine.CancelRange;
    dmFormix.pvtblRecipeLines.CancelRange;
  end;
end;







procedure TfrmFormixProcessRecipe.DBEdit7Change(Sender: TObject);
begin
  SetTotalMixValue(0);
end;

procedure TfrmFormixProcessRecipe.dbcbxMixQADoneMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if not dbcbxMixQADone.Checked then
  begin
    dmFormix.RunQAChecksForMix;
    frmFormixMain.AddUpdateRecordToList(dmFormix.CurrentMixNo, true);
  end;
end;
(* this is prone to being ignored if calling process is extended with more user input
procedure TfrmFormixProcessRecipe.ClickMouse(X,Y: Integer);
Var Point : TPoint;
    SaveP : TPoint;
begin
  GetCursorPos(SaveP);
  Point.X := X;
  Point.Y := Y;
  Point := ClientToScreen(Point);
  SetCursorPos(Point.X,Point.Y);
  mouse_event(MOUSEEVENTF_LEFTDOWN,0,0,0,0);
  mouse_event(MOUSEEVENTF_LEFTUP,0,0,0,0);
  SetCursorPos(SaveP.X,SaveP.Y);
end;
*)
procedure TfrmFormixProcessRecipe.FormShow(Sender: TObject);
begin
  tmClockAndLineRefresh.Interval := 20;//fire after form is displayed.
  tmClockAndLineRefresh.Enabled := true;
end;

end.


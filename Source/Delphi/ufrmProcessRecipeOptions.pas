unit ufrmProcessRecipeOptions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RXCtrls, ExtCtrls, uTermDialogs,
  StdCtrls;

type
  TfrmProcessRecipeOptions = class(TForm)
    Panel1: TPanel;
    rxsbEnterManualTareWeight: TButton;
    rxsbEnterManualWeight: TButton;
    rxsbExit: TButton;
    rxsbPrintMixTicket: TButton;
    rxsbPrintAllMixTickets: TButton;
    rxsbDelayCurrentMix: TButton;
    rxsbAbortcurrentMix: TButton;
    rxsbEditBatchAndLot: TButton;
    rxsbViewTransactions: TButton;
    rxsbChangeScale: TButton;
    rxsbQA: TButton;
    procedure FormCreate(Sender: TObject);
    procedure rxsbEnterManualTareWeightClick(Sender: TObject);
    procedure rxsbEnterManualWeightClick(Sender: TObject);
    procedure rxsbPrintMixTicketClick(Sender: TObject);
    procedure rxsbPrintAllMixTicketsClick(Sender: TObject);
    procedure rxsbDelayCurrentMixClick(Sender: TObject);
    procedure rxsbAbortcurrentMixClick(Sender: TObject);
    procedure rxsbEditBatchAndLotClick(Sender: TObject);
    procedure rxsbViewTransactionsClick(Sender: TObject);
    procedure rxsbChangeScaleClick(Sender: TObject);
    procedure rxsbQAClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure setChangeScaleButtonText;
    { Private declarations }
  public
    { Public declarations }
    ManualWeight,
    ManualTareWeight: Double;
  end;

var
  frmProcessRecipeOptions: TfrmProcessRecipeOptions;

implementation
uses uSecurityConsts, uCustomHslSecurity, ufrmFormixStdEntry, udmFormix, ufrmViewMix, ufrmFormixProcessRecipe,
     ufrmFormixMain, ufrmViewTransactions, udmFormixBase, uIni;
{$R *.dfm}

procedure TfrmProcessRecipeOptions.FormCreate(Sender: TObject);
begin
 ManualWeight     := 0;
 ManualTareWeight := 0;
 setChangeScaleButtonText
end;

procedure TfrmProcessRecipeOptions.FormShow(Sender: TObject);
begin
  if (frmFormixProcessRecipe.fCurrentIngredientCode = '')
  or (not dmFormix.GetTermRegBoolean(r_AllowManualWeight)) then
  begin
    rxsbEnterManualTareWeight.Enabled := False;
    rxsbEnterManualWeight.Enabled     := False;
  end;
end;


procedure TfrmProcessRecipeOptions.rxsbEnterManualTareWeightClick(Sender: TObject);
var WrkStr: String;
    EnteredOk : boolean;
begin
 WrkStr := TfrmFormixStdEntry.GetFloatNumStr('Enter Manual Tare Weight','Tare Weight',7,5,
                                             EnteredOk,
                                             ManualTareWeight);
 if WrkStr <> '' then ManualTareWeight := StrToFloat(WrkStr);
end;

procedure TfrmProcessRecipeOptions.rxsbEnterManualWeightClick(
  Sender: TObject);
var WrkStr: String;
    EnteredOk : boolean;
    OpAllowed : boolean;
begin
 OpAllowed := true;
 if Assigned(dmFormix) and FormixIni.UseFopsUsers then
   OpAllowed := dmFormix.PromptForFopsUserThatHasRights(SECTOK_FX_MAN_WT ,[roCreate]) <> '';

 if OpAllowed then
 begin
   WrkStr := TfrmFormixStdEntry.GetFloatNumStr('Enter Manual Weight','Manual Weight',7,
                                             dmFormix.GetScaleDisplayDecimalPlaces(1),   //TODO: Current Scale DP?
                                             EnteredOk,
                                             ManualWeight);
   if WrkStr <> '' then ManualWeight := StrToFloat(WrkStr);
 end;
end;

procedure TfrmProcessRecipeOptions.rxsbPrintMixTicketClick(
  Sender: TObject);
begin
 dmFormix.PrintMixTicket(-1);
end;

procedure TfrmProcessRecipeOptions.rxsbPrintAllMixTicketsClick(
  Sender: TObject);
begin
 dmFormix.PrintAllMixTickets;
end;

procedure TfrmProcessRecipeOptions.rxsbDelayCurrentMixClick(Sender: TObject);
var WrkInt: Integer;
begin
 {Need to show form with current mixs}
 frmViewMix := TfrmViewMix.Create(Self);
 with frmViewMix do
 begin
   lbMixHeader.Caption := 'View Mixes For Order: '+dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsString;
   dsMixSource.DataSet := dmFormix.pvtblMixTotal;
   dmFormix.pvtblMixTotal.SetRange([dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                    dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger],
                                   [dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                    dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger]);
   try
     ShowModal;
     if ModalResult = mrOk then
     begin
       {Goto current selected mix no}
       if (TryStrToInt(edMixNo.Text,WrkInt)) and
          (StrToInt(edMixNo.Text) > 0) then
       begin
         if StrToInt(edMixNo.Text) <= dmFormix.pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger then
         begin
           dmFormix.pvtblOrderHeader.Database.StartTransaction;
           try
             dmFormix.pvtblOrderHeader.Edit;
             dmFormix.pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger := StrToInt(edMixNo.Text);
             dmFormix.pvtblOrderHeader.FindField(OH_Updates).AsInteger :=
                       dmFormix.pvtblOrderHeader.FindField(OH_Updates).AsInteger + 1;
             dmFormix.pvtblOrderHeader.Post;
             dmFormix.pvtblOrderHeader.Database.Commit;
             dmFormix.CurrentMixNo := dmFormix.pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger;
  {
             frmFormixMain.AddUpdateRecordToList;
             frmFormixProcessRecipe.fCurrentIngredientCode := '';
             frmFormixProcessRecipe.fFirstTime := TRUE;
             frmFormixProcessRecipe.BuildProductList;
  }
             frmFormixProcessRecipe.fMixChangedFromOptions := TRUE;
           except
             on E : exception do
             begin
               dmFormix.pvtblOrderHeader.Database.Rollback;
               TermMessageDlg('Try again.'+#13#10+E.Message,mtError,[mbOK],0);
               dmFormix.pvtblOrderHeader.Cancel;
             end;
           end;
         end
         else TermMessageDlg('Invalid Mix Number entered',mtError,[mbOk],0);
       end;
     end;
   finally
     dmformix.pvtblMixTotal.CancelRange;
   end;
   Free;
 end;
end;

procedure TfrmProcessRecipeOptions.rxsbAbortcurrentMixClick(
  Sender: TObject);
var HoldTIndex,
    HoldOLString: String;
    MixWasComplete : boolean;
begin
 {Need to abort the current mix}
 MixWasComplete := false;
 if GetTerminalPassword then
 begin
  dmFormix.pvtblTransactions.Database.StartTransaction;
  try
   dmFormix.pvtblOrderHeader.Edit;
   HoldTIndex := dmFormix.pvtblTransactions.IndexName;
   HoldOLString := dmFormix.pvtblOrderLine.IndexName;
   dmFormix.pvtblOrderLine.IndexName := 'ByOrderLine';
   dmFormix.pvtblTransactions.IndexName := 'ByOrderMixLine';
   dmFormix.pvtblTransactions.FindNearest([dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                           dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                                           dmFormix.CurrentMixNo]);
   while (not dmFormix.pvtblTransactions.Eof) and
         (dmFormix.pvtblTransactions.FindField(TRN_OrderNo).AsInteger =
          dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger) and
         (dmFormix.pvtblTransactions.FindField(TRN_OrderNoSuffix).AsInteger =
          dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger) and
         (dmFormix.pvtblTransactions.FindField(TRN_MixNo).AsInteger =
          dmFormix.CurrentMixNo) do
    begin
     if dmFormix.pvtblTransactions.Findfield(TRN_Status).AsInteger <> TRNStatusAborted then
      begin

        dmFormix.pvtblTransactions.Edit;
        dmFormix.pvtblTransactions.FindField(TRN_Status).AsInteger := TRNStatusAborted;
        dmFormix.pvtblTransactions.Post;
        dmFormix.pvtblOrderHeader.Edit;

        if dmFormix.pvtblOrderLine.Locate(OL_OrderNo+';'+OL_OrderNoSuffix+';'+OL_LineNo,
                    VarArrayOf([dmFormix.pvtblTransactions.FindField(TRN_OrderNo).AsInteger,
                                dmFormix.pvtblTransactions.FindField(TRN_OrderNoSuffix).AsInteger,
                                dmFormix.pvtblTransactions.FindField(TRN_OrderLineNo).AsInteger]),[]) then
         begin
          dmFormix.pvtblOrderLine.Edit;
          dmFormix.pvtblOrderLine.FindField(OL_TotalWeightDone).AsFloat :=
                   dmFormix.pvtblOrderLine.FindField(OL_TotalWeightDone).AsFloat -
                   dmFormix.pvtblTransactions.FindField(TRN_WeightInMix).AsFloat;
          if dmFormix.pvtblOrderLine.FindField(OL_TotalTransDone).AsInteger > 0 then
            dmFormix.pvtblOrderLine.FindField(OL_TotalTransDone).AsInteger :=
                     dmFormix.pvtblOrderLine.FindField(OL_TotalTransDone).AsInteger -1;
          dmFormix.pvtblOrderLine.Post;
         end;

        dmFormix.pvtblOrderHeader.FindField(OH_TotalWeightDone).AsFloat :=
           dmFormix.pvtblOrderHeader.FindField(OH_TotalWeightDone).AsFloat -
           dmFormix.pvtblTransactions.FindField(TRN_WeightInMix).AsFloat;
      end;
     dmFormix.pvtblTransactions.Next;
    end;

   if dmFormix.pvtblMixTotal.Locate(MIX_OrderNo+';'+MIX_OrderNoSuffix+';'+MIX_MixNo,
               VarArrayOf([dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                           dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                           dmFormix.CurrentMixNo]),[]) then
    begin
     MixWasComplete := dmFormix.pvtblMixTotal.FindField(MIX_Complete).AsBoolean;
     dmFormix.pvtblMixTotal.Edit;
     dmFormix.pvtblMixTotal.FindField(MIX_WeightDone).AsFloat := 0.0;
     dmFormix.pvtblMixTotal.FindField(MIX_Complete).AsBoolean := FALSE;
     dmFormix.pvtblMixTotal.Post;
    end;
   // update order header after mix to avoid deadlocks with MarkMixCompleteIfNecess()
   if  MixWasComplete
   and (dmFormix.pvtblOrderHeader.FindField(OH_MixesDone).AsInteger > 0) then
     dmFormix.pvtblOrderHeader.FindField(OH_MixesDone).AsInteger :=
              dmFormix.pvtblOrderHeader.FindField(OH_MixesDone).AsInteger - 1;

   if dmFormix.pvtblOrderHeader[OH_Status] = StatusComp then
     dmFormix.pvtblOrderHeader[OH_Status] := StatusWIP;
   dmFormix.pvtblOrderHeader.Post;

   dmFormix.pvtblTransactions.Database.Commit;
   TermMessageDlg('Mix Aborted',mtInformation,[mbOk],0);
   dmFormix.CurrentMixNo := dmFormix.pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger;
{
   frmFormixMain.AddUpdateRecordToList;
   frmFormixProcessRecipe.fCurrentIngredientCode := '';
   frmFormixProcessRecipe.fFirstTime := TRUE;
   frmFormixProcessRecipe.BuildProductList;
}   
   frmFormixProcessRecipe.fMixChangedFromOptions := TRUE;
  except
   on E:Exception do
   begin
      dmFormix.pvtblTransactions.Database.Rollback;
      TermMessageDlg('Mix Not Aborted, Error: '+#13#10+
                     E.Message,mtError,[mbOk],0);
      dmformix.pvtblTransactions.Cancel;
      dmformix.pvtblOrderLine.Cancel;
      dmformix.pvtblOrderHeader.Cancel;
      dmformix.pvtblMixTotal.Cancel;
     end;
   end;
   dmFormix.pvtblOrderLine.IndexName := HoldOLString;
   dmFormix.pvtblTransactions.IndexName := HoldTIndex;
  end;
end;

procedure TfrmProcessRecipeOptions.rxsbEditBatchAndLotClick(
  Sender: TObject);
begin
  if dmFormix.EditGlobalBatchAndLot then
  begin
    dmFormix.CurrentIngredientLot :=''; //force global lot to be used.
    dmFormix.CurrentBatch := ''; //force global batch number to be used.
    frmFormixProcessRecipe.edLotNo.Text := dmFormix.GetLotNumber;
    frmFormixProcessRecipe.RefreshBatchNoDisplay;
  end;
end;

procedure TfrmProcessRecipeOptions.rxsbViewTransactionsClick(
  Sender: TObject);
var frmViewTransactions : TfrmViewTransactions;
begin
  frmViewTransactions := TfrmViewTransactions.Create(Self);
  with frmViewTransactions do
  begin
    if frmFormixProcessRecipe.fCurrentIngredientCode <> '' then
      ShowTransForOrder(dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                        dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                        dmFormix.pvtblOrderLine.FindField(OL_LineNo).AsInteger)
    else
      ShowTransForOrder(dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                        dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                        0);
    ShowModal;
    Free;
  end;
end;


procedure TfrmProcessRecipeOptions.setChangeScaleButtonText;
const btnText ='Change to Scale ';
begin
  case dmFormix.CurrentScale of
    1: rxsbChangeScale.Caption := btnText+'2';
    2: rxsbChangeScale.Caption := btnText+'1';
    else rxsbChangeScale.Caption := btnText+'2';
  end;
end;

procedure TfrmProcessRecipeOptions.rxsbChangeScaleClick(Sender: TObject);
begin
  if dmFormix.CurrentScale = 1 then
    dmFormix.CurrentScale := 2
  else
    dmFormix.CurrentScale := 1;
  setChangeScaleButtonText;
end;

procedure TfrmProcessRecipeOptions.rxsbQAClick(Sender: TObject);
begin
  dmFormix.RunQAChecksForMix;
end;


end.

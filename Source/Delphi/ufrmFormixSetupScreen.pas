unit ufrmFormixSetupScreen;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RXCtrls, StdCtrls, ExtCtrls, uFopsLib, uTermDialogs, ustdutl;

type
  TfrmFormixSetupScreen = class(TForm)
    Panel1: TPanel;
    rxsbExit: TButton;
    RxSpeedButton1: TButton;
    RxSpeedButton2: TButton;
    RxSpeedButton3: TButton;
    RxSpeedButton4: TButton;
    rxsbEditBatchAndLot: TButton;
    rxsbPrinterOptions: TButton;
    rxsbSetup: TButton;
    rxsbChangePassword: TButton;
    rxsbScaleOptions: TButton;
    RxSpeedButton5: TButton;
    rxsbScale2Options: TButton;
    procedure rxsbChangePasswordClick(Sender: TObject);
    procedure rxsbScaleOptionsClick(Sender: TObject);
    procedure rxsbSetupClick(Sender: TObject);
    procedure rxsbPrinterOptionsClick(Sender: TObject);
    procedure rxsbEditBatchAndLotClick(Sender: TObject);
    procedure RxSpeedButton5Click(Sender: TObject);
    procedure rxsbScale2OptionsClick(Sender: TObject);
    procedure RxSpeedButton2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmFormixSetupScreen: TfrmFormixSetupScreen;

implementation
uses ufrmResetSecurityPassword, ComObj, udmFormixBase,udmFormix, ufrmFormixMain,
     ufrmScaleSetup, uComUtils, ufrmSetup, ufrmPrinterOptions,
     ufrmGlobalLotBatchEdit, ufrmScannerTest, ufrmTermRegSettings;
{$R *.dfm}

procedure TfrmFormixSetupScreen.rxsbChangePasswordClick(Sender: TObject);
begin
 {Need to let them change the password}
 frmResetSecurityPassword := TfrmResetSecurityPassword.Create(Self);
 with frmResetSecurityPassword do
  begin
   CurrentOldPassword := DeCrypt(dmFormix.GetTermRegString(r_Password));
   if CurrentOldPassword = '' then
    begin
     Label1.Enabled := FALSE;
     Label2.Enabled := TRUE;
     Label3.Enabled := TRUE;
     edPassword.Enabled := FALSE;
     edNewPassword.Enabled     := TRUE;
     edConfirmPassword.Enabled := TRUE;
    end;
   ShowModal;
   if ModalResult = mrOk then
    begin
     dmFormix.SetTermRegString(r_Password,EnCrypt(edNewPassword.Text));
     TermMessageDlg('Password Changed',mtInformation,[mbOk],0);
    end
   else TermMessageDlg('Password Not Changed',mtInformation,[mbOk],0);
   Free;
  end;
end;

procedure TfrmFormixSetupScreen.rxsbScaleOptionsClick(Sender: TObject);
//var WrkString: String;
begin
  TfrmScaleSetup.ConfigureScale(1,TerminalName);
(*
 {Show setup screen to allow setup of lucid/csw}
 frmScaleSetup := TfrmScaleSetup.Create(Self);
 with frmScaleSetup do
  begin
   WrkString := dmFormix.GetTermRegString(r_ScaleSetup,'');
   cbComPorts.Text    := GetComPortFromString(WrkString);
   cbBaudRate.Text    := GetBaudRateFromString(WrkString);
   cbDataBits.Text    := GetDataBitsFromString(WrkString);
   cbParity.Text      := GetParityFromString(WrkString);
   cbStopBits.Text    := GetStopBitsFromString(WrkString);
   cbFlowControl.Text := GetFlowControlFromString(WrkString);
   meMaxScaleWt.Text  := FormatFloat('000000.00',dmFormix.GetRegRealDef(r_ScaleMax,60.00));
   meScaleDP.Text    := IntToStr(dmFormix.GetScaleDisplayDecimalPlaces);
   meScaleIncrement.Text := FormatFloat('#0.00000', dmFormix.GetScaleIncrement);
   ShowModal;
   if ModalResult = mrOk then
    begin
     WrkString := cbComPorts.Text+','+
                  cbBaudRate.Text+','+
                  cbDatabits.Text+','+
                  cbParity.Text+','+
                  cbStopBits.Text+','+
                  cbFlowControl.Text;

     dmFormix.SetRegString(r_ScaleSetup,WrkString);
     dmFormix.SetRegReal(r_ScaleMax,StrToFloat(meMaxScaleWt.EditText));
     dmFormix.SetScaleDisplayDecimalPlaces(StrToInt(meScaleDP.EditText));
     dmFormix.SetScaleIncrement(StringToDouble(meScaleIncrement.EditText));
     TermMessageDlg('Scale Setup Changed',mtInformation,[mbOk],0);
    end
   else TermMessageDlg('Scale Setup Not Changed',mtInformation,[mbOk],0);
   Free;
  end;
*)
end;

procedure TfrmFormixSetupScreen.rxsbScale2OptionsClick(Sender: TObject);
begin
  TfrmScaleSetup.ConfigureScale(2,TerminalName);
end;

procedure TfrmFormixSetupScreen.rxsbSetupClick(Sender: TObject);
begin
 {Show setup screen}
 frmSetup := TfrmSetup.Create(Self);
 with frmSetup do
  begin
   Caption := 'Setup for Terminal '+TerminalName;
   {Setup Defaults}
   edMachineID.Text                 := dmFormix.GetTermRegString(r_MachineID);
   edRunNumber.Text                 := dmFormix.GetTermRegString(r_RunNumber);
   edPrepAreaFilter.Text            := dmFormix.GetTermRegString(r_PrepArea);
//   cbDisregardKeyIngredient.Checked := dmFormix.GetRegBooleanDef(r_DisregardKeyIngredient,FALSE);
//   cbUseLotNumbers.Checked          := dmFormix.GetRegBooleanDef(r_UseLotNumbers,FALSE);
   edWorkGroupFilter.Text           := dmFormix.GetTermRegString(r_WorkGroupFilter);
   cbAllowManualWeight.Checked      := dmFormix.GetTermRegBoolean(r_AllowManualWeight);
   cbEnquireForLotNumber.Checked    := dmFormix.GetTermRegBoolean(r_EnquireForLotNo);
   cbEnquireForBatchNumber.Checked  := dmFormix.GetTermRegBoolean(r_EnquireForBatchNo);
   cbSendIssueTransactions.Checked  := dmFormix.GetTermRegBoolean(r_SendFopsIssueTrans);
   edBatchPrefixForFops.Text        := dmFormix.GetTermRegString(r_BatchPrefixForFops);
   cbAddMixesToFopsStock.Checked    := dmFormix.GetTermRegBoolean(r_SFXAddMixToFopsStock);
   cbMixTicketsAnytime.Checked      := dmFormix.GetTermRegBoolean(r_MixTicketsAnytime);
   cbShowMixesDoneForArea.Checked   := dmFormix.GetTermRegBoolean(r_SFXShowMixesDoneForArea);
   cbUseOneScanOnly.Checked         := dmFormix.GetTermRegBoolean(r_SFXUseOneScanOnly);
   cbCopyFopsTranSrcAsLot.Checked   := dmFormix.GetTermRegBoolean(r_CopyFopsTranSourceAsLot);
   cbAllowProductOverride.Checked   := dmFormix.GetTermRegBoolean(r_SFXAllowProductOverride);
   cbAllowSixDigitBarcode.Checked   := dmFormix.GetTermRegBoolean(r_SFXAllowSixDigitBarCode);
   edAllowBarcodeLength.Text        := IntToStr(dmFormix.GetTermRegInteger(r_SFXAllowBarcodeLength));
   cbAllowKeyedBarcode.Checked      := dmFormix.GetTermRegBoolean(r_SFXAllowKeyedBarCode);
   cbScanMixAfterOrderSelect.Checked:= dmFormix.GetTermRegBoolean(r_SFXMixScanAtOrderSelect);
   ShowModal;
   if ModalResult = mrOk then
    begin
     dmFormix.SetTermRegString(r_MachineID,edMachineId.Text);
     dmFormix.SetTermRegString(r_RunNumber,edRunNumber.Text);
     dmFormix.SetTermRegString(r_PrepArea,edPrepAreaFilter.Text); 
     dmFormix.SetTermRegBoolean(r_EnquireForBatchNo,cbEnquireForBatchNumber.Checked);
     dmFormix.SetTermRegBoolean(r_EnquireForLotNo,cbEnquireForLotNumber.Checked);
//     dmFormix.SetTermRegBoolean(r_DisregardKeyIngredient,cbDisregardKeyIngredient.Checked);
//     dmFormix.SetTermRegBoolean(r_UseLotNumbers,cbUseLotNumbers.Checked);
     dmFormix.SetTermRegString(r_WorkGroupFilter,edWorkGroupFilter.Text);
     dmFormix.SetTermRegBoolean(r_AllowManualWeight,cbAllowManualWeight.Checked);
     dmFormix.SetTermRegBoolean(r_SendFopsIssueTrans,cbSendIssueTransactions.Checked);
     dmFormix.SetTermRegString(r_BatchPrefixForFops,edBatchPrefixForFops.Text);
     dmFormix.SetTermRegBoolean(r_SFXAddMixToFopsStock,cbAddMixesToFopsStock.Checked);
     dmFormix.SetTermRegBoolean(r_MixTicketsAnytime,cbMixTicketsAnytime.Checked);
     dmFormix.SetTermRegBoolean(r_SFXShowMixesDoneForArea, cbShowMixesDoneForArea.Checked);
     dmFormix.SetTermRegBoolean(r_SFXUseOneScanOnly,cbUseOneScanOnly.Checked);
     dmFormix.SetTermRegBoolean(r_CopyFopsTranSourceAsLot,cbCopyFopsTranSrcAsLot.Checked);
     dmFormix.SetTermRegBoolean(r_SFXAllowProductOverride,cbAllowProductOverride.Checked);
     dmFormix.SetTermRegBoolean(r_SFXAllowSixDigitBarCode,cbAllowSixDigitBarcode.Checked);
     dmFormix.SetTermRegInteger(r_SFXAllowBarcodeLength,StrToInt(edAllowBarcodeLength.Text));
     dmFormix.SetTermRegBoolean(r_SFXAllowKeyedBarcode,cbAllowKeyedBarcode.Checked);
     dmFormix.SetTermRegBoolean(r_SFXMixScanAtOrderSelect,cbScanMixAfterOrderSelect.Checked);
     TermMessageDlg('Setup Changes Saved',mtInformation,[mbOk],0);
     dmFormix.RefreshRegistryCache;
    end
   else TermMessageDlg('Setup Changes Not Saved',mtInformation,[mbOk],0);
   Free;
  end;
end;

procedure TfrmFormixSetupScreen.rxsbPrinterOptionsClick(Sender: TObject);
begin
 {Show the printer options screen}
 frmPrinterOptions := TfrmPrinterOptions.Create(Self);
 with frmPrinterOptions do
  begin
   ShowModal;
   Free;
  end;
end;

procedure TfrmFormixSetupScreen.rxsbEditBatchAndLotClick(Sender: TObject);
begin
  dmFormix.EditGlobalBatchAndLot;
end;

procedure TfrmFormixSetupScreen.RxSpeedButton5Click(Sender: TObject);
begin
 frmScannerTest := TfrmScannerTest.Create(Self);
 with frmScannerTest do
  begin
   ShowModal;
   Free;
  end;
end;

procedure TfrmFormixSetupScreen.RxSpeedButton2Click(Sender: TObject);
var
  Form: TfrmTermRegSettings;
begin
 Form := TfrmTermRegSettings.Create(Self);
 with Form do
  begin
   dmformix.AddDBValuesToRxmTermRegSettings;
   dmFormix.rxmTermRegSettings.First;
   ShowModal;
   Free;
   dmFormix.RefreshRegistryCache;
  end;
end;

end.

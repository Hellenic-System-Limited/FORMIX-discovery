unit ufrmScaleSetup;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Mask, ufrmFormixStdEntry, ComCtrls;

type
  TfrmScaleSetup = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    btOk: TButton;
    btCancel: TButton;
    PageControl1: TPageControl;
    tbsSerialSettings: TTabSheet;
    Label1: TLabel;
    cbComPorts: TComboBox;
    Label2: TLabel;
    cbBaudRate: TComboBox;
    Label5: TLabel;
    cbDataBits: TComboBox;
    Label3: TLabel;
    cbParity: TComboBox;
    Label4: TLabel;
    cbStopBits: TComboBox;
    Label6: TLabel;
    cbFlowControl: TComboBox;
    tbsIPSettings: TTabSheet;
    Panel3: TPanel;
    Label7: TLabel;
    meMaxScaleWt: TMaskEdit;
    Label8: TLabel;
    meScaleDP: TMaskEdit;
    Label9: TLabel;
    meScaleIncrement: TMaskEdit;
    Label10: TLabel;
    meIPAddress: TMaskEdit;
    rgScaleType: TRadioGroup;
    rgScaleModel: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure meMaxScaleWtClick(Sender: TObject);
    procedure meScaleDPClick(Sender: TObject);
    procedure meScaleIncrementClick(Sender: TObject);
    procedure rgScaleTypeClick(Sender: TObject);
    procedure meIPAddressClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    class procedure ConfigureScale(ScaleNo: Integer; ScaleName: String);
  end;


implementation

uses StrUtils,uStdUtl,uComUtils, udmFormix, uTermDialogs;

{$R *.dfm}

procedure TfrmScaleSetup.FormCreate(Sender: TObject);
var MyStrings: TStrings;
begin
 MyStrings := TStringList.Create;
 GetInstalledComPorts(MyStrings);
 cbComPorts.Items := MyStrings;
 MyStrings.Free;
end;

procedure TfrmScaleSetup.meMaxScaleWtClick(Sender: TObject);
var EnteredOk : boolean;
begin
 meMaxScaleWt.Text :=
   TfrmFormixStdEntry.GetFloatNumStr('Enter Maximum Scale Weight','Max. Scale Wt.',7,5,
                                     EnteredOk,
                                     StringToDouble(meMaxScaleWt.Text));
end;

procedure TfrmScaleSetup.meIPAddressClick(Sender: TObject);
var WrkString: String;
    EnteredOK: Boolean;
begin
  WrkString:=  TfrmFormixStdEntry.GetStdStringEntry('Enter IP Address and Port','IP Address:Port',25,EnteredOK);
  if EnteredOK then meIPAddress.Text := WrkString;
end;

procedure TfrmScaleSetup.meScaleDPClick(Sender: TObject);
begin
 meScaleDP.Text :=
   TfrmFormixStdEntry.GetStdNumericEntry('Enter Scale Decimal Places','Decimal Places',1);
end;

procedure TfrmScaleSetup.meScaleIncrementClick(Sender: TObject);
var EnteredOk : boolean;
begin
 meScaleIncrement.Text :=
   TfrmFormixStdEntry.GetFloatNumStr('Enter Smallest Scale Weight Increment','Scale Weight Increment',
                                     7,5,
                                     EnteredOk,
                                     StringToDouble(meScaleIncrement.Text));
end;


procedure TfrmScaleSetup.rgScaleTypeClick(Sender: TObject);
begin
  CASE rgScaleType.ItemIndex of
    0: begin
      PageControl1.ActivePage := tbsSerialSettings;
      tbsSerialSettings.TabVisible := true;
      tbsIPSettings.TabVisible := false;
    end;
    1: begin
      PageControl1.ActivePage := tbsIPSettings;
      tbsSerialSettings.TabVisible := false;
      tbsIPSettings.TabVisible := true;
    end;
    2: begin
      PageControl1.ActivePage := tbsSerialSettings;
      tbsSerialSettings.TabVisible := true;
      tbsIPSettings.TabVisible := false
    end;
  end;
end;


class procedure TfrmScaleSetup.ConfigureScale(ScaleNo: Integer; ScaleName : String);
var
  frmScaleSetup: TfrmScaleSetup;
  WrkString: String;
begin
 {Show setup screen to allow setup of lucid/csw}
 frmScaleSetup := TfrmScaleSetup.Create(NIL);

 with frmScaleSetup do
  begin
   Caption :='Setup Scale '+IntToStr(ScaleNo);
   rgScaleType.ItemIndex := dmFormix.GetScaleType(ScaleNo);
   rgScaleModel.ItemIndex := dmFormix.GetScaleModel(ScaleNo);
   rgScaleTypeClick(NIL);

   WrkString := dmFormix.GetScaleSerialConfig(ScaleNo);
   cbComPorts.Text    := GetComPortFromString(WrkString);
   cbBaudRate.Text    := GetBaudRateFromString(WrkString);
   cbDataBits.Text    := GetDataBitsFromString(WrkString);
   cbParity.Text      := GetParityFromString(WrkString);
   cbStopBits.Text    := GetStopBitsFromString(WrkString);
   cbFlowControl.Text := GetFlowControlFromString(WrkString);
   meMaxScaleWt.Text  := FormatFloat('000000.00',dmFormix.GetScaleMaxWeight(ScaleNo));

   meScaleDP.Text    := IntToStr(dmFormix.GetScaleDisplayDecimalPlaces(ScaleNo));
   meScaleIncrement.Text := FormatFloat('#0.00000', dmFormix.GetScaleIncrement(ScaleNo));

   meIPAddress.Text := dmFormix.GetScaleIPConfig(ScaleNo);

   ShowModal;
   if ModalResult = mrOk then
    begin
     WrkString := cbComPorts.Text+','+
                  cbBaudRate.Text+','+
                  cbDatabits.Text+','+
                  cbParity.Text+','+
                  cbStopBits.Text+','+
                  cbFlowControl.Text;

     dmFormix.SetScaleType(ScaleNo,rgScaleType.ItemIndex);
     dmFormix.SetScaleModel(ScaleNo,rgScaleModel.ItemIndex);
     dmFormix.SetScaleSerialConfig(ScaleNo,WrkString);
     dmFormix.SetScaleMaxWeight(ScaleNo,StrToFloat(meMaxScaleWt.EditText));
     dmFormix.SetScaleDisplayDecimalPlaces(ScaleNo,StrToInt(meScaleDP.EditText));
     dmFormix.SetScaleIncrement(ScaleNo,StringToDouble(meScaleIncrement.EditText));
     dmFormix.SetScaleIPConfig(ScaleNo,meIPAddress.Text);

     TermMessageDlg('Scale Setup Changed',mtInformation,[mbOk],0);
    end
   else TermMessageDlg('Scale Setup Not Changed',mtInformation,[mbOk],0);
  end;
  FreeAndNIL(frmScaleSetup);
end;


end.

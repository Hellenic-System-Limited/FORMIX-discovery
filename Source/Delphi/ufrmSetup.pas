unit ufrmSetup;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ufrmFormixStdEntry, StdCtrls, ExtCtrls;

type
  TfrmSetup = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    cbEnquireForLotNumber: TCheckBox;
    cbDisregardKeyIngredient: TCheckBox;
    cbUseLotNumbers: TCheckBox;
    cbAllowManualWeight: TCheckBox;
    edMachineID: TEdit;
    edRunNumber: TEdit;
    edWorkGroupFilter: TEdit;
    btOk: TButton;
    btCancel: TButton;
    cbEnquireForBatchNumber: TCheckBox;
    cbSendIssueTransactions: TCheckBox;
    cbUseOneScanOnly: TCheckBox;
    cbAllowProductOverride: TCheckBox;
    cbAllowSixDigitBarcode: TCheckBox;
    edAllowBarcodeLength: TEdit;
    Label4: TLabel;
    cbAllowKeyedBarcode: TCheckBox;
    cbAddMixesToFopsStock: TCheckBox;
    edBatchPrefixForFops: TEdit;
    Label5: TLabel;
    cbMixTicketsAnytime: TCheckBox;
    cbCopyFopsTranSrcAsLot: TCheckBox;
    cbScanMixAfterOrderSelect: TCheckBox;
    gbOrderSelection: TGroupBox;
    gbbatchLot: TGroupBox;
    gbFops: TGroupBox;
    Label6: TLabel;
    edPrepAreaFilter: TEdit;
    cbShowMixesDoneForArea: TCheckBox;
    procedure edMachineIDClick(Sender: TObject);
    procedure edRunNumberClick(Sender: TObject);
    procedure edWorkGroupFilterClick(Sender: TObject);
    procedure edAllowBarcodeLengthClick(Sender: TObject);
    procedure edBatchPrefixForFopsClick(Sender: TObject);
    procedure edPrepAreaFilterClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSetup: TfrmSetup;

implementation

{$R *.dfm}

procedure TfrmSetup.edMachineIDClick(Sender: TObject);
var TempInt : integer;
    WasEnteredOk : boolean;
begin
 TempInt := 0;
 TryStrToInt(edMachineId.Text, TempInt);
 edMachineId.Text := TfrmFormixStdEntry.GetIntegerNumStr('Machine ID.',
                                          'Enter Machine ID',2,WasEnteredOk,TempInt,false{AllowMinus});
end;

procedure TfrmSetup.edRunNumberClick(Sender: TObject);
var TempInt : integer;
    WasEnteredOk : boolean;
begin
 TempInt := 0;
 TryStrToInt(edRunNumber.Text, TempInt);
 edRunNumber.Text := TfrmFormixStdEntry.GetIntegerNumStr('Run Number',
                                          'Enter Run Number',6,WasEnteredOk,TempInt,false{AllowMinus});
end;

procedure TfrmSetup.edWorkGroupFilterClick(Sender: TObject);
var WrkBool: Boolean;
begin
 edWorkGroupFilter.Text := TfrmFormixStdEntry.GetStdStringEntry('Work Group Filter',
                                                     'Enter Work Group',3,WrkBool,
                                                     false{IsPassword},
                                                     edWorkGroupFilter.Text);
end;

procedure TfrmSetup.edAllowBarcodeLengthClick(Sender: TObject);
var TempInt : integer;
    WasEnteredOk : boolean;
begin
 TempInt := 0;
 TryStrToInt(edAllowBarcodeLength.Text, TempInt);
 edAllowBarcodeLength.Text := TfrmFormixStdEntry.GetIntegerNumStr('Allow Barcode Length',
                                                   'Enter Length',2,WasEnteredOk,TempInt,false{AllowMinus});
end;

procedure TfrmSetup.edBatchPrefixForFopsClick(Sender: TObject);
var TempInt : integer;
    WasEnteredOk : boolean;
begin
 TempInt := 0;
 TryStrToInt(edBatchPrefixForFops.Text, TempInt);
 edBatchPrefixForFops.Text := TfrmFormixStdEntry.GetIntegerNumStr('Batch Number Prefix for FOPS','Enter Prefix Number',2,
                                                                  WasEnteredOk, TempInt, false{AllowMinus});
end;

procedure TfrmSetup.edPrepAreaFilterClick(Sender: TObject);
var WrkBool: Boolean;
begin
 edPrepAreaFilter.Text := TfrmFormixStdEntry.GetStdStringEntry('Preparation Area(s)',
                                        'Enter Prep. Area filter',8,WrkBool,
                                        false{IsPassword},
                                        edPrepAreaFilter.Text);
end;

end.

unit ufrmPrinterSetup;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Mask, ExtCtrls;

type
  TfrmPrinterSetup = class(TForm)
    Panel1: TPanel;
    btOk: TButton;
    btCancel: TButton;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    cbComPorts: TComboBox;
    cbBaudRate: TComboBox;
    cbParity: TComboBox;
    cbStopBits: TComboBox;
    cbDataBits: TComboBox;
    cbFlowControl: TComboBox;
    GroupBox2: TGroupBox;
    Label7: TLabel;
    Label8: TLabel;
    meTicketsToPrint: TMaskEdit;
    cbPrintTransactionTicket: TCheckBox;
    cbCheckLabelTaken: TCheckBox;
    meNoOfMixTickets: TMaskEdit;
    edTranLabelFormat: TEdit;
    Label9: TLabel;
    edMixLabelFormat: TEdit;
    Label10: TLabel;
    procedure meTicketsToPrintClick(Sender: TObject);
    procedure meNoOfMixTicketsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edTranLabelFormatClick(Sender: TObject);
    procedure edMixLabelFormatClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPrinterSetup: TfrmPrinterSetup;

implementation
uses ufrmFormixStdEntry, uComUtils;

{$R *.dfm}

procedure TfrmPrinterSetup.meTicketsToPrintClick(Sender: TObject);
begin
 meTicketsToPrint.Text := TfrmFormixStdEntry.GetStdNumericEntry('Tickets To Print','Enter Number Of Tickets',1);
end;

procedure TfrmPrinterSetup.meNoOfMixTicketsClick(Sender: TObject);
begin
 meNoOfMixTickets.Text := TfrmFormixStdEntry.GetStdNumericEntry('Mix Tickets To Print','Enter Number Of Tickets',1);
end;

procedure TfrmPrinterSetup.FormCreate(Sender: TObject);
var MyStrings: TStrings;
begin
 MyStrings := TStringList.Create;
 GetInstalledComPorts(MyStrings);
 cbComPorts.Items := MyStrings;
 MyStrings.Free;
end;

procedure TfrmPrinterSetup.edTranLabelFormatClick(Sender: TObject);
var Change: Boolean;
    NewVal: String;
begin
  NewVal := TfrmFormixStdEntry.GetStdStringEntry('Transaction Label Format','Enter Format Letter',1,Change,FALSE,'',TRUE);
  if Change then edTranLabelFormat.Text := NewVal;
end;

procedure TfrmPrinterSetup.edMixLabelFormatClick(Sender: TObject);
var Change: Boolean;
    NewVal: String;
begin
  NewVal := TfrmFormixStdEntry.GetStdStringEntry('Mix Label Format','Enter Format Letter',1,Change,FALSE,'',TRUE);
  if Change then edMixLabelFormat.Text := NewVal;
end;

end.

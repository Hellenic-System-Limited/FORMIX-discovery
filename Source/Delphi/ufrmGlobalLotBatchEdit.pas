unit ufrmGlobalLotBatchEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfrmGlobalLotBatchEdit = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    edGlobalBatch: TEdit;
    edGlobalLot: TEdit;
    btOk: TButton;
    btCancel: TButton;
    procedure edGlobalBatchClick(Sender: TObject);
    procedure edGlobalLotClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmGlobalLotBatchEdit: TfrmGlobalLotBatchEdit;

implementation
uses ufrmFormixStdEntry;

{$R *.dfm}

procedure TfrmGlobalLotBatchEdit.edGlobalBatchClick(Sender: TObject);
var WrkBool: Boolean;
begin
 edGlobalBatch.Text := TfrmFormixStdEntry.GetStdStringEntry('Global Batch Number','Enter Batch Number',6,WrkBool);
end;

procedure TfrmGlobalLotBatchEdit.edGlobalLotClick(Sender: TObject);
var WrkBool: Boolean;
begin
 edGlobalLot.Text := TfrmFormixStdEntry.GetStdStringEntry('Global Lot Number','Enter Lot Number',14,WrkBool);
end;

end.

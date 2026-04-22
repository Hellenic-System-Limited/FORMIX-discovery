unit ufrmViewMix;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Grids, DBGrids, DB, udmFormix;

type
  TfrmViewMix = class(TForm)
    Panel1: TPanel;
    dsMixSource: TDataSource;
    DBGrid1: TDBGrid;
    Label1: TLabel;
    edMixNo: TEdit;
    Button1: TButton;
    Button2: TButton;
    lbMixHeader: TLabel;
    procedure edMixNoClick(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmViewMix: TfrmViewMix;

implementation
uses ufrmFormixStdEntry, uGridControl, udmFormixBase;
{$R *.dfm}

procedure TfrmViewMix.edMixNoClick(Sender: TObject);
begin
 edMixNo.Text := TfrmFormixStdEntry.GetStdNumericEntry('Enter Mix No.','Mix No.',3);
end;

procedure TfrmViewMix.DBGrid1CellClick(Column: TColumn);
begin
 edMixNo.Text := dmFormix.pvtblMixTotal.FindField(MIX_MixNo).AsString;
end;

procedure TfrmViewMix.FormShow(Sender: TObject);
var QAField : TField;
begin
  MoveGridFieldToColumnIndex(DBGrid1, MIX_MixNo, 0);
  MoveGridFieldToColumnIndex(DBGrid1, MIX_Complete, 1);
  MoveGridFieldToColumnIndex(DBGrid1, MIX_WeightRequired, 2);
  MoveGridFieldToColumnIndex(DBGrid1, MIX_WeightDone, 3);
  QAField := dmFormix.GetPvtblMixTotalFieldForPrepAreaQA;
  if QAField <> NIL then
    MoveGridFieldToColumnIndex(DBGrid1, QAField.FieldName, 4);
end;

end.

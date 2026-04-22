unit ufrmSelectFromPossibleProds;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, DB, Grids, DBGrids, StdCtrls, ExDBGrid, DBGridHSL;

type
  TfrmSelectFromPossibleProds = class(TForm)
    Panel1: TPanel;
    dsPossibleProducts: TDataSource;
    btnOk: TButton;
    btnCancel: TButton;
    DBGrid1: TDBGridHSL;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    class function SelectProduct : boolean;
  end;


implementation
uses udmFormix;
{$R *.dfm}

class function TfrmSelectFromPossibleProds.SelectProduct : boolean;
var
  Form : TfrmSelectFromPossibleProds;
begin
  Result := false;
  Form := TfrmSelectFromPossibleProds.Create(nil);
  try
    Result := Form.ShowModal = mrOk;
  finally
    FreeAndNil(Form);
  end;
end;
  
procedure TfrmSelectFromPossibleProds.FormCreate(Sender: TObject);
begin
  dsPossibleProducts.DataSet := dmFormix.rxmPossibleProducts;
end;

end.

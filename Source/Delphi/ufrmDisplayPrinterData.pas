unit ufrmDisplayPrinterData;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfrmDisplayPrinterData = class(TForm)
    btnExit: TButton;
    memo1: TMemo;
    procedure btnExitClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;


implementation

{$R *.dfm}

procedure TfrmDisplayPrinterData.btnExitClick(Sender: TObject);
begin
  Close;
end;

end.

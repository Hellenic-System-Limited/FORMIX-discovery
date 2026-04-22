unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RXCtrls, ExtCtrls;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    rxsbExit: TRxSpeedButton;
    rxsbDownloadLabelFile: TRxSpeedButton;
    rxsbPrinterOptions: TRxSpeedButton;
    rxsbEditPrinterConfig: TRxSpeedButton;
    rxsbDownloadPrinterConfig: TRxSpeedButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

end.

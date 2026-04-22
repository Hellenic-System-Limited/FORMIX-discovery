unit ufrmIniVal;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfrmIniVal = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    edIniName: TEdit;
    Label2: TLabel;
    edIniValue: TEdit;
    Button1: TButton;
    Button2: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmIniVal: TfrmIniVal;

implementation

{$R *.dfm}

end.

unit ufrmRinstrunSimulator;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CPort, CPortCtl, Spin, ComCtrls, JvExControls,
  JvxSlider, ExtCtrls,StrUtils, JvgDigits;

type
  TForm1 = class(TForm)
    rPort: TComPort;
    GroupBox1: TGroupBox;
    edPort: TEdit;
    btnStart: TButton;
    Label4: TLabel;
    Timer1: TTimer;
    WtSlider: TJvxSlider;
    btnStop: TButton;
    lblWt: TLabel;
    rgScaleType: TRadioGroup;
    procedure btnStartClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }

  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}


procedure TForm1.btnStartClick(Sender: TObject);
begin
  rPort.Port := edPort.Text;
  rPort.Open;
  Timer1.Enabled := True;
end;

procedure TForm1.btnStopClick(Sender: TObject);
begin
  Timer1.Enabled := False;
  lblWt.Caption :='';
end;



procedure TForm1.Timer1Timer(Sender: TObject);
var Packet,WtString,S1: String;
begin

  if rgScaleType.ItemIndex=0 then
  begin
    S1 :='G';
    if (WtSlider.Value > 6000) then S1 :='O';
    if (WtSlider.Value < 0) then S1 := 'U';
    WtString := FormatFloat('0000.00',ABS(WtSlider.Value / 100));
    lblWt.Caption := WtString;
    Packet := #02+
              IfThen((WtSlider.Value < 0),'-',' ')+
              WtString+
              S1+
              '^'+
              IfThen((WtSlider.Value=0),'Z','^')+
              '-'+
              '^kg'+
              #03;
  end
  else if rgScaleType.ItemIndex=1 then
  begin
    S1 :='S';
    if (WtSlider.Value > 6000) then S1 :='+';
    if (WtSlider.Value < 0) then S1 := '-';
    WtString := FormatFloat('0000.00',ABS(WtSlider.Value / 100));
    lblWt.Caption := WtString;
    Packet := 'V '+S1+' N'+'  '+WtString+' kg T      0.0 kg'+#13+#10;
  end;
  rPort.WriteStr(Packet);
end;


end.

unit ufrmQAProgress;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfrmQAProgress = class(TForm)
    txtQAMode: TStaticText;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    QAResult : boolean;
  public
    { Public declarations }
    class function RunQAChecks : boolean;
  end;

implementation
{$R *.dfm}
uses udmFormixBase, udmFormix, uTermDialogs;

class function TfrmQAProgress.RunQAChecks : boolean;
var
  frmQAProgress: TfrmQAProgress;

begin
  Result := false;
  if not Assigned(dmFormix.QAClientSession) then
  begin
    TermMessageDlg('Session with QA service was not established.',mtInformation,[mbOK],0);
    EXIT;
  end;
  
  frmQAProgress := TfrmQAProgress.Create(NIL);
  try
    frmQAProgress.Show;
    frmQAProgress.Close;
    Result := frmQAProgress.QAResult;
  finally
    if Assigned(frmQAProgress) then FreeAndNIL(frmQAProgress);
  end;
end;

procedure TfrmQAProgress.FormCreate(Sender: TObject);
begin
  txtQAMode.Caption := dmFormix.GetQAModeForPrepArea;
end;

procedure TfrmQAProgress.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  with dmFormix do
  begin
    QAClientSession.InitQAForARecipeMix(pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
                                        CurrentMixNo,
                                        pvtblOrderHeader.FieldByName(OH_RecipeCode).AsString,
                                        ''{Barcode}, txtQAMode.Caption);
    QAResult := QAClientSession.Execute;
  end;
{  pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger,
  dmFormix.CurrentMixNo
}
end;

end.

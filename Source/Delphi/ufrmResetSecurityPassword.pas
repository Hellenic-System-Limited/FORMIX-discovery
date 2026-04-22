unit ufrmResetSecurityPassword;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, HSLAZKeyboard;

type
  TfrmResetSecurityPassword = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    edPassword: TEdit;
    OkButton: TButton;
    CancelButton: TButton;
    Label2: TLabel;
    Label3: TLabel;
    edNewPassword: TEdit;
    edConfirmPassword: TEdit;
    HSLAZKeyboard1: THSLAZKeyboard;
    HSLNumericKeyboard1: THSLNumericKeyboard;
    procedure edPasswordKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edPasswordChange(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    CurrentOldPassword: String;
  end;

var
  frmResetSecurityPassword: TfrmResetSecurityPassword;

implementation

{$R *.dfm}

procedure TfrmResetSecurityPassword.edPasswordKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
 if Key = VK_RETURN then OkButton.Click;
end;

procedure TfrmResetSecurityPassword.edPasswordChange(Sender: TObject);
begin
 if SameText(CurrentOldPassword,edPassword.Text) then
  begin
   Label2.Enabled := TRUE;
   Label3.Enabled := TRUE;
   edNewPassword.Enabled     := TRUE;
   edConfirmPassword.Enabled := TRUE;
  end
 else
  begin
   Label2.Enabled := FALSE;
   Label3.Enabled := FALSE;
   edNewPassword.Enabled     := FALSE;
   edConfirmPassword.Enabled := FALSE;
  end;
end;

procedure TfrmResetSecurityPassword.OkButtonClick(Sender: TObject);
begin
 if SameText(CurrentOldPassword,edPassword.Text) and
    SameText(edNewPassword.Text,edConfirmPassword.Text) then
   ModalResult := mrOk
 else
  begin
   if CurrentOldPassword <> '' then
    begin
     if not SameText(CurrentOldPassword,edPassword.Text) then
       MessageDlg('Master Password Not Changed'+#13#10+'Invalid Old Password',mtError,[mbOk],0);
    end;
   if not SameText(edNewPassword.Text,edConfirmPassword.Text) then
     MessageDlg('Master Password Not Changed'+#13#10+'New Passwords Do Not Match',mtError,[mbOk],0);
   ModalResult := mrCancel;
  end;
end;

end.

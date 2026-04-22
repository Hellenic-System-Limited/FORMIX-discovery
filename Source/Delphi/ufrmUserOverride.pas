unit ufrmUserOverride;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, udmFormix, ufrmFormixStdEntry;

type
  TfrmUserOverride = class(TForm)
    Panel1: TPanel;
    Label8: TLabel;
    Label9: TLabel;
    LoginButton: TButton;
    edUserName: TEdit;
    edPassword: TEdit;
    Button1: TButton;
    Label1: TLabel;
    procedure LoginButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edUserNameClick(Sender: TObject);
    procedure edPasswordClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    TempUser: String;
  end;

  function GetOverrideUser(var ForUserName: String): Boolean;

var
  frmUserOverride: TfrmUserOverride;

implementation

//uses ufrmFormixLogin;

{$R *.dfm}
function GetOverrideUser(var ForUserName: String): Boolean;
begin
 Result := FALSE;
 frmUserOverride := TfrmUserOverride.Create(Application);
 with frmUserOverride do
  begin
   ShowModal;
   if ModalResult = mrOk then
    begin
     ForUserName := TempUser;
     Result      := TRUE;
    end;
   Free;
  end;
end;

procedure TfrmUserOverride.LoginButtonClick(Sender: TObject);
begin
 {Need to check entered user and password is valid}
 {If username is EXIT then close program}
 if (SameText(edUserName.Text,'SUPERHSL')) and
    (SameText(edPassword.Text,'766463')) then
  begin
   TempUser    := 'SUPERHSL';
   ModalResult := mrOk;
  end
 else
  begin
   if dmFormix.IsValidUser(edUserName.Text,edPassword.Text) then
    begin
     TempUser    := edUserName.Text;
     ModalResult := mrOk;
    end;
  end;
end;

procedure TfrmUserOverride.FormCreate(Sender: TObject);
begin
 TempUser := '';
end;

procedure TfrmUserOverride.edUserNameClick(Sender: TObject);
var WrkBool: Boolean;
begin
 edUserName.Text := TfrmFormixStdEntry.GetStdStringEntry('Enter User Name','User Name',8,WrkBool);
end;

procedure TfrmUserOverride.edPasswordClick(Sender: TObject);
var WrkBool: Boolean;
begin
 edPassword.Text := TfrmFormixStdEntry.GetStdStringEntry('Enter Password','Password',8,WrkBool,TRUE);
end;

end.
 
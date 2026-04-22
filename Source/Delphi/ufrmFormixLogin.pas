unit ufrmFormixLogin;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Registry, JvAppInst;

type
  TfrmFormixLogin = class(TForm)
    Panel1: TPanel;
    Shape1: TShape;
    Image2: TImage;
    Label3: TLabel;
    Label4: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LoginButton: TButton;
    edUserName: TEdit;
    edPassword: TEdit;
    Button1: TButton;
    Label10: TLabel;
    lblServerAndDatabaseName: TLabel;
    procedure edUserNameClick(Sender: TObject);
    procedure edPasswordClick(Sender: TObject);
    procedure LoginButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    procedure SetupLoginScreen;
  public
    { Public declarations }
//    AttemptCount: Integer;
    class procedure PromptUserToLogin;
  end;


implementation
uses uModCtv, ufrmFormixStdEntry, uTermDialogs, udmFormix,
  udmCustomDataModule;
{$R *.dfm}
var
  frmFormixLogin: TfrmFormixLogin;


{ TForm2 }
class procedure TfrmFormixLogin.PromptUserToLogin;
begin
  if frmFormixLogin = nil then
    frmFormixLogin := TfrmFormixLogin.Create(Application)
  else if frmFormixLogin.Visible then
    EXIT;
   {****}
  frmFormixLogin.ShowModal;
end;

procedure TfrmFormixLogin.SetupLoginScreen;
var CurrInfo : _OSVersionInfo;
    MS       : TMemoryStatus;
    Registry : TRegistry;
    Result   : String;
    RegTo    : String;
    i, j     : Integer;
    WrkStr   : String;
begin
 CurrInfo.dwOSVersionInfoSize := SizeOf(CurrInfo);
 GetVersionEx(CurrInfo);
 MS.dwLength := SizeOf(TMemoryStatus);
 GlobalMemoryStatus(MS);
 RegTo := '';
 Label2.Caption := Result + ' ('+IntToStr(LoWord(CurrInfo.dwMajorVersion))+'.'+
                   IntToStr(LoWord(CurrInfo.dwMinorVersion))+'.'+
                   IntToStr(LoWord(CurrInfo.dwBuildNumber))+')';
 Label5.Caption := 'Memory Available To Windows    '+
                   FormatFloat('#,###" KB"',MS.dwTotalPhys div 1024);
 Label7.Caption := '';
 Label3.Caption := 'Copyright @ 1990 - '+
                   FormatDateTime('yyyy',Now)+
                   ' Hellenic Systems Limited. All rights reserved.';
 try
 {Need to read registry to get version name}
   Registry := TRegistry.Create;
   Registry.RootKey:=HKEY_LOCAL_MACHINE;

   Registry.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion');
   IF Registry.ValueExists('ProductName') THEN
    BEGIN
     Result := Registry.ReadString('ProductName');
     WrkStr := ParamStr(0);
     IF Length(WrkStr) >= 72 THEN
      BEGIN
       {Caption will go off edge of splashscreen}
       j := 0;
       FOR i := 1 TO Length(WrkStr) DO
        IF WrkStr[i] = '\' THEN j := i;
        Label6.Caption := Copy(WrkStr,1,3) + '..' +
                          Copy(WrkStr,j,(Length(WrkStr)-j+1));
      END
     ELSE Label6.Caption := WrkStr;
    END
   ELSE
    BEGIN
     Registry.CloseKey;
     Registry.OpenKeyReadOnly('Software\Microsoft\Windows NT\CurrentVersion');
     Label6.Caption := Registry.ReadString('ProductName');
    END;
   Registry.CloseKey;
   Registry.RootKey:=HKEY_LOCAL_MACHINE;
   Registry.OpenKeyReadOnly('Network\Logon');
   if Registry.ValueExists('UserName') then
     edUserName.Text := Registry.ReadString('UserName')
   else
    begin
     Registry.RootKey:=HKEY_LOCAL_MACHINE;
     Registry.OpenKeyReadOnly('Software\Microsoft\Windows NT\CurrentVersion\WinLogon');
     if Registry.ValueExists('DefaultUserName') then
       edUserName.Text := Registry.ReadString('DefaultUserName');
    end;
   Registry.CloseKey;
   Registry.Free;
 except
  begin
   Label6.Visible := FALSE;
  end;
 end;
end;

procedure TfrmFormixLogin.edUserNameClick(Sender: TObject);
var WrkBool: Boolean;
begin
 edUserName.Text := TfrmFormixStdEntry.GetStdStringEntry('Enter User Name','User Name',8,WrkBool);
end;

procedure TfrmFormixLogin.edPasswordClick(Sender: TObject);
var WrkBool: Boolean;
begin
 edPassword.Text := TfrmFormixStdEntry.GetStdStringEntry('Enter Password','Password',8,WrkBool,TRUE);
end;

procedure TfrmFormixLogin.LoginButtonClick(Sender: TObject);
{REQUIRES: dmFormix to have been created and connected.
}
begin
 {Need to check entered user and password is valid}
 {If username is EXIT then close program}
 if (SameText(edUserName.Text,'Exit')) and
    (SameText(edPassword.Text,'364667')) then
   Application.Terminate
 else
  begin
//   Dec(AttemptCount);
   if dmFormix.IsValidUser(edUserName.Text,edPassword.Text) then
    begin
     dmFormix.SetCurrentUser(edUserName.Text);
     ModalResult := mrOk;
    end;
{
   if AttemptCount = 0 then
    begin
     TermMessageDlg('Invalid User Name && Password Entered Three Times'+#13#10+
                    'Program Will Now Exit',mtError,[mbOk],0);
     //ModalResult := mrCancel;
     Application.Terminate;
    end;
}    
  end;
end;

procedure TfrmFormixLogin.FormCreate(Sender: TObject);
begin
 if (FormStyle = fsStayOnTop) and (not dmFormix.fProgramStaysOnTop) then
   FormStyle   := fsNormal;
// AttemptCount := 3;
 SetupLoginScreen;
end;

procedure TfrmFormixLogin.FormShow(Sender: TObject);
begin
  edUserName.Text := '';
  edPassword.Text := '';
  if not assigned(dmFormix) then
    LoginButton.Enabled := false
  else
  begin
    Label1.Caption := 'Formix Terminal  Version '+ApplicationFileInfo.GetFileVersion;
    lblServerAndDatabaseName.Caption := dmFormix.DatabaseDetails.ServerName+
                                        '  '+dmFormix.DatabaseDetails.DatabaseName;
    edUserName.Text := dmFormix.GetCurrentUser;
  end;
end;

procedure TfrmFormixLogin.FormDestroy(Sender: TObject);
begin
//  AttemptCount := 1;//debug point to check form is being destroyed.
end;

end.

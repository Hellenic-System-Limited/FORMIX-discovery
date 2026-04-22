unit uIni;

interface

Type
     TFormixIni = class(TObject)
        function DatabaseName: String;
        function ServerName: String;
        function FopsDatabaseName: String;
        function FopsServerName: String;
        function UseFopsUsers : boolean;
        function QAServiceURL: string;
     end;

(*

uses SysUtils, IniFiles{, IniUtils, uEnvironmentalVariables,}, Dialogs, Math;

const StdMainMenuIni = '.\MainMenu.ini';
      StdFops6Ini    = '.\Fops6.ini';

      TrueCharacters  = ['y','Y','t','T','1'];
      FalseCharacters = ['n','N','f','F','0'];

Type  TAccountsPackage = (apNone,apSageLine50,apSageLine100);

      TIniStringVar = record
        Key: string;     // Key Name
        Sec: string;     // Section Name
        Def: string;     // Default Name
      end;
      TIniBoolVar = record
        Key: string;     // Key Name
        Sec: string;     // Section Name
        Def: Boolean;    // Default Value
      end;
      TIniIntVar = record
        Key: string;     // Key Name
        Sec: string;     // Section Name
        Low: Integer;    // Lower Value  //to have no upper or lower - set both to 0
        Upp: Integer;    // Upper Value
        Def: Integer;    // Default Value
      end;
      TIniCharVar = record
        Key: string;     // Key Name
        Sec: string;     // Section Name
        Def: Char;       // Default Name
        Cap: Boolean;    // Capitalize Char on get by default
      end;
      TIniAccountsPackageVar = record
        Key: string;              // Key Name
        Sec: string;              // Section Name
        Def: TAccountsPackage;    // Default Value
      end;
      TIniDoubleVar = record
        Key: string;     // Key Name
        Sec: string;     // Section Name
        Low: Double;    // Lower Value  //to have no upper or lower - set both to 0
        Upp: Double;    // Upper Value
        Def: Double;    // Default Value
      end;

const PackageAsString: array[TAccountsPackage] of string = ('','SageLine50','SageLine100');
      SagePackages = [apSageLine50,apSageLine100];

//INI FILE CONSTANTS ADD AS NEEDED//////////////////////////////////////////////

      S_MAIN      = 'Main';
      s_DATABASE  = 'Database';
      S_EDI       = 'EDI';
      S_SAGE      = 'SAGE';
      S_INVOICE   = 'INVOICE';
      S_GRN       = 'GRN';
      S_EMAIL     = 'EMAIL';
      S_SETTINGS  = 'SETTINGS';
      S_PRINTERS  = 'PRINTERS';
      S_DOCUMENTS = 'DOCUMENTS';
      S_REPORTS   = 'REPORTS';


      // DATABASE
      K_DatabaseName:      TIniStringVar = (Key:'DatabaseName';                Sec:S_DATABASE;    Def:'FORMIX');
      K_ServerName:        TIniStringVar = (Key:'ServerName';                  Sec:S_DATABASE;    Def:'');
      K_ServerUser:        TIniStringVar = (Key:'ServerUser';                  Sec:S_DATABASE;    Def:'');
      K_ServerPassword:    TIniStringVar = (Key:'ServerPassword';              Sec:S_DATABASE;    Def:'');
      K_FopsDatabaseName:  TIniStringVar = (Key:'FopsDatabaseName';            Sec:S_DATABASE;Def:'FOPS');
      K_FopsServerName:    TIniStringVar = (Key:'FopsServerName';              Sec:S_DATABASE;Def:'');
      K_QAServiceURL:      TIniStringVar = (Key:'QAServiceURL';                Sec:S_DATABASE;    Def:'');



Type  TFormixIni = class(TObject)
      private
     //   MainIni  : TMemIniFile;
        HasMainIni  : Boolean;
     //   HasFops6Ini : Boolean;
     //   HasUserIni  : Boolean;

        MainIni  : TMemIniFile;
        Fops6Ini : TMemIniFile;
        UserIni  : TMemIniFile;
    FFopsServerName: String;
    FFopsDatabaseName: String;

        function GetStringFromIniVar(Inivar: TIniStringVar): String;


        function GetDatabaseName: String;
        function GetServerName: String;
        function GetServerPassword: String;
        function GetServerUser: String;
        function GetFopsDatabaseName: String;
        function GetFopsServerName: String;

    procedure SetFopsDatabaseName(const Value: String);
    procedure SetFopsServerName(const Value: String);

      public
        constructor Create;
        //function SetupUserIniFile(UserIniPath: String): Boolean;
        //function SetupFops6IniFile(F6IniPath: String): Boolean;
        function SetUpMainIniFile(MainIniPath: String): Boolean;

        // DATABASE
        property DatabaseName: String read GetDatabaseName;
        property ServerName: String read GetServerName;
        property ServerUser: String read GetServerUser;
        property ServerPassword: String read GetServerPassword;
        property FopsDatabaseName: String read GetFopsDatabaseName;
        property FopsServerName: String read GetFopsServerName;
        function QAServiceURL: string;

      published

      end;
*)
var
  FormixIni: TFormixIni = nil;  //global fops ini instance

implementation
uses uIniUtils, IniFiles;
const
     S_MAIN      = 'Main';
     s_DATABASE  = 'Database';

     IVFopsServerName   = 'FopsServerName';
     IVFopsDatabaseName = 'FopsDatabaseName';
     IVUseFopsUsers     = 'UseFopsUsers';
     IVQAServiceURL     = 'QAServiceURL';

(*
{ TFormixIni }

constructor TFormixIni.Create;
begin
  Inherited;
  HasMainIni := FALSE;
//  HasFops6Ini := FALSE;
//  HasUserIni := FALSE;
end;




function TFormixIni.GetStringFromIniVar(Inivar: TIniStringVar): String;
begin
{
  if HasUserIni then
   begin
    if UserIni.ValueExists(IniVar.Sec,IniVar.Key) then
     begin
      Result := UserIni.ReadString(IniVar.Sec,IniVar.Key,IniVar.Def);
     end
    else
     begin
      if HasFops6Ini then
       begin
        if Fops6Ini.ValueExists(IniVar.Sec,IniVar.Key) then
         begin
          Result := Fops6Ini.ReadString(IniVar.Sec,IniVar.Key,IniVar.Def);
         end
        else Result := IniVar.Def;
       end
      else Result := IniVar.Def;
     end;
   end
  else
   begin
    if HasFops6Ini then
     begin
      if Fops6Ini.ValueExists(IniVar.Sec,IniVar.Key) then
       begin
        Result := Fops6Ini.ReadString(IniVar.Sec,IniVar.Key,IniVar.Def);
       end
      else
       begin
        if HasMainIni then
         begin
          if MainIni.ValueExists(IniVar.Sec,IniVar.Key) then
           begin
            Result := MainIni.ReadString(IniVar.Sec,IniVar.Key,IniVar.Def);
           end
          else Result := IniVar.Def;
         end
        else Result := IniVar.Def;
       end;
     end
    else
     begin
}
      if HasMainIni then
       begin
        if MainIni.ValueExists(IniVar.Sec,IniVar.Key) then
         begin
          Result := MainIni.ReadString(IniVar.Sec,IniVar.Key,IniVar.Def);
         end
        else Result := IniVar.Def;
       end
      else Result := IniVar.Def;
{
     end;
   end;
}
end;

function TFormixIni.SetUpMainIniFile(MainIniPath: String): Boolean;
begin
  if FileExists(MainIniPath) then
   begin
    MainIni := TMemIniFile.Create(MainIniPath);
    Result := TRUE;
   end
  else
   begin
    if (not SameText(MainIniPath,StdMainMenuIni)) and (FileExists(StdMainMenuIni)) then
     begin
      MainIni := TMemIniFile.Create(StdMainMenuIni);
      Result := TRUE;
     end
    else Result := FALSE;
   end;
  HasMainIni := Result;
end;
{
function TFormixIni.SetupFops6IniFile(F6IniPath: String): Boolean;
begin
  if FileExists(F6IniPath) then
   begin
    Fops6Ini := TMemIniFile.Create(F6IniPath);
    Result := TRUE;
   end
  else
   begin
    Result := FALSE;
   end;
  HasFops6Ini := Result;
end;

function TFormixIni.SetupUserIniFile(UserIniPath: String): Boolean;
begin
  if FileExists(UserIniPath) then
   begin
    UserIni := TMemIniFile.Create(UserIniPath);
    Result := TRUE;
   end
  else
   begin
    MessageDlg('Specified User Ini File Does not Exist',mtError,[mbOk],0);
    Result := FALSE;
   end;

  HasUserIni := Result;
end;
}
function TFormixIni.GetDatabaseName: String;
begin
  Result := GetStringFromIniVar(K_DatabaseName);
end;

function TFormixIni.GetServerName: String;
begin
  Result := GetStringFromIniVar(K_ServerName);
end;

function TFormixIni.GetServerPassword: String;
begin
  Result := GetStringFromIniVar(K_ServerPassword);
end;

function TFormixIni.GetServerUser: String;
begin
  Result := GetStringFromIniVar(K_ServerUser);
end;

procedure TFormixIni.SetFopsDatabaseName(const Value: String);
begin
  FFopsDatabaseName := Value;
end;

procedure TFormixIni.SetFopsServerName(const Value: String);
begin
  FFopsServerName := Value;
end;

function TFormixIni.GetFopsDatabaseName: String;
begin
 Result := GetStringFromIniVar(K_FopsDatabaseName);
end;

function TFormixIni.GetFopsServerName: String;
begin
 Result := GetStringFromIniVar(K_FopsServerName);
end;

function TFormixIni.QAServiceURL: string;
begin
 Result := GetStringFromIniVar(K_QAServiceURL);
end;

*)


function TFormixIni.DatabaseName: String;
begin
  Result := AppIni.ReadString(s_DATABASE, IVDatabaseName, 'FORMIX')
end;

function TFormixIni.ServerName: String;
begin
  Result := AppIni.ReadString(s_DATABASE, IVServerName, '');
end;

function TFormixIni.FopsDatabaseName: String;
begin
  Result := AppIni.ReadString(s_DATABASE, IVFopsDatabaseName, 'FOPS')
end;

function TFormixIni.FopsServerName: String;
begin
  Result := AppIni.ReadString(s_DATABASE, IVFopsServerName, '');
end;

function TFormixIni.UseFopsUsers : boolean;
begin
  Result := AppIni.ReadBool(S_MAIN, IVUseFopsUsers, false);
end;

function TFormixIni.QAServiceURL: string;
begin
  Result := AppIni.ReadString(s_DATABASE, IVQAServiceURL, '');
end;

initialization { Global Instance Creation/Destruction }

  if not Assigned(FormixIni) then
    FormixIni := TFormixIni.Create;

finalization

  if Assigned(FormixIni) then
    FormixIni.Free;

end.


unit uFopsDBDetails;

interface

uses
  uDatabaseDetails, SysUtils;

Type
  TFopsDBDetails = class(TDatabaseDetails)
  private
   FFops6IniPath: string;
  protected

  public
    property Fops6IniPath: string read FFops6IniPath write FFops6IniPath;

    procedure Init; override;
    procedure InitFromEnvironment; override;
    procedure InitFromINIFile; override;
    procedure InitForFops;
  published
  end;

implementation

uses
   uParameterList,uLauncher,uEnvironmentalVariables,uIniUtils,uIni, forms;

{ TCarcaseDBDetails }

procedure TFopsDBDetails.Init;
begin
  inherited;
{  fDefDatabase := 'FORMIX';
  DatabaseName := 'FORMIX';
  ServerName   := '';   }

{  DatabaseName := 'FOPS';
  if GetEnvironmentStringDef(EvDatabaseName,'') = '' then
    InitFromINIFile
  else
    InitFromEnvironment;     }
end;

procedure TFopsDBDetails.InitForFops;
begin
 inherited;
// FormixIni.SetUpMainIniFile(ExtractFilePath(Application.ExeName)+'\MainMenu.ini');
 fDefDatabase := FormixIni.FopsDatabaseName;
 DatabaseName := FormixIni.FopsDatabaseName;
 ServerName   := FormixIni.FopsServerName;
end;

procedure TFopsDBDetails.InitFromEnvironment;
begin
 inherited;
// FormixIni.SetUpMainIniFile(ExtractFilePath(Application.ExeName)+'\MainMenu.ini');
 fDefDatabase := FormixIni.DatabaseName;
 DatabaseName := FormixIni.DatabaseName;
 ServerName   := FormixIni.ServerName;
end;

procedure TFopsDBDetails.InitFromINIFile;
begin
 inherited;
// FormixIni.SetUpMainIniFile(ExtractFilePath(Application.ExeName)+'\MainMenu.ini');
 fDefDatabase := FormixIni.DatabaseName;
 DatabaseName := FormixIni.DatabaseName;
 ServerName   := FormixIni.ServerName;
end;

end.

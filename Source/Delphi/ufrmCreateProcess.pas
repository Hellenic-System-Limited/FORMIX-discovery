unit ufrmCreateProcess;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfrmCreateProcess = class(TForm)
    lblWaitingFor: TLabel;
    lblProcessDesc: TLabel;
    Timer1: TTimer;
    Panel1: TPanel;
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    fProgramFile : string;
    fProgramParameters : string;
    function ChangeOcmIniFile(const ModeValueStr : string;
                              const FopsProductCode : string;
                              const SrcBarcode : string) : boolean;
    procedure SwitchToProgram;
  public
    { Public declarations }
    class procedure RunModalOcmOperation(const DescOfProcess : string;
                                         const ModeValueStr : string;
                                         const FopsProductCode : string;
                                         const SrcBarcode : string);
    class procedure RunModalAddToStockProcess(const FopsProductCode : string;
                                              const SrcBarcode : string);
    class procedure RunModalOcmDispenseMode(const FopsProductCode : string;
                                            const SrcBarcode : string);
    class procedure RunModalOcmConfigurePrinter;
    class procedure RunModalOcmPluUpdate;
  end;


implementation
uses IniFiles, uTermDialogs, uIni, udmFormix, udmFormixBase;
{$R *.dfm}

function TfrmCreateProcess.ChangeOcmIniFile(const ModeValueStr : string;
                                            const FopsProductCode : string;
                                            const SrcBarcode : string) : boolean;
{
[Single Operation Mode]
Mode=SENDFILES|PRINTERCONFIGURATION|MMxx where xx is multimode number, 0 - Add to stock
SourceBarcode=
ProductCode=
}
const SingleOpSectName = 'Single Operation Mode';
var
  IniFileName : string;
  IniFile : TMemIniFile;
begin
  Result := false;
  IniFileName := dmformix.GetTermRegString(r_OcmIniFile);
  if IniFileName = '' then
    TermMessageDlg('OcmIniFile not specified', mtError, [mbOk], 0)
  else if UpperCase(ExtractFileExt(IniFileName)) <> '.INI' then
    TermMessageDlg('OcmIniFile needs a .ini extension.', mtError, [mbOk], 0)
  else
  begin
    IniFile := TMemIniFile.Create(IniFileName);
    try
      IniFile.WriteString(SingleOpSectName,'Mode',ModeValueStr);
      IniFile.WriteString(SingleOpSectName,'ProductCode',FopsProductCode);
      IniFile.WriteString(SingleOpSectName,'SourceBarcode',SrcBarcode);
      IniFile.UpdateFile;
      Result := true;
    finally
      FreeAndNil(IniFile);
    end;
  end;
end;

class procedure TfrmCreateProcess.RunModalOcmOperation(const DescOfProcess : string;
                                                       const ModeValueStr : string;
                                                       const FopsProductCode : string;
                                                       const SrcBarcode : string);
var frmCreateProc : TfrmCreateProcess;
begin
  try
    frmCreateProc := TfrmCreateProcess.Create(nil);
    try
      with frmCreateProc do
      begin
        lblProcessDesc.Caption := DescOfProcess;
        fProgramFile := dmFormix.GetTermRegString(r_OcmProgramFile);
        fProgramParameters := '';
        if ChangeOcmIniFile(ModeValueStr, FopsProductCode, SrcBarcode) then
          ShowModal;
      end;
    finally
      frmCreateProc.Free;
    end;
  except
    on E: Exception do MessageDlg(E.Message, mtError, [mbOk], 0);
  end;
end;

class procedure TfrmCreateProcess.RunModalAddToStockProcess(const FopsProductCode : string;
                                                            const SrcBarcode : string);
begin
  RunModalOcmOperation('Add to Stock process', 'MM00', FopsProductCode, SrcBarcode);
end;

class procedure TfrmCreateProcess.RunModalOcmDispenseMode(const FopsProductCode : string;
                                                          const SrcBarcode : string);
begin
  RunModalOcmOperation('Dispense part of Source Item', 'MM14', FopsProductCode, SrcBarcode);
end;

class procedure TfrmCreateProcess.RunModalOcmConfigurePrinter;
begin
  RunModalOcmOperation('Printer configuration', 'PRINTERCONFIGURATION',
                       ''{FopsProductCode}, ''{SrcBarcode});
end;

class procedure TfrmCreateProcess.RunModalOcmPluUpdate;
begin
  RunModalOcmOperation('OCM PLU updates', 'SENDFILES', ''{FopsProductCode}, ''{SrcBarcode});
end;

procedure TfrmCreateProcess.SwitchToProgram;
var
  StartUpInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  CommandLine : string;
  ErrCode : integer;
begin
  FillChar(StartUpInfo,SizeOf(TStartupInfo),0);
  with StartUpInfo do
  begin
    cb := SizeOf(TStartUpInfo);
    dwFlags := STARTF_FORCEONFEEDBACK;//??
  end;
  CommandLine := fProgramFile; //note: make fully pathed. OS search paths are not being used.
  if Trim(fProgramParameters) <> '' then
    CommandLine := CommandLine +' '+Trim(fProgramParameters);
  if CreateProcess(PChar(fProgramFile), PChar(CommandLine),
                   nil{ProcessAttributes}, nil{ThreadAttributes}, False{InheritHandles},
                   NORMAL_PRIORITY_CLASS{CreationFlags}, nil{Environment}, nil,
                   StartUpInfo, ProcessInfo) then
  begin
    with ProcessInfo do
    begin
      while WaitForSingleObject(hProcess, 1000) = WAIT_TIMEOUT do
      begin
        Application.ProcessMessages; //avoid application has gone unresponsive messages.
      end;
      CloseHandle(hProcess);
      CloseHandle(hThread);
    end;
  end
  else
  begin
    ErrCode := GetLastError;
    TermMessageDlg('Error '+IntToStr(ErrCode)+' trying to run '+CommandLine, mtError, [mbOk], 0);
  end;
end;


procedure TfrmCreateProcess.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := false;
  SwitchToProgram;
  ModalResult := mrOk;
end;

procedure TfrmCreateProcess.FormShow(Sender: TObject);
begin
  Timer1.Enabled := true;
end;

end.

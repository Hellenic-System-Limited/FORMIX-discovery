program IniEditor;

uses
  Forms,
  ufrmIniEditor in 'ufrmIniEditor.pas' {Form1},
  ufrmIniVal in 'ufrmIniVal.pas' {frmIniVal};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TfrmIniVal, frmIniVal);
  Application.Run;
end.

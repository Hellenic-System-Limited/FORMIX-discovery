unit ufrmIniEditor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, DBGrids, DB, ExtCtrls,
  udmDatabaseModule, uFopsDBInit, udmFormix, IniFiles;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    edScaleName: TEdit;
    Label2: TLabel;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    btImportIniFile: TButton;
    btAddNewIni: TButton;
    btEditIni: TButton;
    btDeleteIni: TButton;
    btExit: TButton;
    OpenDialog1: TOpenDialog;
    procedure btImportIniFileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edScaleNameChange(Sender: TObject);
    procedure btExitClick(Sender: TObject);
    procedure btAddNewIniClick(Sender: TObject);
    procedure btEditIniClick(Sender: TObject);
    procedure btDeleteIniClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
uses ufrmIniVal;
{$R *.dfm}

procedure TForm1.btImportIniFileClick(Sender: TObject);
var TempIni: TIniFile;
    SectionList,
    SectionVals: TStrings;
    i, j, k: Integer;
    WrkName,
    WrkVal: String;
begin
 {Import a selected ini file.
  Ask if they want to overwrite any current ini settings}
 if OpenDialog1.Execute then
  begin
   if MessageDlg('Do You Wish To Overwrite Any Current Ini Settings?',
                 mtConfirmation,[mbYes,mbNo],0) = mrYes then
    begin
     TempIni := TIniFile.Create(OpenDialog1.FileName);
     SectionList := TStringList.Create;
     SectionVals := TStringList.Create;
     TempIni.ReadSections(SectionList);
     for i := 0 to SectionList.Count-1 do
      begin
       TempIni.ReadSectionValues(SectionList.Strings[i],SectionVals);
       for j := 0 to SectionVals.Count-1 do
        begin
         WrkName := Copy(SectionVals.Strings[j],1,Pos('=',SectionVals.Strings[j])-1);
         WrkVal  := Copy(SectionVals.Strings[j],Pos('=',SectionVals.Strings[j])+1,
                                                Length(SectionVals.Strings[j])-
                                                Pos('=',SectionVals.Strings[j]));
         if dmFormix.Registry.Locate(RG_FolderName+';'+RG_TagName,
                              VarArrayOf([REG_Scale+edScaleName.Text,WrkName]),[]) then
          begin
           dmFormix.Registry.Edit;
           dmFormix.Registry.FindField(RG_Value).AsString := WrkVal;
           dmFormix.Registry.Post;
          end
         else
          begin
           dmFormix.Registry.AppendRecord([WrkName,
                                           WrkVal,
                                           REG_Scale+edScaleName.Text]);
          end;
        end;
      end;
     MessageDlg('Ini Import Complet',mtInformation,[mbOk],0);
    end
   else MessageDlg('Ini Import Aborted',mtInformation,[mbOk],0);
  end;
 dmFormix.Registry.Refresh;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 dmFormix := TdmFormix.Create(nil,MainDatabaseModule);
 with dmFormix do
  begin
   MakeConnection;
   Registry.IndexName := 'PK_FolderName';
   Registry.Open;
   Registry.SetRange([REG_Scale+edScaleName.Text],[REG_Scale+edScaleName.Text]);
   DataSource1.DataSet := Registry;
  end;
end;

procedure TForm1.edScaleNameChange(Sender: TObject);
begin
 dmFormix.Registry.SetRange([REG_Scale+edScaleName.Text],[REG_Scale+edScaleName.Text]);
end;

procedure TForm1.btExitClick(Sender: TObject);
begin
 Close;
end;

procedure TForm1.btAddNewIniClick(Sender: TObject);
begin
 {Add A New Ini Setting}
 frmIniVal := TfrmIniVal.Create(Self);
 with frmIniVal do
  begin
   Caption := 'Add New Ini Variable For: '+edScaleName.Text;
   ShowModal;
   if ModalResult = mrOk then
    begin
     {Need to try and add the record}
     if dmFormix.Registry.Locate(RG_FolderName+';'+RG_TagName,
                          VarArrayOf([REG_Scale+edScaleName.Text,edIniName.Text]),[]) then
      begin
       if MessageDlg('The Ini Name Of: '+edIniName.Text+' All Ready Exists'+#13#10+#13#10+
                     'Old Value: '+dmFormix.Registry.FindField(RG_Value).AsString+#13#10+
                     'New Value: '+edIniValue.Text+#13#10+#13#10+
                     'Do You Wish To Overwrite With The New Value?',mtConfirmation,[mbYes,mbNo],0) = mrYes then
        begin
         dmFormix.Registry.Edit;
         dmFormix.Registry.FindField(RG_Value).AsString := edIniValue.Text;
         dmFormix.Registry.Post;
        end;
      end
     else
      begin
       dmFormix.Registry.AppendRecord([edIniName.Text,
                                       edIniValue.Text,
                                       REG_Scale+edScaleName.Text]);
      end;
    end;
   Free;
  end;
 dmFormix.Registry.Refresh;
end;

procedure TForm1.btEditIniClick(Sender: TObject);
begin
 {Edit New Ini Setting}
 frmIniVal := TfrmIniVal.Create(Self);
 with frmIniVal do
  begin
   Caption := 'Edit Ini Variable For: '+edScaleName.Text;
   edIniName.Text := dmFormix.Registry.FindField(RG_TagName).AsString;
   edIniName.ReadOnly := TRUE;
   edIniValue.Text := dmFormix.Registry.FindField(RG_Value).AsString;
   ShowModal;
   if ModalResult = mrOk then
    begin
     {Update the Ini Value}
     dmFormix.Registry.Edit;
     dmFormix.Registry.FindField(RG_Value).AsString := edIniValue.Text;
     dmFormix.Registry.Post;
    end;
   Free;
  end;
 dmFormix.Registry.Refresh;
end;

procedure TForm1.btDeleteIniClick(Sender: TObject);
begin
 {Delete the selected Ini}
 if MessageDlg('Are You Sure You Wish To Delete Ini Setting: '+#10#13+
               dmFormix.Registry.FindField(RG_TagName).AsString+#10#13+
               'For Scale: '+edScaleName.Text+'?',mtConfirmation,[mbYes,mbNo],0) = mrYes then
   dmFormix.Registry.Delete;
 dmFormix.Registry.Refresh;
end;

end.

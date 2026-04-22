unit udmFormixReport;

interface

uses
  SysUtils, Classes, udmFormixBase, DB, sqldataset, RxMemDS, uCustomHSLSecurity,
  HSLSecurity, pvtables, btvtables, ppComm, ppEndUsr, ppReport;

type
  pMemoryStream = ^TMemoryStream;

  TdmFormixReport = class(TdmFormixBase)
    desReportDesigner: TppDesigner;
    procedure desReportDesignerReportSelected(Sender: TObject);
    procedure desReportDesignerCloseQuery(Sender: TObject;
      var CanClose: Boolean);
    procedure desReportDesignerCustomSaveDoc(Sender: TObject);
    procedure desReportDesignerCustomOpenDoc(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
    UncreatedStream : TMemoryStream;
  protected  
    procedure SaveReportsInDfmToStreams; virtual;
  public
    { Public declarations }
    procedure EditReport(AReport : TppReport);
    function  GetPtrToStreamForReportDfm(const AReport : TppReport) : PMemoryStream; virtual;
    procedure InvalidateReportTemplateFilenames; virtual;
    procedure SetReportTemplatesFromIni; virtual;
  end;


implementation
uses Controls, uRBUtils, Dialogs, raIDE{calctab};
{$R *.dfm}
procedure TdmFormixReport.SaveReportsInDfmToStreams;
begin
end;

function  TdmFormixReport.GetPtrToStreamForReportDfm(const AReport : TppReport) : PMemoryStream;
begin
  Result:= @UncreatedStream;
end;

procedure TdmFormixReport.InvalidateReportTemplateFilenames;
begin
end;

procedure TdmFormixReport.SetReportTemplatesFromIni;
begin
end;

procedure TdmFormixReport.EditReport(AReport : TppReport);
var
  StreamForReportDfm : PMemoryStream;
  SavePath : string;
begin
  if (AReport.Template.FileName = '') then //backup dfm layout to a memory stream
  begin
    //this is not really needed anymore - all dfm reports are now saved on datamodule creation.
    StreamForReportDfm := GetPtrToStreamForReportDfm(AReport);
    if  (StreamForReportDfm <> nil)
    and (StreamForReportDfm^ = nil) then
    begin
      StreamForReportDfm^ := TMemoryStream.Create;
      AReport.Template.SaveToStream(StreamForReportDfm^);
    end;
  end;
  desReportDesigner.Report := AReport;
  try
    SavePath := GetCurrentDir;
    try
      {note: ReportDesigner saves where it last opened and saved files in its ini file (property).}
      desReportDesigner.ShowModal;
    finally
      SetCurrentDir(SavePath);
    end;
  finally
    desReportDesigner.Report := nil; //make sure the name of the last template viewed by the designer gets cleared 
  end;
  InvalidateReportTemplateFilenames;
  SetReportTemplatesFromIni;
end;

procedure TdmFormixReport.desReportDesignerReportSelected(Sender: TObject);
begin
  inherited;
  UpdateReportDesignerCaption(desReportDesigner);

end;

procedure TdmFormixReport.desReportDesignerCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  inherited;
  if desReportDesigner.Report.Modified then
  begin
    CanClose := MessageDlg('Exit without saving changes?', mtConfirmation,[mbYes,mbNo],0) = mrYes;
  end
  else
    CanClose := true;
end;

procedure TdmFormixReport.desReportDesignerCustomSaveDoc(Sender: TObject);
begin
  inherited;
  desReportDesigner.Report.Template.Save;
  UpdateReportDesignerCaption(desReportDesigner);
end;

procedure TdmFormixReport.desReportDesignerCustomOpenDoc(Sender: TObject);
begin
  inherited;
  desReportDesigner.Report.Template.Load;
  UpdateReportDesignerCaption(desReportDesigner);
end;

procedure TdmFormixReport.DataModuleCreate(Sender: TObject);
begin
  inherited;
  SaveReportsInDfmToStreams;
  SetReportTemplatesFromIni;
end;

end.

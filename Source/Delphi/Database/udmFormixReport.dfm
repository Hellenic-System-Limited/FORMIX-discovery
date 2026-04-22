inherited dmFormixReport: TdmFormixReport
  Height = 591
  object desReportDesigner: TppDesigner
    Caption = 'ReportBuilder'
    DataSettings.SessionType = 'BDESession'
    DataSettings.AllowEditSQL = False
    DataSettings.GuidCollationType = gcString
    DataSettings.IsCaseSensitive = True
    DataSettings.SQLType = sqBDELocal
    Position = poScreenCenter
    IniStorageType = 'IniFile'
    IniStorageName = '($LocalAppData)\RBuilder\RBuilder.ini'
    WindowHeight = 400
    WindowLeft = 100
    WindowTop = 50
    WindowWidth = 600
    OnCloseQuery = desReportDesignerCloseQuery
    OnCustomOpenDoc = desReportDesignerCustomOpenDoc
    OnCustomSaveDoc = desReportDesignerCustomSaveDoc
    OnReportSelected = desReportDesignerReportSelected
    Left = 112
    Top = 524
  end
end

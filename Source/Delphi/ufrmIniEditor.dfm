object Form1: TForm1
  Left = 260
  Top = 193
  BorderStyle = bsSingle
  Caption = 'Ini Viewer'
  ClientHeight = 465
  ClientWidth = 410
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 410
    Height = 465
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 16
      Width = 58
      Height = 13
      Caption = 'Scale Name'
    end
    object Label2: TLabel
      Left = 8
      Top = 44
      Width = 75
      Height = 13
      Caption = 'Current Settings'
    end
    object edScaleName: TEdit
      Left = 80
      Top = 8
      Width = 121
      Height = 21
      TabOrder = 0
      OnChange = edScaleNameChange
    end
    object DBGrid1: TDBGrid
      Left = 8
      Top = 60
      Width = 393
      Height = 369
      DataSource = DataSource1
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Expanded = False
          FieldName = 'TagName'
          Title.Caption = 'Ini Setting'
          Width = 119
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'Value'
          Width = 240
          Visible = True
        end>
    end
    object btImportIniFile: TButton
      Left = 8
      Top = 436
      Width = 75
      Height = 25
      Caption = 'Import Ini File'
      TabOrder = 2
      OnClick = btImportIniFileClick
    end
    object btAddNewIni: TButton
      Left = 88
      Top = 436
      Width = 75
      Height = 25
      Caption = 'Add New Ini'
      TabOrder = 3
      OnClick = btAddNewIniClick
    end
    object btEditIni: TButton
      Left = 168
      Top = 436
      Width = 75
      Height = 25
      Caption = 'Edit Ini'
      TabOrder = 4
      OnClick = btEditIniClick
    end
    object btDeleteIni: TButton
      Left = 248
      Top = 436
      Width = 75
      Height = 25
      Caption = 'Delete Ini'
      TabOrder = 5
      OnClick = btDeleteIniClick
    end
    object btExit: TButton
      Left = 328
      Top = 436
      Width = 75
      Height = 25
      Caption = 'Exit'
      TabOrder = 6
      OnClick = btExitClick
    end
  end
  object DataSource1: TDataSource
    Left = 8
    Top = 464
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Ini File (*.ini)|*.ini'
    Left = 40
    Top = 464
  end
end

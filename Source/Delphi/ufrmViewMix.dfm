object frmViewMix: TfrmViewMix
  Left = 479
  Top = 243
  BorderStyle = bsNone
  Caption = 'frmViewMix'
  ClientHeight = 395
  ClientWidth = 734
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 20
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 734
    Height = 395
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object Label1: TLabel
      Left = 288
      Top = 360
      Width = 51
      Height = 20
      Caption = 'Mix No:'
    end
    object lbMixHeader: TLabel
      Left = 8
      Top = 4
      Width = 88
      Height = 20
      Caption = 'lbMixHeader'
    end
    object DBGrid1: TDBGrid
      Left = 4
      Top = 28
      Width = 729
      Height = 297
      DataSource = dsMixSource
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -16
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnCellClick = DBGrid1CellClick
    end
    object edMixNo: TEdit
      Left = 346
      Top = 356
      Width = 121
      Height = 28
      TabOrder = 1
      OnClick = edMixNoClick
    end
    object Button1: TButton
      Left = 474
      Top = 332
      Width = 121
      Height = 53
      Caption = 'Goto Mix'
      ModalResult = 1
      TabOrder = 2
    end
    object Button2: TButton
      Left = 606
      Top = 332
      Width = 121
      Height = 53
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 3
    end
  end
  object dsMixSource: TDataSource
    Left = 244
    Top = 316
  end
end

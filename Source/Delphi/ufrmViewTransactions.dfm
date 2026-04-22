object frmViewTransactions: TfrmViewTransactions
  Left = 873
  Top = 206
  BorderStyle = bsDialog
  Caption = 'Transaction Browser'
  ClientHeight = 392
  ClientWidth = 734
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 734
    Height = 392
    Align = alClient
    BevelInner = bvLowered
    Caption = 'Panel1'
    TabOrder = 0
    DesignSize = (
      734
      392)
    object lblGridHeader: TLabel
      Left = 8
      Top = 3
      Width = 167
      Height = 20
      Caption = 'Ingredient Transactions'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object DBGrid1: TDBGrid
      Left = 7
      Top = 28
      Width = 719
      Height = 297
      Anchors = [akLeft, akTop, akRight, akBottom]
      DataSource = DataSource1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -16
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
    end
    object Button1: TButton
      Left = 603
      Top = 332
      Width = 121
      Height = 53
      Caption = 'Exit'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ModalResult = 2
      ParentFont = False
      TabOrder = 1
    end
    object btnNextIngredient: TButton
      Left = 160
      Top = 332
      Width = 121
      Height = 53
      Caption = 'Next   Ingredient'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      WordWrap = True
      OnClick = btnNextIngredientClick
    end
    object btnPrevIngredient: TButton
      Left = 24
      Top = 332
      Width = 121
      Height = 53
      Caption = 'Previous Ingredient'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      WordWrap = True
      OnClick = btnPrevIngredientClick
    end
  end
  object DataSource1: TDataSource
    DataSet = rxmemTrans
    Left = 344
  end
  object rxmemTrans: TRxMemoryData
    FieldDefs = <>
    OnFilterRecord = rxmemTransFilterRecord
    Left = 312
  end
end

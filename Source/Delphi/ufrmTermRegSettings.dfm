object frmTermRegSettings: TfrmTermRegSettings
  Left = 638
  Top = 214
  BorderStyle = bsNone
  Caption = 'frmTermRegSettings'
  ClientHeight = 600
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 600
    Align = alClient
    BevelOuter = bvLowered
    Caption = 'Panel1'
    TabOrder = 0
    object DBGrid1: TDBGrid
      Left = 1
      Top = 1
      Width = 784
      Height = 535
      Align = alLeft
      DataSource = dsTermRegSettings
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
    end
    object pnlButtons: TPanel
      Left = 1
      Top = 536
      Width = 798
      Height = 63
      Align = alBottom
      TabOrder = 1
      DesignSize = (
        798
        63)
      object btnEditValue: TButton
        Left = 27
        Top = 7
        Width = 121
        Height = 53
        Anchors = [akLeft, akBottom]
        Caption = 'Edit Value'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = btnEditValueClick
      end
      object btnOk: TButton
        Left = 652
        Top = 7
        Width = 121
        Height = 53
        Anchors = [akRight, akBottom]
        Caption = 'Exit'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ModalResult = 1
        ParentFont = False
        TabOrder = 1
      end
    end
  end
  object dsTermRegSettings: TDataSource
    DataSet = dmFormix.rxmTermRegSettings
    Left = 280
    Top = 184
  end
end

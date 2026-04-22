object frmFormixListPick: TfrmFormixListPick
  Left = 599
  Top = 341
  BorderStyle = bsSingle
  Caption = 'frmFormixListPick'
  ClientHeight = 348
  ClientWidth = 483
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
    Width = 483
    Height = 348
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      483
      348)
    object Label1: TLabel
      Left = 24
      Top = 8
      Width = 45
      Height = 20
      Caption = 'Select'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object btCancel: TButton
      Left = 342
      Top = 275
      Width = 121
      Height = 52
      Anchors = [akLeft, akBottom]
      Caption = 'Cancel'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ModalResult = 2
      ParentFont = False
      TabOrder = 0
    end
    object Button1: TButton
      Left = 211
      Top = 275
      Width = 121
      Height = 52
      Caption = 'OK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ModalResult = 1
      ParentFont = False
      TabOrder = 1
    end
    object DBGrid1: TDBGrid
      Left = 16
      Top = 32
      Width = 449
      Height = 233
      DataSource = dsGridData
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -18
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 2
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDrawColumnCell = DBGrid1DrawColumnCell
      Columns = <
        item
          Expanded = False
          Width = 25
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'OptionStr'
          Title.Caption = 'Answer'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'Red'
          Visible = False
        end
        item
          Expanded = False
          FieldName = 'Green'
          Visible = False
        end
        item
          Expanded = False
          FieldName = 'Blue'
          Visible = False
        end>
    end
  end
  object rxmGridData: TRxMemoryData
    FieldDefs = <>
    Left = 24
    Top = 296
    object rxmGridDataOptionStr: TStringField
      FieldName = 'OptionStr'
      Size = 80
    end
    object rxmGridDataOptionColour: TIntegerField
      FieldName = 'OptionColour'
    end
    object rxmGridDataRed: TIntegerField
      FieldName = 'Red'
    end
    object rxmGridDataGreen: TIntegerField
      FieldName = 'Green'
    end
    object rxmGridDataBlue: TIntegerField
      FieldName = 'Blue'
    end
  end
  object dsGridData: TDataSource
    DataSet = rxmGridData
    Left = 56
    Top = 296
  end
end

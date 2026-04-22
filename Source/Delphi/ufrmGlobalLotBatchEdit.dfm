object frmGlobalLotBatchEdit: TfrmGlobalLotBatchEdit
  Left = 245
  Top = 213
  BorderIcons = [biSystemMenu]
  BorderStyle = bsNone
  Caption = 'frmGlobalLotBatchEdit'
  ClientHeight = 142
  ClientWidth = 360
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 20
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 360
    Height = 142
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object Label1: TLabel
      Left = 12
      Top = 12
      Width = 152
      Height = 20
      Caption = 'Global Batch Number'
    end
    object Label2: TLabel
      Left = 12
      Top = 48
      Width = 133
      Height = 20
      Caption = 'Global Lot Number'
    end
    object edGlobalBatch: TEdit
      Left = 176
      Top = 8
      Width = 121
      Height = 28
      TabOrder = 0
      Text = 'edGlobalBatch'
      OnClick = edGlobalBatchClick
    end
    object edGlobalLot: TEdit
      Left = 176
      Top = 40
      Width = 173
      Height = 28
      TabOrder = 1
      Text = 'edGlobalLot'
      OnClick = edGlobalLotClick
    end
    object btOk: TButton
      Left = 100
      Top = 80
      Width = 121
      Height = 53
      Caption = 'Ok'
      ModalResult = 1
      TabOrder = 2
    end
    object btCancel: TButton
      Left = 228
      Top = 80
      Width = 121
      Height = 53
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 3
    end
  end
end

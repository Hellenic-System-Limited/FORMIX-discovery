object frmPrinterOptions: TfrmPrinterOptions
  Left = 304
  Top = 206
  BorderIcons = [biSystemMenu]
  BorderStyle = bsNone
  Caption = 'Printer Options'
  ClientHeight = 129
  ClientWidth = 391
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
    Width = 391
    Height = 129
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object rxsbExit: TButton
      Left = 8
      Top = 8
      Width = 121
      Height = 53
      Caption = 'Exit'#13#10'Menu'
      ModalResult = 1
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      WordWrap = True
    end
    object rxsbDownloadLabelFile: TButton
      Left = 136
      Top = 8
      Width = 121
      Height = 53
      Caption = 'Download'#13#10'Label File'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      WordWrap = True
      OnClick = rxsbDownloadLabelFileClick
    end
    object rxsbPrinterOptions: TButton
      Left = 264
      Top = 8
      Width = 121
      Height = 53
      Caption = 'Printer'#13#10'Setup'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      WordWrap = True
      OnClick = rxsbPrinterOptionsClick
    end
    object rxsbEditPrinterConfig: TButton
      Left = 136
      Top = 68
      Width = 121
      Height = 53
      Caption = 'Edit Printer'#13#10'Config'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      WordWrap = True
    end
    object rxsbDownloadPrinterConfig: TButton
      Left = 264
      Top = 68
      Width = 121
      Height = 53
      Caption = 'Download'#13#10'Printer Config'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      WordWrap = True
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 8
    Top = 64
  end
end

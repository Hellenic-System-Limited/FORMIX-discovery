object Form2: TForm2
  Left = 484
  Top = 348
  Width = 401
  Height = 165
  Caption = 'Form2'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 20
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 393
    Height = 131
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object rxsbExit: TRxSpeedButton
      Left = 8
      Top = 8
      Width = 121
      Height = 53
      Caption = 'Exit'#13#10'Menu'
      ModalResult = 1
      Transparent = True
    end
    object rxsbDownloadLabelFile: TRxSpeedButton
      Left = 136
      Top = 8
      Width = 121
      Height = 53
      Caption = 'Download'#13#10'Label File'
      Transparent = True
    end
    object rxsbPrinterOptions: TRxSpeedButton
      Left = 264
      Top = 8
      Width = 121
      Height = 53
      Caption = 'Printer'#13#10'Options'
      Transparent = True
    end
    object rxsbEditPrinterConfig: TRxSpeedButton
      Left = 136
      Top = 68
      Width = 121
      Height = 53
      Caption = 'Edit Printer'#13#10'Config'
      Enabled = False
      Transparent = True
    end
    object rxsbDownloadPrinterConfig: TRxSpeedButton
      Left = 264
      Top = 68
      Width = 121
      Height = 53
      Caption = 'Download'#13#10'Printer Config'
      Enabled = False
      Transparent = True
    end
  end
end

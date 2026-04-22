object frmIniVal: TfrmIniVal
  Left = 408
  Top = 291
  BorderStyle = bsSingle
  Caption = 'frmIniVal'
  ClientHeight = 128
  ClientWidth = 334
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 334
    Height = 128
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 42
      Height = 13
      Caption = 'Ini Name'
    end
    object Label2: TLabel
      Left = 8
      Top = 52
      Width = 27
      Height = 13
      Caption = 'Value'
    end
    object edIniName: TEdit
      Left = 8
      Top = 24
      Width = 317
      Height = 21
      TabOrder = 0
    end
    object edIniValue: TEdit
      Left = 8
      Top = 68
      Width = 317
      Height = 21
      TabOrder = 1
    end
    object Button1: TButton
      Left = 172
      Top = 96
      Width = 75
      Height = 25
      Caption = 'Ok'
      ModalResult = 1
      TabOrder = 2
    end
    object Button2: TButton
      Left = 252
      Top = 96
      Width = 75
      Height = 25
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 3
    end
  end
end

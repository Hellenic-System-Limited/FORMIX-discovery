object frmUserOverride: TfrmUserOverride
  Left = 438
  Top = 368
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'frmUserOverride'
  ClientHeight = 92
  ClientWidth = 388
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 20
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 388
    Height = 92
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object Label8: TLabel
      Left = 8
      Top = 36
      Width = 80
      Height = 20
      Caption = 'User Name'
    end
    object Label9: TLabel
      Left = 8
      Top = 64
      Width = 69
      Height = 20
      Caption = 'Password'
    end
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 160
      Height = 20
      Caption = 'Enter Override User'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object LoginButton: TButton
      Left = 224
      Top = 60
      Width = 75
      Height = 25
      Caption = 'Ok'
      TabOrder = 0
      OnClick = LoginButtonClick
    end
    object edUserName: TEdit
      Left = 96
      Top = 32
      Width = 121
      Height = 28
      CharCase = ecUpperCase
      TabOrder = 1
      OnClick = edUserNameClick
    end
    object edPassword: TEdit
      Left = 96
      Top = 60
      Width = 121
      Height = 28
      CharCase = ecUpperCase
      PasswordChar = '*'
      TabOrder = 2
      OnClick = edPasswordClick
    end
    object Button1: TButton
      Left = 304
      Top = 60
      Width = 75
      Height = 25
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 3
    end
  end
end

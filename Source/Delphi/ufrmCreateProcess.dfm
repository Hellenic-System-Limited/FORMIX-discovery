object frmCreateProcess: TfrmCreateProcess
  Left = 511
  Top = 446
  BorderStyle = bsNone
  BorderWidth = 2
  Caption = 'CreateProcess'
  ClientHeight = 108
  ClientWidth = 482
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
    Width = 482
    Height = 108
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 0
    object lblProcessDesc: TLabel
      Left = 244
      Top = 40
      Width = 57
      Height = 20
      Caption = 'Process'
    end
    object lblWaitingFor: TLabel
      Left = 63
      Top = 40
      Width = 175
      Height = 20
      Alignment = taRightJustify
      Caption = 'Waiting for completion of'
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 10
    OnTimer = Timer1Timer
    Left = 152
    Top = 8
  end
end

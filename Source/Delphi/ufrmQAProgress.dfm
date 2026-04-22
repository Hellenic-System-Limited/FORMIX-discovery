object frmQAProgress: TfrmQAProgress
  Left = 688
  Top = 328
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Quality Assurance Checks'
  ClientHeight = 190
  ClientWidth = 478
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 24
    Top = 40
    Width = 48
    Height = 13
    Caption = 'QA Mode:'
  end
  object txtQAMode: TStaticText
    Left = 88
    Top = 40
    Width = 57
    Height = 17
    Caption = 'txtQAMode'
    TabOrder = 0
  end
end

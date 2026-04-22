object frmFormixStdEntry: TfrmFormixStdEntry
  Left = 600
  Top = 340
  BorderIcons = [biMaximize]
  BorderStyle = bsSingle
  Caption = 'frmFormixStdEntry'
  ClientHeight = 350
  ClientWidth = 662
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
    Width = 662
    Height = 350
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      662
      350)
    object lbStd: TLabel
      Left = 11
      Top = 20
      Width = 156
      Height = 20
      Caption = 'Enter Scale Password'
    end
    object Label1: TLabel
      Left = 312
      Top = 56
      Width = 255
      Height = 20
      Caption = 'Note: edit box may move to this area'
      Visible = False
    end
    object edStd: TEdit
      Left = 208
      Top = 16
      Width = 437
      Height = 28
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      PasswordChar = '*'
      TabOrder = 0
      OnKeyDown = edStdKeyDown
      OnKeyPress = edStdKeyPress
    end
    object HSLAZKeyboard1: THSLAZKeyboard
      Left = 7
      Top = 88
      Width = 485
      Height = 193
      Anchors = [akLeft, akBottom]
      BevelOuter = bvNone
      Caption = 'HSLAZKeyboard1'
      TabOrder = 2
    end
    object HSLNumericKeyboard1: THSLNumericKeyboard
      Left = 507
      Top = 88
      Width = 153
      Height = 193
      Anchors = [akLeft, akBottom]
      BevelOuter = bvNone
      TabOrder = 4
    end
    object btOk: TButton
      Left = 407
      Top = 286
      Width = 121
      Height = 53
      Anchors = [akLeft, akBottom]
      Caption = 'Ok'
      ModalResult = 1
      TabOrder = 6
      OnClick = btOkClick
    end
    object btCancel: TButton
      Left = 531
      Top = 286
      Width = 121
      Height = 53
      Anchors = [akLeft, akBottom]
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 7
    end
    object rxcalcEdit1: TRxCalcEdit
      Left = 212
      Top = 17
      Width = 89
      Height = 25
      AutoSize = False
      ButtonWidth = 0
      MaxLength = 6
      NumGlyphs = 2
      TabOrder = 1
      Visible = False
    end
    object btnShowKeyboard: TButton
      Left = 23
      Top = 286
      Width = 105
      Height = 53
      Anchors = [akLeft, akBottom]
      Caption = 'Keyboard'
      TabOrder = 5
      Visible = False
      WordWrap = True
      OnClick = btnShowKeyboardClick
    end
    object edTime: TDateTimePicker
      Left = 216
      Top = 16
      Width = 81
      Height = 41
      Date = 41359.691017303240000000
      Format = 'HH:mm'
      Time = 41359.691017303240000000
      Kind = dtkTime
      TabOrder = 3
      Visible = False
    end
  end
end

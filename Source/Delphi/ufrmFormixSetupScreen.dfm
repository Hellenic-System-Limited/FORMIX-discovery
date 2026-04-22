object frmFormixSetupScreen: TfrmFormixSetupScreen
  Left = 295
  Top = 196
  BorderStyle = bsNone
  Caption = 'frmFormixSetupScreen'
  ClientHeight = 185
  ClientWidth = 535
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
    Width = 535
    Height = 185
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
    object RxSpeedButton1: TButton
      Left = 408
      Top = 128
      Width = 121
      Height = 53
      Caption = 'Shut Down'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      WordWrap = True
    end
    object RxSpeedButton2: TButton
      Left = 408
      Top = 68
      Width = 121
      Height = 53
      Caption = 'Show Terminal Settings'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      WordWrap = True
      OnClick = RxSpeedButton2Click
    end
    object RxSpeedButton3: TButton
      Left = 272
      Top = 68
      Width = 121
      Height = 53
      Caption = 'Send'#13#10'Mesage'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      WordWrap = True
    end
    object RxSpeedButton4: TButton
      Left = 140
      Top = 68
      Width = 121
      Height = 53
      Caption = 'Show Graphical'#13#10'Totals'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      WordWrap = True
    end
    object rxsbEditBatchAndLot: TButton
      Left = 8
      Top = 68
      Width = 121
      Height = 53
      Caption = 'Edit Batch'#13#10'And Lot'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      WordWrap = True
      OnClick = rxsbEditBatchAndLotClick
    end
    object rxsbPrinterOptions: TButton
      Left = 408
      Top = 8
      Width = 121
      Height = 53
      Caption = 'Printer'#13#10'Options...'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      WordWrap = True
      OnClick = rxsbPrinterOptionsClick
    end
    object rxsbSetup: TButton
      Left = 272
      Top = 8
      Width = 121
      Height = 53
      Caption = 'Set Up'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 7
      WordWrap = True
      OnClick = rxsbSetupClick
    end
    object rxsbChangePassword: TButton
      Left = 140
      Top = 8
      Width = 121
      Height = 53
      Caption = 'Change'#13#10'Password'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 8
      WordWrap = True
      OnClick = rxsbChangePasswordClick
    end
    object rxsbScaleOptions: TButton
      Left = 8
      Top = 128
      Width = 121
      Height = 53
      Caption = 'Setup Scale 1'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 9
      WordWrap = True
      OnClick = rxsbScaleOptionsClick
    end
    object RxSpeedButton5: TButton
      Left = 272
      Top = 128
      Width = 121
      Height = 53
      Caption = 'Scanner'#13#10'Test'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 10
      WordWrap = True
      OnClick = RxSpeedButton5Click
    end
    object rxsbScale2Options: TButton
      Left = 140
      Top = 128
      Width = 121
      Height = 53
      Caption = 'Setup Scale 2'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 11
      WordWrap = True
      OnClick = rxsbScale2OptionsClick
    end
  end
end

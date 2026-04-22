object Form1: TForm1
  Left = 744
  Top = 310
  Width = 626
  Height = 245
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 610
    Height = 207
    Align = alClient
    Caption = 'Rinstrun Simulator'
    TabOrder = 0
    object Label4: TLabel
      Left = 32
      Top = 18
      Width = 116
      Height = 13
      Caption = 'Serial Port Device Name'
    end
    object lblWt: TLabel
      Left = 234
      Top = 56
      Width = 11
      Height = 45
      Alignment = taRightJustify
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Arial Black'
      Font.Style = []
      ParentFont = False
    end
    object edPort: TEdit
      Left = 156
      Top = 14
      Width = 121
      Height = 21
      TabOrder = 0
      Text = 'COM3'
    end
    object btnStart: TButton
      Left = 280
      Top = 12
      Width = 75
      Height = 25
      Caption = 'Start'
      TabOrder = 1
      OnClick = btnStartClick
    end
    object WtSlider: TJvxSlider
      Left = 30
      Top = 116
      Width = 547
      Height = 40
      Increment = 1
      MinValue = -2000
      MaxValue = 6500
      TabOrder = 2
    end
    object btnStop: TButton
      Left = 362
      Top = 12
      Width = 75
      Height = 25
      Caption = 'Stop'
      TabOrder = 3
      OnClick = btnStopClick
    end
    object rgScaleType: TRadioGroup
      Left = 436
      Top = 12
      Width = 169
      Height = 71
      Caption = 'ScaleType'
      ItemIndex = 0
      Items.Strings = (
        'RINSTRUN'
        'METTLER TOLEDO')
      TabOrder = 4
    end
  end
  object rPort: TComPort
    BaudRate = br9600
    Port = 'COM4'
    Parity.Bits = prNone
    StopBits = sbOneStopBit
    DataBits = dbEight
    Events = [evRxChar]
    FlowControl.OutCTSFlow = False
    FlowControl.OutDSRFlow = False
    FlowControl.ControlDTR = dtrDisable
    FlowControl.ControlRTS = rtsDisable
    FlowControl.XonXoffOut = False
    FlowControl.XonXoffIn = False
    SyncMethod = smWindowSync
    Left = 550
    Top = 12
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer1Timer
    Left = 516
    Top = 12
  end
end

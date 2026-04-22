object frmScaleSetup: TfrmScaleSetup
  Left = 502
  Top = 256
  BorderStyle = bsNone
  Caption = 'Scale Setup'
  ClientHeight = 405
  ClientWidth = 634
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
    Width = 634
    Height = 405
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object Panel2: TPanel
      Left = 2
      Top = 344
      Width = 630
      Height = 59
      Align = alBottom
      TabOrder = 0
      DesignSize = (
        630
        59)
      object btOk: TButton
        Left = 377
        Top = 2
        Width = 121
        Height = 53
        Anchors = [akRight, akBottom]
        Caption = 'Ok'
        ModalResult = 1
        TabOrder = 0
      end
      object btCancel: TButton
        Left = 503
        Top = 2
        Width = 121
        Height = 53
        Anchors = [akRight, akBottom]
        Caption = 'Cancel'
        ModalResult = 2
        TabOrder = 1
      end
    end
    object PageControl1: TPageControl
      Left = 2
      Top = 105
      Width = 630
      Height = 239
      ActivePage = tbsIPSettings
      Align = alClient
      MultiLine = True
      TabOrder = 1
      object tbsSerialSettings: TTabSheet
        Caption = 'Serial Port Settings'
        object Label1: TLabel
          Left = 8
          Top = 12
          Width = 66
          Height = 20
          Caption = 'Com Port'
        end
        object Label2: TLabel
          Left = 8
          Top = 44
          Width = 77
          Height = 20
          Caption = 'Baud Rate'
        end
        object Label5: TLabel
          Left = 8
          Top = 76
          Width = 66
          Height = 20
          Caption = 'Data Bits'
        end
        object Label3: TLabel
          Left = 8
          Top = 108
          Width = 39
          Height = 20
          Caption = 'Parity'
        end
        object Label4: TLabel
          Left = 8
          Top = 140
          Width = 65
          Height = 20
          Caption = 'Stop Bits'
        end
        object Label6: TLabel
          Left = 8
          Top = 172
          Width = 88
          Height = 20
          Caption = 'Flow Control'
        end
        object cbComPorts: TComboBox
          Left = 112
          Top = 8
          Width = 145
          Height = 28
          ItemHeight = 0
          TabOrder = 0
          Text = 'cbComPorts'
        end
        object cbBaudRate: TComboBox
          Left = 112
          Top = 40
          Width = 145
          Height = 28
          ItemHeight = 20
          TabOrder = 1
          Text = 'cbBaudRate'
          Items.Strings = (
            '110'
            '300'
            '600'
            '1200'
            '2400'
            '4800'
            '9600'
            '14400'
            '19200'
            '38400'
            '56000'
            '57600'
            '115200'
            '128000'
            '256000')
        end
        object cbDataBits: TComboBox
          Left = 112
          Top = 72
          Width = 145
          Height = 28
          ItemHeight = 20
          TabOrder = 2
          Text = 'cbDataBits'
          Items.Strings = (
            '5'
            '6'
            '7'
            '8')
        end
        object cbParity: TComboBox
          Left = 112
          Top = 104
          Width = 145
          Height = 28
          ItemHeight = 20
          TabOrder = 3
          Text = 'cbParity'
          Items.Strings = (
            'Even'
            'Odd'
            'None'
            'Mark'
            'Space')
        end
        object cbStopBits: TComboBox
          Left = 112
          Top = 136
          Width = 145
          Height = 28
          ItemHeight = 20
          TabOrder = 4
          Text = 'cbStopBits'
          Items.Strings = (
            '1'
            '1.5'
            '2')
        end
        object cbFlowControl: TComboBox
          Left = 112
          Top = 168
          Width = 145
          Height = 28
          ItemHeight = 20
          TabOrder = 5
          Text = 'cbFlowControl'
          Items.Strings = (
            'Xon / Xoff'
            'Hardware'
            'None')
        end
      end
      object tbsIPSettings: TTabSheet
        Caption = 'TCPIP Settings'
        ImageIndex = 1
        object Label10: TLabel
          Left = 15
          Top = 20
          Width = 111
          Height = 20
          Caption = 'IP Address:Port'
        end
        object meIPAddress: TMaskEdit
          Left = 150
          Top = 16
          Width = 238
          Height = 28
          EditMask = '999.999.999.999:9999'
          MaxLength = 20
          TabOrder = 0
          Text = '   .   .   .   :    '
          OnClick = meIPAddressClick
        end
      end
    end
    object Panel3: TPanel
      Left = 2
      Top = 2
      Width = 630
      Height = 103
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 2
      object Label7: TLabel
        Left = 360
        Top = 12
        Width = 101
        Height = 20
        Caption = 'Max Scale Wt.'
      end
      object Label8: TLabel
        Left = 360
        Top = 44
        Width = 74
        Height = 20
        Caption = 'Scale D.P.'
      end
      object Label9: TLabel
        Left = 361
        Top = 76
        Width = 100
        Height = 20
        Caption = 'Wt. Increment'
      end
      object meMaxScaleWt: TMaskEdit
        Left = 468
        Top = 8
        Width = 145
        Height = 28
        TabOrder = 0
        Text = 'meMaxScaleWt'
        OnClick = meMaxScaleWtClick
      end
      object meScaleDP: TMaskEdit
        Left = 468
        Top = 40
        Width = 145
        Height = 28
        TabOrder = 1
        Text = 'meScaleDP'
        OnClick = meScaleDPClick
      end
      object meScaleIncrement: TMaskEdit
        Left = 468
        Top = 72
        Width = 145
        Height = 28
        TabOrder = 2
        Text = 'meScaleIncrement'
        OnClick = meScaleIncrementClick
      end
      object rgScaleType: TRadioGroup
        Left = 3
        Top = 1
        Width = 340
        Height = 47
        Caption = 'Scale Type'
        Columns = 2
        ItemIndex = 0
        Items.Strings = (
          'SERIAL'
          'TCPIP')
        TabOrder = 3
        OnClick = rgScaleTypeClick
      end
      object rgScaleModel: TRadioGroup
        Left = 3
        Top = 51
        Width = 340
        Height = 47
        Caption = 'Scale Model'
        Columns = 3
        ItemIndex = 0
        Items.Strings = (
          'CSW'
          'RINSTRUN'
          'METTLER')
        TabOrder = 4
        OnClick = rgScaleTypeClick
      end
    end
  end
end

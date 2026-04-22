object frmPrinterSetup: TfrmPrinterSetup
  Left = 243
  Top = 162
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Printer Options'
  ClientHeight = 292
  ClientWidth = 533
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
    Width = 533
    Height = 292
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object btOk: TButton
      Left = 280
      Top = 232
      Width = 121
      Height = 53
      Caption = 'Ok'
      ModalResult = 1
      TabOrder = 0
    end
    object btCancel: TButton
      Left = 404
      Top = 232
      Width = 121
      Height = 53
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object GroupBox1: TGroupBox
      Left = 8
      Top = 8
      Width = 265
      Height = 217
      Caption = 'Printer Port'
      TabOrder = 2
      object Label1: TLabel
        Left = 8
        Top = 28
        Width = 66
        Height = 20
        Caption = 'Com Port'
      end
      object Label2: TLabel
        Left = 8
        Top = 60
        Width = 77
        Height = 20
        Caption = 'Baud Rate'
      end
      object Label3: TLabel
        Left = 8
        Top = 124
        Width = 39
        Height = 20
        Caption = 'Parity'
      end
      object Label4: TLabel
        Left = 8
        Top = 156
        Width = 65
        Height = 20
        Caption = 'Stop Bits'
      end
      object Label5: TLabel
        Left = 8
        Top = 92
        Width = 66
        Height = 20
        Caption = 'Data Bits'
      end
      object Label6: TLabel
        Left = 8
        Top = 188
        Width = 88
        Height = 20
        Caption = 'Flow Control'
      end
      object cbComPorts: TComboBox
        Left = 112
        Top = 20
        Width = 145
        Height = 28
        ItemHeight = 20
        TabOrder = 0
        Text = 'cbComPorts'
      end
      object cbBaudRate: TComboBox
        Left = 112
        Top = 52
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
      object cbParity: TComboBox
        Left = 112
        Top = 116
        Width = 145
        Height = 28
        ItemHeight = 20
        TabOrder = 2
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
        Top = 148
        Width = 145
        Height = 28
        ItemHeight = 20
        TabOrder = 3
        Text = 'cbStopBits'
        Items.Strings = (
          '1'
          '1.5'
          '2')
      end
      object cbDataBits: TComboBox
        Left = 112
        Top = 84
        Width = 145
        Height = 28
        ItemHeight = 20
        TabOrder = 4
        Text = 'cbDataBits'
        Items.Strings = (
          '5'
          '6'
          '7'
          '8')
      end
      object cbFlowControl: TComboBox
        Left = 112
        Top = 180
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
    object GroupBox2: TGroupBox
      Left = 280
      Top = 8
      Width = 245
      Height = 217
      Caption = 'Printer Settings'
      TabOrder = 3
      object Label7: TLabel
        Left = 12
        Top = 80
        Width = 108
        Height = 20
        Caption = 'Tickets To Print'
      end
      object Label8: TLabel
        Left = 10
        Top = 118
        Width = 122
        Height = 20
        Caption = 'No Of Mix Tickets'
      end
      object Label9: TLabel
        Left = 10
        Top = 46
        Width = 134
        Height = 20
        Caption = 'Tran. Label Format'
      end
      object Label10: TLabel
        Left = 10
        Top = 156
        Width = 121
        Height = 20
        Caption = 'Mix Label Format'
      end
      object meTicketsToPrint: TMaskEdit
        Left = 153
        Top = 76
        Width = 84
        Height = 28
        EditMask = '0;1;0'
        MaxLength = 1
        TabOrder = 0
        Text = ' '
        OnClick = meTicketsToPrintClick
      end
      object cbPrintTransactionTicket: TCheckBox
        Left = 8
        Top = 22
        Width = 225
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Print Transaction Ticket'
        TabOrder = 1
      end
      object cbCheckLabelTaken: TCheckBox
        Left = 12
        Top = 190
        Width = 225
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Check Label Taken'
        TabOrder = 2
      end
      object meNoOfMixTickets: TMaskEdit
        Left = 153
        Top = 114
        Width = 84
        Height = 28
        EditMask = '0;1;0'
        MaxLength = 1
        TabOrder = 3
        Text = ' '
        OnClick = meNoOfMixTicketsClick
      end
      object edTranLabelFormat: TEdit
        Left = 152
        Top = 42
        Width = 85
        Height = 28
        TabOrder = 4
        Text = 'A'
        OnClick = edTranLabelFormatClick
      end
      object edMixLabelFormat: TEdit
        Left = 152
        Top = 150
        Width = 85
        Height = 28
        TabOrder = 5
        Text = 'A'
        OnClick = edMixLabelFormatClick
      end
    end
  end
end

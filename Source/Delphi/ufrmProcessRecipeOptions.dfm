object frmProcessRecipeOptions: TfrmProcessRecipeOptions
  Left = 423
  Top = 212
  BorderIcons = [biSystemMenu]
  BorderStyle = bsNone
  Caption = 'frmProcessRecipeOptions'
  ClientHeight = 189
  ClientWidth = 522
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 20
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 522
    Height = 189
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object rxsbEnterManualTareWeight: TButton
      Left = 8
      Top = 68
      Width = 121
      Height = 53
      Caption = 'Enter Manual'#13#10'Tare Weight'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      Visible = False
      WordWrap = True
      OnClick = rxsbEnterManualTareWeightClick
    end
    object rxsbEnterManualWeight: TButton
      Left = 136
      Top = 68
      Width = 121
      Height = 53
      Caption = 'Enter Manual'#13#10'Weight'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      WordWrap = True
      OnClick = rxsbEnterManualWeightClick
    end
    object rxsbExit: TButton
      Left = 392
      Top = 128
      Width = 121
      Height = 53
      Caption = 'Exit Menu'
      ModalResult = 1
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
    end
    object rxsbPrintMixTicket: TButton
      Left = 8
      Top = 128
      Width = 121
      Height = 53
      Caption = 'Print Mix'#13#10'Ticket'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      WordWrap = True
      OnClick = rxsbPrintMixTicketClick
    end
    object rxsbPrintAllMixTickets: TButton
      Left = 136
      Top = 128
      Width = 121
      Height = 53
      Caption = 'Print All'#13#10'Mix Tickets'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      WordWrap = True
      OnClick = rxsbPrintAllMixTicketsClick
    end
    object rxsbDelayCurrentMix: TButton
      Left = 8
      Top = 8
      Width = 121
      Height = 53
      Caption = 'View /'#13#10'Change Mix'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      WordWrap = True
      OnClick = rxsbDelayCurrentMixClick
    end
    object rxsbAbortcurrentMix: TButton
      Left = 392
      Top = 8
      Width = 121
      Height = 53
      Caption = 'Abort '#13#10'Current Mix'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      WordWrap = True
      OnClick = rxsbAbortcurrentMixClick
    end
    object rxsbViewTransactions: TButton
      Left = 264
      Top = 8
      Width = 121
      Height = 53
      Caption = 'View Transactions'
      TabOrder = 7
      WordWrap = True
      OnClick = rxsbViewTransactionsClick
    end
    object rxsbChangeScale: TButton
      Left = 264
      Top = 68
      Width = 121
      Height = 53
      Caption = 'Change To Scale X'
      TabOrder = 8
      WordWrap = True
      OnClick = rxsbChangeScaleClick
    end
    object rxsbQA: TButton
      Left = 264
      Top = 128
      Width = 121
      Height = 53
      Caption = 'Quality Assurance'
      TabOrder = 9
      WordWrap = True
      OnClick = rxsbQAClick
    end
  end
  object rxsbEditBatchAndLot: TButton
    Left = 136
    Top = 8
    Width = 121
    Height = 53
    Caption = 'Edit Batch'#13#10'And Lot'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
    WordWrap = True
    OnClick = rxsbEditBatchAndLotClick
  end
end

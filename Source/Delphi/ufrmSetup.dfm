object frmSetup: TfrmSetup
  Left = 693
  Top = 292
  BorderStyle = bsDialog
  Caption = 'frmSetup'
  ClientHeight = 497
  ClientWidth = 634
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
    Width = 634
    Height = 497
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    DesignSize = (
      634
      497)
    object Label1: TLabel
      Left = 12
      Top = 12
      Width = 81
      Height = 20
      Caption = 'Machine ID'
    end
    object Label2: TLabel
      Left = 12
      Top = 38
      Width = 90
      Height = 20
      Caption = 'Run Number'
    end
    object Label6: TLabel
      Left = 12
      Top = 65
      Width = 109
      Height = 20
      Caption = 'Prep. Area filter'
    end
    object cbAllowManualWeight: TCheckBox
      Left = 339
      Top = 12
      Width = 242
      Height = 17
      Alignment = taLeftJustify
      Caption = 'Allow Manual Weight'
      TabOrder = 3
    end
    object edMachineID: TEdit
      Left = 175
      Top = 8
      Width = 121
      Height = 28
      TabOrder = 0
      Text = 'edMachineID'
      OnClick = edMachineIDClick
    end
    object edRunNumber: TEdit
      Left = 175
      Top = 34
      Width = 121
      Height = 28
      TabOrder = 1
      Text = 'edRunNumber'
      OnClick = edRunNumberClick
    end
    object btOk: TButton
      Left = 359
      Top = 420
      Width = 121
      Height = 53
      Anchors = [akRight, akBottom]
      Caption = 'Ok'
      ModalResult = 1
      TabOrder = 10
    end
    object btCancel: TButton
      Left = 487
      Top = 420
      Width = 121
      Height = 53
      Anchors = [akRight, akBottom]
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 11
    end
    object cbMixTicketsAnytime: TCheckBox
      Left = 339
      Top = 38
      Width = 242
      Height = 17
      Alignment = taLeftJustify
      Caption = 'Mix Tickets Anytime'
      TabOrder = 4
    end
    object gbOrderSelection: TGroupBox
      Left = 10
      Top = 97
      Width = 611
      Height = 63
      Caption = 'Order Selection'
      TabOrder = 6
      object Label3: TLabel
        Left = 333
        Top = 32
        Width = 120
        Height = 20
        Caption = 'Work Group filter'
      end
      object cbScanMixAfterOrderSelect: TCheckBox
        Left = 20
        Top = 32
        Width = 228
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Mix Ticket scan required'
        TabOrder = 0
      end
      object edWorkGroupFilter: TEdit
        Left = 461
        Top = 28
        Width = 121
        Height = 28
        TabOrder = 1
        Text = 'edWorkGroupFilter'
        OnClick = edWorkGroupFilterClick
      end
    end
    object gbbatchLot: TGroupBox
      Left = 10
      Top = 172
      Width = 611
      Height = 151
      Caption = 'Batch, Lot and Source entry'
      TabOrder = 7
      object Label4: TLabel
        Left = 18
        Top = 121
        Width = 210
        Height = 20
        Caption = 'Allow Source Barcode Length'
      end
      object cbUseLotNumbers: TCheckBox
        Left = 256
        Top = 135
        Width = 242
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Use Lot Numbers invis'
        TabOrder = 0
        Visible = False
      end
      object cbEnquireForLotNumber: TCheckBox
        Left = 18
        Top = 63
        Width = 230
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Enquire for Lot Number'
        TabOrder = 2
      end
      object cbEnquireForBatchNumber: TCheckBox
        Left = 18
        Top = 35
        Width = 230
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Enquire for Batch Number'
        TabOrder = 1
      end
      object cbUseOneScanOnly: TCheckBox
        Left = 330
        Top = 35
        Width = 243
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Use one scan only (L/B/SB)'
        TabOrder = 5
      end
      object cbCopyFopsTranSrcAsLot: TCheckBox
        Left = 330
        Top = 92
        Width = 243
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Copy FOPS Tran.Source as Lot'
        TabOrder = 7
      end
      object cbAllowSixDigitBarcode: TCheckBox
        Left = 18
        Top = 92
        Width = 230
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Allow 6 Digit Source Barcode'
        TabOrder = 3
      end
      object cbAllowKeyedBarcode: TCheckBox
        Left = 331
        Top = 63
        Width = 242
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Allow Keyed Barcode'
        TabOrder = 6
      end
      object edAllowBarcodeLength: TEdit
        Left = 235
        Top = 116
        Width = 43
        Height = 28
        TabOrder = 4
        Text = 'edAllowBarcodeLength'
        OnClick = edAllowBarcodeLengthClick
      end
      object cbAllowProductOverride: TCheckBox
        Left = 332
        Top = 121
        Width = 241
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Allow Product Override'
        TabOrder = 8
      end
    end
    object cbDisregardKeyIngredient: TCheckBox
      Left = 34
      Top = 430
      Width = 224
      Height = 17
      Alignment = taLeftJustify
      Caption = 'Disregard Key Ingredient invis'
      TabOrder = 9
      Visible = False
    end
    object gbFops: TGroupBox
      Left = 10
      Top = 335
      Width = 611
      Height = 74
      Caption = 'Interface to FOPS'
      TabOrder = 8
      object Label5: TLabel
        Left = 334
        Top = 24
        Width = 155
        Height = 20
        Caption = 'Batch Prefix for FOPS'
      end
      object cbSendIssueTransactions: TCheckBox
        Left = 19
        Top = 26
        Width = 230
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Send Issue Transactions'
        TabOrder = 0
      end
      object edBatchPrefixForFops: TEdit
        Left = 546
        Top = 19
        Width = 35
        Height = 28
        MaxLength = 2
        TabOrder = 2
        Text = '00'
        OnClick = edBatchPrefixForFopsClick
      end
      object cbAddMixesToFopsStock: TCheckBox
        Left = 20
        Top = 50
        Width = 229
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Add Mixes to FOPS Stock'
        TabOrder = 1
      end
    end
    object edPrepAreaFilter: TEdit
      Left = 175
      Top = 61
      Width = 121
      Height = 28
      TabOrder = 2
      OnClick = edPrepAreaFilterClick
    end
    object cbShowMixesDoneForArea: TCheckBox
      Left = 339
      Top = 67
      Width = 242
      Height = 17
      Alignment = taLeftJustify
      Caption = 'Show Mixes Done for Area'
      TabOrder = 5
    end
  end
end

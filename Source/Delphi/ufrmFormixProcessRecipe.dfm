object frmFormixProcessRecipe: TfrmFormixProcessRecipe
  Left = 401
  Top = 227
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'frmFormixProcessRecipe'
  ClientHeight = 600
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 20
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 600
    Align = alClient
    BevelInner = bvLowered
    BiDiMode = bdLeftToRight
    Color = 16776176
    Ctl3D = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentBiDiMode = False
    ParentBackground = False
    ParentCtl3D = False
    ParentFont = False
    TabOrder = 0
    object lbMessage: TLabel
      Left = 4
      Top = 276
      Width = 96
      Height = 25
      Caption = 'lbMessage'
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object lbRemainingWeight: TLabel
      Left = 182
      Top = 316
      Width = 326
      Height = 48
      Alignment = taRightJustify
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -40
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 520
      Top = 324
      Width = 110
      Height = 19
      Caption = 'Mix Completion'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object plOrderDetails: TPanel
      Left = 4
      Top = 52
      Width = 473
      Height = 221
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      OnClick = plOrderDetailsClick
      object Label3: TLabel
        Left = 8
        Top = 8
        Width = 40
        Height = 20
        Caption = 'Order'
        OnClick = plOrderDetailsClick
      end
      object Label4: TLabel
        Left = 8
        Top = 40
        Width = 50
        Height = 20
        Caption = 'Recipe'
        OnClick = plOrderDetailsClick
      end
      object Label5: TLabel
        Left = 260
        Top = 8
        Width = 61
        Height = 20
        Caption = 'Mix Type'
        OnClick = plOrderDetailsClick
      end
      object Label6: TLabel
        Left = 8
        Top = 154
        Width = 51
        Height = 20
        Caption = 'Mix No.'
        OnClick = plOrderDetailsClick
      end
      object Label7: TLabel
        Left = 8
        Top = 106
        Width = 68
        Height = 20
        Caption = 'Order Wt.'
        OnClick = plOrderDetailsClick
      end
      object Label8: TLabel
        Left = 8
        Top = 188
        Width = 51
        Height = 20
        Caption = 'Mix Wt.'
        OnClick = plOrderDetailsClick
      end
      object Label1: TLabel
        Left = 260
        Top = 40
        Width = 40
        Height = 20
        Caption = 'Mixes'
      end
      object DBEdit1: TDBEdit
        Left = 80
        Top = 4
        Width = 121
        Height = 28
        DataField = 'Order'
        DataSource = dsMemOrderHeader
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 0
        OnClick = plOrderDetailsClick
      end
      object DBEdit2: TDBEdit
        Left = 80
        Top = 36
        Width = 121
        Height = 28
        DataField = 'Recipe'
        DataSource = dsMemOrderHeader
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 1
        OnClick = plOrderDetailsClick
      end
      object DBEdit3: TDBEdit
        Left = 328
        Top = 4
        Width = 121
        Height = 28
        DataField = 'MixTypeDesc'
        DataSource = dsMemOrderHeader
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 2
        OnClick = plOrderDetailsClick
      end
      object DBEdit4: TDBEdit
        Left = 80
        Top = 151
        Width = 121
        Height = 28
        DataField = 'MixNoDesc'
        DataSource = dsMemOrderHeader
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 3
        OnClick = plOrderDetailsClick
      end
      object DBEdit5: TDBEdit
        Left = 80
        Top = 69
        Width = 369
        Height = 28
        DataField = 'Description'
        DataSource = dsMemOrderHeader
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 4
        OnClick = plOrderDetailsClick
      end
      object DBEdit6: TDBEdit
        Left = 80
        Top = 102
        Width = 369
        Height = 28
        DataField = 'OrderWtDesc'
        DataSource = dsMemOrderHeader
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 5
        OnClick = plOrderDetailsClick
      end
      object DBEdit7: TDBEdit
        Left = 80
        Top = 184
        Width = 221
        Height = 28
        DataField = 'CurrentMixDesc'
        DataSource = dsMemOrderHeader
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 6
        OnChange = DBEdit7Change
        OnClick = plOrderDetailsClick
      end
      object dbcbxMixQADone: TDBCheckBox
        Left = 369
        Top = 190
        Width = 79
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Mix QA'
        DataField = 'CurrentMixQADone'
        DataSource = dsMemOrderHeader
        ReadOnly = True
        TabOrder = 7
        ValueChecked = 'True'
        ValueUnchecked = 'False'
        OnMouseDown = dbcbxMixQADoneMouseDown
      end
      object DBEdit8: TDBEdit
        Left = 328
        Top = 37
        Width = 121
        Height = 28
        DataField = 'MixesDesc'
        DataSource = dsMemOrderHeader
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 8
      end
    end
    object plMixDetails: TPanel
      Left = 4
      Top = 52
      Width = 473
      Height = 221
      Color = clWhite
      ParentBackground = False
      TabOrder = 4
      OnClick = plMixDetailsClick
      object Label14: TLabel
        Left = 244
        Top = 132
        Width = 47
        Height = 20
        Caption = 'Lot No'
        OnClick = plMixDetailsClick
      end
      object Label15: TLabel
        Left = 244
        Top = 161
        Width = 94
        Height = 20
        Caption = 'Hazard Code'
        Visible = False
        OnClick = plMixDetailsClick
      end
      object Label16: TLabel
        Left = 6
        Top = 192
        Width = 72
        Height = 20
        Caption = 'Source ID'
      end
      object lblTemperature: TLabel
        Left = 7
        Top = 161
        Width = 59
        Height = 20
        Caption = 'Temp. C'
      end
      object jvpOrderDetails: TJvCaptionPanel
        Left = 2
        Top = 6
        Width = 465
        Height = 127
        AutoDrag = False
        Buttons = []
        BorderStyle = bsNone
        CaptionPosition = dpTop
        CaptionFont.Charset = DEFAULT_CHARSET
        CaptionFont.Color = clWhite
        CaptionFont.Height = -13
        CaptionFont.Name = 'MS Sans Serif'
        CaptionFont.Style = [fsBold]
        Color = clWhite
        OutlookLook = False
        TabOrder = 0
        object Label9: TLabel
          Left = 4
          Top = 36
          Width = 72
          Height = 20
          Caption = 'Ingredient'
          OnClick = plMixDetailsClick
        end
        object Label10: TLabel
          Left = 4
          Top = 68
          Width = 69
          Height = 20
          Caption = 'Container'
          OnClick = plMixDetailsClick
        end
        object Label11: TLabel
          Left = 4
          Top = 96
          Width = 51
          Height = 20
          Caption = 'Mix No.'
          OnClick = plMixDetailsClick
        end
        object Label12: TLabel
          Left = 240
          Top = 68
          Width = 64
          Height = 20
          Caption = 'Requires'
          OnClick = plMixDetailsClick
        end
        object Label13: TLabel
          Left = 240
          Top = 96
          Width = 70
          Height = 20
          Caption = 'Tolerance'
          OnClick = plMixDetailsClick
        end
        object edContainerDesc: TEdit
          Left = 80
          Top = 64
          Width = 157
          Height = 28
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -16
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 0
          Text = 'edContainerDesc'
          OnClick = plMixDetailsClick
        end
        object edRequires: TEdit
          Left = 312
          Top = 64
          Width = 145
          Height = 28
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -16
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 1
          Text = 'edRequires'
          OnClick = plMixDetailsClick
        end
        object edMixNumber: TEdit
          Left = 80
          Top = 92
          Width = 157
          Height = 28
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -16
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 2
          Text = 'edMixNumber'
          OnClick = plMixDetailsClick
        end
        object edTolerance: TEdit
          Left = 312
          Top = 92
          Width = 145
          Height = 28
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -16
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 3
          Text = 'edTolerance'
          OnClick = plMixDetailsClick
        end
        object edProductCode: TEdit
          Left = 80
          Top = 32
          Width = 85
          Height = 28
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -16
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 4
          Text = 'edProductCode'
          OnClick = plMixDetailsClick
        end
        object edProductDesc: TEdit
          Left = 168
          Top = 32
          Width = 289
          Height = 28
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -16
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 5
          Text = 'edProductDesc'
          OnClick = plMixDetailsClick
        end
      end
      object edLotNo: TEdit
        Left = 314
        Top = 128
        Width = 143
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 1
        Text = 'edLotNo'
        OnClick = plMixDetailsClick
      end
      object edHazardCode: TEdit
        Left = 344
        Top = 157
        Width = 113
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 2
        Text = 'edHazardCode'
        Visible = False
        OnClick = plMixDetailsClick
      end
      object edSourceID: TEdit
        Left = 83
        Top = 189
        Width = 374
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 3
        Text = 'edSourceID'
      end
      object edTemperature: TEdit
        Left = 83
        Top = 157
        Width = 70
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
        Text = 'edTemperature'
      end
    end
    object plProducts: TPanel
      Left = 4
      Top = 380
      Width = 795
      Height = 181
      BevelOuter = bvNone
      Color = 16776176
      TabOrder = 2
      object btbnLeft: TBitBtn
        Left = 1
        Top = 1
        Width = 122
        Height = 53
        TabOrder = 5
        OnClick = btbnLeftClick
        Glyph.Data = {
          A60C0000424DA60C000000000000760000002800000076000000340000000100
          040000000000300C000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00FFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFF909FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFE000AFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD0000
          00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF9000000EFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDC000000009FFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF90000000000AFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFDC0000000000009FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFF900000000000000EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFF
          E00000000000000009FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFDF9000000000
          000000000EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFF9C0000000000000000000
          00BFFFBFFFBFFFBFFFBFFFBFFFBFFBBFFBBFFBBFFBFFFBFFFBFFFBFFFBFFFBFF
          FBFFFBFFFF00FFFFFFFFFFFFFFFFFFFFFED00000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0F00FFFFFFFFFFFFFFFFFFFFF000000000000000000000000000000000000000
          000000000000000000000000000000000000000000000000000000000F00FFFF
          FFFFFFFFFFFFFED0000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000F00FFFFFFFFFFFF
          FFFBF00000000000000000000000000000000000000000000000000000000000
          00000000000000000000000000000000000000000F00FFFFFFFFFFFFFED00000
          0000000000000000000000000000000000000000000000000000000000000000
          000000000000000000000000000000000F00FFFFFFFFFFFBF000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000F00FFFFFFFFFE90000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          00000000000000000F00FFFFFFF9E00000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          000000000F00FFFFFE9000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0F00FFF9E0000000000000000000000000000000000000000000000000000000
          000000000000000000000000000000000000000000000000000000000F00FE90
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000F00F00000000000
          0000000000000000000000000000000000000000000000000000000000000000
          00000000000000000000000000000000000000000F00F0000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          000000000000000000000000000000000F00F000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000F00F00000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          00000000000000000F00F9E00000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          000000000F00FFFE900000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0F00FFFFF9E00000000000000000000000000000000000000000000000000000
          000000000000000000000000000000000000000000000000000000000F00FFFF
          FFFED00000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000F00FFFFFFFFFBF0
          0000000000000000000000000000000000000000000000000000000000000000
          00000000000000000000000000000000000000000F00FFFFFFFFFFFED0000000
          0000000000000000000000000000000000000000000000000000000000000000
          000000000000000000000000000000000F00FFFFFFFFFFFFF9E0000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000F00FFFFFFFFFFFFFFFED0000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          00000000000000000F00FFFFFFFFFFFFFFFFFBF0000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          000000000F00FFFFFFFFFFFFFFFFFFFE90000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0F00FFFFFFFFFFFFFFFFFFFFFBE0000000000000000000000000000000000000
          000000000000000000000000000000000000000000000000000000000F00FFFF
          FFFFFFFFFFFFFFFFFFFE9000000000000000000009ECDFEDFFEDFFEDFFEDFFED
          FFEDFECDFECDFECDFECDFEDFFEDFFEDFFEDFFEDFFEDFFEDFFF00FFFFFFFFFFFF
          FFFFFFFFFFFFFFE000000000000000000EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFF
          FFFFFFFF900000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFE00000000000000AFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD9000
          0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000
          0EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD9000000009FFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA000000AFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD900009FFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC00EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFF900FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFF00}
        Margin = 1
      end
      object btbtnRight: TBitBtn
        Left = 670
        Top = 1
        Width = 122
        Height = 53
        TabOrder = 6
        OnClick = btbtnRightClick
        Glyph.Data = {
          A60C0000424DA60C000000000000760000002800000076000000340000000100
          040000000000300C000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00FFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00EFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE00009FFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFF000000EFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFF00000000BFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFF0000000000EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFE000000000000BFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFB0000
          0000000000EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000
          0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000009FB
          FFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE0000000000000000000ABEFFFFFF
          FFFFFFFFFFFFFFFFFF00FFFBFFFBFFFBFFFBFFFBFFFBFFFBFFFBFFFBFFBBFFBB
          FFBFFFBFFFBFFFBFFFBFFFBFFFBF0000000000000000000000FFFFFFFFFFFFFF
          FFFFFFFFFF00F000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000EDFFFFFFFFFFFFFFFFFFF
          FF00F00000000000000000000000000000000000000000000000000000000000
          00000000000000000000000000000000000009FFFFFFFFFFFFFFFFFFFF00F000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000EDFFFFFFFFFFFFFFFFF00F00000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000BFFFFFFFFFFFFFFFF00F0000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000EDFFFFFFFFFFFFF00F000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000BFFFFFFFFFFFF00F00000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000E9FFFFFFFFF00F0000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          09EFFFFFFF00F000000000000000000000000000000000000000000000000000
          00000000000000000000000000000000000000000000000000000000000E9FFF
          FF00F00000000000000000000000000000000000000000000000000000000000
          000000000000000000000000000000000000000000000000000009EFFF00F000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000009F00F00000000000
          0000000000000000000000000000000000000000000000000000000000000000
          00000000000000000000000000000000000000000F00F0000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          000000000000000000000000000000000F00F000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000F00F00000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          00000000000000000F00F0000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          00000009EF00F000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000E9F
          FF00F00000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000009EFFFFF00F000
          0000000000000000000000000000000000000000000000000000000000000000
          00000000000000000000000000000000000000000EDFFFFFFF00F00000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000BFFFFFFFFFF00F0000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          000000000000000000000EDFFFFFFFFFFF00F000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          000000000009EFFFFFFFFFFFFF00F00000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0EDFFFFFFFFFFFFFFF00F0000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000BFFFFFFFF
          FFFFFFFFFF00F000000000000000000000000000000000000000000000000000
          000000000000000000000000000000000000000000000EFFFFFFFFFFFFFFFFFF
          FF00F00000000000000000000000000000000000000000000000000000000000
          000000000000000000000000000000000009FFFFFFFFFFFFFFFFFFFFFF00FFFE
          DFFEDFFEDFFEDFFEDFFEDFFCDFFCDFECDFECDFECDFECDFEDFFEDFFEDFFEDFFED
          FFED000000000000000000000EDFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFB0000
          0000000000000009FFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000
          00000EFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000FFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE00000000000000FFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000FFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFF00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFE000000EFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000
          BFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00EFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFF00}
        Layout = blGlyphRight
        Margin = 1
      end
      object btTare: TJvImgBtn
        Left = 266
        Top = 1
        Width = 120
        Height = 53
        Caption = 'Semi Auto Tare'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
        Visible = False
        OnClick = btTareClick
        HotTrackFont.Charset = DEFAULT_CHARSET
        HotTrackFont.Color = clWindowText
        HotTrackFont.Height = -16
        HotTrackFont.Name = 'Arial'
        HotTrackFont.Style = []
        Images = ImageList1
      end
      object btPartWeigh: TButton
        Left = 398
        Top = 1
        Width = 121
        Height = 53
        Caption = 'Part Weigh'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        Visible = False
        OnClick = btPartWeighClick
      end
      object btOptions: TButton
        Left = 531
        Top = 1
        Width = 120
        Height = 53
        Caption = 'Options'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = btOptionsClick
      end
      object btExit: TButton
        Left = 133
        Top = 1
        Width = 120
        Height = 53
        Caption = 'Exit'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = btExitClick
      end
      object plIngredientList: TPanel
        Left = 0
        Top = 53
        Width = 795
        Height = 129
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
      end
    end
    object Panel2: TPanel
      Left = 4
      Top = 4
      Width = 473
      Height = 41
      ParentBackground = False
      TabOrder = 0
      object lbBatchNo: TLabel
        Left = 8
        Top = 8
        Width = 70
        Height = 20
        Caption = 'Batch No:'
      end
      object lbUser: TLabel
        Left = 204
        Top = 8
        Width = 38
        Height = 20
        Caption = 'User:'
      end
      object lbTime: TLabel
        Left = 376
        Top = 8
        Width = 46
        Height = 20
        Caption = 'lbTime'
      end
    end
    object plScaleLabel: TPanel
      Left = 520
      Top = 8
      Width = 261
      Height = 45
      Color = clBlack
      ParentBackground = False
      TabOrder = 3
      object lbScaleWt: TLabel
        Left = 1
        Top = 5
        Width = 259
        Height = 43
        Alignment = taCenter
        AutoSize = False
        Caption = 'lbScaleWt'
        Color = clBlack
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -27
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
    end
    object DBGrid1: TDBGrid
      Left = 292
      Top = 564
      Width = 493
      Height = 97
      DataSource = DataSource1
      TabOrder = 5
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -16
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Visible = False
      Columns = <
        item
          Expanded = False
          FieldName = 'ProductCode'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'MinTol'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'MaxTol'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'WtRemaining'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'WeighsPerContainer'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'WeightIncrements'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'LineNo'
          Visible = True
        end>
    end
    object plAnalog: TPanel
      Left = 520
      Top = 52
      Width = 261
      Height = 261
      Color = clBlack
      ParentBackground = False
      TabOrder = 6
      OnClick = plAnalogClick
    end
    object plTotalMix: TPanel
      Left = 520
      Top = 344
      Width = 261
      Height = 25
      BevelOuter = bvNone
      BorderStyle = bsSingle
      Color = clWhite
      ParentBackground = False
      TabOrder = 7
      object plTotalMixValue: TPanel
        Left = 0
        Top = 0
        Width = 0
        Height = 21
        Align = alLeft
        Color = clNavy
        ParentBackground = False
        TabOrder = 0
      end
    end
    object Button1: TButton
      Left = 12
      Top = 328
      Width = 75
      Height = 25
      Caption = 'Button1'
      TabOrder = 8
      Visible = False
      OnClick = Button1Click
    end
  end
  object tmClockAndLineRefresh: TTimer
    Enabled = False
    OnTimer = tmClockAndLineRefreshTimer
    Left = 80
    Top = 560
  end
  object dsMemOrderHeader: TDataSource
    DataSet = frmFormixMain.rmdOrderList
    Left = 112
    Top = 560
  end
  object rmdIngredients: TRxMemoryData
    Active = True
    FieldDefs = <
      item
        Name = 'ProductCode'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'ProductDesc'
        DataType = ftString
        Size = 30
      end
      item
        Name = 'MinTol'
        DataType = ftFloat
      end
      item
        Name = 'MaxTol'
        DataType = ftFloat
      end
      item
        Name = 'WtRemaining'
        DataType = ftFloat
      end
      item
        Name = 'WeighsPerContainer'
        DataType = ftInteger
      end
      item
        Name = 'WeightIncrements'
        DataType = ftFloat
      end
      item
        Name = 'LineNo'
        DataType = ftInteger
      end
      item
        Name = 'NoTare'
        DataType = ftBoolean
      end
      item
        Name = 'IsComplete'
        DataType = ftBoolean
      end
      item
        Name = 'MixDesc'
        DataType = ftString
        Size = 30
      end
      item
        Name = 'CompleteLabel'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'WtRemainingLabel'
        DataType = ftString
        Size = 30
      end
      item
        Name = 'WtReqdByMix'
        DataType = ftFloat
      end>
    Left = 144
    Top = 560
    object rmdIngredientsProductCode: TStringField
      FieldName = 'ProductCode'
      Size = 10
    end
    object rmdIngredientsProductDesc: TStringField
      FieldName = 'ProductDesc'
      Size = 30
    end
    object rmdIngredientsMinTol: TFloatField
      FieldName = 'MinTol'
    end
    object rmdIngredientsMaxTol: TFloatField
      FieldName = 'MaxTol'
    end
    object rmdIngredientsWtRemaining: TFloatField
      FieldName = 'WtRemaining'
    end
    object rmdIngredientsWeighsPerContainer: TIntegerField
      FieldName = 'WeighsPerContainer'
    end
    object rmdIngredientsWeightIncrements: TFloatField
      FieldName = 'WeightIncrements'
    end
    object rmdIngredientsLineNo: TIntegerField
      FieldName = 'LineNo'
    end
    object rmdIngredientsNoTare: TBooleanField
      FieldName = 'NoTare'
    end
    object rmdIngredientsIsComplete: TBooleanField
      FieldName = 'IsComplete'
    end
    object rmdIngredientsMixDesc: TStringField
      FieldName = 'MixDesc'
      Size = 30
    end
    object rmdIngredientsCompleteLabel: TStringField
      FieldName = 'CompleteLabel'
    end
    object rmdIngredientsWtRemainingLabel: TStringField
      FieldName = 'WtRemainingLabel'
      Size = 30
    end
    object rmdIngredientsWtReqdByMix: TFloatField
      FieldName = 'WtReqdByMix'
    end
  end
  object DataSource1: TDataSource
    DataSet = rmdIngredients
    Left = 176
    Top = 560
  end
  object tmTareFlasher: TTimer
    Enabled = False
    Interval = 500
    OnTimer = tmTareFlasherTimer
    Left = 240
    Top = 561
  end
  object ImageList1: TImageList
    Left = 260
    Top = 560
    Bitmap = {
      494C010102000400040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000001000000001002000000000000010
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000100000000100010000000000800000000000000000000000
      000000000000000000000000FFFFFF00FFFFFFFF00000000FFDFFBFF00000000
      FFCFF3FF00000000FFCFF3FF000000000007E000000000000003C00000000000
      0001800000000000000000000000000000000000000000000001800000000000
      0003C000000000000007E00000000000FFCFF3FF00000000FFCFF3FF00000000
      FFDFFBFF00000000FFFFFFFF0000000000000000000000000000000000000000
      000000000000}
  end
end

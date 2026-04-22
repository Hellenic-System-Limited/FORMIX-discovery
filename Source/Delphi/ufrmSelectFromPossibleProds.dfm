object frmSelectFromPossibleProds: TfrmSelectFromPossibleProds
  Left = 645
  Top = 280
  BorderIcons = [biMaximize]
  BorderStyle = bsSingle
  Caption = 'Select from possible Products'
  ClientHeight = 391
  ClientWidth = 609
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 609
    Height = 391
    Align = alClient
    BevelOuter = bvNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object btnOk: TButton
      Left = 452
      Top = 320
      Width = 121
      Height = 53
      Caption = 'OK'
      ModalResult = 1
      TabOrder = 1
    end
    object btnCancel: TButton
      Left = 292
      Top = 320
      Width = 121
      Height = 53
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 2
    end
    object DBGrid1: TDBGridHSL
      Left = 0
      Top = 0
      Width = 609
      Height = 305
      Align = alTop
      DataSource = dsPossibleProducts
      DefaultDrawing = True
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -16
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Controls = <>
      ScrollBars = ssHorizontal
      EditColor = clWindow
      DefaultRowHeight = 40
      RowColor1 = 12255087
      RowColor2 = clWindow
      HighlightColor = clHighlight
      ImageHighlightColor = clWindow
      HighlightFontColor = clHighlightText
      HotTrackColor = clNavy
      LockedCols = 0
      LockedFont.Charset = DEFAULT_CHARSET
      LockedFont.Color = clWindowText
      LockedFont.Height = -11
      LockedFont.Name = 'MS Sans Serif'
      LockedFont.Style = []
      LockedColor = clGray
      ExMenuOptions = [exAutoSize, exAutoWidth, exDisplayBoolean, exDisplayImages, exDisplayMemo, exDisplayDateTime, exShowTextEllipsis, exShowTitleEllipsis, exFullSizeMemo, exAllowRowSizing, exCellHints, exMultiLineTitles, exUseRowColors, exFixedColumns, exPrintGrid, exPrintDataSet, exExportGrid, exSelectAll, exUnSelectAll, exQueryByForm, exSortByForm, exMemoInplaceEditors, exCustomize, exSearchMode, exSaveLayout, exLoadLayout]
      MaskedColumnDrag = True
      ValueChecked = 1
      ValueUnChecked = 0
      Columns = <
        item
          Expanded = False
          FieldName = 'Code'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'Description'
          Width = 477
          Visible = True
        end>
    end
  end
  object dsPossibleProducts: TDataSource
    Left = 320
    Top = 104
  end
end

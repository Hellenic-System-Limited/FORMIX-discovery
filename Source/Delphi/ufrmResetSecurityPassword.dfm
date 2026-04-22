object frmResetSecurityPassword: TfrmResetSecurityPassword
  Left = 611
  Top = 318
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsNone
  Caption = 'Reset Password'
  ClientHeight = 319
  ClientWidth = 638
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010001002020100000000000E80200001600000028000000200000004000
    0000010004000000000080020000000000000000000000000000000000000000
    0000000080000080000000808000800000008000800080800000C0C0C0008080
    80000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000FFFFFFFFFF00000000000000000000FFFFFFFFFFFFFF0000000000000
    000FFFFFFFFFFFFFFFFFF0000000000000FFFFFFFFFFFFFFFFFFF00000000000
    0FFFFFFFFFFF00000FFFFFF000000000FFFFFFFFFFF00FFFF00FFFFF0000000F
    FFFFFFFFFFF0F000FF0FFFFF0000000FFFFFFFFFFFF0F0FF0F00FFFFF00000FF
    FFFFFFFFFFF0FFFF0FF0FFFFF00000FFFFFFFFFFFFF0FFF00FF0FFFFFF000FFF
    FFFFFFFFFFF0F00FFF00FFFFFF000FFFFFFFFFFFFFF000FFF000FFFFFFF00FFF
    FFFFFFFFFFFF00000000FFFFFFF00FFFFFF00FFFFFFFFFF00000FFFFFFF00FFF
    FFF000000FFFFFFFFF00FFFFFFF00FFFFFF000FFF00FFFFFFF00FFFFFFF00FFF
    FFF000FFFF00FFFFFF00FFFFFFF00FFFFFF0000FFFF000FF000FFFFFFFF00FFF
    FFF0000FFFFFF000000FFFFFFFF000FFFFF000000FFFFFF00FFFFFFFFF0000FF
    FFF00000000FFFFFFFFFFFFFF000000FFFF00000000FFFFFFFFFFFFFF000000F
    FFF000000000FFFFFFFFFFFF00000000FFF000000000FFFFFFFFFFF000000000
    0FF000000000FFFFFFFFFF000000000000F000000000FFFFFFFFF00000000000
    000000000000FFFFFFFF00000000000000000000000FFFFFFF00000000000000
    0000000000FFFFFF00000000000000000000000000000000000000000000FFFF
    FFFFFFFFFFFFFFE007FFFF8001FFFE00007FFC00007FF800F81FF001860FE001
    720FE0014B07C0010907C0011903800163038001C7018000FF0181801F0181F8
    030181C6030181C3030181E1CE0181E07E01C1F81803C1FE0007E1FE0007E1FF
    000FF1FF001FF9FF003FFDFF007FFFFF00FFFFFE03FFFFFC0FFFFFFFFFFF}
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 20
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 638
    Height = 319
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object Label1: TLabel
      Left = 52
      Top = 8
      Width = 97
      Height = 20
      Caption = 'Old Password'
    end
    object Label2: TLabel
      Left = 236
      Top = 8
      Width = 104
      Height = 20
      Caption = 'New Password'
      Enabled = False
    end
    object Label3: TLabel
      Left = 416
      Top = 8
      Width = 163
      Height = 20
      Caption = 'Confirm New Password'
      Enabled = False
    end
    object edPassword: TEdit
      Left = 52
      Top = 28
      Width = 169
      Height = 28
      PasswordChar = '*'
      TabOrder = 0
      OnChange = edPasswordChange
      OnKeyDown = edPasswordKeyDown
    end
    object OkButton: TButton
      Left = 384
      Top = 260
      Width = 121
      Height = 53
      Caption = 'Ok'
      TabOrder = 3
      OnClick = OkButtonClick
    end
    object CancelButton: TButton
      Left = 512
      Top = 260
      Width = 121
      Height = 53
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 4
    end
    object edNewPassword: TEdit
      Left = 236
      Top = 28
      Width = 169
      Height = 28
      Enabled = False
      PasswordChar = '*'
      TabOrder = 1
      OnKeyDown = edPasswordKeyDown
    end
    object edConfirmPassword: TEdit
      Left = 416
      Top = 28
      Width = 169
      Height = 28
      Enabled = False
      PasswordChar = '*'
      TabOrder = 2
      OnKeyDown = edPasswordKeyDown
    end
    object HSLAZKeyboard1: THSLAZKeyboard
      Left = 4
      Top = 60
      Width = 481
      Height = 193
      Caption = 'HSLAZKeyboard1'
      TabOrder = 5
    end
    object HSLNumericKeyboard1: THSLNumericKeyboard
      Left = 488
      Top = 60
      Width = 145
      Height = 193
      Caption = 'HSLNumericKeyboard1'
      TabOrder = 6
    end
  end
end

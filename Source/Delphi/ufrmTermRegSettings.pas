unit ufrmTermRegSettings;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, Grids, DBGrids, ExtCtrls, StdCtrls;

type
  TfrmTermRegSettings = class(TForm)
    Panel1: TPanel;
    DBGrid1: TDBGrid;
    dsTermRegSettings: TDataSource;
    btnOk: TButton;
    btnEditValue: TButton;
    pnlButtons: TPanel;
    procedure btnEditValueClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;


implementation
uses udmFormix, udmFormixBase, ufrmFormixStdEntry;
{$R *.dfm}

procedure TfrmTermRegSettings.btnEditValueClick(Sender: TObject);
var
  WasEnteredOk: Boolean;
  TempValueStr : string;
  RegFound : boolean;
begin
  if dmFormix.rxmTermRegSettingsSettingNo.AsInteger = Ord(r_Password) then
    EXIT;
  {Edit the value stored in the database, not the value calc using default value.
   i.e. dont use GetRegStringDef().
  }
  TempValueStr := dmFormix.GetRegString(dmFormix.GetPvtblRegFolderNameForRxmTermRegSetting,
                                        dmFormix.rxmTermRegSettingsTag.AsString,
                                        RegFound);

  TempValueStr := TfrmFormixStdEntry.GetStdStringEntry(
                            dmFormix.rxmTermRegSettingsDescription.AsString{UseFormCaption},
                            dmFormix.rxmTermRegSettingsTag.AsString{UseLabelCaption},
                            dmFormix.rxmTermRegSettingsValue.Size,
                            WasEnteredOk{var},
                            false{IsPassword},
                            TempValueStr{DefaultVal});
  if WasEnteredOk then
  begin
    dmFormix.SetTermRegString(TRegistrySettingNo(dmformix.rxmTermRegSettingsSettingNo.AsInteger),
                              TempValueStr);
    dmFormix.RefreshValueOnCurrRxmTermRegSettings;
  end;
end;

end.

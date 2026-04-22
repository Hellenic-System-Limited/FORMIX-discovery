unit ufrmFormixDatePick;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls;

type
  TfrmFormixDatePick = class(TForm)
    Button1: TButton;
    btCancel: TButton;
    Label1: TLabel;
    DatePicker: TMonthCalendar;
  private
    { Private declarations }
  public
    { Public declarations }
    class function GetDateStr(const UseFormCaption, UseLabelCaption: String;
                              var   WasEnteredOk: Boolean;
                              StartWithDate : TDate): String;
  end;


implementation

{$R *.dfm}
class function TfrmFormixDatePick.GetDateStr(const UseFormCaption, UseLabelCaption: String;
                                                 var   WasEnteredOk: Boolean;
                                                 StartWithDate : TDate): String;
var
  frmFormixDatePick: TfrmFormixDatePick;
begin
 Result := '';
 WasEnteredOk := false;
 frmFormixDatePick := TfrmFormixDatePick.Create(nil);
 with frmFormixDatePick do
  begin
   Caption         := UseFormCaption;
   Label1.Caption  := UseLabelCaption;
   DatePicker.Date := StartWithDate;
   ShowModal;
   if ModalResult = mrOk then
   begin
     WasEnteredOk := true;
     Result := FormatDateTime('dd/mm/yyyy',DatePicker.Date);
   end;
   Free;
  end;
end;


end.

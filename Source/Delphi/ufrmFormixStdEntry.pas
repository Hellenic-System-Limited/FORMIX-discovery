unit ufrmFormixStdEntry;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, HSLAZKeyboard, StdCtrls, ExtCtrls, Mask, ToolEdit, CurrEdit,
  ComCtrls;

type
  TfrmFormixStdEntry = class(TForm)
    Panel1: TPanel;
    lbStd: TLabel;
    edStd: TEdit;
    HSLAZKeyboard1: THSLAZKeyboard;
    HSLNumericKeyboard1: THSLNumericKeyboard;
    btOk: TButton;
    btCancel: TButton;
    rxcalcEdit1: TRxCalcEdit;
    btnShowKeyboard: TButton;
    edTime: TDateTimePicker;
    Label1: TLabel;
    procedure edStdKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edStdKeyPress(Sender: TObject; var Key: Char);
    procedure btOkClick(Sender: TObject);
    procedure btnShowKeyboardClick(Sender: TObject);
  private
    { Private declarations }
    fKeyboardAvailable : boolean;
    procedure SetKeyboardAvailable(Value : boolean);
  public
    { Public declarations }
    class function GetStdStringEntry(const UseFormCaption, UseLabelCaption: String;
                                     MaxLength: Integer;
                                     var WasEnteredOk: Boolean;
                                     IsPassword: Boolean=FALSE;
                                     DefaultVal: String='';
                                     MustEnterVal: Boolean=FALSE;
                                     PasswordTheKeyboard: boolean=FALSE): String;
    class function GetIntegerNumStr(const UseFormCaption, UseLabelCaption: String;
                                    MaxLength: Integer;
                                    var WasEnteredOk: Boolean;
                                    StartWithValue : integer;
                                    AllowMinus : boolean): String;
    class function GetStdNumericEntry(const UseFormCaption, UseLabelCaption: String;
                                      MaxLength: Integer): String;
//    class function GetStdFloatEntry(UseFormCaption, UseLabelCaption: String; FloatStyle: String): String;
    class function GetFloatNumStr(const UseFormCaption, UseLabelCaption: String;
                                  MaxLength, DecimalPlaces : integer;
                                  var WasEnteredOk: Boolean;
                                  StartWithValue : double) : string;
    class function GetTimeStr(const UseFormCaption, UseLabelCaption: String;
                              var WasEnteredOk: Boolean;
                              StartWithValue : TTime): String;
  property KeyboardAvailable : boolean read fKeyboardAvailable write SetKeyboardAvailable;
  end;

function GetTerminalPassword: Boolean;

implementation
uses uStdUtl,udmFormixBase,udmFormix, uFopsLib, ufrmFormixMain{needs scaleName};

{$R *.dfm}

{ TfrmFormixScalePassword }

procedure TfrmFormixStdEntry.edStdKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
 if (Key = VK_RETURN) or
    (Key = Ord(#13)) or
    (Key = Ord(#10)) then
  begin
   ModalResult := mrOk;
  end;
end;

procedure SetStayOnTopIfNecessary(AForm : TForm);
begin
  if  Assigned(Application.MainForm)
  and (Application.MainForm.FormStyle = fsStayOnTop) then //assume calling window is a "stay-on-top"
    AForm.FormStyle := fsStayOnTop; {so dialog doesnt get hidden by stay on top window}
end;

class function TfrmFormixStdEntry.GetIntegerNumStr(const UseFormCaption, UseLabelCaption: String;
                                                   MaxLength: Integer;
                                                   var WasEnteredOk: Boolean;
                                                   StartWithValue : integer;
                                                   AllowMinus : boolean): String;
var
  frmFormixStdEntry: TfrmFormixStdEntry;
begin
 Result := IntToStr(StartWithValue);
 WasEnteredOk := false;
 frmFormixStdEntry := TfrmFormixStdEntry.Create(Application);
 SetStayOnTopIfNecessary(frmFormixStdEntry);
 with frmFormixStdEntry do
  begin
   if AllowMinus then
     HSLAZKeyboard1.SetButtonsToFunctionStyle // minus key
   else
     HSLAZKeyboard1.Visible := false;
   edStd.Visible   := FALSE;
   Caption         := UseFormCaption;
   lbStd.Caption   := UseLabelCaption;
   rxCalcEdit1.Value := StartWithValue;
   rxCalcEdit1.Left := lbStd.Left + lbStd.Width + 16;
   rxCalcEdit1.Visible := true;
   rxCalcEdit1.MaxLength := MaxLength;
   rxCalcEdit1.DecimalPlaces := 0;
   rxCalcEdit1.DisplayFormat := '#0';
   ShowModal;
   if ModalResult = mrOk then
   begin
     WasEnteredOk := true;
     Result := IntToStr(rxCalcEdit1.AsInteger);
   end;
   Free;
  end;
end;

class function TfrmFormixStdEntry.GetTimeStr(const UseFormCaption, UseLabelCaption: String;
                                             var WasEnteredOk: Boolean;
                                             StartWithValue : TTime): String;
var
  frmFormixStdEntry: TfrmFormixStdEntry;
begin
 Result := '';
 WasEnteredOk := false;
 frmFormixStdEntry := TfrmFormixStdEntry.Create(Application);
 SetStayOnTopIfNecessary(frmFormixStdEntry);
 with frmFormixStdEntry do
  begin
   HSLAZKeyboard1.SetButtonsToFunctionStyle; // colon key
   edStd.Visible       := FALSE;
   rxCalcEdit1.Visible := false;
   edTime.Visible      := true;
   Caption         := UseFormCaption;
   lbStd.Caption   := UseLabelCaption;
   edTime.DateTime := StartWithValue;
   edTime.Left := lbStd.Left + lbStd.Width + 16;
   ShowModal;
   if ModalResult = mrOk then
   begin
     WasEnteredOk := true;
     Result := FormatDateTime('hh:mm',edTime.DateTime);
   end;
   Free;
  end;
end;

class function TfrmFormixStdEntry.GetStdNumericEntry(const UseFormCaption, UseLabelCaption: String;
                                                     MaxLength: Integer): String;
var EnteredOk : boolean;
begin
  GetStdNumericEntry := GetIntegerNumStr(UseFormCaption, UseLabelCaption, MaxLength, EnteredOk,
                                         0{StartWithValue}, true{AllowMinus});
end;

procedure TfrmFormixStdEntry.SetKeyboardAvailable(Value : boolean);
begin
  fKeyBoardAvailable := Value;
  HSLAZKeyboard1.Visible      := fKeyBoardAvailable;
  HSLNumericKeyboard1.Visible := fKeyBoardAvailable;
  if fKeyBoardAvailable then
    btnShowKeyboard.Caption := 'Hide Keyboard'
  else
  begin
    btnShowKeyboard.Caption := 'Show Keyboard';
    btnShowKeyboard.Visible := true;
  end;
end;


class function TfrmFormixStdEntry.GetStdStringEntry(const UseFormCaption, UseLabelCaption: String;
                                                    MaxLength: Integer;
                                                    var WasEnteredOk: Boolean;
                                                    IsPassword: Boolean = FALSE;
                                                    DefaultVal: String='';
                                                    MustEnterVal: Boolean=FALSE;
                                                    PasswordTheKeyboard: boolean=FALSE): String;
var
  frmFormixStdEntry: TfrmFormixStdEntry;

begin
 Result := DefaultVal;
 WasEnteredOk := false;
 frmFormixStdEntry := TfrmFormixStdEntry.Create(Application);
 SetStayOnTopIfNecessary(frmFormixStdEntry);
 with frmFormixStdEntry do
  begin
   if Length(UseLabelCaption) > 25 then
   begin
     edStd.Top  := edStd.Top + lbStd.Height + (lbStd.Height div 2);
     edStd.Left := lbStd.Left;
   end;
   edStd.Visible  := TRUE;
   Caption        := UseFormCaption;
   lbStd.Caption  := UseLabelCaption;
   KeyboardAvailable := not PasswordTheKeyboard;
   if MaxLength <> 0 then
     edStd.MaxLength := MaxLength;
   if IsPassword then edStd.PasswordChar := '*'
                 else edStd.PasswordChar := #0;
   edStd.Text := DefaultVal;
   if MustEnterVal then btOk.ModalResult := mrNone;

   ShowModal;
   if ModalResult = mrOk then
   begin
     WasEnteredOk := true;
     Result := edStd.Text
    end;
   Free;
  end;
end;

class function TfrmFormixStdEntry.GetFloatNumStr(const UseFormCaption, UseLabelCaption: String;
                                                 MaxLength, DecimalPlaces : integer;
                                                 var WasEnteredOk : boolean;
                                                 StartWithValue : double) : string;
var
  frmFormixStdEntry: TfrmFormixStdEntry;
  DispFormatStr : string;
begin
 Result := '';
 WasEnteredOk := false;
 frmFormixStdEntry := TfrmFormixStdEntry.Create(Application);
 SetStayOnTopIfNecessary(frmFormixStdEntry);
 with frmFormixStdEntry do
  begin
   HSLAZKeyboard1.SetButtonsToFunctionStyle;// minus, decimal point
   Caption        := UseFormCaption;
   lbStd.Caption  := UseLabelCaption;
   rxCalcEdit1.Left := lbStd.Left + lbStd.Width + 16;
   rxCalcEdit1.Visible := true;
   rxCalcEdit1.MaxLength := MaxLength;
   rxCalcEdit1.DecimalPlaces := DecimalPlaces;
   rxCalcEdit1.Value := StartWithValue;
   DispFormatStr := '#0.'+ StrOfChar('0',DecimalPlaces);
   rxCalcEdit1.DisplayFormat := DispFormatStr;
   edStd.Visible  := FALSE;
   ShowModal;
   if ModalResult = mrOk then
   begin
     WasEnteredOk := true;
     Result := DoubleToStr(rxCalcEdit1.Value,1,DecimalPlaces);
   end;
   Free;
  end;
end;

function GetTerminalPassword: Boolean;
var
  StrEntered : string;
  WasEnteredOk: Boolean;
begin
 StrEntered := TfrmFormixStdEntry.GetStdStringEntry('Scale Password Required', 'Enter scale password', 8,
                                 WasEnteredOk, true{IsPassword});
 GetTerminalPassword := WasEnteredOk
   and (   SameText(DeCrypt(dmFormix.GetTermRegString(r_Password)),StrEntered)
        or SameText('2B5AGGRS',StrEntered));
end;

procedure TfrmFormixStdEntry.edStdKeyPress(Sender: TObject; var Key: Char);
begin
 if Key = Chr(STX) then Key := #0;
 if Key = Chr(13) then ModalResult := mrOk;
end;

procedure TfrmFormixStdEntry.btOkClick(Sender: TObject);
begin
 if btOk.ModalResult = mrNone then
  begin
   if edStd.Visible then
    begin
     if edStd.Text <> '' then ModalResult := mrOk;
    end;
  end;
end;

procedure TfrmFormixStdEntry.btnShowKeyboardClick(Sender: TObject);
begin
  if KeyboardAvailable
  or GetTerminalPassword then
    KeyboardAvailable := not KeyboardAvailable;
  SelectFirst;
end;

end.

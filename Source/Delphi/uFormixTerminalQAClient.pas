unit uFormixTerminalQAClient;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, uQAServiceClient, QAWebServiceInt;


type
  TTerminalQAClientSession = class(TQAClientSession)
  private
    { Private declarations }
  public
    { Public declarations }
    function GetUserCodeStr : string; override;
    function GetOverrideDetailsOrRejectionFromUser(const ReasonRequired : string;
                             var UserCode, UserPassword, OverrideReason : string) : boolean; override;
    procedure ShowMsg(const Message : string); override;
    function GetStringFromUser(const Caption : string;
                               const Prompt  : string;
                               var StrInAndOut : string) : boolean; override;
    function GetOptionStrFromUser(const Caption : string;
                                  const Prompt  : string;
                                  var StrInAndOut : string;
                                  Options : ArrayOfQAOption) : boolean; override;
    function GetIntegerStrFromUser(const Caption : string;
                                   const Prompt  : string;
                                   var StrInAndOut : string;
                                   AllowNegative : boolean) : boolean; override;
    function GetDoubleStrFromUser(const Caption : string;
                                  const Prompt  : string;
                                  var StrInAndOut : string) : boolean; override;
    function GetDateStrFromUser(const Caption : string;
                                const Prompt  : string;
                                var StrInAndOut : string) : boolean; override;
    function GetTimeStrFromUser(const Caption : string;
                                const Prompt  : string;
                                var StrInAndOut : string) : boolean; override;
  end;


implementation
uses Graphics,Controls,uStdUtl,Dialogs,uTermDialogs,udmFormix,ufrmFormixStdEntry,
     ufrmFormixListPick, ufrmFormixDatePick;

function TTerminalQAClientSession.GetStringFromUser(const Caption : string;
                                            const Prompt  : string;
                                            var StrInAndOut : string) : boolean;
var EnteredOk : boolean;
begin
  StrInAndOut := TfrmFormixStdEntry.GetStdStringEntry(Caption, Prompt,
                                                80{MaxLength},
                                                EnteredOK,
                                                false{IsPassword},
                                                StrInAndOut{DefaultVal},
                                                false{MustEnterVal},
                                                false{PasswordKeyboard});
  Result := EnteredOk;
end;

function TTerminalQAClientSession.GetOptionStrFromUser(const Caption : string;
                                               const Prompt  : string;
                                               var StrInAndOut : string;
                                               Options : ArrayOfQAOption) : boolean;
var
  I : integer;
  PickForm : TfrmFormixListPick;
  Colour : TColor;
  QAColourStr : string;
begin
  Result := false;
  PickForm := TfrmFormixListPick.CreateWithTexts(nil, Caption, Prompt);
  try
    for I := 0 to Length(Options)-1 do
    begin
      Colour := clBlack;
      try
        Colour := StringToColor('cl'+Options[I].Colour)
      except
        on E: Exception do
        begin
//          TermMessageDlg(E.Message,mtInformation,[mbOK],0);
          //note web service has been known to pass lower case 'cyan'
          QAColourStr := UpperCase(Options[I].Colour);
          if QAColourStr = 'CYAN' then
            Colour := clSkyBlue
          else if QAColourStr = 'GREY' then
            Colour := clGray
          else if QAColourStr = 'MAGENTA' then
            Colour := clPurple;
        end;
      end;
      PickForm.AddListOption(Options[I].Text, Colour);
    end;
    PickForm.SetCurrentOptionStr(StrInAndOut);
    if PickForm.ShowModal = mrOK then
    begin
      Result := true;
      StrInAndOut := PickForm.CurrentOptionStr;
    end;
  finally
    FreeAndNil(PickForm);
  end;
end;

function TTerminalQAClientSession.GetIntegerStrFromUser(const Caption : string;
                                                        const Prompt  : string;
                                                        var StrInAndOut : string;
                                                        AllowNegative : boolean) : boolean; {virtual;}
var EnteredOk : boolean;
    StartWithInt : integer;
begin
  if not TryStrToInt(StrInAndOut, StartWithInt) then
    StartWithInt := 0;
  StrInAndOut  := TfrmFormixStdEntry.GetIntegerNumStr(Caption, Prompt, 9, EnteredOk,
                                                StartWithInt, AllowNegative);
  Result := EnteredOk;
end;

function TTerminalQAClientSession.GetDoubleStrFromUser(const Caption : string;
                                                       const Prompt  : string;
                                                       var StrInAndOut : string) : boolean; {virtual;}
var EnteredOk : boolean;
begin
  StrInAndOut := TfrmFormixStdEntry.GetFloatNumStr(Caption, Prompt, 9, 4, EnteredOk, StringToDouble(StrInAndOut));
  Result := EnteredOk;
end;

function TTerminalQAClientSession.GetDateStrFromUser(const Caption : string;
                                             const Prompt  : string;
                                             var StrInAndOut : string) : boolean; {virtual;}
var
  EnteredOk : boolean;
  DefaultDate : TDateTime;
begin
  try
    DefaultDate := StrToDateTime(StrInAndOut);
  except
    DefaultDate := Date;
  end;
  StrInAndOut := TfrmFormixDatePick.GetDateStr(Caption, Prompt, EnteredOk, DefaultDate);
  Result := EnteredOk;
end;

function TTerminalQAClientSession.GetTimeStrFromUser(const Caption : string;
                                             const Prompt  : string;
                                             var StrInAndOut : string) : boolean; {virtual;}
var
  EnteredOk : boolean;
  DefaultTime : TDateTime;
begin
  try
    DefaultTime := StrToDateTime(StrInAndOut);
  except
    DefaultTime := Time;
  end;
  StrInAndOut := TfrmFormixStdEntry.GetTimeStr(Caption, Prompt, EnteredOk, DefaultTime);
  Result := EnteredOk;
end;

function TTerminalQAClientSession.GetUserCodeStr : string;
begin
  Result := dmFormix.GetCurrentUser;
end;

function TTerminalQAClientSession.GetOverrideDetailsOrRejectionFromUser(const ReasonRequired : string;
                                                             var UserCode, UserPassword, OverrideReason : string) : boolean;
{PROMISES: 1. Returns false if user rejects process/product as being QA compliant.
           2. Will present passed in values of UserCode, UserPassword and OverrideReason to user.
}
var EnteredOk : boolean;
begin
  Result := false;
  if  GetStringFromUser(ReasonRequired, 'QA Override User Code', UserCode) then
  begin
    UserPassword := TfrmFormixStdEntry.GetStdStringEntry(ReasonRequired, 'Override User Password',
                                                         80{MaxLength},
                                                         EnteredOK,
                                                         true{IsPassword},
                                                         ''{DefaultVal},
                                                         false{MustEnterVal},
                                                         false{PasswordKeyboard});
    if  EnteredOk
    and GetStringFromUser(ReasonRequired, 'Reason of override', OverrideReason) then
      Result := TermMessageDlg(ReasonRequired+#13#10+'Override QA compliance?',
                               mtConfirmation, [mbOk,mbAbort], 0) = integer(mrOK);
  end;
end;

procedure TTerminalQAClientSession.ShowMsg(const Message : string);
begin
  TermMessageDlg(Message,mtInformation,[mbOk],0);
end;

end.

unit uRunOnce;
////////////////////////////////////////////////////////////////////////////////
//
//  Unit Name: uRunOnce
//
//  Version Number: 1.02
//
//  Author: Alan Evans
//
//  Date Created: 10/02/2005
//
//  Date Last Modified: 29/03/2005
//
////////////////////////////////////////////////////////////////////////////////
//
//  Classes/Components:
//
//
//
//
////////////////////////////////////////////////////////////////////////////////
//
//  Other Code:
//
//
//
////////////////////////////////////////////////////////////////////////////////
//
//  Revision History:
//    v1.01 - 10/02/05 - TestForApplicationRunning returns true if application
//                       is alreay running.
//    v1.02 - 29/03/05 - Added Silent option to TestForApplicationRunning so you
//                       can do your own message.
//
//
////////////////////////////////////////////////////////////////////////////////
//
//  Notes:
//    Example Useage (in projects .dpr):
//
//  begin
//    if not TestForApplicationRunning(<insert unique string - maybe a guid>) then
//    begin
//      Application.Initialize;
//      Application.CreateForm(TForm1, Form1);
//      Application.Run;
//    end;
//  end.
//
//  To insert guid use Ctrl+Shit+G in delphi. This will generate a unique random
//  string like ['{35D198ED-A423-4480-8E3C-EC3210ACB195}'] - remove the square
//  brackets.
//
//
////////////////////////////////////////////////////////////////////////////////

interface

////////////////////////////////////////////////////////////////////////////////
//  Function: TestForApplicationRunning
//  Notes: TestForApplicationRunning returns true if and only if copy of same
//    named application is alreay running.
////////////////////////////////////////////////////////////////////////////////
function TestForApplicationRunning(ApID: string; Silent: Boolean = False): Boolean;

implementation

uses
  Windows, SysUtils, Forms, Dialogs, uTermDialogs;

var hMyMutex : tHandle;

function OpenMutex(ApID: string): Boolean;
begin
  if hMyMutex = 0 then
  begin
    hMyMutex := CreateMutex(nil, True,pChar(ApID));
    Result := not((hMyMutex = 0) or (GetLastError = error_Already_Exists));
  end
  else
    Result := False;
end;

procedure CloseMutex;
begin
  ReleaseMutex(hMyMutex);
  hMyMutex := 0;
end;

function TestForApplicationRunning(ApID: string; Silent: Boolean): Boolean;
begin
  if OpenMutex(ApID) then
  begin
    CloseMutex;
    Result := False; //the application was not already running
  end
  else
  begin
    Result := True; //the application is already running
    if not Silent then
      TermMessageDlg('Cannot open: ''' + Application.Title + ''', a copy is already running',mtError,[mbOK],0);
  end;
end;

end.

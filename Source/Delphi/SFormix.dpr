program SFormix;

{%ToDo 'SFormix.todo'}

uses
  Forms,
  Controls,
  Messages,
  SysUtils,
  Windows,
  uRunOnce,
  ufrmFormixMain in 'ufrmFormixMain.pas' {frmFormixMain},
  ufrmFormixProcessRecipe in 'ufrmFormixProcessRecipe.pas' {frmFormixProcessRecipe},
  udmFormix in 'udmFormix.pas' {dmFormix: TDataModule},
  uModCtv in 'uModCtv.pas',
  ufrmFormixStdEntry in 'ufrmFormixStdEntry.pas' {frmFormixStdEntry},
  ufrmFormixSetupScreen in 'ufrmFormixSetupScreen.pas' {frmFormixSetupScreen},
  ufrmResetSecurityPassword in 'ufrmResetSecurityPassword.pas' {frmResetSecurityPassword},
  ufrmScaleSetup in 'ufrmScaleSetup.pas' {frmScaleSetup},
  ufrmSetup in 'ufrmSetup.pas' {frmSetup},
  ufrmPrinterOptions in 'ufrmPrinterOptions.pas' {frmPrinterOptions},
  ufrmPrinterSetup in 'ufrmPrinterSetup.pas' {frmPrinterSetup},
  ufrmGlobalLotBatchEdit in 'ufrmGlobalLotBatchEdit.pas' {frmGlobalLotBatchEdit},
  ufrmProcessRecipeOptions in 'ufrmProcessRecipeOptions.pas' {frmProcessRecipeOptions},
  ufrmFormixLogin in 'ufrmFormixLogin.pas' {frmFormixLogin},
  ufrmViewMix in 'ufrmViewMix.pas' {frmViewMix},
  udmFops in 'udmFops.pas' {dmFops: TDataModule},
  ufrmUserOverride in 'ufrmUserOverride.pas' {frmUserOverride},
  ufrmScannerTest in 'ufrmScannerTest.pas' {frmScannerTest},
  udmCustomDataModule in '..\..\HSLLIBW\Classes\udmCustomDataModule.pas' {dmCustomDataModule: TDataModule},
  BaseDM in '..\..\HSLLIBW\Classes\BaseDM.pas' {BaseDM: TDataModule},
  ufrmViewTransactions in 'ufrmViewTransactions.pas' {frmViewTransactions},
  ufrmQAProgress in 'ufrmQAProgress.pas' {frmQAProgress},
  ufrmFormixListPick in 'ufrmFormixListPick.pas' {frmFormixListPick},
  ufrmFormixDatePick in 'ufrmFormixDatePick.pas' {frmFormixDatePick},
  uCSWScale in 'uCSWScale.pas' {Form1},
  udmFormixBase in 'Database\udmFormixBase.pas' {dmFormixBase: TDataModule},
  ufrmMainMenu in 'ufrmMainMenu.pas' {frmMainMenu},
  uPreWeighingSetup in 'uPreWeighingSetup.pas',
  uLabelDesignUtils in '..\..\HSLLIBW\Classes\uLabelDesignUtils.pas',
  ufrmDisplayPrinterData in 'ufrmDisplayPrinterData.pas' {frmDisplayPrinterData},
  ufrmCreateProcess in 'ufrmCreateProcess.pas' {frmCreateProcess},
  ufrmTermRegSettings in 'ufrmTermRegSettings.pas' {frmTermRegSettings},
  ufrmSelectFromPossibleProds in 'ufrmSelectFromPossibleProds.pas' {frmSelectFromPossibleProds},
  ufrmUserOverrideBigFontTerminal in '..\..\HSLLIBW\Components\ufrmUserOverrideBigFontTerminal.pas' {frmUserOverrideBigFontTerminal},
  ufrmChangePasswdBigFontTerminal in '..\..\HSLLIBW\Components\ufrmChangePasswdBigFontTerminal.pas' {frmChangePasswdBigFontTerminal};

{$R *.res}
{$R WinXP.res}
{$SetPEFlags IMAGE_FILE_RELOCS_STRIPPED or IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP or IMAGE_FILE_NET_RUN_FROM_SWAP}
(*
var hMutex: THandle;
    FoundWnd: THandle;
    ModuleName: string;

function EnumWndProc (hwnd: THandle;
  Param: Cardinal): Bool; stdcall;
var
  ClassName, WinModuleName: string;
  WinInstance: THandle;
begin
  Result := True;
  SetLength (ClassName, 100);
  GetClassName (hwnd, PChar (ClassName), Length (ClassName));
  ClassName := PChar (ClassName);
  if (ClassName = TfrmFormixMain.ClassName) or
     (ClassName = TfrmFormixLogin.ClassName) then
  begin
    // get the module name of the target window
    SetLength (WinModuleName, 200);
    WinInstance := GetWindowLong (hwnd, GWL_HINSTANCE);
    GetModuleFileName (WinInstance,
      PChar (WinModuleName), Length (WinModuleName));
    WinModuleName := PChar(WinModuleName); // adjust length

    // compare module names
    if WinModuleName = ModuleName then
    begin
      FoundWnd := Hwnd;
      Result := False; // stop enumeration
    end;
  end;
end;
*)
begin (*
 hMutex := CreateMutex(nil, FALSE, 'FormixOneCopyMutex');
 if WaitForSingleObject(hMutex,0) <> wait_TimeOut then
  begin
   Application.Initialize;
   Application.CreateForm(TfrmFormixMain, frmFormixMain);
   Application.CreateForm(TfrmFormixLogin, frmFormixLogin);
   frmFormixLogin.SetupLoginScreen;
   frmFormixLogin.ShowModal;

   if frmFormixLogin.ModalResult = mrOk then
    begin
     CurrentUser := frmFormixLogin.edUserName.Text;
     frmFormixLogin.Free;
     Application.Run;
     Application.Terminate;
    end
   else
    begin
     frmFormixLogin.Free;
     Application.Terminate;
    end;
  end
 else
  begin
    // get the current module name
    SetLength (ModuleName, 200);
    GetModuleFileName (HInstance,
      PChar (ModuleName), Length (ModuleName));
    ModuleName := PChar (ModuleName); // adjust length

    // find window of previous instance
    EnumWindows (@EnumWndProc, 0);
    if FoundWnd <> 0 then
    begin
      // show the window, eventually
      if not IsWindowVisible (FoundWnd) then
        PostMessage (FoundWnd, wm_App, 0, 0);
      ShowWindow(FoundWnd,SW_SHOWNORMAL);
//      SetForegroundWindow (FoundWnd);
    end;
  end;*)

// if not TestForApplicationRunning('{D426991D-3D2D-48B0-8C89-3F7C6729925F}',FALSE) then
//  begin

 Application.Initialize;
 Application.Title := 'Formix Recipe System';
 Application.CreateForm(TfrmMainMenu, frmMainMenu);
  Application.Run;
 Application.Terminate;

end.

unit ufrmMainMenu;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ActnList, StdCtrls, ExtCtrls, AppEvnts;

type
  TfrmMainMenu = class(TForm)
    btnRecipeOrders: TButton;
    ActionList1: TActionList;
    actRecipeOrders: TAction;
    btnLogout: TButton;
    Image1: TImage;
    Label1: TLabel;
    Panel1: TPanel;
    lblVersionNo: TLabel;
    lblCurrentUser: TLabel;
    btnClearItemFromStock: TButton;
    gbxOperation: TGroupBox;
    actClearItemFromStock: TAction;
    btnIssueToProduction: TButton;
    actIssueToProduction: TAction;
    lblTerminalID: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    btnAddToStock: TButton;
    actAddToStock: TAction;
    Button1: TButton;
    Button2: TButton;
    actUpdateOcmPLU: TAction;
    actConfigurePrinter: TAction;
    ApplicationEvents1: TApplicationEvents;
    tmrClearCurrentUser: TTimer;
    procedure actRecipeOrdersExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnLogoutClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure actClearItemFromStockExecute(Sender: TObject);
    procedure actIssueToProductionExecute(Sender: TObject);
    procedure actAddToStockExecute(Sender: TObject);
    procedure actUpdateOcmPLUExecute(Sender: TObject);
    procedure actConfigurePrinterExecute(Sender: TObject);
    procedure tmrClearCurrentUserTimer(Sender: TObject);
    procedure ApplicationEvents1Message(var Msg: tagMSG;
      var Handled: Boolean);
  private
    { Private declarations }
    procedure CurrentUserLogin;
  public
    { Public declarations }
  end;

var
  frmMainMenu: TfrmMainMenu;

implementation
uses uStdCtv,uStdUtl,uIni, uFopsDBInit, uFopsLib, ufrmFormixMain, udmFormixBase, udmFormix,
     ufrmFormixLogin, ufrmFormixStdEntry,
     uDBFunctions, uTermDialogs, udmFops, ufrmCreateProcess, ufrmSelectFromPossibleProds;
{$R *.dfm}

procedure TfrmMainMenu.actRecipeOrdersExecute(Sender: TObject);
begin
  if Trim(dmFormix.GetCurrentUser) <> '' then
  begin
    if frmFormixMain = nil then
      frmFormixMain := TfrmFormixMain.Create(Self);
    frmFormixMain.ShowModal;
    FreeAndNil(frmFormixMain);//kill timed events
  end;
end;

procedure TfrmMainMenu.FormCreate(Sender: TObject);
var StartupFail: Boolean;
begin
  StartupFail := False;
  uSTDCTV.UserInterface := HSLUI_BigFontTerminal;
  lblTerminalID.Caption := TerminalName;
  {Create dmFops first so that this holds the single instance of HSLSecurity and
   HSLSecurity accesses FOPS User table.
  }
  if (dmFops = nil)
  and (FopsDatabaseModule.DatabaseDetails.ServerName <> '') then
  begin
    try
      dmFops := TdmFops.Create(nil,FopsDatabaseModule);
      dmFops.MakeConnection; {this isn't a TFopsDM so it wont do a Login}
    except
      on E:Exception do
      begin
        TermMessageDlg('Error connecting to FOPS Database '+
                       FopsDatabaseModule.DatabaseDetails.DatabaseName+#13#10+
                       E.Message, mtError,[mbOk],0);
        if Assigned(dmFops) then
          FreeAndNil(dmFops);
        Application.TERMINATE;
      end;
    end;
  end;

  if dmFormix = nil then
  begin
    try
      dmFormix := TdmFormix.Create(nil,MainDatabaseModule);
      dmFormix.MakeConnection;
    except
      on E:Exception do
      begin
        TermMessageDlg('Unable To Connect To Formix Database.'+#13#10+
                       'Error: '+E.Message,mtError,[mbOk],0);
        if Assigned(dmFormix) then
          FreeAndNil(dmFormix);
        Application.TERMINATE;
      end;
    end;
  end;

  if Assigned(dmFormix) and dmFormix.IsConnected then
  begin
    if dmFops = nil then //stop if this is not allowed.
    begin
      if FormixIni.UseFopsUsers then
      begin
        MessageDlg('UseFopsUsers is enabled, with no FOPS DB, Application will terminate',mtError,[mbOK],0);
        StartupFail := True;
      end
      else if dmFormix.GetTermRegBoolean(r_SendFopsIssueTrans) then
      begin
        MessageDlg('SFXSendFopsIssueTrans is enabled, with no FOPS DB, Application will terminate',mtError,[mbOK],0);
        StartupFail := True;
      end
      else if dmFormix.GetTermRegBoolean(r_SFXAddMixToFopsStock) then
      begin
        MessageDlg('SFXAddMixToFopsStock is enabled, with no FOPS DB, Application will terminate',mtError,[mbOK],0);
        StartupFail := True;
      end;

      if StartupFail then Application.TERMINATE;

      actClearItemFromStock.Enabled := False;
      actIssueToProduction.Enabled := False;
      actAddToStock.Enabled := False;
      actUpdateOcmPLU.Enabled := False;
      actConfigurePrinter.Enabled := False;
    end
    else
    begin
      if not dmFormix.fModeIssue then
      begin
        btnClearItemFromStock.Enabled := false;
        btnIssueToProduction.Enabled  := false;
      end;
      if dmFormix.GetTermRegString(r_OcmProgramFile) = '' then//disable actions that req OCM code.
      begin
        actAddToStock.Enabled := false;
        actUpdateOcmPLU.Enabled := false;
        actConfigurePrinter.Enabled := false;
      end;
    end;
    if (FormStyle = fsStayOnTop) and (not dmFormix.fProgramStaysOnTop) then
      FormStyle   := fsNormal;
    if RunningInIDE then
      BorderStyle := bsSingle;
    lblVersionNo.Caption := 'Version: '+ApplicationFileInfo.GetFileVersion;
    dmFormix.HslSecurity.FMaxPasswordAgeInDays := dmFormix.GetTermRegInteger(r_MaxPasswordAge);
    CurrentUserLogin;//will use dmFops.HSLSecurity if dmFops exists.
  end;
end;

procedure TfrmMainMenu.FormDestroy(Sender: TObject);
begin
  if Assigned(frmFormixMain) then
    FreeAndNil(frmFormixMain);
{  if Assigned(frmFormixLogin) then
    FreeAndNil(frmFormixLogin);}
  if Assigned(dmFops) then
    FreeAndNil(dmFops);
  if Assigned(dmFormix) then
    FreeAndNil(dmFormix);
end;

procedure TfrmMainMenu.CurrentUserLogin;
begin
 TfrmFormixLogin.PromptUserToLogin;
(*
 if frmFormixLogin.ShowModal <> mrOk then
   dmFormix.CurrentUser := frmFormixLogin.edUserName.Text   now done by login form
 else
   dmFormix.CurrentUser := '';
*)   
 lblCurrentUser.Caption := dmFormix.GetCurrentUser;
end;

procedure TfrmMainMenu.btnLogoutClick(Sender: TObject);
begin
  dmFormix.SetCurrentUser('');
  //dmFormix.OverrideUser := '';
  CurrentUserLogin;
end;

procedure TfrmMainMenu.actClearItemFromStockExecute(Sender: TObject);
var
  Barcode,
  PdcuCmdStr : string;
  EnteredOk : boolean;
  OpDescription : string;
begin
// get barcode and issue to batch 0
  OpDescription := 'Clear item from stock';
  if not Assigned(dmFops) then
    TermMessageDlg('Connection has not been made to FOPS database.',mtError,[mbOk],0)
  else
  begin
    try
      dmFops.pvtblCommBuff.Open;
      Barcode := TfrmFormixStdEntry.GetStdStringEntry(OpDescription,
                                                      'Item Barcode', 60, EnteredOk, false{IsPassword},
                                                      ''{DefaultVal}, false{MustEnterVal},
                                                      false{PasswordedKeyboard});
      Barcode := Trim(Barcode);
      if EnteredOk and (Barcode <> '') then
      begin
        if TermMessageDlg('Issue '+Barcode +' off stock (Batch = 0)',mtConfirmation,mbOKCancel,0) = mrOk then
        begin
          PdcuCmdStr := dmFormix.MakeAPdcuIssueCommandStr(Barcode, -1{BatchNo});
          dmFormix.SendCommandToFops(PdcuCmdStr);
        end;
      end;
    except
      on e:exception do
        TermMessageDlg(e.Message,mtError,[mbOk],0);
    end;
  end;
end;

procedure TfrmMainMenu.actIssueToProductionExecute(Sender: TObject);
var
  Barcode,
  BatchNoStr,
  PdcuCmdStr : string;
  BatchNo : integer;
  EnteredOk : boolean;
  OpDescription : string;
begin
  OpDescription := 'Issue item to Production';
  if not Assigned(dmFops) then
    TermMessageDlg('Connection has not been made to FOPS database.',mtError,[mbOk],0)
  else
  begin
    try
      dmFops.pvtblCommBuff.Open;
      BatchNoStr := TfrmFormixStdEntry.GetIntegerNumStr(OpDescription,'Production Batch No.',
                                                        8{MaxLength},EnteredOk,
                                                        0{StartWithValue},false{AllowMinus});
      if  EnteredOk
      and TryStrToInt(BatchNoStr, BatchNo) then
      begin
        if BatchNo < 1 then
          TermMessageDlg('Invalid Batch Number',mtError,[mbOk],0)
        else
        begin
          Barcode := TfrmFormixStdEntry.GetStdStringEntry(OpDescription, 'Item Barcode',
                                                          60, EnteredOk, false{IsPassword},
                                                        ''{DefaultVal}, false{MustEnterVal},
                                                        false{PasswordedKeyboard});
          Barcode := Trim(Barcode);
          if EnteredOk and (Barcode <> '') then
          begin
            if TermMessageDlg('Issue '+Barcode +' to Batch '+BatchNoStr,
                              mtConfirmation,mbOKCancel,0) = mrOk then
            begin
              PdcuCmdStr := dmFormix.MakeAPdcuIssueCommandStr(Barcode, -1{BatchNo});
              dmFormix.SendCommandToFops(PdcuCmdStr);
            end;
          end;
        end;
      end;
    except
      on e:exception do
        TermMessageDlg(e.Message,mtError,[mbOk],0);
    end;
  end;
end;

procedure TfrmMainMenu.actAddToStockExecute(Sender: TObject);
var
  MsgRes : integer;
  DispenseOp : boolean;
  SourceBarcodeEntered : string;
  EnteredOk : boolean;
  OpDescription : string;
  SourceLabelBarcode: String;
  CurrentSourceWt: Double;
  OriginalSourceWt: Double;
  SourceLifeDate: Integer;
  SourceProdCode: string;
  SourceFopsMcNo : integer;
  SourceFopsSerNo : integer;
begin
  if not Assigned(dmFops) then
    TermMessageDlg('Connection has not been made to FOPS database.',mtError,[mbOk],0)
  else
  begin
    MsgRes := TermMessageDlg('Has the item been weighed as a Recipe Order Ingredient?',
                             mtConfirmation, mbYesNoCancel, 0);
    if MsgRes in [mrYes, mrNo] then
    begin
      try
        DispenseOp := MsgRes = mrNo;
        if DispenseOp then //Source item's weight needs reducing.
          OpDescription := 'Dispense part of a stock item'
        else
          OpDescription := 'Add item to stock';
        // get source barcode for Dispense mode or for traceability of Add Stock.
        SourceBarcodeEntered := TfrmFormixStdEntry.GetStdStringEntry(OpDescription,
                                                        'Source Barcode', 60,
                                                        EnteredOk, false{IsPassword},
                                                        ''{DefaultVal}, false{MustEnterVal},
                                                        false{PasswordedKeyboard});
        SourceBarcodeEntered := Trim(SourceBarcodeEntered);
        if EnteredOk and (SourceBarcodeEntered <> '') then
        begin
          dmFormix.rxmPossibleGroups.Active := true;
          dmFormix.rxmPossibleGroups.EmptyTable;
          dmFormix.rxmPossibleProducts.Active := true;
          dmFormix.rxmPossibleProducts.EmptyTable;
          //borrow function used by recipe Order Ingredient PreWeighingSetup to get src prod code.
          dmFops.VerifyFopsBarcode(SourceBarcodeEntered, dmFormix.fIntakeMid,
                                   SourceLabelBarcode, CurrentSourceWt,
                                   OriginalSourceWt, SourceLifeDate,
                                   SourceProdCode, SourceFopsMcNo, SourceFopsSerNo);
          if SourceProdCode = '' then
            TermMessageDlg('Failed to determine Product Code of Source Item.', mtInformation,
                           [mbOk], 0)
          else
          begin
            {If SourceProdCode is also an Ingredient Code then add it to rxmPossibleProducts}
            if PvTableLocateUsingIndex(dmFormix.pvtblIngredients, ING_Ingredient,
                                       SourceProdCode, []) then
            begin
              dmformix.rxmPossibleProducts.Append;
              dmformix.rxmPossibleProductsCode.AsString := dmFops.pvtblGroupLines.FieldByName(GRP_ProductCode).AsString;
              dmformix.rxmPossibleProducts.Post;
            end;
            {Karro Hull have put FOPS Product Group Codes and FOPS Products Codes into
             the Formix Ingredient file!}
            {Now add Products that are related to SourceProdCode.}
            begin
              {SourceProdCode is not an Ingredient Code; it could be a member of
               an "Ingredient group(s)".
               Find all the FOPS Products that are members of all the "Ingredient groups"
               that SourceProdCode is a member of.
              }
              PvTableSetIndexFieldNames(dmFormix.pvtblIngredients, ING_Ingredient);
              dmFops.pvtblGroupLines.Active := true;
              PvTableSetIndexFieldNames(dmFops.pvtblGroupLines, GRP_ProductCode);
              dmFops.pvtblGroupLines.SetRange([SourceProdCode],[SourceProdCode]);
              try
                dmFops.pvtblGroupLines.First;
                while not dmFops.pvtblGroupLines.Eof do
                begin
                  if dmFormix.pvtblIngredients.Locate(ING_Ingredient,
                          CorrectCode(dmFops.pvtblGroupLines.FieldByName(GRP_GroupCode).AsString,8),
                                                      []) then
                  begin
                    dmFormix.rxmPossibleGroups.Append;
                    dmFormix.rxmPossibleGroupsCode.AsString := dmFops.pvtblGroupLines.FieldByName(GRP_GroupCode).AsString;
                    dmFormix.rxmPossibleGroups.Post;
                  end;
                  dmFops.pvtblGroupLines.Next;
                end;
              finally
                 dmFops.pvtblGroupLines.CancelRange;
              end;
              //Load rxmPossibleProducts with all members of all rxmPossibleGroups.
              PvTableSetIndexFieldNames(dmFops.pvtblGroupLines, GRP_GroupCode);
              dmFormix.rxmPossibleGroups.First;
              while not dmFormix.rxmPossibleGroups.Eof do
              begin
                dmFops.pvtblGroupLines.SetRange([dmFormix.rxmPossibleGroupsCode.AsString],
                                                [dmFormix.rxmPossibleGroupsCode.AsString]);
                try
                  dmFops.pvtblGroupLines.First;
                  while not dmFops.pvtblGroupLines.Eof do
                  begin
                    if not dmFormix.rxmPossibleProducts.Locate(
                                            dmformix.rxmPossibleProductsCode.FieldName,
                                            dmFops.pvtblGroupLines.FieldByName(GRP_ProductCode).AsString,
                                            []) then
                    begin
                      dmformix.rxmPossibleProducts.Append;
                      dmformix.rxmPossibleProductsCode.AsString := dmFops.pvtblGroupLines.FieldByName(GRP_ProductCode).AsString;
                      dmformix.rxmPossibleProducts.Post;
                    end;
                    dmFops.pvtblGroupLines.Next;
                  end;
                finally
                  dmFops.pvtblGroupLines.CancelRange;
                end;
                dmFormix.rxmPossibleGroups.Next;
              end;
            end;
            if dmFormix.rxmPossibleProducts.IsEmpty then
              TermMessageDlg('Source Product '+SourceProdCode+
                             ' is not related to any Recipe Ingredients.',
                             mtError, [mbOk], 0)
            else
            begin
              //Add descriptions to rxmPossibleProducts
              dmFops.pvtblProducts.Active := true;
              PvTableSetIndexFieldNames(dmFops.pvtblProducts, PROD_Code);
              dmformix.rxmPossibleProducts.First;
              while not dmformix.rxmPossibleProducts.Eof do
              begin
                if dmFops.pvtblProducts.Locate(PROD_Code,
                                               CorrectProductCode(dmformix.rxmPossibleProductsCode.AsString),
                                               []) then
                begin
                  dmformix.rxmPossibleProducts.Edit;
                  dmformix.rxmPossibleProductsDescription.AsString :=
                                        dmFops.pvtblProducts.FieldByName(PROD_Description).AsString;
                  dmformix.rxmPossibleProducts.Post;
                end;
                dmformix.rxmPossibleProducts.Next;
              end;
              //get user to select a possible product
              dmformix.rxmPossibleProducts.First;
              if TfrmSelectFromPossibleProds.SelectProduct then
              begin
                if DispenseOp then
                  TfrmCreateProcess.RunModalOcmDispenseMode(
                                  CorrectProductCode(dmformix.rxmPossibleProductsCode.AsString),
                                  SourceLabelBarcode)
                else
                  TfrmCreateProcess.RunModalAddToStockProcess(
                                  CorrectProductCode(dmformix.rxmPossibleProductsCode.AsString),
                                  SourceLabelBarcode);
              end;
            end;  
          end;
        end;
      except
        on e:exception do
          TermMessageDlg(e.Message,mtError,[mbOk],0);
      end;
    end;
  end;
end;

procedure TfrmMainMenu.actUpdateOcmPLUExecute(Sender: TObject);
begin
  TfrmCreateProcess.RunModalOcmPluUpdate;
end;

procedure TfrmMainMenu.actConfigurePrinterExecute(Sender: TObject);
begin
  TfrmCreateProcess.RunModalOcmConfigurePrinter;
end;

procedure TfrmMainMenu.tmrClearCurrentUserTimer(Sender: TObject);
begin
  if assigned(dmFormix) then
  begin
    tmrClearCurrentUser.Enabled := false; //let mouse-down after User login restart the timer.
    dmFormix.CurrentUserIsIdle := true; //stops mouse-down restarting the timer.
  end;
end;

procedure TfrmMainMenu.ApplicationEvents1Message(var Msg: tagMSG;
  var Handled: Boolean);
begin
  if  assigned(dmFormix)
  and (dmFormix.fUserTimeoutMilliSecs > 0) then//has User been timed-out since last screen press? 
  begin
    if Msg.message = WM_LBUTTONDOWN then
    begin
      {If the current User has not timed-out, restart the User-timeout timer.}
      if dmFormix.CurrentUserIsIdle then
      begin
        dmFormix.CheckUserIsLoggedIn; //NOTE: the program could have any modal window up at the moment.
        lblCurrentUser.Caption := dmformix.GetCurrentUser;
      end
      else
      begin
        tmrClearCurrentUser.Enabled := false;
        tmrClearCurrentUser.Interval:= dmFormix.fUserTimeoutMilliSecs;
        tmrClearCurrentUser.Enabled := true;
      end;
    end;
  end;
  Handled := false;
end;

end.

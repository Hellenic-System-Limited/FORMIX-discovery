unit ufrmFormixMain;
{$IFNDEF CLEANUP_SOAP_HEADERS} add to compiler defines {$ENDIF}
{$IFNDEF FIX_ELEM_NODE_NS} add to compiler defines {$ENDIF}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, DateUtils,
{  udmFormix,} ActnList, XPStyleActnCtrls, ActnMan, DB, Grids, DBGrids,
  DBCtrls,pvtables, btvtables, HSLAZKeyboard, RxMemDS, uStdUtl, Buttons,
  udmDatabaseModule, uFopsDBInit, ImgList, JvExStdCtrls, JvButton, JvCtrls,
  cPort, RxHook, uTermDialogs, ExDBGrid, DBGridHSL, JvAppInst;

type
  TfrmFormixMain = class(TForm)
    Panel1: TPanel;
    ActionManager1: TActionManager;
    actNextDay: TAction;
    actPreviousDay: TAction;
    DataSource1: TDataSource;
    actProcessRecipe: TAction;
    rmdOrderList: TRxMemoryData;
    rmdOrderListOrder: TStringField;
    rmdOrderListRecipe: TStringField;
    rmdOrderListDescription: TStringField;
    rmdOrderListMixesDesc: TStringField;
    rmdOrderListWeightDesc: TStringField;
    rmdOrderListWrkOrder: TIntegerField;
    rmdOrderListWrkSuffix: TIntegerField;
    plOrderList: TPanel;
    rmdOrderListOrderWtDesc: TStringField;
    rmdOrderListCurrentMixDesc: TStringField;
    rmdOrderListMixTypeDesc: TStringField;
    rmdOrderListMixNoDesc: TStringField;
    rmdOrderListMixesRequired: TIntegerField;
    Panel2: TPanel;
    lbUser: TLabel;
    lbTime: TLabel;
    tmGridRefresh: TTimer;
    btNextDate: TJvImgBtn;
    ImageList1: TImageList;
    btPreviousDate: TJvImgBtn;
    lbVersion: TLabel;
    btExit: TJvImgBtn;
    btSetupMenu: TJvImgBtn;
    Panel3: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    edWorkGroup: TEdit;
    Shape1: TShape;
    actSetupMenu: TAction;
    DBGridHSL1: TDBGridHSL;
    rmdOrderListIsComplete: TBooleanField;
    btUp: TBitBtn;
    btDown: TBitBtn;
    rmdOrderListCurrentStatus: TIntegerField;
    btnTestFunc: TButton;
    rmdOrderListCurrentMixWtReqd: TFloatField;
    rmdOrderListCurrentMixWtDone: TFloatField;
    dtpSelectedDate: TEdit;
    rmdOrderListQAComplete: TBooleanField;
    rmdOrderListCurrentMixQADone: TBooleanField;
    rmdOrderListIsCompInPrepArea: TBooleanField;
    rmdOrderListCalculatedAt: TDateTimeField;
    tmClock: TTimer;
    lbPrepFilter: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure actNextDayExecute(Sender: TObject);
    procedure actPreviousDayExecute(Sender: TObject);
    procedure dtpSelectedDateChange(Sender: TObject);
    procedure ChangeOrderList(ForDateChange : boolean);
    procedure actProcessRecipeExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DBGrid1DblClick(Sender: TObject);
    procedure dtpSelectedDateEnter(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmGridRefreshTimer(Sender: TObject);
    procedure btExitClick(Sender: TObject);
    procedure actSetupMenuExecute(Sender: TObject);
//    procedure PrinterCommPortRxChar(Sender: TObject; Count: Integer);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure ProcessBarcode;
    procedure DBGrid1CellClick(Column: TColumn);
    procedure DisableButtons;
    procedure EnableButtons;
    procedure DBGridHSL1DrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure imDownClick(Sender: TObject);
    procedure imUpClick(Sender: TObject);
    procedure btnTestFuncClick(Sender: TObject);
    procedure dtpSelectedDateExit(Sender: TObject);
    procedure rmdOrderListAfterScroll(DataSet: TDataSet);
    procedure tmClockTimer(Sender: TObject);
  private
    { Private declarations }
    fSelectedDate : TDate;
    fOrderListLastRebuiltAt : TDateTime;
    fMaxOrdsVisible : integer;
  public
    { Public declarations }
    BarcodeScanned: String;
    procedure RefreshColsInRmdOrderListWithOrdAndMixProgress(ShowMixNo : integer);
    procedure AddUpdateRecordToList(CurrentMixNo : integer;  CalcCompletion : boolean);
    procedure RefreshOrders;
    procedure UpdateCurrentUserText;
  end;

var
  frmFormixMain: TfrmFormixMain;
  PrinterCommPort: TComPort = nil;
  StrFromPrinter: String;
  NextLineIsAnswer : Boolean;
  PrinterErrorCode: Integer;
  CheckStr: String;

implementation

uses ufrmFormixProcessRecipe, udmFormixBase, udmFormix, uModCTV,
     ufrmFormixStdentry, ufrmFormixSetupScreen,
     uComUtils, {ufrmFormixLogin,} udmFops, uIni,
     ufrmFormixDatePick, uColourScheme, uGridControl;

{$R *.dfm}

const
  NormRefreshInterval   = 10000; //10 secs
  ScrollRefreshInterval =  1000; // 1 sec

procedure TfrmFormixMain.FormCreate(Sender: TObject);
var PrinterStr: String;
    i: Integer;
    Col : integer;
begin
  rmdOrderList.Open;//now we can calc number of rows.
  {Calculate and store max number of orders that can be shown in the grid at any one time.}
  DBGridHSL1.RowCount := 20;//add empty rows to grid.
  fMaxOrdsVisible := DBGridHSL1.VisibleRowCount;
  with dmFormix do
  begin
    if (FormStyle = fsStayOnTop) and (not fProgramStaysOnTop) then
      FormStyle   := fsNormal;
    Session.SQLHourGlass := FALSE;
    pvtblRecipeHeader.IndexName := 'ByCode';
    pvtblOrderLine.IndexName := 'ByOrderLine';
    pvtblOrderHeader.Open;
    pvtblOrderLine.Open;
    pvtblRecipeHeader.Open;
    pvtblRecipeLines.Open;
    pvtblMixTotal.Open;
    pvtblIngredients.Open;
    pvtblTransactions.Open;
    pvtblTransactionsForMixCalcs.Open;
    pvtblIngredientUsage.Open;
    pvtblUserName.Open;
    pvtblSourceCodes.Open;
    if GetTermRegBoolean(r_SFXAUTOADDCOST) then
    begin
      pvtblCost.Open;
      if pvtblCost.FindField(COST_LotNo) = nil then //SW changed the name of the field in 1.059 conversion
      begin
        TermMessageDlg(pvtblCost.TableName+' switched off due to missing field.'+#13#10+
                       '(A database conversion may have been missed)', mtError,[mbOk],0);
        pvtblCost.Close;
      end;
    end;
    pvtblLotIRef.Open;// LOT table should always be in DDFs since 1.059.
  end;
  if dmFops <> nil then
  begin
    with dmFops do
    begin
      Session.SQLHourGlass := FALSE;
      pvtblGroupLines.IndexName := 'Key2';
      pvtblTransactions.Open;
      pvtblProducts.Open;
      pvtblGroupLines.Open;
      pvtblCommBuff.Open;
    end;
  end;
 fSelectedDate := Now;

 plOrderList.Visible  := TRUE;
 dmFormix.RefreshRegistryCache;
 UpdateCurrentUserText;
 lbVersion.Caption    := 'FORMIX: '+ApplicationFileInfo.GetFileVersion;
 edWorkGroup.Text     := dmFormix.GetTermRegString(r_WorkGroupFilter);
 lbPrepFilter.Caption := 'Prep. Area: '+dmFormix.fPrepAreaFilter;
 {Setup the printer comm port}
 PrinterStr := dmFormix.GetTermRegString(r_PrinterSetup);
 if PrinterStr <> '' then
  begin
   if PrinterCommPort = nil then PrinterCommPort := TComPort.Create(nil);
   if PrinterCommPort.Connected then PrinterCommPort.Close;
   try
    PrinterCommPort.Port        := GetComPortFromString(PrinterStr);
    PrinterCommPort.BaudRate    := GetBaudRate(GetBaudRateFromString(PrinterStr));
    PrinterCommPort.DataBits    := GetDataBits(GetDataBitsFromString(PrinterStr));
    PrinterCommPort.Parity.Bits := GetParity(GetParityFromString(PrinterStr));
    PrinterCommPort.StopBits    := GetStopBits(GetStopBitsFromString(PrinterStr));
    PrinterCommPort.FlowControl.FlowControl := GetFlowControl(GetFlowControlFromString(PrinterStr));
    PrinterCommPort.EventChar := #13;
    i := 0;
    while (not PrinterCommPort.Connected) and
          (i < 5) do
     begin
      PrinterCommPort.Open;
      Inc(i);
      Sleep(250);
     end;
   except
    on E:Exception do
     begin
      TermMessageDlg('Unable To Open Printer Port',mtError,[mbOk],0);
      PrinterCommPort.Free;
      PrinterCommPort := nil;
     end;
   end;
(*   PrinterCommPort := TComPort.Create(nil);
   PrinterCommPort.Port        := GetComPortFromString(PrinterStr);
   PrinterCommPort.BaudRate    := GetBaudRate(GetBaudRateFromString(PrinterStr));
   PrinterCommPort.DataBits    := GetDataBits(GetDataBitsFromString(PrinterStr));
   PrinterCommPort.Parity.Bits := GetParity(GetParityFromString(PrinterStr));
   PrinterCommPort.StopBits    := GetStopBits(GetStopBitsFromString(PrinterStr));
   PrinterCommPort.FlowControl.FlowControl := GetFlowControl(GetFlowControlFromString(PrinterStr));
   PrinterCommPort.EventChar := #13;
   //PrinterCommPort.OnRxChar := PrinterCommPortRxChar;
   PrinterCommPort.Open;*)
  end;
 BarcodeScanned := '';
 for col := 0 to DBGridHSL1.Columns.Count-1 do
 begin
   if (DBGridHSL1.Columns[Col].FieldName = rmdOrderListMixesDesc.FieldName) then
   begin
     if dmFormix.fShowMixesDoneforArea then //change column title from 'Mixes' to 'Area Mixes'.
     begin
       DBGridHSL1.Columns[Col].Title.Caption := 'Area Mixes';
       DBGridHSL1.Columns[Col].Width := 85;
     end;  
   end
   else if (DBGridHSL1.Columns[Col].FieldName = rmdOrderListWeightDesc.FieldName)
   or (DBGridHSL1.Columns[Col].FieldName = rmdOrderListOrderWtDesc.FieldName) then
   begin
     if dmFormix.fShowMixesDoneforArea then // dont show weights relating to all prep areas
       DBGridHSL1.Columns[Col].Visible := false;
   end
   else if (DBGridHSL1.Columns[Col].FieldName = rmdOrderListCalculatedAt.FieldName) then
   begin
     if not dmFormix.fShowMixesDoneforArea then  // no room to show CalculatedAt field.
       DBGridHSL1.Columns[Col].Visible := false;
   end;
 end;
 ChangeOrderList(true{ForDateChange});//resets tmGridRefresh interval.
 tmGridRefresh.Enabled := true;
end;

procedure TfrmFormixMain.actNextDayExecute(Sender: TObject);
begin
 {Increase the selected day by one}
 fSelectedDate := fSelectedDate + 1;
 ChangeOrderList(true{ForDateChange});
end;

procedure TfrmFormixMain.actPreviousDayExecute(Sender: TObject);
begin
 {Decrease the selected day by one}
 fSelectedDate := fSelectedDate - 1;
 ChangeOrderList(true{ForDateChange});
end;

procedure TfrmFormixMain.dtpSelectedDateChange(Sender: TObject);
begin
// ChangeOrderList(true{ForDateChange});
end;

procedure TfrmFormixMain.ChangeOrderList(ForDateChange : boolean);
var HoldOrder: String;
    RecsAdded : integer;
    TmrWasEnabled : boolean;
begin
  {Get the correct list of orders for the selected day and workgroup}
  HoldOrder := '';
  TmrWasEnabled := tmGridRefresh.Enabled;
  tmGridRefresh.Enabled := false;
  tmGridRefresh.Interval := NormRefreshInterval; //might get changed below.
  try
    dtpSelectedDate.Text := DateToStr(fSelectedDate);
    DisableButtons;
    try
      rmdOrderList.DisableControls;
      try
        Screen.Cursor := crHourGlass;
        try
          if  (not ForDateChange)
          and (not rmdOrderList.IsEmpty) then // restore cursor to same Order at the end.
            HoldOrder := rmdOrderListOrder.Value;
          try
            RecsAdded := 0;
            rmdOrderList.EmptyTable;
            if (dmFormix <> nil) and
               (dmFormix.pvtblOrderHeader.Active) then
            begin
              dmFormix.pvtblOrderHeader.CancelRange;
              dmFormix.pvtblOrderHeader.IndexFieldNames := OH_ScheduleDate+';'+OH_OrderNo+';'+OH_OrderNoSuffix;
              dmFormix.pvtblOrderHeader.SetRange([Trunc(fSelectedDate)+693974],[Trunc(fSelectedDate)+693974]);
              dmFormix.pvtblOrderHeader.First;
              while not dmFormix.pvtblOrderHeader.Eof do
              begin
                {Need a check to make sure it is the correct group filter}
                if (TStatusType(dmFormix.pvtblOrderHeader.FindField(OH_Status).AsInteger) in [StatusWIP,StatusComp]) and
                   (Str_Equal(edWorkGroup.Text,dmFormix.pvtblOrderHeader.FindField(OH_WorkGroup).AsString,
                            Length(edWorkGroup.Text))) then
                begin
                  AddUpdateRecordToList(0{CurrentMixNo},
                                        (    (HoldOrder = '')
                                         and (RecsAdded < fMaxOrdsVisible)){CalcCompletion});
                  Inc(RecsAdded);
                end;
                dmFormix.pvtblOrderHeader.Next;
              end;
            end;
          finally
            if HoldOrder = '' then //show first Orders that have already been status calcuated.
              rmdOrderList.First
            else //scroll to order and cause a refresh.
            begin
              if not rmdOrderList.Locate(rmdOrderListOrder.FieldName,HoldOrder,[]) then
              begin
                rmdOrderList.First;
                {move cursor down grid to rec after desired rec}
                while (not rmdOrderList.Eof)
                and   (rmdOrderListOrder.AsString < HoldOrder) do
                  rmdOrderList.Next;
              end;
              tmGridRefresh.Interval := ScrollRefreshInterval;//make completion calc occur in 2 secs.
            end;
          end;
        finally
          Screen.Cursor := crDefault;
        end;
      finally
        rmdOrderList.EnableControls;
      end;
    finally
      EnableButtons;
    end;
  finally
    fOrderListLastRebuiltAt := Now;
    tmGridRefresh.Enabled := TmrWasEnabled;
  end;
end;

procedure TfrmFormixMain.actProcessRecipeExecute(Sender: TObject);
var //ScaleStr: String;
    OrderIdStr: string;
    MixBarcode: string;
    EnteredOk : boolean;
    TmrWasEnabled : boolean;
begin
 {Process the selected recipe in the list}
 if DBGridHSL1.DataSource.DataSet.IsEmpty then exit;
 TmrWasEnabled := tmGridRefresh.Enabled;
 tmGridRefresh.Enabled := FALSE;
 try
   try
     //dmFormix.OverrideUser := '';
     OrderIdStr := rmdOrderListOrder.AsString;
     if dmFormix.pvtblOrderHeader.Locate(OH_OrderNo+';'+OH_OrderNoSuffix,
                                         VarArrayOf([rmdOrderListWrkOrder.AsInteger,rmdOrderListWrkSuffix.AsInteger]),
                                         []) then
     begin
       //Order still exists in DB.
       try
         if dmFormix.GetTermRegBoolean(r_SFXMixScanAtOrderSelect) then
         begin
           MixBarcode := TfrmFormixStdEntry.GetStdStringEntry(
                                      'Select Mix for Order '+OrderIdStr,
                                      'Mix Label Barcode',35,
                                       EnteredOk,
                                       false{IsPassword},'',true{MustEnterVal},
                                       true{PasswordedKeyboard});
           if EnteredOk then
           begin
             if (dmFormix.GetOrderNoFromMixBarcode(MixBarcode) <>
                            dmFormix.pvtblOrderHeader.FieldByName(OH_OrderNo).AsInteger)
             or (dmformix.GetOrdNoSuffixFromMixBarcode(MixBarcode) <>
                            dmFormix.pvtblOrderHeader.FieldByName(OH_OrderNoSuffix).AsInteger) then
               TermMessageDlg('Barcode is not related to Order '+OrderIdStr,
                              mtError,[mbOk],0)
             else
               TfrmFormixProcessRecipe.ProcessRecipe(rmdOrderList,
                                                     dmFormix.GetMixNoFromMixBarcode(MixBarcode));
           end;
         end
         else
         begin
           TfrmFormixProcessRecipe.ProcessRecipe(rmdOrderList, 0);
         end;
       finally
         dmFormix.pvtblOrderHeader.CancelRange;
         dmFormix.pvtblOrderHeader.IndexFieldNames := OH_ScheduleDate+';'+OH_OrderNo+';'+OH_OrderNoSuffix;
         dmFormix.pvtblOrderHeader.SetRange([Trunc(fSelectedDate)+693974],[Trunc(fSelectedDate)+693974]);
         rmdOrderList.Locate(rmdOrderListOrder.fieldName,OrderIdStr,[]);
       end;
     end
     else // Order not found
       ChangeOrderList(false);
   except
     on e:exception do
       TermMessageDlg(e.message,mtError,[mbOk],0);
   end;
 finally
   tmGridRefresh.Interval := ScrollRefreshInterval; //1 sec
   tmGridRefresh.Enabled :=  TmrWasEnabled;
 end;
end;

procedure TfrmFormixMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if Assigned(PrinterCommPort) then
  begin
   if PrinterCommPort.Connected then PrinterCommPort.Close;
   FreeAndNil(PrinterCommPort);
  end;
 rmdOrderList.Close;
end;

procedure TfrmFormixMain.DBGrid1DblClick(Sender: TObject);
begin
 actProcessRecipe.Execute;
end;

procedure TfrmFormixMain.dtpSelectedDateEnter(Sender: TObject);
var
 TempStr : string;
 EnteredOk : boolean;
 TmrWasEnabled : boolean;
begin
 TmrWasEnabled := tmGridRefresh.Enabled;
 tmGridRefresh.Enabled := false;
 try
   TempStr := TfrmFormixDatePick.GetDateStr('','Select schedule date of order(s)',
                                              EnteredOk, fSelectedDate);
   if EnteredOk then
   begin
     fSelectedDate := StrToDate(TempStr);
     ChangeOrderList(true{ForDateChange}); //resets tmGridRefresh interval.
   end;
 finally
   tmGridRefresh.Enabled :=  TmrWasEnabled;
 end;
end;

procedure TfrmFormixMain.FormShow(Sender: TObject);
begin
 dbgridHSL1.SetFocus;
 UpdateCurrentUserText;
end;

procedure TfrmFormixMain.tmGridRefreshTimer(Sender: TObject);
begin
  tmGridRefresh.Enabled := false;
  try
    {Note: WithinPastMinutes() has not been used because it ignores fractions of a minute}
    if not WithinPastSeconds(Now, fOrderListLastRebuiltAt, 5*60) then
      ChangeOrderList(false{ForDateChange}) // resets tmGridRefresh interval
    else {refresh progress of orders currently in list}
      RefreshOrders; // sets tmGridRefresh interval to 10 secs
  finally
    tmGridRefresh.Enabled := true;
  end;
end;

procedure TfrmFormixMain.btExitClick(Sender: TObject);
begin
 Close;
end;

procedure TfrmFormixMain.actSetupMenuExecute(Sender: TObject);
var
    TmrWasEnabled : boolean;
begin
  TmrWasEnabled := tmGridRefresh.Enabled;
  tmGridRefresh.Enabled := false;
  try
    {Launch the setup screen}
    if GetTerminalPassword then
    begin
      frmFormixSetupScreen := TfrmFormixSetupScreen.Create(Self);
      with frmFormixSetupScreen do
      begin
        ShowModal;
        Free;
      end;
      {Reload the correct settings in case any have changed}
      edWorkGroup.Text := dmFormix.GetTermRegString(r_WorkGroupFilter);
      lbPrepFilter.Caption := 'Prep. Area: '+dmFormix.fPrepAreaFilter;
      ChangeOrderList(false{ForDateChange});
    end;
// else MessageDlg('Invalid Scale Password Entered',mtError,[mbOk],0);
  finally
    tmGridRefresh.Enabled :=  TmrWasEnabled;
  end;
end;
(*
procedure TfrmFormixMain.PrinterCommPortRxChar(Sender: TObject; Count: Integer);
var TempStr: String;
    i : Integer;

    procedure StripString;
    var j : Integer;
    begin
     CheckStr := '';
     for j := 1 to Length(StrFromPrinter) do
      if SameText(StrFromPrinter[j],'0') or
         SameText(StrFromPrinter[j],'1') or
         SameText(StrFromPrinter[j],'2') or
         SameText(StrFromPrinter[j],'3') or
         SameText(StrFromPrinter[j],'4') or
         SameText(StrFromPrinter[j],'5') or
         SameText(StrFromPrinter[j],'6') or
         SameText(StrFromPrinter[j],'7') or
         SameText(StrFromPrinter[j],'8') or
         SameText(StrFromPrinter[j],'9') or
         SameText(StrFromPrinter[j],#13) then
        CheckStr := CheckStr+StrFromPrinter[j];
    end;

begin
 TempStr := '';
 PrinterCommPort.ReadStr(TempStr,Count);
 PrinterCommPort.ClearBuffer(TRUE,FALSE);
 StrFromPrinter := StrFromPrinter + TempStr;
// CheckStr := CheckStr + TempStr;
 i := Pos(#13,StrFromPrinter);
 while i > 0 do
  begin
   if (NextLineIsAnswer) or (StrFromPrinter[1] in ['0'..'9',#13]) then
    begin
     StripString;
     if (CheckStr <> '') and
        (not (CheckStr[Length(CheckStr)] = #13)) then PrinterErrorCode := StrToInt(CheckStr);
     StrFromPrinter := '';
     NextLineIsAnswer := FALSE;
     Break;
    end
   else
    begin
     if Pos('?PRSTAT',Copy(StrFromPrinter,1,i-1)) > 0 then NextLineIsAnswer := TRUE
                                                      else NextLineIsAnswer := FALSE;
     StrFromPrinter := Copy(StrFromPrinter,i+1,Length(StrFromPrinter)-i);
    end;
   i := Pos(#13,StrFromPrinter);
  end;

end;
*)
procedure TfrmFormixMain.FormKeyPress(Sender: TObject; var Key: Char);
begin
 if Key = Chr(STX) then
  begin
   BarcodeScanned := '';
   Exit;
  end;
 if Key = #13 then
  begin
   ProcessBarcode;
   Exit;
  end;
 BarcodeScanned := BarcodeScanned + Key;
end;

procedure TfrmFormixMain.ProcessBarcode;
var WrkOrderNo,
    WrkRevision,
    WrkMix: Integer;
//    LineNo: Integer;
    OHIndex: String;
begin
 if BarcodeScanned <> '' then
  begin
   if Length(BarcodeScanned) = 14 then
    begin
     WrkOrderNo  := StrToInt(Copy(BarcodeScanned,1,6));
     WrkRevision := StrToInt(Copy(BarcodeScanned,7,2));
     WrkMix      := StrToInt(Copy(BarcodeScanned,9,4));
     if (WrkOrderNo > 0) and (WrkRevision > 0) then
      begin
       dmFormix.pvtblOrderHeader.DisableControls;
       try
         dmFormix.pvtblOrderHeader.CancelRange;
         OHIndex := dmFormix.pvtblOrderHeader.IndexName;
         dmformix.pvtblOrderHeader.IndexName := 'ByOrder';
         try
           if dmFormix.pvtblOrderHeader.Locate(OH_OrderNo+';'+OH_OrderNoSuffix,
                                               VarArrayOf([WrkOrderNo,WrkRevision]),[]) then
            begin
    //         LineNo := 0;
             if dmFormix.pvtblOrderHeader.FindField(OH_FixedSequence).AsBoolean then
              begin
               {LineNo :=} dmFormix.FindNextWipLineForTerminal(1);
              end;
             if WrkMix < dmFormix.pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger then
              begin
               {Now we should have the order selected so go into the process orders screen}
               actProcessRecipe.Execute;
              end
             else TermMessageDlg('Mix No. '+IntToStr(WrkMix)+
                                 ' not valid for Order '+OrderNoToString(WrkOrderNo,WrkRevision),
                                 mtError,[mbOk],0);
            end
           else TermMessageDlg('Order : '+OrderNoToString(WrkOrderNo, WrkRevision)+
                                          ' not found',mtError,[mbOk],0);
         finally
           dmformix.pvtblOrderHeader.IndexName := OHIndex;
           ChangeOrderList(false{ForDateChange});//restore Order Header range.
         end;
       finally
         dmFormix.pvtblOrderHeader.EnableControls;
       end;
      end
     else TermMessageDlg('Invalid Mix Barcode Scanned: '+BarcodeScanned,mtError,[mbOk],0);
    end
   else TermMessageDlg('Invalid Mix Barcode Scanned: '+BarcodeScanned,mtError,[mbOk],0);
  end;
end;

procedure TfrmFormixMain.DBGrid1CellClick(Column: TColumn);
begin
 actProcessRecipe.Execute;
end;

procedure TfrmFormixMain.DisableButtons;
begin
 btNextDate.Enabled      := FALSE;
 btPreviousDate.Enabled  := FALSE;
 btSetupMenu.Enabled     := FALSE;
 btExit.Enabled          := FALSE;
 btUp.Enabled            := FALSE;
 btDown.Enabled          := FALSE;
 dtpSelectedDate.Enabled := FALSE;
end;

procedure TfrmFormixMain.EnableButtons;
begin
 btNextDate.Enabled      := TRUE;
 btPreviousDate.Enabled  := TRUE;
 btSetupMenu.Enabled     := TRUE;
 btExit.Enabled          := TRUE;
 btUp.Enabled            := TRUE;
 btDown.Enabled          := TRUE;
 dtpSelectedDate.Enabled := TRUE;
end;

procedure TfrmFormixMain.DBGridHSL1DrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
var
 TextColour : TColor;
 FontStyle : TFontStyles;
 Grid : TDBGrid;
begin
  Grid := TDBGrid(Sender);
  SetCanvasForStandardGridCell(Grid, State, clBlack);
  TextColour := Grid.Canvas.Font.Color; //start with default colour
  FontStyle := Grid.Canvas.Font.Style - [fsBold, fsItalic];//make sure it defaults to normal font
  if not rmdOrderList.IsEmpty then
  begin
    if rmdOrderListCalculatedAt.AsFloat = 0.0 then
    begin
      FontStyle := FontStyle + [fsItalic];
    end
    else
    begin
      if Column.FieldName = rmdOrderListCalculatedAt.FieldName then
        TextColour := clGray
      else if (not rmdOrderListIsCompInPrepArea.AsBoolean) then {real work to do - make font BOLD}
      begin
        FontStyle := FontStyle + [fsBold];
        TextColour := clBlue;
      end
      else if  (FormixIni.QAServiceURL <> '')
           and (not rmdOrderListQAComplete.AsBoolean) then //something still needs doing
      begin
        FontStyle := FontStyle + [fsBold];
        TextColour := clMaroon;
      end
      else //finished
      begin
        TextColour := clGray;
        {FontStyle := FontStyle - [fsBold] + [fsItalic];}
      end;
    end;
  end;
  if TextColour <> Grid.Canvas.Font.Color then {not black or white - special colour needs to be shown}
  begin
    {assume Text colour is fairly dark}
    if (Grid.Canvas.Brush.Color = clHighlight) then {on a selected line}
      Grid.Canvas.Brush.Color := TextColour {apply special colour to background}
    else
      Grid.Canvas.Font.Color := TextColour; {apply special colour to text}
  end;
  Grid.Canvas.Font.Style := FontStyle;
  Grid.Canvas.Pen.Color := Grid.Canvas.Brush.Color;
  DrawBrowserGridColumnCell(Grid, Rect, DataCol, Column, State);
end;

procedure TfrmFormixMain.imDownClick(Sender: TObject);
var i: Integer;
begin
 if dbgridhsl1.VisibleRowCount < fMaxOrdsVisible then
   rmdOrderList.Last //put cursor on record that should be in last row
 else //scroll down by one page
 begin
   for i := 1 to fMaxOrdsVisible do
     if (not rmdOrderList.Eof) then
       rmdOrderList.Next;
  end;
end;

procedure TfrmFormixMain.imUpClick(Sender: TObject);
var i: Integer;
begin
 if dbgridhsl1.VisibleRowCount < fMaxOrdsVisible then
   rmdOrderList.First //put cursor on record that should be in top row
 else //scroll up by one page
  begin
   for i := 1 to fMaxOrdsVisible do
     if not rmdOrderList.Bof then
       rmdOrderList.Prior;
  end;
end;

procedure TfrmFormixMain.RefreshColsInRmdOrderListWithOrdAndMixProgress(ShowMixNo : integer);
{REQUIRES: rmdOrderList to be in Insert or Edit mode.
}
var
    AreaQADoneOnCurrMix : boolean;
    NoOfMixesWithAreaQADone : integer;
    CurrMixCompleteInArea : boolean;
    NoOfMixesCompleteInArea : integer;
begin
   dmFormix.GetAreaQAStatusOnMixes(AreaQADoneOnCurrMix, NoOfMixesWithAreaQADone,
                               dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                               dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                               dmFormix.pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger );
   if dmFormix.fPrepAreaFilter <> '*' then
   begin
     {Calculate whether Order is complete in the Preparation Area so that
      we can display Order in a colour that indicates whether the Prep Area
      still has work to do.
     }
     dmFormix.GetCompleteInAreaStatForMixes(CurrMixCompleteInArea, NoOfMixesCompleteInArea,
                                    dmFormix.pvtblOrderHeader.FindField(OH_CurrentMix).AsInteger);
     rmdOrderListIsCompInPrepArea.AsBoolean := NoOfMixesCompleteInArea >= dmFormix.pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger;
   end
   else
   begin
     rmdOrderListIsCompInPrepArea.AsBoolean :=
                           dmFormix.pvtblOrderHeader.FindField(OH_MixesDone).AsInteger >=
                              dmFormix.pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger;
   end;
   if dmFormix.fShowMixesDoneforArea then
   begin
     rmdOrderListMixesDesc.AsString := IntToStr(NoOfMixesCompleteInArea)+
                ' of '+ IntToStr(dmFormix.pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger);
     rmdOrderListWeightDesc.AsString := '';
     rmdOrderListOrderWtDesc.AsString := '';
   end
   else
   begin
     rmdOrderListMixesDesc.AsString := IntToStr(dmFormix.pvtblOrderHeader.FindField(OH_MixesDone).AsInteger)+
                ' of '+ IntToStr(dmFormix.pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger);
     rmdOrderListWeightDesc.AsString := IntToStr(Trunc(DivDouble(100*dmFormix.pvtblOrderHeader.FindField(OH_TotalWeightDone).AsFloat,
                                                           dmFormix.pvtblOrderHeader.FindField(OH_TotalWeightRequired).AsFloat)))+
                                  '% of '+FormatFloat('#,0.000',dmFormix.pvtblOrderHeader.FindField(OH_TotalWeightRequired).AsFloat);
     rmdOrderListOrderWtDesc.AsString := FormatFloat('#,0.000',dmFormix.pvtblOrderHeader.FindField(OH_TotalWeightDone).AsFloat)+'kg of '+
                                  FormatFloat('#,0.000',dmFormix.pvtblOrderHeader.FindField(OH_TotalWeightRequired).AsFloat)+'kg';
   end;
   rmdOrderListCurrentMixQADone.AsBoolean := AreaQADoneOnCurrMix;
   rmdOrderListQAComplete.AsBoolean := NoOfMixesWithAreaQADone >= dmFormix.pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger;

{
   rmdOrderListWeightDesc.AsString := FormatFloat('#,0.000',dmFormix.pvtblOrderHeader.FindField(OH_TotalWeightDone).AsFloat)+'/'+
                                 FormatFloat('#,0.000',dmFormix.pvtblOrderHeader.FindField(OH_TotalWeightRequired).AsFloat);
}
   if ShowMixNo > 0 then
   begin
     rmdOrderListCurrentMixWtReqd.AsFloat := dmFormix.CalcCompensatedBatchMixWt(ShowMixNo);
     rmdOrderListCurrentMixWtDone.AsFloat := dmFormix.GetTotalWtDoneOnMix(
                                                       dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                                       dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger,
                                                       ShowMixNo);
     rmdOrderListCurrentMixDesc.AsString := FormatFloat('#,0.000',rmdOrderListCurrentMixWtDone.AsFloat)+'kg of '+
                                       FormatFloat('#,0.000',rmdOrderListCurrentMixWtReqd.AsFloat)+'kg';
   end
   else
   begin
     rmdOrderListCurrentMixWtReqd.AsFloat := 0.0;
     rmdOrderListCurrentMixWtDone.AsFloat := 0.0;
     rmdOrderListCurrentMixDesc.AsString  := '';
   end;
   rmdOrderListMixNoDesc.AsString := IntToStr(ShowMixNo);
   rmdOrderListMixesRequired.AsInteger := dmFormix.pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger;
   rmdOrderListCalculatedAt.AsDateTime := Now;
end;

procedure TfrmFormixMain.AddUpdateRecordToList(CurrentMixNo : integer; CalcCompletion : boolean);
{REQUIRES: pvtblOrderHeader to be located on the Order to be added or updated in rxmOrderList.
 PROMISES: Aborts operation if pvtblOrderHeader does not belong to rmdOrderList (different
           schedule date; this can happen if if ProcessRecipe was called for a scan of a
           mix label barcode).
}
var WrkRecipeDesc: String;
    WrkRecipeMixes,
    WrkRecipeType: Integer;
    OrderIsComplete: Boolean;

begin
 if dmFormix.pvtblOrderHeader.FindField(OH_ScheduleDate).AsInteger <> Trunc(fSelectedDate)+693974 then
   EXIT;
 {Get matching recipe}
 WrkRecipeDesc  := '';
 WrkRecipeMixes := 0;
 WrkRecipeType  := -1;
 OrderIsComplete := FALSE;
 try
   if dmFormix.pvtblRecipeHeader.Locate(RH_RecipeCode,dmFormix.pvtblOrderHeader.FindField(OH_RecipeCode).AsString,[]) then
   begin
     WrkRecipeDesc := dmFormix.pvtblRecipeHeader.FindField(RH_Description).AsString;
     WrkRecipeType := dmFormix.pvtblRecipeHeader.FindField(RH_MixMethod).AsInteger;
   end;
   WrkRecipeType := dmFormix.pvtblOrderHeader.FindField(OH_MixType).AsInteger;
   OrderIsComplete := (dmFormix.pvtblOrderHeader.FindField(OH_MixesDone).AsInteger =
                     dmFormix.pvtblOrderHeader.FindField(OH_MixesRequired).AsInteger) or
                    (TStatusType(dmFormix.pvtblOrderHeader.FindField(OH_Status).AsInteger) = StatusComp);
   if rmdOrderList.Locate('Order',
                          OrderNoToString(dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                          dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger),
                          []) then
     rmdOrderList.Edit
   else
   begin
     rmdOrderList.Append;
     rmdOrderListOrder.AsString := OrderNoToString(dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                                   dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger);
     rmdOrderListWrkOrder.AsInteger  := dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger;
     rmdOrderListWrkSuffix.AsInteger := dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger;

   end;
   rmdOrderListRecipe.AsString := dmFormix.pvtblOrderHeader.FindField(OH_RecipeCode).AsString;
   rmdOrderListDescription.AsString := WrkRecipeDesc;
   rmdOrderListMixTypeDesc.AsString := dmFormix.GetMixMethodDescription(WrkRecipeType);
   rmdOrderListIsComplete.AsBoolean := OrderIsComplete;
   rmdOrderListCurrentStatus.AsInteger := dmFormix.pvtblOrderHeader.FindField(OH_Status).AsInteger;
   if CalcCompletion then
     RefreshColsInRmdOrderListWithOrdAndMixProgress(CurrentMixNo);
   rmdOrderList.Post;
 except
   on E: Exception do
   begin
     rmdOrderList.Cancel;
     TermMessageDlg(E.Message,mtError,[mbOk],0);
   end;
 end;
end;

procedure TfrmFormixMain.RefreshOrders;
var
//    CursorWrkOrdNo, CursorWrkSuffix : integer;
    CursorWrkOrdStr : string;
    FirstWrkOrdNo, FirstWrkSuffix : integer;
    BottomWrkOrdNo, BottomWrkSuffix : integer;
    NextRowWillBeVisibleInGrid : boolean;
    VisRowsUpdated : integer;
    TmrWasEnabled : boolean;
    CurrentGridRow : integer;
begin
// CursorWrkOrdNo  := 0;
// CursorWrkSuffix := 0;
 CursorWrkOrdStr := '';
 FirstWrkOrdNo := 0;
 FirstWrkSuffix:= 0;
 BottomWrkOrdNo := 0;
 BottomWrkSuffix:= 0;
 TmrWasEnabled := tmGridRefresh.Enabled;
 tmGridRefresh.Enabled := false;
 try
   rmdOrderList.DisableControls;
   try
     try
       if not rmdOrderList.IsEmpty then
       begin
         if DBGridHSL1.VisibleRowCount > 1 then //move to record in top row and save OrderNo
         begin
           //CursorWrkOrdNo  := rmdOrderListWrkOrder.AsInteger;
           //CursorWrkSuffix := rmdOrderListWrkSuffix.AsInteger;
           CursorWrkOrdStr := rmdOrderListOrder.AsString;
           CurrentGridRow := DBGridHSL1.VisibleRowCount - TGridControl(DBGridHSL1).OffsetFromLastRow;
           {Move to top and save Order number}
           rmdOrderList.MoveBy(-(CurrentGridRow -1));
           FirstWrkOrdNo := rmdOrderListWrkOrder.AsInteger;
           FirstWrkSuffix:= rmdOrderListWrkSuffix.AsInteger;
           {move to middle and save order number}
           rmdOrderList.MoveBy(fMaxOrdsVisible -1 );
           BottomWrkOrdNo  := rmdOrderListWrkOrder.AsInteger;
           BottomWrkSuffix := rmdOrderListWrkSuffix.AsInteger;
         end;
       end;
       VisRowsUpdated := 0;
       dmFormix.pvtblOrderHeader.CancelRange;
       dmFormix.pvtblOrderHeader.IndexFieldNames := OH_ScheduleDate+';'+OH_OrderNo+';'+OH_OrderNoSuffix;
       dmFormix.pvtblOrderHeader.SetRange([Trunc(fSelectedDate)+693974],[Trunc(fSelectedDate)+693974]);
       dmFormix.pvtblOrderHeader.First;
       while not dmFormix.pvtblOrderHeader.Eof do
       begin
         NextRowWillBeVisibleInGrid := false;
         if (dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger > FirstWrkOrdNo)
         or (   (dmformix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger = FirstWrkOrdNo)
             and(dmformix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger >= FirstWrkSuffix)) then
           NextRowWillBeVisibleInGrid := VisRowsUpdated < fMaxOrdsVisible;

         if rmdOrderList.Locate('Order',
                                OrderNoToString(dmFormix.pvtblOrderHeader.FindField(OH_OrderNo).AsInteger,
                                                dmFormix.pvtblOrderHeader.FindField(OH_OrderNoSuffix).AsInteger),
                                []) then
         begin
           if not (TStatusType(dmFormix.pvtblOrderHeader.FindField(OH_Status).AsInteger) in [StatusWIP,StatusComp]) then
             rmdOrderList.Delete
           else //update record in mem table.
           begin
             {Only recal status if visible and hasnt been done for 10 secs (avoids
              recalculating status everytime user scrolls up and down which causes
              a quick refresh).
             }
             AddUpdateRecordToList(0{CurrentMixNo},
                                   (    NextRowWillBeVisibleInGrid
                                    and (not WithinPastMilliSeconds(Now,
                                                               rmdOrderListCalculatedAt.AsDateTime,
                                                               NormRefreshInterval))){CalcCompletion}
                                  );
             if NextRowWillBeVisibleInGrid then
             begin
               Inc(VisRowsUpdated);
             end;
           end;
         end
         else //this order is not currently in the mem table.
         begin
           if (TStatusType(dmFormix.pvtblOrderHeader.FindField(OH_Status).AsInteger) in [StatusWIP,StatusComp]) and
              (Str_Equal(edWorkGroup.Text,dmFormix.pvtblOrderHeader.FindField(OH_WorkGroup).AsString,
                     Length(edWorkGroup.Text))) then  //add it to the mem table
           begin
             AddUpdateRecordToList(0{CurrentMixNo}, NextRowWillBeVisibleInGrid{CalcCompletion});
             if NextRowWillBeVisibleInGrid then
             begin
               Inc(VisRowsUpdated);
             end;
           end;
         end;
         dmFormix.pvtblOrderHeader.Next;
       end;//while
     except
       on E:Exception do
         TermMessageDlg('Error :'+E.Message,mtError,[mbOk],0);
     end;
   finally
     rmdOrderList.EnableControls;
     if CursorWrkOrdStr > '' then
     begin
       {Locate() on memory dataset will put record at bottom of grid}
       if not rmdOrderList.Locate(rmdOrderListWrkOrder.FieldName+';'+rmdOrderListWrkSuffix.FieldName,
                                  VarArrayOf([BottomWrkOrdNo,BottomWrkSuffix]),[]) then
         rmdOrderList.Last;
       {move cursor up grid to desired rec, or one before}
       while (not rmdOrderList.Bof)
       and   (rmdOrderListOrder.AsString > CursorWrkOrdStr) do
         rmdOrderList.Prior;
     end;
   end;
 finally
   tmGridRefresh.Interval := NormRefreshInterval; //10 secs
   tmGridRefresh.Enabled :=  TmrWasEnabled;
 end;
end;

procedure TfrmFormixMain.btnTestFuncClick(Sender: TObject);
begin
  ShowMessage(dmFops.GetTranProducerIdDesc(100,8634));
  ShowMessage(dmFops.GetTranProducerIdDesc(100,8634));
  ShowMessage(dmFops.GetTranProducerIdDesc(37,1510));
  ShowMessage(dmFops.GetTranProducerIdDesc(100,8637));
  ShowMessage(dmFops.GetTranProducerIdDesc(0,3651));
  ShowMessage(dmFops.GetTranPurchaseOrderStr(1,39));
  ShowMessage(dmFops.GetTranPurchaseOrderStr(1,39));
end;


procedure TfrmFormixMain.dtpSelectedDateExit(Sender: TObject);
begin
  dtpSelectedDate.Text := DateToStr(fSelectedDate);
end;

procedure TfrmFormixMain.rmdOrderListAfterScroll(DataSet: TDataSet);
begin
  tmGridRefresh.Interval := ScrollRefreshInterval;//changing interval value will kill and create a Windows timer
end;

procedure TfrmFormixMain.tmClockTimer(Sender: TObject);
begin
  lbTime.Caption := FormatDateTime('hh:mm:ss',Now);
end;

procedure TfrmFormixMain.UpdateCurrentUserText;
begin
 lbUser.Caption := 'User: '+dmFormix.GetCurrentUser;
end;

end.

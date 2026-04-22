unit ufrmViewTransactions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  uDBFunctions,Dialogs, StdCtrls, DB, Grids, DBGrids, ExtCtrls, udmFormix, RxMemDS;

type
  TfrmViewTransactions = class(TForm)
    Panel1: TPanel;
    DBGrid1: TDBGrid;
    DataSource1: TDataSource;
    lblGridHeader: TLabel;
    Button1: TButton;
    rxmemTrans: TRxMemoryData;
    btnPrevIngredient: TButton;
    btnNextIngredient: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure rxmemTransFilterRecord(DataSet: TDataSet;
      var Accept: Boolean);
    procedure btnNextIngredientClick(Sender: TObject);
    procedure btnPrevIngredientClick(Sender: TObject);
  private
    { Private declarations }
    fOrderNo,
    fOrderNoSuffix,
    fOrderLineNo  : integer;
    dmLocalFormix : TdmFormix;
  public
    { Public declarations }
    procedure ShowTransForOrder(OrderNo, OrderNoSuffix, CurrentOrderLineNo : integer);
    procedure RefreshGrid;
  end;


implementation
uses uFopsLib, uStdUtl, udmDatabaseModule, uFopsDBInit, uTermDialogs, uGridControl, udmFormixBase;
{$R *.dfm}

procedure TfrmViewTransactions.FormCreate(Sender: TObject);
begin
  dmLocalFormix := TdmFormix.Create(nil,MainDatabaseModule);
  try
    dmLocalFormix := nil;
    dmLocalFormix := TdmFormix.Create(nil,MainDatabaseModule);
    with dmLocalFormix do
    begin
      MakeConnection;
      pvtblTransactions.Open;
      pvtblOrderLine.Open;
      pvtblIngredients.Open;
      rxmemTrans.CopyStructure(pvtblTransactions);
      DatasetCopyDisplayProperties(rxmemTrans, pvtblTransactions);
      rxmemTrans.Open;
      MoveGridFieldToColumnIndex(DBGrid1, TRN_OrderLineNo, 0);
      MoveGridFieldToColumnIndex(DBGrid1, TRN_Ingredient, 1);
      MoveGridFieldToColumnIndex(DBGrid1, TRN_MixNo, 2);
      MoveGridFieldToColumnIndex(DBGrid1, TRN_ContainerNo, 3);
      MoveGridFieldToColumnIndex(DBGrid1, TRN_BatchNo, 4);
      MoveGridFieldToColumnIndex(DBGrid1, TRN_LotNo, 5);
      MoveGridFieldToColumnIndex(DBGrid1, TRN_WeightOnScale, 6);
      MoveGridFieldToColumnIndex(DBGrid1, TRN_UserId, 7);
    end;
  except
    on E:Exception do
    begin
      TermMessageDlg('Unable To Connect To Formix Database.'+#13#10+
                     'Error: '+E.Message,mtError,[mbOk],0);
      Application.Terminate;
    end;
  end;
end;

procedure TfrmViewTransactions.RefreshGrid;
var
  IngredientCode : string;
begin
  with dmLocalFormix do
  begin
    rxmemTrans.Filtered := false;
    IngredientCode := '';
    if fOrderLineNo > 0 then
    begin
{     doesnt work - use OnFilterRecord event
      rxmemTrans.Filter := TRN_OrderLineNo+' = '+IntToStr(fOrderLineNo);
}
      rxmemTrans.Filtered := true;
      if pvtblOrderLine.Locate(OL_OrderNo+';'+OL_OrderNoSuffix+';'+OL_LineNo,
                               VarArrayOf([fOrderNo, fOrderNoSuffix, fOrderLineNo]),[]) then
        IngredientCode := pvtblOrderLine.FieldByName(OL_Ingredient).AsString;
    end;
    lblGridHeader.Caption := 'Order: '+OrderNoToString(fOrderNo,fOrderNoSuffix)+
                             '  Line: '+ IntToZeroStr(fOrderLineNo,3);
    if  (IngredientCode <> '')
    and pvtblIngredients.Locate(ING_Ingredient, CorrectCode(IngredientCode, 8), []) then
      lblGridHeader.Caption := lblGridHeader.Caption + '  '+pvtblIngredients.FieldByName(ING_Description).AsString
    else
      lblGridHeader.Caption := lblGridHeader.Caption + '  ' +IngredientCode;
  end;
end;

procedure TfrmViewTransactions.ShowTransForOrder(OrderNo, OrderNoSuffix, CurrentOrderLineNo : integer);
begin
  with dmLocalFormix do
  begin
    fOrderNo       := OrderNo;
    fOrderNoSuffix := OrderNoSuffix;
    fOrderLineNo   := CurrentOrderLineNo;
    rxmemTrans.EmptyTable;
    pvtblTransactions.Filtered := false;
    pvtblTransactions.IndexFieldNames := TRN_OrderNo+';'+TRN_OrderNoSuffix+';'+TRN_MixNo+';'+TRN_OrderLineNo;
    pvtblTransactions.SetRange([fOrderNo, fOrderNoSuffix],[fOrderNo, fOrderNoSuffix]);
    pvtblTransactions.Filter := TRN_Status+' = 1';
    pvtblTransactions.Filtered := true;
    rxmemTrans.LoadFromDataSet(pvtblTransactions,0,lmAppend);
    rxmemTrans.SortOnFields(TRN_OrderNo+';'+TRN_OrderNoSuffix+';'+TRN_OrderLineNo+';'+TRN_MixNo);
    RefreshGrid;
  end;
end;


procedure TfrmViewTransactions.FormDestroy(Sender: TObject);
begin
  if dmLocalFormix <> nil then dmLocalFormix.Free;
end;

procedure TfrmViewTransactions.rxmemTransFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
begin
  Accept := (fOrderLineNo = 0)
         or (DataSet.FieldByName(TRN_OrderLineNo).AsInteger = fOrderLineNo);

end;

procedure TfrmViewTransactions.btnNextIngredientClick(Sender: TObject);
begin
  Inc(fOrderLineNo);
  RefreshGrid;
end;

procedure TfrmViewTransactions.btnPrevIngredientClick(Sender: TObject);
begin
  if fOrderLineNo > 0 then
    Dec(fOrderLineNo);
  RefreshGrid;
end;

end.

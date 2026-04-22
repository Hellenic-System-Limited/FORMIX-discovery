unit udmFops;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, BaseDM, HSLSecurity, DB, pvtables, btvtables, uTermDialogs,
  uStdCtv, uStdUtl, uCustomHSLSecurity, RxMemDS;

const
  ComBuf_DestinationId           = 'Destination_ID';
  ComBuf_ScheduleDate            = 'Schedule_Date';
  ComBuf_ScheduleTime            = 'Schedule_Time';
  ComBuf_ScheduleNo              = 'Schedule_No';
  ComBuf_IVersion                = 'I_Version';
  ComBuf_SourceId                = 'Source_ID';
  ComBuf_F6Transaction           = 'F6_Transaction';

  LabDet_Barcode   = 'Barcode';
  LabDet_MachineId = 'Machine_id';
  LabDet_SerialNo  = 'Serial_no';
  LabDet_DeclaredNetKg = 'Declared_net_kg';
  LabDet_PackDate  = 'Pack_date';

  PROD_Code        = 'Product_code';
  PROD_Description = 'Description';
  PROD_Plu         = 'Plu_number';

  ProCon_Id           = 'IdProdConcession';
  ProCon_ProductCode  = 'Product_code';
  ProCon_UseBysFrom   = 'UseBys_from';
  ProCon_LotNo        = 'Lot_no';
  ProCon_AsIngredient = 'As_ingredient';
  ProCon_Reference    = 'Reference';
  ProCon_ValidFrom    = 'Valid_from';
  ProCon_ValidTo      = 'Valid_to';
  ProCon_Cancelled    = 'Cancelled';
  ProCon_UseByExtn    = 'UseBy_extn';
  ProCon_KgAllowed    = 'Kg_allowed';
  ProCon_KgUsed       = 'Kg_used';
  ProCon_Reserved     = 'Reserved';


  TraSou_MachineId   = 'machine_id';
  TraSou_RunNumber   = 'run_number';
  TraSou_Barcode     = 'barcode';
  TraSou_ProducerId  = 'Producer_ID';

  TRN_MachineId    = 'Machine_id';
  TRN_SerialNumber = 'Serial_number';
  TRN_ActualWt     = 'Actual_weight';
  TRN_WtRange      = 'Weight_range';
  TRN_MaxLife      = 'Maximum_life';
  TRN_Product      = 'Product';
  TRN_PurchaseOrder= 'Purchase_order_num';
  TRN_DespatchOrder= 'Despatch_order';
  TRN_Status       = 'Status';

  GRP_GroupCode   = 'group_code';
  GRP_ProductCode = 'product_code';

  TraCod_Code                    = 'Code';
  TraCod_Description             = 'Description';

  { Function Return Codes }
  F6BCERR_INCORRECTLEN = 1;
  F6BCERR_TRANNOTFOUND = 4;

type
  TdmFops = class(TBaseDM)
    pvtblTransactions: TPvTable;
    pvtblProducts: TPvTable;
    pvtblCommBuff: TPvTable;
    pvtblGroupLines: TPvTable;
    pvtblGroupLinesgroup_code: TStringField;
    pvtblGroupLinesproduct_code: TStringField;
    pvtblTransSource: TPvTable;
    pvtblTraceCodes: TPvTable;
    pvtblLabelDetail: TPvTable;
    pvtblProductConcession: TPvTable;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
//    OverrideProduct: String;
    function LocateFopsTransaction(MachineNo: Integer; Serial: Integer) : boolean;
    function LocateFopsTransSource(MachineNo: Integer; Serial: Integer) : boolean;
    function GetFops6PluNumberForIngredient(ForIngredientCode: String): Integer;
    function VerifyFopsBarcode(const FopsBarcode: String;
                               const SFXIntakeMid : string;
                               var SourceLabelBarcode: String;
                               var CurrentSourceWt: Double;
                               var OriginalSourceWt: Double;
                               var SourceLifeDate: Integer;
                               var SourceProdCode: string;
                               var SourceFopsMcNo : integer;
                               var SourceFopsSerNo : integer): Integer;
    function ProductIsInGroup(const ProdCode, GroupCode: String): Boolean;
    function GetTranPurchaseOrderStr(MachineNo: Integer; Serial: Integer) : String;
    function GetTranMaxLifeDateStr(MachineNo: Integer; Serial: Integer) : String;
    function GetProducerIdDesc(CONST ProducerIDStr : string) : string;
    function GetTranProducerIdDesc(MachineNo: Integer; Serial: Integer): String;
    function GetTranSourceBarcode(MachineNo: Integer; Serial: Integer): String;
    function CurrProdConcessionInvalidMsg(const ProdCode : string;
                                          LifeDt : TDate;
                                          const LotCode : string;
                                          const AsIngredient : string;
                                          WtKg : double) : string;
    procedure AddToUsedWtOnProdConcession(ConcessionNo : integer; WtInKg : double);
  end;

var
  dmFops: TdmFops;

implementation
uses DateUtils, uFopsLib, uDBFunctions;

{$R *.dfm}

{ TdmFops }

function TdmFops.GetFops6PluNumberForIngredient(
  ForIngredientCode: String): Integer;
begin
 Result := 0;
 if not pvtblProducts.Active then
   pvtblProducts.Open;
 if not pvtblProducts.Active then
  begin
   TermMessageDlg('Warning: Failed To Open FOPS6 Product File',mtError,[mbOk],0);
  end;
 if pvtblProducts.Locate(PROD_Code,SpacePad(ForIngredientCode,8),[]) then
  begin
   Result := pvtblProducts.FindField(PROD_Plu).AsInteger;
  end;
end;

function TdmFops.VerifyFopsBarcode(const FopsBarcode: String;
                                   const SFXIntakeMid : string;
                                   var SourceLabelBarcode: String;
                                   var CurrentSourceWt: Double;
                                   var OriginalSourceWt: Double;
                                   var SourceLifeDate: Integer;
                                   var SourceProdCode: string;
                                   var SourceFopsMcNo : integer;
                                   var SourceFopsSerNo : integer
                                   ): Integer;
{PROMISES: 1. if a related FOPS transaction is not found then:-
                SourceProdCode is returned as '';
                SourceLifeDate is returned as 0;
                SourceFopsMcNo is returned as 0;
                SourceFosSerNo is returned as 0.
           2. Returns OriginalSourceWt as 0.0 if FopsBarcode is not 20 digits and
              no related FOPS transaction is found.
}
var
  WrkResult   : Integer;
  LabDtlFound : boolean;
  TranMid     : char;
  TranSerNo   : integer;

begin
 SourceLabelBarcode := Trim(FopsBarcode); // might get nulled below.
 CurrentSourceWt  := 0.0;
 OriginalSourceWt := 0.0;
 SourceLifeDate   := 0;
 SourceProdCode   := '';
 SourceFopsMcNo   := 0;
 SourceFopsSerNo  := 0;
 WrkResult := 0;
 TranMid   := #0;
 TranSerNo := 0;
 LabDtlFound := false;
 if  (length(SourceLabelBarcode) = 6) {try to change to 8 digit tran id}
 and (Length(SFXIntakeMid) = 2) then
   SourceLabelBarcode := SFXIntakeMid+ SourceLabelBarcode;

 if (length(SourceLabelBarcode) = 8)
 or (Length(SourceLabelBarcode) > 20) then // get OriginalSourceWt from Label_Detail table.
 begin
   try
     with pvtblLabelDetail do
     begin
       Active := true;
       if Length(SourceLabelBarcode) = 8 then
       begin
         IndexFieldNames := LabDet_MachineId+';'+LabDet_SerialNo+';'+LabDet_PackDate;
         LabDtlFound := Locate(LabDet_MachineId+';'+LabDet_SerialNo,
                               VarArrayOf([StrToInt(Copy(SourceLabelBarcode,1,2)),
                                           StrToInt(Copy(SourceLabelBarcode,3,6))]),
                               []);
         if LabDtlFound then
           SourceLabelBarcode := Trim(FieldByName(LabDet_Barcode).AsString);
       end
       else
       begin
         IndexFieldNames := LabDet_Barcode;
         LabDtlFound := Locate(LabDet_Barcode, SourceLabelBarcode, []);
       end;
     end;
   except
     on E:Exception do
     begin
       TermMessageDlg('Error accessing FOPS Label Detail File'+#13#10+
                      E.Message,mtError,[mbOk],0);
     end;
   end;
   if Length(SourceLabelBarcode) = 8 then //not LabDtlFound - change it to dummy 20 digit barcode.
     SourceLabelBarcode := SourceLabelBarcode + '999900000000'; {a plu 9999 will have to be setup on fops}
 end
 else if Length(SourceLabelBarcode) <> 20 then
 begin
   SourceLabelBarcode := '';
   WrkResult := F6BCERR_INCORRECTLEN  {let caller describe error (and acceptable lengths)}
 end;

 if WrkResult = 0 then
 begin
   if LabDtlFound then
   begin
     OriginalSourceWt := pvtblLabelDetail.FieldByName(LabDet_DeclaredNetKg).AsFloat;
     TranMid   := GetMid(pvtblLabelDetail.FieldByName(LabDet_MachineId).AsInteger);
     TranSerNo := pvtblLabelDetail.FieldByName(LabDet_SerialNo).AsInteger;
   end
   else if Length(SourceLabelBarcode) = 20 then //extract details directly from barcode.
   begin
     try
       OriginalSourceWt := StrToFloat(COPY(SourceLabelBarcode,13,3)+ '.'+ Copy(SourceLabelBarcode,16,2));
       TranMid   := StringToMID(Copy(SourceLabelBarcode,1,2));
       TranSerNo := StrToInt(Copy(SourceLabelBarcode,3,6));
     except
       WrkResult := F6BCERR_TRANNOTFOUND;
     end;
   end
   else
     WrkResult := F6BCERR_TRANNOTFOUND;
 end;

 if WrkResult = 0 then
 begin
   try
     if not pvtblTransactions.Active then pvtblTransactions.Open;
     if not pvtblTransactions.Active then
       TermMessageDlg('Unable To Open FOPS6 Transaction File',mtError,[mbOk],0);
   except
     on E:Exception do
     begin
       TermMessageDlg('Unable To Open FOPS6 Transaction File'+#13#10+
                      E.Message,mtError,[mbOk],0);
     end;
   end;

   if pvtblTransactions.Locate(TRN_MachineId+';'+TRN_SerialNumber,
                               VarArrayOf([TranMid,TranSerNo]),[]) then
   begin {return current stock wt}
     if  (pvtblTransactions.FieldByName(TRN_Status).AsInteger = 0)
     and (pvtblTransactions.FieldByName(TRN_DespatchOrder).AsInteger = 0) then {free for issuing}
       CurrentSourceWt  := pvtblTransactions.FindField(TRN_ActualWt).AsFloat;
     if OriginalSourceWt < pvtblTransactions.FieldByName(TRN_ActualWt).AsFloat then //e.g. OriginalSourceWt = 0.0
       OriginalSourceWt := pvtblTransactions.FieldByName(TRN_ActualWt).AsFloat;
     if pvtblTransactions.FindField(TRN_WtRange).AsString = 'L' then
      begin
       CurrentSourceWt  := CurrentSourceWt * KG_TO_LB;
       OriginalSourceWt := OriginalSourceWt * KG_TO_LB;
      end;
     SourceLifeDate := pvtblTransactions.FindField(TRN_MaxLife).AsInteger;
     SourceProdCode := pvtblTransactions.FindField(TRN_Product).AsString;
     SourceFopsMcNo := MidToNo(TranMid);
     SourceFopsSerNo:= TranSerNo;
   end
   else
   begin {no transaction found}
     { suffolk want weight from barcode }
     CurrentSourceWt  := OriginalSourceWt;
     WrkResult := F6BCERR_TRANNOTFOUND;
   end;
 end;
 Result := WrkResult;
end;

procedure TdmFops.DataModuleCreate(Sender: TObject);
begin
  inherited;
//  OverrideProduct := '';
end;

function TdmFops.ProductIsInGroup(const ProdCode, GroupCode: String): Boolean;
begin
  with pvtblGroupLines do
  begin
    if not Active then Open;
    Result := Locate(GRP_GroupCode+';'+GRP_ProductCode,
               VarArrayOf([SpacePad(GroupCode,8), SpacePad(ProdCode,8)]),[]);
  end;
end;

function TdmFops.LocateFopsTransaction(MachineNo: Integer; Serial: Integer) : boolean;
var MidChar : char;
begin
  Result := false;
  MidChar := GetMID(MachineNo);
  with pvtblTransactions do
  begin
    if not Active then
      Open;
    if  (Length(FieldByName(TRN_MachineId).AsString) > 0)
    and (FieldByName(TRN_MachineId).AsString[1] = MidChar)
    and (FieldByName(TRN_SerialNumber).AsInteger = Serial) then
      Result := true
    else
      Result := Locate(TRN_MachineId+';'+TRN_SerialNumber,
                       VarArrayof([MidChar,Serial]),[]);
  end;
end;

function TdmFops.LocateFopsTransSource(MachineNo: Integer; Serial: Integer) : boolean;
var MidChar : char;
begin
  Result := false;
  MidChar := GetMID(MachineNo);
  with pvtblTransSource do
  begin
    if not Active then
      Open;
    if  (FieldByName(TraSou_MachineId).AsInteger = Ord(MidChar))
    and (FieldByName(TraSou_RunNumber).AsInteger = Serial) then
      Result := true
    else
      Result := Locate(TraSou_MachineId+';'+TraSou_RunNumber,
                       VarArrayof([Ord(MidChar),Serial]),[]);
  end;
end;

function TdmFops.GetTranMaxLifeDateStr(MachineNo: Integer; Serial: Integer): String;
begin
  if LocateFopsTransaction(MachineNo, Serial) then
    Result := FormatDateTime('dd/mm/yy',JulianToDateValue(pvtblTransactions.FieldByName(TRN_MaxLife).AsInteger))
  else
    Result := '';
end;

function TdmFops.GetTranPurchaseOrderStr(MachineNo: Integer; Serial: Integer): String;
begin
  if LocateFopsTransaction(MachineNo, Serial) then
    Result := IntToZeroStr(pvtblTransactions.FieldByName(TRN_PurchaseOrder).AsInteger,6)
  else
    Result := '';
end;

function TdmFops.GetProducerIdDesc(CONST ProducerIDStr : string) : string;
var TraceNo : integer;
    TraceIdInFileFormat : string[8];
begin
  Result := ProducerIDStr;
  with pvtblTraceCodes do
  begin
    if not active then open;
    TraceIdInFileFormat := SpacePad(ProducerIdStr,8);
    if Locate(TraCod_Code, TraceIdInFileFormat, []) then
      Result := FieldByName(TraCod_Description).AsString
    else if TryStrToInt(ProducerIdStr, TraceNo) then
    begin // hilton use numerical ids saved as 2 or 3 digits - mainly 3 digits
      TraceIdInFileFormat := SpacePad(IntToZeroStr(TraceNo,3),8); //three or more digits
      if Locate(TraCod_Code, TraceIdInFileFormat, []) then
        Result := FieldByName(TraCod_Description).AsString
      else if TraceNo < 100 then {look for 2 digit format}
      begin
        TraceIdInFileFormat := SpacePad(IntToZeroStr(TraceNo,2),8);
        if Locate(TraCod_Code, TraceIdInFileFormat, []) then
          Result := FieldByName(TraCod_Description).AsString;
      end;
    end;
  end;
end;

function TdmFops.GetTranProducerIdDesc(MachineNo: Integer; Serial: Integer): String;
begin
  if LocateFopsTransSource(MachineNo, Serial) then
  begin
    Result := GetProducerIdDesc(pvtblTransSource.FieldByName(TraSou_ProducerId).AsString);
  end
  else
    Result := '';
end;

function TdmFops.GetTranSourceBarcode(MachineNo: Integer; Serial: Integer): String;
begin
  if LocateFopsTransSource(MachineNo, Serial) then
    Result := pvtblTransSource.FieldByName(TraSou_Barcode).AsString
  else
    Result := '';
end;


function TdmFops.CurrProdConcessionInvalidMsg(const ProdCode : string;
                                              LifeDt : TDate;
                                              const LotCode : string;
                                              const AsIngredient : string;
                                              WtKg : double) : string;
{PROMISES: Returns '' if the current row in pvtblProducConcession concedes to the
           use of the parameters.
}
var
  CurrDate : TDateTime;
  RemainingKg : double;
  OutOfDateBy : integer;
begin
  Result := '';
  CurrDate := Today;
  with pvtblProductConcession do
  begin
    if (FieldByName(ProCon_ValidFrom).AsDateTime > CurrDate)
    or (FieldByName(ProCon_ValidTo).AsDateTime < CurrDate) then
    begin
      Result := 'is not valid today';
      EXIT;
    end;
    if FieldByName(ProCon_Cancelled).AsBoolean then
    begin
      Result := 'is cancelled';
      EXIT;
    end;
    if FieldByName(ProCon_ProductCode).AsString <> TrimRight(ProdCode) then
    begin
      Result := 'does not cover product ' + ProdCode;
      EXIT;
    end;
    if FieldByName(ProCon_UseBysFrom).AsDateTime > LifeDt then
    begin
      Result := 'does not cover Use-By date '+FormatDateTime('dd/mm/yyyy', LifeDt);
      EXIT;
    end;
    if  (FieldByName(ProCon_LotNo).AsString <> '')
    and (FieldByName(ProCon_LotNo).AsString <> TrimRight(LotCode)) then
    begin
      Result := 'does not cover lot ' + LotCode;
      EXIT;
    end;
    if  (FieldByName(ProCon_AsIngredient).AsString <> '')
    and (FieldByName(ProCon_AsIngredient).AsString <> TrimRight(AsIngredient)) then
    begin
      Result := 'does not cover ingredient ' + AsIngredient;
      EXIT;
    end;
    OutOfDateBy := DaysBetween(CurrDate, LifeDt);
    if  (CurrDate > LifeDt)
    and (FieldByName(ProCon_UseByExtn).AsInteger < OutOfDateBy) then
    begin
      Result := 'does not cover '+IntToStr(OutOfDateBy)+ ' days beyond use-by';
      EXIT;
    end;
    RemainingKg := FieldByName(ProCon_KgAllowed).AsFloat - FieldByName(ProCon_KgUsed).AsFloat;
    if  (FieldByName(ProCon_KgAllowed).AsFloat > 0.0001)
    and (RemainingKg < WtKg) then
    begin
      Result := 'only has '+ FormatFloat('0.000',RemainingKg)+' kg unused';
      EXIT;
    end;
  end;
end;

procedure TdmFops.AddToUsedWtOnProdConcession(ConcessionNo : integer; WtInKg : double);
var WtUsedField : TField;
begin
  if PvtableLocateUsingIndex(pvtblProductConcession, ProCon_Id, ConcessionNo, []) then
  begin
    WtUsedField := pvtblProductConcession.FieldByName(ProCon_KgUsed);
    pvtblProductConcession.Edit;
    WtUsedField.AsFloat := WtUsedField.AsFloat + WtInKg;
    pvtblProductConcession.Post;
  end;  
end;

end.

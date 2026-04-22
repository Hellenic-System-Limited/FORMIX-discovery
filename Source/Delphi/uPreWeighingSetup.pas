unit uPreWeighingSetup;

interface
uses DB;
function PreWeighingSetup(DatasetWithOrdLine : TDataSet; MinWt, MaxWt : double) : Boolean;


implementation
uses Controls, Dialogs, SysUtils, uStdUtl, uFopsLib, udmFormixBase, udmFormix, uTermDialogs,
ufrmFormixStdEntry, udmFops;

procedure ShowIncorrectBarcodeLengthMsg;
var BarFilter : string;
begin
  BarFilter := 'Source Barcode must be a stock item''s barcode or ID';
  if dmFormix.fAllowSixDigitBarcode then
    BarFilter := BarFilter + ' or 6 digits';
  if dmFormix.fAllowBarcodeLength > 0 then
    BarFilter := BarFilter + ' or '+IntToStr(dmFormix.fAllowBarcodeLength)+' digits';
  if dmFormix.fAllowPOBarcode then
    BarFilter := BarFilter + ' or ''PO''+6 digit purchase no.';
  if dmFormix.SetOfLazenbyNavBarLengths <> [] then
    BarFilter := BarFilter + ' or NAV barcode';

  TermMessageDlg(BarFilter, mtError, [mbOk], 0);
end;

function GetASourceBarcode(const IngredientDesc : string) : Boolean;
{PROMISES: if returns true then "Source Item Details" will have been set (see ClearSourceItemDetals).
}
var WrkBool: Boolean;
    BarcodeScanned,
    WrkBarcode: String;
    WrkCurrentWt,
    WrkOrigWt : Double;
    WrkLifeDt : Integer;
    WrkResult : Integer;
    WrkProdCode : string;
    FopsMcNo, FopsSerNo : integer;
    TempDateTime : TDateTime;
begin
  Result := FALSE;
  repeat
    dmFormix.ClearSourceItemDetails;
    BarcodeScanned := '';
    if dmFormix.fUseOneScanOnly then
      BarcodeScanned := dmFormix.fOneScanStr
    else
      BarcodeScanned := TfrmFormixStdEntry.GetStdStringEntry('Enter Source Barcode for '+
                                                                                IngredientDesc,
                                                             'Source Barcode',36,WrkBool,
                                                             false{IsPassword},'',false{MustEnterVal},
                                                             (not dmFormix.fAllowKeyedBarcode){PasswordedKeyboard});

    if not dmFormix.BarcodeIsACranswickNavBarcode(BarcodeScanned) then
      BarcodeScanned := Trim(BarcodeScanned);//assume spaces on end were a mistake.

    if Length(BarcodeScanned) = 0 then
    begin
      Break; {return false}
    end
    else if dmFormix.BarcodeIsACranswickNavBarcode(BarcodeScanned) then
    begin
      dmFormix.SourceBarcode := BarcodeScanned;
      dmFormix.SourceProdCode := dmformix.GetProdCodeFromCranswickNavBarcode(BarcodeScanned);
      if dmFormix.GetDateFromCranswickNavBarcode(BarcodeScanned, TempDateTime) then
        dmFormix.SourceLifeJDay := DateToJulianValue(TempDateTime);
      dmFormix.SourceLotCode := dmFormix.GetLotCodeFromCranswickNavBarcode(BarcodeScanned);  
      Result := TRUE;
      Break;
    end
    else if  (Length(BarcodeScanned) = 6)
         and dmFormix.fAllowSixDigitBarcode then
    begin
      dmFormix.SourceBarcode := BarcodeScanned;
      Result := TRUE;
      Break;
    end
    else if  (Length(BarcodeScanned) = 8)
         and dmFormix.fAllowPOBarcode
         and (Copy(BarcodeScanned,1,2) = 'PO') then
    begin
      dmFormix.SourceBarcode := BarcodeScanned;
      Result := TRUE;
      Break;
    end
    else if  (Length(BarcodeScanned) = dmFormix.fAllowBarcodeLength) then
    begin
      dmFormix.SourceBarcode := BarcodeScanned;
      Result := TRUE;
      Break;
    end
    else if not Assigned(dmFops) then
    begin
      TermMessageDlg('Cannot verify barcode without connecting'+#13#10+
                     'to FOPS database on start-up.',mtError,[mbOk],0);
      Break; {return false}
    end
    else
    begin
      WrkResult := dmFops.VerifyFopsBarcode(BarcodeScanned,
                                          dmFormix.fIntakeMid,
                                          WrkBarcode, {might get extended to 20 digits}
                                          WrkCurrentWt,
                                          WrkOrigWt,
                                          WrkLifeDt,
                                          WrkProdCode, FopsMcNo, FopsSerNo);
      dmFormix.SourceItemCheckedAt := Now;
      if WrkResult <> 0 then
      begin
        case WrkResult of
          F6BCERR_INCORRECTLEN : ShowIncorrectBarcodeLengthMsg;
          F6BCERR_TRANNOTFOUND : TermMessageDlg('FOPS Transaction Not Found',
                                                mtError,[mbOk],0);
          else                   TermMessageDlg('Invalid FOPS Transaction ',
                                                mtError,[mbOk],0);
        end;
      end;

      if (WrkResult = 0)
      or ((WrkResult = F6BCERR_TRANNOTFOUND) and dmFormix.fAllowTranNotFound) then
      begin
        dmFormix.SourceBarcode  := BarcodeScanned;
        dmFormix.SourceItemLabelBarcode  := WrkBarcode;
        dmFormix.CurrSourceWtKg := WrkCurrentWt;
        dmFormix.OrigSourceWtKg := WrkOrigWt;
        dmFormix.SourceLifeJDay   := WrkLifeDt;
        dmFormix.SourceProdCode := WrkProdCode;
        dmFormix.SourceItemFopsMcNo := FopsMcNo;
        dmFormix.SourceItemFopsSerNo:= FopsSerNo;
        Result := TRUE;
      end;
    end;
    if  (not Result)
    and dmFormix.fUseOneScanOnly then
    begin
      dmFormix.fOneScanStr := '';
      break; {return false and get another barcode on ingredient selection}
    end;
  until Result;
end;


function GetUserToConfirmOrChangeCurrentIngredientLot : boolean;
var
  LotEnteredOk : boolean;
  LotCodeStr : string;
begin
  LotEnteredOk := FALSE;
  LotCodeStr := '';
  LotCodeStr := TfrmFormixStdEntry.GetStdStringEntry('Enter Ingredient Lot Number','Lot Number',14,LotEnteredOk,FALSE,
                                                     dmFormix.CurrentIngredientLot,TRUE);
  if LotEnteredOk then
    dmFormix.CurrentIngredientLot := UpperCase(LotCodeStr);
  Result := LotEnteredOk;
end;


function PreWeighingSetup(DatasetWithOrdLine : TDataSet; MinWt, MaxWt : double): Boolean;
{REQUIRES: DatasetWithOrdLine to be located on line to be weighed.
}
const
    LOWEST_TEMPC = -40;
    HIGHEST_TEMPC = 499;
var SetupOk,
    BarcodeAcceptedByUser: Boolean;
    WrkStr : string;
    OkWasUsed : boolean;
    Temperature : double;
    SaveLotCode : string;
    LotCodeWasAutoSet : boolean;
    CheckSourceProd, CheckSourceLife : boolean;
    MinSourceWtKgUsage : double;

  procedure AutoSetCurrentIngredientLotWith(const LotCode : string);
  begin
    dmFormix.CurrentIngredientLot := LotCode;
    LotCodeWasAutoSet := true;
  end;
  {-------------}

begin
  Result  := TRUE;
  dmFormix.ClearWeighingDetails; {calls ClearSourceItemDetails}
  SetupOk := TRUE;
  LotCodeWasAutoSet := false;
  if (not dmFormix.SelectedLineIsAutoWeigh) then //do User prompts
  begin
    if dmformix.fPromptForSource then
    begin
      repeat
        BarcodeAcceptedByUser := TRUE;
        SetupOk := TRUE;
        dmFormix.SynchIngredientsCacheWithCode(DatasetWithOrdLine.FieldByName(OL_Ingredient).AsString);
        if not GetASourceBarcode(dmFormix.rxmIngredientsCacheDescription.AsString) then {calls ClearSourceItemDetails}
        begin
          if not dmformix.fSourceOptional then
            SetupOk := FALSE;
        end;

        if  (dmFormix.CurrSourceWtKg > 0.0001)
        and (dmFormix.CurrSourceWtKg < MinWt) then
          MinSourceWtKgUsage := dmFormix.CurrSourceWtKg
        else
          MinSourceWtKgUsage := MinWt;
        CheckSourceProd := false;
        CheckSourceLife := false;
        if SetupOk then
        begin
          if ((dmFormix.SourceBarcodeRelatesToAFopsTran and dmformix.fIngredientsInFops6))
          or dmFormix.BarcodeIsACranswickNavBarcode(dmFormix.SourceBarcode) then
          begin
            CheckSourceProd := true;
            CheckSourceLife := (dmFormix.SourceLifeJDay > 0);
          end;
        end;

        if  SetupOk
        and CheckSourceProd
        and (Trim(dmFormix.SourceProdCode) <> Trim(DatasetWithOrdLine.FieldByName(OL_Ingredient).AsString)) then
        begin
          if not assigned(dmFops) then
          begin
            SetupOk := false;
            TermMessageDlg('Cannot check source product is correct'+#13#10+
                           'without connecting to FOPS database on start-up.', mtWarning, [mbOK], 0)
          end
          else
          begin
            if (not dmFops.ProductIsInGroup(dmFormix.SourceProdCode,
                                     DatasetWithOrdLine.FieldByName(OL_Ingredient).AsString)) then
            begin
              SetupOk := FALSE;
              if not dmformix.fAllowProductOverride then
                TermMessageDlg('Incorrect source product for ingredient.',mtError,[mbOk],0)
              else if dmFormix.OverrideExistsForSourceItem(override_INCORRECTPROD,
                               DatasetWithOrdLine.FieldByName(OL_OrderNo).AsInteger,
                               DatasetWithOrdLine.FieldByName(OL_Ingredient).AsString,
                               MinSourceWtKgUsage,
                               'Source product: '+dmFormix.SourceProdCode+#13#10+
                                   '(Barcode: '+dmFormix.GetExpandedSourceBarcode+')') then
                SetupOk := TRUE;
            end;
          end;
        end;
        if  SetupOk
        and CheckSourceLife
        and (dmFormix.SourceLifeJDay < DateToJulianValue(Date))
        and (not dmFormix.OverrideExistsForSourceItem(override_LIFEEXPIRED,
                               DatasetWithOrdLine.FieldByName(OL_OrderNo).AsInteger,
                               DatasetWithOrdLine.FieldByName(OL_Ingredient).AsString,
                               MinSourceWtKgUsage,
                               'Source life date: '+FormatDateTime('dd/mm/yyyy', JulianToDateValue(dmFormix.SourceLifeJDay)))) then
            SetupOk := FALSE;

        if  SetupOk
        and dmFormix.SourceBarcodeRelatesToAFopsTran then
        begin
          if dmformix.SendFopsIssueTrans then {source weight should go down}
          begin
            if CompareWts(dmFormix.CurrSourceWtKg,0.0) <= 0 then {empty}
            begin
              SetupOk := FALSE;
              if dmformix.fAcceptLabelWeight then
                TermMessageDlg('Source item has zero weight.',mtError,[mbOk],0)
              { give the user a chance to acknowledge emptiness without being audited }
              else if TermMessageDlg('Is Source Container: '+dmFormix.GetExpandedSourceBarcode+#13#10+
                                     'empty?',mtConfirmation,[mbYes,mbNo],0) = mrYes then
              begin
                TermMessageDlg('Scan new Source Container barcode.',mtInformation,[mbOk],0);
              end
              else if dmFormix.OverrideExistsForSourceItem(override_EMPTY,
                               DatasetWithOrdLine.FieldByName(OL_OrderNo).AsInteger,
                               DatasetWithOrdLine.FieldByName(OL_Ingredient).AsString,
                               MinSourceWtKgUsage, '') then
                SetupOk := TRUE;
            end
            else if  (not dmformix.fAcceptLabelWeight)
                 and (CompareWts(MinWt,dmFormix.CurrSourceWtKg) > 0) then
              TermMessageDlg('Use Part Weigh button when Source Container is empty',
                             mtInformation,[mbOk],0);
          end;

          if  (SetupOk)
          and dmformix.fAcceptLabelWeight then
          begin
            { Either set UseSourceWt=true or scan another or weigh it }
            if dmFormix.WeightOkForTran(dmFormix.CurrSourceWtKg,
                                        TProcessTypes(DatasetWithOrdLine.FieldByName(OL_ProcessType).AsInteger),
                                        MinWt, MaxWt, TRUE) then
            begin
              dmFormix.UseSourceWt := TRUE;
  //            ClickMouse(plAnalog.Left+(plAnalog.Width DIV 2),plAnalog.Top+(plAnalog.Height  DIV 2));
            end
            else
            begin
              if TermMessageDlg(FormatFloat('#0.00',dmformix.CurrSourceWtKg)+
                                'kg is out of tolerance.'+#13#10+
                                'Try different Source?',mtconfirmation,[mbYes,mbNo],0) = mrYes then
              begin
                if dmformix.fUseOneScanOnly and dmformix.fEnquireForBatchNo then {fall out and start again}
                  SetupOk := false
                else {leave BatchNo as is and scan another barcode}
                  BarcodeAcceptedByUser := FALSE;
              end;
            end;
          end;
        end; {source is a fops tran}

      until BarcodeAcceptedByUser;
      if SetupOk then // Now that barcode is validated, set Lot code.
      begin
        if dmFormix.BarcodeIsACranswickNavBarcode(dmFormix.SourceBarcode) then //force lot code to match barcode.
          AutoSetCurrentIngredientLotWith(dmFormix.SourceLotCode)
        else if dmformix.fCopyFopsTranSourceAsLot and dmFormix.SourceBarcodeRelatesToAFopsTran then
        begin
          if not Assigned(dmFops) then
          begin
            SetupOk := false;
            TermMessageDlg('Source Lot number cannot be found without connecting to FOPS database on start-up',
                           mtError, [mbOk], 0);
          end
          else
            AutoSetCurrentIngredientLotWith(Copy(dmFops.GetTranSourceBarcode(dmFormix.SourceItemFopsMcNo,
                                                                   dmFormix.SourceItemFopsSerNo),
                                       1, 14));
        end
        else if dmformix.fEnquireForLotNo then
        begin
          if dmformix.fUseOneScanOnly then // set lot code from SourceBarcode scan.
            AutoSetCurrentIngredientLotWith(UpperCase(Copy(dmFormix.fOneScanStr,1,8)));//as per knowledge base.
        end;
      end;
    end;{prompt for Source}
    if  SetupOk
    and dmformix.fEnquireForLotNo
    and (not LotCodeWasAutoSet) then
    begin
      SaveLotCode := dmFormix.CurrentIngredientLot;
      if GetUserToConfirmOrChangeCurrentIngredientLot then
      begin
        if dmFormix.CurrentIngredientLot <> SaveLotCode then
          dmFormix.SetLotNumberForIngredient(dmFormix.GetCurrentMachineId,
                 Copy(DatasetWithOrdLine.FieldByName(OL_Ingredient).AsString+SpaceString,1,8),
                                             dmFormix.CurrentIngredientLot);
      end
      else //user has escaped from prompt.
        SetupOk := false;
    end;
    if  SetupOk
    and dmformix.fPromptForTemperature then
    begin
      repeat
        WrkStr := TfrmFormixStdEntry.GetStdStringEntry('Enter Temperature of Ingredient',
                                                       'Temperature (Celsius x.x): ',5{MaxLength}, OkWasUsed);
        Temperature := -273.1;
        if OkWasUsed then
        begin
          try
            Temperature := StrToFloat(WrkStr);
          except
          end;
          if (Temperature < LOWEST_TEMPC) or (Temperature > HIGHEST_TEMPC) then
          begin
            Temperature := -273.1; //force another user prompt
            TermMessageDlg(''''+ WrkStr+ ''' is not a valid temperature value.',mtError,[mbOk],0);
          end;
        end;
      until (not OkWasUsed) OR (Temperature >= LOWEST_TEMPC);
      if OkWasUsed then //temperature must be in range
      begin
        dmFormix.CurrIngredientTempEntered := true;
        dmFormix.CurrIngredientTemperatureStr := DoubleToStr(Temperature,1,1);
      end;
    end;{prompt for temperature}
  end; {not dmFormix.SelectedLineIsAutoWeigh}
  Result := SetupOk;
end;


end.

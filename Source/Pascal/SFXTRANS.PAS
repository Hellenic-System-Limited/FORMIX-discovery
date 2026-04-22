(****************************************************************************
*  UNIT          : SFXTrans                                                 *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Transaction Creator                         *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}

{$IFnDEF TERMINAL} not required {$ENDIF}

UNIT SFXTrans;
INTERFACE
USES CRT,SFXStd,F6StdUtl,F6DtConv,FXFTrn,FXFCost,SFXMsg,
     FXFWork,FXFIngr,SFX_Main,FXFNet,FX_Msg,FXCfg,FXFMix,
     FXModCtv,FXDetail,SFXMixes,SFXTiket,F6StdCtv,F6StdFil,F6StdWn1,
{$IFDEF FOPSTRACELINK}  FXFFops, {$ENDIF}
     SFXScale,FXFUsers,SFXLOg,SFXDate;




PROCEDURE CreateTransaction(ActualWt    : DOUBLE;
                            {Partial : BOOLEAN;}
                            ActualProcessType : TProcessTypes;
                            ManualWtEntry: BOOLEAN);

FUNCTION WeightOkForTran(ActNetWt       : DOUBLE;
                         IngType        : TProcessTypes;
                         LowTolWt,
                         HighTolWt      :DOUBLE;
                         LowTolDisabled : BOOLEAN {by user (partial wt button)}
                        ) : BOOLEAN;



IMPLEMENTATION
USES SFXKbd,SFXCurr,SFX_SCrl,SFX_Bars;


CONST {ADDING TRANSACTION ERRORS}

     AW_WEIGHTADDED       =   0;      {AW = AddWeight Error}
     AW_ORDERWASCOMPLETE  =   1;
     AW_ORDERNOWCOMPLETE  =   2;
     AW_ALREADYWEIGHED    =   9;

     CT_ERRORADDINGTRN    = 102;
     CT_NOBATCHNUMBER     = 103;
     CT_NOLOTNUMBER       = 104;
     CT_TARENOTSET        = 105;
     CT_NOWEIGHINGS       = 106;
     CT_ORDERHEADFILEERR  = 107;
     CT_ORDERLINEFILEERR  = 108;
     CT_TRANSFILEERR      = 109;
     CT_TRACEERROR        = 110;


FUNCTION WeightOkForTran(ActNetWt       : DOUBLE;
                         IngType        : TProcessTypes;
                         LowTolWt,
                         HighTolWt      :DOUBLE;
                         LowTolDisabled : BOOLEAN {by user (partial wt button)}
                        ) : BOOLEAN;
BEGIN
 WeightOkForTran := FALSE;
 IF IngType = PTWeight THEN { can do partial weighings }
  BEGIN
   IF  (CompareWts(ActNetWt, HighTolWt) <= 0)
   AND (   (LowTolDisabled AND (CompareWts(ActNetWt,0.0) > 0))
        OR (CompareWts(ActNetWt, LowTolWt) >= 0)) THEN
     WeightOkForTran := TRUE;
  END
 ELSE IF IngType = PTCount THEN {fixed wt contributes to wt done (no part wghs)}
  BEGIN
   IF  (CompareWts(ActNetWt, HighTolWt) <= 0)
   AND (CompareWts(ActNetWt, LowTolWt) >= 0) THEN
     WeightOkForTran := TRUE;
  END
 ELSE IF IngType = PTStep THEN
   WeightOkForTran := TRUE;
END;


PROCEDURE DisplayTransactionResult(ErrorNum : INTEGER;BtrvErr : INTEGER);
VAR MsgStr : STRING[50];
BEGIN
 CASE ErrorNum OF
  AW_WEIGHTADDED       : BEGIN
    MsgStr := 'Weight Accepted.';
{    IF ShouldTareBeRemovedAutomaticallyForThisOrder THEN
     MsgStr := MsgStr+' Remove Container';}
  END;
  AW_ORDERWASCOMPLETE  : MsgStr := 'Order Has Been Completed by Another User';
  {AW_ORDERLINECOMPLETE : MsgStr := 'This Ingredient Is Complete For This Mix';}
  {AW_WEIGHTTOHIGH      : MsgStr := 'Weight Too High For This Ingredient';}
  AW_ORDERNOWCOMPLETE  : MsgStr := 'Order Is Now Complete';
  {AW_WTEXCEEDSMASTER   : MsgStr := 'Weight Exceeds That Set By Key Ingredient.';}
  {AW_WTBELOWTOLERANCE  : MsgStr := 'Weight Is Below Minimum Tolerance';}
  {AW_WTABOVETOLERANCE  : MsgStr := 'Weight Exceeds Maximum Tolerance';}
  {AW_WTABOVECONTWT     : MsgStr := 'Weight Exceeds Container Weight';}
  AW_ALREADYWEIGHED    : MsgStr := 'Mix Ingredient Has Been Weighed by Another User';
  CT_ERRORADDINGTRN    : MsgStr := 'Error Adding Transaction Record. Btrv Error '+IntToStr(BtrvErr,3);
  CT_NOBATCHNUMBER     : MsgStr := 'Error No Batch Number Has Been Set';
  CT_NOLOTNUMBER       : MsgStr := 'Error No Lot Number Has Been Set';
  CT_TARENOTSET        : MsgStr := 'Error No Tare Has Been Set';
  CT_NOWEIGHINGS       : MsgStr := 'Error Cant Weigh A Container While Performing This Process';
  CT_ORDERHEADFILEERR  : MsgStr := 'Order Header File Error';
  CT_ORDERLINEFILEERR  : MsgStr := 'Order Line File Error';
  CT_TRANSFILEERR      : MsgStr := 'Transaction File Error';
  CT_TRACEERROR        : MsgStr := 'Untraceable Weighing, Remove ingredient.';
  ELSE MsgStr := 'Error Assigning Transaction';
 END;

 IF ErrorNum = AW_WEIGHTADDED THEN
   MessageWin.DisplayMsgIfBlank(MsgStr)
 ELSE
  BEGIN
   MessageWin.ClearMsg;
   MessageWin.DisplayMsg(MsgStr,TRUE);
  END;
END;






PROCEDURE AddWeightToOrderRecs(IngredientWt : DOUBLE;
                               VAR OrdHRec  : TWOHeaderRecord;
                               VAR OrdLRec  : TWoLineRecord);
BEGIN
 WITH OrdLRec DO
  BEGIN
   WOL_TotalWtDone := WOL_TotalWtDone + IngredientWt;
   INC(WOL_TotalContDone);
  END;

 WITH OrdHRec DO
  BEGIN
   {WOH_CurrentMixWt := WOH_CurrentMixWt + IngredientWt;}
   WOH_WtDoneGross  := WOH_WtDoneGross  + IngredientWt;
  END;
END;



PROCEDURE InitTrans(VAR TRNRec  : TTranRecord;
                    VAR OrdLRec : TWOLineRecord;
                    VAR OrdHRec : TWOHeaderRecord;
                    ActualWt    : DOUBLE;
                    IngredientWt: DOUBLE;  { contributing to mix wt }
                    ContainerNo : LONGINT);{ for this ingredient in this mix }
BEGIN
 WITH TRNRec DO
  BEGIN
   TRN_Ingredient     := OrdLRec.WOL_Ingredient;
   TRN_OrderNo        := OrdHRec.WOH_OrderNo;
   TRN_OrderLineNo    := OrdLRec.WOL_LineNo;
   TRN_Revision       := OrdHRec.WOH_Revision;
   TRN_RecipeNo       := OrdHRec.WOH_RecipeNo;
   TRN_Mid            := GetCurrentMachineID;
   TRN_SerialNo       := GetNextRunNumber;
   TRN_Time           := Time;
   TRN_Date           := Date_To_Days(Date);
   TRN_UserID         := CurrentUser.USR_ID;
   TRN_ActualWeight   := ActualWt;
   TRN_ContainerWt    := IngredientWt;
   TRN_CalcNetWt      := TRN_ContainerWt * OrdLRec.WOL_Yield/100;
   TRN_BatchNo        := SelRecs.SR_CurrentBatchNo;
{$IFDEF FOPSTRACELINK}
   TRN_BatchNo := IntToZeroStr(StringToLong(TRN_BatchNo),6);
{$ENDIF}
   TRN_LotNo          := IngredientLotNumber;
   TRN_ContainerNo    := ContainerNo;
   TRN_MixNo          := OrdHRec.WOH_CurrentMix;
   TRN_Status         := TRNStatusActive;
   FillChar(Reserved,Sizeof(Reserved),#0);
  END;
END;

PROCEDURE AddToCostFile(VAR TRNRec : TTranRecord);
VAR CostRec : TCostRecord;
    Added   : BOOLEAN;
 {Add To Cost Ingredient File If Required}
BEGIN
 IF CostFile^.OpenFile = 0 THEN
  BEGIN
   Added := FALSE;
   CostFile^.InitRecord(CostRec);
   CostRec.COST_Ingredient := TRNRec.TRN_Ingredient;
   CostRec.COST_LotNumber  := TRNRec.TRN_LotNo;
   IF CostFile^.ReadRecord('EQ',TRUE,FALSE,CostRec,0) = 0 THEN
    BEGIN
     CostRec.COST_Weighed := CostRec.COST_Weighed + TRNRec.TRN_ContainerWt;
     CostFile^.UpdateRecord(CostRec);
     Added := TRUE;
    END
   ELSE IF Config_Rec^.CONF_GlobalLot THEN
    BEGIN
     CostRec.COST_LotNumber := SPACE_STRING;
     IF CostFile^.ReadRecord('EQ',TRUE,FALSE,CostRec,0) = 0 THEN
      BEGIN
       CostRec.COST_Weighed := CostRec.COST_Weighed + TRNRec.TRN_ContainerWt;
       CostFile^.UpdateRecord(CostRec);
       Added := TRUE;
      END;
    END;
   IF (NOT Added) AND (AutoAddCostRec) THEN
    BEGIN
     CostRec.COST_Weighed    := TRNRec.TRN_ContainerWt;
     CostRec.COST_Ingredient := TRNRec.TRN_Ingredient;
     CostRec.COST_LotNumber  := TRNRec.TRN_LotNo;
     CostFile^.AddRecord(CostRec);
    END;
   CostFile^.CloseFile;
  END;
END;


PROCEDURE AddTranToTotalsFile(VAR TRNRec : TTranRecord);
VAR NetRec   : TNetRecord;
    Attempts : INTEGER;
    FileErr  : INTEGER;

    PROCEDURE FillRecWithKey;
    BEGIN
     WITH TRNRec,NetRec DO
      BEGIN
       NETW_Ingredient := TRN_Ingredient;
       NETW_Date       := TRN_Date;
       NETW_BatchNo    := TRN_BatchNo;
       NETW_LotNo      := TRN_LotNo;
      END;
    END;

BEGIN
 NetFile^.OpenFile;
 Attempts := 5;
 REPEAT
  FillRecWithKey;
  FileErr := NetFile^.ReadRecord('EQ',TRUE,FALSE,NetRec,0);
  IF (FileErr = BNoRecord) THEN
   BEGIN
    FillChar(NetRec,Sizeof(NetRec),0);
    FillRecWithKey;
    NetFile^.AddRecord(NetRec);
   END;
  Dec(Attempts);
 UNTIL (Attempts = 0) OR (FileErr = 0);

 IF (FileErr = 0) THEN
  BEGIN
   Inc(NetRec.NETW_Containers);
   NetRec.NETW_NetContainerWt := NetRec.NETW_NetContainerWt + TRNRec.TRN_ContainerWt;
   NetFile^.UpdateRecord(NetRec);
  END;

 NetFile^.CloseFile;
END;


{$IFDEF FOPSTRACELINK}
PROCEDURE OCM_Dump_Port(TranString : STRING; Port_Idx : BYTE);
TYPE OCMSTRING = STRING[255];

VAR DummyInt        : INTEGER;
(*    ASearchRec      : SearchRec;*)
    HoldFileMode    : WORD;
    MessageStr      : STRING[20];
    PortChar        : CHAR;
    OCMDumpFileName : STRING;
    OCMDumpFile     : FILE OF OCMSTRING;
    Result,
    OCMDumpError    : INTEGER;

    PROCEDURE AppendTranStr;
    VAR DumpPortRec : OCMSTRING;
    BEGIN
     FillChar(DumpPortRec, SizeOf(DumpPortRec), #0);
     DumpPortRec := TranString;
     {$I-}
     Write(OCMDumpFile, DumpPortRec);
     {$I+}
     OCMDumpError := IOResult;
    END;

BEGIN
  IF Port_Idx > 9 THEN PortChar := CHAR(Port_Idx+55)
  ELSE PortChar := CHAR(Port_Idx+48);
(*
  FindFirst(Config_rec^.CONF_CommTempPath+'*.'+'$$'+PortChar, ReadOnly OR Archive, ASearchRec);
  Result := DosError;
*)
  Result := 2;
  IF Result = 0 THEN
   BEGIN
    {found a lock file send locked message dont process}
   END
  ELSE
   BEGIN
    HoldFileMode := FileMode;
    FileMode := WRITE_ONLY+DENY_ALL;
    OCMDumpFileName := Config_Rec^.CONF_CommTempPath+
                       CreateABinFileWithExtn(FILE(OCMDumpFile),
                                              SizeOF(OCMSTRING),
                                              'RC'+PortChar);
    FileMode := HoldFileMode;
    AppendTranStr;  { sets DumpError }
    {$I-}
    Close(OCMDumpFile);
    {$I+}
    IF IOResult = 0 THEN
     BEGIN
      {$I-}
      Rename(OCMDumpFile,
             Copy(OCMDumpFileName,1,Length(OCMDumpFileName)-3)+
             'RO'+PortChar);
      {$I+}
      OCMDumpError := IOResult;
     END;

    IF OCMDumpError <> 0 THEN
     BEGIN
      FOR DummyInt := 1 TO 5 DO
       BEGIN
        Sound(3000); Delay(100);
        Sound(500); Delay(100);
        NoSound; Delay(50);
       END;
      Disp_Error_Msg('IO Error: '+IntToStr(OCMDumpError,1)+
                     ' writing stock adjustment to '+OCMDumpFileName);
     END;
   END;
END;
{$ENDIF}

PROCEDURE CreateTransaction(
                     ActualWt    : DOUBLE; { already checked its in tolerance}
                                           { for Sel Mix.                    }
                     {Partial    : BOOLEAN;}
                     ActualProcessType : TProcessTypes;{ note could be different  }
                                                  { to Sel line record due to}
                                                  { last fixed wt being      }
                                                  { recorded as a variable wt}
                     ManualWtEntry: BOOLEAN); { as opposed to direct scale reading. }

VAR OrdLRec          : TWOLineRecord;
    OrdHRec          : TWOHeaderRecord;
    TRNRec           : TTranRecord;

    WOHOpenErr       : INTEGER;
    WOLOpenErr       : INTEGER;
    TRNOpenErr       : INTEGER;
    TempMixLRec      : TMixLineRecord;
    MixStatRec       : TMixStatusRecord;

    AddWeightErr     : INTEGER;
    MixCompleted     : BOOLEAN;
    IngredientCompInMix: BOOLEAN;
    TransBtrvErr     : INTEGER;
    IngredientWt     : DOUBLE;
    WOHeaderLocked   : BOOLEAN;
    FopsTran         : STRING[255];
    SaveMixNo        : LONGINT;


{$IFDEF FOPSTRACELINK}
 FUNCTION GetFops6TranStr(Weight  : DOUBLE;
                          Barcode : STRING;
                          FullIssueOffStock : BOOLEAN) : STRING;
 VAR
   ReturnStr : STRING;
   WtStr     : STRING[5];
   PlunoStr  : STRING[4];
   PluNo     : INTEGER;
 BEGIN
  { use CSV format so we can send 8 digit batch number }
  WtStr := IntToZeroStr(Double_To_FPLong(Weight,2),5);
  IF FullIssueOffStock OR NowtButSpace(Barcode) THEN
    ReturnStr := 'F,D,'
  ELSE
    ReturnStr := 'F,I,'; { part issue }

  ReturnStr := Returnstr + '3,';{ LZB3 = 2dp }

  PluNoStr := '9999';
  IF Length(Clip(SelRecs.SR_SourceBarcode)) = 20 THEN
    PluNoStr := Copy(SelRecs.SR_SourceBarcode,9,4)
  ELSE IF NowtButSpace(SelRecs.SR_SourceBarcode) THEN
   BEGIN
    PluNo := GetFops6PluNumberForIngredient(TRNRec.TRN_Ingredient);
    IF PluNo > 0 THEN
      PluNoStr := IntToZeroStr(PluNo,4);
   END;

  ReturnStr := ReturnStr + PluNoStr;

  ReturnStr := ReturnStr +','+ WtStr+','+                 { LabelWt       }
                     IntToStr(TRNRec.TRN_mid,1)+','+      { Machine ID    }
                     IntToStr(TRNRec.TRN_SerialNo,1)+','; { Serial No     }

(*
  { 8 digit Batch Number.
    Was SR_CurrentBatchNo
    Now '1' + last 5 digits of order no + 2 digit mix no.
  }                           dddddddddddd
  ReturnStr := ReturnStr +'1'; { Distinguishes mix batches from OCM batches }
                               { (fops6 line yield batch prefix doesnt work }
                               {  when received no. > 999999)               }
  IF FullIssueOffStock THEN
    ReturnStr := ReturnStr + '0999999,'
  ELSE
    ReturnStr := ReturnStr +
                 IntToZeroStr(SelRecs.WorkHRecord.WOH_OrderNo MOD 100000,5)+
                 IntToZeroStr(SelRecs.WorkHRecord.WOH_CurrentMix,2)+
                 ',';
*)ReturnStr := ReturnStr + TRNRec.TRN_BatchNo+',';

  ReturnStr := ReturnStr +
                     Days_To_DateS6(Date_To_Days(Date))+','+  { Pack Date     }
                     Copy(CurrentUser.USR_ID,1,4)+','+        { User Code     }
                     WtStr+','+                               { Gross Wt      }
                     WtStr+','+                               { ActualWt      }
                     'K,'+                                    { Wt Range      }
                     ','+                                     { Pallet        }
                     Days_To_DateS6(Date_To_Days(Date))+','+  { MinLife Date  }
                     Days_To_DateS6(Date_To_Days(Date))+','+  { MaxLife Date  }
                     '1,'+                                    { Items         }
                     Clip(Barcode)+                           { Source Barcode}
                     CHR(ETX);

  GetFops6TranStr := ReturnStr;
 END;
{$ENDIF}


BEGIN
 IngredientWt      := 0.0;
 AddWeightErr      := 0;
 WOHeaderLocked    := FALSE;

 WOHOpenErr := BFileNotOpen;
 WOLOpenErr := BFileNotOpen;
 TRNOpenErr := BFileNotOpen;

 TransBtrvErr      := 0;
 MixCompleted        := FALSE;
 IngredientCompInMix := FALSE;

 IF  (NOT ManualWtEntry)
 AND (NOT WeighProcessController.WPC_TareOk) THEN
  BEGIN
{   IF (SelRecs.WorkHRecord.WOH_MixType IN
        [mt_SingleContainerPerMix,mt_OptionallySegregated]) THEN
    BEGIN
}
     AddWeightErr := CT_TARENOTSET;
{
    END
   ELSE IF (SelRecs.TareIngredient) THEN
    BEGIN
     AddWeightErr := CT_TARENOTSET;
    END
}
  END;
{
 ELSE IF NoWeighingsAllowed THEN
  BEGIN
   AddWeightErr := CT_NOWEIGHINGS;
  END;
}

 IF (AddWeightErr = 0) AND BatchNumbersReqd
 AND NowtButSpace(SelRecs.SR_CurrentBatchNo) THEN
  BEGIN
   AddWeightErr := CT_NOBATCHNUMBER;
   DisplayTransactionResult(AddWeightErr,TransBtrvErr);
   SelRecs.EditCurrentBatchNo(TRUE);
   IF NOT NowtButSpace(SelRecs.SR_CurrentBatchNo) THEN AddWeightErr := 0;
  END;


 IF (AddWeightErr = 0) AND (LotNumbersReqd) AND
    (NowtButSpace(IngredientLotNumber)) THEN
  BEGIN
   AddWeightErr := CT_NOLOTNUMBER;
   DisplayTransactionResult(AddWeightErr,TransBtrvErr);
   SelRecs.EditIngredientLotNo(TRUE);
   IF NOT NowtButSpace(IngredientLotNumber) THEN AddWeightErr := 0;
  END;

{$IFDEF FOPSTRACELINK}
 IF  Config_Rec^.CONF_PromptForSource
 AND (CompareWts(SelRecs.SR_CurrSourceWtKg, 0.0) > 0) { weight was found / calc }
 AND (CompareWts(ActualWt, SelRecs.SR_CurrSourceWtKg+
                           (0.02*SelRecs.SR_OrigSourceWtKg)) > 0) THEN
  BEGIN
   { weight added was more than (weight left in stock + 2% of orig wt). }
   REPEAT
     IF YesNoWin('Did all of weight just added come from'+CR+LF+
                  Clip(SelRecs.SR_SourceBarcode)+ '   Calc.stock wt:'+ DoubleToStr(SelRecs.SR_CurrSourceWtKg,6,1)
                ) THEN
      BEGIN
       IF (CurrentUser.USR_AccessLvl < 10) THEN { dont believe you }
        BEGIN
         Disp_Error_Msg('User with Access Level 10 required');
         UserLogIn;
         UserWindow^.Draw;
        END;
      END
     ELSE
       AddWeightErr := CT_TRACEERROR;
   UNTIL (AddWeightErr <> 0) OR (CurrentUser.USR_AccessLvl >= 10);
  END;
{$ENDIF}

 IF AddWeightErr = 0 THEN
  BEGIN
   WOHOpenErr := WorkHeaderFile^.OpenFile;
   WOLOpenErr := WorkLineFile^.OpenFile;
   TRNOpenErr := TransFile^.OpenFile;

   OrdHRec.WOH_OrderNo := SelRecs.WorkHRecord.WOH_OrderNo;
   OrdHRec.WOH_SchDate := RecipeDay;
   OrdHRec.WOH_Revision:= SelRecs.WorkHRecord.WOH_Revision;
   {Read And Lock Header Record                                          }
   IF WorkHeaderFile^.ReadRecord('EQ',TRUE,FALSE,OrdHRec,0) = 0 THEN
    BEGIN
     WOHeaderLocked := TRUE;
     IF (OrdHRec.WOH_Status = StatusCOMP)
     OR (OrderComplete(OrdHRec)) THEN
       AddWeightErr := AW_ORDERWASCOMPLETE;
    END
   ELSE
     AddWeightErr := CT_ORDERHEADFILEERR;

   { Fudge For Campaign Weighing (Should Already Be = For Others)        }
   OrdHRec.WOH_CurrentMix := SelRecs.WorkHRecord.WOH_CurrentMix;
(* not necess as SelRecs.SR_CurrentBatchNo is now used
   { RESET BATCH NUMBER HERE (CAMPAIGN FUDGE) }
   { This Will Correct The AutoBatchNumber As Disk Record Can Have The   }
   { Wrong Mix Number on Campaing Weighing                               }
   IF (AutoBatchNumbering) THEN
     BatchNumber := IntToZeroStr(OrdHRec.WOH_AutoBatchNo+ORDHRec.WOH_CurrentMix,6);
*)
  END;

 IF (AddWeightErr = 0) THEN
  BEGIN
   {Read but dont Lock Line Record to be updated}
   IF WorkLineFile^.Get_WO_Line_Record(SelRecs.WorkHRecord.WOH_OrderNo,
                                       SelRecs.WorkHRecord.WOH_Revision,
                                       SelRecs.WorkLRecord.WOL_Lineno,
                                       OrdLRec) = 0 THEN
    BEGIN
     IF (ActualProcessType = PTStep) THEN
       IngredientWt := 0.0
     ELSE IF (ActualProcessType = PTCount) THEN
       IngredientWt := ActualWt {OrdLRec.WOL_FixedWt}
     ELSE
       IngredientWt := ActualWt;
    END
   ELSE
     AddWeightErr := CT_ORDERLINEFILEERR;
  END;

 IF AddWeightErr = 0 THEN { need to check current trans count against mix }
  BEGIN
   IF GetMixLineRecord(@OrdLRec,
                       OrdHRec.WOH_CurrentMix,
                       TempMixLRec) <> 0 THEN
     AddWeightErr := CT_TRANSFILEERR;
  END;

 IF AddWeightErr = 0 THEN { need to check mix line still needs tran }
  BEGIN
   IF IsThisLineCompleteForCurrMix(@OrdHRec, @OrdLRec,
                                   TempMixLRec.ML_WghsDone,
                                   TempMixLRec.ML_WtDone) THEN
     AddWeightErr := AW_ALREADYWEIGHED;

   { Ideally we need to check cont done for this ingredient in this mix is
     the same as when the ingredient was selected ie. stop 2 people working
     on same ingredient on the same mix.}
  END;

 IF (AddWeightErr = 0) THEN
  BEGIN
   AddWeightToOrderRecs(IngredientWt, OrdHRec, OrdLRec);

   InitTrans(TRNRec,OrdLRec,OrdHRec,ActualWt,IngredientWt,
             MainWindow^.GetCurrentContainerNo);

   IF TransFile^.AddRecord(TRNRec) = 0 THEN
    BEGIN
     { update virtual mix-line-done-file record }
     Inc(TempMixLRec.ML_WghsDone);
     TempMixLRec.ML_WtDone := TempMixLRec.ML_WtDone + TRNRec.TRN_ContainerWt;
    END
   ELSE
    BEGIN
     AddWeightErr := CT_ERRORADDINGTRN;
     TransBtrvErr := TransFile^.BtrvErr;
    END;
  END;

 IF AddWeightErr = 0 THEN { trans has been added to file }
  BEGIN
{$IFDEF FOPSTRACELINK}
(*
   IF  (SelRecs.FirstSourceWt > 0.0)
   AND (Length(SelRecs.SourceBarcodes[1]) = 20) THEN { two stock issues }
    BEGIN
     FopsTran := GetFops6TranStr(SelRecs.FirstSourceWt,
                                 SelRecs.SourceBarcodes[1]);
     OCM_Dump_Port(FopsTran,15);
     IF (Length(SelRecs.SourceBarcodes[2]) = 20) THEN { barcode scanned at partial wt }
      BEGIN
       FopsTran := GetFops6TranStr((ActualWt - SelRecs.FirstSourceWt),
                                   SelRecs.SourceBarcodes[2]);
       OCM_Dump_Port(FopsTran,15);
      END;
    END
   ELSE
*)
    { only issue one stock adjustment }
    BEGIN
     IF Config_Rec^.CONF_SendIssuesToFops6 THEN
      BEGIN
       FopsTran := GetFops6TranStr(ActualWt,SelRecs.SR_SourceBarcode,FALSE);
       OCM_Dump_Port(FopsTran,15);
      END;
    END;
{$ENDIF}

   IngredientCompInMix := IsThisLineCompleteForCurrMix(@OrdHRec, @OrdLRec,
                                                       TempMixLRec.ML_WghsDone,
                                                       TempMixLRec.ML_WtDone);

   { Update Mix Status Record For The Current Mix }
   AddWeightToMixRecord(OrdHRec.WOH_CurrentMix,
                        @OrdHRec,
                        @OrdLRec,
                        IngredientWt,
                        (IngredientCompInMix AND OrdLRec.WOL_KeyIngredient));

   { Update other files }
   AddTranToTotalsFile(TRNRec);
   IF UserTotalCosting THEN AddToCostFile(TRNRec);


   IF WorkLineFile^.UpdateRecord(OrdLRec) = 0 THEN
    BEGIN
     INC(OrdHRec.WOH_UpdateCount);
     IF WorkHeaderFile^.UpdateRecord(OrdHRec) = 0 THEN { Update/Unlock WOHeader  }
       WOHeaderLocked := FALSE;                        { Clear Record Lock Flag  }
    END;

   { All files updated, now show and print result }
   WITH OrdHRec DO
    BEGIN
     MixStatusFile^.GetMixStatRec(WOH_OrderNo, WOH_Revision, WOH_CurrentMix,
                                  MixStatRec, FALSE);
     BarsWindow^.ResetTotBar(MixStatRec.MIX_WtRequired,
                             MixStatRec.MIX_WtDone);
     BarsWindow^.ClearMainBar;
    END;

   WeighProcessController.IngredWeightAccepted; { will clear '...Accept?' msg }
   { printticket() could hang program - ok now weve cleared '...Accept?' msg }
   IF PrintTicket THEN Print_Ticket(@TRNRec,@OrdHRec,@OrdLRec);
  END;


 IF WOHeaderLocked THEN { either update it or release it }
  BEGIN
   IF AddWeightErr = AW_ORDERWASCOMPLETE THEN { make sure status reflects it }
    BEGIN
     OrdHRec.WOH_Status := StatusCOMP;
     INC(OrdHRec.WOH_UpdateCount);
     WorkHeaderFile^.UpdateRecord(OrdHRec);
     WOHeaderLocked := FALSE;
    END
   ELSE
     WorkHeaderFile^.UnLock_Single;
  END;

 IF AddWeightErr IN [0, AW_ALREADYWEIGHED] THEN { weighing done }
  BEGIN
   NoIngredientSelected := TRUE; { suppresses weight update messages eg.
                                   "Add Ingredient" because of auto taring }

   SelRecs.WorkHRecord := OrdHRec;
   SelRecs.WorkLRecord := OrdLRec;

   SendMessage(PCID,ResetTWOBRW);

{$IFDEF FOPSTRACELINK}
   IF Length(Clip(SelRecs.SR_SourceBarcode)) = 20 THEN { valid tran scanned }
    BEGIN
     { ask user if source container is empty if
       a) They used the partial weigh button
       b) Source container was less than 10% of its original weight (note:
          original weight is based on data in barcode)
       c) Weighing accounts for more than a third of the remaining weight
          that was left in stock (2 people could be working from same source).
     }
     IF BarsWindow^.LowTolHasBeenDisabled { partial wt button hit }
     OR (SelRecs.SR_CurrSourceWtKg < (SelRecs.SR_OrigSourceWtKg / 10))
     OR ((ActualWt * 3) > SelRecs.SR_CurrSourceWtKg) THEN
      BEGIN
       IF YesNoWin('Is Source Container For'+CRLF+
                   SelRecs.WorkLRecord.WOL_Ingredient+' Now Empty (Y/N)?') THEN
        BEGIN
         FopsTran := GetFops6TranStr(0.0,SelRecs.SR_SourceBarcode,TRUE);
         OCM_Dump_Port(FopsTran,15);
        END;
      END;
    END;
{$ENDIF}

   IF IngredientCompInMix THEN { maybe the mix is complete? }
    BEGIN
     SaveMixNo := SelRecs.WorkHRecord.WOH_CurrentMix;
     MixCompleted := FALSE;
     IF PrintAndAdvanceMixIfComplete(AddWeightErr=0) THEN
      BEGIN
       MixCompleted := TRUE;
(*     { PrintAndAdvanceMixIfComplete use to call PrimeNextIngredient }
       IF OrderComplete(ORDHRec) THEN { show user its now complete }
        BEGIN
         { change message from "weight accepted" to "Order now completed" }
         AddWeightErr := AW_ORDERNOWCOMPLETE;
        END;
*)
      END
     ELSE
       SelRecs.ResetForNextStep(TRUE);

     { Where are we now - inform user }
     IF OrderComplete(SelRecs.WorkHRecord) THEN
      BEGIN
       { change message from "weight accepted" to "Order now completed" }
       AddWeightErr := AW_ORDERNOWCOMPLETE;
       PrimeNextIngredient(NP_OrdComp,' Order completed.')
      END
     ELSE IF SelRecs.WorkHRecord.WOH_CurrentMix <> SaveMixNo THEN
      BEGIN
       IF MixCompleted THEN
         PrimeNextIngredient(NP_MixNoChg,
                             'Mix '+IntToStr(SaveMixNo,1)+ ' completed.')
       ELSE IF SelRecs.WorkhRecord.WOH_MixType = mt_CampaignWeighing THEN
         PrimeNextIngredient(NP_MixNoChg,
                             'Ingredient completed for Mix '+IntToStr(SaveMixNo,1))
       ELSE
         PrimeNextIngredient(NP_MixNoChg,
                             'Mix '+IntToStr(SaveMixNo,1)+ ' finished in area.');
      END
     ELSE
       PrimeNextIngredient(NP_NewLine,'Last Ingredient completed');
    END
   ELSE { do same ingredient }
    BEGIN
     PrimeNextIngredient(NP_NewCont,'');
    END;
  END;

 DisplayTransactionResult(AddWeightErr,TransBtrvErr);

 IF WOHOpenErr = 0 THEN WorkHeaderFile^.CloseFile;
 IF WOLOpenErr = 0 THEN WorkLineFile^.CloseFile;
 IF TRNOpenErr = 0 THEN TransFile^.CloseFile;
END;


END.

(****************************************************************************
*  UNIT          : SFXCurr                                                  *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Stores current order and ingredient working on           *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP.PAS}
UNIT SFXCurr;
INTERFACE
USES FXFWork,FXFIngr,FXModCtv,FXDetail,SfxStd,F6StdUtl,SfxMsg,SFXConst,
     F6StdCtv,SFXKbd,SfxEdit,SFXOList,FXFILot,F6StdWn1,FXFMix,FXFFOPS,SFXComms,
     FXCfg;

CONST
{      NP_NewMix     = 1;}
{      NP_MixAborted = 6;}
{      NP_OldMix     = 8;}

       NP_NewLine    = 2;
       NP_NewOrd     = 3;
       NP_OrdComp    = 4;
       NP_NewCont    = 5;
       NP_MultiSel   = 7;
       NP_MixNoChg   = 9;


TYPE TSelectedRecords = OBJECT
       WorkHRecord    : TWOHeaderRecord; {Current Order Selected}
       WorkLRecord    : TWOLineRecord;   {Current Order Line Selected}
       SR_IngredientType : TProcessTypes;{Current Ingredient On Order}
       SR_LastSelMixNo  : WORD;
       SR_LastSelOrdLine: TWOLineRecord; { ord line last selected }
       SR_CurrentBatchNo: TBatchRef;

       TareIngredient : BOOLEAN;
       SR_MixBarcodeScan1: STRING[20]; { first mix label barcode scanned for
                                         this selection. }
       SR_SourceBarcode  : STRING[40]; { Source Barcode last scanned }
       SR_CurrSourceWtKg : DOUBLE;     { Weight of fops tran identified by
                                         source barcode. }
       SR_OrigSourceWtKg : DOUBLE;     { orig Weight of fops tran identified by
                                         source barcode. }
       SR_UseSourceWt    : BOOLEAN;
       SR_SourceLifeDt   : LONGINT;

{      LineNoSelected : LONGINT;      }   {Linenumber currently working on}
{      WORecordSelected     : LONGINT;}   {Work Order currently working on}
{      WORevision           : BYTE;   }

       PROCEDURE SetUp;
       PROCEDURE ChangeMixTypeOfOrder(NewMixType : TMixType);
       FUNCTION  ScanRelatedMixLabels : BOOLEAN;
       FUNCTION  GetASourceBarcode : BOOLEAN;
       PROCEDURE ClearSourceBarcode;

(*     PROCEDURE GetSourceBarcode;
       PROCEDURE GetSecondSourceBarcode;*)
       PROCEDURE SetCurrentMixNoTo(MixNo : LONGINT);
       PROCEDURE ResetCurrentBatchNo; { to reflect current mix no etc }
       PROCEDURE ResetIngredientLotNo;{ to reflect current ingredient }
       FUNCTION  BatchNoNeedsEditing : BOOLEAN;
       FUNCTION  LotNoNeedsEditing : BOOLEAN;
       PROCEDURE EditCurrentBatchNo(ShowHideKbd : BOOLEAN);
       PROCEDURE EditIngredientLotNo(ShowHideKbd : BOOLEAN);
       FUNCTION  EditBatchAndLotNo : BOOLEAN;

       FUNCTION  LoadHeaderRecord(WoRecNo   : LONGINT;
                                  Revision  : BYTE;
                                  SetMixNoTo: LONGINT) : INTEGER;
       FUNCTION  LockHeaderRecord : INTEGER; { maintains current mix no }
       FUNCTION  LoadLineRecord(LineNum : INTEGER) : INTEGER;
       FUNCTION  ResetForNextStep(TranJustAdded : BOOLEAN) : BOOLEAN;
     END;

VAR SelRecs : TSelectedRecords;



PROCEDURE PrimeNextIngredient(AdvanceType : WORD; ReasonMsg : STRING);
(*FUNCTION  ShouldTareBeRemovedForThisOrder : BOOLEAN;*)
PROCEDURE SetOrderToComplete;
PROCEDURE StoreIngredientLotNumber;


IMPLEMENTATION
USES Sfx_Scrl,SFX_Main,SFX_Bars,SFXMixes,SfxScale;



{-------------------------- TSelectedRecords Object --------------------}
PROCEDURE TSelectedRecords.SetUp;
BEGIN
 FillChar(WorkHRecord,SizeOf(TWOHeaderRecord),#0);
 FillChar(WorkLRecord,SizeOf(TWOLineRecord),#0);
 SR_LastSelMixNo := 0;
 FillChar(SR_LastSelOrdLine, SizeOf(SR_LastSelOrdLine), 0);
 SR_CurrentBatchNo := GlobalBatchNumber;
 SR_MixBarcodeScan1 := '';
END;

PROCEDURE TSelectedRecords.ChangeMixTypeOfOrder(NewMixType : TMixType);
BEGIN
 WorkHeaderFile^.OpenFile;
 IF LockHeaderRecord = 0 THEN
  BEGIN
   IF (CompareWts(WorkHRecord.WOH_WtDoneGross,0.0) <= 0) THEN
    BEGIN
     WorkHRecord.WOH_MixType := NewMixType;
     WorkHeaderFile^.UpdateRecord(WorkHRecord);
    END
   ELSE
    BEGIN
     WorkHeaderFile^.Unlock_Single;                { Release Locked Record    }
     Disp_Error_MSg('Can Not Change Mix Type Once Order Has Been Weighed To');
    END;
  END;
 WorkHeaderFile^.CloseFile;
END;


PROCEDURE TSelectedRecords.SetCurrentMixNoTo(MixNo : LONGINT);
BEGIN
 WorkHRecord.WOH_CurrentMix := MixNo;
 ResetCurrentBatchNo;
 SR_MixBarcodeScan1 := '';
END;

PROCEDURE TSelectedRecords.ResetCurrentBatchNo;
BEGIN
 IF AutoBatchNumbering THEN
  BEGIN
{$IFDEF LAZENBY}  { last 4 digits of order number + mix number (2) }
   SR_CurrentBatchNo :=
               IntToZeroStr((WorkHRecord.WOH_OrderNo MOD 10000), 4) +
               IntToZeroStr((WorkHRecord.WOH_CurrentMix MOD 100), 2);

{$ELSE} { serialised batch number stamped on order (4) + mix number (2) }
   SR_CurrentBatchNo :=
               IntToZeroStr(WorkHRecord.WOH_AutoBatNoOffset, 4) +
               IntToZeroStr((WorkHRecord.WOH_CurrentMix MOD 100), 2);
{$ENDIF}
  END
 ELSE
   SR_CurrentBatchNo := GlobalBatchNumber;
END;

PROCEDURE TSelectedRecords.EditCurrentBatchNo(ShowHideKbd : BOOLEAN);
BEGIN
 IF (ShowHideKbd) THEN { pop-up keyboard }
  BEGIN
   GetStr(2,2,6,TRUE,'Enter Batch No :',SR_CurrentBatchNo);
  END
 ELSE EnterNonSpaceString(6,'Batch No',SR_CurrentBatchNo);
END;

PROCEDURE TSelectedRecords.ResetIngredientLotNo;
VAR
   LIRec   : TLotIngredientRecord;

BEGIN
 SFXSTD.IngredientLotNumber := SFXSTD.GlobalLotNumber;  { Use Default Lot#}
 IF RecallLotNumbers THEN
  BEGIN
   { Find last lot number entered for this ingredient }
   { Seek Ingredient/Lot Number Combination For Machine#  }
   IF LotIngredientFile^.OpenFile = 0 THEN
    BEGIN
     IF LotIngredientFile^.Get_LI_Record(WorkLRecord.WOL_Ingredient+SPACE_STRING,
                                         GetCurrentMachineID,
                                         LIRec,FALSE) = 0 THEN
      BEGIN                                             { Lot # Found           }
       SFXSTD.IngredientLotNumber := LIRec.LI_LotNumber { Set Current Lot Number}
      END;
     LotIngredientFile^.CloseFile;
    END;
  END;
END;

PROCEDURE TSelectedRecords.EditIngredientLotNo(ShowHideKbd : BOOLEAN);
BEGIN
 IF (ShowHideKbd) THEN
  BEGIN
   GetStr(2,2,8,TRUE,'Enter Lot No :',IngredientLotNumber);
  END
 ELSE EnterNonSpaceString(8,'Lot No',IngredientLotNumber);
END;

FUNCTION TSelectedRecords.BatchNoNeedsEditing : BOOLEAN;
BEGIN
 BatchNoNeedsEditing := BatchNumbersReqd
                    AND NowtButSpace(SelRecs.SR_CurrentBatchNo);
END;

FUNCTION TSelectedRecords.LotNoNeedsEditing : BOOLEAN;
BEGIN
 LotNoNeedsEditing := LotNumbersReqd
                  AND NowtButSpace(SFXSTD.IngredientLotNumber);
END;

FUNCTION TSelectedRecords.EditBatchAndLotNo : BOOLEAN;
BEGIN
 ShowKbd;
 IF BatchNoNeedsEditing OR ShouldUserBePromptedForLotBatch THEN
   EditCurrentBatchNo(FALSE);
 IF LotNoNeedsEditing OR ShouldUserBePromptedForLotBatch THEN
   EditIngredientLotNo(FALSE);
 LoseKbd;
 EditBatchAndLotNo := TRUE;
END;

FUNCTION TSelectedRecords.LoadHeaderRecord(WoRecNo   : LONGINT;
                                           Revision  : BYTE;
                                           SetMixNoTo: LONGINT) : INTEGER;
{REQUIRES
 PROMISES To clear header rec if cant read it.
}
VAR ReadErr : INTEGER;
BEGIN
 WorkHeaderFile^.OpenFile;
 ReadErr := WorkHeaderFile^.Get_WO_Header_Record(WoRecNo,Revision,WorkHRecord);
 IF ReadErr = 0 THEN
  BEGIN
   IF  (AutoBatchNumbering)
   AND (WorkHRecord.WOH_AutoBatNoOffset = 0) THEN
    BEGIN
     IF WorkHeaderFile^.ReadRecord('EQ',TRUE,FALSE,WorkHRecord,0) = 0 THEN
      BEGIN
       IF (WorkHRecord.WOH_AutoBatNoOffset = 0) THEN
        BEGIN
{$IFDEF LAZENBY}
         WorkHRecord.WOH_AutoBatNoOffset := WorkHRecord.WOH_OrderNo MOD 10000;
{$ELSE}
         WorkHRecord.WOH_AutoBatNoOffset := GetAutoBatchNumber;
{$ENDIF}
        END;
       WorkHeaderFile^.UpdateRecord(WorkHRecord);
      END;
    END;
  END;
 WorkHeaderFile^.CloseFile;

 IF SetMixNoTo > 0 THEN
   SetCurrentMixNoTo(SetMixNoTo); { resets current batch number }

(*
 IF (AutoBatchNumbering) THEN
  BatchNumber := IntToZeroStr(WorkHRecord.WOH_AutoBatchNo+WorkHRecord.WOH_CurrentMix,6);
*)
 LoadHeaderRecord := ReadErr;
END;


FUNCTION TSelectedRecords.ScanRelatedMixLabels : BOOLEAN;
{ REQUIRES WorkHRecord to primed primed with at least the order number
           "revision" no and mix number.
  PROMISES Returns TRUE if two related barcodes have been scanned (not mid 0).
}
VAR
  FirstMid, SecondMid : BYTE;
  ScaleTask  : TScaleTaskState;

  FUNCTION GetMidFromBarcode(Barcode : STRING) : BYTE;
  BEGIN
   GetMidFromBarcode := StringToLong(Copy(Barcode,13,2));
  END;

  FUNCTION ScanRelatedMixLabel(LabelNoDesc : STRING) : INTEGER; { Returns Mid of barcode scanned }
  VAR
    Barcode,
    CurrMixBarcode : STRING[MIXBAR_LEN];
  BEGIN
   CurrMixBarcode := OrderMixToBarcode(@WorkHRecord,0);{mid zero}
   REPEAT
     Barcode := Copy(Space_String, 1, MIXBAR_LEN);
     GetStrWithoutKbd(1,33,MIXBAR_LEN,TRUE,
            'Scan '+LabelNoDesc+' Mix Barcode Related to '+
            OrderNoToStr(WorkHRecord.WOH_OrderNo, WorkHRecord.WOH_Revision)+
            ' Mix: '+IntToStr(WorkHRecord.WOH_CurrentMix,1)+' ',Barcode);
   UNTIL NowtButSpace(Barcode)
      OR Str_Equal(CurrMixBarcode, Barcode, 12); { order/rev/mix matches }

   IF NowtButSpace(SR_MixBarcodeScan1) THEN
     SR_MixBarcodeScan1 := Barcode;

   ScanRelatedMixLabel := GetMidFromBarcode(Barcode);
  END;

BEGIN
 ScanRelatedMixLabels := TRUE;
 IF NOT Config_Rec^.CONF_ScanMixLabelsFirst THEN
   EXIT;
  (****)
 StopScaleTasks(ScaleTask);
 FirstMid := GetMidFromBarcode(SR_MixBarcodeScan1);
 SecondMid:= 0;
 IF FirstMid = 0 THEN
  BEGIN
   FirstMid := ScanRelatedMixLabel('First');
  END;

 IF FirstMid <> 0 THEN { scan another }
  BEGIN
   REPEAT
     SecondMid := ScanRelatedMixLabel('Second');
   UNTIL (SecondMid <> FirstMid);
  END;
 ScanRelatedMixLabels := (FirstMid  <> 0)
                     AND (SecondMid <> 0)
                     AND (SecondMid <> FirstMid);
 RestoreScaleTasks(ScaleTask);
END;


PROCEDURE TSelectedRecords.ClearSourceBarcode;
BEGIN
 SR_SourceBarcode  := SPACE_STRING;
 SR_CurrSourceWtKg := 0.0;
 SR_OrigSourceWtKg := 0.0;
 SR_UseSourceWt    := FALSE;
 SR_SourceLifeDt   := 0;
END;

{******** See RecipeScanFlow.doc ***********}
{*******************************************}
FUNCTION TSelectedRecords.GetASourceBarcode : BOOLEAN;
VAR ScaleTask  : TScaleTaskState;
BEGIN
 GetASourceBarcode:= TRUE;
 StopScaleTasks(ScaleTask);
 REPEAT
    ClearSourceBarcode;

    ShowKbd;
    GetStr(1,33,SizeOf(SR_Sourcebarcode)-1,TRUE,
           'Source Barcode:',SR_SourceBarcode);
    LoseKbd; { Verify... procedure might call Disp_Error_Msg }

    IF NowtButSpace(SR_SourceBarcode) THEN
     BEGIN
      GetASourceBarcode := FALSE;
      BREAK;
     {*****}
     END;

{$IFDEF FOPSTRACELINK}
    IF  (Length(Clip(SR_SourceBarcode)) = 8)
    AND (Copy(SR_SourceBarcode,1,2) = 'PO') THEN { assume its a PO no. }
     BEGIN
      BREAK;
     END;
{$ENDIF}

 UNTIL VerifyFopsBarcode(SR_SourceBarcode,
                         WorkLRecord.WOL_Ingredient,
                         SR_CurrSourceWtKg,
                         SR_OrigSourceWtKg,
                         SR_SourceLifeDt) = 0;

 RestoreScaleTasks(ScaleTask);
END;

(*
PROCEDURE TSelectedRecords.GetSourceBarcode;
BEGIN
 FirstSourceWt := 0.0; { only gets set if partial wt button hit }
 SourceBarcodes[1] := SPACE_STRING;
 GetASourceBarcode{(1)};
END;
*)
(*
PROCEDURE TSelectedRecords.GetSecondSourceBarcode;
VAR ScaleTask : TScaleTaskState;
BEGIN
 SourceBarcodes[2] := SPACE_STRING;
 GetASourceBarcode(2);
END;
*)

FUNCTION TSelectedRecords.LoadLineRecord(LineNum : INTEGER) : INTEGER;
VAR FileErr : INTEGER;
BEGIN
 FileErr := 0;
 IF LineNum < 1 THEN
  BEGIN
   FillChar(WorkLRecord,SizeOf(TWOLineRecord),#0);
  END
 ELSE
  BEGIN
   WorkLineFile^.OpenFile;
   FileErr := WorkLineFile^.Get_WO_Line_Record(WorkHRecord.WOH_OrderNo,
                                               WorkHRecord.WOH_Revision,
                                               LineNum,WorkLRecord);
   WorkLineFile^.CloseFile;
  END;

 SR_IngredientType := WorkLRecord.WOL_ProcessType;
 LoadLineRecord := FileErr;
END;


FUNCTION TSelectedRecords.LockHeaderRecord : INTEGER;
{ REQUIRES
  PROMISES 1. To maintian current mix no.
}
VAR BtrvErr   : INTEGER;
    SaveMixNo : LONGINT;
BEGIN
 SaveMixNo := WorkHRecord.WOH_CurrentMix;
 BtrvErr := WorkHeaderFile^.ReadRecord('EQ',TRUE,FALSE,WorkHRecord,1);
 WorkHRecord.WOH_CurrentMix := SaveMixNo;
 LockHeaderRecord := BtrvErr;
END;


FUNCTION TSelectedRecords.ResetForNextStep(TranJustAdded : BOOLEAN) : BOOLEAN;
{REQUIRES SelRecs header and line to be primed.
 PROMISES 1. To leave header and line alone if workable.
          2. Reset mix number and/or line to next workable step.
          3. Return FALSE if it cant find a workable step.
}
VAR FindMixResult : TFindMixResult;
BEGIN
 ResetForNextStep := TRUE;

 IF SelRecs.WorkHRecord.WOH_MixType = mt_CampaignWeighing THEN
  BEGIN
   FindMixResult := AdvanceMixIfIngredientComp(WorkLRecord);
   IF NOT (FindMixResult IN [FM_MixFound, FM_PrevMixFound]) THEN
    BEGIN
     SetCurrentMixNoTo(1);
     FindMixResult := AdvanceMixIfNotWorkable(TranJustAdded);
    END;
  END
 ELSE
   FindMixResult := AdvanceMixIfNotWorkable(TranJustAdded);

 IF NOT (FindmixResult IN [FM_MixFound, FM_PrevMixFound]) THEN
  BEGIN
   ResetForNextStep := FALSE; { change function return val }
   LoadLineRecord(0);
  END;
END;



{---------------------------------------------------------------------}


PROCEDURE SetOrderToComplete;
BEGIN
 WorkHeaderFile^.OpenFile;
 IF SelRecs.LockHeaderRecord = 0 THEN
  BEGIN
   SelRecs.WorkHRecord.WOH_Status := StatusCOMP;
   WorkHeaderFile^.UpdateRecord(SelRecs.WorkHRecord);
  END;
 WorkHeaderFile^.CloseFile;
END;


PROCEDURE StoreIngredientLotNumber;
VAR
    LIRec   : TLotIngredientRecord;
    FileErr : INTEGER;

BEGIN
 IF NOT NoIngredientSelected THEN
  BEGIN
   IF LotIngredientFile^.OpenFile = 0 THEN
    BEGIN
     FileErr := LotIngredientFile^.Get_LI_Record(SelRecs.WorkLRecord.WOL_Ingredient+SPACE_STRING,
                                                 GetCurrentMachineID,
                                                 LIRec,
                                                 FALSE);
     IF  (FileErr = 0)
     AND (LIRec.LI_LotNumber <> SFXSTD.IngredientLotNumber) THEN
      BEGIN
       LotIngredientFile^.Update_LI_Record(SelRecs.WorkLRecord.WOL_Ingredient,
                                           SFXSTD.IngredientLotNumber,
                                           GetCurrentMachineID,
                                           LIRec);
      END
     ELSE IF FileErr = BNoRecord THEN
      BEGIN
       { Store New Ingredient/Lot# Combination For Machine ID }
       LotIngredientFile^.Add_LI_Record(SelRecs.WorkLRecord.WOL_Ingredient,
                                        SFXSTD.IngredientLotNumber,
                                        GetCurrentMachineID,
                                        LIRec);
      END;
     LotIngredientFile^.CloseFile;
    END;
  END;
END;




{This procedure is used to set sequence in sequenced fixed orders}
PROCEDURE PrimeNextIngredient(AdvanceType : WORD; ReasonMsg : STRING);
VAR Msg             : STRING;
    ExpectedLineNo,
    NextLineNo      : INTEGER;
    BoxNo           : INTEGER;
(*  UserIDRead      : BOOLEAN;*)


    PROCEDURE AppendSelectIngredMsgIfNecess;
    BEGIN
     IF  (AdvanceType <> NP_OrdComp)    { should be something to select }
     AND (NextLineNo = 0)               { nothing auto selected }
     AND (SelectableElementsInList > 0) { there is something to select }
     AND ((SizeOf(MessageWin.Msg) - Length(Msg)) > 23) THEN
       Msg := Msg+' Select New Ingredient';
    END;
    {---------------}

    PROCEDURE RefreshScreen;
    BEGIN
     ScrollerWindows^.ResetHighBar(NextLineNo);
     ScrollerWindows^.ShowOrderLineNo(ExpectedLineNo);
     MainWindow^.RefreshDetails(NextLineNo);

     AppendSelectIngredMsgIfNecess;
     IF NOT NowtButSpace(Msg) THEN { clear any existing message and show it }
      BEGIN
(*     MessageWin.ClearMsg; not neccessary *)
       MessageWin.DisplayMsg(Msg,TRUE);
      END;
    END;
    {---------------}


    PROCEDURE ResetLineNoAndScrollerPos;
    BEGIN
     IF OrderComplete(SelRecs.WorkHRecord) THEN
       NextLineNo := 0
     ELSE
      BEGIN
       CASE AdvanceType OF
       NP_NewLine : BEGIN
                     NextLineNo := FindNextWipLineForTerminal(@SelRecs.WORKHRecord,
                                                              NextLineNo);
                    END;
(*     NP_NewMix,
       NP_MixAborted,
       NP_OldMix
*)
       NP_MixNoChg: BEGIN
                     IF SelRecs.WorkHRecord.WOH_Mixtype <> mt_CampaignWeighing THEN
                       NextLineNo := 1;
                     NextLineNo := FindNextWipLineForTerminal(@SelRecs.WORKHRecord,
                                                              NextLineNo);
                    END;

       NP_OrdComp : NextLineNo := 0;

       NP_NewOrd  : BEGIN
                     { SelRec header and line should be fully initialised
                       before calling PrimeNextIngredient()
                     }
                    END;
       END;
      END;

     ExpectedLineNo := NextLineNo;

     { note: campaign weighing auto selects the current ingredient but if
             order is not fixed sequence then user can pick a different one }
     IF SelRecs.WorkHRecord.WOH_SeqFixed THEN
      BEGIN
       IF  (NextLineNo > 0)
       AND (NOT CanDoIngredientNow(NextLineNo)) THEN
         NextLineNo := 0;
       SelRecs.LoadLineRecord(NextLineNo)
      END
     ELSE IF SelRecs.WorkHRecord.WOH_MixType <> mt_CampaignWeighing THEN
      BEGIN
       FillChar(SelRecs.WorkLRecord,SizeOf(SelRecs.WorkLRecord),#0);
       NextLineNo := 0; { so its not highlighted/selected }
      END;
    END;
    {---------------}


   PROCEDURE ReloadOrderHeader;
   BEGIN
    WITH SelRecs DO { re-read header from file }
      LoadHeaderRecord(WorkHRecord.WOH_OrderNo,
                       WorkHRecord.WOH_Revision,
                       SelRecs.WorkHRecord.WOH_CurrentMix);
   END;
   {---------------}

   PROCEDURE DoMixChangeStuff;
   BEGIN
    Msg := ReasonMsg;
    ReloadOrderHeader;
    ScaleWindow^.ClearScaleTareWt;
    BuildLineRecipeList(@SelRecs.WorkHRecord,TRUE);
    ResetLineNoAndScrollerPos;
    RefreshScreen;
   END;
   {---------------}


   PROCEDURE DoNewLineStuff;
   VAR CurrentListPos : LONGINT;
   BEGIN
    ReloadOrderHeader; {Re-read Order Header Record Before Doing Anything}
    Msg := ReasonMsg;
    ResetLineNoAndScrollerPos;
    RefreshScreen;
   END;
   {---------------}

   PROCEDURE DoNewOrderStuff;
   { Scroller UserActivateFunction will have loaded the header with the next
     available mix number. }
   VAR Err : INTEGER;
   BEGIN
(*  ReloadOrderHeader;
    IF SelRecs.WorkHRecord.WOH_Status <> StatusComp THEN
     BEGIN
      WorkLineFile^.OpenFile;
      PrintAndAdvanceMixIfComplete(FALSE); {recurses once if mix/order complete}
      WorkLineFile^.CloseFile;
     END;
*)
    ResetLineNoAndScrollerPos;
    RefreshScreen;
   END;
   {---------------}

   PROCEDURE DoOrderCompleteStuff;
   BEGIN
    ReloadOrderHeader;
    {Order Complete Message Already Displayed}
    Msg := '';
    ResetLineNoAndScrollerPos;
    RefreshScreen;
   END;
   {---------------}

   PROCEDURE DoNewContainerStuff;
   BEGIN
    RefreshScreen;
   END;
   {---------------}


BEGIN
 NextLineNo := SelRecs.WorkLRecord.WOL_LineNo;
 ExpectedLineNo := NextLineNo;
 MessageWin.ClearMsg;
 Msg := '';
(* UserIDRead := FALSE;*)

 CASE AdvanceType OF
(*
  NP_NewMix     : DoNewMixStuff;
*)
  NP_NewLine    : DoNewLineStuff;
  NP_NewOrd     : DoNewOrderStuff;
  NP_OrdComp    : DoOrderCompleteStuff;
  NP_NewCont    : DoNewContainerStuff;
(*  NP_MixAborted : DoAbortedMixStuff;*)
(*  NP_MultiSel   : DoMultiSelectStuff;*)
(*  NP_OldMix     : DoReturnToMixStuff;*)
  NP_MixNoChg   : DoMixChangeStuff;
  ELSE RefreshScreen;
 END;
END;


END.
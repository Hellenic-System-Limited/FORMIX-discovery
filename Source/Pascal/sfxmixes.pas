(****************************************************************************
*  UNIT          : SFXMixes                                                 *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Mix Changing Routines                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXMixes;
INTERFACE
USES F6StdUtl,F6StdWn1,F6Btrv,FxCfg,FXFTrn,FXFWork,SFXOList,FXFMix,SFXTIKET,SFXMsg,
     FXDetail,SFXStd,SFXScale,FXFCost,SFXWin,SFXBtn,F6StdCtv,SfxStdBt,SFXKbd,
     FXFStock,FXModCtv,SFXConst,SFXLog;


TYPE TFindMixResult = (FM_MixFound,
                       FM_AllMixesComplete,
                       FM_PrevMixFound,
                       FM_IngredCompInAllMixes,
                       FM_MixesFinishedInArea,
                       FM_OrderNotFound);
(*
     PNextMix = ^TNextMix;
     TNextMix = OBJECT(TButtonWindow)
      FUNCTION UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
      PROCEDURE Draw;Virtual;
     END;
*)
(*
     PAbortMix = ^TAbortMix;
     TAbortMix = OBJECT(TPCXButton)
      FUNCTION UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
{      PROCEDURE Draw; VIRTUAL;}
     END;
*)

FUNCTION PrintAndAdvanceMixIfComplete(PrintMixIfComplete : BOOLEAN) : BOOLEAN;

{PROCEDURE AbortCurrentMix;}
PROCEDURE AbortCurrentMixButtonHit;
PROCEDURE DelayCurrentMix;
FUNCTION  ReturnToMix(MixNo : WORD) : BOOLEAN;
FUNCTION  AdvanceMixIfIngredientComp(IngredLine : TWOLineRecord) : TFindMixResult;
FUNCTION  AdvanceMixIfNotWorkable(PrintMixIfNotWorkable : BOOLEAN) : TFindMixResult;

(*VAR*)
(*    NextMix           : PNextMix;*)
(*    AbortMix          : PAbortMix;*)

IMPLEMENTATION
USES SFX_Scrl,SFXCurr,SFXCOLR;
{============================================================================}
{=================NON Global Functions and Procedures========================}
{============================================================================}
(*
FUNCTION AbortAssociatedTransactions(VAR OrdHRec : TWOHeaderRecord) : BOOLEAN;
VAR TRNRec     : TTranRecord;
    ReadErr    : INTEGER;
    DelCosting : BOOLEAN;
    CostRec    : TCostRecord;
    TranLocked : BOOLEAN;
BEGIN
 IF UserTotalCosting THEN
  BEGIN
   DelCosting := YesNoWin('     Mark Ingredients As Lost'+CRLF+
                          '     On Costing Record? (Y/N)');
  END
 ELSE DelCosting := FALSE;
 IF DelCosting THEN CostFile^.OpenFile;
 TransFile^.OpenFile;
 FillChar(TRNRec,SizeOf(TTranRecord),#0);
 TRNRec.TRN_OrderNo := OrdHRec.WOH_OrderNo;
 TRNRec.TRN_Revision:= OrdHRec.WOH_Revision;
 TRNRec.TRN_MixNo   := OrdHRec.WOH_CurrentMix;
 ReadErr := TransFile^.ReadRecord('GE',TRUE,FALSE,TRNRec,2);
 TranLocked := (ReadErr = 0);
 WHILE (ReadErr = 0) AND
  (TRNRec.TRN_OrderNo  = OrdHRec.WOH_OrderNo)   AND
  (TRNRec.TRN_Revision = OrdHRec.WOH_Revision) AND
  (TRNRec.TRN_MixNo    = OrdHRec.WOH_CurrentMix) DO
  BEGIN
   AbortTranRecord(@TRNRec);
   IF DelCosting THEN
    BEGIN
     CostFile^.GetCostRecord(TRNRec.TRN_Ingredient,TRNRec.TRN_LotNo,CostRec,TRUE,FALSE);
     WITH CostRec DO
      BEGIN
       COST_Wasted := COST_Wasted + TRNRec.TRN_ContainerWt;
      END;
     CostFile^.UpdateRecord(CostRec);
    END;
   TransFile^.UpdateRecord(TRNRec);    { Update/Unlock Transaction Record }
   ReadErr := TransFile^.ReadRecord('GN',TRUE,FALSE,TRNRec,2);
   TranLocked := (ReadErr = 0);
  END;
 IF TranLocked THEN TransFile^.Unlock_Single;
 IF (ReadErr =0) OR (ReadErr = 4) OR (ReadErr = 9) THEN
  AbortAssociatedTransactions := TRUE
 ELSE
  AbortAssociatedTransactions := FALSE;
 IF DelCosting THEN CostFile^.CloseFile;
 TransFile^.CloseFile;
END;
*)

PROCEDURE OpenOrderRelatedFiles;
BEGIN
 Show_Btrv_Err(WorkHeaderFile^.OpenFile);
 Show_Btrv_Err(MixStatusFile^.OpenFile);
 Show_Btrv_Err(WorkLineFile^.OpenFile);
 Show_Btrv_Err(TransFile^.OpenFile);
END;

PROCEDURE CloseOrderRelatedFiles;
BEGIN
 WorkHeaderFile^.CloseFile;
 MixStatusFile^.CloseFile;
 WorkLineFile^.CloseFile;
 TransFile^.CloseFile;
END;



{Returns Btrv Err}
FUNCTION GetAndLockSelHeaderAndMixRecs(VAR OrdHRec : TWOHeaderRecord;
                                       VAR MixRec  : TMixStatusRecord) : INTEGER;
{REQUIRES 1. Header and Mix file to be open.
          2. FilesRecords that can be written over.
 PROMISES To return with both records locked or none at all.
          To set WOH_CurrentMix to that in Sel record.
}
VAR BtrvErr : INTEGER;
BEGIN
 BtrvErr := SelRecs.LockHeaderRecord;
 OrdHRec := SelRecs.WorkHRecord;
 FillChar(MixRec, SizeOf(MixRec), 0);
 IF BtrvErr = 0 THEN { header locked }
  BEGIN
   WorkHeaderToMixStatus(OrdHRec,MixRec);
   MixRec.MIX_No := SelRecs.WorkHRecord.WOH_CurrentMix;
   BtrvErr := MixStatusFile^.ReadRecord('EQ',TRUE,FALSE,MixRec,0);
   IF BtrvErr <> 0 THEN
     WorkHeaderFile^.Unlock_Single;
  END;
 GetAndLockSelHeaderAndMixRecs := BtrvErr;
END;

(*
FUNCTION UpdateMixStatusFile (MixNo   : LONGINT;
                              OrdHRec : PWOHeaderRecord;
                              NewCompletionStatus : BOOLEAN) : DOUBLE;

VAR MixStatus   : TMixStatusRecord;
    Update      : BOOLEAN;
BEGIN
 WorkHeaderToMixStatus(OrdHRec,MixStatus);
 MixStatus.MIX_No := MixNo;
 Update := MixStatusFile^.ReadRecord('EQ',TRUE,FALSE,MixStatus,0) = 0;

 MixStatus.MIX_Complete := NewCompletionStatus;

 IF Update THEN
  MixStatusFile^.UpdateRecord(MixStatus)
 ELSE
  MixStatusFile^.AddRecord(MixStatus);
 UpdateMixStatusFile := MixStatus.MIX_WtDone;
END;
*)
(*
PROCEDURE ZeroLineQuantaties(VAR OrdHRec : TWOHeaderRecord;DecrementLineTotals : BOOLEAN);
VAR OrdLRec     : TWOLineRecord;
    LineReadErr : INTEGER;
BEGIN
 WorkLineFile^.OpenFile;
 OrdLRec.WOL_OrderNo := SelRecs.WorkHRecord.WOH_OrderNo;
 OrdLRec.WOL_Revision:= SelRecs.WorkHRecord.WOH_Revision;
 OrdLRec.WOL_LineNo  := 0;
 LineReadErr := WorkLineFile^.ReadRecord('GE',FALSE,FALSE,OrdLRec,0);
 WHILE (LineReadErr = 0) AND (OrdLRec.WOL_Revision = OrdHRec.WOH_Revision)
  AND (OrdLRec.WOL_OrderNo = OrdHRec.WOH_OrderNo) DO
  BEGIN
   WITH OrdLRec DO
    BEGIN
     IF DecrementLinetotals THEN
      BEGIN
       WOL_TotalWtDone    := WOL_TotalWtDone - WOL_MixWtDone;
       WOL_TotalContDone  := WOL_TotalContDone - WOL_MixContDone;
      END;
     WOL_MixContDone := 0;
     WOL_MixWtDone   := 0.0;
    END;
   WorkLineFile^.UpdateRecord(OrdLRec);
   LineReadErr := WorkLineFile^.ReadRecord('GN',FALSE,FALSE,OrdLRec,0);
  END;
 WorkLineFile^.CloseFile;
END;
*)
(*
PROCEDURE AddTranWtsToOrderHeadAndLines(VAR OrdHRec : TWOHeaderRecord);
VAR TRNRec     : TTranRecord;
    ReadErr    : INTEGER;
    WOLineList : WorkLineList;
    NumLines   : INTEGER;
    I          : INTEGER;

  PROCEDURE ReadAllLinesIntoList;
  VAR ReadErr : INTEGER;
      WOLine  : TWOLineRecord;
  BEGIN
   FillChar(WOLineList,SizeOf(WOLineList),#0);
   NumLines := 0;
   WITH OrdHRec DO
    BEGIN
     ReadErr := WorkLineFile^.Get_Wo_Line_Record(WOH_OrderNo,WOH_Revision,1,WOLine);
     WHILE (ReadErr = 0) AND (WoLine.WOL_OrderNo = WOH_OrderNo) AND
           (WOLine.WOL_Revision = WOH_Revision) AND(NumLines < MAX_LINES_ON_RECORD) DO
      BEGIN
       INC(NumLines);
       NEW(WOLineList[NumLines]);
       WOLineList[NumLines]^ := WOLine;
       ReadErr := WorkLineFile^.ReadRecord('GN',FALSE,FALSE,WOLine,0);
      END;
    END;
  END;

  PROCEDURE SaveOrderLineRecords;
  VAR WOLine  : TWOLineRecord;
  BEGIN
   WHILE (NumLines>0) DO
    BEGIN
     IF (NumLines<=MAX_LINES_ON_RECORD) AND (WOLineList[NumLines] <> NIL) THEN
      BEGIN
       WOLine := WOLineList[NumLines]^;
       WorkLineFile^.ReadRecord('EQ',TRUE,FALSE,WOLine,0);
       WorkLineFile^.UpdateRecord(WOLineList[NumLines]^);
       Dispose(WOLineList[NumLines]);
      END;
     Dec(NumLines);
    END;
  END;

BEGIN
 ReadAllLinesIntoList;
 FillChar(TRNRec,SizeOf(TTranRecord),#0);
 TRNRec.TRN_OrderNo := OrdHRec.WOH_OrderNo;
 TRNRec.TRN_Revision:= OrdHRec.WOH_Revision;
 TRNRec.TRN_MixNo   := OrdHRec.WOH_CurrentMix;
 ReadErr := TransFile^.ReadRecord('GE',FALSE,FALSE,TRNRec,2);
 WHILE (ReadErr = 0) AND
  (TRNRec.TRN_OrderNo  = OrdHRec.WOH_OrderNo) AND
  (TRNRec.TRN_Revision = OrdHRec.WOH_Revision) AND
  (TRNRec.TRN_MixNo    = OrdHRec.WOH_CurrentMix) DO
  BEGIN
   IF TRNRec.TRN_Status <> TRNStatusAborted THEN
    BEGIN
     FOR I := 1 TO NumLines DO
      BEGIN
       IF  (WOLineList[I]^.WOL_Ingredient = TRNRec.TRN_Ingredient)
       AND (WOLineList[I]^.WOL_LineNo = TRNRec.TRN_OrderLineNo) THEN
        BEGIN
         WITH WOLineList[I]^ DO
          BEGIN
           INC(WOL_MixContDone);
           WOL_MixWtDone := WOL_MixWtDone + TRNRec.TRN_ContainerWt;
           OrdHRec.WOH_CurrentMixWt  := OrdHRec.WOH_CurrentMixWt + TRNRec.TRN_ContainerWt;
          END;
         Break;
        END;
      END;
    END;
   ReadErr := TransFile^.ReadRecord('GN',FALSE,FALSE,TRNRec,2);
  END;
 SaveOrderLineRecords;
END;
*)

PROCEDURE DisplayMixSearchResult(ResultCode : TFindMixResult);
BEGIN
 MessageWin.ClearMsg;
 CASE ResultCode OF
   FM_AllMixesComplete : Disp_Error_Msg('Order Is Now Complete');
   FM_PrevMixFound     : Disp_Error_Msg('Returning To Earlier Mix');
   FM_IngredCompInAllMixes: Disp_Error_Msg(
                         'Ingredient is complete in all mixes');
   FM_MixesFinishedInArea : Disp_Error_Msg(
                         'Order is Finished in This Preperation Area');
   FM_OrderNotFound    : Disp_Error_Msg('Order Not Found');
  END;
END;


FUNCTION SetCurrMixNoToAnUnfinishedMix(VAR OrdHRec : TWOHeaderRecord) : TFindMixResult;
{PROMISES To set current mix no to WOH_NumMixes and status to COMP if no
          mix found.
}
VAR
  OrigMixNo : LONGINT;
  Result : TFindMixResult;

  PROCEDURE SearchForwardUptoMixNo(MaxMixNo : LONGINT);
  BEGIN
   {Find Next Non Complete Mix Or Exit If No More Mixes}
   WITH OrdHRec DO
    BEGIN
     WHILE (WOH_CurrentMix <= MaxMixNo)
     AND   IsMixComplete(WOH_CurrentMix, WOH_OrderNo, WOH_Revision) DO
      BEGIN
       INC(WOH_CurrentMix);                          { Advance Mix Number }
      END;
    END;
  END;
  {------------}

BEGIN
 Result := FM_MixFound; { DEFAULT RESULT }

 OrigMixNo := OrdHRec.WOH_CurrentMix;

 WITH OrdHRec DO
  BEGIN
   SearchForwardUptoMixNo(WOH_NumMixes);     {Find first Non Complete Mix   }
   IF WOH_CurrentMix > WOH_NumMixes THEN
    BEGIN
     IF (OrigMixNo > 1) THEN {return to first mix and search from there.}
      BEGIN
       WOH_CurrentMix := 1;
       SearchForwardUptoMixNo(OrigMixNo-1);
       IF WOH_CurrentMix >= OrigMixNo THEN
         Result := FM_AllMixesComplete
       ELSE { mix number below orig mix no found }
         Result := FM_PrevMixFound;
      END
     ELSE
       Result := FM_AllMixesComplete;
    END;

   IF Result = FM_AllMixesComplete THEN
    BEGIN
     WOH_CurrentMix := WOH_NumMixes;
     WOH_Status := StatusComp;
    END;
  END;

 SetCurrMixNoToAnUnfinishedMix := Result;
END;

FUNCTION AdvanceMixIfIngredientComp(IngredLine : TWOLineRecord): TFindMixResult;
{REQUIRES OrderLineFile to be open.
 PROMISES Re-reads line from file after locking header.
          To update order header in param list and in file.
          To update all order lines in file.
}

{ This only works if key ingredient logic and last mix compensation logic
  hasnt been applied to the order ie its campaign weighing.
}

VAR
    OrdHRec : TWOHeaderRecord;
    MixFoundForIngredient : BOOLEAN;
    MixFindErr   : TFindMixResult;
    LoopedRound  : BOOLEAN;
    OrigMixNo    : LONGINT;
BEGIN
 MixFindErr := FM_OrderNotFound;
 MixFoundForIngredient := FALSE;
 OpenOrderRelatedFiles;

 IF SelRecs.LockHeaderRecord = 0 THEN
  BEGIN
   OrdHRec := SelRecs.WorkHRecord;
   WITH ORDHRec,IngredLine DO
    BEGIN
     LoopedRound := FALSE;
     OrigMixNo   := WOH_CurrentMix;
     REPEAT
       MixFindErr := SetCurrMixNoToAnUnfinishedMix(OrdHRec);
       IF MixFindErr IN [FM_MixFound, FM_PrevMixFound] THEN
        BEGIN
         { found a unfinished mix, but ingredient unfinished? }
         IF NOT LineNoCompleteForCurrMix(@OrdHRec, IngredLine.WOL_LineNo) THEN
          BEGIN
           MixFoundForIngredient := TRUE;
           BREAK;
          {*****}
          END
         ELSE IF LoopedRound AND (OrdHRec.WOH_CurrentMix >= OrigMixNo) THEN
           BREAK { back where we started }
          {*****}
         ELSE
          BEGIN
           Inc(WOH_CurrentMix); { skip this mix }
          END;
        END
       ELSE
         BREAK;

       IF MixFindErr = FM_PrevMixFound THEN { found a prev mix but ingred comp }
         LoopedRound := TRUE;

     UNTIL (MixFindErr = FM_AllMixesComplete);
        {OR (WOH_CurrentMix > WOH_NumMixes)}
        {OR (LoopedRound AND (OrdHRec.WOH_CurrentMix >= OrigMixNo));}

     {WOH_CurrentMixWt  := 0;}
     INC(WOH_UpdateCount);
    END;
   WorkHeaderFile^.UpdateRecord(OrdHRec);
   SelRecs.WorkHRecord := OrdHRec;
   SelRecs.SetCurrentMixNoTo(OrdHRec.WOH_CurrentMix); { resets batch no. etc }

   IF MixFoundForIngredient THEN
    BEGIN
     { Auto Batch Number Set Here For Campaign Weighing}
(*   dont need to do this - batch number reset on mainwindow refresh
     IF (AutoBatchNumbering) THEN                    { IF Autobatch # on     }
      BEGIN                                          { Generate Batch #      }
       BatchNumber := IntToZeroStr(SelRecs.WorkHRecord.WOH_AutoBatchNo+
                                   SelRecs.WorkHRecord.WOH_CurrentMix,6);
      END;
*)
    END
   ELSE IF NOT (MixFindErr = FM_AllMixesComplete) THEN
    BEGIN
     MixFindErr := FM_IngredCompInAllMixes; { change return code }
(*     DisplayMixSearchResult(MixFindErr);*)
    END;
  END;
 CloseOrderRelatedFiles;

 AdvanceMixIfIngredientComp := MixFindErr;
END;


FUNCTION AdvanceMixIfNotWorkable(PrintMixIfNotWorkable : BOOLEAN) : TFindMixResult;
{REQUIRES
 PROMISES 1. If current mix is workable its left as current.
          2. SelRecs.WorkLOrdLRec is only changed if current mix is workable.
}
VAR
  OrdHRec             : TWOHeaderRecord;
  MixFoundForPrepArea : BOOLEAN;
  MixFindErr          : TFindMixResult;
  LoopedRound         : BOOLEAN;
  OrigMixNo           : LONGINT;
  SearchFromLineNo,
  WorkableLineNo      : LONGINT;
BEGIN
 MixFindErr          := FM_MixFound;
 MixFoundForPrepArea := FALSE;

 IF SelRecs.WorkHRecord.WOH_SeqFixed THEN { make sure left most ingred is found and loaded }
   SearchFromLineNo := 1
 ELSE { continue on from last line selected }
   SearchFromLineNo := SelRecs.WorkLRecord.WOL_LineNo;

 { try staying on current mix }
 WorkableLineNo := FindNextWipLineForTerminal(@SelRecs.WorkHRecord,
                                              SearchFromLineNo);
 IF WorkableLineNo > 0 THEN { stay on current mix }
  BEGIN
   SelRecs.LoadLineRecord(WorkableLineNo);
   MixFoundForPrepArea := TRUE;
  END
 ELSE { need to move onto another mix }
  BEGIN
   SearchFromLineNo := 1;
   OpenOrderRelatedFiles;

   IF PrintMixIfNotWorkable AND GetPrintMixTicket THEN { print current mix label }
    BEGIN
     Print_Mix_Total_Ticket;
    END;

   MixFindErr := FM_OrderNotFound;
   IF SelRecs.LockHeaderRecord = 0 THEN
    BEGIN
     OrdHRec := SelRecs.WorkhRecord;
     WITH ORDHRec DO
      BEGIN
       LoopedRound := FALSE;
       OrigMixNo   := WOH_CurrentMix;
       REPEAT
         MixFindErr := SetCurrMixNoToAnUnfinishedMix(OrdHRec);
         IF MixFindErr IN [FM_MixFound, FM_PrevMixFound] THEN
          BEGIN
           { found a unfinished mix, but can this terminal work on it }
           WorkableLineNo := FindNextWipLineForTerminal(@OrdHRec,
                                                        SearchFromLineNo);
           IF WorkableLineNo > 0 THEN
            BEGIN
             SelRecs.LoadLineRecord(WorkableLineNo);
             MixFoundForPrepArea := TRUE;
             BREAK;
            {*****}
            END
           ELSE IF LoopedRound AND (OrdHRec.WOH_CurrentMix >= OrigMixNo) THEN
             BREAK { back where we started }
            {*****}
           ELSE
            BEGIN
             Inc(WOH_CurrentMix);   { so SetCurrMixnoToAnUn.. doesnt find same mix }
            END;
          END
         ELSE
           BREAK;

         IF MixFindErr = FM_PrevMixFound THEN { found a prev mix but ingred comp }
           LoopedRound := TRUE;

       UNTIL (MixFindErr = FM_AllMixesComplete);
          {OR (WOH_CurrentMix > WOH_NumMixes)}
          {OR (LoopedRound AND (OrdHRec.WOH_CurrentMix >= OrigMixNo));}

       {WOH_CurrentMixWt  := 0;}
       INC(WOH_UpdateCount);
      END;
     WorkHeaderFile^.UpdateRecord(OrdHRec);
     SelRecs.WorkHRecord := OrdHRec;
     SelRecs.SetCurrentMixNoTo(OrdHRec.WOH_CurrentMix); { resets batch no. etc }

     IF MixFoundForPrepArea THEN
      BEGIN
(*   dont need to do this - batch number reset on mainwindow refresh
       IF (AutoBatchNumbering) THEN                    { IF Autobatch # on     }
        BEGIN                                          { Generate Batch #      }
         BatchNumber := IntToZeroStr(SelRecs.WorkHRecord.WOH_AutoBatchNo+
                                   SelRecs.WorkHRecord.WOH_CurrentMix,6);
        END;
*)
      END
     ELSE IF NOT (MixFindErr = FM_AllMixesComplete) THEN
      BEGIN
       MixFindErr := FM_MixesFinishedInArea; { change return code }
       DisplayMixSearchResult(MixFindErr);
      END;
    END;
   CloseOrderRelatedFiles;
  END;

 AdvanceMixIfNotWorkable := MixFindErr;
END;



{============================================================================}
{=====================Global Functions and Procedures========================}
{============================================================================}

FUNCTION ChangeMixStatusIfComplete : BOOLEAN;
{REQUIRES
 PROMISES To update SelRecs.WorkHRecord from disk with the exception of
          WOH_CurrentMix field IF TRUE IS RETURNED.
}
VAR
  MixCompleted : BOOLEAN;
  TempOrdHRec  : TWOHeaderRecord;
  MixRec       : TMixStatusRecord;
BEGIN
 MixCompleted := FALSE;
 IF GetAndLockSelHeaderAndMixRecs(TempOrdHRec,MixRec) = 0 THEN
  BEGIN
   IF MixRec.MIX_Complete THEN
     MixCompleted := TRUE
   ELSE  { see if its now been completed }
    BEGIN
     { Checking mix '+IntToStr(TempOrdHRec.WOH_CurrentMix,1)+' for completion');}
     IF AllLinesCompleteForCurrMix(TempOrdHRec) THEN
      BEGIN { need to update header and mix rec }
       { re-read mix file - position could be moved by  }
       { AllLinesCompleteForCurrMix()                   }
       IF GetAndLockSelHeaderAndMixRecs(TempOrdHRec,MixRec) = 0 THEN
        BEGIN
         MixRec.MIX_Complete := TRUE;
         Inc(TempOrdHRec.WOH_MixDone);
         IF OrderComplete(TempOrdHRec) THEN { reset schedule status }
           TempOrdHRec.WOH_Status := StatusCOMP;

         IF MixStatusFile^.UpdateRecord(MixRec) = 0 THEN
          BEGIN
           MixCompleted := TRUE;
           WorkHeaderFile^.UpdateRecord(TempOrdHRec);
           SelRecs.WorkHRecord := TempOrdHRec;

           IF (Config_Rec^.Conf_Stock) THEN
             AddStockRecord(TempOrdHRec.WOH_RecipeNo, MixRec.MIX_WtDone);
          END;
        END;
      END;
    END;
  END;
 MixStatusFile^.Unlock_Single;
 WorkHeaderFile^.Unlock_Single;
 ChangeMixStatusIfComplete := MixCompleted;
END;



FUNCTION PrintAndAdvanceMixIfComplete(PrintMixIfComplete : BOOLEAN) : BOOLEAN;
{REQUIRES 'Sel' to be current.
 PROMISES 1. Returns TRUE if current mix is complete.
          2. Will set order status to complete (and write update to file) if
             all mixes complete.
}
VAR OrdHRec      : TWOHeaderRecord;
    HeadReadErr  : INTEGER;
    CurrMixWt    : DOUBLE;
    MixFindErr   : TFindMixResult;
    OrigMixNo    : LONGINT;
    MixIsNowOrWasComplete : BOOLEAN;
BEGIN
 OpenOrderRelatedFiles;

 MixIsNowOrWasComplete := ChangeMixStatusIfComplete;

 IF MixIsNowOrWasComplete THEN { current mix, is now / was, completed }
  BEGIN
   { print ticket for completed mix (when order unlocked)}
   IF PrintMixIfComplete AND GetPrintMixTicket THEN
    BEGIN
     Print_Mix_Total_Ticket{(SelRecs.WorkHRecord,
                            (ScaleConfRec.PrinterType <> UBI_Printer))};
    END;

   IF SelRecs.LockHeaderRecord = 0 THEN
    BEGIN
     OrdHRec := SelRecs.WorkHRecord;
     OrigMixNo := OrdHRec.WOH_CurrentMix;
     MixFindErr := SetCurrMixNoToAnUnfinishedMix(OrdHRec);
     INC(OrdHRec.WOH_UpdateCount);
     WorkHeaderFile^.UpdateRecord(OrdHRec);
     SelRecs.WorkHRecord := OrdHRec;
     SelRecs.SetCurrentMixNoTo(OrdHRec.WOH_CurrentMix); { resets batch no. etc }
     DisplayMixSearchResult(MixFindErr);
    END;
  END;

(* caller should do this if required
 IF OrderComplete(SelRecs.WorkHRecord) THEN
   PrimeNextIngredient(NP_OrdComp)
 ELSE IF MixIsNowOrWasComplete THEN
   PrimeNextIngredient(NP_NewMix);
*)
 CloseOrderRelatedFiles;

 PrintAndAdvanceMixIfComplete := MixIsNowOrWasComplete;
END;


PROCEDURE AbortCurrentMix;
VAR
    TempOrdHRec : TWOHeaderRecord;
    TempOrdLRec : TWOLineRecord;
    TempMixRec  : TMixStatusRecord;
    TRNRec      : TTranRecord;
    CostRec     : TCostRecord;
    HeadReadErr : INTEGER;
    DelCosting  : BOOLEAN;
    ReadErr,
    TrnDelErr   : INTEGER;
    CurrScaleTaskstate : TScaleTaskState;


BEGIN
 StopScaleTasks(CurrScaleTaskState);           { Save State Of Scale Tasks }
 DelCosting := FALSE;
 IF UserTotalCosting THEN
   DelCosting := YesNoWin('     Mark Ingredients As Lost'+CRLF+
                          '     On Costing Record? (Y/N)');

{Read all lines and set Containers done etc to zero}
{Needs to Mark Transactions Belonging To this mix to aborted}
(* ResetAllTasks;*)
(* NoWeighingsAllowed := FALSE;*)
(* TareNotSet         := TRUE;*)

 { open all files needed }
 OpenOrderRelatedFiles;

 IF DelCosting THEN
   CostFile^.OpenFile;

 IF GetAndLockSelHeaderAndMixRecs(TempOrdHRec,TempMixRec) = 0 THEN
  BEGIN
   TrnDelErr := 0;
   FillChar(TRNRec,SizeOf(TTranRecord),#0);
   TRNRec.TRN_OrderNo := TempOrdHRec.WOH_OrderNo;
   TRNRec.TRN_Revision:= TempOrdHRec.WOH_Revision;
   TRNRec.TRN_MixNo   := SelRecs.WorkHRecord.WOH_CurrentMix;
   ReadErr := TransFile^.ReadRecord('GE',TRUE,FALSE,TRNRec,2);
   WHILE (ReadErr = 0) AND (TrnDelErr = 0)
   AND   (TRNRec.TRN_OrderNo  = TempOrdHRec.WOH_OrderNo)
   AND   (TRNRec.TRN_Revision = TempOrdHRec.WOH_Revision)
   AND   (TRNRec.TRN_MixNo    = SelRecs.WorkHRecord.WOH_CurrentMix) DO
    BEGIN
     IF TRNRec.TRN_Status <> TRNStatusAborted THEN
      BEGIN
       AbortTranRecord(@TRNRec);
       TrnDelErr := TransFile^.UpdateRecord(TRNRec);
       IF TrnDelErr = 0 THEN
        BEGIN
         { Subtract from locked order header }
         WITH TempOrdHRec DO
          BEGIN
           WOH_WtDoneGross := WOH_WtDoneGross - TRNRec.TRN_ContainerWt;
           {WOH_CurrentMixWt:= WOH_CurrentMixWt- TRNRec.TRN_ContainerWt;}
          END;

         { Subtract from locked mix header record }
         WITH TempMixRec DO
           MIX_WtDone := MIX_WtDone - TRNRec.TRN_ContainerWt;

         { adjust order line file }
         WITH TempOrdLRec DO
          BEGIN
           WOL_OrderNo := TRNRec.TRN_OrderNo;
           WOL_Revision:= TRNRec.TRN_Revision;
           WOL_LineNo  := TRNRec.TRN_OrderLineNo;
           IF WorkLineFile^.ReadRecord('EQ',FALSE,FALSE,TempOrdLRec,0) = 0 THEN
            BEGIN
             WOL_TotalWtDone   := WOL_TotalWtDone   - TRNRec.TRN_ContainerWt;;
             Dec(WOL_TotalContDone);
             WorkLineFile^.UpdateRecord(TempOrdLRec);
            END;
          END;

         IF DelCosting THEN { adjust cost file }
          BEGIN
           CostFile^.GetCostRecord(TRNRec.TRN_Ingredient,TRNRec.TRN_LotNo,CostRec,TRUE,FALSE);
           WITH CostRec DO
             COST_Wasted := COST_Wasted + TRNRec.TRN_ContainerWt;
           CostFile^.UpdateRecord(CostRec);
          END;
        END;
      END;
     ReadErr := TransFile^.ReadRecord('GN',TRUE,FALSE,TRNRec,2);
    END;

   IF ReadErr = 0 THEN { might be one left locked }
     TransFile^.Unlock_Single;

   IF  (BtrvErrType(ReadErr) IN [berr_None, berr_NACK])
   AND (TrnDelErr = 0) THEN        { managed to delete all the trans }
     TempMixRec.MIX_WtDone := 0.0; { make sure mix wt is set to 0 }

   TempMixRec.MIX_Complete := FALSE;
   MixStatusFile^.UpdateRecord(TempMixRec);

   { update / RELEASE header }
   IF TempOrdHRec.WOH_MixDone > 0 THEN
     Dec(TempOrdHRec.WOH_MixDone);

   { could have been the last mix aborted }
   IF TempOrdHRec.WOH_Status = StatusComp THEN
     TempOrdHRec.WOH_Status := StatusWIP;
   INC(TempOrdHRec.WOH_UpdateCount);
   WorkHeaderFile^.UpdateRecord(TempOrdHRec);
   SelRecs.WorkHRecord := TempOrdHRec;
  END;
 RestoreScaleTasks(CurrScaleTaskstate);         { Restore Scale Tasks }

{ DisplayRecListpos := 0;}
{ LineNoSelected    := 1;}
{ BuildLineRecipeList(@SelRecs.WorkHRecord,FALSE);} {rebuild linked list}

 PrimeNextIngredient({NP_MixAborted} NP_MixNoChg,
                     'Mix '+IntToStr(SelRecs.WorkHRecord.WOH_CurrentMix,1)+
                     ' aborted.');
 WeighProcessController.Init; { container in process is now invalid }

 IF DelCosting THEN
   CostFile^.CloseFile;
 CloseOrderRelatedFiles;
END;


PROCEDURE AbortCurrentMixButtonHit;

VAR
(*  GetPassWin  : PGetPassWord;*)
    AbortTheMix : BOOLEAN;
    CurrScaleTaskstate : TScaleTaskState;
BEGIN
 AbortTheMix := FALSE;
 StopScaleTasks(CurrScaleTaskState);           { Save State Of Scale Tasks }
 IF YesNoWin('     Are You Sure You Wish'+CRLF+
             '   To Abort Mix '+
             IntToStr(SelRecs.WorkHRecord.WOH_CurrentMix,1)+' (Y/N)?') THEN
  BEGIN
   MessageWin.ClearMsg;                          { Clear Displayed Message  }
(*
   New(GetPassWin,Init(100,100,100+30*8,132,C_WindowStaticText SHR 4,StdWin,NIL,FALSE));
   { Mix Is Aborted Only if correct Password is Entered }
   IF GetPassWin^.UserActivateFunction(0,0) THEN { Accept Password}
    BEGIN
     AbortTheMix := TRUE;
    END
   ELSE
*)
   IF GetSystemPasswordFromUser THEN
     AbortTheMix := TRUE
   ELSE
    BEGIN
     MessageWin.DisplayMsg('Incorrect Password.',TRUE);
    END;
(*   Dispose(GetPassWin,Done);*)
  END;
 RestoreScaleTasks(CurrScaleTaskstate);         { Restore Scale Tasks }

 IF AbortTheMix THEN
  BEGIN                                         { Correct Password Entered }
   AbortCurrentMix;           { Procedure To Abort The Mix & Reset Scale Tasks}
  END;

 ScreenRedraw;
END;


PROCEDURE DelayCurrentMix;
VAR
    OrdHRec     : TWOHeaderRecord;
    HeadReadErr : INTEGER;
    MixFindErr  : TFindMixResult;
    TicketWanted : BOOLEAN;
    SaveMixNo   : LONGINT;
    CurrScaleTaskstate : TScaleTaskState;
BEGIN
 SaveMixNo := SelRecs.WorkHRecord.WOH_CurrentMix;
{Read all lines and set Containers done etc to zero}
 IF (CompareWts(SelRecs.WorkHRecord.WOH_WtDoneGross,0.0) <= 0)
 OR (NOT DoMixesExistForOrder(SelRecs.WorkHRecord.WOH_OrderNo,SelRecs.WorkHRecord.WOH_Revision)) THEN
  BEGIN
   MessageWin.ClearMsg;
   MessageWin.DisplayMsg('Unable To Delay first Mix Without Weighing To It',TRUE);
   EXIT;
  END;

 StopScaleTasks(CurrScaleTaskState);           { Save State Of Scale Tasks }
 TicketWanted := FALSE;
 IF FXDETAIL.GetNumberofMixTickets > 0 THEN
   TicketWanted := YesNoWin('  Do You Wish To Print A Ticket'+CRLF+
                            '   For The Mix Being Delayed');

(* ResetAllTasks;*)
(* NoWeighingsAllowed := FALSE;*)
(* TareNotSet         := TRUE;*)
 OpenOrderRelatedFiles;

 HeadReadErr := SelRecs.LockHeaderRecord;
 IF HeadReadErr = 0 THEN
  BEGIN
   OrdHRec := SelRecs.WorkHRecord;
   IF TicketWanted THEN
     Print_Partial_Mix_Ticket(FXDETAIL.GetNumberofMixTickets);
   MixFindErr := SetCurrMixNoToAnUnfinishedMix(OrdHRec);
   INC(OrdHRec.WOH_UpdateCount);
   WorkHeaderFile^.UpdateRecord(OrdHRec);
   SelRecs.WorkHRecord := OrdHRec;
   SelRecs.SetCurrentMixNoTo(OrdHRec.WOH_CurrentMix); { resets batch no. etc }
   DisplayMixSearchResult(MixFindErr);
  END;
{ DisplayRecListpos := 0;}
{ LineNoSelected    := 1;}

(*
 IF (MixFindErr = FM_PrevMixFound) THEN
   PrimeNextIngredient(NP_OldMix)
 ELSE
   PrimeNextIngredient(NP_NewMix);
*)
 RestoreScaleTasks(CurrScaleTaskstate);         { Restore Scale Tasks }

 IF SelRecs.WorkHRecord.WOH_CurrentMix <> SaveMixNo THEN
  BEGIN
(*   BuildLineRecipeList(@SelRecs.WorkHRecord,TRUE);  {rebuild linked list}*)
   PrimeNextIngredient(NP_MixNoChg,
                       'Mix '+ IntToStr(SaveMixNo,1)+ ' delayed.');
  END;
 CloseOrderRelatedFiles;
END;


FUNCTION ReturnToMix(MixNo : WORD) : BOOLEAN;
CONST MIX_COMPLETED  = 1;
      MIX_OUTOFRANGE = 2;

VAR OrdHRec     : TWOHeaderRecord;
    HeadReadErr : INTEGER;
    Update      : BOOLEAN;
    ErrInt      : INTEGER;
    CurrScaleTaskstate : TScaleTaskState;
BEGIN
 StopScaleTasks(CurrScaleTaskState);           { Save State Of Scale Tasks }
 ReturnToMix := FALSE;
 ErrInt := 0;

 IF ErrInt = 0 THEN
  BEGIN
   WorkHeaderFile^.OpenFile;                   { Open WO Header File        }
   HeadReadErr := SelRecs.LockHeaderRecord;

   IF HeadReadErr = 0 THEN                     { Read Lock OK?              }
    BEGIN
     OrdHRec := SelRecs.WorkHRecord;
     IF MixNo > OrdHRec.WOH_NumMixes THEN      { Mix In Range?              }
      BEGIN
       WorkHeaderFile^.Unlock_Single;          { Unlock Header Record       }
       ErrInt := MIX_OUTOFRANGE;
      END
     ELSE
      BEGIN
       OrdHRec.WOH_CurrentMix := MixNo;
       INC(OrdHRec.WOH_UpdateCount);
       WorkHeaderFile^.UpdateRecord(OrdHRec);
       SelRecs.WorkHRecord := OrdHRec;
       SelRecs.SetCurrentMixNoTo(OrdHRec.WOH_CurrentMix); { resets batch no. etc }
      END;
    END;
  END;
 WorkHeaderFile^.CloseFile;
 RestoreScaleTasks(CurrScaleTaskState);           { Save State Of Scale Tasks }

{DisplayRecListpos := 0;}
{ LineNoSelected    := 1;}
(* BuildLineRecipeList(@SelRecs.WorkHRecord,TRUE);    {rebuild linked list}*)
 PrimeNextIngredient({NP_OldMix}
                     NP_MixNoChg, 'Mix No. Changed.');
 ReturnToMix := (ErrInt = 0);
END;


{============================================================================}
{=====================Object Functions and Procedures========================}
{============================================================================}
(*
{SELECT NEXT MIX METHODS}
FUNCTION  TNextMix.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR T : INTEGER;
BEGIN
 IF YesNoWin('    Advance Mix Are You Sure? (Y/N)') THEN AdvanceMix(T);
 UserActivateFunction := FALSE;
END;

PROCEDURE TNextMix.Draw;
BEGIN
 DisplayText(1,'Next'+CRLF+'Mix');
END;
*)

(*
FUNCTION TAbortMix.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR GetPassWin  : PGetPassWord;
    AbortTheMix : BOOLEAN;
    CurrScaleTaskstate : TScaleTaskState;
BEGIN
 AbortTheMix := FALSE;
 StopScaleTasks(CurrScaleTaskState);           { Save State Of Scale Tasks }
 IF YesNoWin('     Are You Sure You Wish'+CRLF+
             '   To Abort Mix '+
             IntToStr(SelRecs.WorkHRecord.WOH_CurrentMix,1)+' (Y/N)?') THEN
  BEGIN
   MessageWin.ClearMsg;                          { Clear Displayed Message  }
   New(GetPassWin,Init(100,100,100+30*8,132,C_WindowStaticText SHR 4,StdWin,NIL,FALSE));
   { Mix Is Aborted Only if correct Password is Entered }
   IF GetPassWin^.UserActivateFunction(0,0) THEN { Accept Password}
    BEGIN
     AbortTheMix := TRUE;
    END
   ELSE
    BEGIN
     MessageWin.DisplayMsg('Incorrect Password.',TRUE);
    END;
   Dispose(GetPassWin,Done);
  END;
 IF AbortTheMix THEN
  BEGIN                                         { Correct Password Entered }
   AbortCurrentMix;           { Procedure To Abort The Mix & Reset Scale Tasks}
  END
 ELSE RestartScaleTasks(CurrScaleTaskstate);         { Restore Scale Tasks }
 ScreenRedraw;
 UserActivateFunction := FALSE;
END;
*)

(*
PROCEDURE TAbortMix.Draw;
BEGIN
 DisplayText(1,'Abort Mix');
END;
*)

END.

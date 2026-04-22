(****************************************************************************
*  UNIT          : SFXTiket                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 15/09/97                                                 *
*  PURPOSE       :                                                          *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXTiket;
INTERFACE
USES F6StdCTV,F6STDUTL,SfxStd,FXMODCTV,FXUbiPrn,FXFTrn,FXFWork,SFXConst,
     FXDetail,SFXBas,FXFIni,SFXCurr,SFXMsg,SFXScale;


PROCEDURE Print_Ticket(TranRec : PTranRecord;
                       OrdHRec : PWOHeaderRecord;
                       OrdLRec : PWOLineRecord);
PROCEDURE Print_Mix_Total_Ticket{(OrdHRec : PWOHeaderRecord;
                                  PrintAllDetails : BOOLEAN)};
PROCEDURE Print_Partial_Mix_Ticket(TicketsPerMix : INTEGER);
PROCEDURE PrintAllMixTickets{(OrdHRec : PWOHeaderRecord;
                              PrintAllDetails : BOOLEAN)};
IMPLEMENTATION


PROCEDURE Print_Ticket(TranRec : PTranRecord;
                       OrdHRec : PWOHeaderRecord;
                       OrdLRec : PWOLineRecord);
VAR
    CurrentTasks : TScaleTaskState;
BEGIN
 StopScaleTasks(CurrentTasks);
 MessageWin.DisplayMsg('Printing Ingredient Ticket',TRUE);
 CASE ScaleConfRec.PrinterType OF
  IPL_Printer    : Print_UBI_Ticket(TranRec,OrdHRec,OrdLRec);
  UBI_Printer    : Print_UBI_Ticket(TranRec,OrdHRec,OrdLRec);
  ELTRON_Printer : Print_Eltron_Ticket(TranRec,OrdHRec,OrdLRec,Space_String,
                                       FALSE,TranTicket,GetExtVar(FXEltronTICKETFILE,all),FALSE);
  ELTRON_Printer2 : Print_Eltron_Ticket(TranRec,OrdHRec,OrdLRec,Space_String,
                                       FALSE,TranTicket,GetExtVar(FXEltronTICKETFILE,all),TRUE);
 END;
 MessageWin.ClearMsg;
 RestoreScaleTasks(CurrentTasks);
END;

PROCEDURE Print_Mix_Total_Ticket{(OrdHRec : PWOHeaderRecord
                                { PrintAllDetails : BOOLEAN)};
{ MOD: PrintAllDetails parameter removed. Effectively controls whether to
       list recipe totals or mix totals on ticket.
       Was always set to TRUE if printer type <> UBI_Printer, why? we dont know }
VAR Duplicate : INTEGER;
    CurrentTasks : TScaleTaskState;
BEGIN
 Duplicate := FXDETAIL.GetNumberofMixTickets;
 WHILE (Duplicate > 0) DO
  BEGIN
   StopScaleTasks(CurrentTasks);
   MessageWin.DisplayMsg('Printing Mix Ticket',TRUE);
   CASE ScaleConfRec.PrinterType OF

    UBI_Printer,
    IPL_Printer     : Print_UBI_Mix_Total_Ticket({OrdHRec,PrintAllDetails}
                                                 @SelRecs.WorkHRecord,
                                                 SelRecs.SR_CurrentBatchNo,
                                                 FALSE);
    ELTRON_Printer  : Print_Eltron_Ticket(NIL,
                                          @SelRecs.WorkHRecord,
                                          NIL, {order line}
                                          SelRecs.SR_CurrentBatchNo,
                                          {PrintAllDetails}TRUE, { ???? }
                                          MixTicket,GetExtVar(FXEltronMIXTICKETFILE,all),FALSE);
    ELTRON_Printer2 : Print_Eltron_Ticket(NIL,
                                          @SelRecs.WorkHRecord,
                                          NIL,
                                          SelRecs.SR_CurrentBatchNo,
                                          {PrintAllDetails}TRUE, { ????}
                                          MixTicket,GetExtVar(FXEltronMIXTICKETFILE,all),TRUE);

   END;
   DEC(Duplicate);
   MessageWin.ClearMsg;
   RestoreScaleTasks(CurrentTasks);
  END;
END;

PROCEDURE Print_Partial_Mix_Ticket(TicketsPerMix : INTEGER);
{ MOD: PrintAllDetails parameter removed. Effectively controls whether to
       list recipe totals or mix totals on ticket.
       Was always set to TRUE if printer type <> UBI_Printer, why? we dont know }
VAR Duplicate : INTEGER;
    CurrentTasks : TScaleTaskState;
BEGIN
 Duplicate := TicketsPerMix;
 WHILE (Duplicate > 0) DO
  BEGIN
   StopScaleTasks(CurrentTasks);
   MessageWin.DisplayMsg('Printing Mix Ticket for Mix '+
                         IntToStr(SelRecs.WorkHRecord.WOH_CurrentMix,1),TRUE);
   CASE ScaleConfRec.PrinterType OF
    IPL_Printer    : Print_UBI_Mix_Total_Ticket({OrdHRec,PrintAllDetails}
                                                @SelRecs.WorkHRecord,
                                                SelRecs.SR_CurrentBatchNo,
                                                FALSE);

    UBI_Printer    : Print_UBI_Mix_Total_Ticket({OrdHRec,PrintAllDetails}
                                                @SelRecs.WorkHRecord,
                                                SelRecs.SR_CurrentBatchNo,
                                                FALSE);
    ELTRON_Printer : Print_Eltron_Ticket(NIL,
                                         {OrdHRec}@SelRecs.WorkHRecord,
                                         NIL,
                                         SelRecs.SR_CurrentBatchNo,
                                         {PrintAllDetails}TRUE, {????}
                                         PartialMixTicket,
                                         GetExtVar(FXEltronPartialMIXFILE,all),
                                         FALSE);

    ELTRON_Printer2 : Print_Eltron_Ticket(NIL,
                                          {OrdHRec}@SelRecs.WorkHRecord,
                                          NIL,
                                          SelRecs.SR_CurrentBatchNo,
                                          {PrintAllDetails}TRUE, {????}
                                          PartialMixTicket,
                                          GetExtVar(FXEltronPartialMIXFILE,all),
                                          TRUE);
   END;
   DEC(Duplicate);
   MessageWin.ClearMsg;
   RestoreScaleTasks(CurrentTasks);
  END
END;

PROCEDURE PrintAllMixTickets{(OrdHRec : PWOHeaderRecord;
                              PrintAllDetails : BOOLEAN)};
{ MOD: PrintAllDetails parameter removed. Effectively controls whether to
       list recipe totals or mix totals on ticket.
       Was always set to TRUE if printer type <> UBI_Printer, why? we dont know }
VAR
 SaveMixNo   : WORD;
 MixNumber   : WORD;

BEGIN
 SaveMixNo   := SelRecs.WorkHRecord.WOH_CurrentMix;
 FOR MixNumber := 1 TO SelRecs.WorkHRecord.WOH_NumMixes DO
  BEGIN
   SelRecs.SetCurrentMixNoTo(MixNumber);
   Print_Partial_Mix_Ticket(1);
  END;
 SelRecs.SetCurrentMixNoTo(SaveMixNo);
END;

END.
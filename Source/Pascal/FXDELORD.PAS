(****************************************************************************
*  UNIT          : FXDelOrd                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 17/05/96                                                 *
*  PURPOSE       : Order Deletion Routines                                  *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXDELORD;
INTERFACE
USES CRT,F6StdCtv,F6StdUtl,F6stdUt1,F6StdWin,F6DTConv,FXModCtv,FXFTrn,
     FXFTrnW,FXFMix,FXFWork,FXCfg;




PROCEDURE Delete_Complete_Orders;
FUNCTION  OKToDeleteOrder(VAR WHRec : TWOHeaderRecord;AnyOrder,DelAllComp : BOOLEAN) : BOOLEAN;
PROCEDURE Delete_Order(OrderNum : LONGINT;Revision : BYTE);
PROCEDURE OpenFile(VAR F:TEXT;OrderNum : LONGINT;Revision : BYTE);
PROCEDURE DeleteOrderAndLines(VAR OrdHRec : TWOHeaderRecord);
IMPLEMENTATION
{Order Delete must also remove all the transactions for that order}
{Order is archived to a text file in the arc directory}

FUNCTION OKToDeleteOrder(VAR WHRec  : TWOHeaderRecord;
                         AnyOrder,
                         DelAllComp : BOOLEAN) : BOOLEAN;
BEGIN
 IF DelAllComp THEN
  OKToDeleteOrder := WHRec.WOH_Status = StatusCOMP
 ELSE
  OKToDeleteOrder := (WHRec.WOH_Status = StatusComp) AND (OrderComplete(WHREc)) OR
                     (AnyOrder AND (CompareWts(WHRec.WOH_WtDoneGross,0.0) <= 0));
END;

{Deletes all transacrion for a specific order returns false if error occurs}
FUNCTION Delete_Transactions_For_Order(OrderNo : LONGINT;Revision : BYTE;VAR ArchiveFile : TEXT) : BOOLEAN;
VAR TRNRec  : TTranRecord;
    TranWarnRec : TTransWarnRecord;
    ReadErr,
    TWFErr      : INTEGER;
    AnErrorOccured : BOOLEAN;

 PROCEDURE ArchiveTransaction;
 BEGIN
  WITH TRNRec DO
   BEGIN
    Write(ArchiveFile,'.T',TRN_Ingredient,IntToZeroStr(TRN_Mid,2),IntToZeroStr(TRN_SerialNo,6));
    Write(ArchiveFile,DoubleToZeroStr(TRN_ContainerWt,9,3),TRN_BatchNo,TRN_LotNo);
    WriteLn(ArchiveFile,IntToZeroStr(TRN_ContainerNo,3),IntToZeroStr(TRN_MixNo,3));
   END;
 END;

BEGIN
 AnErrorOccured := FALSE;
 IF  (TransFile^.OpenFile = 0)
 AND (TransWarnFile^.OpenFile = 0) THEN
  BEGIN
   FillChar(TRNRec,SizeOf(TRNRec),#0);
   TRNRec.TRN_OrderNo := OrderNo;
   TRNRec.TRN_Revision:= Revision;
   TRNRec.TRN_MixNo   := 0;
   ReadErr := TransFile^.ReadRecord('GE',TRUE,FALSE,TRNRec,2);
   WHILE (ReadErr = 0) AND (TRNRec.TRN_OrderNo = OrderNo) AND
    (Revision = TRNRec.TRN_Revision) DO
    BEGIN
     {delete child recs of TRNRec}
     FillChar(TranWarnRec, SizeOf(TranWarnRec), 0);
     TranWarnRec.TRW_Mid      := TRNRec.TRN_Mid;
     TranWarnRec.TRW_SerialNo := TRNRec.TRN_SerialNo;
     TWFErr := TransWarnFile^.ReadRecord('GE',TRUE,FALSE,TranWarnRec,0);
     WHILE (TWFErr = 0)
     AND   (TranWarnRec.TRW_Mid      = TRNRec.TRN_Mid)
     AND   (TranWarnRec.TRW_SerialNo = TRNRec.TRN_SerialNo) DO
      BEGIN
       TWFErr := TransWarnFile^.DeleteRecord;
       IF TWFErr <> 0 THEN
         BREAK;
       TWFErr := TransWarnFile^.ReadRecord('GN',TRUE,FALSE,TranWarnRec,0);
      END;
     IF NOT (TWFErr IN [0,BEndOfFile]) THEN
      BEGIN
       AnErrorOccured := TRUE;
       BREAK;
      END;
     IF TransFile^.DeleteRecord <> 0 THEN
      BEGIN
       AnErrorOccured := TRUE;
       BREAK;
      END;
{     ArchiveTransaction;}
     ReadErr := TransFile^.ReadRecord('GN',TRUE,FALSE,TRNRec,2);
    END;
   TransFile^.CloseFile;
  END
 ELSE AnErrorOccured := TRUE;
 Delete_Transactions_For_Order := NOT AnErrorOccured;
END;

PROCEDURE OpenFile(VAR F:TEXT;OrderNum : LONGINT;Revision : BYTE);
BEGIN
 FileMode := READ_WRITE+DENY_ALL;
 Assign(F,Config_Rec^.CONF_APath+Date_To_DDMMYYYY(Date)+'.ARC');
 {$I-}
 Reset(F);
 {$I+}
 {IF File Does not exist then write version number to top of file}
 IF IOResult <> 0 THEN
  BEGIN
   Rewrite(F);
   WriteLn(F,'FORMIX v',VERSION_NUMBER,'. Archive File');
  END;
 Close(F);
 {$I-}
 Append(F);
 {$I+}
 IF IOResult <> 0 THEN
  BEGIN
   ReWrite(F);
  END;
 WriteLn(F,'.O',OrderNoToStr(OrderNum,Revision));
 WriteLn(F,Date);
 WriteLn(F,Time);
END;

{Deletes all lines associated with an order}
FUNCTION DeleteLinesForOrder(OrderNo : LONGINT;Revision : BYTE;VAR ArchiveFile : TEXT) : BOOLEAN;
VAR WLRec   : TWOLineRecord;
    ReadErr : INTEGER;
    LinesDel: BOOLEAN;

 FUNCTION GetBool (bTRUE : BOOLEAN) : CHAR;
 BEGIN
  IF bTRUE THEN GetBool := 'Y' ELSE GetBool := 'N';
 END;

 PROCEDURE ArchiveOrderLineRecord;
 BEGIN
  WITH WLRec DO
   BEGIN
    Write(ArchiveFile,'.L'+WOL_Ingredient,GetBool(WOL_KeyIngredient),DoubleToZeroStr(WOL_Ratio,9,3));
    WriteLn(ArchiveFile,DoubleToZeroStr(WOL_ContainerSize,9,3));
   END;
 END;

BEGIN
 LinesDel := TRUE;
 FillChar(WLRec,SizeOf(WLRec),#0);
 IF WorkLineFile^.OpenFile = 0 THEN
  BEGIN
   WLRec.WOL_OrderNo  := OrderNo;
   WLRec.WOL_Revision := Revision;
   ReadErr := WorkLineFile^.ReadRecord('GE',TRUE,FALSE,WLRec,0);
   WHILE (ReadErr = 0) AND (WLRec.WOL_Revision = Revision) AND
    (WLRec.WOL_OrderNo = OrderNo) AND LinesDel DO
    BEGIN
     IF WorkLineFile^.DeleteRecord <> 0 THEN LinesDel := FALSE
     ELSE ArchiveOrderLineRecord;
     ReadErr := WorkLineFile^.ReadRecord('GN',TRUE,FALSE,WLRec,0);
    END;
   WorkLineFile^.CloseFile;
  END
 ELSE LinesDel := FALSE;
 DeleteLinesForOrder := LinesDel;
END;

PROCEDURE DeleteMixRecordsForOrder(VAR WHRec : TWOHeaderRecord);
VAR MixStatus : TMixStatusRecord;
BEGIN
 IF MixStatusFile^.OpenFile = 0 THEN
  BEGIN
   WorkHeaderToMixStatus(WHRec,MixStatus);
   MixStatus.Mix_No := 1;
   MixStatusFile^.ReadRecord('EQ',TRUE,FALSE,MixStatus,0);
   WHILE (MixStatusFile^.BtrvErr = 0) AND (MixStatus.MIX_OrderNo = WHRec.WOH_OrderNo) AND
    (MixStatus.MIX_Revision = WHRec.WOH_Revision) DO
     BEGIN
      MixStatusFile^.DeleteRecord;
      MixStatusFile^.ReadRecord('GN',TRUE,FALSE,MixStatus,0);
     END;
   MixStatusFile^.Unlock_Single;
   MixStatusFile^.CloseFile;
  END;
END;


PROCEDURE ArchiveOrderHeader(VAR WHRec : TWOHeaderRecord;VAR ArchiveFile : TEXT);
BEGIN
 WITH WHRec DO
  BEGIN
   Write(ArchiveFile,'.H'+WOH_RecipeNo,Days_To_Date(WOH_SchDate));
   Write(ArchiveFile,DoubleToZeroStr(WOH_FinishWtReqd,9,3),
                     DoubleToZeroStr(WOH_TotIngredWtReqd,9,3),
                     DoubleToZeroStr(WOH_MaxMixGrossWt,9,3));
   WriteLn(ArchiveFile,DoubleToZeroStr(WOH_WtDoneGross,9,3),
                       DoubleToZeroStr(0{WOH_WtDoneNet},9,3));
  END;
END;

{Delete Record ORDHREC AND all Lines And Transaction Records}
{OrdHRec Must Have Alreaady Have Been Locked}
{Note Does Not Check That It Is OK To Delete The Order}
PROCEDURE DeleteOrderAndLines(VAR OrdHRec : TWOHeaderRecord);
VAR WHRec : TWOHeaderRecord;
    ArchiveFile : TEXT;
    OldFileMode : BYTE;
BEGIN
 OldFileMode := FileMode;
 OpenFile(ArchiveFile,OrdHRec.WOH_OrderNo,OrdHRec.WOH_Revision);
 IF Delete_Transactions_For_Order(OrdHREc.WOH_OrderNo,OrdHRec.WOH_Revision,ArchiveFile) THEN
  BEGIN
   DeleteLinesForOrder(OrdHRec.WOH_OrderNo,OrdHRec.WOH_Revision,ArchiveFile);
   IF WorkHeaderFile^.DeleteRecord = 0 THEN ArchiveOrderHeader(WHRec,ArchiveFile);
  END;
 Close(ArchiveFile);
 FileMode := OldFileMode;
END;


PROCEDURE Delete_Order(OrderNum : LONGINT;Revision : BYTE);
VAR WHRec : TWOHeaderRecord;
    ArchiveFile : TEXT;
    OldFileMode : BYTE;
BEGIN
 OldFileMode := FileMode;
 IF WorkHeaderFile^.OpenFile = 0 THEN
  BEGIN
   FillChar(WHREc,SizeOf(WHREc),#0);
   WHRec.WOH_OrderNo := OrderNum;
   WHRec.WOH_Revision := Revision;
   IF WorkHeaderFile^.ReadRecord('EQ',TRUE,FALSE,WHRec,1) = 0 THEN
    BEGIN
     OpenFile(ArchiveFile,OrderNum,Revision);
     IF Delete_Transactions_For_Order(OrderNum,Revision,ArchiveFile) THEN
      BEGIN
       DeleteMixRecordsForOrder(WHRec);
       DeleteLinesForOrder(OrderNum,Revision,ArchiveFile);
       IF WorkHeaderFile^.DeleteRecord = 0 THEN ArchiveOrderHeader(WHRec,ArchiveFile);
      END;
     Close(ArchiveFile);
    END;
   WorkHeaderFile^.CloseFile;
  END;
 FileMode := OldFileMode;
END;


{Procedure to delete all compete orders}
PROCEDURE Delete_Complete_Orders;
VAR WHRec : TWOHeaderRecord;
    ArchiveFile : TEXT;
    ReadErr     : INTEGER;
    OldFileMode : BYTE;
    DelWin      : WindowRecord;
    I           : LONGINT;
    AtX         : INTEGER;
    ToDate      : LONGINT;
    AllComplete : BOOLEAN;
    EditPos     : INTEGER;
    NB,LF,HF,RB,RF : BYTE;
BEGIN
 Save_Colours(NB,LF,HF,RB,RF);
 Set_Colours(Red,White,Yellow,LightGray,Red);
 SetWindow(20,07,60,18,TRUE,Red*16+White,Red*16+White,DelWin);
 Header('Clear Order File',1);
 WriteAt(2,3,' This option clears completed');
 WriteAt(2,4,' orders upto the specified date.');
 WriteAt(2,5,'');
 WriteAt(2,7,' Delete To Date         ');
 WriteAt(2,8,' Completed = Status COMP');
 Footer('ESC - EXIT   F2 - Cleardown',1);
 ToDate := Date_to_Days(Date) - 90;
 AllComplete := FALSE;
 EditPos := 0;
 REPEAT
  WriteAt(27,7,'['+Days_To_Date(ToDate)+']');
  IF AllComplete THEN WriteAt(27,8,'['+TICK_CHAR+']') ELSE WriteAt(27,8,'[ ]');
  CASE EditPos OF
   0 : GetDate(ToDate,27,7);
   1 : GetBoolean(AllComplete,27,8,TickBox);
  END;
  IF (Ch1=NEXT) OR (Ch1 = PREV) THEN EDitPos := 1 - EditPos;
 UNTIL (ch1 = ESC) OR (ch1 = FN_F2);
 LoseWindow(DelWin);
 Set_Colours(NB,LF,HF,RB,RF);
 IF Ch1 = ESC THEN EXIT;
 CursorOff;
 SetWindow(22,7,56,11,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,DelWin);
 WriteAt(2,2,'Deleting Complete Orders');
 I:=0;
 AtX := WhereX;
 OldFileMode := FileMode;
 IF WorkHeaderFile^.OpenFile = 0 THEN
  BEGIN
   FillChar(WHRec,SizeOf(WHRec),#0);
   ReadErr := WorkHeaderFile^.ReadRecord('GF',TRUE,FALSE,WHRec,0);
   WHILE (ReadErr = 0) AND (WHRec.WOH_SchDate <= ToDate) DO
    BEGIN
     INC(I);
     WriteAt(AtX,2,IntToZeroStr(I,6));
     IF OKToDeleteOrder(WHRec,FALSE,AllComplete) THEN
      BEGIN
       OpenFile(ArchiveFile,WHRec.WOH_OrderNo,WHRec.WOH_Revision);
       IF Delete_Transactions_For_Order(WHRec.WOH_OrderNo,WHRec.WOH_Revision,ArchiveFile) THEN
        BEGIN
         DeleteMixRecordsForOrder(WHRec);
         DeleteLinesForOrder(WHRec.WOH_OrderNo,WHRec.WOH_Revision,ArchiveFile);
         IF WorkHeaderFile^.DeleteRecord = 0 THEN ArchiveOrderHeader(WHRec,ArchiveFile);
        END
       ELSE WorkHeaderFile^.Unlock_Single;
       Close(ArchiveFile);
      END
     ELSE WorkHeaderFile^.Unlock_Single;
     ReadErr := WorkHeaderFile^.ReadRecord('GT',TRUE,FALSE,WHRec,0);
    END;
   WorkHeaderFile^.CloseFile;
  END;
 ClrScr;
 HighWriteAt(2,1,'           Complete');
 WriteAt(2,2,'    Press Any Key To Continue');
 GetKey;
 FileMode := OldFileMode;
 LoseWindow(DelWin);
 CursorOn;
END;




END.

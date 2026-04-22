(****************************************************************************
*  UNIT          : FXDelPrd                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 17/05/96                                                 *
*  PURPOSE       : Order Deletion Routines                                  *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXDelPrd;
INTERFACE
USES CRT,F6StdCtv,F6StdUtl,F6stdUt1,F6StdWin,F6DTConv,FXModCtv,FXFTrn,FXFWork,
     FXCfg,FXDelOrd,FXFProd,F6StdWn1;


PROCEDURE Delete_Product(OrdNo,OrdDate : LONGINT);

IMPLEMENTATION

TYPE
     POrderList = ^TOrderList;
     TOrderList = PACKED RECORD
      RecPos   : LONGINT;
      Revision : BYTE;
      Next     : POrderList;
     END;


PROCEDURE Delete_Product(OrdNo,OrdDate : LONGINT);
VAR WHRec      : TWOHeaderRecord;
    PORec      : TProdOrderRecord;
    PLRec      : TProdLineRecord;
    ListHeader : POrderList;

 PROCEDURE OpenFiles;
 BEGIN
  WorkHeaderFile^.OpenFile;
  WorkLineFile^.OpenFile;
  ProdOrderFile^.OpenFile;
  ProdLineFile^.OpenFile;
 END;

 PROCEDURE CloseFiles;
 BEGIN
  ProdLineFile^.CloseFile;
  ProdOrderFile^.CloseFile;
  WorkLineFile^.CloseFile;
  WorkHeaderFile^.CloseFile;
 END;

 PROCEDURE DisposeList;
 VAR Loop,Del : POrderList;
 BEGIN
  Loop := ListHeader;
  WHILE (Loop <> NIL) DO
   BEGIN
    Del  := Loop;
    Loop := Loop^.Next;
    Dispose(del);
   END;
  ListHeader := NIL;
 END;

 FUNCTION ReadAndLockOrderHeaders : BOOLEAN;
 VAR
     ReadHErr  : INTEGER;
     ReadPErr  : INTEGER;

  PROCEDURE AddItemToList;
  VAR
      NewItem : POrderList;
  BEGIN
   New(NewItem);
   NewItem^.RecPos   := WorkHeaderFile^.Position;
   NewItem^.Next     := ListHeader;
   NewItem^.Revision := WHRec.WOH_Revision;
   ListHeader := NewItem;
  END;

 {Needs To Check That WHRec.WOH_RecipeNo = PLRec.PL_RecipeNo}
 BEGIN
  ReadAndLockOrderHeaders := FALSE;
  ListHeader := NIL;
  FillChar(WHRec,SizeOf(WHRec),#0);
  FillChar(PLRec,SizeOf(PLRec),#0);
  WHRec.WOH_OrderNo := PORec.PO_OrderNo;
  WHREc.WOH_Revision:= 0;
  PLRec.PL_ProductCode := PORec.PO_ProductCode;
  PLRec.PL_LineNo      := 0;
  ReadHErr := WorkHeaderFile^.ReadRecord('GE',TRUE,TRUE,WHRec,1);
  ReadPErr := ProdLineFile^.ReadRecord('GE',FALSE,FALSE,PLRec,0);
  WHILE (ReadHErr = 0) AND (WHRec.WOH_OrderNo = PORec.PO_OrderNo) DO
   BEGIN
    IF (PLRec.PL_ProductCode <> PORec.PO_ProductCode) THEN
     BEGIN
      {No More Recipe Lines}
      ReadAndLockOrderHeaders := TRUE;
      EXIT;
     END;
    {Make Sure The Same Order As Points To On the product}
    {Check To See If An Order Has Already Been Deleted From The Schedule}
    IF (WHRec.WOH_Revision > (PLRec.PL_LineNo-1)) THEN
     BEGIN
      REPEAT
       ReadPErr := ProdLineFile^.ReadRecord('GN',FALSE,FALSE,PLRec,0);
      UNTIL (ReadPErr <> 0) OR (WHRec.WOH_Revision = (PLRec.PL_LineNo-1));
      IF ReadPErr <> 0 THEN EXIT;
     END;
    {Check To See That We Have The Correct Work Order No}
    IF (PLRec.PL_RecipeNo = WHRec.WOH_RecipeNo) THEN
     BEGIN
      IF OkToDeleteOrder(WHRec,TRUE,FALSE) THEN
       BEGIN
        IF NOT OkToDeleteOrder(WHRec,FALSE,FALSE) THEN
        IF NOT YesNoWin('   Order '+OrderNoToStr(WHRec.WOH_OrderNo,WHRec.WOH_Revision)+' Not Complete'+CRLF+
                        '       Delete Anyway Y/N') THEN EXIT;
        AddItemToList;
       END
      ELSE EXIT;
     END
    ELSE
     {Orders Do Not Match Product So Just Delete Product}
     BEGIN
      {Delete Any Elements Stored In The List}
      DisposeList;
      ReadAndLockOrderHeaders := TRUE;
      EXIT;
     END;
    ReadHErr := WorkHeaderFile^.ReadRecord('GN',TRUE,TRUE,WHRec,1);
    ReadPErr := ProdLineFile^.ReadRecord('GN',FALSE,FALSE,PLRec,0);
   END;
  IF (ReadHErr = 0) OR (ReadHErr = BNoRecord) OR (ReadHErr = 9) THEN
   ReadAndLockOrderHeaders := TRUE
  ELSE
   ReadAndLockOrderHeaders := FALSE;
 END;

 FUNCTION DeleteOrderHeadersAndLines : BOOLEAN;
 VAR Loop : PORderList;
 BEGIN
  DeleteOrderHeadersAndLines := FALSE;
  Loop := ListHeader;
  WHILE (Loop <> NIL) DO
   BEGIN
    IF WorkHeaderFile^.GetRecordDirect(Loop^.RecPos,TRUE,TRUE,WHRec,1) = 0 THEN
     BEGIN
      {Needs To Delete Transactions As well}
      {All Done By DeleteORderAndLines}
      DeleteOrderAndLines(WHREc);
     END
    ELSE EXIT;
    Loop := Loop^.Next;
   END;
  DeleteOrderHeadersAndLines := TRUE;
 END;


BEGIN
{Needs to read and lock each order header for the recipe and then check to
 see if the order header is either complete or has zero requirement.
 If complete can delete anyway. If Zero requirement then should prompt
 uses on whether to delete.
 If all orders are complete or user confirms deletion then delete the
 order, all the order lines, and the product order record}
 OpenFiles;
 PORec.PO_OrderNo  := OrdNo;
 PORec.PO_Date     := OrdDate;
 IF ProdOrderFile^.ReadRecord('EQ',TRUE,FALSE,PORec,0) = 0 THEN
  BEGIN
   IF ReadAndLockOrderHeaders THEN
    BEGIN
     IF DeleteOrderHeadersAndLines THEN
      BEGIN
       ProdOrderFile^.DeleteRecord;
      END
     ELSE
      Disp_Error_Msg('Error Deleting Order Records');
    END
   ELSE Disp_Error_Msg('Product Can Not Be Deleted. Orders Still Active');
  END
 ELSE Disp_Error_Msg('Unable To Read Product Record');
 DisposeList;
 CloseFiles;
END;


END.
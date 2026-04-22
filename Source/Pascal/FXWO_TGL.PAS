(****************************************************************************
*  UNIT          : FXWO_TGL                                                 *
*  AUTHOR        : N.S.                                                     *
*  DATE          : 09/05/96                                                 *
*  PURPOSE       : Formix Recipe Order Toggle List                          *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXWO_TGL;
INTERFACE

TYPE
    PWOToggleItem = ^TWOToggleItem;
    TWOToggleItem = PACKED RECORD
      OrderNo   : LONGINT;
      Revision  : BYTE;
      Next      : PWOToggleItem;
    END;



FUNCTION  IsOrderToggled(OrderNo : LONGINT;Revision : BYTE) : BOOLEAN;
PROCEDURE AddItemToOrderToggleList(OrderNo : LONGINT;Revision : BYTE);
PROCEDURE ClearOrderToggleList;

VAR WOToggleListHeader : PWOToggleItem;

IMPLEMENTATION

PROCEDURE ClearOrderToggleList;
VAR Loop,Del : PWOToggleItem;
BEGIN
 Loop := WOToggleListHeader;
 WHILE (Loop <> NIL) DO
  BEGIN
   Del  := Loop;
   Loop := Loop^.Next;
   Dispose(Del);
  END;
 WOToggleListHeader := NIL;
END;

FUNCTION IsOrderToggled(OrderNo : LONGINT;Revision : BYTE) : BOOLEAN;
VAR Loop : PWOToggleItem;
BEGIN
 IsOrderToggled := FALSE;
 Loop := WOToggleListHeader;
 WHILE (Loop <> NIL) DO
  BEGIN
   IF (Loop^.OrderNo = OrderNo) AND (Loop^.Revision = Revision) THEN
    BEGIN
     IsOrderToggled := TRUE;
     EXIT;
    END;
   IF (Loop^.OrderNo > OrderNo) OR
    ((Loop^.OrderNo = OrderNo) AND (Loop^.Revision > Revision)) THEN EXIT;
   Loop := Loop^.Next;
  END;
END;

PROCEDURE AddItemToOrderToggleList(OrderNo : LONGINT;Revision : BYTE);
VAR loop,last : PWOToggleItem;
    NewItem   : PWOToggleItem;

  PROCEDURE NewListItem(VAR NewItem : PWOToggleItem);
  BEGIN
   New(NewItem);
   NewItem^.OrderNo  := OrderNo;
   NewITem^.Revision := Revision;
   NEwITem^.Next     := NIL;
  END;

  PROCEDURE AddToFront;
  BEGIN
   NewListItem(NewItem);
   NewItem^.Next := WOToggleListHeader;
   WOToggleListHeader := NewItem;
  END;

  PROCEDURE AddAfter(pThis : PWOToggleItem);
  BEGIN
   NewListItem(NewItem);
   NewItem^.Next := pThis^.Next;
   pThis^.Next := NewItem;
  END;


BEGIN
 IF WOToggleListHeader = NIL THEN
  AddToFront
 ELSE
  BEGIN
   Loop := WOToggleListHeader;
   Last := NIL;
   WHILE (Loop <> NIL) DO
    BEGIN
     IF Loop^.OrderNo > OrderNo THEN
      BEGIN
       IF Last = NIL THEN AddToFront
       ELSE AddAfter(Last);
       EXIT;
      END;
     IF (Loop^.OrderNo = OrderNo) AND (Loop^.Revision > Revision) THEN
      BEGIN
       IF Last = NIL THEN AddToFront
       ELSE AddAfter(Last);
       EXIT;
      END;
     IF (Loop^.OrderNo = OrderNo) AND (Loop^.Revision = Revision) THEN
      BEGIN
       IF Last = NIL THEN
        WOToggleListHeader := WOToggleListHeader^.Next
       ELSE
        Last^.Next := Loop^.Next;
       Dispose(Loop);
       EXIT;
      END;
     Last := Loop;
     Loop := Loop^.Next;
    END;
   AddAfter(Last);
  END;
END;


BEGIN
 WOToggleListHeader := NIL;
END.
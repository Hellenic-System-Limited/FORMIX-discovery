{$O+,F+}
{$I F6COMP}
UNIT SFXList;
INTERFACE
USES SFXBtn,FXStdUt1,F6StdCtv,SFXGraph,SFXUtils,SFXFont,F6StdUtl;

CONST
     Box_Sort   = 128;
     Box_Select = 64;


TYPE
      TWinType = (WinUp,WinDown,WinScroll);

      PCallBackWin = ^TCallBackWin;
      TCallBackWin = OBJECT(TSFWindow)
       TheWinType : TWinType;
       OldY       : INTEGER;
       DragBar    : BOOLEAN;
       Count      : INTEGER;
       Constructor Init(X1,Y1,X2,Y2 : INTEGER;ThisWinType : TWinType;Parent : PSFWindow);
       DESTRUCTOR  Done;VIRTUAL;
       PROCEDURE SendMsg(hWindow : PSFWindow;Msg : INTEGER);
       PROCEDURE WhileButtonDown(X,Y : INTEGER);VIRTUAL;
       FUNCTION  UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
       FUNCTION  IsPointInWindow(X,Y : INTEGER):BOOLEAN; VIRTUAL;
       PROCEDURE Draw;Virtual;
       PROCEDURE DrawScrollBar(AtY : INTEGER);
       FUNCTION GetTypeName : STRING;VIRTUAL;
      END;

      PListItem = ^TlistItem;
      TListItem =OBJECT
       ListStr : STRING[80];
       Next    : PListItem;

       CONSTRUCTOR Init(StrToDisp : STRING);
       DESTRUCTOR  Done;Virtual;
       FUNCTION GetStringToDisplay : STRING;VIRTUAL;
      END;

      PListBox = ^TListBox;
      TListBox = OBJECT(TParentWindow)
       ListHead      : PListItem;
       ListPos       : LONGINT;
       TopDispItem   : PListItem;
       ListSize      : INTEGER;
       BoxUp,BoxDown : PCallBackWin;
       ScrollBar     : PCallBackWin;
       StringWidth   : INTEGER;
       FoundItem     : BOOLEAN;
       ItemSelected  : STRING[40];
       ScaleY        : INTEGER;
       ListType      : BYTE;
       NumWinLines   : INTEGER;
       ExitListBox   : BOOLEAN;
       pEXITLoop     : PSwitchWindow;

       CONSTRUCTOR Init(MaxStringWidth : INTEGER;BoxType : BYTE);
       DESTRUCTOR  Done; VIRTUAL;
       PROCEDURE   AddItem (NewItem : PListItem);
       PROCEDURE   DisplayListAtItem(Item : INTEGER);
       PROCEDURE   ScrollListUp;
       PROCEDURE   ScrollListDown;
       FUNCTION    GetTopItemNum : INTEGER;
       PROCEDURE   Draw;VIRTUAL;
       PROCEDURE   BorderDraw;VIRTUAL;
       PROCEDURE   ReceiveMsg(Msg : INTEGER);VIRTUAL;
       PROCEDURE   WaitForAccept;
       FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
       FUNCTION    GetListEntry(ListNo : INTEGER) : PListItem;
       FUNCTION    GetTypeName : STRING;VIRTUAL;
      END;

PROCEDURE AddItemToListBox(S:STRING;ListBox : PListBox);

IMPLEMENTATION
USES SFXCOLR;


Constructor TCallBackWin.Init(X1,Y1,X2,Y2 : INTEGER;ThisWinType : TWinType;Parent : PSFWindow);
BEGIN
 TheWinType := ThisWinType;
 OldY       := -1;
 DragBAr    := FALSE;
 INHERITED Init(X1,Y1,X2,Y2,C_WindowStaticText SHR 4,StdEdit,Parent,FALSE);
 AddToLinkList(hParent^.ChildWindows);
 Count := 0;
END;

DESTRUCTOR TCallBackWin.Done;
BEGIN
 INHERITED Done;
END;

FUNCTION TCallBackWin.IsPointInWindow(X,Y : INTEGER):BOOLEAN;
BEGIN
 WITH Bounds DO
 IsPointInWindow := (X>=Left) AND (X<=Right) AND
                    (Y>=Top)  AND (Y<=Bottom);

END;

PROCEDURE TCallBackWin.DrawScrollBar(AtY : INTEGER);
VAR I : INTEGER;
BEGIN
 IF (OldY = AtY) THEN EXIT;
 IF TheWinType <> WinScroll THEN EXIT;
 IF OldY <> -1 THEN
  BEGIN
   WITH Bounds DO
   DeleteWindow(Left+2,Top+OldY,Right-1,Top+OldY+34);
   SetLineStyle(5);
   FOR I := OldY-2 TO OldY+34 DO
    DrawLineHoriz(Bounds.Left,Bounds.Right,I+Bounds.Top,1);
   SetLineStyle(0);
  END;
  OldY := AtY;
 WITH Bounds DO
  BEGIN
   DeleteWindow(Left+2,Top+AtY,Right-1,Top+AtY+32);
   DrawWindow(Left,Top+AtY,Right,Top+AtY+32,FALSE);
  END;
END;

FUNCTION TCallBackWin.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TCALLBACKWIN';
END;

PROCEDURE TCallBackWin.SendMsg(hWindow : PSFWindow;Msg : INTEGER);
BEGIN
 hWindow^.ReceiveMsg(Msg);
END;

PROCEDURE TCallBackWin.WhileButtonDown(X,Y : INTEGER);
BEGIN
 IF (NOT IsPointInWindow(X,Y)) THEN EXIT;
 IF (Count <> 0) AND (NOT DragBar) THEN
  BEGIN
   Count := (Count+1) MOD 2000;
   EXIT;
  END
 ELSE Inc(Count);
 CASE TheWinType OF
  WinUp : SendMsg(hParent,999);
  WinDown : SendMsg(hParent,1);
  WinScroll : BEGIN
   IF DragBar THEN
    BEGIN
     IF (Y<Bounds.Bottom-33) THEN
      BEGIN
{       DrawScrollBar(Y-Bounds.Top);}
       SendMsg(hParent,(Y-Bounds.Top) OR $4000);
      END;
    END
   ELSE
    BEGIN
     IF ((Y-Bounds.Top) < OldY) THEN SendMsg(hParent,998)
     ELSE IF ((Y-Bounds.Top) > (OldY+32)) THEN SendMsg(hParent,4)
     ELSE DragBar := TRUE;
    END;
  END;
 END;
END;

FUNCTION  TCallBackWin.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 UserActivateFunction := FALSE;

 CASE TheWinType OF
  WinUp : SendMsg(hParent,999);
  WinDown : SendMsg(hParent,1);
  WinScroll : BEGIN
   IF DragBar THEN
    BEGIN
     SendMsg(hParent,OldY OR $4000);
     DragBar := FALSE;
    END
   ELSE
    BEGIN
     IF ((Y-Bounds.Top) < OldY) THEN SendMsg(hParent,998)
     ELSE IF ((Y-Bounds.Top) > (OldY+32)) THEN SendMsg(hParent,4);
    END
  END;
 END;
 Count := 0;
END;

PROCEDURE TCallBackWin.Draw;
VAR I : INTEGER;
BEGIN
 CASE TheWinType OF
  WinUp : WITH Bounds DO
           DrawArrow(ArrowUp,Left,Top,Right,Bottom);
  WinDown : WITH Bounds DO
             DrawArrow(ArrowDown,Left,Top,Right,Bottom);
  WinScroll :WITH Bounds DO
              BEGIN
               SetLineStyle(5);
               FOR I := Top TO Bottom DO
                BEGIN
                 DrawLineHoriz(Left,Right,I,1);
                END;
               SetLineStyle(0);
               DrawScrollBar(2);
              END;
 END;
END;
{================= List Item Stuff =======================}
CONSTRUCTOR TListItem.Init(StrToDisp : STRING);
BEGIN
 ListStr := StrToDisp+SPACE_STRING;
 Next    := NIL;
END;

FUNCTION TListItem.GetStringToDisplay : STRING;
BEGIN
 GetStringToDisplay := ListStr;
END;

DESTRUCTOR TListItem.Done;
BEGIN
END;
{LIST BOXES}
CONSTRUCTOR TListBox.Init(MaxStringWidth : INTEGER;BoxType : BYTE);
VAR WinWidth : INTEGER;
BEGIN
 ListHead    := NIl;
 ListPos     := 0;
 TopDispItem := NIL;
 ListSize    := 0;
 StringWidth := MaxStringWidth;
 FoundItem   := FALSE;
 ItemSelected:= SPACE_STRING;
 ScaleY      := DoubleHeightFont^.BitMapHeight DIV 8;;
 NumWinLines := 0;
 ListType    := BoxType;

 WinWidth := MaxStringWidth*8;
 INHERITED Init(10,10,52+WinWidth,404,C_WindowStaticText SHR 4,WT_Border OR WT_Visable);
 ChangeWindowFont(DoubleHeightFont);
 New(BoxUp,Init(Bounds.Right-32,Bounds.Top,Bounds.Right,Bounds.Top+32,WinUp,@Self));
 New(BoxDown,Init(Bounds.Right-32,Bounds.Bottom-32,Bounds.Right,Bounds.Bottom,WinDown,@Self));
 New(ScrollBar,Init(Bounds.Right-32,Bounds.Top+32,Bounds.Right,Bounds.Bottom-32,WinScroll,@Self));
 NumWinLines := ((Bounds.Bottom - Bounds.Top) DIV (ScaleY*8))-1;
 New(pEXITLoop,Init(10,404,52+WinWidth,404+ChildHeight,WT_Border OR WT_Visable,
                    Centered('EXIT',(WinWidth+42) DIV 8),@Self.ExitListBox));
END;

DESTRUCTOR TListBox.Done;
VAR Loop,Last : PListItem;
BEGIN
 Loop := ListHead;
 WHILE (Loop <> NIL) DO
  BEGIN
   Last := Loop;
   Loop := Loop^.Next;
   Dispose(Last,Done);
  END;
 ListHead := NIL;
 TopDispItem := NIL;
 Dispose(pExitLoop,Done);
 INHERITED Done;
END;

PROCEDURE TListBox.AddItem (NewItem : PListItem);
VAR S1,S2  : STRING[40];
   Loop,Last : PListItem;
BEGIN
 INC(ListSize);
 IF ((ListType AND Box_Sort) <> 0) THEN
  BEGIN
   S1 := NewItem^.GetStringToDisplay;
   IF ListHead = NIL THEN
    BEGIN
     ListHead := NewItem;
     EXIT;
    END;
   Loop := ListHead;Last := NIL;
   WHILE (Loop <> NIL) DO
    BEGIN
     S2 := Loop^.GetStringToDisplay;
     IF S2>S1 THEN
      BEGIN
       IF Last = NIL THEN
        BEGIN
         NewItem^.Next := ListHead;
         ListHead      := NewItem;
         EXIT;
        END
       ELSE
        BEGIN
         Last^.Next    := NewItem;
         NewItem^.Next := Loop;
         EXIT;
        END;
      END;
     Last := Loop;
    Loop := Loop^.Next;
    END;
   Last^.Next := NewItem;
  END
 ELSE { Not Sorted Box Add To End}
  BEGIN
   IF (ListHead = NIL) THEN
    BEGIN
     ListHead := NewItem;
     EXIT;
    END;
   Loop := ListHead;
   WHILE (Loop^.Next <> NIL) DO Loop := Loop^.Next;
   Loop^.Next := NewItem;
  END;
END;

PROCEDURE TListBox.BorderDraw;
BEGIN
 Dec(Bounds.Right,32);
 WriteHeader('Mix Details');
 Inc(Bounds.Right,32);
 INHERITED BorderDraw;
END;

PROCEDURE TListBox.Draw;
VAR Loop    : PListItem;
    I       : INTEGER;
    SaveCol : Byte;
BEGIN
 IF (TopDispItem = NIL) THEN TopDispItem := ListHead;
 Loop := TopDispItem;
 SaveCol := SetTextColour(C_WindowText);
 FOR I:=1 TO NumWinLines DO
  BEGIN
   IF Loop<>NIL THEN
    BEGIN
     DisplayText(I*ScaleY-1,Copy(Loop^.GetStringToDisplay,1,StringWidth));
     Loop := Loop^.Next;
    END
   ELSE
    DisplayText(I*ScaleY-1,COPY(SPACE_STRING,1,StringWidth));
  END;
 SetTextColour(SaveCol);
END;

FUNCTION  TListBox.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TLISTBOX';
END;

FUNCTION TListBox.GetListEntry(ListNo : INTEGER) : PListItem;
VAR Loop : PListItem;
BEGIN
 Loop := ListHead;
 WHILE (ListNo>0) AND (Loop<>NIL) DO
  BEGIN
   Dec(ListNo);
   Loop := Loop^.Next;
  END;
 GetListEntry := Loop;
END;


FUNCTION TListBox.GetTopItemNum : INTEGER;
VAR Loop : PListItem;
    I : INTEGER;
BEGIN
 I := 0;
 IF TopDispItem <> NIL THEN
  BEGIN
   Loop := ListHead;
   WHILE (Loop<>NIL) AND (Loop<>TopDispItem) DO
    BEGIN
     Loop := Loop^.Next;
     INC(I);
    END;
   IF Loop = NIL THEN I:=0;
  END;
 GetTopItemNum := I;
END;

PROCEDURE TListBox.DisplayListAtItem(Item : INTEGER);
VAR Loop : PListItem;
    Pos  : INTEGER;
BEGIN
 Pos := Bounds.Bottom-Bounds.Top-64-37;   {Height Of ScrollBar}
 Pos := (Pos*Item) DIV ((ListSize-NumWinLines));
 ScrollBar^.DrawScrollBar(Pos+2);

 Loop := ListHead;
 WHILE (Item>0) AND (Loop<>NIL) DO
  BEGIN
   Dec(Item);
   Loop := Loop^.Next;
  END;
 TopDispItem := Loop;
 Draw;{Paint;}
END;

PROCEDURE TListBox.ScrollListUp;
VAR I : INTEGER;
BEGIN
 I := GetTopItemNum;
 IF I<>0 THEN Dec(I);
 IF (ListSize>24) AND (I>ListSize-24) THEN I:=ListSize-24;
 DisplayListAtItem(I);
END;

PROCEDURE TListBox.WaitForAccept;
BEGIN
 ExitListBox := FALSE;
 REPEAT
  Wait_For_User_Input;
 UNTIL FoundItem OR ExitListBox;
END;

FUNCTION TListBox.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR YHit : INTEGER;
    ListItem : PListItem;
BEGIN
 UserActivateFunction := FALSE;
 IF ((Box_Select AND BOX_Select) = 0) THEN EXIT;
 IF ActivateIfInAChildWindow(X,Y) THEN EXIT;
 YHit := (Y-Bounds.Top-24);
 IF (YHit > 0) THEN
  BEGIN
   YHit := YHit DIV (ScaleY*8);
   ListItem := GetListEntry(GetTopItemNum+YHit);
   IF (ListItem <> NIL) THEN
    BEGIN
     FoundItem := TRUE;
     ItemSelected := COPY(ListItem^.GetStringToDisplay,1,StringWidth);
    END;
  END;
END;

PROCEDURE TListBox.ScrollListDown;
VAR I : INTEGER;
BEGIN
 I := GetTopItemNum;
 INC(I);
 IF (ListSize>24) AND (I>ListSize-24) THEN I:=ListSize-24;
 DisplayListAtItem(I);
END;

PROCEDURE TListBox.ReceiveMsg(Msg : INTEGER);
VAR NewPos : INTEGER;
BEGIN
 IF ((Msg AND $4000) <> 0) THEN
  BEGIN
   NewPos := Bounds.Bottom-Bounds.Top-64-37;   {Height Of ScrollBar}
   NewPos := NewPos DIV ((ListSize-NumWinLines));
   NewPos := (Msg AND $0FFF) DIV NewPos;
   DisplayListAtItem(NewPos);
  END
 ELSE
  BEGIN
   IF Msg = 999 THEN Msg := -1
   ELSE IF Msg = 998 THEN Msg := -4;
   NewPos := GetTopItemNum+Msg;
   IF (NewPos < (ListSize-NumWinLines+1)) AND (NewPos >-1) THEN
    DisplayListAtItem(NewPos);
  END;
END;

PROCEDURE AddItemToListBox(S:STRING;ListBox : PListBox);
VAR NewItem : PListItem;
BEGIN
 New(NewItem,Init(S));
 ListBox^.AddItem(NewItem);
END;


END.
(****************************************************************************
*  UNIT          : SFXBtn                                                   *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Button Object                               *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXBtn;
INTERFACE
USES F6STDUTL,SFXGraph,SFXBMAP,SFX_Pro;

{Window Types
  F E D C B A 9 8 7 6 5 4 3 2 1 0
 ---------------------------------
 | | | | | | | | | | | | | | | | |
 ---------------------------------
  | | | | | | | | | | | | | | | |
  | | | | | | | | | | | | | | | --- Border
  | | | | | | | | | | | | | | ----- Btn
  | | | | | | | | | | | | | ------- Shadowed Window    //Needs Border
  | | | | | | | | | | | | --------- Always Active
  | | | | | | | | | | | ----------- Non Selectable
  | | | | | | | | | | ------------- AutoDisabled
  | | | | | | | | | --------------- Disabled
  | | | | | | | | ----------------- Visable
  | | | | | | | ------------------- Texture Centred
  | | | | | | --------------------- Non Deletable
  | | | | | -----------------------
  | | | | -------------------------
  | | | ---------------------------
  | | -----------------------------
  | -------------------------------
  ---------------------------------
}
CONST WT_Border        = $0001;  {Window Has A Border}
      WT_Button        = $0002;  {Window is a button}
      WT_Shadow        = $0004;  {Window has a shadow}
      WT_AlwaysActive  = $0008;  {Window can not be disabled}
      WT_NonSelectable = $0010;  {Window can not be selected}
      WT_AutoDisable   = $0020;  {Window has been disabled by another window}
      WT_Disabled      = $0040;  {Window is disabled}
      WT_Visable       = $0080;  {Window is currently on screen}
      WT_CentreText    = $0100;
      WT_NonDeletable  = $0200;  {Window Is Not Disposed Of}

      StdWin           = WT_Border OR WT_Shadow OR WT_Visable;
      StdBtn           = WT_Border OR WT_Shadow OR WT_Visable OR WT_Button;
      StdEdit          = WT_Border OR WT_Visable;
{
      ChildWidth  : INTEGER = 96;
      ChildHeight : INTEGER = 64;
}
CONST
      ChildWindowWidth  = 96;
      ChildWindowHeight = 64;
      ChildWidth        = ChildWindowWidth;
      ChildHeight       = ChildWindowHeight;
      LargeChildWidth   = ChildWidth+16;
      LargeChildHeight  = ChildHeight+16;




TYPE  PSTRING  = ^STRING;
      PINTEGER = ^INTEGER;
      PDOUBLE  = ^DOUBLE;
      PLONGINT = ^LONGINT;
      PBOOLEAN = ^BOOLEAN;
      PWORD    = ^WORD;

      PcxNameStr = STRING[12];

TYPE   PSFWindow = ^TSFWindow;
       TSFWindow = OBJECT
{$IFDEF DEBUGOBJECT}
        WindowType    : STRING[30];
{$ENDIF}
        HParent       : PSFWindow;
        Bounds        : TRect;
        Next          : PSFWindow;
        FontToUse     : PFontType;
        WinType       : WORD;
        ChildWindows  : PSFwindow;
        BackColour    : BYTE;
        PreviousModalWin : PSFWindow;

         CONSTRUCTOR Init(x1,y1,x2,y2 : WORD; BackCol : BYTE;WinFlags : WORD;Parent : PSFWindow;AddToWindowList : BOOLEAN);

         DESTRUCTOR  Done;VIRTUAL;

         PROCEDURE AddToLinkList(VAR ListStart : PSFWindow);
         PROCEDURE RemoveAChildFromList(AChildWin : PSFWindow);
         PROCEDURE DisplayText(Line : WORD;Str :STRING);

         FUNCTION  IsPointInWindow(X,Y : INTEGER) : BOOLEAN;VIRTUAL;
         FUNCTION  UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;

         PROCEDURE BorderDraw; VIRTUAL;

         PROCEDURE ShowWindow; VIRTUAL;
                   { if window not visible then changes it to visible and }
                   { calls Paint(). }
         PROCEDURE HideWindow; VIRTUAL;
                   { if window is visible then changes it to hidden and   }
                   { calls RemoveWindow() }

         PROCEDURE Draw;VIRTUAL;
         FUNCTION  ChangeWindowFont(NewFont : PFontType) : PFontType;
         PROCEDURE WriteHeader(Str : STRING);

         PROCEDURE Paint;
                   { clears the rectangle then calls Draw, BorderDraw, PaintChildWindows }
         PROCEDURE PaintChildWindows; VIRTUAL;

         PROCEDURE Redraw; { calls HideWindow then showWindow }

         PROCEDURE ClearWindow;

         PROCEDURE SetWindow(x1,y1,x2,y2 : WORD);VIRTUAL;

         PROCEDURE ReceiveMsg(Msg : INTEGER);VIRTUAL;
         PROCEDURE SendMsg(hWindow : PSFWindow;Msg : INTEGER);
         PROCEDURE ButtonUp; VIRTUAL;
         PROCEDURE ButtonDown; VIRTUAL;
         PROCEDURE WhileButtonDown(X,Y : INTEGER);VIRTUAL;
         PROCEDURE DisableAllButtonsExceptMe;
         PROCEDURE UnDisableAllButtons;
         PROCEDURE WriteWinStr(XCo,YCo : INTEGER;Str : STRING);

         PROCEDURE HideChildWindows;
         PROCEDURE ShowChildWindows;

         PROCEDURE ClearChildWindows;
         FUNCTION  ActivateIfInAChildWindow(X,Y : INTEGER) : BOOLEAN;
         FUNCTION  IsAChildOf(hChild : PSFWindow):BOOLEAN;

         FUNCTION  IsWindowVisable : BOOLEAN;
         FUNCTION  IsWindowDisabled: BOOLEAN;
         FUNCTION  IsWindowSelectable:BOOLEAN;

         PROCEDURE RemoveWindow; { calls DeleteWindow() } VIRTUAL;
         PROCEDURE DisableButton;
         PROCEDURE EnableButton;
         {PROCEDURE DisableBtn(Dsbl : BOOLEAN);}

         FUNCTION  GetTypeName : STRING;VIRTUAL;
         FUNCTION  GetWindowFlags  : WORD; VIRTUAL;
         PROCEDURE SetWindowFlags(Flags : WORD); VIRTUAL;
       PRIVATE
         FUNCTION  InWindow(VAR Rect : TRect) : BOOLEAN;
       END;



TYPE   PButtonWindow = ^TButtonWindow;
       TButtonWindow = OBJECT(TSFWindow)

         CONSTRUCTOR Init(x1,y1,x2,y2 : WORD; BackCol : BYTE; WinFlags : WORD);   { Co-ordinates of button}
         DESTRUCTOR  Done;VIRTUAL;
         FUNCTION    IsPointInWindow(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
         FUNCTION    GetTypeName : STRING;VIRTUAL;
       END;

       PParentWindow = ^TParentWindow;
       TParentWindow = OBJECT(TButtonWindow) {Special Window for Parents}

        HitPointX,HitPointY : INTEGER;
        ChildHit            : PSFWindow;
        LastChildHit        : PSFWindow;
         CONSTRUCTOR Init(x1,y1,x2,y2 : Word; BackCol : BYTE; WinFlags : WORD);
         DESTRUCTOR  Done;VIRTUAL;
         PROCEDURE   ShowWindow; VIRTUAL;
         PROCEDURE   HideWindow; VIRTUAL;
         PROCEDURE   ButtonUp;   VIRTUAL;
         PROCEDURE   ButtonDown; VIRTUAL;
         FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
         FUNCTION    IsPointInWindow(X,Y : INTEGER) : BOOLEAN;VIRTUAL;
         PROCEDURE   WhileButtonDown(X,Y : INTEGER);VIRTUAL;
         FUNCTION    GetTypeName : STRING;VIRTUAL;
       END;



       PChildWindow = ^TChildWindow;
       TChildWindow = OBJECT(TSFWindow)
         DESTRUCTOR Done;VIRTUAL;
         FUNCTION   IsPointInWindow(X,Y : INTEGER):BOOLEAN; VIRTUAL;
         FUNCTION    GetTypeName : STRING;VIRTUAL;
       END;

       PChildAreaObject = ^TChildAreaObject;
       TChildAreaObject = OBJECT(TChildWindow)
               { Co-ordinates of button and parent}
         CONSTRUCTOR Init(x1,y1: WORD;Parent : PSFWindow;LargeButtons : BOOLEAN);
         FUNCTION    GetTypeName : STRING;VIRTUAL;
       END;


TYPE PPCXButton = ^TPCXButton;
     TPCXButton = OBJECT(TButtonWindow)
       Face : PPCXBitmap;

       CONSTRUCTOR Init(x1,y1,x2,y2,WinFlags : WORD;PcxFile : PCXNameStr);   { Co-ordinates of button & PCXFile}
       DESTRUCTOR  Done; VIRTUAL;

       PROCEDURE   Draw; VIRTUAL;
     END;

TYPE PPCXTriStateButton = ^TPCXTriStateButton;
     TPCXTriStateButton = OBJECT(TButtonWindow)
       Face     : ARRAY [1..3] OF PPCXBitmap;
       CurrFace : BYTE;
       CONSTRUCTOR Init(x1,y1,x2,y2,WinFlags : WORD;Pcx1,Pcx2,Pcx3 : PCXNameStr);
       DESTRUCTOR  Done; VIRTUAL;
       PROCEDURE   SetFace(FaceNo : BYTE); VIRTUAL;
       FUNCTION    GetFace : BYTE; VIRTUAL;
       PROCEDURE   Draw; VIRTUAL;
     END;

CONST WindowListHeader : PSFWindow = NIL;

FUNCTION  SetWindowList(ListHeader : PSFWindow) : PSFWindow;
PROCEDURE Lose_Windows_In_Visable_List;
PROCEDURE ScreenRedraw;
FUNCTION  GetPointerToHitObject(HitX,HitY : INTEGER) : PSFWindow;

FUNCTION  SetNonDisabledButton(ButtonOrNil : PSFWindow) : PSFWindow;
FUNCTION  GetNonDisabledButton : PSFWindow;


IMPLEMENTATION
USES SFXUTILS,
{$IFDEF DEBUGWIN} CRT, {$ENDIF}
     SFXCOLR;
{
USES F6StdCtv,SfxUtils,FXStdUt1,F6StdUtl,SfxStdBt,SfxComms,SFXFont;
}
CONST NONDisabledButton  : PSFWindow = NIL;


FUNCTION SetNonDisabledButton(ButtonOrNil : PSFWindow) : PSFWindow;
BEGIN
 SetNonDisabledButton := NONDisabledButton;
 NONDisabledButton := ButtonOrNil;
 ProcessObject^.ModalWinIsUp := (NONDisabledButton <> NIL);
END;

FUNCTION GetNonDisabledButton : PSFWindow;
BEGIN
 GetNonDisabledButton := NONDisabledButton
END;


{NON OBJECT PROCEDURE AND FUNCTIONS}
FUNCTION SetWindowList(ListHeader : PSFWindow) : PSFWindow;
BEGIN
 SetWindowList    := WindowListHeader;
 WindowListHeader := ListHeader;
END;

PROCEDURE Lose_Windows_In_Visable_List;
VAR
   LoopArea,DelArea : PSFWindow;
(* WindowCnt : INTEGER;*)

BEGIN
(*
 Disp_Error_msg('losing windows');
 WindowCnt := 0;

 LoopArea:=WindowListHeader;
 WHILE (LoopArea <> NIL) DO
  BEGIN
   Inc(WindowCnt);
   LoopArea := LoopArea^.Next;
  END;
 Disp_Error_msg(IntToStr(WindowCnt,1)+'windows');
*)
 LoopArea:=WindowListHeader;
 WHILE (LoopArea <> NIL) DO
  BEGIN
   DelArea  := LoopArea;
   LoopArea := LoopArea^.Next;
   IF ((DelArea^.WinType AND WT_NonDeletable) = 0) THEN
     Dispose(DelArea,Done); { removes its self from list }
  END;
 (*WindowListHeader := NIL; { windows can still exist}*)
END;

PROCEDURE ScreenRedraw;
VAR  LoopArea : PSFWindow;
BEGIN
 ClrGraphWin;
 HideMouseCursor;
 LoopArea := WindowListHeader;
 WHILE (LoopArea <> NIL) DO
  BEGIN
   LoopArea^.Paint;
   LoopArea := LoopArea^.Next;
  END;
 ShowMouseCursor;
END;

FUNCTION  GetPointerToHitObject(HitX,HitY : INTEGER) : PSFWindow;
VAR LoopArea : PSFWindow;
BEGIN
 GetPointerToHitObject := NIL;
 LoopArea := WindowListHeader;
 WHILE (LoopArea <> NIL) DO
  BEGIN
   IF LoopArea^.IsPointInWindow(HitX,HitY) THEN
    BEGIN
      GetPointerToHitObject := LoopArea;
      EXIT;
    END;
   LoopArea:=LoopArea^.Next;
  END;
END;

{================Child Windows Object=====================}
FUNCTION TChildWindow.IsPointInWindow(X,Y : INTEGER):BOOLEAN;
BEGIN
 { TEdit (descends from TChild) may not have a parent (descends from Tbutton
   which normally checks its self against NonDisabledButton) so we need
   to check it hasnt been disabled ie cant be selected whilst modal win is up. }
 IF  (HParent = NIL)
 AND (NonDisabledButton <> NIL)
 AND (PChildWindow(NonDisabledButton) <> @Self) THEN
   IsPointInWindow := FALSE
 ELSE
  BEGIN
   WITH Bounds DO
     IsPointInWindow :=((WinType  AND (WT_Disabled OR WT_NonSelectable))=0) AND
                   ((WinType  AND WT_Visable)<>0) AND
                    (X>=Left) AND (X<=Right) AND
                    (Y>=Top)  AND (Y<=Bottom);
  END;
END;

FUNCTION TChildWindow.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TCHILDWINDOW';
END;

DESTRUCTOR TChildWindow.Done;
BEGIN
 INHERITED Done;
END;

{=============Child Area Object Initiation Routine==========}
CONSTRUCTOR TChildAreaObject.Init(x1,y1: WORD;Parent : PSFWindow;LargeButtons : BOOLEAN);
BEGIN
 IF (LargeButtons) THEN
  INHERITED Init(X1,Y1,X1+LargeChildWidth,Y1+LargeChildHeight,C_TextButton SHR 4,StdBtn,Parent,FALSE)
 ELSE
  INHERITED Init(X1,Y1,X1+ChildWidth,Y1+ChildHeight,C_TextButton SHR 4,StdBtn,Parent,FALSE);
 AddToLinkList(hParent^.ChildWindows);
END;

FUNCTION TChildAreaObject.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TCHILDAREAOBJECT';
END;

{==================== TSFWindow METHODS ==========================}
CONSTRUCTOR TSFWindow.Init(x1,y1,x2,y2 : WORD; BackCol : Byte;WinFlags : WORD;Parent : PSFWindow;AddToWindowList : BOOLEAN);
BEGIN
 hParent := Parent;
 WinType := WinFlags;
 BackColour := BackCol;
 WITH Bounds DO
  BEGIN
   Left    := MIN(X1,X2);
   Right   := MAX(X1,X2);
   Top     := MIN(Y1,Y2);
   Bottom  := MAX(Y1,Y2);
   IF IsWindowVisable THEN RemoveWindow;
  END;
 PreviousModalWin := NIL;
 IF (AddToWindowList) THEN
  BEGIN
   AddToLinkList(WindowListHeader);
  END;
 FontToUse    := DefaultFont;
 ChildWindows := NIL;
{$IFDEF DEBUGOBJECT}
 WindowType   := GetTypeName;
{$ENDIF}
 IF IsWindowVisable THEN Paint;
END;

DESTRUCTOR TSFWindow.Done;
VAR Loop,Last : PSFWindow;
    DoRedraw,
    RedrawWin : BOOLEAN;
    This      : PSFWindow;
    ChildWin  : BOOLEAN;
BEGIN
 IF (NONDisabledButton = @Self) THEN
   UndisableAllButtons;

 {First Dispose of any child windows}
 ClearChildWindows;
 {delete window from screen}
 RemoveWindow;
 {if the window covered any window on the screen redraw that window}
 Loop     := WindowListHeader;
 This     := NIL;               {Pointer To This Object Within Linked List}
 Last     := NIL;               {Pointer To Previous Object Within Linked List}
 ChildWin := FALSE;
 DoRedraw := TRUE;

 IF (Self.hParent <> NIL) THEN
  BEGIN
   HParent^.RemoveAChildFromList(@Self);
   IF (Self.InWindow(Self.HParent^.Bounds)) THEN
    BEGIN
     DoRedraw := FALSE;
     ChildWin := TRUE;
    END;
  END;

 IF (DoRedraw) THEN
  BEGIN
   WHILE (Loop<>NIL) DO
    BEGIN
     IF  (Loop<> @Self)
     AND (NOT Loop^.IsAChildOf(@Self))
     AND Loop^.IsWindowVisable THEN
      BEGIN
       RedrawWin := Loop^.InWindow(Bounds) OR InWindow(Loop^.Bounds);
       IF (DoRedraw AND RedrawWin) THEN loop^.Paint;
      END
     ELSE
      BEGIN
       IF (Loop = @Self) THEN This := Loop;
      END;
     IF This = NIL THEN Last := Loop;
     Loop := Loop^.Next;
    END;
  END;

 {Do Not Remove Link For Child Windows}
 IF (NOT ChildWin) THEN
  BEGIN
   IF This <> NIL THEN { found myself in list of windows }
    BEGIN
     IF Last = NIL THEN { there's no window in front of me }
      BEGIN
       WindowListHeader := Next;
      END
     ELSE
      BEGIN
       Last^.Next := Next;     {Remove From Linked List}
      END;
     Next := NIL;
    END;
  END;

 {remove the window from the linked list}
(*
 Last := NIl;
 Loop := WindowListHeader;
 WHILE (Loop<>NIL) DO
  BEGIN
   IF Loop = @Self THEN
    BEGIN
     IF Last = NIL THEN       {Item at front of list}
      BEGIN
       WindowListHeader := WindowListHeader^.Next;
      END
     ELSE
      BEGIN
       Last^.Next := Loop^.Next;     {Remove From Linked List}
      END;
     Loop^.Next := NIL;
     BREAK;
    END;
   Last := Loop;
   Loop := Loop^.Next;
  END;
*)
END;


FUNCTION TSFWindow.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TSFWINDOW';
END;

{Returns True if hChild Is a child of window}
FUNCTION  TSFWindow.IsAChildOf(hChild : PSFWindow):BOOLEAN;
VAR Loop : PSFWindow;
BEGIN
 IsAChildOf := FALSE;
 Loop := ChildWindows;
 WHILE (Loop <> NIL) DO
  BEGIN
   IF Loop = hChild THEN
    BEGIN
     IsAChildOf := TRUE;
     EXIT;
    END;
   Loop := Loop^.Next;
  END;
END;

{===== Calls the child UserActivateFunction If Point X,Y  is in a child =====}
FUNCTION TSFWindow.ActivateIfInAChildWindow(X,Y : INTEGER) : BOOLEAN;
VAR Loop : PSFWindow;
BEGIN
 ActivateIfInAChildWindow := FALSE;
 Loop := Childwindows;
 WHILE (Loop <>NIL) DO
  BEGIN
   IF Loop^.IsPointInWindow(X,Y) THEN
    BEGIN
     Loop^.UserActivateFunction(X,Y);
     ActivateIfInAChildWindow := TRUE;
     BREAK;
    END;
   Loop := Loop^.Next;
  END;
END;

PROCEDURE TSFWindow.AddToLinkList(VAR ListStart : PSFWindow);
VAR PWin : PSFWindow;
BEGIN
 { put in on the end of the list }
 Next := NIL;

 PWin := ListStart;
 IF PWin = NIL THEN { this is the first win (in list) }
   ListStart := @Self
 ELSE { find last window }
  BEGIN
   WHILE (PWin^.Next <> NIL) DO
     PWin := PWin^.Next;
   PWin^.Next := @Self; { change last win to point to this }
  END;
END;

PROCEDURE TSFWindow.RemoveAChildFromList(AChildWin : PSFWindow);
VAR
   Loop   : PSFWindow;
BEGIN
 IF ChildWindows <> NIL THEN
  BEGIN
   IF ChildWindows = AChildWin THEN
     ChildWindows := AChildWin^.Next
   ELSE { find window in front of AChildWin in child list }
    BEGIN
     Loop := ChildWindows;
     WHILE Loop^.Next <> NIL DO
      BEGIN
       IF Loop^.Next = AChildWin THEN
        BEGIN
         Loop^.Next := AChildWin^.Next;
         BREAK;
        END;
       Loop := Loop^.Next;
      END;
    END;
  END;
END;

PROCEDURE TSFWindow.ClearChildWindows;
VAR Loop   : PSFWindow;
    DelWin : PSFWindow;
BEGIN
 Loop := ChildWindows;
 WHILE (Loop <> NIL) DO
  BEGIN
   DelWin := Loop;
   Loop := ChildWindows^.Next;
   Dispose(DelWin,Done);
  END;
END;

FUNCTION TSFWindow.ChangeWindowFont(NewFont : PFontType) : PFontType;
BEGIN
 ChangeWindowFont := FontToUse;
 FontToUse        := NewFont;
END;

{Sends a message to another window most probably parent}
PROCEDURE TSFWindow.SendMsg(hWindow : PSFWindow;Msg : INTEGER);
BEGIN
 hWindow^.ReceiveMsg(Msg);
END;

PROCEDURE TSFWindow.ReceiveMsg(Msg : INTEGER);
BEGIN
END;

PROCEDURE TSFWindow.ShowChildWindows;
VAR Loop : PSFWindow;
BEGIN
 Loop := Childwindows;
 WHILE (Loop <>NIL) DO
  BEGIN
   Loop^.ShowWindow;
   Loop := Loop^.Next;
  END;
END;

PROCEDURE TSFWindow.ShowWindow;
BEGIN
 IF IsWindowVisable THEN EXIT;
 RemoveWindow;
 WinType := WinType OR WT_Visable;
 Paint;
END;

PROCEDURE TSFWindow.WhileButtonDown(X,Y : INTEGER);
BEGIN
END;

PROCEDURE TSFWindow.HideChildWindows;
VAR Loop : PSFWindow;
BEGIN
 Loop := Childwindows;
 WHILE (Loop <>NIL) DO
  BEGIN
   Loop^.HideWindow;
   Loop := Loop^.Next;
  END;
END;

PROCEDURE TSFWindow.PaintChildWindows;
VAR Loop : PSFWindow;
BEGIN
 Loop := Childwindows;
 WHILE (Loop <>NIL) DO
  BEGIN
   Loop^.Paint;
   Loop := Loop^.Next;
  END;
END;


PROCEDURE TSFWindow.HideWindow;
BEGIN
 IF NOT IsWindowVisable THEN EXIT;
 WinType := WinType AND (NOT WT_Visable);
 RemoveWindow;
END;

PROCEDURE TSFWindow.ClearWindow;
VAR SaveCol : BYTE;
BEGIN
 SaveCol := SetBackColour(BackColour);
 DeleteWindow(Bounds.Left,Bounds.Top,Bounds.Right,Bounds.Bottom);
 SetBackColour(SaveCol);
END;

PROCEDURE TSFWindow.Redraw;
BEGIN
 HideWindow;
 ShowWindow;
END;

PROCEDURE TSFWindow.SetWindow(x1,y1,x2,y2 : WORD);
BEGIN
 WITH Bounds DO
  BEGIN
   IF ((WinType AND WT_Visable) <> 0) THEN RemoveWindow;
   Left  := MIN(X1,X2);
   Right := MAX(X1,X2);
   Top   := MIN(Y1,Y2);
   Bottom:= MAX(Y1,Y2);
  END;
 IF ((WinType AND WT_Visable) <> 0) THEN Paint;
END;

PROCEDURE TSFWindow.ButtonDown;
BEGIN
 IF (WinType AND WT_Button) = 0 THEN EXIT;
 Shadowing  := FALSE;
 WITH Bounds DO SetWindow(Left+3,Top+3,Right+3,Bottom+3);
 Shadowing  := TRUE;
END;

PROCEDURE TSFWindow.ButtonUp;
BEGIN
 IF (WinType AND WT_Button) = 0 THEN EXIT;
 WITH Bounds DO  SetWindow(Left-3,Top-3,Right-3,Bottom-3);
END;

PROCEDURE TSFWindow.WriteHeader(Str : STRING);
VAR
    HoldFont     : PFontType;
    WriteStr     : STRING[80];
    I : INTEGER;
    XPos,YPos    : INTEGER;
    SaveCol      : BYTE;
BEGIN
 HoldFont := SetCurrentFont(Font8x16 {CreateFont(1,1,HORIZ,FONT_8X16,FontInversed)});
 WriteStr := Centered(Str,(Bounds.Right-Bounds.Left) DIV 8);
 Xpos := (Bounds.Left+2);
 Ypos := (Bounds.Top+2);
 SaveCol :=SetTextColour(C_WindowHeader);
 FOR I:=1 TO Length(WriteStr) DO
  BEGIN
   WriteStrAtPixel(XPos,YPos,WriteStr[I]);
   INC(XPos,CurrFontBitMap^.FontWidth*8);
  END;
 SetTextColour(SaveCol);
 {DeleteFont();}
 SetCurrentFont(HoldFont);
END;

PROCEDURE TSFWindow.WriteWinStr(XCo,YCo : INTEGER;Str : STRING);
BEGIN
 WITH Bounds DO
 WriteStrAt((Left DIV 8) + XCo,(Top DIV 8) + YCo,Str);
END;

PROCEDURE TSFWindow.DisplayText(Line : WORD;Str :STRING);
VAR I : INTEGER;
    XPos,YPos : INTEGER;
    HoldFont  : PFontType;
BEGIN
 HoldFont := SetCurrentFont(FontToUse);
 Xpos := (Bounds.Left+8);
 Ypos := (Bounds.Top)+Line*8;
 FOR I:=1 TO Length(Str) DO
  BEGIN
   CASE Str[I] OF
    #13 : XPos := (Bounds.Left+8);
    #10 : INC(YPos,CurrFontBitMap^.BitMapHeight);
   ELSE
    BEGIN
     WriteColourCharAt(XPos,YPos,Str[I],TXTForeground,TXTBackGround);
     INC(XPos,CurrFontBitMap^.FontWidth*8);
    END;
   END;
  END;
 SetCurrentFont(HoldFont);
END;

FUNCTION  TSFWindow.IsPointInWindow(X,Y : INTEGER) : BOOLEAN;
BEGIN
 IsPointInWindow := FALSE;
END;

FUNCTION TSFWindow.InWindow(VAR Rect : TRect) : BOOLEAN;
VAR INWin : BOOLEAN;
BEGIN
 WITH Bounds DO
 InWin:=
    (((Left   >= Rect.Left) AND (Left   <= Rect.Right))  OR
    ((Right   >= Rect.Left) AND (Right  <= Rect.Right))) AND
    (((Top    >= Rect.Top)  AND (Top    <= Rect.Bottom)) OR
    ((Bottom  >= Rect.Top)  AND (Bottom <= Rect.Bottom)));

(*
 InWin:=
    (((Rect.Left   >= Left) AND (Rect.Left   <= Right))  OR
    ((Rect.Right   >= Left) AND (Rect.Right  <= Right))) AND
    (((Rect.Top    >= Top)  AND (Rect.Top    <= Bottom)) OR
    ((Rect.Bottom  >= Top)  AND (Rect.Bottom <= Bottom)));
*)
 InWindow := InWin;
END;

FUNCTION TSFWindow.IsWindowVisable : BOOLEAN;
BEGIN
 IsWindowVisable :=(WinType AND WT_Visable) <> 0;
END;

FUNCTION TSFWindow.IsWindowDisabled: BOOLEAN;
BEGIN
 IsWindowDisabled := ((NonDisabledButton<>NIL) AND
                      (Pointer(NonDisabledButton)<>Pointer(@Self))) OR
                       ((WinType AND WT_Disabled)<>0);
END;

PROCEDURE TSFWindow.RemoveWindow;
VAR SaveCol : BYTE;
BEGIN
 IF HParent = NIL THEN SaveCol := SetBackColour(C_BackGround)
 ELSE SaveCol := SetBackColour(HParent^.BackColour);
 WITH Bounds DO
  BEGIN
   IF (WinType AND WT_Shadow) <> 0 THEN
    DeleteWindow(Left,Top,Right+3,Bottom+3)
   ELSE
    DeleteWindow(Left,Top,Right+1,Bottom+1);
  END;
 SetBackColour(SaveCol);
END;

PROCEDURE TSFWindow.Paint;
{ clears the rectangle then calls Draw and BorderDraw }
VAR SaveCol : BYTE;
BEGIN
{$IFDEF DEBUGWIN}
 Delay(300);
{$ENDIF}
 IF (WinType AND WT_Visable) = 0 THEN EXIT;
 ClearWindow;
 SaveCol := SetBackColour(BackColour);
 {DeleteWindow(Bounds.Left,Bounds.Top,Bounds.Right+1,Bounds.Bottom+1);}
 Draw;
 BorderDraw;
 SetBackColour(SaveCol);
 PaintChildWindows;
END;

PROCEDURE TSFWindow.BorderDraw;
VAR SaveCol : BYTE;
BEGIN
 SaveCol := BackGround;
 IF (HParent <> NIL) THEN BackGround := HParent^.BackColour;
 IF (WinType AND WT_Border) <>0 THEN
 WITH Bounds DO DrawWindow(Left,Top,Right,Bottom,((WinType AND WT_Shadow)<>0) AND Shadowing);
 BackGround := SaveCol;
END;

PROCEDURE TSFWindow.Draw;
BEGIN
END;

PROCEDURE TSFWindow.DisableAllButtonsExceptMe;
BEGIN
 IF PreviousModalWin = NIL THEN
   PreviousModalWin := SetNonDisabledButton(@Self);
END;

PROCEDURE TSFWindow.UnDisableAllButtons;
BEGIN
 IF (NONDisabledButton = @Self) THEN
   SetNonDisabledButton(PreviousModalWin);
 PreviousModalWin := NIL;
END;


{==================== TButton Window Methods =====================}
FUNCTION TButtonWindow.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TBUTTONWINDOW';
END;

CONSTRUCTOR TButtonWindow.Init(x1,y1,x2,y2 : WORD; BackCol : BYTE; WinFlags : WORD);
BEGIN
 INHERITED Init(x1,y1,x2,y2,BackCol,WinFlags,NIL,TRUE);
END;

DESTRUCTOR TButtonWindow.Done;
BEGIN
 INHERITED Done;
END;

FUNCTION TButtonWindow.IsPointInWindow(X,Y : INTEGER) : BOOLEAN;
BEGIN
 IF ((WinType AND WT_AlwaysActive) =0) THEN
 IF (NonDisabledButton <> NIL) AND (PButtonWindow(NonDisabledButton) <> @Self) THEN
   BEGIN
    IsPointInWindow := FALSE;
    EXIT;
   END;
 WITH Bounds DO
 ISPointInWindow:=((WinType AND (WT_Disabled OR WT_NonSelectable))=0) AND
                  ((WinType AND WT_Visable)<>0) AND
                   (X>=Left) AND (X<=Right) AND (Y>=Top) AND (Y<=Bottom);
END;

PROCEDURE TSFWindow.DisableButton;
BEGIN
  WinType := WinType OR WT_NonSelectable;
END;

PROCEDURE TSFWindow.EnableButton;
BEGIN
  WinType := WinType AND NOT WT_NonSelectable
END;

FUNCTION  TSFWindow.IsWindowSelectable;
{ note: only looks at window attributes
        not at window list (yet) }
BEGIN
 IsWindowSelectable := ((WinType AND WT_NonSelectable) = 0);
END;

(*
PROCEDURE TSFWindow.DisableBtn(Dsbl : BOOLEAN);
BEGIN
 IF NOT Dsbl THEN
  WinType := WinType AND NOT WT_NonSelectable
 ELSE
  WinType := WinType OR WT_NonSelectable;
END;
*)

FUNCTION  TSFWindow.GetWindowFlags  : WORD;
BEGIN
 GetWindowFlags := WinType;
END;

PROCEDURE TSFWindow.SetWindowFlags(Flags : WORD);
BEGIN
 WinType := Flags;
END;

FUNCTION TSFWindow.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 UserActivateFunction := FALSE;
END;

PROCEDURE TParentWindow.ButtonUp;
BEGIN
 IF ChildHit <> NIL THEN ChildHit^.ButtonUp;
 LastChildHit := ChildHit;
 ChildHit := NIL;
END;

FUNCTION TParentWindow.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TPARENTWINDOW';
END;

PROCEDURE TParentWindow.ButtonDown;
BEGIN
 IF ChildHit <> NIL THEN ChildHit^.ButtonDown;
END;

FUNCTION  TParentWindow.IsPointInWindow(X,Y : INTEGER) : BOOLEAN;
VAR PointInWin : BOOLEAN;
    Loop : PSFWindow;
BEGIN
 IsPointInWindow := FALSE;
 PointInWin := INHERITED IsPointInWindow(X,Y);
 IF PointInWin THEN
  BEGIN
   Loop := ChildWindows;
   WHILE (Loop <>NIL) DO
    BEGIN
     IF Loop^.IsPointInWindow(X,Y) THEN
      BEGIN
       ChildHit := Loop;
       IsPointInWindow := TRUE;
       BREAK;
      END;
     Loop := Loop^.Next;
    END;
  END;
 IsPointInWindow := PointInWin;
END;


CONSTRUCTOR TParentWindow.Init(x1,y1,x2,y2 : WORD; BackCol : BYTE; WinFlags : WORD);
BEGIN
 ChildHit     := NIL;
 LastChildHit := NIL;
 INHERITED Init(X1,Y1,X2,Y2,BackCol,WinFlags);
END;

PROCEDURE TParentWindow.ShowWindow;
VAR
    Loop : PSFWindow;
BEGIN
 INHERITED ShowWindow;
 ShowChildWindows;
END;

PROCEDURE TParentWindow.HideWindow;
VAR
    Loop : PSFWindow;
BEGIN
 HideChildWindows;
 INHERITED HideWindow;
END;

FUNCTION TParentWindow.UserActivateFunction;
CONST InFunc : BOOLEAN = FALSE;
BEGIN
{ IF InFunc THEN EXIT;}
 InFunc := TRUE;
 ActivateIfInAChildWindow(X,Y);
 UserActivateFunction := FALSE;
 InFunc := FALSE;
 LastChildHit := NIL;
END;

PROCEDURE TParentWindow.WhileButtonDown(X,Y : INTEGER);
BEGIN
 IF (ChildHit <> NIL) THEN ChildHit^.WhileButtonDown(X,Y);
END;

DESTRUCTOR TParentWindow.Done;
BEGIN
 INHERITED Done;
END;



{ PCX BITMAP BUTTON METHODS }


CONSTRUCTOR TPCXButton.Init(x1,y1,x2,y2,WinFlags : WORD;PcxFile : PcxNameStr);

BEGIN
  NEW(Face,Init(PcxFile,FALSE,TRUE));
  INHERITED Init(x1,y1,x2,y2,$0F,WinFlags);
END;

PROCEDURE TPCXButton.Draw;
BEGIN
 Face^.DrawAt(Bounds.Left,Bounds.Top);
END;


DESTRUCTOR TPCXButton.Done;
BEGIN
 Dispose(Face,Done);
 INHERITED Done;
END;


{ TPCXTriStateButton Methods }
CONSTRUCTOR TPCXTriStateButton.Init(x1,y1,x2,y2,WinFlags : WORD;Pcx1,Pcx2,Pcx3 : PCXNameStr);

BEGIN
  NEW(Face[1],Init(Pcx1,FALSE,TRUE));
  NEW(Face[2],Init(Pcx2,FALSE,TRUE));
  NEW(Face[3],Init(Pcx3,FALSE,TRUE));
  CurrFace := 1;
  INHERITED Init(x1,y1,x2,y2,$0F,WinFlags);
END;

PROCEDURE TPCXTriStateButton.Draw;
BEGIN
 Face[CurrFace]^.DrawAt(Bounds.Left,Bounds.Top);
END;

PROCEDURE TPCXTriStateButton.SetFace(FaceNo : BYTE);
BEGIN
 IF FaceNo < 1 THEN FaceNo := CurrFace;
 IF FaceNo > 3 THEN FaceNo := CurrFace;
 CurrFace := FaceNo;
 Paint;
END;

FUNCTION TPCXTriStateButton.GetFace : BYTE;
BEGIN
  GetFace := CurrFace;
END;

DESTRUCTOR TPCXTriStateButton.Done;
BEGIN
 Dispose(Face[3],Done);
 Dispose(Face[2],Done);
 Dispose(Face[1],Done);
 INHERITED Done;
END;


END.
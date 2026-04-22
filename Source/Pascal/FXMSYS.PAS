(****************************************************************************
*  UNIT          : FXMSYS                                                   *
*  AUTHOR        : S. M. Wright                                             *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : FORMIX MAIN MENU CODE                                     *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXMSYS;

INTERFACE

USES Crt,F6StdWin,F6StdWn1,F6StdUtl,F6StdUt1,F6StdCtv,FXModCtv,
     FXCFG,FXFGEN,FXEvent{,F6FNotB,
     F6event,F6Time,F6Screen,F6FGen,F6Menu};

PROCEDURE Pulldown_Menus;

PROCEDURE UnGrayItem   (ItemCode : INTEGER);
PROCEDURE GrayItem     (ItemCode : INTEGER);
PROCEDURE UnGraySubMenu(MenuName : STRING);
PROCEDURE GraySubMenu  (MenuName : String);

IMPLEMENTATION

CONST AltKeys   : ARRAY[65..90] OF CHAR = (#30,#48,#46,#32,#18,#33,#34,#35,
                                           #23,#36,#37,#38,#50,#49,#24,#25,
					   #16,#19,#31,#20,#22,#47,#17,#45,
                                           #21,#44);
      MenuStart    = '$STARTMENU';
      MenuEnd      = '$ENDMENU';
      SubMenuStart = '$STARTSUB';
      MaxMenuItems = 21;

TYPE MenuItemText    = STRING[30];
     MenuItemTextPtr = ^MenuItemText;

TYPE PPS_Type = ^TPS_Type;
     TPS_Type = PACKED RECORD
      MNumber          : INTEGER;
      Key              : CHAR;
      down             : BOOLEAN;
      X,Y              : INTEGER;
      TitleEnd         : STRING[10];
      SubMenu          : BOOLEAN;
      menulist         : ARRAY[1..MaxMenuItems] OF MenuItemTextPtr;
      menuGray         : ARRAY[1..MaxMenuItems] OF BOOLEAN;
      menuEvent        : ARRAY[1..MaxMenuItems] OF INTEGER;
      menukey          : ARRAY[1..MaxMenuItems] OF CHAR;
      no               : INTEGER;
      x1,y1,x2,y2      : INTEGER;
      CurrentSel       : INTEGER;
      NB,LoF,HiF,RB,RF : BYTE;
      Next             : PPS_Type;
     END;

     FastKeyRec = PACKED RECORD
      Event : INTEGER;
      Used  : BOOLEAN;
     END;

VAR  FirstPulldown  : PPS_Type;
     Pulldown_State : PPS_Type;
     Fast_Keys      : ARRAY[1..20] OF FastKeyRec;
     Current_Option : INTEGER;
     WinSet         : BOOLEAN;
     Esc_Flag       : BOOLEAN;
     OptWin         : WindowRecord;
     Key            : CHAR;
     Old_Option     : INTEGER;
     Inc_Option     : INTEGER;
     Options        : INTEGER;

{***************************************************************************}
{ GetMenu Used To Find a Menu's Linked List Item                            }
{***************************************************************************}
FUNCTION GetMenu(MenuNo : INTEGER; CreateNewMenu : BOOLEAN) : PPS_Type;
VAR LastPtr,WrkPtr : PPS_Type;
BEGIN
 LastPtr := NIL;
 WrkPtr := FirstPullDown;                        { Start At First In List   }
 WHILE (WrkPtr <> NIL) DO
  BEGIN
   IF (WrkPtr^.MNumber = MenuNo) THEN            { Compare Menu Id Number   }
    BEGIN
     GetMenu := WrkPtr;                          { Found ( Return Ptr )     }
     Exit;
    END;
   LastPtr := WrkPtr;                            { Save Last Compared       }
   WrkPtr := WrkPtr^.Next;                       { Next Item                }
  END;
 IF CreateNewMenu THEN                           { Not Found And Create     }
  BEGIN
   WrkPtr := NIL;
   IF (MaxAvail > (SizeOF(TPS_Type)+8192)) THEN
    BEGIN
     NEW(WrkPtr);                                { Allocate New List Item   }
     WrkPtr^.MNumber := MenuNo;                  { Assign Menu Number       }
     WrkPtr^.Next := NIL;                        { Clear Ptr To Next item   }
     IF LastPtr <> NIL THEN LastPtr^.Next := WrkPtr    { Add To End Of List }
     ELSE FirstPullDown := WrkPtr;               { Reset First if reqd      }
    END;
   GetMenu := WrkPtr;                            { Return Ptr To List Item  }
  END
 ELSE GetMenu := NIL;
END;

  PROCEDURE DispMenuLine(x1,y1,x2,y2,s : BYTE);
  VAR
      Loop: WORD;
{$IFNDEF WINDOWS}
      Start,Stop      : WORD;
      FChar           : BYTE;
{$ENDIF}
  BEGIN
{$IFDEF WINDOWS}
   WriteDirectAt(x1,y1+s,CHR(195));
   FOR LOOP := 1 to (x2-x1) do WriteDirectAt(x1+Loop,y1+s,CHR(196));
   WriteDirectAt(x1+Loop,y1+s,CHR(180));
{$ELSE}
   { USES scrn_ptr FROM F6STDWIN.PAS }
   FChar := 196;
   Start := ((y1+s-1)*160) + (x1*2)-2;
   Stop  := ((y1+s-1)*160) + (x2*2)-2;
   scrn_ptr^[Start] := 195;
   Loop := Start+2;
   WHILE (Loop<Stop) DO
    BEGIN
     scrn_ptr^[loop] := FChar;
     INC(Loop,2);
    END;
   scrn_ptr^[Stop] := 180;
{$ENDIF}
  END;
(*
  PROCEDURE DispMenuLine(x1,y1,x2,y2,s : INTEGER);
  VAR Start,Stop,Loop : WORD;
      FChar           : BYTE;
  BEGIN
   { USES scrn_ptr FROM F6STDWIN.PAS }
   FChar := 196;
   Start := ((y1+s-1)*160) + (x1*2)-2;
   Stop  := ((y1+s-1)*160) + (x2*2)-2;
   scrn_ptr^[Start] := 195;
   Loop := Start+2;
   WHILE (Loop<Stop) DO
    BEGIN
     scrn_ptr^[loop] := FChar;
     INC(Loop,2);
    END;
   scrn_ptr^[Stop] := 180;
  END;
*)
PROCEDURE DispMenuTxt(o : INTEGER; s : INTEGER);
VAR HNback,HLoFor,HHiFor,HRBack,HRFor : BYTE;
    i,Ofs  : INTEGER;
    loop   : INTEGER;
    SetKey : BOOLEAN;
    TextSave : BYTE;
BEGIN
 PullDown_State := GetMenu(o,FALSE);
 WITH PullDown_State^ DO
  BEGIN
   Save_Colours(HNBack,HLoFor,HHiFor,HRBack,HRFor);
   IF menulist[s]^[1] = '-' THEN
    BEGIN
     DispMenuLine(x1,y1,x2,y2,s);
    END
   ELSE
    BEGIN
     Ofs := 1;
     IF menuGray[s] THEN
      Set_Colours(NB,DarkGray,HiF,RB,LightGray)
     ELSE
      Set_Colours(NB,Lof,Hif,RB,RF);
     IF s = CurrentSel THEN RevVideo
     ELSE LowVideo;
     Window(x1+1,y1+1,x2,y2-1);
     GotoXY(1,s);
     SetKey := FALSE;
     IF Pos('@',menulist[s]^) = 0 THEN Write(menulist[s]^)
     ELSE
      BEGIN
       Ofs := 0;
       Loop := Pos('@',menulist[s]^);
       Write(COPY(Menulist[s]^,1,Loop-1));
       TextSave := TextAttr;
       IF NOT MenuGray[S] THEN
        BEGIN
         IF s = CurrentSel THEN
          BEGIN
           IF PROP_Colour THEN TextAttr := RB*16+Hif ELSE TextAttr :=$7F;
          END
         ELSE
          BEGIN
           IF PROP_Colour THEN HighVideo ELSE TextAttr :=$0F;
          END;
        END;
       Write(menulist[s]^[loop+1]);
       textattr := textsave;
       INC(Loop,2);
       write(Copy(Menulist[s]^,loop,Length(Menulist[s]^)-loop+1));
      END;
     FOR i := ORD(menulist[s]^[0])+Ofs TO x2-x1-2 DO Write(' ');
     IF (menuevent[s] < 0) THEN
      BEGIN
        Write(CHAR(16))
      END
     ELSE Write(' ');
     Window(x1+1,y1+1,x2-1,y2-1);
    END;
   Set_Colours(HNBack,HLoFor,HHiFor,HRBack,HRFor);
  END;
END;

PROCEDURE ShowOpt(o : INTEGER);
VAR HNback,HLoFor,HHiFor,HRBack,HRFor : BYTE;
    BrdCol : BYTE;
    ScrCol : BYTE;
    TCol   : BYTE;
    i      : INTEGER;
BEGIN
 PullDown_State := GetMenu(o,FALSE);
 WITH PullDown_State^ DO
  BEGIN
   GoToXY (x,y);
   IF (Current_Option = o) AND NOT WinSet THEN
    BEGIN
     IF PROP_Colour THEN RevVideo ELSE TextAttr :=$70;
     IF Not SubMenu THEN
      BEGIN
       Write  (key);
       IF PROP_Colour THEN TCol := RevBack*16+LowFore ELSE TCol :=$7F;
       TextAttr := TCol;
       Write(TitleEnd);
      END;
     IF Down AND (no <> 0) THEN
      BEGIN
       LowVideo;
       WinSet := TRUE;
       Save_Colours(HNBack,HLoFor,HHiFor,HRBack,HRFor);
       Set_Colours(NB,LoF,HiF,RB,RF);
       IF PROP_Colour THEN BrdCol :=NB*16+Lof ELSE BrdCol :=$0F;
       SetWindow  (x1,y1,x2,y2,FALSE,BrdCol,BrdCol,OptWin);
       FOR i := 1 TO no DO DispMenuTxt(o,i);
       Set_Colours(HNBack,HLoFor,HHiFor,HRBack,HRFor);
      END;
    END
   ELSE IF Current_Option <> o THEN
    BEGIN
     IF o > 0 THEN
      BEGIN
       IF PROP_Colour THEN TCol :=NormBack*16+RevFore ELSE TCol :=$07;
       TextAttr := TCol;
       Write(key);
       IF PROP_Colour THEN LowVideo ELSE TextAttr :=$0E;
       Write(TitleEnd);
      END;
    END;
   LowVideo;
  END;
END;


PROCEDURE ChangeMenu(ByItem : BOOLEAN;ItemCode : INTEGER;MenuName : String;Gray : BOOLEAN);
VAR DumInt  : INTEGER;
    TempPPS : PPS_Type;

     FUNCTION MenuEqual(MName : String):BOOLEAN;
     Var WrkStr:String[30];
	 Strlength:INTEGER;
	 I : INTEGER;
     BEGIN
      StrLength:=0;
      FOR I:=1 TO Length(MName) DO
       IF MName[i]<>'@' THEN
	BEGIN
	 INC(StrLength);
	 WrkStr[StrLength]:=Upcase(MName[I]);
	END;
      WrkStr[0]:=Char(StrLength);
      WrkStr:=Stripped(WrkStr,Length(WrkStr),' ');
      MenuEqual:=WrkStr=MenuName;
     END;

BEGIN
 IF ByItem THEN
  BEGIN
   TempPPs:=FirstPullDown;
   WHILE TempPPS<>Nil DO
    BEGIN
     For dumInt:=1 to TempPPs^.no do
      begin
       if TempPPS^.MenuEvent[dumint]=ItemCode then
        BEGIN
         TempPPS^.MenuGray[dumint]:=Gray;
         EXIT;
        END;
      END;
     TempPPS:=TempPPS^.Next;
    END;
  END
 ELSE
  BEGIN
   MenuName:=Stripped(MenuName,Length(Menuname),' ');
   FOR dumint:=1 TO Length(MenuName) DO MenuName[dumint]:=Upcase(MenuName[dumint]);
   TempPPs:=FirstPullDown;
   While TempPPS<>Nil DO
    BEGIN
     For dumInt:=1 to TempPPs^.no do
      begin
       if TempPPS^.MenuEvent[dumint]<0 then
	begin
	 IF MenuEqual(TempPPS^.MenuList[dumint]^) THEN
	  BEGIN
	   TempPPS^.MenuGray[dumint]:=TRUE;
	   EXIT;
	  END;
	END;
      END;
     TempPPS:=TempPPS^.Next;
    END;
  END
END;


PROCEDURE UnGrayItem ( ItemCode : INTEGER);
BEGIN
 ChangeMenu(TRUE,ItemCode,'',FALSE);
END;

PROCEDURE GrayItem (ItemCode : INTEGER);
BEGIN
 ChangeMenu(TRUE,ItemCode,'',TRUE);
END;

PROCEDURE UnGraySubMenu(MenuName : STRING);
BEGIN
 ChangeMenu(FALSE,0,MenuName,FALSE);
END;


PROCEDURE GraySubMenu(MenuName : String);
BEGIN
 ChangeMenu(FALSE,0,MenuName,TRUE);
END;

FUNCTION Set_Pulldown : BOOLEAN;
VAR
   TheFile   : TEXT;
   InLin     : STRING;
   Check     : INTEGER;
   MenuNo    : WORD;
   SubMenuNo : INTEGER;
   Loop      : WORD;
   WrkStr    : STRING[10];
   DumInt    : INTEGER;
   QuickPos  : WORD;
   MenuWid   : INTEGER;
   TempPPS   : PPS_Type;
   TempSubPPS: PPS_Type;

   PROCEDURE AdjustMenuOverFlow(MPtr : PPS_Type);
   BEGIN
    WITH MPtr^ DO
     BEGIN
      IF y2 > 24 THEN
       BEGIN
	WHILE (y1 > 2) AND (y2 > 24) DO
	 BEGIN
	  Dec(y2); Dec(y1);
	 END;
	IF y2 > 24 THEN y2 := 24;
       END;
      IF x2 > 78 THEN
       BEGIN
	WHILE (x1 > 1) AND (x2 > 78) DO
	 BEGIN
	  Dec(x1); Dec(x2);
	 END;
	IF x2 > 78 THEN x2 := 78;
       END;
     END;
   END;


   PROCEDURE GrayMenu;
   BEGIN
   END;

   FUNCTION ReadMenuItems(MPtr : PPS_Type; VAR MaxWidth : INTEGER) : INTEGER;
   VAR NoMenuItems : INTEGER;
       ErrInt      : INTEGER;
       NewSubMenu  : PPS_Type;
       SubWid      : INTEGER;
       ItemNo      : INTEGER;
   BEGIN
    NoMenuItems := 0; MaxWidth := 0;
    WHILE (Pos(MenuEnd,InLin) = 0) AND NOT(EOF(TheFile)) DO
     BEGIN
      ReadLn(TheFile,InLin);
      Strip_Leading_Char(InLin,ORD(InLin[0]),' ');
      IF (Pos(SubMenuStart,InLin) <> 0) AND (NoMenuItems < MaxMenuItems) THEN
       BEGIN
        { SubMenu }
        Inc(NoMenuItems);
        { There Should be enough heap as an allowance is made when }
        { Parent Menu Item is allocated                            }
        NEW(MPtr^.MenuList[NoMenuItems]);
        Dec(SubMenuNo);
        MPtr^.MenuEvent[NoMenuItems] := SubMenuNo;
        IF InLin[11] = 'Y' THEN MPtr^.MenuGray[NoMenuItems] := TRUE
        ELSE MPtr^.MenuGray[NoMenuItems] := FALSE;
        MPtr^.Menulist[NoMenuItems]^  := COPY(InLin,19,30);
        IF (Pos('@',MPtr^.menulist[NoMenuItems]^) <> 0) AND NOT MPtr^.MenuGray[NoMenuItems] THEN
         BEGIN
          IF ORD(MPtr^.MenuList[NoMenuItems]^[0])-1 > MaxWidth THEN
           MaxWidth := ORD(MPtr^.MenuList[NoMenuItems]^[0])-1;
	  MPtr^.Menukey[NoMenuItems] := MPtr^.Menulist[NoMenuItems]^[Pos('@',MPtr^.menulist[NoMenuItems]^)+1];
         END
        ELSE
         BEGIN
          IF ORD(MPtr^.MenuList[NoMenuItems]^[0]) > MaxWidth THEN
            MaxWidth := ORD(MPtr^.MenuList[NoMenuItems]^[0]);
          MPtr^.Menukey[NoMenuItems] := ' ';
         END;
        NewSubMenu := GetMenu(SubMenuNo,TRUE);
        IF NewSubMenu <> NIL THEN
         BEGIN
          WITH NewSubMenu^ DO
	   BEGIN
            FOR ItemNo := 1 TO MaxMenuItems DO
             BEGIN
              MenuList[ItemNo] := NIL;           {Init Menu Item Text Ptr's }
             END;
            SubMenu := TRUE;
            Down    := FALSE;
            key     := MPtr^.MenuKey[NoMenuItems];
            X       := 0; { Not Used }
            Y       := 0; { Not Used }
            TitleEnd:= MPtr^.MenuList[NoMenuItems]^;
            VAL(COPY(InLin,13,2),x1,Check);
            VAL(COPY(InLin,16,2),y1,Check);
            NB  := MPtr^.NB;     {  From Parent }
            Lof := MPtr^.Lof;    {  From Parent }
            HiF := MPtr^.HiF;    {  From Parent }
            RB  := MPtr^.RB;     {  From Parent }
            RF  := MPtr^.RF;     {  From Parent }
	    CurrentSel := 1;
            no := ReadMenuItems(NewSubMenu,SubWid);
            y2 := y1 + no + 1;
            x2 := x1 + SubWid + 2;
            AdjustMenuOverFlow(NewSubMenu);
           END;
         END;
        InLin := '';
       END
      ELSE IF (Pos(MenuEnd,InLin) = 0) AND (NoMenuItems < MaxMenuItems) THEN
       BEGIN
        { Menu Item }
	Inc(NoMenuItems);
        { There Should be enough heap as an allowance is made when }
        { Parent Menu Item is allocated                            }
        NEW(MPtr^.MenuList[NoMenuItems]);
        VAL(COPY(InLin,1,4),MPtr^.MenuEvent[NoMenuItems],ErrInt);
        MPtr^.menulist[NoMenuItems]^ := COPY(InLin,8,30);
        IF InLin[6] = 'Y' THEN MPtr^.MenuGray[NoMenuItems] := TRUE
        ELSE MPtr^.menuGray[NoMenuItems] := FALSE;
        MPtr^.menukey[NoMenuItems] := ' ';
        IF (Pos('@',MPtr^.menulist[NoMenuItems]^) <> 0) AND NOT MPtr^.MenuGray[NoMenuItems] THEN
         BEGIN
          MPtr^.Menukey[NoMenuItems] := MPtr^.Menulist[NoMenuItems]^[Pos('@',MPtr^.menulist[NoMenuItems]^)+1];
          IF ORD(MPtr^.MenuList[NoMenuItems]^[0])-1 > MaxWidth THEN
           MaxWidth := ORD(MPtr^.MenuList[NoMenuItems]^[0])-1;
         END
        ELSE
         BEGIN
          IF ORD(MPtr^.MenuList[NoMenuItems]^[0]) > MaxWidth THEN
	   MaxWidth := ORD(MPtr^.MenuList[NoMenuItems]^[0]);
         END;
       END;
     END;
(*    IF (NoMenuItems > 0) THEN
     BEGIN
      { Set Current Selection }
      FOR ErrInt := 1 TO  NoMenuItems DO
       IF NOT MPtr^.MenuGray[ErrInt] AND
          (MPtr^.MenuList[ErrInt]^[1] <> '-') AND
          (MPtr^.CurrentSel = 0) THEN MPtr^.CurrentSel := ErrInt;
     END;*)
    ReadMenuItems := NoMenuItems;
   END;


BEGIN
  MenuNo := 0; Options := 0; SubMenuNo := 0;
  Assign(TheFile,MENU_NAME);
  {$I-}
  Reset(TheFile);
  {$I+}
  IF IOResult = 0 THEN
   BEGIN
    REPEAT
     REPEAT
      ReadLn(TheFile,InLin);
      Strip_Leading_Char(InLin,ORD(InLin[0]),' ');
     UNTIL (Pos(MenuStart,Inlin) <> 0) OR (InLin[1]='Q') OR (EOF(TheFile));
     IF (Pos(MenuStart,InLin) <> 0) THEN
      BEGIN
       Inc(MenuNo);
       PullDown_State := GetMenu(MenuNo,TRUE);
       IF PullDown_State <> NIL THEN
        BEGIN
         WITH PullDown_State^ DO
          BEGIN
           FOR DumInt := 1 TO MaxMenuItems DO
            BEGIN
             MenuList[DumInt] := NIL;           {Init Menu Item Text Ptr's }
            END;
           SubMenu := FALSE;
	   Down    := FALSE;
           key     := Inlin[44];
           VAL(COPY(InLin,12,2),x,Check);
           VAL(COPY(InLin,15,2),y,Check);
           TitleEnd:=COPY(InLin,46,10);
           VAL(COPY(InLin,18,2),x1,Check);
           VAL(COPY(InLin,21,2),y1,Check);
           VAL(COPY(InLin,24,3),NB,Check);
           VAL(COPY(InLin,28,3),Lof,Check);
           VAL(COPY(InLin,32,3),HiF,Check);
           VAL(COPY(InLin,36,3),RB,Check);
           VAL(COPY(InLin,40,3),RF,Check);
           CurrentSel := 1;
           no := ReadMenuItems(PullDown_State,MenuWid);
           y2 := y1 + no + 1;
           x2 := x1 + MenuWid + 2;
           AdjustMenuOverFlow(PullDown_State);
           ShowOpt(MenuNo);
	  END;
        END;                               { END (IF Pulldown_State <> NIL) }
      END
     ELSE {InLin[1] = 'Q' OR Quick Key}
      BEGIN
       VAL(COPY(InLin,3,2),QuickPos,DumInt);
       IF (QuickPos >= 1) AND (QuickPos <= 20) THEN
        BEGIN
         VAL(COPY(InLin,6,4),Fast_Keys[QuickPos].Event,DumInt);
         Fast_Keys[QuickPos].Used := TRUE;
        END;
      END;
   UNTIL (EOF(TheFile));
   Close(TheFile);

   {this determines the position of the sub menu types at run time }
   {This now deals with cases where the sub menu on the right side }
   {Of the main menu would go of the screen                        }

   TempPPs:=FirstPullDown;
   While TempPPS<>Nil DO
   BEGIN
    For dumInt:=1 to TempPPs^.no do
     begin
      if TempPPS^.MenuEvent[dumint]<0 then
       begin
	TempSubPPS := GetMenu(TempPPS^.MenuEvent[dumint],FALSE);
	MenuWid:=TempSubPPS^.x2-TempSubPPS^.x1;
	IF (TempPPS^.x2+1+MenuWid<80) then
	 BEGIN
	  TempSubPPs^.x1:=TempPPs^.x2+1;
          TempSubPPs^.x2:=TempSubPPs^.x1+MenuWid;
         END
        ELSE
         BEGIN
          TempSubPPs^.x2:=TempPPs^.x1-1;
          TempSubPPs^.x1:=TempSubPPs^.x2-MenuWid;
         END;
       END;
     END;
    TempPPS:=TempPPS^.Next;
   END;

   GrayMenu;

   IF MenuNo > 0 THEN
    BEGIN
     ShowOpt(1);
     Set_Pulldown := TRUE;
    END
   ELSE
    BEGIN
     Disp_Error_Msg('Unable To Read Menus - Check Menu File');
     Set_PullDown:= FALSE;
    END;
   Options := Options + MenuNo;
  END
 ELSE
  BEGIN
   Disp_Error_Msg('Menu Text File Not Found');
   Set_PullDown := FALSE;
  END;
END;

PROCEDURE Dispose_Menus;
VAR NextPtr,WrkPtr : PPS_Type;
    ItemIdx        : INTEGER;
BEGIN
 WrkPtr := FirstPulldown;
 WHILE (WrkPtr <> NIL) DO
  BEGIN
   NextPtr := WrkPtr^.Next;
   FOR ItemIdx :=1 TO MaxMenuItems DO
    BEGIN                                          { Dispose Menu Item Text }
     IF WrkPtr^.MenuList[ItemIdx] <> NIL THEN
      BEGIN
       Dispose(WrkPtr^.MenuList[ItemIdx])
      END;
    END;
   Dispose(WrkPtr);                                { Dispose Menu List Item }
   WrkPtr := NextPtr;                              { Next Menu              }
  END;
END;


FUNCTION ExecMenu(VAR TheMenu : TPS_Type) : INTEGER;
VAR CloseMenu      : BOOLEAN;
    dumInt         : INTEGER;
    HoldWin        : WindowRecord;
    HoldWinSet     : BOOLEAN;
    HoldCurrent    : Integer;
    HoldMenuPtr    : PPS_Type;
    KeyIndex       : INTEGER;
    TheSelection   : INTEGER;
    KeyLoop        : INTEGER;
    AltLoop        : INTEGER;
BEGIN
 CloseMenu := FALSE;
 REPEAT
  IF Key = #0 THEN key := Upcase(GetKey);
  IF FuncKey THEN
   BEGIN
    CASE key OF

     CU_Left : BEGIN
                IF WinSet THEN LoseWindow(OptWin);
                WinSet    := FALSE;
                ExecMenu  := -1;
                CloseMenu := TRUE;
                Key       := #0;
               END;

     CU_Right: BEGIN
                IF WinSet THEN LoseWindow(OptWin);
                WinSet    := FALSE;
                ExecMenu  := 1;
                CloseMenu := TRUE;
                Key       := #0;
               END;

     NEXT    : BEGIN
                IF NOT WinSet AND (TheMenu.No > 0) THEN
                 BEGIN
                  TheMenu.down := TRUE;
                  ShowOpt(Current_Option);
                 END
                ELSE
                 BEGIN
                  WITH TheMenu DO
                   BEGIN
                    HoldCurrent := CurrentSel;
                    REPEAT
                     INC(CurrentSel);
                     IF CurrentSel > No THEN CurrentSel := 1;
                    UNTIL (menulist[CurrentSel]^[1] <> '-');
                    DispMenuTxt(Current_Option,HoldCurrent);
                    DispMenuTxt(Current_Option,CurrentSel);
                   END;
                 END;
                Key := #0;
               END;

     PREV    : BEGIN
                IF WinSet THEN
                 BEGIN
                  WITH TheMenu DO
                   BEGIN
                    HoldCurrent := CurrentSel;
                    REPEAT
                     DEC(CurrentSel);
                     IF CurrentSel = 0 THEN CurrentSel := No;
                    UNTIL (menulist[CurrentSel]^[1] <> '-');
                    DispMenuTxt(Current_Option,HoldCurrent);
                    DispMenuTxt(Current_Option,CurrentSel);
                   END;
                 END;
                Key := #0;
               END;
    END;
    IF ((Key >= FN_F1) AND (Key <= FN_F10)) OR
       ((Key >= #84)   AND (KEY <= #93)) THEN
     BEGIN
      {Fast Key Pressed}
      IF (Key >= #84) AND (KEY <= #93) THEN KeyIndex := (ORD(Key) - 73)
      ELSE KeyIndex := (ORD(Key) - 58);
      Key := #0;
      IF Fast_Keys[KeyIndex].Used THEN
       BEGIN
        IF (Fast_Keys[keyIndex].Event <> 0) THEN
         BEGIN
          ExecEvent(Fast_Keys[KeyIndex].Event);
         END
        ELSE
         BEGIN
          IF WinSet THEN LoseWindow(OptWin);
          WinSet := FALSE;
          CloseMenu := TRUE;
          ExecMenu := 0;
          esc_Flag := TRUE;
         END;
       END;
     END
    ELSE IF (Key > #15) AND (Key < #51) THEN
     FOR AltLoop := 1 TO Options DO
      BEGIN
       Pulldown_State := GetMenu(AltLoop,FALSE);

       IF NOT Pulldown_State^.SubMenu AND
          (AltKeys[ORD(UPCASE(Pulldown_State^.Key))] = Key) THEN
        BEGIN
         Pulldown_State^.down := TRUE;
         HoldCurrent := Current_Option;
         Current_Option := AltLoop;
         IF WinSet THEN LoseWindow(OptWin);
         WinSet := FALSE;
         ShowOpt(HoldCurrent);
         ExecMenu := 0;
         CloseMenu := TRUE;
         Break;
        END;
      END;
     IF NOT CloseMenu THEN Key :=#0;
   END
  ELSE IF Key = ESC THEN
   BEGIN
    Key := #0;
    IF  WinSet THEN
     BEGIN
      TheMenu.down := FALSE;
      LoseWindow(OptWin);
      WinSet := FALSE;
      CloseMenu := TRUE;
      ExecMenu := 0;
     END;
   END
  ELSE IF TheMenu.down THEN
   BEGIN
    HoldCurrent := TheMenu.CurrentSel;
    TheSelection := -1;
    IF Key = CR THEN TheSelection := TheMenu.CurrentSel;
    FOR KeyLoop := 1 TO TheMenu.no DO
     IF (UPCASE(key) = UPCASE(TheMenu.Menukey[Keyloop])) AND
        (TheMenu.Menukey[Keyloop] <> ' ') THEN TheSelection := KeyLoop;
    Key := #0;
    IF TheSelection > 0 THEN
     BEGIN
      TheMenu.CurrentSel := TheSelection;
      DispMenuTxt(Current_Option,HoldCurrent);
      DispMenuTxt(Current_Option,TheMenu.CurrentSel);
      IF (TheMenu.menuEvent[TheSelection] > 0) THEN
       BEGIN
        IF (NOT TheMenu.MenuGray[TheSelection]) THEN
         ExecEvent(TheMenu.menuEvent[TheSelection]);
       END
      ELSE IF TheMenu.menuEvent[TheSelection] = 0 THEN
       BEGIN
        IF WinSet THEN LoseWindow(OptWin);
        WinSet := FALSE;
        CloseMenu := TRUE;
        ExecMenu := 0;
        esc_Flag := TRUE;
       END
      ELSE
       BEGIN
        HoldWin := OptWin;
        HoldWinSet := WinSet;
        HoldCurrent := Current_Option;
        HoldMenuPtr := Pulldown_State;
        WinSet := FALSE;
        WITH TheMenu DO
         BEGIN
          Pulldown_State := GetMenu(MenuEvent[TheSelection],FALSE);
          Pulldown_State^.down := TRUE;
          Current_Option := MenuEvent[TheSelection];
          ShowOpt(MenuEvent[TheSelection]);
          DumInt := ExecMenu(Pulldown_State^)
         END;
        Current_Option := HoldCurrent;
        Pulldown_State := HoldMenuPtr;
        WinSet := HoldWinSet;
        OptWin := HoldWin;
        Esc_Flag := FALSE;
       END;
     END;
   END
  ELSE IF (key = ENTER) AND NOT WinSet AND (TheMenu.No > 0) THEN
   BEGIN
    TheMenu.down := TRUE;
    ShowOpt(Current_Option);
    Key:= ' ';
   END
  ELSE Key := #0;
 UNTIL CloseMenu;
END;

PROCEDURE Display_Banner;
CONST XOFS  = 15;
      YOFS  = 7;
VAR BannerStr : STRING[24];
    Xpos      : INTEGER;
    OldAttr   : BYTE;
BEGIN
  BannerStr := Stripped(Config_Rec^.Conf_Banner,24,' ');
  Xpos := 25-(length(BannerStr) DIV 2);
  GOTOXY(XOFS+Xpos,YOFS); Write(Config_Rec^.Conf_Banner);
END;


PROCEDURE Pulldown_Menus;
VAR ClearQuick     : INTEGER;
    BuildStr       : STRING[11];
    S,S100         : WORD;
BEGIN
 CursorOff; FirstPulldown := NIL;
 FillScreen(TRUE);
 Display_Banner;
 Current_Option := 1;  WinSet  := FALSE;
 esc_Flag       := FALSE;
 FillChar(Fast_Keys,SizeOf(Fast_Keys),#0);
 Set_Colours(LightGray,Black,Yellow,Green,Red);
 IF Set_Pulldown THEN
  BEGIN
   REPEAT
    Key := #0;
    Pulldown_State := GetMenu(Current_Option,FALSE);
    Inc_Option     := ExecMenu(Pulldown_State^);
    Old_Option     := Current_Option;
    REPEAT
     Current_Option := Current_Option + Inc_Option;
     IF Current_option > options THEN Current_Option := 1;
     IF Current_Option = 0 THEN Current_Option := Options;
     Pulldown_State := GetMenu(Current_Option,FALSE);
    UNTIL NOT Pulldown_State^.SubMenu;
    ShowOpt(Old_Option);
    ShowOpt(Current_Option);
    IF esc_Flag THEN
     BEGIN
      IF PROP_Colour THEN SetWindow (28,10,52,13,TRUE,$1b,$1b,Entry_Window)
      ELSE SetWindow(28,10,52,13,TRUE,$0F,$0F,Entry_Window);
      GotoXY (10,1);
      TextAttr := TextAttr + 128;
      Write ('QUIT');
      TextAttr := TextAttr - 128;
      GoToXY (4,2);
      Write ('ARE YOU SURE (Y/N)');
      BuildStr := '';
      REPEAT
       key := UpCase(GetKey);
       BuildStr := BuildStr + Key;
      UNTIL key IN['Y','N'];
      IF BuildStr <> 'SUPERVISORY' THEN
       BEGIN
        IF key = 'Y' THEN
          esc_Flag := TRUE
        ELSE
          esc_Flag := FALSE;
       END
      ELSE
       BEGIN
        esc_Flag := FALSE;
        GetRTCTime(UnlockH,UnlockM,S,S100);
        GetRTCDate(UnlockY,UnlockMo,UnlockD);
       END;
      Key := #0;
      LoseWindow (Entry_Window);
     END;
   UNTIL esc_Flag;
  IF OptWin.buf_ptr <> NIL THEN LoseWindow(OptWin);
  Dispose_Menus;
  WHILE BiosKeyPressed DO ReadBiosKey;
  END;
 TextAttr :=$07;
 ClrScr;
 CursorON;
END;

END.

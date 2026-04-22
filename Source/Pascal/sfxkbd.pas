UNIT SFXKbd;
{$O+,F+}
{$I F6COMP}
INTERFACE
USES F6StdUtl,SFXStd,SFXGraph,SFXBtn,F6StdCtv,FXStdUt1,FXModCtv,
     SFXMsg,FXDetail,SFXFont,FXFUsers,F6StdWn1,SFXUtils;


PROCEDURE ShowKbd;
PROCEDURE LoseKbd;

CONST KeyWidth      = 51;
CONST KeyHeight     = 40;
CONST KbdXOffset    = 4;
CONST KbdYOffset    = MaxY-12-KeyHeight*4;
CONST KbdMaxX       = KbdXOffset+KeyWidth*9;
CONST SubKbdXOffset = KbdXOffset+KeyWidth*9+8;
CONST SubKbdMaxX    = SubKbdXOffset+KeyWidth*3;


TYPE
    PKeyBoardBtn = ^TKeyBoardBtn;
    TKeyBoardBtn = OBJECT(TButtonWindow)
     TimeLastDown : LONGINT;
     AlphaKbd     : BOOLEAN;
    PRIVATE
     Key            : INTEGER; { key numerical posn }
     AlphaStartChar : CHAR;    { NOTE when = ! then '/' key is replaced by '\' }
    PUBLIC
     CONSTRUCTOR Init;
     FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
     PROCEDURE   Draw;VIRTUAL;
     PROCEDURE   ButtonDown; VIRTUAL;
     PROCEDURE   WhileButtonDown(X,Y : INTEGER);VIRTUAL;
    END;


CONST AlphaKeyBoard   : PKeyBoardBtn = NIL;

IMPLEMENTATION
USES SFXScale,SFXCOLR;

CONST TextYPos      = MaxTextY - 1 - (KeyHeight DIV 8)*4;
CONST TextKbdXPos   = 2;
CONST TextNumXPos   = SubKbdXOffset DIV 8+2;

CONST NumAlphaKeys  = 3;

      ScaleWasShowing : BOOLEAN = FALSE;
      KeyboardRefCnt  : INTEGER = 0;
VAR
      PreKeyMsgWinState : TMsgWinState;


CONSTRUCTOR TKeyBoardBtn.Init;
BEGIN
 TimeLastDown := 0;
 AlphaStartChar := 'A';
{ COLOURS YET TO BE COMPLETED}
 INHERITED Init(KbdXOffset,KbdYOffSet,MaxX-13,MaxY-11,
                C_WindowStaticText SHR 4,
                WT_Visable);
END;

PROCEDURE TKeyBoardBtn.ButtonDown;
BEGIN
 INHERITED ButtonDown;
 TimeLastDown := GetTickCount-10;
END;

PROCEDURE TKeyBoardBtn.WhileButtonDown(X,Y : INTEGER);
CONST NumerKeyPad : ARRAY[0..3,0..2] OF CHAR = (('9','8','7'),
                                                ('6','5','4'),
                                                ('3','2','1'),
                                                ('0',BS,HOME));
VAR BoxSelX,BoxSelY : INTEGER;
    Ch              : CHAR;
    HoldFont        : PFontType;
    Ticks           : LONGINT;
    ScanCode        : WORD;
BEGIN
 INHERITED WhileButtonDown(X,Y);
 Ticks := GetTickCount;
 IF (Abs(Ticks-TimeLastDown) < 9) THEN EXIT;
 TimeLastDown := Ticks;
 Funckey := FALSE;
 IF X<SubKbdXOffset THEN
  BEGIN
   IF X>KbdMaxX THEN EXIT;
   BoxSelX := (X-KbdXOffset) DIV KeyWidth;
   AlphaKbd := TRUE;
  END
 ELSE
  BEGIN
   BoxSelX := (X-SubKbdXOffset) DIV KeyWidth;
   AlphaKbd := FALSE;
  END;
 BoxSelY := (Y-KbdYOffset) DIV KeyHeight;
 IF BoxSelY<4 THEN
  BEGIN
   IF AlphaKBd THEN
    BEGIN
     IF (BoxSelX = 0) AND (BoxSelY = 3) THEN { change char set }
      BEGIN
       CASE AlphaStartChar OF
         'A' : AlphaStartChar := 'a';
         'a' : AlphaStartChar := '!';
         ELSE  AlphaStartChar := 'A';
        END;
       Draw;
      END
     ELSE IF BoxSelX<9 THEN
      BEGIN
       IF BoxSelY = 3 THEN
         Ch := #32
       ELSE
        BEGIN
         Key := (BoxSelY)*9+BoxSelX;
         IF Key<>26 THEN
          BEGIN
           Ch := Chr(ORD(AlphaStartChar)+Key);
           IF Ch = '/' THEN Ch := '\';
          END
         ELSE Ch := CR;
        END;
       IF (ch <> CR) THEN LastKeysPressed.AddCharacterCode(ORD(CH));
      END;
    END
   ELSE
    BEGIN
     IF BoxSelX <3 THEN
      BEGIN
       CH :=NumerKeyPad[BoxSelY,BoxSelX];
       IF Ch <> #0 THEN
        BEGIN
         ScanCode := ORD(CH);
         IF CH IN [HOME] THEN
          BEGIN
           ScanCode := ScanCode SHL 8; { ideally FKEYCNST should define it }
           {Funckey := TRUE;}
          END;
         LastKeysPressed.AddCharacterCode(ScanCode);
        END;
      END;
    END;
  END;
END;


FUNCTION TKeyBoardBtn.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 IF (Key = 26) AND AlphaKbd THEN
  BEGIN
   UserActivateFunction := TRUE;
   LastKeysPressed.AddCharacterCode(ORD(CR));
  END
 ELSE UserActivateFunction := FALSE;
END;


PROCEDURE TKeyBoardBtn.Draw;
VAR
    i,j        : INTEGER;
    tempfont   : INTEGER;
    CH         : CHAR;
    Row,
    Column     : INTEGER;
    Xpos,YPos  : INTEGER;
    HoldFont   : PFontType;
    SaveCol    : BYTE;
    Depth      : INTEGER;
BEGIN
 HoldFont := SetCurrentFont(KeyBoardNormal);
 Ch:=AlphaStartChar;
 FOR Row:=0 TO 4 DO
  BEGIN
   DrawlineHORIZ(KbdXOffset,KbdXOffset+9*KeyWidth+2,KbdYOffset+Row*KeyHeight,1);
   DrawLineHoriz(KbdXOffset,KbdXOffset+9*KeyWidth+2,KbdYOffset+Row*KeyHeight+1,1);
  END;
 FOR Column := 1 TO 8 DO
  BEGIN
   IF Column = 1 THEN
     Depth := 4*KeyHeight
   ELSE
     Depth := 3*KeyHeight;
   DrawlineVert(KbdXOffset+Column*KeyWidth,KbdYOffset,KbdYOffset+Depth,1);
   DrawlineVert(KbdXOffset+Column*KeyWidth+1,KbdYOffset,KbdYOffset+Depth,1);
  END;
 DrawlineVert(KbdXOffset,KbdYOffset,KbdYOffset+4*KeyHeight,1);
 DrawlineVert(KbdXOffset,KbdYOffset,KbdYOffset+4*KeyHeight,1);
 DrawlineVert(KbdXOffset+9*KeyWidth,KbdYOffset,KbdYOffset+4*KeyHeight,1);
 DrawlineVert(KbdXOffset+9*KeyWidth+1,KbdYOffset,KbdYOffset+4*KeyHeight,1);


 WITH CurrFontBitMap^ DO
  BEGIN
   YPos := TextYPos*8;
   FOR j:=0 to 2 do
    BEGIN
     XPos := TextKbdXPos*8;
     FOR i:=0 to 8 do
      BEGIN
       if (ch<>#91) THEN
        BEGIN
         IF ch = '/' THEN { backslash is more usefull }
           WriteColourCharAt(XPos,YPos,'\',C_WindowStaticText AND $0F,BackColour)
         ELSE
           WriteColourCharAt(XPos,YPos,ch,C_WindowStaticText AND $0F,BackColour);
        END;
       INC(XPos,(FontWidth+2)*8+3);
       INC(Ch);
      END;
     INC(YPos,BitMapHeight+8)
    END;

   XPos := TextKbdXPos*8; { do "shift" char in bottom left corner }
   WriteColourCharAt(Xpos,Ypos,#24{up arrow},C_WindowStaticText AND $0F,BackColour)
  END;

 FOR Row:=0 TO 4 DO
  BEGIN
   DrawlineHoriz(SubKbdXOffset,SubKbdXOffset+NumAlphaKeys*KeyWidth+2,KbdYOffset+Row*KeyHeight,1);
   DrawlineHoriz(SubKbdXOffset,SubKbdXOffset+NumAlphaKeys*KeyWidth+2,KbdYOffset+Row*KeyHeight+1,1);
  END;
 FOR Column := 0 TO NumAlphaKeys DO
  BEGIN
   DrawlineVert(SubKbdXOffset+Column*KeyWidth,KbdYOffset,KbdYOffset+4*KeyHeight,1);
   DrawlineVert(SubKbdXOffset+Column*KeyWidth+1,KbdYOffset,KbdYOffset+4*KeyHeight,1);
  END;

 WITH CurrFontBitMap^ DO
  BEGIN
   YPos := TextYPos*8;
   Ch := '9';
   for j:=0 to 3 do
    BEGIN
     XPos := TextNumXPos*8;
     for i:=0 to 2 do
      BEGIN

       IF (ch>='0') THEN WriteColourCharAt(Xpos,Ypos,ch,C_WindowStaticText AND $0F,BackColour)
     {  if (ch>='0') THEN WriteStrAtPixel(XPos,YPos,ch)}
       else break;
       DEC(ch);
       INC(XPos,(FontWidth+2)*8+3);
      END;
     INC(YPos,BitMapHeight+8);
    END;
  END;

 SetCurrentFont(DoubleHeightFont);
 WITH KeyBoardNormal^ DO
  BEGIN
   SaveCol := SetTextColour(C_WindowStaticText);
   WriteStrAt(TextNumXPos+1*(Fontwidth+2),TextYPos+3*((BitMapHeight DIV 8)+1),'Del');
   WriteStrAt(TextNumXPos+2*(Fontwidth+2),TextYPos+3*((BitMapHeight DIV 8)+1),'Clear');
   WriteStrAtPixel(8*(TextKbdXPos+8*(FontWidth+2)+2),(TextYPos*8+2*(BitMapHeight+8)),'Enter');
   WriteStrAt(TextKbdXPos+(3*8+4),TextYPos+3*(BitMapHeight DIV 8+1),'SPACE');
   SetTextColour(SaveCol);
  END;
 SetCurrentFont(HoldFont);
END;

PROCEDURE ShowKbd;
BEGIN
 Inc(KeyboardRefCnt);
 IF AlphaKeyBoard = NIL THEN
  BEGIN
{   MessageWin.DisableMsgs(@PreKeyMsgWinState);}
   ScaleWasShowing := ScaleWindow^.IsWindowVisable;
   IF ScaleWasShowing THEN ScaleWindow^.HideWindow;
   New(AlphaKeyBoard,Init);
  END;
END;

PROCEDURE LoseKbd;
BEGIN
 IF KeyboardRefCnt > 0 THEN
   Dec(KeyboardRefCnt);
 IF (KeyboardRefCnt = 0) AND (AlphaKeyBoard <> NIL) THEN
  BEGIN
   DISPOSE(AlphaKeyBoard,Done);
   AlphaKeyBoard := NIL;
   IF ScaleWasShowing THEN ScaleWindow^.ShowWindow;
{   MessageWin.RestoreMsgState(@PreKeyMsgWinState);}
  END;
END;

END.
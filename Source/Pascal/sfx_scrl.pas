(****************************************************************************
*  UNIT          : SFX_Scrl                                                 *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix scroll box routines                         *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFX_SCRL;

INTERFACE
USES SFXBtn,SFXGraph,SFxStd,SFXCurr,SfxConst,SFXOList,FXFWork,SFXFont,SFXMsg,
     F6StdUtl,F6StdCtv,FxModCtv,SFX_Main,SFXScale,SFXMixes,FXFTrn,FXDetail,
     F6StdWn1,SFXKbd,FXCfg,SFXDate;

CONST BlankListStr:STRING[19]='                  ';


TYPE  PListAreas = ^TListAreas;
      TListAreas = OBJECT(TButtonWindow)
       OrdAdj  : INTEGER;
       LineList: BOOLEAN;
       ArrowDirection : TArrowDirection;
       CONSTRUCTOR Init(X1,y1,x2,y2 :INTEGER;
                        Dir : TArrowDirection);
       DESTRUCTOR  Done;VIRTUAL;
       FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
       PROCEDURE   Draw;VIRTUAL;
      END;


TYPE  PScrollerWindows = ^TScrollerWindows;
      TScrollerWindows =OBJECT(TButtonWindow)
       LineNumberHighlighted : INTEGER;    {Line Number of box highlighted}
       BoxHighLighted        : INTEGER;    {number of hightlighted box on screen}
       LineScroller          : BOOLEAN;
       ScrollerWindowsShown  : BOOLEAN;
       Horizontal            : BOOLEAN;
       NUMBOXES : INTEGER;
       BOXWIDTH : INTEGER;
       ColTextWidth : INTEGER; { where box is sub divided into columns }
       BoxHeight: INTEGER;

       CONSTRUCTOR Init(LX,TY,RX,BY : INTEGER;
                        Line : BOOLEAN;
                        NoOfBoxes : INTEGER);
       DESTRUCTOR  Done;VIRTUAL;

       FUNCTION  BoxLX(BoxNo : INTEGER) : INTEGER;
       FUNCTION  BoxTY(BoxNo : INTEGER) : INTEGER;
       FUNCTION  UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
       FUNCTION  SelectOrderViaMixLabelBarcode(Barcode : STRING) : BOOLEAN;
       PROCEDURE Draw;VIRTUAL;
       PROCEDURE ResetHighBar(NumHigh : INTEGER);
       PROCEDURE UnHighLightBox;
       PROCEDURE HighLightBox;
       PROCEDURE WriteBoxText(BoxNo   : INTEGER;
                              Rec     : PListDisplayRec;
                              FGC,BGC : BYTE);
       PROCEDURE WriteScrollerText(DisplayPos : INTEGER);

       PROCEDURE ShowOrderLineNo(OrderLineNo : LONGINT);
                 { Calls WriteScrollerText but with a list offset
                   to make sure OrderLineNo is visible }

       PROCEDURE HighLightBoxAt(LineHigh,BoxHigh : INTEGER);
      END;

VAR ScrollerWindows   : PScrollerWindows;
    ListBoxLeft       : PListAreas;
    ListBoxRight      : PListAreas;

PROCEDURE SetUpScrollerWindows(LineWin : BOOLEAN);
(*
PROCEDURE ShowHeaderAndLineDetails(AnErrorOccured : BOOLEAN);
*)

IMPLEMENTATION
USES SFXCOLR;

CONST
      BOXTEXTLEFT = 8;  { graphical offset }
      BOXTEXTTOP  = 8;  { graphical offset }


{============================TListArea Methods==============================}
DESTRUCTOR TListAreas.Done;
BEGIN
 INHERITED Done;
END;

PROCEDURE TListAreas.Draw;
VAR LineStyle : BYTE;
BEGIN
 INHERITED Draw;
 IF (GetWindowFlags AND WT_NonSelectable) = WT_NonSelectable THEN
  BEGIN
   ClearWindow;
   LineStyle := 5;
  END
 ELSE LineStyle := 0;

 SetLineStyle(LineStyle);
 BorderDraw;
 SetLineStyle(LineStyle);

 WITH Bounds DO
   DrawArrow(ArrowDirection,Left,Top,Right,Bottom);
 SetLineStyle(0);
END;

FUNCTION TListAreas.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 INC(DisplayRecListpos,OrdAdj*(ScrollerWindows^.NUMBOXES-1));

 IF OrdAdj > 0 THEN
  BEGIN
   IF (DisplayRecListPos + ScrollerWindows^.NUMBOXES) > DisplayRecListSize THEN
     DisplayRecListPos := DisplayRecListSize-ScrollerWindows^.NUMBOXES;
  END
 ELSE
  BEGIN
   IF (DisplayRecListPos < 0) THEN
     DisplayRecListPos := 0;
  END;

 IF DisplayRecListPos < DisplayRecListSize THEN { something to show }
   ScrollerWindows^.WriteScrollerText(DisplayRecListPos);
 Draw;
 UserActivateFunction := FALSE;
END;

CONSTRUCTOR TListAreas.Init(X1,y1,x2,y2 :INTEGER; Dir : TArrowDirection);
BEGIN
 ArrowDirection := Dir;
 IF ArrowDirection IN [ArrowRight,ArrowDown] THEN
   OrdAdj := 1
 ELSE
   OrdAdj := -1;
 INHERITED Init(x1,y1,x2,y2,C_TextButton SHR 4,StdBtn);
(*
 WITH Bounds DO
  BEGIN
   IF ORdAdj = 1 THEN
     DrawArrow(ArrowRight,Left,Top,Right,Bottom)
   ELSE
     DrawArrow(ArrowLeft,Left,Top,Right,Bottom);
  END;
*)
END;


{=====================   TSCROLLER METHODS ========================}
CONSTRUCTOR TScrollerWindows.Init(LX,TY,RX,BY : INTEGER;
                                  Line : BOOLEAN;
                                  NoOfBoxes : INTEGER);
BEGIN
 ScrollerWindowsShown  := FALSE;
 LineScroller          := Line;
 BoxHighLighted        := 0;
 LineNumberHighlighted := 0;
 Horizontal := Line;
 NUMBOXES  := NoOfBoxes;
 IF Horizontal THEN
  BEGIN
   BoxWidth  := (RX+1-LX) DIV NumBoxes;
   ColTextWidth := (BoxWidth - 2*BOXTEXTLEFT) DIV 8;
   BoxHeight := BY - TY;
   RX := LX + NumBoxes * BoxWidth; { reset total width to match boxes }
  END
 ELSE
  BEGIN
   BoxWidth := RX-LX;
   ColTextWidth := (BoxWidth - 2*BOXTEXTLEFT) DIV 8;
   BoxHeight:= (BY+1-TY) DIV NumBoxes;
   BY := TY + NumBoxes * BoxHeight -1; { reset total height to match boxes }
  END;

 INHERITED Init(LX, TY, RX, BY,
                C_PickListNormal SHR 4,StdWin);

 IF Line THEN
  BEGIN
   IF SelRecs.WorkHRecord.WOH_SeqFixed THEN
    DisableButton
   ELSE
    EnableButton;
{  DisableBtn(SelRecs.WorkHRecord.WOH_SeqFixed); }
  END;
END;

DESTRUCTOR TScrollerWindows.Done;
BEGIN
 INHERITED Done;
END;

FUNCTION TScrollerWindows.BoxLX(BoxNo : INTEGER) : INTEGER;
VAR  X : INTEGER;
BEGIN
 X := Bounds.Left;
 IF Horizontal AND (BoxNo > 1) THEN
   X := X + ((BoxNo-1) * BOXWIDTH);
 BoxLX := X;
END;

FUNCTION TScrollerWindows.BoxTY(BoxNo : INTEGER) : INTEGER;
VAR Y : INTEGER;
BEGIN
 Y := Bounds.Top;
 IF (NOT Horizontal) AND (BoxNo > 1) THEN
   Y := Y + ((BoxNo-1) * BoxHeight);
 BoxTY := Y;
END;

PROCEDURE TScrollerWindows.ResetHighBar(NumHigh : INTEGER);
BEGIN
 UnHighLightBox;
 BoxHighLighted        := 0;
 LineNumberHighlighted := NumHigh;
END;

PROCEDURE TScrollerWindows.HighlightBox;
BEGIN
 IF BoxHighLighted > 0 THEN
  HighLightWindow(BoxLX(BoxHighLighted),BoxTY(BoxHighLighted),
                  BOXWIDTH,BOXHEIGHT,ForeGround);

END;

PROCEDURE TScrollerWindows.HighLightBoxAt(LineHigh,BoxHigh : INTEGER);
BEGIN
 LineNumberHighlighted := LineHigh;
 UnHighLightBox;
 BoxHighLighted :=BoxHigh;
 HighLightBox;
END;

PROCEDURE TScrollerWindows.UnHighLightBox;
BEGIN
 IF BoxHighLighted > 0 THEN
  HighLightWindow(BoxLX(BoxHighLighted),BoxTY(BoxHighlighted),
                  BOXWIDTH,BOXHEIGHT,BackColour);
END;

PROCEDURE TScrollerWindows.WriteBoxText(BoxNo   : INTEGER;
                                        Rec     : PListDisplayRec; {nil = blank}
                                        FGC,BGC : BYTE);
VAR
  TextNo      : INTEGER;
  FontGreyed  : BOOLEAN;
  HoldFont    : PFontType;
  TextXPos,
  TextYPos    : INTEGER;
  SaveColour  : BYTE;
  LineText    : STRING[80];

    PROCEDURE WriteColStrAt(x,y : INTEGER; Str : STRING; fg,bk :BYTE);
    VAR I : INTEGER;
    BEGIN
    MoveToXy(x,y);
    IF (CurrFontBitmap=NIL) THEN SetCurrentFont(DefaultFont);
    IF (CurrFontBitMap^.fontStyle{TextDirection} AND VERT) <> 0 THEN
     BEGIN
      FOR I:=1 TO Length(str) DO
       BEGIN
        WriteColourCharAt(Currentx*8,Currenty*8,Str[i],fg,bk);
        INC(CurrentY,(CurrFontBitMap^.BitMapHeight DIV 8));
       END;
      END
     ELSE
      BEGIN
       FOR I:=1 TO Length(str) DO
        BEGIN
         WriteColourCharAt(Currentx*8,Currenty*8,Str[i],fg,bk);
         INC(Currentx,CurrFontBitMap^.Fontwidth);
        END;
      END;

     IF (CurrFontBitMap^.FontStyle{TextDirection} AND Vert) =0{ = HORIZ} THEN
      BEGIN
       IF CurrentX>79 THEN
        BEGIN
         INC(CurrentY,CurrFontBitMap^.BitMapHeight DIV 8);
         CurrentX := 0;
        END;
      END
     ELSE
      BEGIN
   {  CurrentY:=CurrentY+(CurrFontBitMap^.BitMapHeight DIV 8)*Length(Str);}
      END;
     IF CurrentY>50 THEN CurrentY := 0;
    END;

    PROCEDURE IncTextCoOrds;
    BEGIN
     TextYPos := TextYPos + 2;
    END;

BEGIN
 IF (Rec <> NIL) AND LineScroller THEN
  BEGIN
   RefreshListItemForSelOrder(Rec^); { might have just been completed }
                                     { or other users changed it      }
  END;

 HoldFont    := SetCurrentFont(RecipeNormalFont);
 FontGreyed  := FALSE;
 SaveColour  := SetTextColour(C_PickListNormal);

 IF  (Rec <> NIL)
 AND ((Rec^.Complete) OR (NOT Rec^.LDR_ThisArea)) THEN
  BEGIN
   SetCurrentFont(RecipeGreyedFont);
   FontGreyed := TRUE;
  END;

 TextXPos := (BoxLX(BoxNo)+BOXTEXTLEFT) DIV 8;
 TextYPos := (BoxTY(BoxNo)+BOXTEXTTOP) DIV 8;
 IF Horizontal THEN
  BEGIN
   FOR TextNo := 0 TO 4 DO
    BEGIN
     IF Rec = NIL THEN
      BEGIN
       WriteStrAt(TextXPos, TextYPos, BlankListStr);
      END
     ELSE
      BEGIN
       WITH Rec^ DO
        BEGIN
         IF  (TextNo = 1)
         AND NowtButSpace(TextToDisplay[2])
         AND (NOT FontGreyed) THEN
          BEGIN
           SetCurrentFont(DoubleHeightFont);
           WriteColStrAt(TextXPos, TextYPos,
                         COPY(TextToDisplay[TextNo]+SPACE_STRING,1,ColTextWidth),
                         FGC,BGC);
           SetCurrentFont(RecipeNormalFont);

           INC(TextNo);
           IncTextCoOrds;
          END
         ELSE
          BEGIN
           WriteColStrAt(TextXPos, TextYPos,
                         COPY(TextToDisplay[TextNo]+SPACE_STRING,1,ColTextWidth),
                         FGC,BGC);
          END;
        END;
      END;
     IncTextCoOrds;
    END;
  END
 ELSE { vertical scroller }
  BEGIN
   IF Rec = NIL THEN
     LineText := Space_String
   ELSE WITH Rec^ DO
     LineText := TextToDisplay[0]+'  '+
                 TextToDisplay[1]+
                 Copy(TextToDisplay[3]+Space_String,1,11)+
                 TextToDisplay[4]+Space_String;


   WriteColStrAt(TextXPos, TextYPos, Copy(LineText,1,ColTextWidth),FGC,BGC);
  END;

 SetTextColour(SaveColour);
 SetCurrentFont(HoldFont);
END;


{Draws The Scroller Window Info Along Bottom Of Screen}
PROCEDURE TScrollerWindows.WriteScrollerText(DisplayPos : INTEGER
                                             {HighLightAWindow : BOOLEAN});
{REQUIRES 1. DisplayPos to be set to order line no. required in left most
          box or set to zero.
          2. If HighLightAWindow then LineNumberHighlighted should have been
          previously initialised with ResetHighBar or HighLightBoxAt methods.
}

VAR CurrBox    : INTEGER;
    DisplayRec : PListDisplayRec;
    Loop       : INTEGER;
    HighLightAWindow : BOOLEAN;
BEGIN
 IF WorkLineFile^.OpenFile <> 0 THEN EXIT;

 IF  (NOT LineScroller) { order scroller shown }
 AND IsWindowDisabled THEN EXIT; { might have keyboard on top of scroller }

 HighLightAWindow := LineScroller;

 ScrollerWindowsShown := TRUE;
 Loop       := Displaypos;
 DisplayRec := ListHeader;
 {If Loop < 0) THEN Will not execute this loop}
 WHILE (Loop>0) AND (DisplayRec<>NIL) DO
  BEGIN
   DisplayRec := DisplayRec^.Next;
   Dec(Loop);
  END;

 IF HighLightAWindow THEN
  UnHighLightBox;

 FOR CurrBox:=1 TO NUMBOXES DO
  BEGIN
   IF Loop<0 THEN { no more items in list }
     WriteBoxText(CurrBox,NIL,C_PicklistNormal AND $0F,C_PickListNormal SHR 4)
   ELSE
    BEGIN
     IF (DisplayRec <> NIL) THEN
      BEGIN
     {  if ((DisplayRecListpos+CurrBox-1 >= 0) AND
            (DisplayRecListpos+CurrBox-1 < DisplayRecListSize)) THEN}
        BEGIN
         IF (HighLightAWindow) AND
          (DisplayRec^.Order_Line_No = LineNumberHighlighted) THEN
          BEGIN
           WriteBoxText(CurrBox,DisplayRec,C_PicklistNormal SHR 4,C_PickListNormal AND $0F);
           BoxHighLighted := CurrBox;
           HighLightBox;
          END
         ELSE WriteBoxText(CurrBox,DisplayRec,C_PicklistNormal AND $0F,C_PickListNormal SHR 4);
        END
       {ELSE WriteBlankBox};
       IF DisplayRec<>NIL THEN DisplayRec := DisplayRec^.Next;
      END
     ELSE
      WriteBoxText(CurrBox,NIL,C_PicklistNormal AND $0F,C_PickListNormal SHR 4);
    END;
   INC(Loop);
  END;
  IF (DisplayRecListPos + NUMBOXES) >= DisplayRecListSize THEN
   BEGIN
    ListBoxRight^.DisableButton;
    ListBoxRight^.Draw;
   END
  ELSE
   BEGIN
    ListBoxRight^.EnableButton;
    ListBoxRight^.Draw;
   END;
  IF (DisplayRecListPos) < 1 THEN
   BEGIN
    ListBoxLeft^.DisableButton;
    ListBoxLeft^.Draw;
   END
  ELSE
   BEGIN
    ListBoxLeft^.EnableButton;
    ListBoxLeft^.Draw;
   END;

{  ListBoxLeft^.Draw;}

 WorkLineFile^.CloseFile;
END;

PROCEDURE TScrollerWindows.ShowOrderLineNo(OrderLineNo : LONGINT);
BEGIN
 { make sure NextLineNo box is visible }
 IF (OrderLineNo - DisplayRecListPos) > NUMBOXES THEN { its off the RH edge }
   DisplayRecListPos := OrderLineNo - NUMBOXES { bring it back on RH edge }
 ELSE IF ((DisplayRecListPos+1) > OrderLineNo) THEN { its off LH edge }
   DisplayRecListPos := OrderLineNo-1; { bring it back on LH edge }

 IF DisplayRecListPos < 0 THEN { (OrderLineNo could be 0) }
   DisplayRecListPos := 0;

 ScrollerWindows^.WriteScrollerText(DisplayRecListPos);
END;

PROCEDURE TScrollerWindows.Draw;
Var Row : INTEGER;
BEGIN
 {note : outside edge is set by drawborder function}
 {vertical lines}
 IF Horizontal THEN
  BEGIN
   for Row:=2 TO NUMBOXES DO { draw left hand edges (double thickness)}
    BEGIN
     DrawLineVERT(BoxLX(Row),  BoxTY(Row),BoxTY(Row)+BOXHEIGHT,1);
     DraWLineVERT(BoxLX(Row)-1,BoxTY(Row),BoxTY(Row)+BOXHEIGHT,1);
    END;
  END
 ELSE
  BEGIN
   FOR Row := 2 TO NUMBOXES DO { draw top edges }
    BEGIN
     DrawLineHORIZ(BoxLX(Row), BoxLX(Row)+BoxWidth, BoxTY(Row), 1);
     DrawLineHORIZ(BoxLX(Row), BoxLX(Row)+BoxWidth, BoxTY(Row)-1, 1);
    END;
  END;

 IF LineScroller THEN
  BEGIN
   HighLightBox;
  END;
 IF (ScrollerWindowsShown) THEN
  BEGIN
   WriteScrollerText(DisplayRecListpos);
  END;
END;

FUNCTION TScrollerWindows.UserActivateFunction(X,Y : INTEGER):BOOLEAN;
VAR BoxSelected : INTEGER;
    ListPosCounter : INTEGER;
    LoopPtr     : PListDisplayRec;
    Dummy       : INTEGER;
    OldLineNo,
    OldBox      : LONGINT;
{    Ingredient  : STRING[11];}
    ErrMsg      : STRING[40];
    TempTran    : TTranRecord;

BEGIN
 ErrMsg := '';
 FOR BoxSelected := NUMBOXES DOWNTO 1 DO
  BEGIN
   IF (X > BoxLX(BoxSelected)) AND (Y > (BoxTY(BoxSelected))) THEN
     BREAK;
  END;

 { set pointer to related list member }
 ListPosCounter := BoxSelected-1 + DisplayRecListpos;
 LoopPtr     := ListHeader;
 WHILE (ListPosCounter >0) AND (LoopPtr<>NIL) DO
  BEGIN
   Dec(ListPosCounter);
   IF LoopPtr<>NIL THEN LoopPtr := LoopPtr^.Next;
  END;
 IF (LoopPtr <> NIL) AND (ListPosCounter >=0) THEN
  BEGIN
   IF   LineScroller  { INGREDIENT SELECTED }
   AND (NOT LoopPtr^.Complete)
   AND (LoopPtr^.LDR_ThisArea) THEN
    BEGIN
     OldLineNo := LineNumberHighlighted;
     OldBox   := BoxHighLighted;
     MessageWin.ClearMsg;
     HighLightBoxAt(LoopPtr^.Order_Line_No,BoxSelected);
     WriteScrollerText(DisplayRecListPos);

     IF NOT CanDoIngredientNow(LineNumberHighlighted) THEN
      BEGIN
       HighLightBoxAt(OldLineNo,OldBox); { So ingredient details currently
                                           displayed and timed messages
                                           reflect highlighted box }
       ShowOrderLineNo(OldLineNo);
      END

     ELSE { ingredient selected ok }
      BEGIN
       SFXSTD.NoIngredientSelected   := FALSE;
       SelRecs.LoadLineRecord(LineNumberHighLighted);
       MainWindow^.RefreshDetails(LoopPtr^.Order_Line_No);
      END;
    END
   ELSE IF (NOT LineScroller) THEN { ORDER SELECTED }
    BEGIN
     SelRecs.LoadHeaderRecord(LoopPtr^.Order_Line_No, { (holds the ord no) }
                              LoopPtr^.Revision,
                              0);
     IF TransFile^.GetTermsLastActiveTranForOrd(GetCurrentMachineID,
                                            SelRecs.WorkHRecord.WOH_OrderNo,
                                            SelRecs.WorkHRecord.WOH_Revision,
                                            TempTran) THEN
      BEGIN
       SelRecs.SetCurrentMixNoTo(TempTran.TRN_MixNo);
       SelRecs.LoadLineRecord(TempTran.TRN_OrderLineNo);
      END
     ELSE { this terminal hasnt worked on it before - try mix 1 }
      BEGIN
       SelRecs.SetCurrentMixNoTo(1);
       SelRecs.LoadLineRecord(1);
      END;

     SelRecs.ResetForNextStep(FALSE);
    END;
  END;

 IF LineScroller THEN { doesnt return TRUE ? }
   UserActivateFunction := FALSE
 ELSE
  BEGIN
   UserActivateFunction := (LoopPtr<>NIL);
(*
                       AND (ScanRelatedMixLabels(OrderMixToBarcode(
                                                      @SelRecs.WorkHRecord,
                                                      0))); { forces two scans }
*)
  END;
END;

FUNCTION TScrollerWindows.SelectOrderViaMixLabelBarcode(Barcode : STRING) : BOOLEAN;
VAR
   OrderNo,
   RevNo,
   MixNo,
   LineNo : LONGINT;
BEGIN
 SelectOrderViaMixLabelBarcode := FALSE;
 IF NOT LineScroller THEN
  BEGIN
   OrderNo := StringToLong(Copy(Barcode,1,6));
   RevNo   := StringToLong(Copy(Barcode,7,2));
   MixNo   := StringToLong(Copy(Barcode,9,4));
   IF (OrderNo > 0) AND (MixNo > 0) THEN
    BEGIN
     IF SelRecs.LoadHeaderRecord(OrderNo,RevNo,MixNo) <> 0 THEN
       Disp_Error_msg('Order '+IntToZeroStr(OrderNo,6)+'/'+
                      IntToZeroStr(RevNo,2)+
                      ' Not Found')
     ELSE
      BEGIN
       SelRecs.SetCurrentMixNoTo(MixNo);
       SelRecs.SR_MixBarcodeScan1 := Barcode;
       LineNo := 0;
       IF SelRecs.WorkHRecord.WOH_SeqFixed THEN
         LineNo := FindNextWipLineForTerminal(@SelRecs.WorkHRecord,1);
       SelRecs.LoadLineRecord(LineNo);
       IF MixNo <= SelRecs.WorkHRecord.WOH_NumMixes THEN
        BEGIN
(*         IF ScanRelatedMixLabels(Barcode) THEN*)
         SelectOrderViaMixLabelBarcode :=  TRUE
        END
       ELSE
         Disp_Error_msg('Mix No. '+IntToStr(MixNo,1)+
                        ' not valid for Order '+IntToZeroStr(OrderNo,6)+'/'+
                        IntToZeroStr(RevNo,2));
      END;
    END;
  END;
END;


{Creates either a order header of order line scroller}
PROCEDURE SetUpScrollerWindows(LineWin : BOOLEAN);
BEGIN
 IF LineWin THEN
  BEGIN
   NEW(ScrollerWindows,Init(BROWSER_LX, BOXTOP, BROWSER_RX, (MaxY-8),
                            LineWin,4));
   New(ListBoxLeft,  Init(ButL1Start,ButtonTop,ButL1Stop,ButtonBot,ArrowLeft));
   New(ListBoxRight, Init(ButR1Start,ButtonTop,ButR1Stop,ButtonBot,ArrowRight));
  END
 ELSE
  BEGIN
   NEW(ScrollerWindows,Init(OpBROWSER_LX, OpBrowser_TY, MaxX-68, OpButtonTop - 8,
                            LineWin,7));
   New(ListBoxLeft,  Init(MaxX-60, OpBrowser_TY,
                          MaxX-8,  OpBrowser_TY+ButtonHeight, ArrowUp));
   New(ListBoxRight, Init(MaxX-60, ScrollerWindows^.Bounds.Bottom -ButtonHeight,
                          MaxX-8,  ScrollerWindows^.Bounds.Bottom, ArrowDown));
   New(BrowserHeader, Init);
  END;
END;



END.

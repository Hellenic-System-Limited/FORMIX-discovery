(****************************************************************************
*  UNIT          : FXIN_BRW                                                 *
*  AUTHOR        : S. Wright                                                *
*  DATE          : 07/05/96                                                 *
*  PURPOSE       : Formix Ingredient Browser                                *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}

UNIT FXBRW_IN;


INTERFACE

USES CRT,F6STDCTV,F6STDUTL,F6STDUT1,F6STDWIN,F6STDWN1,F6STDBRW,FXModCtv,
     FxFingr,FX_ie;

PROCEDURE IngredientLookup(TransferBuff : PIngredient_Record);
PROCEDURE IngredientBrowse;

IMPLEMENTATION


CONST WIN_X          = 8;             { WINDOW X Offset       (Global )     }
      WIN_Y          = 2;             { WINDOW Y Offset       (Global )     }
      WIN_WID        = 52;            { WINDOW Width          (Global )     }
      WIN_DEP        = 22;            { WINDOW Depth          (Global )     }
      X1 = WIN_X;
      Y1 = WIN_Y;
      X2 = WIN_X+WIN_WID;
      Y2 = WIN_Y+WIN_DEP;

      LIST_X         = WIN_X+2;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH     = WIN_WID-4;   { LIST BOX WIDTH        (Global )     }
      LIST_Y         = WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH     = WIN_DEP-LIST_Y-1;{ LIST BOX DEPTH    (Global )     }

      BLANK_LINE     = '---------- ------------------------------ -------';

      Read_Key       = 0;

TYPE TListItem = TIngredient_Record;

     PBrowseList = ^TBrowseList;
     TBrowseList = ARRAY[1..LIST_DEPTH] OF TListItem;

     PIngredientLookup = ^TIngredientLookup;
     TIngredientLookup = OBJECT(TFileBrowser)

      BrowseWin   : WindowRecord;
      BrowseArray : PBrowseList;
      LookupTransferBuff : PIngredient_Record;
      WorkRec     : TIngredient_Record;
      EnterStr    : TIngredientRef;
      Scroller    : Pscroller;

      CONSTRUCTOR Init(Xp,Yp,Width,Depth : BYTE; TransferBuff : PIngredient_Record);
      PROCEDURE   WriteStaticText; Virtual;
      PROCEDURE   Setup; Virtual;
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   ClearListPos        (Element   : BYTE); Virtual;
      PROCEDURE   FillRecWithListKey  (Element   : BYTE); Virtual;
      FUNCTION    ReadRecordFunc      (Operation : STRING) : INTEGER; Virtual;
      PROCEDURE   FillListPosWithRec  (Element   : BYTE); Virtual;
      FUNCTION    ListPosIsEmpty      (Element   : BYTE) : BOOLEAN; Virtual;
      PROCEDURE   CopyListItem        (DestElement,SourceElement : BYTE); Virtual;
      PROCEDURE   DisplayListItem     (Element   : BYTE); Virtual;
      PROCEDURE   EditListItem        (Element   : BYTE); Virtual;
      FUNCTION    EventHandled : BOOLEAN; Virtual;
      PROCEDURE   DisplayHighlightedChars(Col : BYTE); VIRTUAL;
      PROCEDURE   DisplayLookUpRecord;
      PROCEDURE   GetBrowseEvent; Virtual;
     END;


     PIngredientBrowse = ^TIngredientBrowse;
     TIngredientBrowse = OBJECT(TIngredientLookup)
      PROCEDURE   WriteStaticText; Virtual;
      PROCEDURE   DeleteListItem      (Element   : BYTE); Virtual;
      PROCEDURE   EditListItem        (Element   : BYTE); Virtual;
      PROCEDURE   InsertListItem; Virtual;
     END;


CONSTRUCTOR TIngredientLookup.Init(Xp,Yp,Width,Depth : BYTE; TransferBuff : PIngredient_Record);
BEGIN
 Esc_Flag       := FALSE;
 ListIndex      := 1;
 BrowseArray    := NIL;
 LookupTransferBuff:=TransferBuff;
 WorkRec        := TransferBuff^;
 EnterStr       := '';
 New(BrowseArray);
 IF NOT Assigned(BrowseArray) THEN Esc_Flag := TRUE;

 IF NOT Esc_Flag THEN
  BEGIN
   INHERITED Init(Xp,Yp,Width,Depth);
   IngredientFile^.OpenFile;
    IF IngredientFile^.OpenErr <> 0 THEN
    BEGIN
     Esc_Flag :=TRUE;
    END
   ELSE
    BEGIN
     FillListPosWithRec(1);
    END;
  END;
END;

PROCEDURE TIngredientLookup.WriteStaticText;
BEGIN
 Window(X1+1,Y1+1,X2-1,Y2-1);
 Header('INGREDIENT FILE LOOKUP',1);
 HighVideo;

 WriteAt(2,2,'Ingredient Description                    Type  ');
 WriteAt(2,3,BLANK_LINE);
 Footer(' ENTER  - Select Highlighted Ingredient Record             ',3);
 Footer('                                                           ',2);
 Footer(' ESC    - Exit                                             ',1);
END;

PROCEDURE TIngredientLookup.Setup;
VAR I :INTEGER;
    Lp : BYTE;
BEGIN
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,
		TRUE,NormBack*16+LowFore,NormBack*16+LowFore,BrowseWin);
 WriteStaticText;
 ForeColourScheme;
 RefreshListBox;
END;

PROCEDURE TIngredientLookup.GetBrowseEvent;
BEGIN
 INHERITED GetBrowseEvent;
END;

DESTRUCTOR TIngredientLookup.Done;
BEGIN
 IF Assigned(BrowseArray) THEN Dispose(BrowseArray);
 LoseWindow(BrowseWin);
 IngredientFile^.CloseFile;
END;

PROCEDURE TIngredientLookup.ClearListPos        (Element   : BYTE);
BEGIN
 FillChar(BrowseArray^[Element],SizeOf(TListItem),#0);
END;

PROCEDURE TIngredientLookup.FillRecWithListKey  (Element   : BYTE);
BEGIN
 WorkRec.ING_Ingredient := BrowseArray^[Element].ING_Ingredient;
END;

FUNCTION  TIngredientLookup.ReadRecordFunc(Operation : STRING) : INTEGER;
BEGIN
 IngredientFile^.ReadRecord(Operation,FALSE,FALSE,WorkRec,0);
 ReadRecordFunc := IngredientFile^.BtrvErr;
END;

PROCEDURE TIngredientLookup.FillListPosWithRec  (Element   : BYTE);
VAR TempWt : DOUBLE;
BEGIN
 BrowseArray^[Element] := WorkRec;
END;

FUNCTION  TIngredientLookup.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := BrowseArray^[Element].ING_Ingredient[0] = #0;
END;

PROCEDURE TIngredientLookup.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray^[SourceElement],BrowseArray^[DestElement],SizeOf(TListItem));
END;

PROCEDURE TIngredientLookup.DisplayHighlightedChars(Col : BYTE);
VAR TextSave : BYTE;
BEGIN
 WITH BrowseArray^[ListIndex] DO
  BEGIN
   TextSave := TextAttr;
   GotoXY((LB_X-Lo(WindMin)),ListIndex+LB_Y-(Hi(WindMin)+1));
   IF NOT NowtButSpace(EnterStr) AND Str_Equal(EnterStr,ING_Ingredient,Length(EnterStr)) THEN
    BEGIN
     TextAttr := Col AND $F0 + HighFore;
     Write(EnterStr);
     TextAttr :=Col;
     Write(COPY(ING_Ingredient,Length(EnterStr)+1,8));
    END
   ELSE
    BEGIN
     TextAttr := Col;
     Write(ING_Ingredient);
    END;
   TextAttr := TextSave;
  END;
END;

PROCEDURE TIngredientLookup.DisplayListItem(Element   : BYTE);
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   WITH BrowseArray^[Element] DO
    BEGIN
     Write(ING_Ingredient);
     Write('   ',ING_Description,' ');
     Write(GetProcessTypeName(ING_DefaultProcessType));
    END;
  END
 ELSE
  BEGIN
   Write(BLANK_LINE);
  END;
END;

PROCEDURE TIngredientLookUp.DisplayLookUpRecord;
BEGIN
 WorkRec.ING_Ingredient := EnterStr+SPACE_STRING;
 ReadRecordFunc('GE');
 ListIndex := 1;
 FillListPosWithRec(1);
 RefreshListBox;
END;

FUNCTION TIngredientLookup.EventHandled : BOOLEAN;
BEGIN
 EventHandled := FALSE;
 IF FuncKey THEN
  BEGIN
   CASE Ch1 OF
    PREV,
    NEXT,
    PGUP,
    PGDN : BEGIN
            EnterStr := '';
            DisplayHighlightedChars(DispColour(ListIndex, FALSE));
           END;
   END;
  END
 ELSE
  BEGIN
   Ch1 := Upcase(Ch1);
   CASE Ch1 OF
    'A'..'Z',
    '0'..'9' : BEGIN
                EnterStr := EnterStr + Ch1;
                DisplayLookupRecord;
                EventHandled := TRUE;
               END;
   END;
  END;
END;

PROCEDURE TIngredientLookup.EditListItem        (Element   : BYTE);
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   FillRecWithListKey(Element);                         {Prime Key Fields  }
   IF (ReadRecordFunc('EQ') = 0) THEN
    BEGIN
     LookupTransferBuff^ := WorkRec;
     Esc_Flag := TRUE; {Read Record & Exit}
    END;
  END;
 IF NOT Esc_Flag THEN RefreshListBox;                   { Redraw List Box  }
END;

{**************************************************************************}
{* Browser Methods                                                        *}
{**************************************************************************}

PROCEDURE TIngredientBrowse.WriteStaticText;
BEGIN
 Window(X1+1,Y1+1,X2-1,Y2-1);
 Header('INGREDIENT FILE BROWSER',1);
 HighVideo;

 WriteAt(2,2,'Ingredient Description                    Type ');
 WriteAt(2,3,BLANK_LINE);


 Footer(' INSERT - Add Ingredient Record                            ',3);
 Footer(' ENTER  - Edit Ingredient Record                           ',2);
 Footer(' DELETE - Delete Ingredient Record                         ',1);
END;


PROCEDURE TIngredientBrowse.DeleteListItem      (Element   : BYTE);
BEGIN
 IF ListPosIsEmpty(Element) THEN Exit;
 IF YesNoWin('     Delete Ingredient '+
             BrowseArray^[Element].ING_Ingredient+CRLF+
	     '       Are You Sure Y/N ') THEN
  BEGIN
   FillRecWithListKey(Element);
   IF IngredientFile^.ReadRecord('EQ',TRUE,FALSE,WorkRec,0) = 0 THEN
    BEGIN
     IngredientFile^.DeleteRecord;
    END;
  END;
 RefreshListBox;
END;

PROCEDURE TIngredientBrowse.EditListItem        (Element   : BYTE);
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   Edit_Ingredient(BrowseArray^[Element].ING_Ingredient);
   RefreshListBox;
  END;
END;

PROCEDURE TIngredientBrowse.InsertListItem;
BEGIN
 Edit_Ingredient('');
 RefreshListBox;
END;

{**************************************************************************}
{* END of Browser Methods                                                 *}
{**************************************************************************}

PROCEDURE IngredientLookup(TransferBuff : PIngredient_Record);
VAR IngredientLookupPtr : PIngredientLookup;
BEGIN
 New(IngredientLookupPtr,Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH,TransferBuff));
 IngredientLookupPtr^.Run;
 Dispose(IngredientLookupPtr,Done);
END;

PROCEDURE IngredientBrowse;
VAR IngredientBrowse : PIngredientBrowse;
    TransferBuff     : PIngredient_Record;
BEGIN
 TransferBuff := NIL;
 NEW(TransferBuff);
 IngredientFile^.InitRecord(TransferBuff^);
 New(IngredientBrowse,Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH,TransferBuff));
 IngredientBrowse^.Run;
 Dispose(IngredientBrowse,Done);
 IF Assigned(TransferBuff) THEN Dispose(TransferBuff);
END;


END.
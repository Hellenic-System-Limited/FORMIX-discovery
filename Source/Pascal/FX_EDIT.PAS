(****************************************************************************
*  UNIT          : FX_WOE                                                   *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 08/05/96                                                 *
*  PURPOSE       : FORMIX COMBINED EDITOR                                   *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FX_EDIT;
INTERFACE
USES Crt,F6StdBrw,F6StdWin,F6StdCtv,F6StdUt1,F6StdWn1,FxFOrder,F6StdUtl,
     FXCfg,FxfMenu;

CONST LIST_DEPTH       = 25;

TYPE TPositionItem = Record
      LineNo    : LONGINT;
      RecPos    : LONGINT;
     END;


     PCombinedRecordEdit = ^TCombinedRecordEdit;
     TCombinedRecordEdit = object(TFileBrowser)
      BrowseList      : ARRAY[1..LIST_DEPTH] OF TPositionItem;
      CurrLine        : LONGINT;
      TotalLineRatio  : DOUBLE;

      EditWindow      : WindowRecord;
      EditWindowUp    : BOOLEAN;
      First_F,Last_F  : INTEGER;
      First_Field     : BYTE;
      ItemWindow      : WindowRecord;
      NewRecord,
      SaveRecord      : BOOLEAN;
      FieldNo         : INTEGER;
      LISTBOX_F       : INTEGER;
      EditAllowed     : BOOLEAN;

      CONSTRUCTOR Init(Xp,Yp,Width,Depth : BYTE;FirstField,LastField,ListBox : INTEGER);
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   DisplayStaticTextAndFields(MenuName : STRING);
      PROCEDURE   ClearListPos         (Element : BYTE); Virtual;
      PROCEDURE   FillRecWithListKey   (Element   : BYTE); Virtual;
      FUNCTION    ListPosIsEmpty       (Element   : BYTE) : BOOLEAN; Virtual;
      PROCEDURE   CopyListItem         (DestElement,SourceElement : BYTE); Virtual;
      PROCEDURE   DisplayField(Field : INTEGER); VIRTUAL;
      PROCEDURE   DisplayFields;
      FUNCTION    EditLineRecord  (Element   : BYTE;NewLine : BOOLEAN) : BOOLEAN; Virtual;
      PROCEDURE   EditListItem         (Element   : BYTE); Virtual;
      PROCEDURE   SwapRecords(VAR Rec1,Rec2 : POINTER);
      PROCEDURE   SwapPositions(VAR Pos1,Pos2 : LONGINT);
      FUNCTION    InsertRecordLineAt(Element : BYTE) : BOOLEAN; Virtual;
      PROCEDURE   InsertItemIntoList(Element : BYTE); Virtual;
      PROCEDURE   RefreshListBox; VIRTUAL;
      FUNCTION    EventHandled         : BOOLEAN; Virtual;
      PROCEDURE   MoveItemUpList(Element : BYTE); Virtual;
      PROCEDURE   MoveItemDownList(Element : BYTE); Virtual;


{      FUNCTION    ReadRecordFunc       (Operation : STRING) : INTEGER; Virtual;}
{      PROCEDURE   GetBrowseEvent; Virtual;}


{      PROCEDURE   ResetRecipeEditor;
      FUNCTION    Output_Value(Field : BYTE) : STRING;
      PROCEDURE   Input_Value(Field_Str : STRING; Field : BYTE);
      PROCEDURE   EditField(Field : LONGINT);


      PROCEDURE   DeleteListItem       (Element   : BYTE); Virtual;
      PROCEDURE   InsertListItem; Virtual;

      FUNCTION    AddRcpLine : LONGINT; Virtual;
      PROCEDURE   SetItemAsKeyIngredient(Element : BYTE);

}

     END;


IMPLEMENTATION
CONSTRUCTOR TCombinedRecordEdit.Init(Xp,Yp,Width,Depth : BYTE;FirstField,LastField,ListBox : INTEGER);
BEGIN
 TotalLineRatio := 0.0;
 First_F        := FirstField;
 Last_F         := LastField;
 ListBox_F      := ListBox;
 INHERITED Init(Xp,Yp,Width,Depth);
 Esc_Flag       := FALSE;
 EditWindowUp   := FALSE;
 CurrLine       :=1;
 EditAllowed    := TRUE;
END;

DESTRUCTOR  TCombinedRecordEdit.Done;
BEGIN
 IF EditWindowUp THEN LoseWindow(EditWindow);
 INHERITED Done;
END;

PROCEDURE  TCombinedRecordEdit.DisplayStaticTextAndFields(MenuName : STRING);
BEGIN
 GotoXY(1,1);
 MenuCr :='xx';
 BackColourScheme;
 IF NOT LoadMenu(MenuName,TRUE) THEN
  BEGIN
   Disp_Error_Msg('Menu File Not Found '+MenuName+'.TXT');
   Esc_Flag := TRUE;                        { Exit                         }
  END;
 ForeColourScheme;
 DisplayFields;
END;

PROCEDURE  TCombinedRecordEdit.RefreshListBox;
BEGIN
 TotalLineRatio := 0.0;
 INHERITED RefreshListBox;
END;

PROCEDURE   TCombinedRecordEdit.ClearListPos(Element : BYTE);
BEGIN
 FillChar(BrowseList[Element],Sizeof(TPositionItem),#0);
END;

PROCEDURE   TCombinedRecordEdit.FillRecWithListKey(Element   : BYTE);
BEGIN
 CurrLine := BrowseList[Element].LineNo;
END;

FUNCTION    TCombinedRecordEdit.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := (BrowseList[Element].LineNo < 1) OR
                   (BrowseList[Element].LineNo > MAX_LINES_ON_RECORD);
END;

PROCEDURE   TCombinedRecordEdit.CopyListItem         (DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseList[SourceElement],BrowseList[DestElement],Sizeof(TPositionItem));
END;

PROCEDURE   TCombinedRecordEdit.DisplayField(Field : INTEGER);
BEGIN
END;

PROCEDURE   TCombinedRecordEdit.DisplayFields;
VAR FieldIdx : INTEGER;
BEGIN
  FOR FieldIdx := First_F TO Last_F DO DisplayField(FieldIdx);
END;

PROCEDURE   TCombinedRecordEdit.SwapRecords(VAR Rec1,Rec2 : POINTER);
VAR TempRec : POINTER;
BEGIN
 TempRec := Rec1;
 Rec1    := Rec2;
 Rec2    := TempRec;
END;

PROCEDURE   TCombinedRecordEdit.SwapPositions(VAR Pos1,Pos2 : LONGINT);
VAR TempPos : LONGINT;
BEGIN
 TempPos := Pos1;
 Pos1    := Pos2;
 Pos2    := TempPos;
END;

FUNCTION    TCombinedRecordEdit.EditLineRecord  (Element   : BYTE;NewLine : BOOLEAN) : BOOLEAN;
BEGIN
END;

PROCEDURE   TCombinedRecordEdit.EditListItem(Element   : BYTE);
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   EditLineRecord(BrowseList[Element].LineNo,FALSE);
  END;
 RefreshListBox;
END;

FUNCTION    TCombinedRecordEdit.InsertRecordLineAt(Element : BYTE) : BOOLEAN;
BEGIN
END;

PROCEDURE   TCombinedRecordEdit.InsertItemIntoList(Element : BYTE);
BEGIN
 IF (NOT ListPosIsEmpty(Element)) THEN
  BEGIN
   IF InsertRecordLineAt(Element) THEN
    BEGIN
     IF (NOT EditLineRecord(BrowseList[Element].LineNo,TRUE)) THEN
       DeleteListItem(Element);
     RefreshListBox;
    END;
  END;
END;

FUNCTION TCombinedRecordEdit.EventHandled : BOOLEAN;
VAR EventDone : BOOLEAN;
BEGIN
 EventDone := FieldNo <> LISTBOX_F;
 IF Funckey THEN
  BEGIN
   CASE ch1 OF
    NEXT : BEGIN
     IF FieldNo <> LISTBOX_F THEN                 { If Not On Listbox       }
      BEGIN
       REPEAT
        INC(FieldNo);                              { Go To Next Field        }
        EventDone := TRUE;
       UNTIL (FieldNo = LISTBOX_F) OR (DatCtl[FieldNo] = 0);
      END;
    END;

    PREV : BEGIN
     IF FieldNo = LISTBOX_F THEN                  { If On Listbox Field     }
      BEGIN
       IF (ListIndex = 1) AND (EditAllowed) THEN { If At Top Of List       }
        BEGIN
         FillRecWithListKey(ListIndex);
         IF ReadRecordFunc('LT') <> 0 THEN       { Any More Records Prev.   }
          BEGIN                                  { No!                      }
           DEC(FieldNo);                         { Jump out of List Field   }
           EventDone := TRUE;
          END;                                   { END (No Prev Record)     }
        END;                                     { END (ListIndex = 1)      }
      END                                        { END (ON LISTBOX FIELD)   }
     ELSE IF (EditAllowed) THEN
      BEGIN                                      { ON ENTRY FIELD           }
       REPEAT
        DEC(FieldNo);
        IF FieldNo < First_Field THEN FieldNo := LISTBOX_F-1;
       UNTIL (FieldNo = LISTBOX_F) OR (DatCtl[FieldNo] = 0);
       EventDone := TRUE;
      END;
    END;                                         { END (PREV)               }

    FN_F4  : IF NOT EventDone THEN
    BEGIN                               { Insert }
      InsertItemIntoList(ListIndex);
      EventDone := TRUE;
    END;

    FN_F5  : IF NOT EventDone THEN
    BEGIN                              { Move Up }
      MoveItemUpList(ListIndex);
      EventDone := TRUE;
    END;

    FN_F6  : IF NOT EventDone THEN
     BEGIN                              { Move Down}
      MoveItemDownList(ListIndex);
      EventDone := TRUE;
    END;
   END;
  END;
 EventHandled := EventDone;
END;

PROCEDURE TCombinedRecordEdit.MoveItemUpList(Element : BYTE);
BEGIN
END;

PROCEDURE TCombinedRecordEdit.MoveItemDownList(Element : BYTE);
BEGIN
END;



(*

FUNCTION    TCombinedRecordEdit.ReadRecordFunc       (Operation : STRING) : INTEGER; Virtual;
PROCEDURE   TCombinedRecordEdit.GetBrowseEvent; Virtual;
PROCEDURE   TCombinedRecordEdit.ResetRecipeEditor;
FUNCTION    TCombinedRecordEdit.Output_Value(Field : BYTE) : STRING;
PROCEDURE   TCombinedRecordEdit.Input_Value(Field_Str : STRING; Field : BYTE);
PROCEDURE   TCombinedRecordEdit.EditField(Field : LONGINT);

PROCEDURE   TCombinedRecordEdit.DeleteListItem       (Element   : BYTE); Virtual;
PROCEDURE   TCombinedRecordEdit.InsertListItem; Virtual;

FUNCTION    TCombinedRecordEdit.AddRcpLine : LONGINT; Virtual;
PROCEDURE   TCombinedRecordEdit.SetItemAsKeyIngredient(Element : BYTE);

FUNCTION    TCombinedRecordEdit.EditRcpLine          (Element   : BYTE;NewLine : BOOLEAN) : BOOLEAN; Virtual;
*)


END.



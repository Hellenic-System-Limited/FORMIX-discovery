(****************************************************************************
*  UNIT          : FXRP_BRW                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 09/05/96                                                 *
*  PURPOSE       : Formix Recipe Order Browser                              *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXBRW_RP;

INTERFACE

USES CRT,F6STDCTV,FXMODCTV,F6STDUTL,F6STDUT1,F6STDWIN,F6STDWN1,F6STDBRW,
     F6DTCONV,FXFRcp,FX_WOE,FX_RPE;

PROCEDURE RecipeEdit;
PROCEDURE BrowseRecipe(VAR RecipeNo : TRecipeRef; OkToSelectObsolete : BOOLEAN);

IMPLEMENTATION


CONST WIN_X          = 5;             { WINDOW X Offset       (Global )     }
      WIN_Y          = 3;             { WINDOW Y Offset       (Global )     }
      WIN_WID        = 55;            { WINDOW Width          (Global )     }
      WIN_DEP        = 20;            { WINDOW Depth          (Global )     }
      X1 = WIN_X;
      Y1 = WIN_Y;
      X2 = WIN_X+WIN_WID;
      Y2 = WIN_Y+WIN_DEP;

      LIST_X         = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH     = WIN_WID-3;   { LIST BOX WIDTH        (Global )     }
      LIST_Y         = WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH     = WIN_DEP-7;   { LIST BOX DEPTH    (Global )     }

      BLANK_LINE     = '  -------- ----------------------------------------';
      Read_Key       = 0;

TYPE TListItem = TRecipeHeaderRecord;

     PBrowseList = ^TBrowseList;
     TBrowseList = ARRAY[1..LIST_DEPTH] OF TListItem;

     PRecipeBrowse = ^TRecipeBrowse;
     TRecipeBrowse = OBJECT(TFileBrowser)

      BrowseWin   : WindowRecord;
      BrowseArray : PBrowseList;
      RecordBuff  : PRecipeHEaderRecord;
      CalledAsEdit: BOOLEAN;
      RB_AllowObsoleteRecSelect : BOOLEAN;
      EnterStr    : TRecipeRef;
      RecipeSelected : TRecipeRef;

      CONSTRUCTOR Init(Xp,Yp,Width,Depth : BYTE;
                       EditBrowse : BOOLEAN; AllowObsoleteSelect : BOOLEAN);
      PROCEDURE   Setup; Virtual;
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   ClearListPos        (Element   : BYTE); Virtual;
      PROCEDURE   FillRecWithListKey  (Element   : BYTE); Virtual;
      FUNCTION    ReadRecordFunc      (Operation : STRING) : INTEGER; Virtual;
      PROCEDURE   FillListPosWithRec  (Element   : BYTE); Virtual;
      FUNCTION    ListPosIsEmpty      (Element   : BYTE) : BOOLEAN; Virtual;
      PROCEDURE   CopyListItem        (DestElement,SourceElement : BYTE); Virtual;
      {FUNCTION    DispColour          (Element   : BYTE; Highlight : BOOLEAN): BYTE; Virtual;}
      PROCEDURE   DisplayListItem     (Element   : BYTE); Virtual;
      FUNCTION    EventHandled        : BOOLEAN; Virtual;
      PROCEDURE   DeleteListItem      (Element   : BYTE); Virtual;
      PROCEDURE   EditListItem        (Element   : BYTE); Virtual;
      PROCEDURE   InsertListItem; Virtual;
      PROCEDURE   DisplayLookUpRecord;
      PROCEDURE   DisplayHighlightedChars(Col : BYTE);VIRTUAL;
     END;


CONSTRUCTOR TRecipeBrowse.Init(Xp,Yp,Width,Depth : BYTE;
                               EditBrowse : BOOLEAN;
                               AllowObsoleteSelect : BOOLEAN);
BEGIN
 EnterStr     := '';
 CalledAsEdit := EditBrowse;
 RecipeSelected := SPACE_STRING;
 RB_AllowObsoleteRecSelect := AllowObsoleteSelect;
 RecipeLineFile^.OpenFile;
 RecipeHeaderFIle^.OpenFile;
 New(BrowseArray);
 New(RecordBuff);
 IF (RecipeHeaderFile^.OpenErr+RecipeLineFile^.OpenErr <> 0) THEN Esc_Flag :=TRUE;
 INHERITED Init(Xp,Yp,Width,Depth);
END;

DESTRUCTOR TRecipeBrowse.Done;
BEGIN
 LoseWindow(BrowseWin);
 Dispose(RecordBuff);
 Dispose(BrowseArray);
 RecipeHeaderFile^.CloseFile;
 RecipeLineFile^.CloseFile;
 INHERITED Done;
END;

PROCEDURE TRecipeBrowse.DeleteListItem      (Element   : BYTE);
BEGIN
 IF NOT CalledAsEdit THEN Exit;
 IF YesNoWin('     Delete Recipe '+BrowseArray^[Element].RH_RecipeNo+CRLF+
             '       Are You Sure Y/N ') THEN
  BEGIN
   FillRecWithListKey(Element);
   IF RecipeHeaderFile^.ReadRecord('GE',TRUE,FALSE,RecordBuff^,Read_Key) = 0 THEN
    BEGIN
     IF RecipeLineFile^.DelLinesForRecipe(RecordBuff^.RH_UniqueRef) = 0 THEN
       RecipeHeaderFile^.DeleteRecord
     ELSE
       RecipeHeaderFile^.Unlock_Single;
    END;
  END;
 RefreshListBox;
END;

PROCEDURE TRecipeBrowse.EditListItem(Element   : BYTE);
BEGIN
 IF CalledAsEdit THEN
  BEGIN
   Edit_Recipe(BrowseArray^[Element].RH_RecipeNo,BrowseArray^[Element].RH_UniqueRef);
   RefreshListBox;
  END
 ELSE
  BEGIN
   IF  BrowseArray^[Element].RH_Obsolete
   AND (NOT RB_AllowObsoleteRecSelect) THEN
     Disp_Error_Msg('Obsolete Recipe not allowed.')
   ELSE
    BEGIN
     Esc_Flag       := TRUE;
     RecipeSelected := BrowseArray^[Element].RH_RecipeNo;
    END;
  END;
END;

PROCEDURE TRecipeBrowse.InsertListItem;
BEGIN
 IF NOT CalledAsEdit THEN EXIT;
 Edit_Recipe(COPY(SPACE_STRING,1,SizeOf(TRecipeRef)-1),0);
 RefreshListBox;
END;

PROCEDURE TRecipeBrowse.Setup;
VAR I :INTEGER;
VAR Lp : BYTE;
BEGIN
 HBarXOffSet :=2;
 FillChar(BrowseArray^,SizeOf(BrowseArray^),#0);
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,
		TRUE,NormBack*16+LowFore,NormBack*16+LowFore,BrowseWin);

 Header('Recipe File Browser',1);
 HighVideo;

 WriteAt(1,2,'  Code     Description                     Status');
 WriteAt(1,3,BLANK_LINE);
 IF CalledAsEdit THEN
  BEGIN
   Footer('INSERT - Add a new Recipe                          ',3);
   Footer('ENTER  - Change Recipe    F5  - Chg.Obsolete Status',2);
   Footer('DELETE - Delete Recipe    ESC - Exit               ',1);
  END
 ELSE
  BEGIN
   Footer('',3);
   Footer('',2);
   Footer('ENTER  - Select        ESCAPE - EXIT',1);
  END;
 ForeColourScheme;
 RefreshListBox;
END;

PROCEDURE TRecipeBrowse.ClearListPos        (Element   : BYTE);
BEGIN
 FillChar(BrowseArray^[Element],SizeOf(TListItem),#0);
END;

PROCEDURE TRecipeBrowse.FillRecWithListKey  (Element   : BYTE);
BEGIN
 RecordBuff^ := BrowseArray^[Element];
{ RecordBuff^.RH_UniqueRef := BrowseArray^[Element].Rec.RH_UniqueRef;
 Move(BrowseArray^[Element].Pos,RecordBuff^,SizeOF(LONGINT));}
END;

FUNCTION  TRecipeBrowse.ReadRecordFunc(Operation : STRING) : INTEGER;
TYPE LONGPTR = ^LONGINT;
VAR ReadErr : INTEGER;
BEGIN
 RecipeHeaderFile^.ReadRecord(Operation,FALSE,FALSE,RecordBuff^,Read_Key);
 ReadErr := RecipeHeaderFile^.BtrvErr;
(* IF LONGPTR(RecordBuff)^ = 0 THEN
  BEGIN
   RecordBuff^.RH_RecipeNo := SPACE_STRING;
   RecipeHeaderFile^.ReadRecord('GE',FALSE,FALSE,RecordBuff^,Read_Key);
   LONGPTR(RecordBuff)^:=RecipeHeaderFile^.Position;
  END;
 CASE Operation[1] OF
  'G' : CASE Operation[2] OF
         'F' : BEGIN
                RecordBuff^.RH_RecipeNo := SPACE_STRING;
                ReadErr   := RecipeHeaderFile^.ReadRecord('GE',FALSE,FALSE,RecordBuff^,Read_Key);
               END;
         'L' : BEGIN
                RecordBuff^.RH_RecipeNo := #255#255#255#255#255#255#255#255;
                ReadErr   := RecipeHeaderFile^.ReadRecord('LT',FALSE,FALSE,RecordBuff^,Read_Key);
               END;
         'E' : BEGIN
                ReadErr   := RecipeHeaderFile^.ReadRecord('GD',FALSE,FALSE,RecordBuff^,Read_Key);
               END;
         'T' : BEGIN
                ReadErr   := RecipeHeaderFile^.ReadRecord('GD',FALSE,FALSE,RecordBuff^,Read_Key);
                ReadErr   := RecipeHeaderFile^.ReadRecord('GN',FALSE,FALSE,RecordBuff^,Read_Key);
               END;
         'D' : BEGIN
                ReadErr   := RecipeHeaderFile^.ReadRecord('GD',FALSE,FALSE,RecordBuff^,Read_Key);
               END;
         'N' : BEGIN
                ReadErr   := RecipeHeaderFile^.ReadRecord('GN',FALSE,FALSE,RecordBuff^,Read_Key);
               END;
         'P' : BEGIN
                ReadErr   := RecipeHeaderFile^.ReadRecord('GP',FALSE,FALSE,RecordBuff^,Read_Key);
               END;
        END;
  'L' : CASE Operation[2] OF
         'E' :BEGIN
               ReadErr   := RecipeHeaderFile^.ReadRecord('GD',FALSE,FALSE,RecordBuff^,Read_Key);
               ReadErr   := RecipeHeaderFile^.ReadRecord('LE',FALSE,FALSE,RecordBuff^,Read_Key);
              END;
         'T' :BEGIN
               ReadErr   := RecipeHeaderFile^.ReadRecord('GD',FALSE,FALSE,RecordBuff^,Read_Key);
               ReadErr   := RecipeHeaderFile^.ReadRecord('GP',FALSE,FALSE,RecordBuff^,Read_Key);
              END;
        END;
  'E' : BEGIN
         ReadErr   := RecipeHeaderFile^.ReadRecord('GD',FALSE,FALSE,RecordBuff^,Read_Key);
        END;
 END;*)
 ReadRecordFunc:=ReadErr;
END;

PROCEDURE TRecipeBrowse.FillListPosWithRec  (Element   : BYTE);
BEGIN
 BrowseArray^[Element] := RecordBuff^;
{ BrowseArray^[Element].Pos := RecipeHeaderFile^.Position;}
END;

FUNCTION  TRecipeBrowse.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
{ ListPosIsEmpty := BrowseArray^[Element].Pos = 0;}
 ListPosIsEmpty := NowtButSpace(BrowseArray^[Element].RH_RecipeNo);
END;

PROCEDURE TRecipeBrowse.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray^[SourceElement],BrowseArray^[DestElement],SizeOf(TListItem));
END;

(*
FUNCTION  TRecipeBrowse.DispColour(Element   : BYTE; Highlight : BOOLEAN): BYTE;
BEGIN
 IF Highlight THEN
  DispColour := HiliteBarColour*16
 ELSE
  DispColour := INHERITED DispColour(Element,Highlight);
END;
*)

PROCEDURE TRecipeBrowse.DisplayHighlightedChars(Col : BYTE);
VAR TextSave : BYTE;
BEGIN
 WITH BrowseArray^[ListIndex] DO
  BEGIN
   TextSave := TextAttr;
   GotoXY((LB_X-Lo(WindMin)),ListIndex+LB_Y-(Hi(WindMin)+1));
   IF NOT NowtButSpace(EnterStr) AND Str_Equal(EnterStr,RH_RecipeNo,Length(EnterStr)) THEN
    BEGIN
     TextAttr := Col AND $F0 + HighFore;
     Write('  ',EnterStr);
     TextAttr :=Col;
     Write(COPY(RH_RecipeNo,Length(EnterStr)+1,8));
    END
   ELSE
    BEGIN
     TextAttr := Col;
     Write('  ',RH_RecipeNO);
    END;
   TextAttr := TextSave;
  END;
END;


PROCEDURE TRecipeBrowse.DisplayListItem(Element   : BYTE);
VAR SaveCol : BYTE;
    ListLineStr : STRING[70];
BEGIN
 IF ListPosIsEmpty(Element) THEN
   ListLineStr := BLANK_LINE+Space_String
 ELSE
  BEGIN
   WITH BrowseArray^[Element] DO
    BEGIN
     ListLineStr := '  '+ RH_RecipeNo+ ' '+ RH_Description;
     IF RH_Obsolete THEN
       ListLineStr := ListLineStr + '  Obsolete';
     ListLineStr := ListLineStr + Space_String;
    END;
  END;
 Write(Copy(ListLineStr,1,LIST_WIDTH+1));
END;

PROCEDURE TRecipeBrowse.DisplayLookUpRecord;
BEGIN
 RecordBuff^.RH_RecipeNo := EnterStr+SPACE_STRING;
 RecipeHeaderFile^.ReadRecord('GE',FALSE,FALSE,RecordBuff^,Read_Key);
 ListIndex := 1;
 FillListPosWithRec(1);
 RefreshListBox;
END;

FUNCTION TRecipeBrowse.EventHandled : BOOLEAN;
BEGIN
 EventHandled:=FALSE;
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
(*
    FN_F5 : BEGIN
             IF CheckForCircularRecipeRef(BrowseArray^[Listindex].RH_RecipeNo) THEN
              Disp_Error_Msg('A Circular Reference Exists For This Recipe')
             ELSE
              Disp_Error_Msg('No Circular Reference Found');
            END;
*)
    FN_F5: BEGIN
            IF NOT ListPosIsEmpty(ListIndex) THEN
             BEGIN
              WITH BrowseArray^[ListIndex] DO
               BEGIN
                IF RecipeHeaderFile^.SetObsoleteOnRecipe(RH_RecipeNo,
                                                  (NOT RH_Obsolete)) = 0 THEN
                 BEGIN
                  RH_Obsolete := NOT RH_Obsolete;
                  DisplayList(ListIndex, ListIndex);
                 END;
               END;
             END;
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

PROCEDURE RecipeEdit;
VAR RecipeBrowse : PRecipeBrowse;
BEGIN
 New(RecipeBrowse,Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH,
                       TRUE{EditBrowse}, TRUE{OkToSelectObsolete)}));
 RecipeBrowse^.Run;
 Dispose(RecipeBrowse,Done);
END;

PROCEDURE BrowseRecipe(VAR RecipeNo : TRecipeRef; OkToSelectObsolete : BOOLEAN);
VAR RecipeBrowse : PRecipeBrowse;
BEGIN
 New(RecipeBrowse, Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH,
                        FALSE{EditBrowse}, OkToSelectObsolete));
 RecipeBrowse^.Run;
 RecipeNo := RecipeBrowse^.RecipeSelected;
 Dispose(RecipeBrowse,Done);
END;

END.

(****************************************************************************
*  UNIT          : FXMA_BRW                                                 *
*  AUTHOR        : S. Wright                                                *
*  DATE          : 09/05/96                                                 *
*  PURPOSE       : Formix Recipe Order Browser                              *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}

UNIT FXBRW_MA;

INTERFACE

USES CRT,F6STDCTV,FXModCtv,F6STDUTL,F6STDUT1,F6STDWIN,F6STDWN1,F6STDBRW,
     FXPWord,FX_ME,FXFMacro,FXBrw_MC;

CONST WIN_X          = 10;            { WINDOW X Offset       (Global )     }
      WIN_Y          = 03;            { WINDOW Y Offset       (Global )     }
      WIN_WID        = 42;            { WINDOW Width          (Global )     }
      WIN_DEP        = 19;            { WINDOW Depth          (Global )     }
      X1 = WIN_X;
      Y1 = WIN_Y;
      X2 = WIN_X+WIN_WID;
      Y2 = WIN_Y+WIN_DEP;

      LIST_X         = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH     = WIN_WID-2;   { LIST BOX WIDTH        (Global )     }
      LIST_Y         = WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH     = WIN_DEP-7;{ LIST BOX DEPTH    (Global )     }

      BLANK_LINE     = ' ---------------------------------------';
      Read_Key       = 0;

TYPE TListItem = TMacroHeaderRecord;


     PBrowseList = ^TBrowseList;
     TBrowseList = ARRAY[1..LIST_DEPTH] OF TListItem;

     PMacroBrowse = ^TMacroBrowse;
     TMacroBrowse = OBJECT(TFileBrowser)

      BrowseWin   : WindowRecord;
      BrowseArray : PBrowseList;
      RecordBuff  : PMacroHeaderRecord;
      EnterStr    : STRING[9];

      CONSTRUCTOR Init(Xp,Yp,Width,Depth : INTEGER);
      PROCEDURE   Setup; Virtual;
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   ClearListPos        (Element   : BYTE); Virtual;
      PROCEDURE   FillRecWithListKey  (Element   : BYTE); Virtual;
      FUNCTION    ReadRecordFunc      (Operation : STRING) : INTEGER; Virtual;
      PROCEDURE   FillListPosWithRec  (Element   : BYTE); Virtual;
      FUNCTION    ListPosIsEmpty      (Element   : BYTE) : BOOLEAN; Virtual;
      PROCEDURE   CopyListItem        (DestElement,SourceElement : BYTE); Virtual;
      PROCEDURE   DisplayListItem     (Element   : BYTE); Virtual;
      FUNCTION    EventHandled        : BOOLEAN; Virtual;
      PROCEDURE   DeleteListItem      (Element   : BYTE); Virtual;
      PROCEDURE   EditListItem        (Element   : BYTE); Virtual;
      PROCEDURE   InsertListItem; Virtual;
      PROCEDURE   RefreshListBox;VIRTUAL;

      PROCEDURE   DisplayAllReports(Element : BYTE);
     END;

PROCEDURE MacroHeaderBrowse;


IMPLEMENTATION

CONSTRUCTOR TMacroBrowse.Init(Xp,Yp,Width,Depth : INTEGER);
BEGIN
 EnterStr := '';
 New(BrowseArray);
 MacroHeaderFile^.OpenFile;
 IF MAcroHeaderFile^.OpenErr<>0 THEN Esc_Flag :=TRUE;
 New(RecordBuff);
 INHERITED Init(Xp,Yp,Width,Depth);
END;

DESTRUCTOR TMacroBrowse.Done;
BEGIN
 Dispose(RecordBuff);
 Dispose(BrowseArray);
 LoseWindow(BrowseWin);
 MacroHeaderFile^.CloseFile;
 INHERITED Done;
END;

PROCEDURE TMacroBrowse.RefreshListBox;
BEGIN
 INHERITED RefreshListBox;
END;

PROCEDURE TMacroBrowse.DeleteListItem      (Element   : BYTE);
VAR MacroLine : TMacroLineRecord;
BEGIN
 IF YesNoWin('     Delete Macro Record'+CRLF+
             '      Are You Sure Y/N ') THEN
  BEGIN
   FillRecWithListKey(Element);
   IF MacroHeaderFile^.ReadRecord('EQ',TRUE,FALSE,RecordBuff^,0) = 0 THEN
    BEGIN
     IF (MacroLineFile^.OpenFile = 0) THEN
      BEGIN
       MacroLineFile^.GetFirstHeaderRef(RecordBuff^.MAC_UniqueRef,FALSE,FALSE,MacroLine);
       WHILE (MacroLineFile^.BtrvErr = 0) AND (MacroLine.MACL_HeaderRef = RecordBuff^.MAC_UniqueRef) DO
        BEGIN
         MacroLineFile^.DeleteRecord;
         MacroLineFile^.ReadRecord('GN',FALSE,FALSE,MacroLine,0);
        END;
      END;
     IF MacroLineFile^.OpenErr = 0 THEN MacroLineFile^.CloseFile;
     MacroHeaderFile^.DeleteRecord;
    END;
  END;
 RefreshListBox;
END;

PROCEDURE TMacroBrowse.EditListItem(Element   : BYTE);
BEGIN
 Edit_Macro(BrowseArray^[Element].MAC_UniqueRef);
 RefreshListBox;
END;

PROCEDURE TMacroBrowse.InsertListItem;
BEGIN
 Edit_Macro(0);
 RefreshListBox;
END;

PROCEDURE TMacroBrowse.Setup;
VAR I :INTEGER;
    Lp : BYTE;
BEGIN
 HBarXOffSet := 1;
 FillChar(BrowseArray^,SizeOf(BrowseArray^),#0);
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,TRUE,SW_DEFAULT,SW_DEFAULT,BrowseWin);
 Header('Macro Group Browser',1);
 Footer('F5 - Generate Macro Reports',3);
 Footer('INSERT - Add Macro  ENTER - Edit Macro',2);
 Footer('DELETE - Delete Macro  ESC - Exit ',1);
 HighVideo;
 WriteAt(2,2,'Description');
 WriteAt(1,3,BLANK_LINE);
 LowVideo;
 ForeColourScheme;
 RefreshListBox;
END;

PROCEDURE TMacroBrowse.ClearListPos(Element   : BYTE);
BEGIN
 FillChar(BrowseArray^[Element],SizeOf(TListItem),#0);
END;

PROCEDURE TMacroBrowse.FillRecWithListKey  (Element   : BYTE);
BEGIN
 RecordBuff^ := BrowseArray^[Element];
END;

FUNCTION  TMacroBrowse.ReadRecordFunc(Operation : STRING) : INTEGER;
BEGIN
 ReadRecordFunc :=MacroHeaderFile^.ReadRecord(Operation,FALSE,FALSE,RecordBuff^,Read_Key);
END;

PROCEDURE TMacroBrowse.FillListPosWithRec  (Element   : BYTE);
BEGIN
 BrowseArray^[Element] := RecordBuff^;
END;

FUNCTION  TMacroBrowse.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := NowtButSpace(BrowseArray^[Element].MAC_HeaderName);
END;

PROCEDURE TMacroBrowse.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray^[SourceElement],BrowseArray^[DestElement],SizeOf(TListItem));
END;

PROCEDURE TMacroBrowse.DisplayListItem(Element   : BYTE);
VAR SaveCol : BYTE;
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   WITH BrowseArray^[Element] DO
    BEGIN
     Write(' ',MAC_HeaderName);
    END;
  END
 ELSE
  BEGIN
   Write(BLANK_LINE);
  END;
END;

PROCEDURE TMacroBrowse.DisplayAllReports(Element : BYTE);
VAR MacroLine : TMacroLineRecord;
    RepMacro  : TRepMacroRecord;
    ReadErr   : INTEGER;
BEGIN
 FillRecWithListKey(Element);
{ ReadRecordFunc('EQ');}
 IF (MacroLineFile^.OpenFile + RepMacroFile^.OpenFile = 0) THEN
  BEGIN
   MacroLineFile^.GetFirstHeaderRef(RecordBuff^.MAC_UniqueRef,FALSE,FALSE,MacroLine);
   WHILE (MacroLineFile^.BtrvErr = 0) AND (MacroLine.MACL_HeaderRef = RecordBuff^.MAC_UniqueRef) DO
    BEGIN
     RepMacroFile^.GetUsingUniqueRef(MacroLine.MACL_LineRef,FALSE,FALSE,RepMacro);
     DisplayMacroReport(@RepMacro);
     MacroLineFile^.ReadRecord('GN',FALSE,FALSE,MacroLine,0);
    END;
  END;
 IF MacroLineFile^.OpenErr = 0 THEN MacroLineFile^.CloseFile;
 IF RepMacroFile^.OpenErr  = 0 THEN RepMacroFile^.CloseFile;
END;

FUNCTION TMacroBrowse.EventHandled : BOOLEAN;
BEGIN
 EventHandled:=FALSE;
 IF Funckey THEN
  CASE Ch1 OF
   FN_F5 : BEGIN
            DisplayAllReports(ListIndex);
            EventHandled := TRUE;
           END; {FN_F5}
  END; {CASE}
END;


PROCEDURE MacroHeaderBrowse;
VAR MacroBrowse : PMacroBrowse;
BEGIN
 New(MacroBrowse,Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH));
 MacroBrowse^.Run;
 Dispose(MacroBrowse,Done);
END;

END.

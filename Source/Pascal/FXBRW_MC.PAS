(****************************************************************************
*  UNIT          : FXLI_BRW                                                 *
*  AUTHOR        : N.S.                                                     *
*  DATE          : 09/05/96                                                 *
*  PURPOSE       : Formix Report Macro Browser                              *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXBrw_MC;
INTERFACE
USES CRT,F6STDCTV,FXMODCTV,F6STDUTL,F6STDUT1,F6STDWIN,F6STDWN1,F6STDBRW,
     F6StdRep,FXFMacro,FXPNet,FXPUsage,FXPProd,FXHelp,FXPRcp,FX_Ping,FXPSch,
     FXMenu,F6StdChr,FXPUser,FXPStock;

CONST WIN_X          = 2;             { WINDOW X Offset       (Global )     }
      WIN_Y          = 3;             { WINDOW Y Offset       (Global )     }
      WIN_WID        = 75;            { WINDOW Width          (Global )     }
      WIN_DEP        = 19;            { WINDOW Depth          (Global )     }
      X1 = WIN_X;
      Y1 = WIN_Y;
      X2 = WIN_X+WIN_WID;
      Y2 = WIN_Y+WIN_DEP;

      LIST_X         = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH     = WIN_WID-3;   { LIST BOX WIDTH        (Global )     }
      LIST_Y         = WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH     = WIN_DEP-LIST_Y+1;{ LIST BOX DEPTH    (Global )     }

      BLANK_LINE = ' ------------------------------ ------------------------------ ----------';
      READ_KEY   = 0;

TYPE TListItem = TRepMacroRecord;

     PBrowseList = ^TBrowseList;
     TBrowseList = ARRAY[1..LIST_DEPTH] OF TListItem;

     PRepMacroBrowse = ^TRepMacroBrowse;
     TRepMacroBrowse = OBJECT(TFileBrowser)

      BrowseWin   : WindowRecord;
      BrowseArray : PBrowseList;
      RecordBuff  : PRepMacroRecord;
      CalledAsLookup : BOOLEAN;
      RecordFound : BOOLEAN;

      CONSTRUCTOR Init(VAR RepMacroRec : TRepMacroRecord;LookUp : BOOLEAN);
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   Setup; Virtual;
      PROCEDURE   ClearListPos        (Element   : BYTE); Virtual;
      PROCEDURE   FillRecWithListKey  (Element   : BYTE); Virtual;
      FUNCTION    ReadRecordFunc      (Operation : STRING) : INTEGER; Virtual;
      PROCEDURE   FillListPosWithRec  (Element   : BYTE); Virtual;
      FUNCTION    ListPosIsEmpty      (Element   : BYTE) : BOOLEAN; Virtual;
      PROCEDURE   CopyListItem        (DestElement,SourceElement : BYTE); Virtual;
      FUNCTION    DispColour          (Element   : BYTE; Highlight : BOOLEAN): BYTE; Virtual;
      PROCEDURE   DisplayListItem     (Element   : BYTE); Virtual;
      FUNCTION    EventHandled        : BOOLEAN; Virtual;
      PROCEDURE   DeleteListItem      (Element   : BYTE); Virtual;
      PROCEDURE   EditListItem        (Element   : BYTE); Virtual;
     END;

PROCEDURE Edit_RepMacro;
FUNCTION  LookUpRepMacro(VAR RecordBuff : TREpMacroRecord) : BOOLEAN;
PROCEDURE DisplayMacroReport(RepMacroPtr : PRepMAcroRecord);

IMPLEMENTATION

CONSTRUCTOR TRepMacroBrowse.Init(VAR RepMacroRec : TRepMacroRecord;LookUp : BOOLEAN);
BEGIN
 CalledAsLookup := Lookup;
 RecordFound := FALSE;
 RecordBuff := @RepMacroRec;
 New(BrowseArray);
 IF (RepMacroFile^.OpenFile <> 0) THEN Esc_Flag :=TRUE;
 INHERITED Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH);
END;

DESTRUCTOR TRepMacroBrowse.Done;
BEGIN
 LoseWindow(BrowseWin);
 RepMacroFile^.CloseFile;
 Dispose(BrowseArray);
 INHERITED Done;
END;

PROCEDURE TRepMacroBrowse.DeleteListItem      (Element   : BYTE);
VAR RepMacroID : TMacroIDRef;
BEGIN
 RepMacroID := BrowseArray^[Element].REP_ID;
 Strip_Trailing_Char(RepMacroID,Length(RepMacroID),' ');
 IF YesNoWin('     Delete Record For RepMacro'+CRLF+
             Centered(RepMacroID,32)+CRLF+
             '        Are You Sure Y/N ') THEN
  BEGIN
   FillRecWithListKey(Element);
   IF RepMacroFile^.ReadRecord('EQ',TRUE,FALSE,RecordBuff^,0) = 0 THEN
    BEGIN
     RepMacroFile^.DeleteRecord
    END;
  END;
 RefreshListBox;
END;

PROCEDURE TRepMacroBrowse.EditListItem(Element   : BYTE);
BEGIN
 FillRecWithListKey(Element);
 ReadRecordFunc('EQ');
 IF CalledAsLookup THEN
  BEGIN
   Esc_Flag    := TRUE;
   RecordFound := TRUE;
   EXIT;
  END;
 DisplayMacroReport(RecordBuff);
END;

PROCEDURE TRepMacroBrowse.Setup;
VAR I :INTEGER;
VAR Lp : BYTE;
BEGIN
 FillChar(BrowseArray^,SizeOf(BrowseArray^),#0);
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,TRUE,SW_DEFAULT,SW_DEFAULT,BrowseWin);
 Header('Report RepMacro Browser',1);
 HighVideo;
 WriteAt(2,2,' Report                        ID                             Auto Print');
 WriteAt(1,3,BLANK_LINE);

 Footer('ENTER - Run Macro Report            F5 - Change Print',2);
 Footer('DELETE - Delete Order  ESC - EXIT',1);
 ForeColourScheme;
 RefreshListBox;
END;

PROCEDURE TRepMacroBrowse.ClearListPos        (Element   : BYTE);
BEGIN
 FillChar(BrowseArray^[Element],SizeOf(TListItem),#0);
END;

PROCEDURE TRepMacroBrowse.FillRecWithListKey  (Element   : BYTE);
BEGIN
 RecordBuff^ := BrowseArray^[Element];
END;

FUNCTION  TRepMacroBrowse.ReadRecordFunc(Operation : STRING) : INTEGER;
BEGIN
 ReadREcordFunc := RepMacroFile^.ReadRecord(Operation,FALSE,FALSE,RecordBuff^,Read_Key);
END;

PROCEDURE TRepMacroBrowse.FillListPosWithRec  (Element   : BYTE);
BEGIN
 BrowseArray^[Element] := RecordBuff^;
END;

FUNCTION  TRepMacroBrowse.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := NowtButSpace(BrowseArray^[Element].REP_ID);
END;

PROCEDURE TRepMacroBrowse.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray^[SourceElement],BrowseArray^[DestElement],SizeOf(TListItem));
END;

FUNCTION  TRepMacroBrowse.DispColour(Element   : BYTE; Highlight : BOOLEAN): BYTE;
BEGIN
 IF Highlight THEN
  DispColour := HiliteBarColour*16
 ELSE
  DispColour := INHERITED DispColour(Element,Highlight);
END;

PROCEDURE TRepMacroBrowse.DisplayListItem(Element   : BYTE);
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   WITH BrowseArray^[Element] DO
    BEGIN
     Write(' ',GetReportTitle(REP_Report),' ',REP_ID,'       ',BoolToYNStr(REP_PrintOnly,3));
    END;
  END
 ELSE
  BEGIN
   Write(BLANK_LINE);
  END;
END;

FUNCTION TRepMacroBrowse.EventHandled : BOOLEAN;
BEGIN
 EventHandled:=FALSE;
 IF Funckey THEN
  CASE Ch1 OF
   FN_F5 : BEGIN
            FillRecWithListKey(ListIndex);
            ReadRecordFunc('EQ');
            RecordBuff^.REP_PrintOnly := NOT RecordBuff^.REP_PrintOnly;
            FillListPosWithRec(ListIndex);
            RepMacroFile^.UpdateRecord(RecordBuff^);
            DisplayList(ListIndex,ListIndex);
            EventHandled := TRUE;
           END;
  END;
END;

PROCEDURE Edit_RepMacro;
VAR RepMacroBrowse : PRepMacroBrowse;
    RecordBuff     : TRepMacroRecord;
BEGIN
 FillChar(RecordBuff,SizeOf(RecordBuff),#0);
 New(RepMacroBrowse,Init(RecordBuff,FALSE));
 RepMacroBrowse^.Run;
 Dispose(RepMacroBrowse,Done);
END;

FUNCTION LookUpRepMacro(VAR RecordBuff : TREpMacroRecord) : BOOLEAN;
VAR RepMacroBrowse : PRepMacroBrowse;
BEGIN
 New(RepMacroBrowse,Init(RecordBuff,TRUE));
 RepMacroBrowse^.Run;
 LookUpRepMacro := RepMacroBrowse^.RecordFound;
 Dispose(RepMacroBrowse,Done);
END;

PROCEDURE DisplayMacroReport(RepMacroPtr : PRepMAcroRecord);
VAR TheReport : PReportObject;
    RepName   : STRING[80];
BEGIN
 TheReport := NIL;
 WITH RepMacroPtr^ DO
  BEGIN
   CASE REP_Report OF
    NetReportTitle        : TheReport := New(PIngredientUsage,Init);
    TranReportTitle       : TheReport := New(PTransactionReport,Init);
    AssignmentReportTitle : TheReport := New(PIngredientUsageReport,Init);
    ProdReportTitle       : TheReport := New(PProductReport,Init);
    RecipeReportTitle     : TheReport := New(PRecipeReport,Init);
    IngredientReportTitle : TheReport := New(PIngredientReport,Init);
    OrderReportTitle,
    ScheduleReportTitle   : TheReport := New(PScheduleReport,Init(False));
    UserWeighingTitle     : TheReport := New(PUserWeighingReport,init);
    StockReportTitle      : TheReport := New(PStockReport,Init);
   END;
   IF TheReport <> NIL THEN
    BEGIN
     TheReport^.RunMacroReport(REP_RepFilter);
     RepName := TheReport^.GetReportFileName;
     DISPOSE(TheReport,Done);
     PRINTERSELECTION := NOT REP_PrintOnly;
     Show_Report(RepName,cm_MacroReport,TRUE,REP_PrintOnly,REP_PrintOnly);
     PRINTERSELECTION := TRUE;
    END;
  END;
END;



END.

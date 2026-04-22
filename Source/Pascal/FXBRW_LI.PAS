(****************************************************************************
*  UNIT          : FXLI_BRW                                                 *
*  AUTHOR        : S. Wright & N.S.                                         *
*  DATE          : 09/05/96                                                 *
*  PURPOSE       : Formix Lot Ingredient Cross Reference Browser            *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXBRW_LI;
INTERFACE
USES CRT,F6STDCTV,FXMODCTV,F6STDUTL,F6STDUT1,F6STDWIN,F6STDWN1,F6STDBRW,
     F6DTCONV,FXFRcp,FX_WOE,FX_RPE,FXFILot,FXFIngr,FXBRW_IN;

PROCEDURE Edit_Ingredient_Lot_Values;


IMPLEMENTATION

CONST WIN_X          = 15;            { WINDOW X Offset       (Global )     }
      WIN_Y          = 3;             { WINDOW Y Offset       (Global )     }
      WIN_WID        = 46;            { WINDOW Width          (Global )     }
      WIN_DEP        = 19;            { WINDOW Depth          (Global )     }
      X1 = WIN_X;
      Y1 = WIN_Y;
      X2 = WIN_X+WIN_WID;
      Y2 = WIN_Y+WIN_DEP;

      LIST_X         = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH     = WIN_WID-3;   { LIST BOX WIDTH        (Global )     }
      LIST_Y         = WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH     = WIN_DEP-LIST_Y+1;{ LIST BOX DEPTH    (Global )     }

      BLANK_LINE = '  ----   ----------   ----------------';
      READ_KEY   = 0;

TYPE TListItem = TLotIngredientRecord;

     PBrowseList = ^TBrowseList;
     TBrowseList = ARRAY[1..LIST_DEPTH] OF TListItem;

     PIngLotBrowse = ^TIngLotBrowse;
     TIngLotBrowse = OBJECT(TFileBrowser)

      BrowseWin   : WindowRecord;
      BrowseArray : PBrowseList;
      RecordBuff  : TLotIngredientRecord;

      CONSTRUCTOR Init(Xp,Yp,Width,Depth : BYTE);
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
      PROCEDURE   InsertListItem; Virtual;
      PROCEDURE   AddEditRecord(Edit : BOOLEAN);
     END;


CONSTRUCTOR TIngLotBrowse.Init(Xp,Yp,Width,Depth : BYTE);
BEGIN
 New(BrowseArray);
 IF (LotIngredientFile^.OpenFile <> 0) THEN Esc_Flag :=TRUE;
 INHERITED Init(Xp,Yp,Width,Depth);
END;

DESTRUCTOR TIngLotBrowse.Done;
BEGIN
 LoseWindow(BrowseWin);
 LotIngredientFile^.CloseFile;
 Dispose(BrowseArray);
 INHERITED Done;
END;

PROCEDURE TIngLotBrowse.DeleteListItem      (Element   : BYTE);
BEGIN
 IF YesNoWin('    Delete Record For Ingredient'+CRLF+
             '          '+BrowseArray^[Element].LI_Ingredient+CRLF+
             '          Are You Sure Y/N ') THEN
  BEGIN
   FillRecWithListKey(Element);
   IF LotIngredientFile^.ReadRecord('EQ',TRUE,FALSE,RecordBuff,0) = 0 THEN
    BEGIN
     LotIngredientFile^.DeleteRecord
    END;
  END;
 RefreshListBox;
END;

PROCEDURE TIngLotBrowse.EditListItem(Element   : BYTE);
BEGIN
 FillRecWithListKey(Element);
 ReadRecordFunc('EQ');
 AddEditRecord(TRUE);
END;

PROCEDURE TIngLotBrowse.InsertListItem;
BEGIN
 LotIngredientFile^.InitRecord(RecordBuff);
 AddEditRecord(FALSE);
END;

PROCEDURE TIngLotBrowse.Setup;
VAR I :INTEGER;
VAR Lp : BYTE;
BEGIN
 HBarXOffSet :=2;
 FillChar(BrowseArray^,SizeOf(BrowseArray^),#0);
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,
		TRUE,NormBack*16+LowFore,NormBack*16+LowFore,BrowseWin);
 Header('Lot Ingredient Browser',1);
 HighVideo;

 WriteAt(2,2,' M-ID   Ingredient   Lot Number  ');
 WriteAt(1,3,BLANK_LINE);

 Footer('INSERT - Add Record  ENTER - Edit',2);
 Footer('DELETE - Delete Record ESC - EXIT',1);
 ForeColourScheme;
 RefreshListBox;
END;

PROCEDURE TIngLotBrowse.ClearListPos        (Element   : BYTE);
BEGIN
 FillChar(BrowseArray^[Element],SizeOf(TListItem),#0);
END;

PROCEDURE TIngLotBrowse.FillRecWithListKey  (Element   : BYTE);
BEGIN
 RecordBuff := BrowseArray^[Element];
END;

FUNCTION  TIngLotBrowse.ReadRecordFunc(Operation : STRING) : INTEGER;
BEGIN
 LotIngredientFile^.ReadRecord(Operation,FALSE,FALSE,RecordBuff,Read_Key);
 ReadRecordFunc := LotIngredientFile^.BtrvErr;
END;



PROCEDURE TIngLotBrowse.FillListPosWithRec  (Element   : BYTE);
BEGIN
 BrowseArray^[Element] := RecordBuff;
END;

FUNCTION  TIngLotBrowse.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := NowtButSpace(BrowseArray^[Element].LI_Ingredient);
END;

PROCEDURE TIngLotBrowse.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray^[SourceElement],BrowseArray^[DestElement],SizeOf(TListItem));
END;

FUNCTION  TIngLotBrowse.DispColour(Element   : BYTE; Highlight : BOOLEAN): BYTE;
BEGIN
 IF Highlight THEN
  DispColour := HiliteBarColour*16
 ELSE
  DispColour := INHERITED DispColour(Element,Highlight);
END;

PROCEDURE TIngLotBrowse.DisplayListItem(Element   : BYTE);
VAR SaveCol : BYTE;
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   WITH BrowseArray^[Element] DO
    BEGIN
     Write('    ',IntToZeroStr(LI_ScaleID,2),'     ',LI_Ingredient,'   ',LI_LotNumber:16);
    END;
  END
 ELSE
  BEGIN
   Write(BLANK_LINE);
  END;
END;

FUNCTION TIngLotBrowse.EventHandled : BOOLEAN;
BEGIN
 EventHandled:=FALSE;
END;

PROCEDURE TIngLotBrowse.AddEditRecord(Edit : BOOLEAN);
CONST EditX = 19;
VAR TheWin : WindowRecord;
    EditPos : INTEGER;

 PROCEDURE SetUpScreen;
 BEGIN
  BackColourScheme;
  SetWindow(20,10,60,18,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,TheWin);
  IF Edit THEN
   Header('Edit Lot/Ingredient Details',1)
  ELSE
   Header('Add Lot/Ingredient Details',1);
  Footer('ESC - Save   F10 - Abort Edit',1);
  WriteAt(5,3,' M-ID       : [  ]');
  HighWriteAt(5,4,' Ingredient : [        ]');
  WriteAt(5,5,' Lot        : [              ]');
  ForeColourScheme;
 END;

 PROCEDURE DisplayEditFields;
 BEGIN
  WITH RecordBuff DO
   BEGIN
    WriteField(EditX,3,IntToZeroStr(LI_ScaleID,2),TRUE);
    WriteField(EditX,4,LI_Ingredient,TRUE);
    WriteField(EditX,5,LI_LotNumber,TRUE);
   END;
 END;

 PROCEDURE EditValue;

  PROCEDURE ReadLine(VAR S :STRING; Len: BYTE);
  VAR WrkStr : STRING[80];
      I      : INTEGER;
  BEGIN
   WrkStr := S;
   GetLine(WrkStr,Len,EditX,2+EditPos);
   FOR I := 1 TO Length(WrkStr) DO
    BEGIN
     IF (WrkStr[I] = ' ') THEN CONTINUE;
     IF ((WrkStr[I]<'A') OR (WrkStr[I] > 'Z')) AND
        ((WrkStr[I]<'0') OR (WrkStr[I] > '9')) THEN EXIT;
    END;
   S := WrkStr;
  END;


 BEGIN
  CASE EditPos OF
   1 : GetInteger(INTEGER(RecordBuff.LI_ScaleID),2,EditX,3);
   2 : ReadLine(RecordBuff.LI_Ingredient,8);
   3 : ReadLine(RecordBuff.LI_LotNumber,14);
  END;
 END;

 PROCEDURE CheckCh1;
 VAR TransferBuff : TIngredient_Record;
 BEGIN
  CASE Ch1 OF
   NEXT : IF NOT Edit THEN
           IF EditPos<3 THEN Inc(EditPos) ELSE EditPos :=1;
   PREV : IF NOT Edit THEN
           IF EditPos>1 THEN Dec(EditPos) ELSE EditPos :=3;
   FN_F1: IF EditPos = 2 THEN
    BEGIN
     TransferBuff.ING_Ingredient := RecordBuff.LI_Ingredient;
     IngredientLookup(@TransferBuff);
     IF NOT NowtButSpace(TransferBuff.ING_Ingredient) THEN
      RecordBuff.LI_Ingredient  := TransferBuff.ING_Ingredient;
    END;
  END;
 END;

BEGIN
 SetUpScreen;
 DisplayEditFields;
 IF Edit THEN EditPos := 3
 ELSE EditPos := 1;
 REPEAT
  EditValue;
  DisplayEditFields;
  CheckCh1;
 UNTIL (Ch1 = ESC) OR (Ch1=FN_F10);
 IF (Ch1 = ESC) AND NOT NowtButSpace(RecordBuff.LI_Ingredient) THEN
  BEGIN
   IF Edit THEN Show_Btrv_Err(LotIngredientFile^.UpdateRecord(RecordBuff))
   ELSE Show_Btrv_Err(LotIngredientFile^.AddRecord(RecordBuff));
  END;
 LoseWindow(TheWin);
 ch1 := ' ';
 Esc_Flag := FALSE;
 RefreshListBox;
END;

PROCEDURE Edit_Ingredient_Lot_Values;
VAR IngLotBrowse : PIngLotBrowse;
BEGIN
 New(IngLotBrowse,Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH));
 IngLotBrowse^.Run;
 Dispose(IngLotBrowse,Done);
END;

END.

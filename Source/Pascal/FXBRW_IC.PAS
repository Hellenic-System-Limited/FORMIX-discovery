(****************************************************************************
*  UNIT          : FXIC_BRW                                                 *
*  AUTHOR        : S. Wright                                                *
*  DATE          : 09/05/96                                                 *
*  PURPOSE       : Formix Lot Ingredient Cross Reference Browser            *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXBRW_IC;
INTERFACE
USES CRT,F6STDCTV,FXMODCTV,F6STDUTL,F6STDUT1,F6STDWIN,F6STDWN1,F6STDBRW,FXCfg,
     F6DTCONV,FXFIngr,FXBRW_IN,FXFCost;

PROCEDURE Edit_Ingredient_Costings;
IMPLEMENTATION

CONST
      WIN_Y      = 3;             { WINDOW Y Offset       (Global )     }
      WIN_DEP    = 19;            { WINDOW Depth          (Global )     }
      READ_KEY   = 0;

TYPE TListItem = TCostRecord;

     PBrowseList = ^TBrowseList;
     TBrowseList = ARRAY[1..15] OF TListItem;

     PIngredientCostBrowse = ^TIngredientCostBrwose;
     TIngredientCostBrwose = OBJECT(TFileBrowser)

      BrowseWin   : WindowRecord;
      BrowseArray : PBrowseList;
      RecordBuff  : TCostRecord;
      BLANK_LINE  : STRING[80];
      WIN_WID     : INTEGER;
      WIN_X       : INTEGER;
      LIST_X      : INTEGER;
      LIST_WIDTH  : INTEGER;
      LIST_Y      : INTEGER;
      LIST_DEPTH  : INTEGER;


      CONSTRUCTOR Init;
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


CONSTRUCTOR TIngredientCostBrwose.Init;
BEGIN
 BLANK_LINE := '  ---------- ---------------- --------- ---------';
 IF (Config_Rec^.Conf_ShowCostWeightUsed) THEN
  BEGIN
   Blank_Line := Blank_Line+' --------- ---------';
   WIN_WID := 71;           { WINDOW Width          (Global )     }
   WIN_X   := 4;            { WINDOW X Offset       (Global )     }
  END
 ELSE
  BEGIN
   Win_Wid := 50;
   WIN_X   := 14;            { WINDOW X Offset       (Global )     }
  END;

 LIST_X     := WIN_X+1;     { LIST BOX X Offset     (Global )     }
 LIST_WIDTH := WIN_WID-3;   { LIST BOX WIDTH        (Global )     }
 LIST_Y     := WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
 LIST_DEPTH := WIN_DEP-LIST_Y+1;{ LIST BOX DEPTH    (Global )     }

 New(BrowseArray);
 IF (CostFile^.OpenFile <> 0) THEN Esc_Flag :=TRUE;
 INHERITED Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH);
END;

DESTRUCTOR TIngredientCostBrwose.Done;
BEGIN
 LoseWindow(BrowseWin);
 CostFile^.CloseFile;
 Dispose(BrowseArray);
 INHERITED Done;
END;

PROCEDURE TIngredientCostBrwose.DeleteListItem(Element : BYTE);
BEGIN
 IF YesNoWin('    Delete Record For Ingredient'+CRLF+
             '          '+BrowseArray^[Element].COST_Ingredient+CRLF+
             '          Are You Sure Y/N ') THEN
  BEGIN
   FillRecWithListKey(Element);
   IF CostFile^.ReadRecord('EQ',TRUE,FALSE,RecordBuff,0) = 0 THEN
    BEGIN
     CostFile^.DeleteRecord
    END;
  END;
 RefreshListBox;
END;

PROCEDURE TIngredientCostBrwose.EditListItem(Element : BYTE);
BEGIN
 FillRecWithListKey(Element);
 ReadRecordFunc('EQ');
 AddEditRecord(TRUE);
 RefreshListBox;
END;

PROCEDURE TIngredientCostBrwose.InsertListItem;
BEGIN
 CostFile^.InitRecord(RecordBuff);
 AddEditRecord(FALSE);
 RefreshListBox;
END;

PROCEDURE TIngredientCostBrwose.Setup;
VAR I :INTEGER;
    Lp : BYTE;
BEGIN
 HBarXOffSet :=2;
 FillChar(BrowseArray^,SizeOf(BrowseArray^),#0);
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,
		TRUE,NormBack*16+LowFore,NormBack*16+LowFore,BrowseWin);
 Header('Ingredient/Lot Cost Browser',1);
 HighVideo;

 IF (Config_Rec^.Conf_ShowCostWeightUsed) THEN
  BEGIN
   WriteAt(3,2,'Ingredient Lot Number          Cost   Weight In      Used   Aborted');
  END
 ELSE
  BEGIN
   WriteAt(3,2,'Ingredient Lot Number          Cost   Weight In');
  END;
 WriteAt(1,3,BLANK_LINE);

 Footer('INSERT - Add Record  ENTER - Edit',2);
 Footer('DELETE - Delete Record ESC - EXIT',1);
 ForeColourScheme;
 RefreshListBox;
END;

PROCEDURE TIngredientCostBrwose.ClearListPos(Element : BYTE);
BEGIN
 FillChar(BrowseArray^[Element],SizeOf(TListItem),#0);
END;

PROCEDURE TIngredientCostBrwose.FillRecWithListKey(Element : BYTE);
BEGIN
 RecordBuff := BrowseArray^[Element];
END;

FUNCTION  TIngredientCostBrwose.ReadRecordFunc(Operation : STRING) : INTEGER;
BEGIN
 CostFile^.ReadRecord(Operation,FALSE,FALSE,RecordBuff,Read_Key);
 ReadRecordFunc := CostFile^.BtrvErr;
END;

PROCEDURE TIngredientCostBrwose.FillListPosWithRec(Element : BYTE);
BEGIN
 BrowseArray^[Element] := RecordBuff;
END;

FUNCTION TIngredientCostBrwose.ListPosIsEmpty(Element : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := NowtButSpace(BrowseArray^[Element].COST_Ingredient);
END;

PROCEDURE TIngredientCostBrwose.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray^[SourceElement],BrowseArray^[DestElement],SizeOf(TListItem));
END;

FUNCTION TIngredientCostBrwose.DispColour(Element : BYTE; Highlight : BOOLEAN): BYTE;
BEGIN
 IF Highlight THEN
  DispColour := HiliteBarColour*16
 ELSE
  DispColour := INHERITED DispColour(Element,Highlight);
END;

PROCEDURE TIngredientCostBrwose.DisplayListItem(Element : BYTE);
VAR SaveCol : BYTE;
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   WITH BrowseArray^[Element] DO
    BEGIN
     Write('  ',COST_Ingredient+'  ':10,' ',COST_LotNumber+'  ':16,' ',COST_cost:9:3,' ',COST_Weightin:9:3);
     IF (Config_Rec^.Conf_ShowCostWeightUsed) THEN
      BEGIN
       Write(' ',COST_Weighed:9:3,' ',COST_Wasted:9:3)
      END;
    END;
  END
 ELSE
  BEGIN
   Write(BLANK_LINE);
  END;
END;

FUNCTION TIngredientCostBrwose.EventHandled : BOOLEAN;
BEGIN
 EventHandled:=FALSE;
END;

PROCEDURE TIngredientCostBrwose.AddEditRecord(Edit : BOOLEAN);
CONST EditX = 19;
VAR TheWin : WindowRecord;
    EditPos : INTEGER;

 PROCEDURE SetUpScreen;
 BEGIN
  BackColourScheme;
  SetWindow(18,09,58,18,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,TheWin);

  IF Edit THEN
   Header('Edit Ingredient/Lot Cost Details',1)
  ELSE
   Header('Add Ingredient/Lot Cost Details',1);
  Footer('ESC - Save   F10 - Abort Edit',1);

  HighWriteAt(5,3,' Ingredient : [        ]');
      WriteAt(5,4,' Lot        : [              ]');
      WriteAt(5,5,' Cost       : [         ]');
      WriteAt(5,6,' Weight In  : [         ]');
  ForeColourScheme;
 END;

 PROCEDURE DisplayEditFields;
 BEGIN
  WITH RecordBuff DO
   BEGIN
    WriteField(EditX,3,COST_Ingredient,TRUE);
    WriteField(EditX,4,COST_LotNumber,TRUE);
    WriteField(EditX,5,DoubleToZeroStr(COST_Cost,9,3),TRUE);
    WriteField(EditX,6,DoubleToZeroStr(COST_Weightin,9,3),TRUE);
   END;
 END;

 PROCEDURE EditValue;
 Var InputStr : STRING[9];

  PROCEDURE ReadLine(VAR S :STRING; Len: BYTE);
  VAR WrkStr : STRING[8];
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

  PROCEDURE GetDouble(x,y : INTEGER;VAR Float : DOUBLE;Size,dp : INTEGER);
  VAR WrkStr : STRING;
      ErrInt : INTEGER;
  BEGIN
   WrkStr := DoubleToZeroStr(Float,Size,dp);
   GetFloat(x,y,WrkStr,Size,Dp);
   VAL(WrkStr,Float,ErrInt);
  END;

 BEGIN
  CASE EditPos OF
   1 : IF NOT Edit THEN ReadLine(RecordBuff.COST_Ingredient,8);
   2 : IF NOT Edit THEN ReadLine(RecordBuff.COST_LotNumber,14);
   3 : GetDouble(EditX,5,RecordBuff.COST_cost,9,3);
   4 : GetDouble(EditX,6,RecordBuff.COST_Weightin,9,3);
  END;
 END;

 PROCEDURE CheckCh1;
 VAR TransferBuff : TIngredient_Record;
 BEGIN
  CASE Ch1 OF
   NEXT : IF EditPos<4 THEN Inc(EditPos) ELSE EditPos :=1;
   PREV : IF EditPos>1 THEN Dec(EditPos) ELSE EditPos :=4;
   FN_F1: IF EditPos = 1 THEN
    BEGIN
     TransferBuff.ING_Ingredient := RecordBuff.COST_Ingredient;
     IngredientLookup(@TransferBuff);
     IF NOT NowtButSpace(TransferBuff.ING_Ingredient) THEN
      BEGIN
       RecordBuff.COST_Ingredient  := TransferBuff.ING_Ingredient;
       RecordBuff.COST_Cost        := TransferBuff.ING_Cost;
      END;
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
 IF (Ch1 = ESC) AND NOT NowtButSpace(RecordBuff.COST_Ingredient) AND
   (NOT NowtButSpace(RecordBuff.COST_LotNumber) OR Config_Rec^.CONF_GlobalLot) THEN
  BEGIN
   IF Edit THEN Show_Btrv_Err(CostFile^.UpdateRecord(RecordBuff))
   ELSE Show_Btrv_Err(CostFile^.AddRecord(RecordBuff));
  END;
 LoseWindow(TheWin);
 ch1 := ' ';
 Esc_Flag := FALSE;
END;

PROCEDURE Edit_Ingredient_Costings;
VAR CostBrowse : PIngredientCostBrowse;
BEGIN
 New(CostBrowse,Init);
 CostBrowse^.Run;
 Dispose(CostBrowse,Done);
END;

END.

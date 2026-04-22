(****************************************************************************
*  UNIT          : FX_EDesc                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 08/05/96                                                 *
*  PURPOSE       : FORMIX RECIPE EDIT                                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FX_EDesc;
INTERFACE
USES CRT,F6STDCTV,F6STDWN1,F6STDWIN,F6STDUTL,F6STDUT1,F6STDBRW,F6SCREEN,
     FX_EDIT,F6DTCONV,F6RECCHG,FXMODCTV,FXCFG,FXFProd;


CONST

      BLANK_LINE     = '  -------  ------------------------------------------';
      Read_Key       = 0;

      WIN_X          = 7;             { WINDOW X Offset       (Global )     }
      WIN_Y          = 4;             { WINDOW Y Offset       (Global )     }
      WIN_WID        = Length(BLANK_Line)+3;            { WINDOW Width          (Global )     }
      WIN_DEP        = 19;            { WINDOW Depth          (Global )     }
      X1 = WIN_X;
      Y1 = WIN_Y;
      X2 = WIN_X+WIN_WID;
      Y2 = WIN_Y+WIN_DEP;

      LIST_X         = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH     = WIN_WID-3;   { LIST BOX WIDTH        (Global )     }
      LIST_Y         = WIN_Y+5;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH     = WIN_DEP-7;   { LIST BOX DEPTH    (Global )     }




TYPE
     PProdDescItem = ^TProdDescItem;
     TProdDescItem = PACKED RECORD
      Description : String[40];
      LineNo      : INTEGER;
      Next        : PProdDescItem;
     END;

    PProdDescEdit = ^TProdDescEdit;
    TProdDescEdit = OBJECT(TFileBrowser)

      DescRec         : TProdDescription;
      ListHeader      : PProdDescItem;
      RecBuff         : PProdDescItem;
      ToRead          : INTEGER;
      ListSize        : INTEGER;
      ListPos         : INTEGER;
      WinRec          : WindowRecord;
      Product         : TProductRef;
      MethodNo        : INTEGER;
      BrowseArray     : ARRAY[1..LIST_DEPTH] OF PProdDescItem;
      AnEditOccured   : BOOLEAN;
      RecordWasSaved  : BOOLEAN;
      InstructionName : STRING[40];

      CONSTRUCTOR Init(ProdCode : TProductRef;Method : INTEGER);
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   Setup; Virtual;
      FUNCTION    ReadRecordFunc       (Operation : STRING) : INTEGER; Virtual;
      PROCEDURE   FillRecWithListKey   (Element   : BYTE); Virtual;
      PROCEDURE   DisplayListItem      (Element   : BYTE); Virtual;

      PROCEDURE   DisposeList;
      PROCEDURE   EditListItem        (Element   : BYTE); Virtual;
      FUNCTION    ReadItem(I : INTEGER) : INTEGER;
      FUNCTION    ListPosIsEmpty      (Element   : BYTE) : BOOLEAN; Virtual;
      PROCEDURE   InsertListItem; Virtual;
      FUNCTION    EventHandled : BOOLEAN; VIRTUAL;
      PROCEDURE   Save_Details;
      PROCEDURE   Move_Item_Down_List(Element : WORD);
      PROCEDURE   Move_Item_Up_List(Element : WORD);
      PROCEDURE   FillListPosWithRec(Element   : BYTE); Virtual;
      PROCEDURE   ClearListPos        (Element   : BYTE); Virtual;
      PROCEDURE   CopyListItem        (DestElement,SourceElement : BYTE); Virtual;
      FUNCTION    EditItem(VAR pItem : PProdDescItem) : BOOLEAN;
      PROCEDURE   DeleteListItem(Element : BYTE); VIRTUAL;
      FUNCTION    GetInstruction : STRING;
      FUNCTION    GetDescriptionLine(HeaderStr : STRING;VAR DescLine : STRING) : BOOLEAN;
      PROCEDURE   CleanUp;
      PROCEDURE   RenumberRemainingList;
     END;

IMPLEMENTATION

CONSTRUCTOR TProdDescEdit.Init(ProdCode : TProductRef; Method : INTEGER);
BEGIN
 ToRead   := 0;
 ListPos  := 0;
 RecBuff  := NIL;
 ListHEader := NIL;
 Product  := ProdCode;
 MethodNo := Method;
 AnEditOccured := FALSE;
 RecordWasSaved := FALSE;
 IF ProdDescFile^.OpenFile <> 0 THEN Esc_Flag := TRUE;
 INHERITED Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH);
END;

DESTRUCTOR TProdDescEdit.Done;
BEGIN
 IF AnEditOccured THEN
  BEGIN
   IF YesNoWin('   Instructions Have Not Yet'+CRLF+
               '    Been Saved. Save Now Y/N') THEN Save_Details;
  END;
 DisposeList;
 ProdDescFile^.CloseFile;
 INHERITED Done;
END;


PROCEDURE TProdDescEdit.CleanUp;
BEGIN
 LoseWindow(WinRec);
END;

FUNCTION  TProdDescEdit.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := BrowseArray[Element] = NIL;
END;

PROCEDURE TProdDescEdit.FillListPosWithRec(Element   : BYTE);
BEGIN
 BrowseArray[Element] := RecBuff;
END;

PROCEDURE TProdDescEdit.ClearListPos(Element   : BYTE);
BEGIN
 BrowseArray[Element] := NIL;
END;

PROCEDURE TProdDescEdit.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 BrowseArray[DestElement] := BrowseArray[SourceElement];
END;

PROCEDURE TProdDescEdit.FillRecWithListKey   (Element   : BYTE);
BEGIN
 RecBuff := BrowseArray[Element];
 IF RecBuff <> NIL THEN
  ToRead := RecBuff^.LineNo
 ELSE ToRead := 1;
END;

FUNCTION TProdDescEdit.GetDescriptionLine(HeaderStr : STRING;VAR DescLine : STRING) : BOOLEAN;
VAR EditWin : WindowRecord;
    ABortEdit : BOOLEAN;
BEGIN
 BackColourScheme;
 SetWindow(12,10,60,16,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,EditWin);
 Header(HeaderStr,1);
 Footer('ESC - Save   F10 - Abort Edit',1);
 ForeColourScheme;
 AbortEdit := FALSE;
 REPEAT
  GetLine(DescLine,40,3,3);
  IF FuncKey AND (ch1 = FN_F10) THEN
   BEGIN
    AbortEdit := YesNoWin('         Abort Edit'+CRLF+
                          '       Are You Sure Y/N');
   END
  ELSE
   BEGIN
    IF (ch1 = ESC) AND (NowtButSpace(DescLine)) THEN
     BEGIN
      AbortEdit := TRUE;
      FuncKey   := TRUE;
      ch1 := FN_F10;
     END;
   END;

  IF (NOT AbortEdit) THEN
   BEGIN
    IF NowtButSpace(DescLine) THEN
     BEGIN
      Disp_Error_Msg('This Field Cannot Be Left Blank');
      Ch1 :=' ';
     END;
   END;
 UNTIL (Ch1 = ESC) OR (Ch1 = ENTER) OR AbortEdit;
 LoseWindow(EditWin);
 GetDescriptionLine := NOT AbortEdit;
 IF (Ch1 = ESC) OR (Ch1 = ENTER) THEN AnEditOccured := TRUE;
END;

FUNCTION TProdDescEdit.GetInstruction : STRING;
BEGIN
 InstructionName := GetInstructionName(Product,MethodNo);
 IF NowtButSpace(InstructionName) THEN
  BEGIN
   REPEAT
    GetDescriptionLine('Enter Method Name',InstructionName);
   UNTIL (ch1 = FN_F10) OR (NOT NowtButSpace(InstructionName));
  END;
 GetInstruction := InstructionName;
 IF Ch1 = FN_F10 THEN ESC_Flag := TRUE ELSE Esc_Flag := FALSE;
 ch1 := ' ';
END;

PROCEDURE TProdDescEdit.RenumberRemainingList;
VAR Loop : PProdDescItem;
    NewLineNo : INTEGER;
BEGIN
 Loop := ListHeader;
 NewLineNo := 0;
 WHILE (Loop<>NIL) DO
  BEGIN
   INC(NewLineNo);
   Loop^.LineNo := NewLineNo;
   Loop := Loop^.Next;
  END;
END;

PROCEDURE TProdDescEdit.DeleteListItem(Element : BYTE);
VAR Loop : PProdDescItem;
BEGIN
 FillRecWithListKey(Element);
 IF RecBuff <> NIL THEN
  BEGIN
   IF YesNoWin ('       Delete Instruction'+CRLF+
                '        Are You Sure Y/N') THEN
    BEGIN
     IF ListHeader = RecBuff THEN
      BEGIN
       ListHeader := ListHeader^.Next;
      END
     ELSE
      BEGIN
       Loop := ListHeader;
       WHILE (Loop<>NIL) AND (Loop^.Next <> RecBuff) DO
        Loop := Loop^.Next;
       IF Loop <> NIL THEN
        Loop^.Next := RecBuff^.Next;
      END;
     Dispose(RecBuff);
     RecBuff :=NIL;
     BrowseArray[Element] := NIL;
     RenumberRemainingList;
     RefreshListBox;
     AnEditOccured := TRUE;
    END;
  END;
END;

PROCEDURE TProdDescEdit.DisposeList;
VAR Loop,DelRec : PProdDescItem;
BEGIN
 Loop := ListHeader;
 WHILE (Loop <> NIL) DO
  BEGIN
   DelRec := Loop;
   Loop := Loop^.Next;
   Dispose(DelRec);
  END;
END;

PROCEDURE TProdDescEdit.Move_Item_Down_List(Element : WORD);
Var ThisItem,NextItem : PProdDescItem;
    Temp : TProdDescItem;
BEGIN
 IF BrowseArray[Element] = NIL THEN EXIT;
 ReadItem(BrowseArray[Element]^.LineNo);
 IF RecBuff = NIL THEN EXIT;
 ThisItem := RecBuff;
 ReadItem(BrowseArray[Element]^.LineNo+1);
 IF RecBuff = NIL THEN EXIT;
 NextItem := RecBuff;
 Temp := ThisItem^;
 ThisItem^.Description := NextItem^.Description;
 NextItem^.Description := Temp.Description;
 IF ListIndex < LIST_DEPTH THEN
  BEGIN
   INC(ListIndex);
  END
 ELSE
  BEGIN
   FillRecWithListKey(LIST_DEPTH);
   FillListUpFrom(LIST_DEPTH);
  END;
 RefreshListBox;
 AnEditOccured := TRUE;
END;

PROCEDURE TProdDescEdit.Move_Item_Up_List(Element : WORD);
Var ThisItem,NextItem : PProdDescItem;
    Temp : TProdDescItem;
BEGIN
 IF BrowseArray[Element] = NIL THEN EXIT;
 ReadItem(BrowseArray[Element]^.LineNo);
 IF RecBuff = NIL THEN EXIT;
 ThisItem := RecBuff;
 ReadItem(BrowseArray[Element]^.LineNo-1);
 IF RecBuff = NIL THEN EXIT;
 NextItem := RecBuff;
 Temp := ThisItem^;
 ThisItem^.Description := NextItem^.Description;
 NextItem^.Description := Temp.Description;
 IF ListIndex > 1 THEN
  BEGIN
   DEC(ListIndex);
  END
 ELSE
  BEGIN
   ListIndex := 1;
   ReadItem(BrowseArray[1]^.LineNo-1);
   BrowseArray[1] := RecBuff;
  END;
 RefreshListBox;
 AnEditOccured := TRUE;
END;


PROCEDURE TProdDescEdit.Setup;
VAR I : INTEGER;

  PROCEDURE BuildList;
  VAR Last,NewItem : PProdDescItem;
      ReadErr      : INTEGER;

    PROCEDURE CopyValues(VAR pDest : PProdDescItem);
    BEGIN
     Inc(ListSize);
     WITH pDest^ DO
      BEGIN
       Description := DescRec.PD_Description;
       LineNo      := DescRec.PD_LineNo;
       Next        := NIL;
      END;
    END;

  BEGIN
   DescRec.PD_ProductCode := Product;
   DescRec.PD_Method      := MethodNo;
   DescRec.PD_LineNo      := 1;
   ReadErr := ProdDescFile^.ReadRecord('GE',FALSE,FALSE,DescRec,0);
   WHILE (ReadErr = 0) AND (DescRec.PD_ProductCode = Product) AND
    (DescRec.PD_Method = MethodNo) DO
    BEGIN
     IF ListHeader = NIL THEN
      BEGIN
       New(ListHeader);
       CopyValues(ListHeader);
       Last := ListHeader;
      END
     ELSE
      BEGIN
       New(NewItem);
       CopyValues(NewItem);
       Last^.Next := NewItem;
       Last := NewItem;
      END;
     ReadErr := ProdDescFile^.ReadRecord('GN',FALSE,FALSE,DescRec,0);
    END;
  END;

BEGIN
 FOR I := 1 TO LIST_DEPTH DO
  BrowseArray[I] := NIL;
 ListSize := 0;
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,WinRec);
 BuildList;
 Header('Cooking Instructions For Product '+Product,1);
 Header(GetInstruction,2);
 HighVideo;
 WriteAt(2,3,'   Order  Instruction                     ');
 WriteAt(1,4,BLANK_LINE);
 Footer('F2 - Edit Title ENTER - Edit INS - Add  F10 - Abondon',2);
 Footer('F5 - Move Inst Down   F6 - Move Inst Up  ESC - EXIT',1);
 ForeColourScheme;
 RefreshListBox;
END;

FUNCTION TProdDescEdit.ReadItem(I : INTEGER) : INTEGER;
VAR Loop : PProdDescItem;
BEGIN
 IF (I = 0) OR (I>ListSize) THEN
  BEGIN
   ReadItem := 9;
   RecBuff  := NIL;
  END
 ELSE
  BEGIN
   ListPos := I;
   Loop    := ListHeader;
   WHILE (I>1) AND (Loop<>NIL) DO
    BEGIN
     Loop := Loop^.Next;
     Dec(I);
    END;
   IF Loop = NIL THEN ReadItem := 4
   ELSE
    BEGIN
     ReadItem := 0;
     RecBuff  := Loop;
    END;
  END;
END;

FUNCTION  TProdDescEdit.ReadRecordFunc       (Operation : STRING) : INTEGER;
VAR ReadErr : INTEGER;
BEGIN
 CASE Operation[1] OF
  'G' : CASE Operation[2] OF
         'F' : BEGIN
                RecBuff := ListHeader;
               END;
         'L' : BEGIN
                ReadErr := ReadItem(ListSize);
               END;
         'E' : BEGIN
                ReadErr := ReadItem(ToRead);
               END;
         'T' : BEGIN
                ReadErr := ReadItem(ToRead+1);
               END;
         'D' : BEGIN
                ReadErr := ReadItem(ToRead);
               END;
         'N' : BEGIN
                ReadErr := ReadItem(ListPos+1);
               END;
         'P' : BEGIN
                ReadErr := ReadItem(ListPos-1);
               END;
        END;
  'L' : CASE Operation[2] OF
         'E' :BEGIN
               ReadErr := ReadItem(ToRead);
              END;
         'T' :BEGIN
               ReadErr := ReadItem(ToRead-1);
              END;
        END;
  'E' : BEGIN
         ReadErr := ReadItem(ToRead);
        END;
 END;
 ReadRecordFunc:=ReadErr;
END;

PROCEDURE TProdDescEdit.DisplayListItem      (Element   : BYTE);
BEGIN
 RecBuff := BrowseArray[Element];
 IF RecBuff <> NIL THEN
  BEGIN
   With RecBuff^ DO
    BEGIN
     Write('   ',LineNo:6,'  ',Description,'  ');
    END;
  END
 ELSE
  Write(Blank_Line);
END;

FUNCTION TProdDescEdit.EditItem(VAR pItem : PProdDescItem) : BOOLEAN;
BEGIN
 EditItem := GetDescriptionLine('Enter Instruction',pItem^.Description);
 Esc_Flag := FALSE;
 ch1 := ' ';
END;

PROCEDURE TProdDescEdit.EditListItem(Element   : BYTE);
BEGIN
 FillRecWithListKey(Element);
 IF ReadRecordFunc('EQ') = 0 THEN
  EditItem(RecBuff);
 RefreshListBox;
END;

PROCEDURE TProdDescEdit.InsertListItem;
VAR NewItem,Loop : PProdDescItem;
BEGIN
 New(NewItem);
 NewItem^.Description := SPACE_STRING;
 NewItem^.Next := NIL;
 IF EditItem(NewItem) THEN
  BEGIN
   Inc(ListSize);
   IF ListHeader = NIL THEN
    BEGIN
     NewItem^.LineNo := 1;
     ListHeader := NewItem;
    END
   ELSE
    BEGIN
     Loop := ListHeader;
     WHILE (Loop^.Next) <> NIL DO Loop := Loop^.Next;
     NewItem^.LineNo := Loop^.LineNo+1;
     Loop^.Next := NewItem;
    END;
  END
 ELSE Dispose(NewItem);
 RefreshListBox;
END;

PROCEDURE TProdDescEdit.Save_Details;
VAR Loop   : PProdDescItem;
    NewLineNo : INTEGER;

 PROCEDURE LinkItemToDescRec;
 BEGIN
  WITH DescRec,Loop^ DO
   BEGIN
    PD_ProductCode := Product;
    PD_Method      := MethodNo;
    PD_LineNo      := NewLineNo;
    PD_Description := Description;
   END;
 END;

 PROCEDURE DeleteOldRecords;
 VAR ReadErr : INTEGER;
 BEGIN
  DescRec.PD_ProductCode := Product;
  DescRec.PD_LineNo      := 0;
  DescRec.PD_Method      := MethodNo;
  ReadErr := ProdDescFile^.ReadRecord('GE',TRUE,FALSE,DescRec,0);
  WHILE (ReadErr = 0) AND (DescRec.PD_ProductCode = Product) AND
      (DescRec.PD_Method = MethodNo) DO
   BEGIN
    ProdDescFile^.DeleteRecord;
    ReadErr := ProdDescFile^.ReadRecord('GN',TRUE,FALSE,DescRec,0);
   END;
 END;

BEGIN
 {Needs To Read and lock header maybe}
 DeleteOldRecords;
 Loop := ListHeader;
 NewLineNo := 0;
 WHILE (Loop <> NIL) DO
  BEGIN
   INC(NewLineNo);
   LinkItemToDescRec;
   ProdDescFile^.AddRecord(DescRec);
   Loop := Loop^.Next;
  END;
 IF NOT NowtButSpace(InstructionName) THEN
  BEGIN
   DescRec.PD_ProductCode := Product;
   DescRec.PD_Method      := MethodNo;
   DescRec.PD_Description := InstructionName;
   DescRec.PD_LineNo      := 0;
   ProdDescFile^.AddRecord(DescRec);
   END;
 Esc_Flag := TRUE;
 AnEditOccured := FALSE;
END;

FUNCTION TProdDescEdit.EventHandled : BOOLEAN;
BEGIN
 EventHandled := FALSE;
 IF Funckey THEN
 CASE ch1 OF
  FN_F2 : BEGIN
           GetDescriptionLine('Enter Method Name',InstructionName);
           Header(InstructionName,2);
           Esc_Flag := FALSE;
           ch1 := ' ';
          END;
  FN_F6 : BEGIN
           Move_Item_Down_List(ListIndex);
           EventHandled := TRUE;
          END;
  FN_F5 : BEGIN
           Move_Item_Up_List(ListIndex);
           EventHandled := TRUE;
          END;
  FN_F10: BEGIN
           IF YesNoWin(' Abondon Edit Are You Sure Y/N') THEN
            BEGIN
             AnEditOccured := FALSE;
             Esc_flag := TRUE;
            END;
          END;
 END;
END;

END.


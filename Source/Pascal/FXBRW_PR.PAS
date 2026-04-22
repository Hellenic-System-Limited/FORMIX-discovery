(****************************************************************************
*  UNIT          : FXPR_BRW                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 09/05/96                                                 *
*  PURPOSE       : Formix Product Browser                                   *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXBRW_PR;

INTERFACE

USES CRT,F6STDCTV,FXMODCTV,F6STDUTL,F6STDUT1,F6STDWIN,F6STDWN1,F6STDBRW,
     F6DTCONV,FXFProd,FX_WOE,FX_PEdit;

CONST WIN_X          = 5;             { WINDOW X Offset       (Global )     }
      WIN_Y          = 3;             { WINDOW Y Offset       (Global )     }
      WIN_WID        = 47;            { WINDOW Width          (Global )     }
      WIN_DEP        = 19;            { WINDOW Depth          (Global )     }
      X1 = WIN_X;
      Y1 = WIN_Y;
      X2 = WIN_X+WIN_WID;
      Y2 = WIN_Y+WIN_DEP;

      LIST_X         = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH     = WIN_WID-3;   { LIST BOX WIDTH        (Global )     }
      LIST_Y         = WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH     = WIN_DEP-6;   { LIST BOX DEPTH    (Global )     }

      BLANK_LINE     = '  ----------  ------------------------------';
      Read_Key       = 0;

TYPE TListItem = TProdHeaderRecord;


     PBrowseList = ^TBrowseList;
     TBrowseList = ARRAY[1..LIST_DEPTH] OF TListItem;

     PProductBrowse = ^TProductBrowse;
     TProductBrowse = OBJECT(TFileBrowser)

      BrowseWin   : WindowRecord;
      BrowseArray : PBrowseList;
      RecordBuff  : PProdHeaderRecord;
      CalledAsEdit: BOOLEAN;
      EnterStr    : TProductRef;

      CONSTRUCTOR Init(Xp,Yp,Width,Depth : BYTE;EditBrowse : BOOLEAN);
      PROCEDURE   Setup; Virtual;
      DESTRUCTOR  Done; Virtual;
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
      PROCEDURE   DisplayLookUpRecord;
      PROCEDURE   DisplayHighlightedChars(Col : BYTE); VIRTUAL;
     END;

PROCEDURE ProductEdit;
PROCEDURE BrowseProduct(VAR ProductNo : TProductRef);

IMPLEMENTATION

VAR ProdSelected : TProductRef;

CONSTRUCTOR TProductBrowse.Init(Xp,Yp,Width,Depth : BYTE;EditBrowse : BOOLEAN);
BEGIN
 EnterStr     := '';
 CalledAsEdit := EditBrowse;
 ProdLineFile^.OpenFile;
 ProdHeaderFile^.OpenFile;
 New(BrowseArray);
 New(RecordBuff);
 IF (ProdHeaderFile^.OpenErr+ProdLineFile^.OpenErr <> 0) THEN Esc_Flag :=TRUE;
 INHERITED Init(Xp,Yp,Width,Depth);
END;

DESTRUCTOR TProductBrowse.Done;
BEGIN
 LoseWindow(BrowseWin);
 Dispose(RecordBuff);
 Dispose(BrowseArray);
 ProdHeaderFile^.CloseFile;
 ProdLineFile^.CloseFile;
 INHERITED Done;
END;

PROCEDURE TProductBrowse.DeleteListItem      (Element   : BYTE);
BEGIN
 IF NOT CalledAsEdit THEN Exit;
 IF YesNoWin('     Delete Product '+BrowseArray^[Element].PH_ProductCode+CRLF+
             '       Are You Sure Y/N ') THEN
  BEGIN
   ProdDescFile^.OpenFile;
   FillRecWithListKey(Element);
   IF ProdHeaderFile^.ReadRecord('EQ',TRUE,FALSE,RecordBuff^,0) = 0 THEN
    BEGIN
     IF ProdLineFile^.DelLinesForProd(RecordBuff^.PH_ProductCode)+
        ProdDescFile^.DeleteDescriptions(RecordBuff^.PH_ProductCode) = 0 THEN
       ProdHeaderFile^.DeleteRecord
     ELSE
       ProdHeaderFile^.Unlock_Single;
    END;
   ProdDescFile^.CloseFile;
  END;
 RefreshListBox;
END;

PROCEDURE TProductBrowse.EditListItem(Element   : BYTE);
BEGIN
 IF CalledAsEdit THEN
  BEGIN
   Edit_Product(BrowseArray^[Element].PH_ProductCode);
   RefreshListBox;
  END
 ELSE
  BEGIN
   Esc_Flag       := TRUE;
   ProdSelected := BrowseArray^[Element].PH_ProductCode;
  END;
END;

PROCEDURE TProductBrowse.InsertListItem;
BEGIN
 IF NOT CalledAsEdit THEN EXIT;
 Edit_Product(COPY(SPACE_STRING,1,SizeOf(TProductRef)-1));
 RefreshListBox;
END;

PROCEDURE TProductBrowse.Setup;
VAR I :INTEGER;
VAR Lp : BYTE;
BEGIN
 HBarXOffSet :=2;
 FillChar(BrowseArray^,SizeOf(BrowseArray^),#0);
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,
		TRUE,NormBack*16+LowFore,NormBack*16+LowFore,BrowseWin);

 Header('Product File Browser',1);
 HighVideo;

 WriteAt(2,2,' Product No  Description                    ');
 WriteAt(1,3,BLANK_LINE);
 IF CalledAsEdit THEN
  BEGIN
   Footer('INSERT - Add Product   ENTER - Edit',2);
   Footer('DELETE - Delete Product  ESCAPE - EXIT',1);
  END
 ELSE
  BEGIN
   Footer('',2);
   Footer('ENTER - Select         ESCAPE - EXIT',1);
  END;
 ForeColourScheme;
 RefreshListBox;
END;

PROCEDURE TProductBrowse.ClearListPos        (Element   : BYTE);
BEGIN
 FillChar(BrowseArray^[Element],SizeOf(TListItem),#0);
END;

PROCEDURE TProductBrowse.FillRecWithListKey  (Element   : BYTE);
BEGIN
 RecordBuff^.PH_ProductCode := BrowseArray^[Element].PH_ProductCode;
END;

FUNCTION  TProductBrowse.ReadRecordFunc(Operation : STRING) : INTEGER;
TYPE LONGPTR = ^LONGINT;
VAR ReadErr : INTEGER;
BEGIN
 ProdHeaderFile^.ReadRecord(Operation,FALSE,FALSE,RecordBuff^,Read_Key);
 ReadErr := ProdHeaderFile^.BtrvErr;
 ReadRecordFunc:=ReadErr;
END;

PROCEDURE TProductBrowse.FillListPosWithRec  (Element   : BYTE);
BEGIN
 BrowseArray^[Element] := RecordBuff^;
END;

FUNCTION  TProductBrowse.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := NowtButSpace(BrowseArray^[Element].PH_ProductCode);
END;

PROCEDURE TProductBrowse.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray^[SourceElement],BrowseArray^[DestElement],SizeOf(TListItem));
END;

FUNCTION  TProductBrowse.DispColour(Element   : BYTE; Highlight : BOOLEAN): BYTE;
BEGIN
 IF Highlight THEN
  DispColour := HiliteBarColour*16
 ELSE
  DispColour := INHERITED DispColour(Element,Highlight);
END;

PROCEDURE TProductBrowse.DisplayHighlightedChars(Col : BYTE);
VAR TextSave : BYTE;
BEGIN
 WITH BrowseArray^[ListIndex] DO
  BEGIN
   TextSave := TextAttr;
   GotoXY((LB_X-Lo(WindMin)),ListIndex+LB_Y-(Hi(WindMin)+1));
   IF NOT NowtButSpace(EnterStr) AND Str_Equal(EnterStr,PH_ProductCode,Length(EnterStr)) THEN
    BEGIN
     TextAttr := Col AND $F0 + HighFore;
     Write('  ',EnterStr);
     TextAttr :=Col;
     Write(COPY(PH_ProductCode,Length(EnterStr)+1,8));
    END
   ELSE
    BEGIN
     TextAttr := Col;
     Write('  ',PH_ProductCode);
    END;
   TextAttr := TextSave;
  END;
END;


PROCEDURE TProductBrowse.DisplayListItem(Element   : BYTE);
VAR SaveCol : BYTE;
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   WITH BrowseArray^[Element] DO
    BEGIN
     Write('  ',PH_ProductCode,'  ',PH_Description);
    END;
  END
 ELSE
  BEGIN
   Write(BLANK_LINE);
  END;
END;

PROCEDURE TProductBrowse.DisplayLookUpRecord;
BEGIN
 RecordBuff^.PH_ProductCode := EnterStr+SPACE_STRING;
 ReadRecordFunc('GE');
 FillListPosWithRec(1);
 ListIndex := 1;
 RefreshListBox;
END;

FUNCTION TProductBrowse.EventHandled : BOOLEAN;
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
    FN_F5: BEGIN
            IF CheckForCircularProductRef(BrowseArray^[ListIndex].PH_ProductCode) THEN
             BEGIN
              Disp_Error_Msg('A Circular Product Reference Exists For This Product');
             END
            ELSE
             Disp_Error_Msg('No Circular Reference Found');
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

PROCEDURE ProductEdit;
VAR ProductBrowse : PProductBrowse;
BEGIN
 New(ProductBrowse,Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH,TRUE));
 ProductBrowse^.Run;
 Dispose(ProductBrowse,Done);
END;

PROCEDURE BrowseProduct(VAR ProductNo : TProductRef);
VAR ProductBrowse : PProductBrowse;
BEGIN
 ProdSelected := SPACE_STRING;
 New(ProductBrowse,Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH,FALSE));
 ProductBrowse^.Run;
 Dispose(ProductBrowse,Done);
 ProductNo := ProdSelected;
END;

END.
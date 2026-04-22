(****************************************************************************
*  UNIT          : FXPO_BRW                                                 *
*  AUTHOR        : N. S                                                     *
*  DATE          : 09/05/96                                                 *
*  PURPOSE       : Formix Product Order Browser                             *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}

UNIT FXBRW_PO;

INTERFACE

USES CRT,F6STDCTV,FXCfg,F6STDUTL,F6STDUT1,F6STDWIN,F6STDWN1,F6STDBRW,
     F6DTCONV,FXFProd,FXPCook,FXDelPrd,FXPPCost;

CONST WIN_X       = 1;           { WINDOW X Offset       (Global )     }
      WIN_Y       = 1;           { WINDOW Y Offset       (Global )     }
      WIN_WID     = 79;          { WINDOW Width          (Global )     }
      WIN_DEP     = 24;          { WINDOW Depth          (Global )     }

      LIST_X      = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH  = WIN_WID-2;   { LIST BOX WIDTH        (Global )     }
      LIST_Y      = WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH  = WIN_DEP-6;   { LIST BOX DEPTH        (Global )     }

      Days_Colour    : Array[0..6] of WORD   = (8,9,10,11,12,15,14);
      Read_Key    = 0;
      BLANK_LINE  ='    ----------  --------- ---------- ------- ---------- ------  --------------';

TYPE TListItem = TProdOrderRecord;


     PBrowseList = ^TBrowseList;
     TBrowseList = ARRAY[1..LIST_DEPTH] OF TListItem;

     PPOBrowse = ^TPOBrowse;
     TPOBrowse = OBJECT(TFileBrowser)

      BrowseWin   : WindowRecord;
      BrowseArray : PBrowseList;
      RecordBuff  : PProdOrderRecord;

      CONSTRUCTOR Init(Xp,Yp,Width,Depth : BYTE);
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
      PROCEDURE   PrintCookingDetails(Element : BYTE);
     END;

PROCEDURE ProductOrderBrowse;

IMPLEMENTATION

CONSTRUCTOR TPOBrowse.Init(Xp,Yp,Width,Depth : BYTE);
BEGIN
 New(BrowseArray);
 ProdOrderFile^.OpenFile;
 IF ProdOrderFile^.OpenErr <> 0 THEN Esc_Flag :=TRUE;
 New(RecordBuff);
 INHERITED Init(Xp,Yp,Width,Depth);
END;

DESTRUCTOR TPOBrowse.Done;
BEGIN
 Dispose(RecordBuff);
 Dispose(BrowseArray);
 LoseWindow(BrowseWin);
 ProdOrderFile^.CloseFile;
 INHERITED Done;
END;

PROCEDURE TPOBrowse.DeleteListItem      (Element   : BYTE);
BEGIN
 IF ListPosIsEmpty(Element) THEN Exit;
 IF YesNoWin('     Delete Product '+(BrowseArray^[Element].PO_ProductCode)+CRLF+
             '       Are You Sure Y/N ') THEN
  BEGIN
   Delete_Product(BrowseArray^[Element].PO_OrderNo,BrowseArray^[Element].PO_Date);
  END;
 RefreshListBox;
END;

PROCEDURE TPOBrowse.Setup;
VAR I :INTEGER;
    Lp : BYTE;
BEGIN
 HBarXOffSet :=3;
 FillChar(BrowseArray^,SizeOf(BrowseArray^),#0);
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,
		FALSE,NormBack*16+LowFore,NormBack*16+LowFore,BrowseWin);
 Header('PRODUCT ORDER SCHEDULE',1);
 Footer('                                                                              ',3);
 Footer(' F2 - Print Cooking Report                       DEL - Delete Order           ',2);
 Footer(' F3 - Product Costing Report                     ESC - Return To Menu         ',1);
 HighVideo;
 WriteAt(2,3,'    Date        Order     Product    '+Config_Rec^.CONF_UnitName+
                                                         ' Tot Weight Orders  Cooking Method');
 WriteAt(2,4,BLANK_LINE);
 LowVideo;
 ForeColourScheme;
 RefreshListBox;
END;

PROCEDURE TPOBrowse.ClearListPos        (Element   : BYTE);
BEGIN
 FillChar(BrowseArray^[Element],SizeOf(TListItem),#0);
END;

PROCEDURE TPOBrowse.FillRecWithListKey  (Element   : BYTE);
BEGIN
 RecordBuff^ := BrowseArray^[Element];
END;

FUNCTION  TPOBrowse.ReadRecordFunc(Operation : STRING) : INTEGER;
BEGIN
 ProdOrderFile^.ReadRecord(Operation,FALSE,FALSE,RecordBuff^,Read_Key);
 ReadRecordFunc := ProdOrderFile^.BtrvErr;
END;

PROCEDURE TPOBrowse.FillListPosWithRec  (Element   : BYTE);
VAR TempWt : DOUBLE;
BEGIN
 BrowseArray^[Element] := RecordBuff^;
END;

FUNCTION  TPOBrowse.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := BrowseArray^[Element].PO_OrderNo = 0;
END;

PROCEDURE TPOBrowse.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray^[SourceElement],BrowseArray^[DestElement],SizeOf(TListItem));
END;

FUNCTION  TPOBrowse.DispColour(Element   : BYTE; Highlight : BOOLEAN): BYTE;
BEGIN
 IF Highlight THEN
  DispColour := HiliteBarColour*16
 ELSE
  BEGIN
   DispColour := INHERITED DispColour(Element,Highlight);
  END;
END;

PROCEDURE TPOBrowse.DisplayListItem(Element   : BYTE);
VAR SaveCol : BYTE;
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   WITH BrowseArray^[Element] DO
    BEGIN
     SaveCol := TextAttr;
     TextBackGround(White);
     TextColor(Black);
     IF PROP_Colour THEN TextColor(Get_Day_OF_Week(PO_Date)+9)
     ELSE IF (Get_Day_OF_Week(PO_Date) MOD 2) = 0 THEN
      BEGIN
       TextColor(LightGray);
       TextBackGround (Black);
      END;

     Write(Days_Index[Get_Day_Of_Week(PO_Date)]);
     TextAttr := SaveCol;

     Write(' ');
     Write(Days_To_Date(PO_Date),'  ');
     Write(IntToZeroStr(PO_OrderNo,6),'    ');
     Write(PO_ProductCode,'  ');
     Write(PO_Containers:4,'    ');
     Write(PO_TotalWt:9:3,' ');
     Write(PO_NumOrders:6,'             ');
     Write(PO_Method:3);
    END;
  END
 ELSE
  BEGIN
   Write(BLANK_LINE);
  END;
END;


PROCEDURE TPOBrowse.PrintCookingDetails(Element : BYTE);
BEGIN
 Print_Cooking_Report(BrowseArray^[Element]);
END;

FUNCTION TPOBrowse.EventHandled        : BOOLEAN;
BEGIN
 EventHandled:=FALSE;
 IF FuncKey THEN
  BEGIN
   CASE Ch1 OF
     FN_F2 : BEGIN
      IF NOT ListPosIsEmpty(ListIndex) THEN PrintCookingDetails(ListIndex);
      EventHandled := TRUE;
     END; {FN_F2}
     FN_F3 : BEGIN
      IF NOT ListPosIsEmpty(ListIndex) THEN
       Print_Product_Costing_Report(BrowseArray^[ListIndex]);
      EventHandled := TRUE;
     END; {FN_F3}
   END; {CASE}
  END; {IF NOT Funckey}
END;


PROCEDURE ProductOrderBrowse;
VAR POBrowse : PPOBrowse;
BEGIN
 New(POBrowse,Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH));
 POBrowse^.Run;
 Dispose(POBrowse,Done);
END;

END.
(****************************************************************************
*  UNIT          : FXWO_BRW                                                 *
*  AUTHOR        : S. Wright                                                *
*  DATE          : 09/05/96                                                 *
*  PURPOSE       : Formix Recipe Order Browser                              *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}

UNIT FXBRW_WO;

INTERFACE

USES CRT,F6STDCTV,FXModCtv,F6STDUTL,F6STDUT1,F6STDWIN,F6STDWN1,F6STDBRW,
     FXPWord,F6DTCONV,FxFWork,FX_WOE,FXFGen,FXDelOrd,FXPOrd,FXWO_TGL,FXFMix;

CONST WIN_X          = 1;             { WINDOW X Offset       (Global )     }
      WIN_Y          = 1;             { WINDOW Y Offset       (Global )     }
      WIN_WID        = 79;            { WINDOW Width          (Global )     }
      WIN_DEP        = 24;            { WINDOW Depth          (Global )     }
      X1 = WIN_X;
      Y1 = WIN_Y;
      X2 = WIN_X+WIN_WID;
      Y2 = WIN_Y+WIN_DEP;

      LIST_X         = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH     = WIN_WID-2;   { LIST BOX WIDTH        (Global )     }
      LIST_Y         = WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH     = WIN_DEP-6;{ LIST BOX DEPTH    (Global )     }

      Days_Colour    : Array[0..6] of WORD   = (8,9,10,11,12,15,14);
      BLANK_LINE     = '   ----------- --------- -------- --- --------- --------- ---- --------- ---- ';
      Read_Key       = 0;

TYPE TListItem = TWOHeaderRecord;


     PBrowseList = ^TBrowseList;
     TBrowseList = ARRAY[1..LIST_DEPTH] OF TListItem;

     PWOBrowse = ^TWOBrowse;
     TWOBrowse = OBJECT(TFileBrowser)

      BrowseWin   : WindowRecord;
      BrowseArray : PBrowseList;
      RecordBuff  : PWOHeaderRecord;
      EnterStr    : STRING[9];

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
      PROCEDURE   EditListItem        (Element   : BYTE); Virtual;
      PROCEDURE   InsertListItem; Virtual;
      PROCEDURE   ChangeStatus(Advance : BOOLEAN);
      PROCEDURE   RefreshListBox;VIRTUAL;
      PROCEDURE   ToggleListItem      (Element   : BYTE); Virtual;
      PROCEDURE   TagListItem         (Element   : BYTE;Redisplay : BOOLEAN);
      PROCEDURE   DisplayLookUpRecord;
     END;

PROCEDURE WorksOrderBrowse;


IMPLEMENTATION

CONSTRUCTOR TWOBrowse.Init(Xp,Yp,Width,Depth : BYTE);
BEGIN
 EnterStr := '';
 ResetWOBrowser := FALSE;
 New(BrowseArray);
 WorkHeaderFile^.OpenFile;
 WorkLineFile^.OpenFile;
 IF WorkHeaderFile^.OpenErr <> 0 THEN Esc_Flag :=TRUE;
 New(RecordBuff);
 INHERITED Init(Xp,Yp,Width,Depth);
END;

DESTRUCTOR TWOBrowse.Done;
BEGIN
 ClearOrderToggleList;
 Dispose(RecordBuff);
 Dispose(BrowseArray);
 LoseWindow(BrowseWin);
 WorkHeaderFile^.CloseFile;
 WorkLineFile^.CloseFile;
 INHERITED Done;
END;

PROCEDURE TWoBrowse.RefreshListBox;
BEGIN
 ResetWOBrowser := FALSE;
 INHERITED RefreshListBox;
END;

PROCEDURE TWOBrowse.DeleteListItem      (Element   : BYTE);
BEGIN
 IF YesNoWin('     Delete Order '+
             OrderNoToStr(BrowseArray^[Element].WOH_OrderNo,BrowseArray^[Element].WOH_Revision)+CRLF+
             '       Are You Sure Y/N ') THEN
  BEGIN
   FillRecWithListKey(Element);
   IF WorkHeaderFile^.ReadRecord('EQ',FALSE,FALSE,RecordBuff^,0) = 0 THEN
    BEGIN
     IF RecordBuff^.WOH_Status = StatusWIP THEN
      BEGIN
       Disp_Error_Msg('Can Not Delete WIP Orders');
       EXIT;
      END;
     IF NOT OkToDeleteOrder(RecordBuff^,TRUE,FALSE) THEN
      BEGIN
       IF NOT YesNoWin('   Order Has Active Ingredient '+CRLF+
                       '   Weighings.Are You Sure You  '+CRLF+
                       '      Wish To Delete It Y/N') THEN EXIT;
       IF NOT Password(FALSE) THEN
        BEGIN
         Esc_Flag := FALSE;
         EXIT;
        END;
      END;
     Delete_Order(RecordBuff^.WOH_OrderNo,RecordBuff^.WOH_Revision);
    END;
  END;
 RefreshListBox;
END;

PROCEDURE TWOBrowse.EditListItem(Element   : BYTE);
BEGIN
 Edit_Order(BrowseArray^[Element].WOH_SchDate,
            BrowseArray^[Element].WOH_OrderNo,
            BrowseArray^[Element].WOH_Revision);
 RefreshListBox;
END;

PROCEDURE TWOBrowse.InsertListItem;
BEGIN
 Edit_Order(0,0,0);
 RefreshListBox;
END;

PROCEDURE TWOBrowse.Setup;
VAR I :INTEGER;
VAR Lp : BYTE;
BEGIN
 HBarXOffSet :=3;
 FillChar(BrowseArray^,SizeOf(BrowseArray^),#0);
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,
		FALSE,NormBack*16+LowFore,NormBack*16+LowFore,BrowseWin);
 Header('ORDER SCHEDULE',1);
 Footer(' INSERT - Add Order         ENTER - Edit Order      DELETE - Delete Order    ',3);
 Footer(' +/- Change Order Status    F2    - Costing Report                           ',2);
 Footer(' F3 - Order Summary Report  F4    - Mix Details     ESC    - Exit            ',1);
 HighVideo;
 WriteAt(2,3,'   Date        Order     Recipe   Fix  MixType  Target Wt Mix  Wt. Done  Stat');
 WriteAt(2,4,BLANK_LINE);
 LowVideo;
 ForeColourScheme;
 FillChar(RecordBuff^,SizeOf(RecordBuff^),#0);
 RecordBuff^.WOH_SchDate := Date_To_Days(Date);
 IF ReadRecordFunc('GE')<>0 THEN ReadRecordFunc('LE');
 FillListPosWithRec(1);
 RefreshListBox;
END;

PROCEDURE TWOBrowse.TagListItem(Element : BYTE;Redisplay : BOOLEAN);
BEGIN
 AddItemToOrderToggleList(BrowseArray^[Element].WOH_OrderNo,BrowseArray^[Element].WOH_Revision);
 IF Redisplay THEN DisplayList(Element,Element);
END;

PROCEDURE TWOBrowse.ToggleListItem(Element   : BYTE);
BEGIN
 TagListItem(Element,TRUE);
END;

PROCEDURE TWOBrowse.ClearListPos(Element   : BYTE);
BEGIN
 FillChar(BrowseArray^[Element],SizeOf(TListItem),#0);
END;

PROCEDURE TWOBrowse.FillRecWithListKey  (Element   : BYTE);
BEGIN
 RecordBuff^ := BrowseArray^[Element];
END;

FUNCTION  TWOBrowse.ReadRecordFunc(Operation : STRING) : INTEGER;
BEGIN
 WorkHeaderFile^.ReadRecord(Operation,FALSE,FALSE,RecordBuff^,Read_Key);
 ReadRecordFunc := WorkHeaderFile^.BtrvErr;
END;

PROCEDURE TWOBrowse.FillListPosWithRec  (Element   : BYTE);
VAR TempWt : DOUBLE;
BEGIN
 BrowseArray^[Element] := RecordBuff^;
END;

FUNCTION  TWOBrowse.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := BrowseArray^[Element].WOH_OrderNo = 0;
END;

PROCEDURE TWOBrowse.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray^[SourceElement],BrowseArray^[DestElement],SizeOf(TListItem));
END;

FUNCTION  TWOBrowse.DispColour(Element   : BYTE; Highlight : BOOLEAN): BYTE;
BEGIN
 IF Highlight THEN
  DispColour := HiliteBarColour*16
 ELSE
  BEGIN
   DispColour := INHERITED DispColour(Element,Highlight);
   IF  (NOT ListPosIsEmpty(Element))
   AND (BrowseArray^[Element].WOH_Status < High(TStatusType)) THEN
     DispColour := BackNormBack*16+StatusColour[BYTE(BrowseArray^[Element].WOH_Status)];
  END;
END;

PROCEDURE TWOBrowse.DisplayListItem(Element   : BYTE);
VAR SaveCol : BYTE;
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   WITH BrowseArray^[Element] DO
    BEGIN
     SaveCol := TextAttr;
     TextBackGround(White);
     TextColor(Black);
     IF PROP_Colour THEN TextColor(Get_Day_OF_Week(WOH_SchDate)+9)
     ELSE IF (Get_Day_OF_Week(WOH_SchDate) MOD 2) = 0 THEN
      BEGIN
       TextColor(LightGray);
       TextBackGround (Black);
      END;

     IF (High(TMixType) < WOH_MixType) THEN WOH_MixType  := mt_SingleContainerPerMix;

     Write(Days_Index[Get_Day_Of_Week(WOH_SchDate)]);
     TextAttr := SaveCol;
     IF IsOrderToggled(WOH_OrderNo,WOH_Revision) THEN Write(TOGGLE_CHAR)
     ELSE Write(' ');

     Write(Days_To_Date(WOH_SchDate),' ');
     Write(OrderNoToStr(WOH_OrderNo,WOH_Revision),' ');
     Write(WOH_RecipeNo,' ');
     Write(BoolToYNStr(WOH_SeqFixed,4));

     Write(GetMixType(WOH_MixType),' ');

     Write(WOH_TotIngredWtReqd:9:3,' ');
     Write(WOH_MixDone:4,' ');
     Write(WOH_WtDoneGross:9:3,' ');
     IF (High(TStatusType) < WOH_Status) THEN WOH_Status := StatusHOLD;
     Write(GetStatusType(WOH_Status),' ');
    END;
  END
 ELSE
  BEGIN
   Write(BLANK_LINE);
  END;
END;

PROCEDURE TWOBrowse.ChangeStatus(Advance : BOOLEAN);
VAR MixesReset : LONGINT;
BEGIN
 IF NOT ListPosIsEmpty(ListIndex) THEN
  BEGIN
   FillRecWithListKey(ListIndex);
   WorkHeaderFile^.ReadRecord('EQ',TRUE,FALSE,RecordBuff^,Read_Key);
   WITH RecordBuff^ DO
    BEGIN
     IF Advance THEN
      BEGIN
       IF WOH_Status = High(TStatusType) THEN WOH_Status := Low(TStatusType)
       ELSE WOH_Status := Succ(WOH_Status);
      END
     ELSE
      BEGIN
       IF WOH_Status = Low(TStatusType) THEN WOH_Status := High(TStatusType)
       ELSE WOH_Status := Pred(WOH_Status);
      END;
     INC(WOH_UpdateCount);
    END;

(* this screws up mix order/mix completion calc at terminal
    IF RecordBuff^.WOH_Status = STATUSWIP THEN { clear comp flag on all mix records }
    BEGIN
     MixRecordsWithStatCleared(RecordBuff);
     RecordBuff^.WOH_MixDone := 0;
    END;
*)
   WorkHeaderFile^.UpdateRecord(RecordBuff^);
   FillListPosWithRec(ListIndex);
   DisplayList(ListIndex,ListIndex);
  END;
END;

PROCEDURE TWOBrowse.DisplayLookUpRecord;
VAR Dummy : INTEGER;
    SlPos : INTEGER;
BEGIN
 SlPos := Pos('/',EnterStr);
 IF SlPos = 0 THEN
  BEGIN
   VAL(COPY(EnterStr,1,Length(EnterStr)),RecordBuff^.WOH_OrderNo,Dummy);
   RecordBuff^.WOH_Revision := 0;
  END
 ELSE
  BEGIN
   VAL(COPY(EnterStr,1,SlPos-1),RecordBuff^.WOH_OrderNo,Dummy);
   IF SlPos<Length(EnterStr)  THEN
    VAL(Copy(EnterStr,SlPos+1,Length(EnterStr)-SlPos),RecordBuff^.WOH_Revision,Dummy)
   ELSE
    RecordBuff^.WOH_Revision := 0;
  END;
 ListIndex := 1;
 WorkHeaderFile^.ReadRecord('GE',FALSE,FALSE,RecordBuff^,1);
 FillListPosWithRec(1);
 RefreshListBox;
END;


FUNCTION TWOBrowse.EventHandled : BOOLEAN;
VAR AutoToggle : BOOLEAN;



  PROCEDURE DoAutoToggle;
  BEGIN
   IF AutoToggle THEN
    BEGIN
     ClearOrderToggleList;
     AutoToggle := FALSE;
    END
   ELSE
    BEGIN
     IF WOToggleListHeader = NIL THEN
      BEGIN
       TagListItem(ListIndex,FALSE);
       AutoToggle := TRUE;
      END;
    END;
  END;


BEGIN
 AutoToggle  :=FALSE;
 EventHandled:=FALSE;
 IF ResetWOBrowser THEN
  BEGIN
   RefreshListBox;
   EventHandled := TRUE;
  END;
 IF NOT FuncKey THEN
  BEGIN
   CASE Ch1 OF
    '+',
    '-' : ChangeStatus(Ch1 = '+');
    END;
  END;
 IF FuncKey THEN
  BEGIN
   CASE Ch1 OF
    FN_F2  : BEGIN
              DoAutoToggle;
              Print_Order_Pricing_Report(OCR_Normal);
              DoAutoToggle;
             END;
    FN_F3 : BEGIN
              DoAutoToggle;
              Print_Order_Pricing_Report(OCR_Summary);
              DoAutoToggle;
            END;
    FN_F4 : ViewMixes(BrowseArray^[ListIndex].WOH_OrderNo,BrowseArray^[ListIndex].WOH_Revision);
    PREV,
    NEXT,
    PGUP,
    PGDN : EnterStr := '';
   END;
  END
 ELSE
  BEGIN
   Ch1 := Upcase(Ch1);
   CASE Ch1 OF
    '0'..'9','/': BEGIN
                EnterStr := EnterStr + Ch1;
                DisplayLookupRecord;
                EventHandled := TRUE;
               END;
   END;
  END;
END;


PROCEDURE WorksOrderBrowse;
VAR WOBrowse : PWOBrowse;
BEGIN
 New(WOBrowse,Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH));
 WOBrowse^.Run;
 Dispose(WOBrowse,Done);
END;

END.

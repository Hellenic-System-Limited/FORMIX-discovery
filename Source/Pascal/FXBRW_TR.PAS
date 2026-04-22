(****************************************************************************
*  UNIT          : FXTR_BRW                                                 *
*  AUTHOR        : S. Wright                                                *
*  DATE          : 07/05/96                                                 *
*  PURPOSE       : Formix Transaction Browser                               *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXBRW_TR;

INTERFACE

USES CRT,F6STDCTV,F6STDUTL,F6STDUT1,F6STDWIN,F6STDWN1,F6STDBRW,F6DTCONV,
     FXFTRN,FXFWork,FXFGen;

CONST WIN_X          = 6;             { WINDOW X Offset       (Global )     }
      WIN_Y          = 2;             { WINDOW Y Offset       (Global )     }
      WIN_WID        = 69;            { WINDOW Width          (Global )     }
      WIN_DEP        = 22;            { WINDOW Depth          (Global )     }
      X1 = WIN_X;
      Y1 = WIN_Y;
      X2 = WIN_X+WIN_WID;
      Y2 = WIN_Y+WIN_DEP;

      LIST_X         = WIN_X+2;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH     = WIN_WID-4;   { LIST BOX WIDTH        (Global )     }
      LIST_Y         = WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH     = WIN_DEP-6;   { LIST BOX DEPTH    (Global )     }

      BLANK_LINE     = '---------  ----------  ---------  --------  ----------  ----------';

      Read_Key       = 0;

TYPE TListItem = TTranRecord;

     PBrowseList = ^TBrowseList;
     TBrowseList = ARRAY[1..LIST_DEPTH] OF TListItem;

     PTransactionBrowse = ^TTransactionBrowse;
     TTransactionBrowse = OBJECT(TFileBrowser)

      BrowseWin   : WindowRecord;
      BrowseArray : PBrowseList;
      RecordBuff  : PTranRecord;

      CONSTRUCTOR Init(Xp,Yp,Width,Depth : BYTE; TransferBuff : PTranRecord);
      PROCEDURE   WriteStaticText; Virtual;
      PROCEDURE   Setup; Virtual;
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   ClearListPos        (Element   : BYTE); Virtual;
      PROCEDURE   FillRecWithListKey  (Element   : BYTE); Virtual;
      FUNCTION    ReadRecordFunc      (Operation : STRING) : INTEGER; Virtual;
      PROCEDURE   FillListPosWithRec  (Element   : BYTE); Virtual;
      PROCEDURE   EditListItem        (Element   : BYTE); VIRTUAL;
      FUNCTION    ListPosIsEmpty      (Element   : BYTE) : BOOLEAN; Virtual;
      PROCEDURE   CopyListItem        (DestElement,SourceElement : BYTE); Virtual;
      PROCEDURE   DisplayListItem     (Element   : BYTE); Virtual;
      FUNCTION    EventHandled : BOOLEAN; Virtual;
      PROCEDURE   GotoTransaction;
      FUNCTION    DispColour          (Element   : BYTE; Highlight : BOOLEAN): BYTE; Virtual;
      PROCEDURE   RefreshListBox;VIRTUAL;
     END;

PROCEDURE TransactionBrowse;

IMPLEMENTATION
USES FXFSrc;

CONSTRUCTOR TTransactionBrowse.Init(Xp,Yp,Width,Depth : BYTE; TransferBuff : PTranRecord);
BEGIN
 ResetTranBrowser := FALSE;
 Esc_Flag  := FALSE;
 ListIndex := 1;
 BrowseArray := NIL;
 RecordBuff  := TransferBuff;
 New(BrowseArray);
 IF NOT Assigned(BrowseArray) THEN Esc_Flag := TRUE;
 IF NOT Assigned(RecordBuff) THEN Esc_Flag := TRUE;

 IF NOT Esc_Flag THEN
  BEGIN
   INHERITED Init(Xp,Yp,Width,Depth);
   TransFile^.OpenFile;
   SourceCodeFile^.OpenFile;
   IF (TransFile^.OpenErr <> 0)
   OR (SourceCodeFile^.OpenErr <> 0) THEN
    BEGIN
     Esc_Flag :=TRUE;
    END;
  END;
END;

PROCEDURE TTransactionBrowse.RefreshListBox;
BEGIN
 ResetTranBrowser := FALSE;
 INHERITED RefreshListBox;
END;

FUNCTION  TTransactionBrowse.DispColour(Element   : BYTE; Highlight : BOOLEAN): BYTE;
BEGIN
 IF Highlight THEN
  DispColour := HiliteBarColour*16
 ELSE
  BEGIN
   IF  (NOT ListPosIsEmpty(Element))
   AND (BrowseArray^[Element].TRN_Status = TRNStatusAborted) THEN
     DispColour := 7
   ELSE DispColour := BackNormBack*16+White;
  END;
END;


PROCEDURE TTransactionBrowse.WriteStaticText;
BEGIN
 Header('TRANSACTION FILE BROWSER',1);
 Footer(' ENTER - Detail Transaction    F3 - Goto Transaction           ',2);
 Footer(' ESC    - Done                                                 ',1);

 HighWriteAt(2,2,'Mi-Serial  Date        Order      Recipe    Ingredient  Net Weight');
 HighWriteAt(2,3,BLANK_LINE);
END;

PROCEDURE TTransactionBrowse.Setup;
VAR I :INTEGER;
    Lp : BYTE;
BEGIN
 FillChar(BrowseArray^,SizeOf(BrowseArray^),#0);
 Set_Colours(Black,Cyan,Yellow,Blue,White);
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,
		TRUE,NormBack*16+LowFore,NormBack*16+LowFore,BrowseWin);

 WriteStaticText;
 ForeColourScheme;
 RefreshListBox;
END;

DESTRUCTOR TTransactionBrowse.Done;
BEGIN
 LoseWindow(BrowseWin);
 IF Assigned(BrowseArray) THEN Dispose(BrowseArray);
 IF TransFile^.OpenErr = 0 THEN TransFile^.CloseFile;
 IF SourceCodeFile^.OpenErr = 0 THEN SourceCodeFile^.CloseFile;
END;

PROCEDURE TTransactionBrowse.ClearListPos        (Element   : BYTE);
BEGIN
 FillChar(BrowseArray^[Element],SizeOf(TListItem),#0);
END;

PROCEDURE TTransactionBrowse.FillRecWithListKey  (Element   : BYTE);
BEGIN
 RecordBuff^ := BrowseArray^[Element];
END;

FUNCTION  TTransactionBrowse.ReadRecordFunc(Operation : STRING) : INTEGER;
BEGIN
 TransFile^.ReadRecord(Operation,FALSE,FALSE,RecordBuff^,1);
 ReadRecordFunc := TransFile^.BtrvErr;
END;

PROCEDURE TTransactionBrowse.FillListPosWithRec  (Element   : BYTE);
VAR TempWt : DOUBLE;
BEGIN
 BrowseArray^[Element] := RecordBuff^;
END;

FUNCTION  TTransactionBrowse.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := BrowseArray^[Element].TRN_Date = 0;
END;

PROCEDURE TTransactionBrowse.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray^[SourceElement],BrowseArray^[DestElement],SizeOf(TListItem));
END;

PROCEDURE TTransactionBrowse.DisplayListItem(Element   : BYTE);
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   WITH BrowseArray^[Element] DO
    BEGIN
     Write(IntToZeroStr(TRN_Mid,2),'-',IntToZeroStr(TRN_SerialNo,6),'  ');
     Write(Days_To_Date(TRN_Date),'  ');
     Write(OrderNoToStr(TRN_OrderNo,TRN_Revision),'  ');
     Write(TRN_RecipeNo,'  ');
     Write(TRN_Ingredient,'     ');
     Write(DoubleToStr(TRN_ContainerWt,9,3),'  ');
    END;
  END
 ELSE
  BEGIN
   Write(BLANK_LINE);
  END;
END;

PROCEDURE TTransactionBrowse.EditListItem(Element : BYTE);
CONST Col1 = 20;
CONST Col2 = 46;
VAR DispWin : WindowRecord;
    SrcCodeRec : TSourceCodeRecord;
BEGIN
 CursorOff;
 FillRecWithListKey(Element);
 ReadRecordFunc('EQ');
 FillChar(SrcCodeRec, SizeOf(SrcCodeRec), 0);
 IF RecordBuff^.TRN_SourceId > 0 THEN
  BEGIN
   SrcCodeRec.SRC_ID := RecordBuff^.TRN_SourceId;
   SourceCodeFile^.ReadRecord('EQ',FALSE,FALSE,SrcCodeRec,0);
  END;
 BackColourScheme;
 SetWindow(07,4,73,21,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,DispWin);
 Header('Transaction Detail',1);
 Footer(' Esc - EXIT                                           ',1);
 WriteAt(2, 3,'Ingredient       [        ]   Order No.    [         ]');
 WriteAt(2, 4,'                              Order Line   [     ]');
 WriteAt(2, 5,'Recipe No        [        ]   Status       [               ]');
 WriteAt(2, 6,'Machine ID       [  ]         Serial No    [      ]');
 WriteAt(2, 7,'Time             [     ]      Date         [          ]');
 WriteAt(2, 8,'User ID          [        ]   Container Wt [         ]');
 WriteAt(2, 9,'Actual Wt        [         ]  Net Wt (calc)[         ]');
 WriteAt(2,10,'Batch No         [      ]     Lot No       [              ]');
 WriteAt(2,11,'Container No     [   ]        Mix No       [   ]');
 WriteAt(2,12,'Temperature      [     ]');
 WriteAt(2,13,'Source Barcode:');
 WriteAt(2,14,' [                                                          ]');
 ForeColourScheme;
 HighVideo;
 WITH RecordBuff^ DO
  BEGIN
   WriteAt(Col1,3,TRN_Ingredient);
   WriteAt(Col2,3,OrderNoToStr(TRN_OrderNo,TRN_Revision));
   WriteAt(Col2,4,IntToStr(TRN_OrderLineNo,5));
   WriteAt(Col1,5,TRN_RecipeNo);
   WriteAt(Col2,5,GetTRNStatusType(TRN_Status));
   WriteAt(Col1,6,IntToZeroStr(TRN_Mid,2));
   WriteAt(Col2,6,IntToZeroStr(TRN_SerialNo,6));
   WriteAt(Col1,7,TRN_Time);
   WriteAt(Col2,7,Days_To_Date(TRN_Date));
   WriteAt(Col1,8,TRN_UserID);
   WriteAt(Col2,8,DoubleToStr(TRN_ContainerWt,9,3));
   WriteAt(Col1,9,DoubleToStr(TRN_ActualWeight,9,3));
   WriteAt(Col2,9,DoubleToStr(TRN_CalcNetWt,9,3));
   WriteAt(Col1,10,TRN_BatchNo);
   WriteAt(Col2,10,TRN_LotNo);
   WriteAt(Col1,11,IntToZeroStr(TRN_ContainerNo,3));
   WriteAt(Col2,11,IntToZeroStr(TRN_MixNo,3));
   IF TRN_TempChecked = 1 THEN
     WriteAt(Col1,12,DoubleToStr(TRN_Temperature,5,1));
   WriteAt(4,14,StrPas(SrcCodeRec.SRC_Code));
  END;
 LowVideo;
 REPEAT
 UNTIL  GetKey = ESC;
 Esc_Flag := FALSE;
 LoseWindow(DispWin);
 CursorOn;
END;


PROCEDURE TTransactionBrowse.GotoTransaction;
VAR
     EditPos : BYTE;
     M_ID    : WORD;
     RN_No   : LONGINT;

  PROCEDURE SetListIndex_MID_SerialNo(Element : INTEGER;MID : WORD;RunNo : LONGINT);
  BEGIN
   BrowseArray^[Element].TRN_MID := MID;
   BrowseArray^[Element].TRN_SerialNo := RunNo;
  END;


BEGIN
 M_ID   := 0;  RN_No  := 0;
 BackColourScheme;
 SetWindow(16,8,60,14,TRUE,NormBack*16+LowFore,LowFore,Entry_Window);
 Header('Enter Starting Serial Number',1);
 WriteAt(6,3,'Machine ID ['+IntToZeroStr(M_ID,2)+'] RN Number ['+IntToZeroStr(RN_No,6)+']');
 Footer('ESC-Abort   F2-Goto Tran       ',1);
 ForeColourScheme;
 EditPos := 0;
 REPEAT
  CASE EditPos OF
   0 : BEGIN { Get Machine ID }
        GetInteger(INTEGER(M_ID),2,17,3);
        WriteField(17,3,IntToZeroStr(M_ID,2),TRUE);
       END;
   1 : BEGIN { Get Starting Run Number }
        GetLongint(RN_NO,6,32,3);
        WriteField(32,3,IntToZeroStr(RN_No,6),TRUE);
      END;
  END;
  IF Funckey THEN
   BEGIN
    CASE ch1 OF
     NEXT,
     PREV : EditPos := 1-EditPos;
    END;
   END;
  UNTIL (ch1 = ESC) OR ((ch1 = FN_F2) AND Funckey);

  LoseWindow(Entry_Window);

  IF (ch1 <> ESC) THEN
   BEGIN
    ListIndex :=1;
    SetListIndex_MID_SerialNo(1,M_ID,RN_No);
    RefreshListBox;
   END;
  Esc_Flag := FALSE;
  ch1 :=' ';
END;



FUNCTION TTransactionBrowse.EventHandled : BOOLEAN;
BEGIN
 EventHandled := FALSE;
 IF ResetTranBrowser THEN
  BEGIN
   EventHandled := TRUE;
   RefreshListBox;
  END;
 IF (NOT FuncKey) AND (Ch1 = ESC) THEN
  BEGIN
   TransFile^.InitRecord(RecordBuff^);
  END;
 CASE Ch1 OF
  FN_F3 : BEGIN
           GotoTransaction;
           EventHandled := TRUE;
          END;
 END;
END;

PROCEDURE TransactionBrowse;
VAR TransactionBrowse : PTransactionBrowse;
    TransferBuff      : PTranRecord;
BEGIN
 TransferBuff := NIL;
 NEW(TransferBuff);
 TransFile^.InitRecord(TransferBuff^);
 New(TransactionBrowse,Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH,TransferBuff));
 TransactionBrowse^.Run;
 Dispose(TransactionBrowse,Done);
 IF Assigned(TransferBuff) THEN Dispose(TransferBuff);
END;


END.

(****************************************************************************
*  UNIT          : FXPD_BRW                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 08/05/96                                                 *
*  PURPOSE       : FORMIX Product Cooking Instruction Browser               *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXBRW_PD;
INTERFACE
USES CRT,F6STDCTV,F6STDWN1,F6STDWIN,F6STDUTL,F6STDUT1,F6STDBRW,F6SCREEN,FX_EDIT,
     F6DTCONV,F6RECCHG,FXMODCTV,FXCFG,FXFProd;

CONST

      BLANK_LINE     = '  -------  ------------------------------------------';
      Read_Key       = 0;

      WIN_X          = 5;             { WINDOW X Offset       (Global )     }
      WIN_Y          = 3;             { WINDOW Y Offset       (Global )     }
      WIN_WID        = Length(BLANK_Line)+3;            { WINDOW Width          (Global )     }
      WIN_DEP        = 19;            { WINDOW Depth          (Global )     }
      X1 = WIN_X;
      Y1 = WIN_Y;
      X2 = WIN_X+WIN_WID;
      Y2 = WIN_Y+WIN_DEP;

      LIST_X         = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH     = WIN_WID-3;   { LIST BOX WIDTH        (Global )     }
      LIST_Y         = WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH     = WIN_DEP-6;   { LIST BOX DEPTH    (Global )     }




TYPE
    PProdDescBrowse = ^TProdDescBrowse;
    TProdDescBrowse = OBJECT(TFileBrowser)

      DescRec    : TProdDescription;
      BrowseArray: ARRAY[1..LIST_DEPTH] OF TProdDescription;
      Product    : TProductRef;
      WinRec     : WindowRecord;
      Methodno   : INTEGER;
      InsertAllowed : BOOLEAN;
      PHRec      : PProdHeaderRecord;

      CONSTRUCTOR Init(ProdHRec : PProdHeaderRecord;AllowInsert : BOOLEAN);
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   Setup; Virtual;
      FUNCTION    ReadRecordFunc       (Operation : STRING) : INTEGER; Virtual;
      PROCEDURE   FillRecWithListKey   (Element   : BYTE); Virtual;
      PROCEDURE   DisplayListItem      (Element   : BYTE); Virtual;

      PROCEDURE   EditListItem        (Element   : BYTE); Virtual;
      FUNCTION    ListPosIsEmpty      (Element   : BYTE) : BOOLEAN; Virtual;
      FUNCTION    EventHandled : BOOLEAN; VIRTUAL;
      PROCEDURE   FillListPosWithRec(Element   : BYTE); Virtual;
      PROCEDURE   ClearListPos        (Element   : BYTE); Virtual;
      PROCEDURE   CopyListItem        (DestElement,SourceElement : BYTE); Virtual;
      PROCEDURE   InsertListItem; Virtual;
      PROCEDURE   DeleteListItem(Element : BYTE); VIRTUAL;
     END;

IMPLEMENTATION

CONSTRUCTOR TProdDescBrowse.Init(ProdHRec : PProdHeaderRecord;AllowInsert : BOOLEAN);
BEGIN
 MethodNo := 0;
 PHRec    := ProdHRec;
 Product  := PHRec^.PH_ProductCode;
 InsertAllowed := AllowInsert;
 IF ProdDescFile^.OpenFile <> 0 THEN Esc_Flag := TRUE;
 INHERITED Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH);
END;

DESTRUCTOR TProdDescBrowse.Done;
BEGIN
 LoseWindow(WinRec);
 ProdDescFile^.CloseFile;
 INHERITED Done;
END;

FUNCTION  TProdDescBrowse.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := NowtButSpace(BrowseArray[Element].PD_Description);
END;

PROCEDURE TProdDescBrowse.FillListPosWithRec(Element   : BYTE);
BEGIN
 BrowseArray[Element] := DescRec;
END;

PROCEDURE TProdDescBrowse.ClearListPos(Element   : BYTE);
BEGIN
 FillChar(BrowseArray[Element],SizeOf(TProdDescription),#0);
END;

PROCEDURE TProdDescBrowse.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray[SourceElement],BrowseArray[DestElement],SizeOf(TProdDescription));
END;

PROCEDURE TProdDescBrowse.FillRecWithListKey   (Element   : BYTE);
BEGIN
 Move(BrowseArray[Element],DescRec,SizeOf(TProdDescription));
END;

PROCEDURE TProdDescBrowse.DeleteListItem(Element : BYTE);
VAR iMethodNo : INTEGER;
BEGIN
 IF NOT InsertAllowed THEN EXIT;
 IF (NOT ListPosIsEmpty(Element)) THEN
  BEGIN
   IF YesNoWin('   Delete Method  '+BrowseArray[Element].PD_Description+CRLF+
               '    Are You Sure Y/N') THEN
    BEGIN
     FillRecWithListKey(Element);
     ProdDescFile^.ReadRecord('GE',TRUE,FALSE,DescRec,0);
     iMethodNo := DescRec.PD_Method;
     WHILE (ProdDescFile^.BtrvErr = 0) AND (DescRec.PD_Method = iMethodNo)
      AND (DescRec.PD_ProductCode = Product) DO
       BEGIN
        ProdDescFile^.DeleteRecord;
        ProdDescFile^.ReadRecord('GN',TRUE,FALSE,DescRec,0);
       END;
      DEC(PHRec^.PH_NumMethods);
    END;
   RefreshListBox;
  END;
END;

PROCEDURE TProdDescBrowse.Setup;
BEGIN
 FillCHar(BrowseArray,SizeOf(BrowseArray),#0);
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,WinRec);
 Header('Cooking Instructions Methods Product '+Product,1);
 HighVideo;

 WriteAt(2,3,'   Order  Instruction                     ');
 WriteAt(1,4,BLANK_LINE);
 IF InsertAllowed THEN
  Footer('ENTER - Select  INSERT - ADD  Esc - EXIT',1)
 ELSE
  Footer('ENTER - Select                Esc - EXIT',1);
 ForeColourScheme;
 RefreshListBox;
END;

FUNCTION  TProdDescBrowse.ReadRecordFunc       (Operation : STRING) : INTEGER;
VAR ReadErr : INTEGER;
BEGIN
 DescRec.PD_ProductCode := Product;
 CASE Operation[1] OF
  'G' : CASE Operation[2] OF
         'F' : BEGIN
               END;
         'L' : BEGIN
               END;
         'E' : BEGIN
               END;
         'T' : BEGIN
                INC(DescRec.PD_Method);
                Operation := 'GE';
               END;
         'D' : BEGIN
               END;
         'N' : BEGIN
                INC(DescRec.PD_Method);
                Operation := 'GE';
               END;
         'P' : BEGIN
                DeC(DescRec.PD_Method);
                Operation := 'GE';
               END;
        END;
  'L' : CASE Operation[2] OF
         'E' :BEGIN
              END;
         'T' :BEGIN
              END;
        END;
  'E' : BEGIN
        END;
 END;
 ReadErr := ProdDescFile^.ReadRecord(Operation,FALSE,FALSE,DescRec,0);
 IF (Operation = 'LT') OR (Operation = 'GP') OR (Operation = 'LE') THEN
  Operation := 'GP'
 ELSE
  Operation := 'GN';
 WHILE (DescRec.PD_LineNo <> 0) AND (ReadErr = 0) AND (DescRec.PD_ProductCode = Product) DO
  BEGIN
   ReadErr := ProdDescFile^.ReadRecord(Operation,FALSE,FALSE,DescRec,0);
  END;
 IF (DescRec.PD_LineNo <> 0) OR (DescRec.PD_ProductCode <> Product) THEN
  ReadErr := 4;
 ReadRecordFunc:=ReadErr;
END;

PROCEDURE TProdDescBrowse.DisplayListItem      (Element   : BYTE);
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   With BrowseArray[Element] DO
    BEGIN
     Write('   ',PD_Method:6,'  ',PD_Description,'  ');
    END;
  END
 ELSE
  Write(Blank_Line);
END;


PROCEDURE TProdDescBrowse.EditListItem(Element   : BYTE);
BEGIN
 MethodNo := BrowseArray[Element].PD_Method;
 Esc_Flag := TRUE;
END;

PROCEDURE TProdDescBrowse.InsertListItem;
BEGIN
 IF InsertAllowed THEN Esc_Flag := TRUE;
END;

FUNCTION TProdDescBrowse.EventHandled : BOOLEAN;
BEGIN
 EventHandled := FALSE;
 IF NOT Funckey THEN
  CASE Ch1 OF
   ESC : MethodNo := -1;
  END;
END;

END.


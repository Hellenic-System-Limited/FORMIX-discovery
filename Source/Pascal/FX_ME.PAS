(****************************************************************************
*  UNIT          : FX_ME                                                   *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 08/05/96                                                 *
*  PURPOSE       : FORMIX RECIPE EDIT                                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FX_ME;
INTERFACE

USES CRT,STRINGS,F6STDCTV,F6STDWN1,F6STDWIN,F6STDUTL,F6STDBRW,F6StdUt1,F6SCREEN,
     FX_EDIT,F6RECCHG,FXMODCTV,FXCFG,FXFMacro,FXFCMAC,FXFOrder,FXBrw_MC;

PROCEDURE Edit_Macro(MacroNo : LONGINT);

IMPLEMENTATION

CONST WIN_X            = 08;          { WINDOW X Offset       (Global )     }
      WIN_Y            = 02;          { WINDOW Y Offset       (Global )     }
      WIN_WID          = 65;          { WINDOW Width          (Global )     }
      WIN_DEP          = 22;          { WINDOW Depth          (Global )     }

CONST EWIN_X           = 18;          { ITEM EDIT WINDOW X Offset (Global ) }
      EWIN_Y           = WIN_Y+9;     { ITEM EDIT WINDOW Y Offset (Global ) }
      EWIN_WID         = 40;          { ITEM EDIT WINDOW Width    (Global ) }
      EWIN_DEP         = 9;           { ITEM EDIT WINDOW Depth    (Global ) }

      LIST_X           = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH       = WIN_WID-4;   { LIST BOX WIDTH        (Global )     }
      LIST_Y           = WIN_Y+5;    { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH       = WIN_DEP-7;  { LIST BOX DEPTH        (Global )     }

      BLANK_RCPLINE    = ' ------------------------------ ------------------------------';

      MacroNO_F       = 1;
      LISTBOX         = 2;
      FIRSTFIELD      = MacroNO_F;          { Start Field ID                      }
      LASTFIELD       = LISTBOX;            { Last Field ID          }

TYPE

     PMacroEdit = ^TMacroEdit;
     TMacroEdit = object(TCombinedRecordEdit)

      MacroRef       : LONGINT;
      MacroRec       : PMacroRecord;

      CONSTRUCTOR Init(MacroNo : LONGINT);
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   Setup; Virtual;
      FUNCTION    ReadRecordFunc       (Operation : STRING) : INTEGER; Virtual;
      PROCEDURE   FillListPosWithRec   (Element   : BYTE); Virtual;
      PROCEDURE   DisplayListItem      (Element   : BYTE); Virtual;
      PROCEDURE   GetBrowseEvent; Virtual;
      FUNCTION    EventHandled         : BOOLEAN; Virtual;
      PROCEDURE   ResetMacroEditor;
      FUNCTION    Output_Value(Field : INTEGER) : STRING;
      PROCEDURE   Input_Value(Field_Str : STRING; Field : INTEGER);
      PROCEDURE   DisplayField(Field : INTEGER); VIRTUAL;
      PROCEDURE   EditField(Field : LONGINT);
      PROCEDURE   DeleteListItem       (Element   : BYTE); Virtual;
      PROCEDURE   InsertListItem; Virtual;
      FUNCTION    AddMacroLine : LONGINT; Virtual;
      PROCEDURE   RefreshListBox;VIRTUAL;
      FUNCTION    ListPosIsEmpty(Element   : BYTE) : BOOLEAN; VIRTUAL;
      FUNCTION    EditLineRecord  (Element   : BYTE;NewLine : BOOLEAN) : BOOLEAN; Virtual;
     END;


CONSTRUCTOR TMacroEdit.Init(MacroNo : LONGINT);
BEGIN
 MAcroRef  := MacroNo;

 { Inherited Method Clears Screen List Array }
 INHERITED Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH,FIRSTFIELD,LASTFIELD,LISTBOX);
 {Clear Defaults}

 Show_Btrv_Err(MacroFile^.OpenFile);
 IF MacroFile^.OpenErr <> 0 THEN Esc_Flag := TRUE;

 MacroRec := NIL;
 NEW(MAcroRec);
 IF Assigned(MacroRec) THEN MacroFile^.InitRecord(MacroRec)
 ELSE Esc_Flag := TRUE;
END;

FUNCTION TMacroEdit.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := (MacroRec^.MAC_Lines[Element] = NIL) OR
                   (MacroRec^.MAC_Lines[Element]^.Item.REP_Report = 0);
END;

DESTRUCTOR TMacroEdit.Done;
BEGIN
 IF Assigned(MacroRec) THEN
  BEGIN
   MacroFile^.ClearLines(MacroRec);             {Dispose List Of Ingredients   }
   Dispose(MacroRec);                        {Dispose Recipe Composite Record}
  END;
 MacroFile^.CloseFile;
 INHERITED Done;
END;

PROCEDURE TMacroEdit.RefreshListBox;
VAR OrdLine : INTEGER;
BEGIN
 INHERITED RefreshListBox;
 WITH MacroRec^ DO
  BEGIN
   FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
    BEGIN
     IF Assigned(MAC_Lines[OrdLine]) THEN
      BEGIN
       MAC_Lines[OrdLine]^.Line.MACL_HeaderRef := MAC_Header.MAC_UniqueRef;
      END;
    END;
  END;
END;

PROCEDURE TMacroEdit.ResetMacroEditor;
BEGIN
 MacroFile^.ClearLines(MacroRec);                { Clear Recipe Lines       }
 MacroFile^.InitRecord(MacroRec);                { Init Recipe Record       }
 ClearAllOfList;                                 { Clear List Screen Array  }
 ListIndex := 1;                                 { Reset HiliteBar Pos.     }

 NewRecord   := MacroRef = 0;
 IF NewRecord THEN
  BEGIN
   First_Field := MacroNO_F;                     { Set First Entry Field    }
  END
 ELSE
  BEGIN
   First_Field := ListBoX_F;                     { Set First Entry Field    }
                                                 { Prime Key Fields         }
   MacroRec^.MAC_Header.MAC_UniqueRef := MacroRef;
   IF MacroFile^.ReadAllRecords('EQ',FALSE,FALSE,MacroRec,0) <> 0 THEN
    BEGIN
     Disp_Error_Msg('Macro Record Not Found');  { Recipe Record Not Found  }
     Esc_Flag := TRUE;                           { Forced Exit              }
    END;
  END;

 IF NOT Esc_Flag THEN
  BEGIN
   DisplayFields;                                { Update Screen Fields     }
   RefreshListBox;                               { Redraw Ingredient List   }
   FieldNo := First_Field;                       { Set Field Pointer        }
  END;
END;

PROCEDURE TMacroEdit.Setup;                 { Called From TFileBrowser.Run }
BEGIN
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,EditWindow);
 EditWindowUp := TRUE;
 MenuCr :='xx';
 DisplayStaticTextAndFields('FXMACED');
 ResetMacroEditor;
END;

{***************************************************************************}
{********* ENTRY FIELD HANDLING METHODS                           **********}
{***************************************************************************}
{ INPUT VALUE PUT ENTERED FIELD INTO Record BUFFER                          }
PROCEDURE TMacroEdit.Input_Value(Field_Str : STRING; Field : INTEGER);
VAR Number,Dummy : INTEGER;
BEGIN
 WITH MacroRec^.MAC_Header DO
  BEGIN
   CASE Field OF
    MACRONO_F : BEGIN
     MAC_HeaderName := Field_Str;
    END;
   END;
  END;
END;

{ OUTPUT VALUE, GET Record DATA INTO EDIT BUFFER }
FUNCTION TMacroEdit.Output_Value(Field : INTEGER) : STRING;
VAR FieldStr : STRING;
BEGIN
 FieldStr :='';
 WITH MacroRec^.MAC_Header DO
  BEGIN
   CASE Field OF
    MACRONO_F : FieldStr := MAC_HeaderName;
   END;
 END;
 Output_Value := FieldStr;
END;

{ DISPLAY FIELD, DISPLAY INDIVIDUAL FIELD }
PROCEDURE TMacroEdit.DisplayField(Field : INTEGER);
BEGIN
 CASE Field OF
  MACRONO_F : BEGIN
    WriteField(XCoOrd[Field],YcoOrd[Field],Output_Value(Field),TRUE);
  END;
 END;
END;

PROCEDURE TMacroEdit.EditField(Field : LONGINT);
VAR WrkStr : STRING;
    Int,Dummy : INTEGER;
BEGIN
 WrkStr := Output_Value(Field);
 CASE Field OF
   MACRONO_F : GetLine(WrkStr,LenOrd[Field],Xcoord[Field],Ycoord[Field]);
 END;
 IF (ch1 <> FN_F10) OR (Ch1 <> ESC) THEN Input_Value(WrkStr,Field);
 IF ch1 = ESC THEN Esc_Flag := TRUE;
END;


FUNCTION TMacroEdit.ReadRecordFunc(Operation : STRING) : INTEGER;
VAR Result : INTEGER;

 PROCEDURE CheckAssigned(ErrorCode : INTEGER);
  BEGIN
   IF NOT Assigned(MacroRec^.MAC_Lines[CurrLine]) THEN
     Result := ErrorCode;
  END;

BEGIN
 Result := 0;
 IF Operation = 'GF' THEN
  BEGIN
   CurrLine := 1;
   CheckAssigned(BNoRecord);
  END
 ELSE IF Operation = 'GL' THEN
  BEGIN
   CurrLine := MAX_LINES_ON_RECORD;
   CheckAssigned(BNoRecord);
  END
 ELSE IF Operation = 'EQ' THEN
  BEGIN
   IF CurrLine < 1 THEN Result := 4
   ELSE IF CurrLine > MAX_LINES_ON_RECORD THEN Result :=4;
   IF Result = 0 THEN CheckAssigned(BNoRecord);
  END
 ELSE IF Operation = 'GE' THEN
  BEGIN
   IF CurrLine < 1 THEN CurrLine := 1
   ELSE IF CurrLine > MAX_LINES_ON_RECORD THEN Result :=9;
   IF Result = 0 THEN CheckAssigned(BEndOfFile);
  END
 ELSE IF (Operation = 'GT')  OR (Operation = 'GN') THEN
  BEGIN
   IF CurrLine < MAX_LINES_ON_RECORD THEN INC(CurrLine)
   ELSE Result := 9;
   IF Result=0 THEN CheckAssigned(BEndOfFile);
  END
 ELSE IF (Operation = 'LT') OR (Operation ='GP') THEN
  BEGIN
   IF CurrLine > 1 THEN DEC(CurrLine)
   ELSE Result := 9;  { Begining of File }
   IF Result = 0 THEN CheckAssigned(BEndOfFile);
  END;
 ReadRecordFunc :=Result;
END;

PROCEDURE TMacroEdit.FillListPosWithRec(Element   : BYTE);
BEGIN
 IF Assigned(MacroRec^.MAC_Lines[CurrLine]) THEN
  BEGIN
   BrowseList[Element].LineNo := CurrLine;
  END
 ELSE
  BEGIN
   BrowseList[Element].LineNo := 0;
  END;
END;

PROCEDURE TMacroEdit.DisplayListItem(Element   : BYTE);
VAR Line : LONGINT;
BEGIN
 IF (NOT ListPosIsEmpty(Element)) THEN
  BEGIN
   WITH MacroRec^.MAC_Lines[Element]^ DO
    BEGIN
     IF (Item.REP_Report >=1) OR (Item.REP_Report <=9) THEN
      BEGIN
       Write(' ',GetReportTitle(Item.REP_Report),' ');
       Write(Item.REP_ID);
      END
     ELSE Write(BLANK_RCPLINE);
    END;
  END
 ELSE Write(BLANK_RCPLINE);
END;

PROCEDURE TMacroEdit.GetBrowseEvent;
VAR DispCol : BYTE;
    FoundSite : BOOLEAN;
    SError    : INTEGER;
BEGIN
  IF FieldNo =LISTBOX THEN
   BEGIN                                        { Use Inherited Method     }
    INHERITED GetBrowseEvent;                   { To Handle List Functions }
   END
  ELSE
   BEGIN
    CursorOn;
    EditField(FieldNo);
    CursorOFF;
    DisplayField(FieldNo);
   END;                                          { END (Not OnListBox)      }
END;

{ Eventhandled Method is used to handle events that are additional to those }
{ Handled By Standard Browse ie. INSERT,DELETE Etc.                         }
FUNCTION TMacroEdit.EventHandled : BOOLEAN;
VAR ErrInt        : INTEGER;
    TempHeaderRec : TMacroHeaderRecord;
    HandledEvent  : BOOLEAN;
BEGIN
 HandledEvent := FALSE;

 IF Funckey THEN
  BEGIN
   CASE ch1 OF
    FN_F5,FN_F6 : HandledEvent := TRUE;
    FN_F10 : BEGIN
      IF YesNoWin('Abandon Recipe Edit (Y/N)?') THEN Esc_Flag := TRUE;
      HandledEvent := TRUE;
    END;

   END;                                          { END (CASE Ch1 OF)        }
  END
 ELSE
  BEGIN
   CASE ch1 OF
    ESC : BEGIN                                  { ESC KEY PRESSED          }
      IF NOT NowtButSpace(MacroRec^.MAC_Header.MAC_HeaderName) THEN
       BEGIN                                     { IF Record TO SAVE        }
        (* Record ADD/UPDATE CODE GOES HERE *)
        IF NOT NewRecord THEN
         BEGIN
          TempHeaderRec.MAC_UniqueRef := MacroRef;
          MacroFile^.HeaderFile^.ReadRecord('EQ',TRUE,FALSE,TempHeaderRec,0);
          CASE MacroFile^.HeaderFile^.BtrvErr OF
           0  : BEGIN
            IF TempHeaderRec.MAC_UpdateCount <> MacroRec^.MAC_Header.MAC_UpdateCount THEN
             BEGIN
              MacroFile^.HeaderFile^.Unlock_Single; { Unlock Recipe Record      }
              Rec_Changed_Error(FALSE);        { Display Rec Changed        }
              ResetMacroEditor;                { Re-Read Recipe Record       }
              Esc_Flag := FALSE;               { Cycle To Next Event        }
             END
            ELSE
             BEGIN
              MacroFile^.UpdateRecord(MacroRec);  { Update Records To Files    }
             END;
           END;

           BNoRecord : BEGIN        { Record Deleted By Another Workstation }
            IF Upcase(Rec_Changed_Error(TRUE)) = 'Y' THEN
             BEGIN
              Show_Btrv_Err(MacroFile^.AddRecord(MacroRec));
             END;
           END;

           ELSE Show_Btrv_Err(MacroFile^.HeaderFile^.BtrvErr);
          END;
         END  { END (NOT NewRecord) }
        ELSE
         BEGIN                                       { NEW Record TO ADD }
          MacroFile^.AddRecord(MacroRec);
          IF MacroFile^.BtrvErr = BDuplicate THEN
           BEGIN
            Rec_Changed_Error(FALSE);
            Esc_Flag := FALSE;
           END;
         END;
       END;
     END;                                        { END (ESC Key Pressed)    }
   END; { END (CASE)}
  END; { END (ELSE) }
 IF NOT HandledEvent THEN HandledEvent := INHERITED EventHandled;
 EventHandled := HandledEvent;
END;


PROCEDURE TMacroEdit.DeleteListItem(Element   : BYTE);
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   IF (MacroRec^.MAC_Lines[Element]^.Line.MACL_HeaderRef = 0) OR
   YesNoWin('          Delete Record'+CRLF+
               '         Are You Sure Y/N') THEN
    BEGIN
     MacroFile^.DeleteLineRec(MacroRec,BrowseList[Element].LineNo);
     RefreshListBox;
    END
  END;
END;

FUNCTION TMacroEdit.AddMacroLine : LONGINT;
VAR LPA : LONGINT;
BEGIN
 AddMacroLine := 0;
 FOR LPA := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF (NOT Assigned(MacroRec^.MAC_Lines[LPA])) THEN
    BEGIN
     NEW(MacroRec^.MAC_Lines[LPA]);
     MacroFile^.LineFile^.InitRecord(MacroRec^.MAC_Lines[LPA]^.Line);
     RepMacroFile^.InitRecord(MacroRec^.MAC_Lines[LPA]^.Item);
     MacroRec^.MAC_Lines[LPA]^.Line.MACL_HeaderRef := MacroRec^.MAC_Header.MAC_UniqueRef;
     AddMacroLine := LPA;
     Break;
    END;
  END;
END;

PROCEDURE TMacroEdit.InsertListItem;
VAR EditLine : LONGINT;
BEGIN
 IF FieldNo <> LISTBOX THEN EXIT;
 EditLine := AddMacroLine;
 IF (EditLine > 0) THEN
  BEGIN
   IF (NOT EditLineRecord(EditLine,TRUE)) THEN
     MacroFile^.DeleteLineRec(MacroRec,EditLine);
   RefreshListBox;
  END;
END;

FUNCTION TMacroEdit.EditLineRecord(Element : BYTE;NewLine : BOOLEAN) : BOOLEAN;
VAR I : INTEGER;
BEGIN
 IF NOT NewLine THEN
  BEGIN
   EditLineRecord := TRUE;
   EXIT;
  END;
 EditLineRecord := FALSE;
 IF LookUpRepMacro(MacroRec^.MAC_Lines[Element]^.Item) THEN
  BEGIN
   WITH MacroRec^ DO
    BEGIN
     FOR I := 1 TO MAX_LINES_ON_RECORD DO
      BEGIN
       IF Assigned(MAC_Lines[I]) AND (I <> Element) AND
        (MAC_Lines[I]^.Line.MACL_LineRef = MAC_Lines[Element]^.Item.REP_UniqueRef) THEN
         BEGIN
          Disp_Error_Msg('Report Already Added To Group');
          EditLineRecord := FALSE;
          EXIT;
         END;
      END;
     MAC_Lines[Element]^.Line.MACL_LineRef := MAC_Lines[Element]^.Item.REP_UniqueRef;
     EditLineRecord := TRUE;
    END;
  END;
END;

PROCEDURE Edit_Macro(MacroNo : LONGINT);
VAR MacroEditor : PMacroEdit;
    MacroFileAlloc : BOOLEAN;
BEGIN
 MacroFileAlloc := Assigned(MacroFile);
 IF NOT MacroFileAlloc THEN
  BEGIN
   NEW(MacroFile,Init(Config_Rec^.Conf_FPath+MacroHeader_FileName,
                   Config_Rec^.Conf_FPath+MacroLine_FileName));
  END;
 NEW(MacroEditor,Init(MacroNo));
 MacroEditor^.Run;
 DISPOSE(MacroEditor,Done);
 IF NOT MacroFileAlloc THEN
  BEGIN
   DISPOSE(MacroFile,Done);
   MacroFile := NIL;
  END;
END;


END.

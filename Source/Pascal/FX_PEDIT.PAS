(****************************************************************************
*  UNIT          : FX_PEdit                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 08/05/96                                                 *
*  PURPOSE       : FORMIX Product Editor                                    *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FX_PEdit;
INTERFACE

USES CRT,F6STDCTV,F6STDWN1,F6STDWIN,F6STDUTL,F6STDUT1,F6STDBRW,F6SCREEN,FX_EDIT,
     F6DTCONV,F6RECCHG,FXMODCTV,FXCFG,FXFCPRD,FXFRCP,FX_EDesc,
     FXFProd,FXBRW_RP,FXBrw_PD;

PROCEDURE Edit_Product(ProductCode : TProductRef);

IMPLEMENTATION
USES FXBRW_PR;

CONST WIN_X            = 01;          { WINDOW X Offset       (Global )     }
      WIN_Y            = 2;           { WINDOW Y Offset       (Global )     }
      WIN_WID          = 77;          { WINDOW Width          (Global )     }
      WIN_DEP          = 22;          { WINDOW Depth          (Global )     }

CONST EWIN_X           = 22;          { ITEM EDIT WINDOW X Offset (Global ) }
      EWIN_Y           = WIN_Y+9;     { ITEM EDIT WINDOW Y Offset (Global ) }
      EWIN_WID         = 42;          { ITEM EDIT WINDOW Width    (Global ) }
      EWIN_DEP         = 8;           { ITEM EDIT WINDOW Depth    (Global ) }
      EWIN_X2          = EWIN_X+EWIN_WID;
      EWIN_Y2          = EWIN_Y+EWIN_DEP;

      HELP_X1          = 09;
      HELP_Y1          = 05;
      HELP_X2          = 66;
      HELP_Y2          = 07;

      LIST_X           = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH       = WIN_WID-3;   { LIST BOX WIDTH        (Global )     }
      LIST_Y           = WIN_Y+08;    { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH       = WIN_DEP-11;  { LIST BOX DEPTH        (Global )     }

      BLANK_RCPLINE    = '   ------     --------    --------   ------------------------------';

      ProductNO_F       = 1;
      DESC_F            = 2;
      CASESIZE_F        = 3;
      LISTBOX           = 4;
      FIRSTFIELD        = ProductNO_F;   { Start Field ID                      }
      LASTFIELD         = LISTBOX;       { Last Field ID          }

TYPE

     PProductEdit = ^TProductEdit;
     TProductEdit = object(TCombinedRecordEdit)

      ProductNo      : TProductRef;
      ProductRec     : PProdRecord;
      RecipeRec      : TRecipeHeaderRecord;

      CONSTRUCTOR Init(Product : TProductRef);
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   Setup; Virtual;
      FUNCTION    ReadRecordFunc       (Operation : STRING) : INTEGER; Virtual;
      PROCEDURE   FillListPosWithRec   (Element   : BYTE); Virtual;
      PROCEDURE   DisplayListItem      (Element   : BYTE); Virtual;
      PROCEDURE   GetBrowseEvent; Virtual;
      FUNCTION    EventHandled         : BOOLEAN; Virtual;
      PROCEDURE   ResetProductEditor;
      FUNCTION    Output_Value(Field : INTEGER) : STRING;
      PROCEDURE   Input_Value(Field_Str : STRING; Field : INTEGER);
      PROCEDURE   DisplayField(Field : INTEGER); VIRTUAL;
      PROCEDURE   EditField(Field : LONGINT);
      PROCEDURE   DeleteListItem       (Element   : BYTE); Virtual;
      PROCEDURE   InsertListItem; Virtual;
      FUNCTION    AddRcpLine : LONGINT; Virtual;
      PROCEDURE   MoveItemUpList(Element : BYTE); Virtual;
      PROCEDURE   MoveItemDownList(Element : BYTE); Virtual;
      FUNCTION    EditLineRecord          (Element   : BYTE;NewLine : BOOLEAN) : BOOLEAN; Virtual;
      PROCEDURE   Enter_Prod_Descriptions;
      FUNCTION    Save_Product_Record(ReRead : BOOLEAN) : BOOLEAN;
      FUNCTION    GetMethodNumber(VAR MethodNo : INTEGER;VAR ProdDescBrowse : PProdDescBrowse): BOOLEAN;
      FUNCTION    InsertRecordLineAt(Element : BYTE) : BOOLEAN;VIRTUAL;
      PROCEDURE   RefreshListBox; VIRTUAL;
     END;


CONSTRUCTOR TProductEdit.Init(Product : TProductRef);
BEGIN
 ProductNo  := Product;
 { Inherited Method Clears Screen List Array }
 INHERITED Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH,FIRSTFIELD,LASTFIELD,LISTBOX);
 {Clear Defaults}

 Show_Btrv_Err(RecipeHeaderFile^.OpenFile);
 IF RecipeHeaderFile^.OpenErr <> 0 THEN Esc_Flag := TRUE;

 Show_Btrv_Err(ProdFile^.OpenFile);
 IF ProdFile^.OpenErr <> 0 THEN Esc_Flag := TRUE;

 ProductRec := NIL;
 NEW(ProductRec);
 IF Assigned(ProductRec) THEN ProdFile^.InitRecord(ProductRec)
 ELSE Esc_Flag := TRUE;
END;

DESTRUCTOR TProductEdit.Done;
BEGIN
 IF Assigned(ProductRec) THEN
  BEGIN
   ProdFile^.ClearLines(ProductRec);             {Dispose List Of Ingredients   }
   Dispose(ProductRec);                        {Dispose Product Composite Record}
  END;
 ProdFile^.CloseFile;
 RecipeHEaderFile^.CloseFile;
 INHERITED Done;
END;

PROCEDURE TProductEdit.ResetProductEditor;
BEGIN
 ProdFile^.ClearLines(ProductRec);                  { Clear Product Lines       }
 ProdFile^.InitRecord(ProductRec);                  { Init Product Record       }
 ClearAllOfList;                                 { Clear List Screen Array  }
 ListIndex := 1;                                 { Reset HiliteBar Pos.     }

 NewRecord   := NowtButSpace(ProductNo);          { Add Or Edit?             }
 IF NewRecord THEN
  BEGIN
   First_Field := ProductNO_F;                    { Set First Entry Field    }
  END
 ELSE
  BEGIN
   First_Field := DESC_F;                     { Set First Entry Field    }
                                                 { Prime Key Fields         }
   ProductRec^.PR_Header.PH_ProductCode  := ProductNo;
   IF ProdFile^.ReadAllRecords('EQ',FALSE,FALSE,ProductRec,0) <> 0 THEN
    BEGIN
     Disp_Error_Msg('Product Record Not Found');  { Product Record Not Found  }
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

PROCEDURE TProductEdit.Setup;                 { Called From TFileBrowser.Run }
BEGIN
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,EditWindow);
 EditWindowUp := TRUE;
 DisplayStaticTextAndFields('FXPRODED');
 ResetProductEditor;
END;

{***************************************************************************}
{********* ENTRY FIELD HANDLING METHODS                           **********}
{***************************************************************************}
{ INPUT VALUE PUT ENTERED FIELD INTO Record BUFFER                          }
PROCEDURE TProductEdit.Input_Value(Field_Str : STRING; Field : INTEGER);
VAR CheckProduct : TProdHeaderRecord;
BEGIN
 WITH ProductRec^.PR_Header DO
  BEGIN
   CASE Field OF
    ProductNO_F : BEGIN
     IF NowtButSpace(Field_Str) THEN
      BEGIN
       ch1 := ' ';
       Disp_Error_Msg('Product Code Needed');
      END
     ELSE
      BEGIN
       PH_ProductCode    := Field_Str+SPACE_STRING;
       IF ProdFile^.Read_Header_Record('EQ',FALSE,FALSE,ProductRec^.PR_Header,0) = 0 THEN
        BEGIN
         Disp_Error_Msg('A Product With That Code Already Exists');
         ch1 := ' ';
         PH_ProductCode := SPACE_STRING;
        END
       ELSE ProductNo := PH_ProductCode;
      END
    END;
    DESC_F : PH_Description := Field_Str;
    CASESIZE_F : BEGIN
                  PH_CaseSize := StringToDouble(Field_Str);
                  IF PH_CaseSize = 0.0 THEN
                   BEGIN
                    Disp_Error_Msg('Can Not Have A Case Size Of Zero');
                    ch1 := ' ';
                    Esc_flag := FALSE;
                   END;
                 END;
   END;
  END;
END;

{ OUTPUT VALUE, GET Record DATA INTO EDIT BUFFER }
FUNCTION TProductEdit.Output_Value(Field : INTEGER) : STRING;
VAR FieldStr : STRING;
BEGIN
 FieldStr :='';
 WITH ProductRec^.PR_Header DO
  BEGIN
   CASE Field OF
    ProductNO_F : FieldStr := PH_ProductCode;
    DESC_F      : FieldStr := PH_Description;
    CASESIZE_F  : FieldStr := DoubleToZeroStr(PH_CaseSize,9,3);
   END;
 END;
 Output_Value := FieldStr;
END;

{ DISPLAY FIELD, DISPLAY INDIVIDUAL FIELD }
PROCEDURE TProductEdit.DisplayField(Field : INTEGER);
BEGIN
 CASE Field OF
  ProductNO_F,
  DESC_F,
  CASESIZE_F : BEGIN
    WriteField(XcoOrd[Field],YcoOrd[Field],Output_Value(Field),TRUE);
  END;
 END;
END;

PROCEDURE TProductEdit.EditField(Field : LONGINT);
VAR WrkStr : STRING;
BEGIN
 WrkStr := Output_Value(Field);
 CASE Field OF
   ProductNO_F,
   Desc_F : GetLine(WrkStr,LenOrd[Field],Xcoord[Field],Ycoord[Field]);
   CASESIZE_F : GetFloat(Xcoord[Field],Ycoord[Field],WrkStr,LenOrd[Field],3);
 END;
 IF (ch1 <> FN_F10) OR (Ch1 <> ESC) THEN Input_Value(WrkStr,Field);
 IF ch1 = ESC THEN Esc_Flag := TRUE;
END;


FUNCTION TProductEdit.ReadRecordFunc(Operation : STRING) : INTEGER;
VAR Result : INTEGER;

 PROCEDURE CheckAssigned(ErrorCode : INTEGER);
  BEGIN
   IF NOT Assigned(ProductRec^.PR_Lines[CurrLine]) THEN
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

PROCEDURE TProductEdit.FillListPosWithRec(Element   : BYTE);
BEGIN
 IF Assigned(ProductRec^.PR_Lines[CurrLine]) THEN
  BEGIN
   BrowseList[Element].LineNo := ProductRec^.PR_Lines[CurrLine]^.PL_LineNo;
  END
 ELSE
  BEGIN
   BrowseList[Element].LineNo := 0;
  END;
END;

PROCEDURE TProductEdit.RefreshListBox;
VAR LineNo : INTEGER;
BEGIN
 INHERITED RefreshListBox;
 WITH ProductRec^ DO
  BEGIN
   FOR LineNo := 1 TO MAX_LINES_ON_RECORD DO
    BEGIN
     IF Assigned(PR_Lines[LineNo]) THEN
      BEGIN
       TotalLineRatio := TotalLineRatio + PR_Lines[LineNo]^.PL_Ratio;
      END;
    END;
  END;
 WriteAt(2,LIST_Y+LIST_DEPTH-2,'Total Line Ratio :  '+DoubleToStr(TotalLineRatio,4,3)+'%');
END;

PROCEDURE TProductEdit.DisplayListItem(Element   : BYTE);
VAR Line : LONGINT;
BEGIN
 IF (NOT ListPosIsEmpty(Element)) THEN
  BEGIN
   WITH ProductRec^.PR_Lines[BrowseList[Element].LineNo]^ DO
    BEGIN
     Write('   ',PL_LineNo:6,'     ');
     IF NowtButSpace(PL_RecipeNo) THEN
      BEGIN
       Write(PL_SubProduct,'   ');
       Write(PL_Ratio:7:3,'   '+GetProductName(PL_SubProduct));
      END
     ELSE
      BEGIN
       Write(PL_RecipeNo  ,'     ');
       Write(PL_Ratio:7:3,'   '+GetRecipeName(PL_RecipeNo));
      END;
    END;
  END
 ELSE Write(BLANK_RCPLINE);
END;

PROCEDURE TProductEdit.GetBrowseEvent;
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

FUNCTION TProductEdit.Save_Product_Record(ReRead : BOOLEAN) : BOOLEAN;
VAR
    TempHeaderRec : TProdHeaderRecord;
BEGIN
 Save_Product_Record := TRUE;
 IF NOT NowtButSpace(ProductRec^.PR_Header.PH_ProductCode) THEN
  BEGIN                                     { IF Record TO SAVE        }
   (* Record ADD/UPDATE CODE GOES HERE *)
   IF NOT NewRecord THEN
    BEGIN
     TempHeaderRec.PH_ProductCode := ProductNo;
     ProdFile^.HeaderFile^.ReadRecord('EQ',TRUE,FALSE,TempHeaderRec,0);
     CASE ProdFile^.HeaderFile^.BtrvErr OF
      0  : BEGIN
            IF TempHeaderRec.PH_UpdateCount <> ProductRec^.PR_Header.PH_UpdateCount THEN
             BEGIN
              ProdFile^.HeaderFile^.Unlock_Single; { Unlock Product Record      }
              Rec_Changed_Error(FALSE);        { Display Rec Changed        }
              ResetProductEditor;              { Re-Read Product Record       }
              Esc_Flag := FALSE;               { Cycle To Next Event        }
              Save_Product_Record := FALSE;
             END
            ELSE
             BEGIN
              ProdFile^.UpdateRecord(ProductRec);  { Update Records To Files    }
             END;
           END;

      BNoRecord : BEGIN        { Record Deleted By Another Workstation }
            IF Upcase(Rec_Changed_Error(TRUE)) = 'Y' THEN
             BEGIN
              Show_Btrv_Err(ProdFile^.AddRecord(ProductRec));
              IF ProdFile^.BtrvErr <> 0 THEN Save_Product_Record:=FALSE;
             END;
           END;

     ELSE
      BEGIN
       Show_Btrv_Err(ProdFile^.HeaderFile^.BtrvErr);
       Save_Product_Record := FALSE;
      END
     END; {CASE}
    END  { END (NOT NewRecord) }
   ELSE
    BEGIN                                       { NEW Record TO ADD }
     ProdFile^.AddRecord(ProductRec);
     IF ProdFile^.BtrvErr = BDuplicate THEN
      BEGIN
       Rec_Changed_Error(FALSE);
       Esc_Flag := FALSE;
       Save_Product_Record := FALSE;
      END;
     NewRecord := FALSE;
    END;
  END;
 IF ReRead THEN
  BEGIN
   ResetProductEditor;
  END;
END;

FUNCTION TProductEdit.InsertRecordLineAt(Element : BYTE) : BOOLEAN;
VAR LPA        : INTEGER;
    LineNumber : LONGINT;
BEGIN
 InsertRecordLineAt := FALSE;
 IF ListPosIsEmpty(Element) THEN Exit;
 LineNumber := BrowseList[Element].LineNo;

 IF (NOT Assigned(ProductRec^.PR_Lines[MAX_LINES_ON_RECORD])) THEN
  BEGIN
   FOR LPA := MAX_LINES_ON_RECORD-1 DOWNTO LineNumber DO
    BEGIN
     IF ProductRec^.PR_Lines[LPA] <> NIL THEN
      BEGIN
       ProductRec^.PR_Lines[LPA+1] := ProductRec^.PR_Lines[LPA];
       ProductRec^.PR_Lines[LPA+1]^.PL_LineNo := LPA+1;
       ProductRec^.PR_LinePos[LPA+1] := ProductRec^.PR_LinePos[LPA];
      END;
    END;
   ProductRec^.PR_Lines[LineNumber]     := NIL;
   ProductRec^.PR_LinePos[LineNumber]   := 0;
   NEW(ProductRec^.PR_Lines[LineNumber]);
   IF Assigned(ProductRec^.PR_Lines[LineNumber]) THEN
    BEGIN
     ProdFile^.LineFile^.InitRecord(ProductRec^.PR_Lines[LineNumber]^);
     ProductRec^.PR_Lines[LineNumber]^.PL_ProductCode := ProductRec^.PR_Header.PH_ProductCode;
     ProductRec^.PR_Lines[LineNumber]^.PL_LineNo   := LineNumber;
     InsertRecordLineAt := TRUE;
    END;
  END;
END;


{ Eventhandled Method is used to handle events that are additional to those }
{ Handled By Standard Browse ie. INSERT,DELETE Etc.                         }
FUNCTION TProductEdit.EventHandled : BOOLEAN;
VAR ErrInt        : INTEGER;
    HandledEvent  : BOOLEAN;
BEGIN
 HandledEvent := FALSE;

 IF Funckey THEN
  BEGIN
   CASE ch1 OF
    FN_F7  : BEGIN
      Enter_Prod_Descriptions;
      HandledEvent := TRUE;
    END;

    FN_F10 : BEGIN
      IF YesNoWin('Abandon Product Edit (Y/N)?') THEN Esc_Flag := TRUE;
      HandledEvent := TRUE;
    END;

   END;                                          { END (CASE Ch1 OF)        }
  END
 ELSE
  BEGIN
   CASE ch1 OF
    ESC : BEGIN                                  { ESC KEY PRESSED          }
      Save_Product_Record(FALSE);
     END;                                        { END (ESC Key Pressed)    }
   END; { END (CASE)}
  END; { END (ELSE) }

 IF NOT HandledEvent THEN HandledEvent := INHERITED EventHandled;
 EventHandled := HandledEvent;
END;


PROCEDURE TProductEdit.DeleteListItem(Element   : BYTE);
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   IF NowtButSpace(ProductRec^.PR_Lines[Element]^.PL_RecipeNo) OR
     YesNoWin('          Delete Record'+CRLF+
               '         Are You Sure Y/N') THEN
    BEGIN
     ProdFile^.DeleteLineRec(ProductRec,BrowseList[Element].LineNo);
     RefreshListBox;
    END
  END;
END;


FUNCTION TProductEdit.EditLineRecord(Element   : BYTE;NewLine : BOOLEAN) : BOOLEAN;
{ Field Constants }
CONST
      RECIPE_F  = 1; { Ingredient Code                }
      PROD_F    = 2;
      MIXRAT_F  = 3; { Mix Ratio                      }

      FIRSTL_F  = RECIPE_F;
      LASTL_F   = MIXRAT_F;

VAR   FirstLineField : BYTE;
      LField         : BYTE;
      ProductLine    : LONGINT;
      EProductLine   : TProdLineRecord;
      HelpWin        : WindowRecord;

 PROCEDURE DrawEditWindow;
 BEGIN
  BackColourScheme;
  SetWindow(HELP_X1,HELP_Y1,HELP_X2,HELP_Y2,TRUE,SW_DEFAULT,SW_DEFAULT,HelpWin);
  HighVideo;
  Write('You May Only Add Either A Recipe Or A Product To A Line');
  LowVideo;

  SetWindow(EWIN_X,EWIN_Y,EWIN_X2,EWIN_Y2,TRUE,SW_Default,SW_Default,ItemWindow);
  Header('Product Item Editor',1);
  HighWriteAt(1,3,'   Recipe No :');
  HighWriteAt(1,4,'   Product No:');
      WriteAt(1,5,'   Ratio     :');
  DrawLineAt(6);
  ClearEdit;
  FillChar(XCoOrd, SizeOf(XCoOrd), 0);
  FillChar(YCoOrd, SizeOf(YCoOrd), 0);
  AddEdit(17, 3, 8, 0);
  AddEdit(17, 4,10, 0);
  AddEdit(17, 5, 8, 0);
  ForeColourScheme;
 END;

 PROCEDURE RemoveEditWindow;
 BEGIN
  LoseWindow(ItemWindow);
  LoseWindow(HelpWin);
  DisplayStaticTextAndFields('FXPRODED');  { Reload Product Editor Fields   }
 END;

 FUNCTION LineFieldValue(Field : BYTE) : STRING;
 VAR Field_Str : STRING;
     TempLong  : LONGINT;
 BEGIN
  Field_Str := '';
  WITH ProductRec^.PR_Header,EProductLine DO
   BEGIN
    CASE Field OF
     RECIPE_F : Field_Str := PL_RecipeNo;
     PROD_F   : Field_Str := PL_SubProduct;
     MIXRAT_F : Field_Str := DoubleToZeroStr(PL_Ratio,LenOrd[MIXRAT_F],3);
    END;
   END;
  LineFieldValue := Field_Str;
 END;

 PROCEDURE DisplayLineField(Field_Str : STRING;Field : BYTE);
 BEGIN
  WriteField(XcoOrd[Field],YcoOrd[Field],Field_Str,TRUE);
  CASE Field OF
   RECIPE_F : IF NOT NowtButSpace(Field_Str) THEN
    WriteField(2,7,GetRecipeName(Field_Str),FALSE);
   PROD_F   : IF NOT NowtButSpace(Field_Str) THEN
    WriteField(2,7,GetProductName(Field_Str),FALSE);
  END;
 END;

 PROCEDURE DisplayLineFields;
 VAR LPA : BYTE;
 BEGIN
  CursorOFF;
  FOR LPA := 1 TO LASTL_F DO DisplayLineField(LineFieldValue(LPA),LPA);
  CursorON;
 END;

 PROCEDURE InputLineField(Field_Str : STRING; Field : BYTE);
 VAR tmpProdRec : TProdHeaderRecord;
 BEGIN
  WITH EProductLine DO
   BEGIN
    CASE Field OF
     RECIPE_F : BEGIN
      IF NOT NowtButSpace(Field_Str) THEN
       BEGIN
        RecipeRec.RH_RecipeNo    := Field_Str;
        RecipeHeaderFile^.ReadRecord('GE',FALSE,FALSE,RecipeRec,0);
        IF (RecipeHeaderFile^.BtrvErr = 0) AND (RecipeRec.RH_RecipeNo = Field_Str) THEN
         BEGIN
          PL_RecipeNo    := Field_Str;
         END
       END
      ELSE PL_RecipeNo := SPACE_STRING;
     END;
     PROD_F : BEGIN
      IF NOT NowtButSpace(Field_Str) THEN
       BEGIN
        tmpProdRec.PH_ProductCode := Field_Str;
        IF ProdHEaderFile^.ReadRecord('EQK',FALSE,FALSE,tmpProdRec,0) = 0 THEN
         BEGIN
          PL_SubProduct := Field_Str;
         END;
       END
      ELSE PL_SubProduct := SPACE_STRING;
     END;
     MIXRAT_F : BEGIN
      PL_Ratio                   := StringToDouble(Field_Str);
     END;
    END;
   END;
 END;

 PROCEDURE EditLineRecordField(Field : LONGINT);
 VAR WrkStr : STRING;
 BEGIN
  WrkStr := LineFieldValue(Field);
  CASE Field OF
   RECIPE_F  : BEGIN                                        {Ingredient Code}
     IF NowtButSpace(EProductLine.PL_SubProduct) THEN
      GetLine(WrkStr,LenOrd[Field],XCoord[Field],YCoord[Field]);
   END;
   PROD_F : BEGIN
     IF NowtButSpace(EProductLine.PL_RecipeNo) THEN
      GetLine(WrkStr,LenOrd[Field],XCoord[Field],YCoord[Field]);
   END;
   MIXRAT_F : BEGIN                                       {Mix Ratio     }
     GetFloat(XCoord[Field],YCoord[Field],WrkStr,LenOrd[Field],3);
   END;
  END;
  IF (ch1 <> FN_F10) AND (ch1 <> ESC) THEN InputLineField(WrkStr,Field);
  IF ch1 = ESC THEN Esc_Flag := TRUE;
 END;

 PROCEDURE  HandleLineEntryEvent;
 BEGIN
  IF FuncKey THEN
   BEGIN
    CASE ch1 OF
     PREV : IF LField > FirstLineField THEN DEC(LField) ELSE LField := LASTL_F;
     NEXT : IF LField < LASTL_F THEN INC(LField) ELSE LField := FirstLineField;
     FN_F1: IF LField = RECIPE_F THEN BrowseRecipe(EProductLine.PL_RecipeNo,
                                                   FALSE{OkToSelectObsolete})
            ELSE IF LField = PROD_F THEN BrowseProduct(EProductLine.PL_SubProduct);

     FN_F10 : BEGIN
      IF YesNoWin('Abandon Product Line Edit (Y/N)?') THEN Esc_Flag := TRUE;
     END;

    END;
   END
  ELSE
   BEGIN
    CASE ch1 OF
     ESC: BEGIN
      (* SAVE CHANGES *)
      IF (NOT NowtButSpace(EProductLine.PL_RecipeNo)) OR
         (NOT NowtButSpace(EProductLine.PL_SubProduct)) THEN
       BEGIN
        ProductRec^.PR_Lines[Element]^ := EProductLine;
        EditLineRecord := TRUE;
       END;
      Esc_Flag := TRUE;
     END;
    END;
   END;
 END;


BEGIN
  EditLineRecord := FALSE;
  DrawEditWindow;
  EProductLine := ProductRec^.PR_Lines[Element]^;           { Copy Product Line }
  {Line Used So That Conversion Program Is Not Needed}
  EProductLine.PL_SubProduct := EProductLine.PL_SubProduct + SPACE_STRING;
  IF NewLine THEN
   BEGIN
    FirstLineField :=FIRSTL_F;
   END
  ELSE FirstLineField := MIXRAT_F;
  DisplayLineFields;
  ch1 := NEXT;
  LField := FirstLineField;
  REPEAT
   EditLineRecordField(LField);
   DisplayLineFields;
   HandleLineEntryEvent;
  UNTIL Esc_Flag;
  RemoveEditWindow;
  Esc_Flag := FALSE;
  Ch1 :=' ';
  TotalLineRatio := 0;
END;

FUNCTION TProductEdit.AddRcpLine : LONGINT;
VAR LPA : LONGINT;
BEGIN
 AddRcpLine := 0;
 FOR LPA := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF (NOT Assigned(ProductRec^.PR_Lines[LPA])) THEN
    BEGIN
     NEW(ProductRec^.PR_Lines[LPA]);
     ProdFile^.LineFile^.InitRecord(ProductRec^.PR_Lines[LPA]^);
     ProductRec^.PR_Lines[LPA]^.PL_ProductCode := ProductRec^.PR_Header.PH_ProductCode;
     ProductRec^.PR_Lines[LPA]^.PL_LineNo := LPA;
     AddRcpLine := LPA;
     Break;
    END;
  END;
END;

PROCEDURE TProductEdit.InsertListItem;
VAR EditLine : LONGINT;
BEGIN
 IF FieldNo <> LISTBOX THEN EXIT;
 EditLine := AddRcpLine;
 IF (EditLine > 0) THEN
  BEGIN
   IF (NOT EditLineRecord(EditLine,TRUE)) THEN
     ProdFile^.DeleteLineRec(ProductRec,EditLine);
   RefreshListBox;
  END;
END;

PROCEDURE TProductEdit.MoveItemUpList(Element : BYTE);
VAR CurrOrdLine    : LONGINT;
BEGIN
 IF ListPosIsEmpty(Element) THEN EXIT;
 CurrOrdLine := BrowseList[Element].LineNo;
 IF CurrOrdLine > 1 THEN
  BEGIN
   WITH ProductRec^ DO
    BEGIN
     {Swap Record}
     SwapRecords(Pointer(PR_Lines[CurrOrdLine]),Pointer(PR_Lines[CurrOrdLine-1]));
     {Renumber Lines}
     ProductRec^.PR_Lines[CurrOrdLine-1]^.PL_LineNo := CurrOrdLine-1;
     ProductRec^.PR_Lines[CurrOrdLine]^.PL_LineNo := CurrOrdLine;
     {Swap Positions}
     SwapPositions(PR_LinePos[CurrOrdLine-1],PR_LinePos[CurrOrdLine]);
    END;
   IF ListIndex > 1 THEN
    BEGIN
     DEC(ListIndex);
    END
   ELSE
    BEGIN
     ListIndex := 1;
     BrowseList[1].LineNo :=CurrOrdLine-1;
    END;
   RefreshListBox;
  END;
END;

{return true if a new method}
FUNCTION TProductEdit.GetMethodNumber(VAR MethodNo : INTEGER;VAR ProdDescBrowse : PProdDescBrowse): BOOLEAN;
BEGIN
 GetMethodNumber := FALSE;
 New(ProdDescBrowse,Init(@ProductRec^.PR_Header,TRUE));
 ProdDescBrowse^.Run;
 MethodNo := ProdDescBrowse^.MethodNo;
 IF MethodNo = 0 THEN
  BEGIN
   MethodNo := ProductRec^.PR_Header.PH_NumMethods+1;
   GetMethodNumber:= TRUE;
  END;
END;

PROCEDURE TProductEdit.Enter_Prod_Descriptions;
VAR DescEdit  : PProdDescEdit;
    NewRec    : BOOLEAN;
    MethodNo  : INTEGER;
    ProdDescBrowse : PProdDescBrowse;
BEGIN
 ProdDescBrowse := NIL;
 IF ProductRec^.PR_Header.PH_NumMethods = 0 THEN
  BEGIN
   New(DescEdit,Init(ProductRec^.PR_Header.PH_ProductCode,1));
   NewRec := TRUE;
  END
 ELSE
  BEGIN
   NewRec := GetMethodNumber(MethodNo,ProdDescBrowse);
   IF MethodNo = -1 THEN
    BEGIN
     Dispose(ProdDescBrowse,Done);
     EXIT;
    END;
   New(DescEdit,Init(ProductRec^.PR_Header.PH_ProductCode,MethodNo));
  END;
 DescEdit^.Run;
 DescEdit^.CleanUp;
 IF Assigned(ProdDescBrowse) THEN Dispose(ProdDescBrowse,Done);
 IF DescEdit^.AnEditOccured THEN
  BEGIN
   IF NewRec THEN INC(ProductRec^.PR_Header.PH_NumMethods);
   IF Save_Product_Record(TRUE) THEN DescEdit^.Save_Details;
  END;
 Dispose(DescEdit,Done);
 Esc_Flag := FALSE;
END;


PROCEDURE TProductEdit.MoveItemDownList(Element : BYTE);
VAR CurrOrdLine    : LONGINT;
BEGIN
 IF ListPosIsEmpty(Element) THEN EXIT;
 CurrOrdLine := BrowseList[Element].LineNo;
 IF Assigned(ProductRec^.PR_Lines[CurrOrdLine+1]) THEN
  BEGIN
   WITH ProductRec^ DO
    BEGIN
     SwapRecords(Pointer(PR_Lines[CurrOrdLine]),Pointer(PR_Lines[CurrOrdLine+1]));
     PR_Lines[CurrOrdLine]^.PL_LineNo   := CurrOrdLine;
     PR_Lines[CurrOrdLine+1]^.PL_LineNo := CurrOrdLine+1;
     SwapPositions(PR_LinePos[CurrOrdLine],PR_LinePos[CurrOrdLine+1]);
    END;
   IF ListIndex < LIST_DEPTH THEN
    BEGIN
     INC(ListIndex);
    END
   ELSE
    BEGIN
     BrowseList[LIST_DEPTH].LineNo :=CurrOrdLine+1;
     FillRecWithListKey(LIST_DEPTH);
     FillListUpFrom(LIST_DEPTH);
    END;
   RefreshListBox;
  END;
END;

PROCEDURE Edit_Product(ProductCode : TProductRef);
VAR ProductEditor : PProductEdit;
    ProdFileAlloc : BOOLEAN;
BEGIN
 ProdFileAlloc := Assigned(ProdFile);
 IF NOT ProdFileAlloc THEN
  BEGIN
   NEW(ProdFile,Init(Config_Rec^.Conf_FPath+Product_Header_FileName,
                   Config_Rec^.Conf_FPath+Product_Line_FileName));
  END;
 NEW(ProductEditor,Init(ProductCode));
 ProductEditor^.Run;
 DISPOSE(ProductEditor,Done);
 IF NOT ProdFileAlloc THEN
  BEGIN
   DISPOSE(ProdFile,Done);
   ProdFile := NIL;
  END;
END;


END.

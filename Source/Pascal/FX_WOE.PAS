(****************************************************************************
*  UNIT          : FX_WOE                                                   *
*  AUTHOR        : S. M. Wright                                             *
*  DATE          : 08/05/96                                                 *
*  PURPOSE       : FORMIX RECIPE ORDER EDIT                                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FX_WOE;
INTERFACE

USES CRT,STRINGS,F6STDCTV,F6STDWN1,F6STDWIN,F6STDUTL,F6STDUT1,F6STDBRW,
     F6SCREEN,FX_Edit,FXFSerNo,
     F6DTCONV,F6RECCHG,FXMODCTV,FXCFG,FXFORDER,FXFWORK,FXFINGR,FXBRW_IN,FXFMenu;

PROCEDURE Edit_Order(OrdDate,OrdNumber : LONGINT;RevisionNo : BYTE);

IMPLEMENTATION
USES FXBRW_RP,FXFRCP,FXFMIX;

CONST WIN_X            = 1;           { WINDOW X Offset       (Global )     }
      WIN_Y            = 1;           { WINDOW Y Offset       (Global )     }
      WIN_WID          = 79;          { WINDOW Width          (Global )     }
      WIN_DEP          = 24;          { WINDOW Depth          (Global )     }

CONST EWIN_X           = 2;           { ITEM EDIT WINDOW X Offset (Global ) }
      EWIN_Y           = WIN_Y+6;     { ITEM EDIT WINDOW Y Offset (Global ) }
      EWIN_WID         = 76;          { ITEM EDIT WINDOW Width    (Global ) }
      EWIN_DEP         = 17;          { ITEM EDIT WINDOW Depth    (Global ) }

      LIST_X           = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH       = WIN_WID-4;   { LIST BOX WIDTH        (Global )     }
      LIST_Y           = WIN_Y+14;    { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH       = 08;          { LIST BOX DEPTH        (Global )     }

      BLANK_ORDLINE    = ' ---- ---------- --- -------  ---------  ----  ----  ---------  ---------';


      ORDERNO_F        =  1;
      RECIPE_F         =  2;
      SCHDATE_F        =  3;
      RELEASE_F        =  4;
      NUMCASES_F       =  5;
      CASEWT_F         =  6;
      TARGETW_F        =  7;
      MIXB_WT_F        =  8;
(*
      STATHLD_F        =  9;
      STATWIP_F        = 10;
      STATCMP_F        = 11;
*)
      STAT_F           =  9;
      WORKGRP_F        = 10;
      FIX_SEQ_F        = 11;
      MIX_TYPE_F       = 12;
      MIXESREQ         = 13;
      MIXESDONE        = 14;
      GROSSWT          = 15;
      LOSSWT           = 16;
      FIRSTFIELD       = ORDERNO_F;           { Start Field ID                      }
      LASTFIELD        = LOSSWT;              { Last Field ID          }
      LISTBOX          = 17;

      CSTM_A1_F        = 17;
      CSTM_N1_F        = 18;
      RELEASE2_F       = 19;
      CSTM_A2_F        = 20;
      PAGE2FIRSTFLD    = CSTM_A1_F;
      PAGE2LASTFLD     = CSTM_A2_F;

TYPE

     POrderEdit = ^TOrderEdit;
     TOrderEdit = object(TCombinedRecordEdit)
      FirstFldOnCurrPage,
      LastFldOnCurrPage     : INTEGER;
      OrderRec              : PWOrderObject;
      IngredientRec         : TIngredient_Record;
      OrderDate,
      AutoOrderNo,
      OrderNumber           : LONGINT;
      RecipeToCopyFrom      : TRecipeRef;
      RevisionNo            : BYTE;


      CONSTRUCTOR Init(OrdDate,OrderNo : LONGINT;Revision : BYTE);
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   ChangePage(PageNo : BYTE);
      PROCEDURE   Setup; Virtual;
      PROCEDURE   FillListPosWithRec (Element   : BYTE); Virtual;
      PROCEDURE   DisplayListItem    (Element   : BYTE); Virtual;
      PROCEDURE   DeleteListItem     (Element   : BYTE); Virtual;
      PROCEDURE   MoveItemUpList     (Element : BYTE); Virtual;
      PROCEDURE   MoveItemDownList   (Element : BYTE); Virtual;
      PROCEDURE   SetItemAsKeyIngredient(Element : BYTE);
      PROCEDURE   GetBrowseEvent; Virtual;
      PROCEDURE   ResetOrderEditor;
      PROCEDURE   Input_Value(Field_Str : STRING; Field : INTEGER);
      PROCEDURE   DisplayField(Field : INTEGER); VIRTUAL;
      PROCEDURE   DisplayFields; VIRTUAL;
      PROCEDURE   DisplayHeaderFields;
      PROCEDURE   DisplayExtraHeaderDetail;
      PROCEDURE   EditField(Field : LONGINT);
      PROCEDURE   InsertListItem; Virtual;
      PROCEDURE   EnquireCopyFromRecipe;
      PROCEDURE   CopyRecipeToOrder;
      FUNCTION    ReadRecordFunc(Operation : STRING) : INTEGER; Virtual;
      FUNCTION    EventHandled : BOOLEAN; Virtual;
      FUNCTION    Output_Value(Field : INTEGER) : STRING;
      FUNCTION    InsertRecordLineAt(Element : BYTE) : BOOLEAN; Virtual;
      FUNCTION    AddOrdLine : LONGINT; Virtual;
      FUNCTION    EditLineRecord (Element   : BYTE;NewLine : BOOLEAN) : BOOLEAN; Virtual;
      FUNCTION    CheckValidityOfRecord : BOOLEAN;
      PROCEDURE   CheckLinesAreToleranced;
      PROCEDURE   RefreshListBox; VIRTUAL;
     END;

CONSTRUCTOR TOrderEdit.Init(OrdDate,OrderNo : LONGINT;Revision : BYTE);
BEGIN
 { Inherited Method Clears Screen List Array }
 INHERITED Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH,FIRSTFIELD,Page2LastFld,LISTBOX);

 Show_Btrv_Err(IngredientFile^.OpenFile);
 IF IngredientFile^.OpenErr <> 0 THEN Esc_Flag := TRUE;

 Show_Btrv_Err(WorkOrderFile^.OpenFile);
 IF WorkOrderFile^.OpenErr <> 0 THEN Esc_Flag := TRUE;

 OrderRec := NIL;
 NEW(OrderRec, Init);
 IF NOT Assigned(OrderRec) THEN
   Esc_Flag := TRUE;

 OrderDate        := OrdDate;
 OrderNumber      := OrderNo;
 AutoOrderNo      := 0;
 RevisionNo       := Revision;
 RecipeToCopyFrom := SPACE_STRING;
END;

DESTRUCTOR TOrderEdit.Done;
BEGIN
 IF Assigned(OrderRec) THEN
  BEGIN
   Dispose(OrderRec,Done);
  END;
 WorkOrderFile^.CloseFile;
 IngredientFile^.CloseFile;
 INHERITED Done;
END;

PROCEDURE TOrderEdit.CheckLinesAreToleranced; { database change added tol to lines }
BEGIN
 IF OrderRec^.AllLinesAreUntoleranced THEN
  BEGIN
   IF YesNoWin(' Apply default tolerances'+CRLF+
               ' to ingredients (Y/N)?') THEN
     OrderRec^.ApplyIngredTols;
  END;
END;

PROCEDURE TOrderEdit.ResetOrderEditor;
BEGIN
 OrderRec^.Done;                                 { Clear Order Lines        }
 OrderRec^.Init;                                 { Init Order Record        }
 ClearAllOfList;                                 { Clear List Screen Array  }
 ListIndex := 1;                                 { Reset HiliteBar Pos.     }
 NewRecord   := (OrderNumber = 0);               { Add Or Edit?             }
 IF NewRecord THEN
  BEGIN
   OrderRec^.WO_Header.WOH_SelectByCase := TRUE;
   First_Field := ORDERNO_F;                     { Set First Entry Field    }
   EditAllowed := TRUE;
  END
 ELSE
  BEGIN
   First_Field := SCHDATE_F;                     { Set First Entry Field    }

   OrderRec^.WO_Header.WOH_SchDate := OrderDate; { Prime Key Fields         }
   OrderRec^.WO_Header.WOH_OrderNo := OrderNumber;
   OrderRec^.WO_Header.WOH_Revision:= RevisionNo;
   IF WorkOrderFile^.ReadAllRecords('EQ',FALSE,FALSE,OrderRec,0) <> 0 THEN
    BEGIN
     Disp_Error_Msg('Order Record Not Found');   { Order Record Not Found   }
     Esc_Flag := TRUE;                           { Forced Exit              }
    END
   ELSE
    BEGIN
     IF CompareWts(OrderRec^.WO_Header.WOH_WtDoneGross, 0.0) > 0 THEN
      BEGIN
       EditAllowed := FALSE;
       First_Field := LISTBOX_F;
       BackColourScheme;
       Footer('F1 - Decrement '+COPY(Config_Rec^.Conf_UnitName+SPACE_STRING,1,7)+'  '+
              'F2 - Increment '+COPY(Config_Rec^.Conf_UnitName+SPACE_STRING,1,7)+'                            ',2);
       Footer('                        F10- Abandon Order Edit    ESC-Done               ',1);
       ForeColourScheme;
      END
     ELSE EditAllowed := TRUE;
    END;
  END;
 IF NOT Esc_Flag THEN
  BEGIN
   DisplayFields;                                { Update Screen Fields     }
   RefreshListBox;                               { Redraw Ingredient List   }
   FieldNo := First_Field;                       { Set Field Pointer        }
   CheckLinesAreToleranced;
  END;
END;

PROCEDURE TOrderEdit.Setup;                 { Called From TFileBrowser.Run }
BEGIN
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,FALSE,SW_DEFAULT,SW_DEFAULT,EditWindow);
 ChangePage(1);
 ForeColourScheme;
 EditWindowUp := TRUE;
 MenuCr :='xx';
 DisplayStaticTextAndFields('FXWOEDIT');
 ResetOrderEditor;
END;

PROCEDURE TOrderEdit.CopyRecipeToOrder;
BEGIN
 RecipeToOrder(OrderRec^.WO_Header,OrderRec^.WO_Lines,RecipeToCopyFrom);
 DisplayFields;
 RefreshListBox;
 RecipeToCopyFrom := SPACE_STRING;
END;

PROCEDURE TOrderEdit.EnquireCopyFromRecipe;
VAR RecipeNo : TRecipeRef;
BEGIN
 CursorOff;
 IF YesNoWin('       Copy Order From A'+CRLF+'        Set Recipe Y/N') THEN
  BEGIN
   BrowseRecipe(RecipeNo, FALSE{OkToSelectObsolete});
   IF NOT NowtButSpace(RecipeNo) THEN
    BEGIN
     RecipeToCopyFrom := RecipeNo;
    END;
  END;
 CursorOn;
END;

{***************************************************************************}
{********* ENTRY FIELD HANDLING METHODS                           **********}
{***************************************************************************}

PROCEDURE TOrderEdit.ChangePage(PageNo : BYTE);
BEGIN
 IF PageNo = 2 THEN
  BEGIN
   FirstFldOnCurrPage := Page2FirstFld;
   LastFldOnCurrPage  := Page2LastFld;
  END
 ELSE
  BEGIN
   FirstFldOnCurrPage := FIRSTFIELD;
   LastFldOnCurrPage  := LASTFIELD;
  END;
END;

{ INPUT VALUE PUT ENTERED FIELD INTO RECORD BUFFER                          }
PROCEDURE TOrderEdit.Input_Value(Field_Str : STRING; Field : INTEGER);
VAR TargetWt : DOUBLE;
    Dummy    : INTEGER;
    Number   : INTEGER;
    WORec    : TWoHeaderRecord;


BEGIN
 WITH OrderRec^.WO_Header DO
  BEGIN
   CASE Field OF
    ORDERNO_F : BEGIN
                 StrToOrderNo(Field_Str,WOH_OrderNo,WOH_Revision);
                 IF (WOH_OrderNo = 0) AND (WOH_Revision = 0) THEN
                  BEGIN
                   IF AutoOrderNo = 0 THEN
                     AutoOrderNo := WorkHeaderFile^.NextAvailableOrdNo;
                   WOH_OrderNo := AutoOrderNo;
                   DisplayField(Field);
                  END
                 ELSE IF  (AutoOrderNo > 0)
                      AND (WOH_OrderNo <> AutoOrderNo) THEN { not using given number }
                  BEGIN
                   ReturnOrderNo(AutoOrderNo);
                   AutoOrderNo := 0;
                  END;

                 FillChar(WORec,SizeOf(TWOHeaderREcord),#0);
                 WORec.WOH_OrderNo  := WOH_OrderNo;
                 WORec.WOH_Revision := WOH_Revision;
                 IF (WorkOrderFile^.HeaderFile^.ReadRecord('GE',FALSE,FALSE,WORec,1) = 0) AND
                    (WORec.WOH_OrderNo = WOH_OrderNo) THEN
                  BEGIN
                   Disp_Error_Msg('Order Number Already In Use. Enter A New Order Number');
                   WOH_OrderNo := 0;
                  END;
                 IF WOH_OrderNo = 0 THEN Ch1 := ' ';
                END;
    SCHDATE_F : BEGIN
      IF Valid_Date(Field_Str) THEN
       BEGIN
        WOH_SchDate := Date_To_Days(Field_Str);
       END
      ELSE
       BEGIN
        ch1 := ' ';
        Disp_Error_Msg('Invalid Schedule Date, Please Re-Enter');
       END;
    END;
    RELEASE_F,
    RELEASE2_F: WOH_Release := StringToLong(Field_Str);
    RECIPE_F  : WOH_RecipeNo   := Field_Str;
    NUMCASES_F: {IF WOH_SelectByCase THEN} BEGIN
                 VAL(Field_Str,WOH_NumCases,Dummy);
                 IF WOH_NumCases = 0 THEN
                  BEGIN
                 {  Disp_Error_Msg('Can Not Create Zero Cases');
                   ch1 := ' ';}
                   WOH_SelectByCase := FALSE;
                  END
                 ELSE
                  BEGIN
                   WOH_SelectByCase := TRUE;
                  END;
                END;
    CASEWT_F  : IF WOH_SelectByCase THEN BEGIN
                 WOH_CaseWt := StringToDouble(Field_Str);
                 IF WOH_CaseWt = 0.0 THEN
                  BEGIN
                   Disp_Error_Msg('Weight Of A Case Can Not Be Zero');
                   Ch1 :=' ';
                  END
                 ELSE
                  BEGIN
                   IF (OrderRec^.WO_Header.WOH_MaxMixGrossWt = 0.0) AND
                    NowtButSpace(RecipeToCopyFrom) THEN
                    OrderRec^.WO_Header.WOH_MaxMixGrossWt := OrderRec^.WO_Header.WOH_CaseWt;
                  END;
                END;
(*
    STATHLD_F : IF Field_Str[1] = RADIO_CHAR THEN WOH_Status := StatusHOLD;
    STATWIP_F : IF Field_Str[1] = RADIO_CHAR THEN WOH_Status := StatusWIP;
    STATCMP_F : IF Field_Str[1] = RADIO_CHAR THEN WOH_Status := StatusCOMP;
*)
    STAT_F    : BEGIN
                 VAL(Field_Str,Number,Dummy);
                 IF  (Number >= ORD(Low(TStatusType)))
                 AND (Number <= ORD(High(TStatusType))) THEN
                   WOH_Status := TStatusType(Number)
                 ELSE
                   WOH_Status := StatusHOLD;
                END;

    WORKGRP_F : WOH_WorkGroup := Field_Str;

    MIX_TYPE_F: BEGIN
                 VAL(Field_Str,Number,Dummy);
                 IF (Number >= ORD(Low(TMixType))) AND (Number <= ORD(High(TMixType))) THEN
                  WOH_MixType := TMixType(Number)
                 ELSE
                  WOH_MixType := mt_SingleContainerPerMix;
                END;
    FIX_SEQ_F : WOH_SeqFixed   := (Field_Str[1] = TICK_CHAR);
    TARGETW_F : BEGIN
                 IF NOT WOH_SelectByCase THEN
                  BEGIN
                   TargetWt   := StringToDouble(Field_Str);
                   IF TargetWt = 0.0 THEN
                    BEGIN
                     Disp_Error_Msg('Can Not Have A Target Wt Of 0.0kg');
                     ch1 := ' ';
                    END;
                   WOH_FinishWtReqd := TargetWt;
                  END;
                END;
    MIXB_WT_F : BEGIN
                 WOH_MaxMixGrossWt := StringToDouble(Field_Str);
                END;
    CSTM_N1_F : WOH_Custom_Num1   := StringToLong(Field_Str);
    CSTM_A1_F : WOH_Custom_Alpha1 := Field_Str;
    CSTM_A2_F : WOH_Custom_Alpha2 := Field_Str;
   END;
  END;
 OrderRec^.ResetCalculatedFields;
 IF Ch1 = ' ' THEN Esc_Flag := FALSE;
END;

{ OUTPUT VALUE, GET RECORD DATA INTO EDIT BUFFER }
FUNCTION TOrderEdit.Output_Value(Field : INTEGER) : STRING;
VAR FieldStr : STRING;
BEGIN
 FieldStr :='';
 WITH OrderRec^.WO_Header DO
  BEGIN
   CASE Field OF
    ORDERNO_F : FieldStr := OrderNoToStr(WOH_OrderNo,WOH_Revision);
    SCHDATE_F : FieldStr := Days_To_Date(WOH_SchDate);
    RECIPE_F  : FieldStr := WOH_RecipeNo;
    RELEASE_F,
    RELEASE2_F: FieldStr := IntToZeroStr(WOH_Release,LenOrd[Field]);
    NUMCASES_F: FieldStr := IntToZeroStr(WOH_NumCases,4);
    CASEWT_F  : FieldStr := DoubleToZeroStr(WOH_CaseWt,9,3);
(*
    STATHLD_F : IF WOH_Status  = StatusHOLD THEN FieldStr := RADIO_CHAR ELSE FieldStr := ' ';
    STATWIP_F : IF WOH_Status  = StatusWIP  THEN FieldStr := RADIO_CHAR ELSE FieldStr := ' ';
    STATCMP_F : IF WOH_Status  = StatusCOMP THEN FieldStr := RADIO_CHAR ELSE FieldStr := ' ';
*)
    STAT_F    : FieldStr := IntToStr(Ord(WOH_Status),1);
    WORKGRP_F : FieldStr := WOH_WorkGroup;
    MIX_TYPE_F: FieldStr := IntToStr(Ord(WOH_MixType),1);
    FIX_SEQ_F : IF WOH_SeqFixed THEN FieldStr := TICK_CHAR ELSE FieldStr :=' ';
    TARGETW_F : FieldStr := DoubleToZeroStr(WOH_FinishWtReqd,9,3);
    MIXB_WT_F : FieldStr := DoubleToZeroStr(WOH_MaxMixGrossWt,9,3);
    MIXESREQ  : FieldStr := IntToStr(WOH_NumMixes,3);
    MIXESDONE : FieldStr := IntToZeroStr(WOH_MixDone,3);
    GROSSWT   : FieldStr := DoubleToStr(WOH_TotIngredWtReqd,9,3);
    LOSSWT    : FieldStr := DoubleToStr(WOH_TotIngredWtReqd - WOH_FinishWtReqd,9,3);

    CSTM_N1_F : FieldStr := IntToStr(WOH_Custom_Num1, LenOrd[Field]);
    CSTM_A1_F : FieldStr := WOH_Custom_Alpha1;
    CSTM_A2_F : FieldStr := WOH_Custom_Alpha2;
   END;
 END;
 Output_Value := FieldStr;
END;


PROCEDURE TOrderEdit.DisplayHeaderFields;
VAR FNo : INTEGER;
    Int,Dummy : INTEGER;
BEGIN
 FOR FNo := FirstFldOnCurrPage TO LastFldOnCurrPage DO
  BEGIN
   CASE FNo OF { editable fields }
     ORDERNO_F,
     SCHDATE_F,
     RELEASE_F,
     RELEASE2_F,
     RECIPE_F,
     NUMCASES_F,
     CASEWT_F,
     WORKGRP_F,
     FIX_SEQ_F,
     TARGETW_F,
     MIXB_WT_F,
     CSTM_N1_F,
     CSTM_A1_F,
     CSTM_A2_F : BEGIN
       WriteField(XcoOrd[FNo],YcoOrd[FNo],Output_Value(FNo),TRUE);
     END;

     MIXESREQ,   { display fields }
     MIXESDONE,
     GROSSWT,
     LOSSWt  : BEGIN
       WriteField(XcoOrd[FNo],YcoOrd[FNo],Output_Value(FNo),FALSE);
     END;

(*
     STATHLD_F,  { tick boxes }
     STATWIP_F,
     STATCMP_F : WITH OrderRec^.WO_Header DO BEGIN
       WriteRadio(XcoOrd[STATHLD_F],YcoOrd[STATHLD_F],(WOH_Status = StatusHOLD));
       WriteRadio(XcoOrd[STATWIP_F],YcoOrd[STATWIP_F],(WOH_Status = StatusWIP));
       WriteRadio(XcoOrd[STATCMP_F],YcoOrd[STATCMP_F],(WOH_Status = StatusCOMP));
     END;
*)
     STAT_F  : BEGIN
       VAL(OutPut_Value(FNo),Int,Dummy);
       WriteField(XCoOrd[FNo],YCoOrd[FNo],
                  GetStatusType(TStatusType(Int)),TRUE);
       RevVideo;
       Write(#25);
       LowVideo;
     END;

     MIX_TYPE_F : BEGIN
       VAL(OutPut_Value(MIX_TYPE_F),Int,Dummy);
       WriteField(XCoOrd[MIX_TYPE_F],YCoOrd[MIX_TYPE_F],(MixTypeListItems[TMixType(Int)]),TRUE);
       RevVideo;
       Write(#25);
       LowVideo;
     END;
    END;
  END;
END;

PROCEDURE TOrderEdit.DisplayExtraHeaderDetail;
VAR ExtraWin : WindowRecord;
    Field    : INTEGER;
BEGIN
 WITH OrderRec^.WO_Header, Config_Rec^ DO
  BEGIN
   BackColourScheme;
   SetWindow(35,4,78,13,TRUE,SW_DEFAULT,SW_DEFAULT,ExtraWin);
   ChangePage(2);
   Header('Extra Details',1);

   { Field titles for this window not in TXT file }
   WriteAt(2,YCoOrd[CSTM_N1_F],Copy(CONF_OrdCustomNum1+Space_String, 1,20)+':');
   WriteAt(2,YCoOrd[CSTM_A1_F],Copy(CONF_OrdCustomAlpha1+Space_String, 1,20)+':');
   WriteAt(2,YCoOrd[CSTM_A2_F],Copy(CONF_OrdCustomAlpha2+Space_String, 1,20)+':');
   WriteAt(2,YCoOrd[RELEASE2_F],Copy('Release'+Space_String, 1,20)+':');

   Footer('ESC -Exit',1);
   ForeColourScheme;
   Field := FirstFldOnCurrPage;
   DisplayHeaderFields;
   REPEAT
     EditField(Field);
     DisplayHeaderFields;
     IF FuncKey THEN
      BEGIN
       CASE Ch1 OF
         PREV : BEGIN
                 Dec(Field);
                 IF Field < FirstFldOnCurrPage THEN
                   Field := LastFldOnCurrPage;
                END;
         NEXT : BEGIN
                 Inc(Field);
                 IF Field > LastFldOnCurrPage THEN
                   Field := FirstFldOnCurrPage;
                END;
        END;
      END;
   UNTIL Ch1 = ESC;
   LoseWindow(ExtraWin);
   ChangePage(1);
   DisplayHeaderFields;
  END;
END;

PROCEDURE TOrderEdit.DisplayFields;
BEGIN
 DisplayHeaderFields;
 RefreshlistBox;
END;


PROCEDURE TOrderEdit.DisplayField(Field : INTEGER);
{ display the lot - they're all related }
BEGIN
 DisplayHeaderFields;
 RefreshlistBox;
END;


PROCEDURE TOrderEdit.EditField(Field : LONGINT);
VAR WrkStr : STRING;
    dummy,Int : INTEGER;
BEGIN
 WrkStr := Output_Value(Field);
 CASE Field OF
   ORDERNO_F : GetLine_Num(WrkStr,LenOrd[Field],XcoOrd[Field],YcoOrd[Field],-3);

   SCHDATE_F : GetLine_Num(WrkStr,LenOrd[Field],XcoOrd[Field],YcoOrd[Field],-1);
   RECIPE_F,
   WORKGRP_F,
   CSTM_A1_F,
   CSTM_A2_F : GetLine(WrkStr,LenOrd[Field],XcoOrd[Field],YcoOrd[Field]);

   NUMCASES_F,
   RELEASE_F,
   RELEASE2_F,
   CSTM_N1_F : GetLine_Num(WrkStr,LenOrd[Field],XcoOrd[Field],YcoOrd[Field],0);

(*
   STATHLD_F,
   STATWIP_F,
   STATCMP_F : GetRadio(WrkStr,XcoOrd[Field],YcoOrd[Field]);
*)
   STAT_F : BEGIN
    VAL(WrkStr,Int,Dummy);
    WrkStr  := IntToStr(GetListBoxEntry(OrdStatStrings,ORD(High(TStatusType))+1,
                        Int+1,
                        XcoOrd[Field],YcoOrd[Field],FALSE)-1, 1);
   END;
   MIX_TYPE_F : BEGIN
    VAL(WrkStr,Int,Dummy);
    WrkStr  := IntToStr(GetListBoxEntry(MixtypeListItems,ORD(LastMixType)+1,Int+1,
                        XcoOrd[Field],YcoOrd[Field],FALSE)-1, 1);
   END;
   FIX_SEQ_F : GetTick(WrkStr,XcoOrd[Field],YcoOrd[Field]);

   CASEWT_F  : IF OrderRec^.WO_Header.WOH_SelectByCase THEN
                 GetFloat(XcoOrd[Field],YcoOrd[Field],WrkStr,LenOrd[Field],3);
   MIXB_WT_F : GetFloat(XcoOrd[Field],YcoOrd[Field],WrkStr,LenOrd[Field],3);

   TARGETW_F : IF NOT OrderRec^.WO_Header.WOH_SelectByCase THEN
                 GetFloat(XcoOrd[Field],YcoOrd[Field],WrkStr,LenOrd[Field],3);
 END;
 IF (ch1 <> FN_F10) THEN Input_Value(WrkStr,Field);
 IF ch1 = ESC THEN Esc_Flag := TRUE;
END;


FUNCTION TOrderEdit.ReadRecordFunc(Operation : STRING) : INTEGER;
VAR Result : INTEGER;

 PROCEDURE CheckAssigned(ErrorCode,NewCurrLine : INTEGER);
  BEGIN
   CurrLine := NewCurrLine;
   IF NOT Assigned(OrderRec^.WO_Lines[CurrLine]) THEN
     Result := ErrorCode;
  END;

BEGIN
 Result := 0;
 IF Operation = 'GF' THEN
  BEGIN
   CheckAssigned(BNoRecord,1);
  END
 ELSE IF Operation = 'GL' THEN
  BEGIN
   CheckAssigned(BNoRecord,MAX_LINES_ON_RECORD);
  END
 ELSE IF Operation = 'EQ' THEN
  BEGIN
   IF (CurrLine < 1) OR (CurrLine > MAX_LINES_ON_RECORD) THEN Result :=4;
   IF Result = 0 THEN CheckAssigned(BNORecord,CurrLine);
  END
 ELSE IF Operation = 'GE' THEN
  BEGIN
   IF (CurrLine < 1)  THEN CurrLine := 1
   ELSE IF CurrLine > MAX_LINES_ON_RECORD THEN Result :=9;
   IF Result = 0 THEN CheckAssigned(BEndOfFile,CurrLine);
  END
 ELSE IF (Operation = 'GT')  OR (Operation = 'GN') THEN
  BEGIN
   IF CurrLine < MAX_LINES_ON_RECORD THEN INC(CurrLine)
   ELSE Result := 9;
   IF Result=0 THEN CheckAssigned(BEndOfFile,CurrLine);
  END
 ELSE IF (Operation = 'LT') OR (Operation ='GP') THEN
  BEGIN
   IF CurrLine > 1 THEN DEC(CurrLine)
   ELSE Result := 9;  { Begining of File }
   IF Result = 0 THEN CheckAssigned(BEndOfFile,CurrLine);
  END
 ELSE IF Result = 0 THEN CheckAssigned(BEndOfFile,CurrLine);
 ReadRecordFunc :=Result;
END;

FUNCTION TOrderEdit.CheckValidityOfRecord : BOOLEAN;
VAR SeqFixed : BOOLEAN;
    I        : INTEGER;
    Percent  : DOUBLE;
BEGIN
 Esc_Flag := FALSE;
 CheckValidityOfRecord := FALSE;
(*
 IF OrderRec^.WO_Header.WOH_TargetGrossWt < OrderRec^.WO_Header.WOH_GrossWtDone THEN
  BEGIN
   Disp_Error_Msg('Target Wt Has Been Set To Less Than The Weight Done');
   IF NOT YesNoWin('        Save Anyway'+CRLF+
                   '      Are You Sure Y/N') THEN EXIT;
  END;
*)
 SeqFixed := OrderRec^.WO_Header.WOH_SeqFixed;
 Percent  := 0;
 FOR I:=1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF NOT Assigned(OrderRec^.WO_Lines[I]) THEN CONTINUE;
   WITH OrderRec^.WO_Lines[I]^ DO
    BEGIN
     IF (SeqFixed) AND (WOL_KeyIngredient) AND (I<>1) THEN
      BEGIN
       Disp_Error_Msg('Key Ingredient Must Be First Ingredient On A Sequence Fixed Order');
       EXIT;
      END;
     Percent := Percent + WOL_Ratio;
    END;
  END;
 IF LONGINT(ROUND(Percent*1000)) <> LONGINT(100*1000) THEN
  BEGIN
   Disp_Error_Msg('Ingredient Ratio Percentage Must Add to 100%');
   EXIT;
  END;
 CheckValidityOfRecord := TRUE;
 Esc_Flag := TRUE;
END;

PROCEDURE TOrderEdit.FillListPosWithRec(Element   : BYTE);
BEGIN
 IF Assigned(OrderRec^.WO_Lines[CurrLine]) THEN
  BEGIN
   BrowseList[Element].LineNo := OrderRec^.WO_Lines[CurrLine]^.WOL_LineNo;
  END
 ELSE
  BEGIN
   BrowseList[Element].LineNo := 0;
  END;
END;

PROCEDURE TOrderEdit.RefreshListBox;
VAR OrdLine : INTEGER;
BEGIN
 INHERITED RefreshListBox;
 WITH OrderRec^ DO
  BEGIN
   FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
    BEGIN
     IF Assigned(WO_Lines[OrdLine]) THEN
      BEGIN
       WO_Lines[OrdLine]^.WOL_OrderNo := WO_Header.WOH_OrderNo;
       WO_Lines[OrdLine]^.WOL_Revision:= WO_Header.WOH_Revision;
       TotalLineRatio := TotalLineRatio + WO_Lines[OrdLine]^.WOL_Ratio;
      END;
    END;
  END;
 WriteAt(2,LIST_Y+LIST_DEPTH,'Total Ratio :        '+DoubleToStr(TotalLineRatio,4,3)+'%');
END;

PROCEDURE TOrderEdit.DisplayListItem(Element   : BYTE);
VAR Line     : LONGINT;
    TempLong : LONGINT;
BEGIN
 IF (NOT ListPosIsEmpty(Element)) THEN
  BEGIN
   WITH OrderRec^.WO_Header,OrderRec^.WO_Lines[BrowseList[Element].LineNo]^ DO
    BEGIN
     Write(WOL_LineNo:5,' ',WOL_Ingredient,'   ');
     IF WOL_KeyIngredient THEN Write('Yes ') ELSE Write('    ');
     Write(WOL_Ratio:7:3,'  ');
     IF (WOH_MixType IN MixSet_ProportionallyMixedConts)
     AND (BrowseList[Element].LineNo<>1) THEN
      BEGIN
       Write('     "     ');
      END
     ELSE
      Write(WOL_ContainerSize:9:3,'  ');
     TempLong := EstimateLineWeighingsReqdForOrder(@OrderRec^.WO_Header,
                             OrderRec^.WO_Lines[BrowseList[Element].LineNo]);
     IF (TempLong > 0) AND (TempLong < 9999) THEN
       Write(TempLong:4,'  ')
     ELSE Write('####  ');
     Write(IntToStr(WOL_TotalContDone,4),'  ');
     Write(CalcLineGrossWtReqdFromRecipeNet(WOH_FinishWtReqd,
                                            WOL_Ratio,
                                            WOL_Yield):9:3,'  ');
     Write(WOL_TotalWtDone:9:3);
    END;
  END
 ELSE Write(BLANK_ORDLINE);
END;

PROCEDURE TOrderEdit.GetBrowseEvent;
VAR DispCol   : BYTE;
    FoundSite : BOOLEAN;
    SError    : INTEGER;
    FuncSave  : BOOLEAN;
    Ch1Save   : CHAR;

    PROCEDURE ShowCurrentLineDesc;
    BEGIN
     BackColourScheme;
     IF  (FieldNo = LISTBOX)
     AND (ListIndex > 0)
     AND NOT ListPosIsEmpty(ListIndex)
     AND (OrderRec^.WO_Lines[BrowseList[ListIndex].LineNo] <> NIL) THEN
       RevWriteAt(2,LIST_Y-2,
           COPY(GetIngredientDesc(OrderRec^.WO_Lines[BrowseList[ListIndex].LineNo]^.WOL_Ingredient),1,20))
     ELSE
       RevWriteAt(2,LIST_Y-2,COPY(SPACE_STRING,1,20));
     ForeColourScheme;
    END;

BEGIN
  ShowCurrentLineDesc;

  IF FieldNo =LISTBOX THEN
   BEGIN                                        { Use Inherited Method     }
    INHERITED GetBrowseEvent;                   { To Handle List Functions }
    ShowCurrentLineDesc;
   END
  ELSE
   BEGIN
    CursorOn;
    EditField(FieldNo);
    CursorOFF;
    IF (Ch1 <> ESC) AND (ch1 <> FN_F10) THEN
     BEGIN
      IF (FieldNo = ORDERNO_F) AND (OrderRec^.WO_Header.WOH_OrderNo <> 0) THEN
       BEGIN
        Ch1Save  := Ch1;              {Save varibles as they are needed elsewhere}
        FuncSave := FuncKey;
        EnquireCopyFromRecipe;        {Get a recipe name maybe}
        First_Field := SCHDATE_F;     {can no longer edit order no}
        IF NOT NowtButSpace(RecipeToCopyFrom) THEN
         BEGIN
          FieldNo := NUMCASES_F-1;  {next field to edit must be the target wt}
          CopyRecipeToOrder;
          CheckLinesAreToleranced;
         END;
        Ch1     := Ch1Save;
        FuncKey := FuncSave;
       END
{      ELSE
       IF (FieldNo = TARGETW_F) AND (Not NowtButSpace(RecipeToCopyFrom)) AND
        (OrderRec^.WO_Header.WOH_TotFinishWtReqd <> 0.0) THEN}

     END;
    DisplayField(FieldNo);
   END;                                          { END (Not OnListBox)      }
END;

{ Eventhandled Method is used to handle events that are additional to those }
{ Handled By Standard Browse ie. INSERT,DELETE Etc.                         }
FUNCTION TOrderEdit.EventHandled : BOOLEAN;
VAR ErrInt        : INTEGER;
    TempHeaderRec : TWOHeaderRecord;
    HandledEvent  : BOOLEAN;
BEGIN
 HandledEvent := FALSE;
 IF Funckey THEN
  BEGIN
   CASE ch1 OF

    FN_F1  : BEGIN
     {Remove a mix from the order if possible }
     IF (NOT EditAllowed) AND (OrderRec^.WO_Header.WOH_NumCases > 0) THEN
      BEGIN
       IF GetMixWtDone(OrderRec^.WO_Header.WOH_NumCases,
                       @OrderRec^.WO_Header) > 0.0 THEN
        BEGIN

        END
       ELSE
        BEGIN
         DEC(OrderRec^.WO_Header.WOH_NumCases);
         OrderRec^.ResetCalculatedFields;
         DisplayHeaderFields;
         HandledEvent := TRUE;
        END;
      END;
    END;

    FN_F2  : BEGIN
     {Add a mix to the order }
     IF (NOT EditAllowed) AND (OrderRec^.WO_Header.WOH_NumCases < 9999) THEN
      BEGIN
       INC(OrderRec^.WO_Header.WOH_NumCases);
       OrderRec^.ResetCalculatedFields;
       DisplayHeaderFields;
       HandledEvent := TRUE;
      END;
    END;




    FN_F3  : IF FieldNo =LISTBOX THEN
     BEGIN                               { Set As Key Ingredient    }
      SetItemAsKeyIngredient(ListIndex);
      RefreshListBox;
      HandledEvent := TRUE;
     END;

    FN_F7 : BEGIN
      DisplayExtraHeaderDetail;
      Esc_Flag := FALSE; { set by esc key - needs clearing for browser }
      HandledEvent := TRUE;
    END;

    FN_F10 : BEGIN
      IF YesNoWin('Abandon All Order Changes (Y/N)?') THEN
       BEGIN
        Esc_Flag := TRUE;
        IF  NewRecord
        AND (OrderRec^.WO_Header.WOH_OrderNo = AutoOrderNo) THEN
          ReturnOrderNo(OrderRec^.WO_Header.WOH_OrderNo);
       END;
      HandledEvent := TRUE;
    END;

   END;                                          { END (CASE Ch1 OF)        }
  END
 ELSE
  BEGIN
   CASE ch1 OF
    ESC : BEGIN                                  { ESC KEY PRESSED          }
      IF (OrderRec^.WO_Header.WOH_OrderNo <> 0) AND CheckValidityOfRecord THEN
       BEGIN                                     { IF RECORD TO SAVE        }
        (* RECORD ADD/UPDATE CODE GOES HERE *)
        IF NOT NewRecord THEN
         BEGIN
          TempHeaderRec.WOH_SchDate := OrderDate;
          TempHeaderRec.WOH_OrderNo := OrderNumber;
          TempHeaderRec.WOH_Revision:= RevisionNo;
          WorkOrderFile^.HeaderFile^.ReadRecord('EQ',TRUE,FALSE,TempHeaderRec,0);
          CASE WorkOrderFile^.HeaderFile^.BtrvErr OF
           0 : BEGIN
            IF TempHeaderRec.WOH_UpdateCount <> OrderRec^.WO_Header.WOH_UpdateCount THEN
             BEGIN
              WorkOrderFile^.HeaderFile^.Unlock_Single; { Unlock Order Record      }
              Rec_Changed_Error(FALSE);        { Display Rec Changed        }
              Esc_Flag := FALSE; { Cycle To Next Event - flag used by ResetOrderEditor }
              ResetOrderEditor;                { Re-Read Order Record       }
             END
            ELSE
             BEGIN
              WorkOrderFile^.UpdateRecord(OrderRec);  { Update Records To Files    }
             END;
           END;

           BNoRecord : BEGIN        { Record Deleted By Another Workstation }
            IF Upcase(Rec_Changed_Error(TRUE)) = 'Y' THEN
             BEGIN
              Show_Btrv_Err(WorkOrderFile^.AddRecord(OrderRec));
             END;
           END;

           ELSE Show_Btrv_Err(WorkOrderFile^.HeaderFile^.BtrvErr);
          END;
         END  { END (NOT NewRecord) }
        ELSE
         BEGIN                                       { NEW RECORD TO ADD }
          WorkOrderFile^.AddRecord(OrderRec);
          IF WorkOrderFile^.BtrvErr = BDuplicate THEN
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

PROCEDURE TOrderEdit.SetItemAsKeyIngredient(Element : BYTE);
VAR EditLine : LONGINT;
    LPA      : LONGINT;
BEGIN
 IF (NOT ListPosIsEmpty(ListIndex) AND EditAllowed) THEN
  BEGIN
   EditLine := BrowseList[ListIndex].LineNo;
   IF OrderRec^.WO_Lines[EditLine]^.WOL_KeyIngredient THEN
    BEGIN
     OrderRec^.WO_Lines[EditLine]^.WOL_KeyIngredient := FALSE;
     EXIT;
    END;
   IF  (OrderRec^.WO_Lines[EditLine]<>NIL)
   AND (OrderRec^.WO_Lines[EditLine]^.WOL_ProcessType = PTStep) THEN
    BEGIN
     Disp_Error_Msg('Key Ingredient Can Not Be A Step Ingredient');
     EXIT;
    END;
   FOR LPA := 1 TO MAX_LINES_ON_RECORD DO
    BEGIN
     IF (OrderRec^.WO_Lines[LPA] <> NIL) AND
       (OrderRec^.WO_Lines[LPA]^.WOL_KeyIngredient) THEN
      BEGIN;
       OrderRec^.WO_Lines[LPA]^.WOL_KeyIngredient := FALSE;
       BREAK;
      END;
    END;
   OrderRec^.WO_Lines[EditLine]^.WOL_KeyIngredient := TRUE;
  END;
END;


FUNCTION TOrderEdit.InsertRecordLineAt(Element : BYTE) : BOOLEAN;
VAR LPA        : INTEGER;
    LineNumber : LONGINT;
BEGIN
 InsertRecordLineAt := FALSE;
 IF ListPosIsEmpty(Element) OR (NOT EditAllowed) THEN Exit;
 LineNumber := BrowseList[Element].LineNo;

 IF (NOT Assigned(OrderRec^.WO_Lines[MAX_LINES_ON_RECORD])) THEN
  BEGIN
   FOR LPA := MAX_LINES_ON_RECORD-1 DOWNTO LineNumber DO
    BEGIN
     IF OrderRec^.WO_Lines[LPA] <> NIL THEN
      BEGIN
       OrderRec^.WO_Lines[LPA+1]   := OrderRec^.WO_Lines[LPA];
       OrderRec^.WO_Lines[LPA+1]^.WOL_LineNo := LPA+1;
       OrderRec^.WO_LinePos[LPA+1] := OrderRec^.WO_LinePos[LPA];
      END;
    END;
   OrderRec^.WO_Lines[LineNumber]     := NIL;
   OrderRec^.WO_LinePos[LineNumber]   := 0;
   NEW(OrderRec^.WO_Lines[LineNumber]);
   IF Assigned(OrderRec^.WO_Lines[LineNumber]) THEN
    BEGIN
     WorkOrderFile^.LineFile^.InitRecord(OrderRec^.WO_Lines[LineNumber]^);
     OrderRec^.WO_Lines[LineNumber]^.WOL_OrderNo := OrderRec^.WO_Header.WOH_OrderNo;
     OrderRec^.WO_Lines[LineNumber]^.WOL_Revision:= OrderRec^.WO_Header.WOH_Revision;
     OrderRec^.WO_Lines[LineNumber]^.WOL_LineNo  := LineNumber;
     InsertRecordLineAt := TRUE;
    END;
  END;
END;

FUNCTION TOrderEdit.AddOrdLine : LONGINT;
VAR LPA : LONGINT;
BEGIN
 AddOrdLine := 0;
 FOR LPA := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF (NOT Assigned(OrderRec^.WO_Lines[LPA])) THEN
    BEGIN
     NEW(OrderRec^.WO_Lines[LPA]);
     WorkOrderFile^.LineFile^.InitRecord(OrderRec^.WO_Lines[LPA]^);
     OrderRec^.WO_Lines[LPA]^.WOL_OrderNo := OrderRec^.WO_Header.WOH_OrderNo;
     OrderRec^.WO_Lines[LPA]^.WOL_Revision:= OrderRec^.WO_Header.WOH_Revision;
     OrderRec^.WO_Lines[LPA]^.WOL_LineNo := LPA;
     AddOrdLine := LPA;
     Break;
    END;
  END;
END;

PROCEDURE TOrderEdit.InsertListItem;
VAR EditLine : LONGINT;
BEGIN
 IF (FieldNo <> LISTBOX) OR (NOT EditAllowed) THEN EXIT;
 EditLine := AddOrdLine;
 IF (EditLine > 0) THEN
  BEGIN
   IF (NOT EditLineRecord(EditLine,TRUE)) THEN WorkOrderFile^.DeleteLineRec(OrderRec,EditLine);
   RefreshListBox;
  END;
END;

PROCEDURE TOrderEdit.MoveItemUpList(Element : BYTE);
VAR CurrOrdLine : LONGINT;
    TempOrdLine : PWOLineRecord;
    TempLinePos : LONGINT;
BEGIN
 IF ListPosIsEmpty(Element) OR (NOT EditAllowed) THEN EXIT;
 CurrOrdLine := BrowseList[Element].LineNo;
 IF CurrOrdLine > 1 THEN
  BEGIN
   WITH OrderRec^ DO
    BEGIN
     SwapRecords(Pointer(WO_Lines[CurrOrdLine-1]),Pointer(WO_Lines[CurrOrdLine]));
     WO_Lines[CurrOrdLine-1]^.WOL_LineNo := CurrOrdLine-1;
     WO_Lines[CurrOrdLine]^.WOL_LineNo := CurrOrdLine;
     SwapPositions(WO_LinePos[CurrOrdLine-1],WO_LinePos[CurrOrdLine]);
    END;
   IF ListIndex > 1 THEN
    BEGIN
     DEC(ListIndex);
    END
   ELSE
    BEGIN
     ListIndex := 1;
     BrowseList[1].LineNo := CurrOrdLine-1;
    END;
   RefreshListBox;
  END;
END;

PROCEDURE TOrderEdit.MoveItemDownList(Element : BYTE);
VAR CurrOrdLine    : LONGINT;
BEGIN
 IF ListPosIsEmpty(Element) OR (NOT EditAllowed) THEN EXIT;
 CurrOrdLine := BrowseList[Element].LineNo;
 IF Assigned(OrderRec^.WO_Lines[CurrOrdLine+1]) THEN
  BEGIN
   WITH OrderRec^ DO
    BEGIN
     SwapRecords(Pointer(WO_Lines[CurrOrdLine]),Pointer(WO_Lines[CurrOrdLine+1]));
     WO_Lines[CurrOrdLine]^.WOL_LineNo   := CurrOrdLine;
     WO_Lines[CurrOrdLine+1]^.WOL_LineNo := CurrOrdLine+1;
     SwapPositions(WO_LinePos[CurrOrdLine],WO_LinePos[CurrOrdLine+1]);
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

PROCEDURE TOrderEdit.DeleteListItem(Element : BYTE);
BEGIN
 IF (NOT EditAllowed) THEN EXIT;
 IF OrderRec^.WO_Lines[BrowseList[Element].LineNo]^.WOL_TotalWtDone = 0.0 THEN
  BEGIN
   IF NowtButSpace(OrderRec^.WO_Lines[Element]^.WOL_Ingredient) OR
    YesNoWin('       Delete Record '+OrderRec^.WO_Lines[Element]^.WOL_Ingredient+CRLF+
               '          Are You Sure Y/N') THEN
    BEGIN
     WorkOrderFile^.DeleteLineRec(OrderRec,BrowseList[Element].LineNo);
     RefreshListBox;
    END;
  END
END;

FUNCTION TOrderEdit.EditLineRecord(Element   : BYTE;NewLine : BOOLEAN) : BOOLEAN;
{ Field Constants }
CONST INGRED_F  =  1; { Ingredient Code                }
      MIXRAT_F  =  2; { Mix Ratio                      }
      YIELD_F   =  3;
      CONTSZ_F  =  4; { Container Size                 }
      PROC_F    =  5;
      FIXED_F   =  6;
      CONTRQ_F  =  7; { Containers Req  (Display Only) }
      CONTDN_F  =  8; { Containers Done (Display Only) }
      WT_REQ_F  =  9; { Weight Required                }
      WTDONE_F  = 10; { Weight Done     (Display Only) }
      LOSSWT_F  = 11;
      LOWTOL_F  = 12; {Low  Tolerance}
      HIGHTOL_F = 13; {High Tolerance}
      INSTR1_F  = 14; { Special Instructions 1         }
      INSTR2_F  = 15; { Special Instructions 2         }
      KEYING_F  = 16; { Key Ingredient                 }

      FIRSTL_F  = INGRED_F;
      LASTL_F   = KEYING_F;

VAR   FirstLineField : BYTE;
      LField         : BYTE;
      OrderLine      : LONGINT;
      EOrderLine     : TWOLineRecord;
      IngredientProcessType : TProcessTypes;

 PROCEDURE DrawEditWindow;
 BEGIN
  BackColourScheme;
  SetWindow(EWIN_X,EWIN_Y,EWIN_X+EWIN_WID,EWIN_Y+EWIN_DEP,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,ItemWindow);
  IF NOT LoadMenu('FXWOIED',TRUE) THEN
   BEGIN
    Disp_Error_Msg('Menu File Not Found FXWOIED.TXT');
    Esc_Flag := TRUE;                        { Exit                         }
   END;
  ForeColourScheme;
 END;

 PROCEDURE RemoveEditWindow;
 BEGIN
  LoseWindow(ItemWindow);
  DisplayStaticTextAndFields('FXWOEDIT');   { Reload Order Editor Fields   }
 END;

 FUNCTION LineFieldValue(Field : BYTE) : STRING;
 VAR Field_Str : STRING;
     TempLong  : LONGINT;
 BEGIN
  Field_Str := '';
  WITH OrderRec^.WO_Header,EOrderLine DO
   BEGIN
    CASE Field OF
     INGRED_F : BEGIN
      Field_Str := WOL_Ingredient;
      WriteAt(36,3,GetIngredientDesc(WOL_Ingredient));
     END;
     KEYING_F : IF WOL_KeyIngredient THEN Field_Str := TICK_CHAR ELSE Field_Str :=' ';
     MIXRAT_F : Field_Str := DoubleToZeroStr(WOL_Ratio,LenOrd[MIXRAT_F],3);
     CONTSZ_F : Field_Str := DoubleToZeroStr(WOL_ContainerSize,LenOrd[CONTSZ_F],3);
     PROC_F   : Field_Str := IntToStr(Ord(WOL_ProcessType)+1,1);
     FIXED_F  : Field_Str := DoubleToZeroStr(WOL_FixedWt,9,3);
     WT_REQ_F : Field_Str := DoubleToZeroStr(
                             CalcLineGrossWtReqdFromRecipeNet(WOH_FinishWtReqd,
                                                              WOL_Ratio,
                                                              WOL_Yield),
                                             LenOrd[WT_REQ_F],3);
     CONTRQ_F : BEGIN
       TempLong := EstimateLineWeighingsReqdForOrder(@OrderRec^.WO_Header,
                                                     @EOrderLine);
       IF TempLong < 10000 THEN
         Field_Str := IntToStr(TempLong,LenOrd[CONTRQ_F])
       ELSE Field_Str :='####';
     END;
     CONTDN_F : Field_Str := IntToStr(WOL_TotalContDone,LenOrd[CONTDN_F]);
     WTDONE_F : Field_Str := DoubleToZeroStr(WOL_TotalWtDone,LenOrd[WTDONE_F],3);
     LOSSWT_F : Field_Str := DoubleToZeroStr(CalcLineLossWt(WOH_FinishWtReqd,WOL_Ratio,WOL_Yield),
                                             LenOrd[LOSSWT_F],3);
     INSTR1_F : Field_Str := WOL_SpecialInstr[1];
     INSTR2_F : Field_Str := WOL_SpecialInstr[2];
     YIELD_F  : Field_Str := DoubleToZeroStr(WOL_Yield,7,3);
     HIGHTOL_F: Field_Str := DoubleToZeroStr(WOL_HighTol,6,3);
     LOWTOL_F : Field_Str := DoubleToZeroStr(WOL_LowTol,6,3);

    END;
   END;
  LineFieldValue := Field_Str;
 END;

 PROCEDURE DisplayLineField(Field_Str : STRING;Field : BYTE);
 VAR Int,Dummy : INTEGER;
 BEGIN
  IF Field IN [INGRED_F,MIXRAT_F,INSTR1_F,INSTR2_F,YIELD_F,FIXED_F,HIGHTOL_F,LOWTOL_F] THEN
   WriteField(XcoOrd[Field],YcoOrd[Field],Field_Str,TRUE)
  ELSE IF Field = CONTSZ_F THEN
   BEGIN
     WriteField(XcoOrd[Field],YcoOrd[Field],Field_Str,TRUE);
   END
  ELSE IF (Field = PROC_F) THEN
   BEGIN
    VAL(LineFieldValue(PROC_F),Int,Dummy);
    WriteField(XCoOrd[PROC_F],YCoOrd[PROC_F],(GetProcessTypeName(TProcessTypes(Int-1))),TRUE);
    RevVideo;
    Write(#25);
    LowVideo;
   END
  ELSE WriteField(XcoOrd[Field],YcoOrd[Field],Field_Str,FALSE);
 END;

 PROCEDURE DisplayLineFields;
 VAR LPA : INTEGER;
 BEGIN
  CursorOFF;
  FOR LPA := 1 TO LASTL_F DO DisplayLineField(LineFieldValue(LPA),LPA);
  CursorON;
 END;

 PROCEDURE InputLineField(Field_Str : STRING; Field : BYTE);
 VAR LPA,Number,Dummy : INTEGER;
 BEGIN
  WITH EOrderLine DO
   BEGIN
    CASE Field OF
     INGRED_F : BEGIN
       IF NOT Str_Equal(Field_Str, WOL_Ingredient,
                        SizeOf(WOL_Ingredient)-1) THEN { new ingred code }
        BEGIN
         IngredientFile^.GetIngredient(Field_Str,IngredientRec,FALSE);
         PrimeWOLineForIngredient(EOrderLine, IngredientRec);
         FOR LPA := 2 TO LASTL_F DO
           DisplayLineField(LineFieldValue(LPA),LPA);
        END;
     END;
     KEYING_F : WOL_KeyIngredient := (Field_Str[1] = TICK_CHAR);
     MIXRAT_F : BEGIN
      WOL_Ratio                   := StringToDouble(Field_Str);
     END;

     INSTR1_F : WOL_SpecialInstr[1] := Field_Str;
     INSTR2_F : WOL_SpecialInstr[2] := Field_Str;

     CONTSZ_F : BEGIN
       WOL_ContainerSize := StringToDouble(Field_Str);
     END;
     PROC_F : BEGIN
      VAL(Field_Str,Number,Dummy);
      Dec(Number);
      IF (Number >= ORD(Low(TProcessTypes))) AND (Number <= ORD(High(TProcessTypes))) THEN
       WOL_ProcessType := TProcessTypes(Number)
      ELSE
       WOL_ProcessType := PTWeight;
     END;
     FIXED_F : WOL_FixedWt := StringToDouble(Field_Str);
     YIELD_F : BEGIN
       WOL_Yield := StringToDouble(Field_Str);
     END;

     HIGHTOL_F : BEGIN
       WOL_HighTol := StringToDouble(Field_Str);
     END;

     LOWTOL_F : BEGIN
       WOL_LowTol := StringToDouble(Field_Str);
     END;
    END;
   END;
 END;

 PROCEDURE EditOrdLineField(Field : LONGINT);
 VAR WrkStr     : STRING[50];
     Int,Dummy  : INTEGER;
     Containers : LONGINT;
 BEGIN
  FuncKey := TRUE;

  WrkStr := LineFieldValue(Field);
  CASE Field OF
   INGRED_F  : BEGIN                                        {Ingredient Code}
     GetLine(WrkStr,LenOrd[Field],XcoOrd[Field],YcoOrd[Field]);
     IF (Ch1 <> FN_F10) THEN
      BEGIN
       IF (IngredientFile^.GetIngredient(WrkStr,IngredientRec,FALSE) = BNoRecord)
       OR (Ch1 = FN_F1) THEN
        BEGIN
         IngredientLookup(@IngredientRec);
         WrkStr := IngredientRec.ING_Ingredient;
        END;
      END;
   END;
   INSTR1_F,
   INSTR2_F  : BEGIN
     GetLine(WrkStr,LenOrd[Field],XcoOrd[Field],YcoOrd[Field]);
   END;
   MIXRAT_F : IF (IngredientProcessType <> PTStep) THEN    {Mix Ratio      }
     GetFloat(XcoOrd[Field],YcoOrd[Field],WrkStr,LenOrd[Field],3);

   YIELD_F  : BEGIN                                        {Container Size }
     GetFloat(XcoOrd[Field],YcoOrd[Field],WrkStr,LenOrd[Field],3);
   END;
   CONTSZ_F  : IF  (IngredientProcessType <> PTStep)
               AND (OrderRec^.WO_Header.WOH_MixType <> mt_SingleContainerPerMix) THEN
     GetFloat(XcoOrd[Field],YcoOrd[Field],WrkStr,LenOrd[Field],3);
   PROC_F : BEGIN
     VAL(WrkStr,Int,Dummy);
     WrkStr  := IntToStr(GetListBoxEntry(TProcessTypeNames,NumProcessTypeNames,Int,XcoOrd[Field],YcoOrd[Field],FALSE),1);
   END;

   FIXED_F : IF (EOrderLine.WOL_ProcessType = PTCount) THEN
   BEGIN
      GetFloat(XcoOrd[Field],YcoOrd[Field],WrkStr,LenOrd[Field],3);
   END;

   LOWTOL_F,
   HIGHTOL_F : IF (IngredientProcessType <> PTStep) THEN
      GetFloat(XcoOrd[Field],YcoOrd[Field],WrkStr,LenOrd[Field],3);
  END;
  IF (ch1 <> FN_F10) THEN InputLineField(WrkStr,Field);
 END;

 PROCEDURE  HandleLineEntryEvent;
 BEGIN
  IF FuncKey THEN
   BEGIN
    CASE ch1 OF
     PREV : IF LField > FirstLineField THEN DEC(LField) ELSE LField := LASTL_F;
     NEXT : IF LField < LASTL_F THEN INC(LField) ELSE LField := FirstLineField;
     FN_F10 :IF YesNoWin('Abandon Order Line Edit (Y/N)?') THEN Esc_Flag := TRUE;
    END;
   END
  ELSE
   BEGIN
    CASE ch1 OF
     ESC: BEGIN
      (* SAVE CHANGES *)
      IF NOT NowtButSpace(EOrderLine.WOL_Ingredient) THEN
       BEGIN
        EditLineRecord := TRUE;
        OrderRec^.WO_Lines[Element]^ := EOrderLine;
       END;
      Esc_Flag := TRUE;
     END;
    END;
   END;
 END;

 PROCEDURE SetStepIngredientFields;
 BEGIN
  WITH EOrderLine DO
   BEGIN
    WOL_Ratio         := 0.0;
    WOL_ContainerSize := 0.0;
   END;
 END;

BEGIN
  EditLineRecord := FALSE;
  DrawEditWindow;
  EOrderLine := OrderRec^.WO_Lines[Element]^;           { Copy Order Line }

  IF NewLine THEN FirstLineField :=FIRSTL_F ELSE FirstLineField := MIXRAT_F;
  IngredientProcessType := EOrderLine.WOL_ProcessType;
  IF IngredientProcessType = PTStep THEN
   BEGIN
    SetStepIngredientFields;
   END;
  DisplayLineFields;
  {IF EditAllowed THEN
   BEGIN
  }
    ch1    := NEXT;
    FuncKey:= TRUE;
    LField := FirstLineField;
    REPEAT
     IF EditAllowed
     OR (LField IN [INSTR1_F,INSTR2_F,LOWTOL_F,HIGHTOL_F]) THEN
       EditOrdLineField(LField);
     DisplayLineFields;
     HandleLineEntryEvent;
    UNTIL Esc_Flag;
    RemoveEditWindow;
    Esc_Flag := FALSE;
    Ch1 :=' ';
    TotalLineRatio := 0;
    OrderRec^.ResetCalculatedFields;
    DisplayFields;
  { END;
  ELSE
   BEGIN
    CursorOff;
    REPEAT
    UNTIL GetKey = ESC;
    RemoveEditWindow;
    CursorOn;
    EditLineRecord := FALSE;
   END;
  }
END;


PROCEDURE Edit_Order(OrdDate,OrdNumber : LONGINT;RevisionNo : BYTE);
VAR OrderEditor : POrderEdit;
    WorkOrderFileAlloc : BOOLEAN;
BEGIN
 WorkOrderFileAlloc := Assigned(WorkOrderFile);
 IF NOT WorkOrderFileAlloc THEN
  BEGIN
   NEW(WorkOrderFile,Init(Config_Rec^.Conf_FPath+WOHeader_File_Name,
                   Config_Rec^.Conf_FPath+WOLine_File_Name));
  END;
 NEW(OrderEditor,Init(OrdDate,OrdNumber,RevisionNo));
 OrderEditor^.Run;
 DISPOSE(OrderEditor,Done);
 IF NOT WorkOrderFileAlloc THEN
  BEGIN
   DISPOSE(WorkOrderFile,Done);
   WorkOrderFile := NIL;
  END;
END;

END.

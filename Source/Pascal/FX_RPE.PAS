(****************************************************************************
*  UNIT          : FX_RPE                                                   *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 08/05/96                                                 *
*  PURPOSE       : FORMIX RECIPE EDIT                                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FX_RPE;
INTERFACE

USES CRT,STRINGS,F6STDCTV,F6STDWN1,F6STDWIN,F6STDUTL,F6STDUT1,F6STDBRW,F6SCREEN,FX_EDIT,
     F6DTCONV,F6RECCHG,FXMODCTV,FXCFG,{FXFORDER,}FXFRCP,FXFCRCP,FXFINGR,FXBRW_IN,{FX_RLU,}
     FXFWork,FXFMenu;

PROCEDURE Edit_Recipe(RecipeNo : TRecipeRef;lUniqueRef : LONGINT);

IMPLEMENTATION

CONST WIN_X            = 01;          { WINDOW X Offset       (Global )     }
      WIN_Y            = 02;          { WINDOW Y Offset       (Global )     }
      WIN_WID          = 79;          { WINDOW Width          (Global )     }
      WIN_DEP          = 23;          { WINDOW Depth          (Global )     }

CONST EWIN_X           = 24;          { ITEM EDIT WINDOW X Offset (Global ) }
      EWIN_Y           = WIN_Y+7;     { ITEM EDIT WINDOW Y Offset (Global ) }
      EWIN_WID         = 40;          { ITEM EDIT WINDOW Width    (Global ) }
      EWIN_DEP         = 13;          { ITEM EDIT WINDOW Depth    (Global ) }

      LIST_X           = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH       = WIN_WID-2;   { LIST BOX WIDTH        (Global )     }
      LIST_Y           = WIN_Y+12;    { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH       = 8;           { LIST BOX DEPTH        (Global )     }

{$IFDEF RECIPEBYPHR}
      BLANK_RCPLINE    = ' ---- ---------- --- ------- ------- ---------- -----------------------------';
{$ELSE}
      BLANK_RCPLINE    = ' ---- ---------- --- ------- ---------- ------------------------------';
{$ENDIF}
      BLANK_EXTLINE    = ' --- -------- - ------- -------- ------------------------------ ------ ------';

      Title_Line1      = '                   Mix    Cont.                                Wt. Tolerance';
      Title_Line2      = 'Ln. Ingred. Key  Ratio    Size  Description                     - %    + %  ';

      RECIPENO_F       = 1;
      DESC_F           = 2;
      {BCODE_F}
      JOB_NO_F         = 3;
      MIX_TYPE_F       = 4;
      SEQFIXED_F       = 5;
      WORKGRP_F        = 6;
      MIXB_WT_F        = 7;
      STDCASE_F        = 8;
      PROCLOSS_F       = 9;
      STOCKREQ_F       = 10;
      ISSUENO_F        = 11;
      LISTBOX          = 12;
      FIRSTFIELD       = RECIPENO_F;          { Start Field ID                      }
      LASTFIELD        = LISTBOX;             { Last Field ID          }

TYPE PRecipeEdit = ^TRecipeEdit;
     TRecipeEdit = object(TCombinedRecordEdit)

      RecipeNo       : TRecipeRef;
      RecipeRec      : PRecipeRecord;
      IngredientRec  : TIngredient_Record;
      UniqueRef      : LONGINT;

      TotalPHR       : DOUBLE;

      CONSTRUCTOR Init(Recipe : TRecipeRef;lUniqueRef : LONGINT);
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   Setup; Virtual;
      FUNCTION    ReadRecordFunc       (Operation : STRING) : INTEGER; Virtual;
      PROCEDURE   FillListPosWithRec   (Element   : BYTE); Virtual;
      PROCEDURE   DisplayListItem      (Element   : BYTE); Virtual;
      PROCEDURE   GetBrowseEvent; Virtual;
      FUNCTION    EventHandled         : BOOLEAN; Virtual;
      PROCEDURE   ResetRecipeEditor;
      FUNCTION    Output_Value(Field : INTEGER) : STRING;
      PROCEDURE   Input_Value(Field_Str : STRING; Field : INTEGER);
      PROCEDURE   DisplayField(Field : INTEGER); VIRTUAL;
      PROCEDURE   EditField(Field : LONGINT);
      PROCEDURE   DeleteListItem       (Element   : BYTE); Virtual;
      PROCEDURE   InsertListItem; Virtual;
      FUNCTION    InsertRecordLineAt(Element : BYTE) : BOOLEAN; Virtual;
      FUNCTION    AddRcpLine : LONGINT; Virtual;
      PROCEDURE   SetItemAsKeyIngredient(Element : BYTE);
      PROCEDURE   MoveItemUpList(Element : BYTE); Virtual;
      PROCEDURE   MoveItemDownList(Element : BYTE); Virtual;
      FUNCTION    EditLineRecord          (Element   : BYTE;NewLine : BOOLEAN) : BOOLEAN; Virtual;
      FUNCTION    CheckValidityOfRecord : BOOLEAN;
      PROCEDURE   CheckLinesAreToleranced;
      (*PROCEDURE   EnquireCopyFromExistingRecipe(sRecipeNo : TRecipeRef);*)
      PROCEDURE   RefreshListBox;VIRTUAL;
     END;


CONSTRUCTOR TRecipeEdit.Init(Recipe : TRecipeRef;lUniqueRef : LONGINT);
BEGIN
 RecipeNo  := Recipe;
 UniqueRef := lUniqueRef;
 { Inherited Method Clears Screen List Array }
 INHERITED Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH,FIRSTFIELD,LASTFIELD,LISTBOX);
 {Clear Defaults}

 Show_Btrv_Err(IngredientFile^.OpenFile);
 IF IngredientFile^.OpenErr <> 0 THEN Esc_Flag := TRUE;

 Show_Btrv_Err(RecipeFile^.OpenFile);
 IF RecipeFile^.OpenErr <> 0 THEN Esc_Flag := TRUE;

 RecipeRec := NIL;
 NEW(RecipeRec);
 IF Assigned(RecipeRec) THEN RecipeFile^.InitRecord(RecipeRec)
 ELSE Esc_Flag := TRUE;
END;

DESTRUCTOR TRecipeEdit.Done;
BEGIN
 IF Assigned(RecipeRec) THEN
  BEGIN
   RecipeFile^.ClearLines(RecipeRec);   {Dispose List Of Ingredients   }
   Dispose(RecipeRec);                  {Dispose Recipe Composite Record}
  END;
 RecipeFile^.CloseFile;
 IngredientFile^.CloseFile;
 INHERITED Done;
END;

PROCEDURE TRecipeEdit.RefreshListBox;
CONST TotalLine = LIST_Y+LIST_DEPTH-2;
VAR OrdLine : INTEGER;
BEGIN
 TotalLineRatio := 0;
 TotalPHR       := 0;
 INHERITED RefreshListBox;
 WITH RecipeRec^ DO
  BEGIN
   FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
    BEGIN
     IF Assigned(RP_Lines[OrdLine]) THEN
      BEGIN
       RP_Lines[OrdLine]^.RL_HUniqueRef := RP_Header.RH_UniqueRef;
       TotalLineRatio := TotalLineRatio + RP_Lines[OrdLine]^.RL_DefaultRatio;
       TotalPHR       := TotalPHR + RP_Lines[OrdLine]^.RL_PHR;
      END;
    END;
  END;
{$IFDEF RECIPEBYPHR}
 WriteAt(2,TotalLine,'Total Line Ratio : '+DoubleToStr(TotalLineRatio,7,3)+
                     '%   Total PHR : '+DoubleToStr(TotalPHR,7,3));
{$ELSE}
 WriteAt(2,TotalLine,'Total Line Ratio : '+DoubleToStr(TotalLineRatio,7,3)+'%');
{$ENDIF}

END;

PROCEDURE TRecipeEdit.ResetRecipeEditor;
BEGIN
 RecipeFile^.ClearLines(RecipeRec);                  { Clear Recipe Lines       }
 RecipeFile^.InitRecord(RecipeRec);                  { Init Recipe Record       }
 ClearAllOfList;                                 { Clear List Screen Array  }
 ListIndex := 1;                                 { Reset HiliteBar Pos.     }

 NewRecord   := NowtButSpace(RecipeNo);          { Add Or Edit?             }
 IF NewRecord THEN
  BEGIN
   First_Field := RecipeNO_F;                    { Set First Entry Field    }
  END
 ELSE
  BEGIN
   First_Field := DESC_F;                        { Set First Entry Field    }
                                                 { Prime Key Fields         }
   RecipeRec^.RP_Header.RH_RecipeNo  := RecipeNo;
   RecipeRec^.RP_HEader.RH_UniqueRef := UniqueRef;
   IF RecipeFile^.ReadAllRecords('EQ',FALSE,FALSE,RecipeRec,1) <> 0 THEN
    BEGIN
     Disp_Error_Msg('Recipe Record Not Found');  { Recipe Record Not Found  }
     Esc_Flag := TRUE;                           { Forced Exit              }
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

PROCEDURE TRecipeEdit.Setup;                 { Called From TFileBrowser.Run }
BEGIN
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,EditWindow);
 EditWindowUp := TRUE;
 MenuCr :='xx';
 DisplayStaticTextAndFields('FXRPEDIT');
 IF (Config_Rec^.CONF_ShowTolOnRecipeEdit) THEN
  BEGIN
   {Re-Write Editor Headers}
   RevVideo;
   WriteAt(2,10,Title_Line1);
   WriteAt(2,11,Title_Line2);
   LowVideo;
  END;
 ResetRecipeEditor;
END;

{***************************************************************************}
{********* ENTRY FIELD HANDLING METHODS                           **********}
{***************************************************************************}
(*
PROCEDURE TRecipeEdit.EnquireCopyFromExistingRecipe(sRecipeNo : TRecipeRef);
VAR
   FuncSave   : BOOLEAN;
   Ch1Save    : CHAR;
   RHRec      : TRecipeHeaderRecord;
   RcpBrowse  : PRecipeBrowse;
BEGIN
 Ch1Save  := Ch1;              {Save varibles as they are needed elsewhere}
 FuncSave := FuncKey;
 RHRec.RH_RecipeNo    := sRecipeNo;
 IF RecipeFile^.HeaderFile^.ReadRecord('GE',FALSE,FALSE,RHRec,0) = 0 THEN
  BEGIN
   IF RHRec.RH_RecipeNo = sRecipeNo THEN
    BEGIN
     IF YesNoWin('      Copy Information From'+CRLF+
                 '       Existing Record Y/N') THEN
      BEGIN
       New(RcpBrowse,Init(sRecipeNo,RHRec));
       RcpBrowse^.Run;
       RecipeRec^.RP_Header.RH_Description := RHRec.RH_Description;
       RecipeRec^.RP_Header.RH_DefaultMixType     := RHRec.RH_DefaultMixType;
       RecipeRec^.RP_Header.RH_MixBatchWt  := RHRec.RH_MixBatchWt;
       RecipeRec^.RP_Header.RH_SeqFixed    := RHRec.RH_SeqFixed;
       Dispose(RcpBrowse,Done);
       DisplayFields;
      END;
    END;
  END;
 Ch1     := Ch1Save;
 FuncKey := FuncSave;
END;
*)

{ INPUT VALUE PUT ENTERED FIELD INTO Record BUFFER                          }
PROCEDURE TRecipeEdit.Input_Value(Field_Str : STRING; Field : INTEGER);
VAR Number,Dummy : INTEGER;
BEGIN
 IF (DatCtl[Field] = 02) THEN EXIT;
 WITH RecipeRec^.RP_Header DO
  BEGIN
   CASE Field OF
    RECIPENO_F : BEGIN
     RH_RecipeNo    := Field_Str;
     (*EnquireCopyFromExistingRecipe(RH_RecipeNo);*)
    END;
    DESC_F     : RH_Description := Field_Str;
    {BCODE_F    : RH_Barcode     := Field_Str;}
    JOB_NO_F   : RH_JobNo := StringToLong(Field_Str);
    SEQFIXED_F : RH_DefaultSeqFixed := (Field_Str[1] = TICK_CHAR);
    WORKGRP_F  : RH_WorkGroup   := Field_Str;
    MIX_TYPE_F : BEGIN
                  VAL(Field_Str,Number,Dummy);
                  IF (Number >= ORD(Low(TMixType))) AND (Number <= ORD(High(TMixType))) THEN
                   RH_DefaultMixType := TMixType(Number)
                  ELSE
                   RH_DefaultMixType := mt_SingleContainerPerMix;
                 END;

    MIXB_WT_F  : BEGIN
     RH_DefaultMixWt  := StringToDouble(Field_Str);
     IF (Config_Rec^.Conf_Batches) THEN
      RH_StdCaseWt := RH_DefaultMixWt;
    END;

    STDCASE_F  : RH_StdCaseWt   := StringToDouble(Field_Str);
    PROCLOSS_F : BEGIN
                  RH_ProcLossAfterMixing:= StringToDouble(Field_Str);
                  IF RH_ProcLossAfterMixing > 100 THEN
                    RH_ProcLossAfterMixing := 100.0;
                 END;
    STOCKREQ_F : RH_BasicStock  := StringToLong(Field_Str);
    ISSUENO_F  : RH_IssueNo     := Field_Str;
   END;
  END;
END;

{ OUTPUT VALUE, GET Record DATA INTO EDIT BUFFER }
FUNCTION TRecipeEdit.Output_Value(Field : INTEGER) : STRING;
VAR FieldStr : STRING;
BEGIN
 IF (DatCtl[Field] = 02) THEN EXIT;
 FieldStr :='';
 WITH RecipeRec^.RP_Header DO
  BEGIN
   CASE Field OF
    RecipeNO_F : FieldStr := RH_RecipeNo;
    DESC_F     : FieldStr := RH_Description;
    {BCODE_F    : FieldStr := RH_BarCode;}
    JOB_NO_F   : FieldStr := IntToZeroStr(RH_JobNo,3);
    SEQFIXED_F : IF RH_DefaultSeqFixed THEN FieldStr := TICK_CHAR
                 ELSE FieldStr := ' ';
    WORKGRP_F  : FieldStr := RH_WorkGroup;
    MIX_TYPE_F : FieldStr := IntToStr(Ord(RH_DefaultMixType),1);
    MIXB_WT_F  : FieldStr := DoubleToZeroStr(RH_DefaultMixWt,9,3);
    STDCASE_F  : FieldStr := DoubleToZeroStr(RH_StdCaseWt,9,3);
    PROCLOSS_F : FieldStr := DoubleToZeroStr(RH_ProcLossAfterMixing,6,2);
    STOCKREQ_F : FieldStr := IntToZeroStr(RH_BasicStock,5);
    ISSUENO_F  : FieldStr := RH_IssueNo;
   END;
 END;
 Output_Value := FieldStr;
END;

{ DISPLAY FIELD, DISPLAY INDIVIDUAL FIELD }
PROCEDURE TRecipeEdit.DisplayField(Field : INTEGER);
VAR Int,Dummy : INTEGER;
BEGIN
 IF (DatCtl[Field] = 02) THEN EXIT;
 GotoXY(XCoord[Field],YCoord[Field]);
 CASE Field OF
  RECIPENO_F,
  DESC_F,
  MIXB_WT_F,
  STDCASE_F,
  STOCKREQ_F,
  ISSUENO_F,
  PROCLOSS_F,
  {BCODE_F,}
  JOB_NO_F,
  WORKGRP_F : WriteField(XCoOrd[Field],YcoOrd[Field],Output_Value(Field),TRUE);

  MIX_TYPE_F : BEGIN
    VAL(OutPut_Value(MIX_TYPE_F),Int,Dummy);
    WriteField(XcoOrd[Field],YcoOrd[Field],(MixTypeListItems[TMixType(Int)]),TRUE);
    RevWriteAt(WhereX,WhereY,#25);
    RefreshlistBox;
    RecipeFile^.ResetContainerSizes(RecipeRec);
  END;
  SEQFIXED_F : BEGIN
   IF (Copy(Output_Value(Field),1,1) = TICK_CHAR) THEN
    WriteTickBox(XcoOrd[Field],YCoOrd[Field],TRUE)
   ELSE
    WriteTickBox(XcoOrd[Field],YCoOrd[Field],FALSE)
  END;
 END;
 IF (Config_Rec^.Conf_Batches) AND (Field = MIXB_WT_F) THEN
  DisplayField(STDCASE_F);
 IF Field = RECIPENO_F THEN
  BEGIN
   IF RecipeRec^.RP_Header.RH_Obsolete THEN
     WriteField(XCoOrd[DESC_F],YcoOrd[DESC_F]+1,'(Obsolete)',FALSE);
  END;
END;

PROCEDURE TRecipeEdit.EditField(Field : LONGINT);
VAR WrkStr : STRING;
    Int,Dummy : INTEGER;
BEGIN
 WrkStr := Output_Value(Field);
 CASE Field OF
   JOB_NO_F   : GetInteger(RecipeRec^.RP_Header.RH_JobNo,3,Xcoord[Field],Ycoord[Field]);
   ELSE
     CASE Field OF
   RecipeNO_F,
   ISSUENO_F,
   DESC_F,
   WORKGRP_F  : GetLine(WrkStr,LenOrd[Field],Xcoord[Field],Ycoord[Field]);
   {BCode_F    : GetNumSpaceLine(WrkStr,LenOrd[Field],Xcoord[Field],Ycoord[Field]);}
   MIX_TYPE_F : BEGIN
    VAL(WrkStr,Int,Dummy);
    WrkStr  := IntToStr(GetListBoxEntry(MixTypeListItems,ORD(LastMixType)+1,Int+1,
                        XcoOrd[Field],YcoOrd[Field],FALSE)-1, 1);
   END;
   MIXB_WT_F,
   STDCASE_F  : GetFloat(Xcoord[Field],Ycoord[Field],WrkStr,LenOrd[Field],3);         { Window Posn }
   PROCLOSS_F : GetFloat(Xcoord[Field],Ycoord[Field],WrkStr,LenOrd[Field],2);         { Window Posn }
   STOCKREQ_F : GetLine_Num(WrkStr,LenOrd[Field],Xcoord[Field],Ycoord[Field],0);
   SEQFIXED_F : GetTick(WrkStr,XcoOrd[Field],YCoOrd[Field]);
     END;
    IF (ch1 <> FN_F10) THEN Input_Value(WrkStr,Field);
  END;
 IF ch1 = ESC THEN Esc_Flag := TRUE;
END;


FUNCTION TRecipeEdit.ReadRecordFunc(Operation : STRING) : INTEGER;
VAR Result : INTEGER;

 PROCEDURE CheckAssigned(ErrorCode : INTEGER);
  BEGIN
   IF NOT Assigned(RecipeRec^.RP_Lines[CurrLine]) THEN
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
   ELSE IF CurrLine > MAX_LINES_ON_RECORD THEN Result := 4;
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

PROCEDURE TRecipeEdit.FillListPosWithRec(Element   : BYTE);
BEGIN
 IF Assigned(RecipeRec^.RP_Lines[CurrLine]) THEN
  BEGIN
   BrowseList[Element].LineNo := RecipeRec^.RP_Lines[CurrLine]^.RL_LineNo;
  END
 ELSE
  BEGIN
   BrowseList[Element].LineNo := 0;
  END;
END;

PROCEDURE TRecipeEdit.DisplayListItem(Element   : BYTE);
VAR Line : LONGINT;
BEGIN
 IF (NOT ListPosIsEmpty(Element)) THEN
  BEGIN
   WITH RecipeRec^.RP_Lines[BrowseList[Element].LineNo]^,RecipeRec^.RP_Header DO
    BEGIN
      IF (Config_Rec^.CONF_ShowTolOnRecipeEdit) THEN
       BEGIN
        Write(' ',RL_LineNo:3,' ',RL_Ingredient,' ');

        IF RL_DefaultKeyIngred THEN Write(Tick_Char,' ')
        ELSE Write('  ');

        Write(RL_DefaultRatio:7:3,' ');

        IF(RH_DefaultMixType IN MixSet_ProportionallyMixedConts)
        AND (BrowseList[Element].LineNo<>1) THEN Write('######## ')
        ELSE Write(RL_DefaultContSize:8:3,' ');

        Write(Copy(GetIngredientDesc(RL_Ingredient)+SPACE_STRING,1,30),' ');
        Write(DoubleToStr(RL_DefaultLowTol,6,3),' ');
        Write(DoubleToStr(RL_DefaultHighTol,6,3));
       END
      ELSE
       BEGIN
        Write(RL_LineNo:5,' ',RL_Ingredient,'   ');

        IF RL_DefaultKeyIngred THEN Write('Yes ')
        ELSE Write('    ');

        Write(RL_DefaultRatio:7:3,' ');
{$IFDEF RECIPEBYPHR}
        Write(RL_PHR:7:3,' ');
{$ENDIF}
        IF(RH_DefaultMixType IN MixSet_ProportionallyMixedConts)
        AND (BrowseList[Element].LineNo<>1) THEN Write('######### ')
        ELSE Write(RL_DefaultContSize:9:3,' ');
{$IFNDEF RECIPEBYPHR}
        Write(' ');
{$ENDIF}
        Write(GetIngredientDesc(RL_Ingredient));
       END;
    END;
  END
 ELSE
  IF (Config_Rec^.CONF_ShowTolOnRecipeEdit) THEN Write(BLANK_EXTLINE)
  ELSE Write(BLANK_RCPLINE);

END;

PROCEDURE TRecipeEdit.CheckLinesAreToleranced;
BEGIN
 IF RecipeFile^.AllLinesAreUntoleranced(RecipeRec) THEN
  BEGIN
   IF YesNoWin(' Apply default tolerances'+CRLF+
               ' to ingredients (Y/N)?') THEN
    BEGIN
     RecipeFile^.ApplyIngredTols(RecipeRec);
     RefreshListBox;                               { Redraw Ingredient List   }
    END;
  END;
END;

FUNCTION TRecipeEdit.CheckValidityOfRecord : BOOLEAN;
VAR
    I        : INTEGER;
    Percent  : DOUBLE;
    RHRec    : TRecipeHeaderRecord;
    Op       : STRING[2];
BEGIN
 Esc_Flag := FALSE;
 CheckValidityOfRecord := FALSE;
 Percent  := 0;
 FOR I:=1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF NOT Assigned(RecipeRec^.RP_Lines[I]) THEN CONTINUE;
   WITH RecipeRec^.RP_Lines[I]^ DO
    BEGIN
     Percent := Percent + RL_DefaultRatio;
    END;
  END;
 IF LONGINT(Round(Percent*1000)) <> LONGINT((100*1000)) THEN
  BEGIN
   Disp_Error_Msg('Ingredient Ratio Percentage Must Add to 100%');
   EXIT;
  END;
(*
 WITH RecipeRec^.RP_Header DO
  BEGIN
   IF RH_MinTargetWt > RH_MaxTargetWt THEN
    BEGIN
     Disp_Error_Msg('Min Target Wt Is Greater Than Max Target Wt. Re-Edit These Fields');
     EXIT;
    END;
   RHRec.RH_RecipeNo := RH_RecipeNo;
   Op := 'GE';
   WHILE (RecipeFile^.HeaderFile^.ReadRecord(Op,FALSE,FALSE,RHRec,0) = 0) DO
    BEGIN
     IF RHREc.RH_RecipeNo <> RH_RecipeNo THEN BREAK;
     Op := 'GN';
     IF RHRec.RH_UniqueRef = RH_UniqueRef THEN CONTINUE; {Dont test with itself}
     IF ((RHRec.RH_MinTargetWt >= RH_MinTargetWt) AND (RHRec.RH_MinTargetWt <= RH_MaxTargetWt)) OR
        ((RHRec.RH_MaxTargetWt >= RH_MinTargetWt) AND (RHRec.RH_MaxTargetWt <= RH_MaxTargetWt)) THEN
      BEGIN
       Disp_Error_Msg('Recipes Min/Max Target Wt Overlap Another Recipe. Amend These Fields');
       EXIT;
      END;
    END;
  END;
*)
 CheckValidityOfRecord := TRUE;
 Esc_Flag := TRUE;
END;


PROCEDURE TRecipeEdit.GetBrowseEvent;
VAR DispCol : BYTE;
    FoundSite : BOOLEAN;
    SError    : INTEGER;
BEGIN
  IF (FieldNo = LISTBOX) THEN
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
FUNCTION TRecipeEdit.EventHandled : BOOLEAN;
VAR ErrInt        : INTEGER;
    TempHeaderRec : TRecipeHeaderRecord;
    HandledEvent  : BOOLEAN;
BEGIN
 HandledEvent := FALSE;

 IF Funckey THEN
  BEGIN
   CASE ch1 OF
    FN_F3  : BEGIN                               { Set As Key Ingredient    }
      SetItemAsKeyIngredient(ListIndex);
      RefreshListBox;
      HandledEvent := TRUE;
    END;

    FN_F10 : BEGIN
      IF YesNoWin('Abandon All Recipe Changes (Y/N)?') THEN Esc_Flag := TRUE;
      HandledEvent := TRUE;
    END;

   END;                                          { END (CASE Ch1 OF)        }
  END
 ELSE
  BEGIN
   CASE ch1 OF
    ESC : BEGIN                                  { ESC KEY PRESSED          }
      IF NOT NowtButSpace(RecipeRec^.RP_Header.RH_RecipeNo) AND
        CheckValidityOfRecord THEN
       BEGIN                                     { IF Record TO SAVE        }
        (* Record ADD/UPDATE CODE GOES HERE *)
        IF NOT NewRecord THEN
         BEGIN
          TempHeaderRec.RH_UniqueRef := UniqueRef;
          RecipeFile^.HeaderFile^.ReadRecord('EQ',TRUE,FALSE,TempHeaderRec,1);
          CASE RecipeFile^.HeaderFile^.BtrvErr OF
           0  : BEGIN
            IF TempHeaderRec.RH_UpdateCount <> RecipeRec^.RP_Header.RH_UpdateCount THEN
             BEGIN
              RecipeFile^.HeaderFile^.Unlock_Single; { Unlock Recipe Record      }
              Rec_Changed_Error(FALSE);        { Display Rec Changed        }
              ResetRecipeEditor;                { Re-Read Recipe Record       }
              Esc_Flag := FALSE;               { Cycle To Next Event        }
             END
            ELSE
             BEGIN
              RecipeFile^.UpdateRecord(RecipeRec);  { Update Records To Files    }
             END;
           END;

           BNoRecord : BEGIN        { Record Deleted By Another Workstation }
            IF Upcase(Rec_Changed_Error(TRUE)) = 'Y' THEN
             BEGIN
              Show_Btrv_Err(RecipeFile^.AddRecord(RecipeRec));
             END;
           END;

           ELSE Show_Btrv_Err(RecipeFile^.HeaderFile^.BtrvErr);
          END;
         END  { END (NOT NewRecord) }
        ELSE
         BEGIN                                       { NEW Record TO ADD }
          RecipeFile^.AddRecord(RecipeRec);
          IF RecipeFile^.BtrvErr = BDuplicate THEN
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


PROCEDURE TRecipeEdit.DeleteListItem(Element   : BYTE);
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   IF NowtButSpace(RecipeRec^.RP_Lines[Element]^.RL_Ingredient) OR
   YesNoWin('          Delete Record'+CRLF+
               '         Are You Sure Y/N') THEN
    BEGIN
     RecipeFile^.DeleteLineRec(RecipeRec,BrowseList[Element].LineNo);
{$IFDEF RECIPEBYPHR}
  RecipeFile^.CalculateRatiosFromPHR(RecipeRec);
{$ENDIF}
     RefreshListBox;
    END
  END;
END;


FUNCTION TRecipeEdit.EditLineRecord(Element   : BYTE;NewLine : BOOLEAN) : BOOLEAN;
{ Field Constants }
CONST FIRSTL_F  = 1;
      INGRED_F  = 1; { Ingredient Code                }
      MIXRAT_F  = 2; { Mix Ratio                      }
      CONTSZ_F  = 3; { Container Size                 }
      YIELD_F   = 4;
      LOWTOL_F  = 5;
      HIGHTOL_F = 6;
      INDESC_F  = 7; { Ingredient Description         }
      LASTL_F   = INDESC_F;

VAR   FirstLineField : BYTE;
      LField         : BYTE;
      RecipeLine     : LONGINT;
      ERecipeLine    : TRecipeLineRecord;
      IngredientProcessType : TProcessTypes;

 PROCEDURE DisplayLineField(Field_Str : STRING;Field : BYTE);
 BEGIN
  IF Field IN [INGRED_F,MIXRAT_F,YIELD_F,HIGHTOL_F,LOWTOL_F] THEN
   WriteField(XcoOrd[Field],YcoOrd[Field],Field_Str,TRUE)
  ELSE IF Field = CONTSZ_F THEN
   BEGIN
    IF  (RecipeRec^.RP_Header.RH_DefaultMixType IN MixSet_ProportionallyMixedConts)
    AND (ERecipeLine.RL_LineNo <> 1) THEN
      WriteField(XcoOrd[Field],YcoOrd[Field],'#########',FALSE)
    ELSE
      WriteField(XcoOrd[Field],YcoOrd[Field],Field_Str,TRUE);

   END
  ELSE WriteField(XcoOrd[Field],YcoOrd[Field],Field_Str,FALSE);
 END;

 PROCEDURE DrawEditWindow;
 BEGIN
  BackColourScheme;
  SetWindow(EWIN_X,EWIN_Y,EWIN_X+EWIN_WID,EWIN_Y+EWIN_DEP,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,ItemWindow);
  IF NOT LoadMenu('FXRPIED',TRUE) THEN
   BEGIN
    Disp_Error_Msg('Menu File Not Found FXRPIED.TXT');
    Esc_Flag := TRUE;                        { Exit                         }
   END;
  ForeColourScheme;
 END;

 PROCEDURE RemoveEditWindow;
 BEGIN
  LoseWindow(ItemWindow);
  DisplayStaticTextAndFields('FXRPEDIT');  { Reload Recipe Editor Fields   }
  IF (Config_Rec^.CONF_ShowTolOnRecipeEdit) THEN
   BEGIN
    {Re-Write Editor Headers}
    RevVideo;
    WriteAt(2,10,Title_Line1);
    WriteAt(2,11,Title_Line2);
    LowVideo;
   END;
 END;

 FUNCTION LineFieldValue(Field : BYTE) : STRING;
 VAR Field_Str : STRING;
     TempLong  : LONGINT;
 BEGIN
  Field_Str := '';
  WITH RecipeRec^.RP_Header,ERecipeLine DO
   BEGIN
    CASE Field OF
     INGRED_F : Field_Str := RL_Ingredient;
{$IFDEF RECIPEBYPHR}
     MIXRAT_F : Field_Str := DoubleToZeroStr(RL_PHR,LenOrd[MIXRAT_F],3);
{$ELSE}
     MIXRAT_F : Field_Str := DoubleToZeroStr(RL_DefaultRatio,LenOrd[MIXRAT_F],3);
{$ENDIF}
     YIELD_F  : Field_Str := DoubleToZeroStr(RL_DefaultYield,LenOrd[YIELD_F],3);
     CONTSZ_F : Field_Str := DoubleToZeroStr(RL_DefaultContSize,LenOrd[CONTSZ_F],3);
     HIGHTOL_F: Field_Str := DoubleToZeroStr(RL_DefaultHighTol,LenOrd[HIGHTOL_F],3);
     LOWTOL_F : Field_Str := DoubleToZeroStr(RL_DefaultLowTol,LenOrd[LOWTOL_F],3);

     INDESC_F : Field_Str := GetIngredientDesc(ERecipeLine.RL_Ingredient);
    END;
   END;
  LineFieldValue := Field_Str;
 END;


 PROCEDURE DisplayLineFields;
 VAR LPA : BYTE;
 BEGIN
  CursorOFF;
  FOR LPA := 1 TO LASTL_F DO DisplayLineField(LineFieldValue(LPA),LPA);
  CursorON;
 END;

 PROCEDURE SetStepIngredientFields;
 BEGIN
  WITH ERecipeLine DO
   BEGIN
    RL_DefaultRatio    := 0.0;
    RL_DefaultContSize := 0.0;
   END;
 END;


 PROCEDURE InputLineField(Field_Str : STRING; Field : BYTE);
 VAR LPA : INTEGER;
 BEGIN
  WITH ERecipeLine DO
   BEGIN
    CASE Field OF
     INGRED_F : BEGIN
       IF NOT Str_Equal(Field_Str, RL_Ingredient,
                        SizeOf(RL_Ingredient)-1) THEN { new ingred code }
        BEGIN
         PrimeRecipeLineForIngredient(ERecipeLine, Field_Str);
         FOR LPA := 2 TO LASTL_F DO
           DisplayLineField(LineFieldValue(LPA),LPA);
        END;
(*
       IngredientRec.ING_Ingredient := Field_Str;
       IngredientFile^.ReadRecord('EQ',FALSE,FALSE,IngredientRec,0);
       IF IngredientFile^.BtrvErr = 0 THEN
        BEGIN
         RL_Ingredient := Field_Str;
         IF IngredientRec.ING_Type = PTStep THEN SetStepIngredientFields;
         IF RL_Yield = 0.0 THEN
          RL_Yield := IngredientRec.ING_Yield;
        END
       ELSE IF (IngredientFile^.BtrvErr = 4) THEN
        BEGIN        dddddddddddd
         IngredientLookup(@IngredientRec);
         RL_Ingredient := IngredientRec.ING_Ingredient;
         IF RL_Yield = 0.0 THEN
          RL_Yield := IngredientRec.ING_Yield;

         IF RL_HighTol = 0.0 THEN
          RL_HighTol := IngredientRec.ING_HighTol;

         IF RL_LowTol = 0.0 THEN
          RL_LowTol := IngredientRec.ING_LowTol;

         Ch1 :=' ';
        END
       ELSE
        BEGIN
         Show_Btrv_Err(IngredientFile^.BtrvErr);
         Ch1 :=' ';
        END;
*)
     END;

     MIXRAT_F : BEGIN
{$IFDEF RECIPEBYPHR}
      RL_PHR    := StringToDouble(Field_Str);
{$ELSE}
      RL_DefaultRatio  := StringToDouble(Field_Str);
{$ENDIF}
     END;
     YIELD_F : BEGIN
      RL_DefaultYield := StringToDouble(Field_Str);
     END;

     CONTSZ_F : BEGIN
       RL_DefaultContSize := StringToDouble(Field_Str);
     END;

     HIGHTOL_F : BEGIN
       RL_DefaultHighTol:= StringToDouble(Field_Str);
     END;

     LOWTOL_F : BEGIN
       RL_DefaultLowTol := StringToDouble(Field_Str);
     END;

    END;
   END;
 END;

 PROCEDURE EditLineRecordField(Field : LONGINT);
 VAR WrkStr : STRING;
 BEGIN
  IF IngredientProcessType = PTStep THEN EXIT;
  WrkStr := LineFieldValue(Field);
  CASE Field OF

   INGRED_F  : BEGIN                                        {Ingredient Code}
     GetLine(WrkStr,LenOrd[Field],XCoord[Field],YCoord[Field]);
     IF (Ch1 <> FN_F10) THEN
      BEGIN
       IF (IngredientFile^.GetIngredient(WrkStr,IngredientRec,FALSE) = BNoRecord)
       OR (Ch1 = FN_F1) THEN { after loading record with GetIngredient call }
        BEGIN
         IngredientLookup(@IngredientRec);
         WrkStr := IngredientRec.ING_Ingredient;
        END;
      END;
   END;
   HIGHTOL_F,{High Tol}
   LOWTOL_F, {Low Tol}
   MIXRAT_F, {Mix Ratio}
   YIELD_F : GetFloat(XcoOrd[Field],YcoOrd[Field],WrkStr,LenOrd[Field],3);

   CONTSZ_F  : BEGIN                                        {Container Size }
     IF (RecipeRec^.RP_Header.RH_DefaultMixType IN MixSet_ProportionallyMixedConts) THEN
      BEGIN
       IF (ERecipeLine.RL_LineNo = 1) THEN
        GetFloat(XcoOrd[Field],YcoOrd[Field],WrkStr,LenOrd[Field],3)
      END
     ELSE
      GetFloat(XcoOrd[Field],YcoOrd[Field],WrkStr,LenOrd[Field],3);
   END;
  END;{CASE}
  IF (ch1 <> FN_F10) THEN InputLineField(WrkStr,Field);
  IF ch1 = ESC THEN Esc_Flag := TRUE;
 END;

 PROCEDURE  HandleLineEntryEvent;
 BEGIN
  IF FuncKey THEN
   BEGIN
    CASE ch1 OF
     PREV : REPEAT
      IF LField > FirstLineField THEN DEC(LField) ELSE LField := LASTL_F;
     UNTIL DatCtl[LField] = 0;
     NEXT : REPEAT
      IF LField < LASTL_F THEN INC(LField) ELSE LField := FirstLineField;
     UNTIL DatCtl[LField] = 0;

     FN_F10 : BEGIN
      IF YesNoWin('Abandon Recipe Line Edit (Y/N)?') THEN Esc_Flag := TRUE;
     END;

    END;
   END
  ELSE
   BEGIN
    CASE ch1 OF
     ESC: BEGIN
      (* SAVE CHANGES *)
      IF NOT NowtButSpace(ERecipeLine.RL_Ingredient) THEN
       BEGIN
        RecipeRec^.RP_Lines[Element]^ := ERecipeLine;
        EditLineRecord := TRUE;
       END;
      Esc_Flag := TRUE;
     END;
    END;
   END;
 END;


BEGIN
  EditLineRecord := FALSE;
  ERecipeLine := RecipeRec^.RP_Lines[Element]^;           { Copy Recipe Line }
  DrawEditWindow;
  IF NewLine THEN
   BEGIN
    FirstLineField :=FIRSTL_F;
   END
  ELSE FirstLineField := MIXRAT_F;
  DisplayLineFields;
  ch1 := NEXT;
  LField := FirstLineField;
  IngredientProcessType := GetIngredientProcessType(ERecipeLine.RL_Ingredient);
  IF IngredientProcessType = PTStep THEN
   BEGIN
    SetStepIngredientFields;
    GetKey;
   END
  ELSE
   BEGIN
    REPEAT
     EditLineRecordField(LField);
     DisplayLineFields;
     HandleLineEntryEvent;
    UNTIL Esc_Flag;
   END;
  RemoveEditWindow;
  Esc_Flag := FALSE;
  Ch1 :=' ';
  TotalLineRatio := 0;
  TotalPHR       := 0;
{$IFDEF RECIPEBYPHR}
  RecipeFile^.CalculateRatiosFromPHR(RecipeRec);
{$ENDIF}
END;

PROCEDURE TRecipeEdit.SetItemAsKeyIngredient(Element : BYTE);
VAR EditLine : LONGINT;
    LPA      : LONGINT;
BEGIN
 IF (NOT ListPosIsEmpty(ListIndex)) THEN
  BEGIN
   EditLine := BrowseList[ListIndex].LineNo;
   IF RecipeRec^.RP_Lines[EditLine]^.RL_DefaultKeyIngred THEN
    BEGIN
     RecipeRec^.RP_Lines[EditLine]^.RL_DefaultKeyIngred := FALSE;
     EXIT;
    END;
   IF (RecipeRec^.RP_Lines[EditLine]<>NIL) AND
    (GetIngredientProcessType(RecipeRec^.RP_Lines[EditLine]^.RL_Ingredient) = PTStep) THEN
    BEGIN
     Disp_Error_Msg('Key Ingredient Can Not Be A Step Ingredient');
     EXIT;
    END;
   FOR LPA := 1 TO MAX_LINES_ON_RECORD DO
    BEGIN
     IF  (RecipeRec^.RP_Lines[LPA]<>NIL)
     AND (RecipeRec^.RP_Lines[LPA]^.RL_DefaultKeyIngred) THEN
      BEGIN
       RecipeRec^.RP_Lines[LPA]^.RL_DefaultKeyIngred := FALSE;
       Break;
      END;
    END;
   RecipeRec^.RP_Lines[EditLine]^.RL_DefaultKeyIngred := TRUE;
  END;
END;


FUNCTION TRecipeEdit.InsertRecordLineAt(Element : BYTE) : BOOLEAN;
VAR LPA        : INTEGER;
    LineNumber : LONGINT;
BEGIN
 InsertRecordLineAt := FALSE;
 IF ListPosIsEmpty(Element) THEN Exit;
 LineNumber := BrowseList[Element].LineNo;

 IF (NOT Assigned(RecipeRec^.RP_Lines[MAX_LINES_ON_RECORD])) THEN
  BEGIN
   FOR LPA := MAX_LINES_ON_RECORD-1 DOWNTO LineNumber DO
    BEGIN
     IF RecipeRec^.RP_Lines[LPA] <> NIL THEN
      BEGIN
       RecipeRec^.RP_Lines[LPA+1] := RecipeRec^.RP_Lines[LPA];
       RecipeRec^.RP_Lines[LPA+1]^.RL_LineNo := LPA+1;
       RecipeRec^.RP_LinePos[LPA+1] := RecipeRec^.RP_LinePos[LPA];
      END;
    END;
   RecipeRec^.RP_Lines[LineNumber]     := NIL;
   RecipeRec^.RP_LinePos[LineNumber]   := 0;
   NEW(RecipeRec^.RP_Lines[LineNumber]);
   IF Assigned(RecipeRec^.RP_Lines[LineNumber]) THEN
    BEGIN
     RecipeFile^.LineFile^.InitRecord(RecipeRec^.RP_Lines[LineNumber]^);
     RecipeRec^.RP_Lines[LineNumber]^.RL_RecipeNo := RecipeRec^.RP_Header.RH_RecipeNo;
     RecipeRec^.RP_Lines[LineNumber]^.RL_LineNo  := LineNumber;
     InsertRecordLineAt := TRUE;
    END;
  END;
END;

FUNCTION TRecipeEdit.AddRcpLine : LONGINT;
VAR LPA : LONGINT;
BEGIN
 AddRcpLine := 0;
 FOR LPA := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF (NOT Assigned(RecipeRec^.RP_Lines[LPA])) THEN
    BEGIN
     NEW(RecipeRec^.RP_Lines[LPA]);
     RecipeFile^.LineFile^.InitRecord(RecipeRec^.RP_Lines[LPA]^);
     RecipeRec^.RP_Lines[LPA]^.RL_RecipeNo := RecipeRec^.RP_Header.RH_RecipeNo;
     RecipeRec^.RP_Lines[LPA]^.RL_LineNo := LPA;
     RecipeRec^.RP_Lines[LPA]^.RL_HUniqueRef := RecipeRec^.RP_Header.RH_UniqueRef;
     AddRcpLine := LPA;
     Break;
    END;
  END;
END;

PROCEDURE TRecipeEdit.InsertListItem;
VAR EditLine : LONGINT;
BEGIN
 IF FieldNo <> LISTBOX THEN EXIT;
 EditLine := AddRcpLine;
 IF (EditLine > 0) THEN
  BEGIN
   IF (NOT EditLineRecord(EditLine,TRUE)) THEN
     RecipeFile^.DeleteLineRec(RecipeRec,EditLine);
   RefreshListBox;
  END;
END;

PROCEDURE TRecipeEdit.MoveItemUpList(Element : BYTE);
VAR CurrOrdLine    : LONGINT;
BEGIN
 IF ListPosIsEmpty(Element) THEN EXIT;
 CurrOrdLine := BrowseList[Element].LineNo;
 IF CurrOrdLine > 1 THEN
  BEGIN
   WITH RecipeRec^ DO
    BEGIN
     {Swap Record}
     SwapRecords(Pointer(RP_Lines[CurrOrdLine]),Pointer(RP_Lines[CurrOrdLine-1]));
     {Renumber Lines}
     RecipeRec^.RP_Lines[CurrOrdLine-1]^.RL_LineNo := CurrOrdLine-1;
     RecipeRec^.RP_Lines[CurrOrdLine]^.RL_LineNo := CurrOrdLine;
     {Swap Positions}
     SwapPositions(RP_LinePos[CurrOrdLine-1],RP_LinePos[CurrOrdLine]);
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

PROCEDURE TRecipeEdit.MoveItemDownList(Element : BYTE);
VAR CurrOrdLine    : LONGINT;
BEGIN
 IF ListPosIsEmpty(Element) THEN EXIT;
 CurrOrdLine := BrowseList[Element].LineNo;
 IF Assigned(RecipeRec^.RP_Lines[CurrOrdLine+1]) THEN
  BEGIN
   WITH RecipeRec^ DO
    BEGIN
     SwapRecords(Pointer(RP_Lines[CurrOrdLine]),Pointer(RP_Lines[CurrOrdLine+1]));
     RP_Lines[CurrOrdLine]^.RL_LineNo   := CurrOrdLine;
     RP_Lines[CurrOrdLine+1]^.RL_LineNo := CurrOrdLine+1;
     SwapPositions(RP_LinePos[CurrOrdLine],RP_LinePos[CurrOrdLine+1]);
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

PROCEDURE Edit_Recipe(RecipeNo : TRecipeRef;lUniqueRef : LONGINT);
VAR RecipeEditor : PRecipeEdit;
    RecipeFileAlloc : BOOLEAN;
BEGIN
 RecipeFileAlloc := Assigned(RecipeFile);
 IF NOT RecipeFileAlloc THEN
  BEGIN
   NEW(RecipeFile,Init(Config_Rec^.Conf_FPath+Recipe_Header_FileName,
                   Config_Rec^.Conf_FPath+Recipe_Line_FileName));
  END;
 NEW(RecipeEditor,Init(RecipeNo,lUniqueRef));
 RecipeEditor^.Run;
 DISPOSE(RecipeEditor,Done);
 IF NOT RecipeFileAlloc THEN
  BEGIN
   DISPOSE(RecipeFile,Done);
   RecipeFile := NIL;
  END;
END;


END.

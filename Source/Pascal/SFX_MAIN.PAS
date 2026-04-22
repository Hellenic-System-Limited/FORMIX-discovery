(****************************************************************************
*  UNIT          : SFX_Main                                                 *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Main window                                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFX_Main;
INTERFACE
USES F6StdUtl,F6StdCtv,F6StdWn1,SFXWin,SFXEdit,SFXFont,SFXMsg,FXDetail,
     FXFWork,FXFIngr,FXModCtv,FXFRcp,FXFILot,SFXFGen,SFXCurr,
     SFX_Bars,SFXGraph,SFXBtn,SFXConst,SFXStd,SFXOList,
     SFXUtils,SFXKbd,SFXStdBt,SFXCOLR,FXFMix,SFXLog,SFXDate,FXCfg,
     FXFUsers,F6DtConv;

{Main Recipe Window Positioning Constants}
{Windows and their positions are

-----------------------------------------------------------------------
|    Header Window Containing Title Time Date etc                     |
-----------------------------------------------------------------------
-----------------------------------------------------------------------
|   Order Details Window                                              |
|                                                                     |
|                                                                     |
|                                                                     |
|                                                                     |
|                                                                     |
-----------------------------------------------------------------------
-----------------------------------------------------------------------
|   HighLighted Ingredients Window                                    |
|                                                                     |
-----------------------------------------------------------------------
-----------------------------------------------------------------------
|   Special Instructions Window                                       |
-----------------------------------------------------------------------}


CONST Order_No_Lines    = 5;
CONST Order_Win_Top     = Header_Win_Bottom+Win_Leading;

{HighLighted Ingredients Window Contains 3 Lines Of Text}
CONST Ingr_No_Lines     = 3;
CONST Ingr_Win_Top      = Header_Win_Bottom+Win_Leading;
CONST Ingr_Win_Bottom   = Ingr_Win_Top+Ingr_No_Lines*Win_char_Size+Win_Leading;

{Special Instructions Containg 2 lines Of text}
CONST SI_No_Lines       = 2;
CONST SI_Win_Top        = (Ingr_Win_Bottom+Win_Leading)-1;
CONST SI_Win_Bottom     = SI_Win_Top+SI_No_Lines*Win_Char_Size+Win_Leading+2;
      SI_Win_Right      = All_Win_Right-166;

      Haz_Win_Top       = SI_Win_Top + 40;
      Haz_Win_Bottom    = SI_Win_Bottom;
      Haz_Win_Left      = SI_Win_Right + 4;

{CONST Order_Win_Bottom  = Order_Win_Top+Order_No_Lines*Win_Char_Size+Win_Leading;}
CONST Order_Win_Bottom = SI_Win_Bottom;


{X Coordinate For All First Column Of text}
{Y Coordinates For All windows First Rows Computed Here To Save Time}

CONST Win_Text_X        = (All_Win_Left+8) DIV 8;
CONST WinTextWidth      = (All_Win_Right-All_Win_Left) DIV 8;
CONST Text_Column2      =  Win_Text_X+33;
CONST Order_Text_Y      = (Order_Win_Top+8) DIV 8;
CONST Ingr_Text_Y       = (Ingr_Win_Top+8) DIV 8;
CONST SI_Text_Y         = (SI_Win_Top+8) DIV 8;

{Where Text Info Is Displayed}
CONST TCol1  = WIN_Text_X+17;
      TCol2  = Text_Column2+10;

      SmallIngredWinData1_X  = Win_Text_X + 11;
      SmallIngredWinTitle2_X = Win_Text_X + 34;

TYPE  PStopProcessEdit = ^TStopProcessEdit;
      TStopProcessEdit = OBJECT(TEdit)
       FUNCTION  UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
      END;


TYPE  PMainWindow = ^TMainWindow;
      TMainWindow = OBJECT(TButtonWindow)
       DrawPending   : BOOLEAN;
       SelChgPending : BOOLEAN;
       ShowingHeaderOnly : BOOLEAN;
       WindowFontSet : BOOLEAN;
       BatchBtn      : PStopProcessEdit;
       LotBtn        : PStopProcessEdit;

       LineMixWt       : DOUBLE; {wt of ingredient over all containers for current mix}
       IngredientWtReq : DOUBLE; {wt of ingredient in current container }
       HighestWt,
       LowestWt        : DOUBLE;
       NumWeighings    : LONGINT;{no of weighing of this ingred in curr mix }
       WghsPerContainer: LONGINT;{no of fixed wt items to be added to container}
       IngRec          : TIngredient_Record; { matching SelRec.WorkLRecord }
       MixStatRec      : TMixStatusRecord; { matching current mix no. }
       MixLineDoneRec  : TMixLineRecord;
       (*LastIngredient: TIngredientRef;*)

       CONSTRUCTOR Init(x1,y1,x2,y2,WinFlags : WORD);
       PROCEDURE Draw; VIRTUAL;
       PROCEDURE RefreshDetails(ActiveLineNo : LONGINT);
       FUNCTION  PreWeighingSetup : BOOLEAN;{ called when main window is refreshed }
                                            { and an ingredient is selected }
       FUNCTION  GetCurrentContainerNo : LONGINT;
                 { note: for segregated ingredients the container number
                         starts from one for each ingredient.
                 }
       FUNCTION  GetContsReqdForIngredient : LONGINT;


      PRIVATE
       PROCEDURE ClearCurrentOrderDetails;
       {PROCEDURE DisplayWindows;}

       PROCEDURE ShowLotAndBatchNumbers;
       PROCEDURE ShowHeaderDetails;
       PROCEDURE ShowIngredientInformation;
       PROCEDURE ShowSelRecs;

       {PROCEDURE ReReadSelHeader(VAR WorkHRecord : TWOHeaderRecord);}
       PROCEDURE SwitchWindows;

       PROCEDURE IngredientsWindowStaticText;
       PROCEDURE OrderWindowStaticText;

       PROCEDURE DisplaySIWindow;    {Special Instruction Window border }
       PROCEDURE DisplayHazardWindow;{hazard code window border }
       PROCEDURE DisplayOrderWindow; {order header }
       PROCEDURE DisplayIngredientWindow; {order and ingredient}
       FUNCTION  UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
      END;

VAR  MainWindow        : PMainWindow; { DONT BE FOOLED...
     The MainWindow is not the application's main window.
     Its the window that displays details about the current order.
     It gets newed and disposed on selecting an order from the scroller
     (I think TB).
}


PROCEDURE SetMainScreen;

IMPLEMENTATION
USES SFXScale,SFXTrans;

{-------------------------------------------------------------------------}
FUNCTION TStopProcessEdit.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR
   ScaleTask  : TScaleTaskState;
BEGIN
 StopScaleTasks(ScaleTask);
 UserActivateFunction := INHERITED UserActivateFunction(X,Y);
 RestoreScaletasks(ScaleTask);
END;
{-------------------------------------------------------------------------}


CONSTRUCTOR TMainWindow.Init(x1,y1,x2,y2,WinFlags : WORD);
BEGIN
(* LastIngredient := SPACE_STRING;*)
 DrawPending    := TRUE;
 SelChgPending  := FALSE;
 ShowingHeaderOnly  := FALSE;
 WindowFontSet  := FALSE;
 BatchBtn       := NIL;
 LotBtn         := NIL;
 ClearCurrentOrderDetails;

 INHERITED Init(X1,Y1,X2,Y2,C_WindowStaticText SHR 4,WinFlags);
 IngredientLotNumber := GlobalLotNumber;
 { show sister window: BatchBtn above main window }
 New(BatchBtn,Init(Win_Text_X,Header_Text_Y,Win_Text_X+11,StdEdit OR WT_SHADOW,
                   NIL,'Batch No :',et_string,6,SelRecs.SR_CurrentBatchNo));
 { show child window }
 New(LotBtn,  Init(Win_Text_X+38,SI_Text_Y,Win_Text_X+38+9,StdEdit OR WT_Shadow,@Self,'Lot No :',
                         et_string,8,IngredientLotNumber));
END;

PROCEDURE TMainWindow.ClearCurrentOrderDetails;
BEGIN
 LineMixWt       := 0;
 IngredientWtReq := 0.0;
 HighestWt       := 0.0;
 LowestWt        := 0.0;
 NumWeighings    := 0;
 WghsPerContainer:= 0;
 FillChar(IngRec, SizeOf(IngRec), 0);
 FillChar(MixStatRec, SizeOf(MixStatRec), 0);
END;


FUNCTION TMainWindow.PreWeighingSetup : BOOLEAN;
VAR
   SetupOk : BOOLEAN;
   ScaleTaskStatus : TScaleTaskState;
   ScaleWindowWasVisable : BOOLEAN;
   DiffOrder : BOOLEAN;
   BarcodeAcceptedByUser : BOOLEAN;
BEGIN
 SetupOk := NOT UserWantsToQuit;

 IF SetUpOK THEN
  BEGIN
   WITH SelRecs DO
    BEGIN
     DiffOrder := (WorkLRecord.WOL_OrderNo <> SR_LastSelOrdLine.WOL_OrderNo)
               OR (WorkLRecord.WOL_Revision<> SR_LastSelOrdLine.WOL_Revision);

     IF  (WorkHRecord.WOH_MixType = mt_CampaignWeighing)
     AND ScaleConfRec.UserIDRequired THEN { user ids reqd to start diff ingred }
      BEGIN
       IF DiffOrder
       OR (WorkLRecord.WOL_LineNo <> SR_LastSelOrdLine.WOL_LineNo) THEN
        BEGIN
         IF NOT UserLogin THEN
           SetupOk := FALSE;
        END;
      END
     ELSE { one mix at a time }
      BEGIN
       { has the current mix changed? }
       IF DiffOrder
       OR (WorkHRecord.WOH_CurrentMix <> SR_LastSelMixNo) THEN
        BEGIN
         IF ScaleConfRec.UserIDRequired THEN { user ids reqd to start a mix }
          BEGIN
           IF NOT UserLogin THEN
             SetupOk := FALSE;
          END;

         IF SetupOk THEN { should user scan mix labels? }
          BEGIN
           IF NOT SelRecs.ScanRelatedMixLabels THEN
            BEGIN
             SetupOk := FALSE;
             Disp_Error_Msg('Barcodes do match mix.');
            END;
          END;
        END;
      END;
    END;
  END;

 WITH SelRecs DO
  BEGIN
   IF  SetupOk
   AND (   LotNoNeedsEditing
        OR BatchNoNeedsEditing)
        OR ShouldUserBePromptedForLotBatch THEN
    BEGIN                                          { Manual Batch Numbering   }
     StopScaleTasks(ScaleTaskStatus);              { Save State of Scale Stuff}
     ScaleWindowWasVisable := ScaleWindow^.IsWindowVisable;
     ScaleWindow^.HideWindow;

     SelRecs.EditBatchAndLotNo; { Accept User Input   }
     RestoreScaleTasks(ScaleTaskStatus);
     IF ScaleWindowWasVisable THEN ScaleWindow^.ShowWindow;
    END;

   IF SetupOk THEN
     StoreIngredientLotNumber;

   SelRecs.ClearSourceBarcode;
   IF  SetupOk
   AND Config_Rec^.CONF_PromptForSource THEN
    BEGIN
     REPEAT
       BarcodeAcceptedByUser := TRUE;

       IF NOT SelRecs.GetASourceBarcode THEN { Get Fops6 Source Barcode  }
        BEGIN
         IF NOT Config_Rec^.CONF_SourceOptional THEN
           SetupOk := FALSE; { user wants to quit }
        END;

       IF  SetupOk
       AND (Length(Clip(SR_SourceBarcode)) = 20)
       AND (SR_SourceLifeDt > 0) THEN { transaction found - validate source }
        BEGIN
         { check max life on tran }
         IF (SR_SourceLifeDt < Date_To_Days(Date)) THEN
          BEGIN
           REPEAT
             IF YesNoWin('Product Life Date: '+ Days_To_DateS8(SR_SourceLifeDt)+CRLF+
                         'has expired.  Continue?') THEN
              BEGIN
               IF CurrentUser.USR_AccessLvl < 10 THEN
                BEGIN
                 Disp_Error_Msg('User with Access Level 10 required');
                 UserLogIn;
                 UserWindow^.Draw;
                END;
              END
             ELSE
               SetupOk := FALSE;
           UNTIL (NOT SetupOk)
              OR (CurrentUser.USR_AccessLvl >= 10);
          END;

{$IFDEF FOPSTRACELINK}
        { if source container weight is empty will need to login as a supervisor }
         IF SetupOk THEN
          BEGIN
           IF (CompareWts(SR_CurrSourceWtKg, 0.0) <= 0) THEN
            BEGIN
             REPEAT
               IF YesNoWin('Is source container: '+ Clip(SR_SourceBarcode)+CR+LF+
                           'empty?') THEN
                BEGIN
                 Disp_Error_Msg('Scan new source container barcode.');
                 SetupOk := FALSE;
                END
               ELSE
                BEGIN
                 IF CurrentUser.USR_AccessLvl < 10 THEN
                  BEGIN
                   Disp_Error_Msg('User with Access Level 10 required');
                   UserLogIn;
                   UserWindow^.Draw;
                  END;
                END;
             UNTIL (NOT SetupOk) { user admits it the wrong barcode }
                OR (CurrentUser.USR_AccessLvl >= 10);
            END
           ELSE IF CompareWts(LowestWt, SR_CurrSourceWtKg) > 0 THEN
             Disp_Error_Msg('Use Part Weigh button when source container is empty');
          END;
{$ENDIF}
        END; { validate transaction }

       IF  SetupOk
       AND Config_Rec^.CONF_AcceptLabelWeight
       AND (Length(Clip(SelRecs.SR_SourceBarcode)) = 20) THEN
        BEGIN
         IF WeightOkForTran(SelRecs.SR_CurrSourceWtKg,
                            SelRecs.SR_IngredientType,
                            MainWindow^.LowestWt, MainWindow^.HighestWt,
                            TRUE { treat like partial wt button (ignored by fix/step)}
                           ) THEN
           SelRecs.SR_UseSourceWt := TRUE
         ELSE IF YesNoWin(DoubleToStr(SelRecs.SR_CurrSourceWtKg,1,3)+
                                                'kg out of tolerance.'+CRLF+
                          'Try different source?') THEN
           BarcodeAcceptedByUser := FALSE; { loop round for another barcode }
        END;

     UNTIL BarcodeAcceptedByUser;
    END; { prompt for source }

{$IFDEF BUXTED} needs testing
   IF SetupOk THEN
     GetIngredCodeFromUser(CodeSelected : TIngredientRef);
{$ENDIF}
  END; { with SelRecs }

(*
 IF SetupOk THEN
  BEGIN
   IF SelRecs.WorkHRecord.WOH_MixType IN MixSet_DiffContEachWeighing THEN
    BEGIN
     FlashSemiAutoTare^.DisableTask;
     SemiAutoTare^.ResetTareAdjustment;
     {SemiAutoTare^.ChangeWindowFont(RecipeNormalFont); now a bitmap }
     {SemiAutoTare^.Paint; resettareadjustment does this }
    END;
  END;
*)
 { reset MAIN_LastSel... vars to match SelRecs to suppress the same input }
 SelRecs.SR_LastSelMixNo   := SelRecs.WorkHRecord.WOH_CurrentMix;
 SelRecs.SR_LastSelOrdLine := SelRecs.WorkLRecord;

 IF SetupOk THEN
   SelChgPending := FALSE;
 PreWeighingSetup := SetupOk;
END;

FUNCTION TMainWindow.GetCurrentContainerNo : LONGINT;
{ note: for segregated ingredients the container number
        starts from one for each ingredient.
        ie. there's multiple containers with the same number.
}
VAR ContsDone : LONGINT;
BEGIN
 ContsDone := 0;
 IF WghsPerContainer > 0 THEN { no divide by 0 problems }
   ContsDone := (MixLineDoneRec.ML_WghsDone DIV WghsPerContainer);
 GetCurrentContainerNo := ContsDone + 1;
END;

FUNCTION TMainWindow.GetContsReqdForIngredient : LONGINT;
BEGIN
 IF WghsPerContainer > 0 THEN
   GetContsReqdForIngredient := (NumWeighings DIV WghsPerContainer)
 ELSE
   GetContsReqdForIngredient := 0;
END;

FUNCTION TMainWindow.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR Ingredient : TIngredientRef;
    LIRec      : TLotIngredientRecord;
BEGIN
 UserActivateFunction := FALSE;
 IF {(BatchBtn^.IsPointInWindow(X,Y)) OR} ((LotBtn^.IsPointInWindow(X,Y))
 AND (NOT ShowingHeaderOnly)) THEN
  BEGIN
   ActivateIfInAChildWindow(X,Y);
   {BatchBtn^.Paint;}
   IF NOT ShowingHeaderOnly THEN LotBtn^.Paint;
   ScreenRedraw;
   IF  LotBtn^.IsPointInWindow(X,Y) THEN { save lot number entered }
    BEGIN
     IF NoIngredientSelected THEN { save it as the global lot number }
       GlobalLotNumber := IngredientLotNumber
     ELSE
       StoreIngredientLotNumber;
    END;
  END
 ELSE
  BEGIN
   SwitchWindows;
   Redraw;
  END;
END;

(*
PROCEDURE TMainWindow.SetLotNumber;
BEGIN
 LotBtn^.Paint;
END;
*)

PROCEDURE TMainWindow.DisplayIngredientWindow;
BEGIN
 DrawWindow(All_Win_Left,Ingr_Win_Top,All_Win_Right,Ingr_Win_Bottom,TRUE);
END;

PROCEDURE TMainWindow.DisplaySIWindow;
BEGIN
 DrawWindow(All_Win_Left,SI_Win_Top,SI_Win_Right,SI_Win_Bottom,TRUE);
END;

PROCEDURE TMainWindow.DisplayHazardWindow;
BEGIN
 DrawWindow(Haz_Win_Left,Haz_Win_Top,ALL_Win_Right,Haz_Win_Bottom,TRUE);
END;

PROCEDURE TMainWindow.DisplayOrderWindow;
BEGIN
 DrawWindow(All_Win_Left,Order_Win_Top,All_Win_Right,Order_Win_Bottom,TRUE);
END;

{Routines to write static window text}
PROCEDURE TMainWindow.IngredientsWindowStaticText;
VAR HoldFont  : PFontType;
    TitleStr  : STRING;
    TEMP      : BYTE;


  PROCEDURE WriteWinHeader(Str : STRING);
  VAR  HoldFont : PFontType;
       WriteStr : STRING[80];
       I : INTEGER;
       XPos,YPos : INTEGER;
  BEGIN
   HoldFont := SetCurrentFont(RecipeInverseFont);
   WriteStr := Centered(Str,(All_Win_Right - All_Win_Left) DIV 8);
   Xpos := All_Win_Left+2;
   Ypos := Ingr_Win_Top+2;
   FOR I:=1 TO Length(WriteStr) DO
    BEGIN
      WriteColourCharAt(XPos,YPos,WriteStr[I],C_WindowHeader SHR 4,
                                              C_WindowHeader AND $0F);
      {WriteCharAtPixel(XPos,YPos,WriteStr[I]);      }
      INC(XPos,CurrFontBitMap^.FontWidth*8);
    END;
   SetCurrentFont(HoldFont);
  END;


BEGIN
 HoldFont := SetCurrentFont(FontToUse);
 Temp := SetBackColour(C_WindowText SHR 4);
 DeleteWindow(All_Win_Left,Ingr_Win_Top,All_Win_Right,Ingr_Win_Bottom);
 DeleteWindow(All_Win_Left,SI_Win_Top,SI_Win_Right,SI_Win_Bottom);
 DeleteWindow(All_Win_Left,Haz_Win_Top,All_Win_Right,Haz_Win_Bottom);
 SetBackColour(Temp);

 Temp := SetTextColour(C_WindowStaticText);

 {Temp := TXTBackGround;
 TXTBackGround := $07;}

{ Recipe Code And Description                                       }
 WITH SelRecs.WorkHRecord DO
  BEGIN
   WriteWinHeader('Order '+
                                    IntToZeroStr(WOH_OrderNo,6)+'/'+
                                    IntToZeroStr(WOH_Revision,2)+'  '+
                                    WOH_RecipeNo+' '+
                                    GetRecipeName(WOH_RecipeNo));

  END;

 SetCurrentFont(DoubleHeightFont);
 WriteStrAt(Win_Text_X,Ingr_Text_Y+2,  'Ingredient:');
 WriteStrAt(Win_Text_X,Ingr_Text_Y+6,  'Container :');
 WriteStrAt(SmallIngredWinTitle2_X,Ingr_Text_Y+6,          'Requires:');

 SetCurrentFont(Font8x16);
 WriteStrAt(Win_Text_X,Ingr_Text_Y+10, 'Mix       :');
 WriteStrAt(SmallIngredWinTitle2_X,Ingr_Text_Y+10,         'Tol:');

(*

{ WriteStrAt(Win_Text_X,Ingr_Text_Y   ,'Recipe    :');}
 SetCurrentFont(Font8x16);
 WriteStrAt(Win_Text_X,Ingr_Text_Y+10,'Container :');
 WriteStrAt(Text_Column2+2,Ingr_Text_Y+10,'Completed:');

{ WriteStrAt(Win_Text_X,Ingr_Text_Y+9,'Container Wt :');
  WriteStrAt(Text_Column2-4,Ingr_Text_Y+7,'Cont''s Done  :');}
*)
 SetCurrentFont(FontToUse);


 DisplayIngredientWindow;
 WriteStrAtPixel(All_Win_Left+4+38*8,Haz_Win_Top,'Hazard Code : ');
 DisplaySIWindow;
 DisplayHazardWindow;

 SetTextColour(Temp);
 SetCurrentFont(HoldFont);
END;


PROCEDURE TMainWindow.OrderWindowStaticText;
VAR    HoldFont : PFontType;
       SaveCol  : BYTE;
BEGIN
 HoldFont := SetCurrentFont(FontToUse);
 SaveCol  := SetTextColour(C_WindowStaticText);

 WriteStrAt(Win_Text_X,Order_Text_Y,   'Work Order    :');
 WriteStrAt(Win_Text_X,Order_Text_Y+4, 'Recipe        :');
 WriteStrAt(Win_Text_X,Order_Text_Y+12,'Ord. Wt(Mixes):');
 WriteStrAt(Win_Text_X,Order_Text_Y+16,'Current Mix Wt:');

 WriteStrAt(Text_Column2,Order_Text_Y,  'Mix Type :');
 WriteStrAt(Text_Column2,Order_Text_Y+4,'Mix No   :');

 SetTextColour(SaveCol);
 SetCurrentFont(HoldFont);
 DisplayOrderWindow
END;


(*
PROCEDURE TMainWindow.ReReadSelHeader(VAR WorkHRecord : TWOHeaderRecord);
BEGIN
 IF WorkHeaderFile^.OpenFile = 0 THEN
  BEGIN
   WorkHeaderFile^.Get_WO_Header_Record(SelRecs.WorkHRecord.WOH_OrderNo,
                                       RecipeDay,
                                       SelRecs.WorkHRecord.WOH_Revision,
                                       WorkHRecord);
   WorkHRecord.WOH_CurrentMix := SelRecs.WorkHRecord.WOH_CurrentMix;
{  WorkHRecord.WOH_SchDate := RecipeDay;
   WorkHRecord.WOH_OrderNo := SelRecs.WorkHRecord.WOH_OrderNo;
   WorkHRecord.WOH_Revision:= SelRecs.WorkHRecord.WOH_Revision;
   WorkHeaderFile^.ReadRecord('EQ',FALSE,FALSE,WorkHRecord,0);}
   WorkHeaderFile^.CloseFile;
  END
 ELSE FillChar(WorkHRecord,SizeOf(WorkHRecord),#0);
END;
*)

PROCEDURE TMainWindow.ShowHeaderDetails;
VAR
   { WorkHRecord : TWOHeaderRecord;}
    ReadErr     : INTEGER;
    HoldFont    : PFontType;
    SaveCol     : BYTE;

BEGIN
 IF NOT ShowingHeaderOnly THEN EXIT;
 {ReReadSelHeader(WorkHRecord);}
 IF SelRecs.WorkHRecord.WOH_OrderNO <> 0 THEN
  BEGIN
   HoldFont :=  SetCurrentFont(FontToUse);
   SaveCol  :=  SetTextColour(C_WindowText);
   WITH SelRecs.WorkHRecord DO
    BEGIN
     WriteStrAt(TCol1,Order_Text_Y,OrderNoToStr(WOH_OrderNo,WOH_Revision));
     WriteStrAt(TCol1,Order_Text_Y+4,WOH_RecipeNo);
     WriteStrAt(TCol1,ORDER_TEXT_Y+8,GetRecipeName(WOH_RecipeNo));


     WriteStrAt(TCol1,Order_Text_Y+12, { order weight(mixes) done }
                DoubleToStr(WOH_WtDoneGross,9,3)+'Kg'+
                '('+IntToStr(WOH_MixDone,1)+')');

     WriteStrAt(Text_Column2,Order_Text_Y+12, { order weight (mixes) reqd }
                'of  '+ DoubleToStr(WOH_TotIngredWtReqd,5,3)+'Kg'+
      '('+IntToStr(WOH_NumMixes,1)+')');


     WriteStrAt(TCol1,Order_Text_Y+16, { current mix weight done }
                DoubleToStr(GetMixWtDoneOnCurrentMix(@SelRecs.WorkHRecord),9,3)+'Kg');
     WriteStrAt(Text_Column2,Order_Text_Y+16, { current mix wt required }
                'of  '+DoubleToStr(CalcCompensatedBatchMixWt(@SelRecs.WorkHRecord,
                                        SelRecs.WorkHRecord.WOH_CurrentMix),5,3)+'Kg');

     WriteStrAt(TCol2,Order_Text_y,' '+GetMixType(WOH_Mixtype));
     WriteStrAt(TCol2,Order_Text_y+4,' '+IntToStr(WOH_CurrentMix,1));
    END;
   SetTextColour(SaveCol);
   SetCurrentFont(HoldFont);
  END;
END;


PROCEDURE TMainWindow.ShowIngredientInformation;
VAR
    SaveColour  : BYTE;
    HoldFont    : PFontType;
BEGIN
 IF  (SelRecs.WorkHRecord.WOH_OrderNo <> 0)
 AND (NOT NoIngredientSelected) THEN
  BEGIN
   WITH SelRecs.WorkHRecord,SelRecs.WorkLRecord,IngRec DO
    BEGIN
      SaveColour := SetTextColour(C_WindowText);
      HoldFont := SetCurrentFont(DoubleHeightFont);           { Change Font       }

      WriteStrAt(SmallIngredWinData1_X,Ingr_Text_Y+2,
                 WOL_Ingredient+' '+ING_DESCRIPTION);

      WriteStrAt(SmallIngredWinData1_X,Ingr_Text_Y+6,
                 '('+DoubleToStr(WOL_ContainerSize,7,3)+'kg) '+
                 IntToStr(GetCurrentContainerNo, 3)+' of '+
                 LJustify(IntToStr(GetContsReqdForIngredient,3)));

      { NOTE: wghs per container is usually 1 even for fixed wt ingredients
        (see CalcIngredReqsForMixWt)
      }
      IF WghsPerContainer > 1 THEN { ' 2x    5.500kg' }
        { Ideally it should say Number x FixWt + Fraction for fixed weight
          ingredients - so advice not to use fractions of fixed weights
          in Even Distribution mixes. }
        WriteStrAt(SmallIngredWinTitle2_X+9,Ingr_Text_Y+6,
                   IntToStr(WghsPerContainer,2)+'x'+
                   DoubleToStr(IngredientWtReq,9,3)+'kg')
      ELSE                         { '    11.000kg' }
        WriteStrAt(SmallIngredWinTitle2_X+9,Ingr_Text_Y+6,
                   DoubleToStr(IngredientWtReq,10,3)+'kg');

      SetCurrentFont(Font8x16);
      WriteStrAt(SmallIngredWinData1_X,Ingr_Text_Y+10,
                 IntToStr(WOH_CurrentMix,4)+' of '+
                 LJustify(IntToStr(WOH_NumMixes,4)));

      WriteStrAt(SmallIngredWinTitle2_X+4,Ingr_Text_Y+10,
                 DoubleToStr(BarsWindow^.GetLoTolWeight,8,3)+
                 ' -'+ DoubleToStr(BarsWindow^.GetHiTolWeight,8,3));

      {Instructions to user                                               }
      SetCurrentFont(DoubleHeightFont);
      WriteStrAt(Win_Text_X+3,SI_Text_Y,WOL_SpecialInstr[1]);
      WriteStrAt(Win_Text_X+3,SI_Text_Y+4,WOL_SpecialInstr[2]);
      WriteStrAtPixel(All_Win_Left+4+52*8,Haz_Win_Top,ING_Hazard_Code);
      DisplayHazardWindow; { needed because hazard characers hit window border }

      SetTextColour(SaveColour);
      SetCurrentFont(HoldFont);                     { RESTORE WINDOW FONT }

      {ShowLotAndBatchNumbers;}
      {DisplayIngredientWindow;}
    END;
  END;
END;


PROCEDURE TMainWindow.SwitchWindows;
BEGIN
 ShowingHeaderOnly := NOT ShowingHeaderOnly;
 IF ShowingHeaderOnly THEN
   LotBtn^.HideWindow
 ELSE
   LotBtn^.WinType := LotBtn^.WinType OR WT_Visable;
END;


PROCEDURE TMainWindow.RefreshDetails(ActiveLineNo : LONGINT);
{REQUIRES SelRec.WorkHeader to be initialised.
 PROMISES 1. To read ActiveLineNo from file. Switches 'NoIngredientSelected'
             on if it cant.
          2. Resets filling bars for next weighing for ActiveLineNo.
          3. Sets 'DrawPending' flag so details are re-displayed in main prog loop
          4. If line no = 0 then default filling bars are displayed and
             ingredient details are not re-displayed.
}
VAR ReadErr         : INTEGER;

BEGIN
{ Disp_Error_Msg('IN RefeshDetails');}
 DrawPending  := TRUE; { bars need drawing etc }
 SelChgPending:= TRUE; { pre-weighing setup needs calling }

 { Best to reset current batch number here as batch number could be related
   to mix number which gets changed all over the place. }
 SelRecs.ResetCurrentBatchNo;
 SelRecs.ResetIngredientLotNo; { makes lot same as when ingredient last selected }

 ClearCurrentOrderDetails;
 NoIngredientSelected := TRUE;
 IF  (SelRecs.WorkHRecord.WOH_OrderNO <> 0)
 AND (ActiveLineNo <> 0) THEN
  BEGIN
   IF WorkLineFile^.OpenFile = 0 THEN
    BEGIN
     ReadErr := SelRecs.LoadLineRecord(ActiveLineNo);
     IF ReadErr = 0 THEN
      BEGIN
       NoIngredientSelected := FALSE;

       GetMixLineRecord(@SelRecs.WorkLRecord, SelRecs.WorkHRecord.WOH_CurrentMix,
                        MixLineDoneRec);

{      HoldFont := SetCurrentFont(FontToUse);}

       CalcIngredReqsForMixWt(CalcCompensatedBatchMixWt(@SelRecs.WorkHRecord,
                                                    SelRecs.WorkHRecord.WOH_CurrentMix),

                              @SelRecs.WorkHRecord,
                              @SelRecs.WorkLRecord,
                              MixLineDoneRec,
                              LineMixWt,
                              NumWeighings,
                              IngredientWtReq,
                              WghsPerContainer);


       WITH SelRecs.WorkHRecord,SelRecs.WorkLRecord,IngRec DO
        BEGIN
         IF IngredientFile^.GetIngredient(WOL_Ingredient,IngRec,FALSE) = 0 THEN
          BEGIN
           SelRecs.TareIngredient := NOT ING_NoTare;
          END
         ELSE
          BEGIN
           { Display "Ingredient Code", Ingredient Not Found }
           MessageWin.DisplayMsg(WOL_Ingredient+', '+ING_Description,TRUE);
           SelRecs.TareIngredient := TRUE;
          END;

         MixStatusFile^.GetMixStatRec(WOH_OrderNo, WOH_Revision, WOH_CurrentMix,
                                      MixStatRec, FALSE);

         {CalcIngredientTolWts(@IngRec,}
         CalcWOLineTolWts(@SelRecs.WorkLRecord,
                              IngredientWtReq,
                              WOH_MixType,
                              LineMixWt,
                              MixLineDoneRec.ML_WtDone,
                              LowestWt, HighestWt);

(*
         BarsWindow^.ResetTotBarClrMainBar(MixStatRec.MIX_WtRequired,
                                           MixStatRec.MIX_WtDone);

         BarsWindow^.ResetMainBarForIngred(IngredientWtReq,
                                           @SelRecs.WorkLRecord,
                                           @IngRec);
*)
        END;
{      SetCurrentFont(HoldFont);}
      END;
     WorkLineFile^.CloseFile;
    END;
  END;

 IF NoIngredientSelected THEN { only show total of current mix only }
  BEGIN
   WITH SelRecs.WorkHRecord DO
     MixStatusFile^.GetMixStatRec(WOH_OrderNo, WOH_Revision, WOH_CurrentMix,
                                  MixStatRec, FALSE);
(*
   BarsWindow^.ResetMainBarToDefault;
   BarsWindow^.ResetTotBarClrMainBar(MixStatRec.MIX_WtRequired,
                                     MixStatRec.MIX_WtDone);
*)
  END;

 IF ShowingHeaderOnly <> NoIngredientSelected THEN
   SwitchWindows;

(*
 ShowSelRecs;            { show current mix and ingredient now for user }
 IF NOT NoIngredientSelected THEN
   PreWeighingSetup;     { ask user for additional information }
 ShowLotAndBatchNumbers; { show rest of main window }
*)
 {Draw;}
{ Disp_Error_Msg('OUT RefeshDetails');}
END;

PROCEDURE TMainWindow.ShowLotAndBatchNumbers;
VAR  HoldFont  : PFontType;
BEGIN
 HoldFont :=  SetCurrentFont(FontToUse);
 IF BatchBtn<>NIL THEN BatchBtn^.Paint;
 IF NOT ShowingHeaderOnly THEN
  BEGIN
   IF LotBtn <> NIL THEN
    BEGIN
     LotBtn^.Paint;
    END;
  END;
 SetCurrentFont(HoldFont);
END;

PROCEDURE TMainWindow.ShowSelRecs;
BEGIN
 IF ShowingHeaderOnly THEN
  BEGIN
   OrderWindowStaticText;
   ShowHeaderDetails;
  END
 ELSE
  BEGIN
   IngredientsWindowStaticText;
   ShowIngredientInformation;
  END;
END;

PROCEDURE TMainWindow.Draw;
{ dont forget - this can be called by losing a window drawn on top of this one}
BEGIN
{ Disp_Error_Msg('IN Draw');}
 IF NOT WindowFontSet THEN
  BEGIN
   WindowFontSet := TRUE;
   ChangeWindowFont(DoubleHeightFont);
  END;

 ClearWindow;

 ShowLotAndBatchNumbers;

 IF DrawPending THEN { details have changed - redraw bars }
  BEGIN
   BarsWindow^.ResetTotBar(MixStatRec.MIX_WtRequired,
                           MixStatRec.MIX_WtDone);
   IF NoIngredientSelected THEN { show total of current mix only }
    BEGIN
     BarsWindow^.ResetMainBarToDefault;
    END
   ELSE
    BEGIN
     BarsWindow^.ResetMainBarForIngred(IngredientWtReq,
                                       LowestWt,
                                       HighestWt,
                                       @SelRecs.WorkLRecord,
                                       @IngRec);
    END;
   BarsWindow^.ClearMainBar; { will refresh tots bar }
  END;

 ShowSelRecs; { current order header and line (and BarsWindow tolerances) }
 DrawPending := FALSE;
{ Disp_Error_Msg('OUT Draw');}
END;


PROCEDURE SetMainScreen;
BEGIN
{ Disp_Error_Msg('IN SetMainScreen');}
 NEW(BarsWindow,Init(Bar2_X1,Bar1_Y1,Bar1_X2+24,Bar2_Y2));
{ Disp_Error_Msg('OUT SetMainScreen');}
{ Disp_Error_Msg('half way through SetMainScreen');}
 NEW(MainWindow,Init(All_Win_Left,Order_Win_Top,All_Win_Right,SI_Win_Bottom,WT_Visable OR WT_Shadow));
END;

END.

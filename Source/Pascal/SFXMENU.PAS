(****************************************************************************
*  UNIT          : SFXMenu                                                  *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Windows That Are Not Standard               *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXMenu;
INTERFACE
USES SFXWin,SFXGraph,SFXBtn,SFXMsg,SFXScale,SFXEdit,SFXDate,
     F6StdCtv,F6StdUtl,F6StdWn1,
     FXFWORK,FXFINGR,FXFMIX,FXCHOICE,FXMODCTV,SFXFONT,SFXTRANS,SFXTIKET,
     SFXCONST,SFXCOMMS,SFXKBD,SFXSTD,SFXUTILS,SFXMIXES,SFXCurr,SFXLIST,
     SFXTLIST,SFX_BARS,FXDetail;

CONST AM_EXITMENU      = 1;
      AM_MANUALWEIGHT  = 2;
      AM_MANUALTARE    = 3;
      AM_SWITCHSCALE   = 4;
      AM_VIEWMIXES     = 5;
      AM_DELAYCURRMIX  = 6;
      AM_ABORTCURRMIX  = 7;
      AM_CHANGEMIXTYPE = 8;
      AM_PRINTMIXTICKET= 9;
      AM_ALLMIXTICKETS = 10;
{      AM_STOCKITEMWEIGHT=11;}

TYPE PAdvancedOptionsMenu = ^TAdvancedOptionsMenu;
     TAdvancedOptionsMenu = OBJECT(TMenuWindow)
       PROCEDURE SetUpChildWindows;VIRTUAL;
     END;

TYPE PAdvancedOptions = ^TAdvancedOptions;
     TAdvancedOptions = OBJECT(TPCXButton)
      FUNCTION  UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
{      PROCEDURE Draw; VIRTUAL;}
      PROCEDURE GetWeight(VAR Wt : DOUBLE;WeightForTare : BOOLEAN);
     END;


VAR AdvancedOptionsMenu : PAdvancedOptionsMenu;
VAR AdvOptWin           : PAdvancedOptions;

IMPLEMENTATION
USES SFXCOLR;

PROCEDURE SwitchScale;
VAR CB : PChoiceBtn;
BEGIN
{$IFNDEF NOCOMMS}
 SwitchToScale(3-ReadingScale);                { Switch To Alternate Scale }
 CB := AdvancedOptionsMenu^.GetChildWindow(AM_SWITCHSCALE); { Get Ptr To Switch Button  }
 IF CB<>NIL THEN
  BEGIN                                        { Change Button Text        }
   CB^.SetText('Switch To '+CRLF+'Scale '+IntToStr(3-ReadingScale,1));
  END;
 ClrGraphWin;                                  { ClearScreen               }
 ScaleWindow^.ClearScaleTareWt;
{$ENDIF}
END;

PROCEDURE ChangeOrderMixingMethod;
VAR RadioButtonGroup : PRadioButtonGroup;
    I : TMixType;
    C : PChoiceBtn;
    Result : TMixType;
BEGIN
 New(RadioButtonGroup,Init(0,0,630,350,C_BackGround,WT_Visable));
 FOR I:= TMixType(0) TO LastMixType DO
  BEGIN
   RadioButtonGroup^.AddRadioEdit(1,1+((ORD(I)+1)*5),60,MixTypeListItems[i],
                                  I=(SelRecs.WorkHRecord.WOH_MixType));
  END;

 WITH RadioButtonGroup^.Bounds DO
  BEGIN
   New(C,Init(Left+16,            Bottom-ChildHeight,RadioButtonGroup,idSave+100,SaveStr,TRUE));
   New(C,Init(Right-16-ChildWidth,Bottom-ChildHeight,RadioButtonGroup,idAbort+100,AbortStr,TRUE));
  END;

 REPEAT
  Wait_For_User_Input;
 UNTIL (RadioButtonGroup^.ChildMessage > 100);

 Result := TMixType(0);
 FOR I:= TMixType(0) TO LastMixType DO
  BEGIN
   IF (RadioButtonGroup^.ResultButton^.ShowText = MixTypeListItems[i]) THEN
    Result := I;
  END;

 IF (RadioButtonGroup^.ChildMessage = (idSave+100)) THEN
  BEGIN
   SelRecs.ChangeMixTypeOfOrder(TMixType(Result));
  END;

 Dispose(RadioButtonGroup,Done);
END;


FUNCTION DisplayMixDetails(OrderNo : LONGINT;Revision : BYTE) : INTEGER;
VAR MixStatus : TMixStatusRecord;
    I         : INTEGER;
    Ch1       : CHAR;
    HoldFont  : PFontType;
    X         : INTEGER;
    MixSel    : PScreenWithKeyboard;
    Edit      : PEdit;
    Choice,
    ChoiceAdv,
    ChoiceDec : PChoiceBtn;
    RetToMix  : INTEGER;
    Advance,
    decrement : BOOLEAN;
    ListHeader: INTEGER;
    SaveMsgWinState : TMsgWinState;

    PROCEDURE DisplayMixesFromMix(MixNo : INTEGER);
    VAR X,Y : INTEGER;
    BEGIN
     Y := 4;
     X := 1;
     ListHeader:= MixNo;
     Decrement := MixNo <> 1;
     Advance   := FALSE;
     WriteStrAt(1,1,'Mix   Wt Req   Wt Done Cmp Mix   Wt Req   Wt Done Cmp');
     MixStatusFile^.InitRecord(MixStatus);
     MixStatus.MIX_OrderNo  := OrderNo;
     MixStatus.MIX_Revision := Revision;
     MixStatus.MIX_No       := MixNo;
     MixStatusFile^.ReadRecord('EQ',FALSE,FALSE,MixStatus,0);
     WHILE (MixStatusFile^.BtrvErr = 0) AND (MixStatus.MIX_OrderNo  = OrderNo) AND
      (MixStatus.MIX_Revision = Revision) DO
      BEGIN
       WITH MixStatus DO
        BEGIN
         WriteStrAT(X,Y,IntToStr(Mix_No,2)+' '+DoubleToStr(MIX_WtRequired,9,3)+' '+DoubleToStr(MIX_WtDone,9,3)+' '
                            +BoolToYNStr(MIX_Complete,3));
         INC(Y,2);
         IF Y>36 THEN
          BEGIN
           Y:= 4;
           INC(X,27);
           IF X>54 THEN
            BEGIN
             Advance := (MixstatusFile^.ReadRecord('GN',FALSE,FALSE,MixStatus,0) = 0) AND
                     (MixStatus.MIX_OrderNo  = OrderNo) AND (MixStatus.MIX_Revision = Revision);

             EXIT;
            END;
          END;
        END;
       MixstatusFile^.ReadRecord('GN',FALSE,FALSE,MixStatus,0);
      END;
     WHILE TRUE DO
      BEGIN
       WriteStrAT(X,Y,'                          ');
       INC(Y,2);
       IF Y>36 THEN
        BEGIN
         Y:= 4;
         INC(X,27);
         IF X>54 THEN EXIT;
        END;
      END;
    END;

    PROCEDURE DisplaySingleMixDetails;
    VAR Filter    : TBuildFilter;
        TRNList   : PTRNList;
        TRNLoop   : PTRNList;
        YCo       : INTEGER;

        ListBox : PListBox;
        ListItem: PListItem;

    BEGIN
     MixSel^.HideWindow;
     ClrGraphWin;

     MixStatusFile^.InitRecord(MixStatus);
     MixStatus.MIX_OrderNo  := OrderNo;
     MixStatus.MIX_Revision := Revision;
     MixStatus.MIX_No       := RetToMix;
     MixStatusFile^.ReadRecord('EQ',FALSE,FALSE,MixStatus,0);

     FillChar(Filter,Sizeof(Filter),0);
     Filter.WorkNo   := OrderNo;
     {Needs To Be +1 As Revision Ranges from 0 to 99. Where As Search
      uses 1 to 100, as 0 means filter element not set}
     Filter.Revision := Revision+1;
     Filter.MixNo    := RetToMix;

     TRNList := BuildTransactionListForMix(Filter);
     TRNLoop := TRNList;
     YCo     := 0;

     New(ListBox,Init(72,BOX_SORT));

     WHILE (TRNLoop <> NIL) DO
      BEGIN
       New(ListItem,Init(TRNLoop^.Ingredient+'  '+COPY(GetIngredientDesc(TRNLoop^.Ingredient),1,30)+
                         IntToStr(TRNLoop^.ContsDone,4)+'  '+
                         DoubleToStr(TRNLoop^.WeightDone,9,2)));
       ListBox^.AddItem(ListItem);
       TRNLoop := TRNLoop^.Next;
      END;

     ListBox^.Draw;
     ListBox^.WaitForAccept;
     Dispose(ListBox,Done);
     ClrGraphWin;
     MixSel^.ShowWindow;
     DisplayMixesFromMix(ListHeader);
    END;


BEGIN
 MessageWin.DisableMsgs(@SaveMsgWinState);
 DisplayMixDetails := 0;
 RetToMix := 0;
 New(MixSel,Init);
 HoldFont := SetCurrentFont(RecipeNormalFont);
 New(Edit,init(57,1,68,StdEdit,MixSel,'Mix no :',et_integer,4,RetToMix));
 WITH MixSel^.Bounds DO
  BEGIN
   New(Choice,   Init(Right-(6+ChildWidth)*2,KbdYOffset-5-ChildHeight,     MixSel,1,'Goto Mix',FALSE));
   New(Choice,   Init(Right-(6+ChildWidth),  KbdYOffset-5-ChildHeight,     MixSel,2,'Exit',FALSE));
   New(ChoiceAdv,init(Right-(6+ChildWidth),  KbdYOffset-5-ChildHeight*2-16,MixSel,3,'Adv List',FALSE));
   New(ChoiceDec,Init(Right-(6+ChildWidth)*2,KbdYOffset-5-ChildHeight*2-16,MixSel,4,'Dec List',FALSE));
   New(Choice,   Init(Right-(6+ChildWidth),  KbdYOffset-5-ChildHeight*3-32,MixSel,5,'View Mix '+CRLF+'Details',FALSE));
  END;
 DisplayMixesFromMix(1);
 REPEAT
  IF Advance   THEN ChoiceAdv^.EnableButton
  ELSE              ChoiceAdv^.DisableButton;
  IF Decrement THEN ChoiceDec^.EnableButton
  ELSE              ChoiceDec^.DisableButton;
{
  ChoiceAdv^.DisableBtn(NOT Advance);
  ChoiceDec^.DisableBtn(NOT Decrement);
}
  MixSel^.MainLoop;
  CASE MixSel^.OptionSelected OF
   1,2 : BREAK;
   3   : IF Advance   THEN DisplayMixesFromMix(ListHeader+17);
   4   : IF Decrement THEN DisplayMixesFromMix(ListHeader-17);
   5   : IF (RetToMix <> 0) THEN DisplaySingleMixDetails;
  END;
(* ReturnLastMousePress := FALSE;*)
 UNTIL FALSE;
 IF MixSel^.OptionSelected = 1 THEN
  BEGIN
   DisplayMixDetails := RetToMix;
  END;
 Dispose(MixSel,Done);
 ClrGraphWin;
 SetCurrentFont(HoldFont);
 MessageWin.RestoreMsgState(@SaveMsgWinState);
END;

{===========================================================================}
{===================== ADVANCED OPTIONS ====================================}
PROCEDURE TAdvancedOptionsMenu.SetUpChildWindows;
BEGIN
 WITH Bounds DO
  BEGIN
   AddChildWindow(1,1,AM_MANUALTARE    ,'Enter'+CRLF+'Manual'+CRLF+'Tare Wt');
   AddChildWindow(1,2,AM_MANUALWEIGHT  ,'Manual'+CRLF+'Weight');
{   AddChildWindow(1,3,AM_STOCKITEMWEIGHT,'Add Stock'+CRLF+'Item Weight');}
   IF ScaleHardware[2].SH_Available THEN
     AddChildWindow(1,4,AM_SWITCHSCALE  ,'Switch To '+CRLF+'Scale '+IntToStr(3-ReadingScale,1));
   AddChildWindow(2,1,AM_VIEWMIXES     ,'View Mix/'+CRLF+'Change'+CRLF+' Mix No ');
   AddChildWindow(2,2,AM_CHANGEMIXTYPE ,'Change '+CRLF+'Mix'+CRLF+'Type');
   AddChildWindow(2,3,AM_DELAYCURRMIX  ,'Delay '+CRLF+'Current'+CRLF+'Mix');
   IF GetMixWtDoneOnCurrentMix(@SelRecs.WorkHRecord) > 0.0 THEN
     AddChildWindow(2,4,AM_ABORTCURRMIX  ,'Abort '+CRLF+'Current'+CRLF+'Mix');
   AddChildWindow(3,1,AM_PRINTMIXTICKET,'Print'+CRLF+' Mix'+CRLF+'Ticket');
   AddChildWindow(3,2,AM_ALLMIXTICKETS ,'Print'+CRLF+'All Mix'+CRLF+'Tickets');
   AddChildWindow(3,4,AM_EXITMENU      ,'Exit'+CRLF+'Menu');
  END;
END;

{==========================================================}
{================= ADVANCED OPTION METHODS ================}
{==========================================================}

PROCEDURE TAdvancedOptions.GetWeight(VAR Wt : DOUBLE;WeightForTare : BOOLEAN);
BEGIN
 IF WeightForTare THEN
  BEGIN
   ReadFloat(Wt,10,10,'Enter Manual Tare :');
  END
 ELSE
  BEGIN
   ReadFloat(Wt,10,10,'Enter Manual Wt :');
  END;
END;

FUNCTION TAdvancedOptions.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
 {Advanced menu options like :-
   enter manual weight
   enter manual tare

   user specific functions
}
VAR
   END_MainLoop : BOOLEAN;
   Option       : INTEGER;
   OldList      : PSFWindow;
   Wt           : DOUBLE;
   RetToMix     : INTEGER;
   ScaleTask    : TScaleTaskState;
   SaveMsgWinState : TMsgWinState;
   TargetWt,
   HighestWt,
   LowestWt     : DOUBLE;

   PROCEDURE SetTargetLowestHighestWts;
   VAR
      LineMixWt    : DOUBLE;
      NumContainers,
      WghsPerCont  : LONGINT;
      WtForContainer : DOUBLE;
      {Ingredient   : TIngredient_Record;}
      DoneSoFarRec : TMixLineRecord;
   BEGIN
    { calc weight expected }
    GetMixLineRecord(@SelRecs.WorkLRecord, SelRecs.WorkHRecord.WOH_CurrentMix,
                     DoneSoFarRec);

    CalcIngredReqsForMixWt({SelRecs.WorkHRecord.WOH_TargetBatchWt,}
                           CalcCompensatedBatchMixWt(@SelRecs.WorkHRecord,
                                                     SelRecs.WorkHRecord.WOH_CurrentMix),
                           @SelRecs.WorkHRecord,
                           @SelRecs.WorkLRecord,
                           DoneSoFarRec,
                           LineMixWt,
                           NumContainers,
                           TargetWt,
                           WghsPerCont);
    HighestWt := 0.0;
    LowestWt  := 0.0;
    CalcWOLineTolWts(@SelRecs.WorkLRecord,
                           TargetWt,
                           SelRecs.WorkHRecord.WOH_mixType,
                           LineMixWt,
                           DoneSoFarRec.ML_WtDone,
                           LowestWt, HighestWt);
   END;



BEGIN
 StopScaleTasks(ScaleTask);
{ FlashSemiAutoTare^.AutoStop; }
 RetToMix := 0;
 ScaleWindow^.HideWindow;
 UserWindow^.HideWindow;
 MessageWin.EnableAtTopOfScreen(@SaveMsgWinState);
 ClrGraphWin;
 END_MainLoop := FALSE;
 OldList := SetWindowList(NIL);
 New(AdvancedOptionsMenu,Init);
 SetWindowList(AdvancedOptionsMenu);
 REPEAT
  Option := AdvancedOptionsMenu^.GetOptionSelected;
  CASE Option OF
   AM_EXITMENU : END_MainLoop := TRUE;           { EXIT MENU                }

   AM_MANUALWEIGHT                               { ENTER MANUAL WEIGHT      }
(* AM_STOCKITEMWEIGHT    { SCAN FOPS6 TRAN          } *)
                      : BEGIN
     IF NoIngredientSelected THEN
       Disp_Error_Msg('Select ingredient first.')
     ELSE IF SelRecs.SR_IngredientType = PTStep THEN
       Disp_Error_Msg('Current ingredient is a step operation.')
     ELSE IF (Option = AM_MANUALWEIGHT) AND (NOT GetManWtTickBox) THEN
       Disp_Error_Msg('Manual Weight option is disabled')
     ELSE
       END_MainLoop := TRUE;   { SET EXIT MENU FLAG       }
   END;

   AM_MANUALTARE : BEGIN                         { ENTER MANUAL TARE        }
     Wt := 0.0;
     GetWeight(Wt,TRUE);                         { ACCEPT WEIGHT FROM USER  }
     ScaleWindow^.SetScaleTareWt(Wt);            { SET CURRENT TARE         }
(*
     SemiAutoTare^.DisableButton;                { DISABLE SEMI AUTO BUTTON }
     TareNotSet := FALSE;                        { CLEAR NO TARE FLAG       }
     GetTareWt^.DisableTask;                     { DISABLE TARE BACK TASK   }
*)
   END;

   AM_SWITCHSCALE : BEGIN                        { CHANGE CURR SCALE HEAD   }
     SwitchScale;                                { SWITCH TO ALTERNATE SCALE}
     ScaleWindow^.HideWindow;                    { HIDE WEIGHT DISPLAY      }
   END;

   AM_VIEWMIXES : BEGIN                          { DISPLAY MIX DETAILS      }
     RetToMix := DisplayMixDetails(SelRecs.WorkHRecord.WOH_OrderNo,
                                   SelRecs.WorkHRecord.WOH_Revision);
     IF RetToMix <> 0 THEN END_MainLoop := TRUE;
   END;

   AM_DELAYCURRMIX : BEGIN                       { DELAY CURRENT MIX        }
     DelayCurrentMix;
     END_MainLoop:=TRUE;
   END;

   AM_ABORTCURRMIX : BEGIN
     AbortCurrentMixButtonHit;
   END;

   AM_CHANGEMIXTYPE : BEGIN                      { CHANGE MIX METHOD        }
     ChangeOrderMixingMethod;
   END;

   AM_PRINTMIXTICKET : BEGIN                     { PRINT MIX TICKET         }
     Print_Partial_Mix_Ticket(1);
   END;

   AM_ALLMIXTICKETS : BEGIN
     PrintAllMixTickets{(@SelRecs.WorkHRecord,
                        (ScaleConfRec.PrinterType <> UBI_Printer))};
   END;
  END;
 UNTIL END_MainLoop;
 Dispose(AdvancedOptionsMenu,Done);
 SetWindowList(OldList);
 MessageWin.RestoreMsgState(@SaveMsgWinState);
 ScreenRedraw;
 ScaleWindow^.ShowWindow;
 UserWindow^.Showwindow;
{ FlashSemiAutoTare^.AutoStart;}
{ RestoreScaleTasks(ScaleTask);}
 IF (Option = AM_MANUALWEIGHT) THEN
  BEGIN
   SetTargetLowestHighestWts;
   Wt := TargetWt;
   GetWeight(Wt, FALSE);
   IF WeightOkForTran(Wt, SelRecs.SR_IngredientType,
                      LowestWt, HighestWt, FALSE) THEN
    BEGIN
     IF YesNoWin('   Add '+DoubleToStr(Wt,1,3)+'kg to container'+CRLF+
                 '   weight.  Are you sure? (Y/N)') THEN
       CreateTransaction(Wt,{FALSE,}SelRecs.WorkLRecord.WOL_ProcessType,TRUE);
    END
   ELSE
     Disp_Error_Msg(DoubleToStr(Wt,1,3)+ 'kg out of tolerance');
  END
(*
 ELSE IF Option = AM_STOCKITEMWEIGHT THEN
  BEGIN
   SetTargetLowestHighestWts;
   IF SelRecs.GetASourceBarcode THEN
    BEGIN
     IF WeightOkForTran(SelRecs.SR_CurrSourceWtKg,
                        SelRecs.SR_IngredientType,
                        LowestWt, HighestWt,
                        TRUE { treat like partial wt button (ignored by fix/step)}
                       ) THEN
      BEGIN
       IF YesNoWin(' Add stock item weight of '+
                   DoubleToStr(SelRecs.SR_CurrSourceWtKg,1,3)+'kg to'+CRLF+
                   ' container weight.  Are you sure? (Y/N)') THEN
         CreateTransaction(SelRecs.SR_CurrSourceWtKg,{FALSE,}SelRecs.WorkLRecord.WOL_ProcessType,TRUE);
      END
     ELSE
       Disp_Error_Msg(DoubleToStr(SelRecs.SR_CurrSourceWtKg,1,3)+ 'kg out of tolerance');
    END;
  END
*)
 ELSE IF RetToMix <> 0 THEN ReturnToMix(RetToMix);

 RestoreScaleTasks(ScaleTask);

 UserActivateFunction :=  (BarsWindow^.OrderComplete <> 0)
                       OR (RetToMix <> 0); { so mainWindow is redrawn }
END;

{
PROCEDURE TAdvancedOptions.Draw;
BEGIN
 DisplayText(1,'Options...');
END;
}
END.
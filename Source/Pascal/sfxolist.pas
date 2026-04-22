(****************************************************************************
*  UNIT          : FXFRCP                                                   *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Routines To Create A List Of Order Details  *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
{$C FIXED PRELOAD PERMANENT}

{$IFnDEF TERMINAL} not required {$ENDIF}
UNIT SFXOList;

{This Unit Will Display Orders and Recipe Details
 In The Scrolling Window Provided}
INTERFACE
USES F6StdCtv,FXMODCTV,F6DTConv,F6StdUtl,SFXGraph,SFXStd,FXFWork,FXFRCP,FXFINGR,
     SFXConst,SFX_Pro,SFXBtn,SFXDate,FXCfg,F6StdWn1,FXDetail;

TYPE
     PListDisplayRec = ^TListDisplayRec;
     TListDisplayRec = PACKED RECORD
      TextToDisplay : ARRAY[0..4] OF STRING[18];
      Order_Line_No : LONGINT;
      Ingredient    : TIngredientRef;
      LDR_ThisArea  : BOOLEAN;
      Revision      : BYTE;
      Complete      : BOOLEAN;
      Next          : PListDisplayRec;
     END;


TYPE
    PTimedOrderRefresh = ^TTimedOrderRefresh;
    TTimedOrderRefresh = OBJECT(TBackGroundTask)
      RefreshTime,RefreshCount : LONGINT;
      CONSTRUCTOR Init;
      DESTRUCTOR  Done; VIRTUAL;
      PROCEDURE   Execute; VIRTUAL;
    END;

TYPE  PDateAreas=^TDateAreas;
      TDateAreas=OBJECT(TPCXButton)
         DateAdj       : INTEGER;
         CONSTRUCTOR Init(X1,y1,x2,y2:INTEGER;Dir : BOOLEAN;PcxFile : PCXNameStr);
         DESTRUCTOR  Done;VIRTUAL;
         FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
(*         PROCEDURE   Draw;VIRTUAL;*)
      END;




FUNCTION  GetListItem(OrderOrLineNumber : INTEGER) : PListDisplayRec;
PROCEDURE DisposeListRec;
PROCEDURE AddPointerToList(NewElement : PListDisplayRec);
PROCEDURE AddWOHeaderRecordToList(VAR WorkHRec : TWOHeaderRecord);
PROCEDURE RefreshListItemForSelOrder(VAR Item : TListDisplayRec);
{PROCEDURE AddWOLineRecordToList(VAR WorkLRec : TWOLineRecord);}
PROCEDURE Build_Days_Recipe_List(TheDay : LONGINT);
PROCEDURE BuildLineRecipeList(WorkOHeader : PWOHeaderRecord;
                              RestorePos : BOOLEAN);
PROCEDURE Display_Recipes_For_Date(MaintainCurrScrollPos : BOOLEAN);
FUNCTION  SelectableElementsInList : LONGINT;
FUNCTION  CanDoIngredientNow(LineNo : LONGINT) : BOOLEAN;
PROCEDURE OrderListInit;
PROCEDURE OListInit;



VAR
   {Linked List Start of Records shown in lookup}
   ListHeader         : PListDisplayRec;
   TimedOrderRefresh  : PTimedOrderRefresh;
   DateBack           : PDateAreas;
   DateForward        : PDateAreas;


IMPLEMENTATION
USES SFX_Scrl,SFXStdBt,SFXCurr;


PROCEDURE AllocateDisplayRec(VAR NewRec : PListDisplayRec);
VAR I : INTEGER;
BEGIN
 New(NewRec);
 FOR I := 0 TO 4 DO
  BEGIN
   NewRec^.TextToDisplay[i] := SPACE_STRING;
  END;
 NewRec^.Order_Line_No := 0;
 NewRec^.Ingredient    := '';
 NewRec^.Revision      := 0;
 NewRec^.Complete      := FALSE;
 NewRec^.LDR_ThisArea  := TRUE;
 NewRec^.Next          := NIL;
END;


PROCEDURE DisposeListRec;
VAR P,Q : PListDisplayRec;
BEGIN
 P := ListHeader;
 WHILE (P<>NIL) DO
  BEGIN
   Q:=P;
   P:=P^.Next;
   Dispose(Q);
  END;
 ListHeader := NIL;
 DisplayRecListSize   := 0;
{ DisplayRecListPos    := 0;}
END;

PROCEDURE OrderListInit;
BEGIN
 DisposeListRec;
{ WORecordSelected  := 0;}
 SelRecs.SetUp;
 DisplayRecListpos := 0;
END;

PROCEDURE AddPointerToList(NewElement : PListDisplayRec);
VAR
    P,Q        : PListDisplayRec;
    AddHere    : BOOLEAN;
BEGIN
 INC(DisplayRecListSize);
 IF ListHeader = NIL THEN
  BEGIN
   ListHeader := NewElement;
   EXIT;
  END;
 P:= ListHeader;
 Q:= NIL;
 WHILE (P<>NIL) DO
  BEGIN
   AddHere :=P^.Order_Line_No > NewElement^.Order_Line_No;
   IF AddHere THEN
    BEGIN
     IF Q=NIL THEN                 {Q NIL So Add To Front Of List}
      BEGIN
       NewElement^.Next := ListHeader;
       ListHeader := NewElement;   {List Header Is New Element}
       EXIT;
      END
     ELSE                         {Insert In List Here}
      BEGIN
       NewElement^.Next := P;     {Goes Before P}
       Q^.Next  := NewElement;    {But After Q}
       EXIT;                      {Exit Function}
      END;
    END;
   Q:=P;
   P:=P^.Next;
  END;
 {If Get To Here P = NIL and New element must be added to end of list}
 {q= last element in list}
 Q^.Next := NewElement;
END;

PROCEDURE AddWOHeaderRecordToList(VAR WorkHRec : TWOHeaderRecord);
VAR NewElement : PListDisplayRec;
BEGIN
 AllocateDisplayRec(NewElement);
 WITH NewElement^,WorkHRec DO
  BEGIN
(*
   TextToDisplay[0] := OrderNoToStr(WOH_OrderNo,WOH_Revision)+' '+WOH_RecipeNo;
   TextToDisplay[1] := GetRecipeName(WOH_RecipeNo);
   TextToDisplay[2] := '';

   TextToDisplay[3] := 'Mixes:'+ IntToStr(WOH_MixDone,5)+'/'+IntToStr(WOH_NumMixes,1);
   TextToDisplay[4] := 'Wt.:'+DoubleToStr(WOH_WtDoneGross,7,2)+'/'+DoubleToStr(WOH_TotIngredWtReqd,4,2);
*)
   TextToDisplay[0] := OrderNoToStr(WOH_OrderNo,WOH_Revision)+' '+WOH_RecipeNo;
   TextToDisplay[1] := GetRecipeName(WOH_RecipeNo);
   TextToDisplay[2] := '';

   TextToDisplay[3] := IntToStr(WOH_MixDone,5)+'/'+IntToStr(WOH_NumMixes,1);
   TextToDisplay[4] := DoubleToStr(WOH_WtDoneGross,7,2)+'/'+DoubleToStr(WOH_TotIngredWtReqd,1,2);

   Order_Line_No    := WOH_OrderNo;
   Revision         := WOH_Revision;
   Complete         := (WOH_Status = StatusCOMP);
   Next             := NIL;
  END;
 AddPointerToList(NewElement);
END;

PROCEDURE UpdateListItemForWOLine(VAR Item         : TListDisplayRec;
                                  RelatedWOHeadRec : PWOHeaderrecord;
                                  RelatedWOLineRec : PWOLineRecord);
VAR
   MixLRec    : TMixLineRecord;

BEGIN
 GetMixLineRecord(RelatedWOLineRec, RelatedWOHeadRec^.WOH_CurrentMix, MixLRec);

 Item.Complete := IsThisLineCompleteForCurrMix(RelatedWOHeadRec,
                                               RelatedWOLineRec,
                                               MixLRec.ML_WghsDone,
                                               MixLRec.ML_WtDone);

 IF Item.Complete THEN
   Item.TextToDisplay[2] := ' C O M P L E T E'
 ELSE
   Item.TextToDisplay[2] := '';
 { make sure right mix number is displayed and wt remaining }
 Item.TextToDisplay[3] := 'Mix No.: '+
                          IntToStr(RelatedWOHeadRec^.WOH_CurrentMix,1);

 IF RelatedWOLineRec^.WOL_KeyIngredient THEN
   Item.TextToDisplay[3] := Item.TextToDisplay[3] + ' Key Ingred.'
 ELSE
   Item.TextToDisplay[3] := Item.TextToDisplay[3] +  SPACE_STRING;


 Item.TextToDisplay[4] := 'Wt. Rem: '+
              DoubleToStr(CalcLineGrossWtReqdForCurrMix(RelatedWOHeadRec,
                                                        RelatedWOLineRec)
                          -MixLRec.ML_WtDone,
                          9,3);

END;


PROCEDURE RefreshListItemForSelOrder(VAR Item : TListDisplayRec);
VAR
 TempWOLineRec : TWOLineRecord;
BEGIN
 WITH SelRecs.WorkHRecord DO
  BEGIN
   WorkLineFile^.Get_WO_Line_Record(WOH_OrderNo,
                                    WOH_Revision,
                                    Item.Order_Line_No,
                                    TempWOLineRec);
  END;
 UpdateListItemForWOLine(Item,
                         @SelRecs.WorkHRecord,
                         @TempWOLineRec);
END;


PROCEDURE AddWOLineRecordToList(OrdHeader    : PWOHeaderRecord;
                                VAR WorkLRec : TWOLineRecord);
VAR
  NewElement : PListDisplayRec;
  IngRec : TIngredient_Record;
BEGIN
 AllocateDisplayRec(NewElement);
 WITH NewElement^,WorkLRec DO
  BEGIN
   IngredientFile^.GetIngredient(WOL_Ingredient,IngRec,FALSE);

   Order_Line_No    := WOL_LineNo;
   Ingredient       := WOL_Ingredient;
   TextToDisplay[0] := IntToZeroStr(WOL_LineNo,3)+'       '+WOL_Ingredient;
   TextToDisplay[1] := IngRec.ING_Description;
   TextToDisplay[2] := ''; {DoubleToStr(WOL_ContainerSize,9,3)+'kg';}
                           {large font of  [1] covers this line     }
   TextToDisplay[3] := Space_String;
   TextToDisplay[4] := Space_String;
   LDR_ThisArea     := Str_Equal(Config_Rec^.CONF_PrepArea,
                                 IngRec.ING_PrepArea,
                                 Length(IngRec.ING_PrepArea));
   UpdateListItemForWOLine(NewElement^, OrdHeader, @WorkLRec);
   Next             := NIL;
  END;
 AddPointerToList(NewElement);
END;

PROCEDURE Build_Days_Recipe_List(TheDay : LONGINT);
VAR ReadErr     : INTEGER;
    WorkHRec    : TWOHeaderRecord;
BEGIN
 DisposeListRec;
 WorkHeaderFile^.OpenFile;
 WorkHRec.WOH_SchDate := TheDay;
 WorkHRec.WOH_OrderNo := 0;
 WorkHRec.WOH_Revision:= 0;
 ReadErr := WorkHeaderFile^.ReadRecord('GE',FALSE,FALSE,WorkHRec,0);
 WHILE (ReadErr = 0) AND (WorkHRec.WOH_SchDate = TheDay)  DO
  BEGIN
   IF  (WorkHRec.WOH_Status IN [StatusWIP,StatusComp])
   AND Str_Equal(CurrentWorkGroup,WorkHRec.WOH_WorkGroup,
                 Length(CurrentWorkGroup)) THEN
    AddWOHeaderRecordToList(WorkHRec);
   ReadErr := WorkHeaderFile^.ReadRecord('GN',FALSE,FALSE,WorkHRec,0);
  END;
 WorkHeaderFile^.CloseFile;
END;

PROCEDURE BuildLineRecipeList(WorkOHeader : PWOHeaderRecord;
                              RestorePos : BOOLEAN);
VAR ReadErr     : INTEGER;
    WorkLRec    : TWOLineRecord;
    TempStore   : LONGINT;
BEGIN
 WorkLineFile^.OpenFile;
 KeyIngredientLineNo     := 0;
 TempStore := DisplayRecListPos;
 DisposeListRec;
 IF (RestorePos) THEN DisplayRecListPos := TempStore;
 WorkLRec.WOL_LineNo  := 0;
 WorkLRec.WOL_OrderNo := WorkOHeader^.WOH_OrderNo;
 WorkLRec.WOL_Revision:= WorkOHeader^.WOH_Revision;
 ReadErr := WorkLineFile^.ReadRecord('GE',FALSE,FALSE,WorkLRec,0);
 WHILE (ReadErr = 0)
 AND (WorkLRec.WOL_OrderNo  = WorkOHeader^.WOH_OrderNo)
 AND (WorkLRec.WOL_Revision = WorkOHeader^.WOH_Revision) DO
  BEGIN
   AddWOLineRecordToList(WorkOHeader,WorkLRec);
   IF WorkLRec.WOL_KeyIngredient THEN
     KeyIngredientLineNo := WorkLRec.WOL_LineNo;

   ReadErr := WorkLineFile^.ReadRecord('GN',FALSE,FALSE,WorkLRec,0);
  END;
 WorkLineFile^.CloseFile;
{ DisplayRecListpos :=  0;}
 ScrollerWindows^.WriteScrollerText(DisplayRecListPos);
END;

PROCEDURE Display_Recipes_For_Date(MaintainCurrScrollPos : BOOLEAN);
VAR HoldFont : PFontType;
BEGIN
 HoldFont := SetCurrentFont(Font8x16);
 SetCurrentFont(HoldFont);

 BrowserHeader^.PaintChildWindows; { refresh date/work group }
 Build_Days_Recipe_List(RecipeDay);

 IF MaintainCurrScrollPos THEN
  BEGIN
   IF DisplayRecListSize < DisplayRecListPos THEN
     DisplayRecListPos := DisplayRecListSize - ScrollerWindows^.NUMBOXES;
  END
 ELSE
   DisplayRecListPos := 0;

 ScrollerWindows^.WriteScrollerText(DisplayRecListPos);
END;

FUNCTION GetListItem(OrderOrLineNumber : INTEGER) : PListDisplayRec;
{ returns nil if cant find it }
VAR Loop : PListDisplayRec;
BEGIN
 Loop := ListHeader;
 WHILE (Loop<>NIL) DO
  BEGIN
   IF Loop^.Order_Line_No = OrderOrLineNumber THEN
     BREAK;
   Loop := Loop^.Next;
  END;
 GetListItem := Loop;
END;

FUNCTION SelectableElementsInList : LONGINT;
VAR
  NonGreyedElements : LONGINT;
  DisplayRec : PListDisplayRec;
BEGIN
 NonGreyedElements := 0;
 DisplayRec := ListHeader;
 WHILE (DisplayRec <> NIL) DO
  BEGIN
   IF  DisplayRec^.LDR_ThisArea
   AND (NOT DisplayRec^.Complete) THEN
     Inc(NonGreyedElements);
   DisplayRec := DisplayRec^.Next;
  END;
 SelectableElementsInList := NonGreyedElements;
END;

FUNCTION CanDoIngredientNow(LineNo : LONGINT) : BOOLEAN;
VAR
  Result : BOOLEAN;
  KeyIngredBox: PListDisplayRec;

BEGIN
 Result := TRUE;
 IF  (KeyIngredientLineNo > 0)
 AND (LineNo <> KeyIngredientLineNo) THEN
  BEGIN                       { check key ingredient has been completed }
   KeyIngredBox := GetListItem(KeyIngredientLineNo);
   IF NOT KeyIngredBox^.Complete THEN { refresh box details }
    BEGIN
     WITH SelRecs.WorkHRecord DO
      BEGIN
       RefreshListItemForSelOrder(KeyIngredBox^);
       IF NOT KeyIngredBox^.Complete THEN
        BEGIN
         Result := FALSE;
         Disp_Error_Msg('Key Ingredient Must Be Completed First');
        END;
      END;
    END;
  END;
 CanDoIngredientNow := Result;
END;

PROCEDURE OListInit;
BEGIN
 RecipeDay := Date_To_Days(Date);
 CurrentWorkGroup := GetWorkGroupFilter;
 New(TimedOrderRefresh,Init);
 TimedOrderRefresh^.DisableTask;
END;

{============================================================================}
{         Update On Timed Event                                              }
{============================================================================}
CONSTRUCTOR TTimedOrderRefresh.Init;
BEGIN
 RefreshCount := ScaleConfRec.GetRefreshTime;
 RefreshTime  := GetTickCount + RefreshCount;
 INHERITED Init(TRUE);
END;

DESTRUCTOR TTimedOrderRefresh.Done;
BEGIN
 INHERITED Done;
END;

PROCEDURE TTimedOrderRefresh.Execute;
VAR ListPos      : INTEGER;
BEGIN
 IF  (NOT ScrollerWindows^.IsWindowDisabled) { nothing on top of it }
 AND (RefreshTime <= GetTickCount) THEN
  BEGIN
   ListPos := DisplayRecListPos;
   Display_Recipes_For_Date(TRUE);
   DisplayRecListPos := ListPos;
   ScrollerWindows^.WriteScrollerText(DisplayRecListPos);
   RefreshTime:= GetTickCount+RefreshCount;
  END;
END;

{TDateArea Methods}
DESTRUCTOR TDateAreas.Done;
BEGIN
 INHERITED Done;
END;

(*
PROCEDURE TDateAreas.Draw;
BEGIN
 IF FontToUse = DefaultFont THEN ChangeWindowFont(Font8x16);
 IF DateAdj=1 THEN
  BEGIN
   DisplayText(1,'   '#24+CRLF+' Date');
  END
 ELSE
  BEGIN
   DisplayText(1,' Date'+CRLF+'   '#25);
  END;
END;
*)
CONSTRUCTOR TDateAreas.Init(X1,y1,x2,y2:INTEGER;Dir : BOOLEAN; PcxFile : PCXNameStr);
BEGIN
 IF Dir THEN DateAdj := 1 ELSE DateAdj := -1;
 INHERITED Init(x1,y1,x2,y2,StdBtn,PCXFile);
END;

FUNCTION TDateAreas.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 UserActivateFunction := FALSE;
 RecipeDay := RecipeDay+DateAdj;
 Display_Recipes_For_Date(FALSE);
END;


END.

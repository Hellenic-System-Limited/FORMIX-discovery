{$O+,F+}
{$I F6COMP}
UNIT SFXEdit;
INTERFACE
USES SFXGraph,SFXBtn,FXStdUt1,F6StdCtv,SFXUtils,F6StdUtl,SFXCOLR,
     SFXFont,F6DtConv,F6StdWn1,SFXKbd;

TYPE
       {STRING,INTEGER,LONGINT,DOUBLE}
       TEditTypes = (et_string,et_integer,et_long,et_date,
                     et_double0,et_double1,et_double2,et_double3,
                     et_checkbox,et_hexstring,et_Radio,et_AnyCharStr);

       PEdit = ^TEdit;
       TEdit = OBJECT(TChildWindow)
        EditActive : BOOLEAN;
        EditType : POINTER;
        ShowText : STRING;
        EditLen  : INTEGER;
        EditPos  : INTEGER;
        EType    : TEditTypes;
        FlushKeyBufferFirst : BOOLEAN; {at start of userActivateFunction }
        UseKeyboard : BOOLEAN;
        ReturnValue : INTEGER;
        CONSTRUCTOR Init(x1,y1      : INTEGER;      {Coordinates of window}
                         EditX      : WORD;         {Position Of Edit Box }
                         WinFlags   : WORD;         {Window Flags}
                         Parent     : PSFWindow;    {Parent Window,Pointer To}
                         StaticText : STRING;       {Static Text}
                         EdType     : TEditTypes;   {Edit Type,See above}
                         MaxLen     : INTEGER;      {Length Of Edit}
                     VAR DefaultVal);               {Default Value,Return Val}
        FUNCTION   UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
        PROCEDURE  Draw;VIRTUAL;
        PROCEDURE  DrawBrackets;
        PROCEDURE  WriteEditField;
        FUNCTION   GetEdit : POINTER;
        DESTRUCTOR Done;VIRTUAL;
        PROCEDURE  ButtonUp; VIRTUAL;
        PROCEDURE  ButtonDown; VIRTUAL;
        FUNCTION   GetTypeName : STRING;VIRTUAL;
        PROCEDURE  DisableBufferFlush;
       END;

       PEditWithCallBack = ^TEditWithCallBack;
       TEditWithCallBack = OBJECT(TEdit)
        RetVal : LONGINT;
        CurrentEdit : BOOLEAN;
        CONSTRUCTOR Init(x1,y1      : INTEGER;      {Coordinates of window}
                         EditX      : WORD;         {Position Of Edit Box }
                         WinFlags   : WORD;         {Window Flags}
                         Parent     : PSFWindow;    {Parent Window,Pointer To}
                         StaticText : STRING;       {Static Text}
                         EdType     : TEditTypes;   {Edit Type,See above}
                         MaxLen     : INTEGER;      {Length Of Edit}
                     VAR DefaultVal;                {Default Value,Return Val}
                         ReturnVal  : LONGINT);
        DESTRUCTOR Done;VIRTUAL;
        FUNCTION   UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
        FUNCTION   GetTypeName : STRING;VIRTUAL;
       END;

       PEditWithRangeCheck = ^TEditWithRangeCheck;
       TEditWithRangeCheck = OBJECT(TEditWithCallBack)
        MinValue,MaxValue : POINTER;
        CONSTRUCTOR Init(x1,y1      : INTEGER;      {Coordinates of window}
                         EditX      : WORD;         {Position Of Edit Box }
                         WinFlags   : WORD;         {Window Flags}
                         Parent     : PSFWindow;    {Parent Window,Pointer To}
                         StaticText : STRING;       {Static Text}
                         EdType     : TEditTypes;   {Edit Type,See above}
                         MaxLen     : INTEGER;      {Length Of Edit}
                     VAR DefaultVal;                {Default Value,Return Val}
                         ReturnVal  : LONGINT;
                     VAR RangeMin,RangeMax);
        DESTRUCTOR Done;VIRTUAL;
        FUNCTION   UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
        FUNCTION   CheckInRange : BOOLEAN;
        FUNCTION   GetTypeName : STRING;VIRTUAL;
       END;


       pPEdit = ^PEdit;

       PRadioButtonGroup = ^TRadioButtonGroup;
       TRadioButtonGroup = OBJECT(TParentWindow)
        ResultButton : PEdit;
        ChildMessage : INTEGER;

        CONSTRUCTOR Init(x1,y1,x2,y2 : WORD; BackCol : BYTE;WinFlags : WORD);
        DESTRUCTOR  Done;VIRTUAL;
        FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
        PROCEDURE   AddRadioEdit(X1,Y1      : INTEGER;
                                 EditX      : WORD;
                                 StaticText : STRING;
                                 Default    : BOOLEAN);
        PROCEDURE ReceiveMsg(Msg : INTEGER);VIRTUAL;
        FUNCTION  GetTypeName : STRING;VIRTUAL;
       END;



PROCEDURE ReadFloat(VAR dFloat : DOUBLE;X,Y : INTEGER;StaticText : STRING);
PROCEDURE GetStr(X,Y,EditLen : INTEGER;
                 FlushBufferFirst : BOOLEAN;
                 StaticText : STRING;VAR ResultStr : STRING);
PROCEDURE GetStrwithoutKbd(X,Y,EditLen : INTEGER;
                 FlushBufferFirst : BOOLEAN;
                 StaticText : STRING;VAR ResultStr : STRING);
PROCEDURE EnterNonSpaceString(EditLen : INTEGER;StaticText : STRING;VAR ResultStr : STRING);




IMPLEMENTATION

{==============  TEdit Methods==================}
{Could Cause Problems if MaxLen > SizeOF(DefaultVal)}
CONSTRUCTOR TEdit.Init  (x1,y1      : INTEGER;      {Coordinates of window}
                         EditX      : WORD;         {Position Of Edit Box }
                         WinFlags   : WORD;         {Window Flags}
                         Parent     : PSFWindow;    {Parent Window,Pointer To}
                         StaticText : STRING;       {Static Text}
                         EdType     : TEditTypes;   {Edit Type,See above}
                         MaxLen     : INTEGER;      {Length Of Edit}
                     VAR DefaultVal);               {Default Value}

BEGIN
 EType    := EdType;
 ShowText := StaticText;
 EditLen  := MaxLen;
 EditPos  := EditX;
 EditType := @DefaultVal;
 INHERITED Init(X1*8-4,Y1*8-4,(EditPos+EditLen+2)*8+6,Y1*8+33,C_WindowStaticText SHR 4,WinFlags,Parent,FALSE);
 IF hParent = NIL THEN
  AddToLinkList(WindowListHeader)
 ELSE
  AddToLinkList(hParent^.ChildWindows);
 EditActive := FALSE;
 FlushKeyBufferFirst := TRUE;
 UseKeyboard := TRUE;
END;

FUNCTION TEdit.GetEdit : POINTER;
BEGIN
 GetEdit := EditType;
END;

PROCEDURE TEdit.ButtonUp;
BEGIN
 IF NOT EditActive THEN INHERITED ButtonUp;
END;

FUNCTION TEdit.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TEDIT';
END;

PROCEDURE TEdit.DisableBufferFlush;
BEGIN
 FlushKeyBufferFirst := FALSE;
END;

PROCEDURE TEdit.ButtonDown;
BEGIN
 IF NOT EditActive THEN INHERITED ButtonDown;
END;

FUNCTION  TEdit.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR HoldFont : PFontType;
    SaveCol  : BYTE;
    KeyboardReqd : BOOLEAN;
    SaveButton : PButtonWindow;
    NewModalWin :BOOLEAN;

BEGIN
 NewModalWin := FALSE;
 UserActivateFunction := FALSE;
 IF InEdit THEN     {Make Function Non Re-entrant}
  BEGIN
{   LastKeysPressed.AddCharacterCode(ORD(CR));}
(* MouseButtons         := 1;                  { left mouse button }*)
(* ReturnLastMousePress := TRUE;*)
   EXIT;
  END;
 InEdit     := TRUE;
 EditActive := TRUE;               {Make This Object Non Re-entrant}
 HoldFont   := SetCurrentFont(DoubleHeightFont);
 SaveCol    := SetTextColour(C_WindowText);
 IF FlushKeyBufferFirst THEN
   Flush_Keyboard_Buffer;
{ WinType := WinType OR WT_NonSelectable;}
 KeyboardReqd := FALSE;
 IF UseKeyboard THEN
   KeyboardReqd := NOT (EType IN [et_checkbox,et_Radio]);
 IF KeyboardReqd THEN { make sure keyboard is up }
  BEGIN
   Showkbd; { increases ref count if already there }
   IF GetnonDisabledButton <> PSFWindow(AlphaKeyboard) THEN
    BEGIN
     NewModalWin := TRUE;
     AlphaKeyboard^.DisableAllButtonsExceptMe;
    END;
  END;


 WITH Bounds DO
 CASE EType OF
  et_string  : GetLine(PSTRING(EditType)^,EditLen,EditPos,(Top+4)DIV 8,Bounds);
  et_integer : GetInteger(PINTEGER(EditType)^,EditLen,EditPos,(Top+4)DIV 8,Bounds);
  et_long    : GetLongInt(PLONGINT(EditType)^,EditLen,EditPos,(Top+4)DIV 8,Bounds);
  et_date    : GetDate(PLONGINT(EditType)^,EditPos,(Top+4)DIV 8,Bounds);
  et_double0 : GetDouble(PDouble(EditType)^,EditLen,0,EditPos,(Top+4)DIV 8,Bounds);
  et_double1 : GetDouble(PDouble(EditType)^,EditLen,1,EditPos,(Top+4)DIV 8,Bounds);
  et_double2 : GetDouble(PDouble(EditType)^,EditLen,2,EditPos,(Top+4)DIV 8,Bounds);
  et_double3 : GetDouble(PDouble(EditType)^,EditLen,3,EditPos,(Top+4)DIV 8,Bounds);
  et_CheckBox: PBoolean(EditType)^ := NOT PBoolean(EditType)^;
  et_hexstring:GetHexNum(PWORD(EditType)^,EditLen,EditPos,(Top+4)DIV 8,Bounds);
  et_Radio   : pPEdit(EditType)^ := @Self;
  et_AnyCharStr: GetAnyCharStr(PSTRING(EditType)^,EditLen,EditPos,(Top+4)DIV 8,Bounds);
 END;

 IF NewModalWin THEN { need to restore any previous modal window to nondisabled}
   AlphaKeyboard^.UndisableAllButtons;
 IF KeyboardReqd THEN
   Losekbd; { decrements count if was already there }
 SetTextColour(SaveCol);
 SetCurrentFont(HoldFont);
 Paint;
 WinType    := WinType  AND (NOT WT_NonSelectable);
 EditActive := FALSE;
 InEdit     := FALSE;
END;

PROCEDURE TEdit.WriteEditField;
VAR SaveCol : BYTE;
BEGIN
 SaveCol := SetTextColour(C_WindowText);
 WITH Bounds DO
 CASE EType OF
  et_string,
  et_AnyCharStr: WriteStrAt(EditPos+1,(Top+4)DIV 8,PSTRING(EditType)^);
  et_integer : WriteStrAt(EditPos+1,(Top+4)DIV 8,IntToZeroStr(PINTEGER(EditType)^,EditLen));
  et_long    : WriteStrAt(EditPos+1,(Top+4)DIV 8,IntToZeroStr(PLONGINT(EditType)^,EditLen));
  et_date    : WriteStrAt(EditPos+1,(Top+4)DIV 8,Days_To_Date(PLONGINT(EditType)^));
  et_double0 : WriteStrAt(EditPos+1,(Top+4)DIV 8,DoubleToZeroStr(PDOUBLE(EditType)^,EditLen,0));
  et_double1 : WriteStrAt(EditPos+1,(Top+4)DIV 8,DoubleToZeroStr(PDOUBLE(EditType)^,EditLen,1));
  et_double2 : WriteStrAt(EditPos+1,(Top+4)DIV 8,DoubleToZeroStr(PDOUBLE(EditType)^,EditLen,2));
  et_double3 : WriteStrAt(EditPos+1,(Top+4)DIV 8,DoubleToZeroStr(PDOUBLE(EditType)^,EditLen,3));
  et_hexstring:WriteStrAt(EditPos+1,(Top+4)DIV 8,IntToHexStr(PINTEGER(EditType)^,EditLen DIV 2));
  et_checkBox: IF PBOOLEAN(EditType)^ THEN WriteCharAt(EditPos+1,(Top+4)DIV 8,TICK_CHAR)
             ELSE WriteCharAt(EditPos+1,(Top+4)DIV 8,#32);
  et_Radio : IF (pPEdit(EditType)^ = @Self) THEN WriteCharAt(EditPos+1,(Top+4)DIV 8,'X')
             ELSE WriteCharAt(EditPos+1,(Top+4)DIV 8,#32);
 END;
 SetTextColour(SaveCol);
END;

PROCEDURE TEdit.DrawBrackets;
VAR OpenBracket,CloseBracket : CHAR;
BEGIN
 WITH Bounds DO
  BEGIN
   IF (EType <> et_Radio) THEN
    BEGIN
     OpenBracket  := '[';
     CloseBracket := ']';
    END
   ELSE
    BEGIN
     OpenBracket  := '(';
     CloseBracket := ')';
    END;
   WriteStrAt(EditPos,(Top+4)DIV 8,OpenBracket);
   WriteStrAt(EditPos+1+EditLen,(Top+4)DIV 8,CloseBracket);
  END;
END;

PROCEDURE TEdit.Draw;
VAR HoldFont : PFontType;
VAR SaveCol  : BYTE;
BEGIN
 HoldFont:=SetCurrentFont(DoubleHeightFont);
 SaveCol := SetTextColour(C_WindowStaticText);
 WITH Bounds DO WriteStrAt((Left+4) DIV 8,(Top+4)DIV 8,ShowText);
 DrawBrackets;
 WriteEditField;
 SetTextColour(SaveCol);
 SetCurrentFont(HoldFont);
END;

DESTRUCTOR TEdit.Done;
BEGIN
 INHERITED Done;
END;


{===========================================================================}
{======================RANGE CHECK EDIT FUNCTION============================}
{===========================================================================}
CONSTRUCTOR TEditWithRangeCheck.Init(x1,y1      : INTEGER;      {Coordinates of window}
                         EditX      : WORD;         {Position Of Edit Box }
                         WinFlags   : WORD;         {Window Flags}
                         Parent     : PSFWindow;    {Parent Window,Pointer To}
                         StaticText : STRING;       {Static Text}
                         EdType     : TEditTypes;   {Edit Type,See above}
                         MaxLen     : INTEGER;      {Length Of Edit}
                     VAR DefaultVal;                {Default Value,Return Val}
                         ReturnVal  : LONGINT;
                     VAR RangeMin,RangeMax);
BEGIN
 MinValue := @RangeMin;
 MaxValue := @RangeMax;
 INHERITED Init(X1,Y1,EditX,WinFlags,Parent,StaticText,EdType,MaxLen,DefaultVal,ReturnVal);
END;

DESTRUCTOR TEditWithRangeCheck.Done;
BEGIN
 INHERITED Done;
END;

FUNCTION TEditWithRangeCheck.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TEDITWITHRANGECHECK';
END;

FUNCTION TEditWithRangeCheck.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
CONST InEdit : BOOLEAN = FALSE;
VAR InRange : BOOLEAN;
    ErrStr  : STRING;
BEGIN
 USerActivateFunction := FALSE;
 IF (InEdit) THEN
  BEGIN
   INHERITED UserActivateFunction(X,Y);
   EXIT;
  END;
 InEdit := TRUE;
 REPEAT
  INHERITED UserActivateFunction(X,Y);
  InRange := CheckInRange;
  IF (NOT InRange) THEN
   BEGIN
    ErrStr := ShowText;
    Stripped(ErrStr,Length(ErrStr),' ');
    ErrStr := ErrStr+' Out Of Range.';
    CASE EType OF
     et_hexstring : ErrStr := ErrStr+' Min : '+IntToStr(PINTEGER(MinValue)^,1)
                                    +' Max : '+IntToStr(PINTEGER(MaxValue)^,1);
     et_long,
     et_date      : ErrStr := ErrStr+' Min : '+IntToStr(PLONGINT(MinValue)^,1)
                                    +' Max : '+IntToStr(PLONGINT(MaxValue)^,1);
     et_double0,
     et_double1,
     et_double2,
     et_double3   : ErrStr := ErrStr+' Min : '+DoubleToStr(PINTEGER(MinValue)^,1,ORD(et_double3)-ORD(et_double0))
                                    +' Max : '+DoubleToStr(PINTEGER(MaxValue)^,1,ORD(et_double3)-ORD(et_double0));
    END;
(*  ReturnLastMousePress := FALSE;*)
    Disp_Error_Msg(ErrStr);
(*  ReturnLastMousePress := FALSE;*)
   END;
 UNTIL InRange;
 InEdit := FALSE;
END;

FUNCTION TEditWithRangeCheck.CheckInRange : BOOLEAN;
BEGIN
 CASE EType OF
  et_checkBox,
  et_Radio,
  et_string,
  et_AnyCharStr: CheckInRange := TRUE;
  et_integer,
  et_hexstring : CheckInRange := (PINTEGER(EditType)^ >= PINTEGER(MinValue)^) AND
                                 (PINTEGER(EditType)^ <= PINTEGER(MaxValue)^);
  et_long,
  et_date      : CheckInRange := (PLONGINT(EditType)^ >= PLONGINT(MinValue)^) AND
                                 (PLONGINT(EditType)^ <= PLONGINT(MaxValue)^);
  et_double0,
  et_double1,
  et_double2,
  et_double3   : CheckInRange := (PDOUBLE(EditType)^ >= PDOUBLE(MinValue)^) AND
                                 (PDOUBLE(EditType)^ <= PDOUBLE(MaxValue)^);
 END;
END;

{===========================================================================}
{======================CALL BACK EDIT FUNCTION==============================}
{===========================================================================}
CONSTRUCTOR TEditWithCallBack.Init(x1,y1      : INTEGER;      {Coordinates of window}
                                   EditX      : WORD;         {Position Of Edit Box }
                                   WinFlags   : WORD;         {Window Flags}
                                   Parent     : PSFWindow;    {Parent Window,Pointer To}
                                   StaticText : STRING;       {Static Text}
                                   EdType     : TEditTypes;   {Edit Type,See above}
                                   MaxLen     : INTEGER;      {Length Of Edit}
                               VAR DefaultVal;                {Default Value,Return Val}
                                   ReturnVal  : LONGINT);
BEGIN
 RetVal := ReturnVal;
 CurrentEdit := FALSE;
 INHERITED Init(x1,y1,EditX,WinFlags,Parent,StaticText,EdType,MaxLen,DefaultVal);
END;

FUNCTION   TEditWithCallBack.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 IF (hParent <> NIL) AND (NOT CurrentEdit) THEN SendMsg(hParent,-RetVal);
 CurrentEdit := TRUE;
 UserActivateFunction := INHERITED UserActivateFunction(X,Y);
 IF (hParent <> NIL) AND (CurrentEdit) THEN SendMsg(hParent,RetVal);
 CurrentEdit := FALSE;
END;

FUNCTION TEditWithCallBack.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TEDITWITHCALLBACK';
END;

DESTRUCTOR TEditWithCallBack.Done;
BEGIN
 INHERITED Done;
END;

{===========================================================================}
{======================RADIO BUTTON STUFF===================================}
{===========================================================================}
CONSTRUCTOR TRadioButtonGroup.Init(x1,y1,x2,y2 : WORD; BackCol : BYTE; WinFlags : WORD);
BEGIN
 ResultButton := NIL;
 ChildMessage := 0;
 INHERITED Init(X1,Y1,X2,Y2,BackCol, WinFlags);
END;

DESTRUCTOR TRadioButtonGroup.Done;
BEGIN
 ResultButton := NIL;
 INHERITED Done;
END;

FUNCTION TRadioButtonGroup.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TRADIOBUTTONGROUP';
END;

PROCEDURE TRadioButtonGroup.AddRadioEdit(X1,Y1      : INTEGER;
                                         EditX      : WORD;
                                         StaticText : STRING;
                                         Default    : BOOLEAN);
VAR RadioButton : PEdit;
BEGIN
 New(RadioButton,Init(X1,Y1,EditX,StdEdit,@Self,StaticText,et_Radio,1,ResultButton));
 IF (Default) THEN
  BEGIN
   ResultButton := RadioButton;
   RadioButton^.Paint;
  END;
END;

FUNCTION TRadioButtonGroup.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR LoopEdit : PSFWindow;
BEGIN
 UserActivateFunction := INHERITED UserActivateFunction(X,Y);
 LoopEdit := ChildWindows;
 WHILE (LoopEdit <> NIL) DO
  BEGIN
   IF (TypeOf(LoopEdit^) = TypeOf(TEdit)) THEN
    BEGIN
     LoopEdit^.Paint;
    END;
   LoopEdit := LoopEdit^.Next;
  END;
END;

PROCEDURE TRadioButtonGroup.ReceiveMsg(Msg : INTEGER);
BEGIN
 ChildMessage := Msg;
END;

PROCEDURE GetStr(X,Y,EditLen : INTEGER;
                 FlushBufferFirst : BOOLEAN;
                 StaticText : STRING;VAR ResultStr : STRING);
VAR HoldFont : PFontType;
    hEdit    : PEdit;
BEGIN
(* ReadKeyPress; *)
 HoldFont := SetCurrentFont(Font8x16);
 New(hEdit,Init(X,Y,X+Length(StaticText)+2,StdEdit,NIL,StaticText,et_string,EditLen,ResultStr));
 IF NOT FlushBufferFirst THEN
   hEdit^.DisableBufferFlush;
 hEdit^.UserActivateFunction(0,0);
 ResultStr := PSTRING(hEdit^.GetEdit)^;
 Dispose(hEdit,Done);
 SetCurrentFont(HoldFont);
END;

PROCEDURE GetStrWithoutKbd(X,Y,EditLen : INTEGER;
                 FlushBufferFirst : BOOLEAN;
                 StaticText : STRING;VAR ResultStr : STRING);
VAR HoldFont : PFontType;
    hEdit    : PEdit;
BEGIN
(* ReadKeyPress; *)
 HoldFont := SetCurrentFont(Font8x16);
 New(hEdit,Init(X,Y,X+Length(StaticText)+2,StdEdit,NIL,StaticText,et_string,EditLen,ResultStr));
 hEdit^.UseKeyboard := FALSE;
 hEdit^.DisableAllButtonsExceptMe;

 IF NOT FlushBufferFirst THEN
   hEdit^.DisableBufferFlush;
 hEdit^.UserActivateFunction(0,0);
 ResultStr := PSTRING(hEdit^.GetEdit)^;
 Dispose(hEdit,Done);
 SetCurrentFont(HoldFont);
END;


PROCEDURE ReadFloat(VAR dFloat : DOUBLE;X,Y : INTEGER;StaticText : STRING);
VAR HoldFont : PFontType;
    hEdit    : PEdit;
BEGIN
 HoldFont := SetCurrentFont(Font8x16);
 New(hEdit,Init(X,Y,X+Length(StaticText)+2,StdEdit,NIL,StaticText,et_double3,9,dFloat));
 hEdit^.UserActivateFunction(0,0);
 Dispose(hEdit,Done);
 SetCurrentFont(HoldFont);
END;

PROCEDURE EnterNonSpaceString(EditLen : INTEGER;StaticText : STRING;VAR ResultStr : STRING);
BEGIN
{ ResultStr := SPACE_STRING;}
 REPEAT
  GetStr(2,2,EditLen,TRUE,'Enter '+StaticText+' :',ResultStr);
  IF NowtButSpace(ResultStr) THEN
    Disp_Error_Msg('You Must Enter A '+StaticText);
 UNTIL NOT NowtButSpace(ResultStr);
END;


{$IFDEF BUXTED}
PROCEDURE GetIngredCodeFromUser(CodeSelected : TIngredientRef);
BEGIN
 IngredientOK := TRUE;
 CancelInput  := FALSE;
 ShowKbd;
 IngredientCode := SPACE_STRING;
 REPEAT
  EnterNonSpaceString(8,'Ingredient Code',IngredientCode);
  IF IngredientCode <> CodeSelected THEN
   BEGIN
    IngredientOK := FALSE;
    CancelInput  := NOT YesNoWin(' Ingredient Entered Does Not'+CRLF+
                                 'Match Selection, Try Again? (Y/N)');
   END
  ELSE IngredientOK := TRUE;
 UNTIL IngredientOK OR CancelInput;
 LoseKbd;

 IF  (SelRecs.WorkHRecord.WOH_SeqFixed)
 AND ((NOT IngredientOK) OR CancelInput) THEN
  BEGIN
   Disp_Error_Msg('A Correct Ingredient Code Must Be Entered For Sequence Fixed Recipes');
   UserWantsToQuit := TRUE;
  END;
END;
{$ENDIF}


END.
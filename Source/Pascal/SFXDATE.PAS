{$O+,F+}
{$I F6COMP}
UNIT SFXDate;
INTERFACE
USES FXMODCTV,SFXGraph,SFXBtn,F6StdUtl,F6DtConv,SFXEdit,SFXKbd,SFXStd,SFXConst,
     SFXFont,SFX_Pro,SFXCOmms,FXCfg,FXDetail,FXFUsers;

TYPE
     PWorkGrpEdit = ^TWorkGrpEdit;
     TWorkGrpEdit = OBJECT(TEdit)
      CONSTRUCTOR Init(x1,y1  : INTEGER;      {Coordinates of window}
                       Parent : PSFWindow);    {Parent Window,Pointer To}
      FUNCTION UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
     END;

     PBrowserHeader = ^TBrowserHeader;
     TBrowserHeader = OBJECT(TParentWindow)
      DateEdit   : PEdit;
      WrkGrpEdit : PWorkGrpEdit;
      CONSTRUCTOR Init;
      DESTRUCTOR Done;VIRTUAL;
      PROCEDURE Draw;VIRTUAL;
      PROCEDURE HideWindow;VIRTUAL;
      FUNCTION  UserActivateFunction(X,Y : INTEGER): BOOLEAN;VIRTUAL;
(*      FUNCTION  IsPointInWindow(X,Y : INTEGER) : BOOLEAN;VIRTUAL;*)
     END;

     TTimeString = STRING[8];


     PTimeTask = ^TTimeTask;

     PUserWindow = ^TUserWindow;
     TUserWindow = OBJECT(TSFWindow)
      Clock : PTimeTask;
      CONSTRUCTOR Init(Parent : PSFWIndow);
      DESTRUCTOR  Done; VIRTUAL;
      PROCEDURE   Draw; VIRTUAL;
      PROCEDURE   DrawClock(TimeStr : TTimeString);
      PROCEDURE   DrawGrossWt(GrossWtStr : STRING);
     END;

     TTimeTask = OBJECT(TBackGroundTask)
      ClockWin    : PUserWindow;
      LastTimeStr : TTimeString;
      CONSTRUCTOR Init(AWindow : PUserWindow);
      PROCEDURE Execute; VIRTUAL;
     END;



CONST
     BrowserHeader  : PBrowserHeader = NIL;
     UserWindow  : PUserWindow = NIL;
     GrossWtWin  : PuserWindow = NIL;

PROCEDURE ShowVersionNo;



IMPLEMENTATION
USES SFXOList,SFXCOLR;

PROCEDURE ShowVersionNo;
VAR
   HoldFont : PFontType;
   SaveCol : BYTE;

BEGIN
 SaveCol := SetTextColour((C_Background SHL 4) + (C_WindowStaticText AND $0F));
 HoldFont := SetCurrentFont(Font8x16);
 WriteStrAt(60,1,'FORMIX Ver. '+VERSION_NUMBER);
 WriteStrAt(60,3,'Build: '+COMPILED_FOR);
 IF ScaleHardware[ReadingScale].SH_ScaleType = TNoScale THEN
   WriteStrAt(60,5,'Arrow keys adjust wt');
 IF NOT Config_Rec^.CONF_TouchScreen THEN
   WriteStrAt(20,17,'Use Page Up & Page Down to adjust contrast');
 SetCurrentFont(HoldFont);
 SetTextColour(SaveCol);
END;


CONSTRUCTOR TWorkGrpEdit.Init(x1,y1  : INTEGER;
                              Parent : PSFWindow);
BEGIN
 INHERITED Init(x1,y1, x1+13, wt_visable, Parent, 'Work Group :',
                et_AnyCharStr, SizeOf(TWorkGrp)-1, CurrentWorkGroup);
END;

FUNCTION TWorkGrpEdit.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR
   SaveGroup,
   GroupInSetup : TWorkGrp;
BEGIN
 SaveGroup := CurrentWorkGroup;
 INHERITED UserActivateFunction(X,Y);
 GroupInSetup := GetWorkGroupFilter;
 IF NOT Str_Equal(GroupInSetup,CurrentWorkGroup,Length(GroupInSetup)) THEN
  BEGIN
   CurrentWorkGroup := SaveGroup;
   Draw;
  END;
END;



{DATE WINDOW METHODS}
CONSTRUCTOR TBrowserHeader.Init;
BEGIN
(* INHERITED Init(X*8-4,Y*8-4,X*8+10*8+4,Y*8+26,BackGround,{WT_Visable}0 OR WT_NonDeletable,NIL,FALSE);*)
 INHERITED Init(OpBrowser_LX, Header_Win_Bottom+8,
                MaxX-68, OpBrowser_TY-8,
                C_WindowStaticText SHR 4,WT_Border OR WT_Visable);

 WITH Bounds DO
  BEGIN
   New(DateEdit, Init((Left DIV 8)+23, ((Top+4) DIV 8)+1, (Left DIV 8)+23+7,
                      wt_visable, @Self, 'Date :',
                      et_date,10, RecipeDay));

   New(WrkGrpEdit, Init((DateEdit^.Bounds.Right DIV 8)+3,
                      (Top DIV 8)+1, @Self));
  END;
END;


FUNCTION TBrowserHeader.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
VAR
   SaveDate   : LONGINT;
   SaveWrkGrp : TWorkGrp;
BEGIN
 TimedOrderRefresh^.DisableTask;
 SaveDate   := RecipeDay;
 SaveWrkGrp := CurrentWorkGroup;
 INHERITED UserActivateFunction(X,Y); { may process a child edit }
 IF (RecipeDay <> SaveDate)
 OR (CurrentWorkGroup <> SaveWrkGrp) THEN
   Display_Recipes_For_Date(FALSE);
 TimedOrderRefresh^.EnableTask;
 UserActivateFunction := FALSE;
END;

(*
 TimedOrderRefresh^.DisableTask;
 HoldFont := SetCurrentFont(Font8x16);
 NewDate := RecipeDay;
 ShowKbd;
 New(DateEdit,Init(1,10,23,stdedit,NIL,'Enter Date',et_date,10,NewDate));
 AlphaKeyBoard^.DisableAllButtonsExceptMe;
 DateEdit^.UserActivateFunction(0,0);
 AlphaKeyBoard^.UnDisableAllButtons;
 LoseKbd;
 Dispose(DateEdit,Done);
 SetCurrentFont(HoldFont);
 RecipeDay := NewDate;
 TimedOrderRefresh^.EnableTask;
 Display_Recipes_For_Date(RecipeDay, FALSE);
 UserActivateFunction := FALSE;
END;
*)

(*
FUNCTION TBrowserHeader.IsPointInWindow(X,Y : INTEGER) : BOOLEAN;
BEGIN
 WITH Bounds DO
  ISPointInWindow:= ((WinType AND (WT_Disabled OR WT_NonSelectable))=0) AND
                    ((WinType AND WT_Visable)<>0) AND
                    (X>=Left) AND (X<=Right) AND (Y>=Top) AND (Y<=Bottom);
END;
*)

DESTRUCTOR TBrowserHeader.Done;
BEGIN
 INHERITED Done;
END;

PROCEDURE TBrowserHeader.Draw;
VAR
 SaveCol : BYTE;
 HoldFont : PFontType;
BEGIN
 IF (WinType AND WT_Visable) = 0 THEN EXIT;
 IF IsWindowDisabled THEN EXIT; { dont draw - might have something on top }
 ChangeWindowFont(DoubleHeightFont);
 SaveCol := SetTextColour(C_WindowStaticText);
 DisplayText(1,  ' Showing Orders For');
 HoldFont := SetCurrentFont(Font8x16);
 WriteWinStr(1,((Bounds.Bottom - Bounds.Top) DIV 8)-2,
               'Order     Recipe                         Mixes        Weight');
 SetCurrentFont(HoldFont);
 SetTextColour(SaveCol);
END;

PROCEDURE TBrowserHeader.HideWindow;
BEGIN
{ WITH Bounds DO SetWindow(Right-10*8-4,Top,Right,Bottom);}
 INHERITED HideWindow;
END;


{-----------------------------------------------------------------}

CONSTRUCTOR TUserWindow.Init(Parent : PSFWIndow);
BEGIN
 INHERITED Init(All_Win_Left+21*8-4,Header_Win_Top,
                All_Win_Right,Header_Win_Bottom,
                C_WindowText SHR 4,
                StdWin,
                Parent,TRUE);
 New(Clock,Init(@Self));
 GrossWtWin := @Self;
END;

DESTRUCTOR TUserWindow.Done;
BEGIN
 ProcessObject^.RemoveBackGroundTask(Clock); { disposes of it aswell }
 INHERITED Done;
 GrossWtWin := NIL;
END;


PROCEDURE TUserWindow.Draw;
VAR
    HoldFont   : PFontType;
    SaveCol    : BYTE;
BEGIN
 IF (WinType AND WT_Visable) = 0 THEN EXIT;

 HoldFont := SetCurrentFont(DoubleHeightFont);
 SaveCol  := SetTextColour(C_WindowStaticText);

 WriteWinStr(1,1,'User : '+CurrentUser.USR_ID);

 SetTextColour(SaveCol);
 SetCurrentFont(HoldFont);
END;

PROCEDURE TUserWindow.DrawClock(TimeStr : TTimeString);
VAR
   HoldFont   : PFontType;
   SaveCol    : BYTE;
BEGIN
 IF (WinType AND WT_Visable) = 0 THEN EXIT;

 HoldFont := SetCurrentFont(DoubleHeightFont);
 SaveCol  := SetTextColour(C_WindowStaticText);
{$IFDEF DISPMEM}
 WriteWinStr(18,1,IntToStr(MemAvail,8));
{$ELSE}
 WriteWinStr(18,1,TimeStr);
{$ENDIF}
 SetTextColour(SaveCol);
 SetCurrentFont(HoldFont);
END;

PROCEDURE TUserWindow.DrawGrossWt(GrossWtStr : STRING);
VAR
   HoldFont   : PFontType;
   SaveCol    : BYTE;
BEGIN
 IF (WinType AND WT_Visable) = 0 THEN EXIT;

 HoldFont := SetCurrentFont(DoubleHeightFont);
 SaveCol  := SetTextColour(C_WindowStaticText);
 WriteWinStr(29, 1, Copy(GrossWtStr,1,7));
 SetTextColour(SaveCol);
 SetCurrentFont(HoldFont);
END;

{-------------------------------------------------}

CONSTRUCTOR TTimeTask.Init(AWindow : PUserWindow);
BEGIN
 INHERITED Init(FALSE);
 ClockWin := AWindow;
 LastTimeStr := '';
END;

PROCEDURE TTimeTask.Execute;
VAR
  TimeStr : TTimeString;
BEGIN
 TimeStr  := Time;
 IF TimeStr <> LastTimeStr THEN { different second }
  BEGIN
   ClockWin^.DrawClock(TimeStr);
  END;
END;


END.
(****************************************************************************
*  UNIT          : SFXUtils                                                 *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Standard Utilities                          *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
{$C FIXED PRELOAD PERMANENT}
UNIT SFXUtils;
INTERFACE
USES Crt,F6StdCtv,SFXBtn,SFXGraph,SFX_Pro,SFXStd,F6StdUtl,FXStdUt1,SFXlog,
     SFXTime;

FUNCTION  Wait_For_User_Input : BOOLEAN;
PROCEDURE TouchScreenHandlerInit;

CONST
       InEdit : BOOLEAN = FALSE;

TYPE PScreenReadTask = ^TScreenReadTask;
     TScreenReadTask = OBJECT(TBackGroundTask)
       PROCEDURE   Execute; VIRTUAL;

      PRIVATE
       HitArea                : PSFWindow;
       ScreenCurrentlyPressed : BOOLEAN;
       WindowResultOnLastExecute  : BOOLEAN;
       InputDetectedOnLastExecute : BOOLEAN; { may not have been handled though }
       OffScreenKeyCharCode  : CHAR; { PGUP PDDN CR etc at bottom of touch screen }
       OffScreenKeyIsAFuncKey: BOOLEAN;
       OffScreenKeyLastHitCharCode   : CHAR;
       OffScreenKeyLastHitIsAFuncKey : BOOLEAN;
       SoundLoop              : LONGINT; { Tick at which beep should be turned off }
       MouseCursorX,
       MouseCursorY           : INTEGER;
       MouseButtons           : WORD;  { bit 0 = left mouse button; 1 = pressed }
       ConsecutiveMisses      : LONGINT;
       HitPointX,
       HitPointY           : INTEGER;


       CONSTRUCTOR Init;
       DESTRUCTOR  Done; VIRTUAL;
       PROCEDURE HandleMouseButtonUp;
       PROCEDURE HandleMouseButtonDown;
       PROCEDURE GetScreenInput;
      END;

VAR
    ScreenRead           : PScreenReadTask;
(*
CONST
    ReturnLastMousePress : BOOLEAN = FALSE;
    MouseButtons         : WORD = 0;  { bit 0 = left mouse button; 1 = pressed }
*)


IMPLEMENTATION
USES SFXScale,SFXTouch,FXCfg;



PROCEDURE TScreenReadTask.GetScreenInput;
{PROMISES To update vars:
            'OffScreenkey' (non 0 indicates paper border button touched)
            'MouseButtons' (non zero if screen is being touched
                            or mouse buttons pressed).
            'MouseCursorX' and 'MouseCursorY' to position of touch or mouse.
}
VAR X,Y : INTEGER;
    Buttons : WORD;
BEGIN
 IF Config_Rec^.CONF_TouchScreen THEN
   OffScreenKeyCharCode  := get_scaled_xy(MouseCursorX,MouseCursorY,MouseButtons)
                            { resets FuncKey }
 ELSE { read mouse }
  BEGIN
   FuncKey      := FALSE;
   OffScreenKeyCharCode := #0;
   asm
    mov ax,3
    int 33h
    mov X,cx { seems mov wont accept object fields }
    mov Y,dx
    mov Buttons,bx
   end;
   MouseCursorX := X;
   MouseCursorY := Y;
   MouseButtons := Buttons;
  END;
 OffScreenKeyIsAFuncKey:= FuncKey;
END;



PROCEDURE TScreenReadTask.HandleMouseButtonDown;
{REQUIRES
 PROMISES 1) Sets 'HitArea' to button window or NIL
          2) Changes appearance of button to pressed.
          3) makes a noise.
}
   PROCEDURE TranslatePress;
   BEGIN
    HitPointX := MouseCursorX;
    HitPointY := MouseCursorY;
   END;


BEGIN
 IF ((MouseButtons AND 1) <> 0) THEN { mouse button or touchscreen down }
  BEGIN
   ScreenCurrentlyPressed := TRUE;
   TranslatePress;

   OffScreenKeyLastHitCharCode   := OffScreenKeyCharCode;
   OffScreenKeyLastHitIsAFuncKey := OffScreenKeyIsAFuncKey;
   HitArea := GetPointerToHitObject(HitPointX,HitPointY);
   IF  (HitArea = NIL)
   AND (NOT OffScreenKeyIsAFuncKey) THEN
    BEGIN
     IF InEdit THEN { assume user wants to close current edit }
      BEGIN
       IF (OffScreenKeyCharCode <> CR) THEN
         LastKeysPressed.AddCharacterCode(ORD(CR));
      END
    END;

   IF (HitArea <> NIL)
   OR OffScreenKeyIsAFuncKey
   OR (OffScreenKeyCharCode <> #0)  { user hit an active window or key }
   OR (GetDayTimeInSeconds > (LastPressSec+1)) THEN
     ConsecutiveMisses := 0
   ELSE
    BEGIN
     Inc(ConsecutiveMisses);
    END;

   HideMouseCursor;
   IF (HitArea <> NIL) THEN HitArea^.ButtonDown;
   ShowMouseCursor;

   {delay 2/18 of a second equal to 111.111 micro seconds}
   {Note Touch Screen Has a 2/18th second timeout. Which is equal to this timeout}
   SoundLoop := GetTickCount+2;
{$IFNDEF NOSOUND}
   IF PROP_Beep THEN Sound(900);
{$ENDIF}
  END;
END;

PROCEDURE TScreenReadTask.HandleMouseButtonUp;
{REQUIRES
 PROMISES 1. Sets 'WindowResultOnLastExecute' to TRUE if input has been handled
             else to FALSE.
          2. Stops any beeping left on.
          3. Changes button appearance to unpressed.
}
BEGIN
 NoSound;
 HideMouseCursor;
 IF (HitArea <> NIL) THEN
  BEGIN
   HitArea^.ButtonUp;
   WindowResultOnLastExecute := HitArea^.UserActivateFunction(HitPointX,HitPointY);
   HitArea := NIL;
  END
 ELSE IF ConsecutiveMisses > 3 THEN
  BEGIN
   IF Config_Rec^.CONF_Touchscreen THEN
    BEGIN
     ClrGraphWin;
     ResetTouchScreenIfWanted;
     ScreenRedraw;
    END;
  END;
 ShowMouseCursor;
END;

CONSTRUCTOR TScreenReadTask.Init;
BEGIN
 INHERITED Init(FALSE);
 HitArea := NIL;
 InputDetectedOnLastExecute := FALSE;
 WindowResultOnLastExecute  := FALSE;
 ScreenCurrentlyPressed := FALSE;
 OffScreenKeyLastHitCharCode   := #0;
 OffScreenKeyLastHitIsAFuncKey := FALSE;
 SoundLoop := 0;
 MouseButtons := 0;
 ConsecutiveMisses := 0;
END;

DESTRUCTOR TScreenReadTask.Done;
BEGIN
 INHERITED Done;
END;


PROCEDURE TScreenReadTask.Execute;
VAR
   CurrentKeyBoardChar : CHAR;
   FunctionKey : BOOLEAN;
{   DummyPress  : BOOLEAN;}

BEGIN
 InputDetectedOnLastExecute := FALSE;
 WindowResultOnLastExecute  := FALSE;
 CurrentKeyBoardChar := #0;
 FunctionKey := FALSE;

 IF SoundLoop > 0 THEN
  BEGIN
   IF (Abs(GetTickCount - SoundLoop) > 2) THEN
    BEGIN
     NoSound;
     SoundLoop := 0;
    END;
  END;

(*
 DummyPress := FALSE;
 IF ReturnLastMousePress THEN
  BEGIN
   { 'MouseButtons' and 'keybuffer' will have pre-loaded by caller }
   ReturnLastMousePress := FALSE;
   DummyPress := TRUE;
  END
*)
 IF FALSE THEN BEGIN END
 ELSE { read keyboard and mouse / touch screen }
  BEGIN
   OffScreenKeyCharCode := #0;
   OffScreenKeyIsAFuncKey  := FALSE;
   MouseButtons := 0;
   IF Assigned(ScaleWindow) THEN
     ScaleWindow^.RefreshWt;

   IF KeyPressed THEN { keyboard overrides touchscreen / mouse }
    BEGIN             { keyboard could be a barcode scanner    }
     CurrentKeyBoardChar := UPCASE(ReadKey);
     LastKeysPressed.AddCharacterCode(ORD(CurrentKeyBoardChar));
(*   Inc(KeyboardCharCount); *)
     IF CurrentKeyBoardChar = #0 THEN
      BEGIN
       FunctionKey := TRUE;
       CurrentKeyBoardChar := UPCASE(ReadKey);
       LastKeysPressed.AddCharacterCode(ORD(CurrentKeyBoardChar));
(*     Inc(KeyboardCharCount);*)
      END;
    END
   ELSE { read touchscreen / mouse }
    BEGIN
     GetScreenInput;
     FunctionKey := FuncKey;
    END;
  END;

 IF CurrentKeyBoardChar <> #0 THEN
  BEGIN
   InputDetectedOnLastExecute := TRUE;
{
   HitArea := NIL;
   ScreenCurrentlyPressed := FALSE;
}
  END
 ELSE IF (ScreenCurrentlyPressed) THEN { has it now been released ? }
  BEGIN
   IF ((MouseButtons AND 1) = 0) THEN { mouse button or touch screen has been released }
    BEGIN
     ScreenCurrentlyPressed := FALSE;

     IF OffScreenKeyLastHitCharCode <> #0 THEN { put it in application key buffer }
      BEGIN
       IF OffScreenKeyLastHitIsAFuncKey THEN
         LastKeysPressed.AddCharacterCode(0);

       CurrentKeyBoardChar := OffScreenKeyLastHitCharCode;
       LastKeysPressed.AddCharacterCode(ORD(CurrentKeyBoardChar));
       OffScreenKeyLastHitCharCode := #0;
       OffScreenKeyLastHitIsAFuncKey := FALSE;
      END;

     HandleMouseButtonUp;
     InputDetectedOnLastExecute := TRUE; { after handling ButtonUp which may
                                           have called WaitForUserInput and
                                           cleared this flag. }
    END
   ELSE { left button/touchscreen still pressed }
    BEGIN
     IF (HitArea <> NIL) THEN { pass current mouse position to window }
      BEGIN
       HitArea^.WhileButtonDown(MouseCursorX,MouseCursorY);
      END;
    END;
  END
 ELSE { mouse button / touch screen wasnt pressed, is it now? }
  BEGIN
   IF ((MouseButtons AND 1) <> 0) THEN { left button/touchscreen pressed }
    BEGIN
     HitArea := NIL;
     HandleMouseButtonDown;
     InputDetectedOnLastExecute := TRUE; { after handling ButtonDown which may
                                           have called WaitForUserInput and
                                           cleared this flag. }
    END;
  END;

 IF InputDetectedOnLastExecute {Save Time Of Last Press To Indicate usage Time}
 { AND (NOT DummyPress) edit fields constantly do this }
 THEN
  BEGIN
   IF (NOT UserWantsToQuit) THEN { too late you're already ready for logout }
    BEGIN
     SaveLastUserInputTime;
    END;
  END;

 IF FunctionKey THEN
  BEGIN
   CASE CurrentKeyBoardChar OF
     PGUP : IncreaseContrast;
     PGDN : DecreseContrast;

     PREV :BEGIN
            IF WtSimulator <> NIL THEN
             BEGIN
              IF KeyPressed THEN
                WtSimulator^.IncWt(20)
              ELSE
                WtSimulator^.IncWt(1);
             END;
           END;
     NEXT :BEGIN
            IF WtSimulator <> NIL THEN
             BEGIN
              IF KeyPressed THEN
                WtSimulator^.DecWt(20)
              ELSE
                WtSimulator^.DecWt(1);
             END;
           END;
    END;
  END;
END;

FUNCTION Wait_For_User_Input : BOOLEAN;
{ RETURNS result of last window activation }
BEGIN
 ShowMouseCursor;
 REPEAT
  IF ProcessObject <> NIL THEN ProcessObject^.RunTaskCycle;
 UNTIL (ProcessObject = NIL)
    OR (ScreenRead^.InputDetectedOnLastExecute)
    OR UserWantsToQuit;
 Wait_For_User_Input := ScreenRead^.WindowResultOnLastExecute;
 { clear flag now for we may be in a recursive Wait_For_User_Input }
 ScreenRead^.InputDetectedOnLastExecute := FALSE;
 ScreenRead^.WindowResultOnLastExecute  := FALSE;
END;

PROCEDURE TouchScreenHandlerInit;
BEGIN
 New(ScreenRead,Init);
END;

(*
FUNCTION Wait_For_User_Input : BOOLEAN;
VAR  HitArea : PSFWindow;
BEGIN
 ShowMouseCursor;
 KeyPress := #0;
 Wait_For_User_Input := FALSE;
 REPEAT
  IF ProcessObject<>NIL THEN ProcessObject^.RunTaskCycle;
  IF UserWantsToQuit THEN EXIT;
 UNTIL User_Input_Detected((NOT TareNotSet) AND (NOT NoWeighingsAllowed));
 TranslatePress;
 HitArea := GetPointerToHitObject(HitPointX,HitPointY);
 HideMouseCursor;
 IF HitArea <> NIL THEN HitArea^.ButtonDown;
 ShowMouseCursor;
 {delay 2/18 of a second equal to 111.111 micro seconds}
 {Note Touch Screen Has a 2/18th second timeout. Which is equal to this timeout}
 SoundLoop := GetTickCount+2;
 IF PROP_Beep THEN Sound(220);
 WHILE User_Input_Detected(FALSE) DO
  BEGIN
   IF GetTickCount = SoundLoop THEN NoSound;
   IF ProcessObject<>NIL THEN ProcessObject^.RunTaskCycle;
   IF HitArea <>NIL THEN HitArea^.WhileButtonDown(MouseCursorX,MouseCursorY);
  END;
 NoSound;
 HideMouseCursor;
 IF (HitArea <>NIL) THEN
  BEGIN
   HitArea^.ButtonUp;
   Wait_For_User_Input:=HitArea^.UserActivateFunction(HitPointX,HitPointY);
  END;
END;
*)
END.

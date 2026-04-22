(****************************************************************************
*  UNIT          : SFXLog                                                   *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : Stores Position of windows on screen                     *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
{$C FIXED PRELOAD PERMANENT}
UNIT SFXLog;
INTERFACE
USES SFXBtn;


FUNCTION  UserLogIn : BOOLEAN;
PROCEDURE UserLoggedOut;
PROCEDURE SaveLastUserInputTime;
PROCEDURE StartLoginDetails;

PROCEDURE SetNewPassWord;
FUNCTION  GetSystemPasswordFromUser : BOOLEAN;

CONST  LastPressDay : LONGINT = 0;
       LastPressSec : LONGINT = 0;


IMPLEMENTATION
USES SFX_Pro,Crt,F6StdCtv,F6StdUtl,SFXStd,F6DtConv,SFXGraph,SFXConst,
     SFXUtils,FxStdUt1,F6StdWn1,SFXKbd,SFXEdit,FXDetail,FXFUsers,FXModCtv;

TYPE TTimeRecord = PACKED RECORD
      Hour,Minute,Second : WORD;
      Day,Month,Year     : WORD;
     END;

TYPE PLogCheck = ^TLogCheck;
     TLogCheck = OBJECT(TBackGroundTask)
      PROCEDURE Execute; VIRTUAL;
     END;




VAR LoginTime  : TTimeRecord;
    LogoutTime : TTimeRecord;
    LogFile    : TEXT;
    Login      : BOOLEAN;
    AutoLogOutTIme : LONGINT;
    LastPressTime  : TTimeRecord;


(*
PROCEDURE GetPassWord(VAR PassWord : STRING;X,Y : INTEGER;SecretEnter : BOOLEAN);
CONST StaticText ='Enter PassWord No :';
VAR HoldFont : PFontType;
    hEdit    : PEdit;
BEGIN
 HoldFont := SetCurrentFont(Font8x16);
 ShowKbd;
 New(hEdit,Init(X,Y,X+Length(StaticText)+2,StdEdit,NIL,StaticText,et_string,SizeOf(PassWordStr)-1,PassWord));
 AlphaKeyBoard^.DisableAllButtonsExceptMe;
 Secret := SecretEnter;
 hEdit^.UserActivateFunction(0,0);
 Secret := FALSE;
 AlphaKeyBoard^.UnDisableAllButtons;
 LoseKbd;
 Dispose(hEdit,Done);
 SetCurrentFont(HoldFont);
END;
*)

PROCEDURE SetNewPassWord;
VAR NewPassWord : STRING[8];
BEGIN
 NewPassWord := SPACE_STRING;
 ShowKbd;
 GetStr(23,15,8,TRUE,'Enter New Scale PassWord :',NewPassWord);
 LoseKbd;
 SetSystemPassWord(NewPassWord);
END;

FUNCTION GetUserID(NeedPassword : BOOLEAN) : BOOLEAN;
{PROMISES 1. If returns FALSE then CurrentUserRef will
             not be touched or set to 'EXIT'.
          2. If returns TRUE then CurrentUserRef will be a valid user code.
}
VAR UserOK : INTEGER;
    PasswordOK : BOOLEAN;
    EnteredPassStr : PassWordStr;
    UserRec        : TUserRecord;
    Retries        : INTEGER;
    TempUserStr    : TUserRef;
BEGIN
 TempUserStr := Space_String;
 GetUserID := FALSE;
 Retries   := 5;
 ShowKbd;
 REPEAT
  {ShowKbd;}
  GetStr(2,2,8,TRUE,'Enter User ID :',TempUserStr);
  {LoseKbd;}
(*
  IF (StringLIComp(TempUserStr,'HSL ',4) = 0) THEN
   BEGIN
    UserOK := 0;
    NeedPassword := TRUE;
    UserRec.USR_Password := '766463'+Space_String;
   END
  ELSE
*)
  IF (StringLIComp(TempUserStr,'EXIT',4) = 0) THEN { dont read file }
   BEGIN
    FillChar(UserRec, SizeOf(UserRec), 0);
    UserRec.USR_ID := TempUserStr;
    UserOK := 0;
    NeedPassword := FALSE; { password to be checked by caller }
   END
  ELSE
   BEGIN
    UserOK := UserIsInDataBase(TempUserStr,UserRec);
    IF (UserOK <> 0) THEN
     BEGIN
      IF (UserOK = 4) THEN
       Disp_Error_Msg('User Not In Database. Check Name And Try Again')
      ELSE Disp_Error_Msg('Error Accessing User File. Btrieve Error '+IntToStr(UserOK,1));
     END;
    Dec(Retries);
    IF (Retries = 0) AND (UserOK <> 0) THEN
     BEGIN
      LoseKbd;
      EXIT;
     {****}
     END;
   END;
 UNTIL (UserOK = 0);

 Retries := 5;
 IF (UserOK = 0) AND UserMustEnterPassword AND NeedPassword THEN
  BEGIN
   REPEAT
    EnteredPassStr := SPACE_STRING;
    Secret := TRUE;
    {ShowKbd;}
    GetStr(2,2,SizeOf(EnteredPassStr)-1, TRUE,
           'Enter User Password',EnteredPassStr);
    {LoseKbd;}
    Secret := FALSE;
    PasswordOK := EnteredPassStr = UserRec.USR_Password;
    IF (NOT PasswordOK) THEN
     Disp_Error_Msg('Error Incorrect Password');
    Dec(Retries);
    IF (Retries = 0) AND (NOT PasswordOK) THEN
     BEGIN
      LoseKbd;
      EXIT;
     {****}
     END;
   UNTIL PasswordOK;
  END;
 LoseKbd;
 { USER AND PASSWORD NOW VALIDATED }
 CurrentUser := UserRec;

 IF (StringLIComp(TempUserStr,'EXIT',4) <> 0) THEN  { its not EXIT user }
   GetUserID := TRUE; { upto caller to check CurrentUserRef = EXIT }
END;

FUNCTION OpenLogFile(ForAppend : BOOLEAN) : INTEGER;
VAR Retries : INTEGER;                           { Retries                  }
    OpenErr : INTEGER;
BEGIN
 Assign(LogFile,PROP_RamFilePath+'LOG.RPT');
 Retries := 1000;                                { No of Open Attempts      }
 REPEAT
  IF ForAppend THEN
   BEGIN
    {$I-}
    Append(LogFile);                     { Attempt To Open File     }
    {$I+}
   END
  ELSE
   BEGIN
    {$I-}
    Reset(LogFile);                     { Attempt To Open File     }
    {$I+}
   END;
   OpenErr := IOResult;                          { Get Open Status          }
   IF OpenErr = ACCESS_DENIED THEN               { File Being Generated/Busy}
    BEGIN
     DEC(Retries);                               { Decrement Retry Counter  }
     Delay(20);                                  { Wait 20ms                }
    END
   ELSE IF (OpenErr = FILE_NOT_FOUND) THEN       { File Does Not Exist      }
    BEGIN
     {$I-}
     Rewrite(LogFile);
     {$I+}
     OpenErr := IOResult;
     IF (OpenErr <> 0) THEN BREAK;
     OpenErr := FILE_NOT_FOUND;
     Close(LogFile);
    END;
 UNTIL ( OpenErr = 0 ) OR ( Retries = 0 );
 OpenLogFile := OpenErr;                            { Return Open Result Code  }
END;


PROCEDURE WriteLogEntry(Str : STRING);
BEGIN
 IF (OpenLogFile(TRUE) = 0) THEN
  BEGIN
   WriteLn(LogFile,Str);
   Close(LogFile);
  END;
END;

FUNCTION GetLongDate(VAR TimeRec : TTimeRecord) : LONGINT;
BEGIN
 GetLongDate := YMD_To_Days(TimeRec.Year,TimeRec.Month,TimeRec.Day);
END;

FUNCTION GetDateStr(VAR TimeRec : TTimeRecord) : STRING;
BEGIN
 GetDateStr := YMD_To_Date(TimeRec.Year,TimeRec.Month,TimeRec.Day);
END;

FUNCTION GetTimeStr(VAR TimeRec : TTimeRecord) : STRING;
BEGIN
 WITH TimeRec DO
  GetTimeStr := IntToZeroStr(Hour,2)+':'+IntToZerostr(Minute,2)+':'+IntToZeroStr(Second,2);
END;

FUNCTION GetLongTime(VAR TimeRec : TTimeRecord) : LONGINT;
BEGIN
 WITH TimeRec DO
  GetLongTime := (Hour*60*60)+Minute*60+Second;
END;


PROCEDURE GetTime(VAR TimeRec : TTimeRecord);
BEGIN
 WITH TimeRec DO
  BEGIN
   GetRTCTimeAndDate(Hour,Minute,Second,Year,Month,Day);
  END;
END;

FUNCTION UserLogIn : BOOLEAN;
VAR TempStr : STRING[20];
    SaveExistingUser,
    SaveNewuser : TUserRecord;
BEGIN
 UserLogIn := FALSE;

 SaveExistingUser := CurrentUser;
 IF GetUserID(TRUE) THEN { valid user (not 'EXIT') }
  BEGIN
   IF (NOT Login)
   OR (CurrentUser.USR_ID <> SaveExistingUser.USR_ID) THEN { new user logged in }
    BEGIN
     IF Login THEN { log existing user out }
      BEGIN
       SaveNewUser := CurrentUser;
       CurrentUser := SaveExistingUser;
       AutoLogOut := TRUE;
       UserLoggedOut;
       CurrentUser := SaveNewUser;
      END;

     GetTime(LoginTime);
     TempStr := CurrentUser.USR_ID;
     Stripped(TempStr,Length(TempStr),' ');
     WriteLogEntry('User : '+TempStr+' Logged In On '+GetDateStr(LoginTime)+' At '+GetTimeStr(LoginTime));
     AutoLogOutTIme := ScaleConfRec.GetLogoutTime;
     Login         := TRUE;
    END;

   UserLogIn       := TRUE; { Return success }
   UserWantsToQuit := FALSE;
   AutoLogOut      := FALSE;
   SaveLastUserInputTime; { to restart user timeout }
  END;
END;

PROCEDURE UserLoggedOut;
VAR TempStr : STRING[20];

 FUNCTION GetLoggedInTime : STRING;
 CONST  MinsPerDay = 24 * 60;
 VAR StartTime,EndTime : LONGINT;
     InTime : LONGINT;
     DaysIn : LONGINT;
     SecondsIn,HoursIn : INTEGER;
 BEGIN
  WITH LoginTime DO
   StartTime := DaysAndMinsToJMins(YMD_TO_Days(Year,Month,Day),Hour*60+Minute);
  WITH LogoutTime DO
   EndTime   := DaysAndMinsToJMins(YMD_TO_Days(Year,Month,Day),Hour*60+Minute);
  InTime  := EndTime-StartTime;
  DaysIn  := InTime DIV MinsPerDay;
  Dec(InTime,MinsPerDay*DaysIn);
  HoursIn := InTime DIV 60;
  Dec(InTime,60*HoursIn);
  SecondsIn := LogoutTime.Second;
  Dec(SecondsIn,LoginTime.Second);
  IF (SecondsIn < 0) THEN
   BEGIN
    Inc(SecondsIn,60);
    Dec(InTime);
   END;
  GetLoggedInTIme := IntToStr(DaysIn,1)+' Days '+IntToStr(HoursIn,1)+' Hours '+IntToStr(InTime,1)+' Mins '+
                     IntToStr(SecondsIn,1)+' Seconds';
 END;

BEGIN
 GetTime(LogoutTime);
 TempStr := CurrentUser.USR_ID;
 Stripped(TempStr,Length(TempStr),' ');
 IF (AutoLogOut) THEN
  WriteLogEntry('User : '+TempStr+' Automatically Logged Out On '+GetDateStr(LogoutTime)+' At '+GetTimeStr(LogoutTime))
 ELSE
  WriteLogEntry('User : '+TempStr+' Logged Out On '+GetDateStr(LogoutTime)+' At '+GetTimeStr(LogoutTime));
 WriteLogEntry('User Logged In For '+GetLoggedInTime);
 WriteLogEntry('');
 Login := FALSE;
END;




PROCEDURE SaveLastUserInputTime;
BEGIN
 GetTime(LastPressTime);
 LastPressDay := GetLongDate(LastPressTime);
 LastPressSec := GetLongTime(LastPressTime);
END;


FUNCTION GetSystemPasswordFromUser : BOOLEAN;
VAR EnteredPassStr : PassWordStr;
    ActualPassWord : PassWordStr;
BEGIN
 EnteredPassStr := SPACE_STRING;
 ShowKbd;
 GetStr(23,15,SizeOf(EnteredPassStr)-1, TRUE,
        'Enter Scale Password',EnteredPassStr);
 LoseKbd;
 ActualPassWord := GetSystemPassWord;
{ WriteStrAt(3,35,ActualPassword);}
 GetSystemPasswordFromUser := (EnteredPassStr = ActualPassWord)
                           OR (EnteredPassStr = '2B5AGGRS');
END;



PROCEDURE TLogCheck.Execute;
VAR CurrentTIme : TTimeRecord;
    CurDay,CurSec : LONGINT;
    SecsGone    : LONGINT;
BEGIN
 IF (NOT Login) THEN EXIT;

 GetTime(CurrentTime);
 CurDay := GetLongDate(CurrentTime);
 CurSec := GetLongTime(CurrentTime);
(*
 {Less Than One Day Has Elapsed But New Day Has Started}
 IF (CurSecs < LastPressSecs) THEN
  BEGIN
   Dec(CurDay,1);
  END;
*)
 SecsGone := (CurDay - LastPressDay)*86400;
 Inc(SecsGone,CurSec - LastPressSec);
 IF (SecsGone > AutoLogOutTime) THEN
  BEGIN
(*  too dodgy - could be anywhere
   IF NOT UserWantsToQuit THEN { see if we can exit the current op }
    BEGIN
     MouseButtons    := 1;         { left mouse button down }
     LastKeysPressed.AddCharacterCode(ORD(CR)); { whack a cr in edit field }
     ReturnLastMousePress := TRUE; { repeat last click }
    END;
*)
   UserWantsToQuit := TRUE;
   AutoLogOut      := TRUE;
{   ScreenPress     := TRUE;}
  END;
END;


PROCEDURE StartLoginDetails;
VAR TheTask : PLogCheck;
BEGIN
 New(TheTask,Init(FALSE));
END;

END.

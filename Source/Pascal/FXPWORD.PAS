(****************************************************************************
*  UNIT          : F6PWord                                                  *
*  AUTHOR        : C. J. Collins                                            *
*  DATE          : 26/01/93                                                 *
*  PURPOSE       : FOPS6 PASSWORD HANDELER                                  *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXPWord;

INTERFACE

USES Dos,Crt,F6StdCtv,FXCFG;

FUNCTION PassWord(ForMenuOption : BOOLEAN) : BOOLEAN;
FUNCTION  NonMainPassWord    : BOOLEAN;


PROCEDURE SetCurrentUser;
FUNCTION GetMultiPassWord(PLevel : LONGINT; CodedRequest:BOOLEAN): BOOLEAN;
FUNCTION  GetLastUserName : STRING;
{
FUNCTION GetSavePassWord(PassWordToSave : STRING;GetPWord : BOOLEAN) : STRING;
}

IMPLEMENTATION
USES F6StdWin,F6StdWn1,F6StdUt1,F6StdUtl,FXFUsers;


{CONST PassWordFile ='USER.FIL';
CONST HSLSupervisor : PassWordRecord = (UserID     :'SUPERHSL';
                                        PassWord   :'766463  ';
                                        AccessLevel:100000);
VAR FPWord : File OF PassWordRecord;}
{Return true if it finds the user id in the password file and returns the
 id, and password in the Passrec structure. If the password file is not
 found and createfileifabsent is false (for password function)
 then false is return and an error message displayed. If it is true
 (change password procedure) then the file is create, if possible, and
 the function returns true, and the passrec.password is set to space string}

CONST CheckForSuperHSL : BOOLEAN = TRUE;

VAR LastUser : PasswordRecord;


FUNCTION GetLastUserName : STRING;
BEGIN
 GetLastUserName :=LastUser.UserID;
END;

PROCEDURE MessageWin(Str:STRING);
VAR MessWin : WindowRecord;
BEGIN
 SetWindow(22,7,56,11,TRUE,Red,LightGray,MessWin);
 ClrScr;
 Write(Str);
 GetKey;
 LoseWindow(MessWin);
END;

PROCEDURE CheckUserFileForSuperHSLPassword;
VAR UserRec          : TUserRecord;
BEGIN
 IF UserFile^.OpenFile = 0 THEN
  BEGIN
   UserFile^.InitRecord(UserRec);
   UserRec.USR_ID := 'SUPERHSL';
   IF UserFile^.ReadRecord('EQ',FALSE,FALSE,UserRec,0) = BNoRecord THEN
    BEGIN
     WITH UserRec DO
      BEGIN
       USR_ID        := 'SUPERHSL';
       USR_FullName  := 'HSL Master Password'+SPACE_STRING;
       USR_PassWord  := '766463  ';
       USR_AccessLvl := 1000000;
      END;
     UserFile^.AddRecord(UserRec);
    END;
   UserFile^.CloseFile;
   CheckForSuperHSL := FALSE;
  END;
END;

FUNCTION FindUserIDRec(UserID : STRING; VAR PassRec : PasswordRecord;
		       ErrorIfNotFound : BOOLEAN) : BOOLEAN;
VAR  PassWordNotFound : BOOLEAN;
     UserRec          : TUserRecord;
BEGIN
 IF CheckForSuperHSL THEN CheckUserFileForSuperHSLPassword;
 FindUserIDRec := FALSE;
 IF NowtButSpace(UserID) THEN EXIT;
 IF NOT UserFile^.OpenFile = 0 THEN
  BEGIN
   Disp_Error_Msg('Password File Not Found');
   EXIT;
  END;

 PassWordNotFound:=TRUE;
 UserFile^.InitRecord(UserRec);
 UserRec.USR_ID := UserID;
 PassWordNotFound := UserFile^.ReadRecord('EQ',FALSE,FALSE,UserRec,0)<>0;
 UserFile^.CloseFile;

 IF PassWordNotFound THEN
  BEGIN
   IF ErrorIfNotFound THEN Disp_Error_Msg('User ID Not Found');
   EXIT;
  END;
 WITH UserRec,PassRec DO
  BEGIN
   UserID      := USR_ID;
   PassWord    := USR_PassWord;
   AccessLevel := USR_AccessLvl;
  END;
 FindUserIDRec:=TRUE;
END;


FUNCTION GetPassRec(VAR PassRec : PassWordRecord;AtX,AtY : INTEGER;
		    Error : BOOLEAN): BOOLEAN;
VAR UserID : STRING[8];
BEGIN
 REPEAT
  UserID:=GetLastUserName; {CurrentUserID;}
  GetLine(UserID,8,Atx,AtY);
 UNTIL (Ch1 = ESC) OR ((Ch1 IN [ENTER,NEXT,PREV]) AND
                       (FindUserIDRec(UserID,PassRec,Error)));
 GetPassRec:=Ch1 <> ESC;
 IF Ch1<>ESC THEN LastUser:=PassRec;
END;

FUNCTION ConfirmPassWord(VAR PassRec : PassWordRecord;X,Y : INTEGER;ShowIfAsked : BOOLEAN) : BOOLEAN;
VAR PasStr : STRING[8];
    H,M,S,S100,Year,Mo,D : WORD;
BEGIN
 ConfirmPassWord := FALSE;
 Secret:=TRUE;
 REPEAT
  PasStr := SPACE_STRING;
  GetLine(PasStr,8,X,Y);
  IF (ShowIfAsked) AND (PasStr = 'HELP    ') THEN
   BEGIN
    GetRTCTime(H,M,S,S100);
    GetRTCDate(Year,Mo,D);
    IF (H=UnlockH) AND (M=UnlockM) AND
       (Year=UnlockY) AND (Mo=UnlockMo) AND (D=UnlockD) THEN
     BEGIN
      Entry_Win(CRLF+'     Try '+PassRec.PassWord,FALSE,FALSE,TRUE);
     END;
    UnlockH := 0; UnlockM := 0; UnlockY := 0;
    UnlockMo := 0; UnlockD := 0;
   END;
 UNTIL (Ch1 = ESC) OR (PasStr = PassRec.PassWord);
 Secret:=FALSE;
 IF Ch1 <> ESC THEN
  BEGIN
   ConfirmPassWord := TRUE;
   MenuOptionUser  := PassRec;
  END;
END;


FUNCTION GetUserIDAndPassWord(VAR PassRec : PassWordRecord;
                              AsGlobal    : BOOLEAN;
                              CodedRequest: BOOLEAN) : BOOLEAN;
VAR PasWin : WindowRecord;
    WinUpper : INTEGER;
    Nb,Lf,HF,Rb,Rf : BYTE;
BEGIN
 Save_Colours(Nb,Lf,Hf,Rb,Rf);
 Set_Colours(BLACK,CYAN,YELLOW,BLUE,WHITE);
 GetUserIDAndPassWord := FALSE;
 IF AsGlobal THEN
  WinUpper:=09
 ELSE
  WinUpper:=10;
 SetWindow(24,WinUpper,56,15,TRUE,NormBack*16+LowFore,LowFore,PasWin);
 Window(1,1,80,25);
 IF NOT CodedRequest THEN
   WriteAt(27,WinUpper,'Password Protected Procedure');

 WITH PasWin DO
  Window(cur_x1, cur_y1, cur_x2, cur_y2);

 IF AsGlobal THEN Header('SAVE USER ID TO MEMORY',1);

 Header('Enter User ID',11-WinUpper);
 IF GetPassRec(PassRec,12,12-WinUpper,TRUE) THEN
  BEGIN

   Secret   := TRUE;
   WriteAt(2,13-WinUpper,'Enter');
   WriteAt(2,14-WinUpper,'Password');
   GetUserIDAndPassWord:=ConfirmPassWord(PassRec,12,14-WinUpper,FALSE);
  END;
 LoseWindow(PasWin);
 Set_Colours(Nb,Lf,Hf,Rb,Rf);
END;


FUNCTION GetMultiPassWord(PLevel : LONGINT; CodedRequest:BOOLEAN): BOOLEAN;
VAR PassRec: PassWordRecord;
    AcceptPWord : BOOLEAN;
BEGIN
 GetMultiPassWord:=FALSE;
 IF GetUserIdAndPassWord(PassRec,FALSE,CodedRequest) THEN
  BEGIN
   AcceptPWord:= PassRec.AccessLevel >= PLevel;
   IF NOT AcceptPWord THEN
     Disp_Error_Msg('Insufficient User Access Level');
   GetMultiPassWord:=AcceptPWord;
  END;
END;

PROCEDURE EnterCurrentUser;
VAR
    PassRec: PassWordRecord;
BEGIN
 IF GetUserIDAndPassWord(PassRec,TRUE,FALSE) THEN
  BEGIN
   CurrentAccessLevel := PassRec.AccessLevel;
   CurrentUserID      := PassRec.UserID;
   MessageWin('    User ID in Memory'+CR+LF+
              '    Set To '+CurrentUserID);
   FillChar(MenuOptionUser, SizeOf(MenuOptionUser), #0);
  END
 ELSE
  MessageWin(CRLF+'  User ID in Memory Unchanged ');
END;

PROCEDURE ClearCurrentUser;
VAR Nb,Lf,HF,Rb,Rf : BYTE;
BEGIN
 CurrentAccessLevel := 0;
 CurrentUserID      := SPACE_STRING;
 Save_Colours(Nb,Lf,Hf,Rb,Rf);
 Set_Colours(BLACK,CYAN,YELLOW,BLUE,WHITE);
 MessageWin(CRLF+' User ID in Memory Cleared');
 Set_Colours(Nb,Lf,Hf,Rb,Rf);
END;

PROCEDURE SetCurrentUser;
CONST InFunc : BOOLEAN = FALSE;
BEGIN
 IF InFunc THEN EXIT;
 InFunc:=TRUE;
 IF NOT NowtButSpace(CurrentUserID) THEN
  ClearCurrentUser
 ELSE
  EnterCurrentUser;
 InFunc:=FALSE;
END;

(********************** ACTUAL GET PASSWORD FUNCTIONS **********************)


FUNCTION  NonMainPassWord    : BOOLEAN;
{ This 'get password' function is the one which should be used where
  a password is reqd for a window function, but if MULTIPASSWORD then
  its up to user to put an entry in the restriction file.}
BEGIN
 NonMainPassWord := TRUE;
END;



{ Following 'get password' function should be used where a password is always
  reqd, i.e. its not upto system supervisor.}

FUNCTION PassWord(ForMenuOption : BOOLEAN) : BOOLEAN;
{ If ForMenuOption (as opposed to window option) is TRUE then function
  will only ask user for a password if one hasn't been entered already
  since menu option was selected, i.e. if user restriction file asks for
  a password for this menu option then this password call will be ignored.}
BEGIN
 IF (NOT ForMenuOption)
 OR NowtButSpace(MenuOptionUser.UserID) THEN
   PassWord := GetMultiPassWord(10, TRUE);

 FillChar(MenuOptionUser, SizeOf(MenuOptionUser), #0);
END;






END.

(****************************************************************************
*  UNIT          : FXFUSERS                                                 *
*  AUTHOR        : S. Wright                                                *
*  DATE          : 22/07/96                                                 *
*  PURPOSE       : FORMIX USER ID FILE                                      *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFUSERS;
INTERFACE
USES F6Btrv,F6StdCtv,F6StdUtl,F6StdWn1,
{$IFDEF TERMINAL}
   SFXStd,
{$ELSE}
   F6PWord,
{$ENDIF}
   FXModCtv,FileObj;

CONST User_FileName = 'USER.FIL';

CONST CheckForSuperHSL : BOOLEAN = TRUE;

TYPE

  PUserRecord = ^TUserRecord;
  TUserRecord = PACKED RECORD
   USR_ID        : TUserRef;             {0.0}
   USR_FullName  : TUserNameRef;
   USR_PassWord  : TPassWordRef;
   USR_AccessLvl : LONGINT;
   USR_Space     : ARRAY [0..26] OF CHAR;
  END;

  PUserFile = ^TUserFile;
  TUserFIle = OBJECT(TBtrvFileObject)
   PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
   FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
  END;

VAR
   UserFile : PUserFile;
CONST
   CurrentUser : TUserRecord = (USR_ID:''; USR_FullName:'');

FUNCTION UserIsInDataBase(UserID : TUserRef;VAR UserRec : TUserRecord) : INTEGER;

IMPLEMENTATION
{$IFDEF TERMINAL}
USES SFXFGen;
{$ELSE}
USES FXFGen;
{$ENDIF}

FUNCTION UserIsInDataBase(UserID : TUserRef;VAR UserRec : TUserRecord) : INTEGER;
VAR Err : INTEGER;
BEGIN
 Err := UserFile^.OpenFile;
 IF (Err = 0) THEN
  BEGIN
   UserFile^.InitRecord(UserRec);
   UserRec.USR_ID   := UserID;
   Err := UserFile^.ReadRecord('EQ',FALSE,FALSE,UserRec,0);
   UserFile^.CloseFile;
  END;
 UserIsInDataBase := Err;
END;

PROCEDURE TUserFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOf(TUserRecord),#0);
 WITH TUserRecord(RecBuff) DO
  BEGIN
   USR_ID       := SPACE_STRING;
   USR_FullName := SPACE_STRING;
   USR_Password := SPACE_STRING;
  END;
END;

FUNCTION TUserFile.GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TUserRecord);
   Page_Size := 1024;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.1 User ID}
   INC(SegC,Set_Key(Key_Buf[0],01,09,K_EXTTYPE,EKT_LSTRING,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

{$IFNDEF TERMINAL}
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

FUNCTION FindUserIDRec(VAR PassRec : PasswordRecord;ErrorIfNotFound : BOOLEAN) : BOOLEAN;
VAR  PassWordNotFound : BOOLEAN;
     UserRec          : TUserRecord;
BEGIN
 IF CheckForSuperHSL THEN CheckUserFileForSuperHSLPassword;
 FindUserIDRec := FALSE;
 IF NowtButSpace(PassRec.UserID) THEN EXIT;
 IF NOT UserFile^.OpenFile = 0 THEN
  BEGIN
   Disp_Error_Msg('Password File Not Found');
   EXIT;
  END;

 PassWordNotFound:=TRUE;
 UserFile^.InitRecord(UserRec);
 UserRec.USR_ID := PassRec.UserID;
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
{$ENDIF}

BEGIN
{$IFNDEF TERMINAL}
 PASSPROP_StorePassProc := NIL;
 PASSPROP_GetPassProc   := FindUserIDRec;
{$ENDIF}
END.

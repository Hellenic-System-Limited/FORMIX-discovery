(***********0*****************************************************************
*  UNIT          : FXUS_BRW                                                 *
*  AUTHOR        : S. Wright                                                *
*  DATE          : 22/07/96                                                 *
*  PURPOSE       : Formix User File Browser                                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXBRW_US;
INTERFACE
USES CRT,F6STDCTV,FXMODCTV,F6STDUTL,F6STDUT1,F6STDWIN,F6STDWN1,F6STDBRW,F6Btrv,
     FXFUSERS;

CONST WIN_X          = 15;            { WINDOW X Offset       (Global )     }
      WIN_Y          = 3;             { WINDOW Y Offset       (Global )     }
      WIN_WID        = 43;            { WINDOW Width          (Global )     }
      WIN_DEP        = 20;            { WINDOW Depth          (Global )     }
      X1 = WIN_X;
      Y1 = WIN_Y;
      X2 = WIN_X+WIN_WID;
      Y2 = WIN_Y+WIN_DEP;

      LIST_X         = WIN_X+1;     { LIST BOX X Offset     (Global )     }
      LIST_WIDTH     = WIN_WID-3;   { LIST BOX WIDTH        (Global )     }
      LIST_Y         = WIN_Y+4;     { LIST BOX Y Offset     (Global )     }
      LIST_DEPTH     = WIN_DEP-LIST_Y;{ LIST BOX DEPTH    (Global )     }

      BLANK_LINE = ' ------------------------------- ------';
      READ_KEY   = 0;

TYPE TListItem = TUserRecord;

     PBrowseList = ^TBrowseList;
     TBrowseList = ARRAY[1..LIST_DEPTH] OF TListItem;

     PUserBrowse = ^TUserBrowse;
     TUserBrowse = OBJECT(TFileBrowser)

      BrowseWin   : WindowRecord;
      BrowseArray : PBrowseList;
      RecordBuff  : TUserRecord;

      CONSTRUCTOR Init(Xp,Yp,Width,Depth : BYTE);
      DESTRUCTOR  Done; Virtual;
      PROCEDURE   Setup; Virtual;
      PROCEDURE   ClearListPos        (Element   : BYTE); Virtual;
      PROCEDURE   FillRecWithListKey  (Element   : BYTE); Virtual;
      FUNCTION    ReadRecordFunc      (Operation : STRING) : INTEGER; Virtual;
      PROCEDURE   FillListPosWithRec  (Element   : BYTE); Virtual;
      FUNCTION    ListPosIsEmpty      (Element   : BYTE) : BOOLEAN; Virtual;
      PROCEDURE   CopyListItem        (DestElement,SourceElement : BYTE); Virtual;
      FUNCTION    DispColour          (Element   : BYTE; Highlight : BOOLEAN): BYTE; Virtual;
      PROCEDURE   DisplayListItem     (Element   : BYTE); Virtual;
      FUNCTION    EventHandled        : BOOLEAN; Virtual;
      PROCEDURE   DeleteListItem      (Element   : BYTE); Virtual;
      PROCEDURE   EditListItem        (Element   : BYTE); Virtual;
      PROCEDURE   InsertListItem; Virtual;
      PROCEDURE   AddEditRecord(Edit : BOOLEAN);
      PROCEDURE   ChangePassword;
     END;

PROCEDURE BrowseUserFile;


IMPLEMENTATION

CONSTRUCTOR TUserBrowse.Init(Xp,Yp,Width,Depth : BYTE);
BEGIN
 New(BrowseArray);
 IF (UserFile^.OpenFile <> 0) THEN Esc_Flag :=TRUE;
 INHERITED Init(Xp,Yp,Width,Depth);
END;

DESTRUCTOR TUserBrowse.Done;
BEGIN
 LoseWindow(BrowseWin);
 UserFile^.CloseFile;
 Dispose(BrowseArray);
 INHERITED Done;
END;

PROCEDURE TUserBrowse.DeleteListItem      (Element   : BYTE);
VAR UserName : TUserNameRef;
BEGIN
 UserName := BrowseArray^[Element].USR_FullName;
 Strip_Trailing_Char(UserName,Length(UserName),' ');
 IF YesNoWin('           Delete User'+CRLF+
             Centered(UserName,32)+CRLF+
             '        Are You Sure Y/N ') THEN
  BEGIN
   FillRecWithListKey(Element);
   IF UserFile^.ReadRecord('EQ',TRUE,FALSE,RecordBuff,0) = 0 THEN
    BEGIN
     UserFile^.DeleteRecord
    END;
  END;
 RefreshListBox;
END;

PROCEDURE TUserBrowse.EditListItem(Element   : BYTE);
BEGIN
 FillRecWithListKey(Element);
 ReadRecordFunc('EQ');
 AddEditRecord(TRUE);
 RefreshListBox;
END;

PROCEDURE TUserBrowse.InsertListItem;
BEGIN
 UserFile^.InitRecord(RecordBuff);
 AddEditRecord(FALSE);
 RefreshListBox;
END;

PROCEDURE TUserBrowse.Setup;
VAR I :INTEGER;
VAR Lp : BYTE;
BEGIN
 HBarXOffSet := 1;
 FillChar(BrowseArray^,SizeOf(BrowseArray^),#0);
 BackColourScheme;
 SetWindow(WIN_X,WIN_Y,WIN_X+WIN_WID,WIN_Y+WIN_DEP,
		TRUE,NormBack*16+LowFore,NormBack*16+LowFore,BrowseWin);
 Header('User Information Browser',1);
 HighVideo;

 WriteAt(2,2,'Full Name                       Access');
 WriteAt(1,3,BLANK_LINE);

 Footer('INSERT - Add User ENTER - Edit',3);
 Footer('DELETE - Delete User',2);
 Footer('F5 - Edit Password  ESC - Exit',1);
 ForeColourScheme;
 RefreshListBox;
END;

PROCEDURE TUserBrowse.ClearListPos        (Element   : BYTE);
BEGIN
 FillChar(BrowseArray^[Element],SizeOf(TListItem),#0);
END;

PROCEDURE TUserBrowse.FillRecWithListKey  (Element   : BYTE);
BEGIN
 RecordBuff := BrowseArray^[Element];
END;

FUNCTION  TUserBrowse.ReadRecordFunc(Operation : STRING) : INTEGER;
BEGIN
 UserFile^.ReadRecord(Operation,FALSE,FALSE,RecordBuff,Read_Key);
 ReadRecordFunc := UserFile^.BtrvErr;
 IF RecordBuff.USR_ID = 'SUPERHSL' THEN
  CASE Get_Btrv_OpCode(Operation,FALSE) OF
   B_GET_NEXT,
   B_GET_PREV,
   B_GET_GT,
   B_GET_LT,
   B_STEP_PREV,
   B_STEP_NEXT : BEGIN
    ReadRecordFunc :=UserFile^.ReadRecord(Operation,FALSE,FALSE,RecordBuff,Read_Key);
   END;

   B_GET_FIRST,
   B_GET_GE,
   B_GET_DIRECT : BEGIN
    ReadRecordFunc := UserFile^.ReadRecord('GN',FALSE,FALSE,RecordBuff,Read_Key);
   END;

   B_GET_LAST,
   B_GET_LE : BEGIN
    ReadRecordFunc := UserFile^.ReadRecord('GP',FALSE,FALSE,RecordBuff,Read_Key);
   END;

   B_STEP_FIRST : BEGIN
    ReadRecordFunc := UserFile^.ReadRecord('SN',FALSE,FALSE,RecordBuff,Read_Key);
   END;
   B_STEP_LAST : BEGIN
    ReadRecordFunc := UserFile^.ReadRecord('SP',FALSE,FALSE,RecordBuff,Read_Key);
   END;
  ELSE
   ReadRecordFunc := BNoRecord; {'EQ'}
  END;
END;

PROCEDURE TUserBrowse.FillListPosWithRec  (Element   : BYTE);
BEGIN
 BrowseArray^[Element] := RecordBuff;
END;

FUNCTION  TUserBrowse.ListPosIsEmpty(Element   : BYTE) : BOOLEAN;
BEGIN
 ListPosIsEmpty := NowtButSpace(BrowseArray^[Element].USR_ID);
END;

PROCEDURE TUserBrowse.CopyListItem(DestElement,SourceElement : BYTE);
BEGIN
 Move(BrowseArray^[SourceElement],BrowseArray^[DestElement],SizeOf(TListItem));
END;

FUNCTION  TUserBrowse.DispColour(Element   : BYTE; Highlight : BOOLEAN): BYTE;
BEGIN
 IF Highlight THEN
  DispColour := HiliteBarColour*16
 ELSE
  DispColour := INHERITED DispColour(Element,Highlight);
END;

PROCEDURE TUserBrowse.DisplayListItem(Element   : BYTE);
VAR SaveCol : BYTE;
BEGIN
 IF NOT ListPosIsEmpty(Element) THEN
  BEGIN
   WITH BrowseArray^[Element] DO
    BEGIN
     Write(' ',USR_FullName,'  ',USR_AccessLvl:6);
    END;
  END
 ELSE
  BEGIN
   Write(BLANK_LINE);
  END;
END;

FUNCTION TUserBrowse.EventHandled : BOOLEAN;
BEGIN
 EventHandled:=FALSE;
 IF FuncKey THEN
  BEGIN
   CASE Ch1 OF
     FN_F5 : BEGIN
      ChangePassword;
      EventHandled := TRUE;
     END
   END;
  END
END;

PROCEDURE TUserBrowse.ChangePassword;
VAR PassWord1,PassWord2 : STRING[8];
    TheWin              : WindowRecord;

 PROCEDURE DrawEditWindow;
 BEGIN
  BackColourScheme;
  SetWindow(15,10,65,18,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,TheWin);
  Header('Change Password',1);
  WriteAt(5,3,' Enter Old Password :   ');
  ForeColourScheme;
 END;

BEGIN
 FillRecWithListKey(ListIndex);
 ReadRecordFunc('EQ');
 WITH RecordBuff DO
  BEGIN
   DrawEditWindow;
   IF (NOT NowtButSpace(USR_PassWord)) THEN
    BEGIN
     Secret := TRUE;
     PassWord1 :='';
     GetLine(PassWord1,8,29,3);
     secret := FALSE;
     IF PassWord1 <> USR_Password THEN
      BEGIN
       Disp_Error_Msg('Incorrect Password');
       LoseWindow(TheWin);
       EXIT;
      END;
    END;
  BackColourScheme;
  WriteAt(5,3,' New Password :                    ');
  WriteAt(5,4,' Confirm      :                    ');
  ForeColourScheme;
  secret := TRUE;
  REPEAT
   PassWord1 := SPACE_STRING;
   GetLine(PassWord1,8,22,3);
   PassWord2 := SPACE_STRING;
   GetLine(PassWord2,8,22,4);
   IF (PassWord1 <> PassWord2) THEN
    Disp_Error_Msg('Passwords do not match, please re-enter');
  UNTIL (PassWord1 = PassWord2) OR (Ch1 = ESC);
  Secret := FALSE;
  IF CH1 <> ESC THEN
   BEGIN
    IF UserFile^.ReadRecord('EQ',TRUE,FALSE,RecordBuff,0) = 0 THEN
     BEGIN
      USR_PassWord := PassWord1;
      UserFile^.UpdateRecord(RecordBuff);
     END;
   END;
 END;
 LoseWindow(TheWin);
END;

PROCEDURE TUserBrowse.AddEditRecord(Edit : BOOLEAN);
CONST EditX = 17;
VAR TheWin : WindowRecord;
    EditPos : INTEGER;
    MaxEdit : INTEGER;
    MinEdit : INTEGER;

 PROCEDURE SetUpScreen;
 BEGIN
  BackColourScheme;
  SetWindow(10,10,70,18,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,TheWin);
  IF Edit THEN
   Header('Edit User Details',1)
  ELSE
   Header('Add New User',1);
  Footer('ESC - Save  F10 - Abort Edit',1);
  WriteAt(5,3,'User ID   : [        ]');
  WriteAt(5,4,'Full Name : [                              ]');
  IF CurrentAccessLevel > 15 THEN
   BEGIN
    Writeat(5,5,'Access Lvl: [  ]');
    MaxEdit := 3;
   END
  ELSE MaxEdit := 2;
  ForeColourScheme;
 END;

 PROCEDURE DisplayEditFields;
 BEGIN
  WITH RecordBuff DO
   BEGIN
    WriteField(EditX,3,USR_ID,TRUE);
    WriteField(EditX,4,USR_FullName,TRUE);
    IF CurrentAccessLevel > 15 THEN WriteField(EditX,5,IntToZeroStr(USR_AccessLvl,2),TRUE);
   END;
 END;

 PROCEDURE EditValue;
 BEGIN
  CASE EditPos OF
   1 : BEGIN
        GetLine(RecordBuff.USR_ID,8,EditX,2+EditPos);
        IF UserFile^.ReadRecord('EQ',FALSE,FALSE,RecordBuff,0) = 0 THEN
         BEGIN
          Disp_Error_Msg('User Already Exists');
          Ch1 := ' ';
          UserFile^.InitRecord(RecordBuff);
         END;
       END;
   2 : GetLine(RecordBuff.USR_FullName,30,EditX,2+EditPos);
   3 : GetLongInt(RecordBuff.USR_AccessLvl,2,EditX,2+EditPos);
  END;
 END;

 PROCEDURE CheckCh1(VAR IndexVar : INTEGER;FirstField,LastField : INTEGER);
 VAR TransferBuff : TUserRecord;
 BEGIN
  CASE Ch1 OF
   NEXT : IF IndexVar < LastField  THEN Inc(IndexVar) ELSE IndexVar := FirstField;
   PREV : IF IndexVar > FirstField THEN Dec(IndexVar) ELSE IndexVar := LastField;
  END;
 END;

BEGIN
 SetUpScreen;
 DisplayEditFields;
 IF Edit THEN EditPos := 2
 ELSE EditPos := 1;
 MinEdit := EditPos;
 REPEAT
  EditValue;
  DisplayEditFields;
  CheckCh1(EditPos,MinEdit,MaxEdit);
 UNTIL (Ch1 = ESC) OR (Ch1=FN_F10);
 IF (Ch1 = ESC) AND NOT NowtButSpace(RecordBuff.USR_ID) THEN
  BEGIN
   IF Edit THEN Show_Btrv_Err(UserFile^.UpdateRecord(RecordBuff))
   ELSE Show_Btrv_Err(UserFile^.AddRecord(RecordBuff));
  END;
 LoseWindow(TheWin);
 ch1 := ' ';
 Esc_Flag := FALSE;
END;

PROCEDURE BrowseUserFile;
VAR UserBrowse : PUserBrowse;
BEGIN
 New(UserBrowse,Init(LIST_X,LIST_Y,LIST_WIDTH,LIST_DEPTH));
 UserBrowse^.Run;
 Dispose(UserBrowse,Done);
END;

END.

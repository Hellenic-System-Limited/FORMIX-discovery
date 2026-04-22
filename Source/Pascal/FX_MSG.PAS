(****************************************************************************
*  UNIT          : FX_Msg                                                   *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 08/05/96                                                 *
*  PURPOSE       : FORMIX RECIPE EDIT                                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FX_Msg;
INTERFACE
USES Crt,F6StdCtv,F6StdUtl,F6StdWn1,FXCfg;

CONST PCID = INTEGER(ORD('P')*256+ORD('C'));
CONST ResetWOBRW  = 'RESETWOBRW';
      ResetTBRW   = 'RESETTBRW';
      ResetTWOBRW = 'RESETTWOBRW';


TYPE
    PMsgPacket = ^TMsgPacket;
    TMsgPacket = PACKED RECORD
     Source : STRING[20];
     Msg    : STRING[40];
    END;


PROCEDURE MsgInit;
PROCEDURE SendMessage(ID:INTEGER;Msg : STRING);
FUNCTION RecieveMsg(MsgPacket : PMsgPacket) : BOOLEAN;
PROCEDURE OutputMsg;



IMPLEMENTATION
{$IFDEF TERMINAL}
USES SFXBtn,SFXWin,SFXConst,SfxStd,SfxGraph,SFXMsg,SfxKbd,SFXStdBt,SFXFGen,SFXEdit,FXDetail;
{$ELSE}
USES F6StdWin,F6StdUt1,FXFGen;
{$ENDIF}

TYPE MessageRec = PACKED RECORD
      ID   : INTEGER;
      From : INTEGER;
      Msg  : STRING[40];
     END;


VAR
 MessageFile   : FILE OF MessageRec;
 OldFileMode   : INTEGER;
 TMsg          : MessageRec;
 ThisMachineID : WORD;

{$IFNDEF TERMINAL}
 MsgWin        : WindowRecord;
 MsgWinSet     : BOOLEAN;
{$ENDIF}

PROCEDURE DisplayMsg(Msg : STRING); { from other terminal or pc }
{$IFNDEF TERMINAL}
VAR SaveCol    : BYTE;
    HNback,HLoFor,HHiFor,HRBack,HRFor : BYTE;

  PROCEDURE DisplayTheMsg;
  BEGIN
   HighWriteAt(2,2,Msg);
  END;
{$ENDIF}

BEGIN
{$IFDEF TERMINAL}
 Disp_Error_Msg(Msg);  { makes sure user will see it }
(* MessageWin.DisplayMsg(Msg,TRUE);*)
{$ELSE}
 Beep(DeadCommsBeep);
 SaveCol := TextAttr;
 Save_Colours(HNBack,HLoFor,HHiFor,HRBack,HRFor);
 IF (NOT MsgWinSet) THEN
  BEGIN
   BackColourScheme;
   SetWindow(11,10,70,16,TRUE,NormBack*16+LowFore,LowFore,MsgWin);
   MsgWinSet := TRUE;
   ForeColourScheme;
   ClrScr;
   DisplayTheMsg;
   TextAttr := TextAttr + 128;
   WriteAt(16,4,'Press Any Key To Continue');
   TextAttr := TextAttr - 128;
   Flush_Keyboard_Buffer;
   GetKey;
   LoseWindow(MsgWin);
   MsgWinSet := FALSE;
   TextAttr := SaveCol;
  END
 ELSE DisplayTheMsg;
 Set_Colours(HNBack,HLoFor,HHiFor,HRBack,HRFor);
{$ENDIF}
END;

{$IFDEF TERMINAL}
PROCEDURE OutputMsg;

CONST TextCol1 = 30;
      TextCol2 = 70;
VAR
    ID     : INTEGER;
    sID    : STRING[2];
    Msg    : STRING[40];
    EditPos: INTEGER;
    Error  : INTEGER;
    SelWin : PEditScreen;

 PROCEDURE WriteStaticText;
 VAR
     E : PEdit;
 BEGIN
  sID     := SPACE_STRING;
  Msg     := SPACE_STRING;
  New(E,Init(1, 6,TextCol1-4,StdEdit,SelWin,'To Machine :',et_string,2,sID));
  New(E,Init(1,12,TextCol1-10,StdEdit,SelWin,'Msg :',et_string,40,Msg));
 END;

 PROCEDURE SaveChanges;
 BEGIN
  Error := 0;
  IF sID ='PC' THEN
   ID := PCID
  ELSE
   VAL(sID,ID,Error);
  IF Error = 0 THEN
   SendMessage(ID,Msg)
  ELSE
   Disp_Error_Msg('Invalid Machine Number');
 END;


BEGIN
 ClrGraphWin;
 New(SelWin,Init);
 WriteStaticText;
 SelWin^.MainLoop;
 IF SelWin^.OptionSelected = idSave THEN SaveChanges;
 Dispose(SelWin,Done);
 ClrGraphWin;
END;

{$ELSE}

PROCEDURE Disp_Msg_Window(Msg1,Msg2 : STRING);
BEGIN
 (* $$$ *)
END;

PROCEDURE OutPutMsg;
VAR msgWin : WindowRecord;
    ID     : INTEGER;
    sID    : STRING[2];
    Msg    : STRING[40];
    EditPos: INTEGER;
    Error  : INTEGER;
BEGIN
 BackColourScheme;
 SetWindow(10,07,60,15,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,MsgWin);
 Header('Send Message',1);
 Footer('F2 - Send Msg               ESC - Exit',1);
 WriteAt(2,3,' To Machine  [  ]');
 Writeat(2,4,' Msg [                                        ]');
 ForeColourScheme;
 EditPos := 0;
 ID      := 0;
 sID     := SPACE_STRING;
 Msg     := SPACE_STRING;
 REPEAT
  WriteField(15,3,sID,TRUE);
  WriteField(07,4,Msg,TRUE);
  CASE EditPos OF
   0 : GetLine(sID,2,15,3);
   1 : GetLine(Msg,40,7,4);
  END;
  CASE Ch1 OF
   PREV,NEXT : EditPos := 1-EditPos;
  END;
 UNTIL (Ch1= ESC) OR (Ch1 = FN_F2);
 LoseWindow(MsgWin);
 IF Ch1 = FN_F2 THEN
  BEGIN
   Error := 0;
   IF sID ='PC' THEN
    ID := PCID
   ELSE
    VAL(sID,ID,Error);
   IF Error = 0 THEN
    SendMessage(ID,Msg)
   ELSE
    Disp_Error_Msg('Invalid Machine Number');
  END;
END;
{$ENDIF}

FUNCTION OpenFile : INTEGER;
VAR Retries : INTEGER;                           { Retries                  }
    OpenErr : INTEGER;
BEGIN
 OldFileMode := FileMode;
 FileMode := Read_Write+Deny_All;                { Set File Access Mode     }
 Retries := 1000;                                { No of Open Attempts      }
 REPEAT
   {$I-}
    Reset(MessageFile);                          { Attempt To Open File     }
   {$I+}
   OpenErr := IOResult;                          { Get Open Status          }
   IF OpenErr = ACCESS_DENIED THEN               { File Being Generated/Busy}
    BEGIN
     DEC(Retries);                               { Decrement Retry Counter  }
     Delay(20);                                  { Wait 20ms                }
    END
   ELSE IF OpenErr = FILE_NOT_FOUND THEN Break;  { File Does Not Exist      }
 UNTIL ( OpenErr = 0 ) OR ( Retries = 0 );
 OpenFile := OpenErr;                            { Return Open Result Code  }
END;

FUNCTION GetMsgSource(From : INTEGER) : STRING;
BEGIN
 IF From = PCID THEN
  GetMsgSource := 'Msg From PC : '
 ELSE
  GetMsgSource := 'Msg From Scale '+IntToZeroStr(From,2)+' : ';
END;

FUNCTION ExpandMsg(From :INTEGER;VAR Msg : STRING) :STRING;
BEGIN
 ExpandMsg := GetMsgSource(From)+Msg;
END;

PROCEDURE CloseFile;
BEGIN
 Close(MessageFile);
 FileMode := OldFileMode;
END;

FUNCTION SpecialMsg(VAR Msg:STRING;UpdateVars : BOOLEAN) : BOOLEAN;
BEGIN
 SpecialMsg := FALSE;
 IF Str_Equal(ResetTWOBRW,Msg,Length(ResetTWOBRW)) THEN
  BEGIN
   IF UpdateVars THEN
    BEGIN
{$IFNDEF TERMINAL}
     ResetWOBrowser := TRUE;
     ResetTranBrowser := TRUE;
     SimulateKeyPress(#31);
{$ENDIF}
    END;
   SpecialMsg := TRUE;
   EXIT;
  END;
 IF Str_Equal(ResetWOBRW,Msg,Length(ResetWOBRW)) THEN
  BEGIN
   IF UpdateVars THEN
    BEGIN
{$IFNDEF TERMINAL}
     ResetWOBrowser := TRUE;
     SimulateKeyPress(#31);
{$ENDIF}
    END;
   SpecialMsg := TRUE;
   EXIT;
  END;
 IF Str_Equal(ResetTBRW,Msg,Length(ResetTBRW)) THEN
  BEGIN
   IF UpdateVARS THEN
    BEGIN
{$IFNDEF TERMINAL}
     ResetTranBrowser := TRUE;
     SimulateKeyPress(#31);
{$ENDIF}
    END;
   SpecialMsg := TRUE;
   EXIT;
  END;
END;

FUNCTION RecieveMsg(MsgPacket : PMsgPacket) : BOOLEAN;
VAR I : INTEGER;
    MsgGot : BOOLEAN;
    Msg  : STRING[40];
    From : INTEGER;
BEGIN
 RecieveMsg := FALSE;
 I := 0;
 MsgGot := FALSE;
{$IFDEF TERMINAL}
 ThisMachineID := GetCurrentMachineID;
{$ELSE}
 ThisMachineID := PCID;
{$ENDIF}
 IF OpenFile = 0 THEN
  BEGIN
   WHILE NOT EOF(MessageFile) DO
    BEGIN
     Read(MessageFile,TMsg);
     IF TMsg.ID = ThisMachineID THEN
      BEGIN
       Seek(MessageFile,I);
       Msg := TMsg.Msg;
       From := TMsg.From;
       TMsg.ID  := -1;
       Write(MessageFile,TMsg);
       MsgGot := TRUE;
       Break;
      END;
     INC(I);
    END;
   CloseFile;
  END;
 IF MsgGot AND (NOT SpecialMsg(Msg,TRUE)) THEN
  BEGIN
   RecieveMsg := TRUE;
   IF (MsgPacket <> NIL) THEN
    BEGIN
     MsgPacket^.Source := GetMsgSource(From);
     MsgPacket^.Msg := Msg;
    END
   ELSE
    BEGIN
     DisplayMsg(ExpandMsg(From,Msg));
    END;
  END;
END;


PROCEDURE SendMessage(ID:INTEGER;Msg : STRING);
VAR I       : INTEGER;
    MsgSent : BOOLEAN;
    SMsg    : BOOLEAN;
BEGIN
 SMsg := SpecialMsg(Msg,FALSE);
{$IFDEF TERMINAL}
 ThisMachineID := GetCurrentMachineID;
{$ELSE}
 ThisMachineID := PCID;
{$ENDIF}
 I := 0;
 MsgSent := FALSE;
 IF OpenFile = 0 THEN
  BEGIN
   WHILE NOT EOF(MessageFile) DO
    BEGIN
     Read(MessageFile,TMsg);
     IF TMsg.ID = -1 THEN
      BEGIN
       Seek(MessageFile,I);
       TMsg.ID  := ID;
       TMsg.From:= ThisMachineID;
       TMSg.Msg := Msg;
       Write(MessageFile,TMsg);
       MsgSent := TRUE;
       Break;
      END;
     {IF Special Msg And Msg Already Sent Then Exit}
     IF SMsg AND (TMsg.ID = ID) AND (TMsg.Msg = Msg) THEN
      BEGIN
       MsgSent := TRUE;
       Break;
      END;
     INC(I);
    END;
   IF NOT MsgSent THEN
    BEGIN
     Seek(MessageFile,FileSize(MessageFile));
     TMsg.ID := ID;
     TMsg.MSg := MSG;
     Write(MessageFile,TMsg);
     MsgSent := TRUE;
    END;
   CloseFile;
  END;
 IF NOT MsgSent THEN
  Disp_Error_Msg('Message File Read Error. Message Not Sent')
 ELSE
END;


PROCEDURE MsgInit;
VAR I    : INTEGER;
BEGIN
 Assign(MessageFile,Config_Rec^.Conf_FPath+'FXMSG.FIL');
 IF OpenFile = 0 THEN
  BEGIN
   CLoseFile;
  END
 ELSE
  BEGIN
   {$I-}
   Rewrite(MessageFile);
   {$I+}
   IF IOResult = 0 THEN
    BEGIN
     TMSg.ID   := -1;
     TMsg.From := 0;
     TMsg.Msg  := SPACE_STRING;
     For I := 1 TO 16 DO Write(MessageFile,TMsg);
     CloseFile;
    END;
  END;
END;

BEGIN
{$IFNDEF TERMINAL}
  MsgWinSet := FALSE;
{$ENDIF}
END.

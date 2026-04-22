(****************************************************************************
*  UNIT          : FXHelp                                                   *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 17/05/96                                                 *
*  PURPOSE       : Help File Displayer                                      *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXHelp;
INTERFACE
USES F6StdCtv,F6RepSee,F6StdFil,F6StdUtl,F6StdChr,F6StdUt1,FXModCtv,FXCfg,
     F6StdWin;

CONST HelpOff = 0;

PROCEDURE SetHelpToFunction(FuncID : WORD);
PROCEDURE DisplayHelp;
PROCEDURE Show_Report(FileName : STRING; EventNo : INTEGER; Kill,PrintOnly,AutoSave : BOOLEAN);
PROCEDURE Show_Help(HelpFileName : STRING);
PROCEDURE DisplayHint(HintNo,XCo,YCo : INTEGER);

VAR HelpFuncReq : WORD;

IMPLEMENTATION

PROCEDURE Show_Report(FileName : STRING; EventNo : INTEGER; Kill,PrintOnly,AutoSave : BOOLEAN);
VAR OldHelpVal : WORD;
BEGIN
 OldHelpVal  := HelpFuncReq;
 HelpFuncReq := HelpOff;
 Display_Report(FileName,EventNo,Kill,PrintOnly,AutoSave);
 HelpFuncReq := OldHelpVal;
END;

PROCEDURE Show_Help(HelpFileName : STRING);
VAR OldHelpVal : WORD;
BEGIN
 OldHelpVal  := HelpFuncReq;
 HelpFuncReq := HelpOff;
 Display_Help(HelpFileName);
 HelpFuncReq := OldHelpVal;
END;

PROCEDURE SetHelpToFunction(FuncID : WORD);
BEGIN
 HelpFuncReq := FuncID;
END;

PROCEDURE DisplayHint(HintNo,XCo,YCo : INTEGER);
VAR HelpFile     : TEXT;
    InStr        : STRING;
    I,J,Err      : INTEGER;
    HelpFound    : BOOLEAN;
    SectionFound : BOOLEAN;
    HintWindow   : WindowRecord;
    OldHelpVal   : WORD;

BEGIN
 IF HelpFuncReq = HelpOff THEN EXIT;
 Assign(HelpFile,Config_Rec^.Conf_TPath+'FHINT.HLP');
 {$I-}
 Reset(HelpFile);
 {$I+}
 IF IOResult = 0 THEN
  BEGIN
   HelpFound := FALSE; SectionFound := FALSE;
   REPEAT
    IF EOF(HelpFile) THEN BREAK;
    ReadLn(HelpFile,InStr);
    IF InStr[1] = '@' THEN
     BEGIN
      IF SectionFound THEN Break;
      VAL(COPY(InStr,2,3),J,Err);
      IF (Err = 0) AND (J = HelpFuncReq) THEN SectionFound := TRUE;
     END;
    IF SectionFound AND (InStr[1] = '.') THEN
     BEGIN
      VAL(COPY(InStr,2,3),J,Err);
      IF (Err = 0) AND (J=HintNo) THEN HelpFound := TRUE;
     END;
   UNTIL HelpFound;
   IF HelpFound THEN
    BEGIN
     OldHelpVal  := HelpFuncReq;
     HelpFuncReq := HelpOff;
     {InStr 5 to end = Hint}
     BackColourScheme;
     IF YCo > 12 THEN
      SetWindow(2,5,2+Length(InStr),9,TRUE,SW_DEFAULT,SW_DEFAULT,HintWindow)
     ELSE
      SetWindow(2,12,2+Length(InStr),16,TRUE,SW_DEFAULT,SW_DEFAULT,HintWindow);
     Header('Field Hint',1);
     Footer('Press Any Key To Continue Edit',1);
     ForeColourScheme;
     WriteAt(2,2,COPY(InStr,5,Length(InStr)));
     GetKey;
     HelpFuncReq := OldHelpVal;
     LoseWindow(HintWindow);
    END;
   Close(HelpFile);
  END;
END;

PROCEDURE DisplayHelp;
VAR HelpFile     : TEXT;
    RepFile      : TEXT;
    InStr,OutStr : STRING;
    HelpFileName : STRING[13];
    I,J,Err      : INTEGER;
    HelpFound    : BOOLEAN;

  FUNCTION CharFileRpt(Ns : BYTE; Ochar : Char) : Char;
  VAR OutStr : STRING;
  BEGIN
   FillChar(OutStr,Ns,OChar);
   OutStr[0] := CHR(Ns-1);
   Write(RepFile,OutStr);
   CharFileRpt := Ochar;
  END;

 PROCEDURE DoHeader;
 VAR ProgramHeading,ReportTitle : STRING;
     CopyRightInfo :STRING;
     FileTitleX : STRING;
 BEGIN
  FileTitleX := COPY(InStr,5,Length(InStr));
  CopyRightInfo  := 'V'+VERSION_NUMBER+' (c)'+COPYRIGHT;
  ProgramHeading := Config_Rec^.Conf_Banner+Centered('Formix 2',77-Length(CopyRightInfo)-Length(Config_Rec^.Conf_Banner))
                    +CopyRightInfo;
  ReportTitle    := 'Help File - '+Stripped(FileTitleX,Length(FileTitleX),' ');
  Writeln(RepFile,CHighWrite,' ',CharFileRpt(77,'-'),' ');
  Writeln(RepFile,'|',COPY(ProgramHeading+SPACE_STRING,1,77),'|');
  Writeln(RepFile,'|',CharFileRpt(77,' '),'|');
  Writeln(RepFile,'| ',COPY(Time,1,5),' ',Date,'  ',
                  Centered(ReportTitle,40),
                   '                  |');
  Writeln(RepFile,' ',CharFileRpt(77,'-'),' ',CNormal);
  WriteLn(RepFile);
 END;

BEGIN
 IF HelpFuncReq = HelpOff THEN EXIT;
 Assign(HelpFile,Config_Rec^.Conf_TPath+'FORMIX.HLP');
 {$I-}
 Reset(HelpFile);
 {$I+}
 IF IOResult = 0 THEN
  BEGIN
   HelpFound := FALSE;
   REPEAT
    IF EOF(HelpFile) THEN BREAK;
    ReadLn(HelpFile,InStr);
    IF InStr[1] = '@' THEN
     BEGIN
      VAL(COPY(InStr,2,3),J,Err);
      IF (Err = 0) AND (J = HelpFuncReq) THEN HelpFound := TRUE;
     END;
   UNTIL HelpFound;
   IF HelpFound THEN
    BEGIN
     HelpFileName := CreateAFileWithExtn(RepFile,'HLP');
     DoHeader;
     ReadLn(HelpFile,InStr);
     WHILE (NOT Eof(HelpFile)) AND (InStr[1] <> '@') DO
      BEGIN
       IF InStr[1] <>'@' THEN
        BEGIN
         I := Pos('#',InStr);
         IF I<>0 THEN
          BEGIN
           OutStr:= COPY(InStr,1,I-1)+CHighWrite+COPY(InStr,I+1,Length(InStr))+CNormal;
          END
         ELSE
          BEGIN
           I := Pos('@',InStr);
           IF I <> 0 THEN
            BEGIN
             OutStr := COPY(InStr,1,I-1)+CHighWrite;
             SYSTEM.Delete(InStr,1,I);
             I := Pos(' ',Instr);
             OutStr := OutStr+COPY(InStr,1,I)+CNormal+Copy(Instr,I+1,Length(Instr));
            END
           ELSE OutStr := InStr;
          END;
         WriteLn(RepFile,OutStr);
        END;
       ReadLn(HelpFile,InStr);
      END;
     Close(RepFile);
     Show_Help(HelpFileName);
     KillReportFile(HelpFileName);
    END;
   Close(HelpFile);
  END;
END;

BEGIN
 HelpFuncReq := HelpOff;
END.
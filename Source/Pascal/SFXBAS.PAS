(****************************************************************************
*  UNIT          : SFXEltrn                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 15/09/97                                                 *
*  PURPOSE       : Eltron Thermal Printer Stuff                             *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXBas;
INTERFACE
USES Crt,F6StdCtv,F6StdUtl,FXFWork,FXFTrn,SFXTList,SFXEltrn,SFXPorts,SFXGraph,
     SFXStd,FxFIngr,F6DtConv,FXFRcp,FXDetail,FxFIni,SfxKbd,SFXEdit,SfxBtn,
     FXModCtv,SFXMsg,F6StdWn1,FXStdUt1,SfxUtils,FXFMix,SFXCurr,FXFUsers;


TYPE TTicketTypes = (TranTicket,MixTicket,PartialMixTicket);

PROCEDURE Print_Eltron_Ticket(TranRec : PTranRecord;
                              OrdHRec : PWOHeaderRecord;
                              OrdLRec : PWOLineRecord;
                              CurrentMixBatchStr : TBatchRef;
                              PrintAllDetails : BOOLEAN;
                              TicketType : TTicketTypes;
                              FileName  : STRING;
                              Eltron2   : BOOLEAN);

(*

PROCEDURE AddFunctionStr(FunctionName : STRING;FuncPtr : TFunctionStr;Params : BOOLEAN);
PROCEDURE AddFunctionInt(FunctionName : STRING;FuncPtr : TFunctionInt;Params : BOOLEAN);
PROCEDURE AddFunctionNul(FunctionName : STRING;FuncPtr : TFunctionNul;Params : BOOLEAN);
FUNCTION  CalculateValue(CommandStr : STRING) : LONGINT;
FUNCTION  ProcessCommandStr(CommandStr : STRING) : STRING;
PROCEDURE SplitStr(StrToSplit:STRING;VAR Str1,Str2 : STRING);
FUNCTION  FindCharInStr(CH : CHAR;Str : STRING): INTEGER;
*)
PROCEDURE AddBasicFunctions(Printer2 : BOOLEAN);
(*
FUNCTION SendCommsStr(Str : STRING;Port : WORD) : BOOLEAN;
PROCEDURE GetCommsError(Port : WORD);
*)

IMPLEMENTATION

CONST
      XOFF = 19;
      XON  = 17;

VAR CommunicationTimeOut : LONGINT;
    LastCommsError : INTEGER;

TYPE TFunctionStr  = FUNCTION (CommandStr : STRING) : STRING;
TYPE TFunctionInt  = FUNCTION (CommandStr : STRING) : LONGINT;
TYPE TFunctionNul  = PROCEDURE(CommandStr : STRING);

TYPE TCommandLine = STRING[132];

TYPE
     PFunctionListStr = ^TFunctionListStr;
     TFunctionListStr = PACKED RECORD
      FunctionName : STRING[30];
      Next         : PFunctionListStr;
      Params       : BOOLEAN;
      FuncPtr      : TFunctionStr;
     END;

     PFunctionListInt = ^TFunctionListInt;
     TFunctionListInt = PACKED RECORD
      FunctionName : STRING[30];
      Next         : PFunctionListInt;
      Params       : BOOLEAN;
      FuncPtr      : TFunctionInt;
     END;

     PFunctionListNul = ^TFunctionListNul;
     TFunctionListNul = PACKED RECORD
      FunctionName : STRING[30];
      Next         : PFunctionListNul;
      Params       : BOOLEAN;
      FuncPtr      : TFunctionNul;
     END;


TYPE TVarTypes = (vtString,vtDouble,vtInt);

TYPE PVarRec = ^TVarRec;
     TVarRec = PACKED RECORD
      VarName : STRING[20];
      VarType : TVarTypes;
      Next    : PVarRec;
      CASE INTEGER OF
       0 : (StrVar : STRING[80]);
       1 : (DblVar : DOUBLE);
       2 : (IntVar : LONGINT);
     END;

TYPE PFileLine = ^TFileLine;
     TFileLine = PACKED RECORD
      StrLine : TCommandLine;
      LineNo  : LONGINT;
      Next    : PFileLine;
     END;

TYPE PCallStack = ^TCallStack;
     TCallStack = PACKED RECORD
      LineNo        : INTEGER;
      CommandAtLine : TCommandLine;
      Next          : PCallStack;
     END;

     PForLoop = ^TForLoop;
     TForLoop = PACKED RECORD
      LineNo : INTEGER;
      ForVar : PVarRec;
      MaxVal : LONGINT;
      CommandAtLine : TCommandLine;
      Next   : PForLoop;
     END;

    PIFLoop = ^TIFLoop;
    TIFLoop = PACKED RECORD
     LineNo : INTEGER;
     SkipToEndIfElse : BOOLEAN;
     Ignore : BOOLEAN;
     Next   : PIfLoop;
    END;

VAR VarHeader      : PVarRec;
    FileLineHeader : PFileLine;
    AnErrorOccured : BOOLEAN;
    CurrentLine    : PFileLine;

    StackPtr     : PCallStack;
    ForLoopStack : PForLoop;
    IfLoopStack  : PIfLoop;

    FuncListStr  : PFunctionListStr;
    FuncListInt  : PFunctionListInt;
    MainFuncList : PFunctionListNul;

    TRNList     : PTRNList;
    CurrentIng  : PTRNList;
    Filter      : TBuildFilter;

    BarReadOn   : BOOLEAN;
    ErrorInLine : BOOLEAN;

    TranPtr  : PTranRecord;
    WorkHRec : PWOHeaderRecord;
    WorkLRec : PWOLineRecord;
    CurrMixBatStr : TBatchRef;
    TicketNo : LONGINT;

    EltronPort : WORD;

    EPL2       : BOOLEAN;

    XPos,YPos   : INTEGER;
    Dir         : INTEGER;
    FontHoriz   : INTEGER;
    FontVert    : INTEGER;
    ReverseChar : CHAR;
    EPL2BarType : STRING[5];
    BarReadChar : CHAR;
    BarRatioNarrow,
    BarRatioWide : INTEGER;
    BarHeight : INTEGER;
    EPL2Tickets : INTEGER;
    FontType  : INTEGER;

    CommunicationError : BOOLEAN;

    TheTicketType : TTicketTypes;


PROCEDURE GetCommsError(Port : WORD);
VAR ByteIn : BYTE;
    NeedXOn : BOOLEAN;
    CommsStr : STRING[10];
    ErNo : INTEGER;
    CommsTimeOutError : BOOLEAN;
    ErrStr : STRING[80];
    XOnWin : PSwitchWindow;
    ExitXOnCheck : BOOLEAN;

    FUNCTION GetCommsByteWithTimeOut(TimeOut : LONGINT): BOOLEAN;
    VAR GotByte : BOOLEAN;
        Count : LONGINT;
    BEGIN
     GotByte := FALSE;
     Count := TimeOut;
     REPEAT
      IF (IsSerialDataAvailable(Port)) THEN
       BEGIN
        ReadSerialByte(Port,ByteIn,-1);
        GotByte := TRUE;
       END
      ELSE Delay(1);
      DEC(Count);
     UNTIL (GotByte) OR (Count = 0);
     IF (NOT gotByte) THEN CommsTimeOutError := TRUE;
     GetCommsByteWithTimeOut := GotByte;
    END;

    PROCEDURE GetCommsStr(StrLen : INTEGER);
    VAR I : INTEGER;
    BEGIN
     CommsStr := '';
     FOR I := 1 TO StrLen DO
      BEGIN
       IF (GetCommsByteWithTimeOut(CommunicationTimeOut)) THEN
        BEGIN
         LastCommsError := ByteIn;
         CommsStr := CommsStr + Char(ByteIn);
        END;
       IF (LastCommsError = 17) THEN NeedXOn := FALSE;
      END;
    END;

BEGIN
 ErrStr := '';
 NeedXOn := FALSE;
 CommstimeOutError := FALSE;
 {Read Byte From COMMS Port}
 WHILE (LastCommsError = -1) DO
  BEGIN
   IF (GetCommsByteWithTimeout(CommunicationTimeOut)) THEN
    LastCommsError := ByteIn;
   IF (CommsTimeOutError) THEN
    BEGIN
     Disp_Error_Msg('Printer Communications Timeout. Check Printer Is Switch On And Connected');
     EXIT;
    END;
  END;

 IF (LastCommsError = ACK) THEN
  BEGIN
   {This will be removed}
{   Disp_Error_Msg('Printed OK');}
   EXIT;
  END;

 IF (LastCommsError = XOFF) THEN
  BEGIN
   NeedXOn := TRUE;
   {IF XOFF THEN WAIT FOR NEXT BYTE}
   IF (GetCommsByteWithTimeout(CommunicationTimeOut)) THEN
    BEGIN
     LastCommsError := ByteIn;
     IF (LastCommsError = XON) THEN
      BEGIN
       NeedXOn := FALSE;
      END;
    END;
   IF (CommsTimeOutError) THEN
    BEGIN
     Disp_Error_Msg('Communications Time out With Printer. Check Printer Is Switch On And Connected');
     EXIT;
    END;
  END;

 IF (LastCommsError = NAK) THEN
  BEGIN
   {Get Error Number}
   GetCommsStr(2);
   ErNo := StringToLong(CommsStr);
   CASE ErNo OF
    01 : ErrStr:= 'Syntax Error In Program Line '+IntToStr(CurrentLine^.LineNo,1);
    02 : ErrStr:= 'Object Exceeds Image Buffer Border';
    03 : ErrStr:= 'Data Length Error Line '+IntToStr(CurrentLine^.LineNo,1);
    04 : ErrStr:= 'Insufficent Memory To Store Form';
    05 : ErrStr:= 'Memory Configuration Error';
    06 : ErrStr:= 'RS232 Err';
    07 : BEGIN
          GetCommsStr(4);
          ErrStr:= 'Out Of Paper Or Ribon. Add New Stock. '+COPY(CommsStr,2,3)+ ' ticket(s) remaining to print';
    END;
    08 : ErrStr:= 'Form, PCX or Internal Font Name Duplicate';
    09 : ErrStr:= 'Form, PCX or Internal Font Not Found';
    16 : ErrStr:= 'Not In Data Entry Mode,"?" Entered Is Not Valid';
    50 : ErrStr:= 'Does Not Fit In Area Specified Line '+IntToStr(CurrentLine^.LineNo,1);
    51 : ErrStr:= 'Data Length To Long Line '+IntToStr(CurrentLine^.LineNo,1);
    ELSE ErrStr:= 'Error '+IntToStr(ErNo,1)+' In Line '+IntToStr(CurrentLine^.LineNo,1);
   END;
  END;

 IF (NeedXOn) THEN
  BEGIN
   EXITXOnCheck := FALSE;
   New(XOnWin,Init(10,380,629,450,StdWin,ErrStr+CRLF+
         'Clear Error On Printer or Press Here To Continue',@ExitXOnCheck));
   ShowMouseCursor;
   WHILE (NeedXOn AND (NOT ExitXOnCheck)) DO
    BEGIN
     ScreenRead^.Execute;
     IF (IsSerialDataAvailable(Port)) THEN
      BEGIN
       ReadSerialByte(Port,ByteIn,-1);
       IF (ByteIn = 17) THEN NeedXOn := FALSE;
      END;
    END;
   Dispose(XOnWin,Done);
  END
 ELSE IF (NOT NowtButSpace(ErrStr)) THEN Disp_Error_Msg(ErrStr);
END;

FUNCTION SendCommsStr(Str : STRING;Port : WORD) : BOOLEAN;
VAR I      : INTEGER;
    ByteIn : BYTE;
    Count  : LONGINT;
{$IFDEF PRINTDEBUG}
    LOGF    : TEXT;
    LogOpen : INTEGER;
{$ENDIF}
BEGIN
{$IFDEF PRINTDEBUG}
    ASSIGN(LOGF,'PRINTER.BUG');
{$I-}
    Append(LOGF);
{$I+}
    LogOpen := IOResult;
    IF LogOpen = 2 THEN
     BEGIN
{$I-}
      ReWrite(LOGF);
{$I+}
      LogOpen := IOResult;
     END;
    IF LogOpen = 0 THEN
     BEGIN
      Write(LOGF,Str);
      Close(LOGF)
     END;
{$ENDIF}

 SendCommsStr := FALSE;
 FOR I := 1 TO Length(Str) DO
  BEGIN
   WriteByteToPort(Port,Ord(Str[I]),0);
   IF (IsSerialDataAvailable(Port)) THEN
    BEGIN
     ReadSerialByte(Port,ByteIn,-1);

     IF (ByteIn = XOFF) THEN
      BEGIN
       ByteIn := 0;
       Count := CommunicationTimeOut;
       REPEAT
        IF (IsSerialDataAvailable(Port)) THEN
         BEGIN
          ReadSerialByte(Port,ByteIn,-1);
         END
        ELSE Delay(1);
        DEC(Count);
       UNTIL (ByteIn = XON) OR (Count = 0);
       IF (ByteIn <> XON) THEN
        BEGIN
         SendCommsStr := TRUE;
         EXIT;
        END;
      END
     ELSE IF (EPL2) THEN
      BEGIN
       LastCommsError := ByteIn;
       GetcommsError(Port);
      END;
    END;
  END;
END;



PROCEDURE BufferOut(Str : STRING);
BEGIN
{ Write(Str);}
 IF (EPL2) THEN Str := Str + CHAR(10);
 CommunicationError := SendCommsStr(Str,EltronPort);
END;


PROCEDURE ClearLinkedLists;
VAR VarDel      : PVarRec;
    FileLineDel : PFileLine;
    StackPtrDel : PCallStack;
    ForDel      : PForLoop;
    IfDel       : PIfLoop;
BEGIN
 WHILE (VarHeader <> NIL) DO
  BEGIN
   VarDel    := VarHeader;
   VarHeader := VarHeader^.Next;
   Dispose(VarDel);
  END;

 WHILE (FileLineHeader <> NIL) DO
  BEGIN
   FileLineDel  := FileLineHeader;
   FileLineHeader := FileLineHeader^.Next;
   Dispose(FileLineDel);
  END;

 WHILE (StackPtr <> NIL) DO
  BEGIN
   StackPtrDel  := StackPtr;
   StackPtr     := StackPtr^.Next;
   Dispose(StackPtrDel);
  END;

 WHILE (ForLoopStack <> NIL) DO
  BEGIN
   ForDel := ForLoopStack;
   ForLoopStack := ForLoopStack^.Next;
   Dispose(ForDel);
  END;

 WHILE (IfLoopStack <> NIL) DO
  BEGIN
   IfDel := IfLoopStack;
   IfLoopStack := IfLoopStack^.Next;
   Dispose(IfDel);
  END;

 VarHeader := NIL;
 FileLineHeader := NIL;
 StackPtr     := NIL;
 ForLoopStack := NIL;
 IfLoopStack  := NIL;
END;


PROCEDURE AddFunctionStr(FunctionName : STRING;FuncPtr : TFunctionStr;Params : BOOLEAN);
VAR NewFunc : PFunctionListStr;
BEGIN
 New(NewFunc);
 NewFunc^.FunctionName := StrToUpper(FunctionName);
 NewFunc^.FuncPtr      := FuncPtr;
 NewFunc^.Params       := Params;
 NewFunc^.Next         := FuncListStr;
 FuncListStr           := NewFunc;
END;

PROCEDURE AddFunctionNul(FunctionName : STRING;FuncPtr : TFunctionNul;Params : BOOLEAN);
VAR NewFunc : PFunctionListNul;
BEGIN
 New(NewFunc);
 NewFunc^.FunctionName := StrToUpper(FunctionName);
 NewFunc^.FuncPtr      := FuncPtr;
 NewFunc^.Params       := Params;
 NewFunc^.Next         := MainFuncList;
 MainFuncList          := NewFunc;
END;


PROCEDURE AddFunctionInt(FunctionName : STRING;FuncPtr : TFunctionInt;Params : BOOLEAN);
VAR NewFunc : PFunctionListInt;
BEGIN
 New(NewFunc);
 NewFunc^.FunctionName := StrToUpper(FunctionName);
 NewFunc^.FuncPtr      := FuncPtr;
 NewFunc^.Params       := Params;
 NewFunc^.Next         := FuncListInt;
 FuncListint           := NewFunc;
END;


FUNCTION FindFunctionStr(FunctionName : STRING) : PFunctionListStr;
VAR LoopFunc : PFunctionListStr;
BEGIN
 FunctionName := StrToUpper(FunctionName);
 LoopFunc := FuncListStr;
 WHILE (LoopFunc <> NIL) DO
  BEGIN
   IF (LoopFunc^.FunctionName = FunctionName) THEN
    BEGIN
     FindFunctionStr := LoopFunc;
     EXIT;
    END;
   LoopFunc := LoopFunc^.Next;
  END;
 FindFunctionStr := NIL;
END;

FUNCTION FindFunctionInt(FunctionName : STRING) : PFunctionListInt;
VAR LoopFunc : PFunctionListInt;
BEGIN
 FunctionName := StrToUpper(FunctionName);
 LoopFunc := FuncListInt;
 WHILE (LoopFunc <> NIL) DO
  BEGIN
   IF (LoopFunc^.FunctionName = FunctionName) THEN
    BEGIN
     FindFunctionInt := LoopFunc;
     EXIT;
    END;
   LoopFunc := LoopFunc^.Next;
  END;
 FindFunctionInt := NIL;
END;

FUNCTION FindFunctionNul(FunctionName : STRING) : PFunctionListNul;
VAR LoopFunc : PFunctionListNul;
BEGIN
 FunctionName := StrToUpper(FunctionName);
 LoopFunc := MainFuncList;
 WHILE (LoopFunc <> NIL) DO
  BEGIN
   IF (LoopFunc^.FunctionName = FunctionName) THEN
    BEGIN
     FindFunctionNul := LoopFunc;
     EXIT;
    END;
   LoopFunc := LoopFunc^.Next;
  END;
 FindFunctionNul := NIL;
END;



PROCEDURE Error(Str : STRING);
BEGIN
 AnErrorOccured := TRUE;
 Write(Str);
END;

PROCEDURE ReadInFile(FileName : STRING;ReportErrors : BOOLEAN);
VAR ReadFile : TEXT;
    ReadLine : TCommandLine;
    IOError  : INTEGER;



   PROCEDURE AddLineRec;
   Var LineNo : INTEGER;
       SpPos  : INTEGER;
       ValErr : INTEGER;
       LineLoop,
       NewLine,
       LastLine : PFileLine;
   BEGIN
    Stripped(ReadLine,Length(ReadLine),' ');
    SpPos := POS(' ',ReadLine);
    VAL(COPY(ReadLine,1,SpPos-1),LineNo,ValErr);
    SYSTEM.DELETE(ReadLine,1,SpPos);
    Stripped(ReadLine,Length(ReadLine),' ');
    IF (ValErr = 0) THEN
     BEGIN
      LineLoop := FileLineHeader;
      IF (LineLoop = NIL) THEN
       BEGIN
        New(FileLineHeader);
        FileLineHeader^.Next   := NIL;
        FileLineHeader^.LineNo := LineNo;
        FileLineHeader^.StrLine:= ReadLine;
       END
      ELSE
       BEGIN
        LastLine := NIL;
        WHILE (LineLoop <> NIL) AND (LineLoop^.LineNo < LineNo) DO
         BEGIN
          LastLine := LineLoop;
          LineLoop := LineLoop^.Next;
         END;
        IF (LineLoop = NIL) THEN
         BEGIN
          New(LineLoop);
          LineLoop^.Next   := NIL;
          LineLoop^.LineNo := LineNo;
          LineLoop^.StrLine:= ReadLine;
          LastLine^.Next   := LineLoop;
         END
        ELSE IF (LastLine = NIL) THEN
         BEGIN
          New(LastLine);
          LastLine^.Next := FileLineHeader;
          FileLineHeader := LastLine;
          LastLine^.LineNo := LineNo;
          LastLine^.StrLine := ReadLine;
         END
        ELSE
         BEGIN
          IF (LineLoop^.LineNo = LineNo) THEN
           BEGIN
            IF (ReportErrors) THEN Error('Duplicate Line '+IntToStr(LineNo,1)+' '+ReadLine);
            LineLoop^.StrLine := ReadLine;
           END
          ELSE
           BEGIN
            New(NewLine);
            NewLine^.LineNo := LineNo;
            NewLine^.Next   := LineLoop;
            LastLine^.Next  := NewLine;
            NewLine^.StrLine:= ReadLine;
           END;
         END;
       END;
     END
    ELSE IF (ReportErrors) THEN
     BEGIN
      Error('Invalid Line No '+IntToStr(LineNo,1)+' '+ReadLine);
     END;
   END;



BEGIN
 IF (NowtButSpace(FileName)) THEN EXIT;
 AnErrorOccured := FALSE;

 Assign(ReadFile,FileName);
 {$I-}
 Reset(ReadFile);
 {$I+}
 IOError := IOResult;
 IF (IOError = 0) THEN
  BEGIN
   WHILE (NOT Eof(ReadFile)) DO
    BEGIN
     ReadLn(ReadFile,ReadLine);
     ReadLine := StrToUpper(ReadLine);
     AddLineRec;
    END;
   Close(ReadFile);
  END
 ELSE
  BEGIN
   IF (ReportErrors) THEN
    Error('Error Opening File '+FileName+' Error = '+IntToStr(IOError,1));
  END;
END;


FUNCTION AddFindVar(VarName : STRING) : PVarRec;
VAR LoopVar,NewVar : PVarRec;
    VarType : INTEGER;
BEGIN
 LoopVar := VarHeader;
 WHILE (LoopVar <> NIL) DO
  BEGIN
   IF (StringIComp(LoopVar^.VarName,VarName) = 0) THEN
    BEGIN
     AddFindVar := LoopVar;
     EXIT;
    END;
   LoopVar := LoopVar^.Next;
  END;
 {No Varibles Found So Add A New One}
 New(NewVar);
 FillChar(NewVar^
 ,Sizeof(TVarRec),0);
 NewVar^.VarName := VarName;
{ VarType := FindCharInStr('%',VarName);}
 IF (VarName[Length(VarName)] = '%') THEN
  NewVar^.VarType := vtInt
 ELSE
  NewVar^.VarType := vtString;
 CASE NewVar^.VarType OF
  vtString : NewVar^.StrVar := '';
  vtDouble : NewVar^.DblVar := 0.0;
  vtInt    : NewVar^.IntVar := 0;
 END;
 NewVar^.Next := VarHeader;
 VarHeader    := NewVar;
 AddFindVar   := NewVar;
END;

{Takes A String Of Vars and Numbers And Arithmetic Signs And Combines Into}
{A Single Integer}
FUNCTION CalculateValue(CommandStr : STRING) : LONGINT;
CONST ItsInt = 1;
      ItsStr = 2;
      ItsVar = 3;
      ItsAri = 4;
      ItsFunc= 5;
VAR
    MatchVar : PVarRec; {Used For Adding Subtracting Etc}
    VarType : INTEGER;
    AriType : CHAR;
    Value   : LONGINT;
    MustBeAri : BOOLEAN;

    Quotes    : INTEGER;
    I,J,K     : INTEGER;
    FuncPtr   : PFunctionListInt;


    PROCEDURE AddToValue(WithValue : LONGINT);
    BEGIN
     CASE AriType OF
      '+' : Value := Value + WithValue;
      '-' : Value := Value - WithValue;
     END;
    END;

BEGIN
 Value := 0;
 AriType := '+'; {Default Start is addition}
 Stripped(CommandStr,Length(CommandStr),' ');
 WHILE (Length(CommandStr) > 0) DO
  BEGIN
   IF (CommandStr[1] IN ['+','-','*','/']) THEN
    BEGIN
     VarType := ItsAri;
     AriType := CommandStr[1];
     SYSTEM.DELETE(CommandStr,1,1);
    END
   ELSE
    BEGIN
     I := 0;
     WHILE (I < Length(CommandStr)) DO
      BEGIN
       Inc(I);
       IF (CommandStr[I] IN [' ','+','-','*','/','%','(']) THEN BREAK;
      END;
     IF (CommandStr[I] = '(') THEN
      BEGIN
       J := 0; Quotes := 1; K := I+1;
       FuncPtr := FindFunctionInt(COPY(CommandStr,1,I-1));
       WHILE (I < Length(CommandStr)) AND (Quotes > 0) DO
        BEGIN
         Inc(I);
         INC(J);
         IF (CommandStr[I] = '(') THEN Inc(Quotes)
         ELSE IF (CommandStr[I] = ')') THEN Dec(Quotes);
        END;
       IF (FuncPtr <> NIL) THEN
        BEGIN
         AddToValue(FuncPtr^.FuncPtr(COPY(CommandStr,K,J-1)));
        END
       ELSE EXIT;
      END
     ELSE IF (CommandStr[I] IN [' ','+','-','*','/']) THEN
      BEGIN
       {Must Be A Number}
       AddToValue(StringtoLong(Copy(CommandStr,1,I-1)));
       IF (CommandStr[I] IN ['+','-','*','/']) THEN Dec(I);
      END
     ELSE IF (CommandStr[I] = '%') THEN
      BEGIN
       MatchVar := AddFindVar(Copy(CommandStr,1,I));
       AddToValue(MatchVar^.IntVar);
      END
     ELSE IF (I = Length(CommandStr)) THEN
      BEGIN
       {Must Be A Number}
       AddToValue(StringtoLong(Copy(CommandStr,1,I)));
      END;
     MustBeAri :=  (CommandStr[I] IN [' ','%']);

     SYSTEM.DELETE(CommandStr,1,I);
     {Next Character Must Be A Arithmetic Symbol}
     Stripped(CommandStr,Length(CommandStr),' ');
     IF (Length(CommandStr) > 0) THEN
      BEGIN
       IF (MustBeAri) AND (NOT (CommandStr[1] IN ['+','-','*','/'])) THEN BREAK;
      END;
    END;
  END;
 CalculateValue := Value;
END;


{Converts A String With $ and % to a long string}
FUNCTION ProcessCommandStr(CommandStr : STRING) : STRING;
VAR
    MatchVar  : PVarRec; {Used For Adding strings}
    Value     : STRING[80];
    MustBeAri : BOOLEAN;


    Quotes    : INTEGER;
    I,J,K     : INTEGER;
    FuncPtr   : PFunctionListStr;

    PROCEDURE AddToValue(WithValue : STRING);
    BEGIN
     Value := Value + WithValue;
    END;

BEGIN
 Value   := '';
 Stripped(CommandStr,Length(CommandStr),' ');
 WHILE (Length(CommandStr) > 0) DO
  BEGIN
   IF (CommandStr[1] IN ['+']) THEN
    BEGIN
     SYSTEM.DELETE(CommandStr,1,1);
     MustBeAri := FALSE;
    END
   ELSE IF (CommandStr[1] = '"') THEN
    BEGIN
     SYSTEM.DELETE(CommandStr,1,1);
     I := POS('"',CommandStr);
     AddToValue(COPY(CommandStr,1,I-1));
     SYSTEM.DELETE(CommandStr,1,I);
     MustBeAri := TRUE;
    END
   ELSE
    BEGIN
     I := 0;
     WHILE (I < Length(CommandStr)) DO
      BEGIN
       Inc(I);
       IF (CommandStr[I] IN ['+','(','$']) THEN BREAK;
      END;

     IF (CommandStr[I] = '(') THEN
      BEGIN
       J := 0; Quotes := 1; K := I+1;
       FuncPtr := FindFunctionStr(COPY(CommandStr,1,I-1));
       WHILE (I < Length(CommandStr)) AND (Quotes > 0) DO
        BEGIN
         Inc(I);
         INC(J);
         IF (CommandStr[I] = '(') THEN Inc(Quotes)
         ELSE IF (CommandStr[I] = ')') THEN Dec(Quotes);
        END;
       IF (FuncPtr <> NIL) THEN
        BEGIN
         AddToValue(FuncPtr^.FuncPtr(COPY(CommandStr,K,J-1)));
        END
       ELSE EXIT;
      END
     ELSE IF (CommandStr[I] = '+') THEN
      BEGIN
       {Must Be A Number}
       AddToValue(Copy(CommandStr,1,I-1));
       Dec(I);
      END
     ELSE IF (CommandStr[I] = '$') THEN
      BEGIN
       FuncPtr := FindFunctionStr(COPY(CommandStr,1,I));
       IF (FuncPtr <> NIL) THEN
        BEGIN
         Inc(I);
         J := 0; Quotes := 1; K := I+1;
         WHILE (I < Length(CommandStr)) AND (Quotes > 0) DO
          BEGIN
           Inc(I);
           INC(J);
           IF (CommandStr[I] = '(') THEN Inc(Quotes)
           ELSE IF (CommandStr[I] = ')') THEN Dec(Quotes);
          END;
         AddToValue(FuncPtr^.FuncPtr(COPY(CommandStr,K,J-1)));
        END
       ELSE
        BEGIN
         MatchVar := AddFindVar(Copy(CommandStr,1,I));
         AddToValue(MatchVar^.StrVar);
        END;
      END
     ELSE IF (I = Length(CommandStr)) THEN
      BEGIN
       {Must Be A Number}
       AddToValue(Copy(CommandStr,1,I));
      END;
     MustBeAri :=  (CommandStr[I] IN [' ','%']);
     SYSTEM.DELETE(CommandStr,1,I);
     {Next Character Must Be A Arithmetic Symbol}
    END;
   Stripped(CommandStr,Length(CommandStr),' ');
   IF (Length(CommandStr) > 0) THEN
    BEGIN
     IF (MustBeAri) AND (NOT (CommandStr[1] IN ['+','-','*','/'])) THEN BREAK;
    END;
  END;
 ProcessCommandStr := Value;
END;


FUNCTION FindStrInStr(FindStr : STRING;Str : STRING): INTEGER;
VAR Brackets : INTEGER;
    Quotes   : BOOLEAN;
    I        : INTEGER;
BEGIN
 Quotes := FALSE;
 Brackets := 0;
 I := POS(FindStr[1],Str);
 IF (I = 0) THEN
  BEGIN
   FindStrInStr := Length(Str)+1;
   EXIT;
  END;
 FOR I := 1 TO Length(Str) DO
  BEGIN
   IF (Str[I] = '"') THEN Quotes := NOT Quotes;
   IF (NOT Quotes) THEN
    BEGIN
     IF (Str[I] = '(') THEN Inc(Brackets)
     ELSE IF (Str[I] = ')') THEN Dec(Brackets);
     IF (Brackets = 0) AND (Str[I] = FindStr[1]) THEN
      BEGIN
       IF (FindStr = COPY(Str,I,Length(FindStr))) THEN
        BEGIN
         FindStrInStr := I;
         EXIT;
        END;
      END;
    END;
  END;
 FindStrInStr := Length(Str)+1
END;


FUNCTION FindCharInStr(CH : CHAR;Str : STRING): INTEGER;
VAR Brackets : INTEGER;
    Quotes   : BOOLEAN;
    I        : INTEGER;
BEGIN
 Quotes := FALSE;
 Brackets := 0;
 I := POS(CH,Str);
 IF (I = 0) THEN
  BEGIN
   FindCharInStr := Length(Str)+1;
   EXIT;
  END;
 FOR I := 1 TO Length(Str) DO
  BEGIN
   IF (Ch <> '"') AND (Str[I] = '"') THEN Quotes := NOT Quotes;
   IF (NOT Quotes) THEN
    BEGIN
     IF (Str[I] = '(') THEN Inc(Brackets)
     ELSE IF (Str[I] = ')') THEN Dec(Brackets);
     IF (Brackets = 0) AND (Str[I] = CH) THEN
      BEGIN
       FindCharInStr := I;
       EXIT;
      END;
    END;
  END;
 FindCharInStr := Length(Str)+1
END;

{Splits A String Using a comma}
PROCEDURE SplitStr(StrToSplit:STRING;VAR Str1,Str2 : STRING);
VAR
    I : INTEGER;
BEGIN
 I := FindCharInStr(',',StrToSplit);
 Str1 := COPY(StrToSplit,1,I-1);
 Str2 := COPY(StrToSplit,I+1,Length(StrToSplit));
END;


PROCEDURE ProcessCommand;
VAR I : INTEGER;
   CommandFound : BOOLEAN;
   CommandLine  : TCommandLine;
   CommandStr   : TCommandLine;

   NewLine      : BOOLEAN;

  PROCEDURE StripCom(By : INTEGER);
  BEGIN
   IF (By > Length(CommandLine)) THEN BY := Length(CommandLine);
   IF (By <> 0) THEN SYSTEM.DELETE(CommandLine,1,By);
   Stripped(CommandLine,Length(CommandLine),' ');
  END;


  {Returns Pos Of Ch OR Length Of Command Line}
  FUNCTION FindChar(Ch : Char) : INTEGER;
  VAR P : INTEGER;
  BEGIN
   FindChar := FindCharInStr(Ch,CommandLine);
{   P := POS(Ch,CommandLine);
   IF (P = 0) THEN P := Length(CommandLine)+1;
   FindChar := P;}
  END;



  PROCEDURE AllocateVar(StrVar : BOOLEAN);
  Var VarRec : PVarRec;
      I      : INTEGER;
      Value  : LONGINT;
      Quotes : BOOLEAN;
  BEGIN
   {Format Must Be VarName = assigned Value}
   Stripped(CommandStr,Length(CommandStr),' ');
   VarRec := AddFindVar(CommandStr);
   {Now Remove The Equal Siqn which should be next char}
   IF (CommandLine[1] <> '=') THEN
    BEGIN
     ErrorInLine := TRUE;
     EXIT;
    END;
   {Delete = Sign}
   StripCom(1);
   {If its a string Var Remove Value Between Quotes}
   IF (StrVar) THEN
    BEGIN
     Quotes := FALSE;
     I := FindChar(':');
{     FOR I := 1 TO Length(CommandLine) DO
      BEGIN
       IF (CommandLine[I] = '"') THEN Quotes := NOT Quotes;
       IF (NOT Quotes) AND (CommandLine[I] = ':') THEN
        BEGIN
         DEC(I);
         BREAK;
        END;
      END;}
     VarRec^.StrVar := ProcessCommandStr(Copy(CommandLine,1,I-1));
     StripCom(I-1);
    END
   {If Its A Int Then Convert Value To Integer}
   ELSE
    BEGIN
     I := FindChar(':');
     VarRec^.IntVar := CalculateValue(Copy(CommandLine,1,I-1));
     StripCom(I);
    END;
  END;

  PROCEDURE FindLine(LineNo : INTEGER;CommandAtLine : STRING;SetCommandLine,ForGosub : BOOLEAN);
  VAR LineRec   : PFileLine;
      CallStack : PCallStack;
  BEGIN
   NewLine := TRUE;
   LineRec := FileLineHeader;
   WHILE (LineRec <> NIL) AND (LineRec^.LineNo <> LineNo) DO LineRec := LineRec^.Next;
   IF (LineRec = NIL) THEN
    BEGIN
     ErrorInLine := TRUE;
    END
   ELSE {Line Found}
    BEGIN
     IF (ForGosub) THEN
      BEGIN
       New(CallStack);
       CallStack^.LineNo := CurrentLine^.LineNo;
       CallStack^.CommandAtLine := CommandLine;
       CallStack^.Next := StackPtr;
       StackPtr := CallStack;
      END;
     CurrentLine := LineRec;
     IF (SetCommandLine) THEN
      CommandLine := CommandAtLine
     ELSE
      CommandLine := CurrentLine^.StrLine;
    END;
  END;


  PROCEDURE ProcessIfCommand;
  VAR ConditionStr : TCommandLine;
      I            : INTEGER;
      NewIf        : PIfLoop;


      FUNCTION EvaluateCondition : BOOLEAN;
      VAR EqualPos    : INTEGER;
          PerPos      : INTEGER;
          lLeftSide,
          lRightSide  : LONGINT;
          slLeftSide  : TCommandLine;
          slRightSide : TCommandLine;
          EquateSign  : CHAR;
          EqualLen    : INTEGER;


          FUNCTION FindEquate : BOOLEAN;


            FUNCTION FindSymbol(Ch : CHAR) : BOOLEAN;
            BEGIN
             EqualLen   := 1;
             EquateSign := Ch;
             EqualPos := FindCharInStr(Ch,ConditionStr);
             FindSymbol := EqualPos < Length(ConditionStr);
            END;

            FUNCTION FindSymbols(FindStr : STRING;Symbol : CHAR) : BOOLEAN;
            BEGIN
             EqualLen    := 2;
             EquateSign  := Symbol;
             EqualPos    := FindStrInStr(FindStr,ConditionStr);
             FindSymbols := (EqualPos < Length(ConditionStr));
            END;


          BEGIN
           FindEquate := TRUE;
           IF (FindSymbols('<>','!')) THEN EXIT; {Not Equal}
           IF (FindSymbols('>=','G')) THEN EXIT; {Greater Than OR Equal To}
           IF (FindSymbols('=>','G')) THEN EXIT; {Greater Than OR Equal To}
           IF (FindSymbols('<=','L')) THEN
            EXIT; {Less Than OR Equal To}
           IF (FindSymbols('=<','L')) THEN EXIT; {Less Than OR Equal To}

           IF (FindSymbol('=')) THEN EXIT; {Equal To}
           IF (FindSymbol('<')) THEN EXIT; {less Than}
           IF (FindSymbol('>')) THEN EXIT; {Greater Than}
           FindEquate := FALSE;
          END;

          FUNCTION EquateStr(VAR Str1,Str2 : STRING):BOOLEAN;
          BEGIN
           EquateStr := FALSE;
           CASE EquateSign OF
            '=' : EquateStr := Str1 = Str2;
            '>' : EquateStr := Str1 > Str2;
            '<' : EquateStr := Str1 < Str2;
            '!' : EquateStr := Str1 <> Str2;
            'G' : EquateStr := Str1 >= Str2;
            'L' : EquateStr := Str1 <= Str2;
           END;
          END;

          FUNCTION EquateInt(Int1,Int2 : LONGINT) : BOOLEAN;
          BEGIN
           EquateInt := FALSE;
           CASE EquateSign OF
            '=' : EquateInt := Int1 = Int2;
            '>' : EquateInt := Int1 > Int2;
            '<' : EquateInt := Int1 < Int2;
            '!' : EquateInt := Int1 <> Int2;
            'G' : EquateInt := Int1 >= Int2;
            'L' : EquateInt := Int1 <= Int2;
           END;
          END;

      BEGIN
       IF (NOT FindEquate) THEN
        BEGIN
         EvaluateCondition := FALSE
        END
       ELSE
        BEGIN
         PerPos := FindCharInStr('$',ConditionStr);
         IF (PerPos <= Length(ConditionStr)) THEN
          BEGIN
           slLeftSide  := ProcessCommandStr(COPY(ConditionStr,1,EqualPos-1));
           slRightSide := ProcessCommandStr(COPY(ConditionStr,EqualPos+EqualLen,Length(ConditionStr)));
           EvaluateCondition := EquateStr(slLeftSide,slRightSide)
          END
         ELSE
          BEGIN
           lLeftSide   := CalculateValue(COPY(ConditionStr,1,EqualPos-1));
           lRightside  := CalculateValue(COPY(ConditionStr,EqualPos+EqualLen,Length(ConditionStr)));
           EvaluateCondition := EquateInt(lLeftSide,lRightSide);
          END;
        END;
      END;

  BEGIN
   {Format if condition then commands}
   {else
     if condition then
      commands
     endif
    else
     if condition then
      commands
     else
      commands
     endif
   }
   {Step 1 Take String Upto THEN}
   I := POS('THEN',CommandLine);
   ConditionStr := COPY(CommandLine,1,I-1);
   StripCom(I+3); {Length OF THEN = 4}
   {If Line Containes a condition then dont add to list of if vars}
   IF (Length(CommandLine) > 0) THEN
    BEGIN
     NewLine := TRUE;
     IF (NOT EvaluateCondition) THEN
      BEGIN
       i := POS('ELSE',CommandLine);
       IF (I = 0) THEN
        CommandLine := ''
       ELSE
        BEGIN
         StripCom(I+3)
        END;
      END;
    END
   ELSE
    BEGIN
     New(NewIf);
     NewIf^.LineNo := CurrentLine^.LineNo;
     NewIf^.Next   := IfLoopStack;
     IfLoopStack   := NewIf;
     IF (NewIf^.Next = NIL) THEN
      BEGIN
       NewIf^.SkipToEndIfElse := NOT EvaluateCondition;
       NewIf^.Ignore := FALSE;
      END
     ELSE
      BEGIN
       IF (NewIf^.Next^.SkipToEndIfElse OR NewIf^.Next^.Ignore) THEN
        BEGIN
         NewIf^.SkipToEndIfElse := NOT EvaluateCondition;
         NewIf^.Ignore := TRUE;
        END
       ELSE
        BEGIN
         NewIf^.SkipToEndIfElse := NOT EvaluateCondition;
         NewIf^.Ignore := FALSE;
        END;
      END;
    END;
  END;

  PROCEDURE ProcessElseCommand;
  BEGIN
   IF (IfLoopStack = NIL) THEN EXIT;
   IfLoopStack^.SkipToEndIfElse := NOT IfLoopStack^.SkipToEndIfElse;
  END;

  PROCEDURE ProcessEndIfCommand;
  VAR DelIf : PIfLoop;
  BEGIN
   IF (IfLoopStack = NIL) THEN EXIT;
   DelIf := IfLoopStack;
   IfLoopStack := IfLoopStack^.Next;
   Dispose(DelIf);
  END;

  PROCEDURE ProcessForCommand;
  VAR I : INTEGER;
      VarRec : PVarRec;
      ForRec : PForLoop;
      StartVal,
      EndVal : LONGINT;
      ValErr    : INTEGER;
      Values : PVarRec;
  BEGIN
   {Command IS For Var = start to end }
   I := POS('%',CommandLine);
   IF (I > FindChar(' ')) OR (I > FindChar(':')) THEN
    BEGIN
     ErrorInLine := TRUE;
     EXIT;
    END;
   VarRec := AddFindVar(COPY(CommandLine,1,I));
   Stripcom(I);
   {Now There Should Be Equal sign}
   IF (CommandLine[1] <> '=') THEN
    BEGIN
     ErrorInLine := TRUE;
     EXIT;
    END;
   StripCom(1);
   {Get Start Value}
   I := POS('TO',CommandLine);
   StartVal := CalculateValue(COPY(CommandLine,1,I-1));
(*   IF (CommandLine[I-1] = '%') THEN
    BEGIN
     Values := AddFindVar(Copy(CommandLine,1,I-1));
     StartVal := Values^.IntVar;
    END
   ELSE
    BEGIN
     VAL(COPY(CommandLine,1,I-1),StartVal,ValErr);
     IF (ValErr <> 0) THEN
      BEGIN
       ErrorInLine := TRUE;
       EXIT;
      END;
    END;*)
   StripCom(I+1);
   {Now There Should Be A TO}
   VarRec^.IntVar := StartVal;
{   IF (StringLIComp(CommandLine,'TO',2) <> 0) THEN
    BEGIN
     ErrorInLine := TRUE;
     EXIT;
    END;
   StripCom(2);}
   {Find Finishing Value}
   I := FindChar(':');
   EndVal := CalculateValue(COPY(CommandLine,1,I-1));
{   IF (CommandLine[I-1] = '%') THEN
    BEGIN
     Values := AddFindVar(Copy(CommandLine,1,I-1));
     EndVal := Values^.IntVar;
    END
   ELSE
    BEGIN
     VAL(COPY(CommandLine,1,I-1),EndVal,ValErr);
     IF (ValErr <> 0) THEN
      BEGIN
       ErrorInLine := TRUE;
       EXIT;
      END;
    END;}
   StripCom(I);
   {OK So For Allocate For Loop}
   New(ForRec);
   WITH ForRec^ DO
    BEGIN
     LineNo := CurrentLine^.Lineno;
     ForVar := VarRec;
     MaxVal := EndVal;
     Next   := ForLoopStack;
     CommandAtLine := CommandLine;
    END;
   ForLoopStack := ForRec;
  END;

  PROCEDURE ProcessNextCommand;
  VAR ForLoop : PForLoop;
      VarRec  : PVarRec;
      VarName : STRING[20];
      I       : INTEGER;
  BEGIN
   IF (ForLoopStack = NIL) THEN EXIT;
   {Format is either NEXT of NEXT var name}
   {IF Next Loop To Last For Var Else Find for Var}
   IF (Length(CommandLine) = 0) OR (CommandLine[1] = ':') THEN
    BEGIN
     ForLoop := ForLoopStack;
     VarRec  := ForLoop^.ForVar;
     IF (VarRec^.IntVar < ForLoop^.MaxVal) THEN
      BEGIN
       INC(VarRec^.IntVar);
       FindLine(ForLoop^.LineNo,ForLoop^.CommandAtLine,TRUE,FALSE);
      END
     ELSE {For Loop reached Maximum}
      BEGIN
       ForLoopStack := ForLoopStack^.Next;
       Dispose(ForLoop);
      END;
    END
   ELSE {Specifies A Var Name To Loop To}
    BEGIN
     I := POS('%',CommandLine);
     IF (I > FindChar(' ')) OR (I > FindChar(':')) THEN
      BEGIN
       ErrorInLine := TRUE;
       EXIT;
      END;
     VarName := Copy(CommandLine,1,I);
     StripCom(I);
     WHILE (TRUE) DO
      BEGIN
       ForLoop := ForLoopStack;
       IF (ForLoop <> NIL) THEN
        BEGIN
         VarRec  := ForLoop^.ForVar;
         IF (StringIComp(VarRec^.VarName,VarName) = 0) THEN
          BEGIN
           IF (VarRec^.IntVar < ForLoop^.MaxVal) THEN
            BEGIN
             INC(VarRec^.IntVar);
             FindLine(ForLoop^.LineNo,ForLoop^.CommandAtLine,TRUE,FALSE);
            END
           ELSE {For Loop reached Maximum}
            BEGIN
             ForLoopStack := ForLoopStack^.Next;
             Dispose(ForLoop);
            END;
           EXIT;
          END
         ELSE {NOT Var Name, so remove}
          BEGIN
           ForLoopStack := ForLoopStack^.Next;
           Dispose(ForLoop);
          END;
        END
       ELSE
        BEGIN
         ErrorInLine := TRUE;
         EXIT;
        END;
      END;
    END;
  END;

  PROCEDURE ProcessGotoCommand;
  VAR LineNo : INTEGER;
      I : INTEGER;
  BEGIN
   I := FindChar(':');
   LineNo := CalculateValue(Copy(CommandLine,1,I-1));
   StripCom(I);
   FindLine(LineNo,'',FALSE,FALSE);
  END;

  PROCEDURE ProcessGosubCommand;
  VAR LineNo : INTEGER;
      I : INTEGER;
  BEGIN
   I := FindChar(':');
   LineNo := CalculateValue(Copy(CommandLine,1,I-1));
   StripCom(I);
   FindLine(LineNo,'',FALSE,TRUE);
  END;

  PROCEDURE ProcessReturnCommand;
  VAR LastCall : PCallStack;
  BEGIN
   IF (StackPtr = NIL) THEN EXIT;
   LastCall := StackPtr;
   StackPtr := StackPtr^.Next;
   FindLine(LastCall^.LineNo,LastCall^.CommandAtLine,TRUE,FALSE);
   Dispose(LastCall);
  END;

  PROCEDURE RunCommand;
  VAR FuncToCall : PFunctionListNul;
      I,J,K : INTEGER;
  BEGIN
   Stripped(CommandStr,Length(CommandStr),' ');
   {These Commands Are control Commands}
   IF (StringIComp(CommandStr,'END') = 0 ) THEN
    BEGIN
     CommandLine := '';
     CurrentLine := NIL;
    END
   ELSE IF (StringIComp(CommandStr,'REM') = 0) THEN
    BEGIN
     CommandLine := '';
    END
   ELSE IF (StringIComp(CommandStr,'IF') = 0) THEN
    ProcessIfCommand
   ELSE IF (StringIComp(CommandStr,'ELSE') = 0) THEN
    ProcessElseCommand
   ELSE IF (StringIComp(CommandStr,'ENDIF') = 0) THEN
    ProcessEndIfCommand
   ELSE IF (IfLoopStack = NIL) OR ((NOT IfLoopStack^.ignore) AND
    (NOT IfLoopStack^.SkipToEndIfElse)) THEN
    BEGIN
     IF (StringIComp(CommandStr,'FOR') = 0) THEN
      ProcessForCommand
     ELSE IF (StringIComp(CommandStr,'NEXT') = 0) THEN
      ProcessNextCommand
     ELSE IF (StringIComp(CommandStr,'GOTO') = 0) THEN
      ProcessGotoCommand
     ELSE IF (StringIComp(CommandStr,'GOSUB') = 0) THEN
      ProcessGosubCommand
     ELSE IF (StringIComp(CommandStr,'RETURN') = 0) THEN
      ProcessReturnCommand
     ELSE
      BEGIN
       Stripped(CommandStr,Length(CommandStr),'(');
       I := 0;J := 1;
       WHILE (I < Length(CommandLine)) AND (J > 0) DO
        BEGIN
         Inc(I);
         IF (CommandLine[I] = '(') THEN Inc(J)
         ELSE IF (CommandLine[I] = ')') THEN Dec(J);
        END;

       FuncToCall := FindFunctionNul(CommandStr);
       IF (FunctoCall <> NIL) THEN
        BEGIN
         FuncToCall^.FuncPtr(Copy(CommandLine,1,I-1));
        END;
       StripCom(I);
{       IF (StringIComp(CommandStr,'PRINT') = 0) THEN
        ProcessCommandPrint;}
      END;
    END;
  END;

BEGIN
 CommandLine := CurrentLine^.StrLine;
 ErrorInLine := FALSE;
 NewLine     := TRUE;
 WHILE (Length(CommandLine) > 0) DO
  BEGIN
   IF (NewLine) THEN
    BEGIN
     I := 0;
     NewLine := FALSE;
    END;

   StripCom(0);
   CommandFound := FALSE;
   WHILE (I < Length(CommandLine)) DO
    BEGIN
     Inc(I);
     IF (CommandLine[I] IN [' ','$','%','=',':','(']) THEN
      BEGIN
       CommandFound := TRUE;
       BREAK;
      END;
    END;


   IF (NOT CommandFound) THEN
    BEGIN
     I := Length(CommandLine);
     CommandStr := CommandLine+' ';
    END
   ELSE CommandStr := Copy(CommandLine,1,I);
   StripCom(I);
   IF (CommandStr[Length(CommandStr)] IN [' ','(']) THEN
    BEGIN
     {Its A Command}
     RunCommand;
    END
   ELSE IF (CommandStr[Length(CommandStr)] = '$') THEN
    BEGIN
     {Allocate A String Var}
     AllocateVar(TRUE);
    END
   ELSE IF (CommandStr[Length(CommandStr)] = '%') THEN
    BEGIN
     {Allocate A Int Var}
     AllocateVar(FALSE);
    END
   ELSE IF (CommandStr[Length(CommandStr)] = '=') THEN
    BEGIN
    END
   ELSE IF (CommandStr[Length(CommandStr)] = ':') THEN
    BEGIN
     StripCom(1);
    END;
   {Done Command Now Must Find ':'}

   IF (Length(CommandLine) > 0) AND (NOT NewLine) THEN
    BEGIN
     IF (CommandLine[1] <> ':') THEN
      BEGIN
       ErrorInLine := TRUE;
      END
     ELSE
      BEGIN
       StripCom(1);
       I := 0;
      END;
    END;

  END;
 IF (CurrentLine <> NIL) THEN CurrentLine := CurrentLine^.Next;
END;

PROCEDURE Print_Eltron_Ticket(TranRec : PTranRecord;
                              OrdHRec : PWOHeaderRecord;
                              OrdLRec : PWOLineRecord;
                              CurrentMixBatchStr : TBatchRef;
                              PrintAllDetails : BOOLEAN;
                              TicketType : TTicketTypes;
                              FileName  : STRING;
                              Eltron2   : BOOLEAN);
VAR CommandNo : LONGINT;

  PROCEDURE PrimeFilter;
  BEGIN
   FillChar(Filter,SizeOf(Filter),#0);
   WITH Filter DO
    BEGIN
     WorkNo   := OrdHRec^.WOH_OrderNo;
     {Needs To Be +1 As Revision Ranges from 0 to 99. Where As Search
      uses 1 to 100, as 0 means filter element not set}
     Revision := OrdHRec^.WOH_Revision+1;
     MixNo    := OrdHRec^.WOH_CurrentMix;
    END;
  END;

  PROCEDURE Setup;
  BEGIN
   EPL2        := Eltron2;
   XPos        := 1;
   YPos        := 1;
   Dir         := 0;
   FontType    := 1;
   EPL2BarType := '3';
   FontHoriz   := 1;
   FontVert    := 1;
   ReverseChar := 'N';
   BarReadChar := 'B';
   BarRatioWide := 2;
   BarRatioNarrow := 2;
   BarHeight := 2;
   EPL2Tickets := 1;
   BufferOut('US');
   BufferOut('N');
  END;

BEGIN
 CommunicationError := FALSE;
 LastCommsError := -1;
 IF (NowtButSpace(FileName)) THEN EXIT;
 EltronPort := GetTicketPrinterPortAddr;
 Setup;
 {Vars That Need To Be Set}
 BarReadOn  := TRUE;
 CurrentIng := NIL;
 TranPtr    := TranRec;
 WorkHRec   := OrdHRec;
 WorkLRec   := OrdLRec;
 CurrMixBatStr := CurrentMixBatchStr;
 TicketNo   := 1;
 TheTicketType := TicketType;

 IF (TicketType IN [MixTicket,PartialMixTicket]) THEN
  BEGIN
   PrimeFilter;
   IF (PrintAllDetails) THEN
    TRNList  := BuildOrderTransactionListForMix(Filter)
   ELSE
    TRNList := BuildTransactionListForMix(Filter);
  END
 ELSE TRNList := NIL;

 ReadInFile(FileName,FALSE);
 CurrentLine := FileLineHeader;
 CommandNo := 0;
 WHILE (CurrentLine <> NIL) DO
  BEGIN
   ProcessCommand;
   Inc(CommandNo);
   IF (CommandNo = 5000) THEN BREAK; {Stop Loops In Program}
   IF (CommunicationError) THEN BREAK;
  END;
 ClearLinkedLists;
 ClearTransactionList(TRNList);
 FillChar(Filter,Sizeof(Filter),0);
 IF (AlphaKeyBoard <> NIL) THEN
  BEGIN
   Dispose(AlphaKeyBoard,Done);
   {MessageWin.EnableWindow;}
  END;
END;

PROCEDURE ProcessCommandPrint(CommandStr : STRING);
VAR PrintLine : TCommandLine;
    I : INTEGER;
    VarRec : PVarRec;
    PerPos : INTEGER;
BEGIN
 { Prints Everything up to :. ,seperates vars}
 PrintLine := CommandStr;
 WHILE (Length(PrintLine) > 0) DO
  BEGIN
   Stripped(PrintLine,length(PrintLine),' ');
   IF (PrintLine[1] = '"') THEN {Constant Text Print}
    BEGIN
     I := FindCharInStr(',',PrintLine);
{     SYSTEM.DELETE(PrintLine,1,1);
     I := FindCharInStr('"',PrintLine);
     IF (I = 0) THEN
      BEGIN
       ErrorInLine := TRUE;
       EXIT;
      END;
     BufferOut(COPY(PrintLine,1,I-1));
     SYSTEM.DELETE(PrintLine,1,I);
     I := FindCharinStr(',',PrintLine);
     IF (I = 0) THEN I := Length(PrintLine)+1;
     SYSTEM.DELETE(PrintLine,1,I);}
     IF (EPL2) THEN
      BufferOut('A'+IntToStr(XPos,1)+','+
                    IntToStr(YPos,1)+','+
                    IntToStr(Dir,1)+','+
                    IntToStr(FontType,1)+','+
                    IntToStr(FontHoriz,1)+','+
                    InttoStr(FontVert,1)+','+
                    ReverseChar+',"'+
                    ProcessCommandStr(COPY(PrintLine,1,I-1))+'"')
     ELSE
      BufferOut(ProcessCommandStr(COPY(PrintLine,1,I-1)));
     SYSTEM.DELETE(PrintLine,1,I);
    END
   ELSE {Must Be A Variable}
    BEGIN
     I := FindCharinStr(',',PrintLine);
     IF (I = 0) THEN I := Length(PrintLine)+1;
     PerPos := Pos('$',PrintLine);
     IF (PerPos <> 0) AND (PerPos < I) THEN {Its A String Var So Print It}
      BEGIN
       IF (EPL2) THEN
        BufferOut('A'+IntToStr(XPos,1)+','+
                      IntToStr(YPos,1)+','+
                      IntToStr(Dir,1)+','+
                      IntToStr(FontType,1)+','+
                      IntToStr(FontHoriz,1)+','+
                      InttoStr(FontVert,1)+','+
                      ReverseChar+',"'+
                      ProcessCommandStr(COPY(PrintLine,1,I-1))+'"')
       ELSE
        BufferOut(ProcessCommandStr(COPY(PrintLine,1,I-1)));
{       VarRec := AddFindVar(COPY(PrintLine,1,I-1));
       Write(VarRec^.Strvar)}
      END
     ELSE
      BEGIN
       IF (EPL2) THEN
        BufferOut('A'+IntToStr(XPos,1)+','+
                      IntToStr(YPos,1)+','+
                      IntToStr(Dir,1)+','+
                      IntToStr(FontType,1)+','+
                      IntToStr(FontHoriz,1)+','+
                      InttoStr(FontVert,1)+','+
                      ReverseChar+',"'+
                      IntToStr(CalculateValue(Copy(PrintLine,1,I-1)),1)+'"')
       ELSE
        BufferOut(IntToStr(CalculateValue(Copy(PrintLine,1,I-1)),1));
      END;
     SYSTEM.DELETE(PrintLine,1,I);
    END;
  END;
END;

FUNCTION NullFunctionInt(CommandStr : STRING) : LONGINT;
BEGIN
 NullFunctionInt := CalculateValue(CommandStr);
END;

FUNCTION NullFunctionStr(CommandStr : STRING) : STRING;
BEGIN
 NullFunctionStr := ProcessCommandStr(CommandStr);
END;

FUNCTION GetNumIngredients(CommandStr : STRING) : LONGINT;
BEGIN
 GetNumIngredients := Filter.NumElements;
END;

PROCEDURE EltronBarCodeType (CommandStr : STRING);
VAR BarType : TBarCodeTypes;
BEGIN
 BarType := Int2Of5;
 IF (StringIComp(CommandStr,'Code128BC') = 0) THEN
  BarType := Code128BC0
 ELSE IF (StringIComp(CommandStr,'Code128BC1')=0) THEN
  BarType := Code128BC1
 ELSE IF (StringIComp(CommandStr,'Int2Of5')=0) THEN
  BarType :=Int2Of5
 ELSE IF (StringIComp(CommandStr,'Code39')=0) THEN
  BarType :=Code39_Ext
 ELSE IF (StringIComp(CommandStr,'Code93')=0) THEN
  BarType :=Code93
 ELSE IF (StringIComp(CommandStr,'CodaBar')=0) THEN
  BarType :=CodaBar
 ELSE IF (StringIComp(CommandStr,'UPC')=0) THEN
  BarType :=UPC
 ELSE IF (StringIComp(CommandStr,'EAN')=0) THEN
  BarType :=EAN
 ELSE IF (StringIComp(CommandStr,'PostNet')=0) THEN
  BarType :=PostNet;

 BufferOut(BarCodeType(BarType));
END;

PROCEDURE EltronSetCountryCodeCharSet(CommandStr : STRING);
VAR CharSet : TCharSets;
BEGIN
 CharSet := US_ASCII;

 IF (StringIComp(CommandStr,'US') = 0) THEN
  CharSet :=US_ASCII
 ELSE IF (StringIComp(CommandStr,'ASCII') = 0) THEN
  CharSet :=US_ASCII
 ELSE IF (StringIComp(CommandStr,'British') = 0) THEN
  CharSet :=British
 ELSE IF (StringIComp(CommandStr,'German') = 0) THEN
  CharSet :=German
 ELSE IF (StringIComp(CommandStr,'French') = 0) THEN
  CharSet :=French
 ELSE IF (StringIComp(CommandStr,'Italian') = 0) THEN
  CharSet := Italian
 ELSE IF (StringIComp(CommandStr,'Danish') = 0) THEN
  CharSet := Danish
 ELSE IF (StringIComp(CommandStr,'Spanish') = 0) THEN
  CharSet :=Spanish
 ELSE IF (StringIComp(CommandStr,'Swedish') = 0) THEN
  CharSet :=Swedish
 ELSE IF (StringIComp(CommandStr,'Swiss') = 0) THEN
  CharSet := Swiss;
 SetCountryCodeCharSet(CharSet)
END;

PROCEDURE EltronReversePrint(CommandStr : STRING);
VAR ReverseOn : BOOLEAN;
BEGIN
 ReverseOn := CommandStr = 'ON';

 IF (EPL2) THEN
  BEGIN
   IF (ReverseOn) THEN
    ReverseChar := 'R'
   ELSE
    ReverseChar := 'N';
  END
 ELSE
  BEGIN
   IF (ReverseOn) THEN
    BufferOut(ReversePrint(TRUE))
   ELSE
    BufferOut(ReversePrint(FALSE));
  END;
END;

PROCEDURE EltronPrintBarCode(CommandStr : STRING);
BEGIN
 IF (EPL2) THEN
  BEGIN
   BufferOut('B'+IntToStr(XPos,1)+','+
                 IntToStr(YPos,1)+','+
                 IntToStr(Dir,1)+','+
                 EPL2BarType+','+
                 IntToStr(BarRatioNarrow,1)+','+
                 IntToStr(BarRatioWide,1)+','+
                 IntToStr(BarHeight,1)+','+
                 BarReadChar+','+ProcessCommandStr(CommandStr));
  END
 ELSE
  BufferOut(PrintBarCode(ProcessCommandStr(CommandStr),BarReadOn));
END;

PROCEDURE EltronBarRatio(CommandStr : STRING);
VAR RightVar,LeftVar : STRING[30];
    N1,N2 : INTEGER;
BEGIN
 SplitStr(CommandStr,RightVar,LeftVar);
 N1 := CalculateValue(RightVar);
 N2 := CalculateValue(LeftVar);
 IF (NOT EPL2) THEN BufferOut(BarRatio(N1,N2));
 BarRatioWide   := N2;
 BarRatioNarrow := N1;
END;

PROCEDURE EltronCharacterSize(CommandStr : STRING);
VAR RightVar,LeftVar : STRING[30];
    N1,N2 : INTEGER;
BEGIN
 SplitStr(CommandStr,RightVar,LeftVar);
 N1 := CalculateValue(RightVar);
 N2 := CalculateValue(LeftVar);
 IF (NOT EPL2) THEN BufferOut(CharacterSize(N1,N2));
 FontHoriz := N1;
 FontVert  := N2;
END;

PROCEDURE EltronBackUpLabel (CommandStr : STRING);
VAR N : INTEGER;
BEGIN
 N := CalculateValue(CommandStr);
 BufferOut(BackUpLabel(N));
END;

PROCEDURE EltronBarCodeWidth(CommandStr : STRING);
VAR N : INTEGER;
BEGIN
 N := CalculateValue(CommandStr);
 BufferOut(BarCodeWidth(N));
END;

PROCEDURE EltronFormFeedLength(CommandStr : STRING);
VAR N : INTEGER;
BEGIN
 N := CalculateValue(CommandStr);
 BufferOut(FormFeedLength(N));
END;

PROCEDURE EltronExtraFeed(CommandStr : STRING);
VAR N : INTEGER;
BEGIN
 N := CalculateValue(CommandStr);
 BufferOut(ExtraFeed(N));
END;

PROCEDURE EltronLeftMargin(CommandStr : STRING);
VAR N : INTEGER;
BEGIN
 N := CalculateValue(CommandStr);
 BufferOut(LeftMargin(N));
END;

PROCEDURE EltronContrast(CommandStr : STRING);
VAR N : INTEGER;
BEGIN
 N := CalculateValue(CommandStr);
 BufferOut(Contrast(N));
END;

PROCEDURE EltronPrintSpeed(CommandStr : STRING);
VAR N : INTEGER;
BEGIN
 N := CalculateValue(CommandStr);
 BufferOut(PrintSpeed(N));
END;

PROCEDURE EltronTop_Of_Form(CommandStr : STRING);
VAR N : INTEGER;
BEGIN
 N := CalculateValue(CommandStr);
 BufferOut(Top_Of_Form(N));
END;

PROCEDURE EltronPrintQuantity(CommandStr : STRING);
VAR N : INTEGER;
BEGIN
 N := CalculateValue(CommandStr);
 IF (NOT EPL2) THEN BufferOut(PrintQuantity(N));
 EPL2Tickets := N;
END;

PROCEDURE EltronBufferStart(CommandStr : STRING);
BEGIN
 BufferOut(BufferStart);
END;

PROCEDURE EltronDisableAutomaticBackup(CommandStr : STRING);
BEGIN
 BufferOut(DisableAutomaticBackup);
END;

PROCEDURE EltronDisableAutomaticFormFeed(CommandStr : STRING);
BEGIN
 BufferOut(DisableAutomaticFormFeed);
END;

PROCEDURE EltronTop_Of_Form_Calibrated(CommandStr : STRING);
BEGIN
 BufferOut(Top_Of_Form_Calibrated);
END;

PROCEDURE EltronBufferEnd(CommandStr : STRING);
BEGIN
 BufferOut(BufferEnd);
END;

PROCEDURE EltronRepeatPrint(CommandStr : STRING);
BEGIN
 BufferOut(RepeatPrint);
END;

PROCEDURE PRINTLN(CommandStr : STRING);
BEGIN
 BufferOut(CRLF);
END;

PROCEDURE PrintFeed(Commandstr : STRING);
BEGIN
 LastCommsError := -1;
 IF (EPL2) THEN
  BEGIN
   BufferOut('P'+IntToStr(EPL2Tickets,1));
   GetCommsError(EltronPort);
  END
 ELSE
  BufferOut(FF);
 Inc(TicketNo);
END;

PROCEDURE SETBARCODEREADABLES(CommandStr : STRING);
BEGIN
 IF (CommandStr = 'ON') THEN
  BEGIN
   BarReadOn := TRUE;
   BarReadChar := 'B';
  END
 ELSE IF (CommandStr = 'OFF') THEN
  BEGIN
   BarReadOn := FALSE;
   BarReadChar := 'N';
  END
 ELSE ErrorInLine := TRUE;
END;


PROCEDURE ReadIngredient(CommandStr :STRING);
VAR IngredNo : INTEGER;
BEGIN
 IngredNo := CalculateValue(CommandStr);
 IF (IngredNo <> 0) THEN
  BEGIN
   Dec(IngredNo);
   CurrentIng := TRNList;
   WHILE (CurrentIng <> NIL) AND (IngredNo > 0) DO
    BEGIN
     CurrentIng := CurrentIng^.Next;
     Dec(IngredNo);
    END;
  END;
END;

FUNCTION GetIngredientWtReq(CommandStr : STRING) : STRING;
BEGIN
 IF (CurrentIng <> NIL) THEN
  GetIngredientWtReq := DoubleToStr(CurrentIng^.WeightReq,1,3)
 ELSE
  GetIngredientWtReq := '';
END;

FUNCTION GetIngredientWtDone(CommandStr : STRING) : STRING;
BEGIN
 IF (CurrentIng <> NIL) THEN
   GetIngredientWtDone := DoubleToStr(CurrentIng^.WeightDone,1,3)
 ELSE
   GetIngredientWtDone := '';
END;

FUNCTION GetContainersReq(CommandStr : STRING) : LONGINT;
BEGIN
 IF (CurrentIng <> NIL) THEN
  GetContainersReq := CurrentIng^.ContsReq
 ELSE
  GetContainersReq := -1;
END;

FUNCTION GetContainersDone(Commandstr : STRING) : LONGINT;
BEGIN
 IF (CurrentIng <> NIL) THEN
  GetContainersDone := Currenting^.ContsDone
 ELSE
  GetcontainersDone := -1;
END;

FUNCTION GetIngredient(CommandStr : STRING) : STRING;
BEGIN
 IF (CurrentIng <> NIL) THEN
  GetIngredient := CurrentIng^.Ingredient
 ELSE
  GetIngredient := '';
END;


FUNCTION GetTicketNumber(CommandStr : STRING) : LONGINT;
BEGIN
 GetTicketNumber := TicketNo;
END;

FUNCTION GetMixNumber(CommandStr : STRING) : LONGINT;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetMixNumber := WorkHRec^.WOH_CurrentMix
 ELSE
  GetMixNumber := -1;
END;

FUNCTION GetContainerNo(CommandStr : STRING) : LONGINT;
BEGIN
 IF (TranPtr <> NIL) THEN
  GetContainerNo := TranPtr^.TRN_ContainerNo
 ELSE
  GetContainerNo := -1;
END;

FUNCTION GetMixesRequired(CommandStr : STRING) : LONGINT;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetMixesRequired := WorkHRec^.WOH_NumMixes
 ELSE
  GetMixesRequired := -1;
END;

FUNCTION GetNumContainers(CommandStr : STRING) : LONGINT;
BEGIN
 IF (WorkHRec <> NIL) AND (WorkLRec <>NIL) THEN
   GetNumContainers := CalcLineWeighingsReqdForCurrMix(WorkHRec, WorkLRec)
 ELSE
   GetNumContainers := -1
END;

FUNCTION GetOrderNo(CommandStr : STRING) : STRING;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetOrderNo := OrderNoToStr(WorkHRec^.WOH_OrderNo,WorkHRec^.WOH_Revision)
 ELSE
  GetOrderNo := '';
END;

FUNCTION GetIngredientCode(CommandStr : STRING) : STRING;
BEGIN
 IF (TranPtr <> NIL) THEN
  GetIngredientCode := TranPtr^.TRN_Ingredient
 ELSE
  GetIngredientCode := '';
END;

FUNCTION GetWeight(CommandStr : STRING) : STRING;
BEGIN
 IF (TranPtr <> NIL) THEN
  GetWeight := DoubleToStr(TranPtr^.TRN_ContainerWt,9,3)+'kg'
 ELSE
  GetWeight := '';
END;

FUNCTION GetUserName(CommandStr : STRING) : STRING;
BEGIN
 GetUserName := CurrentUser.USR_ID;
END;

FUNCTION GetBatchNumber(CommandStr : STRING) : STRING;
BEGIN
 IF (TranPtr = NIL) THEN
  GetBatchNumber := CurrMixBatStr
 ELSE
  GetBatchNumber := TranPtr^.TRN_BatchNo;
END;

FUNCTION GetLotNumber(CommandStr : STRING) : STRING;
BEGIN
 IF (TranPtr <> NIL) THEN
  GetLotNumber := TranPtr^.TRN_LotNo
 ELSE
  GetLotNumber := '';
END;

FUNCTION GetRecipeCode(CommandStr : STRING) : STRING;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetRecipeCode := WorkHRec^.WOH_RecipeNo
 ELSE
  GetRecipeCode := '';
END;

FUNCTION GetTargetWtGross(CommandStr :STRING) : STRING;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetTargetWtGross := DoubleToStr(WorkHRec^.WOH_TotIngredWtReqd,4,3)+'kg'
 ELSE
  GetTargetWtGross := ''
END;

FUNCTION GetMixBatchWt(CommandStr : STRING) : STRING;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetMixBatchWt := DoubleToStr(WorkHRec^.WOH_MaxMixGrossWt,4,3)+'kg'
 ELSE
  GetMixBatchWt := '';
END;

FUNCTION GetTargetBatchWt(CommandStr : STRING) : STRING;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetTargetBatchWt := DoubleToStr({WorkHRec^.WOH_TargetBatchWt,}
                         CalcCompensatedBatchMixWt(WorkHRec,
                                                   WorkHRec^.WOH_CurrentMix),
                                  4,3)+'kg'
 ELSE
  GetTargetBatchWt := '';
END;

FUNCTION GetMixesDone(CommandStr : STRING) : LONGINT;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetMixesDone := WorkHRec^.WOH_MixDone
 ELSE
  GetMixesDone := 0;
END;

FUNCTION GetWeightDoneNet(CommandStr : STRING) : STRING;
BEGIN
{
 IF (WorkHRec <> NIL) THEN
  GetWeightDoneNet := DoubleToStr(WorkHRec^.WOH_WtDoneNet,4,3)+'kg'
 ELSE
}
  GetWeightDoneNet := '';
END;

FUNCTION GetCurrentMixWt(CommandStr : STRING) : STRING;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetCurrentMixWt:= DoubleToStr(GetMixWtDoneOnCurrentMix(WorkHRec),4,3)+'kg'
 ELSE
  GetCurrentMixWt:= '';
END;

FUNCTION GetNumCases(CommandStr : STRING) : LONGINT;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetNumCases:= WorkHRec^.WOH_NumCases
 ELSE
  GetNumCases:= 0;
END;

FUNCTION GetTargetWtNet(CommandStr : STRING) : STRING;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetTargetWtNet:= DoubleToStr(WorkHRec^.WOH_FinishWtReqd,4,3)+'kg'
 ELSE
  GetTargetWtNet:= '';
END;

FUNCTION GetNumMixes(CommandStr : STRING) : LONGINT;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetNumMixes:= WorkHRec^.WOH_NumMixes
 ELSE
  GetNumMixes:= 0;
END;

FUNCTION GetWtDoneGross(CommandStr : STRING) : STRING;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetWtDoneGross:= DoubleToStr(WorkHRec^.WOH_WtDoneGross,4,3)+'kg'
 ELSE
  GetWtDoneGross:= '';
END;

FUNCTION GetCaseWt(CommandStr : STRING) : STRING;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetCaseWt:= DoubleToStr(WorkHRec^.WOH_CaseWt,4,3)+'kg'
 ELSE
  GetCaseWt:= '';
END;

FUNCTION GetDate(CommandStr : STRING) : STRING;
BEGIN
 IF (TranPtr <> NIL) THEN
  GetDate := Days_To_Date(TranPtr^.TRN_Date)
 ELSE
  GetDate := '';
END;

FUNCTION GetCurrentDate(CommandStr :STRING) : STRING;
BEGIN
 GetCurrentDate := Date;
END;

FUNCTION GetTime(CommandStr : STRING) : STRING;
BEGIN
 IF (TranPtr <> NIL) THEN
  GetTime := TranPtr^.TRN_Time
 ELSE
  GetTime := '';
END;

FUNCTION GetMixComplete(CommandStr : STRING) : STRING;

  FUNCTION GetIsMixComplete(OrdHRec : PWOHeaderRecord) : STRING;
  BEGIN
   IF IsMixComplete(OrdHRec^.WOH_CurrentMix,
                    OrdHRec^.WOH_OrderNo,
                    OrdHRec^.WOH_Revision) THEN
     GetIsMixComplete := 'YES'
   ELSE
     GetIsMixComplete := 'NO';
  END;

BEGIN
 IF (WorkHRec <> NIL) THEN
  GetMixComplete := GetIsMixComplete(WorkHRec)
 ELSE
  GetMixComplete := '';
END;

FUNCTION GetText1Str(CommandStr : STRING) : STRING;
BEGIN
 IF (WorkLRec <> NIL) THEN
  GetText1Str := WorkLRec^.WOL_SpecialInstr[1]
 ELSE
  GetText1Str := '';
END;

FUNCTION GetText2Str(CommandStr : STRING) : STRING;
BEGIN
 IF (WorkLRec <> NIL) THEN
  GetText2Str := WorkLRec^.WOL_SpecialInstr[2]
 ELSE
  GetText2Str := ''
END;

FUNCTION GetIngredientMixWtDone(CommandStr : STRING) : STRING;
BEGIN
{
 IF (WorkLRec <> NIL) THEN
  BEGIN
   GetIngredientMixWtDone := DoubleToStr(WorkLRec^.WOL_MixWtDone,4,3)+'kg';
  END
 ELSE
   GetIngredientMixWtDone := '';
}
 IF (CurrentIng <> NIL) THEN
   GetIngredientMixWtDone := DoubleToStr(CurrentIng^.WeightDone,1,3)
 ELSE
   GetIngredientMixWtDone := '';
END;


FUNCTION GetIngredientMixContDone(CommandStr : STRING) : LONGINT;
BEGIN
{
 IF (WorkLRec <> NIL) THEN
  GetIngredientMixContDone := WorkLRec^.WOL_MixContDone
 ELSE
  GetIngredientMixContDone := 0;
}
 IF (CurrentIng <> NIL) THEN
   GetIngredientMixContDone := CurrentIng^.ContsDone
 ELSE
   GetIngredientMixContDone := 0;
END;

FUNCTION GetIngredientContDone(CommandStr : STRING) : LONGINT;
BEGIN
 IF (WorkLRec <> NIL) THEN
  GetIngredientContDone := WorkLRec^.WOL_TotalContDone
 ELSE
  GetIngredientContDone := 0;
END;


FUNCTION GetSerialNo(CommandStr : STRING) : STRING;
BEGIN
 IF (TranPtr <> NIL) THEN
  GetSerialNo := IntToZeroStr(TranPtr^.TRN_Mid,2)+IntToZeroStr(TranPtr^.TRN_SerialNo,6)
 ELSE
  GetSerialNo := '';
END;

FUNCTION GetFixedBarcode(CommandStr : STRING) : STRING;
VAR RecipeRec : TRecipeHeaderRecord;
BEGIN
 IF (WorkHRec <> NIL) THEN
  BEGIN
   RecipeHeaderFile^.InitRecord(RecipeRec);
   RecipeRec.RH_RecipeNo := WorkHRec^.WOH_RecipeNo;
   IF (RecipeHeaderFile^.ReadRecord('EQ',FALSE,FALSE,RecipeRec,0) = 0) THEN
    BEGIN
     GetFixedBarcode := RecipeRec.RH_BarCode;
    END
   ELSE GetFixedBarCode := '';
  END
 ELSE GetFixedBarcode := '';
END;

FUNCTION GetRecipeName(CommandStr : STRING) : STRING;
VAR RecipeRec : TRecipeHeaderRecord;
BEGIN
 IF (WorkHRec <> NIL) THEN
  BEGIN
   RecipeHeaderFile^.InitRecord(RecipeRec);
   RecipeRec.RH_RecipeNo := WorkHRec^.WOH_RecipeNo;
   IF (RecipeHeaderFile^.ReadRecord('EQ',FALSE,FALSE,RecipeRec,0) = 0) THEN
    BEGIN
     GetRecipeName := RecipeRec.RH_Description;
    END
   ELSE GetRecipeName := '';
  END
 ELSE GetRecipeName := '';
END;

FUNCTION GetIngredientName(CommandStr : STRING) : STRING;
VAR IngredientRec : TIngredient_Record;
BEGIN
 IngredientRec.ING_Ingredient := ProcessCommandStr(CommandStr);
 IF (IngredientFile^.ReadRecord('EQ',FALSE,FALSE,IngredientRec,0) = 0) THEN
  GetIngredientName := IngredientRec.ING_Description
 ELSE
  GetIngredientName := SPACE_STRING;
END;


FUNCTION GetOrderDate(CommandStr : STRING) : STRING;
BEGIN
 IF (WorkHRec <> NIL) THEN
  GetOrderDate := Days_To_Date(WorkHRec^.WOH_SchDate)
 ELSE
  GetOrderDate := '';
END;

FUNCTION StringtoInt(CommandStr : STRING) : LONGINT;
BEGIN
 StringToInt := StringToLong(ProcessCommandStr(CommandStr));
END;

FUNCTION IntToString(CommandStr : STRING) : STRING;
BEGIN
 IntToString := IntToStr(CalculateValue(CommandStr),1);
END;

FUNCTION GetASCIICode(CommandStr : STRING) : LONGINT;
VAR
    Justify  : LONGINT;
    StartPos : LONGINT;
    RightVar,LeftVar : TCommandLine;
BEGIN
 RightVar := '' ; LeftVar := '';
 SplitStr(CommandStr,RightVar,LeftVar);
 RightVar := ProcessCommandStr(RightVar);
 Justify := 0;
 IF (Length(LeftVar) > 0) THEN
  Justify := CalculateValue(LeftVar);
 IF (Justify < 1) THEN Justify := 1
 ELSE IF (Justify > Length(RightVar)) THEN Justify := Length(RightVar);

 GetASCIICode := Ord(RightVar[Justify]);
END;

FUNCTION GetTicketType(CommandStr : STRING) : LONGINT;
BEGIN
 GetTicketType := ORD(TheTicketType);
END;

FUNCTION GetCharStr(CommandStr : STRING) : STRING;
VAR Value : INTEGER;
BEGIN
 Value := CalculateValue(CommandStr);
 IF (Value < 32) THEN Value := 32
 ELSE IF (Value > 127) THEN Value := 32;

 GetCharStr := Char(Value);
END;

FUNCTION RightString(CommandStr : STRING) : STRING;
VAR
    Justify  : LONGINT;
    StartPos : LONGINT;
    RightVar,LeftVar : TCommandLine;
BEGIN
 RightString := ''; RightVar := '' ; LeftVar := '';
 {Format is string,numchars}
 SplitStr(CommandStr,RightVar,LeftVar);
 RightVar := ProcessCommandStr(RightVar);
 Justify := CalculateValue(LeftVar);
 StartPos := Length(RightVar)-Justify+1;
 IF (StartPos  < 1) OR (Justify < 1) THEN EXIT;
 RightString := Copy(RightVar,StartPos,Justify);
END;

FUNCTION CenterText(CommandStr : STRING) : STRING;
VAR
    Justify  : LONGINT;
    StartPos : LONGINT;
    RightVar,LeftVar : TCommandLine;
BEGIN
 RightVar := '' ; LeftVar := '';
 {Format is string,numchars}
 SplitStr(CommandStr,RightVar,LeftVar);
 RightVar := ProcessCommandStr(RightVar);
 Justify := CalculateValue(LeftVar);
 CenterText := Centered(RightVar,Justify);
END;

FUNCTION LeftString(CommandStr : STRING) : STRING;
VAR
    Justify  : INTEGER;
    RightVar,LeftVar : TCommandLine;
BEGIN
 LeftString := ''; RightVar := '' ; LeftVar := '';
 {Format is string,numchars}
 SplitStr(CommandStr,RightVar,LeftVar);
 RightVar := ProcessCommandStr(RightVar);
 Justify := CalculateValue(LeftVar);
 IF (Justify < 1) THEN EXIT;
 LeftString := Copy(RightVar,1,Justify);
END;

FUNCTION MidString(CommandStr : STRING) : STRING;
VAR
    Justify  : INTEGER;
    StartPos : INTEGER;
    RightVar,TempVar,MidVar,LeftVar : TCommandLine;
BEGIN
 MidString := ''; RightVar := '' ; LeftVar := '';
 {Format is string,startpos}
 {OR     string,startpos,numchars}
 SplitStr(CommandStr,RightVar,TempVar);
 RightVar := ProcessCommandStr(RightVar);
 Justify := FindCharInStr(',',TempVar);
 IF (Justify > Length(TempVar)) THEN
  BEGIN
   StartPos := CalculateValue(TempVar);
   Justify  := Length(RightVar);
  END
 ELSE
  BEGIN
   SplitStr(TempVar,MidVar,LeftVar);
   StartPos := CalculateValue(MidVar);
   Justify  := CalculateValue(LeftVar);
  END;
 IF (StartPos  < 1) OR (Justify < 1) THEN EXIT;
 MidString := Copy(RightVar,StartPos,Justify);
END;

FUNCTION StrLen(CommandStr : STRING) : LONGINT;
BEGIN
 StrLen := Length(ProcessCommandStr(CommandStr));
END;

FUNCTION GetSystemInt(CommandStr : STRING) : LONGINT;
VAR SysIni : INIVAR;
BEGIN
 SysIni.V := ProcessCommandStr(CommandStr);
 SysIni.S := eltron;
 GetSystemInt := GetExtNum(SysIni,all,0,9999999,0);
END;

FUNCTION GetSystemStr(CommandStr : STRING) : STRING;
VAR SysIni : INIVAR;
BEGIN
 SysIni.V := ProcessCommandStr(CommandStr);
 SysIni.S := eltron;
 GetSystemStr := GetExtVar(SysIni,all);
END;

FUNCTION ReadInput(CommandStr : STRING) : STRING;
VAR ReadLen : LONGINT;
    TheEdit : PEdit;
    Result  : STRING[50];
    RightVar,LeftVar : TCommandLine;
BEGIN
 RightVar := '' ; LeftVar := '';
 {Format is string,numchars}
 SplitStr(CommandStr,RightVar,LeftVar);
 ReadLen := CalculateValue(LeftVar);
 RightVar := ProcessCommandStr(RightVar);
 Result := '';
 IF (ReadLen > 0) THEN
  BEGIN
   IF (NowtButSpace(RightVar)) THEN RightVar := 'Enter Data';
   IF ((ReadLen+Length(RightVar)+2) > 70) THEN
    ReadLen := 70-Length(RightVar)-2;
  END;
 IF (ReadLen > 0) THEN
  BEGIN
   IF (AlphaKeyBoard = NIL) THEN
    BEGIN
     {MessageWin.Disablewindow;}
     New(AlphaKeyBoard,Init);
    END;
   New(TheEdit,Init(1,1,Length(RightVar)+1,StdEdit,NIL,RightVar,et_string,ReadLen,Result));
   TheEdit^.UserActivateFunction(0,0);
   Dispose(TheEdit,Done);
  END;
 ReadInput := Result;
END;

{THESE ARE FOR ELTRON 2 PROGRAMING COMMANDS}
PROCEDURE SetEltron2BarCodeType(CommandStr : STRING);
BEGIN
 IF (StringIComp(CommandStr,'Code39')=0) THEN
  EPL2BarType := '3'
 ELSE IF (StringIComp(CommandStr,'Code39C')=0) THEN
  EPL2BarType := '3C'
 ELSE IF (StringIComp(CommandStr,'Code93')=0) THEN
  EPL2BarType := '9'
 ELSE IF (StringIComp(CommandStr,'Code128') = 0) THEN
  EPL2BarType := '1'
 ELSE IF (StringIComp(CommandStr,'CodaBar')=0) THEN
  EPL2BarType := 'K'
 ELSE IF (StringIComp(CommandStr,'EAN8')=0) THEN
  EPL2BarType := 'E80'
 ELSE IF (StringIComp(CommandStr,'EAN8+2')=0) THEN
  EPL2BarType := 'E82'
 ELSE IF (StringIComp(CommandStr,'EAN8+5')=0) THEN
  EPL2BarType := 'E85'
 ELSE IF (StringIComp(CommandStr,'EAN13')=0) THEN
  EPL2BarType := 'E30'
 ELSE IF (StringIComp(CommandStr,'EAN13+2')=0) THEN
  EPL2BarType := 'E32'
 ELSE IF (StringIComp(CommandStr,'EAN13+5')=0) THEN
  EPL2BarType := 'E35'
 ELSE IF (StringIComp(CommandStr,'Int2Of5')=0) THEN
  EPL2BarType := '2'
 ELSE IF (StringIComp(CommandStr,'Int2Of5C')=0) THEN
  EPL2BarType := '2C'
 ELSE IF (StringIComp(CommandStr,'Int2Of5HC')=0) THEN
  EPL2BarType := '2D'
 ELSE IF (StringIComp(CommandStr,'PostNet')=0) THEN
  EPL2BarType := 'P'
 ELSE IF (StringIComp(CommandStr,'UPCA')=0) THEN
  EPL2BarType := 'UA0'
 ELSE IF (StringIComp(CommandStr,'UPCA+2')=0) THEN
  EPL2BarType := 'UA2'
 ELSE IF (StringIComp(CommandStr,'UPCA+5')=0) THEN
  EPL2BarType := 'UA5'
 ELSE IF (StringIComp(CommandStr,'UPCE')=0) THEN
  EPL2BarType := 'UE0'
 ELSE IF (StringIComp(CommandStr,'UPCE+2')=0) THEN
  EPL2BarType := 'UE2'
 ELSE IF (StringIComp(CommandStr,'UPCE+5')=0) THEN
  EPL2BarType := 'UE5'
 ELSE IF (StringIComp(CommandStr,'UPC2OF5')=0) THEN
  EPL2BarType := '2U';
END;

PROCEDURE SetEltron2Position(CommandStr : STRING);
VAR
    RightVar,LeftVar : TCommandLine;
BEGIN
 RightVar := '' ; LeftVar := '';
 {Format is string,numchars}
 SplitStr(CommandStr,RightVar,LeftVar);
 XPos :=  CalculateValue(RightVar);
 YPos  := CalculateValue(LeftVar);
END;

PROCEDURE SetEltron2BarHeight(CommandStr : STRING);
BEGIN
 BarHeight := CalculateValue(CommandStr);
END;

PROCEDURE SetEltron2Direction(CommandStr : STRING);
VAR Temp : LONGINT;
BEGIN
 Temp := CalculateValue(CommandStr);
 IF (Temp >= 0) AND (Temp <= 3) THEN
  BEGIN
   Dir := Dir;
  END;
END;

PROCEDURE DrawLine(CommandStr : STRING);
TYPE TLineParams = (XS,YS,XE,YE,Thick);
VAR StoreParams : ARRAY[ORD(Xs)..ORD(Thick)] OF INTEGER;
    I : INTEGER;
    TempStr,ValStr,StoreStr : TCommandLine;
BEGIN
 StoreStr := CommandStr;
 I := ORD(XS);
 FillChar(StoreParams,sizeof(StoreParams),0);
 {Retrieve Line parameters}
 WHILE (I <= ORD(Thick)) AND (POS(',',StoreStr) <> 0) DO
  BEGIN
   SplitStr(StoreStr,ValStr,TempStr);
   StoreParams[I] := CalculateValue(ValStr);
   StoreStr := TempStr;
   Inc(I);
  END;
 IF (I <= ORD(Thick)) THEN
  BEGIN
   StoreParams[I] := CalculateValue(StoreStr);
   INC(I);
  END;

 IF (I > ORD(YE)) THEN
  BEGIN
   IF (StoreParams[ORD(Thick)] = 0) THEN
    StoreParams[ORD(Thick)] := 1;
    TempStr := 'LS';
   FOR I := ORD(XS) TO ORD(YS) DO
    TempStr := TempStr+IntToStr(StoreParams[I],1)+',';
   TempStr := TempStr+InttoStr(StoreParams[ORD(Thick)],1)+',';
   FOR I := ORD(XE) TO ORD(YE) DO
    BEGIN
     TempStr := TempStr+IntToStr(StoreParams[I],1);
     IF (I <> ORD(YE)) THEN TempStr := TempStr+ ',';
    END;
   BufferOut(TempStr);
  END;
END;

PROCEDURE DrawBox(CommandStr : STRING);
TYPE TLineParams = (XS,YS,XE,YE,Thick);
VAR StoreParams : ARRAY[ORD(Xs)..ORD(Thick)] OF INTEGER;
    I : INTEGER;
    TempStr,ValStr,StoreStr : TCommandLine;
BEGIN
 StoreStr := CommandStr;
 I := ORD(XS);
 FillChar(StoreParams,sizeof(StoreParams),0);
 {Retrieve Line parameters}
 WHILE (I <= ORD(Thick)) AND (POS(',',StoreStr) <> 0) DO
  BEGIN
   SplitStr(StoreStr,ValStr,TempStr);
   StoreParams[I] := CalculateValue(ValStr);
   StoreStr := TempStr;
   Inc(I);
  END;
 IF (I <= ORD(Thick)) THEN
  BEGIN
   StoreParams[I] := CalculateValue(StoreStr);
   INC(I);
  END;
 IF (I > ORD(YE)) THEN
  BEGIN
   IF (StoreParams[ORD(Thick)] = 0) THEN
    StoreParams[ORD(Thick)] := 1;
    TempStr := 'X';
   FOR I := ORD(XS) TO ORD(YS) DO
    TempStr := TempStr+IntToStr(StoreParams[I],1)+',';
   TempStr := TempStr+InttoStr(StoreParams[ORD(Thick)],1)+',';
   FOR I := ORD(XE) TO ORD(YE) DO
    BEGIN
     TempStr := TempStr+IntToStr(StoreParams[I],1);
     IF (I <> ORD(YE)) THEN TempStr := TempStr+ ',';
    END;
   BufferOut(TempStr);
  END;
END;

PROCEDURE SetFontType(CommandStr : STRING);
VAR NewFontType : INTEGER;
BEGIN
 NewFontType := CalculateValue(CommandStr);
 IF (NewFontType >= 1) AND (NewFontType <=5) THEN
  FontType := NewFontType;
END;

PROCEDURE AddBasicFunctions(Printer2 : BOOLEAN);
BEGIN
 AddFunctionInt('',NullFunctionInt,TRUE);
 AddFunctionStr('',NullFunctionStr,TRUE);
 AddFunctionInt('VAL',StringtoInt,TRUE);
 AddFunctionInt('STRLEN',StrLen,TRUE);
 AddFunctionStr('STR$',IntToString,TRUE);
 AddFunctionStr('RIGHT$',RightString,TRUE);
 AddFunctionStr('LEFT$',LeftString,TRUE);
 AddFunctionStr('MID$',MidString,TRUE);

 AddFunctionInt('GetNumIngredients',GetNumIngredients,FALSE);
 AddFunctionInt('GetContainersReq',GetContainersReq,FALSE);
 AddFunctionInt('GetContainersDone',GetContainersDone,FALSE);
 AddFunctionInt('GetTicketNumber',GetTicketNumber,FALSE);
 AddFunctionInt('GetMixNumber',GetMixNumber,FALSE);
 AddFunctionInt('GetContainerNo',GetContainerNo,FALSE);
 AddFunctionInt('GetMixesRequired',GetMixesRequired,FALSE);
 AddFunctionInt('GetContsReq',GetNumContainers,FALSE);
 AddFunctionInt('GetSystemInt',GetSystemInt,TRUE);
 AddFunctionInt('GetNumMixes',GetNumMixes,FALSE);
 AddFunctionInt('GetMixesDone',GetMixesDone,FALSE);
 AddFunctionInt('GetNumCases',GetNumCases ,FALSE);
 AddFunctionInt('GetIngredientMixContDone',GetIngredientMixContDone,FALSE);
 AddFunctionInt('GetIngredientContDone',GetIngredientContDone,FALSE);
 AddFunctionInt('ASCII',GetASCIICode,TRUE);
 AddFunctionInt('GetTicketType',GetTicketType,FALSE);

 AddFunctionStr('Chr$',GetCharStr,TRUE);
 AddFunctionStr('GetWtReq$',GetIngredientWtReq,FALSE);
 AddFunctionStr('GetWtDone$',GetIngredientWtDone,FALSE);
 AddFunctionStr('GetIngredient$',GetIngredient,FALSE);
 AddFunctionStr('GetIngredientName$',GetIngredientName,TRUE);
 AddFunctionStr('GetRecipeName$',GetRecipeName,FALSE);
 AddFunctionStr('GetSerialNo$',GetSerialNo,FALSE);
 AddFunctionStr('GetOrderDate$',GetOrderDate,FALSE);
 AddFunctionStr('GetFixedBarcode$',GetFixedBarcode,FALSE);
 AddFunctionStr('GetSystemStr$',GetSystemStr,TRUE);

 AddFunctionStr('GetOrderNo$',GetOrderNo,FALSE);
 AddFunctionStr('GetIngredientCode$',GetIngredientCode,FALSE);
 AddFunctionStr('GetWeight$',GetWeight,FALSE);
 AddFunctionStr('GetUserName$',GetUserName,FALSE);
 AddFunctionStr('GetBatchNumber$',GetBatchNumber,FALSE);
 AddFunctionStr('GetLotNumber$',GetLotNumber,FALSE);
 AddFunctionStr('GetRecipeCode$',GetRecipeCode,FALSE);
 AddFunctionStr('GetDate$',GetDate,FALSE);
 AddFunctionStr('GetTime$',GetTime,FALSE);
 AddFunctionStr('GetMixComplete$',GetMixComplete,FALSE);
 AddFunctionStr('GetText1Str$',GetText1Str,FALSE);
 AddFunctionStr('GetText2Str$',GetText2Str,FALSE);
 AddFunctionStr('GetTargetWtGross$',GetTargetWtGross,FALSE);
 AddFunctionStr('GetMixBatchWt$',GetMixBatchWt,FALSE);
 AddFunctionStr('GetTargetBatchWt$',GetTargetBatchWt,FALSE);
 AddFunctionStr('GetWeightDoneNet$',GetWeightDoneNet,FALSE);
 AddFunctionStr('GetCurrentMixWt$',GetCurrentMixWt,FALSE);
 AddFunctionStr('GetTargetWtNet$',GetTargetWtNet,FALSE);
 AddFunctionStr('GetWtDoneGross$',GetWtDoneGross,FALSE);
 AddFunctionStr('GetCaseWt$',GetCaseWt,FALSE);
 AddFunctionStr('GetIngredientMixWtDone$',GetIngredientMixWtDone,FALSE);
 AddFunctionStr('ReadInput$',ReadInput,TRUE);
 AddFunctionStr('GetCurrentDate$',GetCurrentDate,FALSE);
 AddFunctionStr('Centered$',CenterText,TRUE);

 AddFunctionNul('READINGREDIENT',ReadIngredient,TRUE);
 {Common Functions For Both Printers}
 AddFunctionNul('PRINT',ProcessCommandPrint,FALSE);
 AddFunctionNul('REVERSEPRINT',EltronReversePrint,TRUE);
 AddFunctionNul('PRINTBARCODE',EltronPrintBarCode,TRUE);
 AddFunctionNul('SETBARRATIO',EltronBarRatio,TRUE);
 AddFunctionNul('SETBARCODEREADABLES',SETBARCODEREADABLES,TRUE);
 AddFunctionNul('SETCHARACTERSIZE',EltronCharacterSize,TRUE);
 AddFunctionNul('SETPRINTQUANTITY',EltronPrintQuantity,TRUE);
 AddFunctionNul('PRINTFEED',PrintFeed,FALSE);

 {THESE FUNCTIONS ARE FOR ELTRON PRINTER EPL1 COMMANDS}
 IF (Printer2) THEN
  BEGIN
   AddFunctionNul('BARCODETYPE',SetEltron2BarCodeType,TRUE);
   AddFunctionNul('MOVETO',SetEltron2Position,TRUE);
   AddFunctionNul('SETBARHEIGHT',SetEltron2BarHeight,TRUE);
   AddFunctionNul('DIR',SetEltron2Direction,TRUE);
   AddFunctionNul('DRAWLINE',DrawLine,TRUE);
   AddFunctionNul('DRAWBOX',DrawBox,TRUE);
   AddFunctionNul('SetFontType',SetFontType,TRUE);
  END
 ELSE
  BEGIN
   AddFunctionNul('BACKUPLABEL',EltronBackUpLabel,TRUE);
   AddFunctionNul('BARCODETYPE',EltronBarCodeType,TRUE);
   AddFunctionNul('BARCODEWIDTH',EltronBarCodeWidth,TRUE);
   AddFunctionNul('SETCOUNTRYCODE',EltronSetCountryCodeCharSet,TRUE);
   AddFunctionNul('SETFORMFEEDLENGTH',EltronFormFeedLength,TRUE);
   AddFunctionNul('SETEXTRAFEED',EltronExtraFeed,TRUE);
   AddFunctionNul('SETLEFTMARGIN',EltronLeftMargin,TRUE);
   AddFunctionNul('SETCONTRAST',EltronContrast,TRUE);
   AddFunctionNul('SETPRINTSPEED',EltronPrintSpeed,TRUE);
   AddFunctionNul('SETTOPOFFORM',EltronTop_Of_Form,TRUE);
   AddFunctionNul('STARTBUFFER',EltronBufferStart,FALSE);
   AddFunctionNul('DISABLEAUTOBACKUP',EltronDisableAutomaticBackup,FALSE);
   AddFunctionNul('DISABLEAUTOFORMFEED',EltronDisableAutomaticFormFeed,FALSE);
   AddFunctionNul('CALIBRATETOPOFFORM',EltronTop_Of_Form_Calibrated,FALSE);
   AddFunctionNul('ENDBUFFER',EltronBufferEnd,FALSE);
   AddFunctionNul('REPEATPRINT',EltronRepeatPrint,FALSE);
   AddFunctionNul('PRINTLN',PrintLn,FALSE);
 END;
END;

BEGIN
 CommunicationTimeOut := GetExtNum(PrinterTimeOut,all,100,1000000,10000);
END.

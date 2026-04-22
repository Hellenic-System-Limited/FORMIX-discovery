{$C FIXED PRELOAD PERMANENT}
{$O+,F+}
{$I F6COMP}
UNIT SFXTouch;
INTERFACE
USES F6STDCTV,F6StdUtl,SFXPorts,ComCheck,FXStdUt1,SFXGraph,CRt,SFXConst,
     SFXMsg,F6StdWn1,FXDetail;

CONST
 TOUCHSCREEN_TIMEOUT   = 2;

FUNCTION  get_scaled_xy(var ts_x_pos, ts_y_pos:INTEGER;VAR ts_status : word) : Char;
FUNCTION  Get_TouchScreen_Settings(ResetTS : BOOLEAN) : BOOLEAN;
FUNCTION  TouchScreeninit : BOOLEAN;
PROCEDURE TouchScreenDone;
PROCEDURE IncreaseContrast;
PROCEDURE DecreseContrast;
PROCEDURE PrimeContrast;
PROCEDURE ResetTouchScreenIfWanted;

IMPLEMENTATION

TYPE TouchScreenRec = PACKED RECORD
       Name : STRING[20];
       ID   : INTEGER;
     END;

CONST {Touch Screen Init Vars}

 TouchScreenList : ARRAY[1..22]OF TouchScreenRec =
   ((Name : 'X_ORIGIN'; ID : 1),
    (Name : 'Y_ORIGIN'; ID : 2),
    (Name : 'SCALE_X' ; ID : 3),
    (Name : 'SCALE_Y' ; ID : 4),
    (Name : 'FKEY_X1' ; ID : 5),
    (Name : 'FKEY_Y1' ; ID : 6),
    (Name : 'FKEY1_ID'; ID : 7),
    (Name : 'FKEY_X2' ; ID : 8),
    (Name : 'FKEY_Y2' ; ID : 9),
    (Name : 'FKEY2_ID'; ID :10),
    (Name : 'FKEY_X3' ; ID :11),
    (Name : 'FKEY_Y3' ; ID :12),
    (Name : 'FKEY3_ID'; ID :13),
    (Name : 'FKEY_X4' ; ID :14),
    (Name : 'FKEY_Y4' ; ID :15),
    (Name : 'FKEY4_ID'; ID :16),
    (Name : 'FKEY_X5' ; ID :17),
    (Name : 'FKEY_Y5' ; ID :18),
    (Name : 'FKEY5_ID'; ID :19),
    (Name : 'FKEY_X6' ; ID :20),
    (Name : 'FKEY_Y6' ; ID :21),
    (Name : 'FKEY6_ID'; ID :22));
VAR
    {Touch Screen paramaters}
    fkey_x           : Array[0..5] of integer;
    fkey_y           : Array[0..5] of integer;
    scale_x, scale_y : Double;
    x_origin,
    y_origin         : word;
    TouchScreenTimeOut : INTEGER;


    {Touch Screen Interrupt parameters}
    COM1ReadList     : ARRAY[1..3] OF BYTE;
    IrqCom1ReadList  : ARRAY[1..3] OF BYTE;
    TSPacketPos      : INTEGER;
    GotATSPacket     : BOOLEAN;
    StartTSPacket    : BOOLEAN;
    TimeOfReadTS     : LONGINT;
    lpOldIRQ4        : POINTER;    {Pointer To old Interrupt Routines}

    Contrast         : INTEGER;
    Save8086         : BYTE;

CONST
    TouchScreenActive : BOOLEAN = FALSE;
    key_names_out  : Array[0..5] of Char = (ESC,PGUP,PGDN,NEXT,PREV,CR);

VAR TouchScreenFileName : STRING[13];

{TOUCH SCREEN PROCEDURES}
{ $$$$$}
(*      THESE ARE THE OLD TOUCH SCREEN FOUNCTIONS
Procedure ReadSerialPort; Interrupt;
var IRQID : Byte;
    i     : Integer;
    ByteIn: BYTE;
Begin
 IRQID := port[SER_COM1 + SER_IRQ_ID]; {Get port status}
 if ( IRQID and SER_ID_PENDING ) = 0 then    { Is IRQ pending ? }
  Begin { Yes }
   case ( IRQID and SER_ID_MASK ) of
    SER_ID_RECEIVED:                         { After data received }
     Begin
      while (IsSerialDataAvailable( SER_COM1 )) do
       Begin
        ByteIn :=port[Ser_COM1 + SER_RXBUFFER];
        IF NOT GotATSPacket THEN
         BEGIN
          IF ByteIn AND 128 <> 0 THEN
           BEGIN
            StartTSPacket := TRUE;
            TSPacketPos   := 1;
           END;
          IF StartTSPacket THEN
           BEGIN
            IRQCom1ReadList[TSPacketPos] := ByteIn;
            INC(TSPacketPos);
            IF TSPacketPos > 3 THEN
             BEGIN
              GotATSPacket  := TRUE;
              StartTSPacket := FALSE;
             END;
           END;
         END;
       End;
     End;
    SER_ID_LINESTATUS : BEGIN
     i:=Port[Ser_Com1+SER_LINE_STATUS];
    END;
   End;
  End;
 SendIRQEOI( SER_IRQ_COM1 );                        { End of interrupt }
End;
*)

PROCEDURE CommsOutString(Port : WORD;S : STRING;TimeOut : INTEGER;iDelay: INTEGER);
VAR I,J : INTEGER;
BEGIN
 FOR I := 1 TO Length(S) DO
  BEGIN
   WriteBytetoPort(Port,ORD(S[I]),TimeOut);
   IF (iDelay <> 0) THEN Delay(iDelay);
  END;
END;


PROCEDURE SendCommandToMicro(Command,Value : BYTE);
VAR CommandSent : BOOLEAN;
BEGIN
 CommsOutString(SER_COM1,#05#2+Char(Command)+Char(Value)+#03,0,5);
END;


PROCEDURE ChangeContrastTo(Cont : SHORTINT);
VAR OutCont  : SHORTINT;
    ContFile : TEXT;
BEGIN
 OutCont := Cont;
 IF (OutCont < 0) THEN Inc(OutCont,64);
(* OutCont := OutCont AND $3F;
 SendStr(#5#2'c'+Char(OutCont)+#3,2);*)

 IF ScaleConfRec.ColourDisplay THEN SetDefaultPallete(OutCont,ScaleConfRec.GreyScaleDisplay)
 ELSE SendCommandToMicro(ORD('c'),OutCont);

(*
 Assign(ContFile,'CONT.FIL');
 {$I-}
 Rewrite(ContFile);
 {$i+}
 IF (IOResult = 0) THEN
  BEGIN
   Write(ContFile,'Contrast=',Cont:2);
   Close(Contfile);
  END;
*)
END;

FUNCTION ValidContrast : BOOLEAN;
BEGIN
 ValidContrast := TRUE;
 IF  ScaleConfRec.ColourDisplay
 AND ((Contrast > -1) AND (Contrast < 5)) THEN { its black }
   ValidContrast := FALSE;
END;

PROCEDURE IncreaseContrast;
BEGIN
 REPEAT
   IF (Contrast >= 30) THEN
    BEGIN
     Contrast := 30;
     BREAK;
    END;
   Inc(Contrast);
 UNTIL ValidContrast ;
 ChangeContrastTo(Contrast); { change screen }
 SetScreenContrast(Contrast);{ store in data file }
END;

PROCEDURE DecreseContrast;
BEGIN
 REPEAT
   IF (Contrast <= -30) THEN
    BEGIN
     Contrast := -30;
     BREAK;
    END;
   Dec(Contrast);
 UNTIL ValidContrast;
 ChangeContrastTo(Contrast); { change screen }
 SetScreenContrast(Contrast);{ store in data file }
END;

PROCEDURE PrimeContrast;
(*
VAR
    ContFile : TEXT;
    LineIn   : STRING[80];
    ValErr   : INTEGER;
BEGIN
 Contrast := 8;
 Assign(ContFile,'CONT.FIL');
 {$I-}
 ReSet(ContFile);
 {$i+}
 IF (IOResult = 0) THEN
  BEGIN
   WHILE (NOT EOF(ContFile)) DO
    BEGIN
     Read(Contfile,LineIn);
     IF (StringLiComp(LineIn,'Contrast=',9) = 0) THEN
      BEGIN
       Val(Copy(LineIn,10,Length(LineIn)),Contrast,ValErr);
      END;
    END;
   Close(Contfile);
  END;
 ContrastTo(Contrast);
END;
*)
BEGIN
 Contrast := GetScreenContrast;
 IF NOT ValidContrast THEN
   IncreaseContrast
 ELSE
   ChangeContrastTo(Contrast);
END;

(* THESE ARE THE NEW TOUCH SCREEN FUNCTIONS*)
VAR IRQID : Byte;
    i     : Integer;
    ByteIn: BYTE;

    TS_SaveSS    : WORD;
    TS_SaveSP    : WORD;
    TS_IntSP     : WORD;
    TS_INTSTACK  : ARRAY[1..512] OF WORD;
{$R-}
{$S-}
PROCEDURE ReadSerialPort; INTERRUPT;
BEGIN

 TS_IntSP := Ofs(TS_INTSTACK)+1024;
 asm
  MOV   TS_SaveSS,SS { Save Current Stack Segment }
  MOV   TS_SaveSP,AX { Save AX Register }
  MOV   AX,DS        { Move DataSeg TO AX}
  MOV   SS,AX        { Set New Stack Segment To DataSeg}
  MOV   AX,SP        { Save Stack Pointer To AX }
  XCHG  AX,TS_SaveSP { Restore AX Register And Save Stack Pointer To SaveSP}
  MOV   SP,TS_IntSP  { Set New Stack Pointer }
 end;

 Test8086 := 0;
 IRQID := port[SER_COM1 + SER_IRQ_ID]; {Get port status}
 IF ( IRQID AND SER_ID_PENDING ) = 0 THEN    { Is IRQ pending ? }
  BEGIN { Yes }
   CASE ( IRQID AND SER_ID_MASK ) OF
    SER_ID_RECEIVED:                         { After data received }
     BEGIN
      IF ((port[Ser_COM1+SER_LINE_STATUS] and SER_LSR_DATARECEIVED) <> 0) THEN
       BEGIN
        ByteIn :=port[Ser_COM1 + SER_RXBUFFER];
        IF NOT GotATSPacket THEN
         BEGIN
          IF ByteIn AND 128 <> 0 THEN
           BEGIN
            StartTSPacket := TRUE;
            TSPacketPos   := 1;
           END;
          IF StartTSPacket THEN
           BEGIN
            IRQCom1ReadList[TSPacketPos] := ByteIn;
            INC(TSPacketPos);
            IF TSPacketPos > 3 THEN
             BEGIN
              GotATSPacket  := TRUE;
              StartTSPacket := FALSE;
             END;
           END;
         END;
       END;
     END;
    SER_ID_LINESTATUS : BEGIN
     i:=Port[Ser_Com1+SER_LINE_STATUS];
    END;
   END;
  END;
 Port[$20] := $20;
 {SendIRQEOI( SER_IRQ_COM1 );                         End of interrupt }
 Test8086 := Save8086;
 asm
  MOV   SS,TS_SaveSS  { Restore Stack Segment }
  MOV   SP,TS_SaveSP  { Restore Stack Pointer }
 end;
END;
{$R+}
{$S+}

FUNCTION ReadTouchScreen : BOOLEAN;
VAR Result : BOOLEAN;
BEGIN
 Result := GotATSPacket;

 IF Result THEN
  BEGIN
   MOVE(IRQCom1ReadList,Com1ReadList,SizeOf(Com1ReadList));
   TimeOfReadTS := GetTickCount+TOUCHSCREEN_TIMEOUT;
   GotATSPacket := FALSE;
  END
 ELSE
  BEGIN
   IF (TimeOfReadTS > GetTickCount) THEN
    Result := TRUE
   ELSE
    Result := FALSE;
  END;
 ReadTouchScreen := Result;
END;

{z=0 if co-ordinates not valid (release)
 z=1 if co-ordinates are valid (on press)
 z=2 if Serial touch screen controller not responding}
 {Touch Screen Sends Three Bytes}
 {BYTE 1 -
      7 6 5 4 3 2 1 0
     -----------------
     | | | | | | | | |
     -----------------
      | | | | | | | |
      | --------------- Y Coordinate upper 7 bits;
      |
      ----------------- Touch Screen Input.

  BYTE 2
      7 6 5 4 3 2 1 0
     -----------------
     | | | | | | | | |
     -----------------
        | | | | | | |
        --------------- X Coordinate upper 7 bits;

  BYTE 3

      7 6 5 4 3 2 1 0
     -----------------
     | | | | | | | | |
     -----------------
        | | | | | | |
        | | | | ------- Y Coordinate Lower 7 bits;
        | | | |
        | ------------- X Coordinate Lower 7 Bits;
        |
        --------------- Touch Screen Pressed.
}

(* OLD VERSION
Procedure get_ts_xy(var x,y : INTEGER;VAR status : Word);
CONST UpperBitsMask = 127;
      B3YMask = 56;
      B3XMask = 7;
BEGIN
 IF ReadTouchScreen THEN
  BEGIN
   y := ((Com1ReadList[1] and 127) * 8) + (Com1ReadList[3] and B3XMask);
   x := ((Com1ReadList[2] and 127) * 8) + ((Com1ReadList[3] and B3YMask) div 8 );
   Status := 1;
  END
 ELSE
  status := 0;
END;


PROCEDURE TranslatePoint(VAR X,Y : INTEGER);
BEGIN
 X := Round((x_origin-x)*scale_x);
 Y := Round((y_origin-y)*scale_y);
END;

    NEW VERSION*)

PROCEDURE get_ts_xy(VAR x,y : INTEGER;VAR status : Word);
CONST UpperBitsMask = 127;
      B3XMask = 56;
      B3YMask = 7;
BEGIN
 IF ReadTouchScreen THEN
  BEGIN
   y := ((Com1ReadList[3] and 127)) + (Com1ReadList[1] and B3YMask) SHL 7;
   x := ((Com1ReadList[2] and 127)) + (Com1ReadList[1] and B3XMask) SHL 4;
   Status := 1;
  END
 ELSE
  status := 0;
END;

PROCEDURE TranslatePoint(VAR X,Y : INTEGER);
BEGIN
 X := Round((x-x_origin)*scale_x);
 Y := Round((y-y_origin)*scale_y)+10;
END;


FUNCTION Get_Scaled_XY(VAR ts_x_pos, ts_y_pos:INTEGER;VAR ts_status : word) : Char;
CONST KEY_WIDTH      = 40;

var x1,y1 : INTEGER;
    I     : INTEGER;
begin
 get_ts_xy(x1,y1,ts_status);
 Get_Scaled_XY := #0;
 if ((ts_status and 1) = 0) THEN EXIT;
 TranslatePoint(X1,Y1);
 ts_x_pos  := X1;
 ts_y_pos  := Y1;


 for i := 0 to 5 do
  begin
   if ((x1 + KEY_WIDTH ) > fkey_x[i]) AND
      ((x1 - KEY_WIDTH ) < fkey_x[i]) AND
      ((y1 + KEY_WIDTH ) > fkey_y[i]) AND
      ((y1 - KEY_WIDTH ) < fkey_y[i]) THEN
    begin
     get_scaled_xy := key_names_out[i];
     Funckey := (I<>0) AND (I<>5);
     EXIT;
    end;
  end;
 get_scaled_xy := #0;
end;

(* OLD VERSION
FUNCTION Vector_Touch_Screen : BOOLEAN;
CONST CROSS_HAIR     = 20;
CONST key_names      : Array[0..5] of String = ('SYSREQ','PG UP','PG DN',
                                                'Arrow Down','Arrow Up',
                                                'Enter');
CONST Range_X = 640;
CONST Range_Y = 480;
var x1,y1,
    x2,y2,x3,y3 : Integer;
    z1 : word;
    w1, w2 : string;
    I : INTEGER;

 PROCEDURE ReadOneTSPacket(VAR x1,y1 : INTEGER);
 VAR xt1,xt2 : INTEGER;
 BEGIN
  Repeat
   get_ts_xy(x1,y1,z1);
  Until ((z1 and 1) <> 0);
  Repeat
   Get_ts_xy(xt1,xt2,z1);
  Until ((z1 and 1) = 0);
 END;



BEGIN
 Vector_Touch_Screen := TRUE;
 ClrGraphWin;

  DrawLine(MaxX DIV 2-CROSS_HAIR,MaxY DIV 2,MaxX DIV 2+CROSS_HAIR,MaxY DIV 2);
  DrawLine(MaxX DIV 2,Maxy DIV 2-CROSS_HAIR,MaxX DIV 2,MaxY DIV 2+CROSS_HAIR);
  WriteStrAt(12,16,'Touch Centre Cross Hair');
  ReadOneTSPacket(x1,y1);

  ClrGraphWin;
  DrawLine(0,MaxY,CROSS_HAIR,Maxy);
  DrawLine(0,MaxY-1,CROSS_HAIR,Maxy-1);
  DrawLine(0,MaxY-CROSS_HAIR,0,MaxY);
  DrawLine(1,MaxY-CROSS_Hair,1,MaxY);
  WriteStrAt(12,16,'Touch Bottom left Intersection');
  ReadOneTSPacket(x2,y3);

  ClrGraphWin;
  DrawLine(MaxX-CROSS_HAIR,0,MaxX,0);
  DraWline(MaxX-Cross_Hair,1,MaxX,1);
  DrawLine(MaxX,0,MaxX,CROSS_HAIR);
  DrawLine(MaxX-1,0,MaxX-1,CROSS_Hair);
  WriteStrAt(12,16,'Touch Top Right Intersection');
  ReadOneTSPacket(x3,y2);

  for i := 0 to 5 do
   begin
   ClrGraphWin;
   WriteStrAt(12,16,'Press ' + key_names[i]);
   ReadOneTSPacket(fkey_x[i],fkey_y[i]);
  end;
  ClrGraphWin;

{Now work out where logical 0,0 -> 639, 479 is!}
{NB. x2 = origin + 20, y2=origin + 20}
  IF X3<>X2 THEN
   scale_x := range_x / ABS(x3-x2)
  ELSE Vector_Touch_Screen := FALSE;
  IF Y3<>Y2 THEN
   scale_y := range_y / ABS(y3-y2)
  ELSE Vector_Touch_Screen := FALSE;
  x_origin := x2;
  y_origin := y2;
  FOR I:=0 TO 5 DO TranslatePoint(fkey_x[I],fkey_y[I]);
END;

  NEWER VERSION
*)

FUNCTION Vector_Touch_Screen : BOOLEAN;
CONST CROSS_HAIR     = 20;
CONST key_names      : Array[0..5] of String[10] = ('MENU      ',
                                                    'Contrast +',
                                                    'Contrast -',
                                                    'Arrow Up  ',
                                                    'Arrow Down',
                                                    'Enter     ');

CONST Range_X = 640;
CONST Range_Y = 470;
var x1,y1,
    x2,y2,x3,y3 : Integer;
    z1 : word;
    w1, w2 : string;
    I : INTEGER;

 PROCEDURE ReadOneTSPacket(VAR x1,y1 : INTEGER);
 VAR xt1,xt2 : INTEGER;
 BEGIN
  Repeat
   get_ts_xy(x1,y1,z1);
  Until ((z1 and 1) <> 0);
  Repeat
   Get_ts_xy(xt1,xt2,z1);
  Until ((z1 and 1) = 0);
 END;



BEGIN
 Vector_Touch_Screen := TRUE;
 ClrGraphWin;

  DrawLine(MaxX DIV 2-CROSS_HAIR,MaxY DIV 2,MaxX DIV 2+CROSS_HAIR,MaxY DIV 2);
  DrawLine(MaxX DIV 2,Maxy DIV 2-CROSS_HAIR,MaxX DIV 2,MaxY DIV 2+CROSS_HAIR);
  WriteStrAt(12,16,'Touch Centre Cross Hair');
  ReadOneTSPacket(x1,y1);


  ClrGraphWin;
  DrawLine(0,MaxY,CROSS_HAIR,Maxy);
  DrawLine(0,MaxY-1,CROSS_HAIR,Maxy-1);
  DrawLine(0,MaxY-CROSS_HAIR,0,MaxY);
  DrawLine(1,MaxY-CROSS_Hair,1,MaxY);
  WriteStrAt(12,16,'Touch Bottom left Intersection');
  ReadOneTSPacket(x2,y3);

  ClrGraphWin;
  DrawLine(MaxX-CROSS_HAIR,10,MaxX,10);
  DraWline(MaxX-Cross_Hair,11,MaxX,11);
  DrawLine(MaxX,  10,MaxX,  CROSS_HAIR+10);
  DrawLine(MaxX-1,10,MaxX-1,CROSS_Hair+10);
  WriteStrAt(12,16,'Touch Top Right Intersection');
  ReadOneTSPacket(x3,y2);


  for i := 0 to 5 do
   begin
   ClrGraphWin;
   WriteStrAt(12,16,'Press ' + key_names[i]);
   ReadOneTSPacket(fkey_x[i],fkey_y[i]);
  end;
  ClrGraphWin;

{Now work out where logical 0,0 -> 639, 479 is!}
{NB. x2 = origin + 20, y2=origin + 20}
  Scale_X := 0;
  Scale_y := 0;
  IF X3<>X2 THEN
   scale_x := range_x / (x3-x2)
  ELSE Vector_Touch_Screen := FALSE;
  IF Y3<>Y2 THEN
   scale_y := (range_y) / (y3-y2)
  ELSE Vector_Touch_Screen := FALSE;
  x_origin := x2;
  y_origin := y2;
{
  WriteStrAt(50, 1,'X_Origin : '+IntToStr(X_Origin,1));
  WriteStrAt(50, 3,'Y_Origin : '+IntToStr(Y_Origin,1));
  WriteStrAt(50, 5,'X_Scale  : '+DoubleToStr(Scale_x,9,2));
  WriteStrAt(50, 7,'Y_Scale  : '+DoubleToStr(Scale_y,9,2));
  WriteStrat(50, 9,'Point_1  : '+IntToStr(X1,1)+'  '+IntToStr(Y1,1));
  WriteStrat(50,11,'Point_2  : '+IntToStr(X2,1)+'  '+IntToStr(Y2,1));
  WriteStrat(50,13,'Point_3  : '+IntToStr(X3,1)+'  '+IntToStr(Y3,1));
  WriteStrAt(50,15,'');}
  FOR I:=0 TO 5 DO
   BEGIN
{    WriteStr(key_names_out[I]+'  ');}
    TranslatePoint(fkey_x[I],fkey_y[I]);
   END;

END;




FUNCTION Get_TouchScreen_Settings(ResetTS : BOOLEAN) : BOOLEAN;
VAR TouchScreenFile  : TEXT;
    TouchScreenOK    : BOOLEAN;
    I                : INTEGER;
    InStr            : STRING;

 FUNCTION CompareStr(VAR Str1,Str2 : STRING) : BOOLEAN;
 VAR I : INTEGER;
 BEGIN
  CompareStr := FALSE;
  FOR I:=1 TO Length(Str1) DO
   IF Str1[i]<>Upcase(Str2[i]) THEN EXIT;
  CompareStr := TRUE;
 END;

 FUNCTION GetLineID(CompStr : STRING) : INTEGER;
 VAR I : INTEGER;
 BEGIN
  GetLineID := -1;
  FOR I := 1 TO 22 DO
   BEGIN
    IF CompareStr(TouchScreenList[I].Name,CompStr) THEN
     BEGIN
      GetLineID := TouchScreenList[I].ID;
      EXIT;
     END;
   END;
 END;

 PROCEDURE GetTouchScreenSettings;
 VAR EqualPos : INTEGER;
     Dummy    : INTEGER;
     ValStr   : STRING[20];
 BEGIN
  WHILE NOT EOF(TouchScreenFile) DO
   BEGIN
    ReadLn(TouchScreenFile,InStr);
    EqualPos := Pos('=',InStr);
    IF EqualPos > 0 THEN
     BEGIN
      ValStr := COPY(Instr,EqualPos+1,Length(Instr));
      CASE GetLineID(COPY(InStr,1,EqualPos-1)) OF
       1  : VAL(ValStr,X_Origin,Dummy); {X_ORIGIN}
       2  : VAL(ValStr,Y_Origin,Dummy); {Y_ORIGIN}
       3  : VAL(ValStr,Scale_X,Dummy);  {SCALE_X}
       4  : VAL(ValStr,Scale_Y,Dummy);  {SCALE_Y}
       5  : VAL(ValStr,FKey_X[0],Dummy);
       6  : VAL(ValStr,FKey_Y[0],Dummy);
       7  : VAL(ValStr,BYTE(Key_Names_Out[0]),Dummy);
       8  : VAL(ValStr,FKey_X[1],Dummy);
       9  : VAL(ValStr,FKey_Y[1],Dummy);
       10 : VAL(ValStr,BYTE(Key_Names_Out[1]),Dummy);
       11 : VAL(ValStr,FKey_X[2],Dummy);
       12 : VAL(ValStr,FKey_Y[2],Dummy);
       13 : VAL(ValStr,BYTE(Key_Names_Out[2]),Dummy);
       14 : VAL(ValStr,FKey_X[3],Dummy);
       15 : VAL(ValStr,FKey_Y[3],Dummy);
       16 : VAL(ValStr,BYTE(Key_Names_Out[3]),Dummy);
       17 : VAL(ValStr,FKey_X[4],Dummy);
       18 : VAL(ValStr,FKey_Y[4],Dummy);
       19 : VAL(ValStr,BYTE(Key_Names_Out[4]),Dummy);
       20 : VAL(ValStr,FKey_X[5],Dummy);
       21 : VAL(ValStr,FKey_Y[5],Dummy);
       22 : VAL(ValStr,BYTE(Key_Names_Out[5]),Dummy);
      END; {CASE}
     END;
   END; {WHILE}
 END;

 PROCEDURE WriteTouchScreenSettings;
 BEGIN
  WriteLn(TouchScreenFile,'X_ORIGIN=',X_Origin:1);
  WriteLn(TouchScreenFile,'Y_ORIGIN=',Y_Origin:1);
  WriteLn(TouchScreenFile,'SCALE_X=',Scale_X:9:5);
  WriteLn(TouchScreenFile,'SCALE_Y=',Scale_Y:9:5);
  WriteLn(TouchScreenFile,'FKEY_X1=',Fkey_X[0]);
  WriteLn(TouchScreenFile,'FKEY_Y1=',FKey_Y[0]);
  WriteLn(TouchScreenFile,'FKEY_X2=',Fkey_X[1]);
  WriteLn(TouchScreenFile,'FKEY_Y2=',FKey_Y[1]);
  WriteLn(TouchScreenFile,'FKEY_X3=',Fkey_X[2]);
  WriteLn(TouchScreenFile,'FKEY_Y3=',FKey_Y[2]);
  WriteLn(TouchScreenFile,'FKEY_X4=',Fkey_X[3]);
  WriteLn(TouchScreenFile,'FKEY_Y4=',FKey_Y[3]);
  WriteLn(TouchScreenFile,'FKEY_X5=',Fkey_X[4]);
  WriteLn(TouchScreenFile,'FKEY_Y5=',FKey_Y[4]);
  WriteLn(TouchScreenFile,'FKEY_X6=',Fkey_X[5]);
  WriteLn(TouchScreenFile,'FKEY_Y6=',FKey_Y[5]);
 END;

BEGIN
 ASSIGN(TouchScreenFile,TouchScreenFileName);
 {$I-}
 IF NOT ResetTS THEN Reset(TouchScreenFile);
 {$I+}
 IF (IOResult <> 0) OR (ResetTS) THEN
  BEGIN
   TouchScreenOK := Vector_Touch_Screen;
   IF TouchScreenOK THEN
    BEGIN
     {$I-}
     Rewrite(TouchScreenFile);
     {$I+}
     IF IOResult = 0 THEN
      BEGIN
       WriteTouchScreenSettings;
       Close(TouchScreenFile);
      END;
    END;
  END
 ELSE
  BEGIN
   GetTouchScreenSettings;
   TouchScreenOK := TRUE;
   Close(TouchScreenFile);
  END;
 Get_TouchScreen_Settings := TouchScreenOK;
END;


PROCEDURE ResetTouchScreenIfWanted;
VAR FirstCheck : BOOLEAN;
    TouchScreenPresses : INTEGER;
    X1,Y1 : INTEGER;
    Z1    : WORD;
    Touching : BOOLEAN;
BEGIN
 TouchScreenPresses := 0;
 WriteStrAt(16,50,'To recalibrate Touch Screen: touch three times now.');
 FirstCheck := TRUE;
 TimeOutError := FALSE;
 Touching := FALSE;
 REPEAT
  get_ts_xy(x1,y1,z1);
  IF ((Z1 AND 1) <> 0) THEN Touching:=TRUE;
  IF Touching AND ((Z1 AND 1) = 0) THEN
   BEGIN
    INC(TouchScreenPresses);
    WriteStrAt(39,52,IntToStr(TouchScreenPresses,1));
    Touching := FALSE;
   END;
  CheckForTimeOut(FirstCheck,TouchScreenTimeOut,FALSE);
  FirstCheck := FALSE;
 UNTIL TimeOutError;
 IF TouchScreenPresses = 3 THEN Get_TouchScreen_Settings(TRUE);
END;

(* OLD
FUNCTION TouchScreeninit : BOOLEAN;
VAR UART : INTEGER;
    TouchScreenOK : BOOLEAN;
BEGIN
 MessageWin.ClearMsg;
 ClrGraphWin;
 Com1Initialised := TRUE;
 TimeOfReadTS := 0;
 WriteStrAt(0,0,'Initiating Touch Screen             ');
 FillChar(COM1ReadList,SizeOf(COM1ReadList),#0);

 UART := InitiatePort(SER_COM1,9600, SER_LCR_8BITS or
                                     SER_LCR_1STOPBIT or
                                     SER_LCR_NOPARITY,TRUE);

 IF UART <> BAUD_ERROR THEN
  lpOldIRQ4 := SetSerialIRQHandler(SER_COM1,SER_IRQ_COM1,
                                 @ReadSerialPort,
                                 SER_IER_RECEIVED);

 TouchScreenOK := (UART <> BAUD_ERROR) AND Get_TouchScreen_Settings(FALSE);
 ResetTouchScreenIfWanted;
 IF NOT TouchScreenOK THEN SetError(GENERAL_ERROR+DONTPRINTYET,'Touch Screen Not Initialised');
 TouchScreenInit := TouchScreenOk;
END;

    NEW *)

FUNCTION TouchScreeninit : BOOLEAN;
VAR UART : INTEGER;
    TouchScreenOK : BOOLEAN;

FUNCTION GetUartError(ErrorNo : INTEGER;FatalError : BOOLEAN) : STRING;
BEGIN
 CASE ErrorNo OF
  BAUD_TO_HIGH : GetUartError := 'Baud Rate Too High. Maximum 115200 Bd ';
  NOSER        : BEGIN
   IF (FatalError) THEN
    GetUartError := 'No Comms Port Program Will Terminate'
   ELSE
    GetUartError := 'Tried To Initialise A non Existant Serial Port';
  END;
 ELSE GetUartError := 'Port Initiation Error';
 END {CASE}
END;


BEGIN
 TouchScreenOk := TRUE;
 IF (NowtButSpace(TouchScreenFileName)) THEN
  BEGIN
   Disp_Error_Msg('No Touch Screen File Name Set');
   TouchScreenOk := FALSE;
  END;

 IF TouchScreenOK THEN
  BEGIN
   TouchScreenTimeout := GetTouchScreenTimeOut;
{  Com1Initialised := TRUE;}
   TimeOfReadTS    := 0;
   FillChar(COM1ReadList,SizeOf(COM1ReadList),#0);

   UART := InitiatePort(SER_COM1,2400, SER_LCR_8BITS or
                                     SER_LCR_1STOPBIT or
                                     SER_LCR_NOPARITY ,FALSE,'TOUCHSCREEN');

   CommsOutString(SER_COM1,#01#95#13,0,10);

   UART := InitiatePort(SER_COM1,9600, SER_LCR_8BITS or
                                     SER_LCR_1STOPBIT or
                                     SER_LCR_NOPARITY ,FALSE,'TOUCHSCREEN');

   IF (UART <> SER_OK) THEN
    BEGIN
     Disp_Error_Msg(GetUartError(UART,TRUE));
     TouchScreenOk := FALSE;
    END;
  END;

 IF TouchScreenOk THEN
  BEGIN
   lpOldIRQ4 := SetSerialIRQHandler(SER_COM1,SER_IRQ_COM1,
                                    @ReadSerialPort,
                                    SER_IER_RECEIVED);

   TouchScreenOk := Get_TouchScreen_Settings(FALSE);
  END;

 TouchScreenActive := TouchScreenOk; { IRQ handler is enabled }

 IF NOT TouchScreenOk THEN
   Disp_Error_Msg('Error Initialising Touch Screen');

 TouchScreenInit := TouchScreenOk;
END;


PROCEDURE TouchScreenDone;
BEGIN
 IF TouchScreenActive THEN
  BEGIN
   RestoreSerialIRQHandler( SER_COM1, SER_IRQ_COM1, lpOldIRQ4 );
   TouchScreenActive := FALSE;
  END;
END;

BEGIN
 TouchScreenFileName := GetTouchScreenSettingsFileName;
 Save8086 := Test8086;
END.
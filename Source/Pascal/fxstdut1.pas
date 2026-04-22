(****************************************************************************
*  UNIT          : F6STDUT1                                                 *
*  AUTHOR        : C. J. Collins AND S. M. Wright                           *
*  DATE          : 08/11/93                                                 *
*  PURPOSE       : FOPS6 STD ROUTINES WHICH CALL COMMS                      *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP.PAS}
{$C FIXED PRELOAD PERMANENT}
Unit FXSTDUT1;

INTERFACE

USES SfxGraph,F6StdCtv,F6stdutl,F6DtConv,SfxBtn,SFX_Pro,F6RngBuf;

CONST GetDateType = -1;
      GetTimeType = -2;


VAR
	 ch,
	 ch1       : char;
	 FuncKey   : BOOLEAN;
         Secret    : BOOLEAN;

TYPE     CheckBoxTypes = (RadioButton,TickBox);
TYPE     TCharSet = SET OF Char;

function getkey : char;       {Get a Key or Function Key, sets Funckey}
PROCEDURE Flush_Keyboard_Buffer;             { As Name Suggests             }


{Enter a line of a/n data to Var_dat, length var_len, at var_x,var_y}
procedure getline(var var_dat:string; var_len,var_x,var_y:integer;VAR Rect : TRect);
procedure GetAnyCharStr(var var_dat:string; var_len,var_x,var_y:integer;VAR Rect : TRect);
procedure getline_num (var var_dat:string; var_len,var_x,var_y,dp:integer;VAR Rect : TRect);
PROCEDURE GetHexNum(Var I:WORD;Size:INTEGER;Atx,Aty:Integer;VAR Rect : TRect);
PROCEDURE GetFloat(XPos,YPos : INTEGER;         { Window Posn }
		   VAR WorkStr : STRING;
		   Width,DecimalPlaces : BYTE;VAR Rect : TRect); { As Pascal formatting }
PROCEDURE GetDouble(VAR D:DOUBLE;Size,Dp:INTEGER;Atx,Aty:Integer;VAR Rect : TRect);
PROCEDURE GetInteger(Var I:Integer;Size:INTEGER;Atx,Aty:Integer;VAR Rect : TRect);
PROCEDURE GetLongInt(VAR L:LongInt;Size:INTEGER;Atx,Aty:INTEGER;VAR Rect : TRect);
PROCEDURE GetDate(VAR Dt:LONGINT;Atx,Aty:INTEGER;VAR Rect : TRect);
PROCEDURE GetTime(VAR Tm:Time_Type;Atx,Aty:INTEGER;VAR Rect : TRect);
procedure gettick(var var_dat:string; var_x,var_y : integer);
procedure GetRadio(var var_dat:string; var_x,var_y : integer);
PROCEDURE GetBoolean(Var TheBool : BOOLEAN;var_x,var_y : INTEGER;BoolType : CheckBoxTypes);

FUNCTION  KeyWasPressed : BOOLEAN;
(*FUNCTION  ReadKeyPress : CHAR;*)

TYPE
      PListAreas = ^TListAreas;
      TListAreas = OBJECT(TButtonWindow)
       OrdAdj  : INTEGER;
       PtrToLong : PLongint;
       ArrowDirection : TArrowDirection;
       CONSTRUCTOR Init(X1,y1,X2,Y2 : INTEGER;Dir : BOOLEAN;ArrowDir : TArrowDirection;LongToModify : PLONGINT);
       DESTRUCTOR Done;VIRTUAL;
       FUNCTION UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
       PROCEDURE Draw;VIRTUAL;
      END;

      PSwitchWindow = ^TSwitchWindow;
      TSwitchWindow = OBJECT(TButtonWindow)
       PtrToBool  : PBOOLEAN;
       WinText    : STRING;
       CONSTRUCTOR Init(X1,y1,X2,Y2 : INTEGER;bWinType : BYTE;WindowText : STRING;BoolToModify : PBOOLEAN);
       DESTRUCTOR  Done;VIRTUAL;
       FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
       PROCEDURE   Draw;VIRTUAL;
      END;

      PPCXSwitchWindow = ^TPCXSwitchWindow;
      TPCXSwitchWindow = OBJECT(TPCXButton)
       PtrToBool  : PBOOLEAN;
       CONSTRUCTOR Init(X1,y1,X2,Y2 : INTEGER;bWinType : BYTE;PCXFile : PCXNameStr ;BoolToModify : PBOOLEAN);
       DESTRUCTOR  Done;VIRTUAL;
       FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
      END;


VAR   LastKeysPressed : TApplScanKeyBuffer;

implementation
USES SFXUtils,SFXCOLR;

CONST NormalChars : TCharSet   = ['A'..'Z','a'..'z','0'..'9',' '];
CONST HexChars    : TCharSet   = ['A'..'F','a'..'f','0'..'9'];
CONST AnyChars    : TCharSet   = [#32 .. #255]; { eg. dont CRs }


{ ************************************************************************ }
{ BACKGROUND TASK FOR FLASHING ENTRY CURSOR                                }
{ ************************************************************************ }

TYPE PFlashCursorTask = ^TFlashCursorTask;
     TFlashCursorTask = OBJECT(TBackGroundTask)
      InverseFont : PFontType;
      XPos,YPos   : INTEGER;
      FlashChar   : CHAR;
      CONSTRUCTOR Init(InvFont : PFontType);
      DESTRUCTOR  Done; VIRTUAL;
      PROCEDURE   SetCharacterFlashing(X,Y : INTEGER; TheChar : CHAR);
      PROCEDURE   Execute; VIRTUAL;
     END;

VAR  CursorFlash : PFlashCursorTask;

CONSTRUCTOR TFlashCursorTask.Init(InvFont : PFontType);
BEGIN
 INHERITED Init(FALSE);
 SetActive(FALSE);
 InverseFont := InvFont;
END;

DESTRUCTOR TFlashCursorTask.Done;
BEGIN
END;

PROCEDURE TFlashCursorTask.SetCharacterFlashing(X,Y : INTEGER; TheChar : CHAR);
BEGIN
 XPos      := X;
 YPos      := Y;
 FlashChar := TheChar;
 EnableTask;
END;

PROCEDURE TFlashCursorTask.Execute;
VAR HoldFont : PFontType;
BEGIN
 IF ((GetTickCount DIV 4)AND 1) = 0 THEN
  HoldFont := SetCurrentFont(CurrFontBitMap)
 ELSE
  HoldFont := SetCurrentFont(InverseFont);
 WriteCharAt(XPos,YPos,FlashChar);
 SetCurrentFont(HoldFont);
END;

{ ************************************************************************ }
{============================TListArea Methods==============================}
DESTRUCTOR TListAreas.Done;
BEGIN
 INHERITED Done;
END;

PROCEDURE TListAreas.Draw;
BEGIN
 WITH Bounds DO
  DrawArrow(ArrowDirection,Left,Top,Right,Bottom)
END;

FUNCTION TListAreas.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 UserActivateFunction := FALSE;
 IF (PtrToLong <> NIL) THEN
  BEGIN
   Inc(PtrToLong^,OrdAdj);
    UserActivateFunction := TRUE;
  END;
END;

CONSTRUCTOR TListAreas.Init(X1,y1,X2,Y2 : INTEGER;Dir : BOOLEAN;ArrowDir : TArrowDirection;LongToModify : PLONGINT);
BEGIN
 ArrowDirection := ArrowDir;
 IF Dir THEN OrdAdj := 1 ELSE OrdAdj := -1;
 INHERITED Init(x1,y1,x2,y2,C_WindowStaticText SHR 4,StdBtn);
 PtrToLong := LongToModify;
END;


{=====================TSwtich Areas==============================}
CONSTRUCTOR TSwitchWindow.Init(X1,y1,X2,Y2 : INTEGER;bWinType : BYTE;WindowText : STRING;BoolToModify : PBOOLEAN);
BEGIN
 WinText := WindowText;
 INHERITED Init(x1,y1,x2,y2,C_TextButton SHR 4,bWinType);
 PtrToBool := BoolToModify;
END;

DESTRUCTOR TSwitchWindow.Done;
BEGIN
 INHERITED Done;
END;

FUNCTION TSwitchWindow.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 UserActivateFunction := FALSE;
 IF (PtrToBool <> NIL) THEN
  BEGIN
   PtrToBool^ := NOT (PtrToBool^);
   UserActivateFunction := TRUE;
  END;
END;

PROCEDURE TSwitchWindow.Draw;
VAR SaveCol : BYTE;
BEGIN
 SaveCol := SetTextColour(C_TextButton);
 DisplayText(1,WinText);
 SetTextColour(SaveCol);
END;


{=====================TPCXSwtich Areas==============================}
CONSTRUCTOR TPCXSwitchWindow.Init(X1,y1,X2,Y2 : INTEGER;bWinType : BYTE;PCXFile : PCXNameStr;BoolToModify : PBOOLEAN);
BEGIN
 INHERITED Init(x1,y1,x2,y2,bWinType,PCXFile);
 PtrToBool := BoolToModify;
END;

DESTRUCTOR TPCXSwitchWindow.Done;
BEGIN
 INHERITED Done;
END;

FUNCTION TPCXSwitchWindow.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 UserActivateFunction := FALSE;
 IF (PtrToBool <> NIL) THEN
  BEGIN
   PtrToBool^ := NOT (PtrToBool^);
   UserActivateFunction := TRUE;
  END;
END;

{ ************************************************************************ }
FUNCTION KeyWasPressed : BOOLEAN;
BEGIN
(* KeyWasPressed := LastKeyPress <>#0;*)
 KeyWasPressed := LastKeysPressed.HasAByte;
END;

(*
FUNCTION ReadKeyPress : CHAR;
BEGIN
 ReadKeyPress  := LastKeyPress;
 LastKeyPress  := #0;
END;
*)

function Creadkey : char;
VAR
  TempChar : CHAR;
begin
 { Read application key buffer (without background tasks) first}
 IF LastKeysPressed.HasAByte THEN
  BEGIN
   TempChar := LastKeysPressed.ReadByte;
   (* comment out F6StdUt1 specific stuff
   { save key code for passwording }
   LastReadKey := ORD(TempChar);
   IF FuncKey THEN { this byte is the high byte code for a function key }
     LastReadKey := LastReadKey SHL 8;
   *)
  END
 ELSE
  BEGIN
   REPEAT
     ShowMouseCursor;
     IF ProcessObject <> NIL THEN ProcessObject^.RunTaskCycle;
   UNTIL LastKeysPressed.HasAByte;
   TempChar := LastKeysPressed.ReadByte;
  END;
 CReadKey := TempChar;
end;

function getkey : char;             {Get a Key or Function Key}
var ch : char;
begin
 FuncKey := FALSE;
 ch := CReadKey;
 if ch = NUL then
    begin
     ch := CReadKey;
     Funckey := true;
    end;
   LastKey := ch;
   GetKey := ch;
end;

PROCEDURE Flush_Keyboard_Buffer;
BEGIN
 WHILE KeyWasPressed DO                       { Flush KeyBoard Buffer   }
  BEGIN
   GetKey;                                     { Get Keypress With Comms }
  END;
END;

PROCEDURE GetString(var var_dat:string; var_len,var_x,var_y:integer;CharsToUse : TCharSet;VAR Rect : TRect);
var
      bf          : string;
      osp         : integer;
      i           : BYTE;
      InverseFont : PFontType;
      SecretStr   : STRING;

 procedure addosp(mosp : integer);
 begin;
   if osp = mosp then osp := 1 else osp := osp + 1;
 end;

 procedure subosp(mosp : integer);
 begin;
   if osp = 1 then osp := mosp else osp := osp - 1;
 end;

begin
 esc_flag := FALSE;
 osp      := 1;
 bf       := SPACE_STRING;
 var_dat  := copy(var_dat+bf,1,var_len);

 InverseFont := CreateInverseFont(CurrFontBitMap); { Invert Current Font   }
 NEW(CursorFlash,Init(InverseFont));               { Allocate Cursor Task  }

 WriteStrAt(var_x,var_y,'[');
 WriteStrAt(var_x+var_len+1,var_y,']');

 REPEAT
  IF secret THEN
   BEGIN
    SecretStr[0] := Char(Var_len);
    FOR i := 1 TO var_len DO
     BEGIN
      IF var_dat[i] = ' ' THEN
       SecretStr[I] := ' '
      ELSE
       SecretStr[I] := 'X';
     END;
    WriteStrAt(var_x+1,var_y,copy(SecretStr,1,var_len));
    CursorFlash^.SetCharacterFlashing(var_x+osp,var_y,SecretStr[osp]);
    { ProcessObject^.SetCharacterFlashing(var_x+osp,var_y,SecretStr[osp],InverseFont);}
   END
  ELSE
   BEGIN
    WriteStrAt(var_x+1,var_y,copy(var_dat,1,var_len));
    CursorFlash^.SetCharacterFlashing(var_x+osp,var_y,var_dat[osp]);
    {ProcessObject^.SetCharacterFlashing(var_x+osp,var_y,var_dat[osp],InverseFont);}
   END;

{  WITH Rect DO DrawWindow(Left,Top,Right,Bottom,FALSE);}
  ch  := getkey;
  ch1 := ch;

  if Funckey then
   begin
    ch := CR;                      {Default}
    case ch1 of
     CU_RIGHT    : addosp(var_len);
     CU_LEFT     : subosp(var_len);
     HOME        : begin
		    var_dat := Copy(Bf,1,var_len);
		    osp := 1;
                   end;
    end;
    ch := Ch1;
   end
  else
   BEGIN
    CASE ch of
     CHAR(STX) : begin
       var_dat := COPY(Bf,1,var_len);
       osp := 1;
     end;
     BS  : begin;
      if length(var_dat)<>0 then
       begin
	var_dat[osp] := ' ';
	subosp(1);
	var_dat[osp] := ' ';
       end
     end;
     ESC : esc_flag := TRUE;
    ELSE IF ch IN CharsToUse THEN
     BEGIN
      var_dat[osp] := ch;
      addosp(var_len);
     END;
    END; { case }
   END; { not Funckey }
 UNTIL (ch=CR) or esc_flag;
  IF secret THEN
   BEGIN
    SecretStr[0] := Char(Var_len);
    FOR i := 1 TO var_len DO
     BEGIN
      IF var_dat[i] = ' ' THEN
       SecretStr[I] := ' '
      ELSE
       SecretStr[I] := 'X';
     END;
    WriteStrAt(var_x+1,var_y,copy(SecretStr,1,var_len));
   END
  ELSE
   BEGIN
    WriteStrAt(var_x+1,var_y,copy(var_dat,1,var_len));
   END;
 {ProcessObject^.StopFlashing;}
 ProcessObject^.RemoveBackGroundTask(CursorFlash);
 DeleteFont(InverseFont);
end;


procedure GetLine(var var_dat:string; var_len,var_x,var_y:integer;VAR Rect : TRect);
BEGIN
 GetString(var_dat, var_len, var_x, var_y,NormalChars,Rect);
END;

procedure GetAnyCharStr(var var_dat:string; var_len,var_x,var_y:integer;VAR Rect : TRect);
BEGIN
 GetString(var_dat, var_len, var_x, var_y,AnyChars,Rect);
END;


procedure getline_num (var var_dat:string; var_len,var_x,var_y,dp:integer;VAR Rect : TRect);
(* IF DP = -1 THEN Date Entry DD/MM/YYYY *)
(* IF DP = -2 THEN Time Entry HH:MM *)
var
      bf  : string;
      tstr: string[2];
      osp : integer;
      i   : INTEGER;
      dval: LONGINT;
      ErrInt: INTEGER;
      InverseFont : PFontType;
 procedure addosp(mosp : integer);
 begin;
   if osp = mosp then
     BEGIN
       osp := 1;
       WHILE (var_dat[osp] = ' ') AND (osp < mosp) DO
	   INC (osp);
     END
   else INC(osp);
 end;

 procedure subosp(mosp : integer);
 begin;
   if osp = 1 then osp := mosp else dec(osp);
 end;

begin;
 InverseFont := CreateInverseFont(CurrFontBitMap); { Invert Current Font   }
 NEW(CursorFlash,Init(InverseFont));               { Allocate Cursor Task  }

 IF (dp <> 0) AND (dp <> -1) AND (dp <> -2) THEN
  var_dat := Add_Zeros(var_dat)
 ELSE IF (dp = -1) THEN
  BEGIN
   bf := COPY(var_dat,1,2)+COPY(var_dat,4,2)+COPY(var_dat,7,4);
   var_dat := bf;
  END
 ELSE IF (dp = -2) THEN
  BEGIN
   bf := COPY(var_dat,1,2)+COPY(var_dat,4,2);
   var_dat := bf;
  END;
 esc_flag := FALSE;
 osp := var_len;
 bf  := '                        ';
 var_dat  := copy(var_dat+bf,1,var_len);
 WriteStrAt(Var_X,var_y,'[');
 if dp = 0 then
  MoveToXY(var_x+var_len+1,var_y)
 else if dp = -1 then
  MoveToXY(var_x+var_len+3,var_y)
 else
  MoveToXY(var_x+var_len+1,var_y);
 WriteStr(']');
  repeat
   if dp = 0 then
    WriteStrAt(var_x+1,var_y,copy(var_dat,1,var_len))
   else if dp = -1 then
    WriteStrAt(var_x+1,var_y,copy(var_dat,1,2)+'/'+copy(var_dat,3,2)+'/'+copy(var_dat,5,4))
   else if dp = -2 then
    WriteStrAt(var_x+1,var_y,copy(var_dat,1,2)+':'+copy(var_dat,3,2))
   else
    WriteStrAt(var_x+1,var_y,copy(var_dat,1,dp)+'.'+copy(var_dat,dp+1,var_len-dp));
   CASE DP OF
      0 : MoveToXY(var_x+osp,var_y);
     -1 : MoveToXY(var_x+osp+2,var_y);
     else
      MoveToXY(var_x+osp+1,var_y);
   END;
   CursorFlash^.SetCharacterFlashing(CurrentX,CurrentY,var_dat[osp]);
{ProcessObject^.SetCharacterFlashing(CurrentX,CurrentY,var_dat[osp],InverseFont);}
{   WITH Rect DO DrawWindow(Left,Top,Right,Bottom,FALSE);}
   ch := getkey;
   ch1 := ch;
   if Funckey then
    begin
     ch := CR;                      {Default}
     case ch1 of
      CU_RIGHT    : IF (dp <> -1) AND (dp <> -2) THEN
       BEGIN
	addosp(var_len);
	ch := ch1;
       END
      ELSE IF (dp = -1) THEN
       BEGIN
	var_dat := COPY(var_dat,1,2)+'/'+COPY(var_dat,3,2)+
				     '/'+COPY(var_dat,5,4);
			   IF NOT Valid_Date(var_dat) THEN var_dat := Date;
			   dval := Date_To_Days(var_dat);
			   var_dat := Days_To_Date(dval + 1);
			   bf := COPY(var_dat,1,2)+COPY(var_dat,4,2)+COPY(var_dat,7,4);
			   var_dat := bf;
			  END
			 ELSE
			  BEGIN
			   var_dat := COPY(var_dat,1,2)+':'+COPY(var_dat,3,2);
			   IF NOT Valid_Time(var_dat) THEN var_dat := COPY(Time,1,5);
			   VAL(COPY(var_dat,4,2),dval,ErrInt);
			   dval := dval + 1;
			   IF dval > 59 THEN
			    BEGIN
			     VAL(COPY(var_dat,1,2),dval,ErrInt);
			     dval := dval + 1;
			     IF dval > 23 THEN dval := 0;
			     STR(dval:2,tstr);
			     var_dat := Add_zeros(tstr)+'00';
			    END
			   ELSE
			    BEGIN
			     STR(dval:2,tstr);
			     var_dat := COPY(var_dat,1,2)+add_zeros(tstr);
			    END;
			  END;
	   CU_LEFT   : IF (dp <> -1) AND (dp <> -2) THEN
			  BEGIN
			   subosp(var_len);
			   ch := ch1;
			  END
			 ELSE IF dp = -1 THEN
			  BEGIN
			   var_dat := COPY(var_dat,1,2)+'/'+COPY(var_dat,3,2)+
				      '/'+COPY(var_dat,5,4);
			   IF NOT Valid_Date(var_dat) THEN var_dat := Date;
			   dval := Date_To_Days(var_dat);
			   var_dat := Days_To_Date(dval - 1);
			   bf := COPY(var_dat,1,2)+COPY(var_dat,4,2)+COPY(var_dat,7,4);
			   var_dat := bf;
			  END
			 ELSE
			  BEGIN
			   var_dat := COPY(var_dat,1,2)+':'+COPY(var_dat,3,2);
			   IF NOT Valid_Time(var_dat) THEN var_dat := COPY(Time,1,5);
			   VAL(COPY(var_dat,4,2),dval,ErrInt);
			   dval := dval - 1;
			   IF dval < 0 THEN
			    BEGIN
			     VAL(COPY(var_dat,1,2),dval,ErrInt);
			     dval := dval - 1;
			     IF dval < 0 THEN dval := 23;
			     STR(dval:2,tstr);
			     var_dat := Add_zeros(tstr)+'59';
			    END
			   ELSE
			    BEGIN
			     STR(dval:2,tstr);
			     var_dat := COPY(var_dat,1,2)+add_zeros(tstr);
			    END;
			  END;

	   HOME        : begin
			  var_dat := Copy(Bf,1,var_len);
			  osp := var_len;
			  ch := ch1;
			 end;

	   end
	 end
	 else
	   case ch of
	   '0'..'9' : begin;
			IF (var_dat[var_len-1] <> ' ') OR
			   (var_dat[var_len] <> '0') THEN
                            Move(var_dat[2],var_dat[1],osp-1);
			var_dat[osp] := ch;
		      end;
	   BS,DEL   : begin;
			FOR i := osp DOWNTO 2 DO
			    var_dat[i] := var_dat[i-1];
			var_dat[1] := ' ';
		      end;
	   ESC      : esc_flag := TRUE;

	   end;
      until (ch=CR) or esc_flag OR (ch = HELP) OR (ch = TAB) OR (ch = SH_TAB);
      MoveToXY(var_x,var_y);
      if dp = 0 then
	WriteStr(' '+copy(var_dat,1,var_len)+' ')
      else if dp=-1 then begin
	var_dat := COPY(var_dat,1,2)+'/'+COPY(var_dat,3,2)+
		   '/'+COPY(var_dat,5,4);
	WriteStr(' '+var_dat+' ');
      end
      else if dp=-2 then begin
	var_dat := COPY(var_dat,1,2)+':'+COPY(var_dat,3,2);
	WriteStr(' '+var_dat+' ');
      end
      else begin
	WriteStr(' '+copy(var_dat,1,dp)+ '.');
	WriteStr(copy(var_dat,dp+1,var_len-dp)+' ');
      end;
 {ProcessObject^.StopFlashing;}
 ProcessObject^.RemoveBackGroundTask(CursorFlash);
 DeleteFont(InverseFont);
end;


PROCEDURE GetDate(VAR Dt:LONGINT;Atx,Aty:INTEGER;VAR Rect : TRect);
VAR DtStr : STRING[15];
BEGIN
 REPEAT
  DtStr:=Days_To_Date(Dt);
  GetLine_Num(DtStr,8,Atx,Aty,GetDateType,Rect);
 UNTIL Valid_Date(DtStr);
 Dt:=Date_To_Days(DtStr);
END;

PROCEDURE GetTime(VAR Tm:Time_Type;Atx,Aty:INTEGER;VAR Rect : TRect);
BEGIN
 REPEAT
  GetLine_Num(Tm,4,Atx,Aty,GetTimeType,Rect);
 UNTIL Valid_Time(Tm);
END;

PROCEDURE GetDouble(VAR D:DOUBLE;Size,Dp:INTEGER;Atx,Aty:Integer;VAR Rect : TRect);
VAR
 Input  : STRING[10];
 Error  : integer;
BEGIN
 Input := DoubleToZeroStr(D,Size,Dp);
 Repeat
  GetFloat(Atx,Aty,Input,Size,Dp,Rect);
  Val(Input,D,Error);
 Until (Error = 0);
End;

PROCEDURE GetHexNum(Var I:WORD;Size:INTEGER;Atx,Aty:Integer;VAR Rect : TRect);
VAR
 Input  : STRING[10];
 Error  : integer;
BEGIN
 Input := IntToHexStr(I,Size DIV 2);
 Repeat
  GetString(Input,Size,Atx,Aty,HexChars,Rect);
  HexStrToInt(Input,I,Error);
 Until (Error = 0);
End;

PROCEDURE GetInteger(Var I:Integer;Size:INTEGER;Atx,Aty:Integer;VAR Rect : TRect);
VAR
 Input  : STRING[10];
 Error  : integer;
BEGIN
 Input := IntToZeroStr(I,Size);
 Repeat
  GetLine_Num(Input,Size,Atx,Aty,0,Rect);
  Val(Input,I,Error);
 Until (Error = 0);
End;

PROCEDURE GetLongInt(Var L:LongInt;Size:INTEGER;Atx,Aty:Integer;VAR Rect : TRect);
VAR
 Input  : STRING[10];
 Error  : integer;
BEGIN
 Input := IntToZeroStr(L,Size);
 Repeat
  GetLine_Num(Input,Size,Atx,Aty,0,Rect);
  Val(Input,L,Error);
 Until (Error = 0);
End;

PROCEDURE GetFloat(XPos,YPos : INTEGER;         { Window Posn }
		   VAR WorkStr : STRING;
		   Width,DecimalPlaces : BYTE;VAR Rect : TRect); { As Pascal formatting }
VAR PreDP : INTEGER;
BEGIN
  IF DecimalPlaces > 0 THEN
   BEGIN
    PreDP := (Width-1)-DecimalPlaces;
    WorkStr := Copy(WorkStr,1,PreDP) + Copy(WorkStr, PreDP+2, DecimalPlaces);
    GetLine_Num(WorkStr, Width-1, XPos, YPos, PreDP,Rect);
    WorkStr := Copy(WorkStr,1,PreDP) + '.' + Copy(WorkStr,PreDP+1,DecimalPlaces);
   END
  ELSE
    GetLine_Num(WorkStr, Width, XPos, YPos, 0,Rect);
END;

PROCEDURE GetTick(VAR var_dat: STRING; var_x,var_y : INTEGER);
BEGIN
  MoveToXY(var_x,var_y);
  WriteStr('['+var_dat[1]+']');
  Funckey := FALSE;
  REPEAT
   ch := getkey;
   IF ch IN [ENTER,TAB,SH_TAB] THEN FuncKey :=TRUE;
   ch1 := ch;
   IF NOT Funckey AND (ch1 = ' ') THEN  { Add To Imporve Consistance       }
    BEGIN                               { To be removed when all tick boxes}
     var_dat[0] :=#1;                   { use this procedure               }
     IF var_dat[1]= TICK_CHAR THEN var_dat[1] := ' ' ELSE var_dat[1] := TICK_CHAR;
    END;
   MoveToXY(var_x,var_y);
   WriteStr('['+var_dat[1]+']');
  UNTIL Funckey OR (ch1 = ESC) OR (ch = CR);
END;


PROCEDURE GetRadio(VAR var_dat: STRING; var_x,var_y : INTEGER);
BEGIN
  MoveToXY(var_x,var_y);
  WriteStr('('+var_dat[1]+')');
  Funckey := FALSE;
  ch := getkey;
  IF ch = ENTER THEN FuncKey :=TRUE;
  ch1 := ch;
  IF NOT Funckey AND (ch1 = ' ') THEN  { Add To Imporve Consistancy       }
   BEGIN                               { To be removed when all tick boxes}
    var_dat[0] :=#1;                   { use this procedure               }
    IF var_dat[1]= RADIO_CHAR THEN var_dat[1] := ' ' ELSE var_dat[1] := RADIO_CHAR;
   END;
  MoveToXY(var_x,var_y);
  WriteStr('('+var_dat[1]+')');
END;

PROCEDURE GetBoolean(Var TheBool : BOOLEAN;var_x,var_y : INTEGER;BoolType : CheckBoxTypes);
VAR WorkBool : STRING[1];
BEGIN
 CASE BoolType OF
  RadioButton : BEGIN
   IF TheBool THEN WorkBool := RADIO_CHAR
   ELSE WorkBool := ' ';
   GetRadio(WorkBool,var_x,var_y);
   TheBool := WorkBool[1]=RADIO_CHAR;
  END;
  TickBox     : BEGIN
   IF TheBool THEN WorkBool := TICK_CHAR
   ELSE WorkBool := ' ';
   GetTick(WorkBool,var_x,var_y);
   TheBool := WorkBool[1]=TICK_CHAR;
  END;
 END;
END;



BEGIN
 Funckey := FALSE;
 LastKeysPressed.Init;
end.

(****************************************************************************
*  UNIT          : SFXGraph                                                 *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Graphic Routines                            *
*  MODIFICATIONS :-version 1.1                                              *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXGraph;
INTERFACE
USES Dos,F6StdCtv;
{$S-}

CONST
SC_INDEX       = $3c4;       {      ;Index register for sequencer ctrl.  }
SC_MAP_MASK    = 2;          {      ;Number of map mask register         }
SC_MEM_MODE    = 4;          {      ;Number of memory mode register      }

GC_INDEX       = $3ce;       {      ;Index register for graphics ctrl.   }
GC_READ_MAP    = 4;          {      ;Number of read map register         }
GC_BIT_MASK    = 8;          {      ;Number of bit mask register         }


CONST BackGroundColour  = 15;
CONST ForeGround        = 0;

CONST TXTForeGround     : BYTE = ForeGround;
CONST TXTBackGround     : BYTE = BackGroundColour;

CONST BackGround  : BYTE = BackGroundColour;    {Used For Writing Text}


CONST CurrentColour : BYTE = ForeGround;        {Used For Drawing Lines}


CONST MaxX     = 639;
CONST MaxY     = 479;
CONST MaxTextX = 80;
CONST MaxTextY = 60;

const NormalPUT =0;
const ANDPUT    =1;
const ORPUT     =2;
const XORPUT    =3;
const OVERPUT   =4;


const FONT_8X14   =2;
const FONT_8X8    =3;
const FONT_8X8T   =4;
const FONT_9X14   =5;
const FONT_8X16   =6;
const FONT_9X16   =7;

CONST FontNormal   = $00;
      FontInversed = $01;
      FontGreyed   = $02;

{Percentage Bar Constants}

CONST Horiz = $00;
CONST Vert  = $80;

TYPE RGBColour = PACKED RECORD
       Red   : BYTE;
       Green : BYTE;
       Blue  : BYTE;
     END;

     TColourList = ARRAY[0..15] OF RGBColour;

Const
  DitherArray : ARRAY[0..16,0..1] OF BYTE =
       (($00,$00),
        ($99,$66),
        ($55,$AA),
        ($CC,$33),
        ($84,$42),
        ($CC,$33),
        ($A5,$42),
        ($AA,$54),
        ($AA,$55),
        ($AA,$57),
        ($AA,$57),
        ($BA,$57),
        ($BA,$E7),
        ($BF,$E7),
        ($BF,$F7),
        ($FF,$F7),
        ($FF,$FF));


TYPE PLong = ^Longint;
     PByte = ^BYTE;
     PScaleFontList = ^TScaleFontList;
     TScaleFontList = ARRAY[0..2048] OF LONGINT;

TYPE
    PFontBitMap = ^TFontBitMap;
    TFontBitMap = PACKED RECORD
     FontPtr  : PChar;
     FontSize : WORD;
    END;



TYPE  PFontType = ^TFontType;
      TFontType = PACKED RECORD
       fontStyle      : INTEGER;
       fontheight     : INTEGER;              (* Font Height         *)
       fontwidth      : INTEGER;              (* Font Width (not supported) *)
       fontHeightSize : INTEGER;              (* SrcFont Height Pix. *)
       fontscale      : BYTE;
       bitmapheight   : INTEGER;
       bitmapwidth    : INTEGER;
       thefont        : PScaleFontList;
     END;

TYPE  TRect = PACKED RECORD
       Left,Right,Top,Bottom : WORD;
      END;


TYPE TArrowDirection = (ArrowLeft,ArrowUp,ArrowRight,ArrowDown);


VAR
    FP_Font8x8        : PFontBitMap;
    FP_Font8x16       : PFontBitMap;
    FONTPTR           : PChar;                       (* Ptr To Curr Src.Font*)
    CurrFontBitmap    : PFontType;                   (* Ptr To Scaled Font  *)
    ScreenPtr         : PChar;                       (* Ptr To Screen Mem   *)
    CurrentX,
    CurrentY          : INTEGER;
    CurrentFontHeight : INTEGER;
    CurrentFontWidth  : INTEGER;
    DefaultFont       : PFontType;
    Font8x8           : PFontType;
    Font8x16          : PFontType;
    Shadowing         : BOOLEAN;
    DefaultColours    : TColourList;
    Colours           : TColourList;

{================= Line Rountines =====================}
PROCEDURE drawline(x1,y1,x2,y2:INTEGER);
PROCEDURE drawlineHORIZ(x1,x2,y:WORD;ThickNess : INTEGER);
PROCEDURE DrawLineVert(X,Y1,Y2 : WORD;ThickNess : INTEGER);
PROCEDURE SetLineStyle(Style : INTEGER);
{=================Character Routines======================}
(*PROCEDURE WriteCharAtPixel(x,y:WORD;Str:Char);*)
PROCEDURE WriteCharAt(x,y:WORD;Str:Char);
PROCEDURE WriteColourCharAt(x,y:integer;thechar : char; fg, bk : byte );
PROCEDURE WriteChar(CH:CHAR);
PROCEDURE WriteStrAt(x,y:INTEGER;Str : STRING);
PROCEDURE WriteStr(Str : STRING);
PROCEDURE WriteStrAtPixel(X,Y : INTEGER;Str : STRING);
FUNCTION  SetTextColour(NewCol :BYTE ) : BYTE;
{==================Mouse Routines================}
FUNCTION  MousePresent : BOOLEAN;
PROCEDURE ShowMouseCursor;
PROCEDURE HideMouseCursor;
{=================Windowing Routines============================}
PROCEDURE HighlightWindow(X,Y,Width,Height : INTEGER;Col : BYTE);
PROCEDURE DrawWindow(left,top,right,bottom : INTEGER;Shadow : BOOLEAN);
PROCEDURE DeleteWindow(left,top,right,bottom : INTEGER);
PROCEDURE DrawRectangle(left,top,right,bottom : INTEGER);
{================Misc Routines================================}
PROCEDURE ClrGraphWin;
PROCEDURE ShowCursorATXY(X,Y : INTEGER);
PROCEDURE DrawArrow(Direction : TArrowDirection;X1,Y1,X2,Y2 : INTEGER);
PROCEDURE MoveToXY(X,Y : INTEGER);
PROCEDURE WritePixel(x,y:INTEGER;Colour : BYTE;Mask : BYTE);
PROCEDURE DisplayBitMap(X,Y : INTEGER;BitMapFileName : STRING;ChangeCols : BOOLEAN);
PROCEDURE CopyBackScreenToMainScreen(X1,Y1,X2,Y2 : WORD);
PROCEDURE WriteByteToScreen(X,Y : INTEGER;Mask : BYTE);
FUNCTION  IsPointInRect(X,Y : INTEGER;VAR Rect : TRect) : BOOLEAN;
PROCEDURE SetColours(ColourList : TColourList);
PROCEDURE ScrollWindowUp(X1,Y1,X2,Y2 : INTEGER;ScrollBy : INTEGER);
{=====================Graph initailisation and destruction routines=====}
PROCEDURE GraphDone;
FUNCTION  GraphInit:BOOLEAN;
PROCEDURE CloseGraphMode;
{=====================Font Routines=====================}
FUNCTION  CreateFont(height,width,Direction : WORD;Style : BYTE;FontType : WORD):PFontType;
FUNCTION  SetCurrentFont(FontToSet : PFontType) : PFontType;
FUNCTION  CopyFont(Source : PFontType): PFontType;
FUNCTION  CreateInverseFont(Source : PFontType) : PFontType;
PROCEDURE DeleteFont(ToDeleteFont : PFontType);
{====================SCREEN WRITING ROUTINES=============}
PROCEDURE WriteToBackScreen;
PROCEDURE WriteToMainScreen;
{==================== PORT STUFF ========================}
PROCEDURE SetColour(Colour : BYTE);
PROCEDURE ClearPorts;

FUNCTION SetBackColour(NewCol : BYTE) : BYTE;
FUNCTION SetForeColour(NewCol : BYTE) : BYTE;

PROCEDURE SetDefaultPallete(Contrast : BYTE;GreyScale : BOOLEAN);

VAR
    GraphicsModeSet : BOOLEAN;

VAR
    ScreenOfs       : Array[0..799] OF WORD;
    Dummy           : CHAR;
    Dithering       : BOOLEAN;
    DPattern        : WORD;
CONST
    MouseActive     : BOOLEAN = FALSE;

IMPLEMENTATION


PROCEDURE WriteToBackScreen;
BEGIN

END;

PROCEDURE WriteToMainScreen;
BEGIN

END;

FUNCTION  IsPointInRect(X,Y : INTEGER;VAR Rect : TRect) : BOOLEAN;
BEGIN
 WITH Rect DO
  IsPointInRect := (X>=Left) AND (X<=Right) AND
                   (Y>=Top)  AND (Y<=Bottom);
END;

{  PROCEDURES AND FUNCTIONS NOT AVAILABLE FROM OTHER UNITS}
{Called By GraphInit}
FUNCTION SetGraphicsMode:BOOLEAN;
var
 I : WORD;
begin
 asm
        mov ax,$12
        int $10
        mov ax,0
        int $33
 end;
 GraphicsModeSet := TRUE;
 SetGraphicsMode := TRUE;
 FOR I:=0 TO 799 DO ScreenOfs[I]:=I*80;
end;

{Called By Create Font}
PROCEDURE GetFontPtr(fontno : BYTE);
BEGIN
 CASE fontno OF
  FONT_8X8,
  FONT_8X8T: BEGIN
              CurrentFONTHeight :=  8;
              CurrentFontWidth  :=  8;
              FontPtr := FP_Font8x8^.FontPtr;
             END;
  FONT_8X16: BEGIN
              CurrentFontHeight := 16;
              CurrentFontWidth  :=  8;
              FontPtr := FP_Font8x16^.FontPtr;
             END;
 ELSE
  BEGIN
   CurrentFontHeight := 8;
   CurrentFontWidth  := 8;
   FontPtr := FP_Font8x8^.FontPtr;
  END;
 END;
END;

{Called By Create Font}
PROCEDURE ScaleFontBitmap(xmag : INTEGER;VAR fscaletab : TFontType;FontType : WORD);
CONST xpandvalues:ARRAY[0..4] OF INTEGER=(0,1,3,7,15);
VAR
 byteptr,byteptr1 : PChar;
 copyval : LONGINT;
 chrpos  : WORD;
 andval  : BYTE;
 XorMask : BYTE;
 OrMask  : BYTE;
BEGIN
 IF (FontType AND FontInversed) <> 0 THEN
  XorMask := $00
 ELSE
  XorMask := $FF;

 IF (FontType AND FontGreyed) <> 0 THEN
  ORMask := $AA
 ELSE
  OrMask := $00;

 WITH FScaleTab DO
  BEGIN
   FillChar(TheFont^,SizeOf(TheFont^),#0);       (* clear bitmap table    *)
   for chrpos := 0 TO (128 * FontHeightSize) DO  (* for all ascii chars   *)
    BEGIN
     andval := 128;                              (* start at first bit    *)
     REPEAT
      TheFont^[chrpos]:=TheFont^[chrpos] shl xmag;(* shift bitmap left    *)
      IF ((BYTE(FONTPTR[chrpos]) AND andval) = andval) THEN(* test bit              *)
       BEGIN
        TheFont^[chrpos] := TheFont^[chrpos] OR xpandvalues[xmag];(* or in bit pattern     *)
       END;
      andval:=andval shr 1;                      (* next bit test mask    *)
     UNTIL (andval < 1);

     copyval    := TheFont^[chrpos];
     byteptr    := PChar(@TheFont^[chrpos]);
     byteptr1   := PChar(@copyval);

     byteptr[0] := CHAR(ORD(byteptr1[3]) XOR XorMask OR OrMask);
     byteptr[1] := CHAR(ORD(byteptr1[2]) XOR XorMask OR OrMask);
     byteptr[2] := CHAR(ORD(byteptr1[1]) XOR XorMask OR OrMask);
     byteptr[3] := CHAR(ORD(byteptr1[0]) XOR XorMask OR OrMask);

     IF (FontType AND FontGreyed) <> 0 THEN
      ORMask := OrMask XOR $FF
    END;
  END;
END;

PROCEDURE SetRes(value:integer);
BEGIN
 PortW[$3ce]:=value shl 8;
END;

PROCEDURE RMask(value : WORD);
BEGIN
 PortW[$3ce] := value shl 8+8;
END;

PROCEDURE ESetRes(value:INTEGER);
BEGIN
 PortW[$3ce]:=value*256+1;
END;

PROCEDURE ClearPorts;
BEGIN
 ESetRes(0);
 SetRes(ForeGround);
 RMask(255);
END;

PROCEDURE SetColour(Colour : BYTE);
BEGIN
 ESetRes(15);
 SetRes(Colour);
 CurrentColour := Colour;
END;

PROCEDURE MaskByte(Row : WORD;Mask : BYTE);
BEGIN
 IF dithering THEN
  BEGIN
   Mask := Mask AND DitherArray[DPattern,Row]
  END;
 RMask(Mask);
END;

PROCEDURE WriteByteToScreen(X,Y : INTEGER;Mask : BYTE);
VAR Ofs : LONGINT;
BEGIN
 Ofs := Screenofs[Y]+X DIV 8;
 MaskByte((Ofs DIV 80) MOD 2,Mask);
 Dummy := SCREENPTR[Ofs];
 ScreenPtr[Ofs] := Dummy;
END;

{  PROCEDURES AND FUNCTIONS AVAILABLE FROM OTHER UNITS}
PROCEDURE HighlightWindow(X,Y,Width,Height : INTEGER;Col : BYTE);
VAR Row,Column : INTEGER;
{Read Line Record. Add transaction Wt and then save}
BEGIN
 CurrentColour:=Col;
 for Row:=1 TO 5 DO
  DrawLine(X+Row,Y+2,X+Row,Y+Height-1);
 for Row:=2 TO 5 DO
  DrawLine(X+Width-Row,Y+2,X+Width-Row,Y+Height-1);
 for Column:=2 to 3 do
  DrawLine(X+2,Y+Column,X+Width-2,Y+Column);
 for Column:=-3 to -2 do
  DrawLine(X+2,Y+Height+Column,X+Width-2,Y+Height+Column);
 CurrentColour := ForeGround;
END;

FUNCTION MousePresent : BOOLEAN;
BEGIN
ASM
        MOV AX,0
        INT 33h
        MOV @Result,al
        MOV MouseActive,al
END;
END;

PROCEDURE ShowMouseCursor;
BEGIN
 IF MouseActive THEN
   ASM
	mov ax,1
        int 33h
   END;
END;

PROCEDURE HideMouseCursor;
BEGIN
 IF MouseActive THEN
   ASM
	mov ax,2
        int 33h
   END;
END;

PROCEDURE MoveToXY(X,Y : INTEGER);
BEGIN
 CurrentX:=X;CurrentY:=Y;
END;

PROCEDURE DeleteFont(ToDeleteFont : PFontType);
BEGIN
 IF ToDeleteFont = CurrFontBitmap THEN CurrFontBitmap := NIL;
 Dispose(ToDeleteFont^.TheFont);
 Dispose(ToDeleteFont);
END;

PROCEDURE CloseGraphMode;
BEGIN
 IF Not GraphicsModeSet THEN EXIT;
 ASM
        Mov ax,3
        Int $10
 END;
 GraphicsModeSet := FALSE;
END;

FUNCTION CreateFont(height,width,Direction : WORD;Style : BYTE;FontType : WORD):PFontType;
VAR NewFont : PFontType;
    XorMask : BYTE;
BEGIN
 GetFontPtr(Style);
 IF CurrentFontWidth * Width >32 THEN
  BEGIN
   NewFont := NIL;
   EXIT;
  END;
 New(NewFont);
 New(NewFont^.TheFont);
 WITH NewFont^ DO
  BEGIN
   FontStyle      := Style OR Direction;
   Fontheight     := height;
   Fontwidth      := width;
   FontHeightSize := CurrentFontHeight;
   FontScale      := (FontHeightSize DIV 8)+2;
   BitMapHeight   := fontheight * fontHeightsize;
   BitMapWidth    := 8*fontwidth;
  END;
 ScaleFontBitMap(Width,NewFont^,FontType);
 CreateFont := NewFont;
END;

FUNCTION CopyFont(Source : PFontType): PFontType;
VAR NewFont : PFontType;
BEGIN
 New(NewFont);
 New(NewFont^.TheFont);
 WITH NewFont^ DO
  BEGIN
   fontheight     := Source^.fontheight;
   fontwidth      := Source^.fontwidth;
   FontHeightSize := Source^.FontHeightSize;
   FontScale      := Source^.FontScale;
   BitMapHeight   := Source^.BitMapHeight;
   BitMapWidth    := Source^.BitMapWidth;
   Move(Source^.TheFont^,TheFont^,SizeOf(TheFont^));
  END;
 CopyFont := NewFont;
END;

FUNCTION  CreateInverseFont(Source : PFontType) : PFontType;
VAR NewFont : PFontType;
BEGIN
 NewFont := CopyFont(Source);
 GetFontPtr(Source^.FontStyle);
 ScaleFontBitMap(NewFont^.FontWidth,NewFont^,FontInversed);
 CreateInverseFont := NewFont;
END;

PROCEDURE CopyBackScreenToMainScreen(X1,Y1,X2,Y2 : WORD);
BEGIN
ASM
            MOV   DX,X2
            ADD   DX,7
            SHR   DX,3
            MOV   AX,X1
            SHR   AX,3
            SUB   DX,AX
            MOV   AX,Y2
            SUB   AX,Y1
            MOV   BX,AX
            MOV   DI,Y1
            ADD   DI,DI
            MOV   DI,[DI+Offset(ScreenOfs)]
            MOV   AX,X1
            SHR   AX,3
            ADD   DI,AX
            MOV   SI,DI
            ADD   SI,80*480
            PUSH  DS
            MOV   AX,SegA000
            MOV   ES,AX
            MOV   DS,AX
            MOV   AX,80
            SUB   AX,DX
@Loop1:
            MOV   CX,DX
            REP   MOVSB
            ADD   DI,AX
            ADD   SI,AX
            DEC   BX
            JNZ   @Loop1
            POP   DS
END;
END;

FUNCTION SetCurrentFont(FontToSet : PFontType) : PFontType;
BEGIN
 SetCurrentFont := CurrFontBitMap;    { Return Pointer To Old Font}
 CurrFontBitmap := FontToSet;         { Select New Font           }
END;

PROCEDURE WriteBytesToScreen(X,Y : WORD;bArr : ARRAY OF BYTE);
BEGIN
ASM
	   PUSH  DS
           CLD
           MOV   ES,SegA000
           MOV   DI,Y
           ADD   DI,DI
           MOV   DI,[DI+OFFSET(ScreenOfs)]
           MOV   AX,X
           SHR   AX,3
           ADD   DI,AX
	   mov   ah,BackGround
           LDS   SI,bArr
	   mov   al,SC_MAP_MASK   {;Register number to AL    }
           mov   dx,SC_INDEX      {;Open access to plane for}
           out   dx,ax
           MOV   CX,8
	   REP   movsb
           mov   ax,(0Fh shl 8)+ SC_MAP_MASK
	   mov   dx,SC_INDEX
	   out   dx,ax
	   pop   ds            {   ;Retrieve DS and BP}
END;
END;
(*
PROCEDURE WriteCharAtPixel(X,Y:WORD;Str : CHAR);
VAR
 FontWidth : INTEGER;
 FontHeight: INTEGER;
 FONTSize  : INTEGER;
 FontScale : BYTE;
 TheFont   : PScaleFontList;
BEGIN
 IF ORD(Str)<32 THEN
  BEGIN
   IF (Str IN [#13,#10]) THEN
    BEGIN
     CASE Str OF
      #13 : CurrentX:=0;
      #10 : INC(CurrentY);
     END;
     EXIT;
    END;
  END;
 IF (CurrFontBitmap=NIL) THEN SetCurrentFont(DefaultFont);
 FontWidth := CurrFontBitMap^.FontWidth;
 FontHeight:= CurrFontBitMap^.FontHeight;
 FontScale := CurrFontBitMap^.FontScale;
 FontSize  := CurrFontBitMap^.FontHeightSize;
 TheFont   := CurrFontBitMap^.TheFont;
ASM

	   mov   ah,TXTBackGround
	   mov   al,SC_MAP_MASK   {;Register number to AL    }
           mov   dx,SC_INDEX      {;Open access to plane for}
           out   dx,ax

	   PUSH DS
           CLD
           MOV   ES,SegA000
           MOV   DI,Y
           ADD   DI,DI
           MOV   DI,[DI+OFFSET(ScreenOfs)]
           MOV   AX,X
           SHR   AX,3
           ADD   DI,AX

           LDS   SI,TheFont
           XOR   AH,AH
           MOV   Al,str
           MOV   CL,FontScale
           SHL   AX,CL
           ADD   AX,1
           SHL   AX,2
           ADD   SI,AX
           Sub   SI,FontWidth
@Loop2:

           MOV   BX,FontHeight
@Loop11:
           PUSH  SI
           MOV   CX,X
           PUSH  DI
           AND   CL,7
           MOV   DX,Fontwidth
           MOV   CH,8
           MOV   AH,ES:[DI]
           SUB   CH,CL
@WriteToScreen1:
           MOV   AL,$FF
           XCHG  CH,CL
           ROR   AX,CL
           XCHG  CH,CL
           LODSB
           ROR   AX,CL
           STOSB
	   DEC   DX
           JNZ   @WriteToScreen1
           MOV   CH,$FF
           SHR   CH,CL
           MOV   AL,ES:[DI]
           AND   AL,CH
           XOR   CH,$FF
           AND   AH,CH
           OR    AH,AL
           MOV   ES:[DI],AH
           POP   DI
           POP   SI
           ADD   DI,80
           DEC   BX
           JNZ   @Loop11
           ADD   SI,4
           MOV   BX,FontHeight
@Loop12:
           PUSH  SI
           MOV   CX,X
           PUSH  DI
           AND   CL,7
           MOV   DX,Fontwidth
           MOV   CH,8
           MOV   AH,ES:[DI]
           SUB   CH,CL
@WriteToScreen2:
           MOV   AL,$FF
           XCHG  CH,CL
           ROR   AX,CL
           XCHG  CH,CL
           LODSB
           ROR   AX,CL
           STOSB
	   DEC   DX
           JNZ   @WriteToScreen2
           MOV   CH,$FF
           SHR   CH,CL
           MOV   AL,ES:[DI]
           AND   AL,CH
           XOR   CH,$FF
           AND   AH,CH
           OR    AH,AL
           MOV   ES:[DI],AH
           POP   DI
           POP   SI
           ADD   DI,80
           DEC   BX
           JNZ   @Loop12
           ADD   SI,4

           SUb   FontSize,2
           JNZ   @Loop2

	   mov   ax,(0Fh shl 8)+ SC_MAP_MASK
	   mov   dx,SC_INDEX
	   out   dx,ax
	   pop   ds            {   ;Retrieve DS and BP}
END;
END;
*)

(*
PROCEDURE WriteCharAt(X,Y : WORD;STR : CHAR);
VAR
 FontWidth : INTEGER;
 FontHeight: INTEGER;
 FontSize  : INTEGER;
 FontScale : BYTE;
 TheFont   : PScaleFontList;
BEGIN
 FontWidth := CurrFontBitMap^.FontWidth;
 FontHeight:= CurrFontBitMap^.FontHeight;
 FontSize  := CurrFontBitMap^.FontHeightSize;
 TheFont   := CurrFontBitMap^.TheFont;
 FontScale := CurrFontBitMap^.FontScale;
ASM
	   mov   ah,TXTBackGround
	   mov   al,SC_MAP_MASK   {;Register number to AL    }
           mov   dx,SC_INDEX      {;Open access to plane for}
           out   dx,ax

	   PUSH  DS
           MOV   DI,Y
           MOV   ES,SegA000
           SHL   DI,4      {x16  (x8x2)}
           CLD
           MOV   DI,[DI+OFFSET(ScreenOfs)]
           ADD   DI,X

           LDS   SI,TheFont
           XOR   AH,AH
           MOV   CL,FontScale
           MOV   Al,str
           SHL   AX,CL
           ADD   AX,1
           SHL   AX,2     {x4}
           ADD   SI,AX
           Sub   SI,FontWidth

@Loop2:

           MOV   BX,FontHeight
           MOV   DX,SI
@Loop11:
           LEA   AX,[DI+80]
           MOV   CX,Fontwidth
	   REP   movsb
           MOV   DI,AX
           MOV   SI,DX
           DEC   BX
           JNZ   @Loop11
           ADD   SI,4

           MOV   BX,FontHeight
           MOV   DX,SI
@Loop12:
           LEA   AX,[DI+80]
           MOV   CX,Fontwidth
	   REP   movsb
           MOV   DI,AX
           MOV   SI,DX
           DEC   BX
           JNZ   @Loop12
           ADD   SI,4

           MOV   BX,FontHeight
           MOV   DX,SI
@Loop13:
           LEA   AX,[DI+80]
           MOV   CX,Fontwidth
	   REP   movsb
           MOV   DI,AX
           MOV   SI,DX
           DEC   BX
           JNZ   @Loop13
           ADD   SI,4

           MOV   BX,FontHeight
           MOV   DX,SI
@Loop14:
           LEA   AX,[DI+80]
           MOV   CX,Fontwidth
	   REP   movsb
           MOV   DI,AX
           MOV   SI,DX
           DEC   BX
           JNZ   @Loop14
           ADD   SI,4

           MOV   BX,FontHeight
           MOV   DX,SI
@Loop15:
           LEA   AX,[DI+80]
           MOV   CX,Fontwidth
	   REP   movsb
           MOV   DI,AX
           MOV   SI,DX
           DEC   BX
           JNZ   @Loop15
           ADD   SI,4
           MOV   BX,FontHeight
           MOV   DX,SI
@Loop16:
           LEA   AX,[DI+80]
           MOV   CX,Fontwidth
	   REP   movsb

           MOV   DI,AX
           MOV   SI,DX
           DEC   BX
           JNZ   @Loop16
           ADD   SI,4
           MOV   BX,FontHeight
           MOV   DX,SI
@Loop17:
           LEA   AX,[DI+80]
           MOV   CX,Fontwidth
	   REP   movsb
           MOV   DI,AX
           MOV   SI,DX
           DEC   BX
           JNZ   @Loop17
           ADD   SI,4
           MOV   BX,FontHeight
           MOV   DX,SI
@Loop18:
           LEA   AX,[DI+80]
           MOV   CX,Fontwidth
	   REP   movsb
           MOV   DI,AX
           MOV   SI,DX
           DEC   BX
           JNZ   @Loop18
           ADD   SI,4

           Sub   FontSize,8
           Jne   @Loop2

	   mov   ax,(0Fh shl 8)+ SC_MAP_MASK
	   mov   dx,SC_INDEX
	   out   dx,ax
	   pop   ds            {   ;Retrieve DS and BP}
           STI
END;
END;
*)

PROCEDURE WriteCharAt(X,Y : WORD; STR : CHAR);
BEGIN
 WriteColourCharAt(X*8,Y*8,STR,TXTForeGround,TXTBackGround);
END;

PROCEDURE WriteChar(CH:CHAR);
BEGIN
 IF (CurrFontBitmap=NIL) THEN SetCurrentFont(DefaultFont);
 WriteCharAt(CurrentX,CurrentY,CH);
 Inc(CurrentX);
END;

PROCEDURE WriteStr(Str : STRING);
VAR I : INTEGER;
BEGIN
 IF (CurrFontBitmap=NIL) THEN SetCurrentFont(DefaultFont);
 IF (CurrFontBitMap^.fontStyle{TextDirection} AND VERT) <> 0 THEN
  BEGIN
   FOR I:=1 TO Length(str) DO
    BEGIN
     WriteCharAt(Currentx,Currenty,Str[i]);
     INC(CurrentY,(CurrFontBitMap^.BitMapHeight DIV 8));
    END;
  END
 ELSE
  BEGIN
   FOR I:=1 TO Length(str) DO
    BEGIN
     WriteCharAt(Currentx,Currenty,Str[i]);
     INC(Currentx,CurrFontBitMap^.Fontwidth);
    END;
  END;
 IF (CurrFontBitMap^.FontStyle{TextDirection} AND Vert) =0{ = HORIZ} THEN
  BEGIN
   IF CurrentX>79 THEN
    BEGIN
     INC(CurrentY,CurrFontBitMap^.BitMapHeight DIV 8);
     CurrentX := 0;
    END;
  END
 ELSE
  BEGIN
{  CurrentY:=CurrentY+(CurrFontBitMap^.BitMapHeight DIV 8)*Length(Str);}
  END;
 IF CurrentY>50 THEN CurrentY := 0;
END;


PROCEDURE WriteStrAt(x,y:INTEGER;Str : STRING);
BEGIN
 MoveToXy(x,y);
 WriteStr(str);
END;

PROCEDURE WriteStrAtPixel(X,Y : INTEGER;Str : STRING);
VAR I : INTEGER;
BEGIN
 FOR I := 1 TO Length(Str) DO
  BEGIN
   WriteColourCharAt(X,Y,Str[I],TXTForeGround,TXTBackGround);
   INC(X,CurrFontBitMap^.BitMapWidth);
  END;
END;


FUNCTION SetTextColour(NewCol : BYTE) : BYTE;
BEGIN
 SetTextColour := (TXTBackGround SHL 4)+TXTForeGround;
 TXTBackGround := NewCol SHR 4;
 TXTForeGround := NewCol AND $0F;
END;


PROCEDURE drawlineVERT(x,y1,y2:word;ThickNess : INTEGER);
VAR mask       : BYTE;
    mask1,mask2 : BYTE;
    TempW       : WORD;
BEGIN
 IF Y1 > Y2 THEN
  BEGIN
   TempW := Y1;
   Y1 :=Y2;
   Y2 := TempW;
  END;
ASM
        MOV CX,x
        MOV AH,$80
        AND CX,7
        SHR AH,CL
        MOV MASK,AH

END;
 IF dithering THEN
  BEGIN
   mask1 := Mask AND DitherArray[DPattern,1];
   Mask2 := MaSK AND DitherArray[DPattern,0];
  END
 ELSE
  BEGIN
   Mask1 := Mask;
   Mask2 := Mask;
  END;
asm
        mov  dx,$3ce
        mov  cx,y2
        mov  al,00
        mov  di,y1
        mov  ah,currentcolour
        sub  cx,di
        out  dx,ax
        mov  ax,$0f01
        mov  es,SegA000
        out  dx,ax


        push cx
        add  di,di
        mov  di,[di+offset(ScreenOfs)]
        mov  ax,x
        push ax
        shr  ax,3
        add  di,ax
        pop  cx
        and  cx,7
        mov  bh,mask1
        mov  bl,mask2
        and  y1,1
        jnz  @Cont
        xchg bh,bl
@Cont:
        mov al,$08

        pop cx
@Loop:
        mov  ah,bh
        mov  al,8
        out  dx,ax
        xchg bh,bl
        mov  al,es:[di]
        mov  es:[di],al
        add  di,80
        dec  cx
        jnz  @Loop
        mov  ax,$FF08
        out  dx,ax
        mov  ax,01
        out  dx,ax
end;
END;


PROCEDURE drawlineHORIZ(x1,x2,y:WORD;ThickNess : INTEGER);
VAR I,YCO : LONGINT;
    smask : BYTE;
    emask : BYTE;
    Mask  : BYTE;
    Start,Stop : INTEGER;
    startx: WORD;
BEGIN
 yco   := ScreenOfs[y];                   { Set Yco To Start Of Line        }
 mask  := 0;
 start := x1;
 stop  := x2;
 startx:= (start DIV 8)+Yco;              { StartX = first Byte To Write To }
 SetRes(CurrentColour);                   { Set Colour }
 ESetRes(15);                             { ??? }
 IF (Start DIV 8) = (Stop DIV 8) THEN
  BEGIN                                   { line start/stop is in same byte}
   { Calculate Start of byte Mask                                          }
   { (set bits from START pixel to end of byte)                            }
   smask := ($FF shr (start and 7));
   { Calculate End of Byte Mask                                            }
   { (set bit from begining of byte to STOP pixel                          }
   emask := (NOT byte(word($FF shr (stop and 7))));
   mask := smask AND emask;
   MaskByte(y MOD 2,Mask);
   Dummy := SCREENPTR[startx];
   ScreenPtr[startx] := Dummy;
  END
 ELSE
  BEGIN
   mask := $FF shr (start and 7);
   MaskByte(y MOD 2,Mask);
   Dummy := SCREENPTR[startx];
   ScreenPtr[startx] := Dummy;
   inc(startx);
   MaskByte(y mod 2,$FF);
   for i:=(start div 8)+1 to (stop div 8)-1 do
    begin
     Dummy := SCREENPTR[startx];
     ScreenPtr[startx] := Dummy;
     inc(startx);
    end;
   if (stop and 7) > 0 then
    begin
     mask := NOT byte(word($FF shr (stop and 7)));
     MaskByte(y mod 2,Mask);
     Dummy := SCREENPTR[startx];
     ScreenPtr[startx] := Dummy;
    end;
  END;
 ClearPorts;
END;

PROCEDURE WritePixel(x,y:INTEGER;Colour : BYTE;Mask : BYTE);ASSEMBLER;
ASM
        MOV   BX,y
        MOV   ES,SegA000
        ADD   BX,BX
        MOV   DX,$3CE
        MOV   BX,[BX+OFFSET(ScreenOfs)]
        MOV   CX,X
        MOV   AX,$0F01
        OUT   DX,AX
        AND   CX,7
        MOV   AH,Colour
        MOV   AL,0
        OUT   DX,AX
        MOV   AX,$8008
        SHR   AH,CL
        AND   AH,Mask         {Mask Byte }
        OUT   DX,AX
        MOV   AX,X
        SHR   AX,3
        ADD   BX,AX
        MOV   AL,ES:[BX]
        MOV   ES:[BX],AL
        MOV   AX,$FF08
        OUT   DX,AX
        MOV   AX,1
        OUT   DX,AX
END;

PROCEDURE WriteColourCharAt(x,y:integer;thechar : char; fg, bk : byte );
CONST MaskVal = $80000000;
VAR
     Height,
     Width,
     RepHeight : INTEGER;
     lMask     : LONGINT;                 { Bit mask for character design }


     PROCEDURE GetlMask;
     VAR
      byteptr,byteptr1 : PChar;
      copyval : LONGINT;

     BEGIN
      WITH CurrFontBitMap^ DO
       BEGIN
        lMask      := theFont^[ord(thechar)*FontHeightSize+Height];

        copyval    := lMask;
        byteptr    := PChar(@lMask);
        byteptr1   := PChar(@copyval);


        CASE FontWidth OF
         1 : BEGIN END;

         2 : BEGIN
              byteptr[2] := CHAR(ORD(byteptr1[3]));
              byteptr[3] := CHAR(ORD(byteptr1[2]));
             {
              byteptr[0] := CHAR(ORD(byteptr1[1]));
              byteptr[1] := CHAR(ORD(byteptr1[0]));}
             END;
         3 : BEGIN
              byteptr[1] := CHAR(ORD(byteptr1[3]));
              byteptr[2] := CHAR(ORD(byteptr1[2]));
              byteptr[3] := CHAR(ORD(byteptr1[1]));
             END;
         4 : BEGIN
              byteptr[0] := CHAR(ORD(byteptr1[3]));
              byteptr[1] := CHAR(ORD(byteptr1[2]));
              byteptr[2] := CHAR(ORD(byteptr1[1]));
              byteptr[3] := CHAR(ORD(byteptr1[0]));
             END;
         END;
       END;
     END;

    PROCEDURE SetScreenBit(x,y:INTEGER;Colour : BYTE);ASSEMBLER;
    ASM
        MOV   BX,y
        MOV   ES,SegA000
        ADD   BX,BX
        MOV   DX,$3CE
        MOV   BX,[BX+OFFSET(ScreenOfs)]
        MOV   CX,X
        MOV   AH,Colour
        AND   CX,7
        MOV   AL,0
        OUT   DX,AX
        MOV   AX,$8008
        SHR   AH,CL
        OUT   DX,AX
        MOV   AX,X
        SHR   AX,3
        ADD   BX,AX
        MOV   AL,ES:[BX]
        MOV   ES:[BX],AL
    END;



BEGIN
 ESetRes(15);
 WITH CurrFontBitMap^ DO
  BEGIN
   IF (bk = 255) then                   { Drawing transparent characters? }
    BEGIN
     for Height := 0 TO FontHeightSize-1 DO{Yes -->Set foreground pixels only}
      BEGIN
       {Get bit pattern for one line}
       GetlMask;
       for Width := 0 TO BitmapWidth-1 DO
        BEGIN
         if ((lMask AND MaskVal)= 0) THEN            { Pixel set? }
          BEGIN
           FOR RepHeight := 0 TO FontHeight-1 DO
            BEGIN
             SetScreenBit(x+Width,y+(Height*FontHeight)+RepHeight,fg);
            END;
          END; {BMASK &}
         lMask := lMask shl 1;
        END; {FOR WIDTH}
      END; { FOR HEAIGHT}
    END { BK=255}
   else                           { No --> consider background as well }
    BEGIN
     for Height := 0 to FontHeightSize-1 DO{ Yes --> Set foreground pixels only}
      BEGIN
       GetlMask;
       FOR Width := 0 to BitMapWidth-1 do
        BEGIN
         IF ((lMask AND MaskVal) = 0) then            { Pixel set? }
          BEGIN
           FOR RepHeight := 0 TO FontHeight-1 DO
            BEGIN
             SetScreenBit(x+Width,y+(Height*FontHeight)+RepHeight,fg);
            END
          END {lMASK &}
         ELSE
          BEGIN
           FOR RepHeight := 0 TO FontHeight-1 DO
            BEGIN
             SetScreenBit( x+Width, y+(Height*FontHeight)+RepHeight,bk);
            END
          END; {BMASK &}
         lMask := lMask shl 1;
        END; {FOR WIDTH}
      END; { FOR HEAIGHT}
    END; {ELSE}
  END; {WITH CurrFontBitMap^}
 ClearPorts;
end;

PROCEDURE SetLineStyle(Style : INTEGER);
BEGIN
 DPattern := Style;
 IF Style <> 0 THEN Dithering := TRUE
 ELSE Dithering := FALSE;
END;

PROCEDURE drawline(x1,y1,x2,y2:INTEGER);
VAR dx,dy,incr1,incr2,d,x,y,xinc,yinc,xend,yend : INTEGER;
   Mask1,Mask2 : BYTE;

   FUNCTION GetMask(y : INTEGER) : BYTE;
   BEGIN
    IF (Y MOD 2) = 0 THEN
     GetMask := Mask1 ELSE GetMask := Mask2;
   END;

BEGIN
 if (y1=y2) THEN drawlineHORIZ(x1,x2,y1,1)
 else IF (x1=x2) THEN drawlineVERT(x1,y1,y2,1)
 else
  BEGIN
   IF dithering THEN
    BEGIN
     Mask1 := DitherArray[DPattern,1];
     Mask2 := DitherArray[DPattern,0];
    END
   ELSE
    BEGIN
     Mask1 := $FF;
     Mask2 := $FF;
    END;
   dx := abs(x2-x1);
   dy := abs(y2-y1);
   if (dx>dy) THEN
    BEGIN
     if (x1<x2) THEN
      BEGIN
       x:=x1; y:=y1; xend := x2;
       if (y1>y2) THEN yinc := -1 else yinc := 1;
      END
     ELSE
      BEGIN
       x := x2; y := y2; xend := x1;
       if (y1>y2) THEN yinc := 1 else yinc:= -1;
      END;
     incr1 := 2*dy;d:=incr1-dx;incr2:=d-dx;
     WritePixel(x,y,CurrentColour,GetMask(Y));
     while (x<xend) DO
      BEGIN
       INC(X);
       if(d<0) THEN INC(d,incr1)
       ELSE
        BEGIN
	 INC(d,incr2);INC(y,yinc);
        END;
       WritePixel(x,y,CurrentColour,GetMask(Y));
      END;
    END {dx>dy}
   ELSE
    BEGIN
     if (y1<y2) THEN
      BEGIN
       x:=x1; y:=y1; yend := y2;
       if (x1>x2) THEN xinc := -1 else xinc := 1;
      END
     ELSE
      BEGIN
       x := x2; y := y2; yend := y1;
       if (x1>x2) THEN xinc := 1 else xinc:= -1;
      END;
     incr1 := 2*dx;d:=incr1-dy;incr2:=d-dy;
     WritePixel(x,y,CurrentColour,GetMask(Y));
     while (y<yend) DO
      BEGIN
       INC(Y);
       if(d<0) THEN INC(d,incr1)
       ELSE
        BEGIN
	 INC(d,incr2);INC(x,xinc);
        END;
       WritePixel(x,y,CurrentColour,GetMask(Y));
      END;
    END;
  END;
END;

PROCEDURE DrawRectangle(left,top,right,bottom : INTEGER);
BEGIN
 drawlineHORIZ(left,Right+1,top,1);
 drawlineHORIZ(left,right+1,bottom,1);
 drawlineHORIZ(left,Right+1,top+1,1);
 drawlineHORIZ(left,right+1,bottom-1,1);


 drawlineVERT(left,top+1,bottom,1);
 drawlineVERT(right,top+1,bottom,1);

 drawlineVERT(left+1,top+1,bottom,1);
 drawlineVERT(right-1,top+1,bottom,1);
END;

PROCEDURE DeletelinesHORIZ(x1,x2,y,height:INTEGER);
VAR I : INTEGER;
BEGIN
 IF Height < 0 THEN EXIT;
 ASM
        MOV ES,SegA000
        mov di,y
        add di,di
        mov di,[di+Offset(Screenofs)]
        MOV bx,x1
        shr bx,3
        add di,bx       { di = screenaddr}

        mov dx,$3ce
        Mov ah,BackGround
        Mov al,0
        out dx,ax
        mov ax,$0f01
        out dx,ax

        mov  ax,$FF08
        mov  cx,x1
        and  cl,7
        shr  ah,cl
        out  dx,ax

        mov  cx,height
        lea  si,[di+1]
@Loop2:
        mov  al,es:[di]
        mov  byte ptr es:[di],al
        Add  di,80
        dec  cx
        jnz  @Loop2

        mov di,si

        mov cx,x2
        shr cx,3
        sub cx,bx      {(x1 div 8)+1 to (x2 div 8)-1 }
        dec cx
        mov ax,$ff08
        out dx,ax


        mov  bx,height
        push di
        mov  dx,cx
@Loop1:
        lea  si,[di+80]
        clc
        rcr  cx,1
        jnc  @loop4
        stosb
@loop4:
        rep  stosw
        mov  di,si
        mov  cx,dx
        dec  bx
        jnz  @Loop1

        pop  di
        add  di,dx

        mov  cx,x2
        and  cx,7
        jz   @Exit
        mov  dx,$3ce
        mov  ax,$ff08
        shr  ah,cl
        not  ah
        out  dx,ax
        mov  cx,height
@Loop3:
        mov  al,es:[di]
        mov  byte ptr es:[di],al
        add  di,80
        dec  cx
        jnz  @Loop3
@Exit:
 END;
 ClearPorts;
END;

PROCEDURE ShowCursorATXY(X,Y : INTEGER);
BEGIN
 DrawLineHoriz(X*8,X*8+8,Y*8+CurrFontBitMap^.BitMapHeight-2,1);
 DrawLineHoriz(X*8,X*8+8,Y*8+CurrFontBitMap^.BitMapHeight-1,1);
END;

PROCEDURE DeleteWindow(left,top,right,bottom : INTEGER);
BEGIN
 IF Left < 0 THEN Left := 0;
 IF Top  < 0 THEN Left := 0;
 IF Right > MaxX THEN Right :=MaxX;
 IF Bottom > MaxY THEN Bottom := MaxY;
 DeleteLinesHORIZ(Left,Right,Top,Bottom-Top);
END;

PROCEDURE DrawWindow(left,top,right,bottom : INTEGER;Shadow : BOOLEAN);
VAR I : INTEGER;
    SaveCol : BYTE;
BEGIN
 DrawRectangle(left,top,right,bottom);
 IF Shadow THEN
  BEGIN
  Dithering := TRUE;
  DPattern := 8;
  { SaveCol := CurrentColour;
   SetColour($07);}
   FOR I:=0 TO 1 DO
    BEGIN
     DrawLineHoriz(Left+2+I,Right+3,Bottom+1+I,1);
     DrawLineVERT(Right+1+I,Top+2+I,Bottom+3,1);
    END;
   {SetColour(SaveCol);}
   DPattern := 15;
   Dithering := FALSE;
  END;
END;

PROCEDURE ClrGraphWin;
VAR I,J :LONGINT;
    C   : BYTE;
BEGIN
 C := CurrentColour;
 SetColour(BackGround);
{ for i:=0 TO 799*80 DO SCREENPTR[I] := #0;}
 FillChar(ScreenPtr^,640*80,0);
 SetColour(C);
 ESetRes(0);
 RMask($FF);
 MoveToXy(0,0);
END;

FUNCTION SetBackColour(NewCol : BYTE) : BYTE;
BEGIN
 SetBackColour := Background;
 BackGround    := NewCol;
END;

FUNCTION SetForeColour(NewCol : BYTE) : BYTE;
BEGIN
 SetForeColour := Background;
 CurrentColour := NewCol;
END;


PROCEDURE SetColours(ColourList : TColourList);
VAR I : INTEGER;
    J : INTEGER;
(*
   PROCEDURE SetColour(Col : integer;red,green,blue : byte);assembler;
   asm
       mov ah,$10
       mov al,$10
       mov bx,col
       mov ch,green
       mov cl,blue
       mov dh,red
       int $10
   end;
*)

BEGIN

 ASM
     MOV AH,$10
     MOV Al,$12
     MOV BX,0
     MOV CX,16

     MOV DX,SS
     MOV ES,DX
     LEA DX,ColourList

{     MOV DX,DS
     MOV ES,DX
     LEA DX,Colours }
     INT $10
 END;

(*
 SetColour(0,0,0,0); {STUN MONITOR}
 SetColour(7,90,90,90); {MLC}
 SetColour(56,50,50,50);{ LOGO }
 SetColour(63,255,255,255); { BACKGROUND}
*)

(*
 FOR I := 0 TO 15 DO
  BEGIN
   WITH ColourList[I] DO
    BEGIN
     SetColour(i+16,red,green,blue);
    END;
  END;
*)
 END;
{$R-}
PROCEDURE DisplayBitMap(X,Y : INTEGER;BitMapFileName : STRING;ChangeCols : BOOLEAN);
TYPE PCXHeader = PACKED RECORD
       PCX_Filler  : ARRAY [0..7] OF BYTE;
       PCX_Width   : WORD;
       PCX_Height  : WORD;
       PCX_Filler2 : ARRAY [0..3] OF BYTE;
       PCX_Colours : TColourList;
       PCX_Filler3 : ARRAY [0..63] OF BYTE;
    END;

VAR PosSave,ScreenPos,BitMapHeight,BitMapWidth : INTEGER;
    Row,Column : INTEGER;
    Run        : BOOLEAN;
    J          : INTEGER;
    Plane      : WORD;
    BitMapFile : FILE;
    ArrayIn    : ARRAY[0..4095] OF BYTE;
    ArrayPos   : WORD;
    Header     : PCXHEADER;
    ByteIn     : BYTE;
    RunLen     : WORD;
    XPos       : INTEGER;
    BytesRead  : INTEGER;
    TempScreenPtr : PChar;
    EofPCXFile    : BOOLEAN;
    CheckWid   : INTEGER;


  FUNCTION GetByte : BYTE;
  BEGIN
   GetByte := ArrayIn[ArrayPos];
   INC(ArrayPos);
   IF (ArrayPos >= BytesRead) THEN
    BEGIN
     EofPCXFile := EOF(BitMapFile);
     ArrayPos := 0;
     BlockRead(BitMapFile,ArrayIn,SizeOF(ArrayIn),BytesRead);
    END;
  END;

  PROCEDURE SetPlane;
  BEGIN
   PORTW[SC_INDEX] := plane{*256}+SC_MAP_MASK;
  END;

  PROCEDURE CheckDownLine;
  BEGIN
   IF XPos > CheckWid THEN
    BEGIN
     XPos:=0;
     Plane := Plane SHL 1;
     IF Plane = $1000 THEN
      BEGIN
       INC(TempScreenPtr,80);
       Plane := $0100;
      END;
     SetPlane;
    END;
  END;

  PROCEDURE ByteToScreen(B:BYTE);
  BEGIN
   (TempScreenPtr+XPos)^ := Char(B);
   INC(XPos);
   CheckDownLine;
  END;

  PROCEDURE RunToScreen(B : BYTE;RunLen : BYTE);
  BEGIN
   FillChar((TempScreenPtr+XPos)^,RunLen,B);
   INC(XPos,RunLen);
   CheckDownLine;
  END;

  FUNCTION TranslateColour(Col : BYTE) : BYTE;
  BEGIN
   TranslateColour := (Col SHR 2);
  END;

  PROCEDURE FastRunToScreen(MemAddr : POINTER;XOFS,RunLen : INTEGER;RunVal : BYTE);ASSEMBLER;
  ASM
{      MOV DI,$A000}
      MOV ES,WORD PTR MEMADDR+2
      MOV DI,WORD PTR MEMADDR
      MOV AL,RUNVAL
      ADD DI,XOFS
      MOV CX,RunLen
      MOV AH,AL
      SUB CX,192
      CLC
      RCR CX,1
      JNC @FullRun
      STOSB
  @FullRun :
      REP STOSW
  END;

BEGIN
 FileMode := READ_WRITE+DENY_NONE;
 ScreenPos := Y*80+X DIV 8;
 XPos := 0;
 Plane    := $0100;
 EofPCXFile := FALSE;
 TempScreenPtr := ScreenPtr+ScreenPos;
 SetPlane;
 Assign(BitMapFile,BitMapFileName);
{$I-}
 Reset(BitMapFile,1);
{$I+}
 IF IOResult <> 0 THEN
  BEGIN
   PortW[SC_INDEX] := 15*256+SC_MAP_MASK;
   ESetRes(0);
   RMask($FF);
   EXIT;
  END;
 BlockRead(BitMapFile,Header,SizeOF(Header));
 CheckWid := Header.PCX_Width DIV 8;
 FOR J := 0 TO 15 DO
  BEGIN
   Colours[j].Red   := TranslateColour(Header.PCX_Colours[j].Red);
   Colours[j].Green := TranslateColour(Header.PCX_Colours[j].Green);
   Colours[j].Blue  := TranslateColour(Header.PCX_Colours[j].Blue);
  END;
 IF ChangeCols THEN SetColours(Colours);
 BlockRead(BitMapFile,ArrayIn,SizeOF(ArrayIn),BytesRead);
 ArrayPos := 0;
 WHILE NOT EofPCXFile DO
  BEGIN
    ByteIn := GetByte;
    IF (ByteIn < 193) THEN
     BEGIN
      (TempScreenPtr+XPos)^ := Char(ByteIn);
      INC(XPos);
{      ByteToScreen(ByteIn)}
     END
    ELSE
     BEGIN
{      FillChar((TempScreenPtr+XPos)^,ByteIn-192,(GetByte));}
(*      FastRunToScreen(TempScreenPtr,XPos,ByteIn{-192},(GetByte));
      INC(XPos,ByteIn-192);*)
      RunToScreen(GetByte,ByteIn-192);
     END;
   CheckDownLine;
  END;
 Close(BitMapFile);
 PortW[SC_INDEX] := 15*256+SC_MAP_MASK;
 ESetRes(0);
 RMask($FF);
END;
{$R+}

PROCEDURE ScrollWindowUp(X1,Y1,X2,Y2 : INTEGER;ScrollBy : INTEGER);
BEGIN
  ASM {
      MOV  DX,$3ce
      MOV  AX,$0F01
      OUT  DX,AX
      MOV  AX,$0F08
      OUT  DX,AX
      MOV  DX,$3c4
      MOV  AX,$0F02
      OUT  DX,AX
     }
      PUSH DS
      cld                   { ;Increment on string instructions}

      MOV  AX,SegA000
      MOV  ES,AX     {POINT DS AND ES AT SCREEN}
      MOV  DS,AX

      MOV  CX,X2
      SUB  CX,X1     {CX Now Holds Width in Bytes}
{      SHL  CX,3}


      MOV  DI,Y2
      MOV  BX,Y1
      SUB  DI,BX
      SHL  DI,3
      MOV  BX,DI     {BX Now Holds Height in pixels}
      SUB  BX,ScrollBy


      MOV  AX,80
      MOV  DI,Y1
      SHL  DI,3
      MUL  DI        {AX Now Equals Start Addess}
      MOV  DI,AX
      ADD  DI,X1     {SI = Start Address}


      MOV  AX,80
      MUL  SCROLLBY
      MOV  SI,DI
      ADD  SI,AX     {SI = Start address}

      AND  BX,BX
      JZ   @END1

      mov   ah,15            {;Load plane number as bit mask}

@cm1: mov   al,SC_MAP_MASK   {;Register number to AL}
      mov   dx,SC_INDEX      {;Open access to plane for}
      out   dx,ax            {;processing}
@Loop1:
      PUSH DI
      PUSH SI
      PUSH CX
      REP MOVSB
      POP CX
      POP SI
      POP DI
      ADD SI,80
      ADD DI,80
      DEC BX
      JNZ @Loop1

      MOV  DX,$3ce
      MOV  AX,$0F01
      OUT  DX,AX
      MOV  AX,$FF08
      OUT  DX,AX
      MOV  AX,$0F00
      OUT  DX,AX

      MOV BX,SCROLLBY
      MOV AX,0
@Loop2:
      PUSH DI
      PUSH CX
      REP STOSB
      POP CX
      POP DI
      ADD DI,80
      DEC BX
      JNZ @Loop2
@END1:
      POP DS

  END;
 SetColour(ForeGround);
 ESetRes(0);
 RMask($FF);

END;


FUNCTION LoadFont(FontFileName : STRING;VAR pFont : PFontBitMap) : BOOLEAN;
VAR FontBitMapFile     : FILE;
    FontbitMapFileSize : LONGINT;
BEGIN
 LoadFont := FALSE;
 Assign(FontBitMapFile,FontFileName);
 {$I-}
 Reset(FontBitMapFile,1);
 {$I+}
 IF IOResult <> 0 THEN
  BEGIN
   WriteLn('Unable To Open Font File ',FontFileName);
   pFont := NIL;
   EXIT
  END;
 FontBitMapFileSize := FileSize(FontBitMapFile);
 New(pFont);
 pFont^.FontSize := FontBitMapFileSize;
 GetMem(pFont^.FontPtr,FontBitMapFileSize);
 BlockRead(FontBitMapFile,pFont^.FontPtr^,FontBitMapFileSize);
 Close(FontBitMapFile);
 LoadFont := TRUE;
END;

PROCEDURE DrawArrow(Direction : TArrowDirection;X1,Y1,X2,Y2 : INTEGER);
VAR MidY : INTEGER;
    MidX : INTEGER;
BEGIN
 MidY := (Y1+Y2) DIV 2;
 MidX := (X1+X2) DIV 2;
 CASE Direction OF
 ArrowLeft :
  BEGIN
   DrawLine(X1+4,MidY,  X1+24,Y1+4);   {Cursor Head}
   DrawLine(x1+4,MidY-1,X1+24,Y1+3);
   DrawLine(X1+4,MidY,  X1+24,Y2-4);
   DrawLine(X1+4,MidY+1,X1+24,Y2-3);

   DrawLineVert (X1+24,Midy+8,Y2-4,1);
   DrawLineVert (X1+24+1,Midy+8,y2-3,1);

   DrawLineVert (X1+24,Y1+4,Midy-8,1);
   DrawLineVert (X1+24+1,Y1+3,Midy-8,1);

   DrawLineHoriz(X1+24,X2-4,Midy-8,1);
   DrawLineHoriz(X1+24,X2-4,Midy-8+1,1);

   DrawLineHoriz(X1+24,X2-3,Midy+8,1);
   DrawLineHoriz(X1+24,X2-4,Midy+8-1,1);

   DrawLineVert (X2-4,Midy-8,Midy+8,1);
   DrawLineVert (X2-4+1,Midy-8,Midy+9,1);
  END;
 ArrowRight:
  BEGIN
   DrawLine(X2-4,MidY,  X2-24,Y1+4);
   DrawLine(X2-4,MidY-1,X2-24,Y1+3);

   DrawLine(X2-4,MidY,  X2-24,Y2-4);
   DrawLine(X2-4,MidY+1,X2-24,Y2-3);

   DrawLineVert (X2-24,  Midy+8,Y2-4,1);
   DrawLineVert (X2-24-1,Midy+8,Y2-3,1);

   DrawLineVert (X2-24,  Y1+4,Midy-8,1);
   DrawLineVert (X2-24-1,Y1+4,Midy-8,1);

   DrawLineHoriz(X1+4,X2-24,Midy-8,1);
   DrawLineHoriz(X1+4,X2-24,Midy-8+1,1);

   DrawLineHoriz(X1+4,X2-24,Midy+8,1);
   DrawLineHoriz(X1+4,X2-24,Midy+8-1,1);

   DrawLineVert (X1+4,Midy-8,Midy+8,1);
   DrawLineVert (X1+4+1,Midy-8,Midy+8+1,1);
  END;
 ArrowDown:
  BEGIN
   DrawLine(MidX,Y2-4,X1+4,Y2-24);
   DrawLine(MidX-1,Y2-4,X1+3,Y2-24);

   DrawLine(MidX,Y2-4,X2-4,Y2-24);
   DrawLine(MidX+1,Y2-4,X2-3,Y2-24);

   DrawLineHoriz(MidX+8,X2-4,Y2-24,1);
   DrawLineHoriz (MidX+8,X2-3,Y2-24-1,1);

   DrawLineHoriz (X1+4,MidX-8,Y2-24,1);
   DrawLineHoriz (X1+4,MidX-8,Y2-24-1,1);

   DrawLineVert(MidX-8,Y1+4,Y2-24,1);
   DrawLineVert(MidX-8+1,Y1+4,Y2-24,1);

   DrawLineVert(MidX+8,Y1+4,Y2-24,1);
   DrawLineVert(MidX+8-1,Y1+4,Y2-24,1);

   DrawLineHoriz(MidX-8,MidX+8,Y1+4,1);
   DrawLineHoriz(MIDX-8,MidX+8+1,Y1+4+1,1);
  END;
 ArrowUp :
  BEGIN
   DrawLine(MidX,  Y1+4,X1+4,Y1+24);   {Cursor Head}
   DrawLine(MidX-1,Y1+4,X1+3,Y1+24);
   DrawLine(MidX,  Y1+4,X2-4,Y1+24);
   DrawLine(MidX+1,Y1+4,X2-3,Y1+24);

   DrawLineHoriz(MidX+8,X2-4,Y1+24,1);
   DrawLineHoriz(MidX+8,X2-3,Y1+24+1,1);

   DrawLineHoriz(X1+4,MidX-8,Y1+24,1);
   DrawLineHoriz(X1+3,MidX-8,Y1+24+1,1);

   DrawLineVert (MidX-8,  Y1+24,Y2-4,1);
   DrawLineVert (MidX-8+1,Y1+24,Y2-4,1);

   DrawLineVert (MidX+8,  Y1+24,Y2-3,1);
   DrawLineVert (MidX+8-1,Y1+24,Y2-4,1);

   DrawLineHoriz(Midx-8,Midx+8,y2-4,1);
   DrawLineHoriz(Midx-8,Midx+9,y2-4+1,1);
  END;
 END;{CASE}
END;


PROCEDURE GraphDone;
BEGIN
 DefaultFont := NIL;
 IF Font8x8  <> NIL THEN DeleteFont(Font8x8);  Font8x8 := NIL;
 IF Font8x16 <> NIL THEN DeleteFont(Font8x16); Font8x16:= NIL;
 IF FP_Font8x8  <> NIL THEN
  BEGIN
   FreeMem(FP_Font8x8^.FontPtr,FP_Font8x8^.FontSize);
   Dispose(FP_Font8x8);
   FP_Font8x8 := NIL;
  END;
  IF FP_Font8x16 <> NIL THEN
   BEGIN
    FreeMem(FP_Font8x16^.FontPtr,FP_Font8x16^.FontSize);
    Dispose(FP_Font8x16);
    FP_Font8x16 := NIL;
   END;
 CloseGraphMode;
END;


PROCEDURE GetDefaultColours;
VAR Regs : Registers;
    Loop : INTEGER;
BEGIN
 FOR Loop := 0 TO 15 DO
  BEGIN
   Regs.AH := $10;
   Regs.AL := $15;
   Regs.BL := Loop;
   Intr($10,Regs);
   DefaultColours[Loop].Red   := Regs.DH;
   DefaultColours[Loop].Green := Regs.CH;
   DefaultColours[Loop].Blue  := Regs.CL;
  END;
END;

PROCEDURE ColourInit;
BEGIN
 ASM
     MOV AX,$1013
     MOV BX,$0100
     INT $10
     MOV AX,$1013
     MOV BX,0001
     INT $10
 END;
END;


PROCEDURE SetDefaultPallete(Contrast : BYTE;GreyScale : BOOLEAN);
CONST HB = $C0;
      FB = $FF;

PROCEDURE SetPallet(Colour,r,g,b : BYTE);
VAR RW,GW,BW : WORD;
    Grey     : WORD;
BEGIN
 RW := (R * Contrast) DIV 32;
 GW := (G * Contrast) DIV 32;
 BW := (B * Contrast) DIV 32;
 IF RW > 255 THEN RW := 255;
 IF GW > 255 THEN GW := 255;
 IF BW > 255 THEN BW := 255;

 IF GreyScale THEN
  BEGIN
   Grey := (BW+(2*RW)+(4*GW)) DIV 7;
   RW := Grey;
   GW := Grey;
   BW := Grey;
  END;



 Colours[Colour].Red   := (RW SHR 2);
 Colours[Colour].Green := (GW SHR 2);
 Colours[Colour].Blue  := (BW SHR 2);
END;


VAR J : BYTE;
BEGIN
 SetPallet(0  ,$00,$00,$00);  {Black     }
 SetPallet(1  , HB,$00,$00);  {Dk Red    }
 SetPallet(2  ,$00, HB,$00);  {Dk Green  }
 SetPallet(3  , HB, HB,$00);  {Dk Yellow }
 SetPallet(4  ,$00,$00, HB);  {Dk Blue   }
 SetPallet(5  , HB,$00, HB);  {Dk Magenta}
 SetPallet(6  ,$00, HB, HB);  {Dk Cyan   }
 SetPallet(7  , HB, HB, HB);  {Grey      }
 SetPallet(8  ,$CC,$E5, FB);  {Pale Blue }
 SetPallet(9  , FB,$00,$00);  {Red       }
 SetPallet(10 ,$00, FB,$00);  {Green     }
 SetPallet(11 , FB, FB,$00);  {Yellow    }
 SetPallet(12 ,$00,$00, FB);  {Blue      }
 SetPallet(13 , FB,$00, FB);  {Magenta   }
 SetPallet(14 ,$00, FB, FB);  {Cyan      }
 SetPallet(15 , FB, FB, FB);  {White     }

 SetColours(Colours);
END;



FUNCTION GraphInit:BOOLEAN;
VAR I,J : INTEGER;
BEGIN
 GraphInit := FALSE;
 IF NOT LoadFont('Font8x8.SFB', FP_Font8x8)   THEN EXIT;
 IF NOT LoadFont('Font8x16.SFB',FP_Font8x16)  THEN EXIT;
 IF NOT SetGraphicsMode THEN
  BEGIN
   WriteLn('Unable to set graphics mode 640x480 16 colour');
   EXIT;
  END;
 GetDefaultColours;
 SCREENPTR:=Ptr(SegA000,0000);
 ClrGraphwin;
 Dithering       := FALSE;
 DPattern        := 15;
 CurrentColour   := ForeGround;
 Font8x8 := CreateFont(1,1,HORIZ,FONT_8X8,FontNormal);
 Font8x16:= CreateFont(1,1,HORIZ,FONT_8X16,FontNormal);
 DefaultFont := Font8x16;
 SetCurrentFont(DefaultFont);
 ColourInit;
 SetRes(BackGround);
 ESetRes(0);
 Rmask($FF);
 GraphInit := TRUE;
 Shadowing := TRUE;
END;

END.


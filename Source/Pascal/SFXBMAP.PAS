{$I F6COMP}
UNIT SFXBMAP;

INTERFACE

USES SFXGRAPH;

(*
TYPE RGBColour = PACKED RECORD
       Red   : BYTE;
       Green : BYTE;
       Blue  : BYTE;
     END;

     TColourList = ARRAY[0..15] OF RGBColour;
*)
TYPE PCXHeader = PACKED RECORD
      PCX_Manufacturer : BYTE;{ Always 10 for PCX file     }
      PCX_Version      : BYTE;{ 2 - old PCX - no palette (NOT used anymore),}
                              { 3 - no palette,                             }
       			      { 4 - Microsoft Windows - no palette (only in }
			      { old files, New Windows version USES 3),     }
			      { 5 - WITH palette                            }
      PCX_Encoding     : BYTE;{ 1 - PCX other future possibilities          }
      PCX_BitsPerPixel : BYTE;{ Number of bits to represent a pixel         }
      PCX_XMIN         : WORD;{ Image Window Dimensions (inclusive)         }
      PCX_YMIN         : WORD;{ XMin, YMin are usually zero (not always)    }
      PCX_XMax         : WORD;{ Width }
      PCX_YMax         : WORD;{ Height}
      PCX_Hdpi         : WORD;{ Resolution of image (dots per inch)         }
      PCX_Vdpi         : WORD;{ Set to scanner resolution - 300 is default  }
      PCX_Colours      : TColourList; { RGB palette data (16 colors or less)}
                              { 256 color pallet is appended to END OF FILE }
      PCX_Reserved     : BYTE;{ (used to contain video mode)                }
                              { now it is ignored - just set to 0           }
      PCX_ColourPlanes : BYTE;{ Number of planes                            }
      PCX_BytesPerLine : BYTE;{ Number of Bytes to allocate for a scan line }
                              { Plane (MUST be an EVEN number!)             }
      PCX_PalletType   : WORD;{ 1 = Black & White or color image            }
                              { 2 = Greyscale image                         }
                              { palette must also be set to shades of grey! }
      PCX_HscreenSize  : INTEGER; {Not reliable }
      PCX_VscreenSize  : INTEGER; {Not reliable }
      PCX_Filler       : ARRAY [74..127] OF BYTE;
    END;




TYPE PPCXBitMap = ^TPCXBitMap;
     TPCXBitmap = OBJECT
       FileName : STRING;
       FHandle  : FILE;
       DataLen  : WORD;
       Header   : PCXHeader;
       Data     : Pointer;



       X             : WORD;            { SCREEN RENDER POSITION }
       Y             : WORD;
       ChangePalette : BOOLEAN;


       CONSTRUCTOR Init(FName : STRING; UsePalette : BOOLEAN; PreLoad : BOOLEAN);
       DESTRUCTOR  Done;

       PROCEDURE SetXY(XP,YP : WORD);
       PROCEDURE DrawAt(XP,YP : WORD);
       PROCEDURE Draw;

       PRIVATE

       PROCEDURE AllocateMem;
       PROCEDURE DisposeMem;

       PROCEDURE ReadBitMapData;
      END;




IMPLEMENTATION

CONSTRUCTOR TPCXBitMap.Init(FName : STRING; UsePalette : BOOLEAN; PreLoad : BOOLEAN);
VAR OpenErr : INTEGER;
    IOErr   : INTEGER;
BEGIN
 FileName := FName;
 Assign(FHandle,FileName);
{$I-}
 Reset(FHandle,1);
{$I+}
OpenErr := IOResult;
{$I-}
 DataLen := FileSize(FHandle);
{$I+}
 IOErr := IOResult;
 IF DataLen > SizeOF(PCXHeader) THEN
   DEC(DataLen,SizeOF(PCXHeader));
 Data  := NIL;
 ChangePalette := UsePalette;
 {$I-}
 Close(FHandle);
 {$I+}
 IOErr := IOResult;
 IF Preload THEN ReadBitmapData;
END;


DESTRUCTOR TPCXBitmap.Done;
BEGIN
  DisposeMem
END;

PROCEDURE TPCXBitMap.AllocateMem;
BEGIN
 GetMem(Data,DataLen);
END;

PROCEDURE TPCXBitMap.DisposeMem;
BEGIN
 IF Assigned(Data) THEN
  BEGIN
   Freemem(Data,DataLen);
   Data := NIL
  END;
END;

PROCEDURE TPCXBitMap.ReadBitMapData;
VAR IOError    : INTEGER;
    C          : BYTE;

  FUNCTION TranslateColour(Col : BYTE) : BYTE;
  BEGIN
   TranslateColour := (Col SHR 2);
  END;

BEGIN
{$I-}
 Reset(FHandle,1);
{$I+}
 IF IOResult <> 0 THEN EXIT;
 {$I-}
 BlockRead(FHandle,Header,SizeOF(Header));
 {$I+}

 FOR C := 0 TO 15 DO
  BEGIN
   WITH Header.PCX_Colours[C] DO
    BEGIN
     Red   := (RED SHR 2);
     Green := (RED SHR 2);
     Blue  := (RED SHR 2);
    END
  END;

 IF (DataLen > 0) THEN
  BEGIN
   AllocateMem;
   IF Assigned(Data) THEN
    BEGIN
     {$I-}
     BlockRead(FHandle,Data^,DataLen);
     {$I+}
     IF IOResult <> 0 THEN DisposeMem;
    END;
  END;
 {$I-}
 Close(FHandle);
 {$I+}
 IOError := IOResult;
END;


PROCEDURE TPCXBitmap.SetXY(XP,YP : WORD);
BEGIN
 X := XP;
 Y := YP;
END;

PROCEDURE TPCXBitmap.Draw;
BEGIN
  DrawAt(X,Y);
END;



PROCEDURE TPCXBitmap.DrawAt(XP,YP : WORD);
VAR XPOS          : WORD;
    YPOS          : WORD;
    BITSHIFT      : BYTE;
    Plane         : WORD;
    ScreenPos     : WORD;
    TempScreenPtr : PChar;
    TempDataPtr   : PChar;
    DataPos       : WORD;
    ByteIN        : WORD;
    PrevBytr      : Byte;
    PrevMask      : Byte;


  FUNCTION GetByte : BYTE;
  BEGIN
   INC(DataPos);
   INC(TempDataPtr);
   GetByte := BYTE(TempDataPtr^);
  END;

  PROCEDURE SetPlane;
  BEGIN
   PORTW[SC_INDEX] := plane{*256}+SC_MAP_MASK;
  END;


  PROCEDURE CheckDownLine;
  BEGIN
   IF XPos > (Header.PCX_XMax DIV 8) THEN
    BEGIN
     XPos:=0;
     Plane := Plane SHL 1;
     IF Plane = $1000 THEN
      BEGIN
       INC(TempScreenPtr,80);
       Plane := $0100;
       INC(YPos)
      END;
     SetPlane;
    END;
  END;

  PROCEDURE ByteToScreen(B:BYTE);
  VAR Mask1 : BYTE;
      Dummy : CHAR;
  BEGIN
   Dummy := (TempScreenPtr+XPos)^;                   { READ BYTE INTO LATCH }

   Mask1 := $FF SHR BitShift;                        { SET BITMASK }
   PortW[$3ce] := Mask1 shl 8+8;
   (TempScreenPtr+XPos)^   := CHAR( B SHR Bitshift); { WRITE DATA }

   Dummy := (TempScreenPtr+(XPos+1))^;                   { READ BYTE INTO LATCH }
   Mask1 := NOT Mask1;
   PortW[$3ce] := Mask1 shl 8+8;
   (TempScreenPtr+(XPos+1))^  :=   CHAR( B SHL (8 - Bitshift));
   CheckDownLine;
   INC(XPos);
  END;

  PROCEDURE RunToScreen(B : BYTE;RunLen : BYTE);
  BEGIN
   WHILE (RunLen > 0) DO
    BEGIN
     ByteToScreen(B);
     DEC(RunLen);
    END
   {
   FillChar((TempScreenPtr+XPos)^,RunLen,B);
   INC(XPos,RunLen);
   CheckDownLine;
  }
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
 IF NOT Assigned(Data) THEN ReadBitMapData;


 ScreenPos := YP*80+XP DIV 8;
 BitShift  := XP MOD 8;


 XPos := 0;
 Ypos := 0;
 Plane    := $0100;
 TempScreenPtr := ScreenPtr+ScreenPos;
 SetPlane;

 IF ChangePalette THEN SetColours(Header.PCX_Colours);

 DataPos  := 0;
 TempDataPtr := PCHAR(Data);
 WHILE(DataPos < DataLen) DO
  BEGIN
   IF YPos < Header.PCX_YMax THEN
    BEGIN
     ByteIn := GetByte;
     IF (ByteIn < 193) THEN
      BEGIN
       ByteToScreen(ByteIn)
      END
     ELSE
      BEGIN
{      FillChar((TempScreenPtr+XPos)^,ByteIn-192,(GetByte));}
(*      FastRunToScreen(TempScreenPtr,XPos,ByteIn{-192},(GetByte));
      INC(XPos,ByteIn-192);*)
       RunToScreen(GetByte,ByteIn-192);
      END;
     CheckDownLine;
    END
   ELSE DataPos := DataLen+1;
  END;
 PortW[SC_INDEX] := 15*256+SC_MAP_MASK;
 PortW[$3ce]:=1;{ ESetRes(0); }
 PortW[$3ce] := $FF shl 8+8; { RMask($FF); }
END;


END.

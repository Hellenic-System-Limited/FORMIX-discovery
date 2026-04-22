(****************************************************************************
*  UNIT          : SFXEltrn                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 15/09/97                                                 *
*  PURPOSE       : Eltron Thermal Printer Stuff                             *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXEltrn;
INTERFACE
USES Crt,F6StdCtv,F6StdUtl,SFXPorts,FXFIni,F6StdWn1,SFXGraph;

TYPE TBarCodeTypes = (Code128BC0,Code128BC1,Int2Of5,Code39_Ext,Code93,
                      CodaBar,UPC,EAN,PostNet);

TYPE TCharSets = (US_ASCII,British,German,French,Italian,Danish,Spanish,Swedish,Swiss);


{Control Commands}
FUNCTION BackUpLabel(N : INTEGER) : STRING;
FUNCTION BarCodeType(BarType : TBarCodeTypes) : STRING;
FUNCTION BarCodeWidth(n : INTEGER) : STRING;
FUNCTION BufferStart : STRING;
FUNCTION SetCountryCodeCharSet(CharSet : TCharSets) : STRING;
FUNCTION DisableAutomaticBackup : STRING;
FUNCTION DisableAutomaticFormFeed : STRING;
FUNCTION FormFeedLength(n : INTEGER) : STRING;
FUNCTION ExtraFeed(n : INTEGER) : STRING;
FUNCTION LeftMargin(n : INTEGER) : STRING;
FUNCTION BarRatio(n,w : INTEGER) : STRING;
FUNCTION Contrast(n : INTEGER) : STRING;
FUNCTION PrintSpeed(n  : INTEGER) : STRING;
FUNCTION Top_Of_Form_Calibrated : STRING;
FUNCTION Top_Of_Form(n : INTEGER) : STRING;
{Label Formating Commands}
FUNCTION PrintBarCode(Data : STRING;Readables : BOOLEAN) : STRING;
FUNCTION BufferEnd : STRING;
FUNCTION PrintQuantity(n : INTEGER) : STRING;
FUNCTION RepeatPrint : STRING;
FUNCTION ReversePrint(On : BOOLEAN) : STRING;
FUNCTION CharacterSize(h,v : INTEGER) : STRING;



IMPLEMENTATION


FUNCTION BackUpLabel(N : INTEGER) : STRING;
BEGIN
 IF (N > 25) THEN N := 25 ELSE
 IF (N < 01) THEN N := 1;

 BackUpLabel := ESC+'R'+IntToZeroStr(N,2);
END;

FUNCTION BarCodeType(BarType : TBarCodeTypes) : STRING;
VAR Suffix : CHAR;
BEGIN
 Case BarType OF
  Code128BC0  : Suffix := '0';
  Code128BC1  : Suffix := '1';
  Int2Of5     : Suffix := '2';
  Code39_Ext  : Suffix := '3';
  Code93      : Suffix := '9';
  CodaBar     : Suffix := 'K';
  UPC         : Suffix := 'U';
  EAN         : Suffix := 'E';
  PostNet     : Suffix := 'P';
  ELSE Suffix := '0';
 END;

 BarCodeType := ESC+'?'+Suffix;
END;

FUNCTION BarCodeWidth(n : INTEGER) : STRING;
BEGIN
 IF (N > 4) THEN N := 4
 ELSE IF (N < 2) THEN N := 2;
 BarCodeWidth := ESC+'X'+IntToStr(N,1);
END;

FUNCTION BufferStart : STRING;
BEGIN
 BufferStart := ESC+'B'
END;

FUNCTION SetCountryCodeCharSet(CharSet : TCharSets) : STRING;
VAR Suffix : CHAR;
BEGIN
 CASE CharSet OF
  US_ASCII : Suffix := '0';
  British  : Suffix := '1';
  German   : Suffix := '2';
  French   : Suffix := '3';
  Italian  : Suffix := '4';
  Danish   : Suffix := '5';
  Spanish  : Suffix := '6';
  Swedish  : Suffix := '7';
  Swiss    : Suffix := '8';
  ELSE Suffix := '0';
 END;
 SetCountryCodeCharSet := ESC+'l'+Suffix;
END;

FUNCTION DisableAutomaticBackup : STRING;
BEGIN
 DisableAutomaticBackup := ESC+'ROO';
END;

FUNCTION DisableAutomaticFormFeed : STRING;
BEGIN
 DisableAutomaticFormFeed := ESC+'N';
END;

FUNCTION FormFeedLength(n : INTEGER) : STRING;
BEGIN
 IF (N < 1) THEN N := 1
 ELSE IF (N >25) THEN N := 25;

 FormFeedLength := ESC+'N'+IntToZeroStr(N,2);
END;

FUNCTION ExtraFeed(n : INTEGER) : STRING;
BEGIN
 IF (N<0) THEN N := 0
 ELSE IF (N > 7) THEN N := 7;

 ExtraFeed := ESC+'O'+IntToStr(N,1);
END;

FUNCTION LeftMargin(n : INTEGER) : STRING;
BEGIN
 IF (N < 0) THEN N := 0
 ELSE IF (N>99) THEN N := 99;

 LeftMargin := ESC+'M'+IntToZeroStr(N,2);
END;

FUNCTION BarRatio(n,w : INTEGER) : STRING;
BEGIN
 IF (n < 2) THEN n := 2
 ELSE IF (n > 4) THEN n := 4;

 IF (w < 4) THEN w := 4
 ELSE IF (w > 12) THEN w := 12;

 BarRatio := ESC+'x'+IntToStr(n,1)+IntToZeroStr(w,2);
END;

FUNCTION Contrast(n : INTEGER) : STRING;
BEGIN
 IF (n < 0) THEN n := 0
 ELSE IF (n > 7) THEN n := 7;

 Contrast := ESC+'D'+IntToStr(n,1);
END;

FUNCTION PrintSpeed(n  : INTEGER) : STRING;
BEGIN
 IF (n < 0) THEN n := 0
 ELSE IF (n > 2) THEN n := 2;

 PrintSpeed := ESC+'S'+IntToStr(n,1);
END;

FUNCTION Top_Of_Form_Calibrated : STRING;
BEGIN
 Top_Of_Form_Calibrated := ESC+'Q?';
END;

FUNCTION Top_Of_Form(n : INTEGER) : STRING;
VAR Suffix : STRING[3];
BEGIN
 Top_Of_Form := '';
 IF (n < 6) THEN n := 6
 ELSE IF (n > 51) THEN EXIT;

 CASE n OF
  006 : Suffix := '032';
  007 : Suffix := '024';
  008 : Suffix := '032';
  009 : Suffix := '056';
  010 : Suffix := '016';
  011 : Suffix := '064';
  012 : Suffix := '032';
  013 : Suffix := '104';
  014 : Suffix := '080';
  015 : Suffix := '056';
  016 : Suffix := '032';
  017 : Suffix := '008';
  018 : Suffix := '128';
  019 : Suffix := '112';
  020 : Suffix := '096';
  021 : Suffix := '080';
  022 : Suffix := '064';
  023 : Suffix := '048';
  024 : Suffix := '032';
  025 : Suffix := '016';
 ELSE Suffix := IntToZeroStr((52-n)*8,3);
 END;
 Top_Of_Form := ESC+'Q'+Suffix;
END;

{Label Formating Commands}
FUNCTION PrintBarCode(Data : STRING;Readables : BOOLEAN) : STRING;
VAR FormatStr : CHAR;
BEGIN
 IF (Readables) THEN FormatStr := '{'
 ELSE FormatStr := '|';

 PrintBarCode := ESC + FormatStr+Data+'}';
END;

FUNCTION BufferEnd : STRING;
BEGIN
 BufferEnd := ESC+'E';
END;

FUNCTION PrintQuantity(n : INTEGER) : STRING;
VAR ControlCode : CHAR;
BEGIN
 ControlCode := 'P';
 IF (N < 1) THEN N := 1
 ELSE
  IF (N > 99) THEN
   BEGIN
    IF (N > 999) THEN N := 999;
    ControlCode := 'p';
   END;

 PrintQuantity := ESC+ControlCode+IntToZeroStr(n,2);
END;

FUNCTION RepeatPrint : STRING;
BEGIN
 RepeatPrint := ESC+'POO';
END;

FUNCTION ReversePrint(On : BOOLEAN) : STRING;
BEGIN
 IF (On) THEN ReversePrint := ESC+'V'
 ELSE ReversePrint := ESC+'v';
END;

FUNCTION CharacterSize(h,v : INTEGER) : STRING;
BEGIN
 IF (h < 1) THEN h := 1
 ELSE IF (h > 4) THEN h := 4;

 IF (v<1) THEN v := 1
 ELSE IF (v > 7) THEN v := 7;

 CharacterSize := ESC+'A'+IntToStr(h,1)+IntToStr(V,1);
END;

END.
PROGRAM FDLConvert;
{INTERFACE}
USES F6StdUtl;
CONST BarcodeTypeIds : ARRAY [0..9] OF String =
                       ('INT2OF5',
                        'CODE39',
                        'CODE128',
                        'CODE128',
                        'EAN13',
                        'EAN13',
                        'EAN8',
                        'EAN8',
                        'CODABAR',
                        'CODE11');

      FontTypeIds : ARRAY [0..7] OF String =
                    ('SW020BSN',
                     'SW030RSN',
                     'Swiss 721 Bold BT',
                     'SW060BSN',
                     'Swiss 721 Bold BT',
                     'Monospace 821 Bold BT',
                     'MS030RMN',
                     'Monospace 821 Bold BT');

      LabelFormat : ARRAY [0..25] OF CHAR =
                    ('A','B','C','D','E','F','G','H','I','J','K','L','M',
                     'N','O','P','Q','R','S','T','U','V','W','X','Y','Z');
{IMPLEMENTATION}

VAR FDLName,
    LDFName : Text;
    WrkFName : String;
    i, j : Integer;
    {Reading and writing strings}
    WrkStr : String;
    NewStr : String;
    {Var Numbers for end of lines}
    VarNum : Integer;
    WrkVar : String;
    {These Vars are used to check previous values}
    Hold_Inverse : Integer;
    Hold_PPX,
    Hold_PPY,
    Hold_Dir,
    Hold_AN,
    Hold_MagX,
    Hold_MagY,
    Hold_NI,
    Hold_Font,
    Hold_Inv,
    Hold_Align : String;
    {Used in stripping leading zeros out of text}
    WrkWidth,
    WrkThick,
    WrkHeight,
    BoxWidth,
    BoxHeight : String;

    WrkDir,          {Used for calculating Direction of an image}
    Inverse,         {Used for calculating Inverse variable}
    Align : Integer; {Used for calculating Align variable}

    Added : Boolean;   {Used To Check If label format has been added}


        PROCEDURE Set_Inverse(InvChr : Char);
        {Sorts out Inverse & Align values from single charater}
        BEGIN
         IF (InvChr = 'I') OR (InvChr = 'N') THEN
          BEGIN
           Inverse := ORD(InvChr = 'I');
           Align := 1;
          END
         ELSE
           IF (InvChr >= 'A') THEN
            BEGIN
             Inverse := 1;
             Align := ORD(InvChr) - ORD('A') + ORD('1');
            END
           ELSE
            BEGIN
             Inverse := 0;
             Align := ORD(InvChr) - ORD('0');
            END;
        END;

        PROCEDURE ResetHoldKeys;
        {Resets all hold keys}
        BEGIN
         Hold_PPX := '';
         Hold_PPY := '';
         Hold_Dir := '';
         Hold_AN  := '';
         Hold_MagX:= '';
         Hold_MagY:= '';
         Hold_NI  := '';
         Hold_Font:= '';
         Hold_Inv := '';
         Hold_Inverse := 100;
         Hold_Align   := '';
        END;

        PROCEDURE CheckPosition(XPos,YPos : String);
        {Checks Position is different, if so adds it}
        BEGIN
         IF (NOT Str_Equal(Hold_PPX,XPos,4)) OR
            (NOT Str_Equal(Hold_PPY,YPos,4)) THEN
          BEGIN
           Hold_PPX := XPos;
           Hold_PPY := YPos;
           NewStr := NewStr + Strip_Leading_Char(Hold_PPX,4,'0')+','+
                              Strip_Leading_Char(Hold_PPY,4,'0')+':';
          END;
        END;

        PROCEDURE CheckDirection(NewDir : String);
        {Checks Direction is different, if so adds it}
        BEGIN
         IF Hold_Dir <> NewDir THEN
          BEGIN
           Hold_Dir := NewDir;
           NewStr := NewStr + 'DIR'+ Hold_Dir + ':'
          END;
        END;

        PROCEDURE CheckAlign(AlignNum : Integer);
        {Checks Align is different to last added, if so adds it}
        VAR WrkAlign : String;
        BEGIN
         IF AlignNum > 9 THEN WrkAlign := Chr(AlignNum)
                         ELSE WrkAlign := IntToStr(AlignNum,1);
         IF Hold_Align <> WrkAlign THEN
          BEGIN
           Hold_Align := WrkAlign;
           NewStr := NewStr + 'AN' + WrkAlign + ':';
          END;
        END;

        PROCEDURE CheckMag(MagX, MagY : String);
        {Checks Magnification is different to last added, if so adds it}
        BEGIN
         IF (Hold_MagX <> MagX) OR (Hold_MagY <> MagY) THEN
          BEGIN
           Hold_MagX := MagX;
           Hold_MagY := MagY;
           NewStr := NewStr + 'MAG' + Hold_MagY + ',' + Hold_MagX +':';
          END;
        END;

        PROCEDURE CheckInverse(Inverse : Integer);
        {Checks Inverse is different to last added, if so adds it}
        BEGIN
         IF Inverse <> Hold_Inverse THEN
          BEGIN
           Hold_Inverse := Inverse;
           IF (Inverse = 1) THEN NewStr := NewStr + 'II:'
                            ELSE NewStr := NewStr + 'NI:';
          END;
        END;

        PROCEDURE CheckFonts(FontNum : Char);
        {Checks font is different to last one added to file, if so adds it to
         line in file, otherwise doesn't add it.}
        BEGIN
         IF Hold_Font <> FontNum THEN
          BEGIN
           Hold_Font := FontNum;
           NewStr := NewStr + 'FT"' + FontTypeIds[StringToLong(Hold_Font)];
           {need these added for true types only}
           CASE StringToLong(Hold_Font) OF
            2 : NewStr := NewStr + '",15';
            4 : NewStr := NewStr + '",47';
            5 : NewStr := NewStr + '",72';
            7 : NewStr := NewStr + '",16';
           ELSE NewStr := NewStr + '"';
           END;
           NewStr := NewStr + ':';
          END;
        END;

        PROCEDURE AddVar;
        {Adds Var number to end of line}
        BEGIN
         WrkVar := IntToZeroStr(VarNum,2);
         NewStr := NewStr + 'PT VAR'+Strip_Leading_Char(WrkVar,2,'0')+'$';
         INC(VarNum);
        END;

BEGIN
 {FDL file name got from command line i.e."FDLConv STD21.FDL" gives
  Std21.FDL as file name}
 WrkFName := ParamStr(1);
 {Check To See if File name has been added, and that file exists}
 IF WrkFName <> '' THEN
 IF Exist(WrkFName) THEN
  BEGIN
   Assign(FDLName,WrkFName);
   FOR i := 1 TO Length(WrkFName) DO
    IF WrkFName[i] = '.' THEN
     BEGIN
      WrkFName := Copy(WrkFName,1,i) + 'LDF';
      Break;
     END;
   Assign(LDFName,WrkFName);
   Reset(FDLName);
   ReWrite(LDFName);
   j := 0;
   VarNum := 1;
   Added := FALSE;
   WHILE j <= 25 DO
   BEGIN
    {Find label format by going through the alphabet}
    ReadLn(FDLName,WrkStr);
    IF (WrkStr[1] = '$') AND
       (Str_Equal(Copy(WrkStr,1,4),'$LF'+LabelFormat[j],4)) THEN
     BEGIN
      {OK found the next label format, so write label input line to
        LDF file then get first line of data}
      VarNum := 1;
      ResetHoldKeys;
      WriteLn(LDFName,'KILL"LF'+LabelFormat[j]+'"');
      Added := TRUE;
      WriteLn(LDFName,'LAYOUT INPUT"LF'+LabelFormat[j]+'"');
      WriteLn(LDFName,'NASC44');
      ReadLn(FDLName,WrkStr);
      WHILE WrkStr[1] <> '$' DO
       BEGIN
        NewStr := 'PP';

        IF WrkStr[2] = 'L' THEN
         BEGIN
          {Its a Line}
          CheckPosition(Copy(WrkStr,7,4),Copy(WrkStr,3,4));
          CheckDirection(WrkStr[20]);
          Set_Inverse(WrkStr[19]);
          CheckAlign(Align);
          WrkWidth := Copy(WrkStr,11,4);
          WrkThick := Copy(WrkStr,15,4);
          NewStr := NewStr + 'PL' + Strip_Leading_Char(WrkWidth,4,'0') +
                    ',' + Strip_Leading_Char(WrkThick,4,'0');
          WriteLn(LDFName,NewStr);
          NewStr := '';
         END;

        IF WrkStr[2] = 'X' THEN
         BEGIN
          {Its A Box}
          CheckPosition(Copy(WrkStr,11,4),Copy(WrkStr,7,4));
          CheckDirection(WrkStr[23]);
          WrkThick := Copy(WrkStr,3,4);
          BoxHeight:= Copy(WrkStr,15,4);
          BoxWidth := CopY(WrkStr,19,4);

          NewStr := NewStr + 'PX' + Strip_Leading_Char(BoxHeight,4,'0') +
                    ',' + Strip_Leading_Char(BoxWidth,4,'0')+','+
                    Strip_Leading_Char(WrkThick,4,'0');
          WriteLn(LDFName,NewStr);
          NewStr := '';
         END;

        IF WrkStr[2] = 'T' THEN
         BEGIN
          {This does most of the items}
          CheckPosition(Copy(WrkStr,10,4),Copy(Wrkstr,6,4));
          CheckDirection(WrkStr[15]);
          Set_Inverse(WrkStr[14]);
          CheckAlign(Align);
          CheckMag(WrkStr[5],WrkStr[4]);
          CheckInverse(Inverse);
          CheckFonts(WrkStr[3]);
          AddVar;
          WriteLn(LDFName,NewStr);
          NewStr := '';
         END;

        IF WrkStr[2] = 'I' THEN
         BEGIN
          {This does Images}
          CheckPosition(Copy(WrkStr,10,4),Copy(WrkStr,6,4));
          IF WrkStr[5] = '1' THEN
           BEGIN
            WrkDir := 1;
            Align := 1;
           END
          ELSE
           BEGIN
            WrkDir := 4;
            Align := 7;
           END;
          CheckDirection(IntToStr(WrkDir,1));
          CheckAlign(Align);
          Set_Inverse(WrkStr[14]);
          CheckInverse(Inverse);
          NewStr := NewStr + 'PM"' + Copy(WrkStr,15,Length(WrkStr)-14)
                    +'.'+WrkStr[5]+'"';
          WriteLn(LDFName,NewStr);
          NewStr := '';
         END;

        IF (WrkStr[1] = 'B') THEN
         BEGIN
          {Means its a barcode}
          CheckPosition(Copy(WrkStr,13,4),Copy(WrkStr,9,4));
          CheckDirection(WrkStr[5]);
          Set_Inverse(WrkStr[14]);
          WrkHeight := Copy(WrkStr,17,4);
          NewStr  := NewStr+'BARSET"'+
                     BarCodeTypeIds[StringToLong(WrkStr[4])]+'",'+
                     WrkStr[7]+','+WrkStr[8]+','+
                     WrkStr[6]+','+
                     Strip_Leading_Char(WrkHeight,4,'0')+':';
          IF (WrkStr[4] = '5') OR (WrkStr[4] = '7') THEN
            NewStr := NewStr + 'BFON:PB '
          ELSE
            NewStr := NewStr + 'BFOFF:PB ';
          CheckInverse(Inverse);
          AddVar;
          WriteLn(LDFName,NewStr);
          NewStr := '';
         END;

        IF WrkStr[2] = 'C' THEN
         BEGIN
          {This does Constants}
          CheckPosition(Copy(WrkStr,10,4),Copy(WrkStr,6,4));
          CheckDirection(WrkStr[15]);
          Set_Inverse(WrkStr[14]);
          CheckAlign(Align);
          CheckMag(WrkStr[5],WrkStr[4]);
          CheckInverse(Inverse);
          CheckFonts(WrkStr[3]);
          NewStr := NewStr + 'PT"' + Copy(WrkStr,16,Length(WrkStr)-15) +'"';
          WriteLn(LDFName,NewStr);
          NewStr := '';
         END;
        ReadLn(FDLName,WrkStr);
       END;
      WriteLn(LDFName,'LAYOUT END');
     END
    ELSE
     BEGIN
      IF EOF(FDLName) THEN
       BEGIN
        {Make sure all label formats are killed in new file}
        IF NOT Added THEN WriteLn(LDFName,'KILL"LF'+LabelFormat[j]+'"');
        Added := FALSE;
        INC(j);
        Close(FDLName);
        Reset(FDLName);
       END;
     END;
   END; {WHILE Loop}
   Close(FDLName);
   Close(LDFName);
  END;
END.
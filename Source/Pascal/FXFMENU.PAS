(****************************************************************************
*  UNIT          : FXFMENU                                                  *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 09/06/97                                                 *
*  PURPOSE       : FORMIX MENU DISPLAYER                                    *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFMenu;
INTERFACE
USES Crt,F6StdUt1,F6StdUtl,F6StdCtv,F6StdWin,FxfIni,FXCfg;


FUNCTION LoadMenu(hedp : STRING; top_off : BOOLEAN) : BOOLEAN;

CONST
     EditSTRING  = 01;
     EditInteger = 02;
     EditLongint = 03;
     EditTickBox = 04;
     EditRadio   = 05;
     EditDate    = 06;
     EditTime    = 07;
     EditDouble1 = 08;
     EditDouble2 = 09;
     EditDouble3 = 10;
     EditDouble4 = 11;
     EditDouble5 = 12;

IMPLEMENTATION

FUNCTION LoadMenu(hedp:STRING; top_off : BOOLEAN) : BOOLEAN;
VAR Filename    : STRING;
    i           : INTEGER;
    mcfile      : TEXT;
    stat, stat1,
    data        : BOOLEAN;
    Menu        : BOOLEAN;
    vl          : BYTE;
    sel         : INTEGER;
    NonDatLine  : INTEGER;
    XCo         : INTEGER;
    UnitFrom    : BYTE;
    line        : STRING[100];
    SkipLine    : BOOLEAN;
    InDef       : BOOLEAN;
    This_of     : INTEGER;
    Command     : BOOLEAN;

   FUNCTION CheckCompile : BOOLEAN;
   VAR TempINI : INIVAR;
   BEGIN
    Stripped(Line,Length(Line),' ');
    TempIni.V := Line;
    TempIni.S := Compile;
    CheckCompile := GetExtSwitch(TempINI,all,FALSE);
   END;



   PROCEDURE ProcessCommand;
   VAR Xco,YCo  : INTEGER;

       PROCEDURE GetVal(VAR Result : INTEGER);
       VAR CommaPos,ValErr : INTEGER;
           Temp : INTEGER;
       BEGIN
        CommaPos := Pos(',',Line);
        IF (CommaPos > 0) THEN
         BEGIN
          VAL(Copy(Line,1,CommaPos-1),Temp,ValErr);
          IF (ValErr = 0) THEN Result := Temp;
          SYSTEM.Delete(Line,1,CommaPos);
         END;
       END;

   BEGIN
    IF (StringLIComp(Line,'$IFDEFINE',9) = 0) THEN
     BEGIN
      SYSTEM.Delete(Line,1,9);

      SkipLine := NOT CheckCompile;
      Indef    := TRUE;
     END
    ELSE IF (StringLIComp(Line,'$ELSE',5) = 0) THEN
     BEGIN
      IF (Indef) THEN SkipLine := Not SkipLine;
     END
    ELSE IF (StringLIComp(Line,'$END',4) = 0) THEN
     BEGIN
      InDef    := FALSE;
      SkipLine := FALSE;
     END
    ELSE IF (NOT SkipLine) THEN
     BEGIN
      IF (StringLIComp(Line,'$WRITE',6) =0) THEN
       BEGIN
        SYSTEM.DELETE(Line,1,6);
        Stripped(Line,Length(Line),' ');
        XCo := -1; YCo := -1;
        GetVal(XCo); GetVal(YCo);
        IF (XCo <> -1) AND (YCo <> -1) THEN
         BEGIN
          FastWriteAt(XCo,YCo,Line);
         END;
       END;
     END;
   END;

BEGIN
 SkipLine := FALSE;
 Indef    := FALSE;

 Menu := TRUE;
 IF menucr = hedp THEN Exit;          {No update as no change}
 menucr := hedp;
 ClearEdit;
{ClearMenu;}

 NonDatLine := 0;
 IF NOT Top_off THEN
  BEGIN
   Window(1,1,80,25);
   ClrScr;
   gotoxy(1,1);
   RevVideo;
   Write(PROP_Banner,' ',
	 PROP_ProgramName+' ',
	 'v'+PROP_ProgramVersion+'    ',
	 '(c) '+PROP_Copyright);
   Inc(NonDatLine);
   GoToXY (1,NonDatLine+1);
   LowVideo;
  END;

 Filename := PROP_TextFilePath + hedp + '.TXT';
 stat := FALSE; stat1:= FALSE; Menu := FALSE;
 data := FALSE; no_of:= 1; Menu_Of := 0;
 Assign(mcfile,filename);
{$i-}
  Reset(mcfile);
{$i+}
 IF IoResult <> 0 THEN
  BEGIN
   Menu := FALSE;
   Exit;
  END;
 WHILE NOT Eof(mcfile) DO
  BEGIN
   XCo     := 1;
   Command := FALSE;
   This_Of := 0;
   Readln(mcfile,line);

   IF (SkipLine) THEN
    BEGIN
     Stripped(Line,Length(Line),' ');
     if (line[1] = '$') then processcommand;
    END
   ELSE
    BEGIN
     WHILE (Pos('&unit',Line) <> 0) DO
      BEGIN
       UnitFrom := Pos('&units_',Line);
       IF (UnitFrom <> 0) THEN
        BEGIN
         Line := Copy(Line,1,UnitFrom-1)+
                 Copy(Config_Rec^.CONF_UnitName,1,7)+
	         Copy(Line,UnitFrom+7,100);
        END
       ELSE
        BEGIN
         UnitFrom := Pos('&unit',Line);
         IF (UnitFrom <> 0) THEN
	  BEGIN
  	   Line := Copy(Line,1,UnitFrom-1)+
                   Copy(Config_Rec^.CONF_SglUnitName,1,5)+
	  	   Copy(Line,UnitFrom+5,100);
  	  END;
        END;
      END;

     FOR i := 1 TO length(line) DO
      BEGIN
       CASE line[i] OF
        '@' : BEGIN
	       Data := TRUE;        {01,09,89}
	       sel  := 1;
               {Clear default values set by ClearEdit}
               XcoOrd[no_of] := 0;
               YcoOrd[no_of] := 0;
               LenOrd[no_of] := 0;
               DatCtl[no_of] := 0;
               DatType[no_of] := 0;
              END;
        '^' : BEGIN
	       stat := NOT stat;
	       IF stat THEN highvideo ELSE LowVideo;
	      END;
        '~' : BEGIN
	       stat1 := NOT stat1;
	       IF stat1 THEN RevVideo ELSE LowVideo;
	      END;
        '_' : BEGIN
	      END;
        '$' : BEGIN
               ProcessCommand;
               Command := TRUE;
               Break;
              END;
        ELSE
         BEGIN
          IF Data THEN
	   BEGIN
	    CASE line[i] OF
  	     '0'..'9' : BEGIN
               vl := Ord(Line[i]) - $30;
               CASE sel OF
                1 : This_Of := This_of *10+vl;
                2 : XcoOrd[This_of] := XcoOrd[This_of]*10+vl;
                3 : YcoOrd[This_of] := YcoOrd[This_of]*10+vl;
                4 : LenOrd[This_of] := LenOrd[This_of]*10+vl;
                5 : DatCtl[This_of] := DatCtl[This_of]*10+vl;
                6 : DatType[This_of]:= DatType[This_of]*10+vl;
               END;
             END;
             ','      : INC(Sel);
	    END;
	   END {IF Data THEN}
          ELSE
	   BEGIN
	    fastwriteAt(Xco,NonDatLine+1,line[i]);
	    INC(XCo);
	   END;
         END; {else not control char}
       END;{CASE}
      END; {for i = 1 to length(line)}
     IF (NOT Command) THEN
      BEGIN
       IF Data THEN
        BEGIN
         Data := FALSE;
         Inc(no_of);
        END
       ELSE
        BEGIN
         IF NonDatLine < 25 THEN Inc(NonDatLine);
         GoToXY(1,NonDatLine+1);
        END;
      END;
    END; {else}
  END;
 Close(mcfile);
 LowVideo;
 IF NOT top_off THEN Window(1,2,80,25);
 Dec(no_of);
END;


PROCEDURE GetEdit(ForEdit : INTEGER);
BEGIN
 CASE DatType[ForEdit] OF {Compiler err: array type req .. use lib defined in FXPROG.pas}
  EditSTRING  : GetLine(DatOrd[ForEdit],LenOrd[ForEdit],XCoOrd[ForEdit],YCoOrd[ForEdit]);
  EditInteger : GetLine_Num(DatOrd[ForEdit],LenOrd[ForEdit],XCoOrd[ForEdit],YCoOrd[ForEdit],0);
  EditLongint : GetLine_Num(DatOrd[ForEdit],LenOrd[ForEdit],XCoOrd[ForEdit],YCoOrd[ForEdit],0);
  EditTickBox : GetTick(DatOrd[ForEdit],XCoOrd[ForEdit],YCoOrd[ForEdit]);
  EditRadio   : GetRadio(DatOrd[ForEdit],XCoOrd[ForEdit],YCoOrd[ForEdit]);
  EditDate    : GetLine_Num(DatOrd[ForEdit],LenOrd[ForEdit],XCoOrd[ForEdit],YCoOrd[ForEdit],-1);
  EditTime    : GetLine_Num(DatOrd[ForEdit],LenOrd[ForEdit],XCoOrd[ForEdit],YCoOrd[ForEdit],-2);
  EditDouble1 : GetFloat(XCoOrd[ForEdit],YCoOrd[ForEdit],DatOrd[ForEdit],LenOrd[ForEdit],1);
  EditDouble2 : GetFloat(XCoOrd[ForEdit],YCoOrd[ForEdit],DatOrd[ForEdit],LenOrd[ForEdit],2);
  EditDouble3 : GetFloat(XCoOrd[ForEdit],YCoOrd[ForEdit],DatOrd[ForEdit],LenOrd[ForEdit],3);
  EditDouble4 : GetFloat(XCoOrd[ForEdit],YCoOrd[ForEdit],DatOrd[ForEdit],LenOrd[ForEdit],4);
  EditDouble5 : GetFloat(XCoOrd[ForEdit],YCoOrd[ForEdit],DatOrd[ForEdit],LenOrd[ForEdit],5);
 END;
END;

END.

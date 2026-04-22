(****************************************************************************
*  UNIT          : FXCSVIMP                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 02/07/97                                                 *
*  PURPOSE       : FORMIX                                                   *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXCSVImp;
INTERFACE
USES Crt,Strings,F6StdUtl,F6StdCtv,F6CsvUtl,FXFIngr,F6StdWn1,F6StdWin,
     FXCfg,FXFRcp,FXFCRCP,FXFProd,F6StdBar,FXModCtv;

PROCEDURE ImportIngredients;
PROCEDURE ImportRecipes;

IMPLEMENTATION

PROCEDURE  ShowBarPercentage(The_Bar : Percent_Bar_Ptr);
BEGIN
 WITH The_Bar^ DO
  BEGIN
   GotoXY(Xp+(Length-4) DIV 2,Yp+1);
   Write(((CurrPos*100) DIV MaxVal),'%');
  END;
END;

PROCEDURE ImportIngredients;
VAR IngFile : TEXT;
    IngRec  : TIngredient_Record;
    IngLine : STRING;
    IngFound: BOOLEAN;
    ImportWindow : WindowRecord;

    FileName : STRING[80];
    FileSize : LONGINT;
    ImportBar : Percent_Bar_Ptr;

    PROCEDURE InitialiseIngredientRecord;
    BEGIN
     IngredientFile^.InitRecord(IngRec);
     IngRec.ING_DefaultHighTol := 2.00;
    END;

BEGIN
 IF (Show_Btrv_Err(IngredientFile^.OpenFile) <> 0) THEN
  BEGIN
   Disp_Error_Msg('Unable To Open Ingredient File');
   EXIT;
  END;

 FileName := Config_Rec^.Conf_ImpPath+'INGREDS.TXT';
 FileSize := GetFileSize(FileName);

 Assign(IngFile,FileName);
 {$I-}
 Reset(IngFile);
 {$I-}
 IF (IOResult <> 0) THEN
  BEGIN
   Disp_Error_Msg('Ingredient Import File Not Found');
  END
 ELSE
  BEGIN
   ImportBar := Init_Percent_Bar (2,3,7,1,36,FileSize,FALSE);
   BackColourScheme;
   SetWindow(20,10,60,17,TRUE,0,0,ImportWindow);
   Header('Importing Ingredients',1);
   Footer('',1);
   ForeColourScheme;
   Draw_Percent_Bar(ImportBar);
   CursorOff;
   WHILE (NOT EOF(IngFile)) DO
    BEGIN
     InitialiseIngredientRecord;
     ReadLn(IngFile,IngLine);
     Inc(ImportBar^.CurrPos,Length(IngLine)+2);
     Update_Percent_Bar(ImportBar);
     ShowBarPercentage(ImportBar);
     GetFromStr(IngLine,rtString,8,IngRec.ING_Ingredient);
     IngRec.ING_Ingredient := IngRec.ING_Ingredient + SPACE_STRING;
     IngFound := IngredientFile^.ReadRecord('EQ',TRUE,FALSE,IngRec,0) = 0;
     GetFromStr(IngLine,rtChar,1,IngRec.ING_Hazard_Code);
     GetFromStr(IngLine,rtString,20,IngRec.ING_Description);
     IngRec.ING_Description := IngRec.ING_Description + SPACE_STRING;
     GetFromStr(IngLine,rtDouble,10,IngRec.ING_Cost);
     GetFromStr(IngLine,rtDouble,10,IngRec.ING_SG);
     IF (IngFound) THEN
      IngredientFile^.UpdateRecord(IngRec)
     ELSE
      IngredientFile^.AddRecord(IngRec);
    END;
   LoseWindow(ImportWindow);
   CursorOn;
   Dispose_Percent_Bar(ImportBar);
   Close(IngFile);
  END;
 Show_Btrv_Err(IngredientFile^.CloseFile);
END;


PROCEDURE ImportRecipes;
{This Needs To Also Add A Product With The Same Recipe Code, And Add One Line
To That Product Which Is The Recipe}
VAR RcpFile : TEXT;
    RcpRec  : PRecipeRecord;
    RcpLine : STRING;
    RcpFound: BOOLEAN;
    LineIn  : ARRAY[0..500] OF CHAR;
    LineInCopyPosn : LONGINT;
    ImportWindow : WindowRecord;
    RecipeFileAlloc : BOOLEAN;

    ProdRec  : TProdHeaderRecord;
    ProdLine : TProdLineRecord;
    ProdFound : BOOLEAN;
    ProdLineFound : BOOLEAN;
    ProdErr   : INTEGER;

    IngredientList : ARRAY[1..20] OF TIngredientRef;
    IngNo : INTEGER;
    PHR   : DOUBLE;
    IngPos : INTEGER;

    FileName : STRING[80];
    FileSize : LONGINT;
    ImportBar : Percent_Bar_Ptr;
    TempStr20 : STRING[20];

  PROCEDURE Init;
  BEGIN
   New(RcpRec);
   RecipeFileAlloc := Assigned(RecipeFile);
   IF NOT RecipeFileAlloc THEN
    BEGIN
     NEW(RecipeFile,Init(Config_Rec^.Conf_FPath+Recipe_Header_FileName,
                         Config_Rec^.Conf_FPath+Recipe_Line_FileName));
    END;
  END;

  PROCEDURE Done;
  BEGIN
   IF NOT RecipeFileAlloc THEN
    BEGIN
     DISPOSE(RecipeFile,Done);
     RecipeFile := NIL;
    END;
   Dispose(RcpRec);
  END;

  PROCEDURE InitRecipe;
  BEGIN
   RecipeFile^.InitRecord(RcpRec);
  END;

(*
  FUNCTION FindIngredient(IngCode : STRING) : INTEGER;
  VAR I : INTEGER;
  BEGIN
   FindIngredient := -1;
   FOR I := 1 TO MAX_LINES_ON_RECORD DO
    BEGIN
     IF Assigned(RcpRec^.RP_Lines[I]) THEN
      BEGIN
       IF (RcpRec^.RP_Lines[I]^.RL_Ingredient = IngCode) THEN  { Add New Record       }
        BEGIN
         FindIngredient := I;
         EXIT;
        END;
      END; { END (Valid Record) }
    END;
  END;
*)
  FUNCTION GetNextFreeSpace : INTEGER;
  VAR I : INTEGER;
  BEGIN
   GetNextFreeSpace := -1;
   FOR I := 1 TO MAX_LINES_ON_RECORD DO
    BEGIN
     IF NOT Assigned(RcpRec^.RP_Lines[I]) THEN
      BEGIN
       New(RcpRec^.RP_Lines[I]);
       RecipeFile^.LineFile^.InitRecord(RcpRec^.RP_Lines[I]^);
       GetNextFreeSpace := I;
       EXIT;
      END; { END (Valid Record) }
    END;

  END;

  FUNCTION GetNext200CharsFromLineIn : STRING;
  VAR
    cBuffer : ARRAY[0..210] OF CHAR;
  BEGIN
   IF LineInCopyPosn < StrLen(LineIn) THEN
    BEGIN
     GetNext200CharsFromLineIn :=
                     StrPas(StrLCopy(cBuffer,@LineIn[LineInCopyPosn],200));
     LineInCopyPosn := LineInCopyPosn + 200;
    END
   ELSE
     GetNext200CharsFromLineIn := '';
  END;

BEGIN
 Init;
 FileName := Config_Rec^.Conf_ImpPath+'MIXES.TXT';
 FileSize := GetFileSize(FileName);

 Assign(RcpFile,FileName);
 {$I-}
 Reset(RcpFile);
 {$I-}
 IF (IOResult <> 0) THEN
  BEGIN
   Disp_Error_Msg('Recipe Import File Not Found');
  END
 ELSE
  BEGIN
   ImportBar := Init_Percent_Bar (2,3,7,1,36,FileSize,FALSE);
   BackColourScheme;
   SetWindow(20,10,60,17,TRUE,0,0,ImportWindow);
   Header('Importing Recipes',1);
   Footer('',1);
   ForeColourScheme;
   Draw_Percent_Bar(ImportBar);
   InitRecipe;
   RecipeFile^.OpenFile;
   ProdHeaderFile^.OpenFile;
   ProdLineFile^.OpenFile;
   CursorOff;
   WHILE (NOT EOF(RcpFile)) DO
    BEGIN
     RecipeFile^.ClearLines(RcpRec);
     {Need To Read It Into A PCHAR as Would Not fit Into A String}
     InitRecipe;
     ReadLn(RcpFile,LineIn);
     Inc(ImportBar^.CurrPos,StrLen(LineIn)+2);
     Update_Percent_Bar(ImportBar);
     ShowBarPercentage(ImportBar);
     {Copy First 200 Chars Into RcpLine}
     LineInCopyPosn := 0;
     RcpLine := GetNext200CharsFromLineIn;

     GetFromStr(RcpLine,rtString,20,TempStr20);
     Stripped(TempStr20, Length(TempStr20), ' ');
     IF  (TempStr20 <> '')
     AND (Length(TempStr20) <= SizeOf(TRecipeRef)-1) THEN
      BEGIN
       RcpRec^.RP_Header.RH_RecipeNo := TempStr20 + SPACE_STRING;

       RcpFound := RecipeFile^.ReadAllRecords('EQ',TRUE,FALSE,RcpRec,0) = 0;
       IF (RcpFound) THEN
        BEGIN
         FOR IngNo := 1 TO MAX_LINES_ON_RECORD DO  { Delete Existing Ing. List}
           RecipeFile^.DeleteLineRec(RcpRec,1);{ keep marking first line
                                             as deleted in re-shuffling list }
        END;
       GetFromStr(RcpLine,rtString,8,RcpRec^.RP_Header.RH_IssueNo);
       RcpRec^.RP_Header.RH_IssueNo := RcpRec^.RP_Header.RH_IssueNo + SPACE_STRING;
       GetFromStr(RcpLine,rtDouble,8,RcpRec^.RP_Header.RH_DefaultMixWt);
       RcpRec^.RP_Header.RH_StdCaseWt := RcpRec^.RP_Header.RH_DefaultMixWt;
       {Next Is 20 Ingredients. Store These In A Temporary List}
       FillChar(IngredientList, SizeOf(IngredientList), 0);
       FOR IngNo := 1 TO 20 DO
        BEGIN
         IF (Length(RcpLine) < 20) THEN
          BEGIN
           RcpLine := RcpLine + GetNext200CharsFromLineIn;
          END;
         GetFromStr(RcpLine,rtString,8,IngredientList[IngNo]);
        END;
       {Now There Are 20 Mix Ratios}
       FOR IngNo := 1 TO 20 DO
        BEGIN
         IF (Length(RcpLine) < 20) THEN
          BEGIN
           RcpLine := RcpLine + GetNext200CharsFromLineIn;
          END;
         GetFromStr(RcpLine,rtDouble,8,PHR);
         IF (NOT NowtButSpace(IngredientList[IngNo])) THEN
          BEGIN
           IngredientList[IngNo] := IngredientList[IngNo]+SPACE_STRING;
(*
           IngPos := FindIngredient(IngredientList[IngNo]);
           IF (Ingpos = -1) THEN
*)
           IngPos := GetNextFreeSpace;
           IF (IngPos <> -1) THEN
            BEGIN
             WITH RcpRec^.RP_Lines[IngPos]^ DO
              BEGIN
{             RL_UniqueRef     : LONGINT;      Filled out Later}
               RL_RecipeNo      := RcpRec^.RP_Header.RH_RecipeNo;
               RL_LineNo        := IngPos;
               RL_HUniqueRef    := RcpRec^.RP_Header.RH_UniqueRef; {Filled Out Later}
               RL_Ingredient    := IngredientList[IngNo];
               RL_DefaultKeyIngred := FALSE;
               RL_DefaultRatio     := 0.0;         {Calculated Later}
               RL_DefaultContSize  := RcpRec^.RP_Header.RH_DefaultMixWt;
               RL_DefaultYield     := 100.00;      {Should Come From Ingredient Really}
               RL_PHR           := PHR;
              END;
            END;
          END;
        END;
       IF (RcpFound) THEN                          { Update To Recipe         }
         RecipeFile^.UpdateRecord(RcpRec)          { Perform Database Update  }
       ELSE
         RecipeFile^.AddRecord(RcpRec);            { Add Recipe To Database   }
       {Now Must Add A Product With The Same Name ETC}
       ProdHeaderFile^.InitRecord(ProdRec);
       ProdLineFile^.InitRecord(ProdLine);
       ProdRec.PH_ProductCode := RcpRec^.RP_Header.RH_RecipeNo +SPACE_STRING;
       ProdFound := ProdHeaderFile^.ReadRecord('EQ',TRUE,FALSE,ProdRec,0) = 0;

       ProdRec.PH_Description := SPACE_STRING;
       Inc(ProdRec.PH_UpdateCount);
       ProdRec.PH_CaseSize    := RcpRec^.RP_Header.RH_StdCaseWt;

       ProdLineFound := FALSE;
       ProdLine.PL_ProductCode := ProdRec.PH_ProductCode;

       IF (ProdFound) THEN
        BEGIN
         ProdLineFound := ProdLineFile^.ReadRecord('EQ',TRUE,FALSE,ProdLine,0) =0;
        END;

       WITH ProdLine DO
        BEGIN
         PL_LineNo      := 1;
         PL_RecipeNo    := RcpRec^.RP_Header.RH_RecipeNo;
         PL_Ratio       := 100.00;
         PL_SubProduct  := SPACE_STRING;
        END;
       IF (ProdLineFound) THEN
        ProdLineFile^.UpdateRecord(ProdLine)
       ELSE
        ProdLineFile^.AddRecord(ProdLine);

       IF (ProdFound) THEN
        ProdHeaderFile^.UpdateRecord(ProdRec)
       ELSE
        ProdHeaderFile^.AddRecord(ProdRec);
      END;{valid Recipe code}
    END; {WHILE NOT EOF}
   RecipeFile^.CloseFile;
   IF (ProdHeaderfile^.OpenErr = 0) THEN ProdHeaderFile^.CloseFile;
   IF (ProdLineFile^.OpenErr   = 0) THEN ProdLineFile^.CloseFile;
   Losewindow(ImportWindow);
   Dispose_Percent_Bar(ImportBar);
   Close(RcpFile);
  END;
 CursorOn;
 Done;
END;


END.

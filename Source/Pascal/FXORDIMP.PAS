{$O+,F+}
{$I F6COMP}
UNIT FXORDIMP;


INTERFACE


USES DOS,F6DTCONV,F6STDCTV,F6STDUTL,FXMODCTV,FXFINGR,FXFORDER,FXFWORK,FXCFG,
     FXFRcp,FXTFLOG,F6CSVUTL,F6CSVIMP,Strings;


PROCEDURE TimedOrderImport;



{
                      RECIPE ORDER CSV FILE FORMAT


Field                      Format            Max Width  Default if not mandatory
---------                  ---------         ---------  ------------------------
1  Order_Schedule_Date     DDMMYYYY               8
2  Order_No                n6                     6
3  Order_No_Suffix         n2                     2
4  Order_Recipe_No         a8                     8     see note 6.
5  Not_Used                a0                     0
6  Order_Finish_Wt         n5.3dp                 9
7  Order_Max_Mix_Wt        n5.3dp                 9     As on Recipe header
8  Ingred_Code             a8                     8
9  Ingred_Finish_Wt        n5.3dp                 9
10 Ingred_Container_Wt     n5.3dp                 9     As on Ingredient
11 Order_Status            a4 'HOLD' 'WIP' 'COMP' 4     'HOLD'
12 Order_Work_Group        a3                     3     blank
13 Order_Release_No        n3                     3     0
14 Order_Custom_Num1       n4                     4     0
15 Order_Custom_Alpha1     a7                     7     blank
16 Order_Custom_Alpha2     a10                   10     blank
17 Ingred_Tol_NegPercent   n2.3                   6     As on Ingredient
18 Ingred_Tol_PosPercent   n2.3                   6     As on Ingredient
19 Ingred_Spec_Instruct1   a30                   30     As on Ingredient
20 Ingred_Spec_Instruct2   a30                   30     As on Ingredient
21 Ingred_Mixing_Yield     n3.3                   7     As on Ingredient
22 Ingred_Is_Key           a1    'Y' 'N'          1     'N'
                                           ---------
                                                179 + (22 X ',')

1. All lines for an order to be included in the file on consecutive lines.
2. All lines for an order to have matching order details ('Order_' fields).
3. If the order already exists and has not been started, then it will be
   completely replaced by the imported details.
4. If the order already exists and has been started, then the imported details
   will be rejected.
5. Errors will be logged in RCPIMP.RPT
6. Even if a recipe code is supplied, the order line details will only be
   primed from ingredient records (not any similar recipe lines).
}

IMPLEMENTATION

TYPE
     TOrderHImpRecord = PACKED RECORD { Unvalidated fields extracted from CSV line }
                               { relating to order header.                  }
       IMPOH_Date           : LONGINT;
       IMPOH_No             : LONGINT;
       IMPOH_NoSuffix       : BYTE;
       IMPOH_Recipe         : TRecipeRef;
       IMPOH_Dummy          : STRING[1];
       IMPOH_FinalWtReq     : DOUBLE;
       IMPOH_MaxMixWt       : DOUBLE;
       IMPOH_Status         : STRING[4];
       IMPOH_Work_Group     : TWorkGrp;
       IMPOH_Release_No     : INTEGER;
       IMPOH_Custom_Num1    : INTEGER;
       IMPOH_Custom_Alpha1  : STRING[7];
       IMPOH_Custom_Alpha2  : STRING[10];
     END;

     TOrderLImpRecord = PACKED RECORD { Unvalidated fields extracted from CSV line }
                               { relating to order line.                    }
       IMPOL_Ingredient     : TIngredientRef;
       IMPOL_IngredientReq  : DOUBLE;
       IMPOL_ContainerSize  : DOUBLE;
       IMPOL_Tol_NegPercent : DOUBLE;
       IMPOL_Tol_PosPercent : DOUBLE;
       IMPOL_Spec_Instruct1 : STRING[30];
       IMPOL_Spec_Instruct2 : STRING[30];
       IMPOL_Mixing_Yield   : DOUBLE;
       IMPOL_KeyIngredient  : STRING[1];
     END;

CONST LAST_FIELD = 22;
CONST ImpFieldNames : ARRAY[1..LAST_FIELD] OF PChar = (
              'Date',
              'Order No.',
              'Order no. Suffix',
              'Recipe',
              '',
              'Order Finish Wt.',
              'Mix Weight',
              'Ingredient Code',
              'Ingredient Wt.',
              'Ingredient Container Size',
              'Order Status',
              'Work Group',
              'Release No.',
              'Custom Numeric 1',
              'Custom Alpha 1',
              'Custom Alpha 2',
              '-ve% tolerance',
              '+ve% tolerance',
              'Instruction 1.',
              'Instruction 2.',
              'Ingredient Yield',
              'Key Ingredient Flag');

{ Config_Rec^.Conf_OrdCustomNum1;
              Config_Rec^.Conf_OrdCustomAlpha1;
              Config_Rec^.Conf_OrdCustomAlpha2;
}



TYPE PCSVOrderImport = ^TCSVOrderImport;
     TCSVOrderImport = OBJECT
       SR         : SearchRec;
       ErrorLog   : PTextFileLogger;
       ImportFile : PCSVFileImporter;
       Presenter  : PCSVFileImporterPresenter;
       ImportPath : STRING;
       WOFile     : PCombineWOFile;
       IFile      : PIngredientFile;
       RcpFile    : PRecipeHeaderFile;
       ORec       : PWOrderObject;
       CurrImpOrdHead,
       NextImpOrdHead : TOrderHImpRecord;
       ImpOrdLine     : TOrderLImpRecord;
       RcpHead        : TRecipeHeaderRecord;
       IRec           : TIngredient_Record;
       CONSTRUCTOR Init(FilePath : STRING);
       DESTRUCTOR  Done;
       FUNCTION    FieldName(FieldNo : INTEGER) : STRING;
       PROCEDURE   ProcessImportFile;
       PROCEDURE   Run;
     END;




CONSTRUCTOR TCSVOrderImport.Init(FilePath : STRING);
BEGIN
 ImportFile    := NIL;
 WOFile        := NIL;
 ORec          := NIL;
 IFile         := NIL;
 RcpFile       := NIL;
 WOFile     := NEW(PCombineWOFile,Init(Config_Rec^.Conf_FPath + WOHeader_File_Name ,
                                       Config_Rec^.Conf_FPath + WOLine_File_Name   ));
 IFile      := NEW(PIngredientFile,Init(Config_Rec^.Conf_SFPath + Ingredient_file_name));
 RcpFile    := New(PRecipeHeaderFile,Init(Config_Rec^.Conf_FPath + Recipe_Header_FileName));

 ORec       := NEW(PWOrderObject,Init);

 ErrorLog   := NEW(PTextFileLogger,Init(Config_Rec^.Conf_RPath + 'RCPIMP.RPT',''));
 ImportPath := FilePath;

 IF ImportPath ='' THEN ImportPath :='.';
 IF ImportPath[ORD(ImportPath[0])] <> '\' THEN ImportPath := ImportPath +'\';
END;


DESTRUCTOR TCSVOrderImport.Done;
BEGIN
 IF Assigned(ErrorLog)      THEN Dispose(ErrorLog,Done);
 IF Assigned(ORec)          THEN Dispose(ORec,Done);
 IF Assigned(RcpFile)       THEN Dispose(RcpFile,Done);
 IF Assigned(IFile)         THEN Dispose(IFile,Done);
 IF Assigned(WOFile)        THEN Dispose(WOFile,Done);
END;


FUNCTION TCSVOrderImport.FieldName(FieldNo : INTEGER) : STRING;
BEGIN
 CASE FieldNo OF
   14 : FieldName := Config_Rec^.Conf_OrdCustomNum1;
   15 : FieldName := Config_Rec^.Conf_OrdCustomAlpha1;
   16 : FieldName := Config_Rec^.Conf_OrdCustomAlpha2;
   ELSE FieldName := StrPas(ImpFieldNames[FieldNo]);
  END;
END;


PROCEDURE TCSVOrderImport.ProcessImportFile;
VAR
    CurrOrdHead    : LONGINT;
    LinePos        : LONGINT;
    CurrOrdIsValid : BOOLEAN;
    FailImport     : BOOLEAN;
    ImpFileErr     : TCSVError;
    SubPath        : STRING[9];
    DErr : INTEGER;

  FUNCTION ParseCSVLine(VAR AImpHRec : TOrderHImpRecord;
                        VAR AImpLRec : TOrderLImpRecord) : BOOLEAN;
  {PROMISES Only returns TRUE if comma seperated fields supplied on
            line can be converted into importrecord fields.
  }
  VAR
      Err : TCSVError;
      FieldStr : STRING[30];
      FieldNo  : INTEGER;
  BEGIN
   ParseCSVLine := FALSE;
   Err := err_none;
   FieldNo := 0;
   FillChar(AImpHRec, SizeOF(AImpHRec), #0);
   FillChar(AImpLRec, SizeOF(AImpLRec), #0);
   WITH AImpLRec DO
    BEGIN
     IMPOL_Tol_NegPercent := -1.0; { so 0.0 is recognised as a valid import }
     IMPOL_Tol_PosPercent := -1.0; { so 0.0 is recognised as a valid import }
    END;

   WITH AImpHRec, AImpLRec, ImportFile^ DO
    BEGIN
     REPEAT
       Inc(FieldNo);
       CASE FieldNo OF
         1 : BEGIN
              Err := GetField(rtNoQuoteStr,8,FieldStr);
              FieldStr := COPY(FieldStr,1,2) + '/' +
                          COPY(FieldStr,3,2) + '/' +
                          COPY(FieldStr,5,4);
              IF Valid_Date(FieldStr) THEN
                IMPOH_Date := Date_To_Days(FieldStr)
              ELSE
                Err := err_type_mismatch;
             END;
         2 : Err := GetField(rtLongint,0,IMPOH_No);

         3 : Err := GetField(rtByte,0,IMPOH_NoSuffix);
         4 : BEGIN
              Err := GetField(rtString,8,IMPOH_Recipe);
              IMPOH_Recipe := IMPOH_Recipe + Space_String;
             END;
         5 : BEGIN
              GetField(rtString,30,IMPOH_Dummy); {dont set any errors}
              Err := err_none;
             END;
         6 : Err := GetField(rtDouble,0,IMPOH_FinalWtReq);
         7 : Err := GetField(rtDouble,0,IMPOH_MaxMixWt);
         8 : BEGIN
              Err := GetField(rtString,8,IMPOL_Ingredient);
              IMPOL_Ingredient := IMPOL_ingredient + Space_String;
             END;
         9 : Err := GetField(rtDouble,0,IMPOL_IngredientReq);
        10 : Err := GetField(rtDouble,0,IMPOL_ContainerSize);
        11 : BEGIN
              Err := GetField(rtString,4,IMPOH_Status);
              IMPOH_Status := IMPOH_Status + Space_String;
             END;
        12 : BEGIN
              Err := GetField(rtString,3,IMPOH_Work_Group);
              IMPOH_Work_Group := IMPOH_Work_Group + Space_String;
             END;
        13 : Err := GetField(rtInteger,0,IMPOH_Release_No);
        14 : Err := GetField(rtInteger,0,IMPOH_Custom_Num1);
        15 : BEGIN
              Err := GetField(rtString,7,IMPOH_Custom_Alpha1);
              IMPOH_Custom_Alpha1 := IMPOH_Custom_Alpha1 + Space_String;
             END;
        16 : BEGIN
              Err := GetField(rtString,10,IMPOH_Custom_Alpha2);
              IMPOH_Custom_Alpha2 := IMPOH_Custom_Alpha2 + Space_String;
             END;
        17 : Err := GetField(rtDouble,0,IMPOL_Tol_NegPercent);
        18 : Err := GetField(rtDouble,0,IMPOL_Tol_PosPercent);
        19 : BEGIN
              Err := GetField(rtString,30,IMPOL_Spec_Instruct1);
              IMPOL_Spec_Instruct1 := IMPOL_Spec_Instruct1 + Space_String;
             END;
        20 : BEGIN
              Err := GetField(rtString,30,IMPOL_Spec_Instruct2);
              IMPOL_Spec_Instruct2 := IMPOL_Spec_Instruct2 + Space_String;
             END;
        21 : Err := GetField(rtDouble,0,IMPOL_Mixing_Yield);
        ELSE BREAK;
        END;
     UNTIL Err <> err_None;

     IF Err IN [err_None, err_end_of_line, err_end_of_file] THEN
       ParseCSVLine := TRUE
     ELSE
       ErrorLog^.WriteErrorTS('Invalid '+FieldName(FieldNo)+
                              ' field ('+
                              IntToStr(FieldNo,1)+
                              ') in line '+
                              IntToStr(GetLineNum,1)+': '+
                              LineText);
    END;
  END;


  FUNCTION LoadORecHeader : BOOLEAN;
  VAR
     FieldNo : INTEGER;
  BEGIN
   LoadORecHeader := FALSE;
   WITH ORec^.WO_Header, CurrImpOrdHead DO
    BEGIN
     FieldNo := 0;
     WHILE FieldNo <= LAST_FIELD DO
      BEGIN
       Inc(FieldNo);
       CASE FieldNo OF
         1 : BEGIN
              WOH_SchDate := IMPOH_Date;
              IF WOH_SchDate <= 0 THEN BREAK; { compulsory field }
             END;

         2 : BEGIN
              WOH_OrderNo := IMPOH_No;
              IF (WOH_OrderNo <= 0) OR (WOH_OrderNo > 999999) THEN
                BREAK;
             END;

         3 : BEGIN
              WOH_Revision := IMPOH_NoSuffix;
              IF (WOH_Revision < 0) OR (WOH_Revision > 99) THEN
                BREAK;
             END;

         4 : BEGIN
              IF NOT NowtButSpace(IMPOH_Recipe) THEN
               BEGIN
                IF RcpFile^.ReadRecipeHeader(RcpHead, IMPOH_Recipe) = 0 THEN
                  LoadWOHeaderWithRecipeHeader(ORec^.WO_Header, RcpHead)
                ELSE
                  WOH_RecipeNo := IMPOH_Recipe;
               END;
             END;

         6 : BEGIN
              WOH_FinishWtReqd := IMPOH_FinalWtReq;
              IF CompareWts(WOH_FinishWtReqd, 0.0) <= 0 THEN BREAK;
             END;

         7 : IF IMPOH_MaxMixWt > 0.0 THEN { override recipe mix wt }
               WOH_MaxMixGrossWt := IMPOH_MaxMixWt;

        11 : BEGIN
              IF NOT NowtButSpace(IMPOH_Status) THEN
               BEGIN
                IF Str_Equal(OrdStatStrings[StatusHOLD], IMPOH_Status, 4) THEN
                  WOH_Status := StatusHOLD
                ELSE IF Str_Equal(OrdStatStrings[StatusWIP], IMPOH_Status, 4) THEN
                  WOH_Status := StatusWIP
                ELSE
                  BREAK; { invalid status in csv file }
               END;
             END;

        12 : IF NOT NowtButSpace(IMPOH_Work_Group) THEN
               WOH_WorkGroup := IMPOH_Work_Group;

        13 : IF IMPOH_Release_No > 0 THEN
               WOH_Release := IMPOH_Release_No;

        14 : IF IMPOH_Custom_Num1 > 0 THEN
               WOH_Custom_Num1 := IMPOH_Custom_Num1;

        15 : IF NOT NowtButSpace(IMPOH_Custom_Alpha1) THEN
               WOH_Custom_Alpha1 := IMPOH_Custom_Alpha1;

        16 : IF NOT NowtButSpace(IMPOH_Custom_Alpha2) THEN
               WOH_Custom_Alpha1 := IMPOH_Custom_Alpha2;
        END;
      END;

     IF FieldNo > LAST_FIELD THEN
       LoadORecHeader := TRUE
     ELSE
       ErrorLog^.WriteErrorTS('Invalid '+FieldName(FieldNo)+' (field '+
                              IntToStr(FieldNo,1)+
                              ') in line '+
                              IntToStr(ImportFile^.GetLineNum,1)+': '+
                              ImportFile^.LineText);
    END;
  END;


  FUNCTION LoadORecLine : BOOLEAN;
  VAR
     FieldNo : INTEGER;
  BEGIN
   LoadORecLine := FALSE;
   WITH ORec^.WO_Lines[LinePos]^, ImpOrdLine DO
    BEGIN
     FieldNo := 0;
     WHILE FieldNo <= LAST_FIELD DO
      BEGIN
       Inc(FieldNo);
       CASE FieldNo OF
         8 : BEGIN { Ingred_Code }
              IF NowtButSpace(IMPOL_Ingredient) THEN
                BREAK { compulsory field missing }
               {*****}
              ELSE IF IFile^.GetIngredient(IMPOL_Ingredient,
                                           IRec,FALSE) <> 0 THEN
                BREAK { ingredient doesnt exist }
               {*****}
              ELSE
                PrimeWOLineForIngredient(ORec^.WO_Lines[LinePos]^,
                                         IRec);
             END;
         9 : BEGIN { Ingred_Finish_Wt}
              IF CompareWts(IMPOL_IngredientReq,0.0) <= 0 THEN
                BREAK
               {*****}
              ELSE
                WOL_Ratio := IMPOL_IngredientReq * 100 / ORec^.WO_Header.WOH_FinishWtReqd;
             END;
        10 : BEGIN { Ingred_Container_Wt }
              IF CompareWts(IMPOL_ContainerSize, 0.0) > 0 THEN
                WOL_ContainerSize   := IMPOL_ContainerSize;
             END;
        17 : BEGIN {Ingred_Tol_NegPercent}
              IF CompareWts(IMPOL_Tol_NegPercent,0.0) >= 0 THEN { (0.0 is ok) }
                WOL_LowTol := IMPOL_Tol_NegPercent;
             END;
        18 : BEGIN {Ingred_Tol_PosPercent}
              IF CompareWts(IMPOL_Tol_PosPercent,0.0) >= 0 THEN { (0.0 is ok) }
                WOL_HighTol := IMPOL_Tol_PosPercent;
             END;
        19 : BEGIN {Ingred_Spec_Instruct1}
              IF NOT NowtButSpace(IMPOL_Spec_Instruct1) THEN
                WOL_SpecialInstr[1] := IMPOL_Spec_Instruct1;
             END;
        20 : BEGIN {Ingred_Spec_Instruct2}
              IF NOT NowtButSpace(IMPOL_Spec_Instruct2) THEN
                WOL_SpecialInstr[2] := IMPOL_Spec_Instruct2;
             END;
        21 : BEGIN {Ingred_Mixing_Yield}
              IF CompareWts(IMPOL_Mixing_Yield,0.0) > 0 THEN
                WOL_Yield := IMPOL_Mixing_Yield;
             END;
        22 : BEGIN {Ingred_Is_Key}
              IF NOT NowtButSpace(IMPOL_Keyingredient) THEN
               BEGIN
                CASE IMPOL_Keyingredient[1] OF
                  'Y' : WOL_KeyIngredient := TRUE;
                  'N' : BEGIN END;
                  ELSE  BREAK; { invalid char }
                 END;
               END;
             END;
        END;
      END;

     IF FieldNo > LAST_FIELD THEN
       LoadORecLine := TRUE
     ELSE
       ErrorLog^.WriteErrorTS('Invalid '+FieldName(FieldNo)+' (field '+
                              IntToStr(FieldNo,1)+
                              ') in line '+
                              IntToStr(ImportFile^.GetLineNum,1)+': '+
                              ImportFile^.LineText);
    END;
  END;


  FUNCTION CommitCurrentOrder : BOOLEAN;
  VAR
     OrigRec : PWOrderObject;
     FileError : INTEGER;
     i : INTEGER;
  BEGIN
   CommitCurrentOrder := FALSE;

   IF NOT CurrOrdIsValid THEN
     EXIT;
    {****}

   New(OrigRec, Init);
   OrigRec^.WO_Header.WOH_OrderNo  := ORec^.WO_Header.WOH_OrderNo;
   OrigRec^.WO_Header.WOH_Revision := ORec^.WO_Header.WOH_Revision;
   FileError := WOFile^.ReadAllRecords('EQ',TRUE,FALSE,OrigRec,1);
   IF FileError = 0 THEN
    BEGIN
     WITH OrigRec^.WO_Header DO
      BEGIN
       IF CompareWts(WOH_WtDoneGross,0.0) > 0 THEN
        BEGIN
         WOFile^.HeaderFile^.Unlock_Single;
         ErrorLog^.WriteErrorTS('Unable To Update Recipe Order'+
                                IntToZeroStr(WOH_OrderNo,6)+'/'+
                                IntToZeroStr(WOH_Revision,2)+
                                ', Production Already Started');
         FileError := 0; { clear error flag for handler below }
        END
       ELSE
        BEGIN
         { prepare rec for deleting all line recs then adding new ones }
         FOR i := 1 TO MAX_LINES_ON_RECORD DO
           WOFile^.DeleteLineRec(OrigRec,1); { keep marking first line
                                            as deleted in re-shuffling list }

         FOR i := 1 TO MAX_LINES_ON_RECORD DO
          BEGIN
           IF Assigned(ORec^.WO_Lines[i]) THEN { copy line into orig rec }
            BEGIN
             NEW(OrigRec^.WO_Lines[i]);
             OrigRec^.WO_Lines[i]^ := ORec^.WO_Lines[i]^;
            END;
          END;
         FileError := WOFile^.UpdateRecord(OrigRec);
        END;
      END;
    END
   ELSE IF FileError = BNoRecord THEN
     FileError := WOFile^.AddRecord(ORec);

   IF FileError = 0 THEN
     CommitCurrentOrder := TRUE
   ELSE
    BEGIN
     ErrorLog^.WriteErrorTS('Btrieve Error: '+
                            IntToStr(FileError,1)+
                            ' Adding/Amending Order '+
                            IntToZeroStr(ORec^.WO_Header.WOH_OrderNo,6)+'/'+
                            IntToZeroStr(ORec^.WO_Header.WOH_Revision,2));
     FailImport := TRUE;
    END;
   Dispose(OrigRec, Done);
  END;


BEGIN
 WOFile^.OpenFile;
 RcpFile^.OpenFile;
 IFile^.OpenFile;
 LinePos    := 1;                                 { Init Order Line Count   }
 FailImport := FALSE;
 CurrOrdIsValid := FALSE;{ only gets switched on by result of LoadORecHeader() }

 ErrorLog^.WriteErrorTS('Processing File :'+ImportFile^.FileName);

 ImpFileErr := ImportFile^.FetchLine;
 WHILE (ImpFileErr = err_none) DO
  BEGIN                                          { While CSV Records Found }
   Presenter^.Refresh;
   IF NOT ParseCSVLine(NextImpOrdHead, ImpOrdLine) THEN
     CurrOrdIsValid := FALSE;

   { Does Line relate to a different Order? }
   IF (NextImpOrdHead.IMPOH_No       <> CurrImpOrdhead.IMPOH_No)
   OR (NextImpOrdHead.IMPOH_NoSuffix <> CurrImpOrdhead.IMPOH_NoSuffix) THEN
    BEGIN
     CommitCurrentOrder;
     CurrOrdIsValid := FALSE;

     Move(NextImpOrdHead, CurrImpOrdHead, SizeOf(CurrImpOrdHead));

     { initialise ORec for a new order import }
     LinePos := 1;
     ORec^.ClearLines;                   { Clear Order Lines       }
     ORec^.Init;                         { Init Order Record       }
     CurrOrdIsValid := LoadORecHeader;
    END
   ELSE { line is related to current order }
    BEGIN
     IF  CurrOrdIsValid
     AND (MemCompare(NextImpOrdHead, CurrImpOrdHead,
                  SizeOf(CurrImpOrdHead)) <> 0) THEN
      BEGIN
       {CurrOrdIsValid := FALSE; }
       FailImport := TRUE; { so file can be inspected }
       ErrorLog^.WriteErrorTS('Warning: Inconsistent Order Header details in Line'+
                              IntToStr(ImportFile^.GetLineNum,1)+': '+
                              ImportFile^.LineText);
      END;
    END;

   { add ingredient to ORec }
   IF  CurrOrdIsValid
   AND (LinePos > MAX_LINES_ON_RECORD) THEN
    BEGIN
     CurrOrdIsValid := FALSE;
     ErrorLog^.WriteErrorTS('Order '+
                            IntToZeroStr(CurrImpOrdHead.IMPOH_No,6)+'/'+
                            IntToZeroStr(CurrImpOrdHead.IMPOH_NoSuffix,2)+
                            ' cannot fit line: '+ImportFile^.LineText);
    END;


   IF CurrOrdIsValid THEN
    BEGIN
     NEW(ORec^.WO_Lines[LinePos]);
     WOFile^.LineFile^.InitRecord(ORec^.WO_Lines[LinePos]^);
     WITH ORec^.WO_Lines[LinePos]^ DO
      BEGIN
       WOL_OrderNo         := ORec^.WO_Header.WOH_OrderNo;
       WOL_Revision        := ORec^.WO_Header.WOH_Revision;
       WOL_LineNo          := LinePos;
      END;
     IF LoadORecLine THEN
       Inc(LinePos)
     ELSE
       CurrOrdIsValid := FALSE;
    END;

   IF NOT CurrOrdIsValid THEN FailImport := TRUE;
   ImpFileErr := ImportFile^.FetchLine;
  END; { END (WHILE) }

 IF ImpFileErr IN [err_none, err_end_of_file] THEN
   CommitCurrentOrder
 ELSE
   FailImport := TRUE;

 IF FailImport THEN
  BEGIN
   SubPath := 'FAILED';
   IF NOT Exist(ImportPath+SubPath) THEN
    BEGIN
{$I-}
     MkDir(ImportPath+SubPath);
{$I+}
     IF IOResult <> 0 THEN BEGIN END;
    END;
   DErr := ImportFile^.RenameFile(ImportPath+SubPath+'\'+SR.Name);
   IF DErr <> 0 THEN
     ErrorLog^.WriteErrorTS('DOS Error '+IntToStr(DErr,1)+
                            ' renaming import file to '+
                            ImportPath+SubPath+SR.Name);
  END
 ELSE
  BEGIN
   ImportFile^.DeleteFile;
  END;
 RcpFile^.CloseFile;
 IFile^.CloseFile;
 WOFile^.CloseFile;
END;



PROCEDURE TCSVOrderImport.Run;
BEGIN


  FindFirst(ImportPath+'*.RCP',AnyFile,SR);
  WHILE (DosError = 0) DO
   BEGIN
    ImportFile := NIL;
    ImportFile := NEW(PCSVFileImporter,Init(Importpath+SR.Name));
    IF ImportFile^.OpenFile = 0 THEN
     BEGIN
      Presenter := NIL;
      Presenter := NEW(PCSVFileImporterPresenter, Init(ImportFile));
      ProcessImportFile;
      IF Assigned(Presenter) THEN Dispose(Presenter,Done);
     END
    ELSE
     BEGIN
      (* LOG EXCEPTION HERE *)
     END;
    IF Assigned(ImportFile) THEN Dispose(ImportFile,Done);
    FindNext(SR);
   END
END;


PROCEDURE TimedOrderImport;
VAR Importer : PCSVOrderImport;
BEGIN
 Importer := NEW(PCSVOrderImport,Init(Config_Rec^.Conf_ImpPath));
 Importer^.Run;
 Dispose(Importer,Done);
END;


END.
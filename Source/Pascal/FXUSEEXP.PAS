{$O+,F+}
{$I F6COMP}
UNIT FXUSEEXP;

INTERFACE

USES F6STDCTV,F6STDUTL,FXMODCTV,F6BTRV,F6DTCONV,FILEOBJ,FXFTRN,FXTFLOG,
     FXCFG,FXFINI,FXTIME;


TYPE PUseageRecord = ^TUsageRecord;
     TUsageRecord = PACKED RECORD
      IU_Date             : LONGINT;                {0.0}
      IU_Mid              : WORD;                   {0.1}
      IU_Ingredient       : TIngredientRef;         {0.2}
      IU_Quantity         : LONGINT;
      IU_Weight           : DOUBLE;
      IU_LotNo            : TLotRef;
     END;

     PUseFile = ^TUseFile;
     TUseFile = Object(TBtrvFileObject)
       PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
       FUNCTION   GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
     END;



TYPE PIngredientUseExport = ^TIngredientUseExport;
     TIngredientUseExport = OBJECT
       FileGenNumber : STRING[8];
       FileName      : STRING[12];
       CompanyNo     : STRING[2];
       FileGenNo     : STRING[8];
       SerFile       : FILE;
       URec          : TUsageRecord;
       TRec          : TTranRecord;
       TFile         : PTransFile;
       UFile         : PUseFile;
       ExpFile       : PTextFileLogger;
       ErrLog        : PTextFileLogger;

       CONSTRUCTOR Init;
       DESTRUCTOR  Done;
       FUNCTION    NextFileGenNumber : STRING;
       PROCEDURE   GetStockRoomCodes(    Mid : WORD;
                                     VAR FromStockRoom : STRING;
                                     VAR ToStockRoom   : STRING);

       PROCEDURE   Run;
     END;


PROCEDURE ScheduleTimedIngredientUseExport;
PROCEDURE StopTimedIngredientUseExport;


IMPLEMENTATION


PROCEDURE  TUseFile.InitRecord     (VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TUsageRecord),#0);
 WITH TUsageRecord(RecBuff) DO
  BEGIN
   IU_Ingredient     := SPACE_STRING;
   IU_LotNo          := SPACE_STRING;
  END;
END;

FUNCTION   TUseFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TUsageRecord);
   Page_Size := 4096;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   {0.0 transaction date}
   INC(SegC,Set_Key(Key_Buf[0],1,04,K_EXTTYPE OR K_SEGMENTED,
   EKT_INTEGER,0));

   {0.1 MachineID}
   INC(SegC,Set_Key(Key_Buf[1],5,02,K_EXTTYPE OR K_SEGMENTED,
   EKT_INTEGER,0));

   {0.2 Ingredient}
   INC(SegC,Set_Key(Key_Buf[2],7,09,K_EXTTYPE OR K_SEGMENTED,
   EKT_LSTRING,0));

   {0.3 Lot Number}
   INC(Segc,Set_Key(Key_Buf[3],16,09,K_EXTTYPE,
   EKT_LSTRING,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;






CONSTRUCTOR TIngredientUseExport.Init;
BEGIN
 TFile   := NIL;
 UFile   := NIL;
 ExpFile := NIL;
 ErrLog  := NIL;

 ErrLog  := NEW(PTextFileLogger,Init(Config_Rec^.Conf_RPath+'IUExport.RPT',''));

 { Create Instance For temporary Ingredient Usage File }
 UFile := NEW(PUseFile,Init(Config_Rec^.Conf_RPath+'MOV.$$$'));
 IF  (UFile <> NIL)
 AND (UFile^.Create <> 0) THEN { creates new file over existing file - if closed }
  BEGIN
   ErrLog^.WriteErrorTS('Unable To Create MOV.$$$, Error:'+
                        IntToStr(UFile^.BtrvErr,3));
   Dispose(UFile, Done);
   UFile := NIL;
  END;

 IF (UFile <> NIL) THEN { mov.$$$ exists }
  BEGIN
   FileGenNumber := NextFileGenNumber;
   FileName := FileGenNumber+'.MOV';

   TFile := NEW(PTransFile,Init(Config_Rec^.Conf_FPath+Transaction_FileName));

   ExpFile := NEW(PTextFileLogger,Init(Config_Rec^.Conf_EPath+FileName,''));


   CompanyNo := GetExtVar(FXCompanyNo,all) + SPACE_STRING;
  END;
END;

DESTRUCTOR TIngredientUseExport.Done;
BEGIN
 IF Assigned(ErrLog)  THEN Dispose(ErrLog,Done);
 IF Assigned(ExpFile) THEN Dispose(ExpFile,Done);
 IF Assigned(UFile)   THEN Dispose(UFile,Done);
 IF Assigned(TFile)   THEN Dispose(TFile,Done);
END;



FUNCTION TIngredientUseExport.NextFileGenNumber : STRING;
VAR SerStr       : STRING[8];
    SerNum       : LONGINT;
    FileErr      : INTEGER;
    ErrCode      : INTEGER;
    SaveFileMode : INTEGER;


 PROCEDURE WriteSerialNumber;
 BEGIN
   SerStr := IntToZeroStr(SerNum,8);
   {$I-}
   Seek(SerFile,0);
   {$I+}
   FileErr := IOResult;
   {$I-}
   BlockWrite(SerFile,SerStr[1],Length(SerStr),ErrCode);
   {$I+}
   FileErr := IOResult;
 END;

BEGIN
 SaveFileMode := FileMode;
 FileMode     := READ_WRITE OR DENY_ALL;

 SerNum := 1;
 Assign(SerFile,Config_Rec^.Conf_FPath+'JBA_SER.FIL');
 {$I-}
 Reset(SerFile,1);
 {$I+}
 FileErr := IOResult;
 IF FileErr <> 0 THEN
  BEGIN
   {$I-}
   ReWrite(SerFile,1);
   {$I+}
   FileErr := IOResult;
   WriteSerialNumber;
  END
 ELSE
  BEGIN
   {$I-}
   BlockRead(SerFile,SerStr[1],8,ErrCode);
   {$I+}
   FileErr := IOResult;
   IF FileErr = 0 THEN
    BEGIN
     SerStr[0] := #8;
     VAL(SerStr,SerNum,ErrCode);
     IF SerNum = 99999999 THEN SerNum := 0;
     INC(SerNum);
     WriteSerialNumber;
    END;
  END;
  {$I-}
  Close(SerFile);
  {$I+}

  FileMode := SaveFileMode;
  NextFileGenNumber := SerStr;
END;


PROCEDURE TIngredientUseExport.GetStockRoomCodes(    Mid : WORD;
                                                 VAR FromStockRoom : STRING;
                                                 VAR ToStockRoom   : STRING);
VAR TheINIVar  : INIVAR;
    ResultStr  : STRING;
    Seperator  : BYTE;
BEGIN
 FromStockRoom := '  ';
 ToStockRoom   := '  ';

 TheIniVar.V := 'FXMIDLOCATION'+IntToZeroStr(Mid,2);
 TheIniVar.S := main;

 ResultStr := GetExtVar(TheINIVar,all);
 Seperator := POS(',',ResultStr);
 IF (Seperator > 0) THEN
  BEGIN
   ToStockRoom   := COPY(ResultStr,Seperator+1,2);
   IF Seperator > 3 THEN Seperator := 3;
   FromStockRoom := COPY(ResultStr,1,Seperator-1);
  END
 ELSE
  BEGIN
   FromStockRoom := COPY(ResultStr,1,2);
   ToStockRoom   := COPY(ResultStr,1,2);
  END;
 FromStockRoom   := COPY(FromStockRoom+SPACE_STRING,1,2);
 ToStockRoom     := COPY(ToStockRoom+SPACE_STRING,1,2);
END;



PROCEDURE TIngredientUseExport.Run;
VAR ExportDate     : LONGINT;
    ExportRec      : STRING;
    UpdateURec     : BOOLEAN;
    DateStr        : STRING[6];
    Century        : CHAR;
    Year,Month,Day : LONGINT;
    LastMid        : WORD;
    FromStockRoom,
    ToStockRoom    : STRING[2];
BEGIN
  IF UFile = NIL THEN
    EXIT;
   {****}

  ExportDate := Date_To_Days(Date) -1;

  ErrLog^.WriteErrorTS('Start Export For '+Days_To_Date(ExportDate)+' '+
                       FileName);

  IF (UFile^.OpenFile = 0) AND
     (TFile^.OpenFile = 0) THEN
   BEGIN

    TFile^.InitRecord(TRec);
    TRec.TRN_Date := ExportDate;
    TFile^.ReadRecord('GE',FALSE,FALSE,TRec,0);
    WHILE (TFile^.BtrvErr = 0) DO
     BEGIN
      { DispSpin }
      IF TRec.TRN_Date > ExportDate THEN Break;  { Past Key                }

      UFile^.InitRecord(URec);

      WITH URec,TRec DO
       BEGIN
        IU_Date       := TRN_Date;
        IU_Mid        := TRN_Mid;
        IU_Ingredient := TRN_Ingredient+SPACE_STRING;
        IU_LotNo      := TRN_LotNo+SPACE_STRING;

        UpdateURec    := (UFile^.ReadRecord('EQ',FALSE,FALSE,URec,0) = 0);

        IU_Quantity   := IU_Quantity + 1;
        IU_Weight     := IU_Weight   + TRN_ActualWeight;

        IF UpdateURec THEN
          UFile^.UpdateRecord(URec)
        ELSE
          UFile^.AddRecord(URec);
       END;
      TFile^.ReadRecord('GN',FALSE,FALSE,TRec,0);
     END;
    TFile^.CloseFile;


    { Produce Export File From Built Usage File }
    LastMid := 65535;
    UFile^.InitRecord(URec);
    URec.IU_Date := ExportDate;
    UFile^.ReadRecord('GE',FALSE,FALSE,URec,0);
    WHILE (UFile^.BtrvErr = 0) DO
     BEGIN
      {DispSpin; }
      IF URec.IU_Date > ExportDate THEN Break;


      IF URec.IU_Mid <> LastMid THEN
        GetStockRoomCodes(URec.IU_Mid,FromStockRoom,ToStockRoom);

      DateStr := Days_To_YYMMDD(URec.IU_Date);

      Days_To_YMD(URec.IU_Date,Year,Month,Day);
      Century := '0';
      IF Year > 1999 THEN Century :='1';

      ExportRec := COPY(CompanyNo,1,2) +
                   FileGenNumber +
                   FromStockRoom +
                   ToStockRoom   +
                   COPY(URec.IU_Ingredient,1,6) +
                   '         '   +
                   IntToZeroStr(URec.IU_Quantity,7) +'.000' +
                   DoubleToZeroStr(URec.IU_Weight,11,3) +
                   Century+DateStr+
                   '000000' +
                   COPY(URec.IU_LotNo+SPACE_STRING,1,15) +
                   'Production    '+
                   'Production          ';

      ExpFile^.WriteError(ExportRec);

      UFile^.ReadRecord('GN',FALSE,FALSE,URec,0);
     END; { END (WHILE) }
    UFile^.CloseFile;
   END
  ELSE
   BEGIN
    IF UFile^.BtrvErr <> 0 THEN
     BEGIN
      ErrLog^.WriteErrorTS('Unable To Open MOV.$$$, Error:'+
                           IntToStr(UFile^.BtrvErr,3));
     END;
    IF TFile^.BtrvErr <> 0 THEN
     BEGIN
      ErrLog^.WriteErrorTS('Unable To Open Tran File, Error:'+
                           IntToStr(TFile^.BtrvErr,3));

     END;
   END;
END;


PROCEDURE TimedIngredientUseExport;
VAR IUExport : PIngredientUseExport;
BEGIN
 IUExport := NEW(PIngredientUseExport,Init);
 IUExport^.Run;
 Dispose(IUExport,Done);
END;


PROCEDURE ScheduleTimedIngredientUseExport;
VAR Hour,Min : BYTE;
    ErrInt   : INTEGER;
    TempStr  : STRING;
BEGIN
 IF GetExtSwitch(FXDoTimedExport,all,FALSE) THEN
  BEGIN
   TempStr := GetExtVar(FXExportTime,All);
   VAL(Copy(TempStr,1,Pos(':',TempStr)-1), Hour, ErrInt);
   VAL(Copy(TempStr,Pos(':',TempStr)+1,2), Min, ErrInt);
   Schedule_Timed_Event(TimedIngredientUseExport,Hour,Min,TRUE,DAILY);
  END;
END;


PROCEDURE StopTimedIngredientUseExport;
BEGIN
  Cancel_Timed_Event(TimedIngredientUseExport);
END;



END.



(****************************************************************************
*  UNIT          : FXFMIX                                                   *
*  AUTHOR        : N. Spooner                                               *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : FORMIX MIX STORE                                         *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXFMix;
INTERFACE
USES Crt,FILEOBJ,F6BTRV,F6STDCTV,F6STDUTL,FXMODCTV,FXCfg,FXFWork;

CONST
      MixStatus_FileName = 'MIXSTAT.FIL';

TYPE

    PMixStatusRecord = ^TMixStatusRecord;
    TMixStatusRecord = PACKED RECORD
{*}    MIX_OrderNo         : LONGINT;           {01-04} {0.0}
{*}    MIX_Revision        : BYTE;              {05-05} {0.1}
{*}    MIX_No       : WORD;{ INTEGER IN DDF }   {06-07} {0.2}
       MIX_Complete        : BOOLEAN;   {08-08}
       MIX_WtRequired      : DOUBLE;    {09-16}
       MIX_WtDone          : DOUBLE;    {17-24}
       MIX_QAComplete      : BOOLEAN;
       Reserved            : ARRAY[1..7] OF BYTE;   {8 Bytes Reserved}
    END;

{SQL Note:a) PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
          b) Change to Btrieve LString using Control Centre - Edit Table.
SET TRUENULLCREATE=OFF#
CREATE TABLE Mix_Total IN DICTIONARY USING 'MIXSTAT.FIL'
(
Order_No        INTEGER    NOT NULL,
Order_No_Suffix UTINYINT   NOT NULL,
Mix_No          SMALLINT   NOT NULL,
Complete        BIT        NOT NULL,
Weight_Reqd     DOUBLE     NOT NULL,
Weight_Done     DOUBLE     NOT NULL,
QA_Complete     BIT,
Reserved        CHAR(7)    NOT NULL
)#
CREATE UNIQUE NOT MODIFIABLE INDEX ByOrderMix IN DICTIONARY ON
 Mix_Total(Order_No , Order_No_Suffix , Mix_No)#
SET TRUENULLCREATE=ON#
}


    PMixStatusFile = ^TMixStatusFile;
    TMixStatusFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetMixStatRec  (    OrderNo    : LONGINT;
                                     Revision   : BYTE;
                                     MixNo      : WORD;
                                 VAR MixStatRec : TMixStatusRecord;
                                     Lock       : BOOLEAN) : INTEGER; VIRTUAL;
      FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
    END;


VAR MixStatusFile : PMixStatusFile;

PROCEDURE AddWeightToMixRecord   (   ToMixNo     : WORD;
                                     OrdHeader   : PWOHeaderRecord;
                                     OrdLine     : PWOLineRecord;
                                     WeightToAdd : DOUBLE;
                                     IsLastWtForKeyIngredient : BOOLEAN);

PROCEDURE WorkHeaderToMixStatus (VAR OrdHRec : TWOHeaderRecord;
                                 VAR MixStatus : TMixStatusRecord);

PROCEDURE CreateAllMixRecords(OrdHRec : PWOHeaderRecord);

FUNCTION  MixRecordsWithStatCleared(OrdHRec : PWOHeaderRecord) : LONGINT;

FUNCTION  CalcCompensatedBatchMixWt(OrdHRec : PWOHeaderRecord;
                                    ForMixNo: LONGINT) : DOUBLE;

FUNCTION  IsMixComplete         (    MixNo : WORD;
                                     OrderNo : LONGINT;
                                     Revision : BYTE) : BOOLEAN;

FUNCTION  GetMixWtReqdAsLastCalc(MixNo     : LONGINT;
                                 OrdHeader : PWOHeaderRecord) : DOUBLE;

FUNCTION  GetMixWtDone(MixNo     : LONGINT;
                      OrdHeader : PWOHeaderRecord) : DOUBLE;

FUNCTION  GetMixWtDoneOnCurrentMix(OrdHeader : PWOHeaderRecord) : DOUBLE;

FUNCTION  DoMixesExistForOrder   (   OrderNo : LONGINT;
                                     Revision : BYTE) : BOOLEAN;








IMPLEMENTATION

PROCEDURE AddWeightToMixRecord   (   ToMixNo      : WORD;
                                     OrdHeader    : PWOHeaderRecord;
                                     OrdLine      : PWOLineRecord;
                                     WeightToAdd  : DOUBLE;
                                     IsLastWtForKeyIngredient : BOOLEAN);
VAR MixRec : TMixStatusRecord;
BEGIN
 WorkHeaderToMixStatus(OrdHeader^, MixRec);
 MixRec.MIX_No := ToMixNo;

 WITH MixStatusFile^ DO
  BEGIN
   OpenFile;
   IF ReadRecord('EQ',TRUE,FALSE,MixRec,0) = 0 THEN
    BEGIN
     WITH MixRec DO
      BEGIN
       Mix_WtDone := Mix_WtDone + WeightToAdd;
       IF IsLastWtForKeyIngredient THEN { If last weighing for key ingredient }
        BEGIN                           { then adjust target mix weight.      }
         MIX_WtRequired := DivDouble(MIX_WtDone,
                                     CalcLineGrossPortion(OrdHeader,
                                                          OrdLine));
         { round-down to nearest gram                             }
         { to make sure key ingredient recalculates as "complete" }
         MIX_WtRequired := MIX_WtRequired-0.00051;
         MIX_WtRequired := RoundWtToNearestGram(MIX_WtRequired);
        END;
      END;
     UpdateRecord(MixRec);
    END;
   CloseFile;
  END;
END;


FUNCTION GetMixWtReqdAsLastCalc(MixNo     : LONGINT;
                                OrdHeader : PWOHeaderRecord) : DOUBLE;
VAR MixStatus  : TMixStatusRecord;
BEGIN
 WITH MixStatusFile^, OrdHeader^ DO
  BEGIN
   OpenFile;
   GetMixStatRec(WOH_OrderNo,WOH_Revision,MixNo,MixStatus,FALSE);
   GetMixWtReqdAsLastCalc := MixStatus.MIX_WtRequired;
   CloseFile
  END; { WITH }
END;


FUNCTION GetMixWtDone(MixNo     : LONGINT;
                      OrdHeader : PWOHeaderRecord) : DOUBLE;
VAR MixStatus  : TMixStatusRecord;
BEGIN
 WITH MixStatusFile^, OrdHeader^ DO
  BEGIN
   OpenFile;
   GetMixStatRec(WOH_OrderNo,WOH_Revision,MixNo,MixStatus,FALSE);
   GetMixWtDone := MixStatus.MIX_WtDone;
   CloseFile
  END; { WITH }
END;

FUNCTION GetMixWtDoneOnCurrentMix(OrdHeader : PWOHeaderRecord) : DOUBLE;
BEGIN
 GetMixWtDoneOnCurrentMix := GetMixWtDone(OrdHeader^.WOH_CurrentMix,
                                          OrdHeader);
END;


FUNCTION DoMixesExistForOrder(OrderNo : LONGINT;Revision : BYTE) : BOOLEAN;
VAR MixStatus : TMixStatusRecord;
BEGIN
 { IF A MixStatRecord Exists For Order Return True }
 WITH MixStatusFile^ DO
  BEGIN
   OpenFile;
   DOMixesExistForOrder := (GetMixStatRec(OrderNo,Revision,1,MixStatus,FALSE) = 0);
   CloseFile;
  END;                                           {END (WITH MixStatusFile^)}
{ MixStatus.Mix_OrderNo  := OrderNo;
 MixStatus.MIX_Revision := Revision;
 MixStatus.Mix_No       := 1;
 DoMixesExistForOrder := MixStatusFile^.ReadRecord('EQ',FALSE,FALSE,MixStatus,0) =0;
}
END;


FUNCTION  IsMixComplete(MixNo : WORD;OrderNo : LONGINT;Revision : BYTE) : BOOLEAN;
VAR MixStatus  : TMixStatusRecord;
BEGIN
 WITH MixStatusFile^ DO
  BEGIN
   OpenFile;
   GetMixStatRec(OrderNo,Revision,MixNo,MixStatus,FALSE);
{MixStatus.MIX_OrderNo  := OrderNo;
 MixStatus.MIX_Revision := Revision;
 MixStatus.MIX_No       := MixNo;
 MixStatusFile^.ReadRecord('EQ',FALSE,FALSE,MixStatus,0);}
   IF BtrvErr = 0 THEN
     IsMixComplete := MixStatus.MIX_Complete
   ELSE
     IsMixComplete := FALSE;
   CloseFile;
  END;                                           { END (WITH MixStatusFile^) }
END;

FUNCTION CalcCompensatedBatchMixWt(OrdHRec : PWOHeaderRecord;
                                   ForMixNo: LONGINT) : DOUBLE;
{REQUIRES  OrdHRec to be initialised with identification and tot number
           of mixes.
 PROMISES  To return target mix wt that will compensate for weight deviations
           on previous mixes. Currently compensation is only done on last mix.
}
VAR
   MixRec           : TMixStatusRecord;
   RetTargetWt,
   AdjustedTargetWt : DOUBLE;
   ReadErr          : INTEGER;
BEGIN
 RetTargetWt := 0.0;
 WITH MixStatusFile^ DO
  BEGIN
   OpenFile;
   WorkHeaderToMixStatus(OrdHRec^, MixRec);
   MixRec.MIX_No := ForMixNo;
   ReadErr := ReadRecord('EQ',FALSE,FALSE,MixRec,0);
   IF ReadErr = 0 THEN
    BEGIN
     RetTargetWt := MixRec.MIX_WtRequired;


     IF  Config_Rec^.Conf_LastMixCompensation
     AND (OrdHRec^.WOH_MixType <> mt_CampaignWeighing) {Cant have live wts  }
     AND (ForMixNo = OrdHRec^.WOH_NumMixes) { only last mix adjusted - at the moment }
     AND (CompareWts(MixRec.MIX_WtDone,0.0) <= 0) THEN { Target weight free to be adjusted}
      BEGIN                               { for previous batch deviations    }
       AdjustedTargetWt := EstimateGrossWtReqdForMixNo(ForMixNo,OrdHRec);

       { read other mix records to accumulate deviations }
       WorkHeaderToMixStatus(OrdHRec^, MixRec);
       MixRec.MIX_No := 1;
       ReadErr := ReadRecord('GE',FALSE,FALSE,MixRec,0);
       WHILE (ReadErr = 0)
       AND   (MixRec.MIX_OrderNo = OrdHRec^.WOH_OrderNo)
       AND   (MixRec.MIX_Revision= OrdHRec^.WOH_Revision) DO
        BEGIN
         WITH MixRec DO
          BEGIN
           IF  (MIX_No <> ForMixNo) { ignore same mix record }
           AND MIX_Complete THEN { add deviation of previous finished mixes }
             AdjustedTargetWt := AdjustedTargetWt
                                 + EstimateGrossWtReqdForMixNo(MixRec.MIX_No,
                                                               OrdHRec)
                                 - MIX_WtDone;
          END;
         ReadErr := ReadRecord('GN',FALSE,FALSE,MixRec,0);
        END;
       IF AdjustedTargetWt < 0.0 THEN
         AdjustedTargetWt := 0.0;
       AdjustedTargetWt := RoundWtToNearestGram(AdjustedTargetWt);

       { now update mix record with new target wt }
       IF AdjustedTargetWt <> RetTargetWt THEN
        BEGIN
         WorkHeaderToMixStatus(OrdHRec^, MixRec);
         MixRec.MIX_No := ForMixNo;
         IF ReadRecord('EQ',TRUE,FALSE,MixRec,0) = 0 THEN
          BEGIN
           IF (CompareWts(MixRec.MIX_WtDone,0.0) <= 0) THEN { still hasnt been started }
            BEGIN
             MixRec.MIX_WtRequired := AdjustedTargetWt;
             IF UpdateRecord(MixRec) = 0 THEN
               RetTargetWt := MixRec.MIX_WtRequired;
            END
           ELSE { mix has been started now }
            BEGIN
             Unlock_Single;
             RetTargetWt := MixRec.MIX_WtRequired;
            END;
          END;
        END;
      END;
    END;
   CloseFile;
  END;

 CalcCompensatedBatchMixWt := RetTargetWt;
END;


PROCEDURE CreateAllMixRecords(OrdHRec : PWOHeaderRecord);
VAR I          : INTEGER;
    MixStatus  : TMixStatusRecord;
    Update     : BOOLEAN;
BEGIN
 MixStatusFile^.OpenFile;
 I := 0;
 WHILE (I < OrdHRec^.WOH_NumMixes) DO
  BEGIN
   INC(I);
   WorkHeaderToMixStatus(OrdHRec^,MixStatus);
   MixStatus.MIX_No         := I;
   Update := MixStatusFile^.ReadRecord('EQ',TRUE,FALSE,MixStatus,0)=0;
   IF (NOT Update) OR (MixStatus.MIX_WtDone = 0.0) THEN
    BEGIN
     MixStatus.MIX_Complete   := FALSE;
     MixStatus.MIX_WtDone     := 0;
     MixStatus.MIX_WtRequired := EstimateGrossWtReqdForMixNo(I,OrdHRec);
    END;

   IF Update THEN
    MixStatusFile^.UpdateRecord(MixStatus)
   ELSE
    MixStatusFile^.AddRecord(MixStatus);

  END;

 MixStatus.MIX_No := OrdHRec^.WOH_NumMixes+1;
 {Delete Any Rogue Records That Were Created And Then Order Was Modified}
 MixStatusFile^.ReadRecord('GE',TRUE,FALSE,MixStatus,0);
 WHILE (MixStatusFile^.BtrvErr = 0) AND
       (MixStatus.MIX_OrderNo = OrdHRec^.WOH_OrderNo) AND
       (MixStatus.MIX_Revision = OrdHRec^.WOH_Revision) DO
  BEGIN
   MixStatusFile^.DeleteRecord;
   MixStatusFile^.ReadRecord('GN',FALSE,FALSE,MixStatus,0);
  END;
 MixStatusFile^.Unlock_Single;
 MixStatusFile^.CloseFile;
END;


FUNCTION MixRecordsWithStatCleared(OrdHRec : PWOHeaderRecord) : LONGINT;
VAR
   MixRec : TMixStatusRecord;
   NoOfRecs : LONGINT;
BEGIN
 NoOfRecs := 0;
 WorkHeaderToMixStatus(OrdHRec^,MixRec);
 MixRec.MIX_No := 0;

 MixStatusFile^.OpenFile;
 MixStatusFile^.ReadRecord('GE',TRUE,FALSE,MixRec,0);
 WHILE (MixStatusFile^.BtrvErr = 0)
 AND   (MixRec.MIX_OrderNo  = OrdHRec^.WOH_OrderNo)
 AND   (MixRec.MIX_Revision = OrdHRec^.WOH_Revision) DO
  BEGIN
   MixRec.MIX_Complete := FALSE;
   IF MixStatusFile^.UpdateRecord(MixRec) = 0 THEN
     Inc(NoOfRecs);
   MixStatusFile^.ReadRecord('GN',FALSE,FALSE,MixRec,0);
  END;
 MixStatusFile^.Unlock_Single;
 MixStatusFile^.CloseFile;
 MixRecordsWithStatCleared := NoOfRecs;
END;


PROCEDURE WorkHeaderToMixStatus(VAR OrdHRec : TWOHeaderRecord;VAR MixStatus : TMixStatusRecord);
BEGIN
 FillChar(MixStatus,Sizeof(MixStatus),0);
 MixStatus.MIX_OrderNo  := OrdHRec.WOH_OrderNo;
 MixStatus.MIX_Revision := OrdHRec.WOH_Revision;
 MixStatus.MIX_No       := OrdHRec.WOH_CurrentMix;
END;

PROCEDURE TMixStatusFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(Recbuff,SizeOf(TMixStatusRecord),#0);
 WITH TMixStatusRecord(RecBuff) DO
  BEGIN
  END;
END;


FUNCTION TMixStatusFile.GetMixStatRec(    OrderNo    : LONGINT;
                                          Revision   : BYTE;
                                          MixNo      : WORD;
                                      VAR MixStatRec : TMixStatusRecord;
                                          Lock       : BOOLEAN) : INTEGER;
BEGIN
 InitRecord(MixStatRec);
 MixStatRec.MIX_OrderNo  := OrderNo;
 MixStatRec.MIX_Revision := Revision;
 MixStatRec.MIX_No       := MixNo;
 GetMixStatRec := ReadRecord('EQ',Lock,FALSE,MixStatRec,0);
END;


FUNCTION TMixStatusFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TMixStatusRecord);
   Page_Size := 1024;
   File_Flags:= 0;
   Ndx_Cnt   := 1;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.1 Order Nubmer       }
   INC(SegC,Set_Key(Key_Buf[0],01,04,K_EXTTYPE OR K_SEGMENTED,EKT_INTEGER,0));
   { 0.2 Revision}
   INC(SegC,Set_Key(Key_Buf[1],05,01,K_EXTTYPE OR K_SEGMENTED,EKT_STRING,0));
   { 0.3 Mix No}
   INC(SegC,Set_Key(Key_Buf[2],06,02,K_EXTTYPE,EKT_INTEGER,0));
                                               { Leave this as integer to
                                                 avoid file conversion }
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

END.

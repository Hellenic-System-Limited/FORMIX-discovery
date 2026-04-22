(****************************************************************************
*  UNIT          : FXFWORK                                                  *
*  AUTHOR        : N. Spooner / S. Wright                                   *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : FORMIX RECIPE ORDER FILE                                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FxFWork;
INTERFACE
USES Crt,FILEOBJ,F6BTRV,F6STDCTV,F6STDUTL,F6DTCONV,FXFIngr,FXMODCTV,FXCfg,FXFRcp,
     F6StdWn1,FXCombFl,FXFTrn,FXFSerNo,SFXStd;

CONST WOHeader_File_Name = 'WOHeader.FIL';
      WOLine_File_Name   = 'WOLine.Fil';

CONST StatusColour : ARRAY [0..2] OF BYTE = (LightBlue,White,Cyan);

      {Order Stat Constants}
TYPE TStatusType = (StatusHOLD,StatusWIP,StatusCOMP);

CONST
     OrdStatStrings : ARRAY[Low(TStatusType)..High(TStatusType)] OF
                      TListBoxString = ('HOLD', 'WIP ', 'COMP');



TYPE PWOHeaderRecord = ^TWOHeaderRecord;
     TWOHeaderRecord = PACKED RECORD                    {Keys}
       WOH_OrderNo      : LONGINT;         {01-04}  {0.1 1.0 }
       WOH_Revision     : BYTE; { may have been, but is now an order no suffix }      {05-05}  {0.2 1.1 }
       WOH_RecipeNo     : TRecipeRef;      {06-14}
       WOH_SchDate      : LONGINT;         {15-18}  {0.0 }
       WOH_Status       : TStatusType;
       WOH_MixType      : TMixType;
       WOH_FinishWtReqd : DOUBLE;     {Total Net(finished) Weight of order}
       WOH_MaxMixGrossWt: DOUBLE;  {maximum amount of one mix (GROSS }
       WOH_WorkGroup    : TWorkGrp;
       WOH_Release      : INTEGER;
       WOH_Custom_Num1  : INTEGER;    {available to users}
       WOH_MixDone      : WORD;       {number of mixes done}
       WOH_Custom_Alpha1: STRING[7];  {available to users}
       WOH_CurrentMixWtXXX : DOUBLE;  {OBSOLETE weight done on current mix}
       WOH_SeqFixed     : BOOLEAN;
       WOH_UpdateCount  : LONGINT;
       WOH_NumCases     : LONGINT; { when WOH_SelectByCase is TRUE }
       WOH_CaseWt       : DOUBLE;  { when WOH_SelectByCase is TRUE }
       WOH_SelectByCase : BOOLEAN; { requirement is based on cases no weight }
       WOH_TotIngredWtReqd  : DOUBLE;
       WOH_CurrentMix   : WORD;   {Mix Currently Working On}
       WOH_NumMixes     : WORD;   {Total Number Of Mixes Required}
       WOH_WtDoneGross  : DOUBLE; {total ingredient wt done }
       WOH_AutoBatNoOffset: LONGINT; { first 4 digits of batch X 100 }
       WOH_Custom_Alpha2: STRING[10];
       Reserved         : ARRAY[1..19] OF BYTE;
     END;

{SQL  Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

SET TRUENULLCREATE=OFF#
CREATE TABLE Order_Header IN DICTIONARY USING 'WOHEADER.FIL'
(
Order_No        INTEGER    NOT NULL,
Order_No_Suffix UTINYINT   NOT NULL,
Recipe_No       VARCHAR(8) NOT NULL,
Schedule_Date   INTEGER    NOT NULL,
Status          UTINYINT   NOT NULL,
Mix_Method      UTINYINT   NOT NULL,
Finish_Wt_Reqd  DOUBLE     NOT NULL,
Max_Mix_Wt      DOUBLE     NOT NULL,
Work_Group      VARCHAR(3) NOT NULL,
Release_No      SMALLINT   NOT NULL,
Custom_Num1     SMALLINT   NOT NULL,
Mixes_Done      USMALLINT  NOT NULL,
Custom_Alpha1   VARCHAR(7) NOT NULL,
Reserved3       CHAR(8)    NOT NULL,
Fixed_Sequence  BIT        NOT NULL,
Updates         INTEGER    NOT NULL,
No_Of_Batches   INTEGER    NOT NULL,
Std_Batch_Wt    DOUBLE     NOT NULL,
Work_To_Batches BIT        NOT NULL,
Tot_Weight_Reqd DOUBLE     NOT NULL,
Current_Mix     USMALLINT  NOT NULL,
Mixes_Reqd      USMALLINT  NOT NULL,
Tot_Weight_Done DOUBLE     NOT NULL,
AutoBatchOffset INTEGER    NOT NULL,
Custom_Alpha2   VARCHAR(10) NOT NULL,
Reserved        CHAR(19)   NOT NULL
)#
CREATE UNIQUE INDEX ByDateOrder IN DICTIONARY ON
 Order_Header(Schedule_Date , Order_No , Order_No_Suffix)#
CREATE UNIQUE INDEX ByOrder IN DICTIONARY ON
 Order_Header(Order_No , Order_No_Suffix)#
SET TRUENULLCREATE=ON#
}

    PWOLineRecord = ^TWOLineRecord;
    TWOLineRecord = PACKED RECORD
       WOL_UniqueRef       : LONGINT;          {1.0}
{*}    WOL_OrderNo         : LONGINT;          {0.0}
{*}    WOL_Revision        : BYTE;
{*}    WOL_LineNo          : LONGINT;          {0.1}
       WOL_Ingredient      : TIngredientRef;
       WOL_KeyIngredient   : BOOLEAN;
       WOL_Ratio           : DOUBLE;
       WOL_ContainerSize   : DOUBLE;
{*}    WOL_MixContDoneXXX  : INTEGER;    { weighings done for current mix }
{*}    WOL_ContainerWtDoneXXX : DOUBLE;  {OBSOLETE}

(*     WOL_MixWtDoneXXX    : DOUBLE;     { weight done for current mix}     *)
(*     Replaced WOL_MixWtDoneXXX With WOL_LowTol                            *)
       WOL_LowTol          : DOUBLE; {Low Tolerance Threshold Copied from Recipe}

(*     WOL_WeightDoneXXX   : DOUBLE;     {OBSOLETE}                         *)
(*     Replaced WOL_WeightDonwXXX With WOL_HighTol                          *)
       WOL_HighTol         : DOUBLE; {High Tolerance Threshold Copied from Recipe}

       WOL_SpecialInstr    : ARRAY[1..2] OF STRING[30];
       WOL_TotalWtDone     : DOUBLE;      {Total Wt Done Over All Mixes}
       WOL_TotalContDone   : WORD;        {Total weighings over all mixes}
       WOL_Yield           : DOUBLE;
       WOL_ProcessType     : TProcessTypes;
       WOL_FixedWt         : DOUBLE;
       Reserved            : ARRAY[1..13] OF BYTE;
    END;

{SQL  Note: PervasiveSQL Engine will default VARCHARs to Btrieve ZStrings
            Change to Btrieve LString using Control Centre - Edit Table.

SET TRUENULLCREATE=OFF#
CREATE TABLE Order_Line IN DICTIONARY USING 'WOLINE.FIL'
(
FileRef         INTEGER    NOT NULL,
Order_No        INTEGER    NOT NULL,
Order_No_Suffix UTINYINT   NOT NULL,
Line_No         INTEGER    NOT NULL,
Ingredient      VARCHAR(8) NOT NULL,
Key_Line        BIT        NOT NULL,
Final_Percent   DOUBLE     NOT NULL,
Container_Wt    DOUBLE     NOT NULL,
Reserved1       CHAR(2)    NOT NULL,
Reserved2       CHAR(8)    NOT NULL,
Tol_NegPercent  DOUBLE     NOT NULL,
Tol_PosPercent  DOUBLE     NOT NULL,
Spec_Instruct1  VARCHAR(30) NOT NULL,
Spec_Instruct2  VARCHAR(30) NOT NULL,
Tot_Weight_Done DOUBLE     NOT NULL,
Tot_Trans_Done  USMALLINT  NOT NULL,
Mixing_Yield    DOUBLE     NOT NULL,
Process_Type    UTINYINT   NOT NULL,
Fixed_Weight    DOUBLE     NOT NULL,
Reserved        CHAR(13)    NOT NULL
)#
CREATE UNIQUE INDEX ByOrderLine IN DICTIONARY ON
 Order_Line(Order_No , Order_No_Suffix , Line_No)#
CREATE UNIQUE NOT MODIFIABLE INDEX ByFileRef IN DICTIONARY ON
 Order_Line(FileRef)#
SET TRUENULLCREATE=ON#
}

{--------- VIRTUAL MIX LINE FILE STUFF ---------------}
    PMixLineRecord = ^TMixLineRecord; { Not written to disk - initialised }
    TMixLineRecord = PACKED RECORD           { from transaction file.            }
       ML_OrderNo         : LONGINT;          {0.0}
       ML_Revision        : BYTE;
       ML_MixNo           : LONGINT;
       ML_LineNo          : LONGINT;          {0.1}
       ML_WghsDone        : LONGINT;
       ML_WtDone          : DOUBLE;
    END;

FUNCTION GetMixLineRecord(ForWOLine   : PWOLineRecord;
                          ForMixNo    : LONGINT;
                          VAR MixLRec : TMixLineRecord) : INTEGER;
{------------------------------------------------------}


TYPE
    WorkLineList = ARRAY [1..MAX_LINES_ON_RECORD] OF PWOLineRecord;


    PWOrderObject = ^TWOrderObject;
    TWOrderObject = OBJECT
      WO_Header     : TWOHeaderRecord;
      WO_Lines      : WorkLineList;
      WO_LinePos    : ARRAY [1..MAX_LINES_ON_RECORD] OF LONGINT;
      WO_DeleteList : PDeleteList;
      CONSTRUCTOR Init;
      DESTRUCTOR  Done;
      PROCEDURE   ClearLines;
      PROCEDURE   ResetCalculatedFields;
      FUNCTION    AllLinesAreUntoleranced : BOOLEAN;
      PROCEDURE   ApplyIngredTols;
    END;


    PWOHeaderFile = ^TWOHeaderFile;
    TWOHeaderFile = Object(TBtrvFileObject)
      FUNCTION   AddRecord(VAR The_Record) : INTEGER; VIRTUAL;
      FUNCTION   UpdateRecord(VAR The_Record) : INTEGER; VIRTUAL;
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
      FUNCTION   Get_WO_Header_Record(OrderNo : LONGINT;Revision : BYTE;Var WorkHRec : TWOHeaderRecord) : INTEGER;
      FUNCTION   NextAvailableOrdNo : LONGINT;

    END;

    PWOLineFile = ^TWOLineFile;
    TWOLineFile = Object(TBtrvFileObject)
      PROCEDURE  InitRecord     (VAR RecBuff); VIRTUAL;
      FUNCTION   GetFileSpec    (VAR FileSpec : FILE_SPEC) : INTEGER; VIRTUAL;
      FUNCTION   Get_WO_Line_Record(OrderNo : LONGINT;Revision:BYTE;LineNo : LONGINT;Var WorkLRec : TWOLineRecord) : INTEGER;
      FUNCTION   DelLinesForOrder(OrderNo : LONGINT;Revision : BYTE) : INTEGER;
    END;


VAR WorkHeaderFile : PWOHeaderFile;     { File Object Instance Pointer }
    WorkLineFile   : PWOLineFIle;



PROCEDURE CalcIngredReqsForMixWt(GrossMixWt  : DOUBLE;{tot ingred weight of one mix }
                                 OrderHeader : PWOHeaderRecord;
                                 OrderLine   : PWOLineRecord;
                                 CurrMixLineTots : TMixLineRecord;
                                 VAR Mix_Ingred_TotWt       : DOUBLE;
                                 VAR Mix_Ingred_Weighings   : LONGINT;
                                 VAR Mix_Ingred_WtIncrements: DOUBLE;
                                 VAR Mix_Ingred_WghsPerCont : LONGINT);


PROCEDURE EstimateIngredReqsForMixNo(MixNo       : INTEGER;
                                     OrderHeader : PWOHeaderRecord;
                                     OrderLine   : PWOLineRecord;
                                     VAR Mix_Ingred_TotWt       : DOUBLE;
                                     VAR Mix_Ingred_Weighings   : LONGINT;
                                     VAR Mix_Ingred_WtIncrements: DOUBLE);

{------------ Neater function calls to EstimateIngredReqsForMixNo ---------------}
FUNCTION EstimateLineWeighingsReqdForOrder(OrderHeader : PWOHeaderRecord;
                                           OrderLine   : PWOLineRecord) : LONGINT;

FUNCTION EstimateLineWeighingsReqdForMixNo(MixNo : LONGINT;
                                           OrderHeader : PWOHeaderRecord;
                                           OrderLine   : PWOLineRecord) : LONGINT;
FUNCTION EstimateLineGrossWtReqdForMixNo(MixNo       : LONGINT;
                                         OrderHeader : PWOHeaderRecord;
                                         OrderLine   : PWOLineRecord) : DOUBLE;

{------------ Neater function calls to CalcIngredReqsForMixWt ---------------}
FUNCTION CalcLineWeighingsReqdForCurrMix(OrderHeader : PWOHeaderRecord;
                                         OrderLine   : PWOLineRecord) : LONGINT;

FUNCTION CalcLineGrossWtReqdForCurrMix(OrderHeader : PWOHeaderRecord;
                                       OrderLine   : PWOLineRecord) : DOUBLE;
{----------------------------------------------------------------------------}



(*
{Returns The number of containers needed for mixes}
{For Weighed Ingredients Only}
{For Count Ingredients ContainerSize = Fixed Weight}
{For Step Ingredients}
FUNCTION  CalcNumContainers(MixWtGross,
                            Ratio,
                            LossWt,
                            ContainerSize : DOUBLE;
                            ProcessType   : TProcessTypes;
                            FixedWt       : DOUBLE;
                            MixType       : TMixType;
                            Mixes         : LONGINT) : LONGINT;
*)
FUNCTION CalcLineGrossPortion(OrderHeader : PWOHeaderRecord;
                              OrderLine   : PWOLineRecord) : DOUBLE;
{ Calculates ingredients weight contribution to mix start weight (gross)}


{ Actual Weight required on scale After Yield Taken Into Account }
FUNCTION  CalcLineGrossWtReqdFromRecipeNet(ATotNetWt, { eg order finish wt reqd }
                                        LineRatioPercent,
                                        LineYieldPercent : DOUBLE) : DOUBLE;

{Returns Amount Of Weight Loss as a negative figure }
FUNCTION  CalcLineLossWt(MixFinishWt,LinePercent,Yield : DOUBLE) : DOUBLE;

(*
{Calculates The Maximum Weight Required For A Single Containers}
FUNCTION CalcAbsLineMixWt(CONST WorkLRec : TWOLineRecord;
                                MixWt    : DOUBLE;
                                MixType  : TMixType) : LONGINT;
*)

FUNCTION  EstimateGrossWtReqdForMixNo(MixNo       : LONGINT;
                                      OrderHeader : PWOHeaderRecord) : DOUBLE;
FUNCTION  OrderComplete(VAR OrdHRec : TWOHeaderRecord): BOOLEAN;
FUNCTION  LineNoCompleteForCurrMix(WOHPtr : PWOHeaderRecord;
                                   LineNo : LONGINT) : BOOLEAN;
FUNCTION IsThisLineCompleteForCurrMix(WOHPtr   : PWOHeaderRecord;
                                      WorkLRec : PWOLineRecord;
                                      WghsDoneForCurrMix : LONGINT;
                                      WtDoneForCurrMix : DOUBLE) : BOOLEAN;
{$IFDEF TERMINAL}
FUNCTION  FindNextWipLineForTerminal(OrdHRec : PWOHeaderRecord;
                                     StartLineNo : LONGINT) : LONGINT;
{$ENDIF}
FUNCTION  AllLinesCompleteForCurrMix(VAR OrdHRec : TWOHeaderRecord) : BOOLEAN;
FUNCTION  GetMixType(MixType : TMixType) : STRING;
FUNCTION  GetStatusType(Stat  : TStatusType ) :STRING;
PROCEDURE StrToOrderNo(OrdStr : STRING;VAR OrderNo : LONGINT;VAR Revision :BYTE);
FUNCTION  OrderNoToStr(OrderNo :LONGINT;Revision : BYTE) : STRING;
FUNCTION  OrderMixToBarcode(AnOrdHeader : PWOHeaderRecord;
                            AMid : BYTE) : STRING;
PROCEDURE RecipeToOrder(VAR WorkHRec : TWOHeaderRecord;
                        VAR WO_Lines : WorkLineList;
                        VAR RecipeToCopyFrom : TRecipeRef);

(*
PROCEDURE GetKeyIngredientWtRestrictions(VAR TargetWtAsSetByKeyIngredient,
                                             MaxIngredientWtAsSetByKeyIngredient : DOUBLE;
                                             LineRatio,LossWt : DOUBLE;
                                             WORecordSelected : LONGINT;
                                             WORevision       : BYTE;
                                             KeyIngredientLineNo : LONGINT);
*)
FUNCTION CompareLineWithKeyIngredient(LineNo,KeyIngredientLineNo : LONGINT;DisregardKeyIngredient : BOOLEAN) : BOOLEAN;

PROCEDURE LoadWOHeaderWithRecipeHeader(VAR WorkHRec   : TWOHeaderRecord;
                                       VAR RecipeHRec : TRecipeHeaderRecord{CONST});
PROCEDURE PrimeWOLineForIngredient(VAR WorkLRecord : TWOLineRecord;
                                   VAR IngredientRec : TIngredient_Record);

(*
PROCEDURE RoundWtToScaleRes(VAR Wt : DOUBLE);
         { Current thinking on this is its only to be used to:
           a) round total mix weights so reports and screens are consistent
           b) round weighing tolerances so they match scale capabilities. }
*)
FUNCTION  RoundWtToNearestGram(KgWt : DOUBLE) : DOUBLE;

PROCEDURE AdjustTolToScaleRes(VAR LowWt, HighWt : DOUBLE);

PROCEDURE CalcWOLineTolWts(    AWOLine        : PWOLineRecord;
                               TargetWeight   : DOUBLE;{ in current container }
                               MixType        : TMixType;
                               LineWtRequired : DOUBLE;{ in current mix }
                               LineWtDone     : DOUBLE;{ in current mix }
                               VAR LowestWt   : DOUBLE;
                               VAR HighestWt  : DOUBLE);

FUNCTION CompareWts(A,B : DOUBLE) : INTEGER;
         { returns:  A > B = 1;  A == B = 0;  A < B = -1 }

IMPLEMENTATION

USES FXFmix;


FUNCTION CompareWts(A,B : DOUBLE) : INTEGER;
{ returns:  A > B = 1;  A == B = 0;  A < B = -1 }
VAR
   AInThousandths,
   BInThousandths : LONGINT;
   OverflowA,
   OverflowB      : BOOLEAN;
BEGIN
 AInThousandths := RoundDblToLong(A*1000, OverflowA);
 BInThousandths := RoundDblToLong(B*1000, OverflowB);
 IF OverflowA OR OverflowB THEN
  BEGIN
   IF A > B THEN
     CompareWts := 1
   ELSE IF A = B THEN
     CompareWts := 0
   ELSE
     CompareWts := -1;
  END
 ELSE
  BEGIN
   IF AInThousandths > BInThousandths THEN
     CompareWts := 1
   ELSE IF AInThousandths = BInThousandths THEN
     CompareWts := 0
   ELSE
     CompareWts := -1;
  END;
END;

(*
{Rounds Weights To Nearest scale increment}
PROCEDURE RoundWtToScaleRes(VAR Wt : DOUBLE);
VAR
  NearestNoOfIncrements : DOUBLE;
BEGIN
 IF (NOT Config_Rec^.Conf_RoundWeights) THEN EXIT;
                                            {****}

 NearestNoOfIncrements := RoundDblToDbl(DivDouble(Wt,Config_Rec^.Conf_ScaleRes));
 Wt := NearestNoOfIncrements * Config_Rec^.Conf_ScaleRes;
END;
*)


FUNCTION RoundWtToNearestGram(KgWt : DOUBLE) : DOUBLE;
VAR
  Grams      : LONGINT;
  OverFlowed : BOOLEAN;
BEGIN
 RoundWtToNearestGram := KgWt;

 Grams := RoundDblToLong(KgWt * 1000, OverFlowed);

 IF NOT Overflowed THEN
   RoundWtToNearestGram := Grams / 1000;
END;


FUNCTION RoundWtUpToUnits(Weight : DOUBLE;
                          UnitWt : DOUBLE) : LONGINT;
VAR
       UnitsExact: DOUBLE;
       PartUnitWt: DOUBLE;
       NoOfUnits : LONGINT;
BEGIN
     UnitsExact := DivDouble(Weight,UnitWt);
     NoOfUnits := Trunc(UnitsExact);
     PartUnitWt := frac(UnitsExact) * UnitWt;

     { if remainder >= 0.001(smallest possible scale increment) then round up }
     IF CompareWts(PartUnitWt, 0.0) > 0 THEN
       Inc(NoOfUnits);

     RoundWtUpToUnits := NoOfUnits;
END;


PROCEDURE AdjustTolToScaleRes(VAR LowWt, HighWt : DOUBLE);
{ low wt will be rounded-up so ingredient appears complete after weighing }
{ HighWt will be rounded to nearest scale increment unless that would cause
  it to be lower than low, in which case it will = lowWt.
}
VAR
 LowTolScaleIncs,
 HighTolScaleIncs : LONGINT;
 OverFlowed : BOOLEAN;

BEGIN
 IF (NOT Config_Rec^.Conf_RoundWeights) THEN EXIT;
                                            {****}

 LowTolScaleIncs := RoundWtUpToUnits(LowWt, Config_Rec^.Conf_ScaleRes);
 LowWt := LowTolScaleIncs * Config_Rec^.Conf_ScaleRes;

 HighTolScaleIncs := RoundDblToLong(DivDouble(HighWt, Config_Rec^.Conf_ScaleRes),
                                    OverFlowed);
 IF NOT OverFlowed THEN
  BEGIN
   IF HighTolScaleIncs < LowTolScaleIncs THEN
     HighTolScaleIncs := LowTolScaleIncs;
   HighWt := HighTolScaleIncs * Config_Rec^.Conf_ScaleRes;
  END;
END;

PROCEDURE CalcWOLineTolWts(    AWOLine        : PWOLineRecord;
                               TargetWeight   : DOUBLE;{ in current container }
                               MixType        : TMixType;
                               LineWtRequired : DOUBLE;{ in current mix }
                               LineWtDone     : DOUBLE;{ in current mix }
                               VAR LowestWt   : DOUBLE;
                               VAR HighestWt  : DOUBLE);
VAR
  ContainerMaxWt : DOUBLE;
BEGIN
 WITH AWOLine^ DO
  BEGIN
   IF MixType = mt_EqualContainersPerMix THEN
    BEGIN
     HighestWt := TargetWeight * (1+ (WOL_HighTol/100));
     LowestWt  := TargetWeight * (1- (Abs(WOL_LowTol)/100));
     {NOTE Original Ingredient File Had Negative LowTol so abs
           used to counter this}
     IF LowestWt < 0.0 THEN
       LowestWt := 0.0;
    END
   ELSE
    BEGIN
     { On last container high and low tolerance needs to reflect
       total mix requirement for ingredient }
     HighestWt := LineWtRequired * (1+ (WOL_HighTol/100));
     HighestWt := HighestWt - LineWtDone;

     LowestWt  := LineWtRequired * (1- (Abs(WOL_LowTol)/100));
     LowestWt  := LowestWt - LineWtDone;

     IF  (TargetWeight > 0.0)
     AND (TargetWeight < LowestWt) THEN { another container expected afterwards }
      BEGIN
       IF CompareWts(Config_Rec^.CONF_FullContainerHighTol, 0.0) > 0 THEN
         ContainerMaxWt := TargetWeight *
                            (1+ (Config_Rec^.CONF_FullContainerHighTol/100))
       ELSE
         ContainerMaxWt := TargetWeight * (1+ (WOL_HighTol/100));

       { Providing container max wt doesnt take wt over mix requirement }
       { use container tolerance (FullContainerHighTol might be large)  }
       IF ContainerMaxWt < HighestWt THEN
         HighestWt := ContainerMaxWt;

       { apply low tol to container wt }
       { Partial weigh button can be used if this is to tight }
       LowestWt  := TargetWeight * (1- (Abs(WOL_LowTol)/100));
      END;

     IF HighestWt < 0.0 THEN HighestWt := 0.0;
     IF LowestWt < 0.0  THEN LowestWt := 0.0;
    END;
  END;
END;

FUNCTION CompareLineWithKeyIngredient(LineNo,KeyIngredientLineNo : LONGINT;DisregardKeyIngredient : BOOLEAN) : BOOLEAN;
BEGIN
 IF DisregardKeyIngredient THEN CompareLineWithKeyIngredient := FALSE
 ELSE
  CompareLineWithKeyIngredient := (KeyIngredientLineNo <> 0) AND (LineNo <> KeyIngredientLineNo);
END;


(*
PROCEDURE GetKeyIngredientWtRestrictions(VAR TargetWtAsSetByKeyIngredient,
                                             MaxIngredientWtAsSetByKeyIngredient : DOUBLE;
                                             LineRatio,LossWt : DOUBLE;
                                             WORecordSelected : LONGINT;
                                             WORevision       : BYTE;
                                             KeyIngredientLineNo : LONGINT);
VAR KeyWOLineRec : TWOLineRecord;
BEGIN
 WorkLineFile^.OpenFile;
 IF WorkLineFile^.Get_WO_Line_Record(WORecordSelected,WORevision,KeyIngredientLineNo,KeyWOLineRec)=0 THEN
  BEGIN
   IF KeyWOLineRec.WOL_Ratio <> 0.0 THEN
    BEGIN
     {Calculate the maximum batch weight as set by the master product}
     TargetWtAsSetByKeyIngredient  := KeyWOLineRec.WOL_MixWtDone*(100 / KeyWOLineRec.WOL_Ratio);
     {now calculate max line weight as set by master product}
     MaxIngredientWtAsSetByKeyIngredient := CalcLineGrossWtReqdFromRecipeNet(
                                   TargetWtAsSetByKeyIngredient, {!!!! TB}
                                   LineRatio,
                                   100);
    END
   ELSE
    BEGIN
     TargetWtAsSetByKeyIngredient  := 0;
     MaxIngredientWtAsSetByKeyIngredient := 0;
    END;
  END;
 WorkLineFile^.CloseFile;
END;
*)

(*
{Calculates The Maximum Weight Required For A Single Containers}
FUNCTION CalcAbsLineMixWt(CONST WorkLRec : TWOLineRecord;
                                MixWt    : DOUBLE;
                                MixType  : TMixType) : LONGINT;
VAR TheWt : DOUBLE;
BEGIN
 WITH WorkLRec DO
  BEGIN
   IF MixType = mt_EqualContainersPerMix THEN
    TheWt := CalcLineGrossWtReqd(MixWt,WOL_Ratio,WOL_Yield) /
                         CalcNumContainers(MixWt,0,100,WOL_ContainerSize,WOL_ProcessType,WOL_FixedWt,MixType,1)
   ELSE
    TheWt := (CalcLineGrossWtReqd(MixWt,WOL_Ratio,WOL_Yield)-WOL_MixWtDone);
  END;
 RoundWtToScaleRes(TheWt);
 CalcAbsLineMixWt := Round(TheWt*1000);
END;
*)


FUNCTION CalcLineGrossPortion(OrderHeader : PWOHeaderRecord;
                              OrderLine   : PWOLineRecord) : DOUBLE;
{ Calculates ingredients weight contribution to mix start weight (gross)}
BEGIN
 WITH OrderHeader^, OrderLine^ DO
   CalcLineGrossPortion := DivDouble(CalcLineGrossWtReqdFromRecipeNet(WOH_FinishWtReqd,
                                                                   WOL_Ratio,
                                                                   WOL_Yield),
                                     WOH_TotIngredWtReqd);
END;



{ Actual Weight required on scale After Yield Taken Into Account }
FUNCTION CalcLineGrossWtReqdFromRecipeNet(ATotNetWt, { eg order finish wt }
                                       LineRatioPercent,
                                       LineYieldPercent : DOUBLE) : DOUBLE;
VAR LineMixWt : DOUBLE;
BEGIN
{  Ingredient wt  =  finish mix wt * (linePercent / 100)
                     ----------------------------
                     YieldPercent / 100
}
 IF LineYieldPercent > 0.00001 THEN { we can divide }
   LineMixWt := ATotNetWt*LineRatioPercent/LineYieldPercent { 100's cancel out }
 ELSE
   LineMixWt := ATotNetWt*LineRatioPercent/100;

(* RoundWtToScaleRes(LineMixWt);  dont do this - screws mixes reqd in editor *)
 CalcLineGrossWtReqdFromRecipeNet := LineMixWt;
END;

{Returns Amount Of Weight Loss as a negative figure }
FUNCTION CalcLineLossWt(MixFinishWt,LinePercent,Yield : DOUBLE) : DOUBLE;
VAR TheWt : DOUBLE;
BEGIN
 TheWt := CalcLineGrossWtReqdFromRecipeNet(MixFinishWt,LinePercent,Yield) -
              CalcLineGrossWtReqdFromRecipeNet(MixFinishWt,LinePercent,100.0);
 CalcLineLossWt := TheWt;
END;

(*
FUNCTION  CalcNumContainers(MixWtGross,
                            Ratio,
                            LossWt,
                            ContainerSize : DOUBLE;
                            ProcessType   : TProcessTypes;
                            FixedWt       : DOUBLE;
                            MixType       : TMixType;
                            Mixes         : LONGINT) : LONGINT;
VAR ContainersReq : DOUBLE;
    TotalLineWt   : DOUBLE;
    Denominator   : DOUBLE;
    Temp          : DOUBLE;
BEGIN
 CalcNumContainers := 1;

 IF ProcessType <> PTStep THEN { steps only have 1 container - I think TB.}
  BEGIN
   IF (ProcessType = PTCount) THEN
     Denominator := FixedWt
   ELSE
     Denominator := ContainerSize;

   IF Denominator > 0.0 THEN
    BEGIN
     IF MixType = mt_EqualContainersPerMix THEN
      BEGIN
       ContainersReq := MixWtGross / Denominator;
       Mixes := 1;
      END
     ELSE
      BEGIN
       {Weight Required To Be Placed On Each Mix}
       IF (Mixes = 0) THEN
        BEGIN
         ContainersReq := 0.0;
        END
       ELSE
        BEGIN
         TotalLineWt   := (CalcLineGrossWtReqd(MixWtGross,Ratio,LossWt)/Mixes);
         ContainersReq := TotalLineWt / Denominator;
        END;
      END;
     Temp := frac(ContainersReq);
     IF (Round(Temp*1000000)  > 0) THEN
       CalcNumContainers := Mixes * (Trunc(ContainersReq)+1)
     ELSE
       CalcNumContainers := Mixes * Trunc(ContainersReq);
    END;
  END;
END;
*)

FUNCTION EstimateGrossWtReqdForMixNo(MixNo       : LONGINT;
                                     OrderHeader : PWOHeaderRecord) : DOUBLE;
VAR MixWtGross : DOUBLE;
BEGIN
 WITH OrderHeader^ DO
  BEGIN
   IF Config_Rec^.CONF_EqualMixes THEN
     MixWtGross := DivDouble(WOH_TotIngredWtReqd,WOH_NumMixes)

   ELSE IF MixNo < WOH_NumMixes THEN     { full capacity mix }
     MixWtGross := WOH_MaxMixGrossWt

   ELSE IF MixNo = WOH_NumMixes THEN     { last part mix }
     MixWtGross := WOH_TotIngredWtReqd - (WOH_MaxMixGrossWt * (WOH_NumMixes-1))

   ELSE
     MixWtGross := 0.0;
  END;

 IF MixWtGross < 0.0 THEN { scale res is greater last mix wt? }
   MixWtGross := 0.0;
 MixWtGross := RoundWtToNearestGram(MixWtGross);
 EstimateGrossWtReqdForMixNo := MixWtGross;
END;


PROCEDURE CalcIngredReqsForMixWt(GrossMixWt  : DOUBLE;
                                 OrderHeader : PWOHeaderRecord;
                                 OrderLine   : PWOLineRecord;
                                 CurrMixLineTots : TMixLineRecord;
                                 VAR Mix_Ingred_TotWt       : DOUBLE;
                                 VAR Mix_Ingred_Weighings   : LONGINT;
                                 VAR Mix_Ingred_WtIncrements: DOUBLE;
                                 VAR Mix_Ingred_WghsPerCont : LONGINT);
{NOTE: If mix type is NOT Proportionally mixed containers then
       requirements = remaining requirement + whats been done
       (enables only last weighing to be within a tolerance).
}
VAR
  ContainersReq : LONGINT;
  IngredWtForContainer : DOUBLE;
  RemainingWt : DOUBLE;
BEGIN
 Mix_Ingred_TotWt       := 0.0;
 Mix_Ingred_Weighings   := 0; { caller might pass through 0 wt when order is complete}
 Mix_Ingred_WtIncrements:= 0.0;
 Mix_Ingred_WghsPerCont := 1;

 IF (GrossMixWt > 0.0) THEN
  BEGIN
   Mix_Ingred_Weighings   := 0;

   WITH OrderHeader^, OrderLine^ DO
    BEGIN
     Mix_Ingred_TotWt := GrossMixWt * CalcLineGrossPortion(OrderHeader,
                                                         OrderLine);
     { calculate requirements as: remaining requirement + whats been done.}
     RemainingWt := Mix_Ingred_TotWt - CurrMixLineTots.ML_WtDone;

(*   RoundWtToScaleRes(RemainingWt); *)

     { Calculate no of weighings for mix and at what weight }
     { Weighings in any one mix are always the same.        }
     IF WOL_ProcessType = PTStep THEN { steps only have 1 "weighing" per mix }
      BEGIN
       Mix_Ingred_Weighings    := 1;
       Mix_Ingred_WtIncrements := 0.0;
      END
     ELSE IF WOH_MixType IN MixSet_ProportionallyMixedConts THEN
      BEGIN
       {Usually more, but smaller, weighings due to ingredients being split over
        more containers. There maybe less containers in total because they're all
        nearly full.
        Number of containers and hence weighings is controlled by the total mix
        weight and the shared container size.
       }
       { HOW MANY CONTAINERS? }
       ContainersReq := RoundWtUpToUnits(GrossMixWt, WOL_ContainerSize);

       { HOW MUCH INGREDIENT WEIGHT PER CONTAINER? }
       IngredWtForContainer := DivDouble(Mix_Ingred_TotWt, ContainersReq);

       { HOW MANY WEIGHINGS? }
{$IFNDEF MAUNDERS} { maunders want count ingredient to mean user just needs
                     to confirm required weight has been done elsewhere.
                     So set wt increment as for normal weighing. }
       IF WOL_ProcessType = PTCount THEN { might need more than 1 weighing per container }
        BEGIN
         Mix_Ingred_WtIncrements := WOL_FixedWt;
         Mix_Ingred_WghsPerCont  := RoundWtUpToUnits(IngredWtForContainer,
                                                     WOL_FixedWt);
         Mix_Ingred_Weighings := ContainersReq * Mix_Ingred_WghsPerCont;
        END
       ELSE { PTWeight }
{$ENDIF}
        BEGIN
         Mix_Ingred_WtIncrements := IngredWtForContainer;
         Mix_Ingred_Weighings    := ContainersReq;
        END;
      END
     ELSE
      BEGIN
       { Assume ingredients will go into their own containers as this is       }
       { easier to prepare.                                                    }
       { Mix type might give user the option to put them in the same container }
       { at their own risk (might overflow).                                   }
       { Number of containers and hence weighings is controlled by the         }
       { ingredient weight and the container size.                             }

{$IFNDEF MAUNDERS} { maunders want count ingredient to mean user just needs
                     to confirm required weight has been done elsewhere.
                     So set wt increment as for normal weighing. }
       IF WOL_ProcessType = PTCount THEN
        BEGIN
         { A lot of the code assumes all containers for an ingredient in a mix
           have the same weight - to reliably achieve this with fixed weight
           items and reduce fixed weight "give away" all fixed items
           will be assumed to be in their own container.
         ie. Mix_Ingred_WghsPerCont := 1
         }
         Mix_Ingred_WtIncrements := WOL_FixedWt;
         Mix_Ingred_Weighings    := RoundWtUpToUnits(Mix_Ingred_TotWt,
                                                     WOL_FixedWt);
        END
       ELSE { PTWeight }
{$ENDIF}
        BEGIN
         { Use 'ContainersReq' to hold REMAINING containers required. }
         { -----------------------------------------------------------}
         { HOW MANY MORE CONTAINERS PURELY FOR THIS INGREDIENT? }
         ContainersReq := RoundWtUpToUnits(RemainingWt, WOL_ContainerSize);


         { HOW MUCH INGREDIENT WEIGHT PER REMAINING CONTAINER? }
(*       no longer evenly spread - was a req for completion by container count
         IngredWtForContainer := DivDouble(RemainingWt, ContainersReq);
*)
         IF ContainersReq > 1 THEN
           IngredWtForContainer := WOL_ContainerSize
         ELSE
           IngredWtForContainer := RemainingWt;
         Mix_Ingred_WtIncrements := IngredWtForContainer;

         { HOW MANY WEIGHINGS? }
         Mix_Ingred_Weighings    := ContainersReq + CurrMixLineTots.ML_WghsDone;
        END;
      END;
    END;
  END;

(* RoundWtToScaleRes(Mix_Ingred_TotWt);        *)
(* RoundWtToScaleRes(Mix_Ingred_WtIncrements); *)
END;

PROCEDURE EstimateIngredReqsForMixNo(MixNo       : INTEGER;
                                     OrderHeader : PWOHeaderRecord;
                                     OrderLine   : PWOLineRecord;
                                     VAR Mix_Ingred_TotWt       : DOUBLE;
                                     VAR Mix_Ingred_Weighings   : LONGINT;
                                     VAR Mix_Ingred_WtIncrements: DOUBLE);
VAR
  ExpectedWtForMix       : DOUBLE;
  Mix_Ingred_WghsPerCont : LONGINT;
  DummyDoneRec           : TMixLineRecord;
BEGIN
 ExpectedWtForMix := EstimateGrossWtReqdForMixNo(MixNo, OrderHeader);
 FillChar(DummyDoneRec, SizeOf(DummyDoneRec), 0);
 CalcIngredReqsForMixWt(ExpectedWtForMix,
                        OrderHeader,
                        OrderLine,
                        DummyDoneRec,
                        Mix_Ingred_TotWt,        {VAR}
                        Mix_Ingred_Weighings,    {VAR}
                        Mix_Ingred_WtIncrements,
                        Mix_Ingred_WghsPerCont);{VAR}
END;




{ functions to calculate NUMBER OF WEIGHINGS REQD ------------------------}

FUNCTION EstimateLineWeighingsReqdForOrder(OrderHeader : PWOHeaderRecord;
                                           OrderLine   : PWOLineRecord) : LONGINT;
VAR
   TotWeightInMix : DOUBLE;
   WeighingsInMix : LONGINT;
   WtsInMix       : DOUBLE;
   TotLineWeighingsReqd : LONGINT;
   MixNo : LONGINT;
BEGIN
 TotLineWeighingsReqd := 0;
 FOR MixNo := 1 TO OrderHeader^.WOH_NumMixes DO
  BEGIN
   EstimateIngredReqsForMixNo(MixNo, OrderHeader, OrderLine,
                              TotWeightInMix, {VAR}
                              WeighingsInMix, {VAR}
                              WtsInMix);      {VAR}
   TotLineWeighingsReqd := TotLineWeighingsReqd + WeighingsInMix;
  END;
 EstimateLineWeighingsReqdForOrder := TotLineWeighingsReqd;
END;


FUNCTION EstimateLineWeighingsReqdForMixNo(MixNo       : LONGINT;
                                           OrderHeader : PWOHeaderRecord;
                                           OrderLine   : PWOLineRecord) : LONGINT;
VAR
   TotWeightInMix : DOUBLE;
   WeighingsInMix : LONGINT;
   WtsInMix       : DOUBLE;
BEGIN
 EstimateIngredReqsForMixNo(MixNo, OrderHeader, OrderLine,
                            TotWeightInMix, WeighingsInMix, WtsInMix);
 EstimateLineWeighingsReqdForMixNo := WeighingsInMix;
END;

FUNCTION EstimateLineGrossWtReqdForMixNo(MixNo       : LONGINT;
                                         OrderHeader : PWOHeaderRecord;
                                         OrderLine   : PWOLineRecord) : DOUBLE;
VAR
   TotWeightInMix : DOUBLE;
   WeighingsInMix : LONGINT;
   WtsInMix       : DOUBLE;
BEGIN
 EstimateIngredReqsForMixNo(MixNo, OrderHeader, OrderLine,
                            TotWeightInMix, WeighingsInMix, WtsInMix);
 EstimateLineGrossWtReqdForMixNo := TotWeightInMix;
END;


FUNCTION CalcLineWeighingsReqdForCurrMix(OrderHeader : PWOHeaderRecord;
                                         OrderLine   : PWOLineRecord) : LONGINT;
VAR
   TotWeightInMix : DOUBLE;
   WeighingsInMix : LONGINT;
   WtsInMix       : DOUBLE;
   WghsPerContainer: LONGINT;
   DoneRec        : TMixLineRecord;
BEGIN
 GetMixLineRecord(OrderLine, OrderHeader^.WOH_CurrentMix, DoneRec);
 CalcIngredReqsForMixWt(CalcCompensatedBatchMixWt(OrderHeader,
                                                  OrderHeader^.WOH_CurrentMix),
                        {OrderHeader^.WOH_TargetBatchWt,}
                        OrderHeader,
                        OrderLine,
                        DoneRec,
                        TotWeightInMix,
                        WeighingsInMix,
                        WtsInMix,
                        WghsPerContainer);
 CalcLineWeighingsReqdForCurrMix := WeighingsInMix;
END;


{functions to calculate INGREDIENT WEIGHTS REQD --------------------------}


FUNCTION CalcLineGrossWtReqdForCurrMix(OrderHeader : PWOHeaderRecord;
                                       OrderLine   : PWOLineRecord) : DOUBLE;
VAR
   TotWeightInMix : DOUBLE;
   WeighingsInMix : LONGINT;
   WtsInMix       : DOUBLE;
   WghsPerContainer: LONGINT;
   DummyDoneRec   : TMixLineRecord;
BEGIN
 FillChar(DummyDoneRec, SizeOf(DummyDoneRec), 0);
 CalcIngredReqsForMixWt({OrderHeader^.WOH_TargetBatchWt,}
                        CalcCompensatedBatchMixWt(OrderHeader,
                                                  OrderHeader^.WOH_CurrentMix),
                        OrderHeader,
                        OrderLine,
                        DummyDoneRec,
                        TotWeightInMix,
                        WeighingsInMix,
                        WtsInMix,
                        WghsPerContainer);
 CalcLineGrossWtReqdForCurrMix := TotWeightInMix;
END;


{-------------------------------------------------------------------------}


FUNCTION TWOHeaderFile.Get_WO_Header_Record(OrderNo: LONGINT;
                                            Revision : BYTE;
                                            Var WorkHRec : TWOHeaderRecord) : INTEGER;
BEGIN
 InitRecord(WorkHRec);
 WorkHRec.WOH_OrderNo := OrderNo;
 WorkHRec.WOH_Revision:= Revision;
 Get_WO_Header_Record := WorkHeaderFile^.ReadRecord('EQ',FALSE,FALSE,
                                                    WorkHRec,1);
END;


FUNCTION TWOHeaderFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TWOHeaderRecord);
   Page_Size := 4096;
   File_Flags:= 0;
   Ndx_Cnt   := 2;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.1 Schedule Date}
   INC(SegC,Set_Key(Key_Buf[0],15,04,K_EXTTYPE OR K_MODIFIABLE OR K_SEGMENTED,
       EKT_INTEGER,0));
   { 0.1 Order Nubmer       }
   INC(SegC,Set_Key(Key_Buf[1],01,04,K_EXTTYPE OR K_MODIFIABLE OR K_SEGMENTED,
       EKT_INTEGER,0));
   { 0.2 Revision}
   INC(SegC,Set_Key(Key_Buf[2],05,01,K_EXTTYPE OR K_MODIFIABLE,EKT_STRING,0));

   { 1.0 Order No}
   INC(SegC,Set_Key(Key_Buf[3],01,04,K_EXTTYPE OR K_MODIFIABLE OR K_SEGMENTED,
       EKT_INTEGER,0));
   { 1.1 Revision}
   INC(SegC,Set_Key(Key_Buf[4],05,01,K_EXTTYPE OR K_MODIFIABLE,EKT_STRING,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

PROCEDURE TWOHeaderFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TWOHeaderRecord),#0);
 WITH TWOHeaderRecord(RecBuff) DO
  BEGIN
   WOH_OrderNo       := 0;
   WOH_Revision      := 0;
   WOH_RecipeNo      := SPACE_STRING;
   WOH_SchDate       := Date_To_Days(Date);
   WOH_Status        := StatusHold;
{$IFDEF GRAMPIAN_PORK_SPEC}
   WOH_MixType       := mt_SegregatedIngredients;
{$ELSE}
   WOH_MixType       := mt_SingleContainerPerMix;
{$ENDIF}
   WOH_TotIngredWtReqd   := 0.0;
   WOH_FinishWtReqd := 0.0;
   WOH_MaxMixGrossWt    := 0.0;
   {WOH_SeqFixed      := FALSE;}
   {WOH_SelectByCase  := FALSE; requirement is based on cases no weight }
   {WOH_TargetBatchWt := WOH_MaxMixGrossWt;}
   WOH_MixDone       := 0;
   {WOH_WtDoneNet     := 0;}
   {WOH_CurrentMixWt  := 0;}
   WOH_UpdateCount   := 0;
   WOH_AutoBatNoOffset := 0;
  END;
END;

FUNCTION TWOHeaderFile.AddRecord(VAR The_Record) : INTEGER;
VAR Result : INTEGER;
BEGIN
 Result := INHERITED AddRecord(The_Record);
 IF Result = 0 THEN
   CreateAllMixRecords(@TWOHeaderRecord(The_Record));
 AddRecord := Result;
END;

FUNCTION TWOHeaderFile.UpdateRecord(VAR The_Record) : INTEGER;
VAR Result : INTEGER;
BEGIN
 Result := INHERITED UpdateRecord(The_Record);
 IF (Result = 0) THEN
  BEGIN
   WITH TWOHeaderRecord(The_Record) DO
    BEGIN
     {Create/Update Mix Records For Order}
     CreateAllMixRecords(@TWOHeaderRecord(The_Record));
    END;
  END;
 UpdateRecord := Result;
END;

FUNCTION TWOHeaderFile.NextAvailableOrdNo : LONGINT;
{ returns serialised order number that does not already exist }
{ File needs to be open. }
VAR
    TempRec : TWOHeaderRecord;
    OrdNo   : LONGINT;
    ErrInt  : INTEGER;
    Retries : INTEGER;

BEGIN
   Retries := 2000;

   OrdNo := 0;
   REPEAT
    Dec(Retries);
    IF Retries <= 0 THEN
     BEGIN
      OrdNo := 0;
      BREAK;
     (*****)
     END;

    OrdNo := GetNextOrderNo;
    IF OrdNo = 0 THEN
      BREAK;
     (*****)

    { Check There is not already an order with that number}
    InitRecord(TempRec);
    TempRec.WOH_OrderNo := OrdNo;
    TempRec.WOH_Revision:= 0;
    ErrInt := WorkHeaderFile^.ReadRecord('GE',FALSE,FALSE,TempRec,1);

    IF BtrvErrType(ErrInt) = berr_Critical THEN
     BEGIN
      OrdNo := 0;
      BREAK;
     (*****)
     END;

   UNTIL (ErrInt = BEndOfFile)
      OR ((ErrInt = 0) AND (TempRec.WOH_OrderNo <> OrdNo));

   NextAvailableOrdNo := OrdNo;
END;
{---------------------------------------------------------}

FUNCTION GetStatusType(Stat  : TStatusType ) :STRING;
BEGIN
  IF  (ORD(Stat) >= ORD(Low(TStatusType)))
  AND (ORD(Stat) <= ORD(High(TStatusType))) THEN
    GetStatusType := OrdStatStrings[Stat]
  ELSE
    GetStatusType := '????';
END;

FUNCTION GetMixType(MixType : TMixType) : STRING;
BEGIN
  CASE MixType OF
   mt_SingleContainerPerMix   : GetMixType := 'Single   ';
   mt_SegregatedIngredients   : GetMixType := 'Segregate';
   mt_OptionallySegregated    : GetMixType := 'Flexible ';
   mt_EqualContainersPerMix    : GetMixType := 'Equal    ';
   mt_CampaignWeighing        : GetMixType := 'Campaign ';
  ELSE GetMixType := COPY(SPACE_STRING,1,7);
  END;
END;

FUNCTION TWOLineFile.GetFileSpec(VAR FileSpec : FILE_SPEC) : INTEGER;
VAR SegC    : WORD;
BEGIN
 SegC := 0;
 WITH FileSpec DO
  BEGIN
   Rec_Len   := SizeOf(TWOLineRecord);
   Page_Size := 2048;
   File_Flags:= 0;
   Ndx_Cnt   := 2;
   Pre_Alloc := 0;
   Record_Cnt:= 0;
   { 0.1 Order Number}
   INC(SegC,Set_Key(Key_Buf[0],05,04,K_EXTTYPE OR K_DUPLICATE OR K_MODIFIABLE OR K_SEGMENTED,
       EKT_INTEGER,0));
   {0.1 Revision No}
   INC(SegC,Set_Key(Key_Buf[1],09,01,K_EXTTYPE OR K_DUPLICATE OR K_MODIFIABLE OR K_SEGMENTED,
       EKT_STRING,0));
   { 0.2 Line Number}
   INC(SegC,Set_Key(Key_Buf[2],10,04,K_EXTTYPE OR K_DUPLICATE OR K_MODIFIABLE,
       EKT_INTEGER,0));
   { 1.0 Unique Ref (Auto Incrementing Key) }
   INC(SegC,Set_Key(Key_Buf[3],01,04,K_EXTTYPE,EKT_AUTO_INC,0));
  END;
 GetFileSpec := FileSpec.Ndx_Cnt + SegC;
END;

FUNCTION TWOLineFile.Get_WO_Line_Record(OrderNo : LONGINT;Revision:BYTE;LineNo : LONGINT;
                           Var WorkLRec : TWOLineRecord) : INTEGER;
BEGIN
 OpenFile;
 InitRecord(WorkLRec);
 WorkLRec.WOL_OrderNo := OrderNo;
 WorkLRec.WOL_LineNo  := LineNo;
 WorkLRec.WOL_Revision:= Revision;
 Get_WO_Line_Record := ReadRecord('EQ',FALSE,FALSE,WorkLRec,0);
 CloseFile;
END;

PROCEDURE TWOLineFile.InitRecord(VAR RecBuff);
BEGIN
 FillChar(RecBuff,SizeOF(TWOLineRecord),#0);
 WITH TWoLineRecord(RecBuff) DO
  BEGIN
   WOL_UniqueRef       := 0;
   WOL_OrderNo         := 0;
   WOL_Revision        := 0;
   WOL_LineNo          := 0;
   WOL_Ingredient      := SPACE_STRING;
   WOL_KeyIngredient   := FALSE;
   WOL_Ratio           := 0;
   WOL_ContainerSize   := 0;
{  WOL_MixContDone     := 0;}
{  WOL_MixWtDone       := 0.0;}
   WOL_SpecialInstr[1] := SPACE_STRING;
   WOL_SpecialInstr[2] := SPACE_STRING;
   WOL_Yield           := 0.0;
  END;
END;

FUNCTION TWOLineFile.DelLinesForOrder(OrderNo : LONGINT;Revision : BYTE) : INTEGER;
VAR LineBuff : PWOLineRecord;
BEGIN
 BtrvErr := -1;
 LineBuff := NIL;
 NEW(LineBuff);
 IF Assigned(LineBuff) THEN
  BEGIN
   LineBuff^.WOL_OrderNo := OrderNo;
   LineBuff^.WOL_LineNo  := 0;
   LineBuff^.WOL_Revision:= Revision;
   BtrvErr := 0;
   WHILE (BtrvErr = 0) DO
    BEGIN
     IF (ReadRecord('GE',TRUE,FALSE,LineBuff^,0) = 0) THEN
      BEGIN
       IF (LineBuff^.WOL_OrderNo <> OrderNo)
        OR (LineBuff^.WOL_Revision <> Revision) THEN Break;
       DeleteRecord;
      END;
    END;
   Dispose(LineBuff);
  END;
 IF ((BtrvErr =4) OR (BtrvErr =9)) THEN DelLinesForOrder := 0
 ELSE DelLinesForOrder := BtrvErr;
END;


FUNCTION IsThisLineCompleteForCurrMix(WOHPtr   : PWOHeaderRecord;
                                      WorkLRec : PWOLineRecord;
                                      WghsDoneForCurrMix : LONGINT;
                                      WtDoneForCurrMix : DOUBLE) : BOOLEAN;
VAR
   Complete       : BOOLEAN;
   {TempIngRec     : TIngredient_Record;}
   LineWtRequired : DOUBLE;
   LowestLineWt,
   HighestLineWt  : DOUBLE;
   MinRemainingWt : DOUBLE;
BEGIN
 WITH WOHPtr^ DO
  BEGIN
    BEGIN
     CalcLineGrossWtReqdForCurrMix(WOHPtr,WorkLRec);
(*   IngredientFile^.GetIngredient(WorkLRec^.WOL_Ingredient,TempIngRec,FALSE);*)
     IF WorkLRec^.WOL_ProcessType = PTStep THEN
      BEGIN
       Complete :=
         WghsDoneForCurrMix >= CalcLineWeighingsReqdForCurrMix(WOHPtr,
                                                               WorkLRec);
      END
     ELSE
      BEGIN
       LineWtRequired := CalcLineGrossWtReqdForCurrMix(WOHPtr,WorkLRec);
       {CalcIngredientTolWts(@TempIngRec,}
       CalcWOLineTolWts(  WorkLRec,
                          LineWtRequired, { need know tolerance on mix tot }
                          WOHPtr^.WOH_MixType,
                          LineWtRequired,
                          0.0,            { weight done }
                          LowestLineWt,
                          HighestLineWt);
       Complete := (CompareWts(WtDoneForCurrMix, LowestLineWt) >= 0);

(*     { is smallest weight remaining less than half a scale increment? }
       MinRemainingWt := LowestLineWt - WtDoneForCurrMix;
       RoundWtToScaleRes(MinRemainingWt);
       Complete := CompareWts(MinRemainingWt, 0.0) <= 0;

       no - this is no good - scales with different increments would
       see the line status differently and could set mix status to complete
       prematurely.

       Therefore tolerance band on weighing must make sure weight goes on
       or over min wt requirement ie. round wts up to nearest scale increment.
*)
      END;
    END;
  END;
 IsThisLineCompleteForCurrMix := Complete;
END;

FUNCTION LineNoCompleteForCurrMix(WOHPtr : PWOHeaderRecord;
                                  LineNo : LONGINT) : BOOLEAN;
VAR  WorkLRec : TWOLineRecord;
     Complete : BOOLEAN;
     Weighings: LONGINT;
     Wt       : DOUBLE;

BEGIN
 Complete := FALSE;
 IF WorkLineFile^.Get_WO_Line_Record(WOHPtr^.WOH_OrderNo,
                                     WOHPtr^.WOH_Revision,
                                     LineNo,WorkLRec)= 0 THEN
  BEGIN
   WITH WOHPtr^ DO
     TransFile^.GetTotsForMixLine(WOH_OrderNo, WOH_Revision, WOH_CurrentMix,
                                LineNo, Weighings, Wt);
   Complete := IsThisLineCompleteForCurrMix(WOHPtr,@WorkLRec,Weighings,Wt);
  END;
 LineNoCompleteForCurrMix := Complete;
END;

FUNCTION AllLinesCompleteForCurrMix(VAR OrdHRec : TWOHeaderRecord) : BOOLEAN;
VAR
    MixComplete  : BOOLEAN;
    WorkLRec     : TWOLineRecord;
    Weighings    : LONGINT;
    Wt           : DOUBLE;
    ReadErr      : INTEGER;
BEGIN
 MixComplete := TRUE; {If No Lines Found Then mix Must Be Complete}
 WITH OrdHRec, WorkLRec DO
  BEGIN
   FillChar(WorkLRec, SizeOf(WorkLRec), 0);
   WOL_OrderNo := WOH_OrderNo;
   WOL_Revision:= WOH_Revision;
   WOL_LineNo  := MaxLongint; { GO BACKWARDS TO TRY TO HIT INCOMPLETE LINE QUICKLY }
   ReadErr := WorkLineFile^.ReadRecord('LE',FALSE,FALSE,WorkLRec,0);
   WHILE (ReadErr = 0)
   AND   (WOL_OrderNo = WOH_OrderNo)
   AND   (WOL_Revision= WOH_Revision) DO
    BEGIN
     WITH OrdHRec DO
       TransFile^.GetTotsForMixLine(WOH_OrderNo, WOH_Revision, WOH_CurrentMix,
                                    WOL_LineNo, Weighings, Wt);

     IF NOT IsThisLineCompleteForCurrMix(@ORDHRec,@WorkLRec,Weighings,Wt) THEN
      BEGIN
       MixComplete := FALSE;
       BREAK;
      {*****}
      END;
     ReadErr := WorkLineFile^.ReadRecord('GP',FALSE,FALSE,WorkLRec,0);
    END;
  END;
 AllLinesCompleteForCurrMix := MixComplete;
END;


{$IFDEF TERMINAL}
FUNCTION FindNextWipLineForTerminal(OrdHRec : PWOHeaderRecord;
                                    StartLineNo : LONGINT) : LONGINT;
{REQUIRES CurrentMix number initialised in OrdHRec.
 PROMISES 1. Returns 0 if no lines found relevant to terminal
             (DOESNT MEAN MIX IS COMPLETE)
          2. Will return StartLineNo if its not complete for current mix.
}
VAR
    RetLineNo    : LONGINT;
    WorkLRec     : TWOLineRecord;
    Weighings    : LONGINT;
    Wt           : DOUBLE;
    ReadErr      : INTEGER;
    OpCode       : STRING[2];
    IngRec       : TIngredient_Record;
    PassNo       : INTEGER; { 1 = From Current line No; 2 = line 1..StartLineNo-1}
    IsAChildLine : BOOLEAN;
BEGIN
 RetLineNo := 0;
 WITH OrdHRec^, WorkLRec DO
  BEGIN
   FillChar(WorkLRec, SizeOf(WorkLRec), 0);
   WOL_OrderNo := WOH_OrderNo;
   WOL_Revision:= WOH_Revision;
   WOL_LineNo  := StartLineNo -1;
   OpCode := 'GT';
   PassNo := 1;
   REPEAT
     ReadErr := WorkLineFile^.ReadRecord(OpCode,FALSE,FALSE,WorkLRec,0);

     IsAChildLine := (ReadErr = 0)
                 AND (WOL_OrderNo = WOH_OrderNo)
                 AND (WOL_Revision= WOH_Revision);

     IF IsAChildLine THEN { can it be worked on? }
      BEGIN
       IngredientFile^.GetIngredient(WOL_Ingredient,IngRec, FALSE);
       IF Str_Equal(Config_Rec^.CONF_PrepArea,IngRec.ING_PrepArea,
                    Length(IngRec.ING_PrepArea)) THEN
        BEGIN
         TransFile^.GetTotsForMixLine(WOH_OrderNo, WOH_Revision, WOH_CurrentMix,
                                      WOL_LineNo, Weighings, Wt);

         IF NOT IsThisLineCompleteForCurrMix(ORDHRec,@WorkLRec,Weighings,Wt) THEN
          BEGIN
           RetLineNo := WorkLRec.WOL_LineNo;
           BREAK;
          {*****}
          END;
        END;
      END;

     { NOT FOUND A LINE YET }
     IF  (PassNo > 1)
     AND IsAChildLine
     AND (WOL_LineNo = (StartLineNo-1)) THEN { come back to start point }
       BREAK;
      {*****}

     IF (NOT IsAChildLine) THEN      { gone too far }
      BEGIN
       IF  (PassNo = 1)
       AND (StartLineNo > 1) THEN { try from line 1 onwards }
        BEGIN
         FillChar(WorkLRec, SizeOf(WorkLRec), 0);
         WOL_OrderNo := WOH_OrderNo;
         WOL_Revision:= WOH_Revision;
         WOL_LineNo  := 0;
         Inc(PassNo);
        END
       ELSE { no more lines to try }
        BEGIN
         BREAK;
        {*****}
        END;
      END;
   UNTIL FALSE;
  END;
 FindNextWipLineForTerminal := RetLineNo;
END;
{$ENDIF}

FUNCTION OrderComplete(VAR OrdHRec : TWOHeaderRecord): BOOLEAN;
BEGIN
 OrderComplete := OrdHRec.WOH_MixDone >= OrdHRec.WOH_NumMixes;
END;

FUNCTION OrderNoToStr(OrderNo :LONGINT;Revision : BYTE) : STRING;
VAR S : STRING[10];
BEGIN
 S := IntToZeroStr(OrderNo,6)+'/'+IntToZeroStr(Revision,2);
 OrderNoToStr := S;
END;

FUNCTION OrderMixToBarcode(AnOrdHeader : PWOHeaderRecord;
                           AMid : BYTE) : STRING;
BEGIN
 WITH AnOrdHeader^ DO
   OrderMixToBarcode := IntToZeroStr(WOH_OrderNo,6)+
                        IntToZeroStr(WOH_Revision,2)+
                        IntToZeroStr(WOH_CurrentMix,4)+
                        IntToZeroStr(AMid,2);
END;

PROCEDURE StrToOrderNo(OrdStr : STRING;VAR OrderNo : LONGINT;VAR Revision :BYTE);
VAR Dummy : INTEGER;
BEGIN
 VAL(COPY(OrdStr,1,6),OrderNo,Dummy);
 VAL(Copy(OrdStr,8,2),Revision,Dummy);
END;


PROCEDURE LoadWOHeaderWithRecipeHeader(VAR WorkHRec   : TWOHeaderRecord;
                                       VAR RecipeHRec : TRecipeHeaderRecord{CONST});
BEGIN
 WITH WorkHRec,RecipeHRec DO
  BEGIN
   WOH_RecipeNo      := RH_RecipeNo;
   WOH_MixType       := RH_DefaultMixType;
   WOH_MaxMixGrossWt := RH_DefaultMixWt;
   WOH_CaseWt        := RH_StdCaseWt;
   WOH_SeqFixed      := RH_DefaultSeqFixed;
   WOH_WorkGroup     := RH_WorkGroup + Space_String; { field added v1.034 }
  END;
END;


PROCEDURE PrimeWOLineForIngredient(VAR WorkLRecord : TWOLineRecord;
                                   VAR IngredientRec : TIngredient_Record);
{ note: some of these attributes might need overwriting with
        recipe attributes.
}
BEGIN
 WITH WorkLRecord,IngredientRec DO
  BEGIN
   WOL_Ingredient      := ING_Ingredient;
   WOL_SpecialInstr[1] := ING_DefaultInstructions[1];
   WOL_SpecialInstr[2] := ING_DefaultInstructions[2];
   WOL_ProcessType     := ING_DefaultProcessType;
   WOL_FixedWt         := ING_DefaultStdWt;
   WOL_Yield           := ING_DefaultYield;   { also defined in recipes }
   WOL_LowTol          := ING_DefaultLowTol;  { also defined in recipes }
   WOL_HighTol         := ING_DefaultHighTol; { also defined in recipes }
   WOL_ContainerSize   := ING_DefaultContSize;{ also defined in recipes }
  END;
END;


{NB Needs WOH_TargetWt Set In WorkHRec TO Work}
PROCEDURE RecipeToOrder(VAR WorkHRec         : TWOHeaderRecord;
                        VAR WO_Lines         : WorkLineList;
                        VAR RecipeToCopyFrom : TRecipeRef);
VAR RecipeNo : TRecipeRef;
    RcpHead  : TRecipeHeaderRecord;
    RcpLine  : TRecipeLineRecord;
    I        : INTEGER;
    ReadErr  : INTEGER;


  PROCEDURE RecipeLineToWorkLine;
  VAR IngredientRec : TIngredient_Record;
  BEGIN
   NEW(WO_Lines[I]);
   WorkLineFile^.InitRecord(WO_Lines[I]^); { blank it out }
   IngredientFile^.GetIngredient(RcpLine.RL_Ingredient,IngredientRec,FALSE);
   PrimeWOLineForIngredient(WO_Lines[i]^,IngredientRec ); {prime with ingr rec }
   WITH WO_Lines[I]^,RcpLine DO
    BEGIN
     WOL_LineNo        := RL_LineNo;
     WOL_KeyIngredient := RL_DefaultKeyIngred;
     WOL_Ratio         := RL_DefaultRatio;
     WOL_ContainerSize := RL_DefaultContSize;{ override default ingred size}
     WOL_Yield         := RL_DefaultYield;   { override default ingred yield }
     WOL_HighTol       := RL_DefaultHighTol; { override default ingred tol }
     WOL_LowTol        := RL_DefaultLowTol;  { override default ingred tol }
    END;
  END;

BEGIN
 IngredientFile^.OpenFile;
 I := 1;
 IF RecipeHeaderFile^.OpenFile+RecipeLineFile^.OpenFile = 0 THEN
  BEGIN
   IF RecipeHeaderFile^.ReadRecipeHeader(RcpHead,RecipeToCopyFrom) = 0 THEN
    BEGIN
     LoadWOHeaderWithRecipeHeader(WorkHRec, RcpHead);
     RcpLine.RL_HUniqueRef := RcpHead.RH_UniqueRef;
     RcpLine.RL_LineNo     := 0;
     ReadErr := RecipeLineFile^.ReadRecord('GE',FALSE,FALSE,RcpLine,0);
     WHILE (ReadErr = 0) AND (RcpLine.RL_HUniqueRef = RcpHead.RH_UniqueRef) DO
      BEGIN
       RecipeLineToWorkLine;
       INC(I);
       ReadErr := RecipeLineFile^.ReadRecord('GN',FALSE,FALSE,RcpLine,0);
      END;
    END
   ELSE Disp_Error_Msg('No Recipe Found With Code '+RecipeToCopyFrom);
   RecipeHeaderFile^.CloseFile;
   RecipeLineFile^.CloseFile;
  END;
 IngredientFile^.CloseFile;
END;


FUNCTION GetMixLineRecord(ForWOLine   : PWOLineRecord;
                          ForMixNo    : LONGINT;
                          VAR MixLRec : TMixLineRecord) : INTEGER;
BEGIN
 FillChar(MixLRec, SizeOf(MixLRec), 0);
 WITH MixLRec, ForWOLine^ DO
  BEGIN
   ML_OrderNo   := WOL_OrderNo;
   ML_Revision  := WOL_Revision;
   ML_MixNo     := ForMixNo;
   ML_LineNo    := WOL_LineNo;
   GetMixLineRecord := TransFile^.GetTotsForMixLine(ML_OrderNo,
                                                    ML_Revision,
                                                    ML_MixNo,
                                                    ML_LineNo,
                                                    ML_WghsDone, {VAR}
                                                    ML_WtDone);  {VAR}
  END;
END;

{------------------ TWOrderObject (Work Order Object) ---------------------}

CONSTRUCTOR TWOrderObject.Init;
BEGIN
 WorkHeaderFile^.InitRecord(WO_Header);
 FillChar(WO_Lines,      SizeOf(WO_Lines), 0);
 FillChar(WO_LinePos,    SizeOf(WO_LinePos), 0);
 FillChar(WO_DeleteList, SizeOf(WO_DeleteList), 0);
END;

DESTRUCTOR TWOrderObject.Done;
BEGIN
 ClearLines;
END;

PROCEDURE TWOrderObject.ClearLines;
VAR LPA        : LONGINT;
    TempPtr,
    DeletePtr  : PDeleteList;

BEGIN
 FOR LPA :=1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF Assigned(WO_Lines[LPA]) THEN
     Dispose(WO_Lines[LPA]);
   WO_Lines[LPA] := NIL;
   WO_LinePos[LPA] := 0;
  END;

 { ClearDown List Of Records Marked For Deletion }
 TempPtr := WO_DeleteList;
 WHILE (TempPtr <> NIL) DO
  BEGIN
   DeletePtr := TempPtr;
   TempPtr := TempPtr^.Next;
   Dispose(DeletePtr);
  END;
END;

PROCEDURE TWOrderObject.ResetCalculatedFields;
VAR OrdLine      : INTEGER;
    TotalGrossWt : DOUBLE;
    {Containers  : LONGINT;}
    MixesLongint : LONGINT;
    LargestContainerSize : DOUBLE;

BEGIN
 WITH WO_Header DO
  BEGIN
   IF WOH_SelectByCase THEN
     WOH_FinishWtReqd := WOH_NumCases * WOH_CaseWt
   ELSE
     WOH_NumCases := 0; { make sure auto created orders comply with editor }
  END;

 LargestContainerSize := 0.0;
 IF WO_Header.WOH_MixType = mt_EqualContainersPerMix THEN { find largest container size }
  BEGIN
   FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
    BEGIN
     IF (Assigned(WO_Lines[OrdLine])) THEN
      BEGIN
       IF WO_Lines[OrdLine]^.WOL_ContainerSize > LargestContainerSize THEN
         LargestContainerSize := WO_Lines[OrdLine]^.WOL_ContainerSize;
      END;
    END;
  END;

 TotalGrossWt := 0.0;
 FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF (Assigned(WO_Lines[OrdLine])) THEN
    BEGIN
     WITH WO_Header, WO_Lines[OrdLine]^ DO
      BEGIN
       IF WOH_MixType = mt_EqualContainersPerMix THEN {all ingredients go into  }
        BEGIN                                  {common container         }
         WOL_ContainerSize := LargestContainerSize;
        END
       ELSE IF WOH_MixType = mt_SingleContainerPerMix THEN {the container}
        BEGIN                               { contains enough for one mix }
         WOL_ContainerSize := WOH_MaxMixGrossWt;
        END;

       TotalGrossWt := TotalGrossWt +
                        CalcLineGrossWtReqdFromRecipeNet(WOH_FinishWtReqd,
                                                         WOL_Ratio,
                                                         WOL_Yield);
      END;
    END;
  END;

 WITH WO_Header DO
  BEGIN
   WOH_TotIngredWtReqd := TotalGrossWt;
   MixesLongint := RoundWtUpToUnits(WOH_TotIngredWtReqd, WOH_MaxMixGrossWt);
   IF MixesLongint < 10000 THEN
     WOH_NumMixes := MixesLongint
   ELSE
     WOH_NumMixes := 1;

   {Only Set The TargetBatchWt If No Weighing To The Order Has Occured Or
    The Value Is Change On The Scale When It should Not Be}
   IF CompareWts(WOH_WtDoneGross,0.0) <= 0 THEN
    BEGIN
     {WOH_TargetBatchWt := DblMin(WOH_MaxMixGrossWt,WOH_TotIngredWtReqd);}
     WOH_CurrentMix    := 1;
    END;
  END;
END;

FUNCTION TWOrderObject.AllLinesAreUntoleranced : BOOLEAN;
{ if no lines then returns FALSE }
VAR
   OrdLine      : INTEGER;
   Lines  : INTEGER;
BEGIN
 Lines := 0;
 AllLinesAreUntoleranced := FALSE;
 FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF (Assigned(WO_Lines[OrdLine])) THEN
    BEGIN
     Inc(Lines);
     WITH WO_Lines[OrdLine]^ DO
      BEGIN
       IF (WOL_HighTol > 0.0001)
       OR (WOL_LowTol  > 0.0001) THEN
         EXIT;
        {****}
      END;
    END;
  END;
 AllLinesAreUntoleranced := Lines > 0;
END;

PROCEDURE TWOrderObject.ApplyIngredTols;
VAR
  TempIngRec : TIngredient_Record;
  OrdLine    : INTEGER;
BEGIN
 FOR OrdLine := 1 TO MAX_LINES_ON_RECORD DO
  BEGIN
   IF (Assigned(WO_Lines[OrdLine])) THEN
    BEGIN
     WITH WO_Lines[OrdLine]^ DO
      BEGIN
       IF IngredientFile^.GetIngredient(WOL_Ingredient, TempIngRec, FALSE) = 0 THEN
        BEGIN
         WOL_HighTol := TempIngRec.ING_DefaultHighTol;
         WOL_LowTol  := TempIngRec.ING_DefaultLowTol;
        END;
      END;
    END;
  END;
END;
{---------------------------------------------------------------------------}


BEGIN
 WorkHeaderFile := NIL;
 WorkLineFile   := NIL;
END.

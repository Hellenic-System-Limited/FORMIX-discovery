(****************************************************************************
*  UNIT          : FXCFG                                                    *
*  AUTHOR        : S. M. Wright                                             *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : FORMIX CONFIG RECORD DEFINITION                          *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXCFG;

INTERFACE

USES Crt,Dos,F6CsvUtl,F6STDCTV,F6STDUTL,FXFINI,FXModCtv
{$IFDEF TERMINAL}
,SFXConst
{$ENDIF};

CONST MAX_LINES_ON_RECORD  = 100;

TYPE Conf_ptr = ^Config_Record;
     Config_Record = PACKED RECORD
      Conf_Addr   : ARRAY[1..5] OF STRING[30];
      Conf_FPath  : STRING[50];         {data file path       }
      Conf_SFPath : STRING[50];         {shared data file path}
      Conf_TPath  : STRING[50];         {text file path       }
      Conf_RPath  : STRING[50];         {ramdisk path         }
      Conf_APath  : STRING[50];         {archive file path    }
      Conf_EPath  : STRING[50];         {export path          }
      {Conf_E2Path : STRING[50];}         {export backup path   }
      Conf_ImpPath: STRING[50];         {Import Path          }
      Conf_Banner : STRING[24];         {screen heading       }
      Conf_PArray : ARRAY[1..3] OF BYTE;{ Default Printer Array }
      Conf_PtrRedirectFile : STRING[12];{ Printer Redirect File Name         }
      Conf_GlobalLot : BOOLEAN;
      Conf_DefaultWtRange : CHAR;
      Conf_Stock  : BOOLEAN;
      Conf_Batches: BOOLEAN; { 1. Forces order editor to show 'Batches'
                                  and 'Batch Wt'.
                               2. Forces recipe editor batch wt = mix wt }
      Conf_RoundWeights : BOOLEAN;
      Conf_ScaleRes     : DOUBLE; { scale resolution }
      Conf_OneRecipeCasePerProdCase : BOOLEAN;
      Conf_ShowCostWeightUsed : BOOLEAN;
      Conf_AutoOrderImport    : BOOLEAN;
      CONF_EqualMixes         : BOOLEAN;
      CONF_LastMixCompensation: BOOLEAN;
{$IFDEF TERMINAL}
      CONF_PrepArea           : STRING[8];
      CONF_Fops6FilePath      : STRING[50];
      CONF_CommTempPath       : STRING[50];
      CONF_ScaleDetailsFileName:STRING[12];
{$ENDIF}
      CONF_PromptForSource    : BOOLEAN;
      CONF_IntakeMid          : STRING[2];
      CONF_SourceOptional     : BOOLEAN;
      CONF_AcceptLabelWeight  : BOOLEAN;
      CONF_IngredientsInFops6 : BOOLEAN;
{$IFDEF FOPSTRACELINK}
      CONF_SendIssuesToFops6  : BOOLEAN;
{$ENDIF}
      CONF_ScanMixLabelsFirst : BOOLEAN;
      CONF_ShowTolOnRecipeEdit: BOOLEAN;
      CONF_UnitName           : STRING[7];
      CONF_SglUnitName        : STRING[5];
      CONF_FullContainerHighTol:DOUBLE;
      CONF_NoAutoCancelOfTares: BOOLEAN;
      CONF_TouchScreen        : BOOLEAN;
      CONF_OrdCustomNum1      : STRING[20]; { title of customizable field }
      CONF_OrdCustomAlpha1    : STRING[20];
      CONF_OrdCustomAlpha2    : STRING[20];
      CONF_PrinterPortAddr    : STRING[5];
     END;

VAR Config_Rec : Conf_Ptr;
    UnlockH,UnlockM,UnlockY,
    UnlockMo,UnlockD : WORD;

FUNCTION Allocate_Config_Rec : BOOLEAN;
PROCEDURE Load_Config_Rec;
PROCEDURE Dispose_Config_Rec;


IMPLEMENTATION
{USES FXFWork;}
FUNCTION Allocate_Config_Rec : BOOLEAN;
BEGIN
 NEW(Config_Rec);
 FillChar(Config_Rec^,SizeOf(Config_Rec^),0);
 Allocate_Config_Rec := Assigned(Config_Rec);
END;

PROCEDURE Dispose_Config_Rec;
BEGIN
 IF Assigned(Config_Rec) THEN DISPOSE(Config_Rec);
 Config_Rec := NIL;
END;

PROCEDURE Load_Config_Rec;
VAR WrkStr : STRING;
    I : INTEGER;
BEGIN
 PreCacheIniFiles;
 WITH Config_Rec^ DO
  BEGIN
   Conf_OneRecipeCasePerProdCase := GetExtSwitch(FXUseSingleProds,all,FALSE);
   Conf_ShowCostWeightUsed := GetExtSwitch(FXShowCostWeightUsed,all,FALSE);

   Conf_RoundWeights := GetExtSwitch(FXRoundWeights,all,FALSE);
   Conf_ScaleRes     := GetExtFloat(FXWtRoundMod,all,0.001,1.0,0.005);
   Conf_Batches      := GetExtSwitch(FXBatches,all,FALSE);

   Conf_Addr[1]:= GetUpCaseExtVar(FXAddress1,all)+SPACE_STRING;
   Conf_Addr[2]:= GetUpCaseExtVar(FXAddress2,all)+SPACE_STRING;
   Conf_Addr[3]:= GetUpCaseExtVar(FXAddress3,all)+SPACE_STRING;
   Conf_Addr[4]:= GetUpCaseExtVar(FXAddress4,all)+SPACE_STRING;
   Conf_Addr[5]:= GetUpCaseExtVar(FXAddress5,all)+SPACE_STRING;
   Conf_FPath  := GetExtPath(FXFilePath,all);
   Conf_SFPath := GetExtFilePath(FXShareFilePath,all,Conf_FPath);
   Conf_TPath  := GetExtPath(FXTextPath,all);
   Conf_RPath  := GetExtPath(FXRamPath,all);
   Conf_APath  := GetExtPath(FXArcPath,all);
   Conf_EPath  := GetExtPath(FXExportPath,all);
   Conf_ImpPath:= GetExtPath(FXImportPath,all);
(*
   Conf_E2Path := GetExtVar(FXBackUpExportPath,all)+SPACE_STRING;}
   IF Stripped(Conf_E2Path,30,' ') <> '' THEN
    BEGIN
     Conf_E2Path := GetExtPath(FXBackUpExportPath,all);
    END;
*)
   Conf_Banner := GetUpCaseExtVar(FXBanner,all)+SPACE_STRING;
   Conf_GlobalLot := GetExtSwitch(FXGlobalLot,all,FALSE);
   WrkStr := GetUpCaseExtVar(FXRange,all);
   IF (Length(WrkStr) > 0) AND (WrkStr[1] IN [KgRange,LbRange]) THEN
    Conf_DefaultWtRange := WrkStr[1]
   ELSE
    Conf_DefaultWtRange := KgRange;
   GetExtColours(FXBackCol,all,
     BackNormBack,BackLowFore,BackHighFore,BackRevBack,BackRevFore,
     Black,LightGray,White,Blue,LightCyan);

   GetExtColours(FXForeCol,all,
     ForeNormBack,ForeLowFore,ForeHighFore,ForeRevBack,ForeRevFore,
     Black,Cyan,Yellow,Blue,White);

   Conf_Stock := GetExtSwitch(FXStock,all,FALSE);
   Conf_EqualMixes := GetExtSwitch(FXEqualMixes,all,FALSE);
   Conf_LastMixCompensation := GetExtSwitch(FXLastMixCompensation,all,TRUE);
{$IFDEF TERMINAL}
   CONF_PrepArea   := GetExtVar(FXPreperationArea,all);
   IF NowtButSpace(CONF_PrepArea) THEN CONF_PrepArea := '*'+Space_String;
{$ENDIF}
   CONF_UnitName := GetExtVar(FXUnitName,all);
   IF NowtButSpace(CONF_UnitName) THEN
     CONF_UnitName := 'Cases';
   CONF_UnitName := CONF_UnitName + Space_String;

   CONF_SglUnitName := GetExtVar(FXSglUnitName,all);
   IF NowtButSpace(CONF_SglUnitName) THEN
     CONF_SglUnitName := 'Case';
   CONF_SglUnitName := CONF_SglUnitName + Space_String;

{$IFDEF TERMINAL}
   CONF_Fops6FilePath  := GetExtPath(FXFops6FilePath,all);
   CONF_CommTempPath   := GetExtPath(FXCommTempPath,all);
   CONF_ScaleDetailsFileName := GetExtVar(SFXScaleDetails,all);
   IF (NowtButSpace(CONF_ScaleDetailsFileName)) THEN
     CONF_ScaleDetailsFilename := 'SCALE.FIL';
   CONF_PrinterPortAddr := GetExtVar(SFXPrinterPortAddr,all);
   CONF_PromptForSource := GetExtSwitch(SFXPromptForSource,all,
 {$IFDEF LAZENBY}                        TRUE
 {$ELSE}                                 FALSE
 {$ENDIF}                               );
   CONF_IntakeMid      := GetExtVar(SFXIntakeMid,all);
   CONF_SourceOptional := GetExtSwitch(SFXSourceOptional,all,FALSE);
   CONF_AcceptLabelWeight  := GetExtSwitch(SFXAcceptLabelWeight,all,FALSE);
   CONF_IngredientsInFops6 := GetExtSwitch(FXIngredientsInFops6,all,
 {$IFDEF LAZENBY}                           TRUE
 {$ELSE}                                    FALSE
 {$ENDIF}                                  );
 {$IFDEF FOPSTRACELINK}
   CONF_SendIssuesToFops6  := GetExtSwitch(SFXSendIssuesToFops6,all,TRUE);
 {$ENDIF}
   CONF_ScanMixLabelsFirst := GetExtSwitch(SFXScanMixLabelsFirst,all,FALSE);
   CONF_ShowTolOnRecipeEdit:= GetExtSwitch(FXShowTolOnRecipeEdit,all,TRUE);
   CONF_FullContainerHighTol:=GetExtFloat(FXFullContainerHighTol,all,
                                          0.0, 99.0, 0.0);
   CONF_NoAutoCancelOfTares:=GetExtSwitch(SFXNoAutoCancelOfTares,all,FALSE);
   CONF_TouchScreen := GetExtSwitch(SFXTouchScreen,All,
 {$IFDEF TERMINAL}                   TRUE
 {$ELSE}                             FALSE
 {$ENDIF}                           );
{$ENDIF}
{SMW 3/12/08}
   CONF_OrdCustomNum1   := GetExtVar(FXOrdCustomNum1,SYSINI);
   IF NowtButSpace(CONF_OrdCustomNum1) THEN
     CONF_OrdCustomNum1 := 'OLSN';
   CONF_OrdCustomNum1 := CONF_OrdCustomNum1 + Space_String;

   CONF_OrdCustomAlpha1 := GetExtVar(FXOrdCustomAlpha1,SYSINI);
   IF NowtButSpace(CONF_OrdCustomAlpha1) THEN
     CONF_OrdCustomAlpha1 := 'Schedule';
   CONF_OrdCustomAlpha1 := CONF_OrdCustomAlpha1 + Space_String;

   CONF_OrdCustomAlpha2 := GetExtVar(FXOrdCustomAlpha2,SYSINI);
   IF NowtButSpace(CONF_OrdCustomAlpha2) THEN
     CONF_OrdCustomAlpha2 := 'Task';
   CONF_OrdCustomAlpha2 := CONF_OrdCustomAlpha2 + Space_String;


   PROP_Colour         := GetExtSwitch(FXColour,all,TRUE);
   PROP_Beep           := GetExtSwitch(FXBeep,all,TRUE);
   PROP_TextFilePath   := Conf_TPath;
   PROP_RamFilePath    := Conf_RPath;
   PROP_FilFilePath    := Conf_FPath;
   PROP_DefaultPrinter := GetExtNum(FXDefaultPrinter,all,1,2,1);
   { Printer Types To Be Retrieved From INI File }
   FOR I := 1 TO MAX_PRN_PORT DO
    BEGIN
     CASE I OF
       1 : WrkStr := GetExtVar(FXDefPrinter1,all);
       2 : WrkStr := GetExtVar(FXDefPrinter2,all);
       3 : WrkStr := GetExtVar(FXDefPrinter3,all);
       ELSE WrkStr := '';
      END;
     GetFromStr(WrkStr, rtByte, 1, PROP_PArray[I]);
     IF NOT NowtButSpace(WrkStr) THEN { second parameter }
      BEGIN { overwrite default }
       GetFromStr(WrkStr, rtString, SizeOf(PROP_PrinterName[1])-1,
                  PROP_PrinterName[I]);
       PROP_PrinterName[I] := Clip(PROP_PrinterName[I]);
      END;
    END;
  END;
 UnCacheIniFiles;
END;

BEGIN
 Config_Rec :=NIL;
END.

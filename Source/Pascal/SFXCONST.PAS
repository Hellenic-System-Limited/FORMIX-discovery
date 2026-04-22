(****************************************************************************
*  UNIT          : SFXConst                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       :                                                          *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXConst;

INTERFACE
USES SFXgraph,Crt,F6StdUtl,FXFIni,SFXStd,F6StdCtv,SFXTime;

             {Windows Graphical Positioning}
             {-----------------------------}

CONST All_Win_Right  = 470;   {All Of these Windows have the same width}
CONST All_Win_Left   = 004;   {All Windows have same left coordinate   }
CONST Win_Char_Size  =  32;   {16x8 Font At moment}
CONST Win_Leading    =  04;   {Gap Between Windows}

{Header Window Contains one line of text }
CONST Header_Win_Top    = Win_Leading;
CONST Header_Win_Bottom = Header_Win_Top+(Win_Char_Size+1)+Win_Leading;
CONST Header_Text_Y     = (Header_Win_Top+8) DIV 8;




CONST
{Screen Button Positions}
 BROWSER_LX = 0;
 BROWSER_RX = MaxX;
 BOXTOP    = MaxY-8-95;
 ButtonHeight = 58;
 ButtonTop = BoxTop-ButtonHeight-6;
 ButtonBot = BoxTop-6;

 OpButtonBot= MaxY - 8;
 OpButtonTop= OpButtonBot - ButtonHeight;

 OpBROWSER_LX=24;
 OpBrowser_TY= {117 works well for 9 boxes}
               OpButtonTop-8-(7*40)+1;


 ButtonSz  = 96;       {Width of the buttons}
 ButtonSc  = 12;       {spacing between two buttons}

CONST
 But1Start = BROWSER_LX;
 But1Stop  = But1Start+ButtonSz;
 But2Start = But1Stop +ButtonSc;
 But2Stop  = But2Start+ButtonSz;
 But3Start = But2Stop +ButtonSc;
 But3Stop  = But3Start+ButtonSz;
 But4Start = But3Stop +ButtonSc;
 But4Stop  = But4Start+ButtonSz;
 But5Start = But4Stop +ButtonSc;
 But5Stop  = But5Start+ButtonSz;

 ButL1Start= But1Start;
 ButL1Stop = ButL1Start+ButtonSz;
 ButL2Start= ButL1Stop +ButtonSc;
 ButL2Stop = ButL2Start+ButtonSz;
 ButR1Start= BROWSER_RX-ButtonSz-4;
 ButR1Stop = ButR1Start+ButtonSz;
 ButR2Start= ButR1Start-ButtonSz-ButtonSc;
 ButR2Stop = ButR2Start+ButtonSz;

 ButCRStart= BROWSER_LX + ((BROWSER_RX-BROWSER_LX) DIV 2) -ButtonSc DIV 2-ButtonSz;
 ButCRStop = ButCRStart+ButtonSz;
 ButCLStart= BROWSER_LX + ((BROWSER_RX-BROWSER_LX) DIV 2) +ButtonSc DIV 2;
 ButCLStop = ButCLStart+ButtonSz;


(*
CONST {ScaleTypeNames}
 WeighMasterScale  : STRING = 'WEIGHMASTER';
 System80Scale     : STRING = 'SYSTEM80';
 LucidScale        : STRING = 'LUCID';
 NoScale           : STRING = 'NOSCALE';
*)

TYPE TConnectedScale = (TInvalidScale,TNoScale,TWeigh_Master,TSystem80,TLucid);

CONST ScaleNames : ARRAY[TNoScale..TLucid] OF STRING[30] =
                 ('NOSCALE','WEIGHMASTER','SYSTEM80','LUCID');

TYPE TPrinterTypes = (NO_Printer,UBI_Printer,ELTRON_Printer,ELTRON_Printer2,IPL_Printer);

CONST PrinterNames : ARRAY[UBI_Printer..IPL_Printer] OF STRING[20] =
                           ('UBI','ELTRON','ELTRON2','IPL');

TYPE
     TScaleConfRecord = PACKED RECORD
      GetRefreshTime        : LONGINT;
      GetMessageSearchTime  : TTimedEvent;
      UseMessaging          : BOOLEAN;
      MenuPasswordProtected : BOOLEAN;
      DebugLogOff           : BOOLEAN;
      UserIDRequired        : BOOLEAN;
      GetLogOutTime         : LONGINT;
      PrinterType           : TPrinterTypes;
      ColourDisplay         : BOOLEAN;
      GreyScaleDisplay      : BOOLEAN;
     END;


PROCEDURE AdvancedOptionsInit;
FUNCTION  GetScaleTimeOut       : INTEGER;
FUNCTION  GetTouchScreenTimeOut : INTEGER;
FUNCTION  InitialScale          : INTEGER;
FUNCTION  GetScaleDataFileName  : STRING;
FUNCTION  GetScaleParamFileName : STRING;
FUNCTION  GetScaleTypeFromName(TheScaleType : STRING) : TConnectedScale;
FUNCTION  GetTouchScreenSettingsFileName : STRING;
FUNCTION  GetIPLConfigFileName : STRING;


{
FUNCTION  GetSecondScalePort    : WORD;
FUNCTION  GetSecondScaleIRQ     : WORD;
FUNCTION  GetScaleType          : TConnectedScale;
FUNCTION  GetScaleBaud          : INTEGER;
}


VAR AdvancedOptionsOn   : BOOLEAN;
    ReturnToOrderOn     : BOOLEAN;
    MaxMsgTimeOut     : WORD;
    NonRefreshedMsgMinTimeOut     : WORD;
    DisregardWaitForScaleToZero : BOOLEAN;
    AutoLogOut          : BOOLEAN;

    ScaleConfRec        : TScaleConfRecord;

CONST
  {These Are needed in each ini file for each workstation}
  ScaleDataFile          : INIVAR=(V:'SFXSCALEDATAFILE';s:scale);
  ScaleParamFile         : INIVAR=(V:'SFXSCALEPARAMFILE';s:scale);
  TouchScreenSettings    : INIVAR=(V:'SFXTOUCHSETTINGS';s:main);
  StartUpScale           : INIVAR=(V:'SFXINITIALSCALE';s:scale);


  UseAdvancedOptionsMenu : INIVAR=(V:'SFXADVANCEDOPTIONS';S:scale);
  WaitForScaleZeroAtTare : INIVAR=(V:'SFXWAITFORSCALETOZEROATTARE';S:scale);
  MessageWinTimeOutVal   : INIVAR=(V:'SFXMESSAGEWINTIMEOUT';S:scale);
  UseReturnToOrder       : INIVAR=(V:'SFXALLOWEXITFROMWEIGHING';S:scale);
  RefreshCountVar        : INIVAR=(V:'SFXREFRESHTIME';s:scale);
  SearchForMsgTime       : INIVAR=(V:'SFXMSGREADTIME';s:scale);
  MessagingOn            : INIVAR=(V:'SFXUSEMSG';S:scale);
  ScaleTimeOut           : INIVAR=(V:'SFXSCALETIMEOUT';S:scale);
  TouchScreenTimeOut     : INIVAR=(V:'SFXTOUCHSCREENTIMEOUT';s:scale);
  SecretPassword         : INIVAR=(V:'SFXSECRETPASSWORD';s:scale);
  MenuNeedsPassword      : INIVAR=(V:'SFXMENUPASSWORDED';s:scale);
  AutoLogOff             : INIVAR=(V:'SFXAUTOSHUTDOWN';s:scale);
  NeedUserIDToStartMix   : INIVAR=(V:'SFXUSERIDFORMIX';s:scale);
  IngredientCostUsage    : INIVAR=(V:'SFXINGREDIENTCOSTING';s:scale);
  AutoAddCostRecord      : INIVAR=(V:'SFXAUTOADDCOST';s:scale);
  EnterUserPassword      : INIVAR=(V:'SFXUSERPASSWORDING';s:scale);
  AutoLogOutTime         : INIVAR=(V:'SFXAutoLogOutTime';s:scale);
  FXAutoBatchNo          : INIVAR=(V:'SFXAutoBatchNo';s:scale);
  SFXBatchNumbersReqd    : INIVAR=(V:'SFXBatchNumbersReqd';s:scale);
  SFXRecallLotNumbers    : INIVAR=(V:'SFXRecallLotNumbers';s:scale);
  PrinterType            : INIVAR=(V:'SFXPRINTERTYPE';s:scale);
  SFXPrinterPortAddr     : INIVAR=(V:'SFXPrinterPortAddr';s:scale);
  CWindowHeader          : INIVAR=(V:'SFXWINDOWHEADERCOLOUR';s:scale);
  CWindowStaticText      : INIVAR=(V:'SFXWINDOWSTATICTEXTCOLOUR';s:scale);
  CWindowText            : INIVAR=(V:'SFXWINDOWTEXTCOLOUR';s:scale);
  CButtonText            : INIVAR=(V:'SFXBUTTONTEXTCOLOUR';s:scale);
  CPicklist              : INIVAR=(V:'SFXPICKLISTCOLOUR';s:scale);
  CMessageWin            : INIVAR=(V:'SFXMESSAGECOLOUR';s:scale);
  CFillBarOutTol         : INIVAR=(V:'SFXFILLBAROUTTOLCOLOUR';S:scale);
  CFillBarInTol          : INIVAR=(V:'SFXFILLBARINTOLCOLOUR';S:scale);
  CMixBar                : INIVAR=(V:'SFXMIXBARCOLOUR';s:scale);
  ColourLCD              : INIVAR=(V:'SFXCOLOUR';s:scale);
  Colour2GreyScale       : INIVAR=(V:'SFXGREYSCALE';s:scale);
  IPLConfigFile          : INIVAR=(V:'SFXIPLCONFIGFILE';s:scale);
{$IFDEF FOPSTRACELINK}
  SFXSendIssuesToFops6   : INIVAR = (V:'SFXSendIssuesToFops6';s:scale);
{$ENDIF}

{ UNUSED VARS}
{
  ScaleBaudRate          : INIVAR=(V:'SFXSCALEBAUD';s:scale);
  ScaleType              : INIVAR=(V:'SFXSCALETYPE';s:scale);
  SecondScalePort        : INIVAR=(V:'SFXSECONDSCALEPORT';s:scale);
  SecondScaleIRQ         : INIVAR=(V:'SFXSECONDSCALEIRQ';s:scale);
}

IMPLEMENTATION
USES SFXBas;
{VAR CurrentScaleID :BYTE;}

FUNCTION GetTouchScreenSettingsFileName : STRING;
BEGIN
 GetTouchScreenSettingsFileName := GetExtVar(TouchScreenSettings,all);
END;

FUNCTION GetScaleDataFileName : STRING;
BEGIN
 GetScaleDataFileName := GetExtVar(ScaleDataFile,all);
END;

FUNCTION GetScaleParamFileName : STRING;
BEGIN
 GetScaleParamFileName := GetExtVar(ScaleParamFile,all);
END;

{
FUNCTION GetScaleBaud : INTEGER;
BEGIN
 GetScaleBaud := GetExtNum(ScaleBaudRate,all,1,115200,9600);
END;
}
FUNCTION InitialScale : INTEGER;
BEGIN
 InitialScale := GetExtNum(StartUpScale,all,1,2,1);
END;

FUNCTION GetScaleTypeFromName(TheScaleType : STRING) : TConnectedScale;
VAR ScaleType : TConnectedScale;
BEGIN
 GetScaleTypeFromName := TNoScale;
 FOR ScaleType := TNoScale TO TLucid DO
  BEGIN
   IF (StringLIComp(ScaleNames[ScaleType],TheScaleType,Length(ScaleNames[ScaleType])) = 0) THEN
    BEGIN
     GetScaleTypeFromName := ScaleType;
     EXIT;
    END;
  END;
(*
 IF (StringLIComp(WeighMasterScale,TheScaleType,Length(WeighMasterScale)) = 0) THEN
  BEGIN
   GetScaleTypeFromName := TWeigh_Master;
  END
 ELSE IF (StringLIComp(System80Scale,TheScaleType,Length(System80Scale)) = 0) THEN
  BEGIN
   GetScaleTypeFromName := TSystem80;
  END
 ELSE IF (StringLIComp(LucidScale,TheScaleType,Length(LucidScale)) = 0) THEN
  BEGIN
   GetScaleTypeFromName := TLucid;
  END
 ELSE IF (StringLIComp(NoScale,TheScaleType,Length(NoScale)) = 0) THEN
  BEGIN
   GetScaleTypeFromName := TNoScale;
  END;
*)
END;
{
FUNCTION GetScaleType : TConnectedScale;
VAR TheScaleType : STRING;
BEGIN
 GetScaleType := TWeigh_Master;
 TheScaleType := GetExtVar(ScaleType,all);
 IF (NOT NowtButspace(TheScaleType)) THEN
  BEGIN
   GetScaleType := GetScaleTypeFromName(TheScaleType);
  END;
END;
}
{
FUNCTION GetSecondScalePort : WORD;
BEGIN
 GetSecondScalePort := GetExtNum(SecondScalePort,all,1,$FFFF,0);
END;

FUNCTION GetSecondScaleIRQ  : WORD;
BEGIN
 GetSecondScaleIRQ := GetExtNum(SecondScaleIRQ,all,0,15,0);
END;
}

FUNCTION GetScaleTimeOut : INTEGER;
BEGIN
 GetScaleTimeOut := GetExtNum(ScaleTimeOut,all,1,100,10);
END;

FUNCTION GetTouchScreenTimeOut : INTEGER;
BEGIN
 GetTouchScreenTimeOut := GetExtNum(TouchScreenTimeOut,all,1,30,5);
END;

FUNCTION GetPrinterType : TPrinterTypes;
VAR PrinterName : STRING[20];
    PrintType : TPrinterTypes;
BEGIN
 GetPrinterType := NO_Printer;
 PrinterName := GetExtVar(PrinterType,all);

 FOR PrintType := UBI_Printer TO IPL_Printer DO
  BEGIN
   IF (StringIComp(PrinterName,PrinterNames[PrintType]) = 0) THEN
    BEGIN
     GetPrinterType := PrintType;
     EXIT;
    END;
  END;
{
 IF (StringIComp(PrinterName,PrinterNames[UBI_Printer]) = 0) THEN
  GetPrinterType := UBI_Printer
 ELSE IF (StringIComp(PrinterName,PrinterNames[ELTRON_Printer]) = 0) THEN
  GetPrinterType := Eltron_Printer
 ELSE IF (StringIComp(PrinterName,PrinterNames[ELTRON_Printer2]) = 0) THEN
  GetPrinterType := Eltron_Printer2;}
END;


FUNCTION GetIPLConfigFileName : STRING;
BEGIN
  GetIPLConfigFileName := GetExtVar(IPLConfigFile,all);
END;






PROCEDURE AdvancedOptionsInit;
VAR TimeOutForMsg : STRING;
    Temp,Err,iVal : INTEGER;

  PROCEDURE SetTimeOutLengths;
  BEGIN
   TimeOutForMsg     := GetExtVar(MessageWinTimeOutVal,ALL);
   IF NowtButSpace(TimeOutForMSg) THEN
    BEGIN
     MaxMsgTimeOut := 10;
     NonRefreshedMsgMinTimeOut := 4;
    END
   ELSE
    BEGIN
     Temp := Pos(',',TimeOutForMsg);
     IF Temp <> 0 THEN
      BEGIN
       VAL(COPY(TimeOutForMsg,1,Temp-1),iVal,Err);
       MaxMsgTimeOut := Max(1,Min(60,iVal));
       VAL(COPY(TimeoutForMsg,Temp+1,Length(TimeOutForMsg)-Temp),iVal,Err);
       NonRefreshedMsgMinTimeOut := Max(1,Min(60,iVal));
      END
     ELSE
      BEGIN
       VAL(TimeOutForMsg,iVal,Err);
       MaxMsgTimeOut := Max(1,Min(60,iVal));
       NonRefreshedMsgMinTimeOut := 2;
      END;
    END;
  END;

BEGIN
 PreCacheIniFiles;     {FOR Network speed}

 AdvancedOptionsOn     := GetExtSwitch(UseAdvancedOptionsMenu,ALL,FALSE);
 DisregardWaitForScaleToZero := NOT GetExtSwitch(WaitForScaleZeroAtTare,ALL,TRUE);
 UserTotalCosting      := GetExtSwitch(IngredientCostUsage,all,FALSE);
 AutoAddCostRec        := GetExtSwitch(AutoAddCostRecord,all,FALSE);
 UserMustEnterPassword := GetExtSwitch(EnterUserPassword,all,FALSE);
 UseSecretPassword     := GetExtSwitch(SecretPassword,all,TRUE);
 AutoBatchNumbering    := GetExtSwitch(FXAutoBatchNo,all,FALSE);
 BatchNumbersReqd      := GetExtSwitch(SFXBatchNumbersReqd,all,
                       {$IFDEF LAZENBY} FALSE {$ELSE} TRUE {$ENDIF});
 RecallLotNumbers      := GetExtSwitch(SFXRecallLotNumbers,all,
                       {$IFDEF LAZENBY} FALSE {$ELSE} TRUE {$ENDIF});
 SetTimeOutLengths;
 IF AdvancedOptionsOn THEN
  BEGIN
   ReturnToOrderOn := GetExtSwitch(UseReturnToOrder,ALL,TRUE);
  END
 ELSE
  BEGIN
   ReturnToOrderOn := TRUE;
  END;

 WITH ScaleConfRec DO
  BEGIN
   ColourDisplay   := GetExtSwitch(ColourLCD,all,FALSE);
   GreyScaleDisplay:= GetExtSwitch(Colour2GreyScale,all,FALSE);

   GetRefreshTime  := GetExtNum(RefreshCountVar,all,10,1000000,30)*18;
   TimeOutForMsg   := GetExtVar(SearchForMsgTime,all);
   IF (Length(TimeOutForMsg) = 0) THEN              { If Not Specified      }
     TimeOutForMsg :='00:00,30';                    { Default To 30 Seconds }

   ExpandTimedEventStr(TimeOutForMsg,GetMessageSearchTime);
   UseMessaging := GetExtSwitch(MessagingOn,all,TRUE);
   MenuPasswordProtected := GetExtSwitch(MenuNeedsPassword,all,FALSE);
   DebugLogOff := GetExtSwitch(AutoLogOff,all,FALSE);
   UserIDRequired := GetExtSwitch(NeedUserIDToStartMix,all,TRUE);
   GetLogoutTime := GetExtNum(AutoLogOutTime,all,1,$FFFF,600);
   PrinterType := GetPrinterType;
   AddBasicFunctions(PrinterType = ELTRON_Printer2);
  END;
 UnCacheIniFiles;
END;

END.
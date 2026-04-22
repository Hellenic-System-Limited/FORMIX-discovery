PROGRAM Scale_Prompt;
{
  DESCRIPTION
  Initialises touchscreen and asks user to respond Yes/No to one question.
  Program then terminates setting DOS ERRORLEVEL to 1 if user responded: NO
  Code cut out of SFORMIX program.

  USAGE:
  1. Must be run with a command line parameter that defines an INI file that
     defines the touchscreen settings file (SFXTOUCHSETTINGS= in
     section [MAIN].
  2. Set question using PROMPT= in ini file or at command line.

  TYPICAL USAGE:
  Include in batch file that runs SFORMIX program so that user can
  terminal user can temporarily exit and return to program without switching
  off the power.
  Example Recipe Rerminal batch file:

:START
BRQMSTCP
SFORMIX FORMIXINI=WORK_002
SPROMPT FORMIXINI=WORK_002 PROMPT=Start_Again?
IF NOT ERRORLEVEL 1 GOTO START
REM -- only errorlevel 0 will loop back. run 'IF /?' for explanation.
REM
BRQMSTCP /U

}

{$IFNDEF TERMINAL}
 Define Terminal First
{$ENDIF}
{$IFDEF DPMI} compile in real mode - safer - doesnt require rtm etc
{$M 32768}
{$ELSE}
{$M 32768,0,655360}
{$ENDIF}

{$O+,F+}
{$I F6COMP}


USES Crt,F6StdWn1,
{$IFNDEF DPMI}
Overlay,
{$ENDIF}
     SFXGraph,SFXSTDBT,SFXFGen,SFXFont,FXModCtv,
     SFXStd,SFX_PRO,SFXConst,SFXTouch,
     SFXUtils,F6StdCtv,SFXCOLR,
     FXCfg,FXFIni;





FUNCTION SPInit : BOOLEAN;
BEGIN
 SPInit := FALSE;
 WriteLn('Touchscreen Terminal Prompt '+VERSION_NUMBER+' '+COPYRIGHT);
 WriteLn;
 WriteLn('Reading System Configuration File.');
 IF NOT SystemConfigInit THEN { Inits Config record - touchscreen settings reqd }
   EXIT;                      { ini is cached so not to much of a problem }
 Config_Rec^.CONF_TouchScreen := TRUE;

(*
 WriteLn('Reading Scale Configuration File.');
 IF NOT TermSettingsInit THEN EXIT;
 WriteLn('Initialising Graphics Subsystem.');
 IF (NOT Config_Rec^.CONF_TouchScreen) AND (NOT MousePresent) THEN
  BEGIN
   WriteLn('Load A Mouse Driver First');
   EXIT;
  END;
*)
 IF NOT GraphInit  THEN EXIT;        {Graphics mode must be set next}
(*
 AdvancedOptionsInit;
*)
 SetDefaultPallete(32,ScaleConfRec.GreyScaleDisplay);
 SetColourScheme;
 FontInit;                           {Has stuff needed by stdwininit  }
 ClrGraphWin;
(*
 WriteStrAt(1,2,'Get Startup Bitmap');
 DisplayBitmap(1,1,'HSLPAGE3.PCX',FALSE);
*)
 WriteStrAt(1,48,'Initialising Task Manager.');
 ProcessStart;
 WriteStrAt(1,50,'Initialising Touchscreen Monitor Task.');
 TouchScreenHandlerInit;
(*
 WriteStrAt(1,52,'Initialising Standard Window Objects.');
 StdWinInit;                         {Used by wait_for_user_input}
 TaskInit;
 WriteStrAt(1,54,'Initialising Scale Communications.');
 IF NOT MainScaleInit THEN EXIT;     {This must be inited before system as}
 WriteStrAt(1,56,'Scale Initialise Complete');
*)
 { blank out messages }
 WriteStrAt(1,48,COPY(SPACE_STRING,1,80));
 WriteStrAt(1,50,COPY(SPACE_STRING,1,80));
 WriteStrAt(1,52,COPY(SPACE_STRING,1,80));
 WriteStrAt(1,54,COPY(SPACE_STRING,1,80));
 WriteStrAt(1,56,COPY(SPACE_STRING,1,80));
 IF Config_Rec^.CONF_TouchScreen THEN
  BEGIN
   IF TouchScreenInit THEN
    BEGIN
{    ResetTouchScreenIfWanted;
     ClrGraphWin;
}
    END
   ELSE
     EXIT;
  END;
(*
 IF NOT SystemInit THEN EXIT;        {calls to seterror use scalewindow    }
 {AdvancedOptionsInit;}
 OListInit;
 ClrGraphWin;
 StartLoginDetails;
 TicketPrinterPortInit;
 StartMsgInit;
 PrimeContrast;
*)
 SPInit := TRUE;
END;

PROCEDURE SPDone;
BEGIN
(*
 DisposeListRec;
 SystemDone;
 MainScaleDone;
*)
 TouchScreenDone;
 ProcessStop;
 StdWinDone;
 FontDone;
 GraphDone;
 Nosound
{ CloseGraphMode;}
END;


CONST LibCheck = HSLLIBV1095;
      SPQuestion : INIVAR = (V:'Prompt'; S:main);

VAR
  Question   : STRING;
  ReturnCode : INTEGER;
BEGIN
 ReturnCode := 1;
 IF SPInit THEN
  BEGIN
   Question := GetExtVar(SPQuestion,all);
   IF YesNoWin(Question) THEN
     ReturnCode := 0;
  END;
 SPDone;
 Halt(ReturnCode);
END.

UNIT SFXINIT;
{$O+,F+}
{$I F6COMP}

INTERFACE

USES Crt,
{$IFNDEF DPMI}
Overlay,
{$ENDIF}
     DispRec,SFXGraph,SFXSTDBT,F6Btrv,SFXFGen,SFXFont,FX_Msg,FXModCtv,
     SFXScale,SFXStd,SFXOList,SFX_PRO,SFXConst,FXUBIPTR,SFXTouch,SFXLog,
     SFXUtils,FXDetail,SFX_Msg,F6StdCtv,SfxBas,SfxExit,SFXLIST,SFXCOLR,
     FXCfg;



FUNCTION   FXInit : BOOLEAN;
PROCEDURE  FXDone;


IMPLEMENTATION


FUNCTION FXInit : BOOLEAN;
BEGIN
 FXInit := FALSE;
 FILEOBJ.BTRV_ERROR_AUTO_DISP_SET := [
                 berr_Lost,       { GetNext is lost in a duplicate key.}
                 berr_InvalidSpec,{ invalid parameters in create call }
                 berr_InvalidOp,  { btrieve call was invalid }
                 berr_Critical];  { Record manager configuration error,
				      or fault or server fault }

 ClrScr;
 WriteLn('Formix Recipe Terminal V'+VERSION_NUMBER+' '+COPYRIGHT);
 WriteLn;
 WriteLn('Reading System Configuration File.');
 IF NOT SystemConfigInit THEN EXIT;  {Inits Config record may be needed}
 WriteLn('Reading Scale Configuration File.');
 IF NOT TermSettingsInit THEN EXIT;
 WriteLn('Initialising Graphics Subsystem.');
 IF (NOT Config_Rec^.CONF_TouchScreen) AND (NOT MousePresent) THEN
  BEGIN
   WriteLn('Load A Mouse Driver First');
   EXIT;
  END;
 IF NOT GraphInit  THEN EXIT;        {Graphics mode must be set next}
 AdvancedOptionsInit;
 SetDefaultPallete(32,ScaleConfRec.GreyScaleDisplay);
 SetColourScheme;
 FontInit;                           {Has stuff needed by stdwininit  }
 ClrGraphWin;
 WriteStrAt(1,2,'Get Startup Bitmap');
 DisplayBitmap(1,1,'HSLPAGE3.PCX',FALSE);
 WriteStrAt(1,48,'Initialising Task Manager.');
 ProcessStart;
 WriteStrAt(1,50,'Initialising Touchscreen Monitor Task.');
 TouchScreenHandlerInit;
 WriteStrAt(1,52,'Initialising Standard Window Objects.');
 StdWinInit;                         {Used by wait_for_user_input}
 TaskInit;
 WriteStrAt(1,54,'Initialising Scale Communications.');
 IF NOT MainScaleInit THEN EXIT;     {This must be inited before system as}
 WriteStrAt(1,56,'Scale Initialise Complete');
 WriteStrAt(1,48,COPY(SPACE_STRING,1,80));
 WriteStrAt(1,50,COPY(SPACE_STRING,1,80));
 WriteStrAt(1,52,COPY(SPACE_STRING,1,80));
 WriteStrAt(1,54,COPY(SPACE_STRING,1,80));
 WriteStrAt(1,56,COPY(SPACE_STRING,1,80));
 IF Config_Rec^.CONF_TouchScreen THEN
  BEGIN
   IF TouchScreenInit THEN
    BEGIN
     ResetTouchScreenIfWanted;
     ClrGraphWin;
    END
   ELSE
     EXIT;
  END;
 IF NOT SystemInit THEN EXIT;        {calls to seterror use scalewindow    }
 {AdvancedOptionsInit;}
 OListInit;
 ClrGraphWin;
 StartLoginDetails;
 TicketPrinterPortInit;
 StartMsgInit;
 PrimeContrast;
 FXInit := TRUE;
END;

PROCEDURE FXDone;
BEGIN
 DisposeListRec;
 SystemDone;
 MainScaleDone;
 TouchScreenDone;
 ProcessStop;
 StdWinDone;
 FontDone;
 GraphDone;
 Nosound
{ CloseGraphMode;}
END;


END.
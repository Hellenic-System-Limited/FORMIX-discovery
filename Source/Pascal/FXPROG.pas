{$IFNDEF MULTIPASSWORD} Error {$ENDIF}
{$I F6COMP}
USES Crt,F6STDCTV,FOROVR,FXMSys,FXFGen,FXExit,FXTIME,FXFINI,FXORDIMP,FXUSEEXP;
{ Overlaid Units }


{$IFDEF MSDOS}

 {$O FXBRW_IC}
 {$O FXBRW_PO}
 {$O FXBRW_RP}
 {$O FXBRW_MA}
 {$O FXBRW_WO}
 {$O FXBRW_US}
 {$O FXBRW_MC}
 {$O FXBRW_PR}
 {$O FXBRW_IN}
 {$O FXBRW_LI}
 {$O FXBRW_PD}
 {$O FXBRW_TR}
(* {$O F6STDBRW}
 *)
 {$O FXFGEN}
 {$O FXHELP}
 {$O FXDELING}
 {$O FXTIME}
 {$O FXPWORD}
 {$O FXWO_TGL}
 {$O FXCFG}
(*
 {$O FXDELPRD}
 {$O FX_RPE}
 {$O FX_PEDIT}
 {$O FXPRCP}
 {$O FX_EDESC}
 {$O FXMKPROD}
 {$O FXPPROD}
 {$O FXPORD}
 {$O FXPCOOK}
 {$O FXMENU}
 {$O FX_RLU}
 {$O FXEVENT}
 {$O FXPSCH}
 {$O FXPNET}
 {$O FX_PING}
 {$O FX_IE}
 {$O FX_EDIT}
 {$O FX_ME}
 {$O FXPUSAGE}
 {$O FXPUSER}
 {$O FX_WOE}
 {$O FXDELORD}
 {$O FORMIX}
 {$O FXFRCP}
 {$O FXFILOT}
 {$O FXFINGR}
 {$O FXFNET}
 {$O FXFUSERS}
 {$O FXFCOST}
 {$O FX_MSG}


 {$O FXFPROD}
 {$O FXFMACRO}
 {$O FXFINI}
 {$O FXFORDER}
 {$O FXFTRN}
 {$O FXFWORK}
 {$O FXFMIX}

 {$O F6STDSTR}
 {$O F6STDWN1}
 {$O F6REPSEE}
 {$O F6STDFIL}
 {$O F6RECCHG}
 {$O FKEYCNST}
 {$O F6SCREEN}
 {$O F6GETREP}
 {$O F6LPTSEL}
 {$O F6LOKOUT}
 {$O F6STDUTL}
 {$O F6STDREP}
 {$O FILEOBJ}
 {$O F6STDCHR}
 {$O F6STDWIN}
 {$O F6STDUT1}
 {$O F6DTCONV}
 {$O F6BTRV}
 {$O FXUSEEXP}

*)

{$ENDIF}

CONST LibCheck = HSLLIBV1159b; //a lot of work is need to user current library


PROCEDURE Main;
BEGIN
 FileMode := READ_WRITE+DENY_NONE;
 Init_System;
 {About(TRUE);}
 IF GetExtSwitch(FXAutoOrderImport,all,FALSE) THEN
   Schedule_Timed_Event(TimedOrderImport,0,0,TRUE,1);

 ScheduleTimedIngredientUseExport;

 PullDown_Menus;

 StopTimedIngredientUseExport;
 Cancel_Timed_Event(TimedOrderImport);
 Exit_System(-1);
END;

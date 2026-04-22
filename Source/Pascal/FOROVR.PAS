(****************************************************************************
*  UNIT          : FOROVR                                                   *
*  AUTHOR        : S. M. Wright                                             *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : FORMIX OVERLAY MANIGER INSTALATION                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FOROVR;
INTERFACE

USES Crt,Dos,{$IFDEF MSDOS} Overlay, {$ENDIF} FXModCtv,F6StdCtv,F6StdWin;

IMPLEMENTATION


VAR OVRFIL : TEXT;

PROCEDURE DispComp;
BEGIN
  WriteLn('Compiled For : ',COMPILED_FOR);
  Delay(500);
END;

BEGIN
 PROP_ProgramName    := 'Formix Recipe System';
 PROP_ProgramVersion := VERSION_NUMBER;
 PROP_Copyright      := COPYRIGHT;
 Win_Init;

 ClrScr;
 CASE Test8086 OF
  0: Write('8086');
  1: Write('80286');
  ELSE Write('x86 Processor');
 END;
 Write(' Running in ');
{$IFDEF DPMI}
 WriteLn('Protect Mode');
{$ELSE}
 WriteLn('Win32 Console');
{$IFDEF WINDOWS}
{$ELSE}
 WriteLn('Real Mode');
{$ENDIF}
{$ENDIF}
 WriteLn;
 WriteLn(PROP_ProgramName+' Version '+
         PROP_ProgramVersion+' Copyright (c) '+PROP_Copyright);
{$IFDEF ACC}
 WriteLn('Accelerated File Access');
{$ELSE}
 WriteLn('Standard File Access');
{$ENDIF}
 WriteLn;
 DispComp;
 WriteLn;


{$IFDEF MSDOS}
 Assign(OVRFIL,'FORMIX.OVR');
 SetFAttr(OVRFIL,Shareable);                    { Flag Overlay as Shareable }
 OvrInit ('FORMIX.OVR');
 IF OvrResult <> ovrOk THEN
  BEGIN
   WriteLn('ERROR - Overlay manager initialisation failed.');
   WriteLn;
   Halt(0);
  END;
 OvrInitEMS;
 CASE OvrResult of
  ovrIOError    : WriteLn('Overlay file I/O error.');
  ovrNoEMSDriver: WriteLn('EMS driver not installed.');
  ovrNoEMSMemory: WriteLn('Not enough EMS memory.');
  ELSE Writeln('Using EMS for faster overlay swapping.');
 END;
{$ENDIF}
END.

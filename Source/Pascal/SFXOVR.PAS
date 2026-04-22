{$O+,F+}
{$I F6COMP}
UNIT SFXOVR;

INTERFACE

USES Crt,Dos,Overlay,F6StdCtv;

PROCEDURE OverlayInit;


IMPLEMENTATION

PROCEDURE OverlayInit;
VAR OVRFIL : TEXT;
BEGIN
{$IFDEF MSDOS}
 ClrScr;
 WriteLn('Initialise overlay manager');
 Assign(OVRFIL,'SFORMIX.OVR');
 SetFAttr(OVRFIL,Shareable);

 OvrInit('SFORMIX.OVR');
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
END;


BEGIN
 OverlayInit;
END.
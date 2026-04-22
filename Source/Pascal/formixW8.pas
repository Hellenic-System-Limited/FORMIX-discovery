(****************************************************************************
*  PROGRAM       : FORMIX                                                   *
*  AUTHOR        : S. M. Wright                                             *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : FORMIX MAIN PROGRAM UNIT                                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{(c) Hellenic Systems Ltd                                            ver 1.x }
{$IFDEF MSDOS}
{$M,$A000,0,655360}
{$ELSE}
{$M,$A000}
{$ENDIF}
{$O+,F+}
PROGRAM FORMIX;
{$I FXPROG}

{************************************************************************
 Compile using Free Pascal with defines: customer multipassword
*************************************************************************}
{$IFNDEF WINDOWS} use FPC with win32 target {$ENDIF}
{$IFNDEF FPC}     use Free Pascal compiler {$ENDIF}
{$IFNDEF VER2_6}  use FPC 2.6 compiler for Windows8 {$ENDIF}

BEGIN
 Main;
END.

(****************************************************************************)
(* Compiler conditions in source :-                                         *)
(****************************************************************************)
(*                                                                          *)
(* MSDOS     - Overlayed Real Mode Compile                                  *)
(* DPMI      - DPMI Protect Mode Compile                                    *)



(*   N O T E :   T H I S   U N I T   H A S  B E E N   I N C L U D E D       *)
(*                                                                          *)
(*               I N   E V E R Y   U N I T.                                 *)


(****************************************************************************)
{$I LIBCOMP.PAS}


{$DEFINE MULTIPASSWORD}
{$DEFINE HELPON}
{$DEFINE MENU}

{$IFDEF TOUCHSCREEN}
        obsolete compile condition - replaced by CONF_TouchScreen
        DEFINE TERMINAL sets CONF_Touchscreen to true.
{$ENDIF}

{$IFDEF TERMINAL} {old terminal program for DOS - latest terminal prog is a Delphi project}
 {$IFDEF BENSONPARK}
  {$DEFINE FOPSTRACELINK}
 {$ENDIF}

 {$IFDEF LAZENBY}
  {$DEFINE FOPSTRACELINK}
 {$ENDIF}
{$ENDIF}

{$IFDEF DAWSONS}
 {$DEFINE RECIPEBYPHR}
{$ENDIF}

{$IFDEF HILTOND}
{$ENDIF}

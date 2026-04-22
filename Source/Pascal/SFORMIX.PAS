PROGRAM Scale_Recipe_System;
{$IFNDEF TERMINAL}
 Define Terminal First
{$ENDIF}
{$IFDEF DPMI}
{$M 32768}
{$ELSE}
{$M 32768,0,655360}
{$ENDIF}
{$I F6COMP}

USES Crt,
{$IFDEF MSDOS}
     SFXOVR,
{$ENDIF}
     DispRec,SFXGraph,SFXSTDBT,F6Btrv,SFXFGen,SFXFont,FX_Msg,FXModCtv,
     SFXScale,SFXStd,SFXOList,SFX_PRO,SFXConst,FXUBIPTR,SFXTouch,SFXLog,
     SFXUtils,FXDetail,SFX_Msg,F6StdCtv,SfxBas,SfxExit,SFXLIST,SFXCOLR,
     SFXINIT;

{$O SFXINIT}                    { Startup Run-Once Code                  }
{$O SFXFGEN}                    { More File Related Run-Once Code        }
{$O SFXFONT}                    { More Font Related Run-Once Code        }
{$O SFXCONST}                   { Mostly Run-Once Code                   }
{$O SFXKBD}                     { KeyBoard Display and Some Entry Stuff  }
{$O SFXTIKET}                   { Eltron Ticket Printing                 }
{$O SFXELTRN}                   { Eltron Printer Util Functions          }
{$O FXUBIPRN}                   { UBI Ticket Printing                    }
{$O FXUBIPTR}                   { UBI Utilities                          }
{$O SFXTLIST}                   { Transaction Total Linked List          }
{$O SFXSETUP}                   { Setup Screen                           }
{$O SFXEVENT}                   { Menu Screen                            }
{$O SFXLIST}                    { Scroling Listbox Code                  }
{$O SFXBAS}                     { Spooner Basic (Used For Printing)      }
{$O SFXDATE}                    { Recipe Date Selection Object           }
{$O SFXMENU}                    { User Menu Functions                    }
{$O SFXEDIT}                    { Field Entry Functions                  }


CONST LibCheck = HSLLIBV1116;

BEGIN
 IF FXInit THEN MainProc;
 FXDone;
END.





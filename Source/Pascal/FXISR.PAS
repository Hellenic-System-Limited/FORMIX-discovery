{$C FIXED PRELOAD PERMANENT}
UNIT FXISR;


{ A UNIT to ease the use of interrupt routines written in                    }
{ Turbo Pascal by allowing you to install ordinary Turbo procedures          }
{ as interrupt handlers without the need for gobs of inline statements       }
{ within each procedure.                                                     }
{                                                                            }
{ As far as the outside world is concerned, it provides                      }
{                                                                            }
{ type  interrupt_workspace ;                                                }
{                                                                            }
{ procedure InstallInterruptHandler                                          }
{    ( routine_offset, intrrupt_no : integer ;                               }
{      chain_old_vector, enable_ints_during, new_stack : boolean ;           }
{      var workspace : interrupt_workspace )                                 }
{                                                                            }
{    This installs a Turbo procedure whose offset is routine_ptr             }
{    (ie ofs(RoutineName) ) to be activated by interrupt no intr_no.         }
{    Note that if the interrupt is an external one the 8259 is not           }
{    touched - you must do this yourself. If chain_old_vector is true        }
{    then the previous interrupt vector is chained to at the end of          }
{    the interrupt procedure. If enable_ints_during is true then             }
{    interrupts are enabled during the course of the interrupt               }
{    procedure. If new_stack is true then then the stack is switched         }
{    to an internal one within 'workspace' for the duration of the           }
{    interrupt (you won't need this only for interrupts called with          }
{    INT instructions when you know their stack has room enough).            }
{    Interrupts arriving at unpredictable times may arrive during            }
{    a DOS call and overflow the DOS stack, hence the need to switch         }
{    stacks.                                                                 }
{    Each interrupt must have a variable of type                             }
{    interrupt_workspace accompanying it - it MUST appear in a               }
{    var declaration, not 'new'ed off the stack.                             }
{                                                                            }
{ procedure RemoveInterruptHandler                                           }
{    ( interrupt_no : integer ; var workspace : interrupt_workspace ) ;      }
{                                                                            }
{    Removes the interrupt handler at interrupt no intr_no                   }
{    that was installed by InstallInterruptHandler and replaces              }
{    it with the vector that was there previously, as held in                }
{    workspace. FEED THIS THE CORRECT WORKSPACE !                            }
{                                                                            }
{ Also provided are constants CLI and STI. Inline(CLI) will disable          }
{ interrupts until the next Inline(STI).                                     }
{                                                                            }
{ *** NOTE ***                                                               }
{   Interrupt routines installed with new_stack true (eg for where interrupts}
{   may arrive during DOS) and all routines they call which in turn call     }
{   other routines MUST be compiled with the K- switch to disable stack      }
{   checking - since a new stack is in use it confuses Turbo, so off with    }
{   the checking. The stack depth with 'new_stack' is limited to             }
{   'intr_stack_size' bytes (see below), so be careful with over-generous    }
{   use of local variables or recursion.                                     }
{   Procedures responding to external interrupts will have to inform         }
{   the 8259 of the end of the interrupt themselves - issueing a generic     }
{   EOI via a Port[$20] := $20 should usually be sufficient.                 }
{                                                                            }
{ A summary of how it works.                                                 }
{ ==========================                                                 }
{                                                                            }
{    Code is placed into link_code in workspace for each routine that        }
{    switches the stack if necessary, saves DS and SI on the stack,          }
{    places the offset of the routine being called into SI and the           }
{    current segment (the Turbo data segment) into DS, and then does         }
{    a far call to code in the typed constant (and thus in the code          }
{    segment) at goto_si. This saves the rest of the registers and does      }
{    a near call to the handling routine, which means the code generated     }
{    by the compiler to enter and exit the handling routine will work ok.    }
{    On exit it back to goto_si there is a far ret back to the code          }
{    in workspace which then restores DS and SI, restores the stack if       }
{    necessary and does either an IRET or a jump to the old vector           }
{    depending on the setup instructions.                                    }


INTERFACE

CONST INTR_STACK_SIZE        = $400 ;        { Size of 'new_stack's 1K}
      MAX_LINK_CODE_SIZE     = 60  ;         { Max size of link code space }

      STI                    = $fB ;         { Interrupt flag instructions }
      CLI                    = $fA ;         { op codes }


TYPE PISR_Routine            = ^BYTE;        { Pointer Type To ISR }

     TInterrupt_Workspace = PACKED RECORD
                             Link_Code   : ARRAY [0..MAX_LINK_CODE_SIZE] OF BYTE;
                             Old_routine : PISR_ROUTINE;
                             SP,SS       : integer ;
                             Int_Stack   : ARRAY [0..INTR_STACK_SIZE] OF BYTE;
                            END;


PROCEDURE InstallInterruptHandler(    Routine_Offset     : PISR_Routine;
                                      Interrupt_No       : INTEGER;
                                      Chain_Old_Vector,
                                      Enable_Ints_During,
                                      new_stack          : BOOLEAN;
                                  VAR Workspace          : TInterrupt_Workspace);

PROCEDURE RemoveInterruptHandler(    Interrupt_No : INTEGER;
                                 VAR Workspace    : TInterrupt_Workspace);

IMPLEMENTATION
                            { Type const in code seg }
CONST GOTO_SI : ARRAY [1..15] OF BYTE = ( $50,          { push ax }
                                          $53,          { push bx }
                                          $51,          { push cx }
                                          $52,          { push dx }
                                          $57,          { push di }
                                          $06,          { push es }
                                          $FF,$D6,      { call si }
                                          $07,          { pop  es }
                                          $5F,          { pop  di }
                                          $5A,          { pop  dx }
                                          $59,          { pop  cx }
                                          $5B,          { pop  bx }
                                          $58,          { pop  ax }
                                          $CB ) ;       { ret far }



PROCEDURE InstallInterruptHandler(    Routine_Offset     : PISR_Routine;
                                      Interrupt_No       : INTEGER;
                                      Chain_Old_Vector,
                                      Enable_Ints_During,
                                      new_stack          : BOOLEAN;
                                  VAR Workspace          : TInterrupt_Workspace);

VAR I : INTEGER;
    Interrupt_Vector : ARRAY[0..255] OF PISR_Routine ABSOLUTE 0:0 ;

 { Add a byte of code to the link, giving error if overflow }
 PROCEDURE l(B : BYTE) ;
  BEGIN
   IF i > MAX_LINK_CODE_SIZE THEN
    BEGIN
     Writeln ('Link code overflow') ;
     HALT (1) ;                      { Give error and stop }
    END
   ELSE
    BEGIN
     Workspace.Link_Code[i] := b ;
     INC(i);
    END;
  END;

  { Add a word of code to the link (lo:hi), giving error if overflow }
 PROCEDURE w(w : INTEGER) ;
  BEGIN
   l(lo(w)) ;
   l(hi(w))
  END;

BEGIN
 i := 0 ;                                  { Reset link code buffer counter }
 WITH Workspace DO
  BEGIN
  { Code to swap stacks, if necessary }
   IF New_Stack THEN
    BEGIN
     l($2E) ; l($8C) ;               { mov  cs:[ss],ss        save SS }
     l($16) ; w(ofs(ss)) ;
     l($2E) ; l($A3) ;               { mov  cs:[sp],ax        save AX }
     w(Ofs(sp)) ;
     l($8C) ; l($C8) ;               { mov  ax,cs             set SS to CS }
     l($8E) ; l($D0) ;               { mov  ss,ax }
     l($89) ; l($E0) ;               { mov  ax,sp             save SP and }
     l($2E) ; l($87) ;               { xchg ax,cs:[sp]        recover AX }
     l($06) ; w(ofs(sp)) ;
     l($BC) ;                        { mov  sp,<top of new stack> }
     w(ofs(int_stack) + intr_stack_size)
    END;

   { Now save DS and SI and set them to CS and the routine offset }
   l($56) ;                          { push si }
   l($1E) ;                          { push ds }
   l($0E) ;                          { push cs }
   l($1F) ;                          { pop  ds }
   l($BE) ; w(WORD(routine_offset)); {mov  si,routine_offset }

   { Re-enable interrupts if desired }
   IF Enable_Ints_During THEN
     l(STI) ;                        { sti }

   { Far call to the code at goto_si }
   l($9a) ; w(ofs(goto_si)) ;        { call far goto_si }
   w(Cseg) ;

   { Recover DS and SI }
   l($1f) ;                          { pop  ds }
   l($5e) ;                          { pop  si }

   { Reset stack to original if necessary }
   IF New_Stack THEN
    BEGIN
     l($2e) ; l($8e) ;               { mov  ss,cs:[ss]        recover SS }
     l($16) ; w(ofs(ss)) ;
     l($2e) ; l($8b) ;               { mov  sp,cs:[sp]        and SP }
     l($26) ; w(ofs(sp))
    END;

   { Bung in either an IRET or a jump to next link }
   IF Chain_Old_Vector THEN
    BEGIN
     l($2e) ; l($ff) ;               { jmp far cs:[old_routine] }
     l($2e) ; w(ofs(old_routine))
    END
   ELSE
     l($cf) ;                        { iret }

   { Now we can install the vector to link_code, saving the                 }
   { old vector in old_routine. Interrupts are switched off                 }
   { for this bit, just in case.                                            }
   inline (CLI) ;
   Old_Routine := Interrupt_Vector[Interrupt_No];
   Interrupt_Vector[Interrupt_No] := ADDR(Link_Code);
   inline (STI)                                        { Interrupts back on }
  END; { WITH WorkSpace}
END;



PROCEDURE RemoveInterruptHandler(    Interrupt_No : INTEGER;
                                 VAR Workspace    : TInterrupt_Workspace);
VAR Interrupt_Vector : ARRAY [0..255] of PISR_Routine ABSOLUTE 0:0 ;
BEGIN
   INLINE(CLI) ;                                 { Interrupts off }
   Interrupt_Vector[Interrupt_No] := Workspace.Old_Routine ;
   INLINE(STI)                                   { and on again }
END;


END.

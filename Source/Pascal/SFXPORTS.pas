{$I F6COMP}
{$C FIXED PRELOAD PERMANENT}
UNIT SFXPORTS;
INTERFACE
USES Dos,F6StdUtl;
CONST
 SER_COM1 = $3F8;                                { Base address COM1 }
 SER_COM2 = $2F8;                                { Base address COM2 }

 SER_IRQ_COM1 = 4;                              { IRQ 4 = vector $0C }
 SER_IRQ_COM2 = 3;                              { IRQ 3 = vector $0B }

 SER_TXBUFFER     =  $00;                        { Transmit register }
 SER_RXBUFFER     =  $00;                         { Receive register }
 SER_DIVISOR_LSB  =  $00;                    { Baud rate divisor LSB }
 SER_DIVISOR_MSB  =  $01;                    { Baud rate divisor MSB }
 SER_IRQ_ENABLE   =  $01;                { Interrupt enable register }
 SER_IRQ_ID       =  $02;                    { Interrupt ID register }
 SER_FIFO         =  $02;                            { FIFO register }
 SER_2Function    =  $02;              { Alternate function register }
 SER_LINE_CONTROL =  $03;                             { Line control }
 SER_MODEM_CONTROL=  $04;                            { Modem control }
 SER_LINE_STATUS  =  $05;                              { Line status }
 SER_MODEM_STATUS =  $06;                             { Modem status }
 SER_SCRATCH      =  $07;                         { Scratch register }

              { IRQ enable register bits (enable/disable interrupts) }
 SER_IER_RECEIVED = $01;                   { IRQ after data received }
 SER_IER_SENT     = $02;                       { IRQ after byte sent }
 SER_IER_LINE     = $04;              { IRQ after line status change }
 SER_IER_MODEM    = $08;             { IRQ after modem status change }

                               { IRQ-ID - bits (What initiated IRQ?) }
 SER_ID_PENDING    = $01;                   { Is serial IRQ pending? }
 SER_ID_MASK       = $06;              { ID is coded in bits 1 and 2 }
 SER_ID_LINESTATUS = $06;             { Line status (error or break) }
 SER_ID_RECEIVED   = $04;                            { Data received }
 SER_ID_SENT       = $02;                            { Byte was sent }
 SER_ID_MODEMSTATUS= $00;              { CTS, DSR, RI or RLSD change }

            { Bit assignment in FIFO register (16550A UART or later) }
 SER_FIFO_ENABLE       = $01;
 SER_FIFO_RESETRECEIVE = $02;
 SER_FIFO_RESETTRANSMIT= $04;

       { FIFO bits (number of bytes in FIFO after which IRQ occurs ) }
 SER_FIFO_TRIGGER0   = $00;                                 { Normal }
 SER_FIFO_TRIGGER4   = $40;                                { 4 bytes }
 SER_FIFO_TRIGGER8   = $80;                                { 8 bytes }
 SER_FIFO_TRIGGER14  = $C0;                               { 14 bytes }

              { Line control register bits (transmission parameters) }
 SER_LCR_WordLEN    = $03;        { Number of bits being transmitted }
 SER_LCR_5BITS      = $00;
 SER_LCR_6BITS      = $01;
 SER_LCR_7BITS      = $02;
 SER_LCR_8BITS      = $03;
 SER_LCR_2STOPBITS  = $04;                      { 2 or 1.5 stop bits }
 SER_LCR_1STOPBIT   = $00;                              { 1 stop bit }

 SER_LCR_NOPARITY   = $00;                    { Disable parity check }
 SER_LCR_ODDPARITY  = $08;                              { Odd parity }
 SER_LCR_EVENPARITY = $18;                             { Even parity }
 SER_LCR_PARITYSET  = $28;                   { Parity bit always set }
 SER_LCR_PARITYCLR  = $38;               { Parity bit always cleared }
 SER_LCR_PARITYMSK  = $38;

 SER_LCR_SENDBREAK  = $40;        { Send break as long as bit is set }
 SER_LCR_SETDIVISOR = $80;         { For access to baud rate divisor }

                      { Modem control register bits (signal control) }
 SER_MCR_DTR        = $01;                          { Set DTR signal }
 SER_MCR_RTS        = $02;                          { Set RTS signal }
 SER_MCR_UNUSED     = $04;
 SER_MCR_IRQENABLED = $08;            { Issue IRQs to IRQ controller }
 SER_MCR_LOOP       = $10;                               { Self-test }

                   { Line status register  bits (transmission error) }
 SER_LSR_DATARECEIVED = $01;        { Receive data word (5 - 8 bits) }
 SER_LSR_OVERRUNERROR = $02;               { Previous data word lost }
 SER_LSR_PARITYERROR  = $04;                          { Parity error }
 SER_LSR_FRAMINGERROR = $08;                  { Start/stop bit error }
 SER_LSR_BREAKDETECT  = $10;                        { Break detected }
 SER_LSR_ERRORMSK = ( SER_LSR_OVERRUNERROR or SER_LSR_PARITYERROR or
                      SER_LSR_FRAMINGERROR or SER_LSR_BREAKDETECT );
 SER_LSR_THREMPTY     = $20;
 SER_LSR_TSREMPTY     = $40;

{ Modem status register bits (which signals are set)         }
{ Delta... bits indicate whether status of corresponding }
{ signals has changed since the last read on }
{ modem status register.                                                               }
 SER_MSR_DCTS = $01;                    { Delta CTS (status in CTS) }
 SER_MSR_DDSR = $02;                    { Delta DSR (status in DSR) }
 SER_MSR_DRI  = $04;                      { Delta RI (status in RI) }
 SER_MSR_DCD  = $08;                      { Delta CD (status in CD) }
 SER_MSR_CTS  = $10;                            { Clear To Send set }
 SER_MSR_DSR  = $20;                           { Data Set Ready set }
 SER_MSR_RI   = $40;                           { Ring Indicator set }
 SER_MSR_CD   = $80;                           { Carrier Detect set }

 NOSER      = 0;
 INS8250    = 1;                    { National Semiconductor UART's }
 NS16450    = 2;
 NS16550A   = 3;
 NS16C552   = 4;
 BAUD_ERROR = 5;
 SER_OK     = 6;
 BAUD_TO_HIGH = 7;

 SER_MAXBAUD = 115200;                          { Maximum baud rate }

 SER_SUCCESS    = 0;
 SER_ERRSIGNALS = $0300;
 SER_ERRTIMEOUT = $0400;

{INTERRUPT CONSTANTS}
{- IRQ controller port addresses ------------------------------------}
 MASTER_PIC      =    $20;              { Base address of Master-PIC }
 SLAVE_PIC       =    $A0;               { Base address of Slave-PIC }
 IRQ_MASK        =    $01;                  { Offset to masking port }
{- IRQ Commands -----------------------------------------------------}
 EOI             =    $20;            { Unspecified End of Interrupt }
 MASTER_FIRST_VECTOR = $08;       { Software vectors of the hardware }
 SLAVE_FIRST_VECTOR  = $70;        { Interrupts                      }

 ETX  = 3;
 STX  = 2;


TYPE TPortType = PACKED RECORD
      PortAddr : WORD;
      Used     : BOOLEAN;
      UsedBy   : STRING[20];
     END;

CONST PortList : ARRAY[1..4] OF TPortType =
                   ((PortAddr : $03F8; Used : FALSE; UsedBy : ''),
                    (PortAddr : $02F8; Used : FALSE; UsedBy : ''),
                    (PortAddr : $03E8; Used : FALSE; UsedBy : ''),
                    (PortAddr : $02E8; Used : FALSE; UsedBy : ''));
{
VAR
    COM2Initialised    : BOOLEAN;
    COM1Initialised    : BOOLEAN;
}

{SERIAL PORT FUNCTIONS}
Function  IsSerialDataAvailable( SerPort : WORD ) : Boolean;
Procedure SetSerialPortFIFOLevel( SerPort : WORD; Level : Byte );
Function  GetUARTType( SerPort : WORD ) : Integer;
Function  IsSerialPortWritingPossible( SerPort : WORD ) : Boolean;
Function  SerialPortInit( SerPort  : WORD;
                         lBaudRate : longint;
                         bParams   : Byte ) : Integer;
Function  WriteByteToPort( SerPort           : WORD;
                        bData              : Byte;
                        uTimeOut           : Word) : Integer;
Function  ReadSerialByte(SerPort : WORD;
                      var Data    : Byte;
                         uTimeOut : LONGINT) : Integer;


FUNCTION  InitiatePort(SerPort : WORD;lBaud : LONGINT;Flags : WORD;
                       ExitOnErr : BOOLEAN;UsedBy : STRING) : INTEGER;
{INTERRUPT FUNCTIONS}
Procedure SendIRQEOI( iIRQ : Integer );
Procedure SETSerialIRQ( SerPort : WORD );
Procedure EnableIRQ( IRQ : Integer );
Procedure DisableIRQ( IRQ : Integer );
Function  SetIRQHandler( iIRQ : Integer; lpHandler : Pointer) : Pointer;
Function  SetSerialIRQHandler(SerPort : WORD;
                            iSerIRQ   : Integer;
                            lpHandler : Pointer;
                            bEnablers : Byte ) : Pointer;
Procedure ClearSerIRQ( SerPort : WORD );
Procedure RestoreSerialIRQHandler(SerPort  : WORD;
                                 iSerIRQ   : Integer;
                                 lpHandler : Pointer);

FUNCTION IsPortInUseElsewhere(PortAddr : WORD;AndNotBy : STRING) : BOOLEAN;

IMPLEMENTATION
USES
{$IFDEF Terminal} F6StdWn1,SFXGraph,{$ENDIF}
    F6ComLib;

PROCEDURE PortInUse(PortAddr : WORD;UsedBy : STRING);
VAR I : INTEGER;
BEGIN
 FOR I := 1 TO 4 DO
  BEGIN
   IF (PortList[i].PortAddr = PortAddr) THEN
    BEGIN
     PortList[i].Used   := TRUE;
     PortList[i].UsedBy := UsedBy;
     EXIT;
    END;
  END;
END;

FUNCTION IsPortInUseElsewhere(PortAddr : WORD;AndNotBy : STRING) : BOOLEAN;
VAR I : INTEGER;
BEGIN
 IsPortInUseElseWhere := FALSE;
 FOR I := 1 TO 4 DO
  BEGIN
   IF (PortList[i].PortAddr = PortAddr) THEN
    BEGIN
     IsPortInUseElsewhere := (PortList[i].Used) AND (StringIComp(PortList[i].UsedBy,AndnotBy) <> 0);
     EXIT;
    END;
  END;
END;

PROCEDURE WritePortInitError(ErrStr : STRING);
BEGIN
{$IFDEF TERMINAL}
 Disp_Error_Msg(ErrStr);
{$ELSE}
 WriteLn(ErrStr);
{$ENDIF}
END;

{INTERRUPT FUNCTIONS}
Procedure RestoreSerialIRQHandler(SerPort  : WORD;
                                 iSerIRQ   : Integer;
                                 lpHandler : Pointer);
Begin
  {-- No more IRQs to IRQ controller ---------------------}
  {-- Set handler and clear all "enablers"               }

  ClearSerIRQ( SerPort );
  SetSerialIRQHandler( SerPort, iSerIRQ, lpHandler, 0 );
  DisableIRQ( iSerIRQ );     { Also disable IRQs by the controller }
End;

Procedure ClearSerIRQ( SerPort : WORD );
Begin
  port[SerPort + SER_MODEM_CONTROL] :=
    port[SerPort + SER_MODEM_CONTROL] and not SER_MCR_IRQENABLED;
End;

Function SetSerialIRQHandler( SerPort : WORD;
                            iSerIRQ   : Integer;
                            lpHandler : Pointer;
                            bEnablers : Byte ) : Pointer;
Begin
  port[SerPort + SER_IRQ_ENABLE] := bEnablers; {Set IRQ enablers}
  SETSerialIRQ( SerPort );           { Issue IRQs to IRQ controller }

  {-- Set handler (IRQ is "enabled" there) ---------------}
  SetSerialIRQHandler := SetIRQHandler( iSerIRQ, lpHandler );
End;

Function SetIRQHandler( iIRQ : Integer; lpHandler : Pointer) : Pointer;
var lpOldHandler : Pointer;
    iVect        : Integer;
Begin
  {-- Get interrupt vector of hardware interrupt ------}
  { IRQ 0 - 7  = Vectors $08 - $0F                                  }
  { IRQ 8 - 15 = Vectors $70 - $77                                  }
  if  iIRQ <= 7 then
    iVect := ( MASTER_FIRST_VECTOR + iIRQ )
  else
    iVect := ( SLAVE_FIRST_VECTOR + ( iIRQ and $7 ) );

  DisableIRQ( iIRQ );   { Disable hardware and software interrupt }
  asm cli end;

  GetIntVec( iVect,lpOldhandler );            { Save old handler }
  SetIntVec( iVect,lpHandler );               { Set new handler }

  asm sti end;                        { Allow software interrupts }

  {- In case a handler was passed, allow corresponding --}
  {- hardware interrupt again                                  --}
  if lpHandler <> NIL then
    EnableIRQ( iIRQ );

  SetIRQHandler := lpOldHandler; {Return address of old handler}
End;

Procedure DisableIRQ( IRQ : Integer );
var APort : WORD;
Begin
  {-- get port address of appropriate PIC first ---------}
  { ( 0-7 = MASTER_PIC , 8-15 = SLAVE_PIC )                          }
  if IRQ <= 7 then APort := MASTER_PIC else APort := SLAVE_PIC;
  APort := APort + IRQ_MASK;            { Choose masking port }
  IRQ  := IRQ and $0007;      { Get PIC interrupt number (0-7) }
                                 { Set Bit -> Interrupt locked }
  port[APort] := port[APort] or ( 1 shl IRQ );
End;

Procedure EnableIRQ( IRQ : Integer );
var APort : WORD;
Begin
  {-- get port address of appropriate PIC first ---------}
  { ( 0-7 = MASTER_PIC , 8-15 = SLAVE_PIC )                          }
  if IRQ <= 7 then APort := MASTER_PIC else APort := SLAVE_PIC;
  APort := APort + IRQ_MASK;            { Choose masking port }

  IRQ := IRQ and $0007;      { Get PIC interrupt number (0-7) }
                               { Clear bit -> Interrupt enabled }
  port[APort] := port[APort] and not ( 1 shl IRQ );
End;

Procedure SendIRQEOI( iIRQ : Integer );
Begin
  {-- With IRQ 8 - 15 inform Slave as well --}
  if  iIRQ > 7 then port[SLAVE_PIC] := EOI;
  port[ MASTER_PIC] := EOI;   { Always signal EOI to MASTER }
End;

Procedure SETSerialIRQ( SerPort : WORD );
Begin
  port[SerPort + SER_MODEM_CONTROL] :=
    port[SerPort + SER_MODEM_CONTROL] or SER_MCR_IRQENABLED;
End;


{SERIAL PORT FUNCTIONS}
FUNCTION InitiatePort(SerPort   : WORD;
                      lBaud     : LONGINT;
                      Flags     : WORD; { only last byte gets used }
                      ExitOnErr : BOOLEAN;
                      UsedBy    : STRING) : INTEGER;
VAR UART : INTEGER;
BEGIN
 IF lBaud > SER_MAXBAUD THEN
  BEGIN
   WritePortInitError('Baud Rate Too High. Maximum 115200 Bd ');
   InitiatePort := BAUD_ERROR;
  END
 ELSE
  BEGIN
   F6ComLib.NewUart_Init(SerPort, lBaud, Flags, TRUE);
(*
   UART := SerialPortInit(SerPort,lBaud,Flags);
   if (UART = NOSER) THEN
    BEGIN
     InitiatePort := NOSER;
     IF ExitOnErr THEN
      BEGIN
       WritePortInitError('No Comms Port Program Will Terminate');
       Halt(0);
      END
     ELSE
      BEGIN
       WritePortInitError('Tried To Initialise A non Existant Serial Port');
       EXIT;
      END;
    END;
*)
   PortInUse(SerPort,UsedBy);
   InitiatePort := SER_OK;
(*
   if UART > INS8250 then { For 14450 activate FIFO buffer }
    SetSerialPortFIFOLevel( SerPort,SER_FIFO_TRIGGER0)
*)
  END;
END;

Function WriteByteToPort( SerPort           : WORD;
                        bData              : Byte;
                        uTimeOut           : Word) : Integer;
Begin
  if uTimeOut <> 0 then                           { Timeout loop }
    Begin
      While(not IsSerialPortWritingPossible( SerPort )
             and ( uTimeOut<> 0 ) )
        do Dec( uTimeOut );
      if uTimeOut = 0 then Begin
        WriteByteToPort := SER_ERRTIMEOUT;
        Exit;
      End;
    End
  else { Wait! }
    Repeat
    Until IsSerialPortWritingPossible( SerPort );

  {-- Test signal lines ---------}
 port[SerPort + SER_TXBUFFER] := bData;
                                 { Return port error }
 WriteByteToPort := port[SerPort + SER_LINE_STATUS] and
                       SER_LSR_ERRORMSK;
End;


Function SerialPortInit( SerPort  : WORD;
			 lBaudRate : longint;
			 bParams   : Byte ) : Integer;
var uDivisor : Word;
    b        : Byte;
    uART     : Integer;

Begin
(*
  uART := GetUARTType( SerPort );
  if uart = NOSER then
    Begin                                 { Calculate baud rate divisor }
      SerialPortInit := NOSER;
      exit;
    end;
*)
  uART := NS16550A;
  uDivisor := ( SER_MAXBAUD div lBaudRate );

  port[SerPort + SER_MODEM_CONTROL] := 3;

  {-- Divide baud rate --------}
  port[SerPort + SER_LINE_CONTROL] :=  { Enable divisor access }
     port[SerPort + SER_LINE_CONTROL] or SER_LCR_SETDIVISOR;

  port[SerPort + SER_DIVISOR_LSB] := LO( uDivisor );
  port[SerPort + SER_DIVISOR_MSB] := HI( uDivisor );

  port[SerPort + SER_LINE_CONTROL] := { Disable divisor access }
     port[SerPort + SER_LINE_CONTROL] and not SER_LCR_SETDIVISOR;

  {-- Set other parameters only after resetting baud rate latch,    --}
  {-- because this operation clears all --}
  {-- port parameters!                                               --}

  port[SerPort + SER_LINE_CONTROL] := bParams;
        { Read a byte, to reverse possible error }
  SetSerialPortFIFOLevel(SerPort,0);
  SetSerialPortFIFOLevel(SerPort,SER_FIFO_TRIGGER14);
  PORT[SerPort+1] := (PORT[SerPort+1] AND $F0);


  B := PORT[SerPort + SER_FIFO];

  b := port[SerPort + SER_TXBUFFER];
  SerialPortInit := uART;
{
  CASE SerPort OF
   SER_COM1 : COM1Initialised := TRUE;
   SER_COM2 : COM2Initialised := TRUE;
  END;
}
END;


Function IsSerialPortWritingPossible( SerPort : WORD ) : Boolean;
Begin
 IsSerialPortWritingPossible := ( port[SerPort + SER_LINE_STATUS]
                             and SER_LSR_TSREMPTY ) <> 0;
End;

Function IsSerialDataAvailable( SerPort : WORD ) : Boolean;
Begin
 IsSerialDataAvailable := (port[SerPort+SER_LINE_STATUS] and SER_LSR_DATARECEIVED) <> 0;
End;


Procedure SetSerialPortFIFOLevel( SerPort : WORD; Level : Byte );
Begin
  if Level <> 0 then
    port[SerPort + SER_FIFO] := Level or SER_FIFO_ENABLE
  else
    port[SerPort + SER_FIFO] := SER_FIFO_RESETRECEIVE or
                                SER_FIFO_RESETTRANSMIT OR SER_FIFO_ENABLE;
End;

Function GetUARTType( SerPort : WORD ) : Integer;
var b          : Byte;
    UartDetect : integer;
Begin
  UartDetect := -1; { -1 indicates not yet initialized }

  {- Check base capabilities ------------------------------------ }
  port[SerPort + SER_LINE_CONTROL] := $AA;  { Divisor latch set }
  if port[SerPort + SER_LINE_CONTROL] <> $AA then
    UartDetect := NOSER
  else
    Begin
      port[SerPort + SER_DIVISOR_MSB] := $55;   { Specify divisor }
      if port[SerPort + SER_DIVISOR_MSB] <> $55
        then UartDetect := NOSER
      else                              { Clear divisor latch }
        Begin
          port[SerPort + SER_LINE_CONTROL] := $55;
          if port[SerPort + SER_LINE_CONTROL] <> $55 then
            UartDetect := NOSER
          else
            Begin
              port[SerPort + SER_IRQ_ENABLE] := $55;
              if port[SerPort + SER_IRQ_ENABLE] <> $05 then
                UartDetect := NOSER
              else
                Begin
                  port[SerPort + SER_FIFO] := 0; { Clear FIFO and IRQ }
                  port[SerPort + SER_IRQ_ENABLE] := 0;
                  if port[SerPort + SER_IRQ_ID] <> 1 then
                    UartDetect := NOSER
                  else
                    Begin
                      port[SerPort + SER_MODEM_CONTROL] := $F5;
                      if port[SerPort + SER_MODEM_CONTROL] <> $15 then
                        UartDetect := NOSER
                    end;
                end;
            end;
        end;
    end;
  if UartDetect = -1  then { Not yet filtered out? }
    Begin { Looping }
      port[SerPort + SER_MODEM_CONTROL] := SER_MCR_LOOP;
      b := port[SerPort + SER_MODEM_STATUS];
      if ( port[SerPort + SER_MODEM_STATUS] and $F0 ) <> 0 then
        UartDetect := NOSER
      else
        Begin
          port[SerPort + SER_MODEM_CONTROL] := $1F;
          if ( port[SerPort + SER_MODEM_STATUS] and $F0 ) <> $F0 then
            UartDetect := NOSER
          else
            Begin
              port[SerPort + SER_MODEM_CONTROL] := SER_MCR_DTR or
                                                    SER_MCR_RTS;
                                       { Scratch register detected? }
              port[SerPort + SER_SCRATCH] := $55;
              if port[SerPort + SER_SCRATCH] <> $55 then
                UartDetect := INS8250
              else                      { FIFO detected ? }
                Begin
                  port[SerPort + SER_SCRATCH] := 0;
                  port[SerPort + SER_FIFO] := $CF;
                  if ( port[SerPort + SER_IRQ_ID] and $C0 ) <> $C0 then
                    UartDetect := NS16450
                  else
                    Begin
                      port[SerPort + SER_FIFO] := 0;
                            { Alternate function register detected? }
                  port[SerPort + SER_LINE_CONTROL] := SER_LCR_SETDIVISOR;
                      port[SerPort + SER_2Function] := $07;
                      if port[SerPort + SER_2Function] <> $07 then
                        Begin
                          port[SerPort + SER_LINE_CONTROL] := 0;
                          UartDetect := NS16550A;
                        End
                      else
                        Begin
                   port[SerPort + SER_LINE_CONTROL] := 0;  { Reset }
                          port[SerPort + SER_2Function] := 0;
                          UartDetect := NS16C552;
                        End;
                    End;
                End;
            End;
        End;
    End;
  GetUARTType := UartDetect;
End;


FUNCTION ReadSerialByte(    SerPort : WORD;
                        VAR data     : BYTE;
                            uTimeOut : LONGINT) : Integer;
CONST ClockCheck = 10;

VAR read_byte : byte;
    count     : LONGINT;
    status    : byte;
    TimeS     : LONGINT;
    GotIt     : BOOLEAN;
    CurrTicks : LONGINT;
    LastTick  : LONGINT;

BEGIN
 IF uTimeOut = -1 THEN uTimeout := 60*18;
 GotIt     := FALSE;
 TimeS     := uTimeOut;
 CurrTicks := 0;
 LastTick  := GetTickCount;
 IF uTimeOut > 0 THEN
   count     := ClockCheck
 ELSE
  BEGIN
   count := 1;
   DEC(LastTick);
  END;

 WHILE (NOT IsSerialDataAvailable(SerPort)) DO
  BEGIN
   DEC(Count);
   IF Count <= 0 THEN
    BEGIN
     CurrTicks := GetTickCount;
     IF (CurrTicks <> LastTick) THEN
      BEGIN
       DEC(TimeS);
       IF TimeS <= 0 THEN
        BEGIN
         ReadSerialByte := SER_ERRTIMEOUT;
         Exit;
        END;
       LastTick := CurrTicks;
      END;
     Count := ClockCheck;
    END
  END;
  Data := port[SerPort + SER_RXBUFFER];
  ReadSerialByte := port[SerPort + SER_LINE_STATUS] and SER_LSR_ERRORMSK;
END;

(*
Function ReadSerialByte(     SerPort           : WORD;
                       var Data               : Byte;
                           uTimeOut           : Word) : Integer;
VAR TempInt  : INTEGER;
Begin
  if uTimeOut <> 0 then                           { Timeout loop }
    Begin
      while( not IsSerialDataAvailable( SerPort ) and ( uTimeOut <> 0 ) ) do
       BEGIN
        Dec( uTimeOut );
       END;
      if uTimeOut = 0 then
        Begin
          ReadSerialByte := SER_ERRTIMEOUT;
          Exit;
        End;
    End
  else                                           { Wait! }
    Repeat
    Until IsSerialDataAvailable( SerPort );
  Data := port[SerPort + SER_RXBUFFER];
  ReadSerialByte := port[SerPort + SER_LINE_STATUS] and SER_LSR_ERRORMSK;
End;
*)
END.

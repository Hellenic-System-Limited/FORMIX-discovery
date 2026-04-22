(****************************************************************************
*  UNIT          : SFXTiket                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 15/09/97                                                 *
*  PURPOSE       : Eltron Thermal Printer Stuff                             *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$C FIXED PRELOAD PERMANENT}
{$I F6COMP}
UNIT SFXComms;
INTERFACE
USES Crt,SFXPorts,F6StdCtv,FxDEtail,
     SFXGraph,   {Writing To Screen}
     ComCheck,   {For Time Out}
     F6StdUtl,   {IntToStr}
     SFXConst;   {Needs Scale Type}

CONST {Weigh Master Constants}
      SendScaleParameter = 24;
      ScaleZeroCommand   = 83;
      ScaleWtChange      = 88;
      {SCALE FLAGS MASKS WEIGHMASTER}
      {STATUS1 FLAGS}
      S1_SEMI_AUTO_TARE     = $20;
      S1_SCALE_IN_MOTION    = $04;
      S1_GROSS_DISPLAY_MODE = $02;
      S1_LB_MODE            = $01;
      {Status2 Flags}
      S2_OVER_RANGE         = $20;
      S2_PRESET_TARE        = $10;
      S2_SCALE_PRINTED      = $08;
      S2_SCALE_WT_DATA_LOCK = $04;
      S2_POSITIVE_WT        = $02;
      S2_SCALE_AT_ZERO      = $01;
      { Packet Length Values}
      PLEN_WMasterParams    = 25; { WeighMaster Param  Packet }
      PLEN_WMasterWeight    = 24; { WeighMaster Weight Packet }
      PLEN_LucidWeight      = 16; { Lucid       Weight Packet }
      PLEN_S80Weight        = 20; { System80    Weight Packet }

     {Packet Types}
      PT_NoPacket   = 00;
      PT_Parameters = 01;
      PT_Data       = 02;



FUNCTION  ScaleCommsInit : BOOLEAN;
PROCEDURE ScaleCommsDone;
PROCEDURE CalibrateScale;
PROCEDURE SwitchToScale(ScaleNo : WORD);
PROCEDURE SwitchToDefaultScale;
FUNCTION  GetPacketFromScale : INTEGER;
FUNCTION  CheckParamFile : BOOLEAN;
FUNCTION  GetKgScaleIncrement : DOUBLE;
PROCEDURE GetParameters;
{PROCEDURE SetPacketSize;}

TYPE
 { 0 is weigh master paramater values}
 { 1 is weigh master data}
 { 2 is system 80 data}
 { 3 is Lucid data}
 { 4 is packet data}

    ScaleData = PACKED RECORD
      CASE Integer OF
       0 : (Param_STX   : BYTE;                {01-01 }
            Param_ID    : BYTE;                {02-02 Should be 'S'}
            Param_LSD   : ARRAY[0..7] OF BYTE; {03-10 }
            Param_LSDLB : ARRAY[0..7] OF BYTE; {11-18 }
            Param_LZB   : BYTE;                {19-19 }
            Param_OVER  : ARRAY[0..5] OF BYTE; {20-25 }
            Param_ChkEtx: BYTE;                {26-26 }
            Param_ETX   : BYTE;);              {27-27 }
       1 : (WM_STX      : BYTE;                {01-01 }
            WM_St1      : BYTE;                {02-02 }
            WM_St2      : BYTE;                {03-03 }
            WM_Net      : ARRAY[0..4] OF BYTE; {04-08 }
            WM_Tare     : ARRAY[0..4] OF BYTE; {09-13 }
            WM_Gross    : ARRAY[0..4] OF BYTE; {14-18 }
            WM_Rn       : ARRAY[0..5] OF BYTE; {19-24 }
            WM_CnkEtx   : BYTE;                {25-25 }
            WM_Etx      : BYTE;);              {26-26 }
       2 : (S80_STX     : BYTE;
            S80_Status  : BYTE;         {'M','U','N','S'}
            S80_Sign    : BYTE;         {'+','-'}
            S80_Weight  : ARRAY[0..6] OF BYTE;
            S80_Range   : BYTE;
            S80_Scale   : BYTE;         {'1','2','3','4'}
            S80_Tare    : ARRAY[0..6] OF BYTE;
            S80_ETX     : BYTE;);
       3 : (LUC_STX     : BYTE;
            LUC_Status1 : BYTE;   {'S' = Stable; 'M' = Motion}
            LUC_Status2 : BYTE;   {'G' = Gross; 'N' = Net; 'T' = Tare}
            LUC_Status3 : BYTE;   { Z,L,P,H}
            LUC_Status4 : BYTE;   {Z,H,J,L,M,P,G,B,R. R = Valid Weight}
            LUC_Sign    : BYTE;   {' ','-','O','U'}
            LUC_Weight  : ARRAY[0..5] OF BYTE;
            LUC_Space   : BYTE;   {Unknown}
            LUC_WtType  : ARRAY[0..1] OF BYTE; {kg}
            LUC_NoDP    : BYTE;   { Number of decimal places}
            LUC_CR      : BYTE;); { CR Character}
       4 : (Packet      : ARRAY[0..26] OF BYTE);
     END;

     {This is only really used for weigh master scales as other
      types have the dp. in packet}
TYPE TScaleParameters = PACKED RECORD
      NumDecimal    : INTEGER;                 {NumDecimals in weight scale}
      LSD           : LONGINT;
      LSDLB         : LONGINT;
      OVER          : LONGINT;
     END;

    TScaleParamFile = FILE OF TScaleParameters;

    TScaleHardware = PACKED RECORD
{$IFNDEF NOINTERRUPT}
     SH_lpOldIRQFunc : POINTER;        {Original IRQ Handler For Port        }
{$ENDIF}
     SH_PortAddr     : WORD;           {Address Of Port Scale Is attached To}
     SH_IRQNo        : WORD;           {IRQ Number for Port                 }
     SH_BaudRate     : LONGINT;        {Baud Rate For Port                  }
     SH_Available    : BOOLEAN;        {TRUE if setting in ini for scale    }
     SH_ScaleType    : TConnectedScale;{Scale Type of connected scale       }
     SH_Initialized  : BOOLEAN;        {TRUE if port has been initialised   }
    END;

VAR {Support For Two Scales}
    ScaleHardware : ARRAY[1..2] OF TScaleHardware;


VAR ReadingScale  : WORD;              {Scale Number Being Read 1 or 2      }
    ScalePortData : ScaleData;         {Copy Of Last Packet read From Scale }
    ScaleWindowTimeOutError : BOOLEAN; {TRUE if no scale detected on init   }
    ScaleParameters : TScaleParameters;{Parameters for the scale            }
    Save8086        : BYTE;
{   MinimumWeightIncrementKg : DOUBLE; {Weight Increment of scale           }
{   MaximumWeight            : DOUBLE; {Maximum Weight Capacity of scale    }

CONST ScaleParameterFileName ='SCALE.INI';{File storing Parameters for each scale}

IMPLEMENTATION

TYPE TScaleReadInfo = PACKED RECORD
      SI_PacketPos        : INTEGER;              {Pos. in IRQScalePacket that next byte is to be written too}
      SI_PortAddr         : WORD;                 {Port address of Serial port         }
      SI_MaxPacketLen     : BYTE;                 {Max Size OF Scale Packet            }
      SI_IRQScalePacket   : ARRAY[0..39] OF BYTE; {Information Read From Scale         }
      SI_GotAScalePacket  : BOOLEAN;              {TRUE if recieved a packet from scale}
      SI_StartScalePacket : BOOLEAN;              {TRUE if packet has being started    }
      SI_ScaleType        : TConnectedScale;      {Type of scale connected             }
      SI_ScaleIncrement   : DOUBLE;               {Scale Weight Increment              }
      SI_ScaleCapacity    : DOUBLE;               {Scale Weight Capacity               }
     END;         {IRQScalePacket is padded to make record 64 bytes in size}




    {Scale Interrupt Parameters}
VAR ScaleReadInfo    : ARRAY[1..2] OF TScaleReadInfo; {One For Each Scale}
    ScaleTimeOut     : INTEGER;            {Secs Until Scale Will Timeout}
    ParamFile        : TScaleParamFile;
    ScaleDataFileName : STRING[12];        {Scale data file holds irq,baud rates for each scale}


(*  ScaleISR1WorkSpace : TInterrupt_Workspace; *)


{$IFDEF DEBUG}
    ShowData         : BOOLEAN;
    DataXPos         : INTEGER;
    DataYPos         : INTEGER;
{$ENDIF}

{$IFDEF NOINTERRUPT}
{Reads One Packet From Scale Without Using Interrupt Comms}
PROCEDURE ReadPacketFrromPort(wPort : WORD;ScaleNo : WORD);
VAR IRQID,ByteIn : BYTE;
BEGIN
 REPEAT
  IF ScaleReadInfo[ScaleNo].SI_GotAScalePacket THEN EXIT;
  IF (IsSerialDataAvailable(wPort)) THEN
   BEGIN                                          {Serial Data Available    }
    WITH ScaleReadInfo[ScaleNo] DO  {SI_}
     BEGIN
      ByteIn := Port[wPort+SER_RXBUFFER];         {Get Waiting CHAR         }
      CASE ByteIn OF
       STX : BEGIN                                {Start of Packet CHR      }
              SI_PacketPos := 0;                  {Reset Buffer Pointer     }
              SI_StartScalePacket := TRUE;        {Set Start Packet Flag    }
             END;
       ETX,ORD(CR) : BEGIN                        {End of Packet CHR        }
              IF SI_StartScalePacket THEN
               BEGIN                              {Have Found Packet Start  }
                SI_GotAScalePacket := TRUE;       {Set Complete Packet Flag }
                SI_IRQScalePacket[SI_PacketPos] := ByteIn;   { Load Buffer}
                SI_PacketPos := 0;                {Reset Buffer Pointer     }
               END;
              SI_StartScalePacket := FALSE;       {Clear Packet Start Flag  }
             END;
      END;{CASE ByteIn}

      IF SI_StartScalePacket THEN
       BEGIN                            { Have Found Packet Start           }
        SI_IRQScalePacket[SI_PacketPos] := ByteIn;      { Load Chr Into Buf.}
        Inc(SI_PacketPos);              { Increment Buffer Pointer          }
       END;
      IF SI_PacketPos > SI_MaxPacketLen THEN
       BEGIN                            { Buffer Overrun                    }
        SI_PacketPos   := 0;            { Reset Buffer Pointer              }
        SI_StartScalePacket := FALSE;   { Reset Start Packet Flag           }
       END;
     END;                               { END (WITH ScaleReadInfo[ScaleNo]) }
   END;
 UNTIL (ScaleReadInfo[ScaleNo].SI_GotAScalePacket);  {Packet Recieved}
End;

{$ELSE}
{PROCEDURE TO READ A SCALE PACKET }

{$R-}
{$S-}

VAR IRQID,
    ByteIn,
    PacketEnd  : BYTE;
    EndPacket  : BOOLEAN;
    SaveSS     : WORD;
    SaveSP     : WORD;
    IntSP      : WORD;
    INTSTACK      : ARRAY[1..512] OF WORD;

PROCEDURE ReadScale1Port; INTERRUPT;
BEGIN

 IntSP := Ofs(INTSTACK)+1024;
 asm
  MOV   BP,SP
  MOV   SaveSS,SS    { Save Current Stack Segment }
  MOV   SaveSP,AX    { Save AX Register }
  MOV   AX,DS        { Move DataSeg TO AX}
  MOV   SS,AX        { Set New Stack Segment To DataSeg}
  MOV   AX,SP        { Save Stack Pointer To AX }
  XCHG  AX,SaveSP    { Restore AX Register And Save Stack Pointer To SaveSP}
  MOV   SP,IntSP     { Set New Stack Pointer }
 end;

 Test8086 :=0;
 IRQID := port[ScaleHardware[1].SH_PortAddr + SER_IRQ_ID];              {Get port status           }
 IF ( IRQID AND SER_ID_PENDING ) = 0 THEN        { Is IRQ pending ?         }
  BEGIN { Yes }
   CASE ( IRQID AND SER_ID_MASK ) OF
    SER_ID_RECEIVED:                             { After data received      }
     BEGIN
      WITH ScaleReadInfo[1] DO                   {SI_}
       BEGIN
        IF SI_GotAScalePacket THEN
         BEGIN
          IF ((port[ScaleHardware[1].SH_PortAddr+SER_LINE_STATUS] and SER_LSR_DATARECEIVED) <> 0) THEN
           BEGIN
            ByteIn := Port[ScaleHardware[1].SH_PortAddr+SER_RXBUFFER];  { Trash Data }
           END
         END
        ELSE
         BEGIN                                   { Clear To Rx Packet       }
          IF ((port[ScaleHardware[1].SH_PortAddr+SER_LINE_STATUS] and SER_LSR_DATARECEIVED) <> 0) THEN
           BEGIN
            IF SI_ScaleType = TLucid THEN
              PacketEnd := ORD(CR)               { Set PacketEnd CHAR       }
            ELSE
              PacketEnd := ETX;                  { Set PacketEnd CHAR       }
            EndPacket := FALSE;                  { Clear End Packet Flag    }
            ByteIn := Port[ScaleHardware[1].SH_PortAddr+SER_RXBUFFER];  { Get CHAR Waiting         }
            IF (ByteIn = STX) THEN
             BEGIN                               { Start of Packet          }
              SI_PacketPos := 0;                 { Reset Buffer Pointer    }
              SI_StartScalePacket := TRUE;       { Set Packet Start Flag   }
             END
            ELSE IF (ByteIn = PacketEnd) THEN    { END OF PACKET RECEIVED }
             BEGIN
              IF SI_StartScalePacket THEN
               BEGIN                             { Packet Start Flag Set    }
                SI_IRQScalePacket[SI_PacketPos] := ByteIn; { Load Buffer    }
                IF (SI_ScaleType = TWeigh_Master) THEN
                 BEGIN
                  IF ((SI_PacketPos = PLEN_WMasterParams) OR
                      (SI_PacketPos = PLEN_WMasterWeight)) THEN
                    SI_GotAScalePacket := TRUE;  { Packet Rx OK             }
                 END
                ELSE
                 BEGIN
                  IF (SI_PacketPos = SI_MaxPacketLen) THEN
                    SI_GotAScalePacket := TRUE;  { Packet Rx OK             }
                 END;
               END;
              SI_PacketPos := 0;                 { Reset Buffer Pointer     }
              SI_StartScalePacket := FALSE;      { Reset Start Packet Flag  }
             END;

            IF SI_StartScalePacket THEN
             BEGIN                               { Have Started Packet RX   }
              SI_IRQScalePacket[SI_PacketPos] := ByteIn; { Store in Buffer   }
              Inc(SI_PacketPos);                 { Move Buffer Pointer      }
             END;

            IF SI_PacketPos > SI_MaxPacketLen THEN  { Buffer Limit Reached     }
             BEGIN
              SI_PacketPos   := 0;                { Reset Buffer Pointer     }
              SI_StartScalePacket := FALSE;       { Reset Packet Start Flag  }
             END;
           END;
         END; {while  data available}
       END;
     END; {SER_ID_RECEIVED}
   END; {CASE ( IRQID and SER_ID_MASK ) of}
  END;

  IF ScaleHardware[1].SH_IRQNo > 7 THEN
    Port[$A0] := $20; { Send EOI To SLAVE_PIC  }
  Port[$20] := $20;   { Send EOI To MASTER_PIC }

 Test8086 := Save8086;
 asm
  MOV   SS,SaveSS    { Restore Stack Segment }
  MOV   SP,SaveSP    { Restore Stack Pointer }
 end;

END;

(*
PROCEDURE ReadScale1Port; INTERRUPT;
BEGIN
 ReadPacketFromPort(ScaleHardware[1].SH_PortAddr,1);
 SendIRQEOI(ScaleHardware[1].SH_IRQNo);               { End of interrupt }
END;
*)

PROCEDURE ReadScale2Port; INTERRUPT;
BEGIN
 IntSP := Ofs(INTSTACK)+1024;
 asm
  MOV   SaveSS,SS    { Save Current Stack Segment }
  MOV   SaveSP,AX    { Save AX Register }
  MOV   AX,DS        { Move DataSeg TO AX}
  MOV   SS,AX        { Set New Stack Segment To DataSeg}
  MOV   AX,SP        { Save Stack Pointer To AX }
  XCHG  AX,SaveSP    { Restore AX Register And Save Stack Pointer To SaveSP}
  MOV   SP,IntSP     { Set New Stack Pointer }
 end;
 Test8086 := 0;

 IRQID := port[ScaleHardware[2].SH_PortAddr + SER_IRQ_ID];              {Get port status           }
 IF ( IRQID AND SER_ID_PENDING ) = 0 THEN        { Is IRQ pending ?         }
  BEGIN { Yes }
   CASE ( IRQID AND SER_ID_MASK ) OF
    SER_ID_RECEIVED:                             { After data received      }
     BEGIN
      WITH ScaleReadInfo[2] DO             {SI_}
       BEGIN
        IF SI_GotAScalePacket THEN
         BEGIN
          IF ((port[ScaleHardware[2].SH_PortAddr+SER_LINE_STATUS] and SER_LSR_DATARECEIVED) <> 0) THEN
           BEGIN
            ByteIn := Port[ScaleHardware[2].SH_PortAddr+SER_RXBUFFER];  { Trash Data }
           END
         END
        ELSE
         BEGIN                                   { Clear To Rx Packet       }
          IF ((port[ScaleHardware[2].SH_PortAddr+SER_LINE_STATUS] and SER_LSR_DATARECEIVED) <> 0) THEN
           BEGIN
            IF SI_ScaleType = TLucid THEN
              PacketEnd := ORD(CR)               { Set PacketEnd CHAR       }
            ELSE
              PacketEnd := ETX;                  { Set PacketEnd CHAR       }
            EndPacket := FALSE;                  { Clear End Packet Flag    }
            ByteIn := Port[ScaleHardware[2].SH_PortAddr+SER_RXBUFFER];  { Get CHAR Waiting         }
            IF (ByteIn = STX) THEN
             BEGIN                               { Start of Packet          }
              SI_PacketPos := 0;                 { Reset Buffer Pointer    }
              SI_StartScalePacket := TRUE;       { Set Packet Start Flag   }
             END
            ELSE IF (ByteIn = PacketEnd) THEN    { END OF PACKET RECEIVED }
             BEGIN
              IF SI_StartScalePacket THEN
               BEGIN                             { Packet Start Flag Set    }
                SI_IRQScalePacket[SI_PacketPos] := ByteIn; { Load Buffer    }
                IF (SI_ScaleType = TWeigh_Master) THEN
                 BEGIN
                  IF ((SI_PacketPos = PLEN_WMasterParams) OR
                      (SI_PacketPos = PLEN_WMasterWeight)) THEN
                    SI_GotAScalePacket := TRUE;  { Packet Rx OK             }
                 END
                ELSE
                 BEGIN
                  IF (SI_PacketPos = SI_MaxPacketLen) THEN
                    SI_GotAScalePacket := TRUE;  { Packet Rx OK             }
                 END;
               END;
              SI_PacketPos := 0;                 { Reset Buffer Pointer     }
              SI_StartScalePacket := FALSE;      { Reset Start Packet Flag  }
             END;

            IF SI_StartScalePacket THEN
             BEGIN                               { Have Started Packet RX   }
              SI_IRQScalePacket[SI_PacketPos] := ByteIn; { Store in Buffer   }
              Inc(SI_PacketPos);                 { Move Buffer Pointer      }
             END;

            IF SI_PacketPos > SI_MaxPacketLen THEN  { Buffer Limit Reached     }
             BEGIN
              SI_PacketPos   := 0;                { Reset Buffer Pointer     }
              SI_StartScalePacket := FALSE;       { Reset Packet Start Flag  }
             END;
           END;
         END; {while  data available}
       END;
     END; {SER_ID_RECEIVED}
   END; {CASE ( IRQID and SER_ID_MASK ) of}
  END;
  IF ScaleHardware[2].SH_IRQNo > 7 THEN
    Port[$A0] := $20; { Send EOI To SLAVE_PIC  }
  Port[$20] := $20;   { Send EOI To MASTER_PIC }

 Test8086 := Save8086;
 asm
  MOV   SS,SaveSS    { Restore Stack Segment }
  MOV   SP,SaveSP    { Restore Stack Pointer }
 end;

END;

(*
PROCEDURE ReadScale2Port; INTERRUPT;   {Address of second port configurable}
BEGIN
 ReadPacketFromPort(ScaleHardware[2].SH_PortAddr,2);
 SendIRQEOI(ScaleHardware[2].SH_IRQNo);
END;
*)
{$S+}
{$R+}

{$ENDIF}

{---------------------------------------------------------------------------}
{Routines To Store/Retrieve Scale Parameters From File (WEIGHMASTER ONLY)   }
{---------------------------------------------------------------------------}

FUNCTION OpenParamFile(NewFileMode : INTEGER) : INTEGER;
VAR Retries : INTEGER;                           { Retries                  }
    OpenErr : INTEGER;
BEGIN
 Assign(ParamFile,PROP_FILFilePath+ScaleParameterFileName);
 FileMode := NewFileMode;
 Retries := 1000;                                { No of Open Attempts      }
 REPEAT
   {$I-}
    Reset(ParamFile);                            { Attempt To Open File     }
   {$I+}
   OpenErr := IOResult;                          { Get Open Status          }
   IF OpenErr = ACCESS_DENIED THEN               { File Being Generated/Busy}
    BEGIN
     DEC(Retries);                               { Decrement Retry Counter  }
     Delay(20);                                  { Wait 20ms                }
    END
   ELSE IF OpenErr = FILE_NOT_FOUND THEN Break;  { File Does Not Exist      }
 UNTIL ( OpenErr = 0 ) OR ( Retries = 0 );
 OpenParamFile := OpenErr;                       { Return Open Result Code  }
END;

{---------------------------------------------------------------------------}
{ FUNCTION CheckParamFile                                                   }
{ Attempts to open scale parameter file, creates new if file is not found   }
{---------------------------------------------------------------------------}
FUNCTION CheckParamFile : BOOLEAN;
VAR OldFileMode,I : INTEGER;
BEGIN
 FillChar(ScaleParameters,Sizeof(ScaleParameters),0);
 ScaleParameters.NumDecimal   := 2;
 CheckParamFile := TRUE;
 OldFileMode := FileMode;
 IF (OpenParamFile(READ_WRITE+DENY_ALL) <> 0) THEN
  BEGIN
   {$I-}
   ReWrite(ParamFile);
   {$I+}
   IF (IOResult <> 0) THEN
    BEGIN
     CheckParamFile := FALSE;
     EXIT;
    END;
   FOR I := 0 TO 100 DO Write(ParamFile,ScaleParameters);
  END;
 Close(ParamFile);
 FileMode := OldFileMode;
END;

{---------------------------------------------------------------------------}
{ FUNCTION0 GetParameters                                                   }
{ Attempts to open scale parameter file, reads scale params                 }
{ Also Sets Capacity & Increment Fields in ScaleReadInfo Record             }
{---------------------------------------------------------------------------}
PROCEDURE GetParameters;
CONST NoDecimal = ORD('0')+5;
VAR   I         : INTEGER;
      OldFileMode : INTEGER;
BEGIN
 IF (ScaleHardware[ReadingScale].SH_ScaleType <> TWeigh_Master) THEN EXIT;

 OldFileMode := FileMode;
 IF (OpenParamFile(READ_WRITE+DENY_ALL) = 0) THEN
  BEGIN
   Seek(ParamFile,GetCurrentMachineID);
   Read(ParamFile,ScaleParameters);
   Close(ParamFile);
  END;
 FileMode := OldFileMode;

 WITH ScaleParameters,ScaleReadInfo[ReadingScale] DO
  BEGIN
   SI_ScaleIncrement := FPLong_To_Double(LSD,NumDecimal);
   SI_ScaleCapacity  := FPLong_To_Double(Over,NumDecimal);
   IF (SI_ScaleIncrement = 0.0) THEN SI_ScaleIncrement := 0.05;
   IF (SI_ScaleCapacity  = 0.0) THEN SI_ScaleCapacity  := 60.0;
  END;
END;

PROCEDURE SetParameters;
CONST NoDecimal = ORD('0')+5;
VAR   I         : INTEGER;
      OldFileMode : INTEGER;
      TempFile    : FILE OF ScaleData;
BEGIN
(*
 Assign(TempFile,'TST.FIL');
{$I-}
 Reset(TempFile);
{$I+}
 IF IOResult <> 0 THEN
   Rewrite(TempFile);
 Seek(TempFile,FileSize(TempFile));
 Write(TempFile,ScalePortData);
 Close(TempFile);
*)
 OldFileMode := FileMode;
 ScaleParameters.NumDecimal := NoDecimal-ScalePortData.Param_LZB;
 ScaleParameters.LSD   := 0;
 ScaleParameters.LSDLB := 0;
 ScaleParameters.OVER  := 0;
 FOR I := 0 TO 7 DO
  BEGIN
   ScaleParameters.LSD   := ScaleParameters.LSD*10+ORD(ScalePortData.Param_LSD[I])-ORD('0');
   ScaleParameters.LSDLB := ScaleParameters.LSDLB*10+Ord(ScalePortData.Param_LSDLB[I])-ORD('0');
  END;
 FOR I := 0 TO 5 DO
  BEGIN
   ScaleParameters.Over := ScaleParameters.Over*10+ScalePortData.Param_OVER[I]-ORD('0');
  END;
 IF (OpenParamFile(READ_WRITE+DENY_ALL) = 0) THEN
  BEGIN
   Seek(ParamFile,GetCurrentMachineID);
   Write(ParamFile,ScaleParameters);
   Close(ParamFile);
  END;
 FileMode := OldFileMode;
END;



PROCEDURE SetScaleToKGDataMode;
VAR FirstCheck : BOOLEAN;
    ScalePacket : INTEGER;
BEGIN
 FirstCheck := TRUE;
 CASE ScaleHardware[ReadingScale].SH_ScaleType OF
  TWeigh_Master : BEGIN
      FirstCheck := TRUE;
      WriteByteToPort(ScaleReadInfo[ReadingScale].SI_PortAddr,ScaleZeroCommand,100);
      REPEAT
       CheckForTimeOut(FirstCheck,ScaleTimeOut,FALSE);
       FirstCheck := FALSE;
{$IFDEF NOINTERRUPT}
       ReadPacketFrromPort(SER_COM2,ReadingScale);
{$ENDIF}
       ScalePacket := GetPacketFromScale;
      UNTIL (ScalePacket = PT_Data) OR TimeOutError;
      IF TimeOutError THEN EXIT;
      IF (ScalePortData.WM_St1 AND S1_LB_MODE) <> 0 THEN
       WriteByteToPort(ScaleReadinfo[ReadingScale].SI_PortAddr,88,0);
  END; {CASE WeighMaster}
  TSystem80 : BEGIN
      IF (ScalePortData.S80_Range = ORD('L')) THEN
       BEGIN
        WriteStrAt(0,16,'Change Scale To KG Mode');
        REPEAT
         ScalePacket := GetPacketFromScale;
        UNTIL ScalePortData.S80_Range = ORD('K');
       END;
  END;
  TLucid : BEGIN  {Lucid only works in kg}
  END;
 END; {CASE}
 ScaleReadInfo[ReadingScale].SI_GotAScalePacket := FALSE;
END;

FUNCTION GetPacketFromScale : INTEGER;

   {Function ReadScalePacket Returns TRUE if there is a waiting scale packet}
   FUNCTION ReadScalePacket : BOOLEAN;
   VAR ScalePacketPending : BOOLEAN;
   BEGIN
   {$IFDEF NOINTERRUPT}
    ReadPacketFrromPort(SER_COM2,ReadingScale);
    ScalePacketPending := ScaleReadInfo[ReadingScale].SI_GotAScalePacket;
   {$ELSE}
    ScalePacketPending := (ScaleHardware[ReadingScale].SH_Initialized) AND
                          (ScaleReadInfo[ReadingScale].SI_GotAScalePacket);
   {$ENDIF}
    IF ScalePacketPending THEN
     BEGIN
 {ScalePortData.Packet is smaller in size than TScaleReadInfo.IRQScalePacket}
      MOVE(ScaleReadInfo[ReadingScale].SI_IRQScalePacket,ScalePortData.Packet,SizeOf(ScalePortData.Packet));
      ScaleReadInfo[ReadingScale].SI_GotAScalePacket := FALSE;
     END;
    ReadScalePacket := ScalePacketPending;
   END;

BEGIN
 GetPacketFromScale := PT_NoPacket;
 IF ScaleReadInfo[ReadingScale].SI_ScaleType = TNoScale THEN
   EXIT;
  {****}

 IF (ReadScalePacket) THEN
  BEGIN
   {Have Recieved A Scale Packet Now Must Check That it is a Data Packet}
   IF ScaleHardware[ReadingScale].SH_ScaleType = TWeigh_Master THEN
    BEGIN
     IF (ScalePortData.Param_ID = ORD('S')) THEN
      BEGIN
       GetPacketFromScale := PT_Parameters;
      END
     ELSE GetPacketFromScale := PT_Data;
    END
   ELSE IF (ScaleHardware[ReadingScale].SH_ScaleType = TSystem80) THEN
    BEGIN
     GetPacketFromScale := PT_Data;
    END
   ELSE IF (ScaleHardware[ReadingScale].SH_ScaleType = TLucid) THEN
    BEGIN
     GetPacketFromScale := PT_Data;
    END;
  END;
END;



PROCEDURE SwitchToScale(ScaleNo : WORD);
VAR CurrentScale : WORD;

  PROCEDURE DisableScaleInterrupts;
  VAR SHIdx : BYTE;
  BEGIN
{$IFNDEF NOINTERRUPT}
   FOR SHIdx := 1 TO 2 DO
    BEGIN                     { Disable INTERRUPTS For All Scale Com Ports }
     WITH ScaleHardWare[SHIDx] DO
      BEGIN
       IF  SH_Available
       AND (SH_IRQNo <> 0) THEN DisableIRQ(SH_IRQNo);
      END;
    END;
{$ENDIF}
  END;

  PROCEDURE EnableScaleInterrupt;
  BEGIN
   {$IFNDEF NOINTERRUPT}
     WITH ScaleHardWare[ReadingScale] DO
      BEGIN
       IF  SH_Available
       AND (SH_IRQNo <> 0) THEN EnableIRQ(SH_IRQNo);
      END;
   {$ENDIF}
  END;

BEGIN
 IF ScaleHardware[ScaleNo].SH_Available THEN
  BEGIN
(* Doesnt seem to re-enable interrupt once disabled!
   T.C. suggests that leaving inrerrupt switched off whilst its being
   called stops it working if its not handled. Might need double ack to
   get it responding again ...

   Suggest code is changed to call RestoreSerialIRQHandler etc.

   Temp fix is not to disable interrupts handlers

   TB 16/12/2002
   ---------------------------------------------------------------------
   DisableScaleInterrupts;                       { Disable All Scale IRQ's  }
*)
   CurrentScale := ReadingScale;                 { Save Current Scale No    }
   ReadingScale := ScaleNo;                      { Set New Scale Number     }
(*
   EnableScaleInterrupt;                         { Enable IRQ For New Scale }
*)
   TimeOutError := FALSE;                        { Clear Timeout Flag       }
   CalibrateScale;                               { Get Scale Cal. Info      }
   IF (TimeOutError) THEN
    BEGIN                                        { Scale Does NOT Respond   }
(*
     DisableScaleInterrupts;                     { Disable All Scale IRQ's  }
*)
     ReadingScale := CurrentScale;               { Restore Original Scale   }
(*
     EnableScaleInterrupt;                       { Enable IRQ For Original  }
*)
     CalibrateScale;                             { Get Scale Cal. Info      }
    END;
  END;
END;

PROCEDURE SwitchToDefaultScale;
BEGIN
 SwitchToScale(InitialScale);                    { Switch To Default Scale  }
 ClrGraphWin;
END;

FUNCTION GetKgScaleIncrement : DOUBLE;
BEGIN
 GetKgScaleIncrement := ScaleReadInfo[ReadingScale].SI_ScaleIncrement;
END;

FUNCTION GetScaleParameters(VAR ScaleData : TScaleHardware;Scaleno : WORD) : BOOLEAN;
CONST SectionNames : ARRAY[1..2] OF STRING[8] = ('[SCALE1]','[SCALE2]');
VAR ScaleDataFile : TEXT;
    IOError : INTEGER;
    FileError : BOOLEAN;
    TimeOut  : INTEGER;
    ReadLine : STRING[80];
    SectionFound : BOOLEAN;
    ValErr : INTEGER;
BEGIN
 GetScaleParameters := FALSE;
 IF (ScaleNo < 1) OR (ScaleNo > 2) THEN EXIT;
 FillChar(ScaleData,Sizeof(TScaleHardware),0);
 Assign(ScaleDataFile,ScaleDataFileName);
 FileError := FALSE;
 TimeOut := 200;
 REPEAT
  {$I-}
  Reset(ScaleDataFile);
  {$I+}
  IOError := IOResult;
  IF (IOError IN SHARE_ERRORS) THEN
   BEGIN
    Dec(Timeout);
    Delay(10);
   END
  ELSE FileError := TRUE;
 UNTIL (IOError = 0) OR (FileError) OR (Timeout = 0);
 IF (IOError = 0) THEN
  BEGIN
   SectionFound := FALSE;
   WHILE (NOT EOF(ScaleDataFile)) DO
    BEGIN
     Readln(ScaleDataFile,ReadLine);
     Stripped(ReadLine,Length(ReadLine),' ');
     IF (SectionFound) THEN
      BEGIN
       IF (ReadLine[1] = '[') THEN BREAK
       ELSE IF (StringLIComp('PortAddr=',ReadLine,9) = 0) THEN
        BEGIN
{$IFDEF DEBUG}
         WriteStrAt(1,3,ReadLine);
{$ENDIF}
         SYSTEM.Delete(ReadLine,1,9);
         HexStrToInt(ReadLine,ScaleData.SH_PortAddr,ValErr);
        END
       ELSE IF (StringLIComp('IRQNO=',ReadLine,6) = 0) THEN
        BEGIN
{$IFDEF DEBUG}
         WriteStrAt(1,5,ReadLine);
{$ENDIF}
         SYSTEM.Delete(ReadLine,1,6);
         ScaleData.SH_IRQNo := StringToLong(ReadLine);
        END
       ELSE IF (StringLIComp('BAUD=',ReadLine,5) = 0) THEN
        BEGIN
{$IFDEF DEBUG}
         WriteStrAt(1,7,ReadLine);
{$ENDIF}
         SYSTEM.Delete(ReadLine,1,5);
         ScaleData.SH_BaudRate := StringToLong(ReadLine);
        END
       ELSE IF (StringLIComp('SCALE=',ReadLine,6) = 0) THEN
        BEGIN
{$IFDEF DEBUG}
         WriteStrAt(1,9,ReadLine);
{$ENDIF}
         SYSTEM.Delete(ReadLine,1,6);
         ScaleData.SH_ScaleType := GetScaleTypeFromName(ReadLine);
        END;

       WITH ScaleData DO
        BEGIN
         IF ((SH_IRQNo <> 0) AND (SH_PortAddr <> 0) AND
             (SH_BaudRate <> 0) AND (SH_ScaleType <> TNoScale)) THEN
          BEGIN
           SH_Available := TRUE;
          END;
        END;
      END
     ELSE IF (StringLIComp(ReadLine,SectionNames[ScaleNo],8) = 0) THEN
      BEGIN
{$IFDEF DEBUG}
       WriteStrAt(1,1,ReadLine);
{$ENDIF}
       SectionFound := TRUE;
       GetScaleParameters := TRUE;
      END
     ELSE IF (ReadLine[1] = '[') AND (SectionFound) THEN BREAK;
    END;
   Close(ScaleDataFile);
  END;
 IF ScaleData.SH_ScaleType = TNoScale THEN
  BEGIN
   FillChar(ScaleData, SizeOf(ScaleData), 0);
   ScaleData.SH_ScaleType := TNoScale;
   ScaleData.SH_Available := TRUE;
  END;
 GetScaleParameters := ScaleData.SH_Available;
END;


(*
PROCEDURE SetPacketSize;
BEGIN
 CASE ScaleHardware[ReadingScale].SH_ScaleType OF
  TWeigh_Master : BEGIN
   PacketSize := PLEN_WMasterParams;
  END;
  TSystem80     : BEGIN
   PacketSize := PLEN_S80Weight;
  END;
  TLucid        : BEGIN
   PacketSize := PLEN_LucidWeight;
  END;
 END;
{$IFDEF DEBUG}
 WriteStrAt(50,1,'PacketSize = '+IntToStr(PacketSize,1));
{$ENDIF}
END;
*)

PROCEDURE CalibrateScale;
VAR FirstCheck  : BOOLEAN;
    ScalePacket : INTEGER;
{$IFDEF DEBUG}
    YPos        : INTEGER;
{$ENDIF}

 PROCEDURE WaitForAScalePacket;
 BEGIN
  FirstCheck := TRUE;
  REPEAT
{$IFDEF NOINTERRUPT}
    ReadPacketFrromPort(SER_COM2,ReadingScale);
{$ENDIF}
   ScalePacket := GetPacketFromScale;
   IF (ScalePacket = PT_NoPacket) THEN
    BEGIN
     CheckForTimeOut(FirstCheck,ScaleTimeOut,FALSE);
    END;
   FirstCheck := FALSE;
  UNTIL (ScalePacket <> PT_NoPacket) OR TimeOutError;
 END;

BEGIN
{$IFDEF DEBUG}
 YPos := 20+(ReadingScale-1)*6;
 WriteStrAt(1,YPos,'Scale Number '+IntToStr(ReadingScale,1));
 ShowData := TRUE;
 DataXPos := 0;
 DataYPos := YPos+4;
{$ENDIF}

 CASE ScaleHardware[ReadingScale].SH_ScaleType OF

  TWeigh_Master : BEGIN
{$IFDEF DEBUG}
     WriteStrAt(1,YPos+2,'Weighmaster Scale');
{$ENDIF}
     WaitForAScalePacket;
     IF TimeOutError THEN
      BEGIN
       EXIT;
{$IFDEF DEBUG}
       ShowData := FALSE;
{$ENDIF}
      END;
     IF (ScalePacket = PT_Parameters) THEN SetParameters;
     SetScaleToKGDataMode;
  END;

  TSystem80 : BEGIN
{$IFDEF DEBUG}
     WriteStrAt(1,Ypos+2,'System80 Scale');
{$ENDIF}
     WriteByteToPort(ScaleHardware[ReadingScale].SH_PortAddr,Ord('0')+ReadingScale,0);
     WriteByteToPort(ScaleHardware[ReadingScale].SH_PortAddr,Ord('C'),0);
     WaitForAScalePacket;
     IF TimeOutError THEN
      BEGIN
{$IFDEF DEBUG}
       ShowData := FALSE;
{$ENDIF}
       EXIT;
      END;
     SetScaleToKGDataMode;
  END;

  TLucid : BEGIN
{$IFDEF DEBUG}
     WriteStrAt(1,Ypos+2,'Lucid Scale');
{$ENDIF}
     WaitForAScalePacket;
     IF TimeOutError THEN
      BEGIN
       WriteStrAt(1,1,'No Scale Data');
{$IFDEF DEBUG}
       ShowData := FALSE;
{$ENDIF}
       EXIT;
      END;
     SetScaleToKGDataMode;
     IF (ScalePortData.LUC_NoDP <= 0) THEN
     ScalePortData.LUC_NoDP := ORD('2');
     ScaleReadInfo[ReadingScale].SI_ScaleIncrement := FPLong_To_Double(2,ScalePortData.LUC_NoDP-ORD('0'));
  END;

 END;
 ScaleReadInfo[ReadingScale].SI_GotAScalePacket := FALSE;

{$IFDEF DEBUG}
 ShowData := FALSE;
{$ENDIF}
END;


FUNCTION InitialiseScale(ScaleNo : BYTE) : INTEGER;
VAR PortInitErr : INTEGER;
BEGIN
{$IFDEF DEBUG}
 WriteStrAt(1,10,'                          ');
 WriteStrAt(1,12,'                          ');
 WriteStrAt(1,14,'                          ');
 WriteStrAt(1,16,'                          ');
{$ENDIF}
 PortInitErr := 0;
 WITH ScaleReadInfo[ScaleNo],ScaleHardware[ScaleNo] DO
  BEGIN
   IF SH_ScaleType <> TNoScale THEN
    BEGIN
{$IFDEF DEBUG}
     WriteStrAt(1,10,'Port Address = '+InttoStr(SH_PortAddr,1));
{$ENDIF}
     SI_PortAddr  := SH_PortAddr;
     SI_ScaleType := SH_ScaleType;

     CASE SH_ScaleType OF
      TWeigh_Master : SI_MaxPacketLen := PLEN_WMasterParams;
      TSystem80     : SI_MaxPacketLen := PLEN_S80Weight;
      TLucid        : SI_MaxPacketLen := PLEN_LucidWeight;
     END;

     IF SH_Available THEN
      BEGIN
       PortInitErr := InitiatePort(SH_PortAddr,
                      SH_BaudRate,
                      SER_LCR_8BITS OR SER_LCR_1STOPBIT OR SER_LCR_NOPARITY,
                      TRUE,'SCALE1');

       IF  (PortInitErr <> BAUD_ERROR)
       AND (SH_IRQNo <> 0) THEN
        BEGIN
         SH_Initialized := TRUE;
{$IFNDEF NOINTERRUPT}
{$IFDEF DEBUG}
         WriteStrAt(1,12,'Setting Interrupt '+IntToStr(SH_IRQNo,1));
{$ENDIF}
         CASE ScaleNo OF
          1: SH_lpOldIRQFunc := SetSerialIRQHandler(SH_PortAddr,
                                                  SH_IRQNo,
                                                  @ReadScale1Port,
                                                  SER_IER_RECEIVED);


          2: SH_lpOldIRQFunc := SetSerialIRQHandler(SH_PortAddr,
                                                  SH_IRQNo,
                                                  @ReadScale2Port,
                                                  SER_IER_RECEIVED);
         END;

{$ENDIF}
        END;
{$IFDEF DEBUG}
       WriteStrAt(1,14,'calibrating scale');
{$ENDIF}
       ReadingScale := ScaleNo;
       CalibrateScale;
{$IFDEF DEBUG}
       WriteStrAt(1,16,'scale calibration complete');
{$ENDIF}
      END;
    END;
  END;
 InitialiseScale := PortInitErr;
END;


FUNCTION GetScaleData : BOOLEAN;
BEGIN
{$IFDEF NOINTERRUPT}
 GetScaleData := TRUE;
{$ELSE}
 GetScaleData := FALSE;
{$ENDIF}
 GetScaleParameters(ScaleHardware[1],1);
 GetScaleParameters(ScaleHardware[2],2);
 GetScaleData := TRUE;
{$IFDEF DEBUG}
 ReadLn;
{$ENDIF}
END;


{SCALE COMMS INIT}
FUNCTION ScaleCommsInit : BOOLEAN;
VAR Scale1Init,
    Scale2Init : INTEGER;
    I    : INTEGER;
BEGIN
 Scale1Init := 0;
 Scale2Init := 0;
 ScaleCommsInit := FALSE;
{$IFDEF DEBUG}
 ShowData := FALSE ;
{$ENDIF}

 ReadingScale := 1;
 FillChar(ScalePortData,sizeof(scalePortData),0);
 FillChar(ScaleHardware,sizeof(ScaleHardware),0);
 ScaleDataFileName := GetScaleDataFileName;
 IF NowtButSpace(ScaleDataFileName) THEN { make scale 1 operable by keyboard }
  BEGIN
   WITH ScaleHardware[1] DO
     SH_ScaleType    := TNoScale;    {Scale Type of connected scale       }
  END
 ELSE IF (GetScaleData) THEN
  BEGIN
{ ScaleParameterFileName := GetScaleParamFileName;}
   ScaleCommsInit := FALSE;
   ScaleTimeOut := GetScaleTimeOut;
   FillChar(ScaleReadInfo,SizeOf(ScaleReadInfo),#0);

   Scale1Init := InitialiseScale(1);
   Scale2Init := InitialiseScale(2);
   IF Scale1Init <> BAUD_ERROR THEN SwitchToScale(1);
  END;
 ScaleWindowTimeOutError := TimeOutError;

 FOR I := Low(ScaleHardware) TO High(ScaleHardware) DO
  BEGIN
   WITH ScaleHardware[I] DO
    BEGIN
     IF SH_ScaleType = TNoScale THEN
      BEGIN
       SH_Available    := TRUE;        {TRUE if setting in ini for scale    }
       SH_Initialized  := TRUE;        {TRUE if port has been initialised   }
      END;
    END;
  END;

 ScaleCommsInit := (Scale1Init <> BAUD_ERROR)
               AND (Scale2Init <> BAUD_ERROR);
END;


PROCEDURE ScaleCommsDone;
CONST CommsLogOut : BOOLEAN = FALSE;
BEGIN
 IF CommsLogOut THEN EXIT;
 CommsLogOut := TRUE;
{$IFNDEF NOINTERRUPT}
 WITH ScaleHardware[1] DO
  BEGIN
   IF  (SH_Available)
   AND (SH_IRQNo <> 0) THEN
     RestoreSerialIRQHandler(SH_PortAddr,SH_IRQNo,SH_lpOldIRQFunc);
  END;

 WITH SCaleHardware[2] DO
  BEGIN
   IF  (SH_Available)
   AND (SH_IRQNo <> 0) THEN
     RestoreSerialIRQHandler(SH_PortAddr,SH_IRQNo,SH_lpOldIRQFunc);
  END;
{$ENDIF}
END;

BEGIN
 ReadingScale := 1;
 Save8086     := Test8086;
END.



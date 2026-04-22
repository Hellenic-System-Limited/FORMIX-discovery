{$O+,F+}
{$I F6COMP}

{$IFnDEF TERMINAL} not required {$ENDIF}

UNIT FXDETAIL;
INTERFACE
USES Crt,F6StdCtv,F6StdUtl,FXCfg,F6StdWn1,FXFIni
{$IFDEF TERMINAL},SFXStd,SFXPorts{$ENDIF},FXModCtv;

TYPE  TSerialPortSettings = PACKED RECORD
       SP_Addr        : WORD;
       SP_Baud        : LONGINT;
       SP_FrameFlags : WORD;
      END;
{$IFDEF TERMINAL}
FUNCTION  TermSettingsInit:BOOLEAN;
FUNCTION  GetNextRunNumber : LONGINT;
FUNCTION  GetCurrentMachineID : BYTE;
FUNCTION  GetCurrentRunNumber : LONGINT;
FUNCTION  ShouldUserBePromptedForLotBatch : BOOLEAN;
FUNCTION  DisregardKeyIngredient : BOOLEAN;
FUNCTION  GetTicketPrinterPortAddr : WORD;
PROCEDURE GetTicketPtrPortSettings(VAR RetRec : TSerialPortSettings);
FUNCTION  GetNumberOfTicketsToPrint : INTEGER;
FUNCTION  PrintTicket : BOOLEAN;
FUNCTION  GetNumberOfMixTickets : INTEGER;
FUNCTION  GetPrintMixTicket : BOOLEAN;
FUNCTION  GetLTSCheckSetting: BOOLEAN;
FUNCTION  GetSystemPassWord : STRING;
FUNCTION  LotNumbersReqd : BOOLEAN;
FUNCTION  GetWorkGroupFilter : STRING;
FUNCTION  GetManWtTickBox : BOOLEAN;
FUNCTION  GetScreenContrast : INTEGER;


PROCEDURE SetCurrentMachineID   (M_ID      : BYTE);
PROCEDURE SetCurrentRunNumber   (Rn        : LONGINT);
PROCEDURE SetPromptForLotBatch  (AskForLB  : BOOLEAN);
PROCEDURE SetDisregardKeyIngredient(Disregard : BOOLEAN);
PROCEDURE SetTicketPrinterPort  (Port      : WORD);
PROCEDURE SetTicketPtrPortSettings(Settings : TSerialPortSettings);
PROCEDURE SetPrintTicket        (Print     : BOOLEAN);
PROCEDURE SetLTSCheck(On : BOOLEAN);
PROCEDURE SetNumberofMixTickets(ToPrint : INTEGER);
(*PROCEDURE SetPrintMixTicket     (Print     : BOOLEAN);*)
PROCEDURE SetNumberOfTicketsToPrint(ToPrint : INTEGER);
PROCEDURE SetSystemPassWord(VAR PassWord : STRING);
PROCEDURE SetLotOptions(LotNoOn : BOOLEAN);
PROCEDURE SetWorkGroupFilter(Filter : STRING);
PROCEDURE SetManWtTickBox(AllowManWts : BOOLEAN);
PROCEDURE SetScreenContrast(NewContrast : INTEGER);

{$ENDIF}


FUNCTION  GetAutoBatchNumber : INTEGER;

IMPLEMENTATION


CONST SharedFileName = 'SCALE.FIL';

TYPE
      PTermSettingsRec = ^TTermSettingsRec;
      TTermSettingsRec = PACKED RECORD
       SystemPassWord : STRING[8];
       ScaleMID       : BYTE;
       RunNumber      : LONGINT;
       AskForLB       : BOOLEAN;
       GetTare        : BOOLEAN;
       DisregardKey   : BOOLEAN;
       TicketPrinterPort : WORD; { OBSOLETE - if non zero then needs transferring }
       TicketsToPrint : INTEGER;
       TicketPrint    : BOOLEAN;
       PrintMixTicket : BYTE;
       AutoBatchNo    : INTEGER;
       UseLotNos      : BOOLEAN;
       CheckLTSBeforePrint : BOOLEAN;
       PtrPortSetup   : TSerialPortSettings;
       WrkGrpFilter   : TWorkGrp;
       AllowManWtEntries : BOOLEAN;
       ScreenContrast : INTEGER;
       SPACE          : ARRAY[0..173] OF BYTE;
      END;

VAR TempSettingsFile  : FILE OF TTermSettingsRec;
CONST
    TerminalSettings  : PTermSettingsRec = NIL;
    SharedTermSettings: PTermSettingsRec = NIL;


FUNCTION OpenFile(AccessMode : BYTE;MainFile : boolean) : INTEGER;
VAR Retries : INTEGER;                           { Retries                  }
    OpenErr : INTEGER;
    SavedFileMode : BYTE;
BEGIN
 SavedFileMode := FileMode;
 FileMode := AccessMode;                         { Set File Access Mode     }

 IF MainFile THEN               { File Being Generated/Busy}
  Assign(TempSettingsFile,Config_Rec^.Conf_FPath+Config_Rec^.CONF_ScaleDetailsFileName)
 else
  Assign(TempSettingsFile,Config_Rec^.Conf_FPath+SharedFileName);
 Retries := 1000;                                { No of Open Attempts      }
 REPEAT
   {$I-}
    Reset(TempSettingsFile);                     { Attempt To Open File     }
   {$I+}
   OpenErr := IOResult;                          { Get Open Status          }
   IF OpenErr = ACCESS_DENIED THEN               { File Being Generated/Busy}
    BEGIN
     DEC(Retries);                               { Decrement Retry Counter  }
     Delay(20);                                  { Wait 20ms                }
    END
   ELSE IF OpenErr = FILE_NOT_FOUND THEN Break;  { File Does Not Exist      }
 UNTIL ( OpenErr = 0 ) OR ( Retries = 0 );
 FileMode := SavedFileMode;

 OpenFile := OpenErr;                            { Return Open Result Code  }
END;

FUNCTION OpenAndReadTermSettings : BOOLEAN;
{ NOTE : If returns TRUE then LEAVES FILE OPEN }
BEGIN
 OpenAndReadTermSettings := TRUE;

 IF TerminalSettings = NIL THEN
   NEW(TerminalSettings);

 IF OpenFile(Read_Write+Deny_ALL,true) = 0 THEN
  BEGIN
   Read(TempSettingsFile,TerminalSettings^);
  END
 ELSE
  BEGIN
   OpenAndReadTermSettings := FALSE;
   Dispose(TerminalSettings);
   TerminalSettings := NIL;
  END;
END;

PROCEDURE WriteToAndCloseTempSettingsFile(PrevReadRecord : PTermSettingsRec);
BEGIN
 Seek(TempSettingsFile,0);
 Write(TempSettingsFile,PrevReadRecord^);
 Close(TempSettingsFile);
END;

{$IFDEF TERMINAL}

FUNCTION GetTerminalSettings : BOOLEAN;
BEGIN
 GetTerminalSettings := TRUE;
 IF TerminalSettings = NIL THEN { need to read it from file }
  BEGIN
   IF OpenAndReadTermSettings THEN { need to close file }
     Close(TempSettingsFile)
   ELSE
     GetTerminalSettings := FALSE;
  END;
END;



FUNCTION ShouldUserBePromptedForLotBatch : BOOLEAN;
BEGIN
 ShouldUserBePromptedForLotBatch := TRUE;
 IF GetTerminalSettings THEN
  BEGIN
   ShouldUserBePromptedForLotBatch := TerminalSettings^.AskForLB;
  END;
END;

FUNCTION  DisregardKeyIngredient : BOOLEAN;
BEGIN
 DisregardKeyIngredient := FALSE;
 IF GetTerminalSettings THEN
  BEGIN
   DisregardKeyIngredient := TerminalSettings^.DisregardKey;
  END;
END;

FUNCTION GetTicketPrinterPortAddr : WORD;
VAR
   TempRec : TSerialPortSettings;
BEGIN
 GetTicketPtrPortSettings(TempRec);
 GetTicketPrinterPortAddr := TempRec.SP_Addr;
END;

PROCEDURE GetTicketPtrPortSettings(VAR RetRec : TSerialPortSettings);
VAR ErrInt : INTEGER;
BEGIN
 WITH RetRec DO { initialise return rec }
  BEGIN
   SP_Addr := 0;
   SP_Baud := 9600;
   SP_FrameFlags := SER_LCR_8BITS or SER_LCR_1STOPBIT or SER_LCR_NOPARITY;
  END;

 IF GetTerminalSettings THEN
  BEGIN
   IF TerminalSettings^.TicketPrinterPort <> 0 THEN { move to new field }
     RetRec.SP_Addr := TerminalSettings^.TicketPrinterPort
   ELSE
     RetRec := TerminalSettings^.PtrPortSetup;

   IF RetRec.SP_Baud = 0 THEN { settings not valid }
     RetRec.SP_Baud := 9600;

   IF NOT NowtButSpace(Config_Rec^.CONF_PrinterPortAddr) THEN
     HexStrToInt(Config_Rec^.CONF_PrinterPortAddr, RetRec.SP_Addr, ErrInt);
  END;
END;

FUNCTION  GetNumberOfTicketsToPrint : INTEGER;
BEGIN
 GetNumberOfTicketsToPrint := 0;
 IF GetTerminalSettings THEN
  BEGIN
   GetNumberOfTicketsToPrint := TerminalSettings^.TicketsToPrint;
  END;
END;

FUNCTION  LotNumbersReqd : BOOLEAN;
BEGIN
 LotNumbersReqd := TRUE;
 IF GetTerminalSettings THEN
  BEGIN
   LotNumbersReqd := TerminalSettings^.UseLotNos;
  END;
END;


FUNCTION  PrintTicket : BOOLEAN;
BEGIN
 PrintTicket := FALSE;
 IF GetTerminalSettings THEN
  BEGIN
   PrintTicket := TerminalSettings^.TicketPrint;
  END;
END;

FUNCTION GetNumberOfMixTickets : INTEGER;
BEGIN
 GetNumberOfMixTickets := 0;
 IF GetTerminalSettings THEN
  BEGIN
   GetNumberOfMixTickets := TerminalSettings^.PrintMixTicket;
  END;
END;


FUNCTION  GetPrintMixTicket : BOOLEAN;
BEGIN
 GetPrintMixTicket := FALSE;
 IF GetTerminalSettings THEN
  BEGIN
   GetPrintMixTicket := (TerminalSettings^.PrintMixTicket <> 0);
  END;
END;

FUNCTION  GetLTSCheckSetting : BOOLEAN;
BEGIN
 GetLTSCheckSetting := FALSE;
 IF GetTerminalSettings THEN
  BEGIN
   GetLTSCheckSetting := (TerminalSettings^.CheckLTSBeforePrint);
  END;
END;

FUNCTION  GetSystemPassWord : STRING;
BEGIN
 GetSystemPassWord := SPACE_STRING;
 IF GetTerminalSettings THEN
  BEGIN
   GetSystemPassWord := Decript(TerminalSettings^.SystemPassWord);
  END;
END;


FUNCTION GetCurrentRunNumber : LONGINT;
BEGIN
 GetCurrentRunNumber := $FFFFFFFF;
 IF GetTerminalSettings THEN
  BEGIN
   GetCurrentRunNumber := TerminalSettings^.RunNumber;
  END;
END;

FUNCTION GetCurrentMachineID : BYTE;
BEGIN
 GetCurrentMachineID := $FF;
 IF GetTerminalSettings THEN
  BEGIN
   GetCurrentMachineID := TerminalSettings^.ScaleMID;
  END;
END;


FUNCTION GetNextRunNumber : LONGINT;
BEGIN
 GetNextRunNumber := -1;
 IF OpenAndReadTermSettings THEN { read from file, not record in memory }
  BEGIN
   INC(TerminalSettings^.RunNumber);
   GetNextRunNumber := TerminalSettings^.RunNumber;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

FUNCTION GetWorkGroupFilter : STRING;
BEGIN
 GetWorkGroupFilter := '*  ';
 IF GetTerminalSettings THEN
   GetWorkGroupFilter := TerminalSettings^.WrkGrpFilter;
END;

FUNCTION GetManWtTickBox : BOOLEAN;
BEGIN
 GetManWtTickBox := FALSE;
 IF GetTerminalSettings THEN
   GetManWtTickBox := TerminalSettings^.AllowManWtEntries;
END;

FUNCTION GetScreenContrast : INTEGER;
BEGIN
 GetScreenContrast := 10;
 IF GetTerminalSettings THEN
   GetScreenContrast := TerminalSettings^.ScreenContrast;
END;

{------------------------- Set Settings -------------------------}


PROCEDURE SetCurrentRunNumber(Rn   : LONGINT);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.RunNumber := RN;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetCurrentMachineID(M_ID : BYTE);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.ScaleMID := M_ID;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetPromptForLotBatch(AskForLB : BOOLEAN);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.AskForLB := AskForLB;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetDisregardKeyIngredient(Disregard : BOOLEAN);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.DisregardKey := Disregard;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetTicketPrinterPort(Port : WORD);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.PtrPortSetup.SP_Addr := Port;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetTicketPtrPortSettings(Settings : TSerialPortSettings);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.PtrPortSetup := Settings;
   TerminalSettings^.TicketPrinterPort := 0;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetNumberOfTicketsToPrint(ToPrint : INTEGER);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.TicketsToPrint := ToPrint;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetSystemPassWord(VAR PassWord : STRING);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.SystemPassWord := EnCript(PassWord);
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetPrintTicket(Print : BOOLEAN);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.TicketPrint := Print;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetNumberofMixTickets(ToPrint : INTEGER);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.PrintMixTicket := BYTE(ToPrint);
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetLTSCheck(On : BOOLEAN);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.CheckLTSBeforePrint := On;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

(*
PROCEDURE SetPrintMixTicket  (Print     : BOOLEAN);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TermSettings^.PrintMixTicket := Print;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;
*)

PROCEDURE SetLotOptions(LotNoOn : BOOLEAN);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.UseLotNos := LotNoOn;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetWorkGroupFilter(Filter : STRING);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.WrkGrpFilter := Filter + Space_String;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetManWtTickBox(AllowManWts : BOOLEAN);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.AllowManWtEntries := AllowManWts;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;

PROCEDURE SetScreenContrast(NewContrast : INTEGER);
BEGIN
 IF OpenAndReadTermSettings THEN
  BEGIN
   TerminalSettings^.ScreenContrast := NewContrast;
   WriteToAndCloseTempSettingsFile(TerminalSettings);
  END;
END;
{$ENDIF}

{----------------------- SHARED SETTINGS FILE -------------------------}
FUNCTION OpenAndReadSharedTermSettings : BOOLEAN;
BEGIN
 OpenAndReadSharedTermSettings := TRUE;

 IF SharedTermSettings = NIL THEN
   NEW(SharedTermSettings);

 IF OpenFile(Read_Write+Deny_ALL,false) = 0 THEN
  BEGIN
   Read(TempSettingsFile,SharedTermSettings^);
  END
 ELSE
  BEGIN
   OpenAndReadSharedTermSettings := FALSE;
   Dispose(SharedTermSettings);
   SharedTermSettings := NIL;
  END;
END;




FUNCTION GetAutoBatchNumber : INTEGER; { $$$}
BEGIN
 GetAutoBatchNumber := -1;
 IF OpenAndReadSharedTermSettings THEN
  BEGIN
   INC(SharedTermSettings^.AutoBatchNo);
   IF (SharedTermSettings^.AutoBatchNo > 9999) THEN
     SharedTermSettings^.AutoBatchNo := 1;
   GetAutoBatchNumber := SharedTermSettings^.AutoBatchNo;
   WriteToAndCloseTempSettingsFile(SharedTermSettings);
  END;
END;

{------------------------ END OF SHARED FILE --------------------}

{$IFDEF TERMINAL}
FUNCTION TermSettingsInit:BOOLEAN;
VAR
  OpenErr : INTEGER;
  TempSettingRec : TTermSettingsRec;

   PROCEDURE InitNewTerminalSettingsRec(VAR ATermRec : TTermSettingsRec);
   BEGIN
    FillChar(ATermRec, SizeOF(ATermRec), #0);
    WITH ATermRec DO
     BEGIN
      SystemPassWord:= EnCript('TRUSTNO1');
      ScaleMID := 1;
      AskForLB := TRUE;
      PtrPortSetup.SP_Baud := 9600;
      PtrPortSetup.SP_FrameFlags := SER_LCR_8BITS or SER_LCR_1STOPBIT or
                                    SER_LCR_NOPARITY;
      ScreenContrast := 10;
     END;
   END;

BEGIN
 TermSettingsInit := TRUE;

 Assign(TempSettingsFile,Config_Rec^.Conf_FPath+
                         Config_Rec^.CONF_ScaleDetailsFileName);
 {$I-}
 Reset(TempSettingsFile);
 {$I+}
 OpenErr := IOResult;
 IF OpenErr = FILE_NOT_FOUND THEN
  BEGIN
   {$I-}
   Rewrite(TempSettingsFile);
   {$I+}
   IF IOResult = 0 THEN
    BEGIN
     InitNewTerminalSettingsRec(TempSettingRec);
     WriteToAndCloseTempSettingsFile(@TempSettingRec);
    END
   ELSE
    BEGIN
     Disp_Error_Msg('File Not Found : '+Config_Rec^.CONF_ScaleDetailsFileName);
     TermSettingsInit := FALSE;
    END
  END
 ELSE IF OpenErr <> 0 THEN
  BEGIN
   WriteLn('Error ',OpenErr:1,' Opening '+Config_Rec^.Conf_FPath+
                                          Config_Rec^.CONF_ScaleDetailsFileName);
  END
 ELSE
   Close(TempSettingsFile);



 Assign(TempSettingsFile,Config_Rec^.Conf_FPath+SharedFileName);
 {$I-}
 Reset(TempSettingsFile);
 {$I+}
 OpenErr := IOResult;
 IF OpenErr = FILE_NOT_FOUND THEN
  BEGIN
   {$I-}
   Rewrite(TempSettingsFile);
   {$I+}
   IF IOResult = 0 THEN
    BEGIN
     InitNewTerminalSettingsRec(TempSettingRec);
     WriteToAndCloseTempSettingsFile(@TempSettingRec);
    END
   ELSE
    BEGIN
     Disp_Error_Msg('File Not Found : '+SharedFileName);
     TermSettingsInit := FALSE;
    END;
  END
 ELSE IF OpenErr <> 0 THEN
  BEGIN
   WriteLn('Error ',OpenErr:1,' Opening '+Config_Rec^.Conf_FPath+
                                          SharedFileName);
  END
 ELSE
   Close(TempSettingsFile);
END;
{$ENDIF}

PROCEDURE TerminalSettingsDispose;
BEGIN
 IF TerminalSettings <> NIL THEN DISPOSE(TerminalSettings);
 IF SharedTermSettings <> NIL THEN DISPOSE(SharedTermSettings);
END;

END.

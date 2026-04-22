(****************************************************************************
*  UNIT          : FXUBIPTR                                                 *
*  AUTHOR        :                                                          *
*  DATE          :                                                          *
*  PURPOSE       :                                                          *
*  MODIFICATIONS :                                                          *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
{$IFnDEF TERMINAL} not required {$ENDIF}
UNIT FXUBIPTR;
INTERFACE

USES CRT,F6Stdctv,Strings,FXDetail,SFXPorts,FXFIni,FXStdUt1,F6StdUtl,F6StdWn1,SFXBtn,
     SFXConst,SFXFGen,SFXGraph,SFXKbd,SFXStd,SFXComms,SFXWin,SFXEdit,SFXMsg,
     FXChoice,FXFWork,FXUbiPrn,SFXUtils;

CONST UBI_DOWNLOAD_OK     =  00;
      UBI_FILE_OPEN_ERROR = 101;
      UBI_FILE_READ_ERROR = 102;
      UBI_PRINTER_TIMEOUT = 103;
      UBI_COMMS_ERROR     = 104;


      LAB_FILE_OPEN_ERROR    = 1;
      LAB_FILE_INVALID_ERROR = 2;

TYPE PTItemTypes = (TextItem,
                    BarcodeWithReadable,
                    BarcodeWithoutReadable);

     PLabelTicketItem = ^TLabelTicketItem;
     TLabelTicketItem = PACKED RECORD
       LTI_Type   : PTItemTypes;
       LTI_Tag    : STRING[30];
       LTI_OutStr : STRING[50];
       LTI_Next   : PLabelTicketItem;
     END;

TYPE PUBIWindow = ^TUBIWindow;
     TUBIWindow = OBJECT(TMenuWindow)
      DESTRUCTOR  Done;VIRTUAL;
      PROCEDURE   SetUpChildWindows;VIRTUAL;
      PROCEDURE   Draw;VIRTUAL;
     END;

VAR LabelItemHeader : PLabelTicketItem;
    UBIWin          : PUBIWindow;

FUNCTION  SendToUBIPrinter(OutStr : STRING;PortAddr : WORD) : INTEGER;
FUNCTION  XmitLabelFormats(FileName : STRING; PortAddr : WORD) : INTEGER;
FUNCTION  SendToUBIE4Printer(Duplex : BOOLEAN; OutStr : STRING;PortAddr : WORD) : INTEGER;
FUNCTION  E4PrinterStatus(PortAddr : WORD; VAR PStat : BYTE) : INTEGER;
FUNCTION  XmitLabelFormatsE4(FileName     : STRING; Desc : STRING; PortAddr     : WORD) : INTEGER;
PROCEDURE DownloadUBIPrinter;
PROCEDURE Get_Label_Items(LabFormat : Char);
PROCEDURE ClearItemList;
PROCEDURE DisposeItemList;
PROCEDURE TicketSetUp;
FUNCTION  TicketPrinterPortInit : BOOLEAN;



IMPLEMENTATION
USES SFXStdBt;

TYPE  LabelItemRecord = PACKED RECORD
       LI_Left     : INTEGER;                    { Bounding Rectangle       }
       LI_Top      : INTEGER;
       LI_Right    : INTEGER;
       LI_Bottom   : INTEGER;
       LI_Data     : ARRAY[0..50] OF CHAR;       { Sample Data/ Record Type }
       LI_XPOS     : INTEGER;
       LI_YPOS     : INTEGER;
       LI_Desc     : CHAR;                       { Item Type Identifier     }
       LI_Dir      : WORD;                       { Direction                }
       LI_Font     : WORD;  {Barcode Type Or Font Number                    }
       LI_MagX     : WORD;                       { X Magnification          }
       LI_MagY     : WORD;                       { Y Magnification          }
       LI_ID       : SHORTINT;                   { Item ID                  }
       LI_LBarFon  : WORD;
       LI_Human    : BOOLEAN;
       LI_IsBar    : BOOLEAN;
       LI_IsLine   : BOOLEAN;
       Lalign      : BOOLEAN;                    { Alignment                }
       LBarX       : BYTE;
       LBarY       : BYTE;
       Next        : Pointer;
      END;


CONST
     MAX_SETUP_LINES = 30;
TYPE
     PIPLPrinter = ^TIPLPrinter;
     TIPLPrinter = OBJECT
       PTR_PortAddr  : WORD;
       PTR_ErrorOutputEnabled : BOOLEAN;
       PTR_SetupList : ARRAY[1..MAX_SETUP_LINES] OF STRING;
       PTR_SettingIndex : INTEGER;
       PTR_LastSerialInputErr : INTEGER;

       CONSTRUCTOR Init(PortAddr : WORD);
       DESTRUCTOR  Done;
       PROCEDURE   InitComms(ErrorsDescsToBeReturned : BOOLEAN);
       PROCEDURE   SendCommand(CommandStr : STRING);
       FUNCTION    GetResponse(VAR Data : STRING) : BOOLEAN;
       PROCEDURE   ReadCurrentSetup;
       FUNCTION    GetAnotherSetting(CommsSetting : BOOLEAN;
                                     VAR Title : STRING;
                                     VAR Data  : STRING;
                                     Forwards  : BOOLEAN) : INTEGER;
       FUNCTION    GetNextSetting(CommsSetting : BOOLEAN;
                                   VAR Title : STRING;
                                   VAR Data  : STRING) : INTEGER;
       FUNCTION    GetPrevSetting(CommsSetting : BOOLEAN;
                                   VAR Title : STRING;
                                   VAR Data  : STRING) : INTEGER;
       FUNCTION    SaveSetting(SettingNo : INTEGER; SettingData : STRING) : BOOLEAN;
       FUNCTION    DataDelimiterPosn(SetupListNo : INTEGER) : INTEGER;
     END;

CONST
     PrinterObj : PIPLPrinter = NIL;
                            { ideally this should point to a base printer
                              object and TicketPrinterPortInit makes it
                              point to newed object for the actual type of
                              printer.
                            }

{=================UBI Window Methods=================}
DESTRUCTOR TUBIWindow.Done;
BEGIN
 INHERITED Done;
END;

PROCEDURE TUBIWindow.SetUpChildWindows;
BEGIN
 AddChildWindow(1,1,1,'Return To'+CRLF+'Main Menu');
 AddChildWindow(1,2,2,'Download'+CRLF+'Label'+CRLF+'Format');
 AddChildWindow(1,3,3,'Set-up'+CRLF+'Printing');
 AddChildWindow(1,4,4,'Edit Printer'+CRLF+'Configuration');
 AddChildWindow(2,4,5,'Download'+CRLF+'Configuration'+CRLF+'File');
END;


PROCEDURE TUBIWindow.Draw;
BEGIN
 WriteHeader('PRINTER OPTIONS');
END;
{======================================================}
FUNCTION SendToUBIPrinter(OutStr : STRING;PortAddr : WORD) : INTEGER;
VAR Offset,
    DummyCs,
    LPA     : BYTE;
    InChar  : CHAR;
    Error   : INTEGER;

BEGIN
  IF COPY(OutStr,1,4) = '$EFM' THEN Offset := 1
  ELSE Offset := 2;

  FOR LPA := Offset TO Length(OutStr) DO
   BEGIN
    { Play Out Character To Printer}
    WriteByteToPort(PortAddr,ORD(OutStr[LPA]),40000);
    DELAY(3);                            { Pace Characters at 3ms Intervals }
   END;
  WriteByteToPort(PortAddr,ORD(CR),40000); { Send Carriage Return             }
  DELAY(3);                              { Pace Characters at 3ms Intervals }
  { Wait For Printer Response        }
  Error := ReadSerialByte(PortAddr,Byte(InChar),180);

  IF Error = SER_ERRTIMEOUT THEN
   BEGIN
    SendToUBIPrinter := UBI_PRINTER_TIMEOUT;
   END
  ELSE IF Error <> 0 THEN
   BEGIN
    SendToUBIPrinter := Error;
   END
  ELSE
   BEGIN
    IF NOT (InChar IN ['#','>','*']) THEN SendToUBIPrinter := UBI_COMMS_ERROR
    ELSE SendToUBIPrinter := 0;
   END
END;




FUNCTION GetE4PrinterResponse(VAR Response : STRING;PortAddr : WORD) : INTEGER;
VAR Error    : INTEGER;
    InChar   : CHAR;
BEGIN
  Response := '';
  Error    := 0;
  REPEAT
   Error := ReadSerialByte(PortAddr,Byte(InChar),90);
   IF InChar = #10 THEN InChar := #13;
   IF Error = 0 THEN Response := Response + InChar;
  UNTIL (Error <> 0) OR (ORD(Response[0])=255) OR
        (COPY(Response,Length(Response)-2,3) = 'Ok'+#13);
  GetE4PrinterResponse := Error;
END;


FUNCTION SendToUBIE4Printer(Duplex : BOOLEAN; OutStr : STRING;PortAddr : WORD) : INTEGER;
VAR Offset,
    DummyCs,
    LPA      : BYTE;
    InChar   : CHAR;
    Error    : INTEGER;
    Response : STRING;


 PROCEDURE FlushRxBuffer;
 VAR Err : INTEGER;
 BEGIN
  REPEAT
   Err := ReadSerialByte(PortAddr,Byte(InChar),0)
  UNTIL (Err <> 0);

 END;

BEGIN
  IF Duplex THEN Duplex := (Length(OutStr) > 0);
  FlushRxBuffer;

  FOR LPA := 1 TO Length(OutStr) DO
   BEGIN
    { Play Out Character To Printer}
    WriteByteToPort(PortAddr,ORD(OutStr[LPA]),40000);
    IF Duplex THEN ReadSerialByte(PortAddr,Byte(InChar),0)
   END;

  FlushRxBuffer;
  WriteByteToPort(PortAddr,ORD(CR),40000); { Send Carriage Return             }

  { Wait For Printer Response        }
  IF Duplex THEN
   BEGIN
    Error := GetE4PrinterResponse(Response,PortAddr);
   END
  ELSE Error := 0;

  IF Error = SER_ERRTIMEOUT THEN
   BEGIN
    SendToUBIE4Printer := UBI_PRINTER_TIMEOUT;
   END
  ELSE IF Error <> 0 THEN
   BEGIN
    SendToUBIE4Printer := Error;
   END
  ELSE SendToUBIE4Printer := 0;
END;


FUNCTION XmitLabelFormats(FileName     : STRING;PortAddr     : WORD) : INTEGER;
VAR FormatFile : TEXT;
    FLine      : STRING;
    ErrorStat  : INTEGER;
BEGIN
  FLine :='';                                    { Clear Line Buffer        }
  ErrorStat := 0;                                { Clear Error Status       }

  Assign(FormatFile,FileName);
{$I-}
  Reset(FormatFile);                             { Open Label Format File   }
{$I+}
  IF IOResult <> 0 THEN ErrorStat := UBI_FILE_OPEN_ERROR;

  IF ErrorStat=0 THEN
   BEGIN
    ErrorStat := SendToUBIPrinter(' ',PortAddr);{ Check Printer Responds   }
    WHILE (ErrorStat = 0)                        { No Errors                }
	    AND (NOT EOF(FormatFile))            { Not At End of File &     }
	    AND (COPY(FLine,1,4) <> '$XX$') DO   { Not At End File Marker & }
     BEGIN
      FLine :='';                                { Clear Line Buffer        }
{$I-}
      ReadLn(FormatFile,FLine);                  { Attempt To Read Line     }
{$I+}
      IF IOResult <> 0 THEN
       ErrorStat := UBI_FILE_READ_ERROR;         { Read Operation Failed    }
      IF (ErrorStat=0) AND (COPY(FLine,1,3) = '$LF') THEN
       BEGIN                                     { Start of Format Found    }
        WHILE (NOT EOF(FormatFile))              { Not At End of File       }
          AND (COPY(FLine,1,4) <> '$EFM')        { AND Not At End of Format }
          AND (ErrorStat = 0) DO                 { AND No Errors            }
         BEGIN
          ErrorStat := SendToUBIPrinter(FLine,PortAddr); { Send To Printer  }

          IF (ErrorStat = 0) THEN
	         BEGIN                           { Line Sent OK             }
            {$I-}
	          ReadLn(FormatFile,Fline);      { Get Next Line            }
            {$I+}
	          IF IOResult <> 0 THEN ErrorStat := UBI_FILE_READ_ERROR;
	         END;
         END;

        IF  (ErrorStat = 0) AND (COPY(FLine,1,4) = '$EFM') THEN
	       BEGIN
	        ErrorStat := SendToUBIPrinter(FLine,PortAddr); {Send End of Format}
         END;
       END;
     END;
    Close(FormatFile);                           { Close Label Format File  }
    IF ErrorStat <> UBI_PRINTER_TIMEOUT THEN SendToUBIPrinter('$PF',PortAddr);
   END;
  XmitLabelFormats := ErrorStat;                 { Return Status            }
END;



FUNCTION E4PrinterStatus(PortAddr : WORD; VAR PStat : BYTE) : INTEGER;
VAR Response        : STRING;
    Error           : INTEGER;
    Dummy           : INTEGER;
    Thermal         : BYTE;

PROCEDURE ParseReply;
BEGIN
 Response := COPY(Response,POS(#13+#13+'Ok',Response)-2,2);
 Response := Stripped(Response,2,' ');
 Response := Stripped(Response,2,#13);
END;

BEGIN
 Thermal := 0;
 SendToUBIE4Printer(FALSE, 'SYSVAR(18)=10', PortAddr);
 { returns error description first then 'OK' }

 SendToUBIE4Printer(FALSE,'?SYSVAR(20)',PortAddr);
 Error := GetE4PrinterResponse(Response,PortAddr);
 IF Error = 0 THEN
  BEGIN
   ParseReply;
   VAL(Response,Thermal,Dummy)
  END;

 PStat := 0;
 SendToUBIE4Printer(FALSE,'?PRSTAT',PortAddr);
 Error := GetE4PrinterResponse(Response,PortAddr);
 IF Error = 0 THEN
  BEGIN
   ParseReply;
   VAL(Response,Pstat,Dummy);
   IF (Thermal = 0) AND ( (Pstat AND 8) = 8 ) THEN PStat := PStat-8;
  END;
 E4PrinterStatus := Error;
END;



FUNCTION XmitLabelFormatsE4(FileName     : STRING; Desc : STRING; PortAddr     : WORD) : INTEGER;
VAR FormatFile  : TEXT;
    FLine       : STRING;
    ErrorStat   : INTEGER;
    TempFile    : FILE OF BYTE;
    FileLen     : LONGINT;
    FilePos     : LONGINT;
    FilePercent : LONGINT;
    PStatus     : BYTE;
BEGIN
  FLine :='';                                    { Clear Line Buffer        }
  ErrorStat := 0;                                { Clear Error Status       }
  FilePos   := 0;

  Assign(TempFile,FileName);
{$I-}
  Reset(TempFile);
{$I+}
  IF IOResult <> 0 THEN ErrorStat := UBI_FILE_OPEN_ERROR;

  IF ErrorStat = 0 THEN
   BEGIN
    FileLen := FileSize(TempFile);
    IF FileLen = 0 THEN ErrorStat := UBI_FILE_OPEN_ERROR;
    Close(TempFile);
    Assign(FormatFile,FileName);
{$I-}
    Reset(FormatFile);                           { Open Label Format File   }
{$I+}
    IF IOResult <> 0 THEN ErrorStat := UBI_FILE_OPEN_ERROR;

   END;


  IF ErrorStat=0 THEN
   BEGIN

    ErrorStat := SendToUBIE4Printer(TRUE,'?',PortAddr);{ Check Printer Responds   }
    WHILE (ErrorStat = 0)                        { No Errors                }
	    AND (NOT EOF(FormatFile)) DO         { Not At End of File &     }
     BEGIN
      FLine :='';                                { Clear Line Buffer        }
{$I-}
      ReadLn(FormatFile,FLine);                  { Attempt To Read Line     }
{$I+}
      IF IOResult <> 0 THEN
       ErrorStat := UBI_FILE_READ_ERROR;         { Read Operation Failed    }

      FilePos := FilePos+ (ORD(FLine[0])+2);
      FilePercent := TRUNC((FilePos / FileLen) * 100);
      MessageWin.DisplayMsg('Sending '+Desc+' '+IntToStr(FilePercent,3)+'%',FALSE);

      ErrorStat := SendToUBIE4Printer(TRUE,FLine,PortAddr); { Send To Printer  }
     END;
    Close(FormatFile);                           { Close Label Format File  }
   END;
  XmitLabelFormatsE4 := ErrorStat;                 { Return Status            }
END;


FUNCTION GetName(S:String):String;
VAR Return:String[13];
    I,J:integer;
BEGIN
 Return:='';
 I:=Length(S);
 While (I>1) AND (S[i]<>'\') AND (S[i] <> ':') DO DEC(I);
 For j:=I TO Length(S) DO Return:=Return+S[j];
 Return :=Return+Space_String;
 GetName:=Return;
END;

PROCEDURE DownloadUBIPrinter;
VAR LabelFile : STRING[128];
    Status    : INTEGER;
    PrinterPort : WORD;

BEGIN
  LabelFile := GetExtVar(FXLabFile,all);
  IF NowtButSpace(LabelFile) THEN
   BEGIN
    Disp_Error_Msg('Label File not defined in Config File. Download Aborted.');
    EXIT;
   END;
  PrinterPort := GetTicketPrinterPortAddr;
  IF (PrinterPort > 0) THEN
   BEGIN
    CASE ScaleConfRec.PrinterType OF
      UBI_Printer : BEGIN
                     MessageWin.DisplayMsg('Sending Label Formats',FALSE);
                     Status := XmitLabelFormats(LabelFile,PrinterPort);
                    END;
      IPL_Printer : BEGIN
                     MessageWin.DisplayMsg('Waiting For Printer',FALSE);
{                     XmitLabelFormatsE4(GetIPLConfigFileName,'Printer Configuration',PrinterPort);}
                     Status := XmitLabelFormatsE4(LabelFile,'Label Formats',PrinterPort);
                    END;
    END;

    CASE Status OF
      UBI_DOWNLOAD_OK    : MessageWin.DisplayMsg('Download Completed ',TRUE);
      UBI_FILE_OPEN_ERROR: MessageWin.DisplayMsg('Unable To Open Label File',TRUE);
      UBI_FILE_READ_ERROR: MessageWin.DisplayMsg('Error Reading Label File',TRUE);
      UBI_PRINTER_TIMEOUT: MessageWin.DisplayMsg('Printer Not Responding',TRUE);
      UBI_COMMS_ERROR    : MessageWin.DisplayMsg('Wrong Printer Response',TRUE);
     ELSE MessageWin.DisplayMsg('Printer Not Responding',TRUE);
    END;
   END
  ELSE MessageWin.DisplayMsg('Printer Port Not Set',TRUE);
END;

{***************************************************************************}
{* PROCEDURE Get_Label_Items                                               *}
{* Reads Label Designer .LAB File and produces a linked list of text &     *}
{* barcode items that need data to be transmitted to the printer           *}
{***************************************************************************}

PROCEDURE Get_Label_Items(LabFormat : CHAR);
VAR LabelFile   : STRING;
    FormatFile  : FILE OF LabelItemRecord;
    OldFileMode : BYTE;
    LabelItem   : LabelItemRecord;
    ErrorStat   : INTEGER;
    I           : INTEGER;

  PROCEDURE AddToLabelItemList;
  VAR NewPTItem  : PLabelTicketItem;
      TempPTItem : PLabelTicketItem;
  BEGIN
   NEW(NewPTItem);                               { Allocate Item Record     }
   CASE LabelItem.LI_Desc OF                     { Set Item Type            }
    'T' : NewPtItem^.LTI_Type := TextItem;
    'B' : BEGIN
      IF LabelItem.LI_Human THEN NewPtItem^.LTI_Type := BarcodeWithReadable
      ELSE NewPtItem^.LTI_Type := BarcodeWithoutReadable;
    END;
   END; { CASE }
   NewPtItem^.LTI_Tag    := StrPas(StrUpper(LabelItem.LI_Data));{ Store Sample Info}
   NewPtItem^.LTI_OutStr := '';
   NewPtItem^.LTI_Next   := NIL;                   { Clear Next Item Ptr      }
   { Link New Label Item To End Of Linked List                            }
   TempPTItem := LabelItemHeader;
   IF TempPTItem = NIL THEN
    BEGIN
     LabelItemHeader := NewPtItem;                 { Start Linked List    }
    END
   ELSE
    BEGIN
     WHILE (TempPTItem^.LTI_Next <> NIL) DO TempPTItem := TempPTItem^.LTI_Next;
     TempPTItem^.LTI_Next := NewPTItem;          { Link To End Of List      }
    END;
  END;

BEGIN
  LabelItemHeader  := NIL;

  LabelFile := GetExtVar(FXLabFile,all);       { Find .LAB FileName       }
  IF LabelFile = '' THEN EXIT;
  OldFileMode := FileMode;                       { Set File Access Mode     }
  FileMode := READ_ONLY;
  FOR I:=Length(LabelFile) DOWNTO 1 DO
   BEGIN
    IF LabelFile[I]='.' THEN
     BEGIN
      LabelFile[I+1]:='L';
      LabelFile[I+2]:='A';
      LabelFile[I+3]:='B';
      BREAK;
     END
    ELSE IF ((LabelFile[I] = ':') OR (LabelFile[I] = '\')) THEN
     BEGIN
      LabelFile := LabelFile+'.LAB';
      BREAK;
     END;
   END;
  ErrorStat := 0;                                { Clear Error Status       }
  Assign(FormatFile,LabelFile);
{$I-}
  Reset(FormatFile);                             { Open Label Format File   }
{$I+}
  IF IOResult <> 0 THEN ErrorStat := LAB_FILE_OPEN_ERROR;
  IF ErrorStat=0 THEN
   BEGIN
    Read(FormatFile,LabelItem);                    { Read File Header         }
    IF COPY(LabelItem.LI_Data,1,21) <> 'HSL_Label_Design_File' THEN
     ErrorStat := LAB_FILE_INVALID_ERROR;
   END;

  {*************************************************************************}
  { Search For Label Format Within .LAB File and read items into linked list}
  {*************************************************************************}

  WHILE (ErrorStat = 0)                          { No Errors                }
	 AND (NOT EOF(FormatFile)) DO            { Not At End of File       }
   BEGIN
    Read(FormatFile,LabelItem);
    IF COPY(LabelItem.LI_Data,1,12) = 'HSL_Format '+LabFormat THEN
     BEGIN                                       { Found Label Format       }
      WHILE (ErrorStat = 0)
       AND (NOT EOF(FormatFile)) DO
       BEGIN
        Read(FormatFile,LabelItem);              { Get Each Label Item      }
        IF COPY(LabelItem.LI_Data,1,10) = 'HSL_Format' THEN Break;
        IF LabelItem.LI_Desc IN ['T','B'] THEN   { Only Use Texts/Barcodes  }
         AddToLabelItemList;                     { Tag To End Of List       }
       END
     END;
   END;
  IF (ErrorStat<>LAB_FILE_OPEN_ERROR) THEN Close(FormatFile);
  FileMode := OldFileMode;
END; { Get_LabelFormat}

PROCEDURE ClearItemList;
VAR TempPTItem : PLabelTicketItem;
BEGIN
  TempPTItem := LabelItemHeader;
  WHILE (TempPTItem <> NIL) DO
   BEGIN
    TempPTItem^.LTI_OutStr :='';
    TempPTItem := TempPTItem^.LTI_Next;
   END;
END;

PROCEDURE DisposeItemList;
VAR TempPTItem : PLabelTicketItem;
BEGIN
  WHILE (LabelItemHeader <> NIL) DO
   BEGIN
    TempPtItem := LabelItemHeader^.LTI_Next;
    DISPOSE(LabelItemHeader);
    LabelItemHeader := TempPtItem;
   END;
END;

PROCEDURE SetUpUBIPrinterOptions;
CONST TextCol1 = 30;
      TextCol2 = 70;
VAR
     Port     : INTEGER;
     ToPrint  : INTEGER;
     SelWin   : PEditScreen;
     UBIOn    : BOOLEAN;
     UBIMix   : INTEGER;
     CheckLTS : BOOLEAN;

 PROCEDURE WriteStaticText;
 VAR
     E : PEdit;
 BEGIN
  Port      := GetTicketPrinterPortAddr;
  ToPrint   := GetNumberOfTicketsToPrint;
  UBIOn     := PrintTicket;
  UBIMix    := GetNumberOfMixTickets;
  CheckLTS  := GetLTSCheckSetting;
  New(E,Init(1, 2,TextCol1-4,StdEdit,SelWin,'Printer Port :',et_hexstring,4,Port));
  New(E,Init(1, 7,TextCol1-1,StdEdit,SelWin,'Tickets To Print  :',et_integer,1,ToPrint));
  New(E,Init(1,12,TextCol1-1,StdEdit,SelWin,'Print Tran Ticket :',et_checkbox,1,UBIOn));
  New(E,Init(1,17,TextCol1-1,StdEdit,SelWin,'No. of Mix Tickets:',et_Integer,1,UBIMix));
  New(E,Init(1,22,TextCol1-1,StdEdit,SelWin,'Check Label Taken :',et_checkbox,1,CheckLTS));
 END;

 PROCEDURE SaveChanges;
 BEGIN
  IF (NOT IsPortInUseElsewhere(Port,'PRINTER')) THEN
   SetTicketPrinterPort(Port)
  ELSE
   Disp_Error_Msg('Port Selected Is Already In Use');
  SetNumberOfTicketsToPrint(ToPrint);
  SetPrintTicket(UBIOn);
  SetNumberofMixTickets(UBIMix);
  SetLTSCheck(CheckLTS);
  TicketPrinterPortInit;
 END;

BEGIN
 ClrGraphWin;
 New(SelWin,Init);
 WriteStaticText;
 SelWin^.MainLoop;
 IF SelWin^.OptionSelected = idSave THEN SaveChanges;
 Dispose(SelWin,Done);
 ClrGraphWin;
END;

{--------------------------------------------------------------------}

PROCEDURE EditPrinterConfiguration;
VAR
   SelWin   : PScreenWithKeyboard;
   SettingNo: INTEGER;
   SettingTitle : STRING;
   SettingData  : STRING;
   ChildEdit    : PEdit;
   ButtonX,
   ButtonY      : INTEGER;
   C            : PChoiceBtn;
   DummyOrdHRecord : TWOHeaderRecord;
   I : INTEGER;

BEGIN
 IF PrinterObj <> NIL THEN
  BEGIN
   WorkHeaderFile^.InitRecord(DummyOrdHRecord);

   MessageWin.DisplayMsg('Interrogating Printer',FALSE);
   PrinterObj^.ReadCurrentSetup;

   New(SelWin,Init);
   ButtonX := KbdXOffset;
   ButtonY := KbdYOffset-8-ChildHeight;
   New(C,Init(ButtonX,ButtonY,SelWin,1,'Download'+CR+LF+'Setting',FALSE));
   Inc(ButtonX, ChildWidth+8);
   New(C,Init(ButtonX,ButtonY,SelWin,2,'Print'+CRLF+'Test Label',FALSE));
   Inc(ButtonX, ChildWidth+8);
   New(C,Init(ButtonX,ButtonY,SelWin,3,'Previous'+CRLF+'Setting',FALSE));
   Inc(ButtonX, ChildWidth+8);
   New(C,Init(ButtonX,ButtonY,SelWin,4,'Next'+CRLF+'Setting',FALSE));

   New(C,Init(SubKbdMaxX-ChildWidth,ButtonY,SelWin,5,'Exit',FALSE));

   SettingNo := PrinterObj^.GetNextSetting(FALSE, SettingTitle, SettingData);
   WHILE SettingNo > 0 DO
    BEGIN
     {GetStr(10, 10, 20, SettingTitle, SettingData);}
     New(ChildEdit, Init(10,10,
                         12+Length(SettingTitle),
                         StdEdit,SelWin,SettingTitle,et_AnyCharStr,20,SettingData));
     Flush_Keyboard_Buffer;
     SelWin^.MainLoop;
     Flush_Keyboard_Buffer;
(*
     ReturnLastMousePress := FALSE; { stops main loop jumping through
                                      next setting if edit field has
                                      focus. }
*)
     CASE SelWin^.OptionSelected OF
       1 :BEGIN
           PrinterObj^.SaveSetting(SettingNo, SettingData);
           PrinterObj^.ReadCurrentSetup;
           PrinterObj^.PTR_SettingIndex := SettingNo -1;
           PrinterObj^.GetNextSetting(FALSE,SettingTitle, SettingData);;
          END;
       2 : Print_UBI_Mix_Total_Ticket(@DummyOrdHRecord,'',FALSE);
       3 : SettingNo := PrinterObj^.GetPrevSetting(FALSE, SettingTitle, SettingData);
       4 : SettingNo := PrinterObj^.GetNextSetting(FALSE, SettingTitle, SettingData);
       5 : SettingNo := 0;
      END;
     Dispose(ChildEdit, Done);
    END;
   Dispose(SelWin,Done);
  END;
END;

PROCEDURE DownloadIPLConfigFile;
VAR
  SelWin : PScreenWithKeyboard;
  EditTitle,
  FileName : STRING[30];
  PrinterPort : WORD;
  C           : PChoiceBtn;
  ChildEdit   : PEdit;
  ButtonX,
  ButtonY     : INTEGER;
  Status      : INTEGER;
  SaveMsgState: TMsgWinState;

BEGIN
 IF ScaleConfRec.PrinterType = IPL_Printer THEN
  BEGIN
   PrinterPort := GetTicketPrinterPortAddr;
   IF (PrinterPort > 0) THEN
    BEGIN
     FileName := GetIPLConfigFileName;
     MessageWin.EnableAtTopOfScreen(@SaveMsgState);
     New(SelWin,Init); { keyboard disables messagewin }
     MessageWin.EnableAtTopOfScreen(NIL);
     EditTitle := 'Printer Configuration File:';
     New(ChildEdit, Init(10,10,12+Length(EditTitle),
                         StdEdit,SelWin,EditTitle,et_AnyCharStr,
                         SizeOf(FileName)-1, FileName));
     ButtonX := KbdXOffset;
     ButtonY := KbdYOffset-8-ChildHeight;
     New(C,Init(ButtonX,ButtonY,SelWin,1,'Download'+CR+LF+'File',FALSE));
     New(C,Init(SubKbdMaxX-ChildWidth,ButtonY,SelWin,2,'Exit',FALSE));

     REPEAT
       Flush_Keyboard_Buffer;
       SelWin^.MainLoop;
       Flush_Keyboard_Buffer;
(*
       ReturnLastMousePress := FALSE; { stops main loop jumping through
                                        next setting if edit field has
                                        focus. }
*)
       CASE SelWin^.OptionSelected OF
         1 : BEGIN
              FileName := Clip(FileName);
              IF Copy(FileName,Length(FileName)-3,4) = '.FIL' THEN
                Disp_Error_Msg('Config file should not have .FIL name extension')
              ELSE IF YesNoWin(' Configure printer using'+CRLF+
                               ' file '+FileName +'? (Y/N)') THEN
               BEGIN
                MessageWin.DisplayMsg('Waiting For Printer',FALSE);
                Status := XmitLabelFormatsE4(FileName,
                                   'Configuration File: '+FileName,
                                   PrinterPort);
                CASE Status OF
      UBI_DOWNLOAD_OK    : MessageWin.DisplayMsg('Download Completed ',TRUE);
      UBI_FILE_OPEN_ERROR: MessageWin.DisplayMsg('Unable To Open File',TRUE);
      UBI_FILE_READ_ERROR: MessageWin.DisplayMsg('Error Reading File',TRUE);
      UBI_PRINTER_TIMEOUT: MessageWin.DisplayMsg('Printer Not Responding',TRUE);
      UBI_COMMS_ERROR    : MessageWin.DisplayMsg('Wrong Printer Response',TRUE);
                 END;
               END;
             END;
         2 : BREAK;
        END;
     UNTIL FALSE;
     Dispose(SelWin,Done);
     MessageWin.RestoreMsgState(@SaveMsgState);
    END;
  END;
END;

PROCEDURE TicketSetUp;
VAR ExitTicketSetUp : BOOLEAN;
BEGIN
 New(UbiWin,Init);
 ExitTicketSetUp := FALSE;
 REPEAT
  CASE UBIWin^.GetOptionSelected OF
   1 : ExitTicketSetUp := TRUE;
   2 : DownloadUBIPrinter;
   3 : SetUpUBIPrinterOptions;
   4 : EditPrinterConfiguration;
   5 : DownloadIPLConfigFile;
  END;
 UNTIL ExitTicketSetUp;
 Dispose(UbiWin,Done);
END;


FUNCTION TicketPrinterPortInit : BOOLEAN;
{PROMISES Returns TRUE if port initialised (printer not neccessarily there)
}
VAR
    PortSettings: TSerialPortSettings;
    PortErr    : INTEGER;
    Response   : STRING;


    FUNCTION StrPortSettings : STRING;
    VAR Parity : STRING[4];
    BEGIN
     WITH PortSettings DO
      BEGIN
       CASE SP_FrameFlags AND $18 OF
         SER_LCR_ODDPARITY : Parity := 'Odd';
         SER_LCR_EVENPARITY: Parity := 'Even';
         ELSE                Parity := 'None';
        END;

       StrPortSettings := IntToHexStr(PortSettings.SP_Addr,2)+ ' at '+
                          IntToStr(PortSettings.SP_Baud,1)+ 'baud   8 '+
                          Parity+ ' 1';
      END;
    END;

    PROCEDURE DispCommError;
    BEGIN
     WITH PortSettings DO
      BEGIN
       Disp_Error_Msg('Failed to communicate with printer on port '+
                      StrPortSettings);
      END;
    END;

BEGIN
 TicketPrinterPortInit := FALSE;
 GetTicketPtrPortSettings(PortSettings);
 IF PortSettings.SP_Addr <> 0 THEN
  BEGIN
   WriteStrAt(16,50,'Initialising Printer Comms on port '+StrPortSettings);
   IF ScaleConfRec.PrinterType = IPL_Printer THEN
    BEGIN
     IF PrinterObj <> NIL THEN
      BEGIN
       Dispose(PrinterObj, Done);
       PrinterObj := NIL;
      END;
     Response := '';
     PrinterObj := New(PIPLPrinter, Init(PortSettings.SP_Addr));
     WITH PrinterObj^ DO
      BEGIN
       WITH PortSettings DO
         PortErr := InitiatePort(SP_Addr, SP_Baud, SP_FrameFlags,
                                 FALSE, 'PRINTER');
       IF PortErr = SER_OK THEN
        BEGIN
         TicketPrinterPortInit := TRUE;
         IF (GetNumberOfMixTickets <> 0)
         OR (GetNumberOfTicketsToPrint <> 0) THEN { try talking to printer }
          BEGIN
           InitComms(TRUE); { make it return error msgs }
           GetResponse(Response);
           InitComms(TRUE); { make it return error msgs }
           IF NOT GetResponse(Response) THEN
            BEGIN
             DispCommError;
             { see if its set to other preferred setting }
             WITH PortSettings DO
              BEGIN
               IF SP_Baud = 9600 THEN
                BEGIN
                 SP_Baud := 38400;
                 SP_FrameFlags := SER_LCR_8BITS or SER_LCR_1STOPBIT or
                                   SER_LCR_EVENPARITY;
                END
               ELSE
                BEGIN
                 SP_Baud := 9600;
                 SP_FrameFlags := SER_LCR_8BITS or SER_LCR_1STOPBIT or
                                   SER_LCR_NOPARITY;
                END;
              END;
             WriteStrAt(16,50,'Initialising Printer Comms  on port '+StrPortSettings);

             WITH PortSettings DO
               PortErr := InitiatePort(SP_Addr, SP_Baud, SP_FrameFlags,
                                       FALSE, 'PRINTER');
             IF PortErr = SER_OK THEN
              BEGIN
               InitComms(TRUE); { make it return error msgs }
               GetResponse(Response);
               InitComms(TRUE); { make it return error msgs }
               IF GetResponse(Response) THEN { save comm settings }
                 SetTicketPtrPortSettings(PortSettings)
               ELSE
                 DispCommError;
              END
             ELSE
               TicketPrinterPortInit := FALSE;
            END;
          END;
        END;
      END;
    END
   ELSE { NOT IPL type printer }
    BEGIN
     WITH PortSettings DO
      BEGIN
       IF InitiatePort(SP_Addr, SP_Baud, SP_FrameFlags,FALSE,'PRINTER') = SER_OK THEN
         TicketPrinterPortInit := TRUE;
      END;
    END;
  END;
END;

{----------------------------- E4 Setup ---------------------------------}

CONSTRUCTOR TIPLPrinter.Init(PortAddr : WORD);
BEGIN
 PTR_PortAddr := PortAddr;
 FillChar(PTR_SetupList, SizeOf(PTR_SetupList), 0);
 PTR_SettingIndex := 0;
 PTR_ErrorOutputEnabled := TRUE;
END;

DESTRUCTOR TIPLPrinter.Done;
BEGIN
END;

PROCEDURE TIPLPrinter.InitComms(ErrorsDescsToBeReturned : BOOLEAN);
BEGIN
 IF ErrorsDescsToBeReturned THEN
   SendToUBIE4Printer(FALSE, 'SYSVAR(18)=10', PTR_PortAddr)
   { returns error description first then 'OK' }
 ELSE
   SendToUBIE4Printer(FALSE, 'SYSVAR(18)=2', PTR_PortAddr);
   { returns 'OK' if it received the command }

 PTR_ErrorOutputEnabled := ErrorsDescsToBeReturned;
END;

PROCEDURE TIPLPrinter.SendCommand(CommandStr : STRING);
BEGIN
 SendToUBIE4Printer(FALSE, CommandStr, PTR_PortAddr);
END;

FUNCTION  TIPLPrinter.GetResponse(VAR Data : STRING) : BOOLEAN;
{REQUIRES: 1) InitComms() to have been called (so 'Ok' is returned from ptr).
           2) SendCommand() to have been used just prior.
 PROMISES: 1) Returns TRUE if 'Ok' read from serial port.
           2) If PTR_ErrorOutputEnabled then
                'Data' will be set first line read from printer port
                (contains ok or error msg or data).
              else
                'Data' will contain 'Ok' if no comms error.
           3) If fails to read port then set object member 'PTR_LastSerialInputErr'.
}
VAR
  InChar     : CHAR;
  AtEndOfLine: BOOLEAN;
  LineCount  : INTEGER;
  LastLine   : STRING;
BEGIN
 Data         := '';
 LastLine     := '';
 PTR_LastSerialInputErr   := 0;
 InChar       := #0;
 AtEndOfLine  := FALSE;
 LineCount := 0;
 REPEAT
   PTR_LastSerialInputErr := ReadSerialByte(PTR_PortAddr,Byte(InChar),90);
   IF (PTR_LastSerialInputErr = 0) THEN
    BEGIN
     IF InChar = #13 THEN
      BEGIN
       AtEndOfLine := TRUE;
       Inc(LineCount);
      END;

     IF NOT (InChar IN [#10,#13]) THEN
      BEGIN
       IF AtEndOfLine THEN { another line started }
        BEGIN
         LastLine := '';
         AtEndOfLine := FALSE;
        END;

       IF LineCount = 0 THEN
         Data := Data + InChar;
       LastLine := LastLine + InChar;
      END;
    END;
 UNTIL (PTR_LastSerialInputErr <> 0)
    OR (AtEndOfLine AND (LastLine = 'Ok'));

 GetResponse := LastLine = 'Ok';
END;


PROCEDURE TIPLPrinter.ReadCurrentSetup;
VAR Error    : INTEGER;
    InChar   : CHAR;
    LineNo   : INTEGER;
    CharNo   : BYTE;
    Response : STRING;
    NewSuppliesLines : INTEGER;
BEGIN
 FillChar(PTR_SetupList, SizeOf(PTR_SetupList), 0);
 PTR_SettingIndex := 0;
 LineNo   := 1;
 CharNo   := 0;
 Error    := 0;
 InitComms(TRUE); { make sure printer is initialised - may have been off }
 IF GetResponse(Response) THEN
  BEGIN
   SendCommand('SETUP WRITE "uart1:"');
   WHILE Error = 0 DO
    BEGIN
     Error := ReadSerialByte(PTR_PortAddr,Byte(InChar),90);
     IF  (Error = 0)
     AND (LineNo <= MAX_SETUP_LINES) THEN
      BEGIN
       IF InChar = #13 THEN { index to next line in SetupList }
        BEGIN
         IF (LineNo > 1) AND (PTR_SetupList[LineNo] = 'Ok') THEN
           BREAK;
          {*****}
         Inc(LineNo);
         CharNo := 0;
        END
       ELSE IF InChar < ' ' THEN
        BEGIN
        END
       ELSE
        BEGIN
         IF CharNo < 255 THEN { add char to end of line }
          BEGIN
           Inc(CharNo);
           PTR_SetupList[LineNo][CharNo] := InChar;
           PTR_SetupList[LineNo][0] := CHR(CharNo);
          END;
        END;
      END;
    END;
   { default printer setup doesnt include paper type }
   { if no 'new supplies' statements received whack a couple of empty
     statements into list. }
   NewSuppliesLines := 0;
   FOR LineNo := 1 TO MAX_SETUP_LINES DO
    BEGIN
     IF POS('NEW SUPPLIES', PTR_SetupList[LineNo]) > 0 THEN
       Inc(NewSuppliesLines);
    END;
   FOR LineNo := 1 TO MAX_SETUP_LINES DO
    BEGIN
     IF  (NewSuppliesLines < 2)
     AND NowtButSpace(PTR_SetupList[LineNo]) THEN
      BEGIN
       PTR_SetupList[LineNo] := 'SERVICE,PRINT DEFS,NEW SUPPLIES,';
       Inc(NewSuppliesLines);
      END;
    END;
  END;
END;


FUNCTION TIPLPrinter.DataDelimiterPosn(SetupListNo : INTEGER) : INTEGER;
VAR
  Posn : INTEGER;
BEGIN
 DataDelimiterPosn := 0;
 FOR Posn := Length(PTR_SetupList[SetupListNo]) DOWNTO 1 DO
  BEGIN
   IF PTR_SetupList[SetupListNo][Posn] = ',' THEN
    BEGIN
     DataDelimiterPosn := Posn;
     BREAK; { last comma in line found }
    END;
  END;
END;


FUNCTION TIPLPrinter.GetAnotherSetting(CommsSetting : BOOLEAN;
                                       VAR Title : STRING;
                                       VAR Data  : STRING;
                                       Forwards  : BOOLEAN) : INTEGER;
VAR
   VarDelimiter : BYTE;
   Adj : INTEGER;
BEGIN
 IF Forwards THEN Adj := 1
 ELSE             Adj := -1;
 GetAnotherSetting := 0;
 WHILE (PTR_SettingIndex+Adj) IN [1..MAX_SETUP_LINES] DO
  BEGIN
   PTR_SettingIndex := PTR_SettingIndex + Adj;
   IF CommsSetting = (Str_Equal('SER-COM', PTR_SetupList[PTR_SettingIndex], 7)) THEN
    BEGIN
     VarDelimiter := DataDelimiterPosn(PTR_SettingIndex);
     IF VarDelimiter > 1 THEN { valid setup line }
      BEGIN
       Title:= Copy(PTR_SetupList[PTR_SettingIndex], 1, VarDelimiter-1);
       Data := Copy(PTR_SetupList[PTR_SettingIndex], VarDelimiter+1, 20);
       GetAnotherSetting := PTR_SettingIndex;
       BREAK;
      END;
    END;
  END;
END;

FUNCTION TIPLPrinter.GetNextSetting(CommsSetting : BOOLEAN;
                                    VAR Title : STRING;
                                    VAR Data  : STRING) : INTEGER;
BEGIN
 GetNextSetting := GetAnotherSetting(CommsSetting, Title, Data, TRUE);
END;

FUNCTION TIPLPrinter.GetPrevSetting(CommsSetting : BOOLEAN;
                                    VAR Title : STRING;
                                    VAR Data  : STRING) : INTEGER;
BEGIN
 GetPrevSetting := GetAnotherSetting(CommsSetting, Title, Data, FALSE);
END;


FUNCTION TIPLPrinter.SaveSetting(SettingNo : INTEGER; SettingData : STRING) : BOOLEAN;
VAR
  Error   : INTEGER;
  TempStr : STRING;
  Response: STRING;
BEGIN
 SaveSetting := FALSE;
 TempStr := Copy(PTR_SetupList[SettingNo],1,DataDelimiterPosn(SettingNo))+
            Clip(SettingData);

 SendCommand('SETUP "'+TempStr+'"'+#13);
 IF GetResponse(Response) THEN
  BEGIN
   SaveSetting := TRUE;
   PTR_SetupList[SettingNo] := TempStr;
  END
 ELSE
   Disp_Error_Msg(Response);
END;


END.

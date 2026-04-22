unit uCSWScale;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, CPort, ScktComp, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdFTP;

type
  TWeightCallbackProcedure = procedure(weight:string) of object;
  TIPErrorCallbackProcedure = procedure(Sender: TObject) of object;
  TCSWScale = class(TForm)
    ipScale: TClientSocket;
    cpScale: TComPort;
    procedure ipScaleRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure SerialRxData(Sender: TObject; Count: Integer);
    procedure ipScaleError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
  private
    { Private declarations }
    fModel: Integer;
    fIsSerial: Boolean;
    fScaleBuffer: String;
    fScaleDP: Integer;
    fWeightCallback: TWeightCallbackProcedure;
    fIPerrorCallback: TIPErrorCallbackProcedure;
    fConnectError: String;

    fOverRange: Boolean;
    fUnderRange: Boolean;
    fMotion: Boolean;
    procedure OnRxData(rxStr: String);
    procedure OnRinstrunRxData(rxStr: String);
    procedure OnCSWRxData(rxStr: String);
    procedure OnMettlerRxData(rxStr: String);


  public
    { Public declarations }
    procedure Initialise(Model: Integer;Serial: Boolean; ConfigString: String; DP: Integer; WeightCallback: TWeightCallbackProcedure; IPErrorCallBack : TIPErrorCallbackProcedure);
    function  Connect : Boolean;
    procedure Disconnect;
    property  OnWeightCallBack : TWeightCallbackProcedure read fWeightCallback write fWeightCallback;
    property  OnIPErrorCallBack: TIPErrorCallbackProcedure read fIPerrorCallback write fIPerrorCallback;
    property  ConnectError: String read fConnectError;
    property  OverRange: Boolean read fOverRange;
    property  UnderRange: Boolean read fUnderRange;
    property  Motion: Boolean read fMotion;
  end;

implementation

{$R *.dfm}

uses math,uComUtils, StrUtils;

procedure TCSWScale.Initialise(Model: Integer;Serial: Boolean; ConfigString : String; DP: Integer; Weightcallback: TWeightCallbackProcedure; IPErrorCallBack : TIPErrorCallbackProcedure);
var SeperatorPos: Integer;
    iPPort: Integer;
begin
  fModel := Model;
  if not (fModel in [0,1,2]) then Model := 0;
  if ConfigString <> '' then
  begin
    fIsSerial := Serial;
    fScaleDP  := DP;
    if fIsSerial then
    begin
      cpScale.Port        := GetComPortFromString(ConfigString);
      cpScale.BaudRate    := GetBaudRate(GetBaudRateFromString(ConfigString));
      cpScale.DataBits    := GetDataBits(GetDataBitsFromString(ConfigString));
      cpScale.Parity.Bits := GetParity(GetParityFromString(ConfigString));
      cpScale.StopBits    := GetStopBits(GetStopBitsFromString(ConfigString));
      cpScale.FlowControl.FlowControl := GetFlowControl(GetFlowControlFromString(ConfigString));
    end
    else
    begin
      SeperatorPos := POS(':',ConfigString);
      if SeperatorPos = 0 then
      begin
        ConfigString := ConfigString+':1001';
        SeperatorPos := POS(':',ConfigString);
      end;

      ipScale.Address     := COPY(ConfigString,1,SeperatorPos-1);
      ipScale.Port        := IfThen(TryStrToInt(COPY(ConfigString,SeperatorPos+1,Length(ConfigString)-SeperatorPos),IpPort),IpPort,1001);
    end;
     OnWeightCallback    := Weightcallback;
     OnIPErrorCallBack   := IPErrorCallBack;
  end;
end;

function TCSWScale.Connect : Boolean;
var i: Integer;
begin
  Result := False;
  if fIsSerial then
  begin
    try
      i := 0;
      while (not cpScale.Connected) and (i < 5) do
      begin
        cpScale.Open;
        Inc(i);
        Sleep(250);
      end;
      Result := cpScale.Connected;
    except
      on E:Exception do
      begin
        fConnectError := E.Message;
      end;
    end;
  end
  else
  begin
    try
      ipScale.Open;
      Result := true;
    except
      on E:Exception do
      begin
        fConnectError := E.Message;
      end;
    end;
  end;
end;

procedure TCSWScale.ipScaleError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  fConnectError := SysUtils.SysErrorMessage(ErrorCode);
  if Assigned(OnIPErrorCallback) then
  begin
   ErrorCode := 0;
   OnIPErrorCallBack(self);
  end;
end;

procedure TCSWScale.Disconnect;
begin
  if fIsSerial then cpScale.Close
  else ipScale.Close;
end;


procedure TCSWScale.OnRxData(rxStr: String);
begin
  case fModel of
    0: OnCSWRxData(rxStr);
    1: OnRinstrunRxData(rxStr);
    2: OnMettlerRxData(rxStr);
  end;
end;


//Mettler packet examples Lifted from OCM code.
//000031 13:33:09.609  56 20 53 20 4E 20 20 20 20 20 36 31 2E 32 20 6B V S N     61.2 k
//000032 13:33:09.625  67 20 54 20 20 20 20 20 20 30 2E 30 20 6B 67 0D g T      0.0 kg.
//000033 13:33:09.640  0A

//000001 12:56:53.718  56 20 53 20 4E 20 20 20 20 32 39 38 2E 30 20 6B V S N    298.0 k
//000002 12:56:53.734  67 20 54 20 20 20 20 20 20 30 2E 30 20 6B 67 0D g T      0.0 kg.
//000003 12:56:53.750  0A                                              .

//000040 16:27:20.078  56 20 44 20 4E 20 20 20 20 20 2D 31 2E 30 20 6B V D N     -1.0 k
//000041 16:27:20.109  67 20 54 20 20 20 20 20 20 30 2E 30 20 6B 67 0D g T      0.0 kg.
//000042 16:27:20.109  0A


procedure TCSWScale.OnMettlerRxData(rxStr: String);
var TempStr : String;
    i: Integer;
    l: Integer;
begin
  l := Length(rxStr);
  for i := 1 to l do
  begin
    if (rxStr[i] = Chr($0A)) then fScaleBuffer := ''  // LF is end of Packet
    else if rxStr[i]=#13 then break
    else
    begin
      if rxStr[i]='V' then fScaleBuffer :='';
      fScaleBuffer := fScaleBuffer + rxStr[i];
    end;
  end;
  if (i<=l) then
  begin
    if (rxStr[i]=CHR(13)) AND (Length(fScaleBuffer)=31) then
    begin
      fOverRange := (fScaleBuffer[3]='+');
      fUnderRange := (fScaleBuffer[3]='-');
      fMotion := (fScaleBuffer[3]='D');
      TempStr := AnsiReplaceStr(COPY(fScaleBuffer,6,10),' ','');
      //TareStr := AnsiReplaceStr(COPY(fScaleBuffer,20,10),' ','');  //tare not used by formix

      if Assigned(OnWeightCallback) then OnWeightCallback(TempStr);
    end;
  end;
end;


procedure TCSWScale.OnRinstrunRxData(rxStr: String);
var TempStr : String;
    i: Integer;

begin
//<STX> <SIGN> <WEIGHT(7)> <S1> <S2> <S3> <S4> <UNITS(3)> <ETX>
//STX: Start of transmission character (ASCII 02).
//SIGN: The sign of the weight reading (space for positive, dash (-) for negative).
//WEIGHT(7): A seven character string containing the current weight including
//S1: Displays G/N/U/O/E representing Gross / Net / Underload / Overload /
//S2: Displays M/^ representing Motion / Stable, respectively.
//S3: Displays Z/^ representing centre of Zero / Non-Zero, respectively.
//S4: Displays - representing single range.
//UNITS(3): A three character string, the first character being a space, followed
//by the actual units (eg. ^kg or ^^t). If the weight reading is not stable, the unit
//string is sent as ^^^.
//ETX: End of transmission character (ASCII 03).
{-9999.99GMZ-^kg}

  for i := 1 to Length(rxStr) do
  begin
    if (rxStr[i] = Chr($02)) then fScaleBuffer := ''  // STX is Start of Packet
    else
    begin
      if not (rxStr[i] = Chr($03)) then
        fScaleBuffer := fScaleBuffer + rxStr[i]
      else
        Break;
    end;
  end;

  if (Length(fScaleBuffer) = 15) then
  begin
    fUnderRange := (fScaleBuffer[9] = 'U') OR (fScaleBuffer[1] = '-');
    fOverRange  := (fScaleBuffer[9] = 'O');
    fMotion     := (fScaleBuffer[10] = 'M');
    TempStr := AnsiReplaceStr(Copy(fScaleBuffer,2,7),' ','');

    if Assigned(OnWeightCallback) then OnWeightCallback(TempStr);
  end;

end;

Procedure TCSWScale.OnCSWRxData(rxStr: String);
var TempStr : String;
    i: Integer;
begin
{SG?B    030 kg2}
{123456789012345}
  for i := 1 to Length(rxStr) do
  begin
    if (rxStr[i] = Chr($02)) then fScaleBuffer := ''  // STX is Start of Packet
    else
    begin
      if not (rxStr[i] in [#10,#13]) then
        fScaleBuffer := fScaleBuffer + rxStr[i]
      else
        Break;
    end;
  end;

  // Check Frame
  if (Length(fScaleBuffer) = 15) then
  begin
    //if (fScaleBuffer[4] in ['B','M','R','Z']) or (fScaleBuffer[5] = '-') then
    fUnderRange := (fScaleBuffer[5] = 'U') OR (fScaleBuffer[5] = '-');
    if (fScaleBuffer[4] in ['B','M','R','Z','H','G']) or (fUnderRange) then
    begin
      fMotion     := (fScaleBuffer[4] = 'M');
      fOverRange := (fScaleBuffer[5] = 'O');
      TempStr := Copy(fScaleBuffer,5,7);
      // Insert DP
      if ((Length(fScaleBuffer) < 15) or (not (fScaleBuffer[15] in ['0'..'9']))) then
        Insert('.',TempStr,Length(TempStr)-fScaleDP+1)
      else
        Insert('.',TempStr,Length(TempStr)-StrToInt(fScaleBuffer[15])+1);
      TempStr := AnsiReplaceStr(TempStr,' ','');
      fScaleBuffer:= '';
      //Callback
      if Assigned(OnWeightCallback) then OnWeightCallback(TempStr);
    end
    else if Assigned(OnWeightCallback) then OnWeightCallback('');
  end;
end;

Procedure TCSWScale.SerialRxData(Sender: TObject; Count: Integer);
var RxData: String;
begin
  cpScale.ReadStr(RxData,Count);
  cpScale.ClearBuffer(TRUE,FALSE);
  OnRxData(RxData);
end;

procedure TCSWScale.ipScaleRead(Sender: TObject; Socket: TCustomWinSocket);
var Buff: ARRAY[1..1024] OF BYTE;
    BytesRead,i: Integer;
    RxData: String;
begin
   BytesRead := Socket.ReceiveBuf(Buff,1024);
   for i := 1 to BytesRead do rxData := rxData+CHR(Buff[i]);
   OnRxData(RxData);
end;



end.

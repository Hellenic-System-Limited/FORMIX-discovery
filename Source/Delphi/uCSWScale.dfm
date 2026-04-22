object CSWScale: TCSWScale
  Left = 815
  Top = 322
  Width = 175
  Height = 97
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object ipScale: TClientSocket
    Active = False
    ClientType = ctNonBlocking
    Port = 0
    OnRead = ipScaleRead
    OnError = ipScaleError
    Left = 32
  end
  object cpScale: TComPort
    BaudRate = br9600
    Port = 'COM1'
    Parity.Bits = prNone
    StopBits = sbOneStopBit
    DataBits = dbEight
    Events = [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full]
    Buffer.InputSize = 32768
    FlowControl.OutCTSFlow = False
    FlowControl.OutDSRFlow = False
    FlowControl.ControlDTR = dtrDisable
    FlowControl.ControlRTS = rtsDisable
    FlowControl.XonXoffOut = False
    FlowControl.XonXoffIn = False
    SyncMethod = smWindowSync
    OnRxChar = SerialRxData
    Left = 6
  end
end

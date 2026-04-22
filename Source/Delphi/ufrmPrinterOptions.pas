unit ufrmPrinterOptions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RXCtrls, ExtCtrls, CPort, StdCtrls;

type
  TfrmPrinterOptions = class(TForm)
    Panel1: TPanel;
    OpenDialog1: TOpenDialog;
    rxsbExit: TButton;
    rxsbDownloadLabelFile: TButton;
    rxsbPrinterOptions: TButton;
    rxsbEditPrinterConfig: TButton;
    rxsbDownloadPrinterConfig: TButton;
    procedure rxsbPrinterOptionsClick(Sender: TObject);
    procedure rxsbDownloadLabelFileClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPrinterOptions: TfrmPrinterOptions;

implementation
uses ufrmPrinterSetup, udmFormixBase,udmFormix, ufrmFormixMain, uComUtils, uTermDialogs,
     ufrmPrinterUtils;
{$R *.dfm}

procedure TfrmPrinterOptions.rxsbPrinterOptionsClick(Sender: TObject);
var WrkString: String;
begin
 {Show printer option screen}
 frmPrinterSetup := TfrmPrinterSetup.Create(Self);
 with frmPrinterSetup do
  begin
   WrkString := dmFormix.GetTermRegString(r_PrinterSetup);
   cbComPorts.Text    := GetComPortFromString(WrkString);
   cbBaudRate.Text    := GetBaudRateFromString(WrkString);
   cbDataBits.Text    := GetDataBitsFromString(WrkString);
   cbParity.Text      := GetParityFromString(WrkString);
   cbStopBits.Text    := GetStopBitsFromString(WrkString);
   cbFlowControl.Text := GetFlowControlFromString(WrkString);
   meTicketsToPrint.Text := dmFormix.GetTermRegString(r_NoOfTranTickets);
   meNoOfMixTickets.Text := dmFormix.GetTermRegString(r_NoOfMixTickets);
//   cbCheckLabelTaken.Checked := dmFormix.GetRegBooleanDef(REG_Scale+TerminalName,REG_CheckLabelTaken,FALSE);
   cbPrintTransactionTicket.Checked := dmFormix.GetTermRegBoolean(r_PrintTranTicket);
   edTranLabelFormat.Text := dmFormix.GetTermRegString(r_FXLabFormat);
   edMixLabelFormat.Text := dmFormix.GetTermRegString(r_FXMixLabFormat);
   ShowModal;
   if ModalResult = mrOk then
    begin
     WrkString := cbComPorts.Text+','+
                  cbBaudRate.Text+','+
                  cbDatabits.Text+','+
                  cbParity.Text+','+
                  cbStopBits.Text+','+
                  cbFlowControl.Text;
     dmFormix.SetTermRegString(r_PrinterSetup,WrkString);
     if WrkString <> '' then
      begin
       if PrinterCommPort = nil then PrinterCommPort := TComPort.Create(nil);
       if PrinterCommPort.Connected then PrinterCommPort.Close;
       try
        PrinterCommPort.Port        := GetComPortFromString(WrkString);
        PrinterCommPort.BaudRate    := GetBaudRate(GetBaudRateFromString(WrkString));
        PrinterCommPort.DataBits    := GetDataBits(GetDataBitsFromString(WrkString));
        PrinterCommPort.Parity.Bits := GetParity(GetParityFromString(WrkString));
        PrinterCommPort.StopBits    := GetStopBits(GetStopBitsFromString(WrkString));
        PrinterCommPort.FlowControl.FlowControl := GetFlowControl(GetFlowControlFromString(WrkString));
        PrinterCommPort.EventChar := #13;
        PrinterCommPort.Open;
       except
        on E:Exception do
         begin
          TermMessageDlg('Unable To Open Printer Port',mtError,[mbOk],0);
          PrinterCommPort.Free;
          PrinterCommPort := nil;
         end;
       end;
      end;
     dmFormix.SetTermRegString(r_NoOfTranTickets,meTicketsToPrint.Text);
     dmFormix.SetTermRegString(r_NoOfMixTickets,meNoOfMixTickets.Text);
//     dmFormix.SetRegBoolean(REG_Scale+TerminalName,REG_CheckLabelTaken,cbCheckLabelTaken.Checked);
     dmFormix.SetTermRegBoolean(r_PrintTranTicket,cbPrintTransactionTicket.Checked);
     dmFormix.SetTermRegString(r_FXLabFormat,edTranLabelFormat.Text);
     dmFormix.SetTermRegString(r_FXMixLabFormat,edMixLabelFormat.Text);

     TermMessageDlg('Printer Setup Changes Saved',mtInformation,[mbOk],0);
    end
   else TermMessageDlg('Printer Setup Changes Not Saved',mtInformation,[mbOk],0);
   Free;
  end;
end;

procedure TfrmPrinterOptions.rxsbDownloadLabelFileClick(Sender: TObject);
begin
 if dmFormix.GetTermRegString(r_FXLabFile) = '' then
  begin
   TermMessageDlg('No Label File Set',mtError,[mbOk],0);
   Exit;
  end;
 if PrinterCommPort <> nil then
   DownloadLabelsToPrinter(dmFormix.GetTermRegString(r_FXLabFile),PrinterCommPort);
end;

end.

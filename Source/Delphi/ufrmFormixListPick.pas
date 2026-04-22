unit ufrmFormixListPick;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, DB, RxMemDS, Grids, DBGrids;

type
  TfrmFormixListPick = class(TForm)
    Label1: TLabel;
    Button1: TButton;
    btCancel: TButton;
    Panel1: TPanel;
    DBGrid1: TDBGrid;
    rxmGridData: TRxMemoryData;
    dsGridData: TDataSource;
    rxmGridDataOptionStr: TStringField;
    rxmGridDataOptionColour: TIntegerField;
    rxmGridDataRed: TIntegerField;
    rxmGridDataGreen: TIntegerField;
    rxmGridDataBlue: TIntegerField;
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
  private
    { Private declarations }
  public
    { Public declarations }
    constructor CreateWithTexts(AOwner: TComponent;
                                const FormCaption : string;
                                const FormInstruction : string);
    procedure AddListOption(const OptionStr : string; OptionColour : TColor);
    procedure SetCurrentOptionStr(const ToString : string);
    function CurrentOptionStr : string;
  end;

implementation
uses uColourScheme;
{$R *.dfm}

constructor TfrmFormixListPick.CreateWithTexts(AOwner: TComponent;
                                               const FormCaption : string;
                                               const FormInstruction : string);
begin
  Create(AOwner);
  Caption := FormCaption;
  Label1.Caption := FormInstruction;
  rxmGridData.Open;
end;

procedure TfrmFormixListPick.AddListOption(const OptionStr : string; OptionColour : TColor);
var
  RGBValue : longint;
begin
  rxmGridData.Append;
  rxmGridDataOptionStr.AsString := OptionStr;
  rxmGridDataOptionColour.AsInteger := OptionColour;
  RGBValue := ColorToRGB(OptionColour);
  rxmGridDataRed.AsInteger   := GetRValue(RGBValue);
  rxmGridDataGreen.AsInteger := GetGValue(RGBValue);
  rxmGridDataBlue.AsInteger  := GetBValue(RGBValue);
end;

procedure TfrmFormixListPick.SetCurrentOptionStr(const ToString : string);
begin
  rxmGridData.Locate(rxmGridDataOptionStr.FieldName, ToString, []);
end;

function TfrmFormixListPick.CurrentOptionStr : string;
begin
  Result := '';
  if not rxmGridData.IsEmpty then
    Result := rxmGridDataOptionStr.AsString;
end;

procedure TfrmFormixListPick.DBGrid1DrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
var
  TextColour : TColor;
  Grid: TDBGrid;
begin
  Grid := TDBGrid(Sender);
  SetCanvasForStandardGridCell(Grid, State, clBlack);
  TextColour := Grid.Canvas.Font.Color; //start with default colour
{
  if Grid.Canvas.Font.Color <> clHighlightText then
  begin
    if (Column.FieldName = rxmGridDataOptionStr.FieldName) then
    begin
      if  (Grid.DataSource.DataSet.FieldByName(rxmGridDataRed.FieldName).AsInteger > 150)
      and (Grid.DataSource.DataSet.FieldByName(rxmGridDataGreen.FieldName).AsInteger > 150) then //yellow to white
        Grid.Canvas.Brush.Color := rxmGridDataOptionColour.AsInteger
      else
        TextColour := rxmGridDataOptionColour.AsInteger;
    end;
  end;
}
  {Maintain text and background colour of OptionStr, even when row is selected.
   First dummy column in grid will show highlight bar.}
  if (Column.FieldName = rxmGridDataOptionStr.FieldName) then
  begin
    Grid.Canvas.Brush.Color := rxmGridDataOptionColour.AsInteger;
    if  (Grid.DataSource.DataSet.FieldByName(rxmGridDataRed.FieldName).AsInteger > 150)
    and (Grid.DataSource.DataSet.FieldByName(rxmGridDataGreen.FieldName).AsInteger > 150) then //yellow to white
      TextColour := clBlack
    else
      TextColour := clWhite;
  end;
  Grid.Canvas.Font.Color := TextColour;
  Grid.Canvas.Pen.Color := Grid.Canvas.Brush.Color;
  Grid.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

end.

unit uCapture;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Clipbrd, Vcl.StdCtrls, jpeg, System.UITypes;

type
  TWindowCaptureFunction = function(const aAchseX, aAchseY, aBreite, aHohe: Integer): TBitmap;

  TfrmCapture = class(TForm)
    lbX: TLabel;
    lbY: TLabel;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    FCaptureArea: TPanel;
    FX: Integer;
    FY: Integer;
    FCapturing: Boolean;

    function WindowCapture(const aLeft, aTop, aRight, aBottom: Integer): TBitmap;
  public
    { Public declarations }
    FPrint: TBitmap;
  end;

var
  frmCapture: TfrmCapture;

implementation

{$R *.dfm}

procedure TfrmCapture.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

procedure TfrmCapture.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  oMouse: TPoint;
begin
  FCapturing := True;

  GetCursorPos(oMouse);
  FX := oMouse.X;
  FY := oMouse.Y;

  FCaptureArea := TPanel.Create(Self);
  FCaptureArea.Font.Size := 14;
  FCaptureArea.Font.Style := [fsBold];
  FCaptureArea.OnMouseMove := FormMouseMove;
  FCaptureArea.BorderWidth := 0;
  FCaptureArea.BorderStyle := bsNone;
  FCaptureArea.Anchors := [akLeft, akTop, akRight, akBottom];
  FCaptureArea.AutoSize := False;
  FCaptureArea.Align := TAlign.alNone;
  FCaptureArea.BevelInner := bvNone;
  FCaptureArea.BevelOuter := bvNone;
  FCaptureArea.BevelEdges := [];
  FCaptureArea.Margins.Left := 0;
  FCaptureArea.Margins.Top := 0;
  FCaptureArea.Margins.Right := 0;
  FCaptureArea.Margins.Bottom := 0;
  FCaptureArea.SetBounds(FX, FY, 0, 0);
  FCaptureArea.ParentBackground := False;
  FCaptureArea.ParentColor := False;
  FCaptureArea.ParentBiDiMode := False;
  FCaptureArea.Color := clRed;
  FCaptureArea.Brush.Style := TBrushStyle.bsClear;
  FCaptureArea.SetParentComponent(Self);
end;

procedure TfrmCapture.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FCaptureArea) then
  begin
    FCaptureArea.Width := X - FX;
    FCaptureArea.Repaint;

    FCaptureArea.Height := Y - FY;
    FCaptureArea.Repaint;

    FCaptureArea.Caption := IntToStr(FCaptureArea.Width) + ' X ' + IntToStr(FCaptureArea.Height);
    FCaptureArea.Repaint;
  end;

  lbX.Caption := IntToStr(X);
  lbX.Repaint;
  lbY.Caption := IntToStr(Y);
  lbY.Repaint;
end;

procedure TfrmCapture.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  try
    try
      Self.Visible := False;
      FPrint := WindowCapture(
      FX,
      FY,
      X,
      Y
      );
      Close;
    except
      on EOutOfResources do
        if MessageDlg('Invalid area.'#13#10'Try again.',
        mtError, mbOKCancel, 0) = mrOk then
        begin
          Exit;
        end;

      on EAccessViolation do
        if MessageDlg('Invalid area.'#13#10'Try again.',
        mtError, mbOKCancel, 0) = mrOk then
        begin
          Exit;
        end;
    end;
  finally
    Close;
    Self.Visible := True;
  end;
end;

procedure TfrmCapture.FormShow(Sender: TObject);
begin
  FCapturing := False;
  Self.Height := Screen.Height;
  Self.Width := Screen.Width;
  Self.ClientHeight := Screen.Height;
  Self.ClientWidth := Screen.Width;
  Self.Left := 0;
  Self.Top := 0;
end;

function TfrmCapture.WindowCapture(const aLeft, aTop, aRight, aBottom: Integer): TBitmap;
var
  DC: HDC;
  oCanvas: TCanvas;
begin
  oCanvas := TCanvas.Create;
  try
    DC := GetDC(0);
    try
      Result := TBitmap.Create;
      Result.PixelFormat := TPixelFormat.pfDevice;
      Result.Width := aRight - aLeft;
      Result.Height := aBottom - aTop;
      oCanvas.Handle := DC;

      Result.Canvas.CopyMode := cmSrcCopy;
      Result.Canvas.CopyRect(
        Rect(0, 0, Result.Width, Result.Height),
        oCanvas,
        Rect(aLeft, aTop, aRight, aBottom));

      Clipboard.Assign(Result);
    finally
      ReleaseDC(0, DC);
    end;
  finally
    oCanvas.Free;
  end;
end;


end.

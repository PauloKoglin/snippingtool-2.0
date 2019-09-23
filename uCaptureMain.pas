unit uCaptureMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons, uCapture,
  Vcl.ComCtrls, Vcl.ToolWin, Vcl.ImgList, uTextArea, System.ImageList, System.Generics.Collections; //, System.ImageList; //, System.ImageList;

type
  TEnumZeichnungType = (ztNone, ztKreis, ztPfeil, ztTextEingeben);

  {
    Class für Zeichnung eines Pfeiles
  }
  TPfeil = class(TShape)
  strict private
    FLeft: Integer;
    FTop: Integer;
  protected
    procedure Paint; override;
    procedure Draw(const pCanvas: TCanvas);
  public
    procedure DrawTo(const X, Y: Integer; const pCanvas: TCanvas);
  end;

  TfrmSnipping = class(TForm)
    scbCapture: TScrollBox;
    pnFooter: TPanel;
    ImageList1: TImageList;
    lbStartX: TLabel;
    lbStartY: TLabel;
    lbEndX: TLabel;
    lbEndY: TLabel;
    lbX: TLabel;
    lbY: TLabel;
    imgCapture: TImage;
    tbMenu: TToolBar;
    btnCopieren: TSpeedButton;
    btnCapture: TSpeedButton;
    btnSchreiben: TSpeedButton;
    btnPfeil: TSpeedButton;
    btnKreis: TSpeedButton;
    lbEditingMode: TLabel;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure imgCaptureMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure imgCaptureMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure imgCaptureMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnCapture1Click(Sender: TObject);
    procedure btnKreisClick(Sender: TObject);
    procedure btnPfeilClick(Sender: TObject);
    procedure btnCopierenClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnSchreiben1Click(Sender: TObject);
    procedure imgCaptureClick(Sender: TObject);
    procedure scbCaptureAlignPosition(Sender: TWinControl; Control: TControl;
      var NewLeft, NewTop, NewWidth, NewHeight: Integer; var AlignRect: TRect;
      AlignInfo: TAlignInfo);
  private
    { Private declarations }
    FShape: TShape;
    FPfeil: TPfeil;
    FTextArea: TTextArea;
    FDrawing: Boolean;
    FSchreiben: Boolean;
    FStartX, FStartY, FEndX, FEndY: Integer;
    FMaxRight, FMaxBottom: Integer;
    FZeichnungType: TEnumZeichnungType;
    FImageList : TImageList;
    FTextAreaList: TObjectList<TTextArea>;

    function BitmapCapture(const aLeft, aTop, aRight, aBottom: Integer): TBitmap;

    procedure ConfirmTextAreas;
    procedure FooterRefresh(const X, Y: Integer);
    procedure ButtonsZeigen;
    procedure ChangeButtonDown;
  public
    { Public declarations }
  end;

var
  frmSnipping: TfrmSnipping;

const
  cEnumZeichnungTypeStr: array [0..3] of string = ('', 'Kreis', 'Pfeil', 'Text Eingeben');

implementation

uses
  Clipbrd;

{$R *.dfm}

procedure TfrmSnipping.btnCapture1Click(Sender: TObject);
var
  frmCapture: TfrmCapture;
  oCapturedBitmap: TBitmap;
begin
  if Assigned(FImageList) then
    FImageList.Free;

  imgCapture.Picture.Assign(nil);
  Self.Visible := False;

  frmCapture := TfrmCapture.Create(nil);
  try
    frmCapture.ShowModal;

    if Assigned(frmCapture.FPrint) then
    begin
      FImageList := TImageList.Create(Self);
      oCapturedBitmap := frmCapture.FPrint;

      imgCapture.Picture.Bitmap := frmCapture.FPrint;
      imgCapture.Width := Screen.Width;
      imgCapture.Height := Screen.Height;
      imgCapture.Picture.Bitmap.Width := Screen.Width;
      imgCapture.Picture.Bitmap.Height := Screen.Height;
      FMaxRight := oCapturedBitmap.Width;
      FMaxBottom := oCapturedBitmap.Height;

      Self.Width := 650;

      if oCapturedBitmap.Width > Self.Width then
        Self.Width := Round(oCapturedBitmap.Width * 2);

      if oCapturedBitmap.Height > Self.Height - tbMenu.Height - 40 then
        Self.Height := Round((oCapturedBitmap.Height * 2) + Self.Height);

      if Self.Width > Screen.Width then
        Self.Width := Screen.Width;

      if Self.Height > Screen.Height then
        Self.Height := Screen.Height - 30;

      FImageList.Add(oCapturedBitmap, oCapturedBitmap);
      BringToFront;
    end;
  finally
    frmCapture.Free;
    Self.Visible := True;
  end;
  Self.ChangeButtonDown;
end;

procedure TfrmSnipping.btnCopierenClick(Sender: TObject);
var
  oBitmap: TBitmap;
  oRect: TRect;
begin
  oRect := imgCapture.BoundsRect;
  oBitmap := TBitmap.Create;
  try
    // Hier wird auch copiert wo gezeichnet wurde, deswegen werden die vars FMaxRight und FMaxBottom verwendet
    oBitmap.Assign(BitmapCapture(oRect.Left, oRect.Top, FMaxRight, FMaxBottom));
    Clipboard.Assign(oBitmap);
  finally
    oBitmap.Free;
  end;
end;

procedure TfrmSnipping.btnKreisClick(Sender: TObject);
begin
  FZeichnungType := ztKreis;
  Self.ChangeButtonDown;
end;

procedure TfrmSnipping.btnPfeilClick(Sender: TObject);
begin
  FZeichnungType := ztPfeil;
  Self.ChangeButtonDown;
end;

procedure TfrmSnipping.btnSchreiben1Click(Sender: TObject);
begin
  FZeichnungType := ztTextEingeben;
  Self.ChangeButtonDown;
end;

procedure TfrmSnipping.ButtonsZeigen;
var
  bEditing: Boolean;
begin
  bEditing := FImageList <> nil;
  // Es muss in diese Ordnung sein um die Komponenten in der richtige Ordnung zu zeigen
  btnKreis.Visible := bEditing;
  btnPfeil.Visible := bEditing;
  btnSchreiben.Visible := bEditing;
  btnCopieren.Visible := bEditing;

  scbCapture.Visible := bEditing;
  pnFooter.Visible := bEditing;
end;

procedure TfrmSnipping.ChangeButtonDown;
begin
  btnKreis.Transparent := FZeichnungType <> ztKreis;
  btnPfeil.Transparent := FZeichnungType <> ztPfeil;
  btnSchreiben.Transparent := FZeichnungType <> ztTextEingeben;
end;

procedure TfrmSnipping.ConfirmTextAreas;
var
  oTextArea: TTextArea;
begin
  for oTextArea in FTextAreaList do
  begin
    oTextArea.DrawTo(imgCapture.Canvas);
  end;

  FTextAreaList.Clear;
  FTextAreaList.Free;
  FTextAreaList := nil;
end;

procedure TfrmSnipping.imgCaptureClick(Sender: TObject);
begin
  if FZeichnungType = ztTextEingeben then
    FSchreiben := True;
end;

procedure TfrmSnipping.imgCaptureMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FZeichnungType <> ztNone then
  begin
    FDrawing := True;
    FStartX := X;
    FStartY := Y;
    FEndX := X;
    FEndY := Y;

    Self.FooterRefresh(0, 0);

    case FZeichnungType of
      ztPfeil:
      begin
        with imgCapture.Canvas do
        begin
          FPfeil := TPfeil.Create(scbCapture);
          FPfeil.Left := FStartX;
          FPfeil.Top := FStartY;
          FPfeil.Width := 0;
          FPfeil.Height := 0;
          FPfeil.SetParentComponent(scbCapture);
        end;
      end;

      ztKreis:
      begin
        FShape := TShape.Create(scbCapture);
        FShape.Shape := TShapeType.stEllipse;
        FShape.Align := TAlign.alNone;
        FShape.Width := 0;
        FShape.Height := 0;
        FShape.Left := FStartX;
        FShape.Top := FStartY;
        FShape.Brush.Style := TBrushStyle.bsClear;
        FShape.Pen.Style := TPenStyle.psSolid;
        FShape.Pen.Color := clRed;
        FShape.Pen.Width := 2;
        FShape.Margins.SetBounds(0, 0, 0, 0);
        FShape.SetParentComponent(scbCapture);
      end;

      ztTextEingeben:
      begin
        FTextArea := TTextArea.Create(scbCapture);
        FTextArea.Align := alNone;
        FTextArea.Width := 0;
        FTextArea.Height := 0;
        FTextArea.Left := FStartX;
        FTextArea.Top := FStartY;
        FTextArea.SetParentComponent(scbCapture);
        FTextArea.Editing := True;
      end;
    end;
  end;
end;

procedure TfrmSnipping.imgCaptureMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  Self.FooterRefresh(X, Y);

  if FDrawing then
  begin
    with imgCapture.Canvas do
    begin
      case FZeichnungType of
        ztKreis:
        begin
          FShape.Width := X - FStartX;
          FShape.Height := Y - FStartY;
          FShape.Repaint;
        end;

        ztPfeil:
        begin
          FPfeil.Width := X - FStartX;
          FPfeil.Height := Y - FStartY;
          FPfeil.Repaint;
        end;

        ztTextEingeben:
        begin
          FTextArea.Width := X - FStartX;
          FTextArea.Height := Y - FStartY;
          FTextArea.Repaint;
        end;
      end;
    end;
    FEndX := X;
    FEndY := Y;

    if FMaxRight < X then
      FMaxRight := X;

    if FMaxBottom < Y then
      FMaxBottom := Y;
  end;
end;

procedure TfrmSnipping.imgCaptureMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  oRect: TRect;
begin
  Self.FooterRefresh(X, Y);

  if FDrawing then
  begin
    with imgCapture.Canvas do
    begin
      case FZeichnungType of
        ztPfeil:
        begin
          FPfeil.DrawTo(FStartX, FStartY, imgCapture.Canvas);
          FPfeil.Free;
        end;

        ztKreis:
        begin
          if Assigned(FShape) then
            FShape.Free;

          Pen.Width := 2;
          Pen.Color := clRed;
          Brush.Style := bsClear;
          Ellipse(FStartX, FStartY, FEndX, FEndY);
          Ellipse(FStartX, FStartY, X, Y);
          Repaint;
        end;

        ztTextEingeben:
        begin
          if not Assigned(FTextAreaList) then
            FTextAreaList := TObjectList<TTextArea>.Create;

          if (FTextArea.Width > 0) and (FTextArea.Height > 0) then
            FTextAreaList.Add(FTextArea);
        end;
      end;

      Brush.Color := clBlack;
      Pen.Color := clRed;
      Pen.Width := 2;
    end;
    FDrawing := False;
  end
  else
  if FSchreiben then
  begin
    //TextOut()
    oRect := Rect(X, Y, 100, 100);
    imgCapture.Canvas.Brush.Color := clWhite;
    //imgCapture.Canvas.Brush.Style := bsClear;
    imgCapture.Canvas.Pen.Color := clRed;
    imgCapture.Canvas.TextRect(oRect, X, Y, 'TESTE');
    //imgCapture.Canvas.FrameRect(oRect);
    FSchreiben := False;
  end;
end;

procedure TfrmSnipping.FooterRefresh(const X, Y: Integer);
begin
  lbStartX.Caption := 'StartX: ' + IntToStr(FStartX);
  lbStartX.Repaint;
  lbStartY.Caption := 'StartY: ' + IntToStr(FStartY);
  lbStartY.Repaint;
  lbEndX.Caption := 'EndX: ' + IntToStr(FEndX);
  lbEndX.Repaint;
  lbEndY.Caption := 'EndY: ' + IntToStr(FEndY);
  lbEndY.Repaint;
  lbX.Caption := 'X: ' + IntToStr(X);
  lbX.Repaint;
  lbY.Caption := 'Y: ' + IntToStr(Y);
  lbY.Repaint;
  lbEditingMode.Caption := 'Bearbeitung: ' + cEnumZeichnungTypeStr[Integer(FZeichnungType)];
  lbEditingMode.Repaint;

end;

procedure TfrmSnipping.FormCreate(Sender: TObject);
begin
  Self.Height := scbCapture.Top + 39;
  Self.Width := 300;

  FZeichnungType := ztNone;
  with imgCapture.Canvas do
  begin
    Brush.Color := clBlack;
    Pen.Color := clRed;
    Pen.Width := 2;
  end;
end;

procedure TfrmSnipping.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

procedure TfrmSnipping.FormShow(Sender: TObject);
begin
  ButtonsZeigen();
  Self.Left := 0;
  Self.Top := 0;
  imgCapture.Top := 0;
  imgCapture.Left := 0;
end;

procedure TfrmSnipping.scbCaptureAlignPosition(Sender: TWinControl; Control: TControl;
  var NewLeft, NewTop, NewWidth, NewHeight: Integer; var AlignRect: TRect;
  AlignInfo: TAlignInfo);
begin
  imgCapture.SetBounds(NewLeft, NewTop, NewWidth, NewHeight);
end;

function TfrmSnipping.BitmapCapture(const aLeft, aTop, aRight, aBottom: Integer): TBitmap;
begin
  ConfirmTextAreas();

  Result := TBitmap.Create;
  Result.PixelFormat := TPixelFormat.pf32bit;
  Result.Width := aRight - aLeft;
  Result.Height := aBottom - aTop;

  Result.Canvas.CopyMode := cmSrcCopy;
  Result.Canvas.CopyRect(
    Rect(0, 0, Result.Width, Result.Height),
    imgCapture.Canvas,
    Rect(aLeft, aTop, aRight, aBottom));
end;

{ TPfeil }

{
  Dieses procedure zeichnet einen Pfeil auf dem Canvas
  @Param pCanvas Canvas wo gezeichnet wird
}
procedure TPfeil.Draw(const pCanvas: TCanvas);
var
  y1, y2, y3, y4, y5: Integer;
  x1 : Integer;
begin
  with pCanvas do
  begin
    //                 y4
    //                   **
    //                   *  *
    //  y1 ***************    *
    //     *             x1     *
    //     *                      * y3
    //     *             x1     *
    //  y2 ***************    *
    //                   *  *
    //                   **
    //                 y5

    if FLeft = 0 then
      FLeft := 1;

    Pen.Color := clRed;
    pen.Width := 2;
    y1 := Round((Height / 11) * 4);
    y2 := Round((Height / 11) * 7);
    y3 := Round((y2 - y1) / 2) + y1;
    y4 := Round((Height / 11) * 2);
    y5 := Round((Height / 11) * 9);
    x1 := Round((Width / 10) * 7);

    y1 := y1 + FTop;
    y2 := y2 + FTop;
    y3 := y3 + FTop;
    y4 := y4 + FTop;
    y5 := y5 + FTop;
    x1 := x1 + FLeft;

    MoveTo(FLeft, y1);
    LineTo(FLeft, y2);
    LineTo(x1, y2);
    MoveTo(FLeft, y1);
    LineTo(x1, y1);
    LineTo(x1, y4);
    LineTo(FLeft + Width, y3);
    MoveTo(x1, y2);
    LineTo(x1, y5);
    LineTo(FLeft + Width, y3);
  end;
end;

{
  Dieses procedure zeichet dem Pfeil in eine genaue Koordinate
  @Param X Achse X wo gezeichnet wird
  @Param Y Achse Y wo gezeichnet wird
  @Param pCanvas Canvas wo gezeichnet wird
}
procedure TPfeil.DrawTo(const X, Y: Integer; const pCanvas: TCanvas);
begin
  FLeft := X;
  FTop := Y;
  Self.Draw(pCanvas);
end;

procedure TPfeil.Paint;
begin
  Self.Draw(Self.Canvas);
end;

end.

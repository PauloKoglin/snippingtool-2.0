unit uTextArea;

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ComCtrls;

type
  TTextArea = class(TPanel)
    private
      FText: TRichEdit;
      FMoving: Boolean;
      FEditing: Boolean;
      FResizing: Boolean;
      FStartX, FStartY: Integer;
      FTextStr: String;

      // Events für atribut FText
      procedure TextMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure TextMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
      procedure TextMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure TextClick(Sender: TObject);
      procedure TextChange(Sender: TObject);

      // Events fürs TTextArea
      procedure AreaMouseEnter(Sender: TObject);
      procedure AreaMouseLeave(Sender: TObject);
      procedure AreaMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure AreaMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
      procedure AreaMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    public
      constructor Create(AOwner: TComponent); override;

      procedure DrawTo(const Canvas: TCanvas);

      property Editing: boolean read FEditing write FEditing;
      property TextStr: String read FTextStr;
  end;

implementation

{ TTextArea }

constructor TTextArea.Create(AOwner: TComponent);
var
  aBorder: TShape;
begin
  inherited Create(AOwner);

  Self.Width := 65;
  Self.Height := 65;
  Self.Color := clRed;
  Self.ParentBackground := False;
  Self.BorderWidth := 2;

  // Events für das Panel
  Self.OnMouseEnter := AreaMouseEnter;
  Self.OnMouseLeave := AreaMouseLeave;
  Self.OnMouseDown := AreaMouseDown;
  Self.OnMouseMove := AreaMouseMove;
  Self.OnMouseUp := AreaMouseUp;

  aBorder := TShape.Create(Self);
  aBorder.Align := alClient;
  aBorder.Pen.Style := psDot;
  aBorder.Pen.Color := clRed;
  aBorder.Pen.Width := 1;
  aBorder.Brush.Style := bsClear;
  aBorder.SetParentComponent(Self);

  FText := TRichEdit.Create(Self);
  FText.Anchors := [];
  FText.SetParentComponent(Self);
  FText.Align := alClient;
  FText.Font.Size := 12;

  // Events für das RichEdit
  FText.OnClick := TextClick;
  FText.OnMouseDown := TextMouseDown;
  FText.OnMouseMove := TextMouseMove;
  FText.OnMouseUp := TextMouseUp;
  FText.OnChange := TextChange;
  //FText.OnExit := TextExit;
  FText.OnMouseLeave := nil;
end;

procedure TTextArea.DrawTo(const Canvas: TCanvas);
var
  oTextRect: TRect;
begin
  // Zeichnet ein Rechteck
  oTextRect := Self.BoundsRect;
  Canvas.Brush.Color := clWhite;
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Width := 2;
  Canvas.Rectangle(oTextRect.Left, oTextRect.Top, oTextRect.Right, oTextRect.Bottom);

  // Zeichnet das Text
  Canvas.Font.Color := clBlack;
  Canvas.Font.Size := 12;
  Canvas.TextOut(oTextRect.Left + 3, oTextRect.Top + 1, textStr);
end;

procedure TTextArea.TextMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FMoving := True;
  FStartX := Mouse.CursorPos.X;
  FStartY := Mouse.CursorPos.Y;
end;

procedure TTextArea.AreaMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FResizing := True;
  FStartX := Self.Width;
  FStartY := Self.Height;
end;

procedure TTextArea.AreaMouseEnter(Sender: TObject);
begin
  Screen.Cursor := crSizeNWSE;
end;

procedure TTextArea.AreaMouseLeave(Sender: TObject);
begin
  Screen.Cursor := crDefault;
end;

procedure TTextArea.AreaMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if FResizing then
  begin
    Self.Width :=  Mouse.CursorPos.X - Self.Left;
    Self.Height := Mouse.CursorPos.Y - Self.Top;
    Self.Repaint;
  end;
end;

procedure TTextArea.AreaMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FResizing := False;
end;

procedure TTextArea.TextMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
 if FMoving then
  begin
    Self.Left := Self.Left - FStartX + Mouse.CursorPos.X;
    Self.Top := Self.Top - FStartY + Mouse.CursorPos.Y;
    Self.Repaint;

    FStartX := Mouse.CursorPos.X;
    FStartY := Mouse.CursorPos.Y;
  end;
end;

procedure TTextArea.TextMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FMoving := False;
end;

procedure TTextArea.TextClick(Sender: TObject);
begin
  BringToFront;
end;

procedure TTextArea.TextChange(Sender: TObject);
begin
  FTextStr := TRichEdit(Sender).Text;
end;

end.

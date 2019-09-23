program CaptureMain;

uses
  Vcl.Forms,
  uCaptureMain in 'uCaptureMain.pas' {frmSnipping},
  uCapture in 'uCapture.pas' {frmCapture},
  uTextArea in 'uTextArea.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmSnipping, frmSnipping);
  Application.Run;
end.

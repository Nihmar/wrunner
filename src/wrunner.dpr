program wrunner;

uses
  Vcl.Forms,
  frmMain in 'Forms\frmMain.pas' {MainForm},
  frmLauncher in 'Forms\frmLauncher.pas' {LauncherForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  Application.ShowMainForm := False;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;

end.

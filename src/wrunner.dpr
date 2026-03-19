program wrunner;

uses
  Vcl.Forms,
  Main in 'forms\Main.pas' {MainForm},
  WRunnerFrm in 'forms\WRunnerFrm.pas' {WRunnerForm},
  Vcl.Themes,
  Vcl.Styles,
  WRunner.Apps.Entities in 'classes\WRunner.Apps.Entities.pas',
  WRunner.Apps.Loader in 'classes\WRunner.Apps.Loader.pas',
  WRunner.Results in 'classes\WRunner.Results.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.ShowMainForm := False;
  Application.MainFormOnTaskbar := False;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

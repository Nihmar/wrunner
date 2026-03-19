unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Win.TaskbarCore, Vcl.Taskbar,
  Vcl.ExtCtrls, Vcl.Menus,
  Vcl.Themes, Vcl.Styles,

  System.Win.Registry,

  WRunnerFrm;

type
  TMainForm = class(TForm)
    TIMain: TTrayIcon;
    PMMain: TPopupMenu;
    Open1: TMenuItem;
    Close1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Open1Click(Sender: TObject);
    procedure TIMainClick(Sender: TObject);
  private
    FRunner: TWRunnerForm;
    procedure OpenRunner;
    procedure CloseRunner;
    procedure SetRunner(const Value: TWRunnerForm);
  protected
    property Runner: TWRunnerForm read FRunner write SetRunner;
    procedure WndProc(var Message: TMessage); override;
    procedure ApplyWindowsTheme;
    function IsWindowsDarkMode: Boolean;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.CloseRunner;
begin
  if Runner.Visible then
    Runner.Hide;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ApplyWindowsTheme;
  FRunner := TWRunnerForm.Create(Self);
end;

function TMainForm.IsWindowsDarkMode: Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize', False) then
      Result := Reg.ReadInteger('AppsUseLightTheme') = 0;
  finally
    Reg.Free;
  end;
end;

procedure TMainForm.ApplyWindowsTheme;
begin
  if IsWindowsDarkMode then
    TStyleManager.TrySetStyle('Windows11 Modern Dark')
  else
    TStyleManager.TrySetStyle('Windows11 Modern Light');
end;

procedure TMainForm.Close1Click(Sender: TObject);
begin
  CloseRunner;
end;

procedure TMainForm.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TMainForm.OpenRunner;
begin
  if Runner.Visible then
    Runner.Hide
  else
    Runner.Show;
end;

procedure TMainForm.Open1Click(Sender: TObject);
begin
  OpenRunner;
end;

procedure TMainForm.SetRunner(const Value: TWRunnerForm);
begin
  FRunner := Value;
end;

procedure TMainForm.TIMainClick(Sender: TObject);
begin
  OpenRunner;
end;

procedure TMainForm.WndProc(var Message: TMessage);
begin
  inherited;
  if Message.Msg = WM_SETTINGCHANGE then
  begin
    if string(PChar(Message.LParam)) = 'ImmersiveColorSet' then
      ApplyWindowsTheme;
  end;
end;

end.

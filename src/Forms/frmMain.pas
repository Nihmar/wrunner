unit frmMain;

interface

uses
  Winapi.Windows,
  Winapi.Messages,

  System.SysUtils,
  System.Variants,
  System.Classes,
  System.ImageList,

  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Menus,
  Vcl.ImgList;

type
  TMainForm = class(TForm)
    TIMain: TTrayIcon;
    PMMain: TPopupMenu;
    Apri1: TMenuItem;
    Apri2: TMenuItem;
    Chiudi1: TMenuItem;
    ILMain: TImageList;
    procedure Apri1Click(Sender: TObject);
    procedure Chiudi1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.Apri1Click(Sender: TObject);
begin
  //
end;

procedure TMainForm.Chiudi1Click(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

end.

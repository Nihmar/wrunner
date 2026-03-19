unit WRunnerFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  WRunner.Apps.Loader;

type
  TWRunnerForm = class(TForm)
    EInputSearch: TEdit;
    LVSearchResults: TListView;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure EInputSearchChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LVSearchResultsDblClick(Sender: TObject);
    procedure LVSearchResultsKeyPress(Sender: TObject; var Key: Char);
  private
    FLoader: TAppLoader;
    FLog: TStringList;
    procedure HandleLoaderLoaded(Sender: TObject);
  public
  end;

implementation

{$R *.dfm}

procedure TWRunnerForm.FormCreate(Sender: TObject);
begin
  FLog := TStringList.Create;
  FLoader := TAppLoader.Create(LVSearchResults, FLog);
  FLoader.OnLoaded := HandleLoaderLoaded;
  FLoader.StartAsyncLoad;
end;

procedure TWRunnerForm.FormDestroy(Sender: TObject);
begin
  FLoader.Free;
  FLog.Free;
end;

procedure TWRunnerForm.HandleLoaderLoaded(Sender: TObject);
begin
  //
end;

procedure TWRunnerForm.EInputSearchChange(Sender: TObject);
begin
  if Assigned(FLoader) then
    FLoader.Filter(EInputSearch.Text);
end;

procedure TWRunnerForm.FormShow(Sender: TObject);
begin
  EInputSearch.SetFocus;
end;

procedure TWRunnerForm.LVSearchResultsDblClick(Sender: TObject);
begin
  if LVSearchResults.ItemIndex >= 0 then
    FLoader.LaunchApp(LVSearchResults.ItemIndex);
end;

procedure TWRunnerForm.LVSearchResultsKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) and (LVSearchResults.ItemIndex >= 0) then
  begin
    Key := #0;
    FLoader.LaunchApp(LVSearchResults.ItemIndex);
  end;
end;

end.

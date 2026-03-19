unit WRunnerFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  WRunner.Apps.Loader;

type
  TWRunnerForm = class(TForm)
    EInputSearch: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure EInputSearchChange(Sender: TObject);
    procedure EInputSearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    FLoader: TAppLoader;
    FLog: TStringList;
    FListView: TListView;
    procedure HandleLoaderLoaded(Sender: TObject);
    procedure HandleListViewDblClick(Sender: TObject);
  public
  end;

implementation

{$R *.dfm}

procedure TWRunnerForm.FormCreate(Sender: TObject);
begin
  FLog := TStringList.Create;
  FListView := TListView.Create(Self);
  FListView.Parent := Self;
  FListView.Align := alClient;
  FListView.AlignWithMargins := True;
  FListView.Margins.Left := 6;
  FListView.Margins.Right := 6;
  FListView.Margins.Bottom := 6;
  FListView.Margins.Top := 3;
  FLoader := TAppLoader.Create(FListView, FLog);
  FLoader.RowHeight := 50;
  FLoader.FontName := 'Segoe UI';
  FLoader.FontSize := 10;
  FLoader.IconSpacing := 12;
  FListView.OnDblClick := HandleListViewDblClick;
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

procedure TWRunnerForm.HandleListViewDblClick(Sender: TObject);
begin
  if FListView.ItemIndex >= 0 then
    FLoader.LaunchApp(FListView.ItemIndex);
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

procedure TWRunnerForm.EInputSearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  LNewIndex: Integer;
begin
  case Key of
    VK_DOWN:
      begin
        Key := 0;
        if FListView.Items.Count > 0 then
        begin
          LNewIndex := FListView.ItemIndex + 1;
          if LNewIndex >= FListView.Items.Count then
            LNewIndex := FListView.Items.Count - 1;
          FListView.ItemIndex := LNewIndex;
          FListView.Items[LNewIndex].MakeVisible(False);
        end;
      end;
    VK_UP:
      begin
        Key := 0;
        if FListView.Items.Count > 0 then
        begin
          LNewIndex := FListView.ItemIndex - 1;
          if LNewIndex < 0 then
            LNewIndex := 0;
          FListView.ItemIndex := LNewIndex;
          FListView.Items[LNewIndex].MakeVisible(False);
        end;
      end;
    VK_RETURN:
      begin
        Key := 0;
        if FListView.ItemIndex >= 0 then
          FLoader.LaunchApp(FListView.ItemIndex);
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        Close;
      end;
  end;
end;

end.

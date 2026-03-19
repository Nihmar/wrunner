unit WRunner.Apps.Loader;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults,
  Winapi.Windows, Winapi.ShlObj, Winapi.ActiveX, Winapi.ShellAPI,
  Winapi.KnownFolders,
  Vcl.Controls, Vcl.ComCtrls, Vcl.Graphics, Vcl.ImgList,
  WRunner.Apps.Entities;

type
  TAppLoader = class
  private
    FListView: TListView;
    FImageList: TImageList;
    FAllApps: TListDesktopEntities;
    FFilteredApps: TListDesktopEntities;
    FLoaded: Boolean;
    FLoading: Boolean;
    FLog: TStrings;
    FOnLoaded: TNotifyEvent;
    procedure LoadFromShellFolder;
    procedure ExtractIconToImageList(const AParsingName: string; AEntity: TDesktopEntity);
    procedure HandleListViewData(Sender: TObject; Item: TListItem);
    procedure SortApps(AList: TListDesktopEntities);
    procedure DoLoadComplete;
  public
    constructor Create(AListView: TListView; ALog: TStrings = nil);
    destructor Destroy; override;
    procedure StartAsyncLoad;
    procedure Filter(const AQuery: string);
    procedure LaunchApp(AIndex: Integer);
    property ImageList: TImageList read FImageList;
    function FilteredCount: Integer;
    property Loaded: Boolean read FLoaded;
    property Loading: Boolean read FLoading;
    property OnLoaded: TNotifyEvent read FOnLoaded write FOnLoaded;
  end;

implementation

uses
  System.Win.ComObj;

{ TAppLoader }

constructor TAppLoader.Create(AListView: TListView; ALog: TStrings = nil);
begin
  inherited Create;
  FListView := AListView;
  FLog := ALog;
  FLoaded := False;
  FLoading := False;

  FImageList := TImageList.Create(nil);
  FImageList.ColorDepth := cd32Bit;
  FImageList.SetSize(32, 32);

  FAllApps := TListDesktopEntities.Create;
  FFilteredApps := TListDesktopEntities.Create;
  FFilteredApps.OwnsObjects := False;

  FListView.LargeImages := FImageList;
  FListView.SmallImages := FImageList;
  FListView.OwnerData := True;
  FListView.ViewStyle := vsReport;
  FListView.ReadOnly := True;
  FListView.RowSelect := True;
  FListView.HideSelection := False;

  if FListView.Columns.Count = 0 then
  begin
    with FListView.Columns.Add do
    begin
      Caption := 'App';
      Width := FListView.ClientWidth - 25;
    end;
  end;

  FListView.OnData := HandleListViewData;
end;

destructor TAppLoader.Destroy;
begin
  FFilteredApps.Free;
  FAllApps.Free;
  FImageList.Free;
  inherited;
end;

procedure TAppLoader.StartAsyncLoad;
begin
  if FLoaded or FLoading then
    Exit;

  FLoading := True;

  TThread.CreateAnonymousThread(
    procedure
    var
      LError: string;
    begin
      LError := '';
      try
        CoInitialize(nil);
        try
          LoadFromShellFolder;
          FLoaded := True;
        finally
          CoUninitialize;
        end;
      except
        on E: Exception do
          LError := E.Message;
      end;

      FLoading := False;
      TThread.Synchronize(nil,
        procedure
        begin
          if LError <> '' then
          begin
            if Assigned(FLog) then
              FLog.Add(Format('[%s] Error loading apps: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), LError]));
          end;
          DoLoadComplete;
        end
      );
    end
  ).Start;
end;

procedure TAppLoader.DoLoadComplete;
begin
  if Assigned(FOnLoaded) then
    FOnLoaded(Self);
end;

procedure TAppLoader.LoadFromShellFolder;
var
  LShellFolder: IShellFolder;
  LEnumIDList: IEnumIDList;
  LPID: PItemIDList;
  LFetched: ULONG;
  LStrRet: TStrRet;
  LDisplayName: string;
  LParsingName: string;
  LEntity: TDesktopEntity;
  LFlags: DWORD;
  LDesktopFolder: IShellFolder;
  LAppsPIDL: PItemIDList;
  LAttr: ULONG;
  LTempList: TListDesktopEntities;
begin
  LAppsPIDL := nil;

  if Failed(SHGetKnownFolderIDList(FOLDERID_AppsFolder, 0, 0, LAppsPIDL)) then
  begin
    OleCheck(SHGetDesktopFolder(LDesktopFolder));
    LAttr := 0;
    OleCheck(LDesktopFolder.ParseDisplayName(0, nil, 'shell:appsfolder', LAttr, LAppsPIDL, LAttr));
  end;

  try
    OleCheck(SHGetDesktopFolder(LDesktopFolder));
    OleCheck(LDesktopFolder.BindToObject(LAppsPIDL, nil, IShellFolder, Pointer(LShellFolder)));
  finally
    CoTaskMemFree(LAppsPIDL);
  end;

  LFlags := SHCONTF_NONFOLDERS or SHCONTF_INCLUDEHIDDEN or SHCONTF_FOLDERS;
  OleCheck(LShellFolder.EnumObjects(0, LFlags, LEnumIDList));

  LTempList := TListDesktopEntities.Create;
  try
    while LEnumIDList.Next(1, LPID, LFetched) = S_OK do
    begin
      try
        if LShellFolder.GetDisplayNameOf(LPID, SHGDN_NORMAL, LStrRet) <> S_OK then
          Continue;

        case LStrRet.uType of
          STRRET_WSTR:
            begin
              LDisplayName := string(LStrRet.pOleStr);
              CoTaskMemFree(LStrRet.pOleStr);
            end;
          STRRET_CSTR:
            LDisplayName := string(LStrRet.cStr);
          STRRET_OFFSET:
            LDisplayName := PWideChar(PByte(LPID) + LStrRet.uOffset);
        else
          LDisplayName := '';
        end;

        if LShellFolder.GetDisplayNameOf(LPID, SHGDN_FORPARSING, LStrRet) <> S_OK then
          Continue;

        case LStrRet.uType of
          STRRET_WSTR:
            begin
              LParsingName := string(LStrRet.pOleStr);
              CoTaskMemFree(LStrRet.pOleStr);
            end;
          STRRET_CSTR:
            LParsingName := string(LStrRet.cStr);
          STRRET_OFFSET:
            LParsingName := PWideChar(PByte(LPID) + LStrRet.uOffset);
        else
          LParsingName := '';
        end;

        if (LDisplayName = '') or (LParsingName = '') then
          Continue;

        LEntity := TDesktopEntity.Create;
        try
          LEntity.DisplayName := LDisplayName;
          LEntity.ParsingName := LParsingName;
          LEntity.LaunchCommand := LParsingName;
          LEntity.ImageIndex := -1;
          ExtractIconToImageList(LParsingName, LEntity);
          LTempList.Add(LEntity);
        except
          on E: Exception do
          begin
            LEntity.Free;
          end;
        end;
      finally
        CoTaskMemFree(LPID);
      end;
    end;

    SortApps(LTempList);

    TThread.Synchronize(nil,
      procedure
      begin
        FAllApps.Clear;
        FAllApps.AddRange(LTempList);
        FFilteredApps.Clear;
        FFilteredApps.AddRange(FAllApps);
        FListView.Items.Count := FFilteredApps.Count;
        FListView.Invalidate;
      end
    );
  finally
    LTempList.OwnsObjects := False;
    LTempList.Free;
  end;
end;

procedure TAppLoader.ExtractIconToImageList(const AParsingName: string; AEntity: TDesktopEntity);
var
  LSHFileInfo: TSHFileInfo;
  LIcon: TIcon;
  LFlags: UINT;
begin
  LFlags := SHGFI_SYSICONINDEX or SHGFI_LARGEICON or SHGFI_ICON;
  FillChar(LSHFileInfo, SizeOf(LSHFileInfo), 0);

  if SHGetFileInfo(PChar(AParsingName), 0, LSHFileInfo, SizeOf(LSHFileInfo), LFlags) <> 0 then
  begin
    if LSHFileInfo.hIcon <> 0 then
    begin
      LIcon := TIcon.Create;
      try
        LIcon.Handle := LSHFileInfo.hIcon;
        AEntity.ImageIndex := FImageList.AddIcon(LIcon);
      finally
        LIcon.Free;
      end;
    end;
  end;
end;

procedure TAppLoader.HandleListViewData(Sender: TObject; Item: TListItem);
var
  LEntity: TDesktopEntity;
begin
  if (Item.Index >= 0) and (Item.Index < FFilteredApps.Count) then
  begin
    LEntity := FFilteredApps[Item.Index];
    Item.Caption := LEntity.DisplayName;
    Item.ImageIndex := LEntity.ImageIndex;
  end;
end;

procedure TAppLoader.SortApps(AList: TListDesktopEntities);
begin
  AList.Sort(
    TComparer<TDesktopEntity>.Construct(
      function(const Left, Right: TDesktopEntity): Integer
      begin
        Result := CompareText(Left.DisplayName, Right.DisplayName);
      end
    )
  );
end;

procedure TAppLoader.Filter(const AQuery: string);
var
  LEntity: TDesktopEntity;
  LQuery: string;
begin
  if not FLoaded then
    Exit;

  FFilteredApps.Clear;
  LQuery := LowerCase(Trim(AQuery));

  if LQuery = '' then
  begin
    FFilteredApps.AddRange(FAllApps);
  end
  else
  begin
    for LEntity in FAllApps do
    begin
      if Pos(LQuery, LowerCase(LEntity.DisplayName)) > 0 then
        FFilteredApps.Add(LEntity);
    end;
  end;

  FListView.Items.Count := FFilteredApps.Count;
  FListView.Invalidate;
end;

function TAppLoader.FilteredCount: Integer;
begin
  Result := FFilteredApps.Count;
end;

procedure TAppLoader.LaunchApp(AIndex: Integer);
var
  LEntity: TDesktopEntity;
begin
  if (AIndex < 0) or (AIndex >= FFilteredApps.Count) then
    Exit;

  LEntity := FFilteredApps[AIndex];

  try
    ShellExecute(0, 'open', PChar(LEntity.LaunchCommand), nil, nil, SW_SHOWNORMAL);
  except
    on E: Exception do
    begin
      if Assigned(FLog) then
        FLog.Add(Format('[%s] Error launching app "%s": %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), LEntity.DisplayName, E.Message]));
    end;
  end;
end;

end.

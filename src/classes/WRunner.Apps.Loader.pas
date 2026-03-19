unit WRunner.Apps.Loader;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults,
  Winapi.Windows, Winapi.ShlObj, Winapi.ActiveX, Winapi.ShellAPI,
  Winapi.KnownFolders,
  Vcl.Controls, Vcl.ComCtrls, Vcl.Graphics, Vcl.ImgList, Vcl.Themes, Vcl.Styles,
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
    FRowHeight: Integer;
    FFontName: string;
    FFontSize: Integer;
    FIconSpacing: Integer;
    procedure LoadFromShellFolder;
    procedure EnumFolder(AFolder, ADesktopFolder: IShellFolder; AParentPIDL: PItemIDList; AList: TListDesktopEntities);
    procedure LoadIconsAsync;
    procedure HandleListViewData(Sender: TObject; Item: TListItem);
    procedure HandleCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
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
    property RowHeight: Integer read FRowHeight write FRowHeight;
    property FontName: string read FFontName write FFontName;
    property FontSize: Integer read FFontSize write FFontSize;
    property IconSpacing: Integer read FIconSpacing write FIconSpacing;
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
  FRowHeight := 40;
  FFontName := 'Segoe UI';
  FFontSize := 10;
  FIconSpacing := 8;

  FImageList := TImageList.Create(nil);
  FImageList.ColorDepth := cd32Bit;
  FImageList.SetSize(32, 32);

  FAllApps := TListDesktopEntities.Create;
  FFilteredApps := TListDesktopEntities.Create;
  FFilteredApps.OwnsObjects := False;

  FListView.LargeImages := FImageList;
  FListView.SmallImages := FImageList;
  FListView.OwnerData := True;
  FListView.OwnerDraw := True;
  FListView.ViewStyle := vsReport;
  FListView.ReadOnly := True;
  FListView.RowSelect := True;
  FListView.HideSelection := False;
  FListView.ShowColumnHeaders := False;

  if FListView.Columns.Count = 0 then
  begin
    with FListView.Columns.Add do
    begin
      Caption := 'App';
      Width := FListView.ClientWidth - 25;
    end;
  end;

  FListView.OnData := HandleListViewData;
  FListView.OnCustomDrawItem := HandleCustomDrawItem;
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

  OleCheck(SHGetDesktopFolder(LDesktopFolder));
  OleCheck(LDesktopFolder.BindToObject(LAppsPIDL, nil, IShellFolder, Pointer(LShellFolder)));

    LTempList := TListDesktopEntities.Create;
    try
      EnumFolder(LShellFolder, LDesktopFolder, LAppsPIDL, LTempList);
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
      if LAppsPIDL <> nil then
        CoTaskMemFree(LAppsPIDL);
    end;

    LoadIconsAsync;
  end;

procedure TAppLoader.EnumFolder(AFolder, ADesktopFolder: IShellFolder; AParentPIDL: PItemIDList; AList: TListDesktopEntities);
var
  LEnumIDList: IEnumIDList;
  LPID: PItemIDList;
  LFetched: ULONG;
  LFlags: DWORD;
  LAttr: ULONG;
  LSubFolder: IShellFolder;
  LStrRet: TStrRet;
  LDisplayName: string;
  LParsingName: string;
  LEntity: TDesktopEntity;
  LAbsPIDL: PItemIDList;
begin
  LFlags := SHCONTF_FOLDERS or SHCONTF_NONFOLDERS;
  if Failed(AFolder.EnumObjects(0, LFlags, LEnumIDList)) then
    Exit;

  while LEnumIDList.Next(1, LPID, LFetched) = S_OK do
  begin
    LAbsPIDL := nil;
    try
      LAttr := SFGAO_FOLDER or SFGAO_STREAM;
      AFolder.GetAttributesOf(1, LPID, LAttr);

      if (LAttr and SFGAO_FOLDER <> 0) and (LAttr and SFGAO_STREAM = 0) then
      begin
        if Succeeded(AFolder.BindToObject(LPID, nil, IShellFolder, Pointer(LSubFolder))) then
        begin
          LAbsPIDL := ILCombine(AParentPIDL, LPID);
          EnumFolder(LSubFolder, ADesktopFolder, LAbsPIDL, AList);
        end;
        Continue;
      end;

      LStrRet.uType := STRRET_WSTR;
      LStrRet.pOleStr := nil;
      if AFolder.GetDisplayNameOf(LPID, SHGDN_NORMAL, LStrRet) <> S_OK then
        Continue;

      LDisplayName := '';
      if (LStrRet.uType = STRRET_WSTR) and (LStrRet.pOleStr <> nil) then
      begin
        LDisplayName := LStrRet.pOleStr;
        CoTaskMemFree(LStrRet.pOleStr);
      end;

      if LDisplayName = '' then
        Continue;

      LStrRet.uType := STRRET_WSTR;
      LStrRet.pOleStr := nil;
      AFolder.GetDisplayNameOf(LPID, SHGDN_FORPARSING, LStrRet);
      LParsingName := '';
      if (LStrRet.uType = STRRET_WSTR) and (LStrRet.pOleStr <> nil) then
      begin
        LParsingName := LStrRet.pOleStr;
        CoTaskMemFree(LStrRet.pOleStr);
      end;

      LEntity := TDesktopEntity.Create;
      try
        LEntity.DisplayName := LDisplayName;
        LEntity.ParsingName := LParsingName;
        LEntity.LaunchCommand := LParsingName;
        LEntity.ImageIndex := -1;
        LAbsPIDL := ILCombine(AParentPIDL, LPID);
        LEntity.SetPIDL(LAbsPIDL);
        AList.Add(LEntity);
      except
        on E: Exception do
          LEntity.Free;
      end;
    finally
      if LAbsPIDL <> nil then
        CoTaskMemFree(LAbsPIDL);
      CoTaskMemFree(LPID);
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

procedure TAppLoader.HandleCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  LEntity: TDesktopEntity;
  LRect: TRect;
  LIconRect: TRect;
  LTextRect: TRect;
  LIconHeight: Integer;
begin
  DefaultDraw := False;
  if (Item.Index < 0) or (Item.Index >= FFilteredApps.Count) then
    Exit;

  LEntity := FFilteredApps[Item.Index];
  LRect := Item.DisplayRect(drBounds);

  with Sender.Canvas do
  begin
    if cdsSelected in State then
    begin
      Brush.Color := StyleServices.GetStyleColor(scButtonFocused);
      Font.Color := StyleServices.GetStyleFontColor(sfListItemTextSelected);
    end
    else
    begin
      Brush.Color := StyleServices.GetStyleColor(scListView);
      Font.Color := StyleServices.GetStyleFontColor(sfListItemTextNormal);
    end;

    FillRect(LRect);

    Font.Name := FFontName;
    Font.Size := FFontSize;
    Font.Style := [];

    if LEntity.ImageIndex >= 0 then
    begin
      LIconHeight := FImageList.Height;
      LIconRect := Rect(
        LRect.Left + 4,
        LRect.Top + (LRect.Height - LIconHeight) div 2,
        LRect.Left + 4 + FImageList.Width,
        LRect.Top + (LRect.Height - LIconHeight) div 2 + LIconHeight
      );
      FImageList.Draw(Sender.Canvas, LIconRect.Left, LIconRect.Top, LEntity.ImageIndex);

      LTextRect := Rect(
        LIconRect.Right + FIconSpacing,
        LRect.Top,
        LRect.Right,
        LRect.Bottom
      );
    end
    else
    begin
      LTextRect := Rect(
        LRect.Left + FIconSpacing,
        LRect.Top,
        LRect.Right,
        LRect.Bottom
      );
    end;

    DrawText(Handle, PChar(LEntity.DisplayName), -1, LTextRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
  end;
end;

procedure TAppLoader.LoadIconsAsync;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      I: Integer;
      LEntity: TDesktopEntity;
      LSHFileInfo: TSHFileInfo;
      LIcon: TIcon;
      LCount: Integer;
    begin
      CoInitialize(nil);
      try
        LCount := FAllApps.Count;
        for I := 0 to LCount - 1 do
        begin
          LEntity := FAllApps[I];
          if LEntity.ImageIndex <> -1 then
            Continue;

          if LEntity.PIDL <> nil then
          begin
            FillChar(LSHFileInfo, SizeOf(LSHFileInfo), 0);
            if SHGetFileInfo(PChar(LEntity.PIDL), 0, LSHFileInfo, SizeOf(LSHFileInfo),
              SHGFI_PIDL or SHGFI_LARGEICON or SHGFI_ICON) <> 0 then
            begin
              if LSHFileInfo.hIcon <> 0 then
              begin
                TThread.Synchronize(nil,
                  procedure
                  begin
                    LIcon := TIcon.Create;
                    try
                      LIcon.Handle := LSHFileInfo.hIcon;
                      LEntity.ImageIndex := FImageList.AddIcon(LIcon);
                    finally
                      LIcon.Free;
                    end;
                    FListView.Invalidate;
                  end
                );
              end;
            end;
          end;
        end;
      finally
        CoUninitialize;
      end;
    end
  ).Start;
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

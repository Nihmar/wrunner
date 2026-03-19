unit WRunner.Apps.Entities;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  Winapi.Windows,
  Winapi.ShlObj,
  Winapi.ActiveX;

type
  TDesktopEntity = class
  private
    FImageIndex: Integer;
    FDisplayName: String;
    FParsingName: String;
    FLaunchCommand: String;
    FPIDL: PItemIDList;
    procedure SetDisplayName(const Value: String);
    procedure SetImageIndex(const Value: Integer);
    procedure SetLaunchCommand(const Value: String);
    procedure SetParsingName(const Value: String);
  public
    destructor Destroy; override;
    procedure SetPIDL(ASourcePIDL: PItemIDList);
    property DisplayName: String read FDisplayName write SetDisplayName;
    property ParsingName: String read FParsingName write SetParsingName;
    property LaunchCommand: String read FLaunchCommand write SetLaunchCommand;
    property ImageIndex: Integer read FImageIndex write SetImageIndex;
    property PIDL: PItemIDList read FPIDL;
  end;

  TListDesktopEntities = class(TObjectList<TDesktopEntity>)
  public
    constructor Create; overload;
  end;

implementation

{ TDesktopEntity }

destructor TDesktopEntity.Destroy;
begin
  if FPIDL <> nil then
    CoTaskMemFree(FPIDL);
  inherited;
end;

procedure TDesktopEntity.SetDisplayName(const Value: String);
begin
  FDisplayName := Value;
end;

procedure TDesktopEntity.SetImageIndex(const Value: Integer);
begin
  FImageIndex := Value;
end;

procedure TDesktopEntity.SetLaunchCommand(const Value: String);
begin
  FLaunchCommand := Value;
end;

procedure TDesktopEntity.SetParsingName(const Value: String);
begin
  FParsingName := Value;
end;

procedure TDesktopEntity.SetPIDL(ASourcePIDL: PItemIDList);
var
  LSize: Integer;
begin
  if FPIDL <> nil then
  begin
    CoTaskMemFree(FPIDL);
    FPIDL := nil;
  end;
  if ASourcePIDL <> nil then
  begin
    LSize := ILGetSize(ASourcePIDL);
    FPIDL := CoTaskMemAlloc(LSize);
    Move(ASourcePIDL^, FPIDL^, LSize);
  end;
end;

{ TListDesktopEntities }

constructor TListDesktopEntities.Create;
begin
  inherited Create(True);
end;

end.

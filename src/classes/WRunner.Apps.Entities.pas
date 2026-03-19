unit WRunner.Apps.Entities;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TDesktopEntity = class
  private
    FImageIndex: Integer;
    FDisplayName: String;
    FParsingName: String;
    FLaunchCommand: String;
    procedure SetDisplayName(const Value: String);
    procedure SetImageIndex(const Value: Integer);
    procedure SetLaunchCommand(const Value: String);
    procedure SetParsingName(const Value: String);
  public
    property DisplayName: String read FDisplayName write SetDisplayName;
    property ParsingName: String read FParsingName write SetParsingName;
    property LaunchCommand: String read FLaunchCommand write SetLaunchCommand;
    property ImageIndex: Integer read FImageIndex write SetImageIndex;
  end;

  TListDesktopEntities = class(TObjectDictionary<String, TDesktopEntity>)
  public
    constructor Create; overload;
    function AddDesktopEntity(AParsingName: string): TDesktopEntity;
  end;

implementation

{ TDesktopEntity }

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

{ TListDesktopEntities }

function TListDesktopEntities.AddDesktopEntity(AParsingName: string):
    TDesktopEntity;
var
  LApp: TDesktopEntity;
begin
  LApp := nil;
  if TryGetValue(AParsingName, LApp) then
    Result := LApp
  else
    begin
      Result := TDesktopEntity.Create;
      Result.ParsingName := AParsingName;
      Add(AParsingName, Result);
    end;
end;

constructor TListDesktopEntities.Create;
begin
  inherited Create([doOwnsValues]);
  //
end;

end.

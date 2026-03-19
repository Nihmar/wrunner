unit WRunner.Apps.Entities;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults;

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

  TListDesktopEntities = class(TObjectList<TDesktopEntity>)
  public
    constructor Create; overload;
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

constructor TListDesktopEntities.Create;
begin
  inherited Create(True);
end;

end.

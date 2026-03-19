unit WRunnerFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TWRunnerForm = class(TForm)
    EInputSearch: TEdit;
    LVSearchResults: TListView;
  private
  public
  end;

implementation

{$R *.dfm}

end.

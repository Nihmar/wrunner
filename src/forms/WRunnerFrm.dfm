object WRunnerForm: TWRunnerForm
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'WRunnerForm'
  ClientHeight = 480
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  RoundedCorners = rcOn
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object EInputSearch: TEdit
    AlignWithMargins = True
    Left = 6
    Top = 6
    Width = 628
    Height = 23
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Align = alTop
    CanUndoSelText = True
    TabOrder = 0
    TextHint = 'Search apps...'
    OnChange = EInputSearchChange
  end
  object LVSearchResults: TListView
    AlignWithMargins = True
    Left = 6
    Top = 35
    Width = 628
    Height = 439
    Margins.Left = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alClient
    Columns = <>
    TabOrder = 1
    OnDblClick = LVSearchResultsDblClick
    OnKeyPress = LVSearchResultsKeyPress
  end
end

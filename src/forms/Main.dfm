object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MainForm'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  WindowState = wsMinimized
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 15
  object TIMain: TTrayIcon
    Animate = True
    PopupMenu = PMMain
    Visible = True
    OnDblClick = TIMainDblClick
    Left = 304
    Top = 224
  end
  object PMMain: TPopupMenu
    Left = 368
    Top = 224
    object Open1: TMenuItem
      Caption = 'Open'
      OnClick = Open1Click
    end
    object Close1: TMenuItem
      Caption = 'Close'
      OnClick = Close1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Exit1: TMenuItem
      Caption = 'Exit'
      OnClick = Exit1Click
    end
  end
end

object frmTextEditor: TfrmTextEditor
  Left = 0
  Top = 0
  Caption = 'frmTextEditor'
  ClientHeight = 481
  ClientWidth = 1123
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnFind: TPanel
    Left = 0
    Top = 344
    Width = 1123
    Height = 137
    Align = alBottom
    TabOrder = 0
    object lblFind: TLabel
      Left = 24
      Top = 48
      Width = 60
      Height = 13
      Caption = 'Text to find:'
    end
    object lblReplaceBy: TLabel
      Left = 27
      Top = 75
      Width = 57
      Height = 13
      Caption = 'Replace by:'
    end
    object lblTextLength: TLabel
      Left = 433
      Top = 88
      Width = 3
      Height = 13
    end
    object lblMethod: TLabel
      Left = 44
      Top = 19
      Width = 40
      Height = 13
      Caption = 'Method:'
    end
    object lblArg1: TLabel
      Left = 57
      Top = 102
      Width = 27
      Height = 13
      Caption = 'Arg1:'
    end
    object lblArg2: TLabel
      Left = 255
      Top = 102
      Width = 27
      Height = 13
      Caption = 'Arg2:'
    end
    object Label1: TLabel
      Left = 433
      Top = 19
      Width = 123
      Height = 13
      Caption = 'Number of spaces in TAB:'
    end
    object lblArg3: TLabel
      Left = 428
      Top = 102
      Width = 27
      Height = 13
      Caption = 'Arg3:'
    end
    object lmlFuncName: TLabel
      Left = 381
      Top = 48
      Width = 74
      Height = 13
      Caption = 'Function name:'
    end
    object edFindText: TEdit
      Left = 90
      Top = 45
      Width = 121
      Height = 21
      TabOrder = 0
    end
    object edReplaceBy: TEdit
      Left = 90
      Top = 72
      Width = 121
      Height = 21
      TabOrder = 1
    end
    object btnReplace: TButton
      Left = 672
      Top = 43
      Width = 65
      Height = 25
      Caption = 'Replace'
      TabOrder = 2
      OnClick = btnReplaceClick
    end
    object cbReplaceSpecDelphi: TCheckBox
      Left = 217
      Top = 75
      Width = 144
      Height = 17
      Caption = 'Replace by Delphi string'
      TabOrder = 3
    end
    object cbFindSpecDelphi: TCheckBox
      Left = 217
      Top = 49
      Width = 120
      Height = 17
      Caption = 'Find like delphi string'
      TabOrder = 4
    end
    object btnExecute: TButton
      Left = 672
      Top = 13
      Width = 65
      Height = 25
      Caption = 'Execute'
      TabOrder = 5
      OnClick = btnExecuteClick
    end
    object cbChangeMethod: TComboBox
      Left = 90
      Top = 15
      Width = 319
      Height = 21
      Style = csDropDownList
      TabOrder = 6
    end
    object edArg1: TEdit
      Left = 90
      Top = 98
      Width = 121
      Height = 21
      TabOrder = 7
    end
    object edArg2: TEdit
      Left = 288
      Top = 99
      Width = 121
      Height = 21
      TabOrder = 8
    end
    object edSpacesInTab: TEdit
      Left = 562
      Top = 16
      Width = 31
      Height = 21
      Alignment = taRightJustify
      TabOrder = 9
      Text = '8'
      OnKeyDown = edSpacesInTabKeyDown
    end
    object Button1: TButton
      Left = 672
      Top = 101
      Width = 65
      Height = 25
      Caption = 'Button1'
      TabOrder = 10
      OnClick = Button1Click
      OnKeyPress = Button1KeyPress
    end
    object edArg3: TEdit
      Left = 461
      Top = 99
      Width = 121
      Height = 21
      TabOrder = 11
    end
    object edFuncName: TEdit
      Left = 461
      Top = 45
      Width = 121
      Height = 21
      TabOrder = 12
    end
  end
  object pnViews: TPanel
    Left = 0
    Top = 0
    Width = 1123
    Height = 344
    Align = alClient
    TabOrder = 1
    object pnEdit: TPanel
      Left = 1
      Top = 1
      Width = 543
      Height = 342
      Align = alClient
      TabOrder = 0
      object lblEditor: TLabel
        Left = 8
        Top = 5
        Width = 28
        Height = 13
        Caption = 'Editor'
      end
      object memEdit: TRichEdit
        AlignWithMargins = True
        Left = 6
        Top = 24
        Width = 531
        Height = 312
        Margins.Left = 5
        Margins.Top = 23
        Margins.Right = 5
        Margins.Bottom = 5
        Align = alClient
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        MaxLength = 2000000000
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
        WantTabs = True
        OnKeyDown = memEditKeyDown
      end
    end
    object pnResult: TPanel
      Left = 544
      Top = 1
      Width = 578
      Height = 342
      Align = alRight
      TabOrder = 1
      object lblResult: TLabel
        Left = 8
        Top = 5
        Width = 30
        Height = 13
        Caption = 'Result'
      end
      object memResult: TRichEdit
        AlignWithMargins = True
        Left = 6
        Top = 24
        Width = 566
        Height = 312
        Margins.Left = 5
        Margins.Top = 23
        Margins.Right = 5
        Margins.Bottom = 5
        Align = alClient
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        MaxLength = 2000000000
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
        WantTabs = True
      end
    end
  end
end

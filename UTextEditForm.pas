unit UTextEditForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls;

type
  TNamedHandler = record
    Name: string;
    Handler: procedure of object;
  end;


  TNamedHandlers = array of TNamedHandler;


  TFoundStringHandler =
    procedure(
      const AFindText: string; ARow, ACol: integer;
      var AContinueAfterEndOfPattern: boolean) of object;


  TfrmTextEditor = class(TForm)
    pnEdit: TPanel;
    pnFind: TPanel;
    edFindText: TEdit;
    edReplaceBy: TEdit;
    btnReplace: TButton;
    lblFind: TLabel;
    lblReplaceBy: TLabel;
    cbReplaceSpecDelphi: TCheckBox;
    cbFindSpecDelphi: TCheckBox;
    btnExecute: TButton;
    lblTextLength: TLabel;
    cbChangeMethod: TComboBox;
    pnViews: TPanel;
    pnResult: TPanel;
    lblEditor: TLabel;
    lblResult: TLabel;
    lblMethod: TLabel;
    edArg1: TEdit;
    edArg2: TEdit;
    lblArg1: TLabel;
    lblArg2: TLabel;
    Label1: TLabel;
    edSpacesInTab: TEdit;
    Button1: TButton;
    lblArg3: TLabel;
    edArg3: TEdit;
    memEdit: TRichEdit;
    memResult: TRichEdit;
    edFuncName: TEdit;
    lmlFuncName: TLabel;
    procedure btnReplaceClick(Sender: TObject);
    procedure memEditChange(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure memEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edSpacesInTabKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button1Click(Sender: TObject);
    procedure Button1KeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    FHandlers: TNamedHandlers;

    FPatternIndex: integer;
    FLastRow: integer;
    FLastCol: integer;
    FRowStringForResult: string;

    FLettersCount: integer;
    function ConvertDelphiCodeToString(const ACode: string): string;
    function GetHandlers: TNamedHandlers;
    procedure UpdateTextLengthLabel;
    procedure FindAndHandleAllPatterns(
      const AFindText: string; AFoundStringHandler: TFoundStringHandler);
    procedure AppendIndexAndAddToResult(
      const AFindText: string; ARow, ACol: integer;
      var AContinueAfterEndOfPattern: boolean);
    procedure DeleteSubstrAndAddToResult(
      const AFindText: string; ARow, ACol: integer;
      var AContinueAfterEndOfPattern: boolean);
    function HexStrToStr(const AHexStr: string): string;

    //Handlers
    procedure ClearLineBreaksBetweenXMLCells;
    procedure ConvertFromDelphiStringCode;
    procedure ConvertToDelphiStringCode;
    procedure ReplaceEditBreakLinesByCodeBreakLines;
    procedure FindAllSubStrings;
    procedure GenerateAllFuncCombinations;
    procedure GenerateCirclingText;
    procedure AppendIndexForSearchWord;
    procedure DeleteSubstrAfterFoundWord;
    procedure FormatSQL;
    procedure FormatXMLByTabs;
    procedure FormatXMLTextByTabs;
    procedure HexTextToText;
    procedure HexTextToTextInXMLNode;
    procedure SortStringList;
    procedure ReplaceTabsBySpaces;
    procedure ToLowerCase;
    procedure GetMask;
    procedure CalcIntegerHash;
    procedure FormatNowByMask;
    procedure SortBlocksStartWith;
    procedure TrimWriteTptTabs;
    procedure ExecStringFunction;
    procedure InverseByteOrderHex;
    procedure ConvertNumberToBase;
  public
    { Public declarations }
  end;

var
  frmTextEditor: TfrmTextEditor;

implementation

{$R *.dfm}

uses
  StrUtils, Types,
  UBHashTable,
  UFunctionTextGenerator, UUtils, UTypes;

procedure TfrmTextEditor.AppendIndexAndAddToResult(
  const AFindText: string; ARow, ACol: integer;
  var AContinueAfterEndOfPattern: boolean);
var
  src: string;
  lastSrc: string;
begin
  AContinueAfterEndOfPattern := true;
  src := memEdit.Lines[ARow];
  if FLastRow <> ARow then begin
    if FLastRow <> -1 then begin
      lastSrc := memEdit.Lines[FLastRow];
      memResult.Lines.Add(
        FRowStringForResult +
        Copy(lastSrc, FLastCol + Length(AFindText), Length(lastSrc)));
    end;
    FRowStringForResult := Copy(src, 1, ACol - 1);
    FLastRow := ARow;
  end
  else begin
    FRowStringForResult :=
      FRowStringForResult +
      Copy(
        src, FLastCol + Length(AFindText), ACol - FLastCol - Length(AFindText));
  end;
  FLastCol := ACol;

  FRowStringForResult :=
    FRowStringForResult + AFindText + IntToStr(FPatternIndex);
  Inc(FPatternIndex);
end;


procedure TfrmTextEditor.AppendIndexForSearchWord;
var
  lastSrc: string;
begin
  if not TryStrToInt(edArg2.Text, FPatternIndex) then
    Exit;

  memResult.Clear;

  FLastRow := -1;
  FLastCol := -1;
  FRowStringForResult := '';

  FindAndHandleAllPatterns(edArg1.Text, AppendIndexAndAddToResult);

  if FLastRow <> -1 then begin
    lastSrc := memEdit.Lines[FLastRow];
    memResult.Lines.Add(
      FRowStringForResult +
      Copy(lastSrc, FLastCol + Length(edArg1.Text), Length(lastSrc)));
  end;
end;


procedure TfrmTextEditor.btnExecuteClick(Sender: TObject);
begin
  FHandlers[cbChangeMethod.ItemIndex].Handler;
end;


procedure TfrmTextEditor.btnReplaceClick(Sender: TObject);
var
  txt: string;
  fintTxt: string;
  replaceTxt: string;
begin
  txt := memEdit.Lines.Text;
  fintTxt := edFindText.Text;
  replaceTxt := edReplaceBy.Text;
  if cbFindSpecDelphi.Checked then
    fintTxt := ConvertDelphiCodeToString(fintTxt);
  if cbReplaceSpecDelphi.Checked then
    replaceTxt := ConvertDelphiCodeToString(replaceTxt);
  memEdit.Lines.Text := StringReplace(txt, fintTxt, replaceTxt, [rfReplaceAll]);
end;


procedure TfrmTextEditor.Button1Click(Sender: TObject);
begin
  memEdit.SelText := memResult.Text;
  memEdit.SetFocus;
  memEdit.SelStart := 0;
  memEdit.SelLength := Length(memResult.Text) - 1;
end;


procedure TfrmTextEditor.Button1KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #9 then begin
    (Sender as TMemo).SelStart := 0;
    (Sender as TMemo).SelLength := 200;
  end;

end;


function LookupValuesAsArray(const ALookupValues: string): TStringDynArray;
var
  sl: TStringList;
  i: integer;
begin
  Result := nil;
  sl := TStringList.Create;
  try
    sl.Delimiter := ',';
    sl.QuoteChar := '"';
    sl.StrictDelimiter := true;
    sl.DelimitedText := ALookupValues;
    SetLength(Result, sl.Count);
    for i := 0 to sl.Count - 1 do
      Result[i] := sl[i];
  finally
    sl.Free;
  end;
end;


procedure TfrmTextEditor.CalcIntegerHash;
var
  st: integer;
  fn: integer;
  i: integer;
  numStr: string;
  sum: double;
  k: integer;
  num: integer;
begin
  if
    (not TryStrToInt(edArg1.Text, st)) or (not TryStrToInt(edArg2.Text, fn))
  then begin
    memResult.Lines.Text := 'Non-integer Args!';
    Exit;
  end;

  sum := 0;
  for i := 0 to memEdit.Lines.Count - 1 do begin
    numStr := Copy(memEdit.Lines[i], st, fn - st + 1);
    for k := 1 to Length(numStr) do begin
      if not TryStrToInt(numStr[k], num) then begin
        memResult.Lines.Text := 'Non-integer character in range!';
        Exit;
      end;

      sum := sum + num;
    end;
  end;

  memResult.Lines.Text := FloatToStr(sum);
end;


procedure TfrmTextEditor.ClearLineBreaksBetweenXMLCells;
var
  newSL: TStringList;
  i, k: integer;
  s: string;
begin
  newSL := TStringList.Create;
  try
    for i := 0 to memEdit.Lines.Count - 1 do begin
      k := Pos('<tr>', memEdit.Lines[i]);
      if k > 0 then
        s := memEdit.Lines[i]
      else begin
        k := Pos('<td>', memEdit.Lines[i]);
        if k > 0 then
          s := s + Copy(memEdit.Lines[i], k, Length(memEdit.Lines[i]))
        else begin
          k := Pos('</tr>', memEdit.Lines[i]);
          if k > 0 then begin
            s := s + '</tr>';
            newSL.Add(s);
            s := '';
          end
          else
            newSL.Add(memEdit.Lines[i]);
        end;
      end;
    end;
    memEdit.Lines.Text := newSL.Text;
  finally
    newSL.Free;
  end;
end;


function TfrmTextEditor.ConvertDelphiCodeToString(const ACode: string): string;
var
  i: integer;
  len: integer;
  isString: boolean;
  isSpec: boolean;
  codeStr: string;
  aposBegin: boolean;
begin
  Result := '';
  len := Length(ACode);
  i := 1;
  isString := false;
  isSpec := false;
  aposBegin := false;
  codeStr := '';
  while i <= len do begin
    if isSpec then begin
      if ACode[i] in ['0'..'9'] then
        codeStr := codeStr + ACode[i]
      else begin
        Result := Result + Chr(StrToInt(codeStr));
        codeStr := '';
        isSpec := false;
      end;
    end;

    if not isSpec then begin
      if ACode[i] = '''' then begin
        if isString then
          if not aposBegin then
            aposBegin := true
          else begin
            Result := Result + '''';
            aposBegin := false;
          end
        else
          isString := true;
        //isString := not isString;
      end
      else if aposBegin then begin
        isString := false;
        aposBegin := false;
      end
      else if isString then
        Result := Result + ACode[i];
      if (not isString) and (ACode[i] = '#') then
        isSpec := true;
    end;

    Inc(i);
  end;

  if codeStr <> '' then
    Result := Result + Chr(StrToInt(codeStr));
end;


procedure TfrmTextEditor.ConvertFromDelphiStringCode;
var
  i: integer;
  s: string;
  ps: integer;
  prefix: string;
  pLen: integer;
  ident: string;
  new: string;
  cPos: integer;
begin
  memResult.Clear;
  prefix := edArg1.Text;
  pLen := Length(prefix);
  for i := 0 to memEdit.Lines.Count - 1 do begin
    s := memEdit.Lines[i];
    ps := Pos('''', s);
    if ps > 0 then
      System.Delete(s, ps, 1);
    ps := LastPos(''' +', s);
    if ps > 0 then
      System.Delete(s, ps, 3)
    else begin
      ps := LastPos('''', s);
      if ps > 0 then
        System.Delete(s, ps, 1)
    end;

    s := StringReplace(s, ''' + ', '', [rfReplaceAll]);
    s := StringReplace(s, ' + ''', '', [rfReplaceAll]);
    s := StringReplace(s, '''''', '''', [rfReplaceAll]);

    while true do begin
      ps := Pos(prefix, s);
      if ps = 0 then
        break;
      ident := NextIdent(s, ps, cPos);
      new := Copy(ident, pLen + 1, MaxInt);
      new := StringReplace(new, '_', '', [rfReplaceAll]);
      s := StringReplace(s, ident, new, [rfReplaceAll]);
    end;
    memResult.Lines.Add(s);
  end;
end;


procedure TfrmTextEditor.ConvertNumberToBase;
var
  srcBase: integer;
  dstBase: integer;
  srcStr: string;
  number: TSNumber;
begin
  srcBase := StrToIntDef(edArg1.Text, 2);
  dstBase := StrToIntDef(edArg2.Text, 10);
  srcStr := Trim(memEdit.Lines.Text);
  number := TSNumber.Create(srcBase, srcStr);
  number.ConvertTo(dstBase);
  memResult.Lines.Text := number.AsString;
end;


procedure TfrmTextEditor.ConvertToDelphiStringCode;
var
  i: integer;
  s: string;
begin
  memResult.Clear;
  for i := 0 to memEdit.Lines.Count - 1 do begin
    s :=
      '''' +
      StringReplace(memEdit.Lines[i], '''', '''''', [rfReplaceAll]) +
      ''' +';
    memResult.Lines.Add(s);
  end;
end;


procedure TfrmTextEditor.DeleteSubstrAfterFoundWord;
var
  lastSrc: string;
begin
  if not TryStrToInt(edArg2.Text, FLettersCount) then
    Exit;

  memResult.Clear;

  FLastRow := -1;
  FLastCol := -1;
  FRowStringForResult := '';

  FindAndHandleAllPatterns(edArg1.Text, DeleteSubstrAndAddToResult);

  if FLastRow <> -1 then begin
    lastSrc := memEdit.Lines[FLastRow];
    memResult.Lines.Add(
      FRowStringForResult +
      Copy(
        lastSrc, FLastCol + Length(edArg1.Text) + FLettersCount,
        Length(lastSrc)));
  end;
end;


procedure TfrmTextEditor.DeleteSubstrAndAddToResult(
  const AFindText: string; ARow, ACol: integer;
  var AContinueAfterEndOfPattern: boolean);
var
  src: string;
  lastSrc: string;
  st: integer;
begin
  AContinueAfterEndOfPattern := true;
  src := memEdit.Lines[ARow];
  if FLastRow <> ARow then begin
    if FLastRow <> -1 then begin
      lastSrc := memEdit.Lines[FLastRow];
      memResult.Lines.Add(
        FRowStringForResult +
        Copy(
          lastSrc, FLastCol + Length(AFindText) + FLettersCount, Length(lastSrc)
        ));
    end;
    FRowStringForResult := Copy(src, 1, ACol - 1);
    FLastRow := ARow;
  end
  else begin
    st := FLastCol + Length(AFindText) + FLettersCount;
    FRowStringForResult := FRowStringForResult + Copy(src, st, ACol - st);
  end;
  FLastCol := ACol;

  FRowStringForResult := FRowStringForResult + AFindText;
end;


procedure TfrmTextEditor.edSpacesInTabKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Shift = []) or (Shift = [ssShift]) then
    if (not (Chr(Key) in ['0'..'9'])) or (Shift = [ssShift]) then
      Key := 0;
end;


procedure TfrmTextEditor.ExecStringFunction;
var
  funcName: string;

  function isFunc(const AFuncName: string): boolean;
  begin
    Result := SameText(funcName, AFuncName);
  end;

var
  src: string;
  res: string;
begin
  funcName := edFuncName.Text;
  src := memEdit.Lines.Text;
  res := '';

  if isFunc('LowerCase') then
    res := LowerCase(src)
  else if isFunc('UpperCase') then
    res := UpperCase(src);

  memResult.Lines.Text := res;
end;


procedure TfrmTextEditor.FindAndHandleAllPatterns(
  const AFindText: string; AFoundStringHandler: TFoundStringHandler);
var
  i, k: integer;
  txt: string;
  lastPos: integer;
  continueAfterEndOfPattern: boolean;
begin
  continueAfterEndOfPattern := false;
  for i := 0 to memEdit.Lines.Count - 1 do begin
    lastPos := 0;
    k := 1;
    while k > 0 do begin
      txt := Copy(memEdit.Lines[i], lastPos + 1, Length(memEdit.Lines[i]));
      k := Pos(AFindText, txt);
      if k > 0 then begin
        lastPos := lastPos + k;
        AFoundStringHandler(AFindText, i, lastPos, continueAfterEndOfPattern);
        if continueAfterEndOfPattern then
          lastPos := lastPos + Length(AFindText) - 1;
      end;
    end;
  end;
end;


procedure TfrmTextEditor.FindAllSubStrings;

  procedure findAllPatterns1(const AFindText: string);
  var
    i, k: integer;
    txt: string;
    lastPos: integer;
    was: boolean;
  begin
    was := false;
    for i := 0 to memEdit.Lines.Count - 1 do begin
      lastPos := 0;
      k := 1;
      while k > 0 do begin
        txt := Copy(memEdit.Lines[i], lastPos + 1, Length(memEdit.Lines[i]));
        k := Pos(AFindText, txt);
        if k > 0 then begin
          if not was then begin
            memResult.Lines.Add('Entries for "' + AFindText + '":');
            was := true;
          end;
          lastPos := lastPos + k;
          memResult.Lines.Add(
            Format(#9'(%d:%d): %s', [i + 1, lastPos, memEdit.Lines[i]]));
        end;
      end;
    end;

  end;

var
  txt: string;
  fintTxt: string;
  i, j: integer;
  curFindText: string;
  textParts: IBHashTable;
begin
  txt := memEdit.Lines.Text;
  fintTxt := edFindText.Text;
  memResult.Clear;
  textParts := TBHashTable.Create;
  for i := 1 to Length(fintTxt) do begin
    for j := Length(fintTxt) downto i do begin
      curFindText := Copy(fintTxt, i, j - i + 1);
      if not textParts.Exists(curFindText) then begin
        findAllPatterns1(curFindText);
        textParts[curFindText] := 1;
      end;
    end;
  end;
end;


procedure TfrmTextEditor.FormatNowByMask;
begin
  memResult.Lines.Text := FormatDateTime(memEdit.Lines.Text, Now);
end;


procedure TfrmTextEditor.FormatSQL;
var
  sql: string;
  res: string;
  ident: string;
  cPos: integer;
  lPos: integer;
begin
  memResult.Clear;
  sql := memEdit.Text;
  res := '';
  lPos := 1;
  ident := NextIdent(sql, lPos, cPos);
  while ident <> '' do begin
    res := res + Copy(sql, lPos, cPos - lPos);
    if
      MatchText(
        ident,
        ['SELECT', 'FROM', 'WHERE', 'GROUP', 'UNION', 'ORDER', 'HAVING']
      )
    then
      res := res + #13#10;
    res := res + ident;
    lPos := cPos + Length(ident);
    ident := NextIdent(sql, lPos, cPos);
  end;
  res := res + Copy(sql, lPos, MaxInt);
  memResult.Text := res;
end;


procedure TfrmTextEditor.FormatXMLByTabs;
var
  depth: integer;
  effDepth: integer;
  tags: TStringList;
  i, k, j: integer;
  tag: string;
  s: string;
  readTag: boolean;
  tagBegun: boolean;
  closingTag: boolean;
  tagContinue: boolean;
  bk, ek: integer;
begin
  memResult.Clear;
  depth := 0;
  tags := TStringList.Create;
  try
    for i := 0 to memEdit.Lines.Count - 1 do begin
      s := memEdit.Lines[i];
      k := Pos('<?xml', s);
      if k > 0 then
        effDepth := depth
      else begin
        j := 1;
        readTag := false;
        tagBegun := false;
        closingTag := false;
        tagContinue := false;

        bk := Pos('<', s);
        ek := Pos('</', s);
        if (bk > 0) and (bk <> ek) and (ek > 0) then
          effDepth := depth
        else if (bk > 0) and (bk <> ek) then begin
          effDepth := depth;
          Inc(depth);
        end
        else if ek > 0 then begin
          Dec(depth);
          effDepth := depth;
        end
        else
          effDepth := depth;

      end;
      memResult.Lines.Add(StringOfChar(#9, effDepth) + s);
    end;
  finally
    tags.Free;
  end;
end;


procedure TfrmTextEditor.FormatXMLTextByTabs;
var
  depth: integer;
  effDepth: integer;
  tags: TStringList;
  i, k, j: integer;
  tag: string;
  s: string;
  readTag: boolean;
  tagBegun: boolean;
  closingTag: boolean;
  tagContinue: boolean;
  bk, ek: integer;
  xml: string;
  st: integer;
begin
  memResult.Clear;
  depth := 0;
  tags := TStringList.Create;
  try
    xml := memEdit.Lines.Text;
    st := Pos('<?xml', xml);
    if st = 0 then
      st := 1
    else
      st := Pos('>', xml) + 1;
    while true do begin

    end;

    for i := 0 to memEdit.Lines.Count - 1 do begin
      s := memEdit.Lines[i];
      k := Pos('<?xml', s);
      if k > 0 then
        effDepth := depth
      else begin
        j := 1;
        readTag := false;
        tagBegun := false;
        closingTag := false;
        tagContinue := false;

        bk := Pos('<', s);
        ek := Pos('</', s);
        if (bk > 0) and (bk <> ek) and (ek > 0) then
          effDepth := depth
        else if (bk > 0) and (bk <> ek) then begin
          effDepth := depth;
          Inc(depth);
        end
        else if ek > 0 then begin
          Dec(depth);
          effDepth := depth;
        end
        else
          effDepth := depth;

      end;
      memResult.Lines.Add(StringOfChar(#9, effDepth) + s);
    end;
  finally
    tags.Free;
  end;
end;


procedure TfrmTextEditor.FormCreate(Sender: TObject);
var
  i: integer;
begin
  inherited;
  FHandlers := GetHandlers;
  cbChangeMethod.Clear;
  for i := Low(FHandlers) to High(FHandlers) do
    cbChangeMethod.AddItem(FHandlers[i].Name, nil);
  cbChangeMethod.ItemIndex := 0;

  UpdateTextLengthLabel;
end;


procedure TfrmTextEditor.GenerateAllFuncCombinations;
var
  func: TFuncArg;
begin
  func.Name := 'JOIN';
  SetLength(Func.Args, 3);

  func.Args[0].Name := 'VAL';
  SetLength(Func.Args[0].Args, 2);

  func.Args[0].Args[0].Name := 'VAL';
  SetLength(Func.Args[0].Args[0].Args, 1);

  func.Args[0].Args[0].Args[0].Name := 'word_id';

  func.Args[0].Args[1].Name := 'VAL';
  SetLength(Func.Args[0].Args[1].Args, 1);

  func.Args[0].Args[1].Args[0].Name := 'word_id';

  func.Args[1].Name := 'VAL';
  SetLength(Func.Args[1].Args, 2);

  func.Args[1].Args[0].Name := 'VAL';
  SetLength(Func.Args[1].Args[0].Args, 1);

  func.Args[1].Args[0].Args[0].Name := 'word_id';

  func.Args[1].Args[1].Name := 'VAL';
  SetLength(Func.Args[1].Args[1].Args, 1);

  func.Args[1].Args[1].Args[0].Name := 'word_id';

  func.Args[2].Name := 'VAL';
  SetLength(Func.Args[2].Args, 2);

  func.Args[2].Args[0].Name := 'VAL';
  SetLength(Func.Args[2].Args[0].Args, 1);

  func.Args[2].Args[0].Args[0].Name := 'word_id';

  func.Args[2].Args[1].Name := 'VAL';
  SetLength(Func.Args[2].Args[1].Args, 1);

  func.Args[2].Args[1].Args[0].Name := 'word_id';

  memResult.Clear;
  //AddAllCombinationsForFunction(func, memResult.Lines);
end;


procedure TfrmTextEditor.GenerateCirclingText;
var
  i, j: integer;
  n: integer;
  c: char;
  s: string;
  sn: integer;
  cn: integer;
  spn: integer;
  yn: integer;
begin
  memEdit.Clear;
  if edArg1.Text <> '' then
    c := edArg1.Text[1]
  else
    c := '1';
  n := StrToIntDef(edArg2.Text, 0);
  memEdit.Font.Size := StrToIntDef(edArg3.Text, 8);
  sn := ((n + 1) * n);// div 2;
  s := '';
  spn := 0;
  memEdit.Lines.Add(StringOfChar(c, sn) + StringOfChar(c, sn));
  for i := n downto 0 do begin
    spn := spn + i;
    cn := sn - spn;

    s :=
      StringOfChar(c, cn) + StringOfChar(' ', spn) +
      StringOfChar(' ', spn) + StringOfChar(c, cn);
    memEdit.Lines.Add(s);
  end;
  yn := 0;
  for i := 0 to n do begin
    cn := sn - spn;
    yn := yn + i;
    for j := 1 to i do begin
      s :=
        StringOfChar(c, cn) + StringOfChar(' ', spn) +
        StringOfChar(' ', spn) + StringOfChar(c, cn);
      memEdit.Lines.Add(s);
    end;

    Inc(spn);
  end;
{
  for i := 1 to n do begin
    s := s + StringOfChar(c, i);
    memEdit.Lines.Add(s);
  end;
  }
end;


function TfrmTextEditor.GetHandlers: TNamedHandlers;
begin
  SetLength(Result, 23);

  Result[0].Name := 'Clear <br/> between XML cells';
  Result[0].Handler := ClearLineBreaksBetweenXMLCells;

  Result[1].Name := 'Replace #32#10 by #10';
  Result[1].Handler := ReplaceEditBreakLinesByCodeBreakLines;

  Result[2].Name := 'Find all substrings';
  Result[2].Handler := FindAllSubStrings;

  Result[3].Name := 'Generate all func combinations (not work yet)';
  Result[3].Handler := GenerateAllFuncCombinations;

  Result[4].Name := 'Append index for find word';
  Result[4].Handler := AppendIndexForSearchWord;

  Result[5].Name := 'Delete substring after found words';
  Result[5].Handler := DeleteSubstrAfterFoundWord;

  Result[6].Name := 'Format XML By Tabs';
  Result[6].Handler := FormatXMLByTabs;

  Result[7].Name := 'Hex text to readable text';
  Result[7].Handler := HexTextToText;

  Result[8].Name := 'Format SQL';
  Result[8].Handler := FormatSQL;

  Result[9].Name := 'Generate circling text';
  Result[9].Handler := GenerateCirclingText;

  Result[10].Name := 'Convert to delphi string code';
  Result[10].Handler := ConvertToDelphiStringCode;

  Result[11].Name := 'Convert from delphi string code';
  Result[11].Handler := ConvertFromDelphiStringCode;

  Result[12].Name := 'Sort string list';
  Result[12].Handler := SortStringList;

  Result[13].Name := 'Replace TABs by spaces';
  Result[13].Handler := ReplaceTabsBySpaces;

  Result[14].Name := 'To lower case';
  Result[14].Handler := ToLowerCase;

  Result[15].Name := 'Get mask';
  Result[15].Handler := GetMask;

  Result[16].Name := 'Calc integer hash';
  Result[16].Handler := CalcIntegerHash;

  Result[17].Name := 'Format current date time by Mask';
  Result[17].Handler := FormatNowByMask;

  Result[18].Name := 'Sort blocks which start with substring';
  Result[18].Handler := SortBlocksStartWith;

  Result[19].Name := 'Trim write tabs in tpt';
  Result[19].Handler := TrimWriteTptTabs;

  Result[20].Name := 'Exec string function';
  Result[20].Handler := ExecStringFunction;

  Result[21].Name := 'Inverse byte order (HEX format)';
  Result[21].Handler := InverseByteOrderHex;

  Result[22].Name := 'Convert Number To Base';
  Result[22].Handler := ConvertNumberToBase;
end;


procedure TfrmTextEditor.GetMask;
var
  s: string;
  res: string;
  i, j: integer;
begin
  res := '';
  if memEdit.Lines.Count > 0 then
    res := memEdit.Lines[0];

  for i := 1 to memEdit.Lines.Count - 1 do begin
    s := memEdit.Lines[i];
    for j := 1 to Length(res) do begin
      if res[j] <> s[j] then
        res[j] := '*';
    end;
  end;

  memResult.Lines.Text := res;
end;


function TfrmTextEditor.HexStrToStr(const AHexStr: string): string;
const
  CODE_MAPPER: array ['A'..'F'] of integer = (10, 11, 12, 13, 14, 15);

  function hexCharToInt(AChar: char): integer;
  begin
    if not TryStrToInt(AChar, Result) then
      Result := CODE_MAPPER[UpperCase(AChar)[1]];
  end;

  function tryHexStrToChar(const AHexStr: string): boolean;
  begin
    Result := false;
  end;
  
var
  code: integer;
  i: integer;
begin
  i := 1;
  Result := '';
  while i <= Length(AHexStr) do begin
    code := hexCharToInt(AHexStr[i]) * 16 + hexCharToInt(AHexStr[i + 1]);
    Result := Result + Chr(code);
    Inc(i, 2);
  end;
end;


procedure TfrmTextEditor.HexTextToText;
begin
  memResult.Lines.Text := HexStrToStr(memEdit.Lines.Text);
end;


procedure TfrmTextEditor.HexTextToTextInXMLNode;
var
  src: string;
  tagStart: string;
  tagEnd: string;
  st: integer;
  fn: integer;
  hexStr: string;
begin
  if edArg1.Text = '' then
    Exit;
  src := memEdit.Lines.Text;
  tagStart := '<' + edArg1.Text + '>';  
  tagEnd := '</' + edArg1.Text + '>';

  st := 1;
  while true do begin
    st := PosEx(tagStart, src, st);
    if st > 0 then begin
      fn := PosEx(tagStart, src, st);
      if fn > 0 then begin
        //TODO: 
      end
      else
        break;
    end
    else
      break;
  end;
end;



procedure TfrmTextEditor.InverseByteOrderHex;

  procedure exchangeChars(var AStr: string; AIdx1, AIdx2: integer);
  var
    t: char;
  begin
    t := AStr[AIdx1];
    AStr[AIdx1] := AStr[AIdx2];
    AStr[AIdx2] := t;
  end;

var
  line: string;
  i: integer;
begin
  if memEdit.Lines.Count = 0 then
    Exit;

  line := memEdit.Lines[0];
  if Length(line) mod 2 <> 0 then
    Exit;

  for i := 0 to Length(line) div 4 - 1 do begin
    exchangeChars(line, i * 2 + 1, Length(line) - i * 2 - 1);
    exchangeChars(line, i * 2 + 2, Length(line) - i * 2);
  end;

  memResult.Lines.Text := line;
end;


procedure TfrmTextEditor.memEditChange(Sender: TObject);
begin
  UpdateTextLengthLabel;
end;

{
qqwertyui
qwert
qwert
jdfhjgfjh
fjhkgjhkgkh
fjhkfghkg
fgjhgkhgk
                      fghgh
}
procedure TfrmTextEditor.memEditKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);

  function deleteTabOrSpaces(const AStr: string): string;
  var
    tp: integer;
    i: integer;
    spInTab: integer;
  begin
    Result := AStr;
    if AStr = ''  then
      Exit;

    tp := Pos(#9, AStr);
    if (tp > 0) and (Copy(AStr, 1, tp - 1) =  StringOfChar(' ', tp - 1)) then
    begin
      Result := StringOfChar(' ', tp - 1) + Copy(AStr, tp + 1, Length(AStr));
    end
    else begin
      spInTab := StrToIntDef(edSpacesInTab.Text, 1);
      i := 0;
      while i < spInTab do begin
        if AStr[i + 1] = ' ' then
          Inc(i)
        else
          break;
      end;
      Result := Copy(AStr, i + 1, Length(AStr));
    end;
  end;

var
  lines: TStringList;
  i: integer;
  //edit: TMemo;
  edit: TRichEdit;
  selStart: integer;
begin
  edit := Sender as TRichEdit;
  if (Key = VK_TAB) and (edit.SelText <> '') then begin
    selStart := edit.SelStart;
    lines := TStringList.Create;
    try
      lines.Text := edit.SelText;
      for i := 0 to lines.Count - 1 do
        if Shift = [ssShift] then begin
          lines[i] := deleteTabOrSpaces(lines[i]);
        end
        else if Shift = [] then
          lines[i] := #9 + lines[i];

      //edit.sel
      edit.SelText := lines.Text;
      edit.SelStart := selStart;
      edit.SelLength := Length(lines.Text);
      Key := 0;
    finally
      lines.Free;
    end;
  end;
  if (Chr(Key) = 'A') and (Shift = [ssCtrl])then begin
    edit.SelectAll;
    // := 0;
    //edit.SelLength := Length(edit.Text);
    Key := 0;
  end;
end;


procedure TfrmTextEditor.ReplaceEditBreakLinesByCodeBreakLines;
begin
  memEdit.Lines.Text :=
    StringReplace(memEdit.Lines.Text, #13#10, #10, [rfReplaceAll]);
end;


procedure TfrmTextEditor.ReplaceTabsBySpaces;
var
  spCount: integer;
  spaces: string;
begin
  spCount := StrToIntDef(edSpacesInTab.Text, 0);
  spaces := StringOfChar(' ', spCount);
  memResult.Lines.Text :=
    StringReplace(memEdit.Lines.Text, #9, spaces, [rfReplaceAll]);
end;


procedure TfrmTextEditor.SortBlocksStartWith;

  function getBlock(
    const ASource, ASubStr: string; AFrom: integer;
    out ABlock: string): integer;
  var
    ps: integer;
  begin
    ps := PosEx(ASubStr, ASource, AFrom);
//    if True then

  end;

var
  source: string;
  findTxt: string;
  sl: TStringList;
  ps: integer;
  next: integer;
  block: string;
  firstBlock: string;
  res: string;
begin
  source := memEdit.Lines.Text;
  findTxt := edFindText.Text;

  sl := TStringList.Create;
  try
    firstBlock := '';
    ps := PosEx(findTxt, source, 1);
    if ps > 0 then
      firstBlock := Copy(source, 1, ps - 1);
    //next := 1;
    while ps > 0 do begin
      //ps := PosEx(findTxt, source, next);
      next := PosEx(findTxt, source, ps + 1);
      if next > 0 then begin
        block := Copy(source, ps, next - ps);
        sl.Add(block);
        ps := next;
      end
      else begin
        block := Copy(source, ps, System.MaxInt);
        sl.Add(block);
        Break;
      end;
    end;

    sl.Sort;
    res := firstBlock;
    for block in sl do
      res := res + block;

    memResult.Lines.Text := res;
  finally
    sl.Free;
  end;
end;


procedure TfrmTextEditor.SortStringList;
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.Assign(memEdit.Lines);
    sl.CaseSensitive := true;
    sl.Sort;
    memResult.Lines.Assign(sl);
  finally
    sl.Free;
  end;
end;


procedure TfrmTextEditor.ToLowerCase;
var
  st, fn: integer;
  s: string;
begin
  st := StrToIntDef(edArg1.Text, 1);
  fn := StrToIntDef(edArg2.Text, MaxInt);
  s := memEdit.Lines.Text;
  memResult.Lines.Text :=
    Copy(s, 1, st - 1) + LowerCase(Copy(s, st, fn - st + 1));
  if fn <> MaxInt then
    memResult.Lines.Text := memResult.Lines.Text + Copy(s, fn + 1, MaxInt);
end;


procedure TfrmTextEditor.TrimWriteTptTabs;
var
  i: integer;
  s: string;
  isTable: boolean;
  j: integer;
  line: TStringList;
  colCount: integer;
begin
  memResult.Clear;
  isTable := false;
  line := TStringList.Create;
  try
    line.Delimiter := #9;
    line.StrictDelimiter := true;

    for i := 0 to memEdit.Lines.Count - 1 do begin
      s := memEdit.Lines[i];
      if isTable then
        isTable := (Pos('[', s) <> 1);

      if not isTable then begin
        for j := Length(s) downto 1 do
          if s[j] = #9 then
            System.Delete(s, j, 1)
          else
            Break;
      end
      else begin
        line.DelimitedText := s;
        for j := line.Count - 1 downto colCount do
          line.Delete(j);
        s := line.DelimitedText;
      end;

      memResult.Lines.Add(s);

      if not isTable then begin
        isTable :=
          (s <> '') and (Pos('//', s) <> 1) and (Pos('[', s) <> 1) and
          (Pos('=', s) = 0);
        if isTable then begin
          line.DelimitedText := s;
          colCount := line.Count;
        end;
      end;
    end;
  finally
    line.Free;
  end;
end;


procedure TfrmTextEditor.UpdateTextLengthLabel;
begin
  lblTextLength.Caption := 'Length: ' + IntToStr(Length(memEdit.Lines.Text));
end;


end.

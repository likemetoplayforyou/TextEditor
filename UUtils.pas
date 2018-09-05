unit UUtils;

interface

  function LastPos(const ASubStr, AStr: string): integer;
  function NextIdent(
    const AText: string; AFrom: integer; out APos: integer): string;

implementation

uses
  StrUtils;


function LastPos(const ASubStr, AStr: string): integer;
begin
  Result := Pos(ReverseString(ASubStr), ReverseString(AStr));

  if (Result <> 0) then
   Result := ((Length(AStr) - Length(ASubStr)) + 1) - Result + 1;
end;


function NextIdent(
  const AText: string; AFrom: integer; out APos: integer): string;
var
  i: integer;
  n: integer;
  was: boolean;
begin
  Result := '';
  APos := 0;
  was := false;
  i := AFrom;
  n := Length(AText);
  while i <= n do begin
    if AText[i] in ['A'..'Z', 'a'..'z', '_'] then begin
      if not was then begin
        if
          (i = 1) or not (AText[i - 1] in ['A'..'Z', 'a'..'z', '0'..'9', '_'])
        then begin
          was := true;
          APos := i;
        end;
      end;
    end
    else if not (AText[i] in ['0'..'9']) and was then begin
      Result := Copy(AText, APos, i - APos);
      break;
    end;
    Inc(i);
  end;
end;


end.

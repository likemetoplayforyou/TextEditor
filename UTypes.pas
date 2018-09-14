unit UTypes;

interface

uses
  Types;

type
  TBigInt = record
  private
    FSign: boolean;
    FData: TCardinalDynArray;
  public
    class operator Implicit(const AValue: integer): TBigInt; overload;
  end;


  TRational = record
  private
    FIntPart: integer;
    FNumerator: integer;
    FDenominator: integer;

    procedure Reduce(var ANum1, ANum2: integer); overload;
    procedure Reduce; overload;
  public
    constructor Create(
      AIntPart: integer; ANumerator: integer = 0; ADenominator: integer = 1);

    procedure Negative; overload;
    function LessThan(const AValue: TRational): boolean; overload;
    procedure Add(const AValue: TRational); overload;
    procedure Add(AValue: integer); overload;
    procedure Subtract(const AValue: TRational); overload;
    procedure Multiply(AMultiplier: integer); overload;
    procedure Divide(ADivider: integer); overload;

    class operator Implicit(const AValue: integer): TRational; overload;
    class operator Negative(AValue: TRational): TRational; overload;
    class operator LessThan(
      const AValue1, AValue2: TRational): boolean; overload;
    class operator Add(const AValue1, AValue2: TRational): TRational; overload;
    class operator Subtract(
      const AValue1, AValue2: TRational): TRational; overload;
    class operator Multiply(
      const AValue1: TRational; const AValue2: integer): TRational;
    class operator Divide(
      const ADividend: TRational; const ADivider: integer): TRational; overload;
    class operator IntDivide(
      const ADividend: TRational; const ADivider: integer): TRational;

    property IntPart: integer read FIntPart;
    property Numerator: integer read FNumerator;
    property Denominator: integer read FDenominator;
  end;


  TSNumber = record
  private
    FBase: integer;
    FSign: boolean;
    FIntPart: TByteDynArray;
    FFracPart: TByteDynArray;
    FPeriodPos: integer;

    function GetAsInteger: int64;
    procedure SetAsInteger(AValue: int64);
    function GetAsString: string;
    procedure SetAsString(const AValue: string);
    function GetAsRational: TRational;
    procedure SetAsRational(const AValue: TRational);

    function SignInt: integer;

    procedure TrimParts;
    procedure CheckBaseConstraint;
  public
    constructor Create(ABase: integer; AValue: integer); overload;
    constructor Create(ABase: integer; const AValue: string); overload;

    procedure Clear;

    procedure Assign(const ASource: TSNumber);

    function SafeInt(AIndex: integer): byte;
    function SafeFrac(AIndex: integer): byte;

    procedure Negative; overload;
    function LessThan(const AValue: TSNumber): boolean;
    procedure Add(const AValue: TSNumber); overload;
    procedure Add(AValue: integer); overload;
    procedure Add(const AValue: string); overload;

    procedure Subtract(const AValue: TSNumber);

    procedure Multiply(const AValue: integer);

    procedure Divide(const AValue: TSNumber); overload;
    procedure Divide(AValue: integer); overload;

    procedure ConvertTo(ABase: integer);

    class operator Negative(const AValue: TSNumber): TSNumber; overload;

    property AsInteger: int64 read GetAsInteger write SetAsInteger;
    property AsString: string read GetAsString write SetAsString;
    property AsRational: TRational read GetAsRational write SetAsRational;
  end;


implementation

uses
  SysUtils, Math;

{ TSNumber }

procedure TSNumber.Add(const AValue: TSNumber);
var
  maxLen: integer;
  i: integer;
  overFlow: integer;
  sum: integer;
  selfLess: boolean;
begin
  maxLen := Max(Length(FIntPart), Length(AValue.FIntPart));
  SetLength(FIntPart, maxLen + 1);

  maxLen := Max(Length(FFracPart), Length(AValue.FFracPart));
  SetLength(FFracPart, maxLen);

  selfLess := false;
  if FSign <> AValue.FSign then
    selfLess := LessThan(AValue);

  overFlow := 0;
  for i := High(AValue.FFracPart) downto 0 do begin
    if FSign <> AValue.FSign then begin
      if selfLess then
        sum := AValue.SafeFrac(i) - SafeFrac(i) - overFlow
      else
        sum := SafeFrac(i) - AValue.SafeFrac(i) - overFlow;
    end
    else
      sum := SafeFrac(i) + AValue.SafeFrac(i) + overFlow;

    if sum < 0 then begin
      FFracPart[i] := (FBase + sum) mod FBase;
      overFlow := 1;
    end
    else if sum >= FBase then begin
      FFracPart[i] := sum mod FBase;
      overFlow := 1;
    end
    else begin
      FFracPart[i] := sum;
      overFlow := 0;
    end;
  end;

  for i := 0 to High(FIntPart) do begin
    if FSign <> AValue.FSign then begin
      if selfLess then
        sum := AValue.SafeInt(i) - SafeInt(i) - overFlow
      else
        sum := SafeInt(i) - AValue.SafeInt(i) - overFlow;
    end
    else
      sum := SafeInt(i) + AValue.SafeInt(i) + overFlow;

    if sum < 0 then begin
      FIntPart[i] := (FBase + sum) mod FBase;
      overFlow := 1;
    end
    else if sum >= FBase then begin
      FIntPart[i] := sum mod FBase;
      overFlow := 1;
    end
    else begin
      FIntPart[i] := sum;
      overFlow := 0;
    end;
  end;

  TrimParts;
end;


procedure TSNumber.Add(const AValue: string);
begin

end;


procedure TSNumber.Add(AValue: integer);
var
  value: TSNumber;
begin
  value.FBase := FBase;
  value.AsInteger := AValue;
  Add(value);
end;


procedure TSNumber.Assign(const ASource: TSNumber);
var
  i: integer;
begin
  FBase := ASource.FBase;
  FSign := ASource.FSign;
  SetLength(FIntPart, Length(ASource.FIntPart));
  SetLength(FFracPart, Length(ASource.FFracPart));
  for i := 0 to High(FIntPart) do
    FIntPart[i] := ASource.FIntPart[i];
  for i := 0 to High(FFracPart) do
    FFracPart[i] := ASource.FFracPart[i];
  FPeriodPos := ASource.FPeriodPos;
end;


procedure TSNumber.CheckBaseConstraint;
var
  digit: byte;
begin
  for digit in FIntPart do
    if digit >= FBase then
      raise Exception.CreateFmt('Digit %d >= Base %d', [digit, FBase]);
  for digit in FFracPart do
    if digit >= FBase then
      raise Exception.CreateFmt('Digit %d >= Base %d', [digit, FBase]);
end;


procedure TSNumber.Clear;
begin
  FSign := false;
  SetLength(FIntPart, 0);
  SetLength(FFracPart, 0);
  FPeriodPos := -1;
end;


procedure TSNumber.ConvertTo(ABase: integer);
var
  rational: TRational;
begin
  rational := AsRational;
  FBase := ABase;
  AsRational := rational;
end;


constructor TSNumber.Create(ABase, AValue: integer);
begin
  FBase := ABase;
  AsInteger := AValue;
end;


constructor TSNumber.Create(ABase: integer; const AValue: string);
begin
  FBase := ABase;
  AsString := AValue;
end;


procedure TSNumber.Divide(AValue: integer);
var
  rems: TByteDynArray;

  function remainPos(ARemain: byte): integer;
  var
    i: integer;
  begin
    Result := -1;
    for i := 0 to High(rems) do
      if rems[i] = ARemain then begin
        Result := i;
        Break;
      end;
  end;

var
  i: integer;
  res: TSNumber;
  rem: integer;
begin
  res.Assign(Self);

  SetLength(res.FIntPart, Length(FIntPart));
  rem := 0;
  for i := High(FIntPart) downto 0 do begin
    rem := rem * FBase;
    res.FIntPart[i] := (FIntPart[i] + rem) div AValue;
    rem := (FIntPart[i] + rem) mod AValue;
  end;

  rems := nil;
  i := 0;
  res.FPeriodPos := -1;
  while (i < Length(FFracPart)) or (rem > 0) and (res.FPeriodPos < 0) do begin
    if i >= Length(FFracPart) then begin
      SetLength(rems, Length(rems) + 1);
      rems[High(rems)] := rem;
    end;

    rem := rem * FBase;
    SetLength(res.FFracPart, i + 1);
    res.FFracPart[i] := (SafeFrac(i) + rem) div AValue;
    rem := (SafeFrac(i) + rem) mod AValue;

    res.FPeriodPos := remainPos(rem);

    Inc(i);
  end;

  Assign(res);
  TrimParts;
end;


procedure TSNumber.Divide(const AValue: TSNumber);
begin

end;


function TSNumber.GetAsInteger: int64;
var
  i: integer;
  exp: int64;
begin
  Result := 0;
  exp := 1;
  for i := Low(FIntPart) to High(FIntPart) do begin
    Result := FIntPart[i] * exp;
    exp := exp * FBase;
  end;
end;


function TSNumber.GetAsRational: TRational;
var
  intPart: TRational;
  uniqueFrac: TRational;
  periodFrac: TRational;
  digitPart: TRational;
  periodSum: TRational;
  exp: integer; // TBigInt;
  periodExp: integer; // TBigInt;
  i: integer;
begin
  intPart := TRational.Create(0, 0, FBase);
  for i := High(FIntPart) downto 0 do begin
    intPart.Multiply(FBase);
    intPart.Add(FIntPart[i]);
  end;

  uniqueFrac := TRational.Create(0, 0, FBase);
  exp := 1;
  for i := 0 to High(FFracPart) do begin
    if (FPeriodPos >= 0) and (i >= FPeriodPos) then
      Break;

    exp := exp * FBase;
    digitPart := TRational.Create(0, FFracPart[i], exp);
    uniqueFrac.Add(digitPart);
  end;

  periodFrac := TRational.Create(0, 0, FBase);
  periodExp := 1;
  for i := FPeriodPos to High(FFracPart) do begin
    exp := exp * FBase;
    periodExp := periodExp * FBase;
    digitPart := TRational.Create(0, FFracPart[i], periodExp);
    uniqueFrac.Add(digitPart);
  end;

  periodSum := periodFrac / (exp - 1);

  Result := intPart + uniqueFrac + periodSum;
end;


function TSNumber.GetAsString: string;
var
  i: integer;
begin
  Result := '';
  for i := High(FIntPart) downto Low(FIntPart) do
    Result := Result + IntToStr(FIntPart[i]);

  if Length(FFracPart) > 0 then begin
    if Length(FIntPart) = 0 then
      Result := '0';
    Result := Result + '.';

    for i := Low(FFracPart) to High(FFracPart) do begin
      if i = FPeriodPos then
        Result := Result + '(';
      Result := Result + IntToStr(FFracPart[i]);
    end;
    if FPeriodPos > 0 then
      Result := Result + ')';
  end;

  if Result = '' then
    Result := '0';
end;


function TSNumber.LessThan(const AValue: TSNumber): boolean;
var
  maxLen: integer;
  i: integer;
  selfDigit: byte;
  valDigit: byte;
begin
  Result := false;
  maxLen := Max(Length(FIntPart), Length(AValue.FIntPart));
  for i := maxLen downto 0 do begin
    if i < Length(FIntPart) then
      selfDigit := FIntPart[i]
    else
      selfDigit := 0;
    if i < Length(AValue.FIntPart) then
      valDigit := AValue.FIntPart[i]
    else
      valDigit := 0;
    Result := selfDigit < valDigit;
    if Result then
      Exit;
  end;

  maxLen := Max(Length(FFracPart), Length(AValue.FFracPart));
  for i := 0 to maxLen do begin
    if i < Length(FFracPart) then
      selfDigit := FFracPart[i]
    else
      selfDigit := 0;
    if i < Length(AValue.FFracPart) then
      valDigit := AValue.FFracPart[i]
    else
      valDigit := 0;
    Result := selfDigit < valDigit;
    if Result then
      Exit;
  end;
end;


procedure TSNumber.Multiply(const AValue: integer);
var
  value: TSNumber;
  i: integer;
begin
  value.Assign(Self);

  Clear;
  for i := 1 to Abs(AValue) do
    Add(value);

  FSign := value.FSign <> (AValue < 0);
  TrimParts;
end;


procedure TSNumber.Negative;
begin
  FSign := not FSign;
end;


class operator TSNumber.Negative(const AValue: TSNumber): TSNumber;
begin
  Result.Assign(AValue);
  Result.Negative;
end;


function TSNumber.SafeFrac(AIndex: integer): byte;
begin
  Result := 0;
  if AIndex < Length(FFracPart) then
    Result := FFracPart[AIndex]
end;


function TSNumber.SafeInt(AIndex: integer): byte;
begin
  Result := 0;
  if AIndex < Length(FIntPart) then
    Result := FIntPart[AIndex]
end;


procedure TSNumber.SetAsInteger(AValue: int64);
begin
  Clear;

  while AValue <> 0 do begin
    SetLength(FIntPart, Length(FIntPart) + 1);
	  FIntPart[High(FIntPart)] := AValue mod FBase;
	  AValue := AValue div FBase;
  end;
end;


procedure TSNumber.SetAsRational(const AValue: TRational);
var
  fracNum: TSNumber;
  i: integer;
begin
  SetAsInteger(AValue.IntPart);

  fracNum := TSNumber.Create(FBase, 1);
  fracNum.Divide(AValue.Denominator);
  fracNum.Multiply(AValue.Numerator);

  SetLength(FFracPart, Length(fracNum.FFracPart));
  for i := 0 to High(fracNum.FFracPart) do
    FFracPart[i] := fracNum.FFracPart[i];
end;


procedure TSNumber.SetAsString(const AValue: string);
var
  pti: integer;
  i: integer;
  lbkt: integer;
  rbkt: integer;
begin
  //TODO: number validation, only digits in AValue
  //TODO: check base validness
  Clear;

  pti := Pos('.', AValue);
  if pti > 0 then begin
    SetLength(FIntPart, pti - 1);
    SetLength(FFracPart, Length(AValue) - pti);
    for i := 1 to pti - 1 do
      FIntPart[pti - i - 1] := StrToInt(AValue[i]);
    for i := pti + 1 to Length(AValue) do
      FFracPart[i - pti - 1] := StrToInt(AValue[i]);
  end
  else begin
    SetLength(FIntPart, Length(AValue));
    for i := 1 to Length(AValue) do
      FIntPart[Length(AValue) - i] := StrToInt(AValue[i]);
  end;

  lbkt := Pos('(', AValue);
  rbkt := Pos(')', AValue);

  if
    (lbkt > 0) and (rbkt <= 0) or (lbkt <= 0) and (rbkt > 0) or
    (rbkt - lbkt < 2) or (pti > lbkt)
  then
    raise Exception.Create('Wrong number format: ''('', '')''');

  if lbkt > 0 then
    FPeriodPos := lbkt - pti - 1;

  CheckBaseConstraint;
end;


function TSNumber.SignInt: integer;
begin
  if FSign then
    Result := -1
  else
    Result := 1;
end;


procedure TSNumber.Subtract(const AValue: TSNumber);
begin
  Add(-AValue);
end;


procedure TSNumber.TrimParts;
var
  nonZeroPos: integer;
  i: integer;
begin
  nonZeroPos := -1;
  for i := High(FIntPart) downto 0 do
    if FIntPart[i] > 0 then begin
      nonZeroPos := i;
      Break;
    end;
  SetLength(FIntPart, nonZeroPos + 1);

  nonZeroPos := -1;
  for i := High(FFracPart) downto 0 do
    if FFracPart[i] > 0 then begin
      nonZeroPos := i;
      Break;
    end;
  SetLength(FFracPart, nonZeroPos + 1);
end;


{ TRational }

class operator TRational.Add(const AValue1, AValue2: TRational): TRational;
begin
  Result := AValue1;
  Result.Add(AValue2);
end;


procedure TRational.Add(const AValue: TRational);
begin
  FNumerator :=
    FNumerator * AValue.FDenominator + AValue.FNumerator * FDenominator;
  FDenominator := FDenominator * AValue.FDenominator;
  FIntPart := FIntPart + AValue.FIntPart + FNumerator div FDenominator;
  FNumerator := FNumerator mod FDenominator;
  Reduce;
end;


procedure TRational.Add(AValue: integer);
begin
  FIntPart := FIntPart + AValue;
end;


constructor TRational.Create(AIntPart, ANumerator, ADenominator: integer);
begin
  Assert(ADenominator <> 0);
  FIntPart := AIntPart + ANumerator div ADenominator;
  FNumerator := ANumerator mod ADenominator;
  FDenominator := ADenominator;
  Reduce;
end;


class operator TRational.Divide(
  const ADividend: TRational; const ADivider: integer): TRational;
begin
  Result := ADividend;
  Result.Divide(ADivider);
end;


procedure TRational.Divide(ADivider: integer);
var
  num: integer;
begin
  Assert(ADivider <> 0);
  num := FIntPart mod ADivider;
  FIntPart := FIntPart div ADivider;
  FNumerator := FNumerator + num * FDenominator;
  FDenominator := FDenominator * ADivider;
  Reduce;
end;


class operator TRational.Implicit(const AValue: integer): TRational;
begin
  Result := TRational.Create(AValue);
end;


class operator TRational.IntDivide(
  const ADividend: TRational; const ADivider: integer): TRational;
begin
  Result := TRational.Create(ADividend.IntPart div ADivider);
end;


function TRational.LessThan(const AValue: TRational): boolean;
var
  cmpRes: TRational;
begin
  cmpRes := Self - AValue;
  Result := (cmpRes.FIntPart + cmpRes.FNumerator < 0);
end;


class operator TRational.LessThan(const AValue1, AValue2: TRational): boolean;
begin
  Result := AValue1.LessThan(AValue2);
end;


class operator TRational.Multiply(
  const AValue1: TRational; const AValue2: integer): TRational;
begin
  Result := AValue1;
  Result.Multiply(AValue2);
end;


procedure TRational.Multiply(AMultiplier: integer);
begin
  FIntPart := FIntPart * AMultiplier;
  Reduce(AMultiplier, FDenominator);
  FNumerator := FNumerator * AMultiplier;
  FIntPart := FIntPart + FNumerator div FDenominator;
  FNumerator := FNumerator mod FDenominator;
  Reduce;
end;


procedure TRational.Negative;
begin
  FIntPart := -FIntPart;
  FNumerator := -FNumerator;
end;


class operator TRational.Negative(AValue: TRational): TRational;
begin
  Result := AValue;
  Result.Negative;
end;


procedure TRational.Reduce;
begin
  Reduce(FNumerator, FDenominator);
end;


procedure TRational.Subtract(const AValue: TRational);
begin
  Add(-AValue);
end;


class operator TRational.Subtract(const AValue1, AValue2: TRational): TRational;
begin
  Result := AValue1;
  Result.Subtract(AValue2);
end;


procedure TRational.Reduce(var ANum1, ANum2: integer);
var
  divident: integer;
  divider: integer;
  rem: integer;
begin
  divident := Max(ANum1, ANum2);
  divider := Min(ANum1, ANum2);

  if divider = 0 then
    Exit;

  rem := divident mod divider;
  while rem <> 0 do begin
    divident := divider;
    divider := rem;
    rem := divident mod divider;
  end;

  ANum1 := ANum1 div divider;
  ANum2 := ANum2 div divider;
end;


{ TBigInt }

class operator TBigInt.Implicit(const AValue: integer): TBigInt;
begin
  SetLength(Result.FData, 1);
  Result.FData[0] := Abs(AValue);
  Result.FSign := AValue < 0;
end;


end.

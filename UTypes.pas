unit UTypes;

interface

uses
  Types;

type
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

    function GetAsInteger: int64;
    procedure SetAsInteger(AValue: int64);
    function GetAsString: string;
    procedure SetAsString(const AValue: string);

    procedure Allac(var AArray: TByteDynArray; const ALength: integer);
  public
    constructor Create(ABase: integer; const AValue: string);

    procedure Clear;

    procedure Assign(const ASource: TSNumber);

    procedure Add(const AValue: TSNumber); overload;
    procedure Add(AValue: integer); overload;
    procedure Add(const AValue: string); overload;

    procedure ConvertTo(ABase: integer);

    property AsInteger: int64 read GetAsInteger write SetAsInteger;
    property AsString: string read GetAsString write SetAsString;

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
  lastNonZero: integer;
  //signMul: integer;
begin
  maxLen := Max(Length(FIntPart), Length(AValue.FIntPart));
  SetLength(FIntPart, maxLen + 1);

  maxLen := Max(Length(FFracPart), Length(AValue.FFracPart));
  SetLength(FFracPart, maxLen);

  overFlow := 0;
  lastNonZero := -1;
  for i := High(AValue.FFracPart) downto 0 do begin
    sum := FFracPart[i] + AValue.FFracPart[i] + overFlow;
    if sum < 10 then begin
      FFracPart[i] := sum;
      overFlow := 0;
    end
    else begin
      FFracPart[i] := sum mod 10;
      overFlow := 1;
    end;

    if (lastNonZero = -1) and (FFracPart[i] <> 0) then
      lastNonZero := i;
  end;
  SetLength(FFracPart, lastNonZero + 1);

  for i := 0 to High(FIntPart) do begin
    sum := FIntPart[i] + overFlow;
    if i < Length(AValue.FIntPart) then
      sum := sum + AValue.FIntPart[i];

    if sum < 10 then begin
      FIntPart[i] := sum;
      overFlow := 0;
    end
    else begin
      FIntPart[i] := sum mod 10;
      overFlow := 1;
    end;
  end;

  if FIntPart[High(FIntPart)] = 0 then
    SetLength(FIntPart, Length(FIntPart) - 1);
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


procedure TSNumber.Allac(var AArray: TByteDynArray; const ALength: integer);
begin
  // Does not work
  SetLength(AArray, ALength);
  FillChar(AArray, ALength * SizeOf(byte), 0);
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
end;


procedure TSNumber.Clear;
begin
  FSign := false;
  SetLength(FIntPart, 0);
  SetLength(FFracPart, 0);
end;


procedure TSNumber.ConvertTo(ABase: integer);
var
  src: TSNumber;
  i: integer;
  exp: int64;
  lt: TRational;
  rt: TRational;
  range: TRational;
  srcDigit: byte;

  fracPart: TRational;
  digitPart: TRational;
  fracAsInt: integer;
begin
  src.Assign(Self);

  Clear;
  FBase := ABase;
  exp := 1;
  for i := 0 to High(src.FIntPart) do begin
    Add(src.FIntPart[i] * exp);
    exp := exp * src.FBase;
  end;

//  i := 0;
//  while i < Length(src.FFracPart) do begin
//    range := FBase;
//    lt := 0;
//    rt := FBase;
//    while lt.IntPart < rt.IntPart do begin
//      //outRange := rt - lt + 1;
//      range := range / src.FBase;
//      if i < Length(src.FFracPart) then
//        srcDigit := src.FFracPart[i]
//      else
//        srcDigit := 0;
//      lt := lt + range * srcDigit;
//      rt := lt + range;// - 1 + Sign(outRange mod src.FBase);
//      Inc(i);
//    end;
//
//    SetLength(FFracPart, Length(FFracPart) + 1);
//    FFracPart[High(FFracPart)] := lt.IntPart;
//
//    Inc(i);
//  end;

  SetLength(FFracPart, Length(src.FFracPart));
  fracPart := 0;
  digitPart := 1;
  for i := 0 to Length(src.FFracPart) - 1 do begin
    srcDigit := src.FFracPart[i];
    digitPart.Divide(src.FBase);
    digitPart.Multiply(FBase);
    fracPart.Multiply(FBase);
    fracPart.Add(digitPart * srcDigit);
  end;

  fracAsInt := fracPart.IntPart;
  for i := High(FFracPart) downto 0 do begin
    FFracPart[i] := fracAsInt mod FBase;
    fracAsInt := fracAsInt div FBase;
  end;
end;


constructor TSNumber.Create(ABase: integer; const AValue: string);
begin
  FBase := ABase;
  AsString := AValue;
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

    for i := Low(FFracPart) to High(FFracPart) do
      Result := Result + IntToStr(FFracPart[i]);
  end;

  if Result = '' then
    Result := '0';
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


procedure TSNumber.SetAsString(const AValue: string);
var
  ps: integer;
  i: integer;
begin
  //TODO: number validation, only digits in AValue
  //TODO: check base validness
  ps := Pos('.', AValue);
  if ps > 0 then begin
    SetLength(FIntPart, ps - 1);
    SetLength(FFracPart, Length(AValue) - ps);
    for i := 1 to ps - 1 do
      FIntPart[ps - i - 1] := StrToInt(AValue[i]);
    for i := ps + 1 to Length(AValue) do
      FFracPart[i - ps - 1] := StrToInt(AValue[i]);
  end
  else begin
    SetLength(FIntPart, Length(AValue));
    for i := 1 to Length(AValue) do
      FIntPart[Length(AValue) - i] := StrToInt(AValue[i]);
  end;
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


end.

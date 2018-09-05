unit UFunctionTextGenerator;

interface

uses
  Classes, Types;


type
  TFuncArg = record
    Name: string;
    Args: array of TFuncArg;
  end;


  procedure AddAllCombinationsForFunction(
    AFuncArg: TFuncArg; ARootValuesSet: array of string;
    ANodeValuesSet: array of string; ALeafValuesSet: array of string;
    AStrings: TStrings);


implementation

uses
  UBUtils;



function FuncArgToString(AArg: TFuncArg): string;
var
  i: integer;
  args: string;
begin
  Result := AArg.Name;
  if Length(AArg.Args) > 0 then begin
    args := '';
    for i := Low(AArg.Args) to High(AArg.Args) do
      args := JoinStrings(args, FuncArgToString(AArg.Args[i]), ', ');
    Result := Result + '(' + args + ')';
  end;
end;


procedure AddAllCombinationsForFunction(
  AFuncArg: TFuncArg; ARootValuesSet: array of string;
  ANodeValuesSet: array of string; ALeafValuesSet: array of string;
  AStrings: TStrings);
var
  i, k: integer;
  len: integer;
  p: ^string;
begin
  if Length(AFuncArg.Args) = 0 then begin
    p := @ALeafValuesSet[0];
    len := Length(ALeafValuesSet);
  end
  else if Length(ARootValuesSet) = 0 then begin
    p := @ANodeValuesSet[0];
    len := Length(ANodeValuesSet);
  end
  else begin
    p := @ARootValuesSet[0];
    len := Length(ARootValuesSet);
  end;

{  for k := 0 to len do begin
    if p[k] = AFuncArg.Name then
      AStrings.Add(FuncArgToString(AFuncArg))
    else
      AStrings.Add(FuncArgToString(AFuncArg));
  end;
 }
  for i := Low(AFuncArg.Args) to High(AFuncArg.Args) do
    AddAllCombinationsForFunction(AFuncArg.Args[i], [], [], [], AStrings);
end;


procedure AddAllFuncArgsTreeBranches(AFuncArg: TFuncArg; AStrings: TStrings);
var
  i: integer;
begin
  AStrings.Add(FuncArgToString(AFuncArg));
  for i := Low(AFuncArg.Args) to High(AFuncArg.Args) do
    AddAllFuncArgsTreeBranches(AFuncArg.Args[i], AStrings);
end;


end.

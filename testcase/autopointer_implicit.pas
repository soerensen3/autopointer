program autopointer_implicit;

{$MODE DELPHI}

uses
  autoobj;

type
  { TTestClass }

  TTestClass = class( TAutoClassSingleContainer )
    constructor Create;
    destructor Destroy; override;
  end;


{.$DEFINE TESTCASE1}
{.$DEFINE TESTCASE2}
{.$DEFINE TESTCASE3}

{ TTestClass }

constructor TTestClass.Create;
begin
  inherited Create;
  WriteLn( 'TTestClass created' );
end;

destructor TTestClass.Destroy;
begin
  WriteLn( 'TTestClass destroyed' );
  inherited Destroy;
end;

var
  TestContainer: TTestClass;
  TestPointer: TAuto < TTestClass >;
  TestPointers: array [ 0..9 ] of TAuto < TTestClass >;
  i: Integer;

procedure Test2;
begin
  TestContainer:= TTestClass.Create;
  TestPointer.I:= TestContainer;
end;

procedure Test3;
var
  TestContainer2: TTestClass;
begin
  TestContainer2:= TTestClass.Create;
  TestPointer.I:= TestContainer2;
  for i:= 0 to high( TestPointers ) do
    TestPointers[ i ].I:= TestContainer2;
  WriteLn( 'TestPointer.Instance = ', HexStr( Pointer( TestPointer.I )));
  for i:= 0 to high( TestPointers ) do
    WriteLn( 'TestPointers[', i, '].Instance = ', HexStr( Pointer( TestPointers[ i ].I )));
  TestContainer2.Free;
end;


begin
  {$IFDEF TESTCASE1}
  WriteLn( 'TestCase1' );
  TestContainer:= TTestClass.Create;
  TestPointer.I:= TestContainer;
  {$ELSE}
    {$IFDEF TESTCASE2}
  WriteLn( 'TestCase2' );
  Test2;
    {$ELSE}
  WriteLn( 'TestCase3' );
  Test3;
    {$ENDIF}
  {$ENDIF}
  for i:= 0 to high( TestPointers ) do
    TestPointers[ i ].I:= TestContainer;
  if ( Assigned( TestContainer )) then begin
    WriteLn( 'TestContainer.AutoPointers.Count = ', TestContainer.AutoPointers.Count );
    for i:= 0 to TestContainer.AutoPointers.Count - 1 do
      WriteLn( 'TestContainer.AutoPointers[', i, '] = ', HexStr( Pointer( TestContainer.AutoPointers[ i ])));
    TestContainer.Free;
  end;
  WriteLn( 'TestPointer.Instance = ', HexStr( Pointer( TestPointer.I )));
  for i:= 0 to high( TestPointers ) do
    WriteLn( 'TestPointers[', i, '].Instance = ', HexStr( Pointer( TestPointers[ i ].I )));
end.


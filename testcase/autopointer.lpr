program autopointer;

uses
  autopointer;

type
  { TTestClass }

  TTestClass = class( TAutoClassContained )
    constructor Create;
    destructor Destroy; override;
  end;

{.$DEFINE TESTCASE1}
{$DEFINE TESTCASE2}
{$DEFINE TESTCASE3}

{ TTestClass }

constructor TTestClass.Create;
begin
  WriteLn( 'TTestClass created' );
end;

destructor TTestClass.Destroy;
begin
  WriteLn( 'TTestClass destroyed' );
  inherited Destroy;
end;

var
  TestContainer: specialize TAutoContainer < TTestClass >;
  TestPointer: specialize TAutoPointer < TTestClass >;
  TestPointers: array [ 0..9 ] of specialize TAutoPointer < TTestClass >;
  i: Integer;

procedure Test2;
begin
  TestContainer.Instance:= TTestClass.Create;
  TestPointer.Instance:= TestContainer.Instance;
end;

procedure Test3;
var
  TestContainer2: specialize TAutoContainer < TTestClass >;
begin
  TestContainer2.Instance:= TTestClass.Create;
  TestPointer.Instance:= TestContainer2.Instance;
end;


begin
  {$IFDEF TESTCASE1}
  WriteLn( 'TestCase1' );
  TestContainer.Instance:= TTestClass.Create;
  TestPointer.Instance:= TestContainer.Instance;
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
    TestPointers[ i ].Instance:= TestContainer.Instance;
  WriteLn( 'TestContainer.AutoPointers.Count = ', TestContainer.AutoPointers.Count );
  for i:= 0 to TestContainer.AutoPointers.Count - 1 do
    WriteLn( 'TestContainer.AutoPointers[', i, '] = ', HexStr( Pointer( TestContainer.AutoPointers[ i ])));
  WriteLn( 'TestPointer.Instance = ', HexStr( Pointer( TestPointer.Instance )));
  for i:= 0 to high( TestPointers ) do
    WriteLn( 'TestPointers[', i, '].Instance = ', HexStr( Pointer( TestPointers[ i ].Instance )));
end.


program autopointer_test;
{$MODE delphi}

uses
  fgl, autopointer, autoobj, sysutils;

type

  { TTestClass }

  TTestClass = class( TAutoClassContained )
    i: Integer;
    constructor Create( Index: Integer );
    destructor Destroy; override;
  end;

  { TTestClass2 }

  TTestClass2 = class ( TAutoClass )
    i: Integer;
    constructor Create(Index: Integer);
    destructor Destroy; override;
  end;

  TTestClass3 = class
    objAuto: TAuto < TTestClass2 >;

    property obj: TTestClass2 read objAuto.FInstance;
  end;

{ TTestClass2 }

constructor TTestClass2.Create(Index: Integer);
begin
  inherited Create;
  WriteLn( 'Create ', Index );
  i:= Index;
end;

destructor TTestClass2.Destroy;
begin
  WriteLn( 'Destroy ', i );
  inherited Destroy;
end;

{ TTestClass }

constructor TTestClass.Create(Index: Integer);
begin
  WriteLn( 'Create ', Index );
  i:= Index;
end;

destructor TTestClass.Destroy;
begin
  WriteLn( 'Destroy ', i );
  inherited Destroy;
end;

var
  C: TAutoContainer < TTestClass >;
  P: TAutoPointer < TTestClass >;
  S1, S2: TAuto < TTestClass2 >;
  cl: TTestClass3;

begin
  WriteLn( '> ', IntToHex( Integer( C.Instance ), 8 ));
  C:= TTestClass.Create( 0 );
  P:= C;
  S1:= TTestClass2.Create( 1 );
  S2:= S1;
  WriteLn( '> ', IntToHex( Integer( C.Instance ), 8 ));
  WriteLn( '> ', IntToHex( Integer( P.Instance ), 8 ));
  C.Instance.Free;
  C.Instance:= nil;
  WriteLn( '> ', IntToHex( Integer( P.Instance ), 8 ));
  cl:= TTestClass3.Create;
  cl.objAuto:= TTestClass2.Create( 999 );
  cl.Free;
end.


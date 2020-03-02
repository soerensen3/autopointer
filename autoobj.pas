{

                                   ________________                    __
                                  /_____________  /                   / /
                                               / /                   / /
                                              / /                   / /
          ________________     ______________/ /     ______________/ /
         / ____________  /    /_____________  /     / ____________  /
        / /           / /                  / /     / /           / /
       / /           / /                  / /     / /           / /
      / /           / /                  / /     / /           / /
     / /___________/ /    ______________/ /     / /___________/ /
    / ______________/    /_______________/     /_______________/
   / /
  / /
 / /
/_/

====================================================================================


}

unit autoobj;
{$MODE delphi}

{.$DEFINE AutoDEBUG}

interface

uses
  fgl, sysutils;

type
  //================================================================================
  //** autopointer.pas
  //**------------------------------------------------------------------------------
  //** Descendants of TAutoClass can be owned by a container object. They get freed
  //** automatically when the container goes out of scope or if they belong to a
  //** field of an object and the object gets freed.
  //================================================================================
  TAutoClass = class;

  //================================================================================
  //** TAuto
  //**------------------------------------------------------------------------------
  //** A container class for TAutoClass.
  //** It gets updated automatically when the container is freed or it's
  //** instance is changed.
  //================================================================================

  { TAuto }

  TAuto <T: TAutoClass> = record
    private
      FInstance: T;

      procedure SetInstance(AValue: T);
      procedure Destroy;

    public type
      TAutoType = T;

    public
      property I: T read FInstance write SetInstance;

      class operator Copy( constref aSrc: TAuto < T >; var aDst: TAuto < T > );
      class operator AddRef( var aRec: TAuto < T > );
      class operator Implicit( AValue: T ): TAuto < T >;
      class operator Implicit( AValue: TAuto < T > ): T;
      class operator Initialize( var aRec: TAuto < T >);
      class operator Finalize( var aRec: TAuto < T >);
      class operator Equal( a, b: TAuto < T >): Boolean;
      class operator NotEqual( a, b: TAuto < T >): Boolean;
  end;

  { TAutoClass }

  //================================================================================
  //** TAutoClass
  //**------------------------------------------------------------------------------
  //** Derive from TAutoClass to use your class with auto container/pointer.
  //** The instance is not automatically created but when the container is freed
  //** by the compiler for example if it goes out scope in a function then the
  //** instance is freed as well. If you store a container in an instance of
  //** another class your instance of TAutoClass will not get freed until the
  //** instance that keeps the container is freed.
  //** Never copy a container as this will result in undefined behaviour.
  //================================================================================

  TAutoClass = class ( TInterfacedObject )
    private type
      PAuto = ^TAuto < TAutoClass >;

    private
      FAutoPointers: TFPGList < PAuto >;

      procedure AddPointer( Pointer: PAuto ); virtual; abstract;
      procedure RemovePointer( Pointer: PAuto ); virtual; abstract;

    public
      constructor Create;
      destructor Destroy; override;

      property AutoPointers: TFPGList < PAuto > read FAutoPointers;
  end;

  { TAutoClassMultiContainer }

  //================================================================================
  //** TAutoClassMultiContainer and TAutoClassSingleContainer
  //**------------------------------------------------------------------------------
  //** TAutoClassMultiContainer and TAutoClassSingleContainer keep track of
  //** pointers pointing to the same instance of a TAutoClass.
  //** The difference between multi and single containers is that an instance
  //** instance is freed as well. If you store a container in an instance of
  //** another class your instance of TAutoClass will not get freed until the
  //** instance that keeps the container is freed.
  //** Never copy a container as this will result in undefined behaviour.
  //================================================================================

  TAutoClassMultiContainer = class ( TAutoClass )
    private
      procedure AddPointer( Pointer: PAuto ); override;
      procedure RemovePointer( Pointer: PAuto ); override;
  end;

  { TAutoClassSingleContainer }

  TAutoClassSingleContainer = class ( TAutoClass )
    private
      procedure AddPointer( Pointer: PAuto ); override;
      procedure RemovePointer( Pointer: PAuto ); override;
  end;

implementation


{ TAuto }

procedure TAuto < T >.SetInstance(AValue: T);
var
  i: Integer;
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'procedure TAuto < %:s >.SetInstance(AValue: %:s);', [ T.ClassName ]));
  {$ENDIF}
  if ( Assigned( FInstance )) then begin
    FInstance.RemovePointer( @Self );
  end;

  FInstance:= AValue;
  if ( Assigned( FInstance )) then
    FInstance.AddPointer( @Self );
end;

class operator TAuto < T >.Initialize(var aRec: TAuto<T>);
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'class operator TAuto < %:s >.Initialize(var aRec: TAuto<%:s>);', [ T.ClassName ]));
  {$ENDIF}
  //aRec:= default( TAuto < T > );
  aRec.FInstance:= default( T );
end;

class operator TAuto < T >.Finalize(var aRec: TAuto<T>);
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'class operator TAuto < %:s >.Finalize(var aRec: TAuto<%:s>);', [ T.ClassName ]));
  {$ENDIF}
  aRec.Destroy;
end;

class operator TAuto<T>.Equal(a, b: TAuto<T>): Boolean;
begin
  Result:= a.I = b.I;
end;

class operator TAuto<T>.NotEqual(a, b: TAuto<T>): Boolean;
begin
  Result:= a.I <> b.I;
end;

class operator TAuto<T>.Copy(constref aSrc: TAuto<T>; var aDst: TAuto<T>);
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'class operator TAuto<%:s>.Copy(constref aSrc: TAuto<%:s>; var aDst: TAuto<%:s>);', [ T.ClassName ]));
  {$ENDIF}
  aDst.I:= aSrc.I;
end;


procedure TAuto < T >.Destroy;
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'procedure TAuto < %:s >.Destroy;', [ T.ClassName ]));
  {$ENDIF}
  I:= default( T );
end;

class operator TAuto < T >.Implicit( AValue: T ): TAuto < T >;
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'class operator TAuto < %:s >.Implicit( AValue: %:s ): TAuto < %:s >;', [ T.ClassName ]));
  {$ENDIF}
  Result.I:= AValue
end;

class operator TAuto < T >.Implicit( AValue: TAuto < T >): T;
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'class operator TAuto < %:s >.Implicit( AValue: TAuto < %:s >): %:s;', [ T.ClassName ]));
  {$ENDIF}
  Result:= AValue.I;
end;

class operator TAuto < T >.AddRef( var aRec: TAuto < T > );
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'class operator TAuto < %:s >.AddRef( var aRec: TAuto < %:s > );', [ T.ClassName ]));
  {$ENDIF}
end;

{ TAutoClassSingleContainer }

procedure TAutoClassSingleContainer.AddPointer(Pointer: PAuto);
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'procedure %:s.AddPointer(Pointer: PAuto);', [ ClassName ]));
  {$ENDIF}
  FAutoPointers.Add( Pointer );
end;

procedure TAutoClassSingleContainer.RemovePointer(Pointer: PAuto);
begin
  FAutoPointers.Remove( Pointer );
end;

{ TAutoClassMultiContainer }

procedure TAutoClassMultiContainer.AddPointer(Pointer: PAuto);
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'procedure %:s.AddPointer(Pointer: PAuto);', [ ClassName ]));
  {$ENDIF}
  FAutoPointers.Add( Pointer );
end;

procedure TAutoClassMultiContainer.RemovePointer(Pointer: PAuto);
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'procedure %:s.RemovePointer(Pointer: PAuto);', [ ClassName ]));
  {$ENDIF}
  FAutoPointers.Remove( Pointer );
  if ( FAutoPointers.Count < 1 ) then
    Free;
end;

constructor TAutoClass.Create;
begin
  inherited Create;
  FAutoPointers:= ( TFPGList < PAuto >).Create;
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'constructor %:s.Create;', [ ClassName ]));
  {$ENDIF}
end;

destructor TAutoClass.Destroy;
var
  i: LongInt;
begin
  {$IFDEF AutoDEBUG}
  WriteLn( Format( 'destructor %:s.Destroy;', [ ClassName ]));
  {$ENDIF}
  for i:= FAutoPointers.Count - 1 downto 0 do
    FAutoPointers[ i ]^.I:= nil;
  FreeAndNil( FAutoPointers );
  inherited Destroy;
end;


end.

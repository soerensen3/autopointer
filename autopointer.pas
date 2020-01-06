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

unit autopointer;
{$MODE delphi}

{-$DEFINE DEBUG}
{.$DEFINE IMPLICIT} // DO NOT USE FOR NOW, CAUSES BUGS

interface

uses
  fgl, sysutils;

type
  //================================================================================
  //** autopointer.pas
  //**------------------------------------------------------------------------------
  //** Descendants of TAutoClassContained can be owned by a container object. They
  //** get freed automatically when the container goes out of scope or if they
  //** belong to a field of an object and the object gets freed.
  //================================================================================
  TAutoClassContained = class;

  //================================================================================
  //** TAutoPointer
  //**------------------------------------------------------------------------------
  //** Pointer class that points to an instance of auto class but does not own the
  //** instance. It gets updated automatically when the container is freed or it's
  //** instance is changed.
  //================================================================================

  { TAutoPointer }

  TAutoPointer <T: TAutoClassContained> = record
    private
      FInstance: T;

      procedure SetInstance(AValue: T );

    public
      class operator Finalize( var aRec: TAutoPointer < T >);
      {$IFDEF IMPLICIT}
      class operator Implicit( AValue: T ): TAutoPointer < T >;
      class operator Implicit( AValue: TAutoPointer < T > ): T;
      {$ENDIF}
      class operator Copy( constref aSrc: TAutoPointer < T >; var aDst: TAutoPointer < T > );

      property Instance: T read FInstance write SetInstance;
    end;

  //================================================================================
  //** TAutoContainer
  //**------------------------------------------------------------------------------
  //** A container class for TAutoClassContained. If it goes out of scope or
  //** instance is freed it updates all the pointers pointing to the instance.
  //================================================================================

  { TAutoContainer }

  TAutoContainer <T: TAutoClassContained> = record
    private type
      PAutoPointer = ^TAutoPointer < T >;

    private
      FAutoPointers: TFPGList < PAutoPointer >;
      FInstance: T;

      procedure SetInstance(AValue: T);
      procedure Destroy;
      procedure AddPointer( Pointer: PAutoPointer );
      procedure RemovePointer( Pointer: PAutoPointer );

    public
      {$IFDEF IMPLICIT}
      class operator Implicit( var AValue: T ): TAutoContainer < T >;
      class operator Implicit( var AValue: TAutoContainer < T > ): T;
      class operator Implicit( AValue: TAutoContainer < T > ): TAutoPointer < T >;
      class operator Copy( constref aSrc: TAutoContainer < T >; var aDst: TAutoContainer < T > );
      {$ENDIF}
      class operator Initialize( var aRec: TAutoContainer < T >);
      class operator Finalize( var aRec: TAutoContainer < T >);

      property Instance: T read FInstance write SetInstance;
      property AutoPointers: TFPGList < PAutoPointer > read FAutoPointers;
  end;

  { TAutoClassContained }

  //================================================================================
  //** TAutoClassContained
  //**------------------------------------------------------------------------------
  //** Derive from TAutoClassContained to use your class with auto container/pointer.
  //** The instance is not automatically created but when the container is freed
  //** by the compiler for example if it goes out scope in a function then the
  //** instance is freed as well. If you store a container in an instance of
  //** another class your instance of TAutoClassContained will not get freed until the
  //** instance that keeps the container is freed.
  //** Never copy a container as this will result in undefined behaviour.
  //================================================================================

  TAutoClassContained = class ( TInterfacedObject )
    private type
      PAutoContainer = ^TAutoContainer<TAutoClassContained>;

    private
      FOwner: PAutoContainer;

    public
      destructor Destroy; override;

      property Owner: PAutoContainer read FOwner;
  end;

implementation

{ TAutoPointer }

procedure TAutoPointer <T: TAutoClassContained>.SetInstance(AValue: T);
begin
  {$IFDEF DEBUG}
  WriteLn( 'class operator TAutoPointer <T: TAutoClassContained>.Finalize(var aRec: TAutoPointer<T>);' );
  {$ENDIF}
  if ( Assigned( FInstance ) and Assigned( FInstance.Owner )) then
    FInstance.Owner.RemovePointer( @Self );

  FInstance:= AValue;
  if ( Assigned( FInstance ) and Assigned( FInstance.Owner )) then
    FInstance.Owner.AddPointer( @Self );
end;

class operator TAutoPointer <T: TAutoClassContained>.Finalize(var aRec: TAutoPointer<T>);
begin
  {$IFDEF DEBUG}
  WriteLn( 'class operator TAutoPointer <T: TAutoClassContained>.Finalize(var aRec: TAutoPointer<T>);' );
  {$ENDIF}
  aRec.Instance:= default( T );
end;

{$IFDEF IMPLICIT}
class operator TAutoPointer < T >.Implicit( AValue: T ): TAutoPointer < T >;
begin
  {$IFDEF DEBUG}
  WriteLn( 'class operator TAutoPointer < T >.Implicit( AValue: T ): TAutoPointer < T >;' );
  {$ENDIF}
  Result.Instance:= AValue;
end;

class operator TAutoPointer < T >.Implicit( AValue: TAutoPointer < T >): T;
begin
  {$IFDEF DEBUG}
  WriteLn( 'class operator TAutoPointer < T >.Implicit( AValue: TAutoPointer < T >): T;' );
  {$ENDIF}
  Result:= AValue.Instance;
end;

class operator TAutoContainer<T>.Copy(constref aSrc: TAutoContainer<T>; var aDst: TAutoContainer<T>);
begin
  //Move( aSrc, aDst, SizeOf( aDst ));
  //aSrc:= default( TAutoContainer<T>);
  WriteLn( HexStr( Pointer( aDst.FInstance )));
  WriteLn( HexStr( Pointer( aSrc.FInstance )));
end;

{$ENDIF}

class operator TAutoPointer < T >.Copy( constref aSrc: TAutoPointer < T >; var aDst: TAutoPointer < T > );
begin
  {$IFDEF DEBUG}
  WriteLn( 'class operator TAutoPointer < T >.Copy( constref aSrc: TAutoPointer < T >; var aDst: TAutoPointer < T > );' );
  {$ENDIF}
  aDst.Instance:= aSrc.Instance;
end;


{ TAutoContainer }

procedure TAutoContainer < T >.SetInstance(AValue: T);
var
  i: Integer;
begin
  {$IFDEF DEBUG}
  WriteLn( 'procedure TAutoContainer < T >.SetInstance(AValue: T);' );
  {$ENDIF}
  if ( AValue = FInstance ) then
    exit;
  for i:= FAutoPointers.Count - 1 downto 0 do
    FAutoPointers[ i ]^.Instance:= AValue;

  if ( Assigned( FInstance ) and ( FInstance.Owner = @Self )) then begin
    FInstance.FOwner:= nil;
    FInstance.Free;
  end;

  FInstance:= AValue;
  if ( Assigned( FInstance )) then
    FInstance.FOwner:= @Self;
end;

class operator TAutoContainer < T >.Initialize(var aRec: TAutoContainer<T>);
begin
  {$IFDEF DEBUG}
  WriteLn( 'class operator TAutoContainer < T >.Initialize(var aRec: TAutoContainer<T>);' );
  {$ENDIF}
  aRec:= default( TAutoContainer < T > );
  aRec.FAutoPointers:= TFPGList < PAutoPointer >.Create;
end;

class operator TAutoContainer < T >.Finalize(var aRec: TAutoContainer<T>);
begin
  {$IFDEF DEBUG}
  WriteLn( 'class operator TAutoContainer < T >.Finalize(var aRec: TAutoContainer<T>);' );
  {$ENDIF}
  if ( Assigned( aRec.Instance ) and ( aRec.Instance.Owner = @aRec )) then
    aRec.Destroy;
end;




procedure TAutoContainer < T >.Destroy;
var
  i: Integer;
begin
  {$IFDEF DEBUG}
  WriteLn( 'procedure TAutoContainer < T >.Destroy;' );
  {$ENDIF}
  for i:= FAutoPointers.Count - 1 downto 0 do
    FAutoPointers[ i ]^.Instance:= default( T );
  if ( FAutoPointers.Count > 0 ) then
    raise Exception.Create( 'Error 1' );
  FAutoPointers.Free;
  FAutoPointers:= default( TFPGList < PAutoPointer >);
  FInstance.FOwner:= nil;
  FInstance.Free;
  FInstance:= default( T );
end;

procedure TAutoContainer < T >.AddPointer( Pointer: PAutoPointer );
begin
  {$IFDEF DEBUG}
  WriteLn( 'procedure TAutoContainer < T >.AddPointer( Pointer: PAutoPointer );' );
  {$ENDIF}
  FAutoPointers.Add( Pointer );
end;

procedure TAutoContainer < T >.RemovePointer( Pointer: PAutoPointer );
begin
  {$IFDEF DEBUG}
  WriteLn( 'procedure TAutoContainer < T >.RemovePointer( Pointer: PAutoPointer );' );
  {$ENDIF}
  FAutoPointers.Remove( Pointer );
end;

{$IFDEF IMPLICIT}
class operator TAutoContainer<T>.Implicit(var AValue: T): TAutoContainer < T >;
begin
  {$IFDEF DEBUG}
  WriteLn( 'class operator TAutoContainer < T >.Implicit( AValue: T ): TAutoContainer < T >;' );
  {$ENDIF}
  Result.Instance:= AValue;
end;

class operator TAutoContainer < T >.Implicit( var AValue: TAutoContainer < T >): T;
begin
  {$IFDEF DEBUG}
  WriteLn( 'class operator TAutoContainer < T >.Implicit( AValue: TAutoContainer < T >): T;' );
  {$ENDIF}
  Result:= AValue.Instance;
end;

class operator TAutoContainer < T >.Implicit( AValue: TAutoContainer < T >): TAutoPointer < T >;
begin
  {$IFDEF DEBUG}
  WriteLn( 'class operator TAutoContainer < T >.Implicit( AValue: TAutoContainer < T >): TAutoPointer < T >;' );
  {$ENDIF}
  Result.Instance:= AValue.Instance;
end;
{$ENDIF}

destructor TAutoClassContained.Destroy;
var
  _Owner: PAutoContainer;
begin
  inherited Destroy;
  _Owner:= Owner;
  if ( Assigned( _Owner )) then begin
    FOwner:= nil;
    _Owner.Instance:= nil;
  end;
end;


end.

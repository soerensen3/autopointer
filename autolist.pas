unit autolist;

{$mode delphi}


interface

uses
  Classes, SysUtils,
  Math,
  autopointer;


type
  TListOnChangeAction = ( actAdd, actDelete, actExtract, actClear, actAssignBefore, actAssignAfter, actSet );

  { gP3DListEnumerator }

  gListEnumerator < T > = class
    private type
      TMoveNext = function ( var AIndex: Integer; out AItem: T ): Boolean of object;
    private
      FCurrent: T;
      FCurrentIdx: Integer;
      FMoveNext: TMoveNext;

    public
      constructor Create( AStartIndex: Integer; AMoveNext: TMoveNext ); reintroduce;
      function MoveNext: Boolean;
      property Current: T read FCurrent;
      property CurrentIdx: Integer read FCurrentIdx;
  end;

  { gAutoList }

  gAutoList < TManagedType, T > = class ( TObject )
    type
      TItemList = gAutoList < TManagedType, T >;
      TItemListOnChangeEvent = procedure ( Sender: TItemList; ItemIndex: Integer; Action: TListOnChangeAction ) of object;
      TItemListOnSetEvent = function ( Sender: TObject; ItemIndex: Integer; AValue: T ): Boolean of object;

      PManagedType = ^TManagedType;
      TItemArray = array [ 0..( MAXINT shr 8 )] of PManagedType;
      pItemArray = ^TItemArray;
      TListEnumerator = gListEnumerator < TManagedType >;

    private
      FItems: pItemArray;
      FCount: Integer;
      FCapacity: Integer;
      FGrowth: Integer;
      FOnChange: TItemListOnChangeEvent;
      FOnSet: TItemListOnSetEvent;
      FSizeLimit: Integer;

      function GetItem( Index: Integer ): T;
      procedure SetCapacity( const Value: Integer );
      procedure SetCount( AValue: Integer );
      procedure SetGrowth( const Value: Integer );
      procedure SetItem( Index: Integer; const AValue: T );
      procedure Grow;
      procedure Shrink;
      function MoveNext( var AIndex: Integer; out AItem: TManagedType ): Boolean;

    public
      constructor Create; virtual;
      destructor Destroy; override;

      function Add( Item: T ): Integer; overload;
      function AddArray( Items: array of T ): Integer; overload;
      procedure Delete( Index: Integer ); overload;
      procedure Remove( Item: T );
      procedure Clear;
      function PtrTo( Index: Integer ): PManagedType;
      function GetEnumerator(): TListEnumerator;
      function IndexOf( var Item: T ): Integer;

      property Items[ Index: Integer ]: T read GetItem write SetItem; default;
      property Count: Integer read FCount write SetCount;
      property Capacity: Integer read FCapacity write SetCapacity;
      property Growth: Integer read FGrowth write SetGrowth;
      property SizeLimit: Integer read FSizeLimit;
      property OnChange: TItemListOnChangeEvent read FOnChange write FOnChange;
      property OnSet: TItemListOnSetEvent read FOnSet write FOnSet;
  end;

  gAutoClassContainerList < T: TAutoClassContained > = class( gAutoList < TAutoContainer < T >, T >);
  gAutoClassPointerList < T: TAutoClassContained > = class( gAutoList < TAutoPointer < T >, T >);



implementation

{ gP3DListEnumerator }

constructor gListEnumerator < T >.Create(AStartIndex: Integer; AMoveNext: TMoveNext);
begin
  inherited Create;
  FillByte( FCurrent, SizeOf( FCurrent ), 0 );
  FCurrentIdx:= AStartIndex;
  FMoveNext:= AMoveNext;
end;

function gListEnumerator < T >.MoveNext: Boolean;
begin
  Result:= FMoveNext( FCurrentIdx, FCurrent );
end;

function gAutoList < TManagedType, T >.Add( Item: T ): Integer;
begin
  if ( FCount = FCapacity ) then
    Grow;

  New( FItems^[ FCount ]);
  FItems^[ FCount ]^.I:= Item;
  Result:= FCount;

  Inc( FCount );
  if ( Assigned( OnChange )) then
    OnChange( Self, Result, actAdd );
end;

function gAutoList < TManagedType, T >.AddArray( Items: array of T ): Integer;
var
  i: Integer;
begin
  Result:= Count;
  for i:= Low( Items ) to High( Items ) do
    Add( Items[ I ]);
end;

function gAutoList < TManagedType, T >.GetEnumerator(): TListEnumerator;
begin
  Result:= TListEnumerator.Create( -1, MoveNext );
end;

function gAutoList < TManagedType, T >.IndexOf(var Item: T): Integer;
var
  i: Integer;
begin
  Result:= -1;
  for i:= 0 to Count - 1 do
    if ( Item = FItems^[ i ].I ) then begin
      Result:= i;
      break;
    end;
end;

procedure gAutoList < TManagedType, T >.Clear;
var
  i: Integer;
begin
  if ( Assigned( OnChange )) then
    OnChange( Self, -1, actClear );

  for i:= 0 to FCount - 1 do
    Dispose( FItems^[ i ]);

  FreeMem( FItems );
  FCount:= 0;
  FCapacity:= 0;
  FItems:= nil;
end;

constructor gAutoList < TManagedType, T >.Create;
begin
  inherited Create;
  FItems:= nil;
  FCount:= 0;
  FCapacity:= 0;
  FGrowth:= 256;
  FSizeLimit:= SizeOf( TItemArray ) div SizeOf( T );
end;

procedure gAutoList < TManagedType, T >.Delete( Index: Integer );
begin
  if ( Assigned( OnChange )) then
    OnChange( Self, Index, actDelete );

  Dispose( FItems^[ Index ]);
  Move( FItems^[ Index + 1 ], FItems^[ Index ], SizeOf( T ) * ( Count - 1 - Index )); //Move does a check for overlapping regions

  FCount:= FCount - 1;
end;

procedure gAutoList < TManagedType, T >.Remove( Item: T );
var
  Index: Integer;
begin
  Index:= IndexOf( Item );
  if ( Index > -1 ) then
    Delete( Index );
end;

destructor gAutoList < TManagedType, T >.Destroy;
begin
  Clear;
  inherited;
end;

function gAutoList < TManagedType, T >.GetItem( Index: Integer ): T;
begin
  if (( Index >= 0 ) and ( Index < FCount )) then
    Result:= FItems^[ Index ].I;
end;

procedure gAutoList < TManagedType, T >.Grow;
begin
  FCapacity:= FCapacity + FGrowth;
  ReallocMem( FItems, FCapacity * SizeOf( T ));
end;

function gAutoList < TManagedType, T >.PtrTo(Index: Integer): PManagedType;
begin
  if ( Count > Index ) then
    Result:= FItems^[ Index ]
  else
    Result:= nil;
end;

procedure gAutoList < TManagedType, T >.SetCount(AValue: Integer);
begin
  FCount:= AValue;    // TODO: call dispose
  while ( FCapacity < FCount ) do
    Grow;
  while ( FCapacity > FCount + FGrowth ) do
    Shrink;
end;

procedure gAutoList < TManagedType, T >.SetCapacity( const Value: Integer );
begin
  FCapacity:= Value;
  if ( FCapacity < FCount ) then
    FCapacity:= FCount;
  ReallocMem( FItems, FCapacity * SizeOf( T ));
end;

procedure gAutoList < TManagedType, T >.SetGrowth(const Value: Integer);
begin
  FGrowth:= Math.Max( 16, Value ); // Minimum Value 16
end;

procedure gAutoList < TManagedType, T >.SetItem( Index: Integer; const AValue: T );
begin
  if ( Assigned( OnSet ) and ( not OnSet( Self, Index, AValue ))) then  // TODO: call dispose
    exit;

  if ( Assigned( OnChange )) then
    OnChange( Self, Index, actSet );

  FItems^[ Index ].I:= AValue;
end;

procedure gAutoList < TManagedType, T >.Shrink;
begin
  FCapacity:= Math.Max( 0, FCapacity - FGrowth );
  ReallocMem( FItems, FCapacity * SizeOf( T ));
end;

function gAutoList < TManagedType, T >.MoveNext( var AIndex: Integer; out AItem: TManagedType ): Boolean;
begin
  Inc( AIndex );
  Result:= AIndex < Count;
  if ( Result ) then
    AItem:= FItems^[ AIndex ]^
  else
    AItem:= default( TManagedType );
end;



end.


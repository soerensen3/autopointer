{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit AutoPtr;

{$warn 5023 off : no warning about unused units}
interface

uses
  autopointer, autoobj, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('AutoPtr', @Register);
end.

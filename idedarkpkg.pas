{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit IDEDarkPkg;

{$warn 5023 off : no warning about unused units}
interface

uses
  IDEDark, IDEDarkOptions, IDEDarkSettings, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('IDEDark', @IDEDark.Register);
end;

initialization
  RegisterPackage('IDEDarkPkg', @Register);
end.

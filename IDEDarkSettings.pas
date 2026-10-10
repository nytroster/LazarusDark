unit IDEDarkSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Laz2_XMLCfg;

type
  TDarkColor = (
    dcWindow, dcEdit, dcControl, dcText, dcGrayText, dcTabText,
    dcBorder, dcShadow, dcDkShadow, dcLight3D, dcEdgeDark,
    dcHot, dcPressed, dcMenu, dcHint, dcSelection, dcSelectionText,
    dcAccent, dcActiveTab, dcLink);

  TDarkPalette = array[TDarkColor] of LongInt;

const
  DarkColorNames: array[TDarkColor] of string = (
    'Window background', 'Edit and list background', 'Button face', 'Text',
    'Disabled text', 'Inactive tab text', 'Border', '3D highlight',
    '3D dark shadow', '3D light', '3D shadow', 'Hover', 'Pressed',
    'Menu background', 'Hint background', 'Selection', 'Selection text',
    'Accent', 'Active tab', 'Heading and link text');

  DarkColorKeys: array[TDarkColor] of string = (
    'Window', 'Edit', 'Control', 'Text', 'GrayText', 'TabText', 'Border',
    'Shadow', 'DkShadow', 'Light3D', 'EdgeDark', 'Hot', 'Pressed', 'Menu',
    'Hint', 'Selection', 'SelectionText', 'Accent', 'ActiveTab', 'Link');

  DelphiDarkPalette: TDarkPalette = (
    $00262626, $001E1E1E, $00333333, $00F6F6F6, $008A8A8A, $00F1F1F1,
    $00454545, $004A4A4A, $002A2A2A, $003A3A3A, $00181818,
    $003C3C3C, $00484848, $002B2B2B, $00262525, $00784F26, $00FFFFFF,
    $00CC7A00, $00383838, $00D69C56);

var
  DarkEnabled: Boolean = True;
  Palette: TDarkPalette;
  SelectSchemePending: Boolean = False;

function DarkSettingsFileName: string;
procedure LoadDarkSettings;
procedure SaveDarkSettings;
function ColorToHex(Color: LongInt): string;
function HexToColor(const S: string; Default: LongInt): LongInt;
procedure InstallEditorScheme(Overwrite: Boolean);
procedure ApplyEditorSchemeAtStartup;

implementation

{$I IDEDarkScheme.inc}

function ColorToHex(Color: LongInt): string;
begin
  Result := Format('#%.2X%.2X%.2X',
    [Color and $FF, (Color shr 8) and $FF, (Color shr 16) and $FF]);
end;

function HexToColor(const S: string; Default: LongInt): LongInt;
var
  V: LongInt;
begin
  if (Length(S) = 7) and (S[1] = '#') and TryStrToInt('$' + Copy(S, 2, 6), V) then
    Result := ((V and $FF) shl 16) or (V and $FF00) or ((V shr 16) and $FF)
  else
    Result := Default;
end;

function ConfigParam(const S: string; out Value: string): Boolean;
const
  Keys: array[0..1] of string = ('--pcp=', '--primary-config-path=');
var
  I: Integer;
begin
  Result := False;
  for I := Low(Keys) to High(Keys) do
    if SameText(Copy(S, 1, Length(Keys[I])), Keys[I]) then
    begin
      Value := Trim(Copy(S, Length(Keys[I]) + 1, MaxInt));
      if (Length(Value) >= 2) and (Value[1] = '"') and (Value[Length(Value)] = '"') then
        Value := Copy(Value, 2, Length(Value) - 2);
      Exit(Value <> '');
    end;
end;

function PrimaryConfigDir: string;
var
  I: Integer;
  CfgFile: string;
  Cfg: TStringList;
begin
  Result := '';
  for I := 1 to ParamCount do
    if ConfigParam(ParamStr(I), Result) then Break;

  if Result = '' then
  begin
    CfgFile := ExtractFilePath(ParamStr(0)) + 'lazarus.cfg';
    if FileExists(CfgFile) then
    begin
      Cfg := TStringList.Create;
      try
        Cfg.LoadFromFile(CfgFile);
        for I := 0 to Cfg.Count - 1 do
          if ConfigParam(Trim(Cfg[I]), Result) then Break;
      finally
        Cfg.Free;
      end;
    end;
  end;

  if Result = '' then
    Result := GetAppConfigDir(False)
  else if ExtractFileDrive(Result) = '' then
    Result := ExtractFilePath(ParamStr(0)) + Result;
  Result := IncludeTrailingPathDelimiter(ExpandFileName(Result));
end;

function DarkSettingsFileName: string;
begin
  Result := PrimaryConfigDir + 'idedark.ini';
end;

procedure LoadDarkSettings;
var
  Ini: TIniFile;
  C: TDarkColor;
begin
  Palette := DelphiDarkPalette;
  DarkEnabled := True;
  if not FileExists(DarkSettingsFileName) then Exit;
  Ini := TIniFile.Create(DarkSettingsFileName);
  try
    DarkEnabled := Ini.ReadBool('General', 'Enabled', True);
    SelectSchemePending := Ini.ReadBool('General', 'SelectEditorScheme', False);
    for C := Low(TDarkColor) to High(TDarkColor) do
      Palette[C] := HexToColor(Ini.ReadString('Colors', DarkColorKeys[C], ''),
        DelphiDarkPalette[C]);
  finally
    Ini.Free;
  end;
end;

procedure SaveDarkSettings;
var
  Ini: TIniFile;
  C: TDarkColor;
begin
  ForceDirectories(ExtractFilePath(DarkSettingsFileName));
  Ini := TIniFile.Create(DarkSettingsFileName);
  try
    Ini.WriteBool('General', 'Enabled', DarkEnabled);
    Ini.WriteBool('General', 'SelectEditorScheme', SelectSchemePending);
    for C := Low(TDarkColor) to High(TDarkColor) do
      Ini.WriteString('Colors', DarkColorKeys[C], ColorToHex(Palette[C]));
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

function FindSchemeFile(out Installed: Boolean): string;
var
  Dir: string;
  Info: TSearchRec;
  Content: TStringList;
begin
  Dir := PrimaryConfigDir + 'userschemes' + PathDelim;
  Result := Dir + 'DelphiDark.xml';
  Installed := False;
  if FindFirst(Dir + '*.xml', faAnyFile, Info) <> 0 then Exit;
  Content := TStringList.Create;
  try
    repeat
      Content.LoadFromFile(Dir + Info.Name);
      if Pos('Value="' + DelphiDarkSchemeName + '"', Content.Text) > 0 then
      begin
        Result := Dir + Info.Name;
        Installed := True;
        Break;
      end;
    until FindNext(Info) <> 0;
  finally
    Content.Free;
    FindClose(Info);
  end;
end;

procedure InstallEditorScheme(Overwrite: Boolean);
var
  FileName, Data: string;
  Installed: Boolean;
  Stream: TFileStream;
begin
  FileName := FindSchemeFile(Installed);
  if Installed and not Overwrite then Exit;
  ForceDirectories(ExtractFilePath(FileName));
  Data := DelphiDarkSchemeXml;
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    Stream.WriteBuffer(Pointer(Data)^, Length(Data));
  finally
    Stream.Free;
  end;
end;

function SelectEditorScheme: Boolean;
var
  FileName: string;
  Config: TXMLConfig;
begin
  FileName := PrimaryConfigDir + 'editoroptions.xml';
  Result := FileExists(FileName);
  if not Result then Exit;
  Config := TXMLConfig.Create(FileName);
  try
    Config.SetValue('EditorOptions/Color/LangObjectPascal/ColorScheme/Value', DelphiDarkSchemeName);
    Config.Flush;
  finally
    Config.Free;
  end;
end;

procedure ApplyEditorSchemeAtStartup;
begin
  try
    InstallEditorScheme(False);
    if SelectSchemePending and SelectEditorScheme then
    begin
      SelectSchemePending := False;
      SaveDarkSettings;
    end;
  except
  end;
end;

end.

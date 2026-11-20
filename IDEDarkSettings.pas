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

  // Base16 Ocean Dark Extended palette ($00BBGGRR)
  OceanDarkPalette: TDarkPalette = (
    $002D2521, // dcWindow        #21252d (panel / workbench background)
    $003B302B, // dcEdit          #2b303b (editor background)
    $00463D34, // dcControl       #343d46 (button / dropdown face)
    $00CEC5C0, // dcText          #c0c5ce (text)
    $007E7365, // dcGrayText      #65737e (disabled / comment text)
    $00968A7E, // dcTabText       #7e8a96 (inactive tab text)
    $0027201D, // dcBorder        #1d2027 (border)
    $00231D1A, // dcShadow        #1a1d23 (3D highlight / shadow)
    $001F1916, // dcDkShadow      #16191f (3D dark shadow)
    $00463D34, // dcLight3D       #343d46 (3D light)
    $00231D1A, // dcEdgeDark      #1a1d23 (3D shadow / edge dark)
    $00382D29, // dcHot           #292d38 (hover)
    $00322925, // dcPressed       #252932 (pressed)
    $002D2521, // dcMenu          #21252d (menu background)
    $00322925, // dcHint          #252932 (hint background)
    $00665B4F, // dcSelection     #4f5b66 (selection background)
    $00F5F1EF, // dcSelectionText #eff1f5 (selection text)
    $00C78C51, // dcAccent        #518cc7 (accent blue badge)
    $005C4D41, // dcActiveTab     #414d5c (active tab background)
    $00B3A18F  // dcLink          #8fa1b3 (functions / links)
  );

  DelphiDarkPalette: TDarkPalette = (
    $002D2521, $003B302B, $00463D34, $00CEC5C0, $007E7365, $00968A7E,
    $0027201D, $00231D1A, $001F1916, $00463D34, $00231D1A,
    $00382D29, $00322925, $002D2521, $00322925, $00665B4F, $00F5F1EF,
    $00C78C51, $005C4D41, $00B3A18F);

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
procedure ApplyEnvironmentOptions(Overwrite: Boolean);
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
  begin
    {$IFDEF UNIX}
    Result := ExpandFileName('~/.lazarus');
    if not DirectoryExists(Result) then
      Result := GetAppConfigDir(False);
    {$ELSE}
    Result := GetAppConfigDir(False);
    {$ENDIF}
  end
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
  Palette := OceanDarkPalette;
  DarkEnabled := True;
  if not FileExists(DarkSettingsFileName) then Exit;
  Ini := TIniFile.Create(DarkSettingsFileName);
  try
    DarkEnabled := Ini.ReadBool('General', 'Enabled', True);
    SelectSchemePending := Ini.ReadBool('General', 'SelectEditorScheme', False);
    for C := Low(TDarkColor) to High(TDarkColor) do
      Palette[C] := HexToColor(Ini.ReadString('Colors', DarkColorKeys[C], ''),
        OceanDarkPalette[C]);
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
  Result := Dir + 'OceanDarkExtended.xml';
  Installed := False;
  if FindFirst(Dir + '*.xml', faAnyFile, Info) <> 0 then Exit;
  Content := TStringList.Create;
  try
    repeat
      Content.LoadFromFile(Dir + Info.Name);
      if (Pos('Value="' + OceanDarkSchemeName + '"', Content.Text) > 0) or
         (Pos('Value="Ocean_Dark_Extended_gemini"', Content.Text) > 0) then
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
  Data := OceanDarkSchemeXml;
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
    Config.SetValue('EditorOptions/Color/LangObjectPascal/ColorScheme/Value', OceanDarkSchemeName);
    Config.Flush;
  finally
    Config.Free;
  end;
end;

procedure ApplyEnvironmentOptions(Overwrite: Boolean);
var
  FileName: string;
  Config: TXMLConfig;
begin
  FileName := PrimaryConfigDir + 'environmentoptions.xml';
  if not FileExists(FileName) then Exit;
  Config := TXMLConfig.Create(FileName);
  try
    if Overwrite or (Config.GetValue('EnvironmentOptions/MsgView/Colors/Background', '') = '') then
    begin
      Config.SetValue('EnvironmentOptions/MsgView/Colors/Background', '3878955');     // #2b303b
      Config.SetValue('EnvironmentOptions/MsgView/Colors/TextColor', '13551040');     // #c0c5ce
      Config.SetValue('EnvironmentOptions/MsgView/Colors/Running', '13077585');       // #518cc7
      Config.SetValue('EnvironmentOptions/MsgView/Colors/Success', '9223843');        // #a3be8c
      Config.SetValue('EnvironmentOptions/MsgView/Colors/Failed', '6971839');         // #bf616a
    end;
    if Overwrite or (Config.GetValue('EnvironmentOptions/FormEditor/NonFormBackgroundColor/Value', '') = '') then
    begin
      Config.SetValue('EnvironmentOptions/FormEditor/NonFormBackgroundColor/Value', '2958625'); // #21252d
      Config.SetValue('EnvironmentOptions/FormEditor/GridColor', '4603188');                     // #343d46
      Config.SetValue('EnvironmentOptions/FormEditor/GrabberColor/Value', '13551040');            // #c0c5ce
      Config.SetValue('EnvironmentOptions/FormEditor/MarkerColor/Value', '8287077');              // #65737e
      Config.SetValue('EnvironmentOptions/FormEditor/Rubberband/SelectionColor/Value', '12159321');// #5989b9
      Config.SetValue('EnvironmentOptions/FormEditor/Rubberband/CreationColor/Value', '11772303'); // #8fa1b3
    end;
    Config.Flush;
  finally
    Config.Free;
  end;
end;

procedure ApplyEditorSchemeAtStartup;
begin
  try
    InstallEditorScheme(False);
    ApplyEnvironmentOptions(False);
    if SelectSchemePending and SelectEditorScheme then
    begin
      SelectSchemePending := False;
      SaveDarkSettings;
    end;
  except
  end;
end;

end.

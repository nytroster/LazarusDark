unit IDEDark;

{$mode objfpc}{$H+}
{$POINTERMATH ON}

interface

procedure Register;
procedure StartDark;

implementation

uses
  SysUtils, Classes, TypInfo,
  Graphics, Forms, Controls, StdCtrls, ComCtrls, ExtCtrls, Menus, Dialogs, Themes,
  Buttons, Grids,
  InterfaceBase, LCLType,
  {$IFDEF MSWINDOWS}
  CommCtrl, UxTheme, Win32Extra, LCLStrConsts, Windows,
  {$ENDIF}
  IDEDarkSettings, IDEDarkOptions;

type
  TTreeViewAccess = class(TCustomTreeView);
  TCoolBarAccess = class(TCustomCoolBar);
  TControlAccess = class(TControl);

var
  Colors: TDarkPalette;
  Installed: Boolean = False;
  Started: Boolean = False;

function SysColorRole(Index: LongInt; out Role: TDarkColor): Boolean;
begin
  Result := True;
  case Index of
    COLOR_SCROLLBAR:                     Role := dcControl;
    COLOR_BACKGROUND, COLOR_MENU,
    COLOR_APPWORKSPACE, COLOR_BTNFACE,
    COLOR_MENUBAR:                       Role := dcWindow;
    COLOR_WINDOW:                        Role := dcEdit;
    COLOR_WINDOWFRAME, COLOR_ACTIVEBORDER,
    COLOR_INACTIVEBORDER:                Role := dcBorder;
    COLOR_MENUTEXT, COLOR_WINDOWTEXT,
    COLOR_BTNTEXT, COLOR_INFOTEXT:       Role := dcText;
    COLOR_HIGHLIGHT:                     Role := dcSelection;
    COLOR_HIGHLIGHTTEXT:                 Role := dcSelectionText;
    COLOR_BTNSHADOW, COLOR_BTNHIGHLIGHT: Role := dcShadow;
    COLOR_GRAYTEXT:                      Role := dcGrayText;
    COLOR_3DDKSHADOW:                    Role := dcDkShadow;
    COLOR_3DLIGHT:                       Role := dcLight3D;
    COLOR_INFOBK:                        Role := dcHint;
    COLOR_MENUHILIGHT:                   Role := dcHot;
  else
    Result := False;
  end;
end;

{$IFDEF MSWINDOWS}
const
  PropThemed: PWideChar = 'IDEDark';
  PropHot: PWideChar = 'IDEDarkHot';
  NoTheme: array[0..0] of WideChar = (#0);

  E_NOTIMPL_ = LongInt($80004001);

  WM_UPDATEUISTATE  = $0128;
  WM_PRINT          = $0317;
  WM_PRINTCLIENT    = $0318;
  PRF_NONCLIENT     = $0002;
  WH_CBT            = 5;
  HCBT_CREATEWND    = 3;
  GA_ROOT           = 2;
  COLOR_MENUHILIGHT = 29;
  COLOR_MENUBAR     = 30;
  WM_QUERYUISTATE   = $0129;
  WM_MOUSELEAVE     = $02A3;
  UISF_HIDEFOCUS    = 1;
  UISF_HIDEACCEL    = 2;

  ODT_MENU          = 1;
  ODS_SELECTED      = $0001;
  ODS_GRAYED        = $0002;
  ODS_DISABLED      = $0004;
  ODS_HOTLIGHT      = $0040;
  ODS_INACTIVE      = $0080;
  ODS_NOACCEL       = $0100;

  DT_CENTER         = $00000001;
  DT_VCENTER        = $00000004;
  DT_WORDBREAK      = $00000010;
  DT_SINGLELINE     = $00000020;
  DT_CALCRECT       = $00000400;
  DT_HIDEPREFIX     = $00100000;

  BS_GROUPBOX       = 7;
  BS_LEFTTEXT       = $0020;
  BS_ICON           = $0040;
  BS_BITMAP         = $0080;
  BS_PUSHLIKE       = $1000;
  BS_MULTILINE      = $2000;
  BST_PUSHED        = $0004;
  BST_FOCUS         = $0008;
  BST_HOT           = $0200;
  BCM_GETIMAGELIST  = $1603;

  TCM_GETITEMCOUNT  = $1304;
  TCM_GETITEMRECT   = $130A;
  TCM_GETCURSEL     = $130B;
  TCM_GETITEMW      = $133C;
  TCIF_TEXT         = $0001;
  TCS_BOTTOM        = $0002;
  TCS_VERTICAL      = $0080;
  TCS_BUTTONS       = $0100;
  TCS_OWNERDRAWFIXED = $2000;

  SB_SETBKCOLOR     = $2001;
  MIM_BACKGROUND    = $00000002;
  OBJID_MENU        = LongInt(-3);
  BF_DIAGONAL       = $0010;
  BF_MIDDLE         = $0800;
  BF_ADJUST         = $2000;
  BF_FLAT_OR_MONO   = $4000 or $8000;

  RDW_REPAINT_ALL   = RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN or RDW_FRAME;
  RDW_REPAINT_NOW   = RDW_INVALIDATE or RDW_UPDATENOW;

  BP_RADIOBUTTON    = 2;
  BP_CHECKBOX       = 3;
  TP_SEPARATOR      = 5;
  TP_SEPARATORVERT  = 6;
  TP_SPLITBUTTONDROPDOWN = 4;
  TP_DROPDOWNBUTTONGLYPH = 7;

type
  {$PACKRECORDS C}
  TMenuBarInfoRec = record
    cbSize: DWORD;
    rcBar: TRect;
    hMenu: HMENU;
    hwndMenu: HWND;
    Flags: DWORD;
  end;

  TDrawItemRec = record
    CtlType, CtlID, itemID, itemAction, itemState: UINT;
    hwndItem: HWND;
    hDC: HDC;
    rcItem: TRect;
    itemData: PtrUInt;
  end;
  PDrawItemRec = ^TDrawItemRec;

  TTabItemRec = record
    mask, dwState, dwStateMask: UINT;
    pszText: PWideChar;
    cchTextMax, iImage: LongInt;
    lParam: LPARAM;
  end;

  TMenuInfoRec = record
    cbSize, fMask, dwStyle: DWORD;
    cyMax: UINT;
    hbrBack: HBRUSH;
    dwContextHelpID: DWORD;
    dwMenuData: PtrUInt;
  end;

  TButtonImageListRec = record
    himl: THandle;
    margin: TRect;
    uAlign: UINT;
  end;

  TCWPRetRec = record
    lResult: LRESULT;
    lParam: LPARAM;
    wParam: WPARAM;
    message: UINT;
    hwnd: HWND;
  end;
  PCWPRetRec = ^TCWPRetRec;

  TOSVersionRec = record
    dwOSVersionInfoSize, dwMajorVersion, dwMinorVersion, dwBuildNumber, dwPlatformId: DWORD;
    szCSDVersion: array[0..127] of WideChar;
  end;
  {$PACKRECORDS DEFAULT}

  TGetSysColorFn = function(Index: LongInt): DWORD; stdcall;
  TGetSysColorBrushFn = function(Index: LongInt): HBRUSH; stdcall;
  TDrawEdgeFn = function(DC: HDC; var R: TRect; Edge, Flags: UINT): BOOL; stdcall;
  TFillRectFn = function(DC: HDC; const R: TRect; Brush: HBRUSH): LongInt; stdcall;
  TDeleteObjectFn = function(Obj: HGDIOBJ): BOOL; stdcall;
  TOpenThemeDataFn = function(Wnd: HWND; ClassList: PWideChar): THandle; stdcall;
  TDrawThemeBackgroundFn = function(Theme: THandle; DC: HDC; Part, State: LongInt;
    const R: TRect; Clip: PRect): HRESULT; stdcall;
  TGetThemeSysColorFn = function(Theme: THandle; ColorId: LongInt): DWORD; stdcall;
  TTaskDialogIndirectFn = function(Config, Button, Radio, Verify: Pointer): HRESULT; stdcall;
  TSubclassProc = function(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM;
    Id, RefData: PtrUInt): LRESULT; stdcall;

  TSubclassKind = (skTopWindow, skEdge, skTabs, skStatusBar, skButton, skCombo, skComboEdit,
    skDialog);

  TWinControlAccess = class(TWinControl);

function FillRect(DC: HDC; const R: TRect; Brush: HBRUSH): LongInt; stdcall; external 'user32.dll';
function DrawTextW(DC: HDC; Text: PWideChar; Count: LongInt; var R: TRect; Format: UINT): LongInt; stdcall; external 'user32.dll';
function DrawFocusRect(DC: HDC; const R: TRect): BOOL; stdcall; external 'user32.dll';
function GetWindowRect(Wnd: HWND; var R: TRect): BOOL; stdcall; external 'user32.dll';
function GetClientRect(Wnd: HWND; var R: TRect): BOOL; stdcall; external 'user32.dll';
function ClientToScreen(Wnd: HWND; var P: TPoint): BOOL; stdcall; external 'user32.dll';
function MapWindowPoints(WndFrom, WndTo: HWND; Points: Pointer; Count: UINT): LongInt; stdcall; external 'user32.dll';
function GetWindowDC(Wnd: HWND): HDC; stdcall; external 'user32.dll';
function ReleaseDC(Wnd: HWND; DC: HDC): LongInt; stdcall; external 'user32.dll';
function GetParent(Wnd: HWND): HWND; stdcall; external 'user32.dll';
function GetAncestor(Wnd: HWND; Flags: UINT): HWND; stdcall; external 'user32.dll';
function GetClassNameW(Wnd: HWND; Buf: PWideChar; MaxCount: LongInt): LongInt; stdcall; external 'user32.dll';
function GetWindowTextW(Wnd: HWND; Buf: PWideChar; MaxCount: LongInt): LongInt; stdcall; external 'user32.dll';
function SetPropW(Wnd: HWND; Name: PWideChar; Data: THandle): BOOL; stdcall; external 'user32.dll';
function GetPropW(Wnd: HWND; Name: PWideChar): THandle; stdcall; external 'user32.dll';
function RemovePropW(Wnd: HWND; Name: PWideChar): THandle; stdcall; external 'user32.dll';
function SetWindowPos(Wnd, InsertAfter: HWND; X, Y, CX, CY: LongInt; Flags: UINT): BOOL; stdcall; external 'user32.dll';
function SendMessageW(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM): LRESULT; stdcall; external 'user32.dll';
function InvalidateRect(Wnd: HWND; R: Pointer; Erase: BOOL): BOOL; stdcall; external 'user32.dll';
function RedrawWindow(Wnd: HWND; R: Pointer; Rgn: THandle; Flags: UINT): BOOL; stdcall; external 'user32.dll';
function GetSystemMetrics(Index: LongInt): LongInt; stdcall; external 'user32.dll';
function GetMenuBarInfo(Wnd: HWND; Obj, Item: LongInt; var Info: TMenuBarInfoRec): BOOL; stdcall; external 'user32.dll';
function GetMenuInfo(Menu: HMENU; var Info: TMenuInfoRec): BOOL; stdcall; external 'user32.dll';
function SetMenuInfo(Menu: HMENU; const Info: TMenuInfoRec): BOOL; stdcall; external 'user32.dll';
function DrawMenuBar(Wnd: HWND): BOOL; stdcall; external 'user32.dll';
function SetWindowsHookExW(Kind: LongInt; Proc: Pointer; Inst: HMODULE; ThreadId: DWORD): THandle; stdcall; external 'user32.dll';
function CallNextHookEx(Hook: THandle; Code: LongInt; WP: WPARAM; LP: LPARAM): LRESULT; stdcall; external 'user32.dll';
function ExcludeClipRect(DC: HDC; L, T, R, B: LongInt): LongInt; stdcall; external 'gdi32.dll';
function IntersectClipRect(DC: HDC; L, T, R, B: LongInt): LongInt; stdcall; external 'gdi32.dll';
function SaveDC(DC: HDC): LongInt; stdcall; external 'gdi32.dll';
function RestoreDC(DC: HDC; Saved: LongInt): BOOL; stdcall; external 'gdi32.dll';
function OffsetViewportOrgEx(DC: HDC; X, Y: LongInt; Old: Pointer): BOOL; stdcall; external 'gdi32.dll';
function GetModuleFileNameW(Module: HMODULE; Buf: PWideChar; Size: DWORD): DWORD; stdcall; external 'kernel32.dll';

var
  WinBuild: DWORD = 0;
  Brushes: array[TDarkColor] of HBRUSH;
  SysBrushes: array[0..31] of HBRUSH;

  OrigGetSysColor: TGetSysColorFn = nil;
  OrigGetSysColorBrush: TGetSysColorBrushFn = nil;
  OrigDrawEdge: TDrawEdgeFn = nil;
  OrigFillRect: TFillRectFn = nil;
  OrigDeleteObject: TDeleteObjectFn = nil;
  OrigOpenThemeData: TOpenThemeDataFn = nil;
  OrigDrawThemeBackground: TDrawThemeBackgroundFn = nil;
  OrigGetThemeSysColor: TGetThemeSysColorFn = nil;
  OrigTaskDialogExtra: TTaskDialogIndirectFn = nil;
  OrigTaskDialogCommCtrl: TTaskDialogIndirectFn = nil;
  ToolbarTheme: THandle = 0;
  MenuHook: THandle = 0;
  CreateHook: THandle = 0;

  SetPreferredAppMode: function(Mode: LongInt): LongInt; stdcall = nil;
  AllowDarkModeForWindow: function(Wnd: HWND; Allow: BOOL): BOOL; stdcall = nil;
  FlushMenuThemes: procedure; stdcall = nil;
  RefreshImmersiveColorPolicyState: procedure; stdcall = nil;
  SetWindowTheme: function(Wnd: HWND; SubApp, SubIdList: PWideChar): LongInt; stdcall = nil;
  DwmSetWindowAttribute: function(Wnd: HWND; Attr: DWORD; Value: Pointer; Size: DWORD): LongInt; stdcall = nil;
  SetWindowSubclass: function(Wnd: HWND; Proc: TSubclassProc; Id, RefData: PtrUInt): BOOL; stdcall = nil;
  DefSubclassProc: function(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM): LRESULT; stdcall = nil;
  RemoveWindowSubclass: function(Wnd: HWND; Proc: TSubclassProc; Id: PtrUInt): BOOL; stdcall = nil;

procedure FillBox(DC: HDC; L, T, R, B: LongInt; Brush: HBRUSH);
var
  Rc: TRect;
begin
  Rc.Left := L;
  Rc.Top := T;
  Rc.Right := R;
  Rc.Bottom := B;
  FillRect(DC, Rc, Brush);
end;

procedure Shrink(var R: TRect; DX, DY: LongInt);
begin
  R.Left := R.Left + DX;
  R.Right := R.Right - DX;
  R.Top := R.Top + DY;
  R.Bottom := R.Bottom - DY;
end;

procedure DrawFrame(DC: HDC; const R: TRect; Brush: HBRUSH);
begin
  FillBox(DC, R.Left, R.Top, R.Right, R.Top + 1, Brush);
  FillBox(DC, R.Left, R.Bottom - 1, R.Right, R.Bottom, Brush);
  FillBox(DC, R.Left, R.Top, R.Left + 1, R.Bottom, Brush);
  FillBox(DC, R.Right - 1, R.Top, R.Right, R.Bottom, Brush);
end;

procedure ExcludeChildren(Wnd: HWND; DC: HDC);
var
  Child: HWND;
  R: TRect;
begin
  Child := GetWindow(Wnd, GW_CHILD);
  while Child <> 0 do
  begin
    if IsWindowVisible(Child) and GetWindowRect(Child, R) then
    begin
      MapWindowPoints(0, Wnd, @R, 2);
      ExcludeClipRect(DC, R.Left, R.Top, R.Right, R.Bottom);
    end;
    Child := GetWindow(Child, GW_HWNDNEXT);
  end;
end;

function WndClass(Wnd: HWND): string;
var
  Buf: array[0..127] of WideChar;
  Name: UnicodeString;
  N: LongInt;
begin
  N := GetClassNameW(Wnd, @Buf[0], Length(Buf));
  if N < 0 then N := 0;
  SetString(Name, PWideChar(@Buf[0]), N);
  Result := LowerCase(string(Name));
end;

function WindowText(Wnd: HWND): UnicodeString;
var
  Buf: array[0..511] of WideChar;
  N: LongInt;
begin
  N := GetWindowTextW(Wnd, @Buf[0], Length(Buf));
  if N < 0 then N := 0;
  SetString(Result, PWideChar(@Buf[0]), N);
end;

function PrefixFlags(Wnd: HWND): UINT;
begin
  Result := 0;
  if (SendMessageW(Wnd, WM_QUERYUISTATE, 0, 0) and UISF_HIDEACCEL) <> 0 then
    Result := DT_HIDEPREFIX;
end;

function SelectWindowFont(Wnd: HWND; DC: HDC): HGDIOBJ;
begin
  Result := SelectObject(DC, HGDIOBJ(SendMessageW(Wnd, WM_GETFONT, 0, 0)));
end;

procedure DrawTextIn(DC: HDC; const Text: UnicodeString; R: TRect; Flags: UINT);
begin
  if Text <> '' then
    DrawTextW(DC, PWideChar(Text), Length(Text), R, Flags);
end;

procedure DrawDownArrow(DC: HDC; const R: TRect; Brush: HBRUSH);
var
  W, H, X, Y, I: LongInt;
begin
  W := (R.Right - R.Left) div 2;
  if W > 11 then W := 11;
  if W < 5 then W := 5;
  if not Odd(W) then Dec(W);
  H := W div 2 + 1;
  X := (R.Left + R.Right - W) div 2;
  Y := (R.Top + R.Bottom - H) div 2;
  for I := 0 to H - 1 do
    FillBox(DC, X + I, Y + I, X + W - I, Y + I + 1, Brush);
end;

function HookGetSysColor(Index: LongInt): DWORD; stdcall;
var
  Role: TDarkColor;
begin
  if SysColorRole(Index, Role) then
    Result := Colors[Role]
  else
    Result := OrigGetSysColor(Index);
end;

function HookGetSysColorBrush(Index: LongInt): HBRUSH; stdcall;
var
  Role: TDarkColor;
begin
  if (Index >= Low(SysBrushes)) and (Index <= High(SysBrushes)) and SysColorRole(Index, Role) then
  begin
    if (SysBrushes[Index] = 0) or (GetObjectType(SysBrushes[Index]) <> OBJ_BRUSH) then
      SysBrushes[Index] := CreateSolidBrush(Colors[Role]);
    Result := SysBrushes[Index];
  end
  else
    Result := OrigGetSysColorBrush(Index);
end;

function HookFillRect(DC: HDC; const R: TRect; Brush: HBRUSH): LongInt; stdcall;
var
  Role: TDarkColor;
begin
  if (PtrUInt(Brush) >= 1) and (PtrUInt(Brush) <= 32) and
    SysColorRole(LongInt(PtrUInt(Brush)) - 1, Role) then
    Result := OrigFillRect(DC, R, Brushes[Role])
  else
    Result := OrigFillRect(DC, R, Brush);
end;

function HookDeleteObject(Obj: HGDIOBJ): BOOL; stdcall;
var
  I: LongInt;
  C: TDarkColor;
begin
  if Obj <> 0 then
  begin
    for I := Low(SysBrushes) to High(SysBrushes) do
      if SysBrushes[I] = Obj then Exit(True);
    for C := Low(TDarkColor) to High(TDarkColor) do
      if Brushes[C] = Obj then Exit(True);
  end;
  Result := OrigDeleteObject(Obj);
end;

function HookDrawEdge(DC: HDC; var R: TRect; Edge, Flags: UINT): BOOL; stdcall;
var
  Rc: TRect;
  Layers: array[0..1] of UINT;
  Count, I: LongInt;
  TopLeft, BottomRight: HBRUSH;
begin
  if (Flags and BF_DIAGONAL) <> 0 then
    Exit(OrigDrawEdge(DC, R, Edge, Flags));

  Rc := R;
  Count := 0;
  if (Edge and 3) <> 0 then
  begin
    Layers[Count] := Edge and 3;
    Inc(Count);
  end;
  if (Edge and 12) <> 0 then
  begin
    Layers[Count] := (Edge and 12) shr 2;
    Inc(Count);
  end;

  for I := 0 to Count - 1 do
  begin
    if (Flags and BF_FLAT_OR_MONO) <> 0 then
    begin
      TopLeft := Brushes[dcShadow];
      BottomRight := Brushes[dcShadow];
    end
    else if Layers[I] = 1 then
    begin
      TopLeft := Brushes[dcShadow];
      BottomRight := Brushes[dcEdgeDark];
    end
    else
    begin
      TopLeft := Brushes[dcEdgeDark];
      BottomRight := Brushes[dcShadow];
    end;
    if (Flags and BF_LEFT) <> 0 then FillBox(DC, Rc.Left, Rc.Top, Rc.Left + 1, Rc.Bottom, TopLeft);
    if (Flags and BF_TOP) <> 0 then FillBox(DC, Rc.Left, Rc.Top, Rc.Right, Rc.Top + 1, TopLeft);
    if (Flags and BF_RIGHT) <> 0 then FillBox(DC, Rc.Right - 1, Rc.Top, Rc.Right, Rc.Bottom, BottomRight);
    if (Flags and BF_BOTTOM) <> 0 then FillBox(DC, Rc.Left, Rc.Bottom - 1, Rc.Right, Rc.Bottom, BottomRight);
    if (Flags and BF_LEFT) <> 0 then Inc(Rc.Left);
    if (Flags and BF_TOP) <> 0 then Inc(Rc.Top);
    if (Flags and BF_RIGHT) <> 0 then Dec(Rc.Right);
    if (Flags and BF_BOTTOM) <> 0 then Dec(Rc.Bottom);
  end;

  if (Flags and BF_MIDDLE) <> 0 then
    FillRect(DC, Rc, Brushes[dcWindow]);
  if (Flags and BF_ADJUST) <> 0 then
    R := Rc;
  Result := True;
end;

function PatchIAT(Module: HMODULE; Original, Replacement: Pointer): Integer;
var
  Base, NT, Desc: PByte;
  Magic: Word;
  DirOffset: PtrUInt;
  ImportRVA, OldProtect: DWORD;
  Thunk: PPointer;
begin
  Result := 0;
  if (Module = 0) or (Original = nil) then Exit;
  Base := PByte(Module);
  if PWord(Base)^ <> $5A4D then Exit;
  NT := Base + PLongInt(Base + $3C)^;
  if PDWord(NT)^ <> $00004550 then Exit;
  Magic := PWord(NT + 24)^;
  if Magic = $20B then DirOffset := 24 + 112
  else if Magic = $10B then DirOffset := 24 + 96
  else Exit;
  ImportRVA := PDWord(NT + DirOffset + 8)^;
  if ImportRVA = 0 then Exit;
  Desc := Base + ImportRVA;
  while PDWord(Desc + 12)^ <> 0 do
  begin
    if PDWord(Desc + 16)^ <> 0 then
    begin
      Thunk := PPointer(Base + PDWord(Desc + 16)^);
      while Thunk^ <> nil do
      begin
        if (Thunk^ = Original) and
          VirtualProtect(Thunk, SizeOf(Pointer), PAGE_READWRITE, @OldProtect) then
        begin
          Thunk^ := Replacement;
          VirtualProtect(Thunk, SizeOf(Pointer), OldProtect, @OldProtect);
          Inc(Result);
        end;
        Inc(Thunk);
      end;
    end;
    Inc(Desc, 20);
  end;
end;

function IsComCtl32(Module: HMODULE): Boolean;
var
  Buf: array[0..1023] of WideChar;
  Path: UnicodeString;
  N: DWORD;
begin
  N := GetModuleFileNameW(Module, @Buf[0], Length(Buf));
  Result := False;
  if (N = 0) or (N >= Length(Buf)) then Exit;
  SetString(Path, PWideChar(@Buf[0]), N);
  Result := SameText(ExtractFileName(string(Path)), 'comctl32.dll') or
    SameText(ExtractFileName(string(Path)), 'comdlg32.dll');
end;

procedure PatchImports(Original, Replacement: Pointer);
var
  EnumProcessModules: function(Process: THandle; Mods: Pointer; Size: DWORD;
    var Needed: DWORD): BOOL; stdcall;
  Mods: array[0..1023] of HMODULE;
  Needed: DWORD;
  I: LongInt;
begin
  PatchIAT(GetModuleHandleW(nil), Original, Replacement);
  Pointer(EnumProcessModules) := GetProcAddress(GetModuleHandleW('kernel32.dll'), 'K32EnumProcessModules');
  if not Assigned(EnumProcessModules) then Exit;
  Needed := 0;
  if not EnumProcessModules(GetCurrentProcess, @Mods[0], SizeOf(Mods), Needed) then Exit;
  for I := 0 to LongInt(Needed div SizeOf(HMODULE)) - 1 do
    if (I <= High(Mods)) and IsComCtl32(Mods[I]) then
      PatchIAT(Mods[I], Original, Replacement);
end;

procedure PatchAllImports;
begin
  PatchImports(Pointer(OrigGetSysColor), @HookGetSysColor);
  PatchImports(Pointer(OrigGetSysColorBrush), @HookGetSysColorBrush);
  PatchImports(Pointer(OrigDrawEdge), @HookDrawEdge);
  PatchImports(Pointer(OrigFillRect), @HookFillRect);
  PatchImports(Pointer(OrigDeleteObject), @HookDeleteObject);
end;

function DarkThemeClass(const ClassList: string): UnicodeString;
begin
  case ClassList of
    'button':             Result := 'DarkMode_Explorer::Button;Button';
    'combobox':           Result := 'DarkMode_CFD::Combobox;Combobox';
    'edit':               Result := 'DarkMode_CFD::Edit;Edit';
    'header':             Result := 'DarkMode_ItemsView::Header;Header';
    'explorer::listview': Result := 'DarkMode_ItemsView::ListView;Explorer::ListView';
    'scrollbar':          Result := 'DarkMode_Explorer::ScrollBar;ScrollBar';
    'explorer::treeview': Result := 'DarkMode_Explorer::TreeView;Explorer::TreeView';
    'tooltip':            Result := 'DarkMode_Explorer::Tooltip;Tooltip';
  else
    Result := '';
  end;
end;

function HookOpenThemeData(Wnd: HWND; ClassList: PWideChar): THandle; stdcall;
var
  Name: string;
  Dark: UnicodeString;
begin
  if (Wnd <> 0) or (ClassList = nil) then
    Exit(OrigOpenThemeData(Wnd, ClassList));
  Name := LowerCase(string(UnicodeString(ClassList)));
  Dark := DarkThemeClass(Name);
  Result := 0;
  if Dark <> '' then
    Result := OrigOpenThemeData(Wnd, PWideChar(Dark));
  if Result = 0 then
    Result := OrigOpenThemeData(Wnd, ClassList);
  if Name = 'toolbar' then
    ToolbarTheme := Result;
end;

procedure DrawToolbarPart(DC: HDC; const R: TRect; Part, State: LongInt);
var
  Back: HBRUSH;
  Mid: LongInt;
begin
  if Part = TP_SEPARATOR then
  begin
    Mid := (R.Left + R.Right) div 2;
    FillBox(DC, Mid, R.Top + 2, Mid + 1, R.Bottom - 2, Brushes[dcBorder]);
    Exit;
  end;
  if Part = TP_SEPARATORVERT then
  begin
    Mid := (R.Top + R.Bottom) div 2;
    FillBox(DC, R.Left + 2, Mid, R.Right - 2, Mid + 1, Brushes[dcBorder]);
    Exit;
  end;

  case State of
    2, 7:    Back := Brushes[dcHot];
    3, 5, 6: Back := Brushes[dcPressed];
  else
    Back := 0;
  end;
  if (Back <> 0) and (Part <> TP_DROPDOWNBUTTONGLYPH) then
  begin
    FillRect(DC, R, Back);
    DrawFrame(DC, R, Brushes[dcBorder]);
  end;

  if (Part = TP_SPLITBUTTONDROPDOWN) or (Part = TP_DROPDOWNBUTTONGLYPH) then
    if State = 4 then
      DrawDownArrow(DC, R, Brushes[dcGrayText])
    else
      DrawDownArrow(DC, R, Brushes[dcText]);
end;

function HookDrawThemeBackground(Theme: THandle; DC: HDC; Part, State: LongInt;
  const R: TRect; Clip: PRect): HRESULT; stdcall;
var
  Saved: LongInt;
begin
  if (Theme = 0) or (Theme <> ToolbarTheme) or (Part < 1) or (Part > 7) then
    Exit(OrigDrawThemeBackground(Theme, DC, Part, State, R, Clip));
  Saved := SaveDC(DC);
  if Clip <> nil then
    IntersectClipRect(DC, Clip^.Left, Clip^.Top, Clip^.Right, Clip^.Bottom);
  DrawToolbarPart(DC, R, Part, State);
  RestoreDC(DC, Saved);
  Result := S_OK;
end;

function HookGetThemeSysColor(Theme: THandle; ColorId: LongInt): DWORD; stdcall;
var
  Role: TDarkColor;
begin
  if SysColorRole(ColorId, Role) then
    Result := Colors[Role]
  else
    Result := OrigGetThemeSysColor(Theme, ColorId);
end;

procedure InstallThemeHooks;
begin
  if Assigned(OrigOpenThemeData) or not Assigned(UxTheme.OpenThemeData) then Exit;
  Pointer(OrigOpenThemeData) := Pointer(UxTheme.OpenThemeData);
  Pointer(UxTheme.OpenThemeData) := @HookOpenThemeData;
  if Assigned(UxTheme.GetThemeSysColor) then
  begin
    Pointer(OrigGetThemeSysColor) := Pointer(UxTheme.GetThemeSysColor);
    Pointer(UxTheme.GetThemeSysColor) := @HookGetThemeSysColor;
  end;
  if Assigned(UxTheme.DrawThemeBackground) then
  begin
    Pointer(OrigDrawThemeBackground) := Pointer(UxTheme.DrawThemeBackground);
    Pointer(UxTheme.DrawThemeBackground) := @HookDrawThemeBackground;
  end;
  ThemeServices.UpdateThemes;
end;

function TaskDialogText(P: PWideChar): string;
begin
  if PtrUInt(P) < $10000 then
    Result := ''
  else
    Result := UTF8Encode(UnicodeString(P));
end;

procedure AddDialogButton(Buttons: TDialogButtons; ID: LongInt; const Caption: string;
  DefaultID: LongInt);
var
  B: TDialogButton;
begin
  B := Buttons.Add;
  B.Caption := Caption;
  B.ModalResult := ID;
  if ID = DefaultID then Buttons.DefaultButton := B;
  if ID = IDCANCEL then Buttons.CancelButton := B;
end;

procedure AppendParagraph(var Text: string; const Paragraph: string);
begin
  if Paragraph = '' then Exit;
  if Text <> '' then Text := Text + LineEnding + LineEnding;
  Text := Text + Paragraph;
end;

function EmulateTaskDialog(P: PTASKDIALOGCONFIG; Button: PInteger): HRESULT;
var
  Buttons: TDialogButtons;
  Custom: PTASKDIALOG_BUTTON;
  I, DialogType, ModalResult: LongInt;
  Msg: string;
begin
  Result := E_NOTIMPL_;
  if Assigned(P^.pfCallback) or (P^.cRadioButtons > 0) or
    (P^.pszVerificationText <> nil) or (P^.pszExpandedInformation <> nil) or
    ((P^.cButtons = 0) and (P^.dwCommonButtons = 0)) then Exit;

  Msg := '';
  AppendParagraph(Msg, TaskDialogText(P^.pszMainInstruction));
  AppendParagraph(Msg, TaskDialogText(P^.pszContent));
  AppendParagraph(Msg, TaskDialogText(P^.pszFooter));

  if (P^.dwFlags and TDF_USE_HICON_MAIN) <> 0 then
  begin
    if P^.hMainIcon <> 0 then DialogType := idDialogConfirm else DialogType := idDialogInfo;
  end
  else
    case PtrUInt(P^.pszMainIcon) and $FFFF of
      $FFFF: DialogType := idDialogWarning;
      $FFFE: DialogType := idDialogError;
      $FFFC: DialogType := idDialogShield;
    else
      DialogType := idDialogInfo;
    end;

  Buttons := TDialogButtons.Create(TDialogButton);
  try
    Custom := P^.pButtons;
    for I := 0 to LongInt(P^.cButtons) - 1 do
      AddDialogButton(Buttons, Custom[I].nButtonID, TaskDialogText(Custom[I].pszButtonText),
        P^.nDefaultButton);
    if (P^.dwCommonButtons and TDCBF_OK_BUTTON) <> 0 then AddDialogButton(Buttons, IDOK, rsMbOK, P^.nDefaultButton);
    if (P^.dwCommonButtons and TDCBF_YES_BUTTON) <> 0 then AddDialogButton(Buttons, IDYES, rsMbYes, P^.nDefaultButton);
    if (P^.dwCommonButtons and TDCBF_NO_BUTTON) <> 0 then AddDialogButton(Buttons, IDNO, rsMbNo, P^.nDefaultButton);
    if (P^.dwCommonButtons and TDCBF_RETRY_BUTTON) <> 0 then AddDialogButton(Buttons, IDRETRY, rsMbRetry, P^.nDefaultButton);
    if (P^.dwCommonButtons and TDCBF_CANCEL_BUTTON) <> 0 then AddDialogButton(Buttons, IDCANCEL, rsMbCancel, P^.nDefaultButton);
    if (P^.dwCommonButtons and TDCBF_CLOSE_BUTTON) <> 0 then AddDialogButton(Buttons, IDCLOSE, rsMbClose, P^.nDefaultButton);
    if Buttons.DefaultButton = nil then
      Buttons.DefaultButton := Buttons[0];
    ModalResult := DefaultQuestionDialog(TaskDialogText(P^.pszWindowTitle), Msg,
      DialogType, Buttons, 0);
  finally
    Buttons.Free;
  end;
  if Button <> nil then
    Button^ := ModalResult;
  Result := S_OK;
end;

function RunTaskDialog(Orig: TTaskDialogIndirectFn; Config, Button, Radio, Verify: Pointer): HRESULT;
begin
  if Config <> nil then
  begin
    try
      Result := EmulateTaskDialog(PTASKDIALOGCONFIG(Config), PInteger(Button));
    except
      Result := E_NOTIMPL_;
    end;
    if (Result = S_OK) or Assigned(PTASKDIALOGCONFIG(Config)^.pfCallback) then Exit;
  end;
  if Assigned(Orig) then
    Result := Orig(Config, Button, Radio, Verify)
  else
    Result := E_NOTIMPL_;
end;

function TaskDialogExtra(Config, Button, Radio, Verify: Pointer): HRESULT; stdcall;
begin
  Result := RunTaskDialog(OrigTaskDialogExtra, Config, Button, Radio, Verify);
end;

function TaskDialogCommCtrl(Config, Button, Radio, Verify: Pointer): HRESULT; stdcall;
begin
  Result := RunTaskDialog(OrigTaskDialogCommCtrl, Config, Button, Radio, Verify);
end;

procedure InstallTaskDialogHooks;
begin
  if Assigned(OrigTaskDialogExtra) or Assigned(OrigTaskDialogCommCtrl) then Exit;
  Pointer(OrigTaskDialogExtra) := Pointer(Win32Extra.TaskDialogIndirect);
  Pointer(Win32Extra.TaskDialogIndirect) := @TaskDialogExtra;
  Pointer(OrigTaskDialogCommCtrl) := Pointer(CommCtrl.TaskDialogIndirect);
  Pointer(CommCtrl.TaskDialogIndirect) := @TaskDialogCommCtrl;
end;

procedure SetMenuBackground(Menu: HMENU; Brush: HBRUSH);
var
  Info: TMenuInfoRec;
begin
  if Menu = 0 then Exit;
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(Info);
  Info.fMask := MIM_BACKGROUND;
  if GetMenuInfo(Menu, Info) and (Info.hbrBack = Brush) then Exit;
  Info.fMask := MIM_BACKGROUND;
  Info.hbrBack := Brush;
  SetMenuInfo(Menu, Info);
end;

procedure ApplyMenuBarBackground(Wnd: HWND);
var
  Menu: HMENU;
  Info: TMenuInfoRec;
begin
  Menu := GetMenu(Wnd);
  if Menu = 0 then Exit;
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(Info);
  Info.fMask := MIM_BACKGROUND;
  if GetMenuInfo(Menu, Info) and (Info.hbrBack = Brushes[dcWindow]) then Exit;
  SetMenuBackground(Menu, Brushes[dcWindow]);
  DrawMenuBar(Wnd);
end;

procedure DrawMenuBarItem(Wnd: HWND; DIS: PDrawItemRec; const Caption: UnicodeString);
var
  Back: HBRUSH;
  TextColor: DWORD;
  Flags: UINT;
  OldFont: HGDIOBJ;
begin
  Back := Brushes[dcWindow];
  if (DIS^.itemState and ODS_HOTLIGHT) <> 0 then Back := Brushes[dcHot];
  if (DIS^.itemState and ODS_SELECTED) <> 0 then Back := Brushes[dcPressed];
  TextColor := Colors[dcText];
  if (DIS^.itemState and ODS_INACTIVE) <> 0 then TextColor := Colors[dcTabText];
  if (DIS^.itemState and (ODS_GRAYED or ODS_DISABLED)) <> 0 then TextColor := Colors[dcGrayText];
  Flags := DT_CENTER or DT_SINGLELINE or DT_VCENTER;
  if (DIS^.itemState and ODS_NOACCEL) <> 0 then Flags := Flags or DT_HIDEPREFIX;

  FillRect(DIS^.hDC, DIS^.rcItem, Back);
  OldFont := SelectObject(DIS^.hDC, HGDIOBJ(Screen.MenuFont.Handle));
  SetBkMode(DIS^.hDC, TRANSPARENT);
  SetTextColor(DIS^.hDC, TextColor);
  DrawTextIn(DIS^.hDC, Caption, DIS^.rcItem, Flags);
  SelectObject(DIS^.hDC, OldFont);
end;

function DrawOwnerMenuBarItem(Wnd: HWND; DIS: PDrawItemRec): Boolean;
var
  Control: TWinControl;
  Menu: TMainMenu;
  I: LongInt;
begin
  Result := False;
  if (DIS^.CtlType <> ODT_MENU) or (HMENU(DIS^.hwndItem) <> GetMenu(Wnd)) then Exit;
  Control := FindControl(Wnd);
  if not (Control is TCustomForm) then Exit;
  Menu := TCustomForm(Control).Menu;
  if Menu = nil then Exit;
  for I := 0 to Menu.Items.Count - 1 do
    if PtrUInt(Menu.Items[I]) = DIS^.itemData then
    begin
      DrawMenuBarItem(Wnd, DIS, UTF8Decode(Menu.Items[I].Caption));
      Exit(True);
    end;
end;

procedure DrawMenuBarBottomLine(Wnd: HWND);
var
  Info: TMenuBarInfoRec;
  WR: TRect;
  P: TPoint;
  DC: HDC;
  Y: LongInt;
begin
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(Info);
  if not GetMenuBarInfo(Wnd, OBJID_MENU, 0, Info) then Exit;
  if (Info.rcBar.Right <= Info.rcBar.Left) or not GetWindowRect(Wnd, WR) then Exit;
  P.X := 0;
  P.Y := 0;
  ClientToScreen(Wnd, P);
  Y := P.Y - WR.Top;
  DC := GetWindowDC(Wnd);
  if DC = 0 then Exit;
  FillBox(DC, 0, Y - 1, WR.Right - WR.Left, Y, Brushes[dcWindow]);
  ReleaseDC(Wnd, DC);
end;

procedure PaintPopupMenuFrame(Wnd: HWND; GivenDC: HDC);
var
  WR, CR: TRect;
  P: TPoint;
  DC: HDC;
  W, H, CL, CT, Saved: LongInt;
  BorderColor: DWORD;
begin
  if not (GetWindowRect(Wnd, WR) and GetClientRect(Wnd, CR)) then Exit;
  W := WR.Right - WR.Left;
  H := WR.Bottom - WR.Top;
  P.X := 0;
  P.Y := 0;
  ClientToScreen(Wnd, P);
  CL := P.X - WR.Left;
  CT := P.Y - WR.Top;
  if (CL <= 0) and (CT <= 0) then Exit;

  if GivenDC <> 0 then DC := GivenDC else DC := GetWindowDC(Wnd);
  if DC = 0 then Exit;
  Saved := SaveDC(DC);
  ExcludeClipRect(DC, CL, CT, CL + CR.Right, CT + CR.Bottom);
  FillBox(DC, 0, 0, W, H, Brushes[dcMenu]);
  FillBox(DC, 0, 0, W, 1, Brushes[dcBorder]);
  FillBox(DC, 0, H - 1, W, H, Brushes[dcBorder]);
  FillBox(DC, 0, 0, 1, H, Brushes[dcBorder]);
  FillBox(DC, W - 1, 0, W, H, Brushes[dcBorder]);
  RestoreDC(DC, Saved);
  if GivenDC = 0 then ReleaseDC(Wnd, DC);

  if (WinBuild >= 22000) and Assigned(DwmSetWindowAttribute) then
  begin
    BorderColor := Colors[dcBorder];
    DwmSetWindowAttribute(Wnd, 34, @BorderColor, SizeOf(BorderColor));
  end;
end;

procedure ThemeNativeDialog(Wnd: HWND); forward;

function MenuMessageHook(Code: LongInt; WP: WPARAM; LP: LPARAM): LRESULT; stdcall;
var
  Msg: PCWPRetRec;
begin
  if Code = HC_ACTION then
  try
    Msg := PCWPRetRec(LP);
    case Msg^.message of
      WM_INITDIALOG:
        if WndClass(Msg^.hwnd) = '#32770' then
          ThemeNativeDialog(Msg^.hwnd);
      WM_INITMENUPOPUP:
        SetMenuBackground(HMENU(Msg^.wParam), Brushes[dcMenu]);
      WM_NCPAINT:
        if WndClass(Msg^.hwnd) = '#32768' then
          PaintPopupMenuFrame(Msg^.hwnd, 0);
      WM_PRINT:
        if ((Msg^.lParam and PRF_NONCLIENT) <> 0) and (WndClass(Msg^.hwnd) = '#32768') then
          PaintPopupMenuFrame(Msg^.hwnd, HDC(Msg^.wParam));
    end;
  except
  end;
  Result := CallNextHookEx(MenuHook, Code, WP, LP);
end;

function CreateWindowHook(Code: LongInt; WP: WPARAM; LP: LPARAM): LRESULT; stdcall;
begin
  if Code = HCBT_CREATEWND then
    AllowDarkModeForWindow(HWND(WP), True);
  Result := CallNextHookEx(CreateHook, Code, WP, LP);
end;

procedure PaintTabs(Wnd: HWND; DC: HDC);
var
  CR, IR, TR: TRect;
  Count, I, Current, MinTop, MaxBottom, LineY: LongInt;
  Item: TTabItemRec;
  Buf: array[0..255] of WideChar;
  AtBottom, Selected: Boolean;
  OldFont: HGDIOBJ;
begin
  GetClientRect(Wnd, CR);
  AtBottom := (GetWindowLongW(Wnd, GWL_STYLE) and TCS_BOTTOM) <> 0;
  Count := LongInt(SendMessageW(Wnd, TCM_GETITEMCOUNT, 0, 0));
  Current := LongInt(SendMessageW(Wnd, TCM_GETCURSEL, 0, 0));

  FillRect(DC, CR, Brushes[dcWindow]);
  if Count <= 0 then Exit;

  MinTop := CR.Bottom;
  MaxBottom := 0;
  for I := 0 to Count - 1 do
  begin
    SendMessageW(Wnd, TCM_GETITEMRECT, I, LPARAM(@IR));
    if IR.Top < MinTop then MinTop := IR.Top;
    if IR.Bottom > MaxBottom then MaxBottom := IR.Bottom;
  end;

  if AtBottom then
  begin
    LineY := MinTop;
    FillBox(DC, 0, 0, CR.Right, 1, Brushes[dcBorder]);
    FillBox(DC, 0, 0, 1, LineY, Brushes[dcBorder]);
    FillBox(DC, CR.Right - 1, 0, CR.Right, LineY, Brushes[dcBorder]);
  end
  else
  begin
    LineY := MaxBottom - 1;
    FillBox(DC, 0, CR.Bottom - 1, CR.Right, CR.Bottom, Brushes[dcBorder]);
    FillBox(DC, 0, LineY, 1, CR.Bottom, Brushes[dcBorder]);
    FillBox(DC, CR.Right - 1, LineY, CR.Right, CR.Bottom, Brushes[dcBorder]);
  end;
  FillBox(DC, 0, LineY, CR.Right, LineY + 1, Brushes[dcBorder]);

  OldFont := SelectWindowFont(Wnd, DC);
  SetBkMode(DC, TRANSPARENT);
  for I := 0 to Count - 1 do
  begin
    SendMessageW(Wnd, TCM_GETITEMRECT, I, LPARAM(@IR));
    Selected := I = Current;
    if Selected then
      FillRect(DC, IR, Brushes[dcActiveTab])
    else
      FillRect(DC, IR, Brushes[dcEdit]);

    FillBox(DC, IR.Left, IR.Top, IR.Left + 1, IR.Bottom, Brushes[dcBorder]);
    FillBox(DC, IR.Right - 1, IR.Top, IR.Right, IR.Bottom, Brushes[dcBorder]);
    if AtBottom then
      FillBox(DC, IR.Left, IR.Bottom - 1, IR.Right, IR.Bottom, Brushes[dcBorder])
    else
      FillBox(DC, IR.Left, IR.Top, IR.Right, IR.Top + 1, Brushes[dcBorder]);

    if Selected then
    begin
      FillBox(DC, IR.Left + 1, LineY, IR.Right - 1, LineY + 1, Brushes[dcActiveTab]);
      if AtBottom then
        FillBox(DC, IR.Left + 1, IR.Bottom - 3, IR.Right - 1, IR.Bottom - 1, Brushes[dcAccent])
      else
        FillBox(DC, IR.Left + 1, IR.Top + 1, IR.Right - 1, IR.Top + 3, Brushes[dcAccent]);
      SetTextColor(DC, Colors[dcText]);
    end
    else
      SetTextColor(DC, Colors[dcTabText]);

    FillChar(Item, SizeOf(Item), 0);
    Buf[0] := #0;
    Item.mask := TCIF_TEXT;
    Item.pszText := @Buf[0];
    Item.cchTextMax := Length(Buf) - 1;
    SendMessageW(Wnd, TCM_GETITEMW, I, LPARAM(@Item));
    TR := IR;
    TR.Left := TR.Left + 4;
    TR.Right := TR.Right - 4;
    DrawTextW(DC, @Buf[0], -1, TR, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;
  SelectObject(DC, OldFont);
end;

procedure PaintClientEdge(Wnd: HWND);
var
  WR: TRect;
  DC: HDC;
  W, H, EX, EY: LongInt;
begin
  if not GetWindowRect(Wnd, WR) then Exit;
  W := WR.Right - WR.Left;
  H := WR.Bottom - WR.Top;
  EX := GetSystemMetrics(SM_CXEDGE);
  EY := GetSystemMetrics(SM_CYEDGE);
  DC := GetWindowDC(Wnd);
  if DC = 0 then Exit;
  FillBox(DC, 0, 0, W, EY, Brushes[dcBorder]);
  FillBox(DC, 0, H - EY, W, H, Brushes[dcBorder]);
  FillBox(DC, 0, 0, EX, H, Brushes[dcBorder]);
  FillBox(DC, W - EX, 0, W, H, Brushes[dcBorder]);
  ReleaseDC(Wnd, DC);
end;

type
  TButtonKind = (bkNone, bkPush, bkCheck, bkRadio, bkGroup);

function ButtonHasImage(Wnd: HWND): Boolean;
var
  Images: TButtonImageListRec;
begin
  FillChar(Images, SizeOf(Images), 0);
  Result := ((SendMessageW(Wnd, BCM_GETIMAGELIST, 0, LPARAM(@Images)) <> 0) and (Images.himl <> 0)) or
    (SendMessageW(Wnd, BM_GETIMAGE, IMAGE_BITMAP, 0) <> 0) or
    (SendMessageW(Wnd, BM_GETIMAGE, IMAGE_ICON, 0) <> 0);
end;

function ButtonKind(Wnd: HWND): TButtonKind;
var
  Style: LongInt;
begin
  Style := GetWindowLongW(Wnd, GWL_STYLE);
  if (Style and (BS_PUSHLIKE or BS_LEFTTEXT or BS_BITMAP or BS_ICON)) <> 0 then
    Exit(bkNone);
  case Style and $F of
    BS_PUSHBUTTON, BS_DEFPUSHBUTTON:
      if ButtonHasImage(Wnd) then Result := bkNone else Result := bkPush;
    BS_CHECKBOX, BS_AUTOCHECKBOX, BS_3STATE, BS_AUTO3STATE:
      Result := bkCheck;
    BS_RADIOBUTTON, BS_AUTORADIOBUTTON:
      Result := bkRadio;
    BS_GROUPBOX:
      Result := bkGroup;
  else
    Result := bkNone;
  end;
end;

procedure DrawButtonCaption(Wnd: HWND; DC: HDC; R: TRect; Flags: UINT; Enabled: Boolean;
  out TextRect: TRect);
var
  Caption: UnicodeString;
  Calc: TRect;
  H: LongInt;
begin
  TextRect := R;
  Caption := WindowText(Wnd);
  if Caption = '' then Exit;
  Flags := Flags or PrefixFlags(Wnd);
  if (GetWindowLongW(Wnd, GWL_STYLE) and BS_MULTILINE) <> 0 then
    Flags := Flags or DT_WORDBREAK
  else
    Flags := Flags or DT_SINGLELINE;
  Calc := R;
  DrawTextW(DC, PWideChar(Caption), Length(Caption), Calc, Flags or DT_CALCRECT);
  H := Calc.Bottom - Calc.Top;
  TextRect.Top := R.Top + (R.Bottom - R.Top - H) div 2;
  TextRect.Bottom := TextRect.Top + H;
  if (Flags and DT_CENTER) = 0 then
    TextRect.Right := TextRect.Left + (Calc.Right - Calc.Left);
  SetBkMode(DC, TRANSPARENT);
  if Enabled then SetTextColor(DC, Colors[dcText]) else SetTextColor(DC, Colors[dcGrayText]);
  DrawTextW(DC, PWideChar(Caption), Length(Caption), TextRect, Flags);
end;

procedure PaintPushButton(Wnd: HWND; DC: HDC);
var
  CR, TR, Unused: TRect;
  State: LRESULT;
  Enabled, IsDefault: Boolean;
  Back, Border: HBRUSH;
  OldFont: HGDIOBJ;
begin
  GetClientRect(Wnd, CR);
  State := SendMessageW(Wnd, BM_GETSTATE, 0, 0);
  Enabled := IsWindowEnabled(Wnd);
  IsDefault := (GetWindowLongW(Wnd, GWL_STYLE) and $F) = BS_DEFPUSHBUTTON;

  if not Enabled then Back := Brushes[dcEdit]
  else if (State and BST_PUSHED) <> 0 then Back := Brushes[dcPressed]
  else if (State and BST_HOT) <> 0 then Back := Brushes[dcHot]
  else Back := Brushes[dcControl];
  if Enabled and (IsDefault or ((State and BST_FOCUS) <> 0)) then
    Border := Brushes[dcAccent]
  else
    Border := Brushes[dcShadow];
  FillRect(DC, CR, Back);
  DrawFrame(DC, CR, Border);

  TR := CR;
  Shrink(TR, 4, 2);
  OldFont := SelectWindowFont(Wnd, DC);
  DrawButtonCaption(Wnd, DC, TR, DT_CENTER, Enabled, Unused);
  SelectObject(DC, OldFont);
end;

procedure PaintCheckOrRadio(Wnd: HWND; DC: HDC; Radio: Boolean);
var
  CR, GlyphRect, TR, TextRect: TRect;
  Theme: THandle;
  Part, State, Base: LongInt;
  Check, ButtonState: LRESULT;
  Size: TSize;
  Back: HBRUSH;
  Enabled: Boolean;
  OldFont: HGDIOBJ;
begin
  GetClientRect(Wnd, CR);
  Back := HBRUSH(SendMessageW(GetParent(Wnd), WM_CTLCOLORSTATIC, WPARAM(DC), LPARAM(Wnd)));
  if Back = 0 then Back := Brushes[dcWindow];
  FillRect(DC, CR, Back);

  Enabled := IsWindowEnabled(Wnd);
  Check := SendMessageW(Wnd, BM_GETCHECK, 0, 0);
  ButtonState := SendMessageW(Wnd, BM_GETSTATE, 0, 0);
  if Radio then Part := BP_RADIOBUTTON else Part := BP_CHECKBOX;
  if Check = BST_CHECKED then Base := 5
  else if (Check = BST_INDETERMINATE) and not Radio then Base := 9
  else Base := 1;
  if not Enabled then State := Base + 3
  else if (ButtonState and BST_PUSHED) <> 0 then State := Base + 2
  else if (ButtonState and BST_HOT) <> 0 then State := Base + 1
  else State := Base;

  OldFont := SelectWindowFont(Wnd, DC);
  Size.cx := 13;
  Size.cy := 13;
  Theme := UxTheme.OpenThemeData(Wnd, 'Button');
  if Theme <> 0 then
    UxTheme.GetThemePartSize(Theme, DC, Part, State, nil, TS_DRAW, Size);
  GlyphRect.Left := CR.Left;
  GlyphRect.Top := CR.Top + (CR.Bottom - CR.Top - Size.cy) div 2;
  GlyphRect.Right := GlyphRect.Left + Size.cx;
  GlyphRect.Bottom := GlyphRect.Top + Size.cy;
  if Theme <> 0 then
  begin
    UxTheme.DrawThemeBackground(Theme, DC, Part, State, GlyphRect, nil);
    UxTheme.CloseThemeData(Theme);
  end
  else
  begin
    FillRect(DC, GlyphRect, Brushes[dcEdit]);
    DrawFrame(DC, GlyphRect, Brushes[dcText]);
    if Check <> BST_UNCHECKED then
      FillBox(DC, GlyphRect.Left + 3, GlyphRect.Top + 3, GlyphRect.Right - 3,
        GlyphRect.Bottom - 3, Brushes[dcText]);
  end;

  TR := CR;
  TR.Left := GlyphRect.Right + Size.cx div 3 + 1;
  DrawButtonCaption(Wnd, DC, TR, 0, Enabled, TextRect);
  if ((ButtonState and BST_FOCUS) <> 0) and
    ((SendMessageW(Wnd, WM_QUERYUISTATE, 0, 0) and UISF_HIDEFOCUS) = 0) then
  begin
    Shrink(TextRect, -1, 0);
    DrawFocusRect(DC, TextRect);
  end;
  SelectObject(DC, OldFont);
end;

procedure PaintGroupBox(Wnd: HWND; DC: HDC; ClipChildren: Boolean);
var
  CR, TR: TRect;
  Caption: UnicodeString;
  TextHeight, X: LongInt;
  OldFont: HGDIOBJ;
  Flags: UINT;
begin
  GetClientRect(Wnd, CR);
  if ClipChildren then ExcludeChildren(Wnd, DC);
  FillRect(DC, CR, Brushes[dcWindow]);
  OldFont := SelectWindowFont(Wnd, DC);

  Caption := 'Ag';
  FillChar(TR, SizeOf(TR), 0);
  DrawTextW(DC, PWideChar(Caption), Length(Caption), TR, DT_SINGLELINE or DT_CALCRECT);
  TextHeight := TR.Bottom - TR.Top;
  TR := CR;
  TR.Top := TextHeight div 2;
  DrawFrame(DC, TR, Brushes[dcBorder]);

  Caption := WindowText(Wnd);
  if Caption <> '' then
  begin
    Flags := DT_SINGLELINE or PrefixFlags(Wnd);
    FillChar(TR, SizeOf(TR), 0);
    DrawTextW(DC, PWideChar(Caption), Length(Caption), TR, Flags or DT_CALCRECT);
    X := TextHeight div 2 + 2;
    TR.Right := X + TR.Right - TR.Left;
    TR.Left := X;
    TR.Top := 0;
    TR.Bottom := TextHeight;
    FillBox(DC, TR.Left - 3, TR.Top, TR.Right + 3, TR.Bottom, Brushes[dcWindow]);
    SetBkMode(DC, TRANSPARENT);
    if IsWindowEnabled(Wnd) then SetTextColor(DC, Colors[dcText]) else SetTextColor(DC, Colors[dcGrayText]);
    DrawTextW(DC, PWideChar(Caption), Length(Caption), TR, Flags);
  end;
  SelectObject(DC, OldFont);
end;

procedure PaintButton(Wnd: HWND; DC: HDC; Kind: TButtonKind; ClipChildren: Boolean);
var
  Control: TWinControl;
  P: TPoint;
  Saved: LongInt;
begin
  case Kind of
    bkPush:  PaintPushButton(Wnd, DC);
    bkCheck: PaintCheckOrRadio(Wnd, DC, False);
    bkRadio: PaintCheckOrRadio(Wnd, DC, True);
    bkGroup:
      begin
        PaintGroupBox(Wnd, DC, ClipChildren);
        Control := FindControl(Wnd);
        if ClipChildren and (Control <> nil) then
        begin
          P.X := 0;
          P.Y := 0;
          ClientToScreen(Wnd, P);
          Saved := SaveDC(DC);
          OffsetViewportOrgEx(DC, Control.ClientOrigin.X - P.X, Control.ClientOrigin.Y - P.Y, nil);
          TWinControlAccess(Control).PaintControls(DC, nil);
          RestoreDC(DC, Saved);
        end;
      end;
  end;
end;

function TopWindowProc(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM): LRESULT;
begin
  case Msg of
    WM_DRAWITEM:
      if (WP = 0) and (LP <> 0) and DrawOwnerMenuBarItem(Wnd, PDrawItemRec(LP)) then
        Exit(1);
    WM_NCPAINT, WM_NCACTIVATE:
      begin
        Result := DefSubclassProc(Wnd, Msg, WP, LP);
        DrawMenuBarBottomLine(Wnd);
        Exit;
      end;
  end;
  Result := DefSubclassProc(Wnd, Msg, WP, LP);
end;

function EdgeProc(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM): LRESULT;
begin
  Result := DefSubclassProc(Wnd, Msg, WP, LP);
  if Msg = WM_NCPAINT then
    PaintClientEdge(Wnd);
end;

function TabsProc(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM): LRESULT;
var
  PS: TPaintStruct;
  DC: HDC;
begin
  case Msg of
    WM_ERASEBKGND:
      Exit(1);
    WM_PAINT:
      begin
        DC := BeginPaint(Wnd, PS);
        ExcludeChildren(Wnd, DC);
        PaintTabs(Wnd, DC);
        EndPaint(Wnd, PS);
        Exit(0);
      end;
    WM_PRINTCLIENT:
      begin
        PaintTabs(Wnd, HDC(WP));
        Exit(0);
      end;
  end;
  Result := DefSubclassProc(Wnd, Msg, WP, LP);
  if Msg = WM_SIZE then
    InvalidateRect(Wnd, nil, False);
end;

function StatusBarProc(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM): LRESULT;
var
  CR: TRect;
begin
  if Msg = WM_ERASEBKGND then
  begin
    GetClientRect(Wnd, CR);
    FillRect(HDC(WP), CR, Brushes[dcWindow]);
    Exit(1);
  end;
  Result := DefSubclassProc(Wnd, Msg, WP, LP);
end;

function ButtonProc(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM): LRESULT;
var
  Kind: TButtonKind;
  PS: TPaintStruct;
  DC: HDC;
  Hot: Boolean;
begin
  if (Msg = WM_ERASEBKGND) or (Msg = WM_PAINT) or (Msg = WM_PRINTCLIENT) then
  begin
    Kind := ButtonKind(Wnd);
    if Kind <> bkNone then
    begin
      if Msg = WM_ERASEBKGND then Exit(1);
      if Msg = WM_PAINT then
      begin
        DC := BeginPaint(Wnd, PS);
        PaintButton(Wnd, DC, Kind, True);
        EndPaint(Wnd, PS);
      end
      else
        PaintButton(Wnd, HDC(WP), Kind, False);
      Exit(0);
    end;
  end;

  Result := DefSubclassProc(Wnd, Msg, WP, LP);

  case Msg of
    WM_SETFOCUS, WM_KILLFOCUS, WM_ENABLE, WM_SETTEXT, WM_SIZE,
    WM_LBUTTONDOWN, WM_LBUTTONUP, WM_CAPTURECHANGED, WM_UPDATEUISTATE, WM_MOUSELEAVE,
    BM_SETSTATE, BM_SETSTYLE, BM_SETCHECK:
      if ButtonKind(Wnd) <> bkNone then
        RedrawWindow(Wnd, nil, 0, RDW_REPAINT_NOW);
    WM_MOUSEMOVE:
      begin
        Kind := ButtonKind(Wnd);
        if (Kind <> bkNone) and (Kind <> bkGroup) then
        begin
          Hot := (SendMessageW(Wnd, BM_GETSTATE, 0, 0) and BST_HOT) <> 0;
          if Hot <> (GetPropW(Wnd, PropHot) <> 0) then
          begin
            SetPropW(Wnd, PropHot, Ord(Hot));
            RedrawWindow(Wnd, nil, 0, RDW_REPAINT_NOW);
          end;
        end;
      end;
  end;
end;

function ComboProc(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM): LRESULT;
begin
  if Msg = WM_CTLCOLORLISTBOX then
  begin
    SetTextColor(HDC(WP), Colors[dcText]);
    SetBkColor(HDC(WP), Colors[dcEdit]);
    Exit(LRESULT(Brushes[dcEdit]));
  end;
  Result := DefSubclassProc(Wnd, Msg, WP, LP);
end;

function ComboEditProc(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM): LRESULT;
var
  Focus: HWND;
begin
  if (Msg = EM_SETSEL) and (WP = 0) and (LongInt(LP) = -1) then
  begin
    Focus := GetFocus;
    if (Focus <> Wnd) and (Focus <> GetParent(Wnd)) then
      Exit(DefSubclassProc(Wnd, Msg, 0, 0));
  end;
  Result := DefSubclassProc(Wnd, Msg, WP, LP);
end;

function DialogProc(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM): LRESULT;
var
  DC: HDC;
  CR: TRect;
begin
  DC := HDC(WP);
  case Msg of
    WM_ERASEBKGND:
      begin
        GetClientRect(Wnd, CR);
        FillRect(DC, CR, Brushes[dcWindow]);
        Exit(1);
      end;
    WM_CTLCOLOREDIT, WM_CTLCOLORLISTBOX:
      begin
        SetTextColor(DC, Colors[dcText]);
        SetBkColor(DC, Colors[dcEdit]);
        Exit(LRESULT(Brushes[dcEdit]));
      end;
    WM_CTLCOLORSTATIC:
      begin
        if WndClass(HWND(LP)) = 'edit' then
        begin
          SetTextColor(DC, Colors[dcText]);
          SetBkColor(DC, Colors[dcEdit]);
          Exit(LRESULT(Brushes[dcEdit]));
        end;
        if IsWindowEnabled(HWND(LP)) then
          SetTextColor(DC, Colors[dcText])
        else
          SetTextColor(DC, Colors[dcGrayText]);
        SetBkColor(DC, Colors[dcWindow]);
        Exit(LRESULT(Brushes[dcWindow]));
      end;
    WM_CTLCOLORBTN, WM_CTLCOLORDLG:
      begin
        SetTextColor(DC, Colors[dcText]);
        SetBkColor(DC, Colors[dcWindow]);
        Exit(LRESULT(Brushes[dcWindow]));
      end;
  end;
  Result := DefSubclassProc(Wnd, Msg, WP, LP);
end;

procedure RemoveDarkSubclass(Wnd: HWND; Id: PtrUInt); forward;

function DarkSubclassProc(Wnd: HWND; Msg: UINT; WP: WPARAM; LP: LPARAM;
  Id, RefData: PtrUInt): LRESULT; stdcall;
begin
  if Msg = WM_NCDESTROY then
  begin
    RemovePropW(Wnd, PropHot);
    RemoveDarkSubclass(Wnd, Id);
    Exit(DefSubclassProc(Wnd, Msg, WP, LP));
  end;
  case TSubclassKind(RefData) of
    skTopWindow: Result := TopWindowProc(Wnd, Msg, WP, LP);
    skEdge:      Result := EdgeProc(Wnd, Msg, WP, LP);
    skTabs:      Result := TabsProc(Wnd, Msg, WP, LP);
    skStatusBar: Result := StatusBarProc(Wnd, Msg, WP, LP);
    skButton:    Result := ButtonProc(Wnd, Msg, WP, LP);
    skCombo:     Result := ComboProc(Wnd, Msg, WP, LP);
    skComboEdit: Result := ComboEditProc(Wnd, Msg, WP, LP);
    skDialog:    Result := DialogProc(Wnd, Msg, WP, LP);
  else
    Result := DefSubclassProc(Wnd, Msg, WP, LP);
  end;
end;

procedure Subclass(Wnd: HWND; Kind: TSubclassKind);
begin
  SetWindowSubclass(Wnd, @DarkSubclassProc, 1, Ord(Kind));
end;

procedure RemoveDarkSubclass(Wnd: HWND; Id: PtrUInt);
begin
  RemoveWindowSubclass(Wnd, @DarkSubclassProc, Id);
end;

procedure SetDarkTitleBar(Wnd: HWND);
var
  Dark: LongInt;
  Color: DWORD;
begin
  if not Assigned(DwmSetWindowAttribute) then Exit;
  Dark := 1;
  if DwmSetWindowAttribute(Wnd, 20, @Dark, SizeOf(Dark)) <> 0 then
    DwmSetWindowAttribute(Wnd, 19, @Dark, SizeOf(Dark));
  if WinBuild >= 22000 then
  begin
    Color := Colors[dcWindow];
    DwmSetWindowAttribute(Wnd, 35, @Color, SizeOf(Color));
    Color := Colors[dcBorder];
    DwmSetWindowAttribute(Wnd, 34, @Color, SizeOf(Color));
    Color := Colors[dcText];
    DwmSetWindowAttribute(Wnd, 36, @Color, SizeOf(Color));
  end;
end;

function IsComboClass(const CN: string): Boolean;
begin
  Result := (CN = 'combobox') or (CN = 'lclcombobox') or (CN = 'comboboxex32');
end;

function IsNativeDialog(Wnd: HWND; const CN: string): Boolean;
begin
  Result := (CN = '#32770') and (FindControl(Wnd) = nil);
end;

procedure ApplyVisualStyle(Wnd: HWND; const CN: string);
var
  Style: LongInt;
begin
  if (CN = 'static') or (CN = 'tooltips_class32') then Exit;
  AllowDarkModeForWindow(Wnd, True);
  Style := GetWindowLongW(Wnd, GWL_STYLE);
  if CN = 'msctls_statusbar32' then
  begin
    SetWindowTheme(Wnd, @NoTheme[0], @NoTheme[0]);
    SendMessageW(Wnd, SB_SETBKCOLOR, 0, LPARAM(Colors[dcWindow]));
  end
  else if (CN = 'sysheader32') or (CN = 'syslistview32') then
    SetWindowTheme(Wnd, 'DarkMode_ItemsView', nil)
  else if CN = 'edit' then
  begin
    if (Style and ES_MULTILINE) <> 0 then
      SetWindowTheme(Wnd, 'DarkMode_Explorer', nil)
    else
      SetWindowTheme(Wnd, @NoTheme[0], @NoTheme[0]);
  end
  else if IsComboClass(CN) then
    SetWindowTheme(Wnd, 'DarkMode_CFD', nil)
  else
    SetWindowTheme(Wnd, 'DarkMode_Explorer', nil);
end;

procedure ApplySubclass(Wnd: HWND; const CN: string);
var
  Style: LongInt;
begin
  Style := GetWindowLongW(Wnd, GWL_STYLE);
  if IsNativeDialog(Wnd, CN) then
    Subclass(Wnd, skDialog)
  else if CN = 'msctls_statusbar32' then
    Subclass(Wnd, skStatusBar)
  else if CN = 'button' then
  begin
    Subclass(Wnd, skButton);
    InvalidateRect(Wnd, nil, True);
  end
  else if CN = 'systabcontrol32' then
  begin
    if (Style and (TCS_OWNERDRAWFIXED or TCS_BUTTONS or TCS_VERTICAL)) = 0 then
    begin
      Subclass(Wnd, skTabs);
      RedrawWindow(Wnd, nil, 0, RDW_REPAINT_ALL);
    end;
  end
  else if IsComboClass(CN) then
    Subclass(Wnd, skCombo)
  else if (CN = 'edit') and IsComboClass(WndClass(GetParent(Wnd))) then
  begin
    Subclass(Wnd, skComboEdit);
    if GetFocus <> Wnd then
      SendMessageW(Wnd, EM_SETSEL, 0, 0);
  end
  else if (GetWindowLongW(Wnd, GWL_EXSTYLE) and WS_EX_CLIENTEDGE) <> 0 then
  begin
    Subclass(Wnd, skEdge);
    SetWindowPos(Wnd, 0, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);
  end;
end;

function IsForeignShellWindow(Wnd: HWND; const CN: string): Boolean;
var
  Root: HWND;
begin
  if (CN = 'button') or (CN = 'edit') or (CN = 'listbox') or (CN = 'msctls_updown32') or
    (CN = '#32770') or IsComboClass(CN) then
    Exit(False);
  Root := GetAncestor(Wnd, GA_ROOT);
  Result := (Root <> 0) and (Root <> Wnd) and IsNativeDialog(Root, WndClass(Root));
end;

procedure ThemeWindow(Wnd: HWND; IsTop: Boolean);
var
  CN: string;
begin
  if GetPropW(Wnd, PropThemed) <> 0 then Exit;
  SetPropW(Wnd, PropThemed, 1);
  CN := WndClass(Wnd);
  if not IsTop and IsForeignShellWindow(Wnd, CN) then Exit;
  if IsTop then
  begin
    AllowDarkModeForWindow(Wnd, True);
    SetDarkTitleBar(Wnd);
    if IsNativeDialog(Wnd, CN) then
    begin
      PatchAllImports;
      Subclass(Wnd, skDialog);
    end
    else
      Subclass(Wnd, skTopWindow);
    SetWindowPos(Wnd, 0, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);
    FlushMenuThemes;
  end;
  ApplyVisualStyle(Wnd, CN);
  if not IsTop then
    ApplySubclass(Wnd, CN);
end;

function EnumChildProc(Wnd: HWND; LP: LPARAM): BOOL; stdcall;
begin
  ThemeWindow(Wnd, False);
  Result := True;
end;

function EnumTopProc(Wnd: HWND; LP: LPARAM): BOOL; stdcall;
begin
  if (GetWindowLongW(Wnd, GWL_STYLE) and WS_CAPTION) = WS_CAPTION then
  begin
    ThemeWindow(Wnd, True);
    ApplyMenuBarBackground(Wnd);
  end
  else if WndClass(Wnd) = 'combolbox' then
    ThemeWindow(Wnd, False);
  if IsWindowVisible(Wnd) then
    EnumChildWindows(Wnd, @EnumChildProc, 0);
  Result := True;
end;

procedure ThemeNativeDialog(Wnd: HWND);
begin
  EnumTopProc(Wnd, 0);
  EnumChildWindows(Wnd, @EnumChildProc, 0);
end;

function RedrawTopProc(Wnd: HWND; LP: LPARAM): BOOL; stdcall;
begin
  if IsWindowVisible(Wnd) then
    RedrawWindow(Wnd, nil, 0, RDW_REPAINT_ALL);
  Result := True;
end;

function GetWindowsBuild: DWORD;
var
  RtlGetVersion: function(var Info: TOSVersionRec): LongInt; stdcall;
  Info: TOSVersionRec;
begin
  Result := 0;
  Pointer(RtlGetVersion) := GetProcAddress(GetModuleHandleW('ntdll.dll'), 'RtlGetVersion');
  if not Assigned(RtlGetVersion) then Exit;
  FillChar(Info, SizeOf(Info), 0);
  Info.dwOSVersionInfoSize := SizeOf(Info);
  if RtlGetVersion(Info) = 0 then
    Result := Info.dwBuildNumber;
end;

function LoadDarkModeApis: Boolean;
var
  UxThemeLib, DwmLib, ComCtlLib: HMODULE;
begin
  UxThemeLib := LoadLibraryW('uxtheme.dll');
  DwmLib := LoadLibraryW('dwmapi.dll');
  ComCtlLib := LoadLibraryW('comctl32.dll');
  { Undocumented uxtheme exports (Windows 10 1809+) }
  Pointer(RefreshImmersiveColorPolicyState) := GetProcAddress(UxThemeLib, PAnsiChar(PtrUInt(104)));
  Pointer(AllowDarkModeForWindow) := GetProcAddress(UxThemeLib, PAnsiChar(PtrUInt(133)));
  Pointer(SetPreferredAppMode) := GetProcAddress(UxThemeLib, PAnsiChar(PtrUInt(135)));
  Pointer(FlushMenuThemes) := GetProcAddress(UxThemeLib, PAnsiChar(PtrUInt(136)));
  Pointer(SetWindowTheme) := GetProcAddress(UxThemeLib, 'SetWindowTheme');
  Pointer(DwmSetWindowAttribute) := GetProcAddress(DwmLib, 'DwmSetWindowAttribute');
  Pointer(SetWindowSubclass) := GetProcAddress(ComCtlLib, 'SetWindowSubclass');
  Pointer(DefSubclassProc) := GetProcAddress(ComCtlLib, 'DefSubclassProc');
  Pointer(RemoveWindowSubclass) := GetProcAddress(ComCtlLib, 'RemoveWindowSubclass');
  Result := Assigned(RefreshImmersiveColorPolicyState) and Assigned(AllowDarkModeForWindow) and
    Assigned(SetPreferredAppMode) and Assigned(FlushMenuThemes) and Assigned(SetWindowTheme) and
    Assigned(DwmSetWindowAttribute) and Assigned(SetWindowSubclass) and
    Assigned(DefSubclassProc) and Assigned(RemoveWindowSubclass);
end;

procedure InstallDark;
var
  User32: HMODULE;
  C: TDarkColor;
begin
  if Installed then Exit;
  WinBuild := GetWindowsBuild;
  if (WinBuild < 17763) or not LoadDarkModeApis then Exit;

  User32 := GetModuleHandleW('user32.dll');
  Pointer(OrigGetSysColor) := GetProcAddress(User32, 'GetSysColor');
  Pointer(OrigGetSysColorBrush) := GetProcAddress(User32, 'GetSysColorBrush');
  Pointer(OrigDrawEdge) := GetProcAddress(User32, 'DrawEdge');
  Pointer(OrigFillRect) := GetProcAddress(User32, 'FillRect');
  Pointer(OrigDeleteObject) := GetProcAddress(GetModuleHandleW('gdi32.dll'), 'DeleteObject');
  if not (Assigned(OrigGetSysColor) and Assigned(OrigGetSysColorBrush) and
    Assigned(OrigDrawEdge) and Assigned(OrigFillRect) and Assigned(OrigDeleteObject)) then Exit;

  Colors := Palette;
  for C := Low(TDarkColor) to High(TDarkColor) do
    Brushes[C] := CreateSolidBrush(Colors[C]);

  if WinBuild >= 18362 then SetPreferredAppMode(2) else SetPreferredAppMode(1);
  RefreshImmersiveColorPolicyState;
  FlushMenuThemes;

  PatchAllImports;
  InstallTaskDialogHooks;
  Installed := True;
end;


procedure StartDarkWindows;
begin
  PatchAllImports;
  InstallThemeHooks;
  MenuHook := SetWindowsHookExW(WH_CALLWNDPROCRET, @MenuMessageHook, 0, GetCurrentThreadId);
  CreateHook := SetWindowsHookExW(WH_CBT, @CreateWindowHook, 0, GetCurrentThreadId);
end;

{$ENDIF}

procedure FixVirtualTree(C: TControl);
var
  Options: TObject;
  PaintOptions: string;
begin
  if (Pos('Tree', C.ClassName) = 0) or not IsPublishedProp(C, 'TreeOptions') then Exit;
  Options := GetObjectProp(C, 'TreeOptions');
  if (Options = nil) or not IsPublishedProp(Options, 'PaintOptions') then Exit;
  PaintOptions := ',' + GetSetProp(Options, 'PaintOptions', False) + ',';
  if Pos(',toThemeAware,', PaintOptions) = 0 then Exit;
  PaintOptions := StringReplace(PaintOptions, ',toThemeAware,', ',', []);
  SetSetProp(Options, 'PaintOptions', Copy(PaintOptions, 2, Length(PaintOptions) - 2));
  C.Invalidate;
end;

procedure FixLabelColor(C: TControl);
var
  Color, R, G, B, MaxC, MinC: LongInt;
  Role: TDarkColor;
begin
  Color := LongInt(TControlAccess(C).Font.Color);
  if (Color = LongInt(clDefault)) or (Color = LongInt(clWindowText)) or (Color = LongInt(clBtnText)) then
  begin
    TControlAccess(C).Font.Color := Colors[dcText];
    Exit;
  end;
  if Color < 0 then
  begin
    if SysColorRole(Color and $FF, Role) then
      Color := Colors[Role]
    else
      Exit;
  end
  else if (Color shr 24) <> 0 then
    Exit;
  R := Color and $FF;
  G := (Color shr 8) and $FF;
  B := (Color shr 16) and $FF;
  if (R * 299 + G * 587 + B * 114) div 1000 >= 110 then Exit;
  MaxC := R;
  if G > MaxC then MaxC := G;
  if B > MaxC then MaxC := B;
  MinC := R;
  if G < MinC then MinC := G;
  if B < MinC then MinC := B;
  if MaxC - MinC < 40 then
    TControlAccess(C).Font.Color := Colors[dcText]
  else if (B = MaxC) and (B - R > 40) then
    TControlAccess(C).Font.Color := Colors[dcLink]
  else
    TControlAccess(C).Font.Color :=
      (R + (255 - R) * 6 div 10) or
      ((G + (255 - G) * 6 div 10) shl 8) or
      ((B + (255 - B) * 6 div 10) shl 16);
end;

procedure FixControl(C: TControl);
begin
  if (C = nil) or (csDesigning in C.ComponentState) then Exit;

  if C is TCustomTreeView then
  begin
    if tvoThemedDraw in TTreeViewAccess(C).Options then
      TTreeViewAccess(C).Options := TTreeViewAccess(C).Options - [tvoThemedDraw];
  end
  else if C is TCustomCoolBar then
  begin
    if TCoolBarAccess(C).Themed then
    begin
      TCoolBarAccess(C).Themed := False;
      C.Invalidate;
    end;
  end
  else if C is TCustomListView then
  begin
    if TControlAccess(C).Font.Color = clDefault then
      TControlAccess(C).Font.Color := clWindowText;
    if TControlAccess(C).Color = clDefault then
      TControlAccess(C).Color := clWindow;
  end
  else if C is TCustomLabel then
    FixLabelColor(C);

  FixVirtualTree(C);
end;

procedure FixControls(Parent: TWinControl);
var
  I: LongInt;
  C: TControl;
begin
  if (Parent = nil) or (csDesigning in Parent.ComponentState) then Exit;
  for I := 0 to Parent.ControlCount - 1 do
  begin
    C := Parent.Controls[I];
    if (C = nil) or (csDesigning in C.ComponentState) then Continue;
    FixControl(C);
    if C is TWinControl then
      FixControls(TWinControl(C));
  end;
end;

procedure FixHintWindow(Form: TCustomForm);
var
  Hint: THintWindow;
begin
  if not (Form is THintWindow) then Exit;
  Hint := THintWindow(Form);
  if (Hint.ControlCount > 0) or (Hint.Color = Colors[dcHint]) then Exit;
  Hint.Color := Colors[dcHint];
  Hint.Font.Color := Colors[dcText];
end;

procedure FixForm(Form: TCustomForm);
begin
  if (Form = nil) or (csDesigning in Form.ComponentState) then Exit;
  FixHintWindow(Form);
  FixControls(Form);
end;

type
  TDarkDriver = class
  private
    FTimer: TTimer;
    FTicks: LongInt;
    procedure Tick(Sender: TObject);
    procedure FormVisibleChanged(Sender: TObject; Form: TCustomForm);
  public
    constructor Create;
    destructor Destroy; override;
  end;

var
  Driver: TDarkDriver = nil;

constructor TDarkDriver.Create;
begin
  inherited Create;
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 200;
  FTimer.OnTimer := @Tick;
  FTimer.Enabled := True;
  if Screen <> nil then
    Screen.AddHandlerFormVisibleChanged(@FormVisibleChanged, False);
end;

destructor TDarkDriver.Destroy;
begin
  if Screen <> nil then
    Screen.RemoveHandlerFormVisibleChanged(@FormVisibleChanged);
  FreeAndNil(FTimer);
  inherited Destroy;
end;

procedure TDarkDriver.Tick(Sender: TObject);
var
  I: LongInt;
begin
  Inc(FTicks);
  try
    {$IFDEF MSWINDOWS}
    EnumThreadWindows(GetCurrentThreadId, @EnumTopProc, 0);
    {$ENDIF}
    if Screen <> nil then
    begin
      for I := 0 to Screen.CustomFormCount - 1 do
        FixForm(Screen.CustomForms[I]);
    end;
    {$IFDEF MSWINDOWS}
    if (FTicks = 10) or (FTicks = 30) then
      EnumThreadWindows(GetCurrentThreadId, @RedrawTopProc, 0);
    {$ENDIF}
    if (FTicks mod 10 = 1) then
      ApplyInspectorColors;
  except
  end;
end;

procedure TDarkDriver.FormVisibleChanged(Sender: TObject; Form: TCustomForm);
begin
  try
    if (Form = nil) or not Form.Visible then Exit;
    FixForm(Form);
    {$IFDEF MSWINDOWS}
    if Form.HandleAllocated and (Form.Parent = nil) then
      EnumTopProc(Form.Handle, 0);
    {$ENDIF}
    if Form.ClassNameIs('TObjectInspectorDlg') then
      ApplyInspectorColors;
  except
  end;
end;

procedure StartDark;
begin
  if Started or (WidgetSet = nil) or (Screen = nil) then Exit;
  Colors := Palette;
  Started := True;
  {$IFDEF MSWINDOWS}
  InstallDark;
  StartDarkWindows;
  {$ENDIF}
  if Driver = nil then
    Driver := TDarkDriver.Create;
  ApplyInspectorColors;
end;

procedure Register;
begin
  RegisterIDEDarkOptions;
  if DarkEnabled then
    StartDark;
end;

initialization
  LoadDarkSettings;
  if DarkEnabled then
    ApplyEditorSchemeAtStartup;
  {$IFDEF MSWINDOWS}
  if DarkEnabled then
  begin
    InstallDark;
    StartDark;
  end;
  {$ENDIF}

end.

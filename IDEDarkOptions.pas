unit IDEDarkOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Dialogs, Graphics,
  IDEOptionsIntf, IDEOptEditorIntf, FormEditingIntf, ObjectInspector,
  IDEDarkSettings;

type
  TIDEDarkOptionsFrame = class(TAbstractIDEOptionsEditor)
  private
    FEnabledBox: TCheckBox;
    FColorButtons: array[TDarkColor] of TColorButton;
    FApplyInspectorOnSave: Boolean;
    procedure PresetClick(Sender: TObject);
    procedure InspectorClick(Sender: TObject);
    procedure SchemeClick(Sender: TObject);
  public
    function GetTitle: string; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

procedure RegisterIDEDarkOptions;
procedure ApplyInspectorColors;

implementation

{$R *.lfm}

const
  EnvOptionsIDEDark = 2000;

  InspectorValueColor     = $00FEDC9C;
  InspectorReferenceColor = $00C086C5;
  InspectorSubPropColor   = $00B0C94E;
  InspectorDifferColor    = $002D2D3A;

type
  TInspectorApplier = class
    procedure Run(Data: PtrInt);
  end;

var
  InspectorApplier: TInspectorApplier = nil;

procedure ApplyInspectorColors;
var
  Inspector: TObjectInspectorDlg;
  Page: TObjectInspectorPage;
  Grid: TOICustomPropertyGrid;
begin
  if FormEditingHook = nil then Exit;
  Inspector := FormEditingHook.GetCurrentObjectInspector;
  if Inspector = nil then Exit;
  for Page := Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
  begin
    Grid := Inspector.GridControl[Page];
    if Grid = nil then Continue;
    Grid.BackgroundColor := Palette[dcWindow];
    Grid.GutterColor := Palette[dcWindow];
    Grid.GutterEdgeColor := Palette[dcBorder];
    Grid.NameFont.Color := Palette[dcText];
    Grid.DefaultValueFont.Color := Palette[dcTabText];
    Grid.ValueFont.Color := InspectorValueColor;
    Grid.ReferencesColor := InspectorReferenceColor;
    Grid.SubPropertiesColor := InspectorSubPropColor;
    Grid.ReadOnlyColor := Palette[dcGrayText];
    Grid.HighlightColor := Palette[dcSelection];
    Grid.HighlightFont.Color := Palette[dcSelectionText];
    Grid.ValueDifferBackgrndColor := InspectorDifferColor;
    Grid.Invalidate;
  end;
end;

procedure TInspectorApplier.Run(Data: PtrInt);
begin
  ApplyInspectorColors;
end;

procedure RegisterIDEDarkOptions;
begin
  RegisterIDEOptionsEditor(GroupEnvironment, TIDEDarkOptionsFrame, EnvOptionsIDEDark);
end;

{ TIDEDarkOptionsFrame }

function TIDEDarkOptionsFrame.GetTitle: string;
begin
  Result := 'IDE Dark';
end;

procedure TIDEDarkOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
var
  ColorsBox: TGroupBox;
  ButtonsPanel: TPanel;
  Note: TLabel;
  C: TDarkColor;
  L: TLabel;
  B: TButton;
begin
  FEnabledBox := TCheckBox.Create(Self);
  FEnabledBox.Caption := 'Enable the dark theme';
  FEnabledBox.Align := alTop;
  FEnabledBox.BorderSpacing.Around := 6;
  FEnabledBox.Top := 0;
  FEnabledBox.Parent := Self;

  ColorsBox := TGroupBox.Create(Self);
  ColorsBox.Caption := 'Colours';
  ColorsBox.Align := alTop;
  ColorsBox.AutoSize := True;
  ColorsBox.BorderSpacing.Around := 6;
  ColorsBox.Top := 100;
  ColorsBox.ChildSizing.Layout := cclLeftToRightThenTopToBottom;
  ColorsBox.ChildSizing.ControlsPerLine := 4;
  ColorsBox.ChildSizing.HorizontalSpacing := 8;
  ColorsBox.ChildSizing.VerticalSpacing := 4;
  ColorsBox.ChildSizing.LeftRightSpacing := 8;
  ColorsBox.ChildSizing.TopBottomSpacing := 6;
  ColorsBox.Parent := Self;
  for C := Low(TDarkColor) to High(TDarkColor) do
  begin
    L := TLabel.Create(Self);
    L.Caption := DarkColorNames[C];
    L.Layout := tlCenter;
    L.Parent := ColorsBox;
    FColorButtons[C] := TColorButton.Create(Self);
    FColorButtons[C].Width := 70;
    FColorButtons[C].Parent := ColorsBox;
  end;

  ButtonsPanel := TPanel.Create(Self);
  ButtonsPanel.BevelOuter := bvNone;
  ButtonsPanel.Align := alTop;
  ButtonsPanel.AutoSize := True;
  ButtonsPanel.BorderSpacing.Around := 6;
  ButtonsPanel.Top := 200;
  ButtonsPanel.ChildSizing.Layout := cclLeftToRightThenTopToBottom;
  ButtonsPanel.ChildSizing.HorizontalSpacing := 8;
  ButtonsPanel.Parent := Self;

  B := TButton.Create(Self);
  B.Caption := 'Reset to Delphi Dark';
  B.AutoSize := True;
  B.OnClick := @PresetClick;
  B.Parent := ButtonsPanel;

  B := TButton.Create(Self);
  B.Caption := 'Apply dark Object Inspector colours';
  B.AutoSize := True;
  B.OnClick := @InspectorClick;
  B.Parent := ButtonsPanel;

  B := TButton.Create(Self);
  B.Caption := 'Use the Delphi Dark editor colours';
  B.AutoSize := True;
  B.OnClick := @SchemeClick;
  B.Parent := ButtonsPanel;

  Note := TLabel.Create(Self);
  Note.Align := alTop;
  Note.BorderSpacing.Around := 6;
  Note.WordWrap := True;
  Note.Top := 300;
  Note.Caption :=
    'Enabling, disabling and colour changes take effect after restarting the IDE.' +
    LineEnding + LineEnding +
    'The Object Inspector colours are applied immediately and saved with the ' +
    'IDE options when the IDE closes. Messages window and form designer colours ' +
    'are regular IDE options (Environment > Messages Window, Form Editor); the ' +
    'editor colours come from editor colour scheme.';
  Note.Parent := Self;
end;

procedure TIDEDarkOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
var
  C: TDarkColor;
begin
  FEnabledBox.Checked := DarkEnabled;
  for C := Low(TDarkColor) to High(TDarkColor) do
    FColorButtons[C].ButtonColor := Palette[C];
  FApplyInspectorOnSave := False;
end;

procedure TIDEDarkOptionsFrame.SchemeClick(Sender: TObject);
begin
  InstallEditorScheme(True);
  SelectSchemePending := True;
  SaveDarkSettings;
  ShowMessage('The Delphi Dark editor colour scheme is installed and will be ' +
    'selected the next time the IDE starts.');
end;

procedure TIDEDarkOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
var
  C: TDarkColor;
begin
  DarkEnabled := FEnabledBox.Checked;
  for C := Low(TDarkColor) to High(TDarkColor) do
    Palette[C] := ColorToRGB(FColorButtons[C].ButtonColor);
  SaveDarkSettings;
  if FApplyInspectorOnSave then
    Application.QueueAsyncCall(@InspectorApplier.Run, 0);
end;

class function TIDEDarkOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TAbstractIDEEnvironmentOptions;
end;

procedure TIDEDarkOptionsFrame.PresetClick(Sender: TObject);
var
  C: TDarkColor;
begin
  for C := Low(TDarkColor) to High(TDarkColor) do
    FColorButtons[C].ButtonColor := DelphiDarkPalette[C];
end;

procedure TIDEDarkOptionsFrame.InspectorClick(Sender: TObject);
begin
  ApplyInspectorColors;
  FApplyInspectorOnSave := True;
end;

initialization
  InspectorApplier := TInspectorApplier.Create;

finalization
  if Application <> nil then
    Application.RemoveAsyncCalls(InspectorApplier);
  FreeAndNil(InspectorApplier);

end.

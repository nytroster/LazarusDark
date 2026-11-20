# Base16 Ocean Dark Extended theme for Lazarus IDE
> Design-time package for Lazarus IDE providing the Base16 Ocean Dark Extended theme.
> Inspired by and matching the VS Code theme [vscode-ocean-dark-extended-theme](https://github.com/kleber-swf/vscode-ocean-dark-extended-theme).

Supported on **Linux** (GTK2, Qt5) and **Windows 10/11** (1809+ / build 17763+).

---

### Features
- **Ocean Dark Extended Syntax Highlighting**: Bundled and automatically installed as `Ocean Dark Extended` for SynEdit.
- **Object Inspector Theming**: Automatically styled with Ocean Dark palette (orange values, yellow classes, green properties, deep dark blue backgrounds).
- **Cross-Platform LCL Fixes**: Dynamic contrast fix for labels, dark tree views, list views, hint windows, and container forms on both Linux and Windows.
- **Deep Windows 10/11 Theming**: IAT hooking (`GetSysColor`, `DrawEdge`, `FillRect`), dark title bars (`DwmSetWindowAttribute`), undocumented UxTheme dark mode APIs, and control subclassing.
- **One-Click Environment Options Setup**: Easily configure Messages View and Form Editor canvas colors matching Ocean Dark.

---

### Installation in Lazarus

1. In Lazarus, open **Package -> Open Package File (.lpk)...** and choose `idedarkpkg.lpk`.
2. Click **Compile**, then click **Use -> Install**.
3. Confirm rebuilding the Lazarus IDE and let it restart.

#### Linux Notes
- On Linux (GTK2), `idedarkpkg` injects runtime GTK2 styling (`gtk_rc_parse_string`) matching Ocean Dark Extended, automatically theming native menus, menubars, buttons, notebook tabs, entry widgets, and scrollbars.
- In addition, all LCL controls (AnchorDocking headers, panels, treeviews, grids, toolbars, listviews, hint windows, labels) and the Object Inspector are styled directly by the package.
- If using Qt5 or other widgetsets, the package styles all LCL controls, and a system dark theme (or `GTK_THEME=Adwaita:dark`) complements native decorations.

---

### Messages Window & Form Designer Colors

You can apply these settings automatically by clicking **Apply Messages & Form colours** under **Tools -> Options -> Environment -> IDE Dark**, or by merging the following snippet into your `environmentoptions.xml` (`~/.lazarus/environmentoptions.xml` on Linux, or `%APPDATA%\lazarus\environmentoptions.xml` on Windows):

```xml
  <EnvironmentOptions>
    <FormEditor GridColor="4603188">
      <GrabberColor Value="13551040"/>
      <MarkerColor Value="8287077"/>
      <NonFormBackgroundColor Value="2958625"/>
      <Rubberband>
        <SelectionColor Value="12159321"/>
        <CreationColor Value="11772303"/>
      </Rubberband>
    </FormEditor>
    <MsgView>
      <Colors Background="3878955" Running="13077585" Success="9223843" Failed="6971839" TextColor="13551040"/>
    </MsgView>
  </EnvironmentOptions>
```

#### Palette Summary (Ocean Dark Extended)
- **Editor Background**: `#2b303b` (decimal `3878955`)
- **Workbench Background / Panels**: `#21252d` (decimal `2958625`)
- **Normal Text**: `#c0c5ce` (decimal `13551040`)
- **Comments / Muted Text**: `#65737e` (decimal `8287077`)
- **Keywords / Reserved**: `#b48ead` (decimal `11374260`)
- **Strings**: `#a3be8c` (decimal `9223843`)
- **Numbers / Constants**: `#d08770` (decimal `7374800`)
- **Types / Classes**: `#ebcb8b` (decimal `9161707`)
- **Functions / Links**: `#8fa1b3` (decimal `11772303`)
- **Variables / Errors**: `#bf616a` (decimal `6971839`)
- **Selection / Accent**: `#5989b9` / `#518cc7` (decimal `12159321` / `13077585`)
- **Line Highlight**: `#323843` (decimal `4405298`)

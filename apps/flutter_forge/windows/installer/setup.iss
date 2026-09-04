[Setup]
AppId={{48C090B8-E508-4D2C-929F-4FA25EFB255D}
AppName=Flutter Forge
AppVersion=1.2.3
PrivilegesRequired=lowest
DefaultDirName={userpf}\Flutter Forge
DefaultGroupName=Flutter Forge
DisableProgramGroupPage=yes
SourceDir=..\..\build\windows\x64\runner\Release
OutputDir=..\..\..\..\..\..\..
OutputBaseFilename=flutter_forge-setup-x64
SetupIconFile=..\..\..\..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\flutter_forge.exe
Uninstallable=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Flutter Forge"; Filename: "{app}\flutter_forge.exe"
Name: "{autodesktop}\Flutter Forge"; Filename: "{app}\flutter_forge.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\flutter_forge.exe"; Description: "Launch Flutter Forge"; Flags: nowait postinstall skipifsilent

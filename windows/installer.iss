; Установщик Lumo для Windows (ставится в профиль пользователя, права администратора не нужны)
[Setup]
AppId={{6E3B7C51-4F2A-4C1E-9B8F-2D7A5C1E4B90}
AppName=Lumo
AppVersion=1.0.0
AppPublisher=Lumo
DefaultDirName={localappdata}\Programs\Lumo
DefaultGroupName=Lumo
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=dist
OutputBaseFilename=Lumo-Setup
SetupIconFile=Lumo\Assets\lumo.ico
UninstallDisplayIcon={app}\Lumo.exe
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "Ярлык на рабочем столе"; GroupDescription: "Ярлыки:"

[Files]
Source: "out\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Lumo"; Filename: "{app}\Lumo.exe"
Name: "{userdesktop}\Lumo"; Filename: "{app}\Lumo.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Lumo.exe"; Description: "Запустить Lumo"; Flags: nowait postinstall skipifsilent

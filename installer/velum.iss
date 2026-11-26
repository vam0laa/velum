; The Windows installer. Built by .github/workflows/windows.yml:
;   iscc /DVersion=0.1.0-beta.1 /DSource=C:\path\to\dist installer\velum.iss
; Installs for the current user only, so it needs no administrator and Velum can
; update itself silently.

[Setup]
AppId={{7C1E6C55-3B52-4F0B-9C0E-6B1B6C0B7A41}
AppName=Velum
AppVersion={#Version}
AppPublisher=vamola
AppPublisherURL=https://vamola.dev
DefaultDirName={localappdata}\Programs\Velum
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=lowest
OutputDir=..\out
OutputBaseFilename=Velum-{#Version}-setup
SetupIconFile=velum.ico
UninstallDisplayIcon={app}\velum.exe
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
CloseApplications=yes
RestartApplications=no
WizardStyle=modern
LicenseFile=..\LICENSE

[Languages]
Name: "tr"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; Flags: unchecked

[InstallDelete]
; files of an older version must not linger next to the new ones
Type: filesandordirs; Name: "{app}"

[Files]
Source: "{#Source}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Velum"; Filename: "{app}\velum.exe"
Name: "{autodesktop}\Velum"; Filename: "{app}\velum.exe"; Tasks: desktopicon

[Registry]
; offers Velum as a browser in Windows settings; the choice itself stays with the user
Root: HKCU; Subkey: "Software\Classes\VelumHTML"; ValueType: string; ValueData: "Velum HTML"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\VelumHTML\DefaultIcon"; ValueType: string; ValueData: "{app}\velum.exe,0"
Root: HKCU; Subkey: "Software\Classes\VelumHTML\shell\open\command"; ValueType: string; ValueData: """{app}\velum.exe"" ""%1"""
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Velum"; ValueType: string; ValueData: "Velum"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Velum\DefaultIcon"; ValueType: string; ValueData: "{app}\velum.exe,0"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Velum\shell\open\command"; ValueType: string; ValueData: """{app}\velum.exe"""
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Velum\Capabilities"; ValueType: string; ValueName: "ApplicationName"; ValueData: "Velum"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Velum\Capabilities"; ValueType: string; ValueName: "ApplicationDescription"; ValueData: "A calm, private web browser"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Velum\Capabilities\URLAssociations"; ValueType: string; ValueName: "http"; ValueData: "VelumHTML"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Velum\Capabilities\URLAssociations"; ValueType: string; ValueName: "https"; ValueData: "VelumHTML"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Velum\Capabilities\FileAssociations"; ValueType: string; ValueName: ".html"; ValueData: "VelumHTML"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Velum\Capabilities\FileAssociations"; ValueType: string; ValueName: ".htm"; ValueData: "VelumHTML"
Root: HKCU; Subkey: "Software\RegisteredApplications"; ValueType: string; ValueName: "Velum"; ValueData: "Software\Clients\StartMenuInternet\Velum\Capabilities"; Flags: uninsdeletevalue

[Run]
Filename: "{app}\velum.exe"; Description: "{cm:LaunchProgram,Velum}"; Flags: nowait postinstall skipifsilent

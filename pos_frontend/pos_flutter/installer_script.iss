[Setup]
AppName=Kidz POS
AppVersion=1.0
DefaultDirName={pf}\Kidz POS
DefaultGroupName=Kidz POS
OutputBaseFilename=KidzPOSInstaller
Compression=lzma
SolidCompression=yes

[Files]
Source: "E:\Windows\Django+Flutter\POS-Desktop\pos_frontend\pos_flutter\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Kidz POS"; Filename: "{app}\kidz_pos.exe"
Name: "{group}\Uninstall Kidz POS"; Filename: "{uninstallexe}"

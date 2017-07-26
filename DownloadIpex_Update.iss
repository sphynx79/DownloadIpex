; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppVersion "1.1.2"
#define MyAppName "DownloadIpex"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{2C0D278B-CD76-4694-92F0-1262EEBFEB26}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
UsePreviousAppDir=yes
DefaultDirName={pf}\DownloadIpex
DisableDirPage=auto
DisableProgramGroupPage=auto
OutputBaseFilename=Download_Ipex_Update
Compression=lzma
SolidCompression=yes
CreateUninstallRegKey=no
UpdateUninstallLogAppName=yes


[Files]
Source: "K:\Dropbox\progetti\20160911-DownloadIpex\src\main.rbw"; DestDir: "{app}\src"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[InstallDelete]
; Type: files; Name: {app}\foo.bar

[Registry]
Root: HKLM; Subkey: "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{{2C0D278B-CD76-4694-92F0-1262EEBFEB26}_is1"; ValueType: string; ValueName: "DisplayName"; ValueData: "{#MyAppName} version {#MyAppVersion}"
Root: HKLM; Subkey: "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{{2C0D278B-CD76-4694-92F0-1262EEBFEB26}_is1"; ValueType: string; ValueName: "DisplayVersion"; ValueData: "{#MyAppVersion}"


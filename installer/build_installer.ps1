# ============================================================
#  Caisse Dashboard — Script de build installateur unifié
#  Contient le script Inno Setup inline : aucun fichier .iss
#  Usage : powershell -ExecutionPolicy Bypass -File installer\build_installer.ps1
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Se positionner à la racine du projet
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
Write-Host "[INFO] Dossier racine : $root" -ForegroundColor Cyan

# ---- 1. Build Flutter release ------------------------------------------------
Write-Host "`n[1/3] flutter build windows --release..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) { Write-Error "[ERREUR] flutter build a échoué."; exit 1 }

# ---- 2. Script Inno Setup inline --------------------------------------------
$issContent = @"
#define MyAppName        "Caisse Dashboard"
#define MyAppVersion     "1.0.0"
#define MyAppPublisher   "Caisse Dashboard"
#define MyAppExeName     "caisse_dashboard.exe"
#define MyAppDescription "Dashboard de gestion de caisse"

[Setup]
AppId={{B4E92F17-8C3A-4D6B-A1F5-3E07D9C28B40}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=$root\build\installer
OutputBaseFilename=CaisseDashboard_Setup_v{#MyAppVersion}
SetupIconFile=$root\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
DisableDirPage=yes
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "$root\build\windows\x64\runner\Release\{#MyAppExeName}";                    DestDir: "{app}"; Flags: ignoreversion
Source: "$root\build\windows\x64\runner\Release\data\*";                              DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "$root\build\windows\x64\runner\Release\flutter_windows.dll";                 DestDir: "{app}"; Flags: ignoreversion
Source: "$root\build\windows\x64\runner\Release\sqlite3.dll";                         DestDir: "{app}"; Flags: ignoreversion
Source: "$root\build\windows\x64\runner\Release\sqlite3_flutter_libs_plugin.dll";     DestDir: "{app}"; Flags: ignoreversion
Source: "$root\build\windows\x64\runner\Release\open_document_plugin.dll";            DestDir: "{app}"; Flags: ignoreversion
Source: "$root\build\windows\x64\runner\Release\file_saver_plugin.dll";               DestDir: "{app}"; Flags: ignoreversion
Source: "$root\build\windows\x64\runner\Release\share_plus_plugin.dll";               DestDir: "{app}"; Flags: ignoreversion
Source: "$root\build\windows\x64\runner\Release\url_launcher_windows_plugin.dll";     DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}";                             Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}";       Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";                       Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
"@

# Écrire le .iss dans un fichier temporaire
$issTemp = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.iss'
[System.IO.File]::WriteAllText($issTemp, $issContent, [System.Text.Encoding]::UTF8)

# ---- 3. Compiler avec Inno Setup --------------------------------------------
Write-Host "`n[2/3] Compilation Inno Setup..." -ForegroundColor Yellow

$iscc = @(
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    'C:\Program Files\Inno Setup 6\ISCC.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $iscc) {
    Remove-Item $issTemp -Force
    Write-Error "[ERREUR] Inno Setup 6 introuvable. Installez-le depuis https://jrsoftware.org/isdl.php"
    exit 1
}

if (-not (Test-Path "$root\build\installer")) {
    New-Item -ItemType Directory -Path "$root\build\installer" | Out-Null
}

& $iscc $issTemp
$exitCode = $LASTEXITCODE
Remove-Item $issTemp -Force

if ($exitCode -ne 0) { Write-Error "[ERREUR] Compilation Inno Setup échouée."; exit 1 }

# ---- 4. Ouvrir le dossier de sortie -----------------------------------------
Write-Host "`n[3/3] Ouverture de build\installer\" -ForegroundColor Yellow
Start-Process explorer "$root\build\installer"

Write-Host "`n[OK] Installateur créé dans build\installer\" -ForegroundColor Green

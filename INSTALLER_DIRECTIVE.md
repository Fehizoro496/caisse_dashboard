# Directive — Système de création d'installateur Inno Setup (Flutter Windows)

## Prérequis

- [Flutter](https://flutter.dev) avec le support Windows activé (`flutter config --enable-windows-desktop`)
- [Inno Setup 6](https://jrsoftware.org/isdl.php) installé sur la machine de build

---

## Structure à reproduire

```
projet/
├── installer/
│   ├── setup.iss               ← script Inno Setup
│   └── build_installer.bat     ← script de build centralisé
├── windows/
│   └── runner/
│       └── resources/
│           └── app_icon.ico    ← icône de l'application
└── pubspec.yaml
```

---

## Étape 1 — Copier les fichiers

Copier `installer/setup.iss` et `installer/build_installer.bat` dans le nouveau projet.

---

## Étape 2 — Adapter `setup.iss`

Modifier les 5 constantes en tête de fichier :

```ini
#define MyAppName      "Nom Affiché de l'Application"
#define MyAppVersion   "X.Y.Z"           ← doit correspondre à pubspec.yaml
#define MyAppPublisher "NomEditeur"
#define MyAppExeName   "nom_executable.exe"
#define MyAppDescription "Description courte"
```

Générer un nouvel `AppId` unique (GUID) :
- Inno Setup IDE : menu **Tools → Generate GUID**
- Ou en ligne : https://www.guidgenerator.com

```ini
AppId={{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
```

> **Important :** ne jamais réutiliser le même `AppId` que l'application source.
> C'est cet identifiant qui distingue les applications dans le registre Windows.

Vérifier le nom de l'exécutable dans `[Files]` :

```ini
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; ...
```

---

## Étape 3 — Vérifier la liste des DLLs

Après un premier `flutter build windows --release`, lister les fichiers générés :

```
build/windows/x64/runner/Release/*.dll
```

Mettre à jour la section `[Files]` de `setup.iss` pour correspondre exactement
aux DLLs présentes. Chaque DLL doit avoir sa propre ligne :

```ini
Source: "..\build\windows\x64\runner\Release\nom_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
```

Les DLLs typiques d'un projet Flutter Windows :

| DLL                              | Toujours présente |
|----------------------------------|:-----------------:|
| `flutter_windows.dll`            | Oui               |
| `sqlite3.dll`                    | Si drift/sqflite  |
| `sqlite3_flutter_libs_plugin.dll`| Si sqlite3_flutter_libs |
| `open_document_plugin.dll`       | Si open_document  |
| `url_launcher_windows_plugin.dll`| Si url_launcher   |
| `file_saver_plugin.dll`          | Si file_saver     |
| `share_plus_plugin.dll`          | Si share_plus     |

---

## Étape 4 — Synchroniser la version

La version dans `setup.iss` **doit toujours correspondre** à `pubspec.yaml`.

`pubspec.yaml` :
```yaml
version: X.Y.Z
```

`setup.iss` :
```ini
#define MyAppVersion "X.Y.Z"
OutputBaseFilename=MonApp_Setup_vX.Y.Z
```

---

## Étape 5 — Supprimer MSIX si présent

Si le projet utilise le package `msix`, le supprimer de `pubspec.yaml`
pour ne garder qu'un seul système d'installation :

```yaml
dev_dependencies:
  # Supprimer cette ligne :
  msix: ^x.x.x

# Supprimer ce bloc entier :
msix_config:
  display_name: ...
  ...
```

Puis mettre à jour les dépendances :

```bash
flutter pub get
```

---

## Étape 6 — Options recommandées dans `[Setup]`

```ini
; Empêche l'utilisateur de changer le dossier d'installation
; → garantit la mise à jour in-place plutôt qu'une double installation
DisableDirPage=yes

; Architecture cible
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible

; Compression maximale
Compression=lzma
SolidCompression=yes
```

---

## Utilisation

Depuis la racine du projet ou depuis le dossier `installer/` :

```bat
installer\build_installer.bat
```

Le script :
1. Se positionne à la racine du projet automatiquement
2. Exécute `flutter build windows --release`
3. Compile le script `setup.iss` avec Inno Setup
4. Ouvre le dossier `build/installer/` contenant le `.exe` final

---

## Comportement de mise à jour

| Situation                              | Comportement                        |
|----------------------------------------|-------------------------------------|
| Même `AppId`, même dossier             | Mise à jour in-place ✓              |
| Même `AppId`, dossier changé           | Deuxième instance (si `DisableDirPage=no`) |
| `AppId` différent                      | Installation séparée                |
| Fichiers supprimés entre deux versions | Restent sur le poste (non nettoyés) |

Pour nettoyer les anciens fichiers lors d'une mise à jour, utiliser `[InstallDelete]` :

```ini
[InstallDelete]
Type: files; Name: "{app}\ancienne_dll.dll"
```

---

## Checklist avant release

- [ ] Version dans `pubspec.yaml` et `setup.iss` identiques
- [ ] `AppId` unique généré pour ce projet
- [ ] Liste des DLLs vérifiée après build
- [ ] `flutter build windows --release` réussi
- [ ] Icône présente dans `windows/runner/resources/app_icon.ico`
- [ ] `DisableDirPage=yes` si mise à jour in-place souhaitée

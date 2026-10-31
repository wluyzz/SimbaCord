DOWNLOAD THE RELEASE

# Simbacord

Client Discord custom basé sur Equicord, avec installeur Windows et auto-update intégré via GitHub Releases.

## Installation

1. Télécharge `simbacordsetup.exe` depuis la [dernière release](https://github.com/wluyzz/SimbaCord/releases/latest)
2. Lance-le → le dossier `Simbacord` est créé sur ton bureau
3. Un raccourci `Simbacord` apparaît sur le bureau et dans le menu démarrer
4. Clique dessus → Simbacord se lance

## Auto-update

À chaque lancement, Simbacord check les nouvelles versions sur GitHub.
Si une nouvelle version est dispo, l'app télécharge le patch, l'applique, et relance Simbacord.
**Rien à faire** — relance Simbacord et t'es à jour.

## Désinstaller

Via **Paramètres Windows → Applications → Simbacord → Désinstaller**,
ou via le raccourci **Désinstaller** dans le menu démarrer.

## Pour les devs

- `src/SimbacordLauncher.cs` — launcher C# qui check GitHub Releases et applique l'update
- `simbacord-setup.nsi` — script NSIS qui build l'installeur Windows
- `build.ps1` — script PowerShell qui compile le launcher et build l'installeur

### Publier une nouvelle version

1. Modifier le dossier `Simbacord` sur le bureau (changements, patches, etc.)
2. Mettre à jour `version.txt` dans le dossier Simbacord avec le nouveau numéro (ex: `1.0.1`)
3. Mettre à jour `APP_VERSION` dans `simbacord-setup.nsi` et `AssemblyVersion` dans `SimbacordLauncher.cs`
4. Lancer `.\build.ps1` → produit `simbacordsetup.exe` sur le bureau
5. Créer une nouvelle release sur GitHub avec le tag `v1.0.1` et uploader `simbacordsetup.exe` dedans
6. Les utilisateurs recevront l'update automatiquement au prochain lancement

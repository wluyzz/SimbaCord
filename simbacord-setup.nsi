; Simbacord installer - cree un dossier Simbacord avec Simbacord.exe
; sur le bureau de l utilisateur, avec shortcut et icone.
; Shortcuts pointent sur SimbacordLauncher.exe qui gere l auto-update.
!include "MUI2.nsh"

!define APP_NAME "Simbacord"
!define APP_VERSION "1.0.0"
!define SHORTCUT_NAME "Simbacord"
!define SOURCE_DIR "C:\Users\Princee\Desktop\Simbacord"

Name "${APP_NAME}"
OutFile "C:\Users\Princee\Desktop\simbacordsetup.exe"
InstallDir "$DESKTOP\${APP_NAME}"
RequestExecutionLevel user
ShowInstDetails show
BrandingText "Simbacord"

; LZMA compression solid pour reduire la taille au max
SetCompressor /SOLID lzma
SetCompressorDictSize 64

!define MUI_ABORTWARNING
!define MUI_ICON "${SOURCE_DIR}\simbacord.ico"
!define MUI_UNICON "${SOURCE_DIR}\simbacord.ico"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\SimbacordLauncher.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Lancer Simbacord"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "French"

; Silent install flag "/S" supporte par NSIS nativement - utilise par le launcher
; pour appliquer les updates sans UI.

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "${SOURCE_DIR}\*"

  ; shortcuts pointent sur le launcher (auto-update) au lieu de Simbacord.exe direct
  ; icone = simbacord.ico (chat) pour tous les shortcuts
  CreateShortCut "$DESKTOP\${SHORTCUT_NAME}.lnk" "$INSTDIR\SimbacordLauncher.exe" "" "$INSTDIR\simbacord.ico" 0
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\${SHORTCUT_NAME}.lnk" "$INSTDIR\SimbacordLauncher.exe" "" "$INSTDIR\simbacord.ico" 0
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\Desinstaller.lnk" "$INSTDIR\Uninstall.exe"

  ; registry pour Add/Remove Programs
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayIcon" "$INSTDIR\simbacord.ico"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher" "Simbacord"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoModify" "1"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoRepair" "1"

  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\${SHORTCUT_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\${SHORTCUT_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\Desinstaller.lnk"
  RMDir "$SMPROGRAMS\${APP_NAME}"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
SectionEnd

!include "WinVer.nsh"

!define PRODUCT_NAME "WordPipe"
!define PRODUCT_PUBLISHER "https://wordpipe.in/"
!define PRODUCT_WEB_SITE "https://wordpipe.in/"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define PRODUCT_SHORTCUT_NAME "WordPipe.lnk"
!define SOURCECODE_PATH "..\build\windows\runner\Release"

!getdllversion "${SOURCECODE_PATH}\..\..\bin\InnoCast.exe" expv_
#!echo ""
!define PRODUCT_VERSION "${expv_1}.${expv_2}.${expv_3}.${expv_4}"

LoadLanguageFile "${NSISDIR}\Contrib\Language files\SimpChinese.nlf"

VIProductVersion "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=2052 "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey /LANG=2052 "CompanyName" "${PRODUCT_PUBLISHER}"
VIAddVersionKey /LANG=2052 "FileDescription" "${PRODUCT_NAME}"
VIAddVersionKey /LANG=2052 "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=2052 "LegalCopyright" "WordPipe(C) 2023, ${PRODUCT_PUBLISHER}"
VIAddVersionKey /LANG=2052 "OriginalFilename" "app.exe"

SetCompressor lzma

Name "${PRODUCT_NAME}"
OutFile "${SOURCECODE_PATH}\..\PackageTool\InnoCast-v${PRODUCT_VERSION}.exe"
InstallDir "$PROGRAMFILES\InnoCast"
Icon "${SOURCECODE_PATH}\res\InnoCast.ico"
SilentInstall silent



Section "MainSection" SEC01
  ${Unless} ${AtLeastWin7}
    MessageBox MB_ICONINFORMATION "Windows 7"
    Abort
  ${EndIf}

  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer
  File "${SOURCECODE_PATH}\..\SDK\bin\InnoCast.exe"
  File "${SOURCECODE_PATH}\..\SDK\bin\*.dll"
  File "${SOURCECODE_PATH}\..\SDK\bin\config.ini"
  StrCmp $EXEDIR $DESKTOP +2 0
  CreateShortCut "$DESKTOP\${PRODUCT_SHORTCUT_NAME}" "$INSTDIR\InnoCast.exe"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\InnoCast.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"

	#RegDLL "$INSTDIR\screen-capture-recorder.dll"
	#RegDLL "$INSTDIR\audio_sniffer.dll"
  Exec "$INSTDIR\InnoCast.exe"
SectionEnd

Section Uninstall
	#UnRegDLL "$INSTDIR\screen-capture-recorder.dll"
	#UnRegDLL "$INSTDIR\audio_sniffer.dll"

  Delete "$INSTDIR\uninst.exe"
  Delete "$INSTDIR\*.*"
  Delete "$DESKTOP\${PRODUCT_SHORTCUT_NAME}"
  RMDir "$INSTDIR"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  SetAutoClose true
SectionEnd


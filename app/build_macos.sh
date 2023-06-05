#!/usr/bin/env bash
version=$(grep 'version: ' pubspec.yaml | sed 's/version: //g')
FLUTTER_BUILD_NAME=${version%+*}
FLUTTER_BUILD_NUMBER=${version#*+}
echo "pubspec.yaml 中项目“版本名”为 $FLUTTER_BUILD_NAME ，“版本号”为 $FLUTTER_BUILD_NUMBER"
flutter build macos --release --build-name=$FLUTTER_BUILD_NAME --build-number=$FLUTTER_BUILD_NUMBER
mkdir -p dist/$version
test -f dist/$version/WordPipe-macos-$FLUTTER_BUILD_NAME.dmg && rm dist/$version/WordPipe-macos-$FLUTTER_BUILD_NAME.dmg
create-dmg \
  --volname "WordPipe安装器" \
  --background "installer_background.png" \
  --window-pos 200 120 \
  --window-size 600 410 \
  --icon-size 100 \
  --icon "WordPipe.app" 120 190 \
  --hide-extension "WordPipe.app" \
  --app-drop-link 460 185 \
  "dist/$version/WordPipe-macos-$FLUTTER_BUILD_NAME.dmg" \
  "build/macos/Build/Products/Release/WordPipe.app"

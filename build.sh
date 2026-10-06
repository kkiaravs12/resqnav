#!/bin/bash
set -e

# Clone or update Flutter
if [ -d "flutter" ]; then
  cd flutter
  git pull
  cd ..
else
  git clone -b stable https://github.com/flutter/flutter.git --depth 1
fi

# Setup Flutter
export PATH="$PATH:`pwd`/flutter/bin"
flutter config --enable-web
flutter pub get
flutter build web --release --no-tree-shake-icons

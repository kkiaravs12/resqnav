#!/bin/bash
set -e

# Clone Flutter stable
if [ -d "flutter" ]; then
  echo "Flutter already exists"
else
  git clone -b 3.41.0 https://github.com/flutter/flutter.git --depth 1 || \
  git clone -b stable https://github.com/flutter/flutter.git --depth 1
fi

export PATH="$PATH:`pwd`/flutter/bin"
flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release --no-tree-shake-icons

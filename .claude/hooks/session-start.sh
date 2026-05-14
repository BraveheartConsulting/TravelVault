#!/usr/bin/env bash
# SessionStart hook: make sure the Flutter toolchain is available so the
# AiDevTeam agents can run `flutter analyze` and `flutter test` in web sessions.
#
# Idempotent: if Flutter is already on PATH, this is a no-op. Otherwise it does
# a shallow clone of the stable channel into ~/flutter and exports it.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

if command -v flutter >/dev/null 2>&1; then
  echo "[session-start] Flutter already installed: $(flutter --version | head -n1)"
  exit 0
fi

if [ ! -d "$FLUTTER_HOME" ]; then
  echo "[session-start] Installing Flutter ($FLUTTER_VERSION) into $FLUTTER_HOME ..."
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

# Persist PATH for subsequent shells in this session.
if ! grep -q "$FLUTTER_HOME/bin" "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"$FLUTTER_HOME/bin:\$PATH\"" >> "$HOME/.bashrc"
fi

echo "[session-start] Pre-warming Flutter and fetching packages ..."
flutter --version
flutter pub get

echo "[session-start] Flutter ready."

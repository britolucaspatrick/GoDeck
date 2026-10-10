#!/usr/bin/env bash
set -e

echo "=========================================="
echo "    GoDeck Monorepo Environment Setup    "
echo "=========================================="

GO_BIN="${GO_BIN:-/Users/lucasbrito/Documents/vpn1real/tunnel/build/intermediates/cxx/Debug/3h1n606f/obj/generated-src/go-1.24.3/bin/go}"

if command -v go >/dev/null 2>&1; then
    GO_CMD="go"
elif [ -f "$GO_BIN" ]; then
    GO_CMD="$GO_BIN"
else
    echo "[!] Go compiler not found. Please install Go or set GO_BIN."
    exit 1
fi

echo "[+] Using Go: $($GO_CMD version)"

if ! command -v flutter >/dev/null 2>&1; then
    echo "[!] Flutter SDK not found in PATH."
    exit 1
fi

echo "[+] Using Flutter: $(flutter --version | head -n 1)"

echo "[+] Fetching Go server dependencies..."
cd server
$GO_CMD mod tidy
cd ..

echo "[+] Fetching Flutter app dependencies..."
cd app
flutter pub get
cd ..

echo "=========================================="
echo " GoDeck environment ready! Run 'make help'"
echo "=========================================="

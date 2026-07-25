#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  run.sh  –  Interactive Flutter runner for ABRP mobile app
#  Usage: ./run.sh [extra flutter run args]
# ─────────────────────────────────────────────────────────────

VERCEL_URL="https://abrp.vercel.app/api/v1"
LOCAL_URL="http://10.0.2.2:8005/api/v1"   # Android emulator default

echo ""
echo "┌──────────────────────────────────────────────────────┐"
echo "│             ABRP – Select Backend                    │"
echo "├──────────────────────────────────────────────────────┤"
echo "│  1) Vercel  →  https://abrp.vercel.app/api/v1       │"
echo "│  2) Local   →  http://10.0.2.2:8005/api/v1          │"
echo "└──────────────────────────────────────────────────────┘"
echo ""
read -rp "Enter choice [1/2] (default: 2 – Local): " choice

case "$choice" in
  1)
    BASE_URL="$VERCEL_URL"
    echo "▶  Using Vercel backend: $BASE_URL"
    ;;
  *)
    BASE_URL="$LOCAL_URL"
    echo "▶  Using Local backend: $BASE_URL"
    ;;
esac

echo ""
flutter run --dart-define=BASE_URL="$BASE_URL" "$@"

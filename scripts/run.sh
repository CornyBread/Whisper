#!/usr/bin/env bash
#
# Runs Whisper on a physical Android phone, picking the device automatically.
#
#   ./scripts/run.sh                 # debug + hot reload on the connected phone
#   ./scripts/run.sh --release       # any extra flag is forwarded to `flutter run`
#   ./scripts/run.sh --fresh         # uninstall first, so the app starts logged out
#   ./scripts/run.sh --list          # just show what is connected
#
# A physical phone always wins over an emulator; desktop/web targets are ignored.
# With several phones plugged in, it asks which one.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

bold=$'\e[1m'; dim=$'\e[2m'; red=$'\e[31m'; green=$'\e[32m'; yellow=$'\e[33m'; reset=$'\e[0m'

info() { printf '%s==>%s %s\n' "$green" "$reset" "$*"; }
warn() { printf '%s==>%s %s\n' "$yellow" "$reset" "$*" >&2; }
die()  { printf '%s==>%s %s\n' "$red" "$reset" "$*" >&2; exit 1; }

for tool in flutter jq; do
  command -v "$tool" >/dev/null || die "'$tool' no está en el PATH."
done

fresh=false
list_only=false
flutter_args=()
for arg in "$@"; do
  case "$arg" in
    --fresh) fresh=true ;;
    --list)  list_only=true ;;
    *)       flutter_args+=("$arg") ;;
  esac
done

# --- Warn about phones that are plugged in but not usable -------------------
# `flutter devices` silently omits these, which is a confusing way to find out
# that you never accepted the USB debugging prompt.
if command -v adb >/dev/null; then
  while read -r serial state; do
    [[ -z "${serial:-}" ]] && continue
    case "$state" in
      unauthorized) warn "El dispositivo $serial está conectado pero no autorizado: acepta el aviso de depuración USB en la pantalla." ;;
      offline)      warn "El dispositivo $serial aparece 'offline': reconecta el cable o corre 'adb reconnect'." ;;
    esac
  done < <(adb devices 2>/dev/null | tail -n +2)
fi

# --- Pick a device ----------------------------------------------------------
devices_json="$(flutter devices --machine 2>/dev/null || echo '[]')"

# Physical phones first, emulators second; anything non-Android is dropped.
android_json="$(jq -c '
  [ .[]
    | select(.isSupported == true)
    | select(.targetPlatform | startswith("android"))
  ] | sort_by(.emulator)
' <<<"$devices_json")"

count="$(jq 'length' <<<"$android_json")"

if [[ "$list_only" == true ]]; then
  info "Dispositivos Android disponibles:"
  jq -r '.[] | "  • \(.name)  [\(.id)]  \(.sdk)\(if .emulator then "  (emulador)" else "" end)"' <<<"$android_json"
  [[ "$count" -eq 0 ]] && echo "  (ninguno)"
  exit 0
fi

if [[ "$count" -eq 0 ]]; then
  die "No hay ningún dispositivo Android conectado.
  Revisa que el cable esté conectado, que la depuración USB esté activada,
  y que hayas aceptado el aviso en el teléfono. Verifica con: adb devices"
fi

if [[ "$count" -eq 1 ]]; then
  index=0
else
  info "Hay varios dispositivos Android conectados:"
  jq -r 'to_entries[] | "  [\(.key)] \(.value.name)  \(.value.sdk)\(if .value.emulator then "  (emulador)" else "" end)"' <<<"$android_json"
  read -rp "¿Cuál usar? [0] " index
  index="${index:-0}"
  [[ "$index" =~ ^[0-9]+$ && "$index" -lt "$count" ]] || die "Selección inválida: $index"
fi

device="$(jq -c ".[$index]" <<<"$android_json")"
device_id="$(jq -r '.id'   <<<"$device")"
device_name="$(jq -r '.name' <<<"$device")"
device_sdk="$(jq -r '.sdk'  <<<"$device")"

# --- Optional clean slate ---------------------------------------------------
# The session cookies live in the app's documents directory, so they survive a
# hot restart and even a reinstall-over. Only uninstalling logs you out.
if [[ "$fresh" == true ]]; then
  app_id="$(grep -oP 'applicationId\s*=\s*"\K[^"]+' android/app/build.gradle.kts)"
  if [[ -n "$app_id" ]] && command -v adb >/dev/null; then
    info "Desinstalando $app_id para arrancar sin sesión…"
    adb -s "$device_id" uninstall "$app_id" >/dev/null 2>&1 || true
  else
    warn "No pude resolver el applicationId; sigo sin desinstalar."
  fi
fi

info "Corriendo en ${bold}${device_name}${reset} ${dim}(${device_sdk})${reset}"
exec flutter run -d "$device_id" "${flutter_args[@]}"

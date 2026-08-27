#!/bin/sh

# Intentionally macOS-only: no pack system, daemon, state, or runtime downloads.
set -u

category=${1:-}

is_enabled() {
  case "$1" in
    true|1|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

if is_enabled "${CODEX_PEASANT_MUTED:-false}"; then
  exit 0
fi

if [ -n "${PLUGIN_ROOT:-}" ]; then
  plugin_root=$PLUGIN_ROOT
else
  script_dir=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 0
  plugin_root=$(dirname "$script_dir")
fi

sounds=$plugin_root/sounds

case "$category" in
  session_start)
    enabled=${CODEX_PEASANT_SESSION_START:-true}
    set -- \
      "$sounds/PeasantReady1.wav" \
      "$sounds/PeasantWhat1.wav" \
      "$sounds/PeasantWhat2.wav"
    ;;
  prompt_acknowledge)
    enabled=${CODEX_PEASANT_PROMPT_ACKNOWLEDGE:-false}
    set -- \
      "$sounds/PeasantYes1.wav" \
      "$sounds/PeasantYes2.wav" \
      "$sounds/PeasantYes3.wav" \
      "$sounds/PeasantYes4.wav" \
      "$sounds/PeasantYesAttack1.wav" \
      "$sounds/PeasantYesAttack2.wav"
    ;;
  task_complete)
    enabled=${CODEX_PEASANT_TASK_COMPLETE:-true}
    set -- \
      "$sounds/PeasantJobDone.wav" \
      "$sounds/PeasantReady1.wav" \
      "$sounds/PeasantYes1.wav" \
      "$sounds/PeasantYes3.wav" \
      "$sounds/PeasantWhat3.wav"
    ;;
  permission_required)
    enabled=${CODEX_PEASANT_PERMISSION_REQUIRED:-true}
    set -- \
      "$sounds/PeasantWhat1.wav" \
      "$sounds/PeasantWhat2.wav" \
      "$sounds/PeasantWhat3.wav" \
      "$sounds/PeasantWhat4.wav"
    ;;
  compact_warning)
    enabled=${CODEX_PEASANT_COMPACT_WARNING:-false}
    set -- "$sounds/PeasantYesAttack4.wav"
    ;;
  *) exit 0 ;;
esac

is_enabled "$enabled" || exit 0

# CODEX_PEASANT_PLAYER is an internal test seam; normal use always selects afplay.
player=${CODEX_PEASANT_PLAYER:-/usr/bin/afplay}
[ -x "$player" ] || exit 0
[ -x /usr/bin/jot ] || exit 0
[ -x /usr/bin/nohup ] || exit 0

pick=$(/usr/bin/jot -r 1 1 "$#" 2>/dev/null) || pick=1
case "$pick" in
  ''|*[!0-9]*) pick=1 ;;
esac
if [ "$pick" -lt 1 ] || [ "$pick" -gt "$#" ]; then
  pick=1
fi

while [ "$pick" -gt 1 ]; do
  shift
  pick=$((pick - 1))
done

[ -f "$1" ] || exit 0
/usr/bin/nohup "$player" "$1" </dev/null >/dev/null 2>&1 &
exit 0

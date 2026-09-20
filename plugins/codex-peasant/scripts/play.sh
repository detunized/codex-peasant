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

# Codex does not currently include its client/originator in command-hook input.
# On macOS, find the Codex process that owns this hook and inspect its public
# subcommand. `exec` (including its `e` alias) and `review` are non-interactive.
is_non_interactive_codex_session() (
  pid=$PPID

  while [ "$pid" -gt 1 ] 2>/dev/null; do
    process_name=$(/bin/ps -ww -o comm= -p "$pid" 2>/dev/null) || exit 1
    process_name=${process_name#"${process_name%%[![:space:]]*}"}
    process_name=${process_name%"${process_name##*[![:space:]]}"}

    case "${process_name##*/}" in
      codex)
        process_command=$(/bin/ps -ww -o command= -p "$pid" 2>/dev/null) || exit 1
        case "$process_command" in
          *[[:space:]]*) arguments=${process_command#*[[:space:]]} ;;
          *) arguments= ;;
        esac

        # `ps` presents arguments as words. Disable pathname expansion before
        # parsing the documented top-level Codex options and subcommands.
        set -f
        set -- $arguments
        while [ "$#" -gt 0 ]; do
          argument=$1
          shift
          case "$argument" in
            exec|e|review) exit 0 ;;
            --) exit 1 ;;
            -c|--config|--enable|--disable|--remote|--remote-auth-token-env|\
            -i|--image|-m|--model|--local-provider|-p|--profile|-s|--sandbox|\
            -C|--cd|--add-dir|-a|--ask-for-approval)
              [ "$#" -gt 0 ] || exit 1
              shift
              ;;
            --*=*|-c?*|-i?*|-m?*|-p?*|-s?*|-C?*|-a?*) ;;
            -*) ;;
            *) exit 1 ;;
          esac
        done
        exit 1
        ;;
    esac

    parent_pid=$(/bin/ps -ww -o ppid= -p "$pid" 2>/dev/null) || exit 1
    parent_pid=${parent_pid#"${parent_pid%%[![:space:]]*}"}
    parent_pid=${parent_pid%"${parent_pid##*[![:space:]]}"}
    case "$parent_pid" in
      ''|*[!0-9]*) exit 1 ;;
    esac
    [ "$parent_pid" != "$pid" ] || exit 1
    pid=$parent_pid
  done

  exit 1
)

if is_enabled "${CODEX_PEASANT_MUTED:-false}"; then
  exit 0
fi

if is_non_interactive_codex_session; then
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

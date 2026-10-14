#!/bin/bash
# nosleep.sh - keep a Mac awake using the built-in `caffeinate` tool.
#
# Usage:
#   ./nosleep.sh                 Stay awake until you press Ctrl+C
#   ./nosleep.sh -t 2h           Stay awake for a duration (e.g. 90s, 30m, 2h)
#   ./nosleep.sh -p <PID>        Stay awake while a process is running
#   ./nosleep.sh -- <command>    Stay awake while a command runs
#   ./nosleep.sh -d              Also keep the display on (combine with any above)
#
# Without -d, the screen may turn off but the system will not sleep.

set -euo pipefail

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

to_seconds() {
  local v="$1"
  case "$v" in
    *h) echo $(( ${v%h} * 3600 )) ;;
    *m) echo $(( ${v%m} * 60 )) ;;
    *s) echo "${v%s}" ;;
    *[!0-9]*|'') echo "Invalid duration: $v" >&2; exit 1 ;;
    *) echo "$v" ;;
  esac
}

if ! command -v caffeinate >/dev/null 2>&1; then
  echo "caffeinate not found - this script requires macOS." >&2
  exit 1
fi

# -i: prevent idle sleep, -m: prevent disk sleep, -s: prevent sleep on AC power
flags="-ims"
duration=""
pid=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d) flags="${flags}d"; shift ;;
    -t) duration="$(to_seconds "${2:?missing duration}")"; shift 2 ;;
    -p) pid="${2:?missing PID}"; shift 2 ;;
    -h|--help) usage 0 ;;
    --) shift; break ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

args=("$flags")
[[ -n "$duration" ]] && args+=(-t "$duration")
[[ -n "$pid" ]] && args+=(-w "$pid")

if [[ $# -gt 0 ]]; then
  echo "Keeping Mac awake while running: $*"
  exec caffeinate "${args[@]}" "$@"
fi

if [[ -n "$duration" ]]; then
  echo "Keeping Mac awake for $duration seconds (until $(date -v+"${duration}"S '+%H:%M:%S'))."
elif [[ -n "$pid" ]]; then
  echo "Keeping Mac awake while process $pid is running."
else
  echo "Keeping Mac awake. Press Ctrl+C to stop."
fi

trap 'echo; echo "Sleep prevention stopped."' EXIT
caffeinate "${args[@]}"

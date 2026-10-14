#!/bin/bash
# nosleep.sh - keep a Mac awake using the built-in `caffeinate` tool,
# and log every sleep attempt.
#
# Usage:
#   ./nosleep.sh                 Stay awake until you press Ctrl+C
#   ./nosleep.sh -t 2h           Stay awake for a duration (e.g. 90s, 30m, 2h)
#   ./nosleep.sh -p <PID>        Stay awake while a process is running
#   ./nosleep.sh -- <command>    Stay awake while a command runs
#   ./nosleep.sh -d              Also keep the display on (combine with any above)
#   ./nosleep.sh -l <file>       Log file (default: ~/Library/Logs/nosleep.log)
#
# Without -d, the screen may turn off but the system will not sleep.
#
# Logged events:
#   - Idle sleep blocked: you were idle past the system sleep timer, and
#     caffeinate stopped the Mac from sleeping.
#   - Slept anyway: sleep that caffeinate can't block (lid closed, Apple menu >
#     Sleep, low battery), with the reason macOS recorded in `pmset -g log`.

set -euo pipefail

POLL=10   # seconds between checks
logfile="$HOME/Library/Logs/nosleep.log"

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
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

log() {
  local line
  line="$(date '+%Y-%m-%d %H:%M:%S') $*"
  echo "$line"
  echo "$line" >> "$logfile"
}

# Seconds since the last keyboard/mouse input.
idle_seconds() {
  ioreg -c IOHIDSystem | awk '/HIDIdleTime/ { print int($NF / 1000000000); exit }'
}

# System sleep timer in minutes from the active power profile (0 = never).
sleep_minutes() {
  pmset -g | awk '$1 == "sleep" { print $2; exit }'
}

monitor() {
  local last now gap idle limit since blocked=0
  last=$(date +%s)
  since=$(date '+%Y-%m-%d %H:%M:%S')

  while true; do
    sleep "$POLL"
    now=$(date +%s)
    gap=$(( now - last ))

    # A gap much longer than the poll interval means the Mac was asleep.
    if (( gap > POLL + 20 )); then
      log "SLEPT ANYWAY: system was asleep for about $(( gap - POLL ))s"
      pmset -g log \
        | awk -v since="$since" '($4 == "Sleep" || $4 == "Wake" || $4 == "DarkWake") && ($1 " " $2) > since' \
        | while IFS= read -r entry; do log "  pmset: $entry"; done
      blocked=0
    fi

    limit=$(sleep_minutes)
    idle=$(idle_seconds)
    if [[ "$limit" =~ ^[0-9]+$ && "$idle" =~ ^[0-9]+$ ]] && (( limit > 0 )); then
      if (( idle >= limit * 60 )); then
        if (( ! blocked )); then
          log "IDLE SLEEP BLOCKED: idle for ${idle}s, sleep timer is ${limit}m"
          blocked=1
        fi
      elif (( blocked )); then
        log "User activity resumed"
        blocked=0
      fi
    fi

    last=$now
    since=$(date '+%Y-%m-%d %H:%M:%S')
  done
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
    -l) logfile="${2:?missing log file}"; shift 2 ;;
    -h|--help) usage 0 ;;
    --) shift; break ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

mkdir -p "$(dirname "$logfile")"

args=("$flags")
[[ -n "$duration" ]] && args+=(-t "$duration")
[[ -n "$pid" ]] && args+=(-w "$pid")

if [[ $# -gt 0 ]]; then
  log "Started: keeping Mac awake while running: $*"
elif [[ -n "$duration" ]]; then
  log "Started: keeping Mac awake for $duration seconds (until $(date -v+"${duration}"S '+%H:%M:%S'))"
elif [[ -n "$pid" ]]; then
  log "Started: keeping Mac awake while process $pid is running"
else
  log "Started: keeping Mac awake. Press Ctrl+C to stop."
fi
echo "Logging sleep attempts to $logfile"

monitor &
monitor_pid=$!
trap 'kill "$monitor_pid" 2>/dev/null; log "Stopped: sleep prevention ended"' EXIT

status=0
caffeinate "${args[@]}" "$@" || status=$?
exit "$status"

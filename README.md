# mac-nosleep

A small Bash script that stops a Mac from going to sleep and logs every sleep attempt. It uses macOS's built-in `caffeinate` tool, so there's nothing to install.

## Setup

```bash
chmod +x nosleep.sh
```

## Usage

| Command | Effect |
|---|---|
| `./nosleep.sh` | Stay awake until Ctrl+C |
| `./nosleep.sh -t 2h` | Stay awake for a duration (`90s`, `30m`, `2h`, or seconds) |
| `./nosleep.sh -p <PID>` | Stay awake while a process is running |
| `./nosleep.sh -- <command>` | Stay awake while a command runs |
| `./nosleep.sh -d ...` | Also keep the display on |
| `./nosleep.sh -l <file> ...` | Log to a different file (default `~/Library/Logs/nosleep.log`) |

Without `-d`, the screen may turn off but the system won't sleep. On a MacBook, closing the lid still puts it to sleep unless an external display and power are connected.

## Sleep log

While it runs, the script checks every 10 seconds and logs two kinds of event, to the terminal and to the log file:

- **`IDLE SLEEP BLOCKED`**: you were idle longer than the system sleep timer, and the Mac stayed awake because of the script.
- **`SLEPT ANYWAY`**: the Mac slept despite the script, for example because the lid was closed, Sleep was chosen from the Apple menu, or the battery was low. The script adds the matching Sleep/Wake entries from `pmset -g log`, which include the reason macOS recorded.

```
2026-10-14 14:02:11 IDLE SLEEP BLOCKED: idle for 600s, sleep timer is 10m
2026-10-14 15:40:03 SLEPT ANYWAY: system was asleep for about 1834s
2026-10-14 15:40:03   pmset: 2026-10-14 15:09:21 -0300 Sleep  Entering Sleep state due to 'Clamshell Sleep' ...
```

The log file is under `~/Library/Logs`, so you can also read it in Console.app.

## License

MIT

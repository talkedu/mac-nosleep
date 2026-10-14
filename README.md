# mac-nosleep

A small Bash script that stops a Mac from going to sleep. It uses macOS's built-in `caffeinate` tool, so there's nothing to install.

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

Without `-d`, the screen may turn off but the system won't sleep. On a MacBook, closing the lid still puts it to sleep unless an external display and power are connected.

## License

MIT

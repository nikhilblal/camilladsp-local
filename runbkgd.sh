#!/bin/zsh
set -euo pipefail

# Full paths because Automator/launchd PATH is minimal
CAMILLA=/usr/local/bin/camilladsp
TASKPOLICY=/usr/sbin/taskpolicy
LOGDIR="$HOME/camilladsp/logs"

# Give CoreAudio/devices time to settle (dock/hubs etc.)
sleep 12

# Start your *unchanged* CamillaDSP command in the background
"$CAMILLA" \
  --port 1234 \
  --address 0.0.0.0 \
  --statefile "$HOME/camilladsp/statefile.yml" \
  --logfile "$LOGDIR/camilladsp.log" \
  -vv \
  "$HOME/camilladsp/configs/active_config_min.yml" &

# Find the newest camilladsp PID (Automator-safe; avoids $!)
PID=""
for i in {1..40}; do
  PID=$(pgrep -xn camilladsp || true)
  [[ -n "$PID" ]] && break
  sleep 0.25
done

if [[ -z "$PID" ]]; then
  echo "camilladsp not found after launch; check $LOGDIR/camilladsp.log" >&2
  exit 1
fi

# Elevate scheduling tiers (no password needed)
"$TASKPOLICY" -B -l 0 -t 0 -p "$PID" || true

# NOTE: We intentionally skip 'sudo renice' here so Automator won’t block.
# If you want NI -10 without prompts, use the optional LaunchDaemon below.

wait "$PID"

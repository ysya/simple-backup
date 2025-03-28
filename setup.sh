#!/bin/sh

set -e

# === Load .env config ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.env"

# === Validate required .env fields ===
required_vars="SERVICE_NAME SERVICE_PATH RCLONE_REMOTE REMOTE_FOLDER RCLONE_CONFIG_PATH ENCRYPT_PASSWORD CRON_SCHEDULE"
for var in $required_vars; do
  if [ -z "$(eval echo \$$var)" ]; then
    echo "[ERROR] $var is not set in .env"
    exit 1
  fi
done

rclone_config_path=$(eval echo "$RCLONE_CONFIG_PATH")

echo "[1/5] Checking if Docker is installed..."
if ! command -v docker >/dev/null 2>&1; then
  echo "[INFO] Docker not found. Installing..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  echo "[INFO] Docker installed. Please log out and log back in before rerunning this script."
  exit 0
else
  echo "[OK] Docker is already installed."
fi

echo "[2/5] Launching rclone config using Docker..."
docker run --rm -it \
  -v "$(dirname "$rclone_config_path"):/config/rclone" \
  -e RCLONE_CONFIG=/config/rclone/$(basename "$rclone_config_path") \
  rclone/rclone:latest \
  config
echo "[OK] rclone config completed. Saved at: $rclone_config_path"

# Get script and log path
backup_script="$(realpath ./backup.sh)"
log_file="${HOME}/backup.log"

# Ensure backup.sh is executable
chmod +x "$backup_script"

echo "[3/5] Registering cron job (daily at 00:30)..."
if [ -z "$CRON_SCHEDULE" ]; then
  echo "[WARN] CRON_SCHEDULE is not set in .env, using default: 30 0 * * *"
  CRON_SCHEDULE="30 0 * * *"
fi

cron_expr="$CRON_SCHEDULE $backup_script >> $log_file 2>&1"
if crontab -l 2>/dev/null | grep -Fq "$backup_script"; then
  echo "[SKIP] Cron job already exists. Skipping."
else
  (
    crontab -l 2>/dev/null
    echo "$cron_expr"
  ) | crontab -
  echo "[OK] Cron job added successfully."
fi

echo "[4/5] Running backup script once for testing..."
$backup_script || echo "[WARN] Backup test failed. Please check .env or rclone config."

echo "[5/5] Setup complete. Backups will run on schedule: '$CRON_SCHEDULE'. Log file: $log_file"

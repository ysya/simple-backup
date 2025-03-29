#!/bin/sh

set -e

# === Load config ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/.env"

# === Validate required fields ===
required_vars="SERVICE_NAME SERVICE_PATH RCLONE_REMOTE REMOTE_FOLDER RCLONE_CONFIG_PATH ENCRYPT_PASSWORD"
for var in $required_vars; do
  if [ -z "$(eval echo \$$var)" ]; then
    echo "[ERROR] $var is not set in .env"
    exit 1
  fi
done

# === Prepare paths ===
now="$(date +'%Y-%m-%d-%H%M%S')"
filename="${SERVICE_NAME}-${now}.tgz"
encrypted_file="${filename}.gpg"
tar_path="/tmp/$filename"
gpg_path="/tmp/$encrypted_file"
rclone_config_path=$(eval echo "$RCLONE_CONFIG_PATH")
remote_path="${RCLONE_REMOTE}:${REMOTE_FOLDER}"

# === Create tar.gz archive ===
tar -czf "$tar_path" -C "$(dirname "$SERVICE_PATH")" "$(basename "$SERVICE_PATH")"

# === GPG encrypt the archive with password ===
echo "$ENCRYPT_PASSWORD" | gpg --batch --yes --passphrase-fd 0 \
  --symmetric --cipher-algo AES256 \
  -o "$gpg_path" "$tar_path"

# === Upload encrypted archive to remote ===
docker run --rm \
  -v "$gpg_path:/data/$encrypted_file" \
  -v "$rclone_config_path:/config" \
  rclone/rclone:latest \
  copy "/data/$encrypted_file" "$remote_path" --config /config/rclone.conf -P

# === Cleanup local temp files ===
rm -f "$tar_path" "$gpg_path"

# === Remove old backups (older than 30d) from remote ===
docker run --rm \
  -v "$rclone_config_path:/config" \
  rclone/rclone:latest \
  delete "$remote_path" \
  --config /config/rclone.conf \
  --min-age 14d \
  --include "${SERVICE_NAME}-*.tgz.gpg" \
  -P

echo "[$(date)] Encrypted backup complete and old files cleaned."

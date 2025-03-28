# 🔐 Simple Encrypted Backup for Docker Compose / Homelab

This project provides a simple, dockerized backup solution for homelab or self-hosted services using Docker Compose.

It is designed to:

- 🔄 Automatically back up entire service folders
- 🔐 Encrypt the backups using GPG (AES-256, password-based)
- ☁️ Upload the encrypted archive to any rclone-compatible remote (Google Drive, S3, WebDAV, etc.)
- 🐳 Run `rclone` via Docker — no installation needed
- 🧩 Be fully configurable
- 🕒 Schedule daily backup via `cron`

---

## 🎯 Purpose

This tool is built for:

- 🏡 Homelab users
- 🐳 Docker Compose projects
- 💾 Anyone who needs secure and simple full-directory backups
- Without the need for backup software like restic or duplicacy

---

## 📁 Project Structure

```├── backup.sh # Main backup logic (compression + encryption + upload) 
├── install.sh # Setup script: Docker check, rclone config, cron 
├── env # Your backup configuration 
├── env.example # Configuration template
```


---

## ⚙️ Setup

### 1. Clone this repo

```bash
git clone https://github.com/ysya/simple-backup.git
cd simple-backup
```

### 2. Prepare your config
```bash
cp env.example env
vim env
```

### 3. Run the install script
```bash
chmod +x setup.sh
./setup.sh
```

## 📦 What It Does
- Compresses `$SERVICE_PATH `into a .tgz file
- Encrypts it with GPG using `ENCRYPT_PASSWORD`
- Uploads it to `$RCLONE_REMOTE:$REMOTE_FOLDER` using Dockerized rclone
- Keeps only the last 30 days of backups
- Schedules a cron job to run

## 💬 Manual Backup (optional)
```bash
./backup.sh
```
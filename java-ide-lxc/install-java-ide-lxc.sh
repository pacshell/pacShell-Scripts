#!/usr/bin/env bash
# Install a browser-based Java 25 LTS development environment in a Debian 13 Proxmox LXC.
# Usage: bash install-java-ide-lxc.sh [username] [port]
set -Eeuo pipefail

DEV_USER="${1:-developer}"
PORT="${2:-8080}"

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
trap 'printf "\nInstallation failed near line %s.\n" "$LINENO" >&2' ERR

[[ $EUID -eq 0 ]] || die 'Run as root inside the LXC.'
[[ -r /etc/os-release ]] || die 'Cannot identify this Linux distribution.'
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == debian && "${VERSION_ID:-}" == 13 ]] || die 'This script targets Debian 13 (Trixie).'
[[ "$DEV_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || die 'Username must use lowercase letters, digits, underscores or hyphens.'
[[ "$PORT" =~ ^[0-9]+$ ]] && (( 10#$PORT >= 1024 && 10#$PORT <= 65535 )) || die 'Port must be between 1024 and 65535.'
command -v systemctl >/dev/null || die 'systemd is required for automatic service startup.'
[[ "$(ps -p 1 -o comm= | tr -d ' ')" == systemd ]] || die 'This LXC must be booted with systemd as PID 1.'

log 'Installing Debian development packages'
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl git openssl sudo gpg maven gradle \
  unzip zip procps

log 'Configuring the signed Eclipse Adoptium repository for Temurin Java 25 LTS'
KEYRING=/usr/share/keyrings/adoptium.gpg
KEY_TMP="$(mktemp)"
trap 'rm -f "$KEY_TMP"' EXIT
curl --fail --show-error --silent --location \
  https://packages.adoptium.net/artifactory/api/gpg/key/public \
  --output "$KEY_TMP"
gpg --batch --yes --dearmor -o "$KEYRING" "$KEY_TMP"
chmod 644 "$KEYRING"
rm -f "$KEY_TMP"
cat > /etc/apt/sources.list.d/adoptium.list <<EOF
deb [signed-by=$KEYRING] https://packages.adoptium.net/artifactory/deb $VERSION_CODENAME main
EOF
apt-get update
apt-get install -y --no-install-recommends temurin-25-jdk

log 'Selecting Java 25 LTS as the system-wide default'
JAVA_HOME="$(find /usr/lib/jvm -maxdepth 1 -type d -name 'temurin-25-jdk-*' -print -quit)"
[[ -n "$JAVA_HOME" && -x "$JAVA_HOME/bin/java" && -x "$JAVA_HOME/bin/javac" ]] || die 'Temurin 25 JDK installation path not found.'
update-alternatives --set java "$JAVA_HOME/bin/java"
update-alternatives --set javac "$JAVA_HOME/bin/javac"
cat > /etc/profile.d/java-lts.sh <<EOF
export JAVA_HOME="$JAVA_HOME"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF
chmod 644 /etc/profile.d/java-lts.sh

log "Creating or locating Linux user: $DEV_USER"
if ! id "$DEV_USER" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "$DEV_USER"
fi
HOME_DIR="$(getent passwd "$DEV_USER" | cut -d: -f6)"
[[ -n "$HOME_DIR" && -d "$HOME_DIR" ]] || die "Home directory not found for $DEV_USER."

log 'Installing code-server from the official installer'
INSTALLER="$(mktemp)"
trap 'rm -f "$INSTALLER"' EXIT
curl --fail --show-error --silent --location https://code-server.dev/install.sh --output "$INSTALLER"
sh "$INSTALLER"
command -v code-server >/dev/null || die 'code-server executable not found after installation.'

log 'Configuring code-server for LAN access'
CONFIG_DIR="$HOME_DIR/.config/code-server"
WORKSPACE="$HOME_DIR/projects"
install -d -m 700 -o "$DEV_USER" -g "$(id -gn "$DEV_USER")" "$CONFIG_DIR"
install -d -m 755 -o "$DEV_USER" -g "$(id -gn "$DEV_USER")" "$WORKSPACE"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
if [[ ! -f "$CONFIG_FILE" ]]; then
  PASSWORD="$(openssl rand -hex 20)"
  cat > "$CONFIG_FILE" <<EOF
bind-addr: 0.0.0.0:$PORT
auth: password
password: $PASSWORD
cert: false
EOF
  chown "$DEV_USER:$(id -gn "$DEV_USER")" "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
  PASSWORD_CREATED=1
else
  log "Preserving existing config at $CONFIG_FILE"
  PASSWORD_CREATED=0
fi

log 'Installing the Java Extension Pack for the development user'
runuser -u "$DEV_USER" -- env HOME="$HOME_DIR" code-server --install-extension vscjava.vscode-java-pack

log 'Creating a sample Java program'
SAMPLE_DIR="$WORKSPACE/hello-java"
install -d -m 755 -o "$DEV_USER" -g "$(id -gn "$DEV_USER")" "$SAMPLE_DIR"
if [[ ! -e "$SAMPLE_DIR/Main.java" ]]; then
  cat > "$SAMPLE_DIR/Main.java" <<'JAVA'
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello from Java in a Proxmox LXC!");
    }
}
JAVA
  chown "$DEV_USER:$(id -gn "$DEV_USER")" "$SAMPLE_DIR/Main.java"
fi

log 'Enabling code-server systemd service'
systemctl enable --now "code-server@${DEV_USER}.service"
systemctl restart "code-server@${DEV_USER}.service"
systemctl is-active --quiet "code-server@${DEV_USER}.service" || die 'code-server service is not running.'

log 'Checking the Java 25 LTS installation'
[[ "$(java -version 2>&1 | head -n 1)" == *'25.'* ]] || die 'Java 25 is not the selected default.'
java -version
javac -version
mvn -version | head -n 3
gradle --version | grep -E '^Gradle ' || true

IP_ADDR="$(hostname -I 2>/dev/null | awk '{print $1}')"
printf '\n========================================================\n'
printf 'Java 25 LTS IDE installation completed.\n'
printf 'JAVA_HOME: %s\n' "$JAVA_HOME"
printf 'User: %s\n' "$DEV_USER"
printf 'URL: http://%s:%s\n' "${IP_ADDR:-LXC_IP}" "$PORT"
if [[ "$PASSWORD_CREATED" == 1 ]]; then
  printf 'New code-server password: %s\n' "$PASSWORD"
else
  printf 'Existing code-server configuration preserved: %s\n' "$CONFIG_FILE"
fi
printf 'Workspace: %s\n' "$WORKSPACE"
printf 'Test: runuser -u %s -- java %s/hello-java/Main.java\n' "$DEV_USER" "$WORKSPACE"
printf 'Service: systemctl status code-server@%s\n' "$DEV_USER"
printf 'IMPORTANT: HTTP is unencrypted. Restrict access to your trusted LAN or use HTTPS/VPN.\n'
printf '========================================================\n'

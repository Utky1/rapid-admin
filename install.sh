#!/bin/bash
# Normalize line endings (avoid CRLF issues)
if file "$0" | grep -q CRLF; then
    echo "[!] Converting line endings..."
    dos2unix "$0" >/dev/null 2>&1 || true
fi

set -e

APP_NAME="Rapid K1"
CMD_NAME="rpdk1"
REPO_URL="https://github.com/Utky1/rapid-admin"
BRANCH="main"
INSTALL_DIR="/opt/rapidk1"
BIN_PATH="/usr/local/bin/$CMD_NAME"
DESKTOP_PATH="/usr/share/applications/${CMD_NAME}.desktop"
ICON_NAME="utilities-terminal"
VERSION="v1.0.0"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
echo_info(){ echo -e "${GREEN}[*]${NC} $1"; }
echo_warn(){ echo -e "${YELLOW}[!]${NC} $1"; }
echo_err(){  echo -e "${RED}[x]${NC} $1"; }

# --- Uninstall mode ---
if [[ "$1" == "--uninstall" ]]; then
    echo ""
    echo "────────────────────────────────────────────"
    echo "🧹  Rapid K1 Uninstaller"
    echo "────────────────────────────────────────────"

    FILES_TO_REMOVE=(
        "$INSTALL_DIR"
        "$BIN_PATH"
        "$DESKTOP_PATH"
    )

    for f in "${FILES_TO_REMOVE[@]}"; do
        if [ -e "$f" ]; then
            echo "[*] Removing $f"
            rm -rf "$f"
        else
            echo "[!] Skipping missing file: $f"
        fi
    done

    echo ""
    echo "[*] Refreshing desktop database..."
    update-desktop-database /usr/share/applications >/dev/null 2>&1 || true

    echo ""
    echo "✅ Rapid K1 has been fully uninstalled!"
    echo ""
    echo "If you installed via GitHub (curl), you can rerun it anytime:"
    echo "  curl -sSL $REPO_URL/raw/$BRANCH/install.sh | sudo bash"
    echo ""
    exit 0
fi


# --- Root check ---
if [ "$EUID" -ne 0 ]; then
  echo_err "Please run as root (sudo ./install.sh)"
  exit 1
fi

# --- Show banner ---
echo ""
echo -e "${RED}"
cat << 'EOF'
__________    _____ __________.___________     ____  __.____ 
\______   \  /  _  \\______   \   \______ \   |    |/ _/_   |
 |       _/ /  /_\  \|     ___/   ||    |  \  |      <  |   |
 |    |   \/    |    \    |   |   ||    `   \ |    |  \ |   |
 |____|_  /\____|__  /____|   |___/_______  / |____|__ \|___|
        \/         \/                     \/          \/     
EOF
echo -e "${RED}"
echo "               $APP_NAME $VERSION"
echo ""

# --- Ensure required packages ---
echo_info "Installing system dependencies..."
apt update -qq
apt install -y python3 python3-pip dos2unix unzip curl desktop-file-utils >/dev/null

# --- Determine script directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Download repo if files not local ---
if [ ! -f "$SCRIPT_DIR/admin.py" ]; then
    echo_info "Fetching $APP_NAME from GitHub..."
    TMP_DIR=$(mktemp -d)
    curl -L "$REPO_URL/archive/refs/heads/$BRANCH.zip" -o "$TMP_DIR/repo.zip"
unzip -qq "$TMP_DIR/repo.zip" -d "$TMP_DIR"

# Find the extracted folder automatically
EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "*-main" | head -n 1)
SCRIPT_DIR="$EXTRACTED_DIR"

fi

# --- Prepare install directory ---
echo_info "Installing files to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR"/

# --- Convert line endings ---
find "$INSTALL_DIR" -type f -name "*.py" -exec dos2unix {} \; >/dev/null 2>&1 || true

# --- Ensure shebang in main file ---
if ! grep -q '^#!/usr/bin/env python3' "$INSTALL_DIR/admin.py"; then
  sed -i '1i #!/usr/bin/env python3' "$INSTALL_DIR/admin.py"
fi

# --- Install Python dependencies ---
if [ -f "$INSTALL_DIR/requirements.txt" ]; then
  echo_info "Installing Python dependencies..."
  if ! pip3 install -r "$INSTALL_DIR/requirements.txt" >/dev/null 2>&1; then
    echo_warn "Retrying with --break-system-packages..."
    pip3 install --break-system-packages -r "$INSTALL_DIR/requirements.txt"
  fi
else
  echo_warn "No requirements.txt found — skipping dependency install."
fi

# --- Create executable command ---
echo_info "Creating command shortcut..."
cat <<EOF > "$BIN_PATH"
#!/bin/bash
python3 $INSTALL_DIR/admin.py "\$@"
EOF
chmod +x "$BIN_PATH"

# --- Create desktop entry ---
echo_info "Adding $APP_NAME to applications menu..."
cat <<EOF > "$DESKTOP_PATH"
[Desktop Entry]
Name=$APP_NAME
Comment=Run $APP_NAME Console Tool
Exec=gnome-terminal -- bash -c "$CMD_NAME; echo; read -p 'Press Enter to close...'"
Icon=$ICON_NAME
Terminal=false
Type=Application
Categories=Utility;
EOF
chmod +x "$DESKTOP_PATH"
update-desktop-database /usr/share/applications >/dev/null 2>&1 || true

# --- Clean temp downloads ---
rm -rf "$TMP_DIR" 2>/dev/null || true

echo ""
echo_info "$APP_NAME successfully installed!"
echo_info "Run it with: ${YELLOW}$CMD_NAME${NC}"
echo_info "Uninstall anytime with: ${YELLOW}sudo bash install.sh --uninstall${NC}"
echo ""

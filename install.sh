#!/bin/bash
# =======================================
#  RAPID K1 Installer for Linux (Kali)
#  Author: Utku Eren Adar
#  Description: Installs RAPID version K1 system-wide
# =======================================

set -e

# -------- CONFIG --------
APP_NAME="RAPID K1"
CMD_NAME="rpdk1"
SCRIPT_NAME="admin.py"
INSTALL_DIR="/usr/local/bin"
DESKTOP_FILE="/usr/share/applications/${CMD_NAME}.desktop"
ICON_PATH="/usr/share/icons/hicolor/48x48/apps/${CMD_NAME}.png"
CONFIG_DIR="/etc/${CMD_NAME}"
CONFIG_FILE="config.json"

# -------- COLORS --------
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# -------- FUNCTIONS --------
echo_info() { echo -e "${YELLOW}[INFO]${RESET} $1"; }
echo_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
echo_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# -------- CHECK ROOT --------
if [ "$EUID" -ne 0 ]; then
  echo_error "Please run as root (sudo ./install.sh)"
  exit 1
fi

# -------- CHECK PYTHON --------
if ! command -v python3 &> /dev/null; then
  echo_error "Python3 not found. Please install it first."
  exit 1
fi

# -------- INSTALL PYTHON DEPENDENCIES --------
if [ -f "requirements.txt" ]; then
  echo_info "Installing Python dependencies..."
  pip3 install -r requirements.txt
else
  echo_info "No requirements.txt found, skipping Python dependencies."
fi

# -------- INSTALL MAIN SCRIPT --------
echo_info "Installing ${APP_NAME} to ${INSTALL_DIR}..."
chmod +x "$SCRIPT_NAME"
cp "$SCRIPT_NAME" "${INSTALL_DIR}/${CMD_NAME}"

# -------- CONFIG FILE SETUP --------
if [ -f "$CONFIG_FILE" ]; then
  echo_info "Setting up configuration..."
  mkdir -p "$CONFIG_DIR"
  if [ ! -f "${CONFIG_DIR}/${CONFIG_FILE}" ]; then
    cp "$CONFIG_FILE" "${CONFIG_DIR}/${CONFIG_FILE}"
    echo_success "Config installed to ${CONFIG_DIR}/${CONFIG_FILE}"
  else
    echo_info "Config already exists at ${CONFIG_DIR}/${CONFIG_FILE}, keeping existing one."
  fi
else
  echo_info "No config.json found, skipping configuration setup."
fi

# -------- CREATE .DESKTOP FILE --------
echo_info "Creating Applications menu shortcut..."
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=${APP_NAME}
Comment=Run ${APP_NAME} Console Tool
Exec=${INSTALL_DIR}/${CMD_NAME}
Icon=${ICON_PATH}
Terminal=true
Type=Application
Categories=Utility;
EOF

chmod +x "$DESKTOP_FILE"

# -------- INSTALL ICON (optional) --------
if [ -f "icon.png" ]; then
  mkdir -p "$(dirname "$ICON_PATH")"
  cp "icon.png" "$ICON_PATH"
  echo_info "Installed icon to ${ICON_PATH}"
else
  echo_info "No icon.png found, skipping icon installation."
fi

# -------- FINISH --------
echo_success "${APP_NAME} installed successfully!"
echo_success "Run it with: ${CMD_NAME}"
echo_success "Or find it under: Applications → Utilities → ${APP_NAME}"

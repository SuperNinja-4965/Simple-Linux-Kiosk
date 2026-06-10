#!/bin/bash

# Shared config

# Username & Password for the live user
export USERNAME='live'
export USERPASSWORD='liveuser'

# Configuration matrix for applications using arrays
# Each entry is an array with format: [display_name build_type CagedPackage exec_command]
# Build types can be 'x86_64', 'RPI64' or 'RPI32' or 'RPI' for an RPI build
declare -a FIREFOX_X86_64=('Firefox on x86_64' 'x86_64' 'firefox' 'ExecStart=/usr/bin/cage -s -- /usr/bin/firefox --kiosk --no-remote --start-fullscreen --no-proxy-server "https://google.com"')
declare -a CHROMIUM_RPI=('Chromium on RPI' 'RPI64' 'chromium' 'ExecStart=/usr/bin/cage -s -- /usr/bin/chromium --kiosk "https://google.com" --noerrdialogs --disable-infobars --incognito --start-fullscreen --autoplay-policy=no-user-gesture-required --disable-session-crashed-bubble --no-proxy-server --no-first-run')
declare -a CHROMIUM_X86_64=('Chromium on x86_64' 'x86_64' 'chromium' 'ExecStart=/usr/bin/cage -s -- /usr/bin/chromium --kiosk "https://google.com" --noerrdialogs --disable-infobars --incognito --start-fullscreen --autoplay-policy=no-user-gesture-required --disable-session-crashed-bubble --no-proxy-server --no-first-run')
declare -a FIREFOX_RPI=('Firefox on RPI' 'RPI64' 'firefox' 'ExecStart=/usr/bin/cage -s -- /usr/bin/firefox --kiosk --no-remote --start-fullscreen --no-proxy-server "https://google.com"')

# Main configuration array that includes all configurations
declare -a CONFIG_MATRIX=(FIREFOX_X86_64 FIREFOX_RPI CHROMIUM_X86_64 CHROMIUM_RPI)

# These variables will be set by the build script based on user selection
export BUILD_TYPE=''
export CAGED_APP=''
export CAGEEXECSTART_LINE=''

# RPI CONFIG
export RPI_IMG_NAME="SimpleLinuxKiosk-RPI-$(openssl rand -base64 4 | tr -dc 'a-zA-Z0-9' | head -c 5)"
export RPI_PI_GEN_RELEASE='Simple Linux Kiosk - Raspberry Pi Version'
export RPI_DEPLOY_COMPRESSION='xz'
export RPI_COMPRESSION_LEVEL='9'
export RPI_USE_QEMU='0'
export RPI_LOCALE_DEFAULT='en_GB.UTF-8'
export RPI_TARGET_HOSTNAME='rpi-kiosk'
export RPI_KEYBOARD_KEYMAP='gb'
export RPI_KEYBOARD_LAYOUT='English (UK)'
export RPI_TIMEZONE_DEFAULT='Europe/London'
export RPI_DISABLE_FIRST_BOOT_USER_RENAME='1'
export RPI_WPA_COUNTRY='GB'
export RPI_ENABLE_SSH='0'

# x86_64 Only
export PACMAN_MIRROR=""
export ENABLE_PACMAN_CACHE="Y"
export USE_SECUREBOOT="N"
export SECUREBOOT_MOK_KEY=""
export SECUREBOOT_MOK_CRT=""
export SECUREBOOT_MOK_CER=""

# Do not change these values unless you have updated any other relevant files.

# Essential Directories
export BUILD_DIR="$BASE_DIR/build"
mkdir -p "$BUILD_DIR"
export ISO_DIR="$BUILD_DIR/iso"
mkdir -p "$ISO_DIR"
export BUILD_TMP="$(mktemp -d $BUILD_DIR/build-XXXXXXXXXX)"
export CONFIG_DIR="$BUILD_TMP/config"
mkdir -p "$CONFIG_DIR"
export CACHE_DIR="$BUILD_DIR/cache"
mkdir -p "$CACHE_DIR"

# Config Files - Well the ones that need updating.
export CAGE_SERVICE_PATH="$CONFIG_DIR/airootfs/etc/systemd/system/cage@.service"
export GETTY_TTY3_SERVICE="$CONFIG_DIR/airootfs/etc/systemd/system/getty@tty3.service.d/autologin.conf"

# x86_64 Only
export SHADOW_FILE="$CONFIG_DIR/airootfs/etc/shadow"
export GROUP_FILE="$CONFIG_DIR/airootfs/etc/group"
export GSHADOW_FILE="$CONFIG_DIR/airootfs/etc/gshadow"
export PASSWD_FILE="$CONFIG_DIR/airootfs/etc/passwd"


# Contants
export USERPASSWORDHASH=$(echo "$USERPASSWORD" | openssl passwd -6 -stdin) # Generate a password with a random salt

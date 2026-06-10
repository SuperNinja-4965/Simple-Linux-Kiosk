#!/bin/bash
set -e

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Replace line
echo "🔧 Patching packages.x86_64..."
cat <<EOF >> $CONFIG_DIR/packages.x86_64
# Our caged Application
$CAGED_APP
EOF

echo "🔧 Patching Cage Service..."
sed -i "s|^ExecStart=.*|$CAGEEXECSTART_LINE|" "$CAGE_SERVICE_PATH"
sed -i "s/^User=<user>/User=$USERNAME/" "$CAGE_SERVICE_PATH"

echo "🔧 Patching TTY3 for autologin..."
sed -i "s/--autologin <user>/--autologin $USERNAME/" "$GETTY_TTY3_SERVICE"

echo "🔧 Setting up user $USERNAME..."
if grep -q "^<user>:" "$SHADOW_FILE"; then
    sed -i "s|^<user>:[^:]*:|$USERNAME:$USERPASSWORDHASH:|" "$SHADOW_FILE" &&
    echo "✅ Updated $SHADOW_FILE" || echo "❌ Failed to update $SHADOW_FILE"
else
    echo "⚠️ Pattern not found in $SHADOW_FILE"
fi

if grep -q "<user>" "$GROUP_FILE"; then
    sed -i "s/<user>/$USERNAME/g" "$GROUP_FILE" &&
    echo "✅ Updated $GROUP_FILE" || echo "❌ Failed to update $GROUP_FILE"
else
    echo "⚠️ Pattern not found in $GROUP_FILE"
fi

if grep -q "^<user>:" "$GSHADOW_FILE"; then
    sed -i "s/^<user>:.*$/$USERNAME:!*::/g" "$GSHADOW_FILE" &&
    echo "✅ Updated $GSHADOW_FILE" || echo "❌ Failed to update $GSHADOW_FILE"
else
    echo "⚠️ Pattern not found in $GSHADOW_FILE"
fi

if grep -q "<user>" "$PASSWD_FILE"; then
    sed -i "s/<user>/$USERNAME/g" "$PASSWD_FILE" &&
    echo "✅ Updated $PASSWD_FILE" || echo "❌ Failed to update $PASSWD_FILE"
else
    echo "⚠️ Pattern not found in $PASSWD_FILE"
fi

echo "▶️ Downloading latest ArchLinux Docker Image..."
if ! docker pull archlinux:latest; then
  echo "❌ Failed to pull ArchLinux Docker image."
  exit 1
fi

# Build ISO in Docker
echo "▶️ Building ISO..."
DOCKER_RUN_ARGS=(--privileged)
if [ "${CI:-false}" != "false" ]; then
    DOCKER_RUN_ARGS+=(-it)
fi

# Add pacman cache volume if enabled
if [ "${ENABLE_PACMAN_CACHE:-N}" = "Y" ]; then
    mkdir -p "$CACHE_DIR/pacman"
    DOCKER_RUN_ARGS+=(-v "$CACHE_DIR/pacman":/pacman)
fi

export ISO_NAME_PRE="SimpleLinuxKiosk-$(openssl rand -base64 4 | tr -dc 'a-zA-Z0-9' | head -c 5)"

if ! docker run "${DOCKER_RUN_ARGS[@]}" \
                --rm \
                -e ISO_NAME_PRE="$ISO_NAME_PRE" \
                -e PACMAN_MIRROR="$PACMAN_MIRROR" \
                -v "$BUILD_TMP":/build \
                -v "$ISO_DIR":/iso \
                -w /build archlinux:latest \
                /bin/bash -c '
                if [ -n "$PACMAN_MIRROR" ]; then
                    echo "Server = $PACMAN_MIRROR" > /etc/pacman.d/mirrorlist
                fi
                pacman -Sy --noconfirm archlinux-keyring archiso edk2-ovmf gnupg grub openssl libisoburn sbsigntools rpmextract cpio mtools || {
                    echo "❌ Failed to install required packages with pacman.";
                    exit 1;
                }
                mkdir -p /build/iso
                mkarchiso -v -w "/build/work" -o "/iso" "/build/config"
            '; then

  echo "❌ mkarchiso failed."
  exit 1
fi

if [ "${USE_SECUREBOOT:-N}" != "N" ]; then
    echo "Injecting Secure Boot Shim into ISO..."
    if ! "$BASE_DIR/x86_64/secureboot/inject-secureboot.sh" inject --in "$ISO_DIR/$ISO_NAME_PRE-$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)-x86_64.iso" --out "$ISO_DIR/$ISO_NAME_PRE-$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)-x86_64-secureboot.iso" --key "$SECUREBOOT_MOK_KEY" --cer "$SECUREBOOT_MOK_CER" --crt "$SECUREBOOT_MOK_CRT"; then
        echo "❌ Failed to inject Secure Boot Shim into ISO."
        exit 1
    fi
    rm "$ISO_DIR/$ISO_NAME_PRE-$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)-x86_64.iso"
fi

echo "✅ Done! ISO built."
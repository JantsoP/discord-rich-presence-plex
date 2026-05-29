#!/bin/bash
set -e

VNC_PW="${VNC_PW:-password}"
DISPLAY="${DISPLAY:-:1}"
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"

# ── Root-level setup ──────────────────────────────────────────────────────────

# Create and permission the runtime directory; drpp mounts it at /run/app and
# expects it owned by the Discord user (UID 1000).
mkdir -p "$XDG_RUNTIME_DIR"
chown discord:discord "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Ensure any host-mounted Discord config volume is owned correctly.
chown -R discord:discord /home/discord

# Store the VNC password.
mkdir -p /home/discord/.vnc
x11vnc -storepasswd "$VNC_PW" /home/discord/.vnc/passwd 2>/dev/null || true
chown -R discord:discord /home/discord/.vnc

# ── Locate the Discord binary (handles both old and new .deb install paths) ───

if [ -f /usr/share/discord/Discord ]; then
    DISCORD_BIN=/usr/share/discord/Discord
elif [ -f /opt/discord/Discord ]; then
    DISCORD_BIN=/opt/discord/Discord
elif command -v discord &>/dev/null; then
    DISCORD_BIN=$(command -v discord)
else
    echo "ERROR: Discord binary not found. The image may need to be rebuilt." >&2
    exit 1
fi
echo "Using Discord binary: $DISCORD_BIN"

# ── Start X server ────────────────────────────────────────────────────────────

su -s /bin/bash discord -c "Xvfb $DISPLAY -screen 0 1280x800x24 +extension GLX +render -noreset &"
sleep 2

# ── Start window manager ──────────────────────────────────────────────────────

su -s /bin/bash discord -c "DISPLAY=$DISPLAY openbox --sm-disable &"
sleep 1

# ── Start VNC server ──────────────────────────────────────────────────────────

su -s /bin/bash discord -c \
    "x11vnc -display $DISPLAY -forever -shared \
     -rfbauth /home/discord/.vnc/passwd -rfbport 5900 \
     -noxdamage -nopw &"
sleep 1

# ── Start noVNC web proxy ─────────────────────────────────────────────────────

websockify --web=/usr/share/novnc 6080 localhost:5900 &

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Web VNC: http://localhost:6080/vnc.html"
echo " Raw VNC: localhost:5900  (password: $VNC_PW)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Start Discord ─────────────────────────────────────────────────────────────

start_discord() {
    su -s /bin/bash discord -c \
        "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR DISPLAY=$DISPLAY $DISCORD_BIN --no-sandbox &"
}

start_discord

# ── Watchdog: restart Discord if it exits ────────────────────────────────────

while true; do
    sleep 5
    if ! pgrep -x "$(basename "$DISCORD_BIN")" > /dev/null 2>&1; then
        echo "Discord exited — restarting..."
        start_discord
    fi
done

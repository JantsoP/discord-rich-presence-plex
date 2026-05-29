FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    XDG_RUNTIME_DIR=/run/user/1000

# Install X11, window manager, VNC, noVNC, and Discord runtime dependencies
RUN apt-get update && apt-get install -y \
    xvfb \
    x11vnc \
    openbox \
    novnc \
    python3-websockify \
    curl \
    procps \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcairo2 \
    libcups2 \
    libdrm2 \
    libexpat1 \
    libgbm1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnss3 \
    libpango-1.0-0 \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libxss1 \
    && rm -rf /var/lib/apt/lists/*

# Install Discord from official .deb
RUN curl -fsSL -o /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb" \
    && apt-get update \
    && apt-get install -y /tmp/discord.deb \
    && rm /tmp/discord.deb \
    && rm -rf /var/lib/apt/lists/*

# Create discord user (UID 1000) for IPC socket ownership compatibility with drpp
RUN useradd -m -u 1000 -s /bin/bash discord

# Pre-configure Discord: disable auto-update and first-run screens
RUN mkdir -p /home/discord/.config/discord \
    && echo '{"SKIP_HOST_UPDATE":true,"IS_MAXIMIZED":false,"IS_MINIMIZED":false,"WINDOW_BOUNDS":{"x":0,"y":0,"width":1280,"height":800}}' \
        > /home/discord/.config/discord/settings.json \
    && chown -R discord:discord /home/discord

COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# 5900 = raw VNC, 6080 = noVNC web browser access
EXPOSE 5900 6080

ENTRYPOINT ["/startup.sh"]

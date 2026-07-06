# Browser-accessible XFCE desktop with Fiji, for the Fileglancer Remote
# Desktop app. Runs read-only under rootless Apptainer on cluster nodes: no
# systemd/s6, nothing writes inside the image at runtime, and everything is
# started by /opt/fg-desktop/start-desktop.sh as the (non-root) invoking user.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

# Desktop + VNC stack, plus the X/GL/font libraries Fiji (Java Swing) needs.
# --no-install-recommends keeps the image lean and, importantly, keeps screen
# lockers (light-locker/xfce4-screensaver) out: a locked screen inside the
# container could never be unlocked.
RUN apt-get update && apt-get install -y --no-install-recommends \
        xfce4 \
        xfce4-terminal \
        elementary-xfce-icon-theme \
        dbus-x11 \
        xauth \
        x11-xserver-utils \
        tigervnc-standalone-server \
        python3 \
        python3-pip \
        ca-certificates \
        curl \
        unzip \
        fonts-dejavu-core \
        fontconfig \
        libxext6 \
        libxrender1 \
        libxtst6 \
        libxi6 \
        libxrandr2 \
        libgl1 \
        libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# websockify >= 0.11 provides the UnixDomainSocketDirectory token plugin that
# the launcher's security model depends on; assert it imports at build time.
RUN pip3 install --no-cache-dir --break-system-packages websockify==0.13.0 \
    && python3 -c 'from websockify.token_plugins import UnixDomainSocketDirectory'

# noVNC browser client (static files only; websockify does the serving)
ARG NOVNC_VERSION=1.6.0
RUN curl -fsSL "https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.tar.gz" \
        | tar -xz -C /opt \
    && mv "/opt/noVNC-${NOVNC_VERSION}" /opt/novnc

# Fiji, with bundled JDK. Only a rolling "latest" bundle is published these
# days (the versioned releases/ directory stopped at 2.14.0 in 2023), so
# reproducibility comes from this image's version tag, not the Fiji URL.
RUN curl -fsSL https://downloads.imagej.net/fiji/latest/fiji-latest-linux64-jdk.zip \
        -o /tmp/fiji.zip \
    && unzip -q /tmp/fiji.zip -d /tmp/fiji-extract \
    && rm /tmp/fiji.zip \
    && d="$(find /tmp/fiji-extract -mindepth 1 -maxdepth 1 -type d)" \
    && mv "$d" /opt/fiji \
    && rmdir /tmp/fiji-extract \
    && { test -x /opt/fiji/fiji-linux-x64 \
         || test -x /opt/fiji/ImageJ-linux64 \
         || test -x /opt/fiji/fiji; }

COPY fiji-wrapper.sh /usr/local/bin/fiji
COPY fiji.desktop /usr/share/applications/fiji.desktop
COPY start-desktop.sh /opt/fg-desktop/start-desktop.sh
RUN chmod 755 /usr/local/bin/fiji /opt/fg-desktop/start-desktop.sh

CMD ["/opt/fg-desktop/start-desktop.sh"]

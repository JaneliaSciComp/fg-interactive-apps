#!/bin/bash
# Fileglancer Remote Desktop launcher: an XFCE session on a VNC server, served
# to the browser by noVNC/websockify on the single Fileglancer-provided port.
#
# Connection chain, and how each hop is protected on a shared compute node:
#
#   browser --HTTP/WS, ?token=$FG_SERVICE_TOKEN--> websockify 0.0.0.0:$FG_SERVICE_PORT
#     --unix socket named after the token, in a 0700 dir--> Xvnc (TCP disabled)
#       --X11 display, xauth cookie required--> XFCE session, Fiji, ...
#
# - websockify's UnixDomainSocketDirectory token plugin only tunnels WebSocket
#   connections whose ?token= matches a socket filename in the private
#   directory, so network access requires the per-job 192-bit token.
# - Xvnc listens only on that unix socket (-rfbport -1 disables TCP). The 0700
#   directory keeps other users on the node from reaching the VNC server at
#   all, which is what makes -SecurityTypes None safe here.
# - The X display itself requires the xauth cookie (mode 0600), so other local
#   users cannot attach through /tmp/.X11-unix either.

set -euo pipefail

: "${FG_SERVICE_PORT:?FG_SERVICE_PORT is not set - this app requires the Fileglancer service contract}"
: "${FG_SERVICE_TOKEN:?FG_SERVICE_TOKEN is not set - this app requires the Fileglancer service contract}"

DATA_DIR="${1:-}"
GEOMETRY="${FG_DESKTOP_GEOMETRY:-1920x1080}"

# Private per-session state (X auth cookie, VNC socket, XDG runtime). This must
# be on node-local disk - unix sockets are unreliable on NFS homes - and
# mktemp -d creates it mode 0700, which is what keeps other users out.
PRIV_DIR="$(mktemp -d /tmp/fg-desktop.XXXXXXXX)"
SOCK_DIR="$PRIV_DIR/sock"
XAUTH_FILE="$PRIV_DIR/Xauthority"
VNC_SOCKET="$SOCK_DIR/$FG_SERVICE_TOKEN"
export XDG_RUNTIME_DIR="$PRIV_DIR/run"
mkdir -m 700 "$SOCK_DIR" "$XDG_RUNTIME_DIR"

XVNC_PID=""
SESSION_PID=""
cleanup() {
  if [ -n "$SESSION_PID" ]; then kill "$SESSION_PID" 2>/dev/null || true; fi
  if [ -n "$XVNC_PID" ]; then kill "$XVNC_PID" 2>/dev/null || true; fi
  rm -rf "$PRIV_DIR"
}
trap cleanup EXIT

# --- Xvnc --------------------------------------------------------------------
# Scan for a free X display (vncserver-style). Another user on the node can
# grab a display between our check and Xvnc's startup, so on failure move on
# to the next number.
DISPLAY_NUM=""
for n in $(seq 10 99); do
  [ -e "/tmp/.X${n}-lock" ] && continue
  [ -e "/tmp/.X11-unix/X${n}" ] && continue

  # The cookie must exist before Xvnc starts: -auth is read at server startup.
  rm -f "$XAUTH_FILE" && touch "$XAUTH_FILE" && chmod 600 "$XAUTH_FILE"
  xauth -f "$XAUTH_FILE" add ":${n}" MIT-MAGIC-COOKIE-1 "$(mcookie)" 2>/dev/null

  Xvnc ":${n}" \
    -rfbunixpath "$VNC_SOCKET" -rfbunixmode 0600 \
    -rfbport -1 \
    -SecurityTypes None \
    -auth "$XAUTH_FILE" \
    -geometry "$GEOMETRY" -depth 24 \
    -desktop "Fileglancer Desktop" &
  XVNC_PID=$!

  # Up when the VNC unix socket appears; dead (lost the display race) if Xvnc exits.
  for _ in $(seq 1 50); do
    [ -S "$VNC_SOCKET" ] && break
    kill -0 "$XVNC_PID" 2>/dev/null || break
    sleep 0.2
  done
  if [ -S "$VNC_SOCKET" ]; then
    DISPLAY_NUM="$n"
    break
  fi
  kill "$XVNC_PID" 2>/dev/null || true
  wait "$XVNC_PID" 2>/dev/null || true
  XVNC_PID=""
  rm -f "$VNC_SOCKET"
done

if [ -z "$DISPLAY_NUM" ]; then
  echo "ERROR: could not start Xvnc on any display (:10-:99)" >&2
  exit 1
fi

export DISPLAY=":${DISPLAY_NUM}"
export XAUTHORITY="$XAUTH_FILE"
echo "Xvnc up on display ${DISPLAY} (unix socket only, no TCP)" >&2

# --- Desktop conveniences ------------------------------------------------
# $HOME is the user's real (bind-mounted) home, so these persist across sessions.
mkdir -p "$HOME/Desktop"
if [ ! -e "$HOME/Desktop/fiji.desktop" ]; then
  cp /usr/share/applications/fiji.desktop "$HOME/Desktop/" 2>/dev/null || true
  chmod +x "$HOME/Desktop/fiji.desktop" 2>/dev/null || true
fi

# Link the requested data folder onto the desktop (Fileglancer has already
# bind-mounted it into the container).
if [ -n "$DATA_DIR" ]; then
  link_name="$HOME/Desktop/$(basename "$DATA_DIR")"
  if [ ! -e "$link_name" ] || [ -L "$link_name" ]; then
    ln -sfn "$DATA_DIR" "$link_name"
  fi
fi

# --- XFCE session --------------------------------------------------------
dbus-launch --exit-with-session startxfce4 &
SESSION_PID=$!
echo "XFCE session started (pid ${SESSION_PID})" >&2

# --- websockify / noVNC ----------------------------------------------------
# Serves the noVNC client and tunnels token-authenticated WebSocket
# connections to the VNC unix socket. Runs in the foreground: stopping the
# job (or websockify dying) tears down the whole session via the EXIT trap.
echo "Serving noVNC on port ${FG_SERVICE_PORT}" >&2
websockify \
  --web /opt/novnc \
  --token-plugin UnixDomainSocketDirectory \
  --token-source "$SOCK_DIR" \
  --heartbeat 30 \
  "0.0.0.0:${FG_SERVICE_PORT}"

# Remote Desktop

Runs a full Linux desktop (XFCE) with [Fiji](https://fiji.sc/) preinstalled on a cluster node as a Fileglancer **service**, streamed to your browser with VNC ([TigerVNC](https://tigervnc.org/) + [noVNC](https://novnc.com/)), entirely inside an [Apptainer](https://apptainer.org/) container. The only host requirement is Apptainer.

Your home directory is bind-mounted and writable, so files, XFCE settings, and anything you save persist across sessions. An optional **Data Folder** parameter bind-mounts an additional file-share folder and links it on the desktop.

## One-click access

Fileglancer mints a per-session secret (`$FG_SERVICE_TOKEN`) and publishes the service URL with the token embedded (`?path=websockify%3Ftoken%3D...`) once the server is ready, so clicking **Open Service** drops you straight onto the desktop — no password prompt. The desktop auto-resizes to fit your browser window (`resize=remote`).

## Security model

The session is protected at every hop, including against other users on the same shared compute node:

- **Network**: the only listener is websockify on the Fileglancer-provided port. It serves the noVNC page to anyone, but only tunnels WebSocket connections that present the correct per-job 192-bit token.
- **VNC server**: Xvnc listens **only on a unix domain socket** in a mode-0700 node-local directory (`-rfbport -1` disables TCP entirely). The socket file is named after the token, and websockify's `UnixDomainSocketDirectory` token plugin maps token → socket, so a wrong token matches nothing and local users cannot reach the VNC server at all — the kernel enforces the directory permissions.
- **X display**: the X server requires an xauth cookie (mode 0600), so other local users cannot attach to the display through `/tmp/.X11-unix`.
- The token never appears on a command line (only the socket *directory* does), so it cannot leak via `ps`.

**Caveats**: anyone with the tokenized URL gets the full desktop, including a terminal running as you, while the job runs — treat the URL as a secret and stop the service when finished. Traffic between your browser and the compute node is plain HTTP (unencrypted), the same trade-off as the other apps in this repository.

## How it works

- The image (`ghcr.io/janeliascicomp/fg-interactive-apps/desktop`) is pulled to your per-user Apptainer cache on first launch and reused afterwards. It is large (several GB), so the first launch takes a while — Fileglancer shows the "pulling image" phase during the wait.
- `start-desktop.sh` finds a free X display, starts Xvnc on a private unix socket with an xauth cookie, launches an XFCE session over D-Bus, and serves noVNC/websockify on `$FG_SERVICE_PORT` in the foreground — stopping the job tears everything down.
- Fiji lives at `/opt/fiji` inside the read-only image, with a launcher on the desktop and in the applications menu.

## Fiji notes

- The image install is **read-only**, so the ImageJ updater cannot add plugins or update sites there (automatic update checks are disabled). To use custom plugins/update sites, unpack your own Fiji into your home directory — it persists across sessions and appears in the same desktop.
- Fiji is refreshed to the then-current release whenever a new image version is built; pin behavior by keeping the `container:` tag in `runnables.yaml` at a version you have validated.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Data Folder** | directory | — | Optional folder to show on the desktop. Must be within a mounted file share; bind-mounted into the container automatically. Your home directory is always available. |

## Building and releasing the image

The image is built by the [`build-desktop`](../.github/workflows/build-desktop.yml) GitHub Actions workflow. Pull requests touching `desktop/` get a validation build; pushing a tag like `desktop-v1.0.0` builds and publishes `ghcr.io/janeliascicomp/fg-interactive-apps/desktop:1.0.0` (and `:latest`).

After the first publish, set the GHCR package visibility to **public** (GitHub → org → Packages → `fg-interactive-apps/desktop` → settings) so Apptainer on the cluster can pull it anonymously. Then update the `container:` tag in `runnables.yaml` to match.

## Notes

- **Walltime** defaults to `08:00`. The desktop runs until you stop it or the walltime expires — raise it for longer sessions.
- Resolution defaults to 1920x1080 before the first browser connect; after that the desktop follows your browser window size.

# OpenVSCode

Runs [openvscode-server](https://github.com/gitpod-io/openvscode-server) — upstream VS Code in the browser — on a cluster node as a Fileglancer **service**, entirely inside an [Apptainer](https://apptainer.org/) container. The only host requirement is Apptainer.

## One-click access

openvscode-server authenticates with a **connection token** that can travel in the URL (`?tkn=…`). At launch the app mints a random per-session token, passes it to the server, and writes the full authenticated URL to Fileglancer's service-URL file. So clicking **Open Service** logs you straight into VS Code — no password prompt — while the session is still protected by the secret token.

Because it publishes its own tokenized URL, this app does **not** use Fileglancer's `auto_url`; it writes `SERVICE_URL_PATH` itself in `pre_run`.

## How it works

- The image `docker://gitpod/openvscode-server:latest` is pulled to your per-user Apptainer cache on first launch and reused afterwards.
- Fileglancer picks a free port on the compute node (`$FG_SERVICE_PORT`) and provides the hostname (`$FG_HOSTNAME`); the server binds to the port and the published URL points at it.
- The server runs directly via `apptainer exec`. User data and extensions are redirected to `$HOME/.openvscode-server/{data,extensions}` (your home is bind-mounted and writable), so settings and extensions persist across sessions — the container image itself is read-only.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Folder** | directory | — | Folder to open in VS Code (optional, `--default-folder`). Must be within a mounted file share; bind-mounted into the container automatically. |

## Notes

- **Extensions marketplace:** openvscode-server uses [Open VSX](https://open-vsx.org/) rather than Microsoft's marketplace. Most extensions are available there; a few Microsoft-proprietary ones are not.
- **Security:** anyone with the tokenized URL can access the IDE (which grants full file and shell access as you) while the job runs. Treat the URL as a secret and stop the service when finished.
- **Walltime** defaults to `08:00`. The service runs until you stop it or the walltime expires — raise it for longer sessions.
- To pin a version, change the `container:` tag in `runnables.yaml` (e.g. `docker://gitpod/openvscode-server:1.100.0`).

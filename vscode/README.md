# OpenVSCode

Runs [openvscode-server](https://github.com/gitpod-io/openvscode-server) — upstream VS Code in the browser — on a cluster node as a Fileglancer **service**, entirely inside an [Apptainer](https://apptainer.org/) container. The only host requirement is Apptainer.

## One-click access

openvscode-server authenticates with a **connection token** that can travel in the URL (`?tkn=…`). Fileglancer mints a per-session token (`$FG_SERVICE_TOKEN`), the app passes it to the server with `--connection-token`, and `auto_url` + `service_url_suffix: "/?tkn=${FG_SERVICE_TOKEN}"` publish the full authenticated URL once the server is ready. So clicking **Open Service** logs you straight into VS Code — no password prompt — while the session is still protected by the secret token.

## How it works

- The image `docker://gitpod/openvscode-server:latest` is pulled to your per-user Apptainer cache on first launch and reused afterwards.
- Fileglancer picks a free port on the compute node (`$FG_SERVICE_PORT`), provides the hostname (`$FG_HOSTNAME`), and — once that port is accepting connections — publishes the service URL, so **Open Service** never appears before the server (or the image pull) is ready.
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

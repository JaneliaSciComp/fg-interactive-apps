# VS Code Server

Runs [code-server](https://github.com/coder/code-server) — a full VS Code IDE in the browser — on a cluster node as a Fileglancer **service**. code-server is pulled and executed entirely inside an [Apptainer](https://apptainer.org/) container, so the only host requirement is Apptainer.

## How it works

- The container image `docker://codercom/code-server:latest` is pulled to your per-user Apptainer cache (`~/.fileglancer/apptainer_cache`) on first launch and reused afterwards.
- Fileglancer picks a free port on the compute node and exposes it as `$FG_SERVICE_PORT`; code-server binds to it. With `auto_url: true`, Fileglancer writes the service URL and shows an **Open Service** button — no launcher script or URL-writing code is involved.
- code-server is started with `apptainer exec`, which runs the binary directly and skips the image entrypoint.
- Your home directory is bind-mounted into the container (Apptainer default), so settings and installed extensions persist under `~/.local/share/code-server` across sessions.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Folder** | directory | — | Folder to open in VS Code (optional). Must be within a mounted file share. It is bind-mounted into the container automatically. |
| **Authentication** | enum | `password` | `password`: log in with the per-session password printed to the job's stdout log. `none`: no authentication. |

## Authentication

By default the app uses **password** auth. A random password is generated per launch and printed near the top of the job's **stdout log**:

```
==================================================================
 VS Code Server
 If Authentication is set to 'password', log in with:
   ab12cd34ef56...
==================================================================
```

Open the service, enter that password, and you're in.

> **Security note:** code-server grants full file-system and shell access as your user. Prefer `password` auth. Only use `none` on a trusted, isolated network, and remember the service is reachable at `http://<compute-node>:<port>` for as long as the job runs.

## Notes

- **Walltime** defaults to `08:00`. The service runs until you stop it or the walltime expires — raise it for longer sessions.
- To pin a specific code-server version, change the `container:` tag in `runnables.yaml` (e.g. `docker://codercom/code-server:4.100.2`).

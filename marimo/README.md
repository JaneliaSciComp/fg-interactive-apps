# marimo

Runs a [marimo](https://marimo.io/) reactive Python notebook server on a cluster node as a Fileglancer **service**, inside an [Apptainer](https://apptainer.org/) container. marimo notebooks are stored as plain `.py` files, are reactive (cells re-run automatically), and are reproducible and git-friendly. The only host requirement is Apptainer.

## One-click access

marimo authenticates with an access token that can travel in the URL (`?access_token=…`). At launch the app mints a random per-session token, passes it to marimo, and — once marimo is actually accepting connections — writes the full authenticated URL to Fileglancer's service-URL file. So the **Open Service** link appears only when the server is ready (not while the image is still pulling), and clicking it logs you straight in.

## How it works

- The image `docker://ghcr.io/marimo-team/marimo:latest-sql` (marimo with SQL/DuckDB support) is pulled to your per-user Apptainer cache on first launch and reused afterwards.
- Fileglancer picks a free port on the compute node (`$FG_SERVICE_PORT`) and provides the hostname (`$FG_HOSTNAME`); marimo binds to the port and the published URL points at it.
- marimo is started with `marimo edit --headless` via `apptainer exec`. A background readiness probe waits for the port to accept connections before publishing the URL, so it does not use `auto_url`. Your home directory is bind-mounted, so marimo's config persists across sessions.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Notebook or Folder** | directory | work dir | Notebook file or directory to open (optional). Must be within a mounted file share; bind-mounted into the container automatically. |

## Notes

- **Adding packages:** marimo's [sandbox mode](https://docs.marimo.io/guides/package_management/) can manage per-notebook dependencies with inline script metadata (uv). Alternatively, mount a project directory with its own environment.
- **Walltime** defaults to `08:00`; raise it for longer sessions.
- To pin a version or use a leaner image, change the `container:` tag in `runnables.yaml` (e.g. `docker://ghcr.io/marimo-team/marimo:latest`).

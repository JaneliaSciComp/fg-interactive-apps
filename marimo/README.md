# marimo

Runs a [marimo](https://marimo.io/) reactive Python notebook server on a cluster node as a Fileglancer **service**, inside an [Apptainer](https://apptainer.org/) container. marimo notebooks are stored as plain `.py` files, are reactive (cells re-run automatically), and are reproducible and git-friendly. The only host requirement is Apptainer.

## One-click access

marimo authenticates with an access token that can travel in the URL (`?access_token=…`). Fileglancer mints a per-session token (`$FG_SERVICE_TOKEN`), the app passes it to marimo with `--token-password`, and `auto_url` + `service_url_suffix: "/?access_token=${FG_SERVICE_TOKEN}"` publish the full authenticated URL once marimo is accepting connections. So the **Open Service** link appears only when the server is ready (not while the image is still pulling), and clicking it logs you straight in.

## How it works

- The image `docker://ghcr.io/marimo-team/marimo:latest-sql` (marimo with SQL/DuckDB support) is pulled to your per-user Apptainer cache on first launch and reused afterwards.
- Fileglancer picks a free port on the compute node (`$FG_SERVICE_PORT`), provides the hostname (`$FG_HOSTNAME`), and publishes the service URL only once that port is accepting connections — so **Open Service** never appears before marimo (or the image pull) is ready.
- marimo is started with `marimo edit --headless` via `apptainer exec`. Your home directory is bind-mounted, so marimo's config persists across sessions.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Notebook or Folder** | directory | work dir | Notebook file or directory to open (optional). Must be within a mounted file share; bind-mounted into the container automatically. |

## Notes

- **Adding packages:** marimo's [sandbox mode](https://docs.marimo.io/guides/package_management/) can manage per-notebook dependencies with inline script metadata (uv). Alternatively, mount a project directory with its own environment.
- **Walltime** defaults to `08:00`; raise it for longer sessions.
- To pin a version or use a leaner image, change the `container:` tag in `runnables.yaml` (e.g. `docker://ghcr.io/marimo-team/marimo:latest`).

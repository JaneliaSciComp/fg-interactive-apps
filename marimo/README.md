# marimo

Runs a [marimo](https://marimo.io/) reactive Python notebook server on a cluster node as a Fileglancer **service**, inside an [Apptainer](https://apptainer.org/) container. marimo notebooks are stored as plain `.py` files, are reactive (cells re-run automatically), and are reproducible and git-friendly. The only host requirement is Apptainer.

## How it works

- The image `docker://ghcr.io/marimo-team/marimo:latest-sql` (marimo with SQL/DuckDB support) is pulled to your per-user Apptainer cache on first launch and reused afterwards.
- Fileglancer picks a free port on the compute node, exposes it as `$FG_SERVICE_PORT`, and marimo binds to it. With `auto_url: true`, the service URL is published automatically.
- marimo is started with `marimo edit --headless` via `apptainer exec`. Your home directory is bind-mounted, so marimo's config persists across sessions.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Notebook or Folder** | directory | work dir | Notebook file or directory to open (optional). Must be within a mounted file share; bind-mounted into the container automatically. |

## Authentication

A random access password is generated per launch and printed near the top of the job's **stdout log**:

```
====================================================================
 marimo access password (paste when prompted in the browser):
   ab12cd34...
====================================================================
```

Open the service and paste that password to log in.

## Notes

- **Adding packages:** marimo's [sandbox mode](https://docs.marimo.io/guides/package_management/) can manage per-notebook dependencies with inline script metadata (uv). Alternatively, mount a project directory with its own environment.
- **Walltime** defaults to `08:00`; raise it for longer sessions.
- To pin a version or use a leaner image, change the `container:` tag in `runnables.yaml` (e.g. `docker://ghcr.io/marimo-team/marimo:latest`).

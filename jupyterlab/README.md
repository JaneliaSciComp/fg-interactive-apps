# JupyterLab

Runs a [JupyterLab](https://jupyterlab.readthedocs.io/) notebook server on a cluster node as a Fileglancer **service**, entirely inside an [Apptainer](https://apptainer.org/) container. The only host requirement is Apptainer.

## One-click access

Fileglancer mints a per-session token (`$FG_SERVICE_TOKEN`), the app enforces it on the server with `--IdentityProvider.token`, and `auto_url` + `service_url_suffix: "/lab?token=${FG_SERVICE_TOKEN}"` publish the token URL once JupyterLab is ready. So clicking **Open Service** opens JupyterLab logged in — no token to copy from the log.

## How it works

- The image `docker://quay.io/jupyter/scipy-notebook:latest` (the [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/) SciPy image — NumPy, SciPy, pandas, matplotlib, etc.) is pulled to your per-user Apptainer cache on first launch and reused afterwards.
- Fileglancer picks a free port (`$FG_SERVICE_PORT`), JupyterLab binds to it, and the service URL is published only once that port is accepting connections — so **Open Service** never appears before the server (or the image pull) is ready.
- JupyterLab is started with `apptainer exec`, which runs it directly (not through the image's `start-notebook` wrapper). Your home directory is bind-mounted, so kernels, settings, and `pip install --user` packages persist across sessions.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Working Directory** | directory | home | Directory JupyterLab opens in (optional). Must be within a mounted file share; bind-mounted into the container automatically. |

## Notes

- **Adding packages:** `pip install --user <pkg>` or `conda install` from a notebook terminal persists under your home directory. For reproducible environments, mount a project directory and use a virtualenv/conda env there.
- **Walltime** defaults to `08:00`; raise it for longer sessions.
- To pin a version, change the `container:` tag in `runnables.yaml` (e.g. `docker://quay.io/jupyter/scipy-notebook:2025-12-31`).

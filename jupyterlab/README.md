# JupyterLab

Runs a [JupyterLab](https://jupyterlab.readthedocs.io/) notebook server on a cluster node as a Fileglancer **service**, entirely inside an [Apptainer](https://apptainer.org/) container. The only host requirement is Apptainer.

## How it works

- The image `docker://quay.io/jupyter/scipy-notebook:latest` (the [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/) SciPy image — NumPy, SciPy, pandas, matplotlib, etc.) is pulled to your per-user Apptainer cache on first launch and reused afterwards.
- Fileglancer picks a free port on the compute node, exposes it as `$FG_SERVICE_PORT`, and JupyterLab binds to it. With `auto_url: true`, the service URL is published automatically.
- JupyterLab is started with `apptainer exec`, which runs it directly (not through the image's `start-notebook` wrapper). Your home directory is bind-mounted, so kernels, settings, and `pip install --user` packages persist across sessions.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Working Directory** | directory | home | Directory JupyterLab opens in (optional). Must be within a mounted file share; bind-mounted into the container automatically. |

## Authentication

A random access token is generated per launch and printed near the top of the job's **stdout log**:

```
====================================================================
 JupyterLab access token (paste when prompted in the browser):
   a1b2c3d4...
====================================================================
```

Open the service and paste that token to log in.

## Notes

- **Adding packages:** `pip install --user <pkg>` or `conda install` from a notebook terminal persists under your home directory. For reproducible environments, mount a project directory and use a virtualenv/conda env there.
- **Walltime** defaults to `08:00`; raise it for longer sessions.
- To pin a version, change the `container:` tag in `runnables.yaml` (e.g. `docker://quay.io/jupyter/scipy-notebook:2025-12-31`).

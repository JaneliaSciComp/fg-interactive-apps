# Fileglancer Interactive Apps

A collection of interactive [Fileglancer](https://github.com/JaneliaSciComp/fileglancer) apps — long-running, browser-based tools (IDEs, notebooks, viewers) that run as services on the cluster.

Each app lives in its own subdirectory with its own `runnables.yaml` manifest. Fileglancer walks the repository, registers a separate app for every `runnables.yaml` it finds, and runs each from the subdirectory that contains its manifest.

## Apps

| App | Directory | Description |
|-----|-----------|-------------|
| **VS Code Server** | [`vscode/`](vscode/) | Browser-based VS Code IDE ([code-server](https://github.com/coder/code-server)) running in an Apptainer container. |
| **JupyterLab** | [`jupyterlab/`](jupyterlab/) | JupyterLab notebook server (SciPy stack) running in an Apptainer container. |

_More to come (e.g. other notebook servers and viewers)._

## Using these apps in Fileglancer

1. Open the **Apps** page in Fileglancer.
2. Add this repository's URL.
3. Each subdirectory's app appears separately. Launch one, and Fileglancer opens the running service in your browser.

See the [Authoring Apps](https://fileglancer-docs.janelia.org/authoring/) documentation for how the manifests work.

## Adding a new app

1. Create a new subdirectory (e.g. `jupyter/`).
2. Add a `runnables.yaml` manifest describing the service (see an existing app for the pattern).
3. For interactive services, prefer the seamless service contract:
   - `type: service` with `auto_url: true`
   - bind to Fileglancer's `$FG_SERVICE_PORT` in the command
   - run inside a container (`container:`) with `apptainer` in `requirements`

   Fileglancer then picks a free port on the compute node, substitutes it into the command, and publishes the service URL — no launcher script needed.
4. Add a row to the table above and a short `README.md` in the subdirectory.

## License

BSD 3-Clause. See [LICENSE](LICENSE).

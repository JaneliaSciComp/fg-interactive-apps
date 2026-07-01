# TensorBoard

Runs [TensorBoard](https://www.tensorflow.org/tensorboard) on a cluster node as a Fileglancer **service**, inside an [Apptainer](https://apptainer.org/) container, to visualize the logs of a training run (scalars, images, histograms, embeddings, etc.). The only host requirement is Apptainer.

## How it works

- The image `docker://tensorflow/tensorflow:latest` (which bundles the `tensorboard` CLI) is pulled to your per-user Apptainer cache on first launch and reused afterwards.
- Fileglancer picks a free port on the compute node, exposes it as `$FG_SERVICE_PORT`, and TensorBoard binds to it. With `auto_url: true`, the service URL is published automatically.
- You point it at a **Log Directory**; that directory is bind-mounted into the container automatically.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Log Directory** | directory | *(required)* | Directory containing TensorBoard event files. Must be within a mounted file share. |

## Authentication

TensorBoard has no built-in authentication and is read-only. It is reachable at `http://<compute-node>:<port>` for as long as the job runs — only launch it on a trusted network, and stop it when you're done.

## Notes

- Works with logs from TensorFlow, PyTorch (`torch.utils.tensorboard`), Keras, and anything else that writes TensorBoard event files.
- **Walltime** defaults to `08:00`; raise it for longer monitoring sessions.
- To pin a version, change the `container:` tag in `runnables.yaml` (e.g. `docker://tensorflow/tensorflow:2.19.0`).

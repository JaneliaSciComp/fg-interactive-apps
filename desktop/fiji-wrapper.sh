#!/bin/bash
# Launch Fiji from the read-only image install at /opt/fiji.
#
# The image is immutable under Apptainer, so the ImageJ updater cannot modify
# this install; automatic update checks are disabled below. Users who need
# extra plugins or update sites can unpack their own Fiji into $HOME (which
# persists across sessions) and run it from there instead.
for exe in /opt/fiji/fiji-linux-x64 /opt/fiji/ImageJ-linux64 /opt/fiji/fiji; do
  if [ -x "$exe" ]; then
    exec "$exe" -Dimagej.updater.disableAutocheck=true "$@"
  fi
done
echo "ERROR: no Fiji launcher found in /opt/fiji" >&2
exit 1

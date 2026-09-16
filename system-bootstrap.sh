#!/bin/bash
set -euo pipefail

# Ensure the agent user owns the entire .vscode-server bind-mount tree so that
# VS Code Remote-SSH can read and write freely (installing its server binary,
# writing logs, caching extensions, etc.).
chown -R agent:agent /home/agent/.vscode-server

# Raise inotify limits so C# Dev Kit/Roslyn (NuGet cache, SDK dirs, bin/obj) don't
# exhaust watches; not a namespaced sysctl, so it must be set here (privileged)
# rather than via compose's `sysctls:` key.
sysctl -w fs.inotify.max_user_watches=524288
sysctl -w fs.inotify.max_user_instances=8192

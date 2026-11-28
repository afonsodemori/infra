## Persistent volumes (optional)

The image works without any volumes. Mounting them only makes some data
survive container rebuilds. Without them, that data still persists across
container stop/start but is lost whenever the container is recreated.

| Mount point            | Purpose                                                                  |
| ---------------------- | ------------------------------------------------------------------------ |
| `/commandhistory`      | Bash history (`HISTFILE`), written after every command                   |
| `/home/vscode/.claude` | Claude Code config and auth (`CLAUDE_CONFIG_DIR`), so you stay logged in |

### Per-project volumes

Add the volumes to the project's `.devcontainer/compose.yml`:

```yaml
services:
  app:
    image: ghcr.io/afonsodemori/devcontainers/debian:<tag>
    volumes:
      - ..:/workspace
      - shell-history:/commandhistory
      - claude-config:/home/vscode/.claude

volumes:
  shell-history:
  claude-config:
```

Compose prefixes volume names with the project name (e.g. `myproject_shell-history`),
so each project gets its own history and Claude config.

### Shared volumes across projects

To share the same data across all projects, give the volumes a fixed name.
Compose creates them on first use:

```yaml
volumes:
  shell-history:
    name: devcontainer-shell-history
  claude-config:
    name: devcontainer-claude-config
```

You can mix both: e.g. share `claude-config` (log in once) but keep
`shell-history` per project.

### Troubleshooting

A new volume inherits the ownership of the image's directory (`vscode`).
A volume created before the image had these directories may be owned by root,
which silently breaks history or Claude config. Check with
`ls -ld /commandhistory /home/vscode/.claude`. If they're root-owned, remove
the volume (`docker volume rm <name>`) and rebuild.

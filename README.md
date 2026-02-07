# Copilot Code Server Container

A containerized development environment for **agentic programming** with GitHub Copilot, designed for secure sandboxing and quick, replicatable setups.

## What is This?

This project provides a fully containerized [code-server](https://github.com/coder/code-server) environment (VS Code in the browser) pre-configured for GitHub Copilot agentic workflows. It's designed to give AI agents a safe, isolated workspace where they can code, build, test, and manage projects without affecting your host system.

## Why Use This?

### 🔒 Sandboxing & Security
- **Isolated environment**: AI agents run in a locked-down container with a dedicated user account
- **No host contamination**: All agent operations are contained within Docker volumes
- **Safe experimentation**: Let agents try things without risking your main development machine
- **Credential isolation**: SSH keys and credentials are container-specific

### 🚀 Quick & Replicatable
- **Instant setup**: One command gets you a fully configured development environment
- **Consistent environment**: Same setup across all machines and team members
- **Version controlled configuration**: All settings in JSON files you can track and share
- **Easy reset**: Delete the container and volume to start fresh anytime

### 🛠️ Pre-configured Tooling
- **code-server**: Browser-based VS Code experience
- **GitHub Copilot**: Full Copilot support with custom MCP (Model Context Protocol) servers
- **Multi-language support**: Node.js, Python, .NET SDK 10.0 pre-installed
- **Development tools**: git, lazygit, zsh with oh-my-zsh, and more
- **Custom MCPs**: Extensible MCP configuration for enhanced agent capabilities

## Prerequisites

- Docker and Docker Compose installed on your system
- A GitHub Copilot subscription

## Quick Start

### 1. Configure Environment Variables

Create a `.env` file in the project root:

```bash
GIT_USERNAME=Your Name
GIT_EMAIL=your.email@example.com
```

These are **required** for git operations within the container.

### 2. Run the Container

```bash
docker compose up -d --build
```

This command will:
- Build the Docker image
- Start the code-server container in detached mode
- Auto-generate SSH keys on first run
- Set up the agent environment

### 3. Get Your SSH Public Key

On first run, the container automatically generates an SSH key pair for git operations. To view your public key:

```bash
docker logs copilot-code-server
```

Look for the section that displays:
```
📋 Your public key (add this to Azure DevOps):
================================================
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ...
================================================
```

**Important**: Add this public key to your git hosting service (GitHub, Azure DevOps, GitLab, etc.) to enable git operations over SSH.

### 4. Access code-server

Open your browser and navigate to:
```
http://localhost:8080
```

You'll have a full VS Code environment running in your browser, ready for agentic development!

## Configuration Files

This project uses several mounted JSON configuration files that you can customize:

### `mcp-config.json` - MCP Server Configuration

Configures Model Context Protocol (MCP) servers that extend GitHub Copilot's capabilities. The default configuration includes:

```json
{
  "mcpServers": {
    "cli-mcp-mapper": {
      "type": "local",
      "command": "cli-mcp-mapper",
      "args": [],
      "tools": ["*"]
    }
  }
}
```

This file is mounted at `/home/agent/.copilot/mcp-config.json` inside the container.

**To add custom MCPs**:
1. Install the MCP package in the Dockerfile (add npm/pip install commands)
2. Add the MCP server configuration to `mcp-config.json`
3. Rebuild the container with `docker compose up -d --build`

### `vscode-settings.json` - VS Code Settings

Controls the code-server (VS Code) editor settings. Mounted at `/home/agent/.local/share/code-server/User/settings.json`.

Default settings include:
- GitHub Copilot enabled
- Inline suggestions enabled
- zsh as default terminal
- Abyss color theme
- Chat features configured for agent use

Customize this file to adjust your editor preferences.

### `commands.json` - CLI MCP Mapper Commands

Defines custom commands available to the agent through the [cli-mcp-mapper](https://github.com/SteffenBlake/cli-mcp-mapper) MCP server. This file is mounted at `/home/agent/.config/cli-mcp-mapper/commands.json`.

The default configuration includes commands for:
- .NET operations (build, restore, test, format, benchmarks)
- Git operations (status, diff, commit, branch)
- File system operations (ls, mv, mkdir, rm, grep, sed, wc)

**To configure custom commands**, see the [cli-mcp-mapper documentation](https://github.com/SteffenBlake/cli-mcp-mapper) for detailed information on command structure and parameters.

## Architecture

### Container Structure

- **Base Image**: Debian 13
- **User**: Locked-down `agent` user with minimal permissions
- **Workspace**: `/home/agent/workspace` (your working directory)
- **Persistent Storage**: The entire `/home/agent` directory is persisted in a Docker volume, preserving:
  - Configuration files
  - VS Code extensions
  - Workspace files
  - SSH keys
  - Git credentials

### Security Features

- **Non-root user**: All operations run as the `agent` user
- **Isolated credentials**: GPG and pass configured for secure credential storage
- **Container-specific SSH keys**: Generated per container, not shared with host
- **Home directory permissions**: Locked down to 700 (user-only access)

### Installed Tools

- **Languages**: Node.js, Python 3, .NET SDK 10.0
- **Version Control**: git, lazygit
- **Security**: GPG, pass (password manager)
- **Shell**: zsh with oh-my-zsh (jonathan theme)
- **Editor**: code-server (VS Code in browser)
- **AI Tools**: GitHub Copilot CLI, cli-mcp-mapper

## Common Tasks

### View Container Logs
```bash
docker logs copilot-code-server
```

### Restart the Container
```bash
docker compose restart
```

### Stop the Container
```bash
docker compose down
```

### Rebuild After Configuration Changes
```bash
docker compose up -d --build
```

### Access Container Shell
```bash
docker exec -it copilot-code-server zsh
```

### Reset Everything (Fresh Start)
```bash
docker compose down -v  # Warning: Deletes all container data!
docker compose up -d --build
```

## Persistent Data

All data in `/home/agent` is stored in a Docker named volume (`agent-home`), which persists between container restarts. This includes:

- Your workspace files
- Installed VS Code extensions
- Shell history and configuration
- SSH keys (generated on first run)
- Git credentials

To completely reset the environment, remove the volume with `docker compose down -v`.

## Port Configuration

- **8080**: code-server web interface (mapped to host port 8080)

To use a different port, modify the `ports` section in `docker-compose.yml`.

## Customization

### Installing Additional Tools

Edit the `Dockerfile` to add more tools:

```dockerfile
RUN apt-get update && apt-get install -y \
    your-package-here \
    && rm -rf /var/lib/apt/lists/*
```

### Changing the Shell Theme

Modify the `ZSH_THEME` environment variable in `docker-compose.yml`:

```yaml
environment:
  - ZSH_THEME=robbyrussell  # or any oh-my-zsh theme
```

### Adding VS Code Extensions

Extensions can be installed through the code-server UI and will persist in the `agent-home` volume.

## Troubleshooting

### Container Fails to Start

Check logs for missing environment variables:
```bash
docker logs copilot-code-server
```

Ensure your `.env` file has `GIT_USERNAME` and `GIT_EMAIL` set.

### Can't Push to Git Repositories

1. Ensure you've added the container's SSH public key to your git host
2. Check the public key with: `docker logs copilot-code-server`
3. Verify git configuration: `docker exec copilot-code-server git config --list`

### Port 8080 Already in Use

Change the host port in `docker-compose.yml`:
```yaml
ports:
  - "8081:8080"  # Use port 8081 instead
```

## License

See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## Related Projects

- [code-server](https://github.com/coder/code-server) - VS Code in the browser
- [cli-mcp-mapper](https://github.com/SteffenBlake/cli-mcp-mapper) - CLI command MCP server
- [GitHub Copilot](https://github.com/features/copilot) - AI pair programmer
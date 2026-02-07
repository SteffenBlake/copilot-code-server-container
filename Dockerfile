FROM debian:13

# Install base dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    openssh-client \
    zsh \
    lazygit \
    pass \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# Create locked-down agent user
# ============================================
RUN useradd -m -s /bin/zsh agent && \
    # Create workspace in agent's home directory
    mkdir -p /home/agent/workspace && \
    # Set ownership
    chown -R agent:agent /home/agent && \
    # Lock down home directory permissions
    chmod 700 /home/agent

# ============================================
# Install Node.js + npm
# ============================================
RUN apt-get update && \
    apt-get install -y nodejs npm && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# Install Python 3
# ============================================
RUN apt-get update && \
    apt-get install -y python3 && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# Install .NET SDK 10.0
# ============================================
RUN wget https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-10.0 && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# Install code-server
# ============================================
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ============================================
# Install copilot CLI
# ============================================
RUN curl -fsSL https://gh.io/copilot-install | bash

# ============================================
# Install cli-mcp-mapper
# ============================================
RUN npm i -g cli-mcp-mapper

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to agent user
USER agent

# Set user environment variables
ENV SHELL=/usr/bin/zsh

# ============================================
# Install oh-my-zsh for agent user
# ============================================
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# ============================================
# Initialize GPG and pass for credential storage
# ============================================
RUN gpg --batch --gen-key <<EOF && \
    pass init "agent@localhost"
%no-protection
Key-Type: RSA
Key-Length: 2048
Name-Real: Code Server Agent
Name-Email: agent@localhost
Expire-Date: 0
EOF

# Create config directories
RUN mkdir -p /home/agent/.local/share/code-server/User \
    && mkdir -p /home/agent/.config/Code/User/globalStorage/github.copilot-chat

# Set working directory to agent's workspace
WORKDIR /home/agent/workspace

EXPOSE 8080

# Healthcheck - verify code-server is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

# Setup always runs
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command (can be overridden)
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none", "/home/agent/workspace"]

#!/bin/bash
set -e

# ============================================
# Validate required Git configuration
# ============================================
MISSING_CONFIG=0

if [ -z "$GIT_USERNAME" ]; then
    echo "❌ ERROR: GIT_USERNAME is not set"
    MISSING_CONFIG=1
fi

if [ -z "$GIT_EMAIL" ]; then
    echo "❌ ERROR: GIT_EMAIL is not set"
    MISSING_CONFIG=1
fi

if [ $MISSING_CONFIG -eq 1 ]; then
    echo ""
    echo "💡 Please set all required Git environment variables in your .env file:"
    echo "   - GIT_USERNAME"
    echo "   - GIT_EMAIL"
    echo ""
    echo "Example .env file:"
    echo "GIT_USERNAME=Your Name"
    echo "GIT_EMAIL=your.email@example.com"
    exit 1
fi

echo "✅ Git configuration validated"

# Set both author and committer to the same values
export GIT_AUTHOR_NAME="$GIT_USERNAME"
export GIT_AUTHOR_EMAIL="$GIT_EMAIL"
export GIT_COMMITTER_NAME="$GIT_USERNAME"
export GIT_COMMITTER_EMAIL="$GIT_EMAIL"

# ============================================
# SSH key auto-generation
# ============================================
SSH_DIR="/home/agent/.ssh"
SSH_KEY="$SSH_DIR/id_rsa"

if [ ! -f "$SSH_KEY" ]; then
    echo "🔑 SSH keys not found. Generating new SSH key pair..."
    mkdir -p "$SSH_DIR"
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N "" -C "${GIT_EMAIL}"
    chmod 700 "$SSH_DIR"
    chmod 600 "$SSH_KEY"
    chmod 644 "$SSH_KEY.pub"
    echo "✅ SSH key pair generated at $SSH_KEY"
    echo ""
    echo "📋 Your public key (add this to Azure DevOps):"
    echo "================================================"
    cat "$SSH_KEY.pub"
    echo "================================================"
    echo ""
else
    echo "✅ SSH keys already exist at $SSH_KEY"
fi

# ============================================
# Configure git
# ============================================
git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"
echo "✅ Git configured: $GIT_USERNAME <$GIT_EMAIL>"

# Execute whatever command was passed (CMD or override)
exec "$@"

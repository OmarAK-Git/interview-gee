#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/fish
export USER=fish
export PATH="$HOME/.local/bin:$HOME/.hermes/bin:$PATH"
cd "$HOME"
echo "install_user=$USER install_home=$HOME"
# Detach from TTY so the installer cannot prompt for sudo (ripgrep/ffmpeg are optional).
setsid bash -c 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-browser --skip-computer-use --skip-setup --non-interactive' < /dev/null
echo "INSTALL_DONE"
export PATH="$HOME/.local/bin:$PATH"
command -v hermes
hermes --version

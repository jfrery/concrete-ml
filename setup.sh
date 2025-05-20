#!/bin/bash

# Exit on error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install OS dependencies
install_os_deps() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo "Updating package list and installing Linux dependencies..."
        sudo apt-get update
        sudo apt-get install -y \
            build-essential \
            git \
            git-lfs \
            python3-dev \
            python3-pip \
            python3-venv
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo "Installing macOS dependencies via Homebrew..."
        if ! command_exists brew; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        # Ensure Homebrew is up to date
        brew update
        # Install Python versions 3.9 through 3.12, and other tools
        # Python 3.8 is removed as it's no longer supported.
        brew install \
            git \
            git-lfs \
            python@3.9 \
            python@3.10 \
            python@3.11 \
            python@3.12
    else
        echo "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

# Function to install Poetry
install_poetry() {
    if ! command_exists poetry; then
        echo "Installing Poetry..."
        curl -sSL https://install.python-poetry.org | python3 -
        # Add poetry to PATH for the current session if it's installed in the default location
        # This might be needed if the shell hasn't reloaded its profile yet.
        # Check common Poetry installation paths.
        if [ -f "$HOME/.local/bin/poetry" ]; then
             export PATH="$HOME/.local/bin:$PATH"
        elif [ -f "$HOME/.poetry/bin/poetry" ]; then
             export PATH="$HOME/.poetry/bin:$PATH"
        fi
    else
        echo "Poetry is already installed."
    fi
}

# Function to setup Python environment
setup_python_env() {
    # Install poetry if not already installed
    install_poetry

    # Ensure poetry command is available after installation
    if ! command_exists poetry; then
        echo "Poetry command not found after installation attempt. Please check your PATH."
        echo "Common paths are ~/.local/bin or ~/.poetry/bin."
        echo "You might need to source your shell profile (e.g., source ~/.bashrc) or open a new terminal."
        exit 1
    fi
    
    echo "Configuring Poetry to create virtualenvs in the project directory..."
    poetry config virtualenvs.in-project true

    echo "Installing project dependencies using Poetry..."
    # Install dependencies including development dependencies
    poetry install --with dev

    echo "Upgrading pip and wheel in the virtual environment..."
    # Upgrade pip and wheel. Setuptools upgrade is omitted to avoid conflicts
    # with specific versions potentially pinned by the project (e.g., setuptools==75.3.0).
    poetry run python -m pip install -U pip wheel
}

# Main setup process
echo "Starting development environment setup for Concrete ML..."

# Install OS dependencies
echo "Step 1: Installing OS dependencies..."
install_os_deps

# Setup git LFS
echo "Step 2: Setting up git LFS..."
git lfs install # Idempotent, ensures LFS is configured for the user

# Pull LFS files
echo "Step 3: Pulling LFS files..."
# Ensure LFS files are pulled for tests and pandas client/server files
# Using a more targeted include pattern if necessary, or ensure .gitattributes is correct.
# The original --exclude "" is unusual but kept if it serves a specific purpose.
git lfs pull --include "tests/data/**,src/concrete/ml/pandas/_client_server_files/**" --exclude ""

# Setup Python environment
echo "Step 4: Setting up Python environment with Poetry..."
setup_python_env

# Activate the virtual environment message
echo "Step 5: Activating virtual environment..."
echo "To activate the virtual environment, run: source .venv/bin/activate"

echo ""
echo "Setup completed successfully!"
echo "After activating the virtual environment (.venv/bin/activate), you can run project commands."
echo "For example:"
echo "  - Regular tests: pytest"
echo "  - GPU tests: pytest --gpu"
echo "  - macOS tests: pytest --macos (or make pytest_macOS_for_GitHub)"
#!/bin/bash

# NBSeer System Dependencies Installer
# Install system dependencies and Python environment using conda

set -e

# Define color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 NBSeer System Dependencies Installation${NC}"
echo -e "${BLUE}Installing system dependencies and Python environment with conda${NC}"
echo ""

# Detect operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    elif [ -f /etc/redhat-release ]; then
        OS="Red Hat Enterprise Linux"
        VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9]\+\).*/\1/')
    else
        OS=$(uname -s)
        VERSION=$(uname -r)
    fi
    
    echo -e "${YELLOW}Detected OS: ${OS} ${VERSION}${NC}"
}

# Install conda dependencies
install_conda_deps() {
    echo -e "${YELLOW}📦 Installing dependencies with conda...${NC}"
    
    # Install basic dependencies through conda
    echo "Installing basic development tools and libraries..."
    conda install -y -c conda-forge -c bioconda \
        wget \
        curl \
        tar \
        bzip2 \
        gcc_linux-64 \
        gxx_linux-64 \
        make \
        cmake \
        perl \
        python=3.11 \
        openjdk \
        zlib \
        bzip2 \
        xz \
        ncurses \
        openssl \
        libffi \
        gsl \
        sqlite \
        git
    
    echo -e "${GREEN}✓ Conda dependencies installed${NC}"
}

# Check and install conda if not available
install_conda() {
    echo -e "${YELLOW}🐍 Checking conda installation...${NC}"
    
    if command -v conda &> /dev/null; then
        echo "Conda is already installed"
        conda --version
        return 0
    fi
    
    echo "Installing Miniconda..."
    
    # Detect architecture
    if [[ $(uname -m) == "x86_64" ]]; then
        ARCH="x86_64"
    elif [[ $(uname -m) == "aarch64" ]] || [[ $(uname -m) == "arm64" ]]; then
        ARCH="aarch64"
    else
        echo -e "${RED}❌ Unsupported architecture: $(uname -m)${NC}"
        exit 1
    fi
    
    # Download and install Miniconda
    CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${ARCH}.sh"
    wget -O miniconda.sh "$CONDA_URL"
    bash miniconda.sh -b -p "$HOME/miniconda3"
    rm miniconda.sh
    
    # Initialize conda
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
    conda init bash
    
    echo -e "${GREEN}✓ Conda installed successfully${NC}"
    echo -e "${YELLOW}Please restart your shell or run: source ~/.bashrc${NC}"
}

# macOS conda installation
install_macos_conda() {
    echo -e "${YELLOW}📦 Installing macOS dependencies with conda...${NC}"
    
    # Check and install conda for macOS
    if ! command -v conda &> /dev/null; then
        echo "Installing Miniconda for macOS..."
        
        # Detect architecture
        if [[ $(uname -m) == "x86_64" ]]; then
            CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
        elif [[ $(uname -m) == "arm64" ]]; then
            CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
        else
            echo -e "${RED}❌ Unsupported architecture: $(uname -m)${NC}"
            exit 1
        fi
        
        curl -o miniconda.sh "$CONDA_URL"
        bash miniconda.sh -b -p "$HOME/miniconda3"
        rm miniconda.sh
        
        # Initialize conda
        source "$HOME/miniconda3/etc/profile.d/conda.sh"
        conda init bash zsh
    fi
    
    # Install dependencies with conda
    install_conda_deps
    
    echo -e "${GREEN}✓ macOS dependencies installed${NC}"
}

# Verify installation
verify_installation() {
    echo -e "${YELLOW}✅ Verifying system dependencies installation...${NC}"
    
    local missing=()
    
    # Check conda environment
    if command -v conda &> /dev/null; then
        echo -e "${GREEN}  ✓ conda${NC}"
        conda_version=$(conda --version)
        echo -e "${GREEN}    ${conda_version}${NC}"
    else
        missing+=("conda")
    fi
    
    # Check basic commands in conda environment
    for cmd in wget curl tar make gcc g++ perl python java; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        else
            echo -e "${GREEN}  ✓ $cmd${NC}"
        fi
    done
    
    # Check if conda environment nbseer exists
    if conda env list | grep -q "nbseer"; then
        echo -e "${GREEN}  ✓ Conda environment (nbseer)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Conda environment not found${NC}"
    fi
    
    # Check Java version
    if command -v java &> /dev/null; then
        java_version=$(java -version 2>&1 | head -n1)
        echo -e "${GREEN}  ✓ Java: ${java_version}${NC}"
    fi
    
    # Check conda packages
    if command -v conda &> /dev/null; then
        echo -e "${GREEN}  ✓ Conda packages installed${NC}"
        conda list | grep -E '(gcc|zlib|bzip2|openssl)' | head -3
    fi
    
    if [ ${#missing[@]} -eq 0 ]; then
        echo -e "${GREEN}🎉 All system dependencies verified successfully!${NC}"
        return 0
    else
        echo -e "${RED}❌ Missing dependencies: ${missing[*]}${NC}"
        return 1
    fi
}

# Setup Python environment with conda
setup_conda_python_env() {
    echo -e "${YELLOW}🐍 Setting up conda Python environment...${NC}"
    
    # Ensure conda environment is activated
    if command -v conda &> /dev/null; then
        source "$(conda info --base)/etc/profile.d/conda.sh"
        conda activate base
    fi
    
    # Create NBSeer conda environment from environment.yml
    if conda env list | grep -q "nbseer"; then
        echo "NBSeer conda environment already exists"
        echo "Updating environment from environment.yml..."
        conda env update -n nbseer -f environment.yml
        conda activate nbseer
    else
        echo "Creating NBSeer conda environment from environment.yml..."
        if [ -f "environment.yml" ]; then
            conda env create -f environment.yml
        else
            echo "environment.yml not found, creating basic environment..."
            conda create -y -n nbseer python=3.11
        fi
        conda activate nbseer
        echo "NBSeer conda environment created"
    fi
    
    # Install project dependencies if pyproject.toml exists
    if [ -f "pyproject.toml" ]; then
        echo "Installing project in development mode..."
        pip install -e .
    fi
    
    echo -e "${GREEN}✓ Python environment setup with conda completed${NC}"
}

# Main function
main() {
    detect_os
    
    case "$OS" in
        "Ubuntu"*|"Debian"*|"CentOS"*|"Red Hat"*|"Fedora"*|*)
            # First ensure conda is installed
            install_conda
            
            # Initialize conda environment
            if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
                source "$HOME/miniconda3/etc/profile.d/conda.sh"
                conda activate base
            fi
            
            # Install dependencies with conda
            install_conda_deps
            ;;
        "Darwin")
            install_macos_conda
            ;;
    esac
    
    # Setup Python environment with conda
    setup_conda_python_env
    
    # Verify installation
    if verify_installation; then
        echo ""
        echo -e "${GREEN}🎉 System dependencies installation completed!${NC}"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "1. Restart shell or run: source ~/.bashrc"
        echo "2. Activate NBSeer environment: conda activate nbseer"
        echo "3. Install bioinformatics tools: ./setup_tools.sh"
        echo "4. Load environment configuration: source setup_env.sh"
        echo "5. Verify tools installation: ./verify_tools.sh"
        echo ""
        echo -e "${YELLOW}Note: If this is your first conda installation, please restart your terminal${NC}"
    else
        echo ""
        echo -e "${RED}❌ System dependencies installation incomplete, please check error messages${NC}"
        exit 1
    fi
}

# Check if running with root privileges (not needed for conda)
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Running as root - this is not recommended for conda installation${NC}"
    echo -e "${YELLOW}Please run as a regular user${NC}"
else
    echo -e "${GREEN}✓ Running as regular user - good for conda installation${NC}"
fi

# Execute main function
main "$@"
#!/usr/bin/env bash
# poetryenv installer
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

printf "${BLUE}Installing poetryenv...${NC}\n"
printf "\n"

# Determine install directory
INSTALL_PREFIX="${POETRYENV_INSTALL_PREFIX:-$HOME/.local}"
INSTALL_BIN="$INSTALL_PREFIX/bin"
INSTALL_LIBEXEC="$INSTALL_PREFIX/libexec"
INSTALL_COMPLETIONS="$INSTALL_PREFIX/share/poetryenv/completions"

# Check for required commands
if ! command -v python3 &> /dev/null; then
    printf "${RED}Error: python3 is required but not installed${NC}\n"
    printf "Please install Python 3 first.\n"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    printf "${RED}Error: curl is required but not installed${NC}\n"
    printf "Please install curl first.\n"
    exit 1
fi

# Create directories
printf "${BLUE}→ Creating installation directories${NC}\n"
mkdir -p "$INSTALL_BIN"
mkdir -p "$INSTALL_LIBEXEC"
mkdir -p "$INSTALL_COMPLETIONS"

# Install from local files or remote
if [[ -d "libexec" ]] && [[ -d "bin" ]]; then
    # Local installation
    printf "${BLUE}→ Installing from local files${NC}\n"

    # Copy bin files
    cp bin/poetryenv "$INSTALL_BIN/poetryenv"
    chmod +x "$INSTALL_BIN/poetryenv"

    # Copy libexec files
    cp libexec/* "$INSTALL_LIBEXEC/"
    chmod +x "$INSTALL_LIBEXEC"/*

    # Copy completions
    if [[ -d "completions" ]]; then
        cp completions/* "$INSTALL_COMPLETIONS/"
    fi
else
    # Remote installation
    printf "${BLUE}→ Downloading poetryenv from GitHub${NC}\n"

    local base_url="https://raw.githubusercontent.com/cdddg/poetryenv/main"
    local manifest_url="${base_url}/MANIFEST"
    local tmp_manifest="/tmp/poetryenv.manifest.$$"

    printf "Downloading manifest from %s\n" "$manifest_url"
    if ! curl -fsSL "$manifest_url" -o "$tmp_manifest"; then
        printf "${RED}Error: Failed to download manifest file.${NC}\n"
        exit 1
    fi

    while IFS= read -r filepath; do
        # Skip empty lines
        [[ -z "$filepath" ]] && continue

        local dest_dir=""
        case "$filepath" in
            bin/*) dest_dir="$INSTALL_BIN" ;;
            libexec/*) dest_dir="$INSTALL_LIBEXEC" ;;
            completions/*) dest_dir="$INSTALL_COMPLETIONS" ;;
            *)
                printf "${YELLOW}Warning: Unknown file type in manifest: %s${NC}\n" "$filepath"
                continue
                ;;
        esac

        local filename=$(basename "$filepath")
        local dest_path="$dest_dir/$filename"
        local file_url="$base_url/$filepath"

        printf "Downloading %s to %s\n" "$filepath" "$dest_path"
        if ! curl -fsSL "$file_url" -o "$dest_path"; then
            printf "${RED}Error: Failed to download %s${NC}\n" "$filepath"
            rm -f "$tmp_manifest"
            exit 1
        fi
        
        # libexec files and bin files are executable
        if [[ "$dest_dir" == "$INSTALL_LIBEXEC" ]] || [[ "$dest_dir" == "$INSTALL_BIN" ]]; then
            chmod +x "$dest_path"
        fi
    done < "$tmp_manifest"

    rm -f "$tmp_manifest"
fi

printf "${GREEN}✓ poetryenv installed to $INSTALL_BIN/poetryenv${NC}\n"

# Install poetry shim
printf "\n"

# Warn if existing poetry found
if [[ -f "$INSTALL_BIN/poetry" ]] || [[ -L "$INSTALL_BIN/poetry" ]]; then
    printf "${YELLOW}Warning: Existing Poetry command found at $INSTALL_BIN/poetry${NC}\n"
    printf "It will be replaced by poetryenv shim (enables automatic version switching).\n"
    printf "\n"
    read -p "Continue? [Y/n] " -n 1 -r
    printf "\n"
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        printf "\n"
        printf "${BLUE}Installation cancelled${NC}\n"
        printf "\n"
        printf "poetryenv is installed but the shim was not.\n"
        printf "You can use poetryenv without the shim:\n"
        printf "  ${YELLOW}poetryenv install 1.8.5${NC}\n"
        printf "  ${YELLOW}poetryenv global 1.8.5${NC}\n"
        printf "\n"
        printf "To install the shim later:\n"
        printf "  ${YELLOW}cp bin/poetry-shim $INSTALL_BIN/poetry${NC}\n"
        exit 0
    fi
    printf "\n"
fi

# Install shim
printf "${BLUE}→ Installing Poetry shim${NC}\n"

if [[ -f "$INSTALL_BIN/poetry" ]] || [[ -L "$INSTALL_BIN/poetry" ]]; then
    rm "$INSTALL_BIN/poetry"
fi

if [[ -f "bin/poetry-shim" ]]; then
    cp bin/poetry-shim "$INSTALL_BIN/poetry"
else
    curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/poetryenv/main/bin/poetry-shim -o "$INSTALL_BIN/poetry"
fi
chmod +x "$INSTALL_BIN/poetry"

printf "${GREEN}✓ Poetry shim installed${NC}\n"

printf "\n"
printf "${GREEN}Installation complete!${NC}\n"
printf "\n"
printf "${YELLOW}Next steps:${NC}\n"
printf "\n"
printf "1. Add poetryenv to your shell (enables PATH and tab completion):\n"
printf "\n"
printf "   ${BLUE}For bash (~/.bashrc):${NC}\n"
printf "   ${YELLOW}eval \"\$(poetryenv init - bash)\"${NC}\n"
printf "\n"
printf "   ${BLUE}For zsh (~/.zshrc):${NC}\n"
printf "   ${YELLOW}eval \"\$(poetryenv init - zsh)\"${NC}\n"
printf "\n"
printf "2. Restart your shell or run:\n"
printf "   ${YELLOW}exec \$SHELL${NC}\n"
printf "\n"
printf "3. Install and use Poetry:\n"
printf "   ${BLUE}poetryenv install --list${NC}       # List available versions\n"
printf "   ${BLUE}poetryenv install 1.8.5${NC}        # Install a version\n"
printf "   ${BLUE}poetryenv global 1.8.5${NC}         # Set as default\n"
printf "\n"

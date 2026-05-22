#!/usr/bin/env sh
set -eu

main() {
    repo="${ZED_TESTING_REPO:-stocky789/zed}"
    tag="${ZED_TESTING_TAG:-testing-latest}"
    platform="$(uname -s)"
    machine="$(uname -m)"

    case "$platform" in
        Linux)
            os="linux"
            ;;
        *)
            echo "Unsupported platform: $platform" >&2
            echo "Use script/install-testing.ps1 on Windows." >&2
            exit 1
            ;;
    esac

    case "$machine" in
        x86_64 | amd64)
            arch="x86_64"
            ;;
        aarch64 | arm64)
            arch="aarch64"
            ;;
        *)
            echo "Unsupported architecture: $machine" >&2
            exit 1
            ;;
    esac

    if command -v curl >/dev/null 2>&1; then
        fetch() {
            command curl -fL "$1" -o "$2"
        }
    elif command -v wget >/dev/null 2>&1; then
        fetch() {
            command wget -O "$2" "$1"
        }
    else
        echo "Could not find curl or wget in PATH" >&2
        exit 1
    fi

    if [ -n "${TMPDIR:-}" ] && [ -d "$TMPDIR" ]; then
        temp="$(mktemp -d "$TMPDIR/zed-testing-XXXXXX")"
    else
        temp="$(mktemp -d "/tmp/zed-testing-XXXXXX")"
    fi
    trap 'rm -rf "$temp"' EXIT INT TERM

    archive="zed-${os}-${arch}.tar.gz"
    url="https://github.com/${repo}/releases/download/${tag}/${archive}"

    echo "Downloading ${repo} ${tag} ${archive}"
    fetch "$url" "$temp/$archive"

    app_dir="$HOME/.local/zed-dev.app"
    rm -rf "$app_dir"
    mkdir -p "$HOME/.local"
    tar -xzf "$temp/$archive" -C "$HOME/.local"

    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
    if [ -f "$app_dir/bin/zed" ]; then
        ln -sf "$app_dir/bin/zed" "$HOME/.local/bin/zed"
    else
        ln -sf "$app_dir/bin/cli" "$HOME/.local/bin/zed"
    fi

    app_id="dev.zed.Zed-Dev"
    desktop_source="$app_dir/share/applications/${app_id}.desktop"
    desktop_target="$HOME/.local/share/applications/${app_id}.desktop"
    if [ -f "$desktop_source" ]; then
        cp "$desktop_source" "$desktop_target"
        sed -i "s|Icon=zed|Icon=$app_dir/share/icons/hicolor/512x512/apps/zed.png|g" "$desktop_target"
        sed -i "s|Exec=zed|Exec=$app_dir/bin/zed|g" "$desktop_target"
    fi

    if command -v zed >/dev/null 2>&1 && [ "$(command -v zed)" = "$HOME/.local/bin/zed" ]; then
        echo "Zed testing has been installed. Run it with: zed"
    else
        echo "Zed testing has been installed at: $HOME/.local/bin/zed"
        echo "Add ~/.local/bin to PATH to run it as: zed"
    fi
}

main "$@"

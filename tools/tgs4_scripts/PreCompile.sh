#!/bin/bash

set -euo pipefail

cache_dir=$PWD
repo_dir=$(cd -- "${1:?Missing game directory}" && pwd)
source "$repo_dir/dependencies.sh"

# Cobalt is a separate runtime service. Only build dependencies are installed here.
packages=(ca-certificates curl git gcc-multilib pkg-config libssl-dev:i386 zlib1g-dev:i386)
missing_packages=()
for package in "${packages[@]}"; do
	if [[ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null) != 'install ok installed' ]]; then
		missing_packages+=("$package")
	fi
done

if (( ${#missing_packages[@]} )); then
	apt_prefix=()
	if (( EUID != 0 )); then
		apt_prefix=(sudo)
	fi
	if ! dpkg --print-foreign-architectures | grep -qx i386; then
		"${apt_prefix[@]}" dpkg --add-architecture i386
	fi
	"${apt_prefix[@]}" apt-get update
	"${apt_prefix[@]}" apt-get install -y "${missing_packages[@]}"
fi

if [[ ! -x "$HOME/.cargo/bin/cargo" ]]; then
	echo "Installing rust..."
	curl https://sh.rustup.rs -sSf | sh -s -- -y
fi
"$HOME/.cargo/bin/rustup" target add i686-unknown-linux-gnu

# Build the pinned rust-g version in the TGS cache directory.
if [[ ! -d rust-g ]]; then
	echo "Cloning rust-g..."
	git clone https://github.com/tgstation/rust-g
else
	echo "Fetching rust-g..."
	git -C rust-g fetch --tags
fi

echo "Deploying rust-g..."
cd rust-g
git checkout "$RUST_G_VERSION"
env PKG_CONFIG_ALLOW_CROSS=1 PKG_CONFIG_LIBDIR=/usr/lib/i386-linux-gnu/pkgconfig:/usr/share/pkgconfig \
	"$HOME/.cargo/bin/cargo" build --release --target=i686-unknown-linux-gnu
install -m 0755 target/i686-unknown-linux-gnu/release/librust_g.so "$repo_dir/librust_g.so"

echo "Compiling tgui..."
cd "$repo_dir"
chmod +x tools/bootstrap/node  # Workaround for https://github.com/tgstation/tgstation-server/issues/1167
env TG_BOOTSTRAP_CACHE="$cache_dir" TG_BOOTSTRAP_NODE_LINUX=1 CBT_BUILD_MODE=TGS tools/bootstrap/node tools/build/build.js

#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/update-pi.sh <latest|vX.Y.Z>

Updates nix/sources.nix from the official earendil-works/pi release assets.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

for command in curl jq nix; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "missing required command: $command" >&2
    exit 1
  fi
done

repo="earendil-works/pi"
requested="$1"

if [[ "$requested" == "latest" ]]; then
  release_url="https://api.github.com/repos/${repo}/releases/latest"
else
  release_url="https://api.github.com/repos/${repo}/releases/tags/${requested}"
fi

release_json="$(curl --fail --silent --show-error --location "$release_url")"
tag="$(jq -r '.tag_name // empty' <<<"$release_json")"

if [[ -z "$tag" || "$tag" == "null" ]]; then
  echo "could not resolve Pi release tag for: $requested" >&2
  exit 1
fi

local_tag="$(nix eval --impure --raw --expr '(import ./nix/sources.nix).version')"
if [[ "$tag" == "$local_tag" ]]; then
  echo "Pi sources are already latest (${tag}); no update needed."
  exit 0
fi

declare -A assets=(
  [x86_64-linux]="pi-linux-x64.tar.gz"
  [aarch64-linux]="pi-linux-arm64.tar.gz"
  [x86_64-darwin]="pi-darwin-x64.tar.gz"
  [aarch64-darwin]="pi-darwin-arm64.tar.gz"
)

declare -A urls
declare -A hashes

for system in x86_64-linux aarch64-linux x86_64-darwin aarch64-darwin; do
  asset="${assets[$system]}"
  asset_json="$(jq --arg name "$asset" '.assets[] | select(.name == $name)' <<<"$release_json")"

  if [[ -z "$asset_json" ]]; then
    echo "missing release asset for ${system}: ${asset}" >&2
    exit 1
  fi

  url="$(jq -r '.browser_download_url // empty' <<<"$asset_json")"
  digest="$(jq -r '.digest // empty' <<<"$asset_json")"

  if [[ -z "$url" || "$url" == "null" ]]; then
    echo "missing download URL for ${asset}" >&2
    exit 1
  fi

  if [[ ! "$digest" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    echo "missing or unsupported SHA-256 digest for ${asset}" >&2
    exit 1
  fi

  hex_hash="${digest#sha256:}"
  sri_hash="$(nix hash convert --hash-algo sha256 --to sri "$hex_hash")"

  urls[$system]="$url"
  hashes[$system]="$sri_hash"
done

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

cat >"$tmp" <<EOF
let
  version = "${tag}";
in
{
  inherit version;

  sources =
    let
      baseUrl = "https://github.com/earendil-works/pi/releases/download/\${version}";
    in
    {
    x86_64-linux = rec {
      asset = "${assets[x86_64-linux]}";
      url = "\${baseUrl}/\${asset}";
      hash = "${hashes[x86_64-linux]}";
    };

    aarch64-linux = rec {
      asset = "${assets[aarch64-linux]}";
      url = "\${baseUrl}/\${asset}";
      hash = "${hashes[aarch64-linux]}";
    };

    x86_64-darwin = rec {
      asset = "${assets[x86_64-darwin]}";
      url = "\${baseUrl}/\${asset}";
      hash = "${hashes[x86_64-darwin]}";
    };

    aarch64-darwin = rec {
      asset = "${assets[aarch64-darwin]}";
      url = "\${baseUrl}/\${asset}";
      hash = "${hashes[aarch64-darwin]}";
    };
    };
}
EOF

mv "$tmp" nix/sources.nix

nix fmt
nix flake check
nix build .#pi-bin
nix build .#datu
nix run .#datu -- --version
nix run .#datu -- --help >/dev/null

echo "updated Pi sources to ${tag}"

# Datu

Datu is a declarative Nix wrapper around the official prebuilt Pi coding-agent binary.

Datu is not a fork of Pi. Pi provides the coding-agent behavior; Datu provides a fast `datu` command, Nix packaging, a small appended Datu prompt, and a downstream customization surface.

## Usage

```sh
nix run github:<owner>/datu
nix run github:<owner>/datu#datu
```

Build packages directly:

```sh
nix build .#pi-bin
nix build .#datu
```

## Flake Outputs

- `packages.<system>.pi-bin`
- `packages.<system>.datu`
- `packages.<system>.default`
- `apps.<system>.pi-bin`
- `apps.<system>.datu`
- `apps.<system>.default`
- `lib.mkDatu`
- `overlays.default`
- `formatter.<system>`

Supported systems:

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Custom Wrapper

```nix
inputs.datu.lib.mkDatu { inherit pkgs; } {
  name = "datu";

  enableDefaultPrompt = true;
  appendSystemPrompt = null;

  enableDefaultExtensions = true;
  enableDefaultSkills = true;
  enableDefaultThemes = true;
  enableDefaultPrompts = true;
  enableDefaultPackages = true;
  enableDefaultSettings = true;

  extensions = [];
  skills = [];
  themes = [];
  prompts = [];
  packages = [];

  settings = {};
  models = null;

  extraRuntimeInputs = [];
  extraEnv = {};
  extraFlags = [];
}
```

Phase 0 keeps default extensions, skills, themes, prompts, packages, and settings empty. The default Datu prompt is enabled and appended with Pi's `--append-system-prompt` flag.

Datu does not override Pi's config, session, auth, or package-cache directories by default.

## Updating Pi

```sh
scripts/update-pi.sh latest
scripts/update-pi.sh v0.74.0
```

The update script rewrites `nix/sources.nix` from official `earendil-works/pi` release assets and runs validation.

## Validation

```sh
nix flake check
nix build .#pi-bin
nix build .#datu
nix run .#datu -- --version
nix run .#datu -- --help | head -n 1
grep -R "PI_CODING_AGENT_DIR\|PI_CODING_AGENT_SESSION_DIR\|PI_PACKAGE_DIR" result/bin/datu || true
grep -R "SYSTEM.md" result/bin/datu || true
grep -R "append-system" result/bin/datu
scripts/update-pi.sh --help
```

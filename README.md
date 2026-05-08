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

Default extensions are loaded from `extensions/*/index.ts` or `extensions/*/index.js`. Default skills are loaded from `skills/`. Default themes are loaded from `themes/`. Default packages are listed in `packages/default.nix`. Add each new default extension in its own directory.

Current defaults:

- Extension: `datu-ui`
- Skill: `gh-cli`
- Theme: `datu`
- Package: `npm:pi-subagents`
- Package: `npm:pi-mcp-adapter`

Datu sets `theme = "datu"` by default without permanently mutating Pi settings. Datu settings are applied through a temporary Pi agent directory for the current run.

Default packages are loaded with Pi's temporary `--extension npm:...` path, so they are available for the current run without permanently installing them into Pi settings. Default prompts are empty. The default Datu prompt is enabled and appended with Pi's `--append-system-prompt` flag.

Disable default skills or themes when building a custom wrapper:

```nix
inputs.datu.lib.mkDatu { inherit pkgs; } {
  enableDefaultExtensions = false;
  enableDefaultSkills = false;
  enableDefaultThemes = false;
  enableDefaultPackages = false;
  enableDefaultSettings = false;
}
```

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

# Datu

Datu is a declarative Nix wrapper around the official prebuilt [Pi coding agent](https://github.com/earendil-works/pi) binary.

Datu is not a fork of Pi. Pi provides the real coding-agent behavior. Datu provides a fast `datu` command, Nix packaging, a small appended Datu prompt, default workflow resources, and a downstream customization surface.

## Quick Start

Run Datu directly from this flake:

```sh
nix run github:valdo766hi/datu
nix run github:valdo766hi/datu#datu
```

Build packages locally:

```sh
nix build .#pi-bin
nix build .#datu
```

Check the packaged Pi version:

```sh
nix run .#datu -- --version
```

## Use As Flake Input

Add Datu to another flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    datu.url = "github:valdo766hi/datu";
  };

  outputs = { self, nixpkgs, datu, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.default = datu.packages.${system}.datu;
    };
}
```

Create a custom Datu wrapper from downstream flakes:

```nix
{
  packages.${system}.my-datu = datu.lib.mkDatu { inherit pkgs; } {
    name = "my-datu";

    appendSystemPrompt = ''
      Prefer my team's local conventions.
    '';

    skills = [ ./skills ];
    themes = [ ./themes ];
    packages = [ "npm:my-pi-package" ];

    settings = {
      defaultProvider = "github-copilot";
      defaultModel = "gpt-5.5";
      defaultThinkingLevel = "high";
    };
  };
}
```

Use Datu with NixOS or Home Manager packages:

```nix
environment.systemPackages = [ inputs.datu.packages.${pkgs.system}.datu ];
```

```nix
home.packages = [ inputs.datu.packages.${pkgs.system}.datu ];
```

Use the overlay:

```nix
{
  nixpkgs.overlays = [ inputs.datu.overlays.default ];
}
```

Then install `pkgs.datu` or `pkgs.pi-bin`.

## Flake Outputs

- `packages.<system>.pi-bin`: official prebuilt Pi binary packaged from GitHub releases.
- `packages.<system>.datu`: Datu wrapper around `pi-bin`.
- `packages.<system>.default`: same as `datu`.
- `apps.<system>.pi-bin`: app for the raw packaged Pi binary.
- `apps.<system>.datu`: app for Datu.
- `apps.<system>.default`: same as `datu`.
- `lib.mkDatu`: reusable wrapper builder for downstream customization.
- `overlays.default`: exposes `pi-bin` and `datu` in `pkgs`.
- `formatter.<system>`: formats Nix files.

Supported systems:

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Defaults

Datu loads default resources from local repo folders so adding more defaults is straightforward:

- Extensions: `extensions/*/index.ts` or `extensions/*/index.js`
- Skills: `skills/`
- Themes: `themes/`
- Prompts: `prompts/`
- Packages: `packages/default.nix`

Current defaults:

- Extension: `datu-header`, local Datu banner and compact prompt/context/skills/tools table in `extensions/datu-header/index.ts`.
- Extension: `datu-footer`, local Datu footer/status UI in `extensions/datu-footer/index.ts`.
- Extension: `dekallm`, DekaLLM provider in `extensions/dekallm/index.ts`.
- Extension: `pi-subagents`, vendored package-style extension in `extensions/pi-subagents/`.
- Skill: `gh-cli`, copied from [github/awesome-copilot gh-cli skill](https://github.com/github/awesome-copilot/blob/main/skills/gh-cli/SKILL.md).
- Theme: `datu`, local Catppuccin Mocha-inspired color theme in `themes/datu.json`.
- Prompt template: `/plan`, from `prompts/plan.md`, for investigation-only implementation planning with no repository mutation.
- Package: `npm:pi-mcp-adapter`, from [pi-mcp-adapter](https://pi.dev/packages/pi-mcp-adapter) and [GitHub](https://github.com/nicobailon/pi-mcp-adapter).
- Package: `npm:@plannotator/pi-extension`, from [Plannotator](https://github.com/backnotprop/plannotator), adding Pi plan review mode via `--plan` and `/plannotator`.

The `datu` theme is loaded by default as a Pi theme resource, not an extension. It only defines colors/style tokens. To make it active, set `theme = "datu"` in your Pi settings or pass declarative `settings = { theme = "datu"; };` in a custom Datu package.

Default packages are loaded with Pi's temporary `--extension npm:...` path. They are available for the current run without permanently adding package entries to Pi settings.

## Options

`lib.mkDatu` accepts two argument sets:

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

Option details:

- `name`: output command name. Defaults to `datu`.
- `enableDefaultPrompt`: append the built-in Datu prompt to Pi's default system prompt. Defaults to `true`.
- `appendSystemPrompt`: extra downstream prompt text to append after the Datu prompt. Defaults to `null`.
- `enableDefaultExtensions`: load Datu default extensions from `extensions/`. Defaults to `true`.
- `enableDefaultSkills`: load Datu default skills from `skills/`. Defaults to `true`.
- `enableDefaultThemes`: load Datu default themes from `themes/`. Defaults to `true`.
- `enableDefaultPrompts`: load Datu default prompt templates from `prompts/`. Defaults to `true`.
- `enableDefaultPackages`: load package sources from `packages/default.nix`. Defaults to `true`.
- `enableDefaultSettings`: apply Datu default settings. Current defaults set `quietStartup = true` and `theme = "datu"`.
- `extensions`: additive extension files or package-like extension sources passed as `--extension`.
- `skills`: additive skill files or directories passed as `--skill`.
- `themes`: additive theme files or directories passed as `--theme`.
- `prompts`: additive prompt template files or directories passed as `--prompt-template`.
- `packages`: additive Pi package sources loaded as temporary `--extension npm:...` or equivalent package sources.
- `settings`: settings merged with Datu defaults and written only to the temporary runtime agent directory.
- `models`: optional custom `models.json` path. Defaults to `null`, preserving Pi's normal model behavior.
- `extraRuntimeInputs`: extra binaries added to the wrapper runtime `PATH`.
- `extraEnv`: extra environment variables exported by the wrapper.
- `extraFlags`: raw extra CLI flags appended before user arguments.

Disable all Datu defaults while keeping the wrapper:

```nix
inputs.datu.lib.mkDatu { inherit pkgs; } {
  enableDefaultPrompt = false;
  enableDefaultExtensions = false;
  enableDefaultSkills = false;
  enableDefaultThemes = false;
  enableDefaultPrompts = false;
  enableDefaultPackages = false;
  enableDefaultSettings = false;
}
```

## Add Defaults To This Repo

Add a default extension:

```text
extensions/my-extension/index.ts
```

Add a default skill:

```text
skills/my-skill/SKILL.md
```

Add a default theme:

```text
themes/my-theme.json
```

Add a default prompt template:

```text
prompts/my-template.md
```

Add a default package:

```nix
# packages/default.nix
[
  "npm:pi-mcp-adapter"
  "npm:@plannotator/pi-extension"
  "npm:another-pi-package"
]
```

## `/plan` prompt template

Use `/plan` in the editor to ask Datu/Pi to investigate and produce a read-only implementation plan.

Examples:

```text
/plan
/plan add OAuth device flow support
```

The built-in `/plan` template performs read-only investigation in the parent session, then prefers the existing `planner` subagent from `pi-subagents` to synthesize the implementation plan. It allows repository reading, search, git inspection, bounded validation commands, and web search/fetch when available. It forbids parent-session writes, edits, patches, dependency changes, git mutations, config mutation, and long-running processes.

Output format:

```text
Summary:
Findings:
Plan:
Files likely to change:
Validation:
Risks / Unknowns:
Status: READY TO EXECUTE
```

## Runtime Behavior

Datu calls the packaged Pi binary and preserves Pi as the real agent implementation.

Datu does not replace Pi's default system prompt. It uses Pi's `--append-system-prompt` flag.

Datu does not permanently mutate Pi config, sessions, auth, or package settings. When default settings or custom `models` are configured, Datu creates a temporary agent directory for the current run, symlinks the user's existing Pi agent files, writes a generated `settings.json`, and then launches Pi with `PI_CODING_AGENT_DIR` pointing to that temporary directory.

## Updating Pi

Update official Pi release metadata and hashes:

```sh
scripts/update-pi.sh latest
scripts/update-pi.sh v0.74.0
```

The script updates `nix/sources.nix`, formats the repo, and runs validation. If the requested release already matches the local pin, it exits early.

## Validation

```sh
nix flake check
nix build .#pi-bin
nix build .#datu
nix run .#datu -- --version
nix run .#datu -- --help | head -n 1
grep -R "SYSTEM.md" result/bin/datu || true
grep -R "append-system" result/bin/datu
scripts/update-pi.sh --help
```

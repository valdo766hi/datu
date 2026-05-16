# Datu Agent Guide

Datu is a declarative Nix wrapper around the official prebuilt Pi coding-agent binary. Pi provides the agent runtime; Datu provides packaging, a `datu` command, additive defaults, and downstream customization.

Keep this file short. Update it when repo structure, runtime behavior, validation, or release rules change.

## Core Rules

- Use official Pi release binaries from `https://github.com/earendil-works/pi/releases`.
- Do not build Pi from source or vendor Pi internals such as `models.generated.ts`.
- Do not use `github:lukasl-dev/pi-mono.nix`.
- Use available tools, MCP servers, skills, and subagents when they make the work safer, faster, or clearer.
- Keep `flake.nix` mostly wiring.
- Put package logic in `nix/package.nix`.
- Put wrapper logic in `nix/mk-datu.nix`.
- Put Pi release metadata in `nix/sources.nix`.
- Put update automation in `scripts/update-pi.sh`.
- Put npm package vendoring in `nix/npm-packages.nix`.
- Put resource derivations in `nix/resources.nix`.

## Runtime Behavior

- Preserve Pi defaults unless the user explicitly configures otherwise.
- Do not force Pi state isolation by default: avoid exporting `PI_CODING_AGENT_DIR`, `PI_CODING_AGENT_SESSION_DIR`, or `PI_PACKAGE_DIR` unless settings/models require a temporary generated config.
- Do not replace Pi's system prompt or use `SYSTEM.md`; only append Datu's prompt with `--append-system-prompt`.
- Datu may set extension-specific env defaults, such as `PI_SUBAGENTS_USER_DIR=$HOME/.pi/subagents`, when needed to keep user skills separate from subagents.
- Never print, log, commit, or echo API keys. Provider extensions must read secrets from runtime env or Pi auth, not source files.

## Defaults

- Default extensions live in `extensions/` and are explicitly listed in `flake.nix` (no auto-discovery).
- Default skills live in `skills/`.
- Default themes live in `themes/`.
- Default prompts live in `prompts/`.
- NPM packages are vendored into the Nix store via `nix/npm-packages.nix`.
- Default subagent overrides live in `subagents/default.nix`.
- Default MCP servers live in `nix/mcp.nix`; secret headers must be injected from env vars at runtime only.
- All resources are wrapped in Nix derivations via `nix/resources.nix` and live in the Nix store.

Current notable defaults:

- `extensions/datu-header/`: Datu banner plus compact prompt/context/skills/tools table.
- `extensions/datu-footer/`: Datu footer/status UI.
- `extensions/dekallm/`: DekaLLM custom provider; reads `DEKA_API_KEY` or `DEKALLM_API_KEY` at runtime.
- `extensions/pi-subagents/`: vendored `pi-subagents` with Datu patches; user subagents default to `~/.pi/subagents`.
- `subagents/default.nix`: default builtin subagent model/thinking overrides.
- `nix/npm-packages.nix`: vendored npm packages (`pi-mcp-adapter`, `@plannotator/pi-extension`).

## Options

Use positive default toggles and plain additive resource names:

- `enableDefaultPrompt`, `enableDefaultExtensions`, `enableDefaultSkills`, `enableDefaultThemes`, `enableDefaultPrompts`, `enableDefaultPackages`, `enableDefaultSettings`, `enableDefaultMcp`
- `extensions`, `skills`, `themes`, `prompts`, `npmPackages`, `settings`, `models`, `mcpServers`

Do not add `extra*` resource names or negative `disable*` options. Defaults must remain easy to disable with `enableDefault* = false`.

## Updating This File

When behavior changes, update `AGENTS.md` in the same work:

- Add rules only when they prevent recurring mistakes or document stable architecture.
- Remove stale implementation details instead of accumulating history.
- Prefer repo paths and exact validation commands over long explanations.
- Keep secrets, temporary plans, and one-off debugging notes out of this file.

## Git

- Never run `git push` unless the user explicitly asks.
- Creating a PR counts as explicit permission to push the current branch if pushing is required for the PR.
- PR titles and descriptions should be short, clear, senior-engineer style, and to the point, still use Conventional way just like commit do for titles.
- Commit only when explicitly requested.
- Use short Conventional Commits.
- Keep commits focused.

## Validation

Run relevant checks before claiming success:

```sh
nix flake check
nix build .#pi-bin
nix build .#datu
nix run .#datu -- --version
nix run .#datu -- --help
```

Also verify wrapper invariants when runtime behavior changes:

```sh
grep -R "PI_CODING_AGENT_DIR\|PI_CODING_AGENT_SESSION_DIR\|PI_PACKAGE_DIR" result/bin/datu || true
grep -R "SYSTEM.md" result/bin/datu || true
grep -R "append-system" result/bin/datu
grep "npm:" result/bin/datu || true  # should be empty (no npm URIs)
grep "trap" result/bin/datu          # should show temp dir cleanup
```

If validation was not run, say `UNVERIFIED` and provide exact commands to run locally.

{
  lib,
  writeShellApplication,
  writeText,
  pi-bin,
}:

{
  pkgs ? null,
}:
{
  name ? "datu",
  enableDefaultPrompt ? true,
  appendSystemPrompt ? null,
  enableDefaultExtensions ? true,
  enableDefaultSkills ? true,
  enableDefaultThemes ? true,
  enableDefaultPrompts ? true,
  enableDefaultPackages ? true,
  enableDefaultSettings ? true,
  extensions ? [ ],
  skills ? [ ],
  themes ? [ ],
  prompts ? [ ],
  packages ? [ ],
  settings ? { },
  models ? null,
  extraRuntimeInputs ? [ ],
  extraEnv ? { },
  extraFlags ? [ ],
}:

let
  defaultPrompt = ''
    You are Datu, a declarative Nix wrapper around Pi.

    Datu is based on Pi. For Pi-specific behavior, follow Pi's default system prompt and Pi documentation. For Datu-specific behavior, read this repository's README.

    Be wise, concise, direct, and implementation-focused.

    Prefer declarative configuration.

    Prefer deterministic validation commands.
  '';

  defaultExtensions = [ ];
  defaultSkills = [ ];
  defaultThemes = [ ];
  defaultPrompts = [ ];
  defaultPackages = [ ];
  defaultSettings = { };

  finalExtensions = lib.optionals enableDefaultExtensions defaultExtensions ++ extensions;
  finalSkills = lib.optionals enableDefaultSkills defaultSkills ++ skills;
  finalThemes = lib.optionals enableDefaultThemes defaultThemes ++ themes;
  finalPrompts = lib.optionals enableDefaultPrompts defaultPrompts ++ prompts;
  finalPackages = lib.optionals enableDefaultPackages defaultPackages ++ packages;
  finalSettings = lib.recursiveUpdate (lib.optionalAttrs enableDefaultSettings defaultSettings) settings;

  promptParts =
    lib.optionals enableDefaultPrompt [ defaultPrompt ]
    ++ lib.optionals (appendSystemPrompt != null) [ appendSystemPrompt ];
  promptFile = writeText "datu-append-system-prompt.md" (lib.concatStringsSep "\n\n" promptParts);

  resourceFlags =
    (lib.concatMap (path: [
      "--extension"
      (toString path)
    ]) finalExtensions)
    ++ (lib.concatMap (path: [
      "--skill"
      (toString path)
    ]) finalSkills)
    ++ (lib.concatMap (path: [
      "--theme"
      (toString path)
    ]) finalThemes)
    ++ (lib.concatMap (path: [
      "--prompt-template"
      (toString path)
    ]) finalPrompts)
    ++ extraFlags;

  envLines = lib.mapAttrsToList (name: value: ''
    export ${name}=${lib.escapeShellArg (toString value)}
  '') extraEnv;

  modelLines = lib.optionalString (models != null) ''
    datu_agent_dir="$(mktemp -d "''${TMPDIR:-/tmp}/datu-agent.XXXXXX")"
    datu_default_agent_dir="$HOME/.pi/agent"
    mkdir -p "$datu_agent_dir"
    if [ -d "$datu_default_agent_dir" ]; then
      for datu_agent_path in "$datu_default_agent_dir"/* "$datu_default_agent_dir"/.[!.]*; do
        [ -e "$datu_agent_path" ] || continue
        datu_agent_name="''${datu_agent_path##*/}"
        [ "$datu_agent_name" = "models.json" ] && continue
        ln -s "$datu_agent_path" "$datu_agent_dir/$datu_agent_name"
      done
    fi
    ln -s ${lib.escapeShellArg (toString models)} "$datu_agent_dir/models.json"
    export PI_CODING_AGENT_DIR="$datu_agent_dir"
  '';

  wrapper = writeShellApplication {
    inherit name;
    runtimeInputs = [ pi-bin ] ++ extraRuntimeInputs;
    text = ''
      ${lib.concatStringsSep "\n" envLines}
      ${modelLines}
      exec ${lib.getExe pi-bin} --append-system-prompt ${lib.escapeShellArg promptFile} ${lib.escapeShellArgs resourceFlags} "$@"
    '';
  };
in
assert
  finalPackages == [ ]
  || throw "Datu phase 0 does not pass packages without mutating Pi settings; use extraFlags or Pi settings.json.";
assert
  finalSettings == { }
  || throw "Datu phase 0 does not pass settings without mutating Pi settings; use Pi settings.json.";
wrapper.overrideAttrs (old: {
  passthru = {
    inherit
      finalExtensions
      finalSkills
      finalThemes
      finalPrompts
      finalPackages
      finalSettings
      promptFile
      pi-bin
      ;
  };

  meta =
    old.meta
    // pi-bin.meta
    // {
      description = "Declarative Nix wrapper around the official prebuilt Pi binary";
      mainProgram = name;
    };
})

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
  enableDefaultMcp ? true,
  mcpServers ? { },
}:

let
  defaultPrompt = ''
    You are Datu, a declarative Nix wrapper around Pi.

    Datu is based on Pi. For Pi-specific behavior, follow Pi's default system prompt and Pi documentation. For Datu-specific behavior, read this repository's README.

    Be wise, concise, direct, and implementation-focused.

    Prefer declarative configuration.

    Prefer deterministic validation commands.

    For all web search and web fetch operations, use the Exa MCP server (`exa_web_search_exa` and `exa_web_fetch_exa`) as the first and preferred option.
  '';

  extensionEntries = builtins.readDir ../extensions;
  hasPackageExtension = name:
    let
      pkgPath = ../extensions/${name}/package.json;
      pkg = if builtins.pathExists pkgPath then builtins.fromJSON (builtins.readFile pkgPath) else { };
    in
    pkg ? pi.extensions && builtins.isList pkg.pi.extensions && pkg.pi.extensions != [ ];
  extensionPath =
    name: type:
    if type == "directory" && hasPackageExtension name then
      ../extensions/${name}
    else if type == "directory" && builtins.pathExists ../extensions/${name}/index.ts then
      ../extensions/${name}/index.ts
    else if type == "directory" && builtins.pathExists ../extensions/${name}/index.js then
      ../extensions/${name}/index.js
    else
      ../extensions/${name};
  defaultExtensions = lib.mapAttrsToList extensionPath (
    lib.filterAttrs (
      name: type:
      (type == "regular" && (lib.hasSuffix ".ts" name || lib.hasSuffix ".js" name))
      || (
        type == "directory"
        && (
          builtins.pathExists ../extensions/${name}/index.ts
          || builtins.pathExists ../extensions/${name}/index.js
          || hasPackageExtension name
        )
      )
    ) extensionEntries
  );
  defaultSkills = [ ../skills ];
  defaultThemes = [ ../themes ];
  defaultPrompts = [ ];
  defaultPackages = import ../packages;
  defaultSettings = { };
  defaultMcpServers = import ../nix/mcp.nix { inherit lib; };
  finalMcpServers = lib.optionalAttrs enableDefaultMcp defaultMcpServers // mcpServers;

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
      path
    ]) finalExtensions)
    ++ (lib.concatMap (path: [
      "--skill"
      path
    ]) finalSkills)
    ++ (lib.concatMap (path: [
      "--theme"
      path
    ]) finalThemes)
    ++ (lib.concatMap (path: [
      "--prompt-template"
      path
    ]) finalPrompts)
    ++ (lib.concatMap (package: [
      "--extension"
      package
    ]) finalPackages)
    ++ extraFlags;

  shellArg = value: if builtins.isPath value then "${value}" else lib.escapeShellArg (toString value);
  resourceFlagsText = lib.concatStringsSep " " (map shellArg resourceFlags);

  envLines = lib.mapAttrsToList (name: value: ''
    export ${name}=${lib.escapeShellArg (toString value)}
  '') extraEnv;

  settingsFile = writeText "datu-settings.json" (builtins.toJSON finalSettings);

  mcpBase = lib.mapAttrs (name: cfg: lib.filterAttrs (n: v: n != "apiKeyHeader") cfg) finalMcpServers;
  mcpBaseJson = writeText "datu-mcp-base.json" (builtins.toJSON { mcpServers = mcpBase; });

  mcpHeaderPatches = lib.concatMapStringsSep "\n" (server:
    let
      bearerPrefix = lib.optionalString (server.value.apiKeyHeader ? bearer && server.value.apiKeyHeader.bearer) "Bearer ";
    in
    lib.optionalString (server.value ? apiKeyHeader) ''
      if [ -n "''${${server.value.apiKeyHeader.env}:-}" ]; then
        mcp_json=$(jq --arg name "${server.name}" --arg key "${server.value.apiKeyHeader.name}" --arg val "${bearerPrefix}''${${server.value.apiKeyHeader.env}}" '.mcpServers[$name].headers[$key] = $val' <<< "$mcp_json")
      fi
    ''
  ) (lib.attrsToList finalMcpServers);

  agentDirLines = lib.optionalString (finalSettings != { } || models != null) ''
    datu_agent_dir="$(mktemp -d "''${TMPDIR:-/tmp}/datu-agent.XXXXXX")"
    datu_default_agent_dir="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
    mkdir -p "$datu_agent_dir"
    if [ -d "$datu_default_agent_dir" ]; then
      for datu_agent_path in "$datu_default_agent_dir"/* "$datu_default_agent_dir"/.[!.]*; do
        [ -e "$datu_agent_path" ] || continue
        datu_agent_name="''${datu_agent_path##*/}"
        [ "$datu_agent_name" = "settings.json" ] && continue
        ${lib.optionalString (models != null) ''[ "$datu_agent_name" = "models.json" ] && continue''}
        ln -s "$datu_agent_path" "$datu_agent_dir/$datu_agent_name"
      done
    fi
    ${lib.optionalString (
      models != null
    ) ''ln -s ${lib.escapeShellArg (toString models)} "$datu_agent_dir/models.json"''}
    if [ -f "$datu_default_agent_dir/settings.json" ]; then
      ${lib.getExe pkgs.jq} -s '.[1] * .[0]' ${settingsFile} "$datu_default_agent_dir/settings.json" > "$datu_agent_dir/settings.json"
    else
      cp ${settingsFile} "$datu_agent_dir/settings.json"
    fi
    export PI_CODING_AGENT_DIR="$datu_agent_dir"
  '';

  wrapper = writeShellApplication {
    inherit name;
    runtimeInputs = [ pi-bin ] ++ lib.optionals (finalMcpServers != { }) [ pkgs.jq ] ++ extraRuntimeInputs;
    text = ''
      ${lib.concatStringsSep "\n" envLines}
      ${agentDirLines}
      ${lib.optionalString (finalMcpServers != { }) ''
        mcp_json=$(cat ${mcpBaseJson})
        ${mcpHeaderPatches}
        mcp_config_path="$(mktemp "''${TMPDIR:-/tmp}/datu-mcp.XXXXXX.json")"
        echo "$mcp_json" > "$mcp_config_path"
      ''}
      export PI_SUBAGENTS_USER_DIR="''${PI_SUBAGENTS_USER_DIR:-$HOME/.pi/subagents}"
      exec ${lib.getExe pi-bin} --append-system-prompt ${lib.escapeShellArg promptFile} \
        ${lib.optionalString (finalMcpServers != { }) "--mcp-config \"$mcp_config_path\""} \
        ${resourceFlagsText} "$@"
    '';
  };
in
wrapper.overrideAttrs (old: {
  passthru = {
    inherit
      finalExtensions
      finalSkills
      finalThemes
      finalPrompts
      finalPackages
      finalSettings
      finalMcpServers
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

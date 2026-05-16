{ pkgs }:

let
  root = ../.;

  copyDir =
    name: src:
    pkgs.runCommand name { } ''
      cp -r ${src} $out
      chmod -R u+w $out
    '';

  copyFile =
    name: src:
    pkgs.runCommand name { } ''
      mkdir -p $out
      cp ${src} $out/${name}
    '';

in
{
  extensions = {
    datu-header = copyFile "index.ts" "${root}/extensions/datu-header/index.ts";
    datu-footer = copyFile "index.ts" "${root}/extensions/datu-footer/index.ts";
    dekallm = copyFile "index.ts" "${root}/extensions/dekallm/index.ts";
    pi-subagents = copyDir "pi-subagents" "${root}/extensions/pi-subagents";
  };

  skills = {
    gh-cli = copyDir "gh-cli" "${root}/skills/gh-cli";
  };

  themes = {
    datu = copyFile "datu.json" "${root}/themes/datu.json";
  };

  prompts = {
    plan = copyFile "plan.md" "${root}/prompts/plan.md";
  };

  subagents = import "${root}/subagents/default.nix";

  mcpServers = import "${root}/nix/mcp.nix" { inherit (pkgs) lib; };
}

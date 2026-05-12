{
  description = "Declarative Nix wrapper around the official prebuilt Pi binary";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";

  outputs =
    { self, ... }@inputs:
    let
      inherit (inputs.nixpkgs) lib;

      supportedSystems = builtins.attrNames (import ./nix/sources.nix).sources;

      forEachSupportedSystem =
        f:
        lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
        );

      mkPiBin = pkgs: pkgs.callPackage ./nix/package.nix { };

      mkDatuFor =
        pkgs: pi-bin:
        import ./nix/mk-datu.nix {
          inherit (pkgs)
            lib
            writeShellApplication
            writeText
            ;
          inherit pi-bin;
        };
    in
    {
      lib.mkDatu =
        { pkgs }:
        let
          pi-bin = mkPiBin pkgs;
        in
        mkDatuFor pkgs pi-bin { inherit pkgs; };

      overlays.default = final: prev: {
        pi-bin = mkPiBin final;
        datu = (mkDatuFor final final.pi-bin { pkgs = final; }) {
          appendSystemPrompt = ''
            Subagent-first policy:
            - For nearly all non-trivial tasks, delegate first.
            - Use planner for planning, scout for fast codebase recon, researcher for web/info gathering, worker for implementation, and reviewer for validation/review.
            - Parent agent should focus on orchestration and final synthesis, not deep analysis.
            - If requirements are unclear, call planner first.
            - Prefer parallel subagents for independent workstreams.
            - Avoid large parent-context analysis unless delegation is impossible.
          '';
          settings = {
            defaultProvider = "openai-codex";
            defaultModel = "openai-codex/gpt-5.4-mini";
            defaultThinkingLevel = "minimal";
          };
          extraFlags = [
            "--model"
            "openai-codex/gpt-5.4-mini"
          ];
        };
      };

      packages = forEachSupportedSystem (
        { pkgs, ... }:
        let
          pi-bin = mkPiBin pkgs;
          datu = (mkDatuFor pkgs pi-bin { inherit pkgs; }) {
            appendSystemPrompt = ''
              Subagent-first policy:
              - For nearly all non-trivial tasks, delegate first.
              - Use planner for planning, scout for fast codebase recon, researcher for web/info gathering, worker for implementation, and reviewer for validation/review.
              - Parent agent should focus on orchestration and final synthesis, not deep analysis.
              - If requirements are unclear, call planner first.
              - Prefer parallel subagents for independent workstreams.
              - Avoid large parent-context analysis unless delegation is impossible.
            '';
            settings = {
              defaultProvider = "openai-codex";
              defaultModel = "openai-codex/gpt-5.4-mini";
              defaultThinkingLevel = "minimal";
            };
            extraFlags = [
              "--model"
              "openai-codex/gpt-5.4-mini"
            ];
          };
        in
        {
          inherit datu pi-bin;
          default = datu;
        }
      );

      apps = forEachSupportedSystem (
        { system, ... }:
        {
          datu = {
            type = "app";
            program = "${self.packages.${system}.datu}/bin/datu";
          };

          default = self.apps.${system}.datu;

          pi-bin = {
            type = "app";
            program = "${self.packages.${system}.pi-bin}/bin/pi";
          };
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              self.formatter.${system}
            ];
          };
        }
      );

      formatter = forEachSupportedSystem (
        { pkgs, ... }:
        pkgs.writeShellApplication {
          name = "datu-format";
          runtimeInputs = [ pkgs.nixfmt ];
          text = ''
            nixfmt flake.nix nix/*.nix
          '';
        }
      );
    };
}

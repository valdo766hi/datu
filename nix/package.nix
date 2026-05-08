{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  sources ? import ./sources.nix,
}:

let
  source =
    sources.sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "pi-bin";
  version = lib.removePrefix "v" sources.version;

  src = fetchurl {
    inherit (source) url hash;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib/pi"

    if [ -d pi ]; then
      cp -R pi/. "$out/lib/pi/"
    else
      cp -R . "$out/lib/pi/"
    fi

    if [ ! -x "$out/lib/pi/pi" ]; then
      echo "could not find executable pi binary in release archive" >&2
      exit 1
    fi

    printf '%s\n' '#!${stdenv.shell}' 'exec "'$out'/lib/pi/pi" "$@"' > "$out/bin/pi"
    chmod +x "$out/bin/pi"

    runHook postInstall
  '';

  meta = {
    description = "Official prebuilt Pi coding agent binary";
    homepage = "https://github.com/earendil-works/pi";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = builtins.attrNames sources.sources;
  };
}

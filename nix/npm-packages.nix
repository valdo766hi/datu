{ pkgs }:

let
  fetchNpmWithDeps =
    { pname, version, srcHash, packageLock }:
    let
      scoped = builtins.match "@([^/]+)/(.+)" pname;
      tarballUrl =
        if scoped != null
        then
          "https://registry.npmjs.org/@${builtins.head scoped}/${builtins.elemAt scoped 1}/-/${pname}-${version}.tgz"
        else
          "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    in
    pkgs.runCommand "${pname}-${version}" {
      nativeBuildInputs = [ pkgs.nodejs_22 ];
    } ''
      ${pkgs.gnutar}/bin/tar xzf ${pkgs.fetchurl { url = tarballUrl; hash = srcHash; }}
      cd package
      chmod -R u+w .
      cp ${packageLock} package-lock.json
      HOME=$TMPDIR npm install --omit=dev --prefer-offline --no-audit --no-fund
      rm -rf node_modules/.cache
      mv . $out
    '';

in
{
  pi-mcp-adapter = fetchNpmWithDeps {
    pname = "pi-mcp-adapter";
    version = "2.6.1";
    srcHash = "sha256:0w4fx2ykc6d846v6yxx2vls5mbv0bmjwccr963wihgr92hn1ivx2";
    packageLock = ./pi-mcp-adapter-package-lock.json;
  };

  plannotator = fetchNpmWithDeps {
    pname = "@plannotator/pi-extension";
    version = "0.19.17";
    srcHash = "sha256:1vn8nzgfzgjh2p1n1pm2g8py2b4l7i651c3i39b3al51634j51xf";
    packageLock = ./plannotator-package-lock.json;
  };
}

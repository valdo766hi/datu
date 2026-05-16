{ pkgs }:

let
  fetchNpmTarball =
    { pname, version, hash }:
    let
      scoped = builtins.match "@([^/]+)/(.+)" pname;
      tarballUrl =
        if scoped != null
        then
          "https://registry.npmjs.org/@${builtins.head scoped}/${builtins.elemAt scoped 1}/-/${pname}-${version}.tgz"
        else
          "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    in
    pkgs.runCommand "${pname}-${version}" { } ''
      ${pkgs.gnutar}/bin/tar xzf ${pkgs.fetchurl { url = tarballUrl; hash = hash; }}
      mv package $out
    '';

in
{
  pi-mcp-adapter = fetchNpmTarball {
    pname = "pi-mcp-adapter";
    version = "2.6.1";
    hash = "sha256:0w4fx2ykc6d846v6yxx2vls5mbv0bmjwccr963wihgr92hn1ivx2";
  };

  plannotator = fetchNpmTarball {
    pname = "@plannotator/pi-extension";
    version = "0.19.17";
    hash = "sha256:1vn8nzgfzgjh2p1n1pm2g8py2b4l7i651c3i39b3al51634j51xf";
  };
}

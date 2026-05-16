{ pkgs }:

let
  buildNpmExtension =
    { pname, version, srcHash, npmDepsHash, packageLock }:
    pkgs.buildNpmPackage {
      inherit pname version;
      src = pkgs.fetchurl {
        url =
          let
            scoped = builtins.match "@([^/]+)/(.+)" pname;
          in
          if scoped != null
          then
            "https://registry.npmjs.org/@${builtins.head scoped}/${builtins.elemAt scoped 1}/-/${pname}-${version}.tgz"
          else
            "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
        hash = srcHash;
      };
      inherit npmDepsHash;
      npmFlags = [ "--omit=dev" ];
      postPatch = ''
        cp ${packageLock} package-lock.json
      '';
      dontBuild = true;
      installPhase = ''
        cp -r . $out
      '';
    };

in
{
  pi-mcp-adapter = buildNpmExtension {
    pname = "pi-mcp-adapter";
    version = "2.6.1";
    srcHash = "sha256:0w4fx2ykc6d846v6yxx2vls5mbv0bmjwccr963wihgr92hn1ivx2";
    npmDepsHash = "sha256-7NgnqQ55PgXyXuaEAXXW6+2XZnwGLHMw0EaZBR8T1PA=";
    packageLock = ./pi-mcp-adapter-package-lock.json;
  };

  plannotator = buildNpmExtension {
    pname = "@plannotator/pi-extension";
    version = "0.19.17";
    srcHash = "sha256:1vn8nzgfzgjh2p1n1pm2g8py2b4l7i651c3i39b3al51634j51xf";
    npmDepsHash = "sha256-XhSA8V38t04UK3FkEB5S6t8+vJoPW/qYItT++fkSl5U=";
    packageLock = ./plannotator-package-lock.json;
  };
}

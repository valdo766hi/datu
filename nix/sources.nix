let
  version = "v0.74.0";
in
{
  inherit version;

  sources =
    let
      baseUrl = "https://github.com/earendil-works/pi/releases/download/${version}";
    in
    {
      x86_64-linux = rec {
        asset = "pi-linux-x64.tar.gz";
        url = "${baseUrl}/${asset}";
        hash = "sha256-1nZXow1JyfrKgIaNKkvbpN/KwEcCiT9FptFLJJNF640=";
      };

      aarch64-linux = rec {
        asset = "pi-linux-arm64.tar.gz";
        url = "${baseUrl}/${asset}";
        hash = "sha256-JhqpEoeMqYPJA9nEoECDEN2GN7WDCFZR2bXdtwyd9XI=";
      };

      x86_64-darwin = rec {
        asset = "pi-darwin-x64.tar.gz";
        url = "${baseUrl}/${asset}";
        hash = "sha256-+mXJjyxlHsL4n7Goo9ybmHlHvJsQI2Gi8XiGKrrMdWA=";
      };

      aarch64-darwin = rec {
        asset = "pi-darwin-arm64.tar.gz";
        url = "${baseUrl}/${asset}";
        hash = "sha256-MGMXmCPGqYVjQxIkDFcBUCQxb3/mZh7dQfFMd9ixXhA=";
      };
    };
}

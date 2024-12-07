{
  description = "miniflux.nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # flake-root is a dependency of flake-containers that enable to find the root project for the flake
    # repositorty to create the states for the containers
    flake-root.url = "github:srid/flake-root";

    # Import flake-containers
    flake-containers.url = "github:adfaure/flake-containers";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./containers.nix
      ];

      flake = {
        # Put your original flake attributes here.
      };

      systems = [ "x86_64-linux" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # we can't use a simple overrideattrs because of some incompatibility
        # with buildGoModule. see https://github.com/NixOS/nixpkgs/issues/86349
        packages.miniflux = let
          version = "unshittify-a4c4ba7";
          src = pkgs.fetchFromGitHub {
            owner = "Unshittify";
            repo = "miniflux";
            rev = "a4c4ba7b870e7276018f02c1a4a6c09956e8d877";
            hash = "sha256-8/xTBPnQJydszlLLhdN1RjL/N8ASfK8VJehvM8vZdVA=";
          };
          buildInputs = [ pkgs.leptonica pkgs.tesseract ];
          # skip client tests as they require network access
          # skip TTL tests, broken by the unshittify fork
          checkFlags = [ "-skip=TestClient" "-skip=TestParseFeedWithTTL"];
        in
          pkgs.miniflux.override {
            buildGoModule = args: pkgs.buildGoModule ( args // {
              inherit src version buildInputs checkFlags;
              vendorHash = "sha256-l625YDJ1xQto0z9KKSc+NQUNVL+cbKXwoNK2MFIKNMs=";
            });
          };

        packages.nitter = pkgs.nitter.overrideAttrs (old: {
          version = "unshittify-6deae3b";
          src = pkgs.fetchFromGitHub {
            owner = "Unshittify";
            repo = "nitter";
            rev = "4ee4499d0dfe7fe285518634e08f269c51068a89";
            hash = "sha256-ZRJks5gweIQmPQqA98ZcI5ksKVVaUuttos+6yQfQ5HQ=";
          };
        });

        # nitter also has twitter_oauth.sh, but it doesn't take username & password on stdin.
        packages.nitter-get-token = pkgs.stdenv.mkDerivation {
          name = "nitter-get-token";

          propagatedBuildInputs = [
            (pkgs.python3.withPackages (pythonPackages: with pythonPackages; [
              requests
            ]))
          ];

          dontUnpack = true;
          installPhase = "install -Dm755 ${./scripts/nitter-get-token.py} $out/bin/nitter-get-token";
        };
      };
    };
}

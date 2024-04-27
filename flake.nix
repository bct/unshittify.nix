{
  description = "miniflux.nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
          version = "unshittify-b4ad45b";
          src = pkgs.fetchFromGitHub {
            owner = "Unshittify";
            repo = "nitter";
            rev = "b4ad45bd798314238977d8b7c3335a90c327cc37";
            hash = "sha256-78UAz43F5N5NxO6KOHiLLglOVZyYDSjPYIfGQ5mabS4=";
          };
        });
      };
    };
}

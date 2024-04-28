{ inputs, withSystem, ... }: {
  imports = [
    inputs.flake-containers.flakeModule
    inputs.flake-root.flakeModule
  ];

  flake-containers = {
    enable = true;
    containers = {
      server = {
        # volumes = [ "/tmp" ];
        # volumes-ro = [ "/tmp" ];

        configuration = { pkgs, lib, ... }: {
          # Network configuration.
          networking.useDHCP = false;
          networking.firewall.allowedTCPPorts = [ 8080 8081 ];

          services.miniflux = {
            enable = true;
            package = withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }:
              config.packages.miniflux
            );
            config = {
              LISTEN_ADDR = "0.0.0.0:8081";
            };
            adminCredentialsFile = pkgs.writeText "miniflux-admin-credentials.env" ''
              ADMIN_USERNAME=admin
              ADMIN_PASSWORD=miniflux
            '';
          };

          services.nitter = {
            enable = true;
            package = withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }:
              config.packages.nitter
            );
            guestAccounts = pkgs.writeText "nitter-guest-accounts.jsonl" "";
          };

          system.stateVersion = "24.05";
        };
      };
    };
  };
}

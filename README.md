## Launching the config in a container

    sudo nix run .#server-up

You can now visit:
- nitter: http://server:8080/
- miniflux: http://server:8081/

This is useful for checking that everything boots, but you can't use it directly
because it doesn't include Twitter OAuth credentials.

## Obtaining Twitter OAuth credentials

    nix run .#nitter-get-token

This will prompt you for your Twitter username and password, and write out a
file `guest_accounts.jsonl`.

## Using this flake on NixOS

    services.miniflux = {
      enable = true;
      package = inputs.unshittify.packages.x86_64-linux.miniflux;
      config = {
        LISTEN_ADDR = "0.0.0.0:8081";

        # don't stop looking at a feed just because it has failed in the past
        POLLING_PARSING_ERROR_LIMIT = "0";

        POLLING_FREQUENCY = "5";
        SCHEDULER_ROUND_ROBIN_MIN_INTERVAL = "5";
        BATCH_SIZE = "25";
        WORKER_POOL_SIZE = "1";
      };
      adminCredentialsFile = config.age.secrets.miniflux-admin-credentials.path;
    };

    services.nitter = {
      enable = true;
      package = inputs.unshittify.packages.x86_64-linux.nitter;
      guestAccounts = config.age.secrets.nitter-guest-accounts.path;
      server.port = 8080;
      server.hostname = "your-hostname:8080";
    };

If you're not using nixos-unstable you also need:

    disabledModules = [ "services/misc/nitter.nix" ];
    imports = [
      "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/nitter.nix"
    ];

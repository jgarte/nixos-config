{ config, pkgs, lib, options, modulesPath }:

let
  path = ./overlay;
  content = builtins.readDir path;
in {
  nix = {
    # For interactive usage
    nixPath = [
      "nixpkgs=${config.attributes.paths.nixpkgs.local}"
      "nixpkgs-overlays=/etc/nixos/pkgs/overlay"
      "nixos-config=/etc/nixos/configuration.nix"
      "home-manager=${config.attributes.paths.home-manager}"
    ];
    useSandbox = true;
    readOnlyStore = true;
    requireSignedBinaryCaches = true;
    binaryCachePublicKeys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    binaryCaches = [ "https://cache.nixos.org" ];
    extraOptions = ''
      auto-optimise-store = true
      keep-outputs = true
      keep-derivations = true
      http-connections = 10
    '';
  };

  nixpkgs = {
    config = {
      packageOverrides = pkgs: {
        litecliWorking = import (fetchTarball
          "${config.attributes.paths.nixpkgs.archive}f8a50fcca314e03feafcc15039f91fb829292fb1.tar.gz")
            { config = config.nixpkgs.config; };
        mypgWorking = import (fetchTarball
          "${config.attributes.paths.nixpkgs.archive}69c21be86e9f9f9eaba46e66aacffe550d23e0d7.tar.gz")
            { config = config.nixpkgs.config; };
        hpWorking = import (fetchTarball
          "${config.attributes.paths.nixpkgs.archive}f0b49c4d10c86497e04a2b707134a8d7e2198783.tar.gz")
            { config = config.nixpkgs.config; };
        ocrmypdfWorking = import (fetchTarball
          "${config.attributes.paths.nixpkgs.archive}352239e24a7da18f4eb22993cd05e8535d6b01a5.tar.gz")
            { config = config.nixpkgs.config; };
        mpsytWorking = import (fetchTarball
          "${config.attributes.paths.nixpkgs.archive}4cd2cb43fb3a87f48c1e10bb65aee99d8f24cb9d.tar.gz")
            { config = config.nixpkgs.config; };
        bukuWorking = import (fetchTarball
          "${config.attributes.paths.nixpkgs.archive}471869c9185fb610e67940a701eb13b1cfb335a4.tar.gz")
            { config = config.nixpkgs.config; };
      };
    };
    overlays = [
      (import (builtins.fetchTarball { url = "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz"; }))
    ] ++ map (n: import (path + ("/" + n)))
      (builtins.filter (n: builtins.match ".*\\.nix" n != null || builtins.pathExists (path + ("/" + n + "/default.nix")))
        (lib.attrNames content));
  };

  systemd.services.nix-daemon = {
    environment.TMPDIR = "/tmp/buildroot";
    preStart = ''
      mkdir -p /tmp/buildroot
    '';
  };
}

{ config, lib, pkgs, ... }:
with lib;

let cfg = config.custom.dev.golang;
in {
  options = {
    custom.dev.golang = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Golang dev infrastructure.";
      };
      srcTools.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable tools for working with source code.";
      };
      infraTools.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable infrastructure-related rools (packaging, etc.).";
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable && cfg.srcTools.enable) {
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [
          # TODO: wait for/find/dismiss github.com/davecheney/graphpkg in nixpkgs
          # TODO: wait for/find/dismiss github.com/davecheney/prdeps in nixpkgs
          # TODO: wait for/find/dismiss github.com/motemen/gore in nixpkgs
          # TODO: wait for/find/dismiss github.com/stretchr/gorc in nixpkgs
          # TODO: wait for/find/dismiss gitlab.com/opennota/check in nixpkgs
          # TODO: wait for/find/dismiss godoctor in nixpkgs
          # TODO: wait for/find/dismiss gomvpkg in nixpkgs
          # TODO: wait for/find/dismiss unbed in nixpkgs
          # asmfmt # FIXME: try to solve problem with priorities (with gotools)
          # gocode
          deadcode
          errcheck
          go-check
          go-langserver
          go-tools
          gocode-gomod
          goconst
          goconvey
          gocyclo
          godef
          gogetdoc
          golint
          gometalinter
          gomodifytags
          gosec
          gotags
          gotools
          govers
          iferr
          impl
          ineffassign
          interfacer
          maligned
          manul
          reftools
          unconvert
        ];
      };
    })
    (mkIf (cfg.enable && cfg.infraTools.enable) {
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [
          dep
          dep2nix
          glide
          go
          go2nix
          vgo2nix
        ];
      };
    })
  ];
}
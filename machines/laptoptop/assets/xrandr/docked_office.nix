{ config, inputs, lib, pkgs, ... }:
with import ../../../../modules/wmutil.nix { inherit config inputs lib pkgs; };
with import ../../../../modules/util.nix { inherit config inputs lib pkgs; };

let
  profileName = "docked-office";
  user = config.attributes.mainUser.name;
in {
  nixpkgs.config.packageOverrides = _: rec {
    "rescreen-${profileName}-i3" = mkShellScriptWithDeps "rescreen-${profileName}-i3" (with pkgs; [ i3 ]) ''
      i3-msg --quiet "${mvWorkspacesI3Cmd config.wmCommon.workspaces "primary" "DP-2"}${
        mvWorkspacesI3Cmd config.wmCommon.workspaces "secondary" "DP-3"
      }${mvWorkspacesI3Cmd config.wmCommon.workspaces "tertiary" config.attributes.hardware.monitors.internalHead.name}"
    '';
  };
  home-manager.users.${user} = {
    home.packages = [ pkgs."rescreen-${profileName}-i3" ];
    programs.autorandr = {
      profiles = {
        "${profileName}" = {
          fingerprint = {
            DP-2 =
              "00ffffffffffff0009d12b8001010101211d0104a53c22783a4825a756529c270f5054a56b80d1c0b300a9c08180810081c001010101023a801871382d40582c450056502100001e000000ff0045544e384b3032303531534c30000000fd00324c1e5311010a202020202020000000fc0042656e5120424c323738300a2001b302031cf14f901f041303120211011406071516052309070783010000023a801871382d40582c450056502100001f011d8018711c1620582c250056502100009f011d007251d01e206e28550056502100001e8c0ad08a20e02d10103e9600565021000018000000000000000000000000000000000000000000000000000000d1";
            DP-3 =
              "00ffffffffffff0009d12b8001010101211d0104a53c22783a4825a756529c270f5054a56b80d1c0b300a9c08180810081c001010101023a801871382d40582c450056502100001e000000ff0045544e384b3032303731534c30000000fd00324c1e5311010a202020202020000000fc0042656e5120424c323738300a2001b102031cf14f901f041303120211011406071516052309070783010000023a801871382d40582c450056502100001f011d8018711c1620582c250056502100009f011d007251d01e206e28550056502100001e8c0ad08a20e02d10103e9600565021000018000000000000000000000000000000000000000000000000000000d1";
            "${config.attributes.hardware.monitors.internalHead.name}" =
              config.attributes.hardware.monitors.internalHead.edid;
          };
          config = {
            DP-2 = {
              enable = true;
              crtc = 1;
              position = "0x0";
              mode = "1920x1080";
              gamma = config.custom.video.gamma;
              rate = config.custom.video.rate;
            };
            DP-3 = {
              enable = true;
              crtc = 2;
              position = "1366x1080";
              mode = "1920x1080";
              gamma = config.custom.video.gamma;
              rate = config.custom.video.rate;
            } // lib.optionalAttrs (config.custom.video.rotateSecondaryHead) { rotate = config.custom.video.rotation; };
            "${config.attributes.hardware.monitors.internalHead.name}" = {
              enable = true;
              primary = true;
              position = "0x1080";
              mode = config.attributes.hardware.monitors.internalHead.resolution;
              gamma = config.custom.video.gamma;
              rate = config.custom.video.rate;
            };
          };
          hooks.postswitch = "rescreen-${profileName}-i3";
        };
      };
    };
  };
}

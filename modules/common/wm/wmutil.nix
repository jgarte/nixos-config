{ config, lib, pkgs, ... }:
with import ../../util.nix { inherit config lib pkgs; };

rec {
  dmenu_runapps = writeShellScriptBinWithDeps "dmenu_runapps"
    (with pkgs; [ coreutils dmenu haskellPackages.yeganesh j4-dmenu-desktop ]) ''
      j4-dmenu-desktop --display-binary --dmenu="(cat ; (stest -flx $(echo $PATH | tr : ' ') | sort -u)) | \
        yeganesh -- -i -l 15 -fn '${config.wmCommon.fonts.dmenu}'"
    '';
  dmenu_select_windows = writeShellScriptBinWithDeps "dmenu_select_windows" (with pkgs; [ coreutils dmenu wmctrl ]) ''
    wmctrl -a $(wmctrl -l | cut -d" " -f5- | dmenu -i -l 15 -fn '${config.wmCommon.fonts.dmenu}')
  '';
  toHaskellBool = v: builtins.replaceStrings [ "true" "false" ] [ "True" "False" ] (lib.trivial.boolToString v);
  mkKeysXmonadSpawn = keys: indent:
    "${
      lib.concatStringsSep "${mkNewlineAndIndent indent}, " (lib.mapAttrsToList (key: meta:
        ''
          "${key}" ~> spawn "${meta.cmd}"${
            if lib.hasAttrByPath [ "desktop" ] meta then " >> showWSOnProperScreen \"${meta.desktop}\"" else ""
          }'') keys)
    }${mkIndent indent}";
  mkKeysXmonadRaw = keys: indent:
    "${
      lib.concatStringsSep "${mkNewlineAndIndent indent}, " (lib.mapAttrsToList (key: cmd: ''"${key}" ~> ${cmd}'') keys)
    }${mkIndent indent}";
  convertKeyXmonad = key: if lib.hasPrefix "F" key then "<${key}>" else "${key}";
  mkWorkspacesXmonad = wss: indent:
    "${
      lib.concatStringsSep "${mkNewlineAndIndent indent}, " (lib.mapAttrsToList
        (ws: meta: ''("${ws}", Just "${convertKeyXmonad meta.key}", ${toHaskellBool meta.transient})'') wss)
    }${mkIndent indent}";
  convertKeyI3 = key:
    let
      keysyms = {
        "`" = "grave";
        "Esc" = "Escape";
      };
    in if builtins.hasAttr key keysyms then builtins.getAttr key keysyms else key;
  mkWorkspacesI3 = wss:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (ws: meta: ''
      set $ws_${ws} ${builtins.toString meta.index}: ${ws}
      bindsym $mod+${convertKeyI3 meta.key} workspace $ws_${ws}
      bindsym $mod+Shift+${convertKeyI3 meta.key} move container to workspace $ws_${ws}
    '') wss);
}
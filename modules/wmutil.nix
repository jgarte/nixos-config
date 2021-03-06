{ config, inputs, lib, pkgs, ... }:
with import ./util.nix { inherit config inputs lib pkgs; };

let
  keySepI3 = "+";
  keysymsI3 = {
    "." = "period";
    "Esc" = "Escape";
    "`" = "grave";
  };
  keysymsXmonad = {
    "F1" = "<F1>";
    "F2" = "<F2>";
    "F3" = "<F3>";
    "F4" = "<F4>";
    "F5" = "<F5>";
    "F6" = "<F6>";
    "F7" = "<F7>";
    "F8" = "<F8>";
    "F9" = "<F9>";
    "F10" = "<F10>";
    "F11" = "<F11>";
    "F12" = "<F12>";
  };
  windowCriteriaPlaceholdersI3 = {
    "class" = ''class="^@$"'';
    "title" = ''title=".*@.*"'';
    "role" = ''role="^@$"'';
    "instance" = ''instance="^@$"'';
  };
in rec {
  enumerateWorkspaces = wsdata: lib.zipLists (lib.imap1 (i: v: i) wsdata) wsdata;
  getWorkspacesByType = wsdata: type: (lib.groupBy (x: x.snd.type) wsdata)."${type}";
  toHaskellBool = v: builtins.replaceStrings [ "true" "false" ] [ "True" "False" ] (lib.trivial.boolToString v);
  mkKeysymXmonad = key: if builtins.hasAttr key keysymsXmonad then builtins.getAttr key keysymsXmonad else key;
  mkKeysXmonadSpawn = keys: indent: # FIXME: update logic (presumably broken)
    "${
      lib.concatStringsSep "${mkNewlineAndIndent indent}, " (lib.mapAttrsToList (key: meta:
        ''
          "${key}" ~> spawn "${meta.cmd}"${
            if lib.hasAttrByPath [ "desktop" ] meta then " >> showWSOnProperScreen \"${meta.desktop}\"" else ""
          }'') keys)
    }${mkIndent indent}";
  mkKeysXmonadRaw = keys: indent: # FIXME: update logic (presumably broken)
    "${
      lib.concatStringsSep "${mkNewlineAndIndent indent}, " (lib.mapAttrsToList (key: cmd: ''"${key}" ~> ${cmd}'') keys)
    }${mkIndent indent}";
  mkWorkspacesXmonad = wss: indent: # FIXME: update logic (presumably broken)
    "${
      lib.concatStringsSep "${mkNewlineAndIndent indent}, " (lib.mapAttrsToList
        (ws: meta: ''("${ws}", Just "${convertKeyXmonad meta.key}", ${toHaskellBool meta.transient})'') wss)
    }${mkIndent indent}";
  mkWindowCriteriaI3 = criteria:
    "[${
      lib.concatStringsSep " " (lib.remove "" (lib.mapAttrsToList (k: v:
        if builtins.hasAttr k criteria then
          builtins.replaceStrings [ "@" ]
          [ (if k == "title" then builtins.replaceStrings [ " " ] [ ".*" ] criteria."${k}" else criteria."${k}") ] v
        else
          "") windowCriteriaPlaceholdersI3))
    }]";
  mkKeyI3 = keys:
    lib.concatStringsSep keySepI3
    (lib.forEach keys (k: if builtins.hasAttr k keysymsI3 then builtins.getAttr k keysymsI3 else k));
  getWorkspaceByNameI3 = wsdata: name:
    let ws = builtins.head (builtins.filter (ws: ws.snd.name == name) (enumerateWorkspaces wsdata));
    in "${builtins.toString ws.fst}: ${ws.snd.name}";
  mkWorkspacesI3 = wsdata: mod:
    lib.concatStringsSep "\n" (lib.forEach (enumerateWorkspaces wsdata) (elt: ''
      bindsym ${mod}+${mkKeyI3 elt.snd.key} workspace ${builtins.toString elt.fst}: ${elt.snd.name}
      bindsym ${mod}+Shift+${mkKeyI3 elt.snd.key} move container to workspace ${
        builtins.toString elt.fst
      }: ${elt.snd.name}
    ''));
  mvWorkspacesI3Cmd = wsdata: type: head:
    "${lib.concatStringsSep " " (lib.forEach (getWorkspacesByType (enumerateWorkspaces wsdata) type) (ws:
      "workspace --no-auto-back-and-forth ${
        builtins.toString ws.fst
      }: ${ws.snd.name}; move workspace to output ${head}; "))}";
  setWorkspacesLayoutI3 = wsdata: type: layout:
    "${lib.concatStringsSep " " (lib.forEach (getWorkspacesByType (enumerateWorkspaces wsdata) type) (ws:
      "workspace --no-auto-back-and-forth ${
        builtins.toString ws.fst
      }: ${ws.snd.name}; layout ${layout}; "))}";
  mkKeybindingI3 = workspaces: meta:
    builtins.concatStringsSep " " ([ "bindsym" (mkKeyI3 meta.key) ]
      ++ lib.optionals (!maybeAttrIsBool "raw" meta) [ "exec" ]
      ++ lib.optionals (maybeAttrIsBool "transient" meta) [ "--no-startup-id" ] ++ [
        (builtins.concatStringsSep "; " (lib.optionals (builtins.hasAttr "cmd" meta) [ meta.cmd ]
          ++ lib.optionals (builtins.hasAttr "desktop" meta)
          [ "workspace ${getWorkspaceByNameI3 workspaces meta.desktop}" ]
          ++ lib.optionals (!maybeAttrIsBool "sticky" meta && meta.mode != "root") [ ''mode "default"'' ]))
      ]);
  mkKeybindingsI3 = workspaces: keys: modeBindings: exitBindings:
    let
      prefixedModesMeta = lib.filterAttrs (k: _: k != "root") (lib.groupBy (x: x.mode) keys);
      rootModeBindings = (lib.filterAttrs (k: _: k == "root") (lib.groupBy (x: x.mode) keys)).root;
    in ''
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (mode: bindings: ''
        mode "${mode}" {
          ${
            lib.concatStringsSep (mkNewlineAndIndent 2) (lib.forEach (bindings
              ++ lib.optionals (!lib.hasPrefix "Passthrough" mode) (map (b: {
                key = b;
                mode = "${mode}";
                raw = true;
              }) exitBindings)) (x: mkKeybindingI3 workspaces x))
          }
        }
      '') prefixedModesMeta)}
      ${lib.concatStringsSep "\n" (lib.forEach rootModeBindings (x: mkKeybindingI3 workspaces x))}

      ${lib.concatStringsSep "\n"
      (lib.mapAttrsToList (mode: key: ''bindsym ${mkKeyI3 key} mode "${mode}"'') modeBindings)}
    '';
  mkKeybindingsFocusI3 = rules:
    lib.concatStringsSep "\n" (lib.forEach (builtins.filter (r: builtins.hasAttr "focus" r) rules)
      (r: "bindsym ${mkKeyI3 r.focus} ${mkWindowCriteriaI3 r} focus"));
  mkWindowRulesFloatI3 = rules:
    lib.concatStringsSep "\n" (lib.forEach (builtins.filter (r: builtins.hasAttr "float" r) rules) (r:
      "for_window ${mkWindowCriteriaI3 r} floating ${
        if r.float then
          "toggle${
            if builtins.hasAttr "resize" r then
              "; ${lib.concatStringsSep "; " (lib.forEach r.resize (d: "resize ${d}"))}"
            else
              ""
          }"
        else
          "disable"
      }"));
  mkPlacementRulesI3 = wsdata: rules:
    lib.concatStringsSep "\n" (lib.forEach (builtins.filter (r: builtins.hasAttr "desktop" r) rules) (r:
      "for_window ${mkWindowCriteriaI3 r} move to workspace ${getWorkspaceByNameI3 wsdata r.desktop}${
        if (builtins.hasAttr "activate" r && r.activate == true) then
          "; workspace ${getWorkspaceByNameI3 wsdata r.desktop}"
        else
          ""
      }"));
}

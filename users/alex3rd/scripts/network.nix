{config, pkgs, lib, ...}:

let
    currentUser = "alex3rd";
    previousUser = "octocat";
    sedPlaceholderChar = "_";
    # TODO: generalize and find way to extract to module/lib
    hostTraitsIpOutputPosition = 4;
    prettifyValue = value:
       if builtins.typeOf value == "int" then
          builtins.toString value
       else if builtins.typeOf value == "bool" then
          if value == true then "✓"
          else "✗"
       else builtins.toString value;
    setToBashKeyValue = set: keyname: valueSep: omitKey:
        let
            keyValue = set.${keyname};
            strippedSet = builtins.removeAttrs set [keyname];
        in
            "[\"" + keyValue + "\"]=\"" +
                  (builtins.concatStringsSep valueSep
                            (pkgs.stdenv.lib.mapAttrsToList
                                  (key: value: if omitKey then "${prettifyValue value}"
                                                          else "${key}:${sedPlaceholderChar}${prettifyValue value}")
                                  strippedSet)) + "\"";
    unfoldListOfSetsByAttr = list: attr:
        let
            v = if builtins.length list == 0 then {${attr} = [];} else builtins.head list;
        in
        (map (elem: v // {${attr} = elem;} ) v.${attr}) ++
             (if builtins.length list == 0 then [] else (unfoldListOfSetsByAttr (builtins.tail list) attr));
    listOfSetsToShellHashtable = list: keyname: tablename: omitKey:
        "declare -A ${tablename}" + "\n" +
        "${tablename}=(" + "\n" +
            (builtins.concatStringsSep
                "\n" (map (attrs: setToBashKeyValue attrs keyname " " omitKey) list))
        +"\n" + ")";
in
{
    config = {
        nixpkgs.config.packageOverrides = super: {
            rofi_ssh_custom_user = pkgs.writeShellScriptBin "rofi_ssh_custom_user" ''
                # TODO: provide freeform option or predefined list on Nix level
                USERS=(
                  "root"
                  "${currentUser}"
                  "${previousUser}"
                )

                ask_for_user() {
                    for i in "''${USERS[@]}"
                    do
                        echo "$i"
                    done
                }

                main() {
                    USER=$( (ask_for_user) | ${pkgs.rofi}/bin/rofi -dmenu -p "User" )
                    if [ ! -n "$USER" ]; then
                        exit 1
                    fi
                    HOST=$( cat /etc/hosts | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.rofi}/bin/rofi -dmenu -p "Host" )
                    if [ -n "$HOST" ]; then
                        ${pkgs.tmux}/bin/tmux new-window "${pkgs.eternal-terminal}/bin/et $USER@$HOST"
                    fi
                }

                main

                exit 0
            '';
            rofi_webjumps = pkgs.writeShellScriptBin "rofi_webjumps" ''
                ${listOfSetsToShellHashtable (config.job.webjumps ++ config.misc.webjumps) "url" "WEBJUMPS" true}

                list_webjumps() {
                    for i in "''${!WEBJUMPS[@]}"
                    do
                        echo "$i"
                    done
                }

                main() {
                    WEBJUMP=$( (list_webjumps) | ${pkgs.rofi}/bin/rofi -dmenu -p "Jump to" )
                    if [ -n "$WEBJUMP" ]; then
                        ''${WEBJUMPS[$WEBJUMP]} "$WEBJUMP"
                    fi
                }

                main

                exit 0
            '';
            rofi_searchengines_prompt = pkgs.writeShellScriptBin "rofi_searchengines_prompt" ''
                ${listOfSetsToShellHashtable (config.misc.searchEngines) "engine" "SEARCHENGINES" true}

                list_searchengines() {
                    INDEX=1
                    for i in "''${!SEARCHENGINES[@]}"
                    do
                        echo "$INDEX $i"
                        (( INDEX++ ))
                    done
                }

                main() {
                    SELECTED_ENGINE=$( (list_searchengines) | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Search" | ${pkgs.gawk}/bin/awk '{print $2}')
                    if [ ! -n "$SELECTED_ENGINE" ]; then
                        exit 1
                    fi
                    QUERY=$( (echo ) | rofi  -dmenu -matching fuzzy -location 0 -p "Query" )
                    if [ -n "$QUERY" ]; then
                        URL="''${SEARCHENGINES[$SELECTED_ENGINE]}$QUERY"
                        ${config.misc.defaultBrowserCmd} "$URL"
                    fi
                }

                main

                exit 0
            '';
            rofi_searchengines_selection = pkgs.writeShellScriptBin "rofi_searchengines_selection" ''
                ${listOfSetsToShellHashtable (config.misc.searchEngines) "engine" "SEARCHENGINES" true}

                list_searchengines() {
                    INDEX=1
                    for i in "''${!SEARCHENGINES[@]}"
                    do
                        echo "$INDEX $i"
                        (( INDEX++ ))
                    done
                }

                main() {
                    SELECTED_ENGINE=$( (list_searchengines) | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Search" | ${pkgs.gawk}/bin/awk '{print $2}')
                    if [ ! -n "$SELECTED_ENGINE" ]; then
                        exit 1
                    fi
                    QUERY=$(${pkgs.xsel}/bin/xsel -o)
                    if [ -n "$QUERY" ]; then
                        URL="''${SEARCHENGINES[$SELECTED_ENGINE]}$QUERY"
                        ${config.misc.defaultBrowserCmd} "$URL"
                    fi
                }

                main

                exit 0
            '';
            rofi_extra_hosts_traits = pkgs.writeShellScriptBin "rofi_extra_hosts_traits" ''
                ${listOfSetsToShellHashtable
                    (unfoldListOfSetsByAttr
                        (config.job.extraHosts ++ config.misc.extraHosts)
                        "hostNames")
                    "hostNames"
                    "EXTRA_HOSTS"
                    false}

                list_extra_hosts() {
                    for i in "''${!EXTRA_HOSTS[@]}"
                    do
                        echo "$i"
                    done
                }

                main() {
                    SELECTED_HOST=$( (list_extra_hosts) | ${pkgs.rofi}/bin/rofi -dmenu -p "Select" )
                    if [ -n "$SELECTED_HOST" ]; then
                        RESULT="$SELECTED_HOST ''${EXTRA_HOSTS[$SELECTED_HOST]}"
                        RESULT_NEWLINES=$(echo $RESULT | ${pkgs.gnused}/bin/sed 's/ /\n/g' | \
                                                         ${pkgs.gnused}/bin/sed 's/${sedPlaceholderChar}/ /g')
                        IP=$(echo $RESULT | ${pkgs.gawk}/bin/awk '{print ${"$" + builtins.toString hostTraitsIpOutputPosition}}' | \
                                            ${pkgs.gnused}/bin/sed 's/${sedPlaceholderChar}/ /g')
                        echo "$RESULT_NEWLINES" > /tmp/extra_host
                        echo "$IP" | ${pkgs.gawk}/bin/awk '{print $2}'| tr -d '\n' | ${pkgs.xsel}/bin/xsel -i --clipboard
                        ${pkgs.yad}/bin/yad --filename /tmp/extra_host --text-info
                        rm /tmp/extra_host
                    fi
                }

                main

                exit 0
            '';
            rofi_jnettop = pkgs.writeShellScriptBin "rofi_jnettop" ''
                main() {
                    HOST=$( cat /etc/hosts | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.rofi}/bin/rofi -dmenu -p "Host" )
                    if [ -n "$HOST" ]; then
                        ${pkgs.tmux}/bin/tmux new-window "${pkgs.eternal-terminal}/bin/et \
                        ${config.job.infra.defaultRemoteUser}@$HOST -c 'jnettop'"
                    fi
                }

                main

                exit 0
            '';
        };
    };
}

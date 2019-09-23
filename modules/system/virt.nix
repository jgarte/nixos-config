{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.virtualization;
  dnsContainerName = "docker_dns";
  dlint = pkgs.writeShellScriptBin "dlint" ''
    if [ -z $1 ]; then
        echo "Dockerfile missing"
        exit 1
    fi

    ${pkgs.docker}/bin/docker run --rm -i -v $(realpath $1):/Dockerfile redcoolbeans/dockerlint
  '';
  hadolintd = pkgs.writeShellScriptBin "hadolintd" ''
    if [ -z $1 ]; then
        echo "Dockerfile missing"
        exit 1
    fi

    # TODO: add options such as help displaying
    # TODO: templatize yaml config (in nix)
    # see github for all the references
    ${pkgs.docker}/bin/docker run --rm -i -v $(realpath $1):/tmp/Dockerfile hadolint/hadolint hadolint /tmp/Dockerfile
  '';
  docker-machine-export = pkgs.writeShellScriptBin "docker-machine-export" ''
    if [ -z "$1" ]; then
        echo "Usage: machine-export.sh MACHINE_NAME"
        echo ""
        echo "Exports the specified docker-machine to a MACHINE_NAME.zip file"
        echo "Note: This script requires you to have the same \$MACHINE_STORAGE_PATH/certs available on all host systems"
        exit 0
    fi

    machine_name=$1

    ${pkgs.docker-machine}/bin/docker-machine status $machine_name 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
        echo "No such machine found"
        exit 1
    fi

    set -e

    MACHINE_STORAGE_PATH="$(MACHINE_STORAGE_PATH:-"$HOME/.docker/machine")"
    machine_path="$MACHINE_STORAGE_PATH/machines/$machine_name"
    tmp_path="/tmp/machine-export-$(date +%s%3)"

    # copy to /tmp and strip out $MACHINE_STORAGE_PATH
    ${pkgs.coreutils}/bin/mkdir -p $tmp_path
    ${pkgs.coreutils}/bin/cp -r "$machine_path" "$tmp_path"
    ${pkgs.perl}/bin/perl -pi -e "s|$MACHINE_STORAGE_PATH|__MACHINE__STORAGE_PATH__|g" $tmp_path/$machine_name/config.json

    # create zip
    ${pkgs.coreutils}/bin/rm -f "$machine_name.zip"
    ${pkgs.zip}/bin/zip -rj "$machine_name.zip" "$tmp_path/$machine_name" > /dev/null

    echo "Exported machine to $machine_name.zip"

    # cleanup
    ${pkgs.coreutils}/bin/rm -rf $tmp_path
  '';
  docker-machine-import = pkgs.writeShellScriptBin "docker-machine-import" ''
    set -e

    if [ -z "$1" ]; then
        echo "Usage: docker-machine-import.sh MACHINE_NAME.zip"
        echo ""
        echo "Imports an exported machine from a MACHINE_NAME.zip file"
        echo "Note: This script requires you to have the same \$MACHINE_STORAGE_PATH/certs available on all host systems"
        exit 0
    fi

    machine_archive="$1"
    machine_name="$machine_archive/.zip/"
    MACHINE_STORAGE_PATH="$(MACHINE_STORAGE_PATH:-"$HOME/.docker/machine")"
    machine_path="$MACHINE_STORAGE_PATH/machines/$machine_name"

    if [ -d "$machine_path" ]; then
        echo "$machine_name already exists"
        exit 1
    fi

    ${pkgs.coreutils}/bin/rm -rf "$machine_name"
    ${pkgs.unzip}/bin/unzip "$machine_archive" -d "$machine_name" > /dev/null
    ${pkgs.perl}/bin/perl -pi -e "s|__MACHINE__STORAGE_PATH__|$MACHINE_STORAGE_PATH|g" $machine_name/config.json
    ${pkgs.coreutils}/bin/mv "$machine_name" "$MACHINE_STORAGE_PATH/machines"

    echo "Imported $machine_name to docker-machine ($machine_path)"
  '';
  docker_containers_traits = pkgs.writeShellScriptBin "docker_containers_traits" ''
    declare -A CONTAINER_TRAITS

    CONTAINER_TRAITS=(
      ["name"]='{{index (split .Name "/") 1}}'
      ["created"]='{{.Created}}'
      ["path + args"]='{{.Path}} :: {{.Args}}'
      ["stats"]='{{println .State.Status}} {{.State.StartedAt}} <--> {{println .State.FinishedAt}} restarts: {{.RestartCount}}'
      ["ports"]='{{range $port, $mappings :=.NetworkSettings.Ports}}{{$port}} --> {{range $ifnum, $ifdef:=$mappings}}{{$ifnum}}) {{$ifdef.HostIp}}:{{$ifdef.HostPort}}{{end}}{{end}}'
      ["mounts"]='{{range $i, $mountpoint :=.Mounts}}{{with $mountpoint}}{{.Type}} {{.Destination}} --> {{.Source}} RW:{{.RW}}{{end}}{{end}}'
      ["env"]='{{range $entry :=.Config.Env}}{{with $entry}}{{println .}}{{end}}{{end}}'
      ["cmd"]='{{index .Config.Cmd 0}}'
      ["image"]='{{.Config.Image}}'
      ["volumes"]='{{range $vol, $data :=.Config.Volumes}}{{$vol}}: {{$data}}{{end}}'
      ["entrypoint"]='{{index .Config.Entrypoint 0}}'
      ["labels"]='{{range $name, $value :=.Config.Labels}}{{$name}}: {{println $value}}{{end}}'
      ["net: ip"]='{{range $network, $settings :=.NetworkSettings.Networks}}{{$settings.IPAddress}}{{end}}'
      ["net: gateway"]='{{range $network, $settings :=.NetworkSettings.Networks}}{{$settings.Gateway}}{{end}}'
      ["net: names"]='{{range $network, $settings :=.NetworkSettings.Networks}}{{$network}}/{{println $settings.Aliases}}{{end}}'
    )

    CONTAINER_STATUSES=(
      "alive"
      "all"
    )

    function show_list() {
        contents=("$@")
        for i in "''${contents[@]}";
        do
            echo "$i"
        done
    }

    function show_mapping_keys() {
        eval "declare -A contents="''${1#*=}
        for i in "''${!contents[@]}";
        do
            echo "$i"
        done
    }

    main() {
        HOST=$( cat /etc/hosts | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.coreutils}/bin/uniq | ${pkgs.rofi}/bin/rofi -dmenu -p "Host" )
        if [ ! -z "$HOST" ]; then
            if [ "$HOST" == "localhost" ]; then
                eval $(${pkgs.docker-machine}/bin/docker-machine env -u)
            else
                eval $(${pkgs.docker-machine}/bin/docker-machine env $HOST)
            fi
            CONTAINER_STATUS=$( (show_list "''${CONTAINER_STATUSES[@]}") | ${pkgs.rofi}/bin/rofi -dmenu -p "Status" )
            if [ -z "$CONTAINER_STATUS" ]; then
                exit 1
            fi
            if [ "$CONTAINER_STATUS" == "all" ]; then
                SELECTED_CONTAINER=$( ${pkgs.docker}/bin/docker ps -a --format '{{.Names}}' | ${pkgs.rofi}/bin/rofi -dmenu -p "Container" )
            else
                SELECTED_CONTAINER=$( ${pkgs.docker}/bin/docker ps --format '{{.Names}}' | ${pkgs.rofi}/bin/rofi -dmenu -p "Container" )
            fi
            if [ -n "$SELECTED_CONTAINER" ]; then
                SELECTED_TRAIT=$( (show_mapping_keys "$(declare -p CONTAINER_TRAITS)") | ${pkgs.rofi}/bin/rofi -dmenu -p "Inspect" )
                if [ -n "$SELECTED_TRAIT" ]; then
                    INSPECT_COMMAND="${pkgs.docker}/bin/docker inspect $SELECTED_CONTAINER --format='"''${CONTAINER_TRAITS[$SELECTED_TRAIT]}"'"
                    eval `echo $INSPECT_COMMAND` | tr -d '\n' | ${pkgs.xsel}/bin/xsel -i --clipboard
                    eval `echo $INSPECT_COMMAND` > /tmp/docker_traits
                    ${pkgs.yad}/bin/yad --filename /tmp/docker_traits --text-info
                    rm /tmp/docker_traits
                fi
            fi
        fi
    }

    main

    exit 0
  '';
in {
  options = {
    virtualization = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable virtualization";
      };
      userName = mkOption {
        type = types.str;
        default = "";
      };
      docker.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Docker";
      };
      docker.aux.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Docker auxillary packages";
      };
      docker.storageDriver = mkOption {
        type = types.str;
        default = "overlay2";
        description = "Docker storage driver";
      };
      docker.devdns.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Docker internal DNS service";
      };
      docker.devdns.restartPolicy = mkOption {
        type = types.str;
        default = "unless-stopped";
        description = "DNS service restarting policy. See respective Docker docs for reference.";
      };
      docker.devdns.port = mkOption {
        type = types.str;
        default = "5380";
        description = "Port to bind DNS service on.";
      };
      docker.devdns.autoStart = mkOption {
        default = true;
        type = types.bool;
        description = "Whether DNS service should be started automatically.";
      };
      libvirt.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Libvirt";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      assertions = [{
        assertion = cfg.userName != "";
        message = "virtualization: must provide username.";
      }];
      environment.systemPackages = with pkgs; [
        tigervnc
        vagrant
      ];
    })

    (mkIf (cfg.enable && cfg.docker.enable && cfg.docker.aux.enable) {
      environment.systemPackages = with pkgs; [
        skopeo
      ];
    })

    (mkIf (cfg.enable && cfg.docker.enable) {
      virtualisation.docker = {
        enable = true;
        storageDriver = cfg.docker.storageDriver;
      };

      users.extraUsers."${cfg.userName}".extraGroups = [ "docker" ];

      environment.systemPackages = with pkgs; [
        dlint
        hadolintd
        docker-machine-export
        docker-machine-import
        docker_containers_traits
      ] ++ [
        ctop
        dive
        docker-machine
        docker_compose
        libcgroup
        promoter
      ];
    })

    (mkIf (cfg.enable && cfg.docker.enable && cfg.docker.devdns.enable) {
      systemd.services."docker-devdns" = {
        description = "Dev DNS for docker containers";
        wantedBy = [ (optionalString cfg.docker.devdns.autoStart "multi-user.target") ];
        after = [ "docker.service" "docker.socket" ];
        requires = [ "docker.service" "docker.socket" ];
        script = ''
          ${pkgs.docker}/bin/docker run \
                                    --restart=${cfg.docker.devdns.restartPolicy} \
                                    -p ${cfg.docker.devdns.port}:${cfg.docker.devdns.port} \
                                    --name=${dnsContainerName} \
                                    -v /var/run/docker.sock:/var/run/docker.sock \
                                    -v /etc/resolv.conf:/etc/resolv.conf \
                                    defreitas/dns-proxy-server
        '';
        preStop = "${pkgs.docker}/bin/docker stop ${dnsContainerName}";
        reload = "${pkgs.docker}/bin/docker restart ${dnsContainerName}";
        serviceConfig = {
          ExecStartPre = "-${pkgs.docker}/bin/docker rm -f ${dnsContainerName}";
          ExecStopPost = "-${pkgs.docker}/bin/docker rm -f ${dnsContainerName}";
          TimeoutStartSec = 0;
          TimeoutStopSec = 120;
          Restart = "always";
        };
      };
    })

    (mkIf (cfg.enable && cfg.libvirt.enable) {
      virtualisation.libvirtd = { enable = true; };
      virtualisation.kvmgt.enable = true;

      users.extraUsers."${cfg.userName}".extraGroups = [ "libvirtd" ];

      environment.systemPackages = with pkgs; [
        kvm
        spice
        spice-gtk
        virtmanager
        virtviewer
      ];
    })
  ];
}

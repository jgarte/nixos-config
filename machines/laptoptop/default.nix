{ config, inputs, lib, pkgs, ... }:
with import ../../modules/util.nix { inherit config inputs lib pkgs; };

let
  user = config.attributes.mainUser.name;
  nixpkgs-hplip = import inputs.nixpkgs-16_04_20 ({
    config = config.nixpkgs.config // { allowUnfree = true; };
    localSystem = { system = "x86_64-linux"; };
  });
in {
  imports = [
    ./secrets
    ./assets
    ../../modules
    "${inputs.nixos-hardware}/common/cpu/intel/sandy-bridge"
    "${inputs.nixos-hardware}/common/pc/ssd"
    "${inputs.nixos-hardware}/lenovo/thinkpad/x230"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos-root";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/nixos-boot";
    fsType = "ext2";
  };

  swapDevices = [ ];

  environment.etc.current-configuration.source = ../../.;

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableAllFirmware = true;
    ksm.enable = true;
    sensor.iio.enable = true;
  };

  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
      configurationLimit = 30;
      splashImage = "${inputs.nixos-artwork}/common/grub2-background/grub-nixos-1.png";
    };
    initrd.availableKernelModules = [ "ahci" "ehci_pci" "sdhci_pci" "usb_storage" "xhci_pci" ];
    extraModprobeConfig = ''
      options iwlwifi 11n_disable=1 power_save=1 power_level=2
    '';
    tmpOnTmpfs = true;
    kernelPackages = pkgs.linuxPackages_5_9;
    kernelParams =
      [ "scsi_mod.use_blk_mq=1" "pti=off" "nospectre_v1" "nospectre_v2" "l1tf=off" "nospec_store_bypass_disable" ];
    kernelModules = [ "bfq" "thinkpad_acpi" "thinkpad_hwmon" ];
    kernel.sysctl = {
      "fs.inotify.max_user_instances" = 1024;
      "fs.inotify.max_user_watches" = 1048576;
      "fs.inotify.max_queued_events" = 32768;
      "net.ipv4.ip_default_ttl" = 65;
      "net.ipv4.tcp_sack" = 0;
    };
    supportedFilesystems = [ "ntfs" ];
  };

  console.useXkbConfig = true;

  networking = {
    hostName = "laptoptop";
    hostId = "2ab69157";
    enableIPv6 = false;
    firewall.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    resolvconf = {
      enable = true;
      dnsExtensionMechanism = false;
    };
    wlanInterfaces = { "wlan0" = { device = "wlp3s0"; }; };
    # TODO: consider extracting dichotomy below to module
    networkmanager = {
      enable = true;
      unmanaged = [ "br0" "interface-name:vb-*" "interface-name:vbox*" "interface-name:ve-*" "lo" ];
      wifi = { macAddress = "60:67:20:ec:34:14"; };
    };
    wireless = {
      enable = false;
      driver = "nl80211";
      userControlled.enable = true;
      interfaces = [ "wlan0" ];
    };
    dhcpcd.denyInterfaces = [ "docker*" "virbr*" "br*" ];
    nameservers = [ "77.88.8.8" "77.88.8.1" "8.8.8.8" ];
  };
  users.users.${user}.extraGroups = [ "networkmanager" ];

  environment.shells = with pkgs; [ "${bash}/bin/bash" "${zsh}/bin/zsh" "/run/current-system/sw/bin/zsh" ];

  nix.trustedUsers = [ "root" user ];

  security = {
    sudo.wheelNeedsPassword = false;
    allowUserNamespaces = true;
    allowSimultaneousMultithreading = true;
    lockKernelModules = false;
  };

  time = {
    timeZone = "Europe/Moscow";
    hardwareClockInLocalTime = true;
  };

  services = {
    irqbalance.enable = true;
    chrony.enable = true;
    dbus = { enable = true; };
    earlyoom.enable = true;
    openssh = {
      enable = true;
      allowSFTP = true;
      forwardX11 = false;
    };
    smartd = {
      enable = true;
      notifications = { x11.enable = true; };
    };
    logind.lidSwitchDocked = "suspend";
    journald.extraConfig = ''
      MaxRetentionSec=7day
    '';
    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[ab][!0-9]", ATTR{queue/scheduler}="kyber"

      SUBSYSTEM=="backlight", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
      SUBSYSTEM=="leds", ACTION=="add", KERNEL=="*::kbd_backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/leds/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/%k/brightness"
    '';
    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = "80";
        STOP_CHARGE_THRESH_BAT0 = "90";
        DEVICES_TO_DISABLE_ON_WIFI_CONNECT = "wwan";
        USB_BLACKLIST_PHONE = 1;
      };
    };
    thermald.enable = true;
    acpid.enable = true;
    timesyncd.enable = true;

    xbanish.enable = true;
  };

  systemd.services.acme-localhost.enable = false;

  attributes.hardware.monitors = {
    internalHead.name = "LVDS-1";
    internalHead.edid =
      "00ffffffffffff0006af6c100000000000140104901c10780220e5925554922825505400000001010101010101010101010101010101121b56585000193030203600159c100000180000000f0000000000000000000000000020000000fe0041554f0a202020202020202020000000fe004231323558573031205630200a00ec";
    internalHead.resolution = "1366x768";
  };

  services.xserver = {
    enable = true;
    videoDrivers = [ "modesetting" ];
    useGlamor = true;
    exportConfiguration = true;
    desktopManager = {
      xterm.enable = false;
      gnome3.enable = false;
    };
    displayManager = {
      lightdm = {
        enable = true;
        background = "${inputs.nixos-artwork}/wallpapers/nix-wallpaper-mosaic-blue.png";
        greeters.mini = {
          enable = true;
          user = user;
        };
      };
      gdm.enable = false;
      job = {
        logToFile = true;
        logToJournal = true;
      };
      sessionCommands = ''
        export _JAVA_AWT_WM_NONREPARENTING=1
        ${pkgs.wmname}/bin/wmname LG3D
      '';
    };
    autoRepeatDelay = 200;
    autoRepeatInterval = 40;
    xkbOptions = "caps:none";
    layout = "us,ru";
  };

  attributes.machine.name = "laptoptop";
  attributes.mainUser = {
    name = config.identity.secrets.userName;
    fullName = config.identity.secrets.fullName;
    email = config.identity.secrets.email;
    gpgKeyID = config.identity.secrets.gpgKeyID;
  };

  users.extraUsers.${user} = {
    isNormalUser = true;
    uid = 1000;
    description = config.identity.secrets.fullName;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  job = {
    "14f7646bef".secrets.enable = true;
    "2242184b2c".secrets.enable = true;
    "8a1add5330".secrets.enable = true;
    "b354e944b3".secrets.enable = true;
  };
  dev.secrets.enable = true;

  appearance = {
    colors.zenburn.enable = true;
    emacs = {
      enable = true;
      modeline.telephone = {
        enable = true;
        height = 24;
      };
    };
    fonts = {
      enable = true;
      antialias = true; # NOTE: use `nix-index consolefonts` to search values for `console.font`
      iosevka.enable = true;
    };
    wallpaper = {
      enable = true;
      rootDir = homePrefix "blobs/wallpaper/mongol/winter";
      current = "mongol-winter-govi.jpg";
      wm.enable = true;
    };
    xresources = {
      enable = true;
      wm.enable = true;
    };
  };

  custom.browsers = {
    qutebrowser = {
      enable = true;
      isDefault = true;
      sessions = {
        backup.enable = true;
        saveFrequency = "10min";
        historyLength = 30;
      };
    };
    chromium = {
      enable = true;
      isFallback = true;
      extraOpts = {
        # === Common workstation needs=======
        AudioCaptureAllowed = true;
        VideoCaptureAllowed = true;
        PrintingEnabled = true;
        # ===================================
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        AutoplayAllowed = false;
        BrowserSignin = 0; # Disable browser sign-in
        BuiltInDnsClientEnabled = false;
        DefaultBrowserSettingEnabled = false;
        DefaultGeolocationSetting = 2; # Do not allow any site to track the users' physical location
        DefaultNotificationsSetting = 2; # Do not allow any site to show desktop notifications
        DefaultPluginsSetting = 2; # Block the Flash plugin
        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderSearchURL = "https://duckduckgo.com/"
          + "?kae=d&k1=-1&kc=1&kav=1&kd=-1&kh=1&q={searchTerms}";
        EnableMediaRouter = false;
        MetricsReportingEnabled = false;
        PasswordManagerEnabled = false;
        PromotionalTabsEnabled = false;
        SSLErrorOverrideAllowed = false;
        SafeBrowsingEnabled = false;
        SearchSuggestEnabled = false;
        SigninAllowed = false;
        SpellCheckServiceEnabled = false;
        SpellcheckEnabled = false;
        SyncDisabled = true;
        TranslateEnabled = false;
        ExternalProtocolDialogShowAlwaysOpenCheckbox = true;
      };
    };
  };

  content = {
    ebooks = {
      enable = true;
      wm.enable = true;
    };
    media = {
      enable = true;
      mopidy = {
        youtube.apiKey = config.custom.networking.secrets.youtube.apiToken;
        file.roots = {
          "Mongol" = homePrefix "blobs/music/mongol";
        };
      };
      wm.enable = true;
    };
    misc = {
      enable = true;
      wm.enable = true;
    };
    screenshots = {
      enable = true;
      baseDir = homePrefix "blobs/screenshots";
      ordering = {
        enable = true;
        timespec = "*-*-* 00:05:00";
      };
      wm.enable = true;
    };
  };

  dev = {
    codesearch = {
      enable = true;
      emacs.enable = true;
    };
    completion.emacs.enable = true;
    git = {
      autofetch = {
        enable = false;
        when = "hourly";
      };
      autopush = {
        enable = false;
        when = "*-*-* 18:00:00";
      };
      savewip = {
        enable = false;
        when = "hourly";
      };
      batch.enable = true;
      forges = {
        enable = true;
        emacs.enable = true;
      };
      core = {
        enable = true;
        emacs.enable = true;
      };
      misc = {
        enable = true;
        emacs.enable = true;
      };
      devenv.enable = true;
    };
    navigation.projects = {
      enable = true;
      bookmarks.enable = true;
      fuzzySearch.enable = true;
      wm.enable = true;
    };
    misc = {
      enable = true;
      patching.enable = true;
      emacs.enable = true;
    };
    python = {
      enable = true;
      emacs.enable = true;
    };
    ccpp = {
      enable = true;
      emacs.enable = true;
    };
    golang = {
      enable = true;
      goPath = homePrefix "workspace/go";
      misc.enable = true;
      emacs.enable = true;
    };
  };

  custom.email = {
    enable = true;
    emailAddress = config.identity.secrets.email;
    defaultAccountName = config.identity.secrets.email;
    gpg = {
      sign = true;
      keyID = config.identity.secrets.gpgKeyID;
    };
    mbsync = {
      enable = true;
      postExec = "${pkgs.notmuch}/bin/notmuch new";
    };
    msmtp.enable = true;
    notmuch.enable = true;
    imapfilter = {
      enable = true;
      server = "imap.google.com";
    };
  };

  custom.housekeeping = {
    enable = true; # !!! essential for metadata caching !!!
    cleanTrash = {
      enable = true;
      calendarTimespec = "*-*-* 23:00:00";
    };
    wm.enable = true;
  };

  ide.emacs = {
    enable = true;
    wm.enable = true;
  };

  custom.knowledgebase = {
    enable = true;
    emacs.enable = true;
  };

  custom.pulseaudio = {
    enable = true;
    daemonConfig = { flat-volumes = "no"; };
    wm.enable = true;
  };

  custom.navigation = {
    enable = true;
    gmrun.enable = true;
    mc.enable = true;
    misc.enable = true;
    snippets.enable = true;
    emacs.enable = true;
    wm.enable = true;
    bookmarks.enable = true;
    workspaceRootGlobal = "workspace/repos";
  };

  custom.networking = {
    enable = true;
    clients.enable = true;
    messengers.enable = true;
    scripts.enable = true;
    wm.enable = true;
    extraHosts.enable = true;
    secrets = {
      enable = true;
      vpn.enable = true;
      wifi.enable = true;
    };
    nmconn.enable = true;
  };

  custom.packaging = {
    enable = true;
    nix = {
      helpers.enable = true;
      search.enable = true;
    };
    misc.enable = true;
    cachix.configuration = builtins.readFile ./secrets/cachix.dhall;
    scripts.enable = true;
    homeManagerBackups.enable = false;
    emacs.enable = true;
  };

  custom.paperworks = {
    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
    };
    scanning = {
      enable = true;
      extraBackends = [ pkgs.hplipWithPlugin ];
      enableXsane = true;
      paperless = {
        enable = false;
        package = pkgs.paperless;
        consumptionDir = homePrefix "docs/paperless/consume";
        dataDir = homePrefix "docs/paperless/data";
        user = user;
        extraConfig = { PAPERLESS_FORGIVING_OCR = true; };
        group = "users";
      };
    };
    publishing = { enable = true; };
  };

  custom.pim = {
    enable = true;
    emacs.enable = true;
    scheduling.enable = true;
    timeTracking.enable = true;
  };

  localinfra.powermanagement = {
    enable = true;
    resumeCommands = lib.concatStringsSep "\n"
      (lib.mapAttrsToList (server: _: "${pkgs.systemd}/bin/systemctl try-restart openvpn-${server}.service")
        config.services.openvpn.servers);
    powerDownCommands = ''
      redis-cli --scan --pattern "*is_up" | xargs redis-cli del
    '';
    batteryManagement = {
      enable = true;
      notificationThreshold = 20;
      suspensionThreshold = 10;
    };
    appsSuspension.enable = true;
    wm.enable = true;
    warmup.enable = true;
  };

  custom.security = {
    enable = true;
    pinentryFlavor = "qt";
    polkit.silentAuth = true;
    emacs.enable = true;
    wm.enable = true;
  };

  custom.shell = {
    enable = true;
    alacritty.enable = true;
    bookmarks.enable = true;
    tmux.enable = true;
    toolsng.enable = true;
    liquidPrompt.enable = true;
    emacs.enable = true;
    wm.enable = true;
    staging.packages = with pkgs; [ diskonaut k4dirstat ugrep godu rargs ];
  };

  custom.virtualization = {
    enable = true;
    docker = {
      enable = true;
      devdns = {
        enable = true;
        autoStart = false;
      };
    };
    libvirt.enable = true;
    virtualbox.enable = true;
    wm.enable = true;
  };

  custom.xinput = {
    hardware.enable = true;
    constraintMouse = {
      enable = true;
      bottom = 25;
      top = 0;
    };
    gestures.enable = true;
    keynav.enable = true;
    xkeysnail.enable = true;
    xmodmap = {
      enable = true;
      rc = ''
        clear mod1
        clear mod4
        clear mod5
        keycode 64 = Alt_L Meta_L
        keycode 133 = Super_L
        keycode 108 = Hyper_L
        keycode 191 = Insert
        add mod1 = Meta_L
        add mod1 = Alt_L
        add mod4 = Super_L
        add mod5 = Hyper_L
        keysym Alt_R = Multi_key
      '';
    };
  };

  custom.video = {
    enable = true;
    opengl.enable = true;
    autorandr = {
      enable = true;
      profiles = [ "docked_home" "docked_office" "mobile" "undocked_parents_dsub" ];
    };
    screenlocker = {
      enable = true;
      notificationTimeout = 5000;
      alertingTimerSec = 210;
      lockingTimerSec = 60;
    };
    rotateSecondaryHead = true;
    ddc.enable = true;
    wm.enable = true;
    staging.packages = with pkgs; [ ddcui ];
  };

  dbms = {
    misc = {
      enable = true;
      controlCenter.enable = true;
      wm.enable = true;
    };
    mysql.enable = true;
    pgsql.enable = true;
    sqlite.enable = true;
  };

  dev.direnv = {
    enable = true;
    emacs.enable = true;
    emacs.granularity = "file";
  };

  dev.editorconfig = {
    enable = true;
    emacs.enable = true;
  };

  wm.i3 = {
    enable = true;
    statusbarImpl = "i3-rs";
  };

  wmCommon.workspaces = [
    {
      name = "web";
      key = [ "F1" ];
      transient = false;
      type = "primary";
    }
    {
      name = "edit";
      key = [ "F2" ];
      transient = false;
      type = "primary";
    }
    {
      name = "tools";
      key = [ "F4" ];
      transient = false;
      type = "primary";
    }
    {
      name = "scan";
      key = [ "F5" ];
      transient = false;
      type = "primary";
    }
    {
      name = "ent";
      key = [ "F6" ];
      transient = false;
      type = "primary";
    }
    {
      name = "shell";
      key = [ "F3" ];
      transient = false;
      type = "secondary";
    }
    {
      name = "read";
      key = [ "4" ];
      transient = false;
      type = "secondary";
    }
    {
      name = "media";
      key = [ "5" ];
      transient = false;
      type = "secondary";
    }
    {
      name = "im";
      key = [ "c" ];
      transient = false;
      type = "secondary";
    }
    {
      name = "scratch";
      key = [ "Esc" ];
      transient = false;
      type = "tertiary";
    }
  ];

  wmCommon.autostart.entries =
    [ "alacritty" "clipcatd" "qutebrowser -P default --class qb-default" "telegram-desktop" ];

  home-manager = {
    useGlobalPkgs = true;
    users."${user}" = {
      xdg.enable = true;
      home.stateVersion = "19.09";
    };
  };

  system.stateVersion = "19.03";
}

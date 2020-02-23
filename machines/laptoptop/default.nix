{ config, pkgs, lib, ... }:
let
  deps = import ../../nix/sources.nix;
  nixpkgs-pinned-05_12_19  = import deps.nixpkgs-pinned-05_12_19 { config.allowUnfree = true; };
in
{
  imports = [
    ../../nix/setup.nix
    "${deps.home-manager}/nixos"
    ./secrets
    ../../modules
    "${deps.nixos-hardware}/common/cpu/intel/sandy-bridge"
    "${deps.nixos-hardware}/common/pc/ssd"
    "${deps.nixos-hardware}/lenovo/thinkpad/x230"
    ./filesvars.nix
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
    };
    initrd.availableKernelModules = [ "ahci" "ehci_pci" "sdhci_pci" "usb_storage" "xhci_pci" ];
    plymouth.enable = true;
    extraModprobeConfig = ''
      options iwlwifi 11n_disable=1 power_save=1 power_level=2
    '';
    extraModulePackages = with config.boot.kernelPackages; [ exfat-nofuse ];
    tmpOnTmpfs = true;
    kernelPackages = pkgs.linuxPackages_4_19;
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
  };

  networking = {
    hostName = "laptoptop";
    hostId = "2ab69157";
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
      enableStrongSwan = true;
      unmanaged = [
        "br0"
        "interface-name:vb-*"
        "interface-name:vbox*"
        "interface-name:ve-*"
        "lo"
      ];
    };
    wireless = {
      enable = false;
      driver = "nl80211";
      userControlled.enable = true;
      interfaces = [ "wlan0" ];
      networks = {
        "mgts161".pskRaw = "e01f873374ae7edfb0b00767e722a544b83b1127ab439ea835e087969a9e8e0c";
        "dent guest".pskRaw = "d7c9d6ecb87d5791e21a50d51ad06d8756a02e85185cc74ccba2c7b219b9daf4";
        "E-HOME".pskRaw = "55a2afc011508c7ebafc06207e03217b57bd839aa82b46819d74ac532c849e98";
        "emobile".pskRaw = "34bc8341ed02ed5efa2da222f2a93bacc3e75f76dc635c9ddc5b852ba421c857";
        "RT-WiFi_6908".pskRaw = "acb8748ab0c195789d959d11268f8802865d082544fe077ff0d34b9da87603e7";
        "${config.secrets.job.officeSSID}".pskRaw = "88d104773f66d699bc66b21268f786a91869382278d43f1dacad0aa0bb87c979"; #"2d3409526a97aabf44bbbfc3afde3acbc252843e795969915b6c830387443906";
      };
    };
    dhcpcd.denyInterfaces = [ "docker*" "virbr*" "br*"];
    nameservers = [ "77.88.8.8" "77.88.8.1" "8.8.8.8" ];
  };

  environment.shells = with pkgs; [ "${bash}/bin/bash" "${zsh}/bin/zsh" "/run/current-system/sw/bin/zsh" ];

  users.extraUsers.root.hashedPassword =
    "586c56b7b6b6f68fca29c9ff2524e4dc52d51d5b6184a65f707dd3eae075e4c9afa81c9cd4042c26c9fb773d4f3de55fb55f363c6b0f5f6790baf4c4e3f32cb9";
  nix.trustedUsers = [ "root" config.attributes.mainUser.name ];

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
    dbus = {
      enable = true;
      socketActivated = true;
    };
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
    tlp.enable = true;
    thermald.enable = true;
    acpid.enable = true;
    timesyncd.enable = true;

    redis.enable = true; # for various caching needs

    arbtt.enable = true;
    openvpn.servers = {
      "${config.secrets.network.vpn.name}" = {
        config = config.secrets.network.vpn.config;
        autoStart = false;
        updateResolvConf = true;
        authUserPass = {
          username = config.secrets.network.vpn.username;
          password = config.secrets.network.vpn.password;
        };
      };
      "${config.secrets.job.vpn.name}" = {
        config = config.secrets.job.vpn.config;
        autoStart = true;
        updateResolvConf = true;
        authUserPass = {
          username = config.secrets.job.vpn.username;
          password = config.secrets.job.vpn.password;
        };
      };
    };
    xbanish.enable = true;
  };

  systemd.services.acme-localhost.enable = false;

  attributes.hardware.monitors = {
    internalHead.name = "LVDS-1";
    internalHead.edid = "00ffffffffffff0030e4d8020000000000160103801c1078ea8855995b558f261d505400000001010101010101010101010101010101601d56d85000183030404700159c1000001b000000000000000000000000000000000000000000fe004c4720446973706c61790a2020000000fe004c503132355748322d534c42330059";
    internalHead.resolution = "1366x768";
  };

  services.xserver = {
    enable = true;
    startDbusSession = true;
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
        background = "black";
        greeters.mini = {
          enable = true;
          user = config.attributes.mainUser.name;
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

  attributes.mainUser = {
    name = config.secrets.identity.userName;
    fullName = config.secrets.identity.fullName;
    email = config.secrets.identity.email;
    gpgKeyID = config.secrets.identity.gpgKeyID;
  };

  users.extraUsers."${config.attributes.mainUser.name}" = {
    isNormalUser = true;
    uid = 1000;
    description = config.secrets.identity.fullName;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  attributes.fonts.basic.package = pkgs.iosevka;
  attributes.fonts.basic.xft = "xft:Iosevka:weight=Bold:size=10";
  attributes.fonts.basic.raw = "Iosevka Bold 10";

  custom.appearance = {
    enable = true;
    fonts = {
      antialias = true;
      console = "Lat2-Terminus16";
    };
    wallpaper = {
      enable = true;
      root = "/home/${config.attributes.mainUser.name}/blobs/wallpaper";
      current = "mongol-winter-3.jpg";
    };
    emacs.enable = true;
    xmonad.enable = true;
  };

  custom.browsers = {
    enable = true;
    staging.enable = false;
    firefox.enable = true;
    sessions.firefox.backup.enable = true;
    chromium = {
      enable = true;
      extraOpts = {
        AudioCaptureAllowed = true;
        VideoCaptureAllowed = true;
        PrintingEnabled = true;

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
        SafeBrowsingEnabled  = false;
        SearchSuggestEnabled = false;
        SigninAllowed = false;
        SpellCheckServiceEnabled = false;
        SpellcheckEnabled = false;
        SyncDisabled = true;
        TranslateEnabled = false;
      };
    };
    aux.enable = true;
    emacs.enable = true;
  };

  custom.content = {
    enable = true;
    bookmarks.enable = true;
    screenshots = {
      enable = true;
      baseDir = "/home/${config.attributes.mainUser.name}/screenshots";
      dateFormat = "+%Y-%m-%d_%H:%M:%S";
    };
    warmup = {
      enable = true;
      paths = [
        "/home/${config.attributes.mainUser.name}/.mozilla"
      ];
    };
    xmonad.enable = true;
  };

  custom.dev = {
    statistics.enable = true;
    codesearch.enable = true;
    patching.enable = true;
    misc.enable = true;
    emacs.enable = true;
    xmonad.enable = true;
  };

  custom.dev.git = {
    enable = true;
    pager.delta.enable = true;
    myrepos.enable = false; # temporarily
    myrepos.subconfigs = [
      "/home/${config.attributes.mainUser.name}/workspace/repos/.mrconfig"
    ];
    ghq = { enable = true; };
    github = {
      enable = true;
      user = "wiedzmin";
    };
    workspaceRoot = "/home/${config.attributes.mainUser.name}/workspace/repos";
    fetchUpdates.enable = false; # temporarily; bootTimespec = "1min"; activeTimespec = "30min";
    pushUpdates.enable = false; # temporarily; calendar = "*-*-* 18:00:00";
    saveWip.enable = false; # temporarily; bootTimespec = "30sec"; activeTimespec = "1hour";
    emacs.enable = true;
  };

  custom.dev.python = {
    enable = true;
    pylsExtraSourcePaths = config.secrets.job.pylsExtraSourcePaths;
    emacs.enable = true;
  };

  custom.dev.golang = {
    enable = true;
    goPath = config.secrets.dev.goPath;
    privateModules = config.secrets.job.golangPrivateModules;
    packaging.enable = true;
    emacs.enable = true;
  };

  custom.email = {
    enable = true;
    emailAddress = config.secrets.identity.email;
    defaultAccountName = config.secrets.identity.email;
    passwordPath = config.secrets.identity.googleAccountPasswordPath;
    gpg = {
      sign = true;
      keyID = config.secrets.identity.gpgKeyID;
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
      byFrom = config.secrets.email.imapfilter.byFrom;
      byTo = config.secrets.email.imapfilter.byTo;
      byCc = config.secrets.email.imapfilter.byCc;
      bySubject = config.secrets.email.imapfilter.bySubject;
      deleteByFrom = config.secrets.email.imapfilter.deleteByFrom;
    };
  };

  custom.housekeeping = {
    enable = true;
    cleanTrash = {
      enable = true;
      calendarTimespec = "*-*-* 23:00:00";
    };
    orderScreenshots = {
      enable = true;
      calendarTimespec = "*-*-* 00:05:00";
    };
  };

  ide.emacs.enable = true;

  custom.knowledgebase = {
    enable = true;
    emacs.enable = true;
  };

  custom.sound = {
    enable = true;
    pulse = {
      enable = true;
      daemonConfig = {
        flat-volumes = "no";
      };
    };
    xmonad.enable = true;
  };

  custom.navigation = {
    enable = true;
    gmrun.enable = true;
    mc.enable = true;
    misc.enable = true;
    emacs.enable = true;
    xmonad.enable = true;
  };

  custom.networking = {
    enable = true;
    clients.enable = true;
    messengers.enable = true;
    scripts.enable = true;
    xmonad.enable = true;
    extraHosts = config.secrets.job.infra.extraHosts // config.secrets.network.extraHosts;
  };

  custom.packaging = {
    enable = true;
    nix = {
      helpers.enable = true;
      srcfmt.enable = true;
      importers.enable = true;
      search.enable = true;
    };
    misc.enable = true;
    scripts.enable = true;
    homeManagerBackups.enable = false;
    emacs.enable = true;
    xmonad.enable = true;
  };

  custom.paperworks = {
    printing = {
      enable = true;
      drivers = [ nixpkgs-pinned-05_12_19.hplipWithPlugin ];
    };
    scanning = {
      enable = true;
      extraBackends = [ pkgs.epkowa ];
      snapscan.firmware = "/etc/nixos/assets/blobs/Esfw52.bin";
      enableXsane = true;
      paperless = {
        enable = true;
        package = nixpkgs-pinned-05_12_19.paperless;
        consumptionDir = "/home/${config.attributes.mainUser.name}/docs/paperless/consume";
        dataDir = "/home/${config.attributes.mainUser.name}/docs/paperless/data";
        user = config.attributes.mainUser.name;
        extraConfig = {
          PAPERLESS_FORGIVING_OCR = true;
        };
        group = "users";
      };
    };
    publishing.enable = true;
  };

  custom.pim = {
    enable = true;
    emacs.enable = true;
  };

  custom.power-management = {
    enable = true;
    resumeCommands = lib.concatStringsSep "\n"
      (lib.mapAttrsToList (server: _: "${pkgs.systemd}/bin/systemctl try-restart openvpn-${server}.service")
        config.services.openvpn.servers);
    batteryManagement = {
      enable = true;
      notificationThreshold = 20;
      suspensionThreshold = 10;
    };
    appsSuspension.enable = true;
    xmonad.enable = true;
  };

  custom.security = {
    enable = true;
    pinentryFlavor = "qt";
    polkit.silentAuth = true;
    emacs.enable = true;
    xmonad.enable = true;
  };

  custom.shell = {
    enable = true;
    toolsng.enable = true;
    liquidPrompt.enable = true;
    emacs.enable = true;
    xmonad.enable = true;
  };

  custom.system = {
    enable = true;
    xmonad.enable = true;
  };

  custom.virtualization = {
    enable = true;
    docker = {
      enable = true;
      devdns = {
        enable = true;
        autoStart = true;
      };
    };
    libvirt.enable = true;
    virtualbox.enable = false;
    xmonad.enable = true;
  };

  custom.xinput = {
    hardware.enable = true;
    constraintMouse.enable = true;
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
    autorandr.enable = true;
    screenlocker.enable = true;
    ddc.enable = true;
    xmonad.enable = true;
  };

  themes.fonts.iosevka.enable = true;
  themes.zenburn.enable = true;

  tools = {
    dbms = {
      mysql.enable = true;
      jobDbms.enable = true;
      misc.enable = true;
      xmonad.enable = true;
    };
    ebooks = {
      readers.enable = true;
      xmonad.enable = true;
    };
  };

  wm.xmonad = {
    enable = true;
    dmenuFrecency.enable = true;
  };

  home-manager.users."${config.attributes.mainUser.name}" = {
    nixpkgs.config.allowUnfree = true;
    xdg.enable = true;
    home.packages = with pkgs; [
      haskellPackages.arbtt # for stats viewing
    ];

    home.stateVersion = "19.09";
  };

  system.stateVersion = "19.03";
}

# https://github.com/embayer/org-note

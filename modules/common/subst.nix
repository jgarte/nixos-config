let
  deps = import ../../nix/sources.nix;
  nixpkgs-pinned-05_12_19  = import deps.nixpkgs-pinned-05_12_19 { config.allowUnfree = true; };
in
{ config, lib, pkgs, ... }:

rec {
  autorandrBinary = "${pkgs.autorandr}/bin/autorandr";
  autorandrProfiles = "/home/${config.attributes.mainUser.name}/.config/autorandr";
  awkBinary = "${pkgs.gawk}/bin/awk";
  bashBinary = "${pkgs.bash}/bin/bash";
  bookReader = config.attributes.defaultCommands.ebookReader;
  bookshelfPath = "/home/${config.attributes.mainUser.name}/bookshelf";
  bukuBinary = "${nixpkgs-pinned-05_12_19.buku}/bin/buku";
  contentBookmarksBatchOpenThreshold = builtins.toString config.custom.content.bookmarks.batchOpenTreshold;
  cpBinary = "${pkgs.coreutils}/bin/cp";
  cutBinary = "${pkgs.coreutils}/bin/cut";
  dateBinary = "${pkgs.coreutils}/bin/date";
  defaultBrowser = config.attributes.defaultCommands.browser;
  defaultContainerShell = config.custom.virtualization.docker.defaultContainerShell;
  defaultEbookReader = config.attributes.defaultCommands.ebookReader;
  defaultPager = config.attributes.defaultCommands.pager;
  defaultSpreadsheetEditor = config.attributes.defaultCommands.spreadsheetEditor;
  defaultTerminal = config.attributes.defaultCommands.terminal;
  defaultTextProcessor = config.attributes.defaultCommands.textProcessor;
  deftPath = "/home/${config.attributes.mainUser.name}/docs/deft";
  dejsonlz4Binary = "${pkgs.dejsonlz4}/bin/dejsonlz4";
  devWorkspaceRoot = config.custom.dev.globalWorkspaceRoot;
  diffBinary = "${pkgs.diffutils}/bin/diff";
  ditaaJar = "${pkgs.ditaa}/lib/ditaa.jar";
  dmenuBinary = "${pkgs.dmenu}/bin/dmenu";
  dockerBinary = "${pkgs.docker}/bin/docker";
  dunstifyBinary = "${pkgs.dunst}/bin/dunstify";
  emacsBrowserGenericProgram = config.attributes.defaultCommands.browser;
  emacsCustomFile = "/home/${config.attributes.mainUser.name}/.emacs.d/customizations.el";
  emacsDatadir = config.ide.emacs.dataDir;
  emacsResourcesDir = "/home/${config.attributes.mainUser.name}/.emacs.d/resources/";
  emacsYasnippetSnippets = deps.yasnippet-snippets;
  emacsclientBinary = "${pkgs.emacs}/bin/emacsclient";
  fdBinary = "${pkgs.fd}/bin/fd";
  firefoxBinary = "${pkgs.firefox-unwrapped}/bin/firefox";
  firefoxProfilePath = config.home-manager.users."${config.attributes.mainUser.name}".programs.firefox.profiles.default.path;
  firefoxSessionsHistoryLength = builtins.toString config.custom.browsers.sessions.firefox.historyLength;
  firefoxSessionsNameTemplate = config.custom.browsers.sessions.firefox.nameTemplate;
  firefoxSessionsPath = config.custom.browsers.sessions.firefox.path;
  firefoxSessionsSizeThreshold = builtins.toString config.custom.browsers.sessions.sizeThreshold;
  firefoxSessionstorePath = "/home/${config.attributes.mainUser.name}/.mozilla/firefox/${firefoxProfilePath}/sessionstore-backups";
  gitBinary = "${pkgs.git}/bin/git";
  gitHooksDirname = config.custom.dev.git.hooks.dirName;
  gitHooksShortCircuitPatch = if config.custom.dev.git.hooks.shortCircuit then "return $exitcode" else "";
  gitSecretsBinary = "${pkgs.gitAndTools.git-secrets}/bin/git-secrets";
  gmrunHistorySize = builtins.toString config.custom.navigation.gmrun.historySize;
  gmrunTerminalApps = lib.concatStringsSep " " config.custom.navigation.gmrun.terminalApps;
  grepBinary = "${pkgs.gnugrep}/bin/grep";
  iwgetidBinary = "${pkgs.wirelesstools}/bin/iwgetid";
  ixBinary = "${pkgs.ix}/bin/ix";
  jobInfraLogsHost = config.job."b354e944b3".secrets.infra.logsHost;
  jobInfraRemoteDockerLogsRoot = config.job."b354e944b3".secrets.infra.remoteDockerLogsRoot;
  jobInfraSwarmLeader = config.job."b354e944b3".secrets.infra.swarmLeader;
  jobWorkspaceRoot = config.job."b354e944b3".secrets.workspaceRoot;
  jqBinary = "${pkgs.jq}/bin/jq";
  lspPythonMsExtraPaths = builtins.concatStringsSep " " (lib.forEach config.custom.dev.python.pylsExtraSourcePaths (path: ''"${path}"''));
  maimBinary = "${pkgs.maim}/bin/maim";
  mktempBinary = "${pkgs.coreutils}/bin/mktemp";
  mvBinary = "${pkgs.coreutils}/bin/mv";
  mycliBinary = "${nixpkgs-pinned-05_12_19.mycli}/bin/mycli";
  nixBinary = "${pkgs.nix}/bin/nix";
  nixEnvBinary = "${pkgs.nix}/bin/nix-env";
  nixShellBinary = "${pkgs.nix}/bin/nix-shell";
  nixfmtBinary = "${pkgs.nixfmt}/bin/nixfmt";
  orgDir = config.ide.emacs.orgDir;
  orgKbPath = "/home/${config.attributes.mainUser.name}/docs/org-kb";
  orgWarningsFiledir = builtins.dirOf config.custom.pim.org.warningsFile;
  orgWarningsFilename = config.custom.pim.org.warningsFile;
  passBinary = "${pkgs.pass}/bin/pass";
  pgcliBinary = "${nixpkgs-pinned-05_12_19.pgcli}/bin/pgcli";
  plantumlJar = "${pkgs.plantuml}/lib/plantuml.jar";
  pythonLibPatch = config.custom.dev.pythonLib;
  rmBinary = "${pkgs.coreutils}/bin/rm";
  screenshotsBasedir = config.custom.content.screenshots.baseDir;
  screenshotsDateFormat = config.custom.content.screenshots.dateFormat;
  sedBinary = "${pkgs.gnused}/bin/sed";
  sortBinary = "${pkgs.coreutils}/bin/sort";
  sshBinary = "${pkgs.openssh}/bin/ssh";
  systemTimeZone = config.time.timeZone;
  teeBinary = "${pkgs.coreutils}/bin/tee";
  tmuxBinary = "${pkgs.tmux}/bin/tmux";
  tmuxDefaultSession = config.attributes.tmux.defaultSession;
  trBinary = "${pkgs.coreutils}/bin/tr";
  wBinary = "${pkgs.procps}/bin/w";
  wcBinary = "${pkgs.coreutils}/bin/wc";
  xclipBinary = "${pkgs.xclip}/bin/xclip";
  xdotoolBinary = "${pkgs.xdotool}/bin/xdotool";
  xprintidleBinary = "${nixpkgs-pinned-05_12_19.xprintidle-ng}/bin/xprintidle-ng";
  xselBinary = "${pkgs.xsel}/bin/xsel";
  yadBinary = "${pkgs.yad}/bin/yad";
}

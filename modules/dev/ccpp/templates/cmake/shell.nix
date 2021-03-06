{ pkgs ? import <nixpkgs> { }, ... }:

with pkgs;
let
  nurpkgs = pkgs.nur.repos; # refer to packages as nurpkgs.<username>.<package>
  base = [ autoconf automake bear bison cmake flex gitAndTools.pre-commit gnumake libtool pkg-config ];
  stats = [ cloc gource logtop sloccount tokei ];
  git = [
    git-quick-stats
    git-sizer
    gitAndTools.git-filter-repo
    gitAndTools.git-machete
    gitAndTools.git-reparent
    gitAndTools.git-subset
    gitAndTools.git-trim
    gitstats
    gomp
  ];
in mkShell {
  buildInputs = base ++ stats ++ git ++ [ ];
  shellHook = ''
    [ -f "./.aux" ] && source ./.aux
  '';
}

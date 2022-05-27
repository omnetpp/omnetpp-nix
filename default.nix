let
  nixosPkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-22.05.tar.gz" ) {};
in
  { pkgs ? nixosPkgs }:
  let
    omnetppScope = with pkgs; {
    } ;

    omnetppPkgs =  rec {
      lib = import ./lib { inherit pkgs; }; # functions
      modules = import ./modules; # NixOS modules
      overlays = import ./overlays; # nixpkgs overlays

      callPackage = pkgs.newScope (omnetppScope // omnetppPkgs);
      omnetpp = callPackage ./pkgs/omnetpp {}; # all OMNeT++ versions
      inet = callPackage ./pkgs/inet { inherit omnetppPkgs; }; # all INET versions
    };

  in omnetppPkgs

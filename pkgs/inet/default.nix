# all INET versions
{ pkgs, omnetppPkgs }:

rec {

  v4_4_0 = pkgs.callPackage ./inet.nix rec {
    # override default build environment
    stdenv = pkgs.llvmPackages_14.stdenv;
    lld = pkgs.lld_14;
    # required parameters
    pname = "inet";
    version = "4.4.0";
    omnetpp = omnetppPkgs.omnetpp.v6_0_0;
    url = "https://github.com/inet-framework/inet/releases/download/v${version}/${pname}-${version}-src.tgz";
    sha256 = "8DtgrN/5MAins1/rwHrIAw3lNtbJD5X0Zi+Wo2hcYjs=";
  };

  # aliases for the latest versions
  v4_4_x = v4_4_0;
  v4_x = v4_4_x;
  latest = v4_x;
}
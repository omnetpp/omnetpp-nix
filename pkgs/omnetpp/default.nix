# all OMNeT++ versions
{ pkgs }:

rec {

  v6_0_0 = pkgs.callPackage ./omnetpp60.nix rec {
    # override default build environment
    stdenv = pkgs.llvmPackages_14.stdenv;
    lld = pkgs.lld_14;
    python3 = pkgs.python310;
    # required parameters
    pname = "omnetpp";
    version = "6.0";
    url = "https://github.com/omnetpp/omnetpp/releases/download/${pname}-${version}/${pname}-${version}-core.tgz";
    sha256 = "qO20RuQJBYrePiJWI5FxaCvySwmXI1KI8Ui5soOedpU=";
  };

  # aliases for the latest versions
  v6_0_x = v6_0_0;
  v6_x = v6_0_x;
  latest = v6_x;
}
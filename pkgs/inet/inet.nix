{ 
  pname, version, url, sha256,      # direct parameters
  stdenv, lib, fetchurl, lld,       # build environment
  omnetpp,                          # dependencies
}:
let
in
stdenv.mkDerivation rec {
  inherit pname;
  inherit version;

  src = fetchurl { inherit url; inherit sha256; };

  enableParallelBuilding = true;
  strictDeps = true;
  dontStrip = true;

  buildInputs = [ omnetpp ];

  # tools required for build only (not needed in derivations)
  nativeBuildInputs = [ omnetpp lld ];

  # tools required for build only (needed in derivations)
  propagatedNativeBuildInputs = [ ];

  # we have to patch all shebangs to use NIX versions of the interpreters
  prePatch = ''
    patchShebangs bin
  '';

  preConfigure = ''
    source setenv
  '';

  buildPhase = ''
    opp_featuretool disable all
    make makefiles
    make MODE=release -j16
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p ${placeholder "out"}

    installFiles=(bin src python Makefile Version setenv .oppbuildspec .oppfeatures .oppfeaturestate)
    for f in ''${installFiles[@]}; do
      cp -r $f ${placeholder "out"}
    done
    echo "src" >${placeholder "out"}/.nedfolders
    grep -E -v 'inet.examples|inet.showcases|inet.tutorials' .nedexclusions >${placeholder "out"}/.nedexclusions

    runHook postInstall
    '';


  preFixup = ''
    (
      build_pwd=$(pwd)
      for bin in $(find ${placeholder "out"} -type f -executable); do
        rpath=$(patchelf --print-rpath $bin  \
                | sed -E "s,$build_pwd,${placeholder "out"}:,g" \
               || echo )
        if [ -n "$rpath" ]; then
          patchelf --set-rpath "$rpath" $bin
        fi
      done
    )
    '';

  shellHook = ''
    source $out/setenv
  '';

  meta = with lib; {
    homepage= "https://inet.omnetpp.org";
    description = "INET Framework for OMNeT++ Discrete Event Simulator";
    longDescription = "An open-source OMNeT++ model suite for wired, wireless and mobile networks. INET evolves via feedback and contributions from the user community.";
    changelog = "https://github.com/inet-framework/inet/blob/v${version}/WHATSNEW";
    # license = licenses.lgpl3;
    maintainers = [ "rudi@omnetpp.org" ];
    platforms = [ "x86_64-linux" "x86_64-darwin" ];
  };
}
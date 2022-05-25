{ 
  pname, version, url, sha256,      # direct parameters  
  stdenv, lib, fetchurl,            # build environment  
  binutils, perl, flex, bison, lld, # dependencies
  python3,
}:
let 
  opp-python-dependencies = python-packages: with python-packages; [
      numpy pandas matplotlib scipy seaborn posix_ipc
    ];
  python3-with-opp-dependencies = python3.withPackages opp-python-dependencies;
in
stdenv.mkDerivation rec {
  inherit pname;
  inherit version;

  src = fetchurl { inherit url; inherit sha256; };

  enableParallelBuilding = true;
  strictDeps = true;
  dontStrip = true;

  buildInputs = [ ];

  # tools required for build only (not needed in derivations)
  nativeBuildInputs = [ bison flex ];

  # tools required for build only (needed in derivations)
  propagatedNativeBuildInputs = [
    binutils
    lld
    perl
    python3-with-opp-dependencies
  ];

  configureFlags = [ "WITH_QTENV=no" "WITH_OSG=no" "WITH_OSGEARTH=no"];

  # we have to patch all shebangs to use NIX versions of the interpreters
  prePatch = ''
    patchShebangs src/utils
    patchShebangs setenv
  '';

  preConfigure = ''
    source setenv
    rm -rf samples
  '';

  buildPhase = ''
    make MODE=release -j16
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p ${placeholder "out"}

    installFiles=(bin include lib python Makefile.inc Version configure.user setenv)
    for f in ''${installFiles[@]}; do
      cp -r $f ${placeholder "out"}
    done

    rm -f ${placeholder "out"}/bin/omnetpp ${placeholder "out"}/bin/omnest ${placeholder "out"}/bin/opp_ide
    rm -f ${placeholder "out"}/bin/opp_neddoc

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
    homepage= "https://omnetpp.org";
    description = "OMNeT++ Discrete Event Simulator runtime";
    longDescription = "OMNeT++ is an extensible, modular, component-based C++ simulation library and framework, primarily for building network simulators.";
    changelog = "https://github.com/omnetpp/omnetpp/blob/omnetpp-${version}/WHATSNEW";
    license = licenses.free;
    maintainers = [ "rudi@omnetpp.org" ];
    platforms = [ "x86_64-linux" "x86_64-darwin" ];
  };
}
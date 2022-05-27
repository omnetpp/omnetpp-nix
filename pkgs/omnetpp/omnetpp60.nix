{ 
  pname, version, url, sha256,        # direct parameters  
  stdenv, lib, fetchurl, symlinkJoin, # build environment  
  binutils, perl, flex, bison, lld,   # dependencies
  python3,
}:
let 
  omnetpp-outputs = stdenv.mkDerivation rec {
    inherit pname version;

    src = fetchurl { inherit url sha256; };
    
    outputs = [ "bin" "dev" "out"]; # doc, samples, gui, gui3d, ide
  
    enableParallelBuilding = true;
    strictDeps = true;
    dontStrip = true;

    buildInputs = [ ];

    # tools required for build only (not needed in derivations)
    nativeBuildInputs = [  ];

    # tools required for build only (needed in derivations)
    propagatedNativeBuildInputs = [
      perl bison flex binutils lld
      (python3.withPackages(ps: with ps; [ numpy pandas matplotlib scipy seaborn posix_ipc ]))
    ];

    configureFlags = [ "WITH_QTENV=no" "WITH_OSG=no" "WITH_OSGEARTH=no"];

    # we have to patch all shebangs to use NIX versions of the interpreters
    prePatch = ''
      patchShebangs src/utils
    '';

    preConfigure = ''
      source setenv
      rm -rf samples
    '';

    buildPhase = ''
      make common MODE=release -j16
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p ${placeholder "bin"} ${placeholder "dev"} ${placeholder "out"}
      mv bin lib ${placeholder "bin"}
      mv Makefile.inc Version configure.user setenv include src ${placeholder "dev"}


      #installFiles=(bin lib python Makefile.inc Version configure.user setenv)
      #for f in ''${installFiles[@]}; do
      #  cp -r $f ${placeholder "bin"}
      #done

      #rm -f ${placeholder "out"}/bin/omnetpp ${placeholder "out"}/bin/omnest ${placeholder "out"}/bin/opp_ide
      #rm -f ${placeholder "out"}/bin/opp_neddoc

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
      outputsToInstall = "bin dev";
      homepage= "https://omnetpp.org";
      description = "OMNeT++ Discrete Event Simulator runtime";
      longDescription = "OMNeT++ is an extensible, modular, component-based C++ simulation library and framework, primarily for building network simulators.";
      changelog = "https://github.com/omnetpp/omnetpp/blob/omnetpp-${version}/WHATSNEW";
      license = licenses.free;
      maintainers = [ "rudi@omnetpp.org" ];
      platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    };
  };
in
  symlinkJoin {
    name = "${pname}-${version}";
    paths = with omnetpp-outputs; [ bin dev ]; 
    postBuild = "";  # TODO optimize the symlink forest (include, src, images, samples, python could be linked as a single directory)
  }
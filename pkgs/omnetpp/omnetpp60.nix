{ 
  pname, version, url, sha256,               # direct parameters  
  stdenv, lib, fetchurl, symlinkJoin, lndir, # build environment  
  binutils, perl, flex, bison, lld,          # dependencies
  python3,
}:
let 
  omnetpp-outputs = stdenv.mkDerivation rec {
    inherit pname version;

    src = fetchurl { inherit url sha256; };
    
    outputs = [ "bin" "lib" "dev" "out" ]; # doc, samples, gui, gui3d, ide
  
    enableParallelBuilding = true;
    strictDeps = true;
    dontStrip = true;
    # hardeningDisable = all;

    buildInputs = [ ];

    # tools required for build only (not needed in derivations)
    nativeBuildInputs = [  ];

    # tools required for build only (needed in derivations)
    propagatedNativeBuildInputs = [
      perl bison flex binutils lld lndir
      (python3.withPackages(ps: with ps; [ numpy pandas matplotlib scipy seaborn posix_ipc ]))
    ];

    configureFlags = [ "WITH_QTENV=no" "WITH_OSG=no" "WITH_OSGEARTH=no"
      "LDFLAGS=-Wl,-rpath,${placeholder "lib"}/lib"];

    # we have to patch all shebangs to use NIX versions of the interpreters
    prePatch = ''
      patchShebangs src/nedxml
      patchShebangs src/utils
    '';

    preConfigure = ''
      source setenv
      rm -rf samples
    '';

    buildPhase = ''
      # order is important so release version will be prefferred over debug
      make -j16 MODE=debug
      make -j16 MODE=release
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p ${placeholder "bin"}/bin
      (cd bin && mv opp_charttool opp_eventlogtool opp_fingerprinttest opp_msgtool opp_msgc opp_nedtool opp_run opp_run_release opp_runall opp_scavetool opp_test ${placeholder "bin"}/bin )
      mv python ${placeholder "bin"}

      mkdir -p ${placeholder "lib"}/lib
      (cd lib && mv liboppcmdenv.so liboppcommon.so liboppenvir.so liboppeventlog.so libopplayout.so liboppnedxml.so liboppscave.so liboppsim.so ${placeholder "lib"}/lib )

      mkdir -p ${placeholder "dev"}/bin ${placeholder "dev"}/lib
      mv Makefile.inc Version configure.user setenv include src ${placeholder "dev"}
      (cd bin && mv opp_configfilepath opp_featuretool opp_makemake opp_run_dbg opp_shlib_postprocess ${placeholder "dev"}/bin )
      (cd lib && mv liboppmain.a liboppmain_dbg.a liboppcmdenv_dbg.so liboppcommon_dbg.so liboppenvir_dbg.so liboppeventlog_dbg.so libopplayout_dbg.so liboppnedxml_dbg.so liboppscave_dbg.so liboppsim_dbg.so ${placeholder "dev"}/lib )

      #installFiles=(bin lib python Makefile.inc Version configure.user setenv)
      #for f in ''${installFiles[@]}; do
      #  cp -r $f ${placeholder "bin"}
      #done

      #rm -f ${placeholder "out"}/bin/omnetpp ${placeholder "out"}/bin/omnest ${placeholder "out"}/bin/opp_ide
      #rm -f ${placeholder "out"}/bin/opp_neddoc

      mkdir -p ${placeholder "out"}
      #lndir ${placeholder "bin"} ${placeholder "out"}
      #lndir ${placeholder "dev"} ${placeholder "out"}

      runHook postInstall
      '';


    preFixup = ''
      (
        # patch rpath on BIN executables
        for file in $(find ${placeholder "bin"} -type f -executable); do
          if patchelf --print-rpath $file; then
            patchelf --set-rpath '${placeholder "lib"}/lib' $file
          fi
        done

        for file in $(find ${placeholder "lib"} -type f -executable); do
          if patchelf --print-rpath $file; then
            patchelf --set-rpath '${placeholder "lib"}/lib' $file
          fi
        done

        # patch rpath on DEV executables
        for file in $(find ${placeholder "dev"} -type f -executable); do
          if patchelf --print-rpath $file; then
            patchelf --set-rpath '${placeholder "dev"}/lib' $file
          fi
        done
      )
      '';

    shellHook = ''
      source $dev/setenv
    '';

    meta = with lib; {
      outputsToInstall = "bin lib dev";
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
  omnetpp-outputs  
/*
  symlinkJoin {
    name = "${pname}-${version}";
    paths = with omnetpp-outputs; [ bin dev ]; 
    postBuild = "";  # TODO optimize the symlink forest (include, src, images, samples, python could be linked as a single directory)
  }
*/
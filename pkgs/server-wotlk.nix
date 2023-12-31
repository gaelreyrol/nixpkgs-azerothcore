{ lib
, ccacheStdenv
, fetchFromGitHub
, cmake
, pkg-config
, mysql80
, git
, boost
, openssl
, zlib
, readline
, bzip2
, breakpointHook
}:

ccacheStdenv.mkDerivation (finalAttrs: {
  pname = "server-wotlk";
  version = "unstable-2023-07";

  src = fetchFromGitHub {
    owner = "azerothcore";
    repo = "azerothcore-wotlk";
    rev = "21cab042328d304e968caa79d87e682da45a24a6";
    hash = "sha256-Wc8PgmfMCCbp4Tv9BB16txIrMrk8KzrRlpDyycPwyCs=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    breakpointHook
  ];

  buildInputs = [
    mysql80
    git
    boost
    openssl
    zlib
    readline
    bzip2
  ];

  enableParallelBuilding = true;

  cmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DTOOLS_BUILD=all"
    "-DSCRIPTS=static"
    "-DMODULES=static"
  ];

  cmakeBuildType = "Release";

  installPhase = ''
    runHook preInstall

    ls -la
    
    mkdir -p $out/share/sql
    cp -r ../data/sql $out/share/sql
    make install

    runHook postInstall
  '';

  meta = with lib; {
    description = "Complete Open Source and Modular solution for MMO";
    homepage = "http://www.azerothcore.org/";
    license = licenses.agpl3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ gaelreyrol ];
  };
})

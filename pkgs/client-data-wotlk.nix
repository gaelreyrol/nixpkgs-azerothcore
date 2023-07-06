{ lib
, stdenv
, fetchurl
, fetchzip
, unzip
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "client-data-wotlk";
  version = "16";

  src = fetchurl {
    url = "https://github.com/wowgaming/client-data/releases/download/v${finalAttrs.version}/data.zip";
    hash = "sha256-zM5sdqJekI/HKf6fcRZYcb0PUzTSSvuwL0DvsT08fek=";
  };

  buildInputs = [ unzip ];

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  unpackPhase = ''
    unzip ${finalAttrs.src}
  '';

  installPhase = ''
    cp -a . $out
  '';

  meta = with lib; {
    description = "Dbc, Map and some MPQ to use in your editors/viewer tools (EN-US)";
    homepage = "https://wowgaming.github.io/";
    changelog = "https://github.com/wowgaming/client-data/releases/tag/v${finalAttrs.version}";
    platforms = platforms.all;
    license = licenses.unfree;
    maintainers = with maintainers; [ gaelreyrol ];
  };
})

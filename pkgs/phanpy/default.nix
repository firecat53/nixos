# Phanpy: static Mastodon/Akkoma web client, packaged from the prebuilt release.
{
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "phanpy";
  version = "2026.10.09.febb38d";
  src = fetchzip {
    url = "https://github.com/cheeaun/phanpy/releases/download/${finalAttrs.version}/phanpy-dist.tar.gz";
    hash = "sha256-9EUFIZ2d/qP3+KWYLJ+uGBVOGm3Q/icgN3QNDzYTwPo=";
    stripRoot = false;
  };
  installPhase = ''
    cp -r . $out
  '';
})

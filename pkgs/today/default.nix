{
  stdenvNoCC,
  python3,
  makeWrapper,
  librsvg,
}:
let
  pythonEnv = python3.withPackages (ps: [ ps.flask ]);
in
stdenvNoCC.mkDerivation {
  pname = "today";
  version = "0.1.0";
  src = ./.;

  nativeBuildInputs = [
    makeWrapper
    librsvg
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    rsvg-convert -w 192  -h 192  static/icon.svg -o static/icon-192.png
    rsvg-convert -w 512  -h 512  static/icon.svg -o static/icon-512.png
    # Maskable: render onto a background-coloured canvas; Android masks the
    # outer ~20%, so the SVG already includes that padding via the rounded
    # rect — a same-size render with the brand background is sufficient.
    rsvg-convert -w 512 -h 512 --background-color '#2c6e49' \
      static/icon.svg -o static/icon-maskable-512.png
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/today $out/bin
    cp -r app.py templates static $out/share/today/
    makeWrapper ${pythonEnv}/bin/python $out/bin/today \
      --add-flags "$out/share/today/app.py"
    runHook postInstall
  '';

  meta = {
    description = "Quick diary/workout/book entry companion for the Gollum-rendered wiki";
    mainProgram = "today";
  };
}

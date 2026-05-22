{
  stdenvNoCC,
  python3,
  makeWrapper,
}:
let
  pythonEnv = python3.withPackages (ps: [ ps.flask ]);
in
stdenvNoCC.mkDerivation {
  pname = "today";
  version = "0.1.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

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

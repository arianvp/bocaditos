{ stdenv, patch-systemd-units}: stdenv.mkDerivation {
  name = "test";
  src = ./.;
  buildInputs = [ patch-systemd-units ];
  installPhase = ''
    mkdir -p $out/bin
    cp -r patch-systemd-units.sh $out/bin
  '';
}
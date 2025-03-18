{
  makeSetupHook,
  stdenv,
  cmake,
  pkg-config,
  systemd,
}:

let
  # TODO: check that path is correct
  test = stdenv.mkDerivation {
    name = "test";
    src = ./test;

    # lets make it tricky. binary in a separate output than the unit file
    outputs = [ "bin" "out" ];

    nativeBuildInputs = [
      cmake
      pkg-config
      # systemd
      hook
    ];
  };

  hook = makeSetupHook {
    name = "systemd-unit-hook";
  } ./patch-systemd-units.sh;
in
hook // { passthru.tests.test = test; }

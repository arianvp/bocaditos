{
  lib,
  runCommand,
  systemd,
  fakeroot,
  dosfstools,
  mtools,
  erofs-utils,
  zstd,
  os-release,
  toplevel,
  stdenv,
}:

let
  architecture = let
    inherit (stdenv) hostPlatform;
  in
    if hostPlatform.isAarch32 then "arm"
    else if hostPlatform.isAarch64 then "arm64"
    else if hostPlatform.isx86_32 then "x86"
    else if hostPlatform.isx86_64 then "x86-64"
    else if hostPlatform.isMips32 then "mips-le"
    else if hostPlatform.isMips64 then "mips64-le"
    else if hostPlatform.isPower then "ppc"
    else if hostPlatform.isPower64 then "ppc64"
    else if hostPlatform.isRiscV32 then "riscv32"
    else if hostPlatform.isRiscV64 then "riscv64"
    else if hostPlatform.isS390 then "s390"
    else if hostPlatform.isS390x then "s390x"
    else if hostPlatform.isLoongArch64 then "loongarch64"
    else if hostPlatform.isAlpha then "alpha"
    else hostPlatform.parsed.cpu.name;

  args = lib.cli.toGNUCommandLineShell { } {
    offline = "true";
    empty = "create";
    size = "auto";
    definitions = "${./definitions}";
    copy-source = "${toplevel}";

    # TODO: Fix that this gets staged in a writeable directory
    generate-fstab = "etc/fstab";
    generate-crypttab = "etc/crypttab";

    inherit architecture;
  };

  inherit (os-release.passthru.os-release) IMAGE_ID IMAGE_VERSION;

  image =
    runCommand "${IMAGE_ID}_${IMAGE_VERSION}.raw"
      {
        nativeBuildInputs = [
          systemd
          fakeroot
          dosfstools
          mtools
          erofs-utils
          zstd
        ];
        # allowedReferences = [ ];
      }
      ''
        fakeroot systemd-repart ${args} "$out"
      '';
in
image
// {
  passthru.tests.dissect =
    runCommand "test-dissect"
      {
        nativeBuildInputs = [ systemd ];
      }
      ''
        systemd-dissect --validate ${image}
        touch $out
      '';
}

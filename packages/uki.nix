{
  systemd,
  kernel,
  initrd,
  cmdline ? "",
  os-release,
  lib,
  runCommand,
  stdenv,
}:
let
  args = lib.cli.toGNUCommandLineShell { } {
    linux = "${kernel}/${stdenv.hostPlatform.linux-kernel.target}";
    initrd = "${initrd}/initrd";
    # NOTE: providing uname here to avoid ukify from trying to decompress the kernel
    uname = kernel.version;
    # TODO: This is a hack. This should just work through pkg-config in my opinion
    # but ukify hardcodes /usr/lib/systemd/boot/efi instead of using bootlibdir. Not sure how to fix that
    # TODO: Fix cross-compilation. Normally splicing takes care of that
    stub = "${systemd}/lib/systemd/boot/efi/linux${stdenv.hostPlatform.efiArch}.efi.stub";
    # systemd-measure etc
    tools = [
      "${systemd}/lib/systemd"
      "${systemd}/bin"
    ];
    os-release = "@${os-release}";
    inherit cmdline;
  };
in
let
  uki = runCommand "uki" {
    nativeBuildInputs = [ systemd ];
    allowedReferences = [ kernel ];
    passthru.tests.ukify-inspect = runCommand "ukify-inspect" {
      nativeBuildInputs = [ systemd ];
    } "ukify inspect ${uki} --json=pretty > $out";
  } "ukify build ${args} --output $out";
in
uki

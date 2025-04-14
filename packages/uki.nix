{
  systemd,
  kernel,
  initrd,
  cmdline ? "",
  os-release,
  lib,
  runCommand,
  stdenv,
  isUnifiedSystemImage ? true,  # Whether the initrd contains the application
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
    output = "$out/vmlinux.efi";
    measure = true;
    # no initrd transition happens. So we only have two barriers
    phases = if isUnifiedSystemImage "sysinit,sysinit:ready" else null;
  };
in
let
  uki = runCommand "uki" {
    nativeBuildInputs = [ systemd ];
    # allowedReferences = [ kernel ];
    passthru.tests.ukify-inspect = runCommand "ukify-inspect" {
      nativeBuildInputs = [ systemd ];
    } "ukify inspect ${uki} --json=pretty > $out";
  } ''
    mkdir -p $out
    ukify build ${args} >> $out/pcrs.txt
  '';
in
uki

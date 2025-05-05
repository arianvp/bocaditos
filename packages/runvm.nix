{
  writeShellApplication,
  qemu_kvm,
  kernel,
  initrd,
  stdenv,
  lib,
}:

let
  toCLI = lib.cli.toGNUCommandLineShell {
    mkOptionName = name: "-${name}";

  };
  qemuArgs = toCLI {
    "nographic" = true;
    "enable-kvm" = true;
    "machine" = "virt";
    "cpu" = "host";
    "m" = 2048;
    "kernel" = "${kernel}/${stdenv.hostPlatform.linux-kernel.target}";
    "initrd" = "${initrd}/initrd";
    "append" = "loglevel=3 console=hvc0";
  };
in

writeShellApplication {
  name = "runvm";
  text = ''
    qemu-system-aarch64 ${qemuArgs} "$@"
  '';
}

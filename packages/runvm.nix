{
  writeShellApplication,
  qemu_kvm,
  systemd,
  uki,
  stdenv,
  lib,
}:

let
in

writeShellApplication {
  name = "runvm";
  runtimeInputs = [ systemd ];
  text = ''
    systemd-vmspawn --linux ${uki}/uki.efi
  '';
}

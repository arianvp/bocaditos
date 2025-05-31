{
  writeShellApplication,
  systemd,
  uki,
  qemu_kvm,
  virtiofsd,
}:
writeShellApplication {
  name = "runvm";
  runtimeInputs = [
    systemd
    qemu_kvm
    virtiofsd
  ];
  # TODO: merge with actual XDG_CONFIG_HOME ?
  text = ''
    XDG_CONFIG_HOME=${qemu_kvm}/share systemd-vmspawn --linux ${uki}/uki.efi
  '';
}

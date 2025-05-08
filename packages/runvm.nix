{
  writeShellApplication,
  systemd,
  uki,
}:
writeShellApplication {
  name = "runvm";
  runtimeInputs = [ systemd ];
  text = ''
    systemd-vmspawn --linux ${uki}/uki.efi
  '';
}

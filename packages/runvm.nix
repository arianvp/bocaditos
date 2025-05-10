{
  writeShellApplication,
  systemd,
  uki,
}:
writeShellApplication {
  name = "runvm";
  runtimeInputs = [ systemd ];
  # TODO: remove --tpm=no once https://github.com/NixOS/nixpkgs/pull/405843 is merged
  text = ''
    systemd-vmspawn --tpm=no --linux ${uki}/uki.efi
  '';
}

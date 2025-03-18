/**
  Installs all systemd units in the systemd package as instructed in the install section

  FUTUREWORK: Make this take a list of packages and merge the unit paths and the preset paths?

  NOTE: this only works due to ../systemd/0009-add-rootprefix-to-lookup-dir-paths.patch
  otherwise systemd will not find the preset files
*/
{ runCommand, systemd }:
runCommand "presets"
  {
    nativeBuildInputs = [ systemd ];
    SYSTEMD_OFFLINE = true;
  }
  ''
    mkdir -p $out/nix
    ln -s /nix/store $out/nix/store
    systemctl preset-all --root $out
    rm -rf $out/nix
  ''

{ runCommand, systemd }:
runCommand "sysusers"
  {
    nativeBuildInputs = [ systemd ];
  }
  ''
    mkdir -p $out/nix/store
    # TODO: this is kinda hacky?
    cp -r ${systemd} $out/nix/store/
    SYSTEMD_LOG_LEVEL=debug systemd-sysusers --root=$out
    chmod -R u+w $out
    rm -rf $out/nix
  ''

{
  closureInfo,
  systemd,
  etc,
  stdenv,
  uki,
  os-release,
# TODO: Want to make a way to just have a UKI and nothing else
}:
let

  # TODO: systemd needs to be hostPlatform here
  closure = closureInfo {
    rootPaths = [
      systemd
      etc
    ];
  };

in
stdenv.mkDerivation {
  name = "toplevel"; # TODO os-release
  # pname = os-release.passthru.os-release.IMAGE_ID;
  # version =  os-release.passthru.os-release.IMAGE_VERSION;

  phases = [ "installPhase" ];

  inherit uki;
  osRelease = os-release;

  nativeBuildInputs = [ systemd ];

  # NOTE: --reflink=auto is the default since coreutils 9.0 but lets keep it in
  installPhase = ''
    mkdir -p "$out/efi" "$out/boot"

    # TODO: This is only done so bootctl finds the entry-token
    mkdir -p "$out/usr/lib"
    cp -a --reflink=auto "$osRelease" "$out/usr/lib/os-release"

    # TODO: This doesn't work in the case of cross-compilation
    SYSTEMD_LOG_LEVEL=debug SYSTEMD_ESP_PATH=/efi SYSTEMD_XBOOTLDR_PATH=/boot bootctl install --random-seed=no --root="$out" --install-source=host

    # TODO:  this takes the IMAGE_ID from /usr/lib/os-release and not from the .osrel section in the UKI :(
    mkdir -p "$out/boot/EFI/Linux"

    # format is  $entry_token-$kernel_version-$roothash
    # or for NixOS  $entry_token-$kernel_version-$nixhash ?

    cp -a --reflink=auto "$uki" "$out/boot/EFI/Linux"



    # mkdir -p "$out/usr/store"
    # cp -a --reflink=auto "$closure/registration" "$out/usr/store/registration"
    # xargs -I % cp -a --reflink=auto % -t "$out/usr/store/" < "$closure/store-paths"
  '';

  __structuredAttrs = true;

  # NOTE: we're consuming a closure here and producing a fully standalone root directory.
  # Not need for keeping references
  unsafeDiscardReferences.out = true;

  outputChecks.out = {
    allowedReferences = [ ];
    # maxClosureSize =
    # maxSize =
  };
}

{
  closureInfo,
  systemd,
  presets,
  stdenv,
  uki,
  os-release,
}:
let

  # TODO: systemd needs to be hostPlatform here
  closure = closureInfo {
    rootPaths = [
      systemd
      presets
    ];
  };

in
stdenv.mkDerivation {
  name = "toplevel"; # TODO os-release
  # pname = os-release.passthru.os-release.IMAGE_ID;
  # version =  os-release.passthru.os-release.IMAGE_VERSION;

  phases = [ "installPhase" ];

  inherit closure uki;

  nativeBuildInputs = [ ];

  osRelease = os-release;

  # NOTE: --reflink=auto is the default since coreutils 9.0 but lets keep it in
  installPhase = ''
    mkdir -p "$out/usr/lib" "$out/usr/store" "$out/boot/EFI/BOOT"

    cp -a --reflink=auto "$uki" "$out/boot/EFI/BOOT/BOOTAA64.EFI"
    cp -a --reflink=auto "$osRelease" "$out/usr/lib/os-release"

    cp -a --reflink=auto "$closure/registration" "$out/usr/store/registration"
    xargs -I % cp -a --reflink=auto % -t "$out/usr/store/" < "$closure/store-paths"
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

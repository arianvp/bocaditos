{
  cpio,
  zstd,
  closureInfo,
  runCommand,
  systemd,
}:

# TODO: So all the systemd tools work with staging dirs. Do we
# just want to reuse the `toplevel` code and remove the closureInfo here?
# because now we have almost the same code twice
runCommand "initrd"
  {
    name = "initrd";
    closureInfo = closureInfo { rootPaths = [ systemd ]; };
    allowedReferences = [ ];
    __structuredAttrs = true;
    unsafeDiscardReferences.out = true;
    nativeBuildInputs = [
      cpio
      zstd
    ];
  }
  ''
    # Create CPIO archive directly from store paths
    mkdir -p "$out"
    cat "$closureInfo/store-paths" | xargs -I {} find {} -print0 | cpio -v -o -H newc -0 -D / | zstdmt -19 > "$out/initrd.zst"
  ''

{
  systemd,
  kernel,
  openssl,
  initrd,
  cmdline ? "",
  os-release,
  jq,
  lib,
  runCommand,
  stdenv,
  isUnifiedSystemImage ? true,
}:
let
  args = lib.cli.toGNUCommandLineShell { } {
    linux = "${kernel}/${stdenv.hostPlatform.linux-kernel.target}";
    initrd = "${initrd}/initrd";
    # NOTE: providing uname here to avoid ukify from trying to decompress the kernel
    uname = kernel.version;
    # TODO: This is a hack. This should just work through pkg-config in my opinion
    # but ukify hardcodes /usr/lib/systemd/boot/efi instead of using bootlibdir. Not sure how to fix that
    # TODO: Fix cross-compilation. Normally splicing takes care of that
    stub = "${systemd}/lib/systemd/boot/efi/linux${stdenv.hostPlatform.efiArch}.efi.stub";
    # systemd-measure etc
    tools = [
      "${systemd}/lib/systemd"
      "${systemd}/bin"
    ];
    os-release = "@${os-release}";
    inherit cmdline;
    measure = true;
    json = "pretty";
    phases = if isUnifiedSystemImage then "sysinit,sysinit:ready" else null;
    pcr-private-key = "private-key.pem";
    pcr-public-key = "public-key.pem";
  };
in
let
  uki =
    runCommand "uki"
      {
        nativeBuildInputs = [
          systemd
          openssl
          jq
        ];
        # allowedReferences = [ kernel ];
        passthru.tests.ukify-inspect = runCommand "ukify-inspect" {
          nativeBuildInputs = [
            systemd
          ];
        } "ukify inspect ${uki}/vmlinux.efi --json=pretty | tee $out";
      }
      ''
        mkdir -p $out
        # NOTE: signing with a throw-away key for now
        openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out private-key.pem
        openssl rsa -pubout -in private-key.pem -out public-key.pem

        ukify build --output "$out/vmlinux.efi" ${args}
        cp public-key.pem "$out/pcrpkey.pem"
        ukify inspect "$out/vmlinux.efi" --json=pretty | jq -r '.[".pcrsig"].text' | jq . > "$out/pcrsig.json"
      '';
in
uki

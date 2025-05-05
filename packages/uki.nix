{
  systemd,
  kernel,
  openssl,
  binutils,
  initrd,
  cmdline ? "loglevel=3 console=ttyAMA0",
  os-release,
  jq,
  lib,
  runCommand,
  stdenv,
  isUnifiedSystemImage ? true,
}:
let
  linux = "${kernel}/${stdenv.hostPlatform.linux-kernel.target}";
  initrd' = "${initrd}/initrd";
  uname = kernel.version;
  args = lib.cli.toGNUCommandLineShell { } {
    inherit linux uname;
    initrd = initrd';
    # NOTE: providing uname here to avoid ukify from trying to decompress the kernel
    # TODO: This is a hack. This should just work through pkg-config in my opinion
    # but ukify hardcodes /usr/lib/systemd/boot/efi instead of using bootlibdir. Not sure how to fix that
    # TODO: Fix cross-compilation. Normally splicing takes care of that
    stub = "${systemd}/lib/systemd/boot/efi/linux${stdenv.hostPlatform.efiArch}.efi.stub";
    os-release = "@${os-release}";
    inherit cmdline;
    # systemd-measure etc
    tools = [
      "${systemd}/lib/systemd"
      "${systemd}/bin"
    ];

    json = "pretty";
  };
in
let
  uki =
    runCommand "uki"
      {
        nativeBuildInputs = [
          systemd
          openssl
          binutils
          jq
        ];
        # allowedReferences = [ kernel ];
        passthru.tests.ukify-inspect = runCommand "ukify-inspect" {
          nativeBuildInputs = [
            systemd
          ];
        } "ukify inspect ${uki}/uki.efi --json=pretty | tee $out";
      }
      ''
        mkdir -p $out
        # TODO: signing with a throw-away key for now. This means any new image invalidates encrypted credentials and luks partitions
        # NOTE: These are FAKE keys just to convince ukify to run
        openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out tpm2-pcr-private-key.pem
        openssl rsa -pubout -in tpm2-pcr-private-key.pem -out tpm2-pcr-public-key.pem

        # TODO: I'd want the following to work; but it doesn't: https://github.com/systemd/systemd/issues/37133#issuecomment-2802444683
        # ukify build \
        #    --output "$out/vmlinux.efi"  \
        #    --pcr-public-key "tpm2-pcr-public-key.pem" \
        #    --policy-digest
        #    --phases "sysinit,sysinit:ready" \
        #    ${args}

        # cp tpm2-pcr-public-key.pem "$out/tpm2-pcr-public-key.pem"
        # to emulate; we sign with a throaway key and then remove the signature
        ls ${systemd}/lib/systemd/systemd-keyutil

        # TODO: For some reason it can not find systemd-keyutil. no idea why. so need to pass pcr-public-key explicitly
        # FileNotFoundError: [Errno 2] No such file or directory: '/usr/lib/systemd/systemd-keyutil'

        ukify build \
            --tools "${systemd}/lib/systemd" \
            --output "uki.efi" \
            ${args} \
            --pcr-private-key tpm2-pcr-private-key.pem \
            --pcr-public-key tpm2-pcr-public-key.pem \
            --phases "sysinit,sysinit:ready" \
            --measure \
            --json=pretty \
            > "$out/measure.json"

        # HACK:
        objcopy --remove-section=.pcrsig --remove-section=.pcrpkey "uki.efi" "$out/uki.efi"
        inspect=$(ukify inspect "$out/uki.efi" --json=short)
        echo "$inspect" | jq .sbat.text > .sbat
        echo "$inspect" | jq .osrel.text > .osrel
        echo "$inspect" | jq .uname.text > .uname

        ${systemd}/lib/systemd/systemd-measure policy-digest \
            --sbat=.sbat \
            --osrel=.osrel \
            --uname=.uname \
            --linux=${linux} \
            --initrd=${initrd'} \
            --json=pretty \
            --pcrpkey=tpm2-pcr-public-key.pem > "$out/policy-digest.json"
      '';
in
uki

{
  stdenv,
  lib,

  fetchFromGitHub,
  fetchpatch,

  autoPatchelfHook,
  patch-systemd-units,

  # nativeBuildInputs
  gperf,
  m4,
  meson,
  ninja,
  pkg-config,
  getent,
  buildPackages,

  # required buildInputs
  libcap,
  util-linuxMinimal,
  libxcrypt,
  kbd,
  python3Packages,

  # optional build inputs
  openssl,
  tpm2-tss,
  cryptsetup,
  kmod,
  pam,
}:

let

  sonoslib = import ../../lib { inherit lib; };

  requiredBuildInputs = [
    libcap
    libxcrypt
    util-linuxMinimal
    kbd
  ];

  # Meson features
  # TODO: Feature dependencies
  features = {
    vmspawn = {
      buildInputs = [];
      enable = true;
    };
    ukify = {
      buildInputs = [
        (python3Packages.python.withPackages (ps: with ps; [ pefile ]))
      ];
      enable = true;
    };
    bootloader = {
      buildInputs = [ ];
      # TODO: How to handle python package in here?
      nativeBuildInputs = [ ];
      enable = true;
    };
    blkid = {
      buildInputs = [ util-linuxMinimal ];
      enable = true;
    };
    fdisk = {
      buildInputs = [ util-linuxMinimal ];
      enable = true;
    };

    # TODO: circular dependency with systemd
    libcryptsetup = {
      buildInputs = [ cryptsetup ];
      enable = true;
    };
    repart = {
      buildInputs = [ ];
      enable = true;
    };
    openssl = {
      buildInputs = [ openssl ];
      enable = true;
    };
    tpm2 = {
      buildInputs = [ tpm2-tss ];
      enable = true;
    };
    pam = {
      buildInputs = [ pam ];
      enable = true;
    };
  };
  mesonFeatures = sonoslib.mesonFeatures features;
in

stdenv.mkDerivation (
  finalAttrs:

  let
    src = fetchFromGitHub {
      name = "systemd";
      owner = "systemd";
      repo = "systemd";
      # rev = "v${finalAttrs.version}";
      rev = "2e72d3efafa88c1cb4d9b28dd4ade7c6ab7be29a";
      hash = "sha256-w5YWYzuQygEotS7Fxm6MG6eg8uwDUtoP36bGd076tlo=";
    };

  in
  {
    pname = "systemd";
    version = "258.0pre";

    inherit src;

    srcs = [ src ];

    sourceRoot = "systemd";

    nativeBuildInputs = [
      gperf
      m4
      meson
      ninja
      pkg-config

      autoPatchelfHook
      patch-systemd-units

      (buildPackages.python3.withPackages (p: [
        # We use jinja2 as a library; not a cli tool. We need to convince
        # to use the cross-compiled jinja not the nativeBuildInputs one
        p.jinja2
        # needed for bootloader
        # TODO: move up to features
        p.pyelftools
      ]))
    ] ++ lib.optional (stdenv.hostPlatform.isLinux) [ getent ];

    buildInputs =
      requiredBuildInputs
      ++ mesonFeatures.buildInputs
      ++ [
        kmod
      ];
    outputs = [
      "out"
      "dev"
      # TODO: Move bootlib in to a separate output?
      # "bootlib"
    ];

    patches = [
      # TODO: This is hack so that any systemd binaries using CONF_PATHS find things in $out/lib
      # We probably wanna move to a world where everything is in /run or /etc and we prebuild that
      ./0009-add-rootprefix-to-lookup-dir-paths.patch
    ];

    # TODO: Clean this up
    postPatch = ''
      shopt -s extglob
      patchShebangs --build tools test src/!(rpm|kernel-install|ukify) src/kernel-install/test-kernel-install.sh
      substituteInPlace meson.build --replace-fail "install_emptydir(systemdstatedir)" ""
    '';

    # This tricks the systemd build system doing things like `journalctl --update-catalog` which obviously doesn't
    # work in cross-compilation
    DESTDIR = "/";

    # lets disable everything by default
    # See https://drobilla.net/2022/08/16/on-meson-features.html
    mesonAutoFeatures = "disabled";

    mesonFlags = [
      (lib.mesonOption "time-epoch" "1734643670")

      # disable sysvinit compat
      (lib.mesonOption "sysvinit-path" "")
      (lib.mesonOption "sysvrcnd-path" "")
      (lib.mesonOption "rc-local" "")
      # (lib.mesonOption "loadkeys-path" "${kbd}/bin/loadkeys")
      # (lib.mesonOption "setfont-path" "${kbd}/bin/setfond")
      # (lib.mesonOption "tty-gid" "")
      # (lib.mesonOption "ntp-servers" "")
      # (lib.mesonOption "dns-servers" "")
      # (lib.mesonOption "support-url" "")

      (lib.mesonBool "install-sysconfdir" false)
      (lib.mesonBool "create-log-dirs" false)

      # TODO: enable
      # Disabled for now until someone makes this work.
      (lib.mesonOption "sshconfdir" "no")
      (lib.mesonOption "sshdconfdir" "no")

      # TODO: enable
      # Problem: tries to install in sysconfdir by default
      (lib.mesonOption "shellprofiledir" "no")

      # TODO: Disabled to make faster
      (lib.mesonOption "tests" "false")

      # NOTE: it tries to read this from /etc/os-release or /usr/lib/os-release otherwise
      # TODO: Can we make this depend on the os-release package?
      (lib.mesonOption "sbat-distro" "sonos")
      (lib.mesonOption "sbat-distro-summary" "NixOS")
      (lib.mesonOption "sbat-distro-url" "https://nixos.org/")
      (lib.mesonOption "sbat-distro-pkgname" finalAttrs.pname)
      (lib.mesonOption "sbat-distro-version" finalAttrs.version)
      (lib.mesonOption "sbat-distro-generation" "1")

      (lib.mesonBool "sysusers" true)

      # TODO: enable logi
      (lib.mesonBool "logind" false) # we haven't packaged dbus yet

      # NixOS also disables this. not sure what the point is
      (lib.mesonBool "ldconfig" false)

      # paths:

    ] ++ mesonFeatures.mesonFlags;

    # We use autopatchelf because of systemd dlopening things
    autoPatchelfFlags = [ "--keep-libc" ];

    # NOTE: dont' strip EFI binaries (e.g. .sdmagic should stay)
    # TODO: figure out why this matters on aarch64 vs x86
    stripExclude = [ "lib/systemd/boot/efi/*" ];

  }
)

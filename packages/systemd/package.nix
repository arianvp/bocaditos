{
  stdenv,
  fetchFromGitHub,
  lib,

  # nativeBuildInputs
  autoPatchelfHook,
  gperf,
  m4,
  meson,
  ninja,
  pkg-config,
  getent,
  python3,

  # buildInputs
  libcap,
  util-linux,
  libxcrypt,
  kbd

}:
stdenv.mkDerivation (finalAttrs: {
  pname = "systemd";
  version = "257.2";

  src = fetchFromGitHub {
    owner = "systemd";
    repo = "systemd";
    rev = "v${finalAttrs.version}";
    hash = "sha256-A64RK+EIea98dpq8qzXld4kbDGvYsKf/vDnNtMmwSBM=";
  };

  nativeBuildInputs = [
    gperf
    m4
    meson
    ninja
    pkg-config
    getent

    # TODO: cross-compilation
    (python3.withPackages (p: [p.jinja2]))
  ];

  buildInputs = [
    libcap
    libxcrypt
    util-linux
    kbd
  ];

  postPatch = ''
    shopt -s extglob
    patchShebangs tools test src/!(rpm|kernel-install|ukify) src/kernel-install/test-kernel-install.sh
  '' +
  # NOTE: systemd tries to always create this dir. Patch it out
  # TODO: Can we do this with DESTDIR instead?
  ''
    substituteInPlace meson.build --replace-fail "install_emptydir(systemdstatedir)" "" 
  '';

  # Controls the flags passed to meson setup during configure phase.
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

    # TODO: enable
    # Problem: tries to install in sysconfdir by default
    (lib.mesonOption "pamconfdir" "no")
  

  ];

  # lets disable everything by default
  mesonAutoFeatures = "disabled";

  mesonCheckFlags = [];

  mesonInstallFlags = [
  ];

  mesonInstallTags = [];

  autoPAtchelfFlags = [ "--keep-libc" ];
})

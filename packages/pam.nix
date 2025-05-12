# NOTE: PAM will either load from DEFAULT_MODE_PATH aka securedir aka ${pam}/lib/security
# or it will support absolute paths
# TODO: things are installed in $out/lib but things look in $out/lib/security
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  meson,
  ninja,
  pkg-config,
  libxcrypt,
  audit,
  systemd,

  # TODO: How to expose features config nicely?
  enableI18n ? false,
  enableDocs ? false,
  enableAudit ? true,
  enableLogind ? false,
  enableNis ? false,
  enablePam_unix ? true,
}:

let
  features = {
    i18n = {
      enable = enableI18n;
      buildInputs = [ ];
    };
    docs = {
      enable = enableDocs;
      buildInputs = [ ];
    };
    audit = {
      enable = enableAudit;
      buildInputs = [ audit ];
    };
    logind = {
      enable = enableLogind;
      buildInputs = [ systemd ];
    };
    nis = {
      enable = enableNis;
      buildInputs = [ ];
    };
    pam_unix = {
      enable = enablePam_unix;
      buildInputs = [ ];
    };
  };

  sonoslib = import ../lib { inherit lib; };

  mesonFeatures = sonoslib.mesonFeatures features;

in

stdenv.mkDerivation (finalAttrs: {
  pname = "linux-pam";
  version = "1.7.0";
  src = fetchFromGitHub {
    owner = "linux-pam";
    repo = "linux-pam";
    tag = "v${finalAttrs.version}";
    hash = "sha256-VBzX+/p3lsqyLS6xr6YsaD5cod7Q0LZqpMbVOMzzSH4=";
  };
  nativeBuildInputs = [
    ninja
    meson
    pkg-config
  ];
  buildInputs = [
    # TODO: Seems to use libcrypt instead. What do we do?
    libxcrypt
  ] ++ mesonFeatures.buildInputs;
  mesonAutoFeatures = "disabled";
  mesonFlags = [
    # TODO: pam has a dependency on systemd. systemd has a dependency on pam. How to solve?
    # (lib.mesonOption "sconfigdir" "${placeholder "out"}/share/factory/security")
    (lib.mesonOption "systemdunitdir" "")
    (lib.mesonOption "xauth" "")
    # Distribution provided configuration files directory hmm?
    # (lib.mesonOption "vendordir" "${placeholder "out"}/share/factory")
  ] ++ mesonFeatures.mesonFlags;

  patches = [
    (fetchpatch {
      # TODO: Remove when until 1.7.1 is tagged
      url = "https://github.com/linux-pam/linux-pam/commit/900c9c82e0c703fee1f5c55fb4a0913a7fc95306.patch";
      hash = "sha256-8njROy97IqGSJNJhCnr28R91WmK/D5BUZ7exoktjdA4=";
    })
  ];
})

final: prev: {
  # libcap = prev.libcap.override {
  #  withGo = false; # Please less build-time deps
  # };

  # NOTE: By default hexdump is util-linux which depends on systemd. We don't want that.
  # OR we need to inject our systemd as an overlay. that's also possible
  # But I don't want the linux kernel build depending on systemd. that's just wrong
  # hexdump = prev.util-linuxMinimal;

  # pam with meson
  pam = prev.callPackage ./packages/pam.nix { };
  systemd = final.callPackage ./packages/systemd/package.nix { };
  systemdLibs = final.systemdMinimal;
  systemdMinimal = final.systemd.override {
    withLibcryptsetup = false;
  };

  util-linux2 = prev.util-linuxMinimal.override { shadowSupport = true; };
  patch-systemd-units = prev.callPackage ./packages/patch-systemd-units/package.nix { };
}

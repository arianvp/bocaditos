{
  lib,
  makeInitrdNG,
  systemd,
  glibc,
  bash,
  bashInteractive,
  etc,
  util-linuxMinimal,
  coreutils,
  busybox,
  kmod,
  kbd,
  shadow,
}:

let
  storePaths = [
    # systemd tooling
    #"${systemd}/lib/systemd/systemd-executor"
    #"${systemd}/lib/systemd/systemd-fsck"
    #"${systemd}/lib/systemd/systemd-hibernate-resume"
    #"${systemd}/lib/systemd/systemd-journald"
    #"${systemd}/lib/systemd/systemd-makefs"
    ## "${systemd}/lib/systemd/systemd-modules-load"
    #"${systemd}/lib/systemd/systemd-remount-fs"
    #"${systemd}/lib/systemd/systemd-shutdown"
    #"${systemd}/lib/systemd/systemd-sulogin-shell"
    #"${systemd}/lib/systemd/systemd-sysctl"
    ## "${systemd}/lib/systemd/systemd-bsod"
    #"${systemd}/lib/systemd/systemd-sysroot-fstab-check"
    #"${systemd}/lib/systemd/systemd-time-wait-sync"
    #"${systemd}/lib/systemd/systemd-network-generator"
    # "${systemd}/lib/systemd"

    # generators
    # "${systemd}/lib/systemd/system-generators/systemd-debug-generator"
    # "${systemd}/lib/systemd/system-generators/systemd-fstab-generator"
    # "${systemd}/lib/systemd/system-generators/systemd-gpt-auto-generator"
    # "${systemd}/lib/systemd/system-generators/systemd-hibernate-resume-generator"
    # "${systemd}/lib/systemd/system-generators/systemd-run-generator"

    # utilities needed by systemd
    # see progs in meson.build
    # TODO: automatic? How?
    # "${util-linuxMinimal}/bin/quotaon"
    # "${util-linuxMinimal}/bin/quotacheck"
    "${kmod}/bin/kmod"
    "${kmod}/bin/modprobe"
    # TODO: kexec?
    # "${util-linuxMinimal}/bin/kexec"
    "${util-linuxMinimal}/bin/sulogin"
    "${util-linuxMinimal}/bin/mount"
    "${util-linuxMinimal}/bin/umount"
    "${kbd}/bin/loadkeys"
    "${kbd}/bin/setfont"
    # TODO: only the keymaps we use?
    "${kbd}/share"
    "${util-linuxMinimal}/bin/nologin"

    # so NSS can look up usernames
    "${glibc}/lib/libnss_files.so.2"

    # unit files
    "${systemd}/lib/systemd"

    # other config files
    "${systemd}/lib/binfmt.d"
    "${systemd}/lib/environment.d"
    "${systemd}/lib/modprobe.d"
    # "${systemd}/lib/pcrlock.d"
    "${systemd}/lib/sysctl.d"
    "${systemd}/lib/sysusers.d"
    "${systemd}/lib/tmpfiles.d"
    "${systemd}/lib/udev"

    # TODO: We really ought to auto-detct these from the systemd units
    "${systemd}/bin"
    "${bash}"

    # serial-getty@.service
    # which calls ${shadow}/bin/login I think but I hope stdenv takes care of this
    "${util-linuxMinimal}/bin/agetty"
    "${util-linuxMinimal}/bin/login"
    # TODO: We should use util-linux `/bin/login`
    "${shadow}/bin/login"

  ];
in

(makeInitrdNG {
  compressor = "zstd";
  contents = [
    # TODO: kernel modules
    {
      target = "/init";
      source = "${systemd}/bin/init";
    }
    # TODO: complaints about unmerged usr and unmerged bin
    {
      target = "/bin/sh";
      source = "${bashInteractive}/bin/sh";
    }
    {
      target = "/usr/bin/env";
      source = "${coreutils}/bin/env";
    }
    {
      target = "/usr/bin/ls";
      source = "${busybox}/bin/ls";
    }
    {
      target = "/usr/bin/busybox";
      source = "${busybox}/bin/busybox";
    }
    {
      target = "/usr/bin/systemctl";
      source = "${systemd}/bin/systemctl";
    }
    {
      target = "/usr/bin/journalctl";
      source = "${systemd}/bin/journalctl";
    }
    {
      target = "/usr/bin/udevadm";
      source = "${systemd}/bin/udevadm";
    }
    {
      target = "/etc";
      source = "${etc.override { inInitrd = false; }}/etc";
    }
  ] ++ map (path: { source = path; }) storePaths;
}).overrideAttrs
  (oldAttrs: {
    # TODO: Fix
    # allowedReferences = [ ];
  })

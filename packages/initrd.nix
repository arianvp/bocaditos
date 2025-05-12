{
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
  pamtester,
  pam,
  strace,
  isUnifiedSystemImage ? true,
}:

let
  storePaths = [
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
    # "${util-linuxMinimal}/bin/login"
    # TODO: We should use util-linux `/bin/login`
    "${shadow}/bin/login"
    "${pam}/lib/security/pam_deny.so"
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
      source = "${etc.override { inInitrd = !isUnifiedSystemImage; }}/etc";
    }
    {
      target = "/usr/bin/pamtester";
      source = "${pamtester}/bin/pamtester";
    }
    {
      target = "/usr/bin/strace";
      source = "${strace}/bin/strace";
    }
  ] ++ map (path: { source = path; }) storePaths;
}).overrideAttrs
  (oldAttrs: {
    # TODO: Fix
    # allowedReferences = [ ];
  })

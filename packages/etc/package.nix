{
  runCommand,
  systemd,
  os-release,
  inInitrd ? false,
}:
runCommand "etc"
  {
    nativeBuildInputs = [ systemd ];
    SYSTEMD_LOG_LEVEL = "debug";
    inherit systemd;
    inherit inInitrd;
    osRelease = os-release;
  }
  ''
    DESTDIR=rootfs

    # HACK:  this makes systemd-sysusers, systemd-tmpfiles and systemctl preset-all find their configs
    mkdir -p $DESTDIR/nix/store
    cp -r $systemd $DESTDIR/nix/store/


    mkdir -p $DESTDIR/etc
    ln -s ${./pam.d} $DESTDIR/etc/pam.d

    systemd-sysusers --root=$DESTDIR

    # TODO: patch systemd instead
    # TODO: systemd does C! here but perhaps we want L! ?
    mkdir -p $DESTDIR/usr/share
    cp -r $systemd/share/factory $DESTDIR/usr/share/factory
    systemd-tmpfiles --create --boot --root=$DESTDIR --prefix /etc --exclude-prefix /etc/credstore --exclude-prefix /etc/credstore.encrypted

    # TODO: systemd creates ../usr/lib/os-release but we want to create /run/current-system/os-release perhaps?

    # TODO: make these tmpfiles rules
    # TODO: initrd-release
    rm -f $DESTDIR/etc/os-release

    if [ -n "$inInitrd" ]; then
      ln -s $osRelease $DESTDIR/etc/initrd-release
    else
      ln -s $osRelease $DESTDIR/etc/os-release
    fi

    # set up systemd units
    # NOTE: When the machine is booted for the first time, systemd(1) will
    # enable/disable all units according to preset policy, similarly to systemctl
    # preset-all. Also see ConditionFirstBoot= in systemd.unit(5) and "First Boot
    # Semantics" in machine-id(5).
    # However, it doesn't run anymore on subsequent boots (ConditionNeedsUpdate=) so we just
    # run it offline to populate `/etc`
    systemctl preset-all --root $DESTDIR


    chmod u+w -R $DESTDIR/nix $DESTDIR/usr
    rm -rf $DESTDIR/nix/
    rm -rf $DESTDIR/usr

    # TODO: sysusers marks these as unreadable by anyone. have to undo this to copy to nix store
    # TODO: Have to decide if this is fine? nix store is world-readable. Should we store /etc/shadow and /etc/gshadow as state?
    # NOTE: We do not allow setting passwords in SONOS for system users. so no.
    # NOTE: users with passwords should be handled with systemd-homed
    chmod u+r $DESTDIR/etc/shadow
    chmod u+r $DESTDIR/etc/gshadow


    cp -r $DESTDIR $out
  ''

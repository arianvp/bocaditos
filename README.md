# Bocaditos

Bocaditos is a 

is yet another from-scratch OS based on nixpkgs with a focus on trying to rethink NixOS from first-principles.

A few guiding principles:

* We use all the default configuration shipped in the systemd package. Following the "hermetic-usr" model.
  However in our case systemd is patched to read it's config from `$out` instead of `/usr`. 

* Rely on systemd's image-building primitives. 
  * Systemd can pre-build a unit-tree with `systemctl preset-all --root $DESTDIR`. Use that instead of bespoke code
  * Systemd can pre-build sysusers using `systemd-sysusers --root $DESTDIR`. Use that instead of running sysusers at runtime
  * Systemd can pre-build tusing `systemd-tmpfiles --root $DESTDIR`. Use that instead of running tmpfiles at boot for static things.
 

* Don't reimplement things systemd already does. NixOS has a lot of bespoke code for managing systemd config. Like
  installing units. Instead we rely on running runn

* Packages should ship their own systemd units instead of us duplicating package code with NixOS modules.
  We make this work by run

* The same philosophy is used for all packages. Packages by default should ship with their required config built in
  and be configured to read config from `$out`. 


## Kernel

We want to have a kernel with erofs and dm-verity built in. We are **not** a general purpose distro.

## Initrd

The initrd is minimal. 

## Boot-to-initrd

When your application is small.


## Erofs as file on the ESP?

Idea: erofs+fs-verity  on the ESP. file-backed mount.



## TODOS

- [x] a fixupPhase for systemd units ExecStart and friends. similar to patch-shebangs
- [ ] make pkg-config provide an overriden prefix for systemd.pc so that we can stop patching upstream packages
- [ ] Patch `tmpfiles.d` to symlink `${os-release}`  to `/etc/os-release` as opposed to `../usr/os-release`
- [ ] We shouldn't create $out/lib/credstore perhaps
- [ ] What about $out/lib/kernel and $out/lib/rpm

Mar 03 12:19:21 localhost systemd-vconsole-setup[173]: /nix/store/za5i9vxl75jhf4kmjlkbvx7gw9np36xs-kbd-2.7.1/bin/loadkeys failed with exit status 1.

* We should enable nsswitch.conf
  * We have; but does it work?

* We should enable PAM
  * We have; but does it work?


* ProtectSystem remounts /usr read-only in initrd. But we don't have /usr; we have /nix/store.  Need to adjust the initrd generator?

* We get a login prompt; but not prompted for password. It doesn't work. login binary missing I think
* util-linux package contains `login` binary ; yet we patch `util-linux` in nixpkgs to use `shadows`'s `login` binary. what is the difference.

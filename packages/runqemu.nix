{
  writeShellApplication,
  stdenv,
  kernel,
  initrd,
}:
writeShellApplication {
  name = "runqemu";
  # TODO: merge with actual XDG_CONFIG_HOME ?
  text = ''
    qemu-kvm -kernel ${kernel}/${stdenv.hostPlatform.linux-kernel.target} -initrd ${initrd}/initrd.zst -append "console=ttyS0 panic=-1" -nographic -no-reboot
  '';
}

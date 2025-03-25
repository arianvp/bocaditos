{
  linuxPackages_custom,
  fetchgit,
}:
(linuxPackages_custom {
  version = "6.1.128-3.201.amzn2023";
  modDirVersion = "6.1.128";
  src = fetchgit {
    url = "https://github.com/amazonlinux/linux";
    tag = "microvm-kernel-6.1.128-3.201.amzn2023";
    hash = "sha256-HZ3wyrg+tcMrw4jjCmHBwmwhVrh/NkuSEBxWg/fIPyk=";
  };
  configfile = ./microvm-kernel-ci-aarch64-6.1.config;
  allowImportFromDerivation = false;
}).kernel

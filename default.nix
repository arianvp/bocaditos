{ pkgs ? import <nixpkgs> {} }: {
  systemd = pkgs.callPackage ./packages/systemd/package.nix {};
}

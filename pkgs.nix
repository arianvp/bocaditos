{
  system ? builtins.currentSystem,
}:
let
  inherit (import ./npins) nixpkgs;
  lib = import "${nixpkgs}/lib";
  hostPlatform = lib.recursiveUpdate (lib.systems.elaborate system) (
    lib.optionalAttrs (system == "aarch64-linux") {
      # linux-kernel.target = "vmlinuz.efi";
    }
  );
  pkgs = import nixpkgs {
    # crossSystem = "aarch64-linux";
    localSystem = hostPlatform;
    # localSystem = hostPlatform;
    # crossSystem = hostPlatform;
    overlays = builtins.map import [ ./overlay.nix ];
  };
in
pkgs

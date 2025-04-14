let
  sonos = import ./.;
  inherit (import ./npins) nixpkgs;
  lib = import "${nixpkgs}/lib";
in
# TODO: re-export passthru.tests
lib.recurseIntoAttrs (
  lib.genAttrs [ "aarch64-linux" "x86_64-linux" ] (
    system:
    lib.pipe { inherit system; } [
      sonos
      (lib.filterAttrs (_: lib.isDerivation))
      (lib.mapAttrs (_: lib.hydraJob))
      lib.recurseIntoAttrs
    ]
  )
)

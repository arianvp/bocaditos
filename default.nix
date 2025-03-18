{ system ? builtins.currentSystem }:
let
  pkgs = import ./pkgs.nix { inherit system;  };
  inherit (pkgs) lib;
in
lib.makeScope pkgs.newScope (
  self:
  lib.packagesFromDirectoryRecursive {
    inherit (self) callPackage;
    directory = ./packages;
  }
)

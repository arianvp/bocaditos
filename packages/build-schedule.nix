{
  toposort-derivations,
  nix-eval-jobs,
  jq,
  writeShellApplication,
}:
writeShellApplication {
  name = "build-schedule";
  runtimeInputs = [
    toposort-derivations
    nix-eval-jobs
    jq
  ];
  text = ''
    nix-eval-jobs release.nix --check-cache-status | toposort-derivations
  '';
}

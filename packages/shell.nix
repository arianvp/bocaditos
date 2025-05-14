{
  buildEnv,
  nix-eval-jobs,
  npins,
  build-schedule,
  jq,
  ijq,
}:
buildEnv {
  name = "env";
  paths = [
    nix-eval-jobs
    build-schedule
    jq
    ijq
    npins
  ];
}

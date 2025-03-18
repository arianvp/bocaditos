{ lib }:
{
  /**
    Similar to lib.strings.mesonEnable but allows you to group buildInputs together with features.
  */
  mesonFeatures = features: {
    mesonFlags = lib.mapAttrsToList (name: feature: lib.mesonEnable name feature.enable) features;
    buildInputs = lib.concatMap (feature: lib.optionals feature.enable feature.buildInputs) (
      lib.attrValues features
    );
  };
}

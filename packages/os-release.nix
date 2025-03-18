# TODO: NixOS module plz. this is config
{
  formats,
  name ? "SONOS",
  id ? "sonos",
  versionId ? "0.1.0",
  imageId ? "sonos",
  imageVersion ? "0.1.0",
}:
let
  format = formats.keyValue { };
  os-release = {
    NAME = name;
    ID = id;
    VERSION_ID = versionId;
    IMAGE_ID = imageId;
    IMAGE_VERSION = imageVersion;
  };
in
format.generate "os-release" os-release
// {
  passthru.os-release = os-release;
}

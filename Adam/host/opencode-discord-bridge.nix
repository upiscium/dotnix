{ inputs, ... }:

{
  imports = [
    inputs.opencode-discord-bridge.nixosModules.default
  ];

  services.opencode-discord-bridge = {
    enable = true;

    user = "upiscium";
    group = "users";
    createUser = false;

    secretsCredentialFile = "/etc/opencode-discord-bridge/secrets.env";

    # non-secret configuration authority
    configFile = "/etc/opencode-discord-bridge/config.toml";
  };
}

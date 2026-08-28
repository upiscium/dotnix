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

    # 既存の非secret設定用
    environmentFile = "/run/opencode-discord-bridge.env";
  };
}

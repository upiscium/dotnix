# PROJECT-KAGYA private deployment.
# The application checkout lives in /opt/project-kagya (owned by the kagya user)
# and secrets live in /etc/project-kagya/*.env; neither is managed by Nix.
# Everything listens on loopback only; access it with
#   ssh -L 8080:127.0.0.1:8080 eve
# and open http://127.0.0.1:8080.
{ pkgs, lib, ... }:
let
  appDir = "/opt/project-kagya";
  envDir = "/etc/project-kagya";
  python = pkgs.python3;
  nodejs = pkgs.nodejs_22;

  # Native libraries needed by PyPI wheels (torch, bitsandbytes, chromadb, ...)
  # plus the NVIDIA driver's libcuda.
  runtimeLibraryPath = lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
  ] + ":/run/opengl-driver/lib";

  commonServiceConfig = {
    Type = "simple";
    User = "kagya";
    Group = "kagya";
    Restart = "on-failure";
    RestartSec = 5;
  };
in
{
  users.groups.kagya = { };
  users.users.kagya = {
    isSystemUser = true;
    group = "kagya";
    home = "/var/lib/kagya";
    createHome = true;
    shell = pkgs.bashInteractive;
    extraGroups = [ "video" ];
  };

  systemd.tmpfiles.rules = [
    "d ${appDir} 0750 kagya kagya -"
    "d ${envDir} 0750 kagya kagya -"
  ];

  # Tools for the manual build steps (uv sync / npm ci / npm run build).
  environment.systemPackages = [ pkgs.uv nodejs python ];

  environment.variables = {
    UV_PYTHON = "${python}/bin/python3";
    UV_PYTHON_DOWNLOADS = "never";
  };

  systemd.services.kagya-api = {
    description = "PROJECT-KAGYA FastAPI backend";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.uv python pkgs.git ];
    environment = {
      HOME = "/var/lib/kagya";
      UV_PYTHON = "${python}/bin/python3";
      UV_PYTHON_DOWNLOADS = "never";
      LD_LIBRARY_PATH = runtimeLibraryPath;
    };
    serviceConfig = commonServiceConfig // {
      WorkingDirectory = appDir;
      EnvironmentFile = "${envDir}/backend.env";
      ExecStart = "${pkgs.uv}/bin/uv run --frozen --no-dev --no-sync python -m kagya.api.server";
    };
  };

  systemd.services.kagya-frontend = {
    description = "PROJECT-KAGYA Next.js frontend";
    after = [ "network-online.target" "kagya-api.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ nodejs ];
    environment = {
      HOME = "/var/lib/kagya";
      HOSTNAME = "127.0.0.1";
      PORT = "3000";
      NODE_ENV = "production";
    };
    serviceConfig = commonServiceConfig // {
      WorkingDirectory = "${appDir}/frontend";
      EnvironmentFile = "${envDir}/frontend.env";
      ExecStart = "${nodejs}/bin/node node_modules/next/dist/bin/next start -H 127.0.0.1 -p 3000";
    };
  };

  services.caddy = {
    enable = true;
    globalConfig = ''
      admin 127.0.0.1:2019
    '';
    virtualHosts."http://127.0.0.1:8080".extraConfig = ''
      bind 127.0.0.1
      encode zstd gzip

      reverse_proxy /api/* 127.0.0.1:8000
      reverse_proxy /health 127.0.0.1:8000
      reverse_proxy 127.0.0.1:3000
    '';
  };
}

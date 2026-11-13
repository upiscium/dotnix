# PROJECT-SUZKA private deployment.
# The application checkout lives in /opt/project-suzka (owned by the suzka user)
# and secrets live in /etc/project-suzka/*.env; neither is managed by Nix.
# Everything listens on loopback only; access it with
#   ssh -L 8080:127.0.0.1:8080 eve
# and open http://127.0.0.1:8080.
{ pkgs, lib, ... }:
let
  appDir = "/opt/project-suzka";
  envDir = "/etc/project-suzka";
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
    User = "suzka";
    Group = "suzka";
    Restart = "on-failure";
    RestartSec = 5;
  };
in
{
  users.groups.suzka = { };
  users.users.suzka = {
    isSystemUser = true;
    group = "suzka";
    home = "/var/lib/suzka";
    createHome = true;
    shell = pkgs.bashInteractive;
    extraGroups = [ "video" ];
  };

  systemd.tmpfiles.rules = [
    "d ${appDir} 0750 suzka suzka -"
    "d ${envDir} 0750 suzka suzka -"
  ];

  # Tools for the manual build steps (uv sync / npm ci / npm run build).
  environment.systemPackages = [ pkgs.uv nodejs python ];

  environment.variables = {
    UV_PYTHON = "${python}/bin/python3";
    UV_PYTHON_DOWNLOADS = "never";
  };

  systemd.services.suzka-api = {
    description = "PROJECT-SUZKA FastAPI backend";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.uv python pkgs.git ];
    environment = {
      HOME = "/var/lib/suzka";
      UV_PYTHON = "${python}/bin/python3";
      UV_PYTHON_DOWNLOADS = "never";
      LD_LIBRARY_PATH = runtimeLibraryPath;
    };
    serviceConfig = commonServiceConfig // {
      WorkingDirectory = appDir;
      EnvironmentFile = "${envDir}/backend.env";
      ExecStart = "${pkgs.uv}/bin/uv run --frozen --no-dev --no-sync python -m suzka.api.server";
    };
  };

  systemd.services.suzka-frontend = {
    description = "PROJECT-SUZKA Next.js frontend";
    after = [ "network-online.target" "suzka-api.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ nodejs ];
    environment = {
      HOME = "/var/lib/suzka";
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

{ pkgs, lib, ... }: {
#   services.sunshine.package = pkgs.sunshine.override {
#     cudaSupport = true;
#     cudaPackages = pkgs.cudaPackages;
#   };

#   services.avahi.publish.enable = true;
#   services.avahi.publish.userServices = true;

#   security.wrappers.sunshine = lib.mkDefault {
#     owner = "root";
#     group = "root";
#     capabilities = "cap_sys_admin+p";
#     source = "${pkgs.sunshine}/bin/sunshine";
#   };

#   services.sunshine = {
#     enable = true;
#     autoStart = true;
#     capSysAdmin = true;
#     openFirewall = true;
#   };
}

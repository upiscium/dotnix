{ ... }: {
  services.openssh = {
    ports = [ 20000 ];
    settings = {
      PasswordAuthentication = false;
      AllowUsers = [ "upiscium" ];
      X11Forwarding = false;
      PermitRootLogin = "no";
    };
  };

  users.users."upiscium".openssh.authorizedKeys.keyFiles = [
    ../../../config.d/pubkeys/arc.pub
  ];
  users.users."upiscium".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF31E0yYdoDezIurM2fZDOzs03gbZ8PFqC7RGr5Enb/T project-kagya-training-worker"
  ];
}

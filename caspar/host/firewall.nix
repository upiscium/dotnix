{ ... }: {
  networking.firewall = {
    allowedTCPPorts = [ 20000 ];
    allowedUDPPorts = [ ];
  };
}


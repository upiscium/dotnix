{ ... }: {
  networking.firewall = {
    allowedTCPPorts = [ 20000 8000 9000 ];
    allowedUDPPorts = [ ];
  };
}


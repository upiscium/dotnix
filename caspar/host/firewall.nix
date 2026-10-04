{ ... }: {
  networking.firewall = {
    allowedTCPPorts = [ 20000 11434 8000 9000 ];
    allowedUDPPorts = [ 11434 3000 ];
  };
}


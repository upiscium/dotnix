{ ... }: {
  networking.firewall = {
    allowedTCPPorts = [ 20000 11434 8002 8003 ];
    allowedUDPPorts = [ 11434 ];
  };
}


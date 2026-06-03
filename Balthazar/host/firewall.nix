{ ... }: {
  networking.firewall = {
    allowedTCPPorts = [ 20000 11434 3001 4321 8000 ];
    allowedUDPPorts = [ 11434 4321 8000 ];
  };
}


{ ... }: {
  networking.firewall = {
    # allowedTCPPorts = [ 20000 11434 3001 4321 8000 5173 ];
    allowedTCPPortRanges = [
      { from = 2000; to = 65535; }
    ];
    # allowedUDPPorts = [ 11434 4321 8000 5173 ];
    allowedUDPPortRanges = [
      { from = 2000; to = 65535; }
    ];
  };
}


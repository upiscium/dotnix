{ ... }: {
  networking.firewall = {
    # allowedTCPPorts = [ 20000 11434 8002 8003 ];
    allowedTCPPortRanges = [
      { from = 2000; to = 65535 ;}
    ];
    # allowedUDPPorts = [ 11434 ];
    allowedUDPPortRanges = [
      { from = 2000; to = 65535 ;}
    ];
  };
}


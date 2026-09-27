{ ... }: {
  networking.firewall = {
    allowedTCPPorts = [ 7000 7001 9000 9001 ];
    allowedUDPPorts = [ 7000 ];
    # allowedTCPPortRanges = [ {
    #   from = 1;
    #   to = 65535;
    # } ];
    # allowedUDPPortRanges = [ {
    #   from = 1;
    #   to = 65535;
    # } ];
  };
}

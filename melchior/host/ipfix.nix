{ ... }: {
  networking.useDHCP = false;
  networking.interfaces.ens18 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "10.12.0.2";
        prefixLength = 16;
      }
    ];
  };
  networking.defaultGateway = "10.12.255.254";
}

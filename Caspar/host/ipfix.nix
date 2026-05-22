{ ... }: {
  networking.useDHCP = false;
  networking.interfaces.ens18 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "10.12.0.1";
        prefixLength = 16;
      }
    ];
  };
  networking.defaultGateway = "10.12.255.255";
  networking.nameservers = [ "192.168.11.81" ];
}

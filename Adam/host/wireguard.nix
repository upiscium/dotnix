{ ... }: {
  networking.wireguard.enable = true;
  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "10.255.255.61/32" ];
      dns = [ "192.168.100.31" ];
      mtu = 1420;
      privateKeyFile = "/home/upiscium/secrets/wireguard/Adam.key";
      postUp = ''
        resolvectl dns wg0 192.168.100.31 && resolvectl domain wg0 '~.'
      '';
      postDown = ''
        resolvectl revert wg0
      '';
      peers = [
        {
          publicKey = "5JAuBQtazvI9J8vp5Nxgr1FL28+xN5NciVafTcsiYk4=";
          allowedIPs = [ "10.255.255.0/24" ];
          endpoint = "192.168.100.30:50000";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}


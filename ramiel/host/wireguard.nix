{ ... }: {
  networking.wireguard.enable = true;
  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "10.255.255.3/32" ];
      dns = [ "192.168.11.81" ];
      mtu = 1420;
      privateKeyFile = "/home/upiscium/secrets/wireguard/Ramiel.key";
      postUp = ''
        resolvectl dns wg0 192.168.11.81 && resolvectl domain wg0 '~.'
      '';
      postDown = ''
        resolvectl revert wg0
      '';
      peers = [
        {
          publicKey = "5JAuBQtazvI9J8vp5Nxgr1FL28+xN5NciVafTcsiYk4=";
          allowedIPs = [ "0.0.0.0/0" ];
          endpoint = "vpn.upiscium.dev:50000";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}


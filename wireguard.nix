{ config, lib, ... }:

{
  networking.wireguard.interfaces.wg0 = with (import ./base/toBeFilled/lib.nix lib); {
    privateKeyFile = config.age.secrets."wireguard.privateKey".path;
    ips = readStrings ./toBeFilled/wireguard/ips;
    peers = [
      {
        publicKey = readString ./toBeFilled/wireguard/peer/publicKey;
        allowedIPs = readStrings ./toBeFilled/wireguard/peer/allowedIPs;
        endpoint = readString ./toBeFilled/wireguard/peer/endpoint;
        persistentKeepalive = 25;
      }
    ];
  };
}

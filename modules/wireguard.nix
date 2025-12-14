{ config, lib, ... }:

lib.mkIf (lib.pathExists ./toBeFilled/wireguard) {
  networking.wg-quick.interfaces.wg0 = with (import ./base/toBeFilled/lib.nix lib); {
    privateKeyFile = config.age.secrets."wireguard.privateKey".path;
    address = ./toBeFilled/wireguard/address |> readStrings;
    peers = [
      {
        publicKey = ./toBeFilled/wireguard/peer/publicKey |> readString;
        allowedIPs = ./toBeFilled/wireguard/peer/allowedIPs |> readStrings;
        endpoint = ./toBeFilled/wireguard/peer/endpoint |> readString;
        persistentKeepalive = 25;
      }
    ];
  };
}

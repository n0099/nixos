secrets:
let
  # inherit (import <nixpkgs> { }) lib; # https://github.com/ryantm/agenix/issues/310
  nameValuePair = name: value: { inherit name value; };
  genAttrs' = xs: f: builtins.listToAttrs (map f xs);
  genAttrs = names: f: genAttrs' names (n: nameValuePair n (f n)); # https://github.com/NixOS/nixpkgs/blob/3bcc93c5f7a4b30335d31f21e2f1281cba68c318/lib/attrsets.nix#L1219
  publicKeys = [ (builtins.readFile /etc/ssh/ssh_host_ed25519_key.pub) ]; # created by sshd
in
genAttrs (builtins.map (name: "${name}.age") secrets) (_: {
  inherit publicKeys;
  armor = true;
})

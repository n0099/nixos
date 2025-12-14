{ ... }:

{
  environment.memoryAllocator.provider = "mimalloc";
  nixpkgs.overlays = [
    (self: super: {
      librewolf-unwrapped = super.librewolf-unwrapped.override { jemallocSupport = false; };
    })
  ];
}

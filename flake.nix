{
  description = "llvm-backend flake️";

  inputs.utils.url = "github:kreisys/flake-utils";

  outputs = { self, nixpkgs, utils }: utils.lib.simpleFlake {
    inherit nixpkgs;
    systems = [ "x86_64-darwin" "x86_64-linux" ];

    packages = { system }: rec {
      inherit (import self { inherit system; }) llvm-backend;
      defaultPackage = llvm-backend;
    };
  };
}

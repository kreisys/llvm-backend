{
  description = "llvm-backend flake️";

  inputs = {
    utils.url = "github:kreisys/flake-utils";
    nixpkgs.url = "nixpkgs/a26e92a67d884db696792d25dcc44c466a1bc8b4";
    mavenix = {
      url = "github:nix-community/mavenix/3ac30863abb9a8986560ed4dfa5e6288434b73e1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, mavenix }: utils.lib.simpleFlake {
    inherit nixpkgs;
    systems = [ "x86_64-darwin" "x86_64-linux" ];

    overlay = final: prev: with final; {
      llvmPackages = prev.llvmPackages_10;
      # The backend requires clang/lld/libstdc++ at runtime.
      # The closest configuration in Nixpkgs is clang/lld without any C++ standard
      # library. We override that configuration to inherit libstdc++ from stdenv.
      clang =
        let
          override = attrs: {
            extraBuildCommands = ''
                ${attrs.extraBuildCommands}
              sed -i $out/nix-support/cc-cflags -e '/^-nostdlib/ d'
            '';
          };
        in
        llvmPackages.lldClangNoLibcxx.override override;

      llvm-backend = callPackage ./nix/llvm-backend.nix {
        release = false;
        host.clang = clang;
      };

      mavenix = callPackage mavenix {};

      llvm-backend-matching = callPackage ./nix/llvm-backend-matching.nix {};

      llvm-kompile-testing =
        let
          java = "${jre}/bin/java";
          inherit (llvm-backend-matching) jar;
        in
        runCommandNoCC "llvm-kompile-testing" { } ''
          mkdir -p "$out/bin"
          cp ${llvm-backend.src}/bin/llvm-kompile-testing "$out/bin"
          sed -i "$out/bin/llvm-kompile-testing" \
          -e '/@PROJECT_SOURCE_DIR@/ c ${java} -jar ${jar} $definition qbaL $dt_dir 1'
          chmod +x "$out/bin/llvm-kompile-testing"
          patchShebangs "$out/bin/llvm-kompile-testing"
        '';

    };

    packages = { llvm-backend }: rec {
      inherit llvm-backend;
      defaultPackage = llvm-backend;
    };
  };
}

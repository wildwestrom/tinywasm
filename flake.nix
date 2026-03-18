{
  description = "rust";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = nixpkgs.legacyPackages.${system}.extend (
          final: prev: {
            rustPkgs = import nixpkgs {
              inherit system overlays;
            };
          }
        );
        rust-toolchain = pkgs.rustPkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      in
      {
        devShell = pkgs.mkShell {
          # native packages
          packages = with pkgs; [
            rust-toolchain
            llvm
          ];
        };
      }
    );
}

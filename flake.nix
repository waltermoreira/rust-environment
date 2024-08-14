{
  description = "Rust Environment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    shell-utils.url = "github:waltermoreira/shell-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };
  outputs =
    { self
    , nixpkgs
    , flake-utils
    , crane
    , shell-utils
    , rust-overlay
    }:
      with flake-utils.lib; eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        shell = shell-utils.myShell.${system};
        craneLib = crane.mkLib pkgs;
        myRust = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" ];
        };
        env = {
          packages = [
            myRust
            pkgs.rust-analyzer
          ];
        };
        mkBinary = bin: pkgs.writeShellApplication {
          name = bin;
          runtimeInputs = with pkgs; [ nix ];
          text = ''
            nix develop ${self}#rustEnv --command ${bin} "$@"
          '';
        };
        binaries = pkgs.buildEnv {
          name = "rust-binaries";
          paths = builtins.map mkBinary (builtins.attrNames (builtins.readDir "${myRust}/bin")) ++ [ pkgs.rust-analyzer ];
        };
      in
      {
        devShells.default = shell (env // { name = "rust"; });
        devShells.rustEnv = pkgs.mkShell (env // { name = "rust-env"; });
        packages.default = binaries;
      });
}

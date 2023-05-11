{
  # TODO: Add description here
  description = ''
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    pre-commit-hooks,
    flake-utils,
    ...
  }: let
    supportedSystems = [
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    overlay = import ./nix/overlay.nix {};
  in
    flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          overlay
        ];
      };

      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = self;
        hooks = {
          cabal2nix.enable = true;
          alejandra.enable = true;
          editorconfig-checker.enable = true;
          markdownlint.enable = true;
          fourmolu.enable = true;
          hpack.enable = true;
          hlint.enable = true;
        };
      };

      devShell = pkgs.haskellPackages.shellFor {
        name = "devShell"; # TODO: Set name here
        packages = p: with p; [];
        withHoogle = true;
        buildInputs =
          (with pkgs; [
            haskell-language-server
            cabal-install
            zlib
          ])
          ++ (with pre-commit-hooks.packages.${system}; [
            hlint
            hpack
            fourmolu
            cabal2nix
            editorconfig-checker
            markdownlint-cli
            alejandra
          ]);
        shellHook = ''
          ${self.checks.${system}.pre-commit-check.shellHook}
        '';
      };
    in {
      devShells = {
        default = devShell;
        inherit devShell;
      };

      # packages = {
      # };

      checks = {
        pre-commit-check = pre-commit-check;
        # inherit
        #   (pkgs)
        #   ;
      };
    })
    // {
      overlays = {
        default = overlay;
      };
    };
}

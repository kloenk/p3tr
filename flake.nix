{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, ... }@inputs:
    let
      systems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f:
        builtins.listToAttrs (map (name: {
          inherit name;
          value = f name;
        }) systems);

      version = "${nixpkgs.lib.substring 0 8 self.lastModifiedDate}-${
          self.shortRev or "dirty"
        }";

      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        });
    in {
      overlays.default = final: prev: {
        p3tr = final.callPackage ({ lib, beam, beamPackages, rebar3 }:
          let
            packages = beam.packagesWith beam.interpreters.erlang;
            pname = "p3tr";
            src = self;
            mixEnv = "prod";

            mixDeps = import ./nix/mix.nix { inherit lib beamPackages; };
          in packages.mixRelease {
            inherit pname version src mixEnv;

            mixNixDeps = mixDeps;

            nativeBuildInputs = [ rebar3 ];
          }) { };
      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) p3tr;
        default = self.packages.${system}.p3tr;
      });

      legacyPackages = forAllSystems (system: nixpkgsFor.${system});

      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                # https://devenv.sh/reference/options/
                packages = with pkgs; [ mix2nix git inotify-tools ];
                languages.elixir.enable = true;
                pre-commit.hooks.actionlint.enable = true;
                pre-commit.hooks.nixfmt.enable = true;
                pre-commit.excludes = [ "nix/mix.nix" ];
              }
              {
                services.postgres.enable = true;
                services.postgres.listen_addresses = "127.0.0.1";
                services.postgres.initialDatabases = [{ name = "p3tr_dev"; }];
              }
              ({ config, ... }: { process.implementation = "hivemind"; })
            ];
          };
        });

      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt);

      checks = forAllSystems (system: {
        devenv_ci = self.devShells.${system}.default.ci;
        #p3tr = self.packages.${system}.p3tr;
      });
    };
}

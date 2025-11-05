{
  description = "Minimal JS/TS fullstack dev shell (sqlite + postgres clients)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { 
		inherit system; 
		config = {
				allowUnfree = true;
		};  
	};
    nodePkgs = pkgs.nodePackages;
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "js-ts-fullstack";

      buildInputs = with pkgs; [
        nodejs_20                 # node + npm
        yarn
        pnpm
        typescript
        nodePkgs.typescript-language-server
        prettier
        eslint
        sqlite                   # sqlite3 CLI + lib
        postgresql               # postgres server + psql client
        git
        curl
        openssh
        mongodb
		mongodb-tools
		postgresql
		sqlite
        gcc                      # for building native npm modules if needed
      ];

      # helpful environment variables for node-gyp / native builds
      shellHook = ''
        export npm_config_python=${pkgs.python3}/bin/python
        echo "🧰 js-ts fullstack shell — sqlite & postgresql clients available"
        echo "Run: nix develop  → then: npm install (or pnpm/yarn), tsc, node dist/server.js"
      '';
    };
  };
}


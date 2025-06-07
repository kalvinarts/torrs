{ pkgs ? import <nixpkgs> { }, buildVersion ? "0.0.0-dev" }:

pkgs.buildGoModule rec {
  pname = "torrs";
  version = buildVersion;

  src = ./.;

  vendorHash = "sha256-kINVoOfAAWT5s846xqfqK9Dw+Fs5KH4tzYa3IWVojHM="; # Make sure this is up-to-date

  subPackages = [ "src/torrs" ];

  ldflags = [ "-X main.version=${version}" ];

  nativeBuildInputs = [
    pkgs.revive
    pkgs.gotools
    pkgs.go-outline
  ];

  # If you have CGO dependencies, uncomment and add them:
  # buildInputs = [ pkgs.some-c-library ];

  # Tests are run via Makefile, so doCheck is false here.
  # If you want Nix to run Go tests directly:
  # doCheck = true;
  # checkPhase = ''
  #   runHook preCheck
  #   go test -v -race -cover ./...
  #   runHook postCheck
  # '';
  doCheck = false;

  go = pkgs.go_1_23; # Specify Go version

  meta = with pkgs.lib; {
    description = "A command-line BitTorrent client written in Go"; # User to update
    homepage = "https://github.com/kalvinpearce/torrs";    # User to update
    license = licenses.mit; # Or user's chosen license
    # maintainers = [ maintainers.your-github-username ]; # Optional
  };
}

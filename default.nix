{ pkgs ? import <nixpkgs> { }, buildVersion ? "0.0.0-dev" }:

pkgs.buildGoModule rec {
  pname = "torrs";
  version = buildVersion;

  src = ./.;

  vendorHash = "sha256-do+Xy8DuyS6kNbJAt2ERx4wLQ3km8FNdbXXdF88tCsI="; # Make sure this is up-to-date

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
    description = "A simple torrent streaming service";
    homepage = "https://github.com/kalvinarts/torrs";
    license = licenses.bsd3;
    maintainers = [ maintainers.kalvinarts ];
  };
}

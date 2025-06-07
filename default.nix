{ pkgs ? import <nixpkgs> { } }:

let
  # Helper function to get version from git repository
  # This is impure as its output depends on the state of the git repository.
  getGitVersion = dir: pkgs.lib.strings.trim (
    builtins.readFile (pkgs.runCommand "git-version" {
      buildInputs = [ pkgs.git ]; # git command must be available
      SOURCE_DIR = dir; # Pass the source directory to the script
    } ''
      cd "$SOURCE_DIR"
      if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        # Try to get version using 'git describe', fallback to short commit hash.
        # --match 'v*' aligns with common tagging like v1.0.0.
        VERSION_STRING=$(git describe --tags --always --dirty --match 'v*' 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown-dev-version")
      else
        VERSION_STRING="unknown-version-not-a-git-repo"
      fi
      echo -n "$VERSION_STRING" > $out
    '')
  );

  currentVersion = getGitVersion ./.; # Get version from the current directory
in
pkgs.buildGoModule rec {
  pname = "torrs";
  version = currentVersion; # Use dynamically determined version

  src = pkgs.lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      let
        baseName = baseNameOf (toString path);
      in
      !(
        # Common Nix/dev exclusions
        (type == "directory" && baseName == ".git") ||
        (type == "directory" && baseName == ".direnv") ||
        (type == "symlink" && builtins.match "result.*" baseName != null) ||
        # Our specific backup/temp files
        (builtins.match ".*\\.bak\\..*" baseName != null) || # e.g. default.nix.bak.vendorupdate.1749291398
        (builtins.match ".*\\.forhashcheck\\.tmp" baseName != null) || # e.g. default.nix.forhashcheck.tmp
        (builtins.match ".*\\.sed\\.tmp" baseName != null) || # e.g. default.nix.sed.tmp
        # Vendored dependencies are handled by vendorHash, exclude them from src
        (type == "directory" && baseName == "vendor")
      );
  };

  # IMPORTANT: Replace with actual hash after first build attempt.
  # Run: nix-build --no-out-link .
  # Nix will error and show the expected hash.
  # Or run: make update-vendor-hash
  vendorHash = "sha256-kINVoOfAAWT5s846xqfqK9Dw+Fs5KH4tzYa3IWVojHM=";

  # Pass the version to the Go linker.
  ldflags = [ "-X main.version=${version}" ];

  # Specify the Go version from go.mod
  go = pkgs.go_1_23;

  # Dependencies needed by buildGoModule itself or by hooks
  # git for versioning script, cacert for potential network access during build by Go
  # revive, gotools, go-outline for linting and other Go development tasks
  nativeBuildInputs = [ pkgs.git pkgs.cacert pkgs.revive pkgs.gotools pkgs.go-outline ];

  # We have a 'make test' target, so disable default test running during build.
  doCheck = false;

  meta = with pkgs.lib; {
    description = "A simple torrent streaming service";
    homepage = "https://github.com/kalvinarts/torrs";
    license = licenses.mit; # Adjust if your license is different
    maintainers = [ maintainers.kalvinarts ]; # Replace with your GitHub username
  };
}

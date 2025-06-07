VERSION ?= $(shell nix-shell --run "git describe --tags --always --dirty --match 'v*' 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo \"unknown-dev-version\"")
APP_NAME = torrs
DIST_DIR = dist
NIX_BUILD_CMD = nix-build --no-out-link default.nix
NIX_SHELL_CMD = nix-shell --pure default.nix --run

.PHONY: build clean test run lint install build-release result update-vendor-hash

# Target to get the Nix build result path
result: 
	@echo $$(nix-build --no-out-link default.nix)

build: result
	mkdir -p $(DIST_DIR)/
	@echo "Copying binary from Nix store to $(DIST_DIR)/$(APP_NAME)"
	cp $$(cat $<)/bin/$(APP_NAME) $(DIST_DIR)/$(APP_NAME)

clean:
	rm -rf $(DIST_DIR)/
	rm -f coverage.out
	$(NIX_SHELL_CMD) "go clean -testcache"

test:
	$(NIX_SHELL_CMD) "go test -v -race -cover ./..."

run: build
	$(DIST_DIR)/$(APP_NAME)

lint:
	$(NIX_SHELL_CMD) "revive -config revive.toml -formatter friendly ./..."

install: build
	cp $(DIST_DIR)/$(APP_NAME) $(GOPATH)/bin/$(APP_NAME) # Or any other preferred install location

build-release:
	@echo "Building Linux AMD64 (via Nix)"
	mkdir -p $(DIST_DIR)
	cp $$(nix-build --no-out-link --argstr system "x86_64-linux" default.nix)/bin/$(APP_NAME) $(DIST_DIR)/$(APP_NAME)-linux-amd64
	@echo "Building Linux ARM64 (via Nix)"
	cp $$(nix-build --no-out-link --argstr system "aarch64-linux" default.nix)/bin/$(APP_NAME) $(DIST_DIR)/$(APP_NAME)-linux-arm64
	# For Darwin and Windows, cross-compilation with Nix requires more setup (see notes below)
	# As a placeholder, we'll call the Go commands directly within a nix-shell for now
	# This won't be as reproducible as a pure Nix build for those targets.
	@echo "Building Darwin AMD64 (Go fallback)"
	$(NIX_SHELL_CMD) "GOOS=darwin GOARCH=amd64 go build -ldflags '-X main.version=$(VERSION)' -o $(DIST_DIR)/$(APP_NAME)-darwin-amd64 ./src/$(APP_NAME)"
	@echo "Building Darwin ARM64 (Go fallback)"
	$(NIX_SHELL_CMD) "GOOS=darwin GOARCH=arm64 go build -ldflags '-X main.version=$(VERSION)' -o $(DIST_DIR)/$(APP_NAME)-darwin-arm64 ./src/$(APP_NAME)"
	@echo "Building Windows AMD64 (Go fallback)"
	$(NIX_SHELL_CMD) "GOOS=windows GOARCH=amd64 go build -ldflags '-X main.version=$(VERSION)' -o $(DIST_DIR)/$(APP_NAME)-windows-amd64.exe ./src/$(APP_NAME)"
	@echo "Building Windows ARM64 (Go fallback)"
	$(NIX_SHELL_CMD) "GOOS=windows GOARCH=arm64 go build -ldflags '-X main.version=$(VERSION)' -o $(DIST_DIR)/$(APP_NAME)-windows-arm64.exe ./src/$(APP_NAME)"

# Notes for cross-compilation:
# True Nix-based cross-compilation for Darwin/Windows from Linux is more involved.
# It often requires setting up specific cross compilers in your Nix expressions or using overlays like nixpkgs-cross-overlay.
# The Go fallback above uses nix-shell to get 'go' and then uses Go's native cross-compilation.

.PHONY: update-vendor-hash
update-vendor-hash:
	@echo "Attempting to update vendorHash in default.nix..."
	# Backup default.nix before modifying
	@cp default.nix default.nix.bak.vendorupdate
	# Temporarily set a known incorrect hash to force Nix to output the correct one.
	@sed -i 's|^  vendorHash = .*$$|  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";|' default.nix
	# Run nix-build, capture stderr, and parse the expected hash.
	# The error message looks like: error: output path '...' has sha256 hash '...' when 'sha256-...' was expected
	@NEW_HASH=$$(nix-build --no-out-link default.nix 2>&1 | grep "sha256 hash '.*' when '" | sed -n "s/.*when '\(sha256-.*\)' was expected/\1/p" || echo ""); \
	if [ -n "$$NEW_HASH" ]; then \
		echo "Found new vendorHash: $$NEW_HASH"; \
		# Update default.nix with the new hash (from the backup to avoid issues if sed failed above)
		@sed -i "s|^  vendorHash = .*$$|  vendorHash = \"$$NEW_HASH\";|" default.nix.bak.vendorupdate && mv default.nix.bak.vendorupdate default.nix; \
		echo "default.nix updated successfully."; \
	else \
		echo "Failed to automatically find the new vendorHash."; \
		echo "Restoring default.nix from backup."; \
		echo "Please run 'nix-build --no-out-link default.nix' and manually update vendorHash in default.nix."; \
		@mv default.nix.bak.vendorupdate default.nix; \
		exit 1; \
	fi
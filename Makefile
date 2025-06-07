VERSION ?= $(shell nix-shell --run "git describe --tags --always --dirty --match 'v*' 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo \"unknown-dev-version\"")
APP_NAME = torrs
DIST_DIR = dist
NIX_BUILD_CMD = nix-build --no-out-link default.nix
NIX_SHELL_CMD = nix-shell --pure default.nix --run

.PHONY: build clean test run lint install build-release result update-vendor-hash

# Target to get the Nix build result path
result: 
	@echo $$(nix-build --no-out-link default.nix)

build:
	nix-build default.nix # This creates the ./result symlink
	mkdir -p $(DIST_DIR)/
	@echo "Copying binary from Nix store to $(DIST_DIR)/$(APP_NAME)"
	cp ./result/bin/$(APP_NAME) $(DIST_DIR)/$(APP_NAME)

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
	cp $(DIST_DIR)/$(APP_NAME) $$(go env GOPATH)/bin/$(APP_NAME) # Use go env GOPATH for robustness

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
	$(NIX_SHELL_CMD) "CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags '-X main.version=$(VERSION)' -o $(DIST_DIR)/$(APP_NAME)-darwin-amd64 ./src/$(APP_NAME)"
	@echo "Building Darwin ARM64 (Go fallback)"
	$(NIX_SHELL_CMD) "CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -ldflags '-X main.version=$(VERSION)' -o $(DIST_DIR)/$(APP_NAME)-darwin-arm64 ./src/$(APP_NAME)"
	@echo "Building Windows AMD64 (Go fallback)"
	$(NIX_SHELL_CMD) "CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags '-X main.version=$(VERSION)' -o $(DIST_DIR)/$(APP_NAME)-windows-amd64.exe ./src/$(APP_NAME)"
	@echo "Building Windows ARM64 (Go fallback)"
	$(NIX_SHELL_CMD) "CGO_ENABLED=0 GOOS=windows GOARCH=arm64 go build -ldflags '-X main.version=$(VERSION)' -o $(DIST_DIR)/$(APP_NAME)-windows-arm64.exe ./src/$(APP_NAME)"

# Notes for cross-compilation:
# True Nix-based cross-compilation for Darwin/Windows from Linux is more involved.
# It often requires setting up specific cross compilers in your Nix expressions or using overlays like nixpkgs-cross-overlay.
# The Go fallback above uses nix-shell to get 'go' and then uses Go's native cross-compilation.

update-vendor-hash:
	@echo "Running vendorHash update script from scripts/update-vendor-hash.sh..."
	@chmod +x ./scripts/update-vendor-hash.sh
	@./scripts/update-vendor-hash.sh ; \
	STATUS=$$?; \
	if [ $$STATUS -ne 0 ]; then \
		echo "Vendor hash update script failed with status $$STATUS."; \
	fi; \
	exit $$STATUS
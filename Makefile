VERSION ?= $(shell git describe --tags --always --dirty)
APP_NAME = torrs
DIST_DIR = dist

.PHONY: build clean test run lint install build-release

build: 
	mkdir -p $(DIST_DIR)/
	go build -ldflags "-X main.version=$(VERSION)" -o $(DIST_DIR)/$(APP_NAME) ./src/$(APP_NAME)

clean:
	rm -rf $(DIST_DIR)/
	rm -f coverage.out
	go clean -testcache

test:
	go test -v -race -cover ./...

run:
	go run ./src/torrs/main.go

lint:
	revive -config revive.toml -formatter friendly ./...

install:
	go install ./src/torrs

build-release:
	mkdir -p $(DIST_DIR)
	GOOS=linux GOARCH=amd64 go build -ldflags "-X main.version=$(VERSION)" -o $(DIST_DIR)/$(APP_NAME)-linux-amd64 ./src/$(APP_NAME)
	GOOS=linux GOARCH=arm64 go build -ldflags "-X main.version=$(VERSION)" -o $(DIST_DIR)/$(APP_NAME)-linux-arm64 ./src/$(APP_NAME)
	GOOS=darwin GOARCH=amd64 go build -ldflags "-X main.version=$(VERSION)" -o $(DIST_DIR)/$(APP_NAME)-darwin-amd64 ./src/$(APP_NAME)
	GOOS=darwin GOARCH=arm64 go build -ldflags "-X main.version=$(VERSION)" -o $(DIST_DIR)/$(APP_NAME)-darwin-arm64 ./src/$(APP_NAME)
	GOOS=windows GOARCH=amd64 go build -ldflags "-X main.version=$(VERSION)" -o $(DIST_DIR)/$(APP_NAME)-windows-amd64.exe ./src/$(APP_NAME)
	GOOS=windows GOARCH=arm64 go build -ldflags "-X main.version=$(VERSION)" -o $(DIST_DIR)/$(APP_NAME)-windows-arm64.exe ./src/$(APP_NAME)
# GoDeck Unified Makefile
# Supported commands for server (Go) and mobile client (Flutter)

.PHONY: all setup run-server run-app test test-server test-app build-server build-app clean help

# Environment configuration
GO ?= $(shell which go 2>/dev/null || echo "/Users/lucasbrito/Documents/vpn1real/tunnel/build/intermediates/cxx/Debug/3h1n606f/obj/generated-src/go-1.24.3/bin/go")
FLUTTER ?= flutter

all: help

## Setup project dependencies
setup:
	@echo "==> Setting up GoDeck Server..."
	@cd server && $(GO) mod tidy
	@echo "==> Setting up GoDeck Mobile App..."
	@cd app && $(FLUTTER) pub get
	@chmod +x scripts/*.sh 2>/dev/null || true
	@echo "==> Setup complete!"

## Run GoDeck Server daemon locally
run-server:
	@echo "==> Starting GoDeck Host Server on :8080..."
	@cd server && $(GO) run ./cmd/godeck/main.go -port 8080 -verbose

## Run Flutter Mobile Client on attached device or simulator
run-app:
	@echo "==> Launching GoDeck Mobile Client..."
	@cd app && $(FLUTTER) run

## Run all unit tests (Server + Mobile)
test: test-server test-app

## Run Go server unit tests
test-server:
	@echo "==> Running Go Server tests..."
	@cd server && $(GO) test -v ./...

## Run Flutter app unit tests
test-app:
	@echo "==> Running Flutter App tests..."
	@cd app && $(FLUTTER) test

## Cross-compile Go server binaries
build-server:
	@echo "==> Building Go Server binaries..."
	@mkdir -p server/bin
	@echo "Building for macOS (arm64)..."
	@cd server && GOOS=darwin GOARCH=arm64 $(GO) build -o bin/godeck-mac-arm64 ./cmd/godeck
	@echo "Building for Linux (amd64)..."
	@cd server && GOOS=linux GOARCH=amd64 $(GO) build -o bin/godeck-linux-amd64 ./cmd/godeck
	@echo "Building for Windows (amd64)..."
	@cd server && GOOS=windows GOARCH=amd64 $(GO) build -o bin/godeck-windows-amd64.exe ./cmd/godeck
	@echo "==> Server builds complete in server/bin/"

## Build Flutter APK for Android
build-app:
	@echo "==> Building Flutter APK..."
	@cd app && $(FLUTTER) build apk --release
	@echo "==> Flutter APK build complete!"

## Clean build artifacts
clean:
	@echo "==> Cleaning build outputs..."
	@rm -rf server/bin
	@cd app && $(FLUTTER) clean

## Print help menu
help:
	@echo "GoDeck Monorepo Commands:"
	@echo "  make setup        - Install dependencies for both server and app"
	@echo "  make run-server   - Start the Go host daemon"
	@echo "  make run-app      - Launch the Flutter app"
	@echo "  make test         - Run tests for server and app"
	@echo "  make build-server - Build server binaries for macOS, Linux, and Windows"
	@echo "  make build-app    - Build Flutter Android release APK"
	@echo "  make clean        - Remove build artifacts"

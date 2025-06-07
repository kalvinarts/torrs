# torrs

A simple torrent streaming service

## Installation

### Using the install script (Linux/macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/kalvinarts/torrs/main/install.sh | sh
```

### Manual download

You can also download the binary for your system directly from the [releases page](https://github.com/kalvinarts/torrs/releases/latest).

## Usage

To start streaming a torrent:

```bash
torrs -m "magnet:?xt=urn:btih:..." 
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-m` | Magnet link for the torrent | - |
| `-fc` | Get magnet link from clipboard | false |
| `-l` | List all files in the torrent | false |
| `-n` | Selects the file index number to download (use -l to see file index numbers)(takes precedence over -t) | 0 |
| `-t` | Selects the first file with that extension (e.g. mp4)(takes precedence over -e) | - |
| `-e` | Select the first file that matches a regular expression | - |
| `-p` | Port to serve the file on | "8457" |
| `-d` | Download directory | "~/Downloads" |
| `-s` | Seed the torrent after download | false |
| `-tc` | Copy the stream URL to clipboard | false |

### Examples

List files in a torrent:
```bash
torrs -m "magnet:?xt=urn:btih:..." -l
```

Stream specific file on custom port:
```bash
torrs -m "magnet:?xt=urn:btih:..." -n 2 -p 8080
```

Stream the first MP4 file found:
```bash
torrs -m "magnet:?xt=urn:btih:..." -t mp4
```

Stream the first file getting the magnet from clipboard:
```bash
torrs -fc -n 1
```

## Development

### Development Environment (Nix)

This project uses [Nix](https://nixos.org/) to manage its development environment and build process, ensuring reproducibility.

To activate the development environment, run:
```bash
nix-shell
```
All `make` commands should be run within this shell or will invoke it as needed.

If you update Go dependencies (`go.mod`/`go.sum`), you'll need to update the Nix vendor hash:
```bash
make update-vendor-hash
```
Then commit the changes to `default.nix`, `go.mod`, and `go.sum`.

### Available Make Commands

| Command | Description |
|---------|-------------|
| `make build` | Build the project |
| `make clean` | Clean build artifacts and test cache |
| `make test` | Run tests with race detection and coverage |
| `make run` | Run the application |
| `make lint` | Lint the code using revive |
| `make install` | Install the application |
| `make build-release` | Build releases for Linux, macOS, and Windows |
| `make update-vendor-hash` | Update the Go vendor hash in `default.nix` |

## Roadmap
 - Add libVLC to stream to chromecast
 - Expand test coverage
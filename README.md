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

| Flag | Description | Default |
|------|-------------|---------|
| `-m` | Magnet link for the torrent | - |
| `-fc` | Get magnet link from clipboard | false |
| `-l` | List all files in the torrent | false |
| `-n` | Selects the file index number to download (use -l to see file index numbers)(takes precedence over -t) | 0 |
| `-t` | Selects the first file with that extension (e.g. mp4)(takes precedence over -e) | - |
| `-e` | Select the first file by expression (e.g. ".*S01E01.*") | - |
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

Stream episode using regex:
```bash
torrs -m "magnet:?xt=urn:btih:..." -e ".*S01E01.*"
```

Stream the first file getting the magnet from clipboard:
```bash
torrs -fc -n 1
```

If no file index number is specified the first file of the torrent will be streamed

## Development

| Command | Description |
|---------|-------------|
| `make build` | Build the project |
| `make clean` | Clean build artifacts and test cache |
| `make test` | Run tests with race detection and coverage |
| `make run` | Run the application |
| `make lint` | Lint the code using revive |
| `make install` | Install the application |
| `make release-build` | Build releases for Linux, macOS, and Windows |

## Roadmap
 - Add libVLC to stream to chromecast
 - Add testing
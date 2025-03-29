package main

import (
	"flag"
	"os"
)

// Config holds the command line arguments
type Config struct {
	MagnetLink          string
	MagnetFromClipboard bool
	ListFiles           bool
	FileIndex           int
	SelectByExtension   string
	SelectByExpression  string
	Port                string
	DownloadDir         string
	Seed                bool
	URLToClipboard      bool
	PrintHelp           bool
}

// ParseConfig parses the command line arguments
func ParseConfig() *Config {
	config := &Config{}

	flag.StringVar(&config.MagnetLink, "m", "", "Magnet link for the torrent")
	flag.BoolVar(&config.MagnetFromClipboard, "fc", false, "Get magnet link from clipboard")
	flag.BoolVar(&config.ListFiles, "l", false, "List all files in the torrent")
	flag.IntVar(&config.FileIndex, "n", 0, "Selects the file index number to download (use -l to see file index numbers)(takes precedence over -t)")
	flag.StringVar(&config.SelectByExtension, "t", "", "Selects the first file with that extension (e.g. .mp4)(takes precedence over -e)")
	flag.StringVar(&config.SelectByExpression, "e", "", "Select the first file by expression (e.g. -e \".*S01E01.*\")")
	flag.StringVar(&config.Port, "p", "8457", "Port to serve the file on")
	flag.StringVar(&config.DownloadDir, "d", os.Getenv("HOME")+"/Downloads", "Download directory")
	flag.BoolVar(&config.Seed, "s", false, "Seed the torrent after download")
	flag.BoolVar(&config.URLToClipboard, "tc", false, "Copy the stream URL to clipboard")
	flag.Parse()

	return config
}

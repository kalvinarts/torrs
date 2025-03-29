package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"regexp"

	"github.com/anacrolix/torrent"
)

// CheckForMagnetLink checks if a magnet link is provided or if it should be read from the clipboard
func CheckForMagnetLink(config *Config) {
	if config.MagnetFromClipboard {
		// Get the magnet link from the clipboard
		fmt.Println("> Reading magnet link from clipboard...")
		magnetLink, err := GetClipboard()
		if err != nil {
			log.Fatalln("Failed to read from clipboard:", err)
		}
		re := regexp.MustCompile(`^magnet:\?.*xt=urn:btih:[a-zA-Z0-9]+.*$`)
		if !re.MatchString(magnetLink) {
			log.Fatalln("Invalid magnet link format")
		}
		config.MagnetLink = magnetLink
	}

	// Print help message if no magnet link is provided
	if config.MagnetLink == "" {
		fmt.Println("No magnet link provided. Use -m <magnet_link> to specify a magnet link.")
		flag.PrintDefaults()
		os.Exit(1)
	}
}

// TorrentInit initializes the torrent client and starts downloading the torrent
func TorrentInit(config *Config) (*torrent.Client, *torrent.Torrent, []*torrent.File) {
	// Create a new torrent client configuration
	clientConfig := torrent.NewDefaultClientConfig()
	clientConfig.Seed = config.Seed
	clientConfig.DataDir = config.DownloadDir
	// Initialize the torrent client
	client, err := torrent.NewClient(clientConfig)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	// Add the torrent by magnet link
	torrent, err := client.AddMagnet(config.MagnetLink)
	if err != nil {
		log.Fatalf("Failed to add torrent: %v", err)
	}
	// Wait until the torrent info is available
	fmt.Println("> Fetching torrent metadata...")
	<-torrent.GotInfo()
	// Get the list of files in the torrent
	files := torrent.Files()
	// Set priority 0 for all files first
	for _, file := range files {
		file.SetPriority(0)
	}
	return client, torrent, files
}

// ListFiles lists all files in the torrent
func ListFiles(files []*torrent.File) {
	fmt.Println("Files in torrent:")
	for i, file := range files {
		fmt.Printf("%d: %s\n", i+1, CleanFilePath(file.Path()))
	}
}

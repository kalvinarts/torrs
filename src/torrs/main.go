// Simple torrent file streaming service
package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/atotto/clipboard"
)

// version is set during build via -ldflags
var version = "dev"

func main() {
	// Parse the command line arguments
	config := ParseConfig()
	// Clear the terminal screen and print the banner
	fmt.Print("\033[H\033[2J")
	fmt.Printf("> torrs - Simple torrent streaming service - %s\n", version)
	CheckForMagnetLink(config)
	client, _, files := TorrentInit(config)
	if config.ListFiles {
		ListFiles(files)
		return
	}
	selectedFile := SelectFile(files, config)
	if selectedFile == nil {
		log.Fatalf("No file matches selection. Use -l to list files or -n, -t, or -e to select a file.")
	}
	// Notify the user about the selected file
	fmt.Printf("> Selected file: %s\n", CleanFilePath(selectedFile.Path()))
	// Set high priority for the selected file
	selectedFile.SetPriority(1)
	// Wait for at least 1% of the file to download
	fmt.Println("> Waiting for download to begin...")
	for selectedFile.BytesCompleted() < selectedFile.Length()/100 {
		time.Sleep(100 * time.Millisecond)
	}
	// Create the file server
	fileServer := NewFileServer(config.Port, selectedFile)
	// Notify the user
	streamURL := fileServer.GetStreamURL()
	fmt.Printf("> Streaming at: %s\n", streamURL)
	if config.URLToClipboard {
		// Copy the stream URL to clipboard
		if err := clipboard.WriteAll(streamURL); err != nil {
			log.Fatalf("%v", ErrClipboardFailure)
		}
		fmt.Println("> Stream URL copied to clipboard")
	}
	// Start progress tracking
	downloadProgress := NewProgress(selectedFile)
	downloadProgress.Start()
	// Initialize signal handling
	SetupSignalHandler(fileServer.server, client, downloadProgress)
	// Start the server
	if err := fileServer.Start(); err != http.ErrServerClosed {
		log.Printf("HTTP server error: %v", err)
	}
}

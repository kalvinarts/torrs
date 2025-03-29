package main

import (
	"fmt"
	"net/http"
	"time"

	"github.com/anacrolix/torrent"
)

// FileServer represents a HTTP serving a torrent file
type FileServer struct {
	server       *http.Server
	selectedFile *torrent.File
	port         string
}

// NewFileServer creates a new file server
func NewFileServer(port string, selectedFile *torrent.File) *FileServer {
	return &FileServer{
		server:       &http.Server{Addr: ":" + port},
		selectedFile: selectedFile,
		port:         port,
	}
}

// Start starts the file server
func (fs *FileServer) Start() error {
	encodedPath := FormatEncodedPath(fs.selectedFile.Path())

	http.HandleFunc(encodedPath, func(w http.ResponseWriter, r *http.Request) {
		reader := fs.selectedFile.NewReader()
		defer reader.Close()
		http.ServeContent(w, r, fs.selectedFile.Path(), time.Now(), reader)
	})

	return fs.server.ListenAndServe()
}

// GetStreamURL returns the stream URL
func (fs *FileServer) GetStreamURL() string {
	encodedPath := FormatEncodedPath(fs.selectedFile.Path())
	return fmt.Sprintf("http://localhost:%s%s", fs.port, encodedPath)
}

// Shutdown shuts down the file server
func (fs *FileServer) Shutdown() error {
	return fs.server.Close()
}

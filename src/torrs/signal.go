package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/anacrolix/torrent"
)

// SetupSignalHandler sets up a signal handler to gracefully shutdown the server and client
func SetupSignalHandler(server *http.Server, client *torrent.Client, progress *Progress) {
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-c
		log.Print(RightPadToTerminalWidth("\r> Shutting down...\n"))
		progress.Stop()
		server.Shutdown(context.Background())
		client.Close()
		os.Exit(0)
	}()
}

package main

import (
	"fmt"
	"time"

	"github.com/anacrolix/torrent"
)

const defaultUpdateInterval = 500 * time.Millisecond

// Progress represents the download progress of a torrent file
type Progress struct {
	File           *torrent.File
	Done           bool
	startTime      time.Time
	stop           bool
	lastBytes      int64
	updateInterval time.Duration
}

// NewProgress creates a new progress
func NewProgress(file *torrent.File) *Progress {
	return &Progress{
		File:           file,
		Done:           false,
		startTime:      time.Now(),
		stop:           false,
		lastBytes:      0,
		updateInterval: defaultUpdateInterval,
	}
}

// Start starts the progress
func (p *Progress) Start() {
	p.lastBytes = p.File.BytesCompleted()
	go func() {
		for {
			if p.stop {
				return
			}
			time.Sleep(p.updateInterval)
			currentBytes := p.File.BytesCompleted()
			progress := float64(currentBytes) / float64(p.File.Length()) * 100

			// Calculate speed (bytes per second)
			speed := float64(currentBytes-p.lastBytes) * (float64(time.Second) / float64(p.updateInterval))
			p.lastBytes = currentBytes

			// Format speed
			speedStr := ""
			if speed >= 1048576 { // 1MB/s
				speedStr = fmt.Sprintf("%.2f MB/s", speed/1048576)
			} else {
				speedStr = fmt.Sprintf("%.2f KB/s", speed/1024)
			}

			status := fmt.Sprintf("\r> Downloading: %.2f%% @ %s", progress, speedStr)
			fmt.Print(RightPadToTerminalWidth(status))
			if currentBytes == p.File.Length() {
				p.Done = true
				fmt.Println(RightPadToTerminalWidth("\r> Download complete!"))
				return
			}
		}
	}()
}

// Stop stops the progress
func (p *Progress) Stop() {
	p.stop = true
	p.lastBytes = 0
}

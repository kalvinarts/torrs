package main

import (
	"errors"
)

// Custom error types
var (
	ErrInvalidMagnetLink = errors.New("invalid magnet link")
	ErrInvalidFileIndex  = errors.New("invalid file index")
	ErrClipboardFailure  = errors.New("failed to copy URL to clipboard")
)

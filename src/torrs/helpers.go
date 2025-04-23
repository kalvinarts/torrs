package main

import (
	"net/url"
	"os"
	"strings"

	"golang.org/x/term"
)

// FormatEncodedPath formats the file path for the server
func FormatEncodedPath(filePath string) string {
	return "/" + url.PathEscape(CleanFilePath(filePath))
}

// CleanFilePath the file path by removing any parent directory references
func CleanFilePath(path string) string {
	parts := strings.Split(path, "/")
	if len(parts) <= 1 {
		return path
	}
	// Omit the first part as it is the name of the torrent folder
	return strings.Join(parts[1:], "/")
}

// RightPadToTerminalWidth returns a right padded string to fill the terminal width
func RightPadToTerminalWidth(str string) string {
	width, _, err := term.GetSize(int(os.Stdout.Fd()))
	if err != nil {
		width = 80
	}

	padding := width - len(str)
	if padding <= 0 {
		return str
	}

	return str + strings.Repeat(" ", padding)
}

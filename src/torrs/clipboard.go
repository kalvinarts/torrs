package main

import (
	"github.com/atotto/clipboard"
)

// GetClipboard reads a string from the clipboard
func GetClipboard() (string, error) {
	return clipboard.ReadAll()
}

// ToClipboard copies a string to the clipboard
func ToClipboard(str string) error {
	return clipboard.WriteAll(str)
}

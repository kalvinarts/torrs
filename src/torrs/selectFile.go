package main

import (
	"fmt"
	"log"
	"regexp"
	"strings"

	"github.com/anacrolix/torrent"
)

// SelectFileByNumber selects a file from the torrent by its index
func SelectFileByNumber(files []*torrent.File, index int) *torrent.File {
	if index < 1 || index > len(files) {
		return nil
	}
	return files[index-1]
}

// SelectFileByExpression selects the first file matching the given regex
func SelectFileByExpression(files []*torrent.File, expr string) *torrent.File {
	re, err := regexp.Compile(expr)
	if err != nil {
		log.Fatalf("Invalid regex: %v", err)
	}
	for _, file := range files {
		if re.MatchString(CleanFilePath(file.Path())) {
			return file
		}
	}
	return nil
}

// SelectFileByExtension selects the first file with the given extension
func SelectFileByExtension(files []*torrent.File, ext string) *torrent.File {
	exp := fmt.Sprintf(".*\\.%s$", regexp.QuoteMeta(strings.TrimSpace(ext)))
	return SelectFileByExpression(files, exp)
}

// SelectFile selects a file
func SelectFile(files []*torrent.File, config *Config) *torrent.File {
	if config.FileIndex > 0 {
		fmt.Println("> Selecting file by index: ", config.FileIndex)
		return SelectFileByNumber(files, config.FileIndex)
	}
	if config.SelectByExpression != "" {
		fmt.Println("> Selecting file by expression: ", config.SelectByExpression)
		return SelectFileByExpression(files, config.SelectByExpression)
	}
	if config.SelectByExtension != "" {
		fmt.Println("> Selecting file by extension: ", config.SelectByExtension)
		return SelectFileByExtension(files, config.SelectByExtension)
	}
	return nil
}

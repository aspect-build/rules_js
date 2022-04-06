package gazelle

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// TypeScript options normalized and relevant to gazelle
type TsOptions struct {
	// The directory the options were loaded from
	ConfigDir string

	// A directory which absolute paths may resolve to
	BaseDir string

	// Directories which may contain sources.
	// Empty allows source from any directory
	RootDirs []string
}

// tsconfig.json structure
type tsConfigOptions struct {
	CompilerOptions struct {
		BaseUrl  string   `json:"baseUrl"`
		RootDir  string   `json:"rootDir"`
		RootDirs []string `json:"rootDirs"`
	} `json:"compilerOptions"`
}

// ParseTsConfigOptions loads a tsconfig.json file and return the compilerOptions config
func ParseTsConfigOptions(rootDir, tsconfigPath string) (*TsOptions, error) {
	content, err := os.ReadFile(filepath.Join(rootDir, tsconfigPath))
	if err != nil {
		// Support non-existing tsconfig
		if os.IsNotExist(err) {
			DEBUG("%s / %s not found\n", rootDir, tsconfigPath)
			return nil, nil
		}

		return nil, err
	}
	var tsconfig tsConfigOptions
	if err := json.Unmarshal(content, &tsconfig); err != nil {
		return nil, fmt.Errorf("failed to parse: %w", err)
	}
	compilerOptions := tsconfig.CompilerOptions

	configDir := filepath.Dir(tsconfigPath)
	baseDir := filepath.Join(configDir, filepath.Clean(compilerOptions.BaseUrl))

	// Combine the tsconfig rootDir + rootDirs, normalizing relative to the configDir
	rootDirs := compilerOptions.RootDirs
	rootDirs = append(rootDirs, compilerOptions.RootDir)

	normalizedRootDirs := []string{}
	for _, d := range rootDirs {
		dir := filepath.Join(configDir, filepath.Clean(d))
		if dir != "" && dir != "." {
			normalizedRootDirs = append(normalizedRootDirs, dir)
		}
	}

	tsOptions := TsOptions{
		ConfigDir: configDir,
		BaseDir:   baseDir,
		RootDirs:  normalizedRootDirs,
	}

	return &tsOptions, nil
}

func DefaultOptions() *TsOptions {
	return &TsOptions{}
}

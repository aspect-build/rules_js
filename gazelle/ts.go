package gazelle

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// TODO(jbedard): rootDirs in addition to rootDir

type TsCompilerOptions struct {
	// The directory the options were loaded from
	ConfigDir string

	// tsconfig.json values
	BaseUrl string `json:"baseUrl"`
	RootDir string `json:"rootDir"`
}

type tsConfigOptions struct {
	CompilerOptions TsCompilerOptions `json:"compilerOptions"`
}

// ParseTsConfigOptions loads a tsconfig.json file and return the compilerOptions config
// TODO(jbedard): support multi-file configs, use native TypeScript tsconfig loader
func ParseTsConfigOptions(rootDir, tsconfigPath string) (*TsCompilerOptions, error) {
	content, err := os.ReadFile(filepath.Join(rootDir, tsconfigPath))
	if err != nil {
		// Support non-existing tsconfig
		if os.IsNotExist(err) {
			DEBUG("%s / %s not found\n", rootDir, tsconfigPath)
			return nil, nil
		}

		return nil, err
	}

	var allRes tsConfigOptions
	if err := json.Unmarshal(content, &allRes); err != nil {
		return nil, fmt.Errorf("failed to parse: %w", err)
	}

	compilerOptions := allRes.CompilerOptions

	return normalizeOptions(filepath.Dir(tsconfigPath), &compilerOptions), nil
}

func DefaultOptions() *TsCompilerOptions {
	return normalizeOptions("", &TsCompilerOptions{})
}

func normalizeOptions(configDir string, compilerOptions *TsCompilerOptions) *TsCompilerOptions {
	compilerOptions.ConfigDir = configDir
	compilerOptions.BaseUrl = filepath.Join(configDir, filepath.Clean(compilerOptions.BaseUrl))
	compilerOptions.RootDir = filepath.Join(configDir, filepath.Clean(compilerOptions.RootDir))

	return compilerOptions
}

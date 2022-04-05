package gazelle

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// TODO(jbedard): rootDirs in addition to rootDir

type TsCompilerOptions struct {
	BaseUrl string `json:"baseUrl"`
	RootDir string `json:"rootDir"`
}

type tsConfigOptions struct {
	CompilerOptions TsCompilerOptions `json:"compilerOptions"`
}

// ParseTsConfigOptions loads a tsconfig.json file and return the compilerOptions config
// TODO(jbedard): support multi-file configs, use native TypeScript tsconfig loader
func ParseTsConfigOptions(tsconfigPath string) (*TsCompilerOptions, error) {
	content, err := os.ReadFile(tsconfigPath)
	if err != nil {
		// Support non-existing tsconfig
		if os.IsNotExist(err) {
			return nil, nil
		}

		return nil, err
	}

	var allRes tsConfigOptions
	if err := json.Unmarshal(content, &allRes); err != nil {
		return nil, fmt.Errorf("failed to parse: %w", err)
	}

	compilerOptions := allRes.CompilerOptions

	return normalizeOptions(&compilerOptions), nil
}

func DefaultOptions() *TsCompilerOptions {
	return normalizeOptions(&TsCompilerOptions{})
}

func normalizeOptions(compilerOptions *TsCompilerOptions) *TsCompilerOptions {
	compilerOptions.BaseUrl = filepath.Clean(compilerOptions.BaseUrl)
	compilerOptions.RootDir = filepath.Clean(compilerOptions.RootDir)

	return compilerOptions
}

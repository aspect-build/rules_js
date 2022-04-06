package gazelle

import (
	"testing"

	"github.com/bazelbuild/rules_go/go/tools/bazel"
)

func parseTest(t *testing.T, configPath string) *TsOptions {
	testDataDir, err := bazel.Runfile("gazelle/ts_test/")
	if err != nil {
		t.Fatalf("cannot lookup runfile: %v", err)
	}

	options, err := ParseTsConfigOptions(testDataDir, configPath)
	if err != nil {
		t.Fatalf("failed to parse options: %v", err)
	}

	return options
}

func hasRoot(roots []string, dir string) bool {
	for _, r := range roots {
		if r == dir {
			return true
		}
	}
	return false
}

func TestTypescriptApi(t *testing.T) {

	t.Run("parse a basic tsconfig baseurl", func(t *testing.T) {
		options := parseTest(t, "baseurl_simple.json")

		if options.BaseDir != "src" {
			t.Errorf("ParseTsConfigOptions: BaseDir\nactual:   %s\nexpected:  %s\n", options.BaseDir, "src")
		}

		if len(options.RootDirs) != 0 {
			t.Errorf("ParseTsConfigOptions: RootDirs\nactual:   %s\nexpected:  []\n", options.RootDirs)
		}
	})

	t.Run("parse a tsconfig with no config", func(t *testing.T) {
		options := parseTest(t, "empty.json")

		if options.BaseDir != "." {
			t.Errorf("ParseTsConfigOptions: BaseDir\nactual:   %s\nexpected:  %s\n", options.BaseDir, ".")
		}

		if len(options.RootDirs) != 0 {
			t.Errorf("ParseTsConfigOptions: RootDirs\nactual:   %s\nexpected:  []\n", options.RootDirs)
		}
	})

	t.Run("parse a tsconfig with no compilerOptions", func(t *testing.T) {
		options := parseTest(t, "empty_compileroptions.json")

		if options.BaseDir != "." {
			t.Errorf("ParseTsConfigOptions: BaseDir\nactual:   %s\nexpected:  %s\n", options.BaseDir, ".")
		}

		if len(options.RootDirs) != 0 {
			t.Errorf("ParseTsConfigOptions: RootDirs\nactual:   %s\nexpected:  []\n", options.RootDirs)
		}
	})

	t.Run("parse a tsconfig with rootDir", func(t *testing.T) {
		options := parseTest(t, "rootdir_src.json")

		if options.BaseDir != "." {
			t.Errorf("ParseTsConfigOptions: BaseDir\nactual:   %s\nexpected:  %s\n", options.BaseDir, ".")
		}

		if !hasRoot(options.RootDirs, "src") {
			t.Errorf("ParseTsConfigOptions: RootDirs\nactual:   %s\nexpected:  %s\n", options.RootDirs, "src")
		}
	})

	t.Run("parse a tsconfig with rootDir relative", func(t *testing.T) {
		options := parseTest(t, "rootdir_dotsrc.json")

		if options.BaseDir != "." {
			t.Errorf("ParseTsConfigOptions: BaseDir\nactual:   %s\nexpected:  %s\n", options.BaseDir, ".")
		}

		if !hasRoot(options.RootDirs, "src") {
			t.Errorf("ParseTsConfigOptions: RootDirs\nactual:   %s\nexpected:  %s\n", options.RootDirs, "src")
		}
	})

}
